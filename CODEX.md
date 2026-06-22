# CODEX.md

## Project Context

This repository is the Flutter app `BlinkKind: Eye Break Timer`, based on the 20-20-20 rule. The existing Dart package name remains `eyeapptimer` for import stability. The app helps users work for a configurable interval, then take a short eye break. The current direction is a lightweight wellness utility with reliable timer behavior, saved preferences, reminders, daily streak tracking, calm Material 3 UI, and eventual mobile store readiness.

Keep this file updated when architecture, behavior, or roadmap decisions change.


## Project Workflow

- Treat this file as the primary project knowledgebase. Read it at the start of future sessions and update it whenever architecture, behavior, roadmap, workflow, dependencies, or important implementation decisions change.
- Update this file after long implementation sessions, after completing a meaningful feature, or when enough time has passed that the project timeline would otherwise become unclear.
- Keep `WORKLOG.md` as the checklist and completion log. Keep `CODEX.md` as the higher-level source of truth for current architecture, behavior, decisions, and remaining direction.
- Commit after each completed feature or cohesive work unit instead of letting unrelated work accumulate.
- Prefer natural, feature-oriented commit messages. Examples:
  - `Add settings persistence`
  - `Improve timer resume behavior`
  - `Polish timer controls`
  - `Add notification reminders`
- Avoid commit messages that mention internal tooling, generated-by wording, or implementation process notes that do not belong in product history.
- If a feature requires several tightly coupled file changes, keep them in one cohesive commit rather than splitting into commits that leave the project temporarily broken.
- Before committing code changes, run `flutter analyze`; run `flutter test` once after the module and directly related changes are complete, before the feature commit, unless the change is docs-only. Avoid rerunning the full Flutter test suite after every small edit.
- Before every commit, check `git status --short` and make sure only intended files are staged.

## Current Structure

- `lib/main.dart`: App entrypoint only.
- `lib/app.dart`: Top-level `MaterialApp`, theme/preset state, startup loading, persistence coordination, and notification and break-overlay service injection.
- `lib/features/timer/timer_home_page.dart`: Main timer UI, countdown state, phase-event orchestration, lifecycle reconciliation, overlay lifecycle, native deadline-owner synchronization, and notification scheduling hooks.
- `lib/features/timer/phase_schedule.dart`: Pure wall-clock phase projection used to fast-forward restored/backgrounded sessions across every elapsed work and break boundary.
- `lib/features/timer/display_layout.dart`: Pure desktop display-union geometry used to span a break window across multiple monitors and translate each monitor into window-local coordinates.
- `lib/features/timer/desktop_break_overlay.dart`: Desktop break surface that renders once for fullscreen fallback or replicates centered break content across every monitor in a spanning window.
- `lib/models/timer_settings.dart`: Persisted timer settings model and defaults, including color preset, notification, feedback, long-break, automatic-cycle, daily goal, and Off/Gentle/Strict break-screen preferences.
- `lib/theme/color_presets.dart`: Shared preset names, seed colors, swatches, timer gradients, and progress colors.
- `lib/features/settings/settings_page.dart`: Dedicated settings UI for durations, theme, presets, reminder permission recovery, automatic-cycle controls, Android break-overlay permission and preview controls, progress history entry point, and streak reset.
- `lib/features/onboarding/onboarding_page.dart`: First-run 20-20-20 explanation and reminder permission entry point.
- `lib/features/history/history_page.dart`: Range-based daily history, monthly and goal metrics, week-over-week trend, recent completed-session detail, and confirmed activity clearing.
- `lib/models/work_session_record.dart`: Deduplicated completed work-session record with completion time and configured focus duration.
- `lib/models/timer_session.dart`: Serializable active/paused timer session state and automatic-run cycle progress shared by persistence and platform synchronization.
- `lib/services/preferences_service.dart`: `shared_preferences` load/save for onboarding completion, durations, theme mode, color preset, daily streak, daily history, bounded completed-session history, daily goal, notification preference, feedback preferences, automatic-cycle settings, and active timer session.
- `lib/services/notification_service.dart`: `flutter_local_notifications` initialization, permission requests/status checks, system settings recovery hooks, exact-alarm capability checks, battery optimization diagnostics, explicit audible-channel creation, test-reminder support, verified phase reminder scheduling with inexact fallback, and cancellation.
- `lib/services/break_overlay_service.dart`: Android overlay permission, preview, active break display, and dismissal MethodChannel wrapper with safe unsupported-platform behavior.
- `lib/services/desktop_integration_service.dart`: Desktop tray, launch-at-login, window lifecycle, and X11 multi-monitor break-window spanning with restoration of the previous window state.
- `lib/services/timer_background_service.dart`: Dart bridge that sends the active deadline, complete cadence settings, streak, and automatic-run counters to the Android foreground service.
- `android/app/src/main/kotlin/com/jatin/eyecaretimer/BreakOverlayController.kt`: Process-scoped native full-screen break overlay with preview, Gentle/Strict behavior, exercise rotation, countdown, and emergency press-and-hold exit.
- `android/app/src/main/kotlin/com/jatin/eyecaretimer/TimerForegroundService.kt`: Persisted native cadence owner for exact phase deadlines, delayed-boundary fast-forward, automatic cycle limits, long-break cadence, ongoing status, process recovery, and background overlays.
- `android/app/src/main/kotlin/com/jatin/eyecaretimer/PhaseDeadlineReceiver.kt`: Exact-alarm receiver that restores the cadence owner when needed and includes the expected deadline so stale broadcasts are rejected.
- `test/phase_schedule_test.dart`: Unit coverage for multi-boundary wall-clock phase projection and clock-change handling.
- `test/display_layout_test.dart`: Unit coverage for empty, invalid, offset, horizontal, and vertical multi-monitor display geometry.
- `test/timer_session_test.dart`: Timer session platform-serialization coverage.
- `test/widget_test.dart`: Widget smoke, persistence load, timer controls, automatic-cycle restore/limits, break-mode settings, settings/history navigation, notification fake, and transition regression tests.
- `WORKLOG.md`: Ordered roadmap and completion log.

## Current App Behavior

- Default work duration is 20 minutes.
- Default break duration is 20 seconds.
- First run shows onboarding for the 20-20-20 habit and lets the user allow reminders or continue without them.
- Users can change work and break durations from the settings screen while the timer is idle, including quick presets for `20-20-20`, `25 / 5`, and `45 / 5`.
- Start schedules a work-complete notification and begins the countdown.
- Pause stops the animation and cancels the pending phase notification.
- Resume schedules a new phase notification using the remaining time.
- Cancel resets to idle work state and cancels pending notifications.
- Work completion increments the daily streak, saves it into daily history, and automatically starts either the normal break or the configured long break.
- Break completion returns to idle work state by default. When automatic scheduling is enabled, it starts the next work phase until the user cancels or the configured per-run work-cycle limit is reached. A zero limit means unlimited cycles.
- The timer stores an absolute phase deadline and uses the pure `projectPhase` calculation to reconcile every elapsed work/break boundary when the app resumes or restores. It records completed work, advances automatic-cycle counters, and lands on the phase that should be active at the current wall-clock time.
- Active timer sessions are persisted so running and paused work/break phases can restore after app restart.
- Expired restored sessions can advance across multiple phases instead of restarting a full phase after background time has elapsed.
- On Android, an ongoing foreground service mirrors the active cadence and arms each absolute deadline with an exact alarm and inexact fallback. While Flutter is suspended it advances work/break phases, cycle limits, and long-break cadence natively, persists recovery state for process death, fast-forwards delayed alarms, and rejects stale broadcasts. It stops on pause, cancel, and idle.
- Theme mode, color preset, work duration, break duration, long-break settings, automatic-cycle settings and current run progress, daily streak, daily history aggregates, completed-session records, daily goal, notification preference, haptic/sound preferences, and active timer session are persisted.
- Daily streak resets when the saved streak date is not today.
- The main timer shows daily goal progress and a goal-reached state when completed breaks meet the configured goal.
- Settings includes History ranges for 7 days, 30 days, and all active days, plus current-month totals, goal completion rate, best day, weekly trend, recent completed sessions, and confirmed activity clearing.
- Settings shows notification permission, precise-alarm capability, Android battery optimization status, direct reminder-channel sound settings, and a test reminder action. The optional in-app sound toggle is separate from system notification audio.
- On Android, Settings reports display-over-other-apps permission and can launch a native 10-second break-screen preview. Users can persist `Off`, `Gentle`, or `Strict` behavior. Active timer transitions show and dismiss the native overlay, and a background work deadline launches it through the foreground service/alarm path. Gentle mode permits skipping; Strict mode requires a press-and-hold emergency exit.
- Light/dark theme toggle and `Pastel`, `Calm Blue`, `Forest`, `Rose`, `Graphite`, and `Sunrise` presets are available.
- The app theme seed, settings swatches, timer gradients, and timer progress color now come from the same preset source.
- UI now uses state-specific status chips/copy, icon-backed controls, responsive wrapping buttons, a dedicated settings screen, notification and feedback toggle UX, contrast-safe dark-mode primary buttons, calmer text, and tighter card radius.
- The home countdown isolates per-frame work in `AnimatedBuilder` subtrees for the dial and warning curtain. Repaint boundaries keep the static gradient and surrounding controls out of timer repaints, while desktop timer state updates only when the displayed second changes.
- Android explicitly enables Impeller. Android/iOS use Cupertino-style page transitions and bouncing scroll physics for a lighter, consistent mobile interaction feel.
- On desktop, break mode uses a borderless always-on-top window. X11 multi-monitor sessions span the union of all displays and center a break surface on each monitor; single-monitor and Wayland sessions use fullscreen fallback because Wayland does not permit reliable absolute global window positioning.

## Dependencies

Runtime dependencies currently declared:

- `flutter`
- `cupertino_icons`
- `timezone`
- `flutter_local_notifications`
- `shared_preferences`

Dependency cleanup note: the unused `circular_countdown_timer` package was removed because countdown behavior uses Flutter `AnimationController`.

## Platform Notes

Android app identity:

- Application id / namespace: `com.jatin.eyecaretimer`.
- Android launcher label: `BlinkKind: Eye Break Timer`.
- Launcher icons are custom eye/timer branded assets across Android, iOS, macOS, Windows, and web. Android includes adaptive icon resources for API 26+.
- Web, Android, Linux, and Windows use `BlinkKind: Eye Break Timer` in descriptive titles. Constrained app bars and Apple display and executable names use `BlinkKind`.
- MainActivity package path: `android/app/src/main/kotlin/com/jatin/eyecaretimer/MainActivity.kt`.
- The Dart package name, bundle/application id, native package path, method-channel name, Linux/Windows binary identifiers, and repository path retain their existing technical identifiers for compatibility. The Android reminder channel intentionally migrated to `blinkkind_phase_reminders_v2` so devices that created the legacy channel silently receive fresh audible defaults.

Android manifest includes notification-related permissions and receivers:

- `POST_NOTIFICATIONS`
- `RECEIVE_BOOT_COMPLETED`
- `VIBRATE`
- `SCHEDULE_EXACT_ALARM`
- `SYSTEM_ALERT_WINDOW`
- `FOREGROUND_SERVICE`
- `FOREGROUND_SERVICE_SPECIAL_USE`
- `WAKE_LOCK`
- `ScheduledNotificationReceiver`
- `ScheduledNotificationBootReceiver`
- `FlutterLocalNotificationsReceiver`
- `TimerForegroundService`
- `PhaseDeadlineReceiver`

Android reminders use an explicitly audible, vibration-enabled alarm-category channel. Notification scheduling uses `AndroidScheduleMode.exactAllowWhileIdle` when the user grants exact-alarm access and falls back to `inexactAllowWhileIdle` otherwise. Scheduling failures are contained and the pending phase reminder is verified.

Android build toolchain maintenance:

- Gradle wrapper: `8.14.3`.
- Android Gradle Plugin: `8.11.1`.
- Kotlin Gradle Plugin: `2.2.20`.
- `android/gradle.properties` includes Flutter migrator flags for `android.builtInKotlin=false` and `android.newDsl=false`.
- `AndroidManifest.xml` explicitly opts into Flutter's Impeller renderer for Android.

## Current Audit Findings

Last audit date: 2026-06-22.

Commands run after the current implementation:

- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`
- `flutter build apk --release`
- `flutter build web`

Current results:

- `flutter analyze`: passing with no issues.
- `flutter test`: passing, 49 tests.
- `flutter build apk --debug`: passing; generated `build/app/outputs/flutter-apk/app-debug.apk`.
- `flutter build apk --release`: passing with AOT compilation and tree-shaking; generated `build/app/outputs/flutter-apk/app-release.apk` (49.5 MB).
- `flutter build web`: passing; generated `build/web`.
- Android 17 emulator baseline passed for service/alarm registration, cross-app overlay launch at a background work deadline, rotation survival, automatic break dismissal, and service cleanup. This does not replace Android 10-15/OEM physical-device testing.
- Multi-monitor display geometry is covered by seven unit tests. Real X11 multi-monitor, Wayland fallback, and mixed-DPI positioning still require hardware validation; the local Linux build also requires `libayatana-appindicator3-dev` for the existing `system_tray` dependency.

Important git/worktree note:

- `pubspec.lock` was already modified before `CODEX.md` was created, and dependency work later updated it further through `flutter pub add shared_preferences`.

## Priority Direction: Immersive Break Mode

The next major feature is a Safe Eyes-style break experience that temporarily replaces visible screen content with a black, minimal countdown surface. Safe Eyes validates strict breaks, exercise prompts, multi-display coverage, notifications, and smart pause as useful desktop patterns. BlinkKind will implement the concept with explicit safety and platform boundaries.

Implementation decisions:

- Modes: `Off` keeps the current timer, `Gentle` allows skip or postpone, and `Strict` hides routine dismissal while retaining an emergency press-and-hold exit. Strict mode must never disable operating-system escape shortcuts or accessibility controls.
- Break surface: true black background, centered remaining time, one short eye-care instruction, restrained progress, optional sound, and no decorative cards. It must fit phones, tablets, desktop windows, landscape, and large text.
- Transition: show a configurable pre-break warning, then fade to black and enter the break surface. Restore system UI, focus, window state, and the timer state exactly once when the break ends or is safely dismissed.
- Architecture: timer phase transitions must emit presentation-independent events. A dedicated break presentation service will choose in-app immersive UI or native desktop windows without duplicating timer logic.
- Platform priority: prove Android overlay permission and manual overlay behavior first, integrate it with the timer second, then implement Linux, Windows, and macOS desktop enforcement. Desktop still requires tray operation and launch-at-login before overlays can be dependable while the main window is closed. X11 and Wayland require separate validation because compositors may restrict focus and topmost behavior.
- Android: BlinkKind requests `SYSTEM_ALERT_WINDOW` as an explicit opt-in and uses `TYPE_APPLICATION_OVERLAY` to cover other apps during breaks. The manual preview and timer-triggered overlays are implemented. Rotation, system-bar, lock-screen, call, cross-app, Doze, process-death, and OEM behavior still require physical-device validation. Android Go devices may reject overlay permission, and system bars or lock-screen content may remain system-controlled.
- iOS: immersive break UI is available only while BlinkKind is active; iOS does not permit apps to cover other applications or force themselves foreground.
- Android runtime: the foreground service receives a full cadence snapshot, persists it separately from Flutter session state, shows a silent ongoing notification, and advances exact/inexact deadline alarms across native work/break cycles while Flutter is suspended. It mirrors cycle limits and long-break cadence, restores after ordinary process death, fast-forwards delayed delivery, and rejects stale alarms. Flutter remains authoritative and reconciles elapsed boundaries on resume. Reboot rescheduling, later native-only audible reminders, Android 14+ foreground-service requirements, Android 15+ background-start ordering, and OEM restrictions remain open; Android force-stop intentionally prevents self-restart.
- Safety: calls, alarms, lock screen, accessibility navigation, and an emergency exit must remain usable. The feature is habit enforcement, not device lockout.

Creative follow-ups after the core overlay is stable:

- Exercise rotation: distance focus, deliberate blinking, shoulder release, posture reset, and hydration prompts.
- A two-stage warning curtain: a subtle edge flash followed by the full black break if work continues.
- Smart pause based on idle time so time already spent away from the device counts toward eye rest.
- Meeting, presentation, game, and media awareness with user-controlled defer rules.
- Strictness insights that report completed, skipped, and postponed breaks without shaming language.
- Optional low-distraction ambient themes that remain near-black and never undermine the purpose of looking away.

## Remaining Roadmap

1. Product feature expansion.
   - History is implemented with bounded session records, range controls, monthly totals, goal rate, weekly trend, recent session detail, and safe clearing.
   - Notification permission, exact-alarm, pending-reminder, battery optimization, channel-sound settings, and test-reminder diagnostics are implemented.
   - More visual presets are implemented through shared preset definitions.
   - First-run onboarding and notification permission recovery are implemented.
   - Quick timer presets and configurable long-break mode are implemented.
   - Automatic work/break scheduling is implemented with unlimited or configurable per-run cycle limits.

2. Stronger background/session restore.
   - Active session restore is implemented for launch and app resume.
   - Completed work sessions are persisted and deduplicated; daily aggregates remain backward compatible for existing users.
   - Future pass: consider export and optional cancelled-session tracking if deeper analytics are required.

3. Store readiness.
   - Product branding is implemented as `BlinkKind: Eye Break Timer`; existing technical package and application identifiers are intentionally retained for compatibility.
   - App icon polish is implemented across generated platform icon assets.
   - Broader platform metadata cleanup is implemented for web, iOS, macOS, Linux, and Windows templates.
   - Android/iOS store listing copy and screenshots still need product decisions before release.
   - Device testing for exact alarms, battery restrictions, reboot restore, and notification delivery remains required.

4. Dependency cleanup.
   - Unused countdown dependency has been removed; continue watching for unused packages as features change.

## Product Principles

- Keep the app simple and fast to start.
- Timer controls should be obvious and reachable on mobile.
- Preserve a calm, low-distraction visual direction.
- Prefer predictable timer behavior over decorative UI complexity.
- Background and notification behavior must respect pause, resume, cancel, and phase transitions.

## Development Notes For Future Codex Sessions

- Read this file and `WORKLOG.md` first.
- Check `git status --short` before edits and do not revert user changes.
- Use `rg --files` to confirm structure before assuming paths.
- When touching timer behavior, run `flutter analyze` and run `flutter test` once after the module is complete and before committing.
- When touching notifications or platform setup, test Android behavior specifically where possible.
