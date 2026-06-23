# WORKLOG.md

This file tracks the improvement plan for BlinkKind: Eye Break Timer. Update status as work is completed so future sessions can resume without losing context.

## Tasks

### Prioritized Backlog
1. [x] **Break Warning, Fade-to-Black & Postpone Policy**: Implement a pre-break warning notification/overlay, a smooth fade-to-black transition before the break starts, and a configurable skip/postpone settings policy in Flutter and Android.
2. [x] **Smart Idle & Fullscreen App Detection**: Detect when the user is playing a game, watching a video in fullscreen, or actively presenting, and delay/postpone the break overlay to avoid interrupting important tasks.
3. [x] **Linux Desktop Background Support**: Build a Linux background runner with tray controls and launch-at-login support.
4. [x] **Android Reboot Survival**: Ensure the foreground service and exact alarms are correctly re-registered and scheduled upon system reboot.

### Detailed Tasks
- [x] Improve Android rendering smoothness and release readiness.
  - Isolated per-frame countdown updates to the timer dial and warning curtain with `AnimatedBuilder` instead of rebuilding the full home screen.
  - Added repaint boundaries around the static gradient surface and animated timer dial.
  - Reduced desktop-state synchronization from every animation frame to once per displayed second.
  - Added Cupertino-style mobile page transitions, bouncing mobile scroll physics, and explicit Android Impeller enablement.
  - Verified the optimized code with analyzer, tests, and an Android release build before commit.
- [x] Implement user-requested Immersive Focus Mode (tapping the timer dial toggles a clean, fullscreen AMOLED-friendly countdown UI, and supports a customized horizontal landscape desk clock layout).
- [ ] BUG: Timer does not run on real (RTC) time while backgrounded (unified with the foreground-service roadmap item below).
  - Symptom: closing/minimizing the app or locking the screen freezes the work and break countdown at its current value; it only advances when the app is reopened. A 20s break sits at 20s and "runs" on reopen instead of being already over.
  - Diagnosis: resume/launch reconciliation already existed and was correct, but it only ran on `AppLifecycleState.resumed`. The visible countdown is `AnimationController`-driven, which the OS freezes while backgrounded, and there was no native owner advancing the deadline off-screen. The resume path also started a fresh full phase instead of accounting for elapsed time, and only advanced one boundary.
  - [x] Replace the launch/resume reconciliation with one pure, unit-tested `projectPhase` fast-forward (`lib/features/timer/phase_schedule.dart`) that crosses every elapsed work/break boundary, records completed work, advances the streak/auto-run counters, and lands on the phase that should be active now. Both `_restoreInitialSession` and `_syncTimerWithClock` route through it.
  - [x] Clamp backward clock jumps and never report a non-positive remaining for a live phase.
  - [x] Add `TimerSession.toJson`/`fromJson` so the session is a single serializable source of truth across the platform boundary.
  - [x] Add an Android foreground service (`TimerForegroundService`) + exact `AlarmManager` deadline owner (`PhaseDeadlineReceiver`) + `blinkkind/timer_background` MethodChannel bridge + Dart `TimerBackgroundService`, wired into start/pause/resume/cancel/idle/projection.
  - [x] Continue automatic work/break cycles natively while Flutter is suspended, including cycle limits, long-break cadence, delayed-alarm fast-forward, persisted process-death recovery, and stale-alarm rejection.
  - [x] Android 17 emulator baseline: foreground service and exact alarm registered, cross-app overlay launched at the work deadline, rotation survived, configured break auto-dismissed, and the service cleaned up.
  - [x] Fixed minimized/closed Activity overlay suppression: `TimerForegroundService` no longer treats foreground-service process importance as visible UI, and uses explicit `MainActivity` resumed-state tracking before suppressing the native break overlay.
  - [ ] Physical-device validation: background, screen-lock, Doze, app-killed, multi-cycle auto-run, device clock change, and notifications-disabled paths on Pixel/Samsung/Xiaomi-style restrictions. Required to actually close this bug.
  - [x] Native reboot rescheduling and audible reminders for later native-only cycle boundaries. Force-stopped apps cannot restart themselves by Android design.
  - [x] Wire the deadline alarm to launch the immersive break overlay (fullScreenIntent) rather than only a tappable notification (depends on the break-surface UI below).
- [x] Build immersive full-screen break mode (platform implementations complete; hardware validation remains below).
  - [x] Build an Android overlay permission and 10-second manual preview spike before timer integration.
  - [ ] Validate the preview above other apps, system bars, lock screen, rotation, calls, and emergency dismissal on a physical device.
  - [x] Extract timer phase events from the home-screen presentation so break UI can be launched by platform services.
  - [x] Add an Android foreground service and exact-deadline bridge that owns the phase deadline while BlinkKind is backgrounded (built above; still needs device validation and overlay-launch wiring).
  - [x] Add persisted Off, Gentle, and Strict break-screen modes with an emergency press-and-hold exit.
  - [x] Build a responsive black full-screen break surface with countdown, eye exercise, progress, and accessibility semantics.
  - [x] Add pre-break warning, fade-to-black transition, and configurable skip/postpone policy.
  - [ ] Test Android 10-15 plus Pixel, Samsung, and Xiaomi-style background restrictions where devices are available.
  - [x] Enter and restore immersive system UI safely on iOS while BlinkKind is active.
    - Flutter uses manual overlay hiding on iOS and a native `ImmersiveFlutterViewController` hides the status bar/home indicator and defers edge gestures. Chrome is restored on focus exit, disposal, and inactive/background lifecycle states, then reapplied on resume.
    - [ ] Validate status-bar/home-indicator restoration, rotation, app switching, and interruption behavior on a physical iPhone/iPad using a macOS/Xcode build.
  - [x] Add Linux desktop background runtime with tray controls and launch-at-login support (`desktop_integration_service.dart`; tray menu, window-to-tray, autostart).
    - [x] Fixed close-to-tray break takeover: desktop phases now use a wall-clock deadline timer so hidden windows still transition from work to break, and Linux GTK explicitly presents/deiconifies the main window before fullscreening it.
    - [x] Fixed desktop break overlay lifecycle polish: natural break completion now publishes idle state and stops the overlay, the desktop break route is immediately opaque to prevent home-break UI flicker underneath it, and tray-hidden windows return to tray after the break.
  - [x] Add borderless always-on-top desktop break windows with multi-monitor coverage.
    - Break overlay now spans every monitor: `computeDisplaySpan` (`lib/features/timer/display_layout.dart`, pure + unit-tested) unions all displays from `screen_retriever`, one borderless always-on-top window is stretched across the union via `setBounds`, and the break card is replicated/centered on each physical screen so no uncovered display remains.
    - Single-monitor and Wayland sessions keep the original single-monitor fullscreen path (Wayland forbids absolute global window positioning); X11 multi-monitor takes the spanning path.
    - [x] On-device validation completed: Resolved Wayland/X11 multi-monitor spanning issues by implementing native GTK monitor-targeted fullscreening and blocker windows.
  - [x] Add smart idle and existing-fullscreen detection after enforced overlays are stable (screen-off pause + immersion/DND postpone in `TimerForegroundService.kt` on Android, and system-wide idle detection via `system_idle` on Linux/macOS/Windows; "Smart Pause & Postpone" setting).
- [x] Improve notification sound reliability.
  - [x] Migrate Android reminders to a fresh explicitly audible channel.
  - [x] Make foreground sound and system notification sound responsibilities clear.
  - [x] Add a test-reminder action with permission-aware feedback.
- [x] Improve notification reliability.
  - [x] Use exact Android alarms when available with an inexact fallback.
  - [x] Verify pending phase reminders and contain scheduling failures.
  - [x] Surface notification permission, exact-alarm, and battery restriction diagnostics with recovery actions.
- [x] Improve history and insights.
  - [x] Persist session-level completion records.
  - [x] Add monthly totals, goal completion rate, and trend summaries.
  - [x] Add history range controls and clear all recorded activity safely.
- [x] Create worklog and capture the ordered roadmap.
- [x] Rename the product to BlinkKind: Eye Break Timer across runtime UI and platform metadata while preserving technical identifiers.
- [x] Fix current project health.
  - Replaced stale counter widget test with a `BlinkKindApp` smoke test.
  - Resolved analyzer warnings and infos in `lib/main.dart`.
  - Verified with `flutter analyze` and `flutter test`.
- [x] Audit and harden timer behavior.
  - Checked start, pause, resume, cancel, work completion, and break completion paths.
  - Fixed pending transition cancellation and dispose safety around work-to-break handoff.
  - Added focused widget coverage for visible timer controls and cancel-during-transition behavior.
- [x] Refactor app structure.
  - Split the current single-file app into `main.dart`, `app.dart`, and `features/timer/timer_home_page.dart`.
  - Kept the first refactor behavior-preserving and verified it with analyzer/tests.
- [x] Persist user settings.
  - Saved work duration, break duration, theme mode, and color preset.
  - Implemented daily streak persistence with reset when the saved streak date is not today.
- [x] Implement local notifications.
  - Initialized `flutter_local_notifications` through `NotificationService`.
  - Requested Android/iOS/macOS notification permissions.
  - Scheduled and cancelled work-end and break-end reminders on timer start, pause, resume, cancel, and phase transitions.
- [x] Improve background timer behavior.
  - Stored an absolute in-memory phase end timestamp for active timer phases.
  - Reconciled remaining time from the timestamp when the app resumes.
- [x] Improve visual design.
  - Polished timer controls with icons, responsive wrapping, and clearer button hierarchy.
  - Cleaned phase/streak copy, settings card radius, ring contrast, and preset swatches.
- [x] Persist active session restore.
  - Saved active/paused timer phase state with start/end timestamps.
  - Restored running and paused work/break sessions on launch.
  - Advanced expired saved work sessions into the remaining break or idle state.
- [x] Add dedicated settings screen.
  - Moved duration, theme, preset, and streak reset controls into a settings page.
  - Kept the main timer screen focused on timing controls and status.
- [x] Add notification toggle UX.
  - Persisted a notification enabled preference.
  - Added a settings toggle with disabled-state copy.
  - Skipped phase reminder scheduling when notifications are disabled.
- [x] Improve timer state UX.
  - Added state-specific idle, work, paused, and break copy.
  - Added a compact status chip and tightened short-screen layout.
  - Softened irrelevant idle controls.
- [x] Add sound and haptic settings.
  - Persisted haptic and sound feedback preferences.
  - Added feedback controls to the settings page.
  - Phase completion now respects those preferences.
- [x] Add daily goal progress.
  - Persisted a configurable daily break goal.
  - Added goal progress to the timer screen.
  - Added daily goal control to settings.
- [x] Expand product features after the foundation is stable.
  - [x] Streak/history view.
  - [x] Optional sound/haptic settings.
  - [x] Notification permission status in settings.
  - [x] Remove unused countdown dependency.
  - [x] More presets.
  - [x] Branding, app icon, and store metadata cleanup.
    - [x] Android application id, namespace, MainActivity package, and launcher label cleanup.
    - [x] App icon and adaptive icon polish.
    - [x] Store metadata and non-Android platform identity cleanup.

- [x] Add onboarding and permission recovery.
  - [x] First-run explanation for the 20-20-20 rule and notifications.
  - [x] Persist onboarding completion.
  - [x] Add settings action to open system notification settings when blocked.
- [x] Add richer timer modes.
  - [x] Quick timer presets.
  - [x] Long break after a configurable cycle count.
  - [x] Persist timer mode choices.
- [x] Add automatic schedule cycles.
  - [x] Continue from break to work until manually stopped.
  - [x] Add unlimited and configurable per-run cycle limits.
  - [x] Persist automatic-cycle settings and progress across app restarts.

## Completed

- Fixed Linux close-to-tray break takeover. Closing the Linux window hides it to tray, but the work-to-break transition previously depended on a Flutter animation status event that may not fire while hidden; desktop phases now also schedule a wall-clock deadline timer, and the GTK runner explicitly shows, deiconifies, presents, and fullscreen-targets the main window before creating secondary monitor blockers.

- Fixed Android minimized/closed break-overlay takeover. The native foreground service previously used process importance to decide whether BlinkKind was foregrounded, but the foreground service itself keeps the process in a foreground-importance state after the Activity is minimized or gone. `MainActivity` now records actual resumed visibility through `AppVisibility`, and `TimerForegroundService` launches the native overlay when a break starts while the Activity is not resumed.

- Implemented lifecycle-safe iOS immersive focus UI. A dedicated Dart system-UI service selects iOS manual overlay hiding, while `ImmersiveFlutterViewController` controls status-bar visibility, home-indicator auto-hide, and edge-gesture deferral through a MethodChannel. Focus mode restores system chrome when the app becomes inactive, exits focus, or disposes, and reapplies it on resume. `flutter analyze` is clean and all 49 Flutter tests pass; native compilation and physical-device behavior still require macOS/Xcode.

- Added multi-monitor coverage for the desktop break overlay. Previously `setFullScreen(true)` only darkened one monitor, so a second screen stayed usable during a break. Now a pure, unit-tested `computeDisplaySpan` (`lib/features/timer/display_layout.dart`) unions all displays reported by `screen_retriever`, a single borderless always-on-top window is stretched across that union with `setBounds`, and `DesktopBreakOverlay` replicates the break card centered on each monitor. Single-monitor and Wayland sessions fall back to the original fullscreen path (Wayland blocks absolute global positioning), and the window's prior bounds/title-bar are restored when the break ends. Verified with `flutter analyze` (clean) and `flutter test` (49 passing, incl. 7 new geometry tests); Linux native build is blocked locally only by the pre-existing `system_tray` dependency on `libayatana-appindicator3-dev`.

- Improved Android UI smoothness by isolating timer animation rebuilds, containing gradient and dial repaints, reducing desktop synchronization frequency, using lighter mobile transitions and scroll physics, and explicitly enabling Impeller. Confirmed the release pipeline with an Android release APK build.

- Implemented Linux Desktop Background Support: Integrated `system_tray`, `window_manager`, and `launch_at_startup` packages to support hiding the app window to the system tray, autostart configuration, dynamic tray menus (Pause, Resume, Skip, Postpone, Exit), and a full-screen, borderless, always-on-top desktop break overlay widget in Flutter with randomly rotated eye exercises.

- Implemented Smart Idle & Fullscreen App Detection: Added a dynamic system screen-off broadcast receiver to pause the work timer while the screen is off and resume it when it is turned back on. Implemented immersion checks to postpone breaks by the configured duration if the user is playing a game, playing a video, casting/presenting to multiple displays, or has system Do Not Disturb (DND) active when the timer reaches 0. Added a user settings toggle "Smart Pause & Postpone" under Gentle mode, and added full widget test coverage.

- Implemented Android reboot survival: Added a native `BootReceiver` (`BroadcastReceiver`) listening for system boot broadcasts (`BOOT_COMPLETED`, `MY_PACKAGE_REPLACED`, and quickboot actions) to automatically restore `TimerForegroundService` and exact alarms if a timer session was active prior to system shutdown. Exposed internal control methods in `TimerForegroundService` (`handleComplete`, `presentCurrentPhase`, `resumeCurrentPhase`, and `saveState`) to resolve package visibility compilation issues.

- Implemented pre-break warning, fade-to-black screen transition, and configurable Skip/Postpone setting policies. Displays a warning overlay when the work countdown is <= 10s that progressively darkens/fades to black. Supports customizable Skip/Postpone toggles and a dropdown for Postpone duration (1m, 2m, 5m, 10m) in Gentle mode. Fully handles skip and postpone actions across Flutter and Android native foreground services/background overlay controllers.

- Implemented Immersive Focus Mode: tapping the timer dial hides unnecessary UI elements (app bar, settings, daily goal/streak metrics, and phase info), hides system overlays using `SystemUiMode.immersiveSticky`, and defaults to a pure black AMOLED power-saving background. Added a customized landscape layout that presents the timer dial and controls side-by-side. Added corresponding widget tests and confirmed all tests pass.

- Extended the Android deadline owner across automatic work/break cycles with the same cycle-limit and long-break semantics as Flutter, persisted native recovery state, delayed-boundary fast-forward, and stale-alarm protection.

- Reconciled the project knowledgebase after the wall-clock timer, native deadline owner, persisted break-screen modes, and background overlay integration landed. Physical-device validation remains deliberately open.

- Added persisted Off, Gentle, and Strict break overlay mode selections in Settings, refactored timer phase transitions to trigger overlay lifecycle events, and polished the Android native break screen overlay layout with randomly rotated eye exercises, custom styling, and a press-and-hold emergency exit gesture for Strict mode. Also wired the deadline alarm to launch the overlay automatically during background phase transitions.

- Reworked background timing onto a single wall-clock source of truth: a pure, unit-tested `projectPhase` fast-forward that catches up across every elapsed work/break boundary on launch and resume, plus an Android foreground service plus exact-alarm deadline owner and MethodChannel bridge. Dart fixes are tested and the native owner compiles; on-device validation across OEM background restrictions remains.

- Migrated the Android app to Flutter's built-in Kotlin (removed the standalone Kotlin Gradle Plugin and `kotlinOptions`, added a top-level `kotlin {}` block).

- Added Android display-over-other-apps permission handling and a native 10-second black break overlay preview with Settings controls, countdown, and immediate dismissal. Physical-device behavior remains the next validation task.

- Migrated reminders to an explicitly audible alarm-category channel, separated in-app sound copy, and added test-reminder and channel-sound settings actions.

- Added deduplicated completed-session history with 7-day/30-day/all ranges, monthly and goal insights, weekly trend comparison, recent session detail, and confirmed activity clearing.

- Added resilient reminder scheduling with exact-alarm fallback, pending-reminder verification, and Android battery/alarm diagnostics with recovery actions.

- Renamed the product to BlinkKind: Eye Break Timer across app UI, notifications, platform metadata, tests, and documentation.

- Added persisted automatic schedule cycles with unlimited/configurable limits and restart-safe cycle progress.

- Fixed dark-mode home screen Start button contrast and added regression coverage.
- Added quick timer presets and configurable persisted long-break mode.
- Added first-run onboarding and notification permission recovery through Android system settings.
- Cleaned web, iOS, macOS, Linux, and Windows app identity metadata and verified Android and web builds.
- Added custom eye/timer launcher icons across Android, iOS, macOS, Windows, and web, including Android adaptive icon resources.
- Updated Android identity to `com.jatin.eyecaretimer` with the initial launcher label and verified a debug APK build.
- Added shared color presets and expanded the preset list with theme-aware gradients/swatches.
- Removed the unused countdown package from runtime dependencies.
- Added notification permission status in Settings using platform status checks.
- Added a History screen with seven-day break counts, best-day summary, goal streak summary, and reset history action.
- Added daily goal progress with a persisted goal setting.
- Added persisted sound and haptic settings for phase-complete feedback.
- Improved timer state UX with status chip, state-specific copy, and tighter short-screen layout.
- Added persisted notification toggle UX and skipped reminder scheduling when alerts are off.
- Added a dedicated settings screen for timer, appearance, and streak controls.
- Added active session restore for running, paused, and expired timer phases.
- Updated Android build toolchain to Gradle 8.14.3, Android Gradle Plugin 8.11.1, and Kotlin Gradle Plugin 2.2.20.
- Created `WORKLOG.md` with the ordered roadmap.
- Fixed the broken default widget test and current analyzer issues.
- Verified project health with `flutter analyze` and `flutter test`.
- Hardened timer transition handling so cancel/dispose cannot trigger a pending automatic break start.
- Added widget coverage for start, pause, resume, cancel, and cancel-during-transition behavior.
- Refactored the app into focused files without changing behavior.
- Added `shared_preferences` persistence for durations, theme, color preset, and daily streak count.
- Added widget coverage for loading saved duration and streak preferences.
- Added local notification scheduling/cancellation through an injectable `NotificationService`.
- Added widget coverage for notification scheduling and cancellation through a fake service.
- Added lifecycle resume reconciliation so the timer catches up from its phase deadline after backgrounding.
- Polished the timer UI controls, copy, settings card, ring contrast, and color preset sheet.
- Implemented three break visualizer styles (Calm Breathing, Ambient Flow, and Starry Sky) for the desktop break overlay and settings selection.
- Redesigned the history and insights page to feature an animated activity bar chart and range-specific metrics (longest streak, average focus duration, peak hour, etc.).
- Fixed status bar background seaming by setting extendBodyBehindAppBar to true and applying transparent status bar overlay, and resolved contrast issues in dark immersive focus mode by applying a dark theme copy and forcing light status bar icons.
- Prevented showing the fullscreen break overlay on mobile (both native overlay window and Flutter route) when the app is in the foreground, allowing it to behave like a standard Pomodoro break timer interface where the countdown is shown on the home page itself. Configured app lifecycle changes to automatically trigger the native overlay if the user backgrounds the app mid-break.

- Added two new interactive guided break modes (`lib/features/timer/break_guides.dart`):
  - **Eye Exercise Dot Tracker**: an animated glowing dot cycles through 5 eye-muscle exercises (side sweep, vertical sweep, figure-8 lemniscate, zoom pulse, corner diagonals) with instructional labels. Each exercise runs for 8 s and advances automatically for the full break duration.
  - **Box Breathing Guide (4-4-4-4)**: a glowing square whose sides light up progressively during Inhale → Hold → Exhale → Hold phases; color-coded per phase with a per-phase countdown counter in the center.
  - Both guides embedded in `DesktopBreakOverlay` (full-screen, dedicated dark backgrounds) and in `TimerHomePage` portrait layout (inline below the timer dial during in-app breaks).
  - Settings dropdown now exposes "Eye Exercises" and "Box Breathing (4-4-4-4)" alongside the existing Calm Breathing / Ambient Flow / Starry Sky options.
  - Classic card action buttons extracted into a shared `_buildBreakActions()` helper to eliminate duplication between classic and guided layout paths.
  - All 57 tests passing (including new widget tests for the guided break mode animations and transitions).

- Applied **Inter** as the global minimalist typeface across the entire app for a clean, iOS-like feel:
  - Added `google_fonts: ^6.2.1` dependency; set `allowRuntimeFetching = false` in `main.dart` so fonts load instantly from bundled assets with no network dependency.
  - Defined a full 13-role `_buildTextTheme()` in `app.dart`: display sizes use `w200–w300` with tight negative letter-spacing (−1.5 pt at displayLarge, tapering to 0 at body), body/label use `w400–w500` with neutral tracking — the exact combination that gives the crisp, geometric iOS-like typography feel.
  - Applied the theme to both `ThemeData` (light) and `darkTheme` in `MaterialApp`.
  - Removed all wide positive `letterSpacing` overrides (1.0, 1.2, 1.5, 2.0) from `break_guides.dart` and `desktop_break_overlay.dart` that caused the "chunky/funky" look.
  - Switched countdown digit weight from `w700` (bold) to `w300` throughout — Inter's thin tabular figures at display sizes read as premium and minimal.
  - Replaced every raw `TextStyle()` across the UI with `theme.textTheme.X?.copyWith(...)` equivalents: timer dial counter, status badge, focus-mode tap hint (×2), breathing instruction label, hold-to-exit label, history export description, daily goal counter, onboarding feature item titles.
  - All 57 tests passing; `dart analyze lib/` reports no issues.

- Fixed Linux build and runtime crash:
  - Switched to a standalone, native host-linked Flutter SDK instead of the sandboxed Snap SDK to resolve system library conflicts (AppIndicator and GLib mismatch under Ubuntu 24.04).
  - Patched the cached `system_idle_linux` Wayland C protocol headers to use backwards-compatible APIs (`wl_proxy_marshal` / `wl_proxy_destroy` / `wl_proxy_marshal_constructor_versioned`).
  - Enabled dynamic Google Fonts fetching (`allowRuntimeFetching = true` in `main.dart`) to avoid startup font exceptions.
  - Created a Linux packaging script at `tool/package_linux.sh` to package release builds as `.deb` and `.rpm` files natively.
  - Verified successful compilation and built the native `.deb` package at `dist/blinkkind_1.0.0_amd64.deb`.
  - All 57 tests passing; `dart analyze lib/` reports no issues.

- Implemented native GTK monitor-targeted fullscreening for dual/multi-monitor support:
  - Saved a reference to the main GTK window in the native runner.
  - Resolved compiler/compatibility issues by utilizing `gdk_device_get_position` and `gdk_display_get_monitor_at_point` to find the active monitor.
  - Used `gtk_window_fullscreen_on_monitor` to force the main Flutter window onto the active monitor, and spawned native black blocker windows targeting all other monitors.
  - This solves the issue of the break overlay appearing only on the primary display or failing on Wayland/X11 multi-monitor environments.
  - Package built, installed, and verified on-device.

- Resolved window state mapping and multi-monitor flickering:
  - Fixed a race condition on Linux where setBounds and setFullScreen were ignored when transitioning a hidden/minimized window into break overlay mode; mapping (show and restore) is now performed prior to style and bound changes.
  - Guarded window bounds capturing to avoid saving zero or off-screen bounds when the window is hidden or minimized, utilizing a fallback size of 1280x720.
  - Eliminated UI flickering by preventing Dart-side route recreation when the break overlay is already active.
  - Optimized C++ blocker window management to check for active blockers and present them instead of destroying and recreating them on every state sync.
