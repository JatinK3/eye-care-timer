# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
