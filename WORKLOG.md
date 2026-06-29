# WORKLOG.md

This file tracks the improvement plan for BlinkKind: Eye Break Timer. Update status as work is completed so future sessions can resume without losing context.

## Release & Versioning Policy
- **Mandatory Changelog:** For every release, it is mandatory to create and update a `CHANGELOG.md` entry. Conventional commits and semantic Git tags (e.g. `v1.0.0`) must be maintained to enable changelog generation directly from tag differences.
- **Helper Tooling:** Always refer to the `tool/` directory when executing build, dependency validation, packaging, or release tasks, as robust scripts (`lib_resolver.sh`, `package_linux.sh`, `package_android.sh`, `release.sh`) are already maintained there.

## UI/UX Enhancement Plan
- [x] **Interactive Eye Exercise Animations** — Build smooth, relaxing animated guides (e.g. a moving focus target or breathing guide) on the break overlay screen.
- [x] **Immersive Desk Clock Customizations** — Enhance the Desk Clock layout with advanced glassmorphic styling, modern typography, and ambient animations.
- [x] **Interactive History Charts** — Integrate sleek visual charts (bar/line charts) on the History screen to track focus times and compliance rates.
- [x] **Audio Chime Selector UI** — Add a beautiful settings interface to preview and select different gentle audio chimes (Tibetan bowl, birds, etc.) for work/break alarms.

## Tasks

### Prioritized Backlog
1. [x] **Break Warning, Fade-to-Black & Postpone Policy**: Implement a pre-break warning notification/overlay, a smooth fade-to-black transition before the break starts, and a configurable skip/postpone settings policy in Flutter and Android.
2. [x] **Smart Idle & Fullscreen App Detection**: Detect when the user is playing a game, watching a video in fullscreen, or actively presenting, and delay/postpone the break overlay to avoid interrupting important tasks.
3. [x] **Linux Desktop Background Support**: Build a Linux background runner with tray controls and launch-at-login support.
4. [x] **Android Reboot Survival**: Ensure the foreground service and exact alarms are correctly re-registered and scheduled upon system reboot.
5. [x] **Keyboard Dismissal & Shortcuts (Desktop Focus)**: Support key bindings (Esc to postpone, Space/Enter to skip, or hold Space to trigger Strict exit countdown) on the break overlay.
6. [x] **Custom Gentle Audio Player (High UX Value)**: Bundle gentle chime assets (Tibetan bowl, chimes, birds chirps) and play them on break start/end instead of the default OS system beep.
7. [x] **Habit Reports & CSV Data Exporter**: Add a button on the History screen to export timer event history to a CSV file.
9. [x] **Linux Window Restore after Break Bug** — DONE (verified on-device; **do not modify this implementation**). The main window now returns silently to its original tray-hidden, minimized, or floating state and size after a break ends — no UI flash, no stuck-fullscreen. Fixed by making the native GTK runner the single owner of the main-window break transform/restore, so Dart no longer touches the window during a break. See the Completed section for the full rationale and the exact enter/exit sequence.

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

## Future Roadmap (Product Audit — 2026-06-24, updated 2026-06-24)

**Audit snapshot.** BlinkKind is now a mature cross-platform app with a full AI motivation layer: a 20-20-20 work/break/long-break engine with auto-run cycles and limits; Off/Gentle/Strict break modes with skip/postpone policies; five break visualizers plus two guided exercises; smart idle / DND / fullscreen-app postpone; exact-alarm + foreground-service background reliability; native multi-monitor desktop break overlay with tray controls; History & Insights with CSV/JSON export; theming, color presets, Inter typography, Immersive Focus Mode; onboarding and permission recovery; **AI Motivation & Prompts** (Gemini/OpenAI/Groq, dynamic model fetch, background pre-fetch, break-screen injection); **startup splash quote animation**. All P0 categories are fully complete. Remaining items below are ordered by next-session priority.

### P0 — AI Integration & Startup Splash (New)
- [x] **AI LLM Settings & Custom Provider Config**: Support key-value configuration storage in `TimerSettings` and `PreferencesService` for dynamic AI status, provider choice (Gemini, OpenAI, Groq), API keys, model selections, and editable prompts. Render these in a new collapsible settings group "AI Motivation & Prompts".
- [x] **Background Pre-Fetch AI Service**: Design a lightweight HTTP-based client (`AiService`) to call LLM endpoints without bulky dependencies. Implement background pre-fetching during work phases (caching the result to show the message instantly when a break starts), timeout/retry mechanics, and local backup templates for robust failover.
- [x] **Dynamic AI Break Screen Messaging**: Inject the pre-fetched AI-generated text dynamically into the fullscreen desktop break overlay and the in-app break card.
- [x] **App Launch Splash Quote Animation**: Build a 1.5-second startup splash screen displaying a motivational quote that uses a smooth drop-in slide/fade animation before transitioning to the home timer screen.

### P0 — Signature eye-care depth (on-brand, differentiating)
- [x] **Blink reminders & blink-rate training** — the product is literally *BlinkKind*, yet blinking exists only as static break-screen text (`desktop_break_overlay.dart`, `timer_home_page.dart`). Add an opt-in, low-friction "blink now" micro-nudge (subtle tray pulse / brief on-screen cue) on a configurable cadence, plus a guided blink exercise. This is the clearest differentiator vs. generic Pomodoro/eye timers and the most on-brand missing feature.
- [x] **Active work-hours & day schedule** — only run during configured hours/days (e.g. 09:00–18:00, Mon–Fri); auto-pause outside them. Removes the "why is it nagging me at night/weekend" friction. No time-of-day scheduling exists today.
- [x] **Natural / idle break credit** — `system_idle` is already wired for pausing; extend it so that when the user has already been idle ≥ break length, that counts as a completed break and defers the next one instead of interrupting someone who just stepped away (à la Stretchly).
- [x] **Rotating eye-health tips & 20-20-20 education** — surface short, rotating eye-care tips on the break screen and a "Learn" card on home to reinforce the habit and the value proposition.

### P1 — Retention, motivation & everyday UX
- [x] **Achievements, streak milestones & compliance stats** — badges/levels for streaks and breaks taken; add a compliance metric (breaks taken vs. skipped/postponed — the data already exists in `TimerEventRecord`) and a focus-time heatmap to History. No gamification exists today.
- [x] **Global hotkeys + richer tray/menubar** — system-wide start/pause/skip/take-break-now; tray tooltip showing "next break at HH:MM" and a "snooze all for 1h / until tomorrow" quick action.
- [x] **Settings redesign with search & grouping** — `settings_page.dart` is ~1.2k lines and growing; add search and collapsible categories so the surface stays usable.
- [x] **Theme expansion** — custom accent-color picker, true-black AMOLED variant, and Material You / system-accent dynamic color.
- [x] **Break-screen customization** — optional motivational quotes / custom messages, choice of background, and toggles for which info (clock, next phase, tips) is shown during a break.
- [ ] **Localization (i18n) scaffolding** — app is English-only (no `flutter_localizations`/ARB); extract strings and add localization. Large reach multiplier.
- [x] **Auto-start schedule on launch** — automatically start the work timer/schedule when the application starts, persisting this setting to simplify user productivity setup (similar to SafeEyes).
- [x] **Immersive Focus Mode — dynamic accent-color theming** — currently the immersive/focus mode (full-screen countdown) uses a static dark/black background. Planned: the immersive background, glow, and accent should inherit the user's selected color preset (e.g. if the preset is Green, focus mode pulses in deep green; if Blue, in deep blue). Implementation sketch:
  - Pass `colorPreset` and `customAccentColorHex` down to `_FocusModeBackground` (already done for the breathing glow — extend it to the full background gradient).
  - Use `ColorPresets.swatchColor(colorPreset, isDark: true)` as the base hue for the radial gradient background instead of the hardcoded `Colors.black`.
  - Sync the neon ring tip-dot glow and inner bloom color to the same accent so the whole focus surface feels cohesive.
  - Gate behind the existing `isFocusMode` flag; no change to non-immersive layout.
  - **Do NOT implement yet — log only for planning.**

### P2 — Cross-device, ecosystem & context intelligence
- [x] **Settings backup/restore, then cloud sync** — start with config export/import (JSON) to complement the existing history export; later add optional account-based sync of settings + history across devices.
- [x] **Meeting / camera-in-use auto-postpone** — detect an active camera/mic (video calls) or a calendar event and postpone the break, extending the existing smart-idle/DND logic.
- [ ] **Per-app rules & profiles** — don't interrupt while chosen apps are focused; "Work" vs "Gaming" profiles with different cadences.
- [x] **Home-screen widgets & OS surfaces** — Android home widget implemented natively (TimerWidgetProvider) and updated from foreground service. iOS widget, macOS menu-bar extra, and Windows progress remain on backlog.
- [x] **Wellness micro-breaks (modular)** — optional hydration / posture / stretch reminders alongside eye breaks (opt-in modules).
- [x] **OS DND / Focus integration** — set system Do-Not-Disturb / Focus during work phases.

### P3 — Quality, distribution & infrastructure
- [ ] **Physical-device validation** (also tracked above) — Android OEM background restrictions, iOS immersive restore, desktop Wayland/X11 edge cases.
- [ ] **CI + expanded test coverage** — automated analyze/test on push; widen widget/unit coverage as new features land.
- [ ] **Desktop auto-update + store distribution** — an update channel for the `.deb`/`.rpm`, plus publishing to Flathub/Snap, Microsoft Store, App Store, Play Store, and Homebrew.
- [ ] **Opt-in, privacy-respecting analytics & crash reporting** — understand real usage/compliance without compromising the local-first stance.
- [ ] **Accessibility & performance audit** — screen-reader pass, reduced-motion option, colorblind-safe palettes; revisit the once-per-second tray PNG render cadence on desktop.

### P4 — Future AI-Driven Wellness Features
- [ ] **AI Fatigue & Blink Detection** — local, privacy-first computer vision model using front camera (e.g. MediaPipe) to detect blink rate and eye fatigue to trigger breaks dynamically.
- [ ] **Interactive AI Wellness & Ergonomics Coach** — chat/companion interface to consult on ergonomic posture, stretching, and wellness tips based on productivity metrics.
- [ ] **AI-Driven Smart-Break Schedule** — adaptive timer schedule based on user focus patterns, daily compliance, and fatigue feedback.
- [ ] **AI Voice-Guided Eye Exercises** — audio guidance and instructions for dynamic eye exercises during break phases.

### Quick wins (low effort, near-term)
- [x] Promote "Take a break now" and a "Snooze for…" action to the main home screen (currently tray-only).
- [x] Add a one-tap "Restore defaults" in Settings and reconsider defaults (e.g. in-app sound defaults to off).
- [x] Show a "breaks taken today" count on home.
- [x] Add a pre-break countdown indication on the tray icon.

---

## Session Log

### 2026-06-29 (Session ongoing — IST)

**Completed this session:**
- **Fixed duplicate launcher icons on GNOME/Linux:** Removed the duplicate `blinkkind.desktop` installation from both DEB and RPM packaging pipelines, keeping only the standard `com.jatin.eyecaretimer.desktop` launcher matching the GTK application ID.
- **Cleaned up stale launcher files:** Cleaned up local and system application entry paths to remove duplicate entries in the GNOME app grid.
- **Fixed zombie background process sending notifications on exit:** Added `exit(0)` to the application's quit routine in `DesktopIntegrationService` and implemented a `dispose` method in `NotificationService` to terminate background loops, active Dart timers, and the `dbus-monitor` child process. This ensures that exiting the app via the system tray fully kills the app process and terminates all blink reminder notifications.
- **Restored native title bar and window controls on Linux:** Modified `DesktopIntegrationService` to bypass hiding the title bar on Linux platforms, allowing GNOME (Ubuntu/Fedora) to render standard close, minimize, and maximize buttons. Added native GTK setting preference `gtk-application-prefer-dark-theme = TRUE` inside `my_application.cc` to ensure that the header/title bar matches the application's dark theme interface automatically.
- **Added startup notifications for minimized background launches:** Configured `DesktopIntegrationService` to display a silent, non-intrusive system toast notification on startup when the app starts minimized. The notification dynamically states whether the eye-care schedule has started or is awaiting tray activation, making background launch behaviors clear and transparent.
- **Fixed Settings tray menu click behavior:** Added `_showWindow()` restoration to the tray menu onClicked callback for the "Settings" item. This ensures that clicking Settings from the system tray successfully restores and focuses the app window before pushing the settings view.
- **Prevented notification double-posting and rate-limited blink reminders:** Added a static 5-second rate-limiting guard at the entry point of `showBlinkReminder` inside `NotificationService`. This guarantees that even with concurrent loops, duplicate timers, or asynchronous race conditions, only a single notification is shown to the user within any 5-second interval.
- **Improved packaging pipeline installation steps:** Modified `tool/package_linux.sh` to automatically run process termination (`pkill -f eye_care_timer` and `pkill -f blinkkind`) before removing the old package and installing the new one. This prevents Linux file-lock conflicts during system updates.

**Commits this session:**
- `fix(packaging): remove duplicate desktop launcher to prevent double icons in app grid`
- `fix(desktop): terminate process fully on exit to stop background notifications`
- `fix(linux): restore native title bar and window controls on Linux with dark theme preference`
- `feat(desktop): show startup notification when starting minimized in tray`
- `fix(desktop): restore window first when Settings is clicked in tray`
- `fix(desktop): add static rate limiting guard to showBlinkReminder to block duplicate notifications`
- `fix(packaging): terminate running instances before installing on Linux`

---

### 2026-06-28 (Session ongoing — IST)


**Completed this session:**

- **Redesigned timer ring to modern minimal neon style** — replaced the plain grey `CircularProgressIndicator` track and flat arc with a premium multi-layer neon ring:
  - Ghost track: full-circle at 18% opacity, replaces the thick grey ring — eliminates the harsh 12 o'clock join artifact.
  - Outer bloom glow: wide blurred layer (`MaskFilter.blur`, radius 14) giving ambient neon light from the arc.
  - Inner glow: tighter blur (radius 6) for luminosity and depth.
  - Main neon arc: thin gradient arc with `StrokeCap.butt` on all layers to prevent round-cap bleed at the origin.
  - Glowing tip dot: bright white core + halo bloom at the arc endpoint, marks progress like a watch hand.
  - Origin dot: small colored dot at 12 o'clock (arc start) to replace the round cap cleanly.
  - Frosted glass inner circle: 4% white fill + 7% white hairline border, always visible (not just in focus mode).

- **Fixed arc round-cap bleed at 12 o'clock** — when the timer was near full/complete (e.g. in orange/coral urgency phase), `StrokeCap.round` on all three arc layers (bloom, inner glow, main arc) drew a visible rounded cap at both the start AND end of the arc. At nearly 100% progress these caps overlapped at 12 o'clock, creating a harsh orange blob. Fixed by:
  - Switching all arc draws to `StrokeCap.butt` (no caps on the arc).
  - Adding a small colored circle at the arc's start origin (12 o'clock) to maintain a clean, finished look.
  - The existing tip dot already handles the end cap visually.

- **Fixed SnackBar OK button appearing static/unclickable** — added `SnackBarThemeData` to both light and dark `ThemeData` in `app.dart`:
  - `backgroundColor: Color(0xFF1E2A1E)` — dark green, always distinct from any page background.
  - `actionTextColor: Color(0xFF4ADE80)` — neon green, clearly visible and tappable.
  - `behavior: SnackBarBehavior.floating` with rounded corners.
  - Fixes all 12 `SnackBarAction` usages across `timer_home_page.dart`, `settings_page.dart`, and `history_page.dart`.

- **Fixed OS title bar inconsistency on Linux dark mode** — the GTK window decoration was white (following WhiteSur-light system theme) while the app runs in dark mode:
  - Added `windowManager.setTitleBarStyle(TitleBarStyle.hidden, windowButtonVisibility: false)` in `DesktopIntegrationService.initialize()` to hide the GTK chrome.
  - Wrapped the Flutter `AppBar` with `DragToMoveArea` (from `window_manager`) so the window remains draggable after the system title bar is removed.

**Commits this session:**
- `feat: redesign timer ring to modern minimal neon style`
- `fix: name desktop file after GTK app-id for GNOME Wayland icon matching`
- `fix: make SnackBar action button visible and clickable`
- `fix: hide OS title bar for consistent dark theme on Linux`
- `fix: arc round-cap bleed at 12 o'clock — switch to StrokeCap.butt with origin dot`

**State at end of session:**
- `flutter analyze` → 0 issues
- Released as `v1.0.4`

---

### 2026-06-27 (Session end ~20:15 IST)

**Completed this session:**

- **Implemented Color-Coded Gradient Timer Ring (UI/UX Future Improvements Backlog)** — built a premium gradient progress ring that transitions dynamically based on the remaining time percentage during work phases:
  - Remaining time > 25%: Calming Emerald/Mint Green gradient.
  - Remaining time 10%–25%: Amber/Yellow warning gradient.
  - Remaining time <= 10%: Orange/Coral urgency gradient.
  - The focus mode background breathing glow dynamically synchronizes its base color to match the active timer ring color.
  - Replaced the standard `CircularProgressIndicator` with a custom `CustomPainter`-based `_GradientTimerPainter` utilizing a `SweepGradient` to paint smooth color arcs.
- **Fixed widget tests and prevented focus mode and settings history test failures:**
  - Resolved `pumpAndSettle` timing out in the focus mode widget test by replacing it with an explicit `pump` call since the infinite pulsing background animation controller runs indefinitely.
  - Resolved `scrollUntilVisible` failure in the settings opens recent break history test by targeting the first match of the duplicated "Eye Health Score" text finder, and increased the test viewport physicalSize to ensure elements fit on screen.

**Commits this session:**
- `feat: implement color-coded gradient timer ring and sync focus background`
- `test: fix focus mode and settings history widget test failures`

**State at end of session:**
- `flutter analyze` → 0 issues
- `flutter test` → 84/84 pass

---

### 2026-06-27 (Session end ~20:00 IST)

**Completed this session:**

- **Diagnosed & fixed Linux notification sound not playing** — investigated the full audio path for in-app chime notifications:
  - Root cause: `soundEnabled` defaults to `false` in `TimerSettings` (line 175) **and** the `SharedPreferences` fallback also defaults to `false` (line 119 of `preferences_service.dart`), so on a fresh install or after clearing prefs, sound is silently off.
  - Confirmed that on Linux, system notification daemons (e.g. GNOME/KDE) do **not** play sound for `flutter_local_notifications` toasts; the only audio path is the in-app `audioplayers` chime triggered by `_playChime()` in `timer_home_page.dart`.
  - Updated `soundEnabled` default to `true` in both `TimerSettings` and the `PreferencesService` fallback so all new/reset installations have in-app chimes active out of the box.
  - Verified `_playChime()` is called on work/break phase completion and that the `Test reminder` action in Settings also fires it.

- **Added reinstall (`-R`/`--reinstall`) support to `tool/package_linux.sh`** — the script previously only built the package; repeated installs required manual `dnf remove` / `apt remove` before `install`. Added:
  - `-R` / `--reinstall` flag that removes the previously installed `blinkkind` package (via `dnf remove` on Fedora/RHEL or `apt remove` on Ubuntu/Debian) before installing the freshly built one.
  - Integrated into the end-of-build install flow: when `-i` (install) and `-R` (reinstall) are both active, the old package is purged first, then the new one is installed cleanly.
  - Works alongside existing `-y` (auto-accept) and `-ni` (no-install) flags.

- **Added OK action button to all in-app SnackBar toasts** — all `SnackBar` widgets across the app now include a `SnackBarAction(label: 'OK', ...)` so users can immediately dismiss toasts rather than waiting for the 4-second auto-hide:
  - Break skip limit warning in `timer_home_page.dart` (consecutive skips guard).
  - Natural break detected / timer reset notification in `timer_home_page.dart` (lifecycle resume path).
  - All other SnackBars that were previously dismiss-only now include the action.

**Commits this session:**
- `fix: default soundEnabled to true so chimes work on first install`
- `feat: add --reinstall flag to package_linux.sh for clean re-installation`
- `feat: add OK action button to SnackBars for immediate dismissal`

**State at end of session:**
- `flutter analyze` → 0 issues
- RPM package built successfully → `dist/blinkkind-1.0.2-1.fc43.x86_64.rpm`
- All SnackBar toasts across the app include an OK dismiss button

---

### 2026-06-27 (Session end ~14:22 IST)

**Completed this session:**
- **Dynamic Flutter SDK path in `tool/package_linux.sh`** — replaced the hardcoded `/home/jatin/development/flutter/bin/flutter` path (×3 occurrences) with a `resolve_flutter()` function. Resolution order: (1) `flutter` on `$PATH`, (2) common install locations (`~/development/flutter`, `~/flutter`, `/opt/flutter`, `/usr/local/flutter`, snap), (3) explicit `$FLUTTER_HOME` env var. Exits early with a clear error message if Flutter is not found.
- **Cross-distro native library checker `tool/lib_resolver.sh`** — created a new standalone script that detects and installs all native Linux libraries required by BlinkKind's Flutter plugins before a build begins:
  - Supports `apt` (Ubuntu/Debian), `dnf` (Fedora/RHEL), `yum` (CentOS), `pacman` (Arch).
  - Checks and maps packages for: CMake, Ninja, pkg-config, Clang (build tools); GTK3, GLib (Flutter embedder); `keybinder-3.0` (`hotkey_manager`); `ayatana-appindicator3` (`system_tray`); X11 + XTest (`window_manager`); `libnotify` (`flutter_local_notifications`); GStreamer + plugins-base (`audioplayers`); GIO (`launch_at_startup`).
  - Deduplicates package installs; runs `apt-get update` once before apt installs; reports per-package success/failure.
  - Env flags: `LIB_RESOLVER_DRY_RUN=1` (print only), `LIB_RESOLVER_QUIET=1` (suppress info output).
  - Inherits `AUTO_YES` from `package_linux.sh` so `-y` flag auto-installs deps without prompting.
- **Integrated `lib_resolver.sh` into `package_linux.sh`** — sourced after argument parsing (so `AUTO_YES` is available); `resolve_build_deps()` and `patch_plugin_sources()` called before both dev-mode (`-d`) and release builds.
- **Auto-patch Clang C++ errors in Flutter plugin sources (`patch_plugin_sources()`)** — added to `lib_resolver.sh` to fix known `-Werror,-Wsometimes-uninitialized` compile errors that Clang (Fedora/Arch) treats as hard errors but GCC (Ubuntu) silently ignores:
  - **`hotkey_manager_linux`**: `const char* identifier;` and `const char* keystring;` initialized to `nullptr` in `hotkey_manager_linux_plugin.cc`.
  - Patches both the pub-cache master copy (`~/.pub-cache/hosted/pub.dev/hotkey_manager_linux-*/`) and the in-project symlink (`linux/flutter/ephemeral/.plugin_symlinks/...`) so the fix survives `flutter clean` + `flutter pub get` on any distro.
  - Idempotent — diff-checked before applying; "Already patched" if fix is already present.
  - Extensible — new plugin fixes can be added as additional patch blocks.

**Commits this session:**
- `fix: resolve Flutter SDK path dynamically in package_linux.sh`
- `feat: add lib_resolver.sh for cross-distro build dependency checking`
- `fix: auto-patch hotkey_manager_linux Clang uninitialized-var errors in lib_resolver.sh`

**State at end of session:**
- `bash -n tool/lib_resolver.sh` → syntax OK
- `bash -n tool/package_linux.sh` → syntax OK
- `flutter build linux` → ✓ Built `build/linux/x64/release/bundle/eye_care_timer`

---

### 2026-06-26 (Session end ~17:20 IST)

**Completed this session:**
- Fully implemented **Meeting / camera-in-use auto-postpone** on Android and Linux:
  - Registered a global `CameraManager.AvailabilityCallback` in Android `MainActivity` to track camera active status dynamically without requiring permissions.
  - Queried `AudioManager` active calls (`MODE_IN_COMMUNICATION`/`MODE_IN_CALL`) and microphone recording status (`isMicrophoneActive`) dynamically.
  - Updated Flutter `isCameraInUse` and `isMicInUse` logic to query Android via method channel.
  - Exposed `"Camera/mic auto-postpone"` toggle switch under `"Break Screen & Behavior"` settings category.
- Fully implemented **Wellness micro-breaks (modular)**:
  - Exposed `"Wellness reminders"` toggle switch and interval selector (dropdown selecting 30m, 45m, 1h, 1.5h, 2h) under `"Notifications & Sounds"` settings category.
  - Persisted preferences properly via `SharedPreferences`.
- Added full widget test coverage for the settings toggles and dropdown selections.
- Ran static analysis (`flutter analyze`) and all tests successfully (84/84 passing).

### 2026-06-25 (Session end ~13:25 IST)

**Completed this session:**
- Fully implemented **Restore Defaults Settings Option**:
  - `PreferencesService.resetToDefaultSettings()` resets all keys back to factory defaults while retaining streak count and onboarding status.
  - `SettingsPage` displays a new `"System Options"` category containing a `"Reset settings"` option that presents a user-friendly warning dialog before triggering the reset.
- Fully implemented **OS Focus & DND Integration**:
  - `OsFocusService` executes GNOME Shell commands (`gsettings set org.gnome.desktop.notifications show-banners false/true`) to toggle system DND automatically on Linux.
  - `TimerHomePageState` tracks the active phase and automatically enables DND during active work phases, disabling DND when paused, stopped, or on break.
  - Added an `"OS Focus Mode (DND)"` switch toggle under the `"General Schedule"` settings category, which is optional and disabled by default.
  - Added a clear inline note explaining Ubuntu/GNOME DND whitelist/exception behavior (explaining that since Ubuntu doesn't support whitelisting specific apps to bypass system DND, users who need exceptions should keep the toggle off and instead manually silence noisy apps via Ubuntu Settings -> Notifications).
- Fully implemented **Settings Backup & Restore**:
  - Added `toJson()` and `fromJson()` serialization helper methods to `TimerSettings`.
  - Added `PreferencesService.saveAllSettings(settings)` to update all configuration values in SharedPreferences in bulk.
  - Added a `FilePicker` dependency and implemented file export (writing JSON to the `Downloads` directory) and file import (loading, parsing, and applying a chosen JSON backup file).
  - Exposed `"Backup settings"` and `"Restore settings"` options under `"System Options"` in the Settings Page.
- Fully implemented **Pre-Break Tray Icon Countdown**:
  - Enhanced `DesktopIntegrationService._updateDynamicTrayIcon(state)` to detect when a work phase is imminent (< 60 seconds remaining).
  - The tray icon dynamically shifts its ring color to a warn color (`Colors.amberAccent`) and displays remaining seconds instead of rounded minutes in real-time.
- Added **Tray Settings Navigation**:
  - Added a `"Settings"` context menu item to the desktop tray. Tapping it automatically restores/focuses the app window and navigates directly to the settings screen.
- Extended **Splash Screen Quote Duration**:
  - Increased the auto-advance timer on the startup quote splash screen from 1.8 seconds to 2.5 seconds, giving you plenty of time to read the motivational quotes on launch.
- Enhanced **Linux Packaging Script Options**:
  - Added support for advanced command line arguments (`-N`/`-n` to auto-deny, `-Y`/`-y` to auto-accept, `--no-clear`/`-nc` to skip clearing preferences, and `--install`/`-i` to force package installation) to `tool/package_linux.sh` for non-interactive execution.
- Cleaned and verified the entire codebase:
  - Added unit/widget tests for the settings JSON serialization, UI backup/restore entries, DND toggle, and Settings reset features.
  - Verified static analysis (`flutter analyze` is clean with 0 issues) and ran all 71 unit/widget tests successfully (100% passing).

### 2026-06-24 (Session end ~18:30 IST)

**Completed this session:**
- Fully implemented **AI Motivation & Prompts** end-to-end:
  - `AiService` — lightweight `http` client for Gemini, OpenAI, and Groq (chat completions + live model listing with hardcoded fallback).
  - `TimerSettings` + `PreferencesService` — 5 new persisted fields (`aiMotivationEnabled`, `aiProvider`, `aiApiKey`, `aiModel`, `aiCustomSystemPrompt`).
  - `SplashQuotePage` — 1.8 s slide-down/fade-in startup splash with random eye-care quote and Skip button.
  - `app.dart` — `_showSplash` flag + 5 AI setters wired throughout state.
  - `TimerHomePage` — `_preFetchAiQuote()` fires in background on work start; cached quote passed to all `showBreakOverlay` sites.
  - `BreakOverlayService` + `DesktopBreakOverlay` — `aiQuote` threaded through to the break overlay, falling back to static tips.
  - `SettingsPage` — new "AI Motivation & Prompts" collapsible category: enable toggle, provider dropdown, API-key field with debounced live model fetch, model dropdown with "Custom…" dialog, system prompt editor.
  - Test suite updated (`pumpBlinkKindApp` + onboarding test dismiss the splash). **All 59 tests pass, zero analyzer issues.**
- WORKLOG kept current throughout.

**State at end of session:**
- `flutter analyze` → 0 issues
- `flutter test` → 59/59 pass
- Git: 2 commits on `main` (`feat: add AI motivation…` + `docs: mark AI…`)

**Recommended next session priorities (in order):**
1. **Rotating eye-health tips & 20-20-20 education** (P0, 1 remaining) — surface short rotating tips on the break screen and a "Learn" card on home.
2. **Achievements, streak milestones & compliance stats** (P1) — badges/levels for streaks; compliance rate (breaks taken vs. skipped from `TimerEventRecord`); focus-time heatmap in History.
3. **Break-screen customization** (P1) — custom background, toggle for clock/next-phase/tips display during break.
4. **Quick wins** — "breaks taken today" on home screen; "Restore defaults" in Settings; "Take a break now" on home.
5. **Settings backup/restore** (P2) — JSON config export/import (pairs naturally with existing history export).

## Completed

- Implemented auto-start schedule on launch settings preference and logic inside `_restoreInitialSession` callback.
- Implemented the next P1/P2 product-depth batch:
  - History now shows break compliance, achievements/milestones, milestone count, and richer insights based on existing `TimerEventRecord` and completed session history.
  - Break-screen customization settings now persist show-clock, show-tips, show-progress, and custom break-message preferences. Flutter in-app/desktop break surfaces consume these settings.
  - The default break visualizer style is now `Random/All` for new/unset preferences.
  - Home now exposes `Take break now`, `Snooze 1h`, `Tomorrow`, and `Cancel snooze` quick actions, plus a compact breaks-taken-today summary.
  - Added focused coverage for default visualizer, home quick action, break customization settings, and History achievements/compliance. Verification pending final full test run.

- Implemented rotating eye-health tips and 20-20-20 education:
  - Added `lib/features/timer/eye_health_tips.dart` as a shared static catalog for practical eye-care tips.
  - Desktop break overlays now rotate through tip actions/details during the break while preserving AI quote priority when available.
  - In-app break screens show a rotating tip panel, and the home screen includes a compact Learn card that cycles through education tips every 45 seconds.
  - Added focused test coverage for tip rotation and home Learn-card rendering. Verification: `flutter analyze` clean; `flutter test` passes with 61 tests.

- Added desktop **Start minimized** preference for launch-at-startup workflows: Settings now exposes a Desktop Options toggle, the value persists via `TimerSettings`/`PreferencesService`, and desktop startup reads it before initializing the tray/window integration so BlinkKind can launch directly into the system tray. Verified with `flutter analyze` and `flutter test` (59 passing).

- Implemented full AI Motivation integration and startup splash screen:
  - Created `lib/services/ai_service.dart` — a lightweight `http`-based HTTP client with no bulky SDK dependency. Supports Gemini (`v1beta` + API-key query param), OpenAI (`v1/chat/completions` + Bearer token), and Groq (`openai/v1/chat/completions` + Bearer token) for both model listing (`fetchModels`) and motivational quote generation (`generateMotivation`). Falls back to a curated hardcoded list of popular models per provider when the live fetch fails, and also exposes `getDefaultModels(provider)` for instant UI population.
  - Added five new fields to `TimerSettings` (`aiMotivationEnabled`, `aiProvider`, `aiApiKey`, `aiModel`, `aiCustomSystemPrompt`) with `copyWith` support and sensible defaults (Gemini, disabled, empty key/prompt).
  - Added five matching persistence keys and load/save methods to `PreferencesService`.
  - Added a startup splash page (`lib/features/splash/splash_quote_page.dart`): a 1-second slide-down + fade-in animation showing a random eye-care motivational quote with app branding and a Skip button; auto-completes after 1.8 s. Wired into `BlinkKindApp` via a `_showSplash` flag, shown once on each cold start after onboarding.
  - Added `_preFetchAiQuote()` to `TimerHomePageState`: fires in the background immediately when the work timer starts, stores the result in `_cachedAiQuote`, and silently falls back to `null` on any error. All three `showBreakOverlay` call sites now pass `_cachedAiQuote`.
  - Threaded `aiQuote` through `BreakOverlayService.showBreakOverlay` and `_pushBreakOverlayRoute` into `DesktopBreakOverlay`, which renders `widget.aiQuote ?? _currentExercise`.
  - Added an **"AI Motivation & Prompts"** collapsible category to `SettingsPage` with: enable toggle, provider dropdown, obscured API-key field with 800 ms debounced live model fetching, model dropdown with "Custom…" override dialog, and a multi-line system prompt editor. Registered the new category in `_buildCollapsibleGroups` and `_categoryIcon`.
  - Added five AI-setting setters to `_BlinkKindAppState` and wired them into `_openSettings` and `TimerHomePage`.
  - Added `http ^1.2.2` to `pubspec.yaml` as a direct dependency.
  - Updated the `pumpBlinkKindApp` test helper and the onboarding test to dismiss the new splash screen before running assertions. All 59 widget tests pass; `flutter analyze` reports zero issues.

- Implemented Global Hotkeys & Richer Tray/Menubar Controls (Task 2 of P1):
  - Integrated `hotkey_manager` and registered system-wide global hotkeys for standard actions: Pause/Resume (`Ctrl+Alt+P` or `Super+Alt+P`), Take Break Now (`Ctrl+Alt+B` or `Super+Alt+B`), Skip Break (`Ctrl+Alt+S` or `Super+Alt+S` during active breaks), and Postpone Break (`Ctrl+Alt+O` or `Super+Alt+O` during active breaks).
  - Enhanced the system tray tooltip to show the exact absolute time of the next break (e.g. `BlinkKind - Next break at 18:30` instead of a relative countdown) by calculating `nextBreakAt` in the timer state.
  - Implemented in-memory Break Snoozing inside `TimerHomePageState` with snooze quick actions in the system tray menu: "Snooze Breaks for 1 Hour", "Snooze Breaks until Tomorrow", and "Cancel Snooze" (only visible when snoozed).
  - Designed custom UI statuses, phase descriptions, and dynamic tray icon states ("Zz" symbol on a deep purple accent ring) to represent active snooze periods and remaining duration.
  - Added clean-up tasks to unregister global hotkeys on application exit to avoid memory or context leaks.

- Implemented Active Work Hours & Day Schedule (Task 2) and Natural / Idle Break Credit (Task 3):
  - Added work schedule settings (`workHoursEnabled`, start/end hours/minutes, and active work days representation) and natural break credit settings to `TimerSettings`, persisting them in `PreferencesService`.
  - Created a "Work schedule" card in `SettingsPage` containing day selection chips (Mon-Sun) and start/end time dropdown selectors, and added a "Natural break credit" toggle within the smart idle configurations.
  - Implemented periodic active schedule checks in `TimerHomePage` that auto-pauses the timer and displays "Schedule Paused" when outside active hours or days, auto-resuming when schedule times are met.
  - Implemented idle duration checking on returning from desktop system idle (`system_idle`) and Android screen-off: if idle duration matches or exceeds the break length, the user receives a completed break credit, resetting the work countdown while maintaining their daily streak, complete with SnackBar alerts.
  - Updated MethodChannel startPhase calls to pass `naturalBreakCreditEnabled` settings down to Android background services.
  - Updated `TimerForegroundService.kt` to record `screenOffTimeMillis` on screen-off and credit natural breaks in the background when the screen remains off longer than the break duration, generating events parsed by the Flutter app on resume.

- Implemented opt-in blink reminders (micro-nudges) and guided blink pacing training:
  - Added `blinkRemindersEnabled` and `blinkRemindersCadenceSeconds` configurations to the Settings model, preferences service, and settings page.
  - Implemented real-time cadence checking in the work timer ticks to trigger micro-nudges (Haptic ticks on mobile/haptic platforms, and temporary dynamic system tray closed-eye icon changes + central eye animation flashes in the home screen timer dial).
  - Built the `BlinkTrainingGuide` widget with an animated custom-drawn vector eye using the `_EyePacingPainter` (smooth quadratic Beziers shape scaling representing blinking lids, iris, pupil, and light reflection).
  - Wired `BlinkTraining` into desktop overlays and homepage layouts, added settings visualizer dropdown selection, and added full widget test coverage.
  - Fixed system tray caching and minimized status issues for blink reminders:
    - Bypassed Linux AppIndicator icon caching by generating unique timestamped filenames (`blinkkind_tray_icon_$timestamp.png`) and clean-deleting older icons upon new tray states or application exit.
    - Integrated blink reminder checks into both the visible animation loop and the wall-clock background tray tick timer (`_onDesktopTrayTick`) to ensure reminders fire reliably even after the app is minimized to the tray following a break.

- Fixed the desktop tray / app-indicator countdown freezing while the window is hidden. The tray time was only ever pushed from the in-window progress `AnimationController`'s per-frame listener, and Flutter stops producing frames once the GTK window is hidden/closed — so the indicator froze at whatever value it showed when the window was closed, even though the underlying phase (and breaks) kept running on the wall-clock `_phaseDeadlineTimer`.
  - Added a desktop-only wall-clock `Timer.periodic(1s)` (`_desktopTrayTicker` / `_onDesktopTrayTick` in `timer_home_page.dart`) that runs regardless of window visibility, recomputes the remaining time from `_phaseEndsAt`, and pushes it to the tray via `_updateDesktopState()`. It only pushes when the value actually changes, so it is a no-op while the window is visible and the animation already keeps the value current (no duplicate tray redraws). Started in the desktop init block, cancelled in `dispose()`.
  - Also fixed the **in-window** dial showing a stale value when the window is reopened: added a lightweight `_realignAnimationToClock()` that snaps the current phase's animation back to the wall clock, triggered on tray-restore (new `DesktopCommand.windowResumed`, emitted from `DesktopIntegrationService._showWindow()`) and on desktop `AppLifecycleState.resumed`.
  - **Important — did NOT re-enable `_syncTimerWithClock()` on desktop.** `_realignAnimationToClock()` only re-aligns the single current phase's animation; it never runs `projectPhase` reconciliation, crosses boundaries, starts breaks, or mutates streak counters. This preserves the earlier deliberate decision (recorded below) to keep full clock reconciliation Android-only, which avoided duplicate break overlays / state corruption on desktop focus transitions.
  - Verified: `flutter analyze` clean, release build green via `tool/package_linux.sh`, `dist/blinkkind_1.0.0_amd64.deb` produced.

- Fixed Postpone falsely showing a "Break complete" notification. Starting a break schedules a "Break complete" reminder (`NotificationService.scheduleBreakCompleteReminder`, a wall-clock timer on Linux) for the break's full duration. `_postponeBreak()` switched to a work phase but never cancelled that pending reminder, so it still fired at the original break-end time and told the user the break had completed. Fix (`timer_home_page.dart`, `_postponeBreak`): cancel the pending reminder (`_cancelReminders()`), tear down the break overlay (so postponing from the tray menu doesn't leave the fullscreen break screen up), and schedule the reminder for the new postponed work window. Skip was already correct — it routes through `_onPhaseComplete()`, which cancels reminders — so no change was needed there.

- Fixed the main window auto-closing when the work timer is cancelled. The "Cancel" / "Cancel Timer" button routes through `_cancelTimer()` → `stopBreakOverlay()` → native `exitBreak()`, which previously ran its window restore logic unconditionally and reused the leftover "restore to tray" flag from the *previous* break, hiding the visible window even though no break was on screen. Fix (`linux/runner/my_application.cc`, `exit_break()`): early-return when `g_break_active` is false, so the window transform/restore only fires during an actual break and spurious calls leave the user's window untouched. Does not alter the on-device-verified restore path (during a real break `g_break_active` is true, so it runs identically).

- Fixed the Linux "window restore after break" bug for good (backlog item #9) — verified on-device, **this implementation is final and must not be modified**. Made the native GTK runner (`linux/runner/my_application.cc`) the single owner of the main window during a break and removed the Dart `window_manager` transform/deferred-restore entirely, eliminating the long-standing "dual-mapping" conflict where both Dart and native code fought over the same window.
  - New native `enterBreak`: snapshots the window's pre-break state — hidden-to-tray, minimized, maximized, or floating position/size (tracked via a `window-state-event` handler on the main `GtkWindow`) — then forces the window onto the active cursor monitor, fullscreens it to host the rich Flutter break UI, and blacks out the other monitors with blocker windows.
  - New native `exitBreak`: restores the window to exactly that prior state. Crucially, a tray-bound/minimized window is hidden (`gtk_widget_hide`, unmapped) **first** and only **then** has its fullscreen/keep-above styles cleared, all within one synchronous native call — so GNOME/Mutter never gets a chance to re-map and flash the UI on screen. A window that was visible before the break is unfullscreened and presented back at its saved bounds (or re-maximized).
  - This **supersedes the earlier Dart "deferred style restoration" approach** (the entry below), which left the window stuck fullscreen or flashed the UI open because the style changes crossed `await` boundaries that let Mutter map the window mid-transition.
  - The Dart side (`desktop_integration_service.dart`) now simply invokes `enterBreak`/`exitBreak` over the `blinkkind/break_overlay` channel; the deferred-restore helpers, `screen_retriever` active-display lookup, saved-bounds tracking, and move/resize listeners were deleted. The rich Flutter break visuals (eye exercises, breathing guides, visualizers) are fully preserved.
  - Verified via a clean release build through `tool/package_linux.sh` (native runner compiles with zero errors, `dist/blinkkind_1.0.0_amd64.deb` produced) and on-device confirmation that tray-hidden, minimized, and visible pre-break states all return silently with no flash.

- Fixed Linux desktop window restoration tray mapping bug: deferred window style changes (such as unfullscreening, decorations, skipTaskbar) until the window is explicitly unminimized or shown via the tray menu. Only the native hiding (`gtk_widget_hide`) or native minimizing (`gtk_window_iconify`) is performed during break exits, preventing compositor/window manager (like GNOME/Mutter) state mapping events from unhiding or flashing the window on the desktop. _(Superseded by the native single-owner `enterBreak`/`exitBreak` fix above.)_

- Implemented dynamic tray icon countdown and status progress rings, alongside platform-level system tray title displaying remaining focus time.

- Implemented CSV and JSON file exports directly to the user's Downloads folder from the History & Insights screen, complete with dynamic OS directory mapping (Linux, macOS, and Windows) and folder-opening actions.

- Implemented keyboard shortcuts for the desktop break overlay (Esc to postpone, Space/Enter to skip in Gentle mode, and holding Space for 3 seconds to exit in Strict mode) utilizing autofocusing KeyboardListeners.

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

- Implemented silent background window restoration:
  - Added tracking of the window's minimized state (_wasMinimizedBeforeBreak) prior to the break overlay.
  - Modified the break exiting sequence to check if the window was minimized or closed to the system tray before the break started.
  - Passed these parameters to C++ hideBlockers channel and implemented them directly in native GTK (`gtk_widget_hide` / `gtk_window_iconify` / `gtk_window_present`).
  - This unminimizes, minimizes, or hides the main window instantly in GTK during the exit transition, enabling silent background restoration and preventing any main UI flashing.

- Resolved window unfullscreening flicker and mapping issues on GTK exit transition:
  - Restructured `hide_blocker_windows` in `my_application.cc` to hide (`gtk_widget_hide`) or minimize (`gtk_window_iconify`) the main window *first* before restoring style attributes (unfullscreen, decorated, keep-above, skip-taskbar).
  - Unified hidden and minimized exit paths: under GNOME/Mutter, mapping a window that was iconified (minimized) via `gtk_widget_show` forces it to deiconify and display on the desktop. To prevent this, both hidden and minimized windows are now hidden directly to the system tray (`gtk_widget_hide`), where their style attributes and bounds are restored silently in the background. The user can restore them seamlessly by clicking the system tray icon.
  - Passed saved window bounds (size, position, maximized state) to C++ to restore them synchronously while the window is hidden or minimized.
  - This prevents window managers (such as Mutter/GNOME on Linux) from mapping or showing the window during style cleanup, ensuring silent restoration to the system tray/dock without any visual flicker or dashboard flashing.

- Fixed Dart-side double-triggering phase completion race condition:
  - Added guards (`_phaseEndsAt == null` and `!_isRunning`) to `_onPhaseComplete()` in `timer_home_page.dart`.
  - This prevents the standard animation controller completion event and the desktop wall-clock `_phaseDeadlineTimer` callback from executing `_onPhaseComplete()` concurrently.
  - Restricted the lifecycle resume clock synchronization (`_syncTimerWithClock()`) to Android only in `didChangeAppLifecycleState`. Since desktop platforms continue executing Dart VM code in the background (and do not freeze), running clock synchronization on window state focus transitions was causing parallel phase projections and state corruption, starting a secondary 3-second break overlay.

- Added real 20-second break test action:
  - Added `Test 20s break screen` to the settings page, which triggers a full, real 20-second break overlay. This enables instant verification of the break layout, exercise animations, and exit window state transitions (minimizing or hiding silently to the system tray/dock).

- Implemented Settings Redesign with Search & Grouping and Theme Expansion:
  - Grouped settings into clean, collapsible cards (`ExpansionTile`s) by categories: General Schedule, Break Screen & Behavior, Theme & Appearance, Notifications & Sounds, Auto Run & Long Breaks, and Desktop Options.
  - Added a search bar that filters settings in real-time as the user types, presenting a flattened list of items decorated with category badges.
  - Expanded appearance configuration to support Material You / OS system-accent colors, AMOLED true black backgrounds, and a premium accent color selector featuring a custom Hex input field and a 10-color circular picker.
  - Updated all settings-related widget tests to explicitly expand category cards and specify the primary Scrollable target, achieving a fully green test suite.
- Implemented AI Health Insight Dashboard Card:
  - Added a new dynamic card directly below the educational learn card on the main dashboard timer screen (both portrait and landscape layouts).
  - Fetches highly specific, engaging, and actionable eye-health and posture tips (restricted to 30 words) for computer developers.
  - Leverages the existing `AiService` LLM client using configured provider, model, API key, and prompt settings.
  - Features dynamic post-frame loading on app initialization and instant configuration updates when settings are modified.
  - Fully supports manual regeneration/refresh and graceful fallback handling (displaying error messages and retry states, including instructions when the API key is missing).
  - Equipment of full widget and unit test coverage verifying display states (enabled, disabled, loading, missing API key error cases).

- Documented Linux build/install options:
  - Created a new [installation.txt](file:///home/jatin/Desktop/JATIN/Flutter/eye-care-timer/installation.txt) file at the root of the project outlining the packaging script and direct DEB installation guide.
  - Documented all command line flags added to `package_linux.sh` (automatic YES/NO modes `-y`/`-n`, state reset control `-c`/`-nc`, and automatic install `-i`/`-ni`).

- Enlarged system tray indicator icon:
  - Increased dynamic system tray icon canvas size from 24x24 to 32x32 in `lib/services/desktop_integration_service.dart`.
  - Scaled the background circle and progress ring bounds, reducing margins/paddings so the icon occupies more vertical space.
  - Increased progress ring stroke thickness to 2.5 and scaled text font sizes (10.0 to 12.5) and graphics for higher contrast, sharpness, and visual appeal in the dock/system tray.

- Implemented Screen Lock and User Presence Inactivity Detection:
  - **Android**: Updated `TimerForegroundService.kt` to subscribe to `Intent.ACTION_USER_PRESENT` and integrated `KeyguardManager`. The app now waits to resume the timer until the user actually unlocks their device rather than immediately when the screen lights up for a notification.
  - **Linux Desktop**: Subscribed to system DBus session signals (`org.gnome.ScreenSaver`, `org.freedesktop.ScreenSaver`, `org.cinnamon.ScreenSaver`, and systemd `org.freedesktop.login1.Session` Lock/Unlock signals) inside `linux/runner/my_application.cc`. Relayed lock/unlock events through method channel `blinkkind/system_lock` directly to Dart, instantly pausing the active countdown when locked, and resuming it when unlocked.

- Fixed desktop break overlay exit screen flicker:
  - Guarded the background break overlay trigger in `didChangeAppLifecycleState` to execute on Android only. This prevents desktop window focus/state transitions during unfullscreening/hiding from re-triggering a secondary break overlay while the Dart-side timer completes its 300ms fade transition.

- Further enlarged system tray indicator icon and progress ring thickness:
  - Increased background circle radius to fill the 32x32 canvas completely to the edges.
  - Increased progress ring stroke thickness from 2.5 to 3.5 for enhanced visual presence.
  - Scaled the central remaining text font size from 12.5 to 14.5 to match the taskbar font height.

- Implemented Two-Stage Warning and Settings Switch:
  - Added a new `twoStageWarningEnabled` preference and setting switch under "Break Screen & Behavior" category to toggle the pre-break warning behavior.
  - Developed Stage 1 Warning (10s to 6s remaining): Pulsing amber edge border (width 6px) with dynamic sine-wave opacity, and a compact translucent top banner containing warning text and actions (Postpone/Cancel).
  - Developed Stage 2 Warning (5s to 0s remaining): Immersive progressive fade-to-black backdrop with large centered countdown typography, prepare-to-rest instruction, and centralized buttons.
  - Bypasses pre-break warnings entirely when the switch is toggled off, jumping straight to the break overlay when the work timer expires.
  - Resolved compiler/import issues with `BackdropFilter` and missing required constructor arguments.
  - Verified and verified correctness through Dart/Flutter static analysis and unit/widget test suites (all 74 tests green).

- Expanded AI Health Insight system prompt:
  - Updated the default system prompt (`TimerSettings.defaultAiCustomSystemPrompt`) to generate general health tips (drinking water regularly, stretching, standing up, shoulder/legs release) as well as eye-care tips.
  - Implemented migration logic in `PreferencesService.loadSettings()` to automatically transition existing installations with unchanged default prompts to the new broader health and wellness prompt.
  - Verified compilation and test suite remains fully correct and functional.

- Fixed Desktop Linux Warning, Previews, and Single AI Message:
  - Added native Linux GTK `enter_warning()` channel method that snapshots window state and brings the main window visible/always-on-top when the 10-second pre-break warning begins, ensuring the warning is visible even when working on another fullscreen Chrome window.
  - Aligned warning state variables so postponing/cancelling during the warning phase restores the window silently back to the tray/minimized state, reusing native window restoration logic.
  - Exposed "Preview break screen" and "Test 20s break screen" unconditionally on desktop settings UI, removing Android-only overlay permission constraints.
  - Cleaned up AI pre-fetching to trigger exactly once per work phase in `_startTimer` and `_postponeBreak` in the background.
  - Cleaned up break overlay screen layout to hide rotating static tip details subtext when `aiQuote` or `customMessage` is active, keeping a single clean focused quote.
  - Verified compilation, analyzer checks, and unit tests pass successfully.

- Fixed desktop tray restore and blink reminder notification spam:
  - Added a dedicated dashboard command for the system tray Show BlinkKind action so restoring from tray always returns to the main dashboard instead of the last visited Settings route.
  - Kept the Settings tray action separate so it still opens Settings intentionally.
  - Added blink reminder bucket/time throttling in the timer page so the animation ticker and desktop wall-clock ticker cannot both emit notifications for the same cadence boundary.
  - Updated Linux blink reminders to reuse/replace the previous notification when notify-send supports notification IDs, with a fallback for older notify-send versions.
  - Verified with flutter analyze.

- Split blink banners from tray blink nudges:
  - Added independent persisted settings for tray blink nudges and tray nudge interval.
  - Kept OS blink banner reminders separately configurable from tray icon pulses.
  - Updated Settings with separate controls for banner interval and tray nudge interval.
  - Raised blink reminder notifications to a visible banner-style channel/urgency while keeping them silent.
  - Verified with flutter analyze and focused settings/model tests.

- Made blink notification action buttons optional:
  - Added a persisted `blinkReminderInteractiveEnabled` setting and Settings switch under blink reminders.
  - Threaded the setting from App to TimerHomePage and into `NotificationService.showBlinkReminder()`.
  - Split Android blink notification details into interactive and non-interactive variants; both remain silent high-importance banner notifications, but the non-interactive path has no action button.
  - Included the setting in backup/restore JSON and default reset paths.
  - Verified with flutter analyze plus focused settings/model tests.

- Added Linux support for interactive blink notification actions:
  - Replaced the Linux blink reminder path with a freedesktop notification DBus call when available, allowing the `I blinked` action to be included while still receiving a replacement notification ID.
  - Kept a notify-send fallback for environments where DBus notification calls fail.
  - Preserved non-interactive Linux reminders by sending an empty action list when the interactive toggle is disabled.
  - Verified with flutter analyze.

- Fixed conscious blink history updates from notification actions:
  - Added Linux DBus `ActionInvoked` monitoring for blink reminder notification IDs so clicking `I blinked` emits an acknowledgement event.
  - Routed Linux acknowledgements into the same `TimerEventType.blinkReminderAcknowledged` history path used by Android notification actions.
  - Added a live timer event notifier from `App` to `HistoryPage` so an already-open Productivity Insights view updates immediately when a blink is logged.
  - Verified with flutter analyze and a focused timer-event persistence test.

- Hardened conscious blink history syncing:
  - Replaced the per-notification Linux action watcher with a persistent DBus ActionInvoked monitor so `I blinked` clicks are not missed by timing races.
  - Added a History refresh button that reloads daily history, work sessions, and timer event records directly from storage.
  - Wired refresh results back into the live timer event notifier so Productivity Insights can resync immediately.
  - Verified with flutter analyze and the focused TimerEventRecord persistence test.

- Implemented AI Wellness & Focus Reports and Dashboard Navigation Button:
  - Added a required `openHistory` navigation callback to `TimerHomePage` and placed a direct history icon button (`Icons.bar_chart`) on the dashboard's `AppBar` to navigate directly to the Productivity Insights page.
  - Added an **AI Wellness & Focus Report** card directly below the metrics grid on the `HistoryPage`.
  - Fed range-specific statistics (focus time, goal rate, daily streak, peak focus hour, break compliance rate, skipped/postponed breaks, and conscious blinks) into the `AiService` LLM call to generate a customized, occupational health-focused wellness report.
  - Implemented loading, error-fallback, retry, and stale-range regeneration states for the AI report.
  - Added focused widget test coverage to verify direct dashboard navigation and all states of the AI report card.

- Fixed Linux desktop tray countdown skipping seconds:
  - Added a vsync frame rendering tick/heartbeat field `_lastAnimationTickAt` in `_TimerHomePageState` that updates on every frame draw.
  - Refactored the periodic desktop tray ticker `_onDesktopTrayTick` to check if frame animation rendering is frozen (e.g. when minimized/hidden on Linux).
  - If frozen, the tray ticker updates the remaining seconds and tray state on every tick, ensuring a smooth, correct-to-the-second countdown display.

- Fixed Linux blink reminders stacking in history tray:
  - Updated `_showLinuxBlinkReminder` in `NotificationService` to explicitly close the previous notification via `cancelBlinkReminder()` before showing a new one.
  - This ensures that old notification cards are dismissed and removed from both the screen and the system history tray, preventing multiple notifications from piling up.
  - Verified compilation, analyzer checks, and unit tests pass successfully.

- Polished Linux system idle detection and natural break crediting:
  - Adjusted system-idle tracking to subtract the 60-second detection threshold from `_idleStartedAt` when triggered by the system idle monitor, ensuring the 60 seconds is included in the user's computed idle duration.
  - Screen lock events continue to use the immediate lock timestamp, as screen locks represent immediate idle starts.
  - Updated `_creditNaturalBreak` to calculate and save any completed focus time (`_initialDuration - _remainingSeconds`) as a completed work session before resetting the timer, preventing users from losing progress on partially completed work sessions when interrupted by natural breaks.
  - Verified compilation, analyzer checks, and unit tests pass successfully.

- Implemented Postpone and Skip action buttons on work-complete notifications:
  - Created a new `_workCompleteNotificationDetails` in `NotificationService` that includes "Postpone" and "Skip" action buttons for Android local notifications.
  - Generalized the Linux D-Bus `ActionInvoked` stream monitor using a RegExp to extract the invoked action ID and propagate it to `_notificationResponseController`.
  - Added `-A` action button flags to the `notify-send` CLI command on Linux when scheduling work-complete reminders.
  - Updated `_handleNotificationResponse` in `app.dart` to listen to `'postpone_break'` and `'skip_break'` responses and trigger command execution.
  - Exposed `_desktopCommandSubscription` unconditionally in `TimerHomePageState` so that notification actions can trigger timer phase changes on all platforms.
  - Verified compilation, analyzer checks, and unit tests pass successfully.

- Updated desktop launcher routing in packaging:
  - Updated `Exec` path in packaged desktop entry (.desktop) templates to point directly to `/opt/blinkkind/eye_care_timer %u`.
  - Replaced `/usr/bin/blinkkind` wrapper scripts (for both DEB and RPM packages) with a shell script that checks for the presence of `gtk-launch` and executes the application via `gtk-launch blinkkind.desktop` (falling back to direct binary execution if unavailable).
  - This ensures that execution of the application from any command line wrapper is routed through the desktop launcher database, preserving correct session properties.
  - Verified compilation and test suite continues to pass.

- Fixed notifications lingering on application exit:
  - Imported `NotificationService` in `DesktopIntegrationService` and called `cancelBlinkReminder()` within the `_quitApp` exit handler on desktop platforms.
  - This ensures that when the user chooses "Exit" from the system tray menu, any active/on-screen blink reminder notifications are dismissed automatically via D-Bus instead of remaining in the notification center.
  - Verified compilation and test suite continues to pass.

- Fixed tray Settings menu item not opening Settings page on Linux:
  - Separated the dashboard redirection logic (`showDashboard`) from the general `_showWindow` window restoration method.
  - Placed the `showDashboard` trigger explicitly on the "Show BlinkKind" tray menu items and non-Linux tray click/double-click events.
  - This prevents the Linux tray icon's click event (which fires when showing/opening the menu) from queuing a dashboard redirect that immediately pops the user back to the dashboard when they click the "Settings" menu item.
  - Verified compilation and test suite continues to pass.
- Fixed countdown timer floating point precision bug:
  - Replaced the countdown timer remaining seconds calculation in the animation listener with a robust integer rounding of the elapsed controller value fraction (`_initialDuration - (_animationController.value * _initialDuration).round()`).
  - This prevents double precision floating point inaccuracies (e.g., at the 5-second tick of a 15-second timer, 15 * (1.0 - 0.3333333333333333).ceil() evaluated to 11 instead of 10), which previously skipped certain integer seconds (like 10) entirely and broke warning curtain widget expectations.
  - Verified compilation and confirmed all unit/widget tests (including the warning curtain test) pass successfully.
- Reverted and removed the Two-Stage Warning Curtain feature entirely:
  - Removed `twoStageWarningEnabled` from `TimerSettings`, `PreferencesService`, and all associated toggle switches on the Settings Page.
  - Removed stage warning curtains, method channel triggers (`enterWarning`), Vignette overlays, and related animation listener checks from `lib/features/timer/timer_home_page.dart`.
  - Cleaned up and deleted the two-stage warning curtain widget test from `test/widget_test.dart`.
  - Verified static analysis and all unit/widget tests pass cleanly.

- Implemented chime-on-blink-notification-tap:
  - Added a new `DesktopCommand.playChime` variant to `DesktopControlsController` so any part of the app can signal `TimerHomePage` to play the current chime sound.
  - Handled `DesktopCommand.playChime` in `TimerHomePage`'s command switch by calling the existing `_playChime()` method, which respects both `soundEnabled` and `chimeStyle` settings.
  - Updated `_handleNotificationResponse` in `app.dart` to dispatch `playChime` immediately after recording a `blink_done` action, providing audio confirmation when the user taps "I blinked! 👁️" from the Android notification shade.
  - Updated the `onBlinkReminderAcknowledged` listener (the Linux D-Bus path) in `app.dart` to also dispatch `playChime`, ensuring the same chime fires on Linux after the D-Bus `ActionInvoked` event is received.
  - Fixed an orphaned `_blinkChannel` reference in `NotificationService.initialize()` that was a pre-existing compile-time error (the per-chime channel is now built lazily inside `showBlinkReminder()`).
  - Verified `flutter analyze` reports no issues and all previously-passing tests continue to pass.

- Completed Small UI/UX Tasks 11, 12, and 13:
  - **Task 11 (Smooth Theme Transitions)**: Configured MaterialApp with `themeAnimationDuration: const Duration(milliseconds: 200)` and `themeAnimationCurve: Curves.easeInOut` in `lib/app.dart` to smoothly cross-fade when toggling between light and dark themes.
  - **Task 12 (Live Accent Color Preview)**: Enhanced Custom Accent Color preferences in `lib/features/settings/settings_page.dart` with an immediate `onChanged` listener that updates the accent color as the user types/interacts. Added a live preview widget directly below the input field that displays a miniature timer dial and action button dynamically themed to the selected color.
  - **Task 13 (Eye Health Score Chart & Metric)**: Rebranded "Break compliance / Compliance Rate" metrics to "Eye Health Score" (breaks taken / breaks scheduled × 100) across daily logs, statistics grids, and tooltips. Renamed the chart's segmented selector segment to "Eye Health" with a custom wellness heart icon and configured it to paint a beautiful green/teal gradient bar when the 80% goal threshold is met.
  - Verified compilation and static analysis are completely clean.
---

## UI/UX Future Improvements Backlog (planned 2026-06-27)

Ideas captured from design review session. Prioritized by impact. None are scheduled yet — pick from here in a future session.

### 🔥 High Impact (visible, feels premium)

- [x] **Animated eye icon on timer home screen** — replace the static progress ring center with a vector eye that blinks naturally every few seconds and pulses on phase transitions (work → break → work). Clearest on-brand differentiator on the home screen.
- [x] **Breathing animation during breaks** — an expand/contract soft-glow circle behind the break card to encourage slow breathing; pairs with the existing guided exercises. Single `AnimationController` looping on a 4-second inhale/exhale curve.
- [x] **Smooth work→break phase transition animation** — a brief full-screen white (or theme-accent) flash / crossfade when the work phase ends and the break begins, so the transition feels intentional rather than abrupt.
- [x] **Color-coded gradient timer ring** — the progress arc shifts from a calm green → amber → orange as remaining time drops below 25% and 10%, giving the user a passive urgency signal without text.
- [x] **Streak milestone celebrations** — confetti burst / gold glow animation when the user hits streak milestones (5, 10, 25, 50 consecutive days). Reuse existing `streakCount` data; trigger once per milestone per day.

### 🟡 Medium Impact (polish & feel)

- [ ] **Compact Android home-screen widget redesign** — the current widget is functional but plain; give it a sleek minimal card style with the ring, phase label, and countdown typeset in the app's Inter font.
- [ ] **Break countdown ring on the break screen itself** — a subtle thin ring around the break card showing how much of the break has elapsed, so users can gauge progress without needing to read the number.
- [ ] **Haptic feedback patterns by event** — distinct vibration patterns for work-phase-complete vs. break-start vs. blink-reminder vs. postpone, instead of the current uniform haptic pulse.
- [ ] **Settings page sectioned cards** — group the flat settings list into visually distinct card sections with section header chips, so the page feels organized rather than a long scrollable list.
- [ ] **Onboarding flow improvement** — replace the current static onboarding text with a short animated explainer of the 20-20-20 rule (animated eye, animated 20ft/6m target, animated 20s clock).
- [x] **Chime in blink interactive notifications** — play the selected chime sound when the user taps the "I blinked! 👁️" notification action. On Android, assign the chime as the notification channel sound (works without the app being open). On Linux, play via the existing notification callback.

### 🟢 Small but Nice

- [x] **Dark/Light mode transition animation** — instead of an instant theme snap, fade between themes over ~200ms using a color-tween overlay.
- [x] **Custom accent color live preview** — in Settings, the accent color picker should show a mini live-preview of the timer ring and break button in the chosen color as the user drags.
- [x] **History page weekly eye health score** — replace or augment the raw session list with a 7-day bar chart showing "eye health score" (breaks taken / breaks scheduled × 100) per day, giving users a meaningful wellness metric.

