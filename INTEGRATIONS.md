# Integrations

This document records integration decisions, constraints, and implementation context that should survive across feature phases.

## Health Data: Health Connect and Apple Health

**Status:** Discovery complete on 2026-07-21. Implementation has not started.

### Platform Decision

Use **Health Connect** for new Android health-data work. Do not build a new Google Fit integration: Google Fit APIs are deprecated and supported only through the end of 2026. Health Connect is an on-device, user-permissioned store; it does not provide Google-account or cross-device cloud synchronization.

BlinkKind remains the source of truth for timer events and its own history. Any future cloud or cross-device sync is a separate product integration.

### Existing BlinkKind Data

- `TimerEventRecord` has stable event IDs, timestamps, types, durations, and optional mood.
- `WorkSessionRecord` stores completed focus sessions.
- Hydration currently stores daily glass totals and day-level history only.
- Full backup/export includes timer, work-session, hydration, and settings data.

The existing hydration data must not be backfilled into a health store: daily totals have no exact intake timestamps, and inventing them would create inaccurate health records. From the release that enables health sync onward, each logged glass must be written locally as an individual intake event.

### Data Boundaries

| BlinkKind action | Health representation | Rule |
| --- | --- | --- |
| User logs a glass | `HydrationRecord` / Apple Health water sample | One exact-volume, timestamped manual record. |
| User undoes or corrects a glass | Update/delete matching record | Never write an offsetting duplicate. |
| Standard eye break, skipped break, focus block | None | These are not workouts or medical data. |
| Completed, explicitly selected Box Breathing guide | Mindfulness session, feature-gated | Consider only after hydration sync is stable. |
| External hydration record | Read-only connected data | Retain origin and external ID; never write it back. |

### Architecture Requirements

1. Add a platform-neutral `HealthSyncService` interface.
2. Store a persisted, retryable outbox for operations. A notification-action isolate may record an intake locally but must not call a health API; the app flushes pending work while foregrounded.
3. Every outbound record must use the local event ID as its remote client record ID/version, or the implementation must persist an equivalent remote ID. Retried operations must be idempotent.
4. Verify whether the Flutter `health` package exposes the client ID, version, update, and delete behavior needed for this guarantee. Use a small Kotlin Health Connect bridge if it does not.
5. Health permission loss, cancellation, unavailability, update-required state, and sync failures must be visible but never block normal timer or hydration use.

### Phased Delivery

#### Phase 0: Adapter and Data-Model Spike

- Add the individual hydration event/outbox model and service boundary.
- Validate availability, permission, idempotent write, update/delete, and retry behavior on a real Android device.
- Do not add a settings toggle or request production permissions until this is proven.

#### Phase 1: Write-Only Hydration

- Add `Sync with Health Connect`, provider availability/install/update guidance, sync status, and `Manage access` to Settings.
- Request only `WRITE_HYDRATION`.
- Sync new BlinkKind intake events, including notification-action events after foreground flush.
- Do not request read permission or backfill history.

#### Phase 2: Connected Wellness View

- Offer a second, explicit opt-in for `READ_HYDRATION`.
- Show a clearly attributed, read-only connected total beside BlinkKind's total.
- Define duplicate and source-conflict handling before presenting a combined number.
- Refresh on foreground/manual refresh only; background reads are unnecessary.

#### Phase 3: Guided Mindfulness

- Check Health Connect's mindfulness feature availability.
- Sync only completed Box Breathing sessions, with the correct mindfulness type.
- Do not infer mindfulness or exercise from ordinary break completion.

#### Phase 4: Apple Health Parity

- Reuse the local outbox and service contract for HealthKit water samples.
- Add HealthKit entitlement, usage strings, platform-specific permission UX, and iPhone device validation.

### Permission and Release Requirements

- Health Connect is supported on Android 9+ with Google Play services. Android 14+ includes the provider in the system; Android 9-13 may require the Health Connect app.
- Request the minimum data type only at the moment its user-facing feature is enabled. Settings must let users stop syncing and manage their health-store access.
- Before Google Play release, complete the Health apps declaration, Data safety disclosure, privacy-policy justification, and permission explanation for every requested data type.
- Validate Android 9-16 availability, permissions denied/revoked twice, provider update, offline/retry, app restart, undo/correction, duplicate prevention, and notification-action logging.

### Sources

- [Google Fit migration guide](https://developer.android.com/health-and-fitness/health-connect/migration/fit)
- [Health Connect availability](https://developer.android.com/health-and-fitness/health-connect/availability)
- [Health Connect data types](https://developer.android.com/health-and-fitness/health-connect/data-types)
- [Health Connect permission UX](https://developer.android.com/health-and-fitness/health-connect/ui/permissions)
- [Google Play health-app declaration](https://developer.android.com/health-and-fitness/health-connect/publish)
- [Flutter health package](https://pub.dev/packages/health)
