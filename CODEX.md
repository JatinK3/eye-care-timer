# CODEX.md

## Project Context

This repository is a Flutter app named `eyeapptimer` for an Eye Care Timer based on the 20-20-20 rule. The app helps users work for a configurable interval, then take a short eye break. The current direction is a lightweight wellness utility with reliable timer behavior, saved preferences, reminders, daily streak tracking, calm Material 3 UI, and eventual mobile store readiness.

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
- Before committing code changes, run `flutter analyze` and `flutter test` unless the change is docs-only.
- Before every commit, check `git status --short` and make sure only intended files are staged.

## Current Structure

- `lib/main.dart`: App entrypoint only.
- `lib/app.dart`: Top-level `MaterialApp`, theme/preset state, startup loading, persistence coordination, and notification service injection.
- `lib/features/timer/timer_home_page.dart`: Main timer UI, countdown state, lifecycle reconciliation, and notification scheduling hooks.
- `lib/models/timer_settings.dart`: Persisted timer settings model and defaults, including notification preference.
- `lib/features/settings/settings_page.dart`: Dedicated settings UI for durations, theme, presets, and streak reset.
- `lib/models/timer_session.dart`: Persisted active/paused timer session state for launch restore.
- `lib/services/preferences_service.dart`: `shared_preferences` load/save for durations, theme mode, color preset, daily streak, notification preference, and active timer session.
- `lib/services/notification_service.dart`: `flutter_local_notifications` initialization, permission requests, phase reminder scheduling, and cancellation.
- `test/widget_test.dart`: Widget smoke, persistence load, timer controls, notification fake, and cancel-transition regression tests.
- `WORKLOG.md`: Ordered roadmap and completion log.

## Current App Behavior

- Default work duration is 20 minutes.
- Default break duration is 20 seconds.
- Users can change work and break durations from the settings screen while the timer is idle.
- Start schedules a work-complete notification and begins the countdown.
- Pause stops the animation and cancels the pending phase notification.
- Resume schedules a new phase notification using the remaining time.
- Cancel resets to idle work state and cancels pending notifications.
- Work completion increments the daily streak, saves it, and automatically starts a break.
- Break completion returns to idle work state.
- The timer stores an in-memory phase deadline and reconciles remaining time when the app resumes.
- Active timer sessions are persisted so running and paused work/break phases can restore after app restart.
- Expired restored work sessions advance into the remaining break time, or return idle if both work and break would already be complete.
- Theme mode, color preset, work duration, break duration, daily streak, notification preference, and active timer session are persisted.
- Daily streak resets when the saved streak date is not today.
- Light/dark theme toggle and `Pastel` / `Calm Blue` presets are available.
- UI now uses state-specific status chips/copy, icon-backed controls, responsive wrapping buttons, a dedicated settings screen, notification toggle UX, calmer text, and tighter card radius.

## Dependencies

Runtime dependencies currently declared:

- `flutter`
- `cupertino_icons`
- `circular_countdown_timer`
- `timezone`
- `flutter_local_notifications`
- `shared_preferences`

Audit note: `circular_countdown_timer` is still declared but the active countdown uses Flutter `AnimationController`. Revisit whether to remove it if it remains unused.

## Platform Notes

Android manifest includes notification-related permissions and receivers:

- `POST_NOTIFICATIONS`
- `RECEIVE_BOOT_COMPLETED`
- `VIBRATE`
- `ScheduledNotificationReceiver`
- `ScheduledNotificationBootReceiver`
- `FlutterLocalNotificationsReceiver`

Notification scheduling now uses `AndroidScheduleMode.inexactAllowWhileIdle`, which avoids requiring exact alarm permission for this pass.

Android build toolchain maintenance:

- Gradle wrapper: `8.14.3`.
- Android Gradle Plugin: `8.11.1`.
- Kotlin Gradle Plugin: `2.2.20`.
- `android/gradle.properties` includes Flutter migrator flags for `android.builtInKotlin=false` and `android.newDsl=false`.

## Current Audit Findings

Last audit date: 2026-06-17.

Commands run after the current implementation:

- `flutter analyze`
- `flutter test`

Current results:

- `flutter analyze`: passing with no issues.
- `flutter test`: passing, 10 tests.

Important git/worktree note:

- `pubspec.lock` was already modified before `CODEX.md` was created, and dependency work later updated it further through `flutter pub add shared_preferences`.

## Remaining Roadmap

1. Product feature expansion.
   - Streak/history screen.
   - Optional sound/haptic settings.
   - More visual presets.
   - Long-break or custom break modes if useful.

2. Stronger background/session restore.
   - Active session restore is implemented for launch and app resume.
   - Future pass: consider persisted session history/audit trail if streak analytics grow.

3. Store readiness.
   - App name/package cleanup.
   - App icon and branding polish.
   - Android/iOS store metadata.
   - Device testing for notification permission and scheduling behavior.

4. Dependency cleanup.
   - Remove unused dependencies if they remain unused after the next feature pass.

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
- When touching timer behavior, run `flutter analyze` and `flutter test`.
- When touching notifications or platform setup, test Android behavior specifically where possible.
