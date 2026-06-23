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

#include <vector>

static std::vector<GtkWidget*> blocker_windows;
static GtkWindow* main_window = nullptr;

static double get_double_value(FlValue* value) {
  if (value == nullptr) return 0.0;
  FlValueType type = fl_value_get_type(value);
  if (type == FL_VALUE_TYPE_FLOAT) {
    return fl_value_get_float(value);
  } else if (type == FL_VALUE_TYPE_INT) {
    return (double)fl_value_get_int(value);
  }
  return 0.0;
}

static void hide_blocker_windows(bool was_hidden, bool was_minimized,
                                 bool has_saved_bounds, double x, double y, double width, double height,
                                 bool was_maximized) {
  for (GtkWidget* window : blocker_windows) {
    if (GTK_IS_WIDGET(window)) {
      gtk_widget_destroy(window);
    }
  }
  blocker_windows.clear();

  if (main_window != nullptr) {
    if (was_hidden || was_minimized) {
      // 1. Hide the window first to prevent any visual changes or mapping events
      gtk_widget_hide(GTK_WIDGET(main_window));

      // 2. Restore all styles synchronously on the hidden window
      gtk_window_unfullscreen(main_window);
      gtk_window_set_keep_above(main_window, FALSE);
      gtk_window_set_skip_taskbar_hint(main_window, FALSE);
      gtk_window_set_decorated(main_window, TRUE);

      // 3. Restore bounds and maximize state
      if (has_saved_bounds) {
        gtk_window_resize(main_window, (gint)width, (gint)height);
        gtk_window_move(main_window, (gint)x, (gint)y);
      }
      if (was_maximized) {
        gtk_window_maximize(main_window);
      } else {
        gtk_window_unmaximize(main_window);
      }
    } else {
      // Normal restore (visible before break): Exit fullscreen and keep-above first, then present
      gtk_window_unfullscreen(main_window);
      gtk_window_set_keep_above(main_window, FALSE);
      gtk_window_set_skip_taskbar_hint(main_window, FALSE);
      gtk_window_set_decorated(main_window, TRUE);

      // Ensure the window is shown and raised/focused on the screen
      gtk_window_deiconify(main_window);
      gtk_window_present(main_window);
    }
  }
}

static void show_blocker_windows(GtkApplication* app) {
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

  // 1. Force the main Flutter window back from tray-hidden state and
  // onto the active monitor's fullscreen state.
  if (main_window != nullptr) {
    GtkWidget* main_widget = GTK_WIDGET(main_window);
    gtk_widget_show_all(main_widget);
    gtk_window_deiconify(main_window);
    gtk_window_present(main_window);
    while (gtk_events_pending()) {
      gtk_main_iteration();
    }

    GdkRectangle geom;
    gdk_monitor_get_geometry(active_monitor, &geom);
    gtk_window_move(main_window, geom.x, geom.y);
    gtk_window_set_keep_above(main_window, TRUE);
    gtk_window_fullscreen_on_monitor(main_window, screen, active_monitor_idx);
    gtk_window_present(main_window);
  }

  // If blocker windows are already created, don't recreate them to avoid flickering.
  // Just ensure they are on top.
  if (!blocker_windows.empty()) {
    for (GtkWidget* window : blocker_windows) {
      if (GTK_IS_WINDOW(window)) {
        gtk_window_present(GTK_WINDOW(window));
      }
    }
    return;
  }

  // 2. Create native black blocker windows for all other monitors
  for (int i = 0; i < num_monitors; i++) {
    if (i == active_monitor_idx) {
      continue;
    }

    GdkMonitor* monitor = gdk_display_get_monitor(display, i);

    GtkWidget* window = gtk_application_window_new(app);
    gtk_window_set_title(GTK_WINDOW(window), "BlinkKind - Take a Break");
    
    gtk_window_set_keep_above(GTK_WINDOW(window), TRUE);
    gtk_window_set_decorated(GTK_WINDOW(window), FALSE);
    gtk_window_set_skip_taskbar_hint(GTK_WINDOW(window), TRUE);
    gtk_window_set_skip_pager_hint(GTK_WINDOW(window), TRUE);

    GtkCssProvider* provider = gtk_css_provider_new();
    gtk_css_provider_load_from_data(provider, "window { background-color: #000000; }", -1, nullptr);
    GtkStyleContext* context = gtk_widget_get_style_context(window);
    gtk_style_context_add_provider(context, GTK_STYLE_PROVIDER(provider), GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
    g_object_unref(provider);

    GdkRectangle geom;
    gdk_monitor_get_geometry(monitor, &geom);
    gtk_window_move(GTK_WINDOW(window), geom.x, geom.y);
    gtk_window_resize(GTK_WINDOW(window), geom.width, geom.height);

    // Request fullscreen on this specific monitor
    gtk_window_fullscreen_on_monitor(GTK_WINDOW(window), screen, i);

    gtk_widget_show_all(window);
    blocker_windows.push_back(window);
  }
}

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView *view)
{
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));
  main_window = window;

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

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  GdkRGBA background_color;
  // Background defaults to black, override it here if necessary, e.g. #00000000 for transparent.
  gdk_rgba_parse(&background_color, "#000000");
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

        if (g_strcmp0(method, "showBlockers") == 0) {
          show_blocker_windows(GTK_APPLICATION(self));
          fl_method_call_respond_success(method_call, nullptr, nullptr);
        } else if (g_strcmp0(method, "hideBlockers") == 0) {
          FlValue* args = fl_method_call_get_args(method_call);
          bool was_hidden = false;
          bool was_minimized = false;
          bool has_saved_bounds = false;
          double x = 0.0;
          double y = 0.0;
          double width = 0.0;
          double height = 0.0;
          bool was_maximized = false;

          if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
            FlValue* val_hidden = fl_value_lookup_string(args, "wasHidden");
            if (val_hidden != nullptr && fl_value_get_type(val_hidden) == FL_VALUE_TYPE_BOOL) {
              was_hidden = fl_value_get_bool(val_hidden);
            }
            FlValue* val_minimized = fl_value_lookup_string(args, "wasMinimized");
            if (val_minimized != nullptr && fl_value_get_type(val_minimized) == FL_VALUE_TYPE_BOOL) {
              was_minimized = fl_value_get_bool(val_minimized);
            }
            FlValue* val_has_bounds = fl_value_lookup_string(args, "hasSavedBounds");
            if (val_has_bounds != nullptr && fl_value_get_type(val_has_bounds) == FL_VALUE_TYPE_BOOL) {
              has_saved_bounds = fl_value_get_bool(val_has_bounds);
            }
            FlValue* val_x = fl_value_lookup_string(args, "x");
            if (val_x != nullptr) {
              x = get_double_value(val_x);
            }
            FlValue* val_y = fl_value_lookup_string(args, "y");
            if (val_y != nullptr) {
              y = get_double_value(val_y);
            }
            FlValue* val_w = fl_value_lookup_string(args, "width");
            if (val_w != nullptr) {
              width = get_double_value(val_w);
            }
            FlValue* val_h = fl_value_lookup_string(args, "height");
            if (val_h != nullptr) {
              height = get_double_value(val_h);
            }
            FlValue* val_max = fl_value_lookup_string(args, "wasMaximized");
            if (val_max != nullptr && fl_value_get_type(val_max) == FL_VALUE_TYPE_BOOL) {
              was_maximized = fl_value_get_bool(val_max);
            }
          }
          hide_blocker_windows(was_hidden, was_minimized, has_saved_bounds, x, y, width, height, was_maximized);
          fl_method_call_respond_success(method_call, nullptr, nullptr);
        } else {
          fl_method_call_respond_not_implemented(method_call, nullptr);
        }
      },
      self,
      nullptr);

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
  hide_blocker_windows(false, false, false, 0.0, 0.0, 0.0, 0.0, false);

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
                                     "flags", G_APPLICATION_NON_UNIQUE,
                                     nullptr));
}
