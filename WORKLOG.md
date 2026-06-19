# WORKLOG.md

This file tracks the improvement plan for BlinkKind: Eye Break Timer. Update status as work is completed so future sessions can resume without losing context.

## Tasks

- [ ] Build immersive full-screen break mode (current priority).
  - [ ] Extract timer phase events from the home-screen presentation so break UI can be launched by platform services.
  - [ ] Add persisted Off, Gentle, and Strict break-screen modes with an emergency press-and-hold exit.
  - [ ] Build a responsive black full-screen break surface with countdown, eye exercise, progress, and accessibility semantics.
  - [ ] Enter and restore immersive system UI safely on Android/iOS while BlinkKind is active.
  - [ ] Add Linux-first desktop background runtime with tray controls and launch-at-login support.
  - [ ] Add borderless always-on-top desktop break windows and validate X11/Wayland behavior.
  - [ ] Cover every connected desktop monitor during enforced breaks.
  - [ ] Add pre-break warning, fade-to-black transition, and configurable skip/postpone policy.
  - [ ] Add smart idle and existing-fullscreen detection after the enforced overlay is stable.
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
