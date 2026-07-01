#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

#include <algorithm>
#include <vector>

static std::vector<GtkWidget*> blocker_windows;

// The application's main Flutter window. Kept so the break overlay can transform
// it (fullscreen on the active monitor) and restore it to its exact prior state
// when the break ends, without GNOME/Mutter re-mapping a window that should stay
// hidden in the tray.
static GtkWindow* g_main_window = nullptr;

static FlMethodChannel* g_lock_channel = nullptr;
static GDBusConnection* g_dbus_conn = nullptr;

// Latest state from "window-state-event"; used to detect whether the main
// window was minimized/maximized at the moment a break begins.
static GdkWindowState g_main_window_state = static_cast<GdkWindowState>(0);

// Pre-break snapshot of the main window, captured in enter_break and applied in
// exit_break.
static bool g_break_active = false;
static bool g_restore_to_background = false;  // was hidden-to-tray or minimized
static bool g_was_maximized = false;
static bool g_have_saved_bounds = false;
static int g_saved_x = 0;
static int g_saved_y = 0;
static int g_saved_w = 0;
static int g_saved_h = 0;

static gboolean on_main_window_state_event(GtkWidget* widget,
                                           GdkEventWindowState* event,
                                           gpointer user_data) {
  (void)widget;
  (void)user_data;
  g_main_window_state = event->new_window_state;
  return FALSE;
}

static void destroy_blocker_windows() {
  for (GtkWidget* window : blocker_windows) {
    if (GTK_IS_WIDGET(window)) {
      gtk_widget_destroy(window);
    }
  }
  blocker_windows.clear();
}

// End a break: tear down the blockers and return the main window to exactly the
// state it had before the break. Order matters on GNOME/Mutter: a window that
// must go back to the tray is hidden (unmapped) FIRST and only then has its
// fullscreen/always-on-top styles cleared, all synchronously within this call,
// so the compositor never re-maps it and flashes the UI on screen.
static void exit_break() {
  // Generic timer-stop paths (e.g. cancelling the work timer) also route through
  // here via stopBreakOverlay(), even when no break is on screen. If a break is
  // not actually active there are no blockers to tear down and the main window
  // is in its normal, user-controlled state — so leave it completely untouched.
  if (!g_break_active) {
    return;
  }

  destroy_blocker_windows();
  g_break_active = false;

  if (g_main_window == nullptr) {
    return;
  }

  if (g_restore_to_background) {
    gtk_widget_hide(GTK_WIDGET(g_main_window));
    gtk_window_unfullscreen(g_main_window);
    gtk_window_set_keep_above(g_main_window, FALSE);
    gtk_window_set_decorated(g_main_window, TRUE);
    if (g_have_saved_bounds) {
      gtk_window_move(g_main_window, g_saved_x, g_saved_y);
      gtk_window_resize(g_main_window, g_saved_w, g_saved_h);
    }
    // Stays hidden in the system tray; restored as a normal decorated window
    // when the user clicks the tray icon.
  } else {
    gtk_window_unfullscreen(g_main_window);
    gtk_window_set_keep_above(g_main_window, FALSE);
    gtk_window_set_decorated(g_main_window, TRUE);
    if (g_was_maximized) {
      gtk_window_maximize(g_main_window);
    } else if (g_have_saved_bounds) {
      gtk_window_move(g_main_window, g_saved_x, g_saved_y);
      gtk_window_resize(g_main_window, g_saved_w, g_saved_h);
    }
    gtk_window_present(g_main_window);
  }
}

// Snapshot state and show warning window always-on-top
static void enter_warning(GtkApplication* app) {
  if (!g_break_active && g_main_window != nullptr) {
    g_break_active = true;

    GtkWidget* main_widget = GTK_WIDGET(g_main_window);
    bool visible = gtk_widget_get_visible(main_widget);
    bool minimized = (g_main_window_state & GDK_WINDOW_STATE_ICONIFIED) != 0;
    bool maximized = (g_main_window_state & GDK_WINDOW_STATE_MAXIMIZED) != 0;

    g_restore_to_background = (!visible) || minimized;
    g_was_maximized = maximized;
    g_have_saved_bounds = false;
    if (visible && !minimized && !maximized) {
      gtk_window_get_position(g_main_window, &g_saved_x, &g_saved_y);
      gtk_window_get_size(g_main_window, &g_saved_w, &g_saved_h);
      g_have_saved_bounds = true;
    }
  }

  if (g_main_window != nullptr) {
    gtk_widget_show(GTK_WIDGET(g_main_window));
    gtk_window_deiconify(g_main_window);
    gtk_window_set_keep_above(g_main_window, TRUE);
    gtk_window_present(g_main_window);
  }
}

// Begin a break: snapshot the main window's current state, force it up onto the
// active (cursor) monitor in fullscreen to host the Flutter break UI, then cover
// every other monitor with a solid black always-on-top blocker window.
// Using fullscreen_on_monitor for the active monitor and separate blocker windows
// for others is the proven, stable approach that works reliably on GNOME/Mutter
// with both X11 and Wayland. A single "spanned" undecorated window is NOT treated
// as a true fullscreen surface by the compositor, which lets other windows render
// on top. Returns an empty monitorRects map (Flutter break UI on active monitor only).
static FlValue* enter_break(GtkApplication* app) {
  GdkDisplay* display = gdk_display_get_default();
  GdkScreen* screen = gdk_display_get_default_screen(display);
  GdkSeat* seat = gdk_display_get_default_seat(display);
  GdkDevice* pointer = gdk_seat_get_pointer(seat);
  gint x, y;
  gdk_device_get_position(pointer, nullptr, &x, &y);
  GdkMonitor* active_monitor = gdk_display_get_monitor_at_point(display, x, y);

  int num_monitors = gdk_display_get_n_monitors(display);
  int active_monitor_idx = 0;
  for (int i = 0; i < num_monitors; i++) {
    GdkMonitor* monitor = gdk_display_get_monitor(display, i);
    if (monitor == active_monitor) {
      active_monitor_idx = i;
      break;
    }
  }

  // Snapshot the original window state only on the first entry of a break so a
  // re-trigger (postpone/idle) doesn't overwrite it with the mid-break state.
  if (!g_break_active && g_main_window != nullptr) {
    g_break_active = true;

    GtkWidget* main_widget = GTK_WIDGET(g_main_window);
    bool visible = gtk_widget_get_visible(main_widget);
    bool minimized = (g_main_window_state & GDK_WINDOW_STATE_ICONIFIED) != 0;
    bool maximized = (g_main_window_state & GDK_WINDOW_STATE_MAXIMIZED) != 0;

    g_restore_to_background = (!visible) || minimized;
    g_was_maximized = maximized;
    g_have_saved_bounds = false;
    if (visible && !minimized && !maximized) {
      gtk_window_get_position(g_main_window, &g_saved_x, &g_saved_y);
      gtk_window_get_size(g_main_window, &g_saved_w, &g_saved_h);
      g_have_saved_bounds = true;
    }
  }

  // Force the main window up onto the active monitor and fullscreen it so the
  // Flutter break overlay renders there as a true fullscreen surface.
  if (g_main_window != nullptr) {
    gtk_widget_show(GTK_WIDGET(g_main_window));
    gtk_window_deiconify(g_main_window);
    gtk_window_present(g_main_window);
    while (gtk_events_pending()) {
      gtk_main_iteration();
    }

    GdkRectangle active_geom;
    gdk_monitor_get_geometry(active_monitor, &active_geom);
    gtk_window_move(g_main_window, active_geom.x, active_geom.y);
    gtk_window_set_keep_above(g_main_window, TRUE);
    gtk_window_fullscreen_on_monitor(g_main_window, screen, active_monitor_idx);
    gtk_window_present(g_main_window);
  }

  // If blocker windows are already created (e.g. re-entry after postpone),
  // just bring them to the front without recreating them.
  if (!blocker_windows.empty()) {
    for (GtkWidget* window : blocker_windows) {
      if (GTK_IS_WINDOW(window)) {
        gtk_window_present(GTK_WINDOW(window));
      }
    }
  } else {
    // Create a solid black always-on-top blocker window for every non-active monitor
    // so no other content is visible during the break.
    for (int i = 0; i < num_monitors; i++) {
      if (i == active_monitor_idx) continue;

      GdkMonitor* monitor = gdk_display_get_monitor(display, i);

      GtkWidget* window = gtk_application_window_new(app);
      gtk_window_set_title(GTK_WINDOW(window), "BlinkKind - Take a Break");
      gtk_window_set_keep_above(GTK_WINDOW(window), TRUE);
      gtk_window_set_decorated(GTK_WINDOW(window), FALSE);
      gtk_window_set_skip_taskbar_hint(GTK_WINDOW(window), TRUE);
      gtk_window_set_skip_pager_hint(GTK_WINDOW(window), TRUE);

      GtkCssProvider* provider = gtk_css_provider_new();
      gtk_css_provider_load_from_data(provider, "window { background-color: #000000; }", -1, nullptr);
      GtkStyleContext* style_ctx = gtk_widget_get_style_context(window);
      gtk_style_context_add_provider(style_ctx, GTK_STYLE_PROVIDER(provider),
                                     GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
      g_object_unref(provider);

      GdkRectangle geom;
      gdk_monitor_get_geometry(monitor, &geom);
      gtk_window_move(GTK_WINDOW(window), geom.x, geom.y);
      gtk_window_fullscreen_on_monitor(GTK_WINDOW(window), screen, i);

      gtk_widget_show_all(window);
      blocker_windows.push_back(window);
    }
  }

  // Return empty monitorRects — Flutter break UI renders on the active monitor only.
  g_autoptr(FlValue) result = fl_value_new_map();
  g_autoptr(FlValue) monitor_rects = fl_value_new_list();
  fl_value_set_string_take(result, "monitorRects", fl_value_ref(monitor_rects));
  return fl_value_ref(result);
}

static void on_dbus_signal(GDBusConnection* connection,
                           const gchar* sender_name,
                           const gchar* object_path,
                           const gchar* interface_name,
                           const gchar* signal_name,
                           GVariant* parameters,
                           gpointer user_data) {
  (void)connection;
  (void)sender_name;
  (void)object_path;
  (void)interface_name;
  (void)user_data;

  if (g_lock_channel == nullptr) return;

  if (g_strcmp0(signal_name, "ActiveChanged") == 0) {
    gboolean active = FALSE;
    g_variant_get(parameters, "(b)", &active);
    if (active) {
      fl_method_channel_invoke_method(g_lock_channel, "lock", nullptr, nullptr, nullptr, nullptr);
    } else {
      fl_method_channel_invoke_method(g_lock_channel, "unlock", nullptr, nullptr, nullptr, nullptr);
    }
  }
}

static void on_logind_signal(GDBusConnection* connection,
                             const gchar* sender_name,
                             const gchar* object_path,
                             const gchar* interface_name,
                             const gchar* signal_name,
                             GVariant* parameters,
                             gpointer user_data) {
  (void)connection;
  (void)sender_name;
  (void)object_path;
  (void)interface_name;
  (void)parameters;
  (void)user_data;

  if (g_lock_channel == nullptr) return;

  if (g_strcmp0(signal_name, "Lock") == 0) {
    fl_method_channel_invoke_method(g_lock_channel, "lock", nullptr, nullptr, nullptr, nullptr);
  } else if (g_strcmp0(signal_name, "Unlock") == 0) {
    fl_method_channel_invoke_method(g_lock_channel, "unlock", nullptr, nullptr, nullptr, nullptr);
  }
}

static void setup_dbus_listeners() {
  g_autoptr(GError) error = nullptr;
  g_dbus_conn = g_bus_get_sync(G_BUS_TYPE_SESSION, nullptr, &error);
  if (error != nullptr) {
    g_warning("Failed to connect to DBus session bus: %s", error->message);
    return;
  }
  g_object_ref(g_dbus_conn); // Ensure it is kept alive

  // Subscribe to GNOME ScreenSaver ActiveChanged
  g_dbus_connection_signal_subscribe(
      g_dbus_conn,
      nullptr,
      "org.gnome.ScreenSaver",
      "ActiveChanged",
      "/org/gnome/ScreenSaver",
      nullptr,
      G_DBUS_SIGNAL_FLAGS_NONE,
      on_dbus_signal,
      nullptr,
      nullptr
  );

  // Subscribe to KDE / freedesktop ScreenSaver ActiveChanged
  g_dbus_connection_signal_subscribe(
      g_dbus_conn,
      nullptr,
      "org.freedesktop.ScreenSaver",
      "ActiveChanged",
      "/org/freedesktop/ScreenSaver",
      nullptr,
      G_DBUS_SIGNAL_FLAGS_NONE,
      on_dbus_signal,
      nullptr,
      nullptr
  );

  // Subscribe to Cinnamon ScreenSaver ActiveChanged
  g_dbus_connection_signal_subscribe(
      g_dbus_conn,
      nullptr,
      "org.cinnamon.ScreenSaver",
      "ActiveChanged",
      "/org/cinnamon/ScreenSaver",
      nullptr,
      G_DBUS_SIGNAL_FLAGS_NONE,
      on_dbus_signal,
      nullptr,
      nullptr
  );

  // Subscribe to systemd login session Lock
  g_dbus_connection_signal_subscribe(
      g_dbus_conn,
      "org.freedesktop.login1",
      "org.freedesktop.login1.Session",
      "Lock",
      nullptr,
      nullptr,
      G_DBUS_SIGNAL_FLAGS_NONE,
      on_logind_signal,
      nullptr,
      nullptr
  );

  // Subscribe to systemd login session Unlock
  g_dbus_connection_signal_subscribe(
      g_dbus_conn,
      "org.freedesktop.login1",
      "org.freedesktop.login1.Session",
      "Unlock",
      nullptr,
      nullptr,
      G_DBUS_SIGNAL_FLAGS_NONE,
      on_logind_signal,
      nullptr,
      nullptr
  );
}

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView *view)
{
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);

  GList* windows = gtk_application_get_windows(GTK_APPLICATION(application));
  if (windows != nullptr) {
    GtkWindow* window = GTK_WINDOW(windows->data);
    gtk_widget_show(GTK_WIDGET(window));
    gtk_window_deiconify(window);
    gtk_window_present(window);
    return;
  }

  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Request dark theme decorations for consistent dark styling
  g_object_set(gtk_settings_get_default(),
               "gtk-application-prefer-dark-theme", TRUE,
               NULL);

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "BlinkKind: Eye Break Timer");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "BlinkKind: Eye Break Timer");
  }

  gtk_window_set_default_size(window, 1280, 720);

  // Enable RGBA visual for window transparency
  GdkScreen *window_screen = gtk_window_get_screen(window);
  GdkVisual *visual = gdk_screen_get_rgba_visual(window_screen);
  if (visual != nullptr) {
    gtk_widget_set_visual(GTK_WIDGET(window), visual);
  }
  gtk_widget_set_app_paintable(GTK_WIDGET(window), TRUE);

  // Keep a reference to the main window and track its state so the break overlay
  // can transform and restore it from the native side.
  g_main_window = window;
  g_signal_connect(window, "window-state-event",
                   G_CALLBACK(on_main_window_state_event), nullptr);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  GdkRGBA background_color;
  // Background defaults to black, override it here if necessary, e.g. #00000000 for transparent.
  gdk_rgba_parse(&background_color, "#00000000");
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  // Show the window when Flutter renders.
  // Requires the view to be realized so we can start rendering.
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb), self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  FlEngine* engine = fl_view_get_engine(view);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(engine),
      "blinkkind/break_overlay",
      FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      channel,
      [](FlMethodChannel* channel, FlMethodCall* method_call, gpointer user_data) {
        const gchar* method = fl_method_call_get_name(method_call);
        MyApplication* self = MY_APPLICATION(user_data);

        if (g_strcmp0(method, "enterBreak") == 0) {
          g_autoptr(FlValue) result = enter_break(GTK_APPLICATION(self));
          fl_method_call_respond_success(method_call, result, nullptr);
        } else if (g_strcmp0(method, "enterWarning") == 0) {
          enter_warning(GTK_APPLICATION(self));
          fl_method_call_respond_success(method_call, nullptr, nullptr);
        } else if (g_strcmp0(method, "exitBreak") == 0) {
          exit_break();
          fl_method_call_respond_success(method_call, nullptr, nullptr);
        } else if (g_strcmp0(method, "setPiPMode") == 0) {
          bool is_pip = false;
          FlValue* args = fl_method_call_get_args(method_call);
          if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_BOOL) {
            is_pip = fl_value_get_bool(args);
          }
          if (is_pip) {
            gtk_window_unmaximize(g_main_window);
            gtk_window_set_decorated(g_main_window, FALSE);
            gtk_window_set_keep_above(g_main_window, TRUE);
            gtk_window_set_type_hint(g_main_window, GDK_WINDOW_TYPE_HINT_DOCK);
            gtk_window_resize(g_main_window, 150, 150);
          } else {
            gtk_window_set_type_hint(g_main_window, GDK_WINDOW_TYPE_HINT_NORMAL);
            gtk_window_set_decorated(g_main_window, TRUE);
            gtk_window_set_keep_above(g_main_window, FALSE);
            gtk_window_resize(g_main_window, 1280, 720);
          }
          fl_method_call_respond_success(method_call, nullptr, nullptr);
        } else {
          fl_method_call_respond_not_implemented(method_call, nullptr);
        }
      },
      self,
      nullptr);

  g_lock_channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(engine),
      "blinkkind/system_lock",
      FL_METHOD_CODEC(codec));
  g_object_ref(g_lock_channel);

  setup_dbus_listeners();

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application, gchar*** arguments, int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
     g_warning("Failed to register: %s", error->message);
     *exit_status = 1;
     return TRUE;
  }

  if (g_application_get_is_remote(application)) {
     g_application_activate(application);
     *exit_status = 0;
     return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  //MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  //MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.
  destroy_blocker_windows();

  if (g_lock_channel != nullptr) {
    g_object_unref(g_lock_channel);
    g_lock_channel = nullptr;
  }
  if (g_dbus_conn != nullptr) {
    g_object_unref(g_dbus_conn);
    g_dbus_conn = nullptr;
  }

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line = my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID,
                                     "flags", G_APPLICATION_DEFAULT_FLAGS,
                                     nullptr));
}
