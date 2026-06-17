# WORKLOG.md

This file tracks the improvement plan for the Eye Care Timer app. Update status as work is completed so future sessions can resume without losing context.

## Tasks

- [x] Create worklog and capture the ordered roadmap.
- [x] Fix current project health.
  - Replaced stale counter widget test with an `EyeCareTimerApp` smoke test.
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
- [ ] Expand product features after the foundation is stable.
  - Streak/history view.
  - Optional sound/haptic settings.
  - More presets.
  - Branding, app icon, and store metadata cleanup.

## Completed

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
