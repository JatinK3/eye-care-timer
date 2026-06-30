# BlinkKind: Eye Break Timer 👁️⏱️

A beautiful, highly customizable Flutter-based 20-20-20 eye break timer that helps developers and heavy computer users protect their vision. With automatic schedules, streak tracking, intelligent auto-postpone, AI wellness reminders, and gorgeous theme presets, BlinkKind keeps your eyes fresh without interrupting your deep focus.

## ✨ Core Features
- **The 20-20-20 Rule:** Automatically prompts you to take a 20-second break every 20 minutes to look 20 feet away.
- **Smart Auto-Postpone (Linux & Android):** Detects active microphone or camera usage (e.g., during Zoom/Meet calls) and automatically postpones eye breaks so you aren't disturbed during meetings.
- **AI Wellness Coach:** Interactive, AI-generated micro-reminders for stretching, hydration, and posture.
- **Sleek, Distraction-Free UI:** Built with Material 3, glassmorphism, dynamic gradients, smooth animations, and a pulsing eye mascot.
- **Accessibility / Reduced Motion:** Optional support for disabling animations and full-screen color flashes for motion-sensitive users.
- **In-Depth Analytics:** Visualizes your eye health score, daily goals, and historical compliance streaks.
- **Cross-Platform System Integrations:** Native Linux tray icon (with dynamic rendering), Android foreground service, and Android home-screen widget.

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.27+ recommended)
- Android Studio / VS Code (with Flutter & Dart plugins)
- **Linux:** Requires `dbus`, `fuser`, `pactl`, and standard build tools (`gcc`, `cmake`, `ninja-build`).

### Run Locally

1. **Clone the repository:**
   ```bash
   git clone https://github.com/JatinK3/eye-care-timer.git
   cd eye-care-timer
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

---

## 🛠️ Build and Installation

BlinkKind comes with a suite of automated build scripts in the `tool/` directory to simplify packaging for Android and Linux.

### Linux (Debian/Fedora/Arch)
To automatically resolve dependencies and build native `.deb` or `.rpm` packages:

```bash
# Optional: Install necessary C/C++ libraries and build dependencies first
./tool/lib_resolver.sh

# Build Linux packages (.deb / .rpm / .tar.gz)
./tool/package_linux.sh
```
*Note: `package_linux.sh` automatically installs the desktop entry and icon into the system so BlinkKind will appear in your application launcher instantly.*

To explicitly clear existing settings data on install, pass `-c` or `--clear-state`. To cleanly reinstall, pass `-R` or `--reinstall`.

### Android (APK & App Bundle)
To build a release APK or AAB for the Play Store (automatically detects JDK and Android SDK paths):

```bash
./tool/package_android.sh
```

---

## 🎮 How to Use

1. **Launch the App:** You will be greeted by an interactive onboarding sequence that teaches you the 20-20-20 rule.
2. **Start the Timer:** Press "Start Focus Session" from the dashboard. 
3. **Work Phase:** The central ring glows green/blue. You can minimize the app; it will run in the background (Linux system tray or Android foreground notification).
4. **Blink Nudges:** Hear a subtle chime or haptic click reminding you to blink naturally while you work.
5. **Take a Break:** When 20 minutes pass, the screen flashes (or a high-priority notification appears). Look 20 feet away for 20 seconds. 
6. **Track your Health:** Check the Insights tab to see your daily Eye Health Score and streak.

---

## 📸 Screenshots

![UI](https://github.com/user-attachments/assets/dd4eb8ad-6709-4b62-bde6-53ec325a599a)
![UI2](https://github.com/user-attachments/assets/4536063c-f0c8-4d93-a101-7a78a57fa8a6)
![UI3](https://github.com/user-attachments/assets/c572ebc1-c075-4b85-a2c2-b7285ee1b090)
![Ui4](https://github.com/user-attachments/assets/269f62b6-4eb7-4e4e-87fd-aa4c93120a80)

---

## 🤝 Contributing
Contributions, issues, and feature requests are welcome!
Feel free to open a PR or raise an issue on GitHub.
