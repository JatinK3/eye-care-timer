# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
