# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Soundscapes & Binaural Beats:** Enjoy seamless, gapless loops of Brown Noise and Binaural Beats with a dedicated volume slider integrated directly into the dashboard.
- **End-of-Day AI Summaries:** Receive an automated, AI-generated summary at the end of your workday (5 PM or end of configured hours) celebrating your focus cycles, breaks taken, and hydration levels.

### Fixed
- **Notification Overlap:** Fixed an issue where app notifications (SnackBars) overlapped the floating navigation bar. All non-critical notifications now consistently auto-hide in exactly 3 seconds without requiring manual dismissal.
- **System Tray Sync:** Fixed the Linux system tray menu so that the "Mute" / "Unmute" audio options instantly synchronize with the app's internal state.

## [1.3.1] - 2026-07-12

### Added
- **Media Auto-Pause Filter:** Added explicit settings to allow the user to select what type of media should auto-pause the timer (All media, Music only, or Video only).
- **RPM & DEB Packaging Automation:** Enhanced `package_linux.sh` to properly install optional runtime dependencies (`playerctl`, `pulseaudio-utils`) via `lib_resolver.sh`, and added a new `-h` (help) menu and `-i` flag explanation.

### Changed
- **Linux Media Detection Layering:** Integrated `playerctl` as a secondary fallback to `pactl` to robustly detect active media (like web browser YouTube playback) that might not be correctly exposed as un-corked sinks.

### Fixed
- **Strict Mode Settings UI Bug:** Fixed an issue in `settings_page.dart` where choosing "Strict Mode" unintentionally hid all global background and cosmetic settings (like media pausing and visualizer styles).
- **RPM Changelog Formatting:** Resolved strict date/version formatting errors in the auto-generated `.spec` file that caused `rpmbuild` to fail on Fedora.

## [1.3.0] - 2026-07-11

### Added
- **AI-Driven Smart-Break Schedule:** Dynamically generates a customized focus/break schedule using AI (Gemini/OpenAI/Groq) based on your current task context and fatigue levels.
- **Auto-Scaling Cycle Limits:** Automatically adjusts auto-run cycle limits when adopting an AI schedule to match the planned workflow.
- **Dynamic Fluid Mesh Background:** Added a stunning, animated, full-screen fluid mesh background to the dashboard.
- **Glassmorphic Floating Navigation Bar:** Upgraded the main navigation bar to a sleek, frosted glassmorphic design with snappy `AnimatedSize` transitions.
- **Live Eye Strain Risk Score:** Real-time calculation and dashboard display of your eye strain risk based on historical break compliance and active session length.
- **Weekly Health Report & Break Debt:** Track and visualize your weekly eye health metrics, break debt (capped at 7 minutes), and long-term focus trends.
- **Device Validation Mode:** Added a dedicated screen in Settings to test and validate local notification, background execution, and overlay permissions.
- **Full Data Backup & Restore:** Export and import all settings, histories, and session logs in a single unified backup file.
- **Activity Profiles:** Robust activity profile selection for different working environments (e.g., deep focus, meetings, reading).
- **Orbiting Particle Trail:** Added a weaving comet/particle trail effect that orbits the active timer ring for a premium visual feel.

### Changed
- **Adaptive Break Scheduling:** Renamed existing adaptive scheduling toggles and integrated them directly with the new AI Smart Schedule logic.
- **History Chart Scaling:** The history chart now accurately scales the focus time target to correctly track current work duration settings instead of historical averages.
- **Natural Break Credit:** Natural breaks are now credited towards daily focus and break counts, optimizing the accuracy of break debt calculations.
- **Page Transitions:** Upgraded full app navigation to use smooth `FadeUpwards` page transitions.

### Fixed
- **Fedora Sentry-Native Build:** Fixed `sentry-native` compilation failures on Fedora caused by spaces in the build path by completely removing `--version-script` and ensuring the patch runs before `flutter pub get`.
- **Timer Media Pause Bug:** Prevented Telegram/Discord false positives on Linux from pausing the timer, and resolved UI state desync when manually skipping phases.
- **Startup Crash:** Resolved a startup crash caused by `initState` attempting to check schedules outside configured work hours.
- **Glassmorphic Navbar Constraints:** Fixed the settings button block size and `BackdropFilter` constraints within the floating nav bar.

## [1.2.0] - 2026-07-02

### Added
- **Native Android Picture-in-Picture (Mini-Mode):** Mini-Mode on Android now uses the OS-native Picture-in-Picture window (`enterPictureInPictureMode`) instead of a resized in-app window, so the compact timer floats over other apps — including fullscreen video and games. Enter/exit and expand/close via the system PiP controls stay in sync with the app, and the PiP button appears only on devices that support it.
- **Water Break Reminders (Android & Linux):** New opt-in hydration reminders with a daily goal expressed in **glasses *and* volume** (enter glasses; millilitres shown via a configurable glass size). Reminders are paced by spreading the goal evenly across your active-hours window and fire only while the timer is running.
- **Water Intake Tracking:** A "Water today" card on the home screen (shown when water reminders are enabled) tracks glasses consumed against your goal with live `X / goal glasses · Y ml`, a button to log a glass and one to undo, a goal-met celebration state, and an automatic daily reset.
- **"Log a glass" notification action:** Record a glass of water straight from the reminder notification without opening the app. On Android this works whether the app is foregrounded or fully killed (handled in a background isolate); on Linux it is delivered through the notification daemon and captured over D-Bus. The home-screen counter updates on resume.
- **Water Intake History & Insights:** Hydration history is now fully integrated into the History & Insights screen. Displays compliance cards, goal-met details, logged entries, and a hydration metric on the interactive activity chart. CSV and JSON exports also include water consumption logs.
- **Max Consecutive Postpones Limit:** Added a setting to restrict consecutive postpones (No Limit, 1, 2, 3, 5). When the limit is reached, the snooze button is hidden/blocked on the Break Screen, Desktop Controls (Linux D-Bus/Tray), and Android notification actions, forcing the user to take a break.
- **Hydration Undo Action:** Added an undo button/tooltip on the home screen card, and a SnackBar confirmation with an "Undo" action when a glass is logged from a notification, to easily correct mistakes.
- **Smarter Hydration Pacing:** Reminders are automatically skipped if the user is ahead of the daily goal pace.
- **Darwin Notification Categories:** Registered notification categories for iOS and macOS water reminders to support logging actions on Apple devices.
- **Hydration Translations:** Fully localized all new water reminders and tracking strings into Spanish (`es`) and Hindi (`hi`).

### Changed
- **Removed the manual "Auto-Postpone Apps" field:** Dropped the technical per-app package/window-class list (which was X11-only on Linux and silently did nothing on Wayland). The non-technical smart triggers remain — automatic game/video detection, camera/mic auto-postpone, system-idle pause, and Do-Not-Disturb postpone.

### Fixed
- **Android wellness reminders not firing:** Reworked wellness reminder scheduling to be anchored to a wall-clock session start and pre-scheduled across the whole active-hours horizon, so the cadence survives work/break phase changes. Previously a cadence longer than a single work phase (e.g. 30-minute reminders with 20-minute work phases) scheduled zero reminders.
- **Android build under the Kotlin 2.2 toolchain:** Restored the release build by raising the Kotlin `languageVersion`/`apiVersion` for sub-1.9 modules and fixing a native `MainActivity` handler regression.
- **Settings Layout Polish:** Adjusted the category header border radius to match the cards for a clean, nested visual theme.
- **GNOME Focus Mode Note:** Removed the obsolete Ubuntu/GNOME DND whitelisting note as support works out of the box.

## [1.1.0] - 2026-07-01

### Added
- **Interactive Linux Mini-Mode (PiP):** Added a compact desktop timer mode with live circular progress and quick controls so the timer can stay visible without the full dashboard.
- **System Do-Not-Disturb Integration:** Added Android and Linux GNOME focus/DND detection so timer and wellness notifications respect OS quiet modes.
- **Background Wellness Scheduling:** Added native scheduling for periodic hydration, posture, stretch, and blink nudges to keep wellness reminders reliable in the background.
- **Opt-In Sentry Reporting:** Added user-controlled crash/error reporting with settings integration and notification health checks.
- **OEM Battery Restriction Detection:** Added Android battery optimization awareness to help users identify settings that may block background reminders.

### Changed
- **Linux Dependency Resolver:** Added libcurl checks to the desktop dependency resolver for Sentry-enabled builds.
- **Linux PiP Window Behavior:** Moved PiP sizing/top-layer handling into native GTK/Wayland-aware window code with custom MethodChannel support.

### Fixed
- **Wayland PiP Sizing and Placement:** Fixed Linux PiP mode expanding to fill the parent window, staying trapped inside parent bounds, or failing to apply top-layer window hints on Wayland.
- **PiP Layout Clipping:** Fixed circular progress indicator clipping inside the compact desktop timer.
- **GTK Window Transparency:** Applied RGBA visuals for transparent Linux desktop window backgrounds.
- **Notification Cadence Reliability:** Fixed wellness reminder cadence issues discovered while wiring background scheduling and Sentry checks.
- **Flutter Analyze and Native Compile Errors:** Fixed analyzer parameter errors and native Linux compiler regressions from the PiP window integration.

## [1.0.9] - 2026-06-30

### Added
- **Continuous Integration (CI):** Added `.github/workflows/ci.yml` for automated `flutter analyze` and `flutter test` checks on push and PR.
- **Accessibility / Reduced Motion:** Added a "Reduced Motion" toggle under "Theme & Appearance". When enabled, disables the pulsing eye mascot, radial background glow, and full-screen flashing phase transitions for users sensitive to motion.
- **Android Home-Screen Widget Redesign:** Transformed the Android widget into a sleek, minimal side-by-side card style. Uses a smaller 64dp progress ring, modern `sans-serif-medium` typography, and adjusted button padding for a premium look on the launcher.

### Changed
- **Linux Tray Icon Rendering Optimization:** Throttled the desktop tray icon rendering loop, using state comparisons to only write new temporary icon files to disk when the timer state actually changes, dramatically reducing disk I/O and CPU usage on Linux.
- **Flutter 3.27 Compatibility:** Resolved over 20 deprecation warnings in the onboarding screens by migrating `.withOpacity()` to `.withValues(alpha: ...)`.

### Fixed
- **System Accent Color Dashboard Glow:** Fixed a bug where enabling the system accent color would render the dashboard background gradient as dull grey. The custom hex background generator now uses significantly higher saturation (65%) and lightness for a vibrant, colored gradient.
- **Settings Serialization Bug:** Restored missing `reducedMotionEnabled` parameters in `SettingsPage` constructor and `TimerSettings.fromJson`, resolving compiler errors and CI failures.

## [1.0.8] - 2026-06-29

### Added
- **Pulsing eye mascot scaling on blink nudge:** Added a scaling pulse transition and a radial glowing iris bloom background behind the dashboard's eye mascot when a background blink notification triggers.
- **Animated sun/moon theme switcher:** Replaced the standard dark mode switch in Settings with a highly responsive, custom sliding sun/moon switch featuring rotation animations and bouncy transitions.

## [1.0.7] - 2026-06-29

### Added
- **Interactive Animated Onboarding:** Replaced static onboarding list with a high-fidelity vector-animated explainer slideshow outlining the 20-20-20 rule (custom animations of screen timers, depth-target perspective transitions, and a relaxing blinking eye mascot).
- **Responsive Screen-Centered Break Progress Ring:** Enclosed the break screen overlays in a large, thin, and responsive countdown progress ring that dynamically scales to fit both desktop and mobile screens perfectly.

### Changed
- **Glassmorphic Settings Page Cards:** Sectioned the settings list into distinct, visually structured glassmorphic cards with colored chip headers, utilizing Material Card backings to prevent ListTile rendering warnings and ensure full test suite compliance.

## [1.0.6] - 2026-06-29

### Added
- **Startup notifications for minimized runs:** Added a silent, non-intrusive system toast notification on boot when the app starts minimized in the tray, confirming active schedule status.

### Fixed
- **GNOME/Linux duplicate launcher icons:** Removed the duplicate `.desktop` installation files to prevent duplicate launcher icons appearing in the GNOME app grid.
- **Shutdown zombie process leaks:** Added explicit process termination (`exit(0)`) and background loop disposal (`dbus-monitor` child process teardown) when exiting via system tray to prevent zombie background processes from sending notifications after exit.
- **Native GTK window decorations on Linux:** Restored standard title bars and window control buttons (close/minimize/maximize) on Linux, requesting native GTK dark theme preference so window borders match the application theme automatically.
- **Settings tray click focus:** Restored and focused the main application window automatically before triggering the settings transition from the tray menu.
- **Blink notification double-posting:** Implemented a static 5-second rate-limiting guard to eliminate overlapping or simultaneous duplicate notifications.
- **Timer progress ring blur box artifacts:** Replaced the `MaskFilter.blur` halo on the glowing tip dot with a native `RadialGradient` shader, resolving a Skia/Impeller GPU caching bug that drew thin square outline borders.
- **Eye mascot size & geometry on Dashboard Clock:** Scaled up the central eye mascot size and adjusted its bezier parameters to make it naturally round, open, and clear, rather than sleepy or flat.
- **Linux packaging process lock protection:** Packaging and installation script now automatically kills any running `eye_care_timer` or `blinkkind` processes before executing the package upgrade to prevent file-lock conflicts.
- **Default state preservation:** Removed the interactive user-data wipe prompt from the installation script, defaulting to preserving settings and history unless explicitly requested with the `-c` or `--clear-state` flag.

## [1.0.5] - 2026-06-28

### Added
- **Redesigned Minimal Neon Timer Ring:** Switched progress arc to a multi-layered neon glow with SweepGradient and bloom filters. Removed round stroke caps to resolve orange overlap artifacts at the 12 o'clock position (near 100% completion), replacing with a clean origin point. Added a frosted glass inner dial.
- **Animated Eye Mascot:** Integrated a vector-based blinking eye mascot into the center of the timer dial. The mascot blinks naturally every few seconds, blinks rapidly on active blink nudges, and triple-blinks on phase transitions.
- **Breathing Break Glow & Phase Transition Flash:** Added a pulsing radial glow behind the break screen. Implemented a full-screen flash transition (matching the theme color) when switching between work and break phases.
- **Confetti Milestone Celebrations:** Added a physics-based particle confetti burst when completing daily goals or meeting session milestones (5, 10, 25, 50).

### Fixed
- **Hiding OS Title Bar on Linux:** Configured hidden window decoration title bars for consistent dark theming. Moved window dragging region (`DragToMoveArea`) exclusively to the AppBar title text to avoid blocking hit-test events on action buttons.
- **SnackBar Action Button Visibility:** Styled action buttons globally in SnackBarThemeData to ensure the "OK" button is visible and tappable.
- **Widget Test Stability:** Bypassed repeating animations and active timers under `FLUTTER_TEST` environments to resolve pending timer leaks in tests.

## [1.0.4] - 2026-06-27

### Fixed
- **Linux desktop icon not appearing after install (GNOME Wayland):** On GNOME Wayland, the shell identifies running apps by their GTK application ID (`com.jatin.eyecaretimer`) and looks for a matching `com.jatin.eyecaretimer.desktop` file to resolve the icon. Previously only `blinkkind.desktop` was installed, causing GNOME to fall back to a generic gear icon in the dock and launcher. Both `com.jatin.eyecaretimer.desktop` and `blinkkind.desktop` are now installed for full compatibility.
- **Icon invisible with custom icon themes (e.g. WhiteSur-light):** The app icon was only installed to `/usr/share/pixmaps/`, which custom GTK icon themes do not search. Icon is now also installed to `/usr/share/icons/hicolor/128x128/apps/` (the standard fallback hierarchy) and referenced via absolute path in the desktop entry, bypassing icon theme cache issues entirely.
- **Desktop entry not visible in app launcher after install:** `update-desktop-database` and `gtk-update-icon-cache` are now called automatically in the RPM `%post` scriptlet and after DEB/RPM install in `package_linux.sh`, so the launcher entry appears immediately without requiring a logout or reboot.
- **SELinux file context on Fedora/RHEL:** Installed files now get `restorecon` applied post-install to ensure correct SELinux labels so GNOME Shell can execute the binary.
- **GNOME app-picker cache stale after install:** `gsettings reset org.gnome.shell app-picker-layout` is now called post-install to clear the cached app grid so new entries appear without a logout.

## [1.0.3] - 2026-06-27

### Added
- **Color-coded gradient timer ring:** The circular progress arc dynamically shifts from a calming Emerald/Mint green → Amber/Yellow (≤ 25% remaining) → Orange/Coral (≤ 10% remaining) during work phases, giving a passive urgency signal without interrupting focus. The focus-mode background breathing glow synchronises its colour to match the active ring state.

### Fixed
- **Blink notification burst (AI path):** Resolved a bug where 3–4 blink reminder notifications would fire simultaneously after several minutes of work. Async AI-fetched message futures attached via `.then()` were only checking whether the timer was running, but not the cadence-bucket dedup guard. If the AI provider was slow and the response resolved after the next cadence had started, all pending callbacks fired at once. Fixed by introducing a `postNotification()` closure that captures the current bucket at trigger time and re-verifies the dedup guard before posting, regardless of when the async response arrives.
- **Linux notification sound not playing on first install:** Corrected `soundEnabled` default to `true` in both `TimerSettings` and `PreferencesService` so in-app chimes are active out of the box on new/reset installations. Resolved Linux playback fallback chain to use `pw-play` → `paplay` → `aplay` so audio works across PipeWire and PulseAudio systems.

### Changed
- **SnackBar quick-dismiss:** All in-app `SnackBar` toasts now include an **OK** action button so the user can dismiss them immediately rather than waiting for the 4-second auto-hide.
- **Linux packaging `--reinstall` flag:** `tool/package_linux.sh` now accepts `-R` / `--reinstall` which removes the previously installed `blinkkind` package before installing the freshly built one, enabling clean re-installation without manual `dnf remove` / `apt remove`.


## [1.0.2] - 2026-06-27

### Added
- **Smooth theme transitions:** Configured `MaterialApp` with explicitly defined `themeAnimationDuration` (200ms) and `themeAnimationCurve` (easeInOut) to cross-fade UI styles when toggling between light and dark modes instead of instantly snapping.
- **Custom accent color live preview:** Added an immediate `onChanged` listener to the hex code TextFormField so color changes take effect as the user types or interacts. Added a mini live-preview widget block inside the color settings card displaying a themed miniature timer ring and action button so the user can verify their custom color palette instantly.
- **Eye Health Score metric:** Rebranded "Break compliance / Compliance Rate" metrics to "Eye Health Score" (breaks completed / breaks scheduled × 100) across all logs, stats grids, and tooltips. Renamed the chart's compliance tab to "Eye Health" with a custom heart icon and configured it to paint a beautiful green/teal gradient bar when the target goal threshold (80%) is met.

## [1.0.1] - 2026-06-27

### Added
- **Chime confirmation on "I blinked!" notification action:** The selected chime sound now plays when the user taps the "I blinked! 👁️" action button on the blink reminder notification. On Android this provides immediate in-app audio feedback when the notification is dismissed from the shade; on Linux the chime fires via the existing D-Bus `ActionInvoked` callback. Both paths respect the user's sound-enabled toggle and chosen chime style.

### Fixed
- Removed an orphaned `_blinkChannel` field reference in `NotificationService.initialize()` that was left over from an older single-channel approach and would have caused a compile-time error.

## [1.0.0] - 2026-06-27

### Added
- **Android & Linux Meeting Auto-Postpone:** Dynamically detects camera usage (using `CameraManager.AvailabilityCallback`) and active microphone/VOIP calls to postpone eye break prompts during meetings. Added toggle in Settings under "Break Screen & Behavior".
- **Modular Wellness Reminders:** Added optional, configurable notifications for posture, stretching, and hydration (intervals from 30 minutes to 2 hours) persisted via `SharedPreferences`.
- **Cross-Distro Linux Dependency Resolver:** Created `lib_resolver.sh` to check for and install missing build/runtime library dependencies on Debian/Ubuntu (`apt`) and Fedora (`dnf`/`yum`) systems.
- **Unified Release Tooling:** 
  - `package_linux.sh` for generating `.deb` and `.rpm` packages with automatic process restarting.
  - `package_android.sh` to compile release APK and App Bundles (`.aab`) with JDK/SDK autodetect.
  - `release.sh` to compile all Linux/Android builds in a single pipeline.

### Fixed
- **Android Kotlin Compiler Error:** Resolved unresolved reference `isMicrophoneActive` by querying `activeRecordingConfigurations` starting from API level 24 (Nougat).
- **Gradle build JDK compatibility:** Added autodetection for compatible Java JDKs (11, 17, 21) in candidate search paths to prevent compilation failure on systems running Java 25.
- **Linux RPM Packaging Fixes:** Fixed absolute build path RPATH issues in plugin shared libraries (`.so`) using `patchelf` to avoid packaging errors.
- **Timer Precision:** Resolved a floating-point precision bug in the countdown timer.
