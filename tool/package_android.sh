#!/bin/bash
set -e

# Define directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DIST_DIR="$PROJECT_DIR/dist"

# ---------------------------------------------------------------------------
# Dynamically resolve Flutter binary
# ---------------------------------------------------------------------------
resolve_flutter() {
    if command -v flutter &>/dev/null; then
        echo "$(command -v flutter)"
        return
    fi

    local candidates=(
        "$HOME/development/flutter/bin/flutter"
        "$HOME/flutter/bin/flutter"
        "/opt/flutter/bin/flutter"
        "/usr/local/flutter/bin/flutter"
    )
    for candidate in "${candidates[@]}"; do
        if [ -x "$candidate" ]; then
            echo "$candidate"
            return
        fi
    done

    if [ -n "$FLUTTER_HOME" ] && [ -x "$FLUTTER_HOME/bin/flutter" ]; then
        echo "$FLUTTER_HOME/bin/flutter"
        return
    fi

    echo ""
}

FLUTTER="$(resolve_flutter)"
if [ -z "$FLUTTER" ]; then
    echo "Error: Flutter SDK not found."
    echo "Please ensure 'flutter' is on your PATH or set FLUTTER_HOME to your Flutter SDK directory."
    exit 1
fi
echo "Using Flutter: $FLUTTER"

# ---------------------------------------------------------------------------
# Check Android SDK path
# ---------------------------------------------------------------------------
resolve_android_sdk() {
    # 1. Check local.properties
    if [ -f "$PROJECT_DIR/android/local.properties" ]; then
        local sdk_prop
        sdk_prop=$(grep 'sdk.dir' "$PROJECT_DIR/android/local.properties" | cut -d'=' -f2-)
        if [ -d "$sdk_prop" ]; then
            echo "$sdk_prop"
            return
        fi
    fi

    # 2. Check environment variables
    if [ -d "$ANDROID_HOME" ]; then
        echo "$ANDROID_HOME"
        return
    fi
    if [ -d "$ANDROID_SDK_ROOT" ]; then
        echo "$ANDROID_SDK_ROOT"
        return
    fi

    # 3. Common paths
    local candidates=(
        "$HOME/development/android"
        "$HOME/Android/Sdk"
        "/usr/lib/android-sdk"
    )
    for candidate in "${candidates[@]}"; do
        if [ -d "$candidate" ]; then
            echo "$candidate"
            return
        fi
    done

    echo ""
}

ANDROID_SDK="$(resolve_android_sdk)"
if [ -z "$ANDROID_SDK" ]; then
    echo "Error: Android SDK not found."
    echo "Please specify sdk.dir in android/local.properties or set ANDROID_HOME."
    exit 1
fi
echo "Using Android SDK: $ANDROID_SDK"

# ---------------------------------------------------------------------------
# Resolve compatible Java version (Gradle/Kotlin fails with Java 25+)
# ---------------------------------------------------------------------------
resolve_java() {
    local sys_java_ver=""
    if command -v java &>/dev/null; then
        sys_java_ver=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2)
    fi

    # If system java is compatible, use it
    if [ -n "$sys_java_ver" ] && [[ ! "$sys_java_ver" =~ ^25 ]]; then
        echo "system"
        return
    fi

    # Otherwise, search for a compatible Java (JDK 11, 17, or 21)
    local candidates=(
        "$HOME/development/jdk-21"
        "$HOME/.antigravity/extensions/redhat.java-1.53.0-linux-x64/jre/21.0.10-linux-x86_64"
        "$HOME/.cursor/extensions/redhat.java-1.53.0-linux-x64/jre/21.0.10-linux-x86_64"
        "/usr/lib/jvm/java-21-openjdk"
        "/usr/lib/jvm/java-17-openjdk"
        "/usr/lib/jvm/java-11-openjdk"
        "/opt/android-studio/jbr"
        "$HOME/android-studio/jbr"
    )

    for candidate in "${candidates[@]}"; do
        if [ -x "$candidate/bin/java" ]; then
            local ver
            ver=$("$candidate/bin/java" -version 2>&1 | head -n 1 | cut -d'"' -f2)
            if [[ ! "$ver" =~ ^25 ]]; then
                echo "$candidate"
                return
            fi
        fi
    done

    echo ""
}

COMPAT_JAVA="$(resolve_java)"
if [ -z "$COMPAT_JAVA" ]; then
    echo "Warning: No compatible Java JDK (11, 17, or 21) was found automatically."
    echo "If your system Java version is 25+, the Android Gradle build might fail."
elif [ "$COMPAT_JAVA" = "system" ]; then
    echo "Using system Java JDK."
else
    echo "Setting JAVA_HOME to compatible JDK: $COMPAT_JAVA"
    export JAVA_HOME="$COMPAT_JAVA"

    # Force Gradle to stop any existing daemons running on an incompatible Java version
    if [ -f "$PROJECT_DIR/android/gradlew" ]; then
        echo "Stopping running Gradle daemons to ensure Java compatibility..."
        (cd "$PROJECT_DIR/android" && ./gradlew --stop) >/dev/null 2>&1 || true
    fi
fi

# ---------------------------------------------------------------------------
# Extract version from pubspec.yaml
# ---------------------------------------------------------------------------
VERSION=$(grep 'version: ' "$PROJECT_DIR/pubspec.yaml" | sed 's/version: //' | cut -d'+' -f1 | tr -d '[:space:]')
if [ -z "$VERSION" ]; then
    VERSION="1.0.0"
fi

# Parse options
BUILD_APK=true
BUILD_AAB=true

for arg in "$@"; do
    case "$arg" in
        --apk-only)
            BUILD_AAB=false
            ;;
        --aab-only)
            BUILD_APK=false
            ;;
    esac
done

# Run builds
mkdir -p "$DIST_DIR"
cd "$PROJECT_DIR"

if [ "$BUILD_APK" = "true" ]; then
    echo "========================================="
    echo "Building Android APK (Release)..."
    echo "========================================="
    "$FLUTTER" clean
    "$FLUTTER" build apk --release

    SRC_APK="$PROJECT_DIR/build/app/outputs/flutter-apk/app-release.apk"
    DEST_APK="$DIST_DIR/blinkkind_${VERSION}.apk"
    if [ -f "$SRC_APK" ]; then
        cp "$SRC_APK" "$DEST_APK"
        echo "✓ Copied APK to $DEST_APK"
    else
        echo "Error: APK build succeeded but output file not found."
        exit 1
    fi
fi

if [ "$BUILD_AAB" = "true" ]; then
    echo "========================================="
    echo "Building Android App Bundle (Release)..."
    echo "========================================="
    # Clean the build directory to avoid Gradle/R8 intermediate conflicts between APK and AAB builds
    "$FLUTTER" clean
    "$FLUTTER" build appbundle --release

    SRC_AAB="$PROJECT_DIR/build/app/outputs/bundle/release/app-release.aab"
    DEST_AAB="$DIST_DIR/blinkkind_${VERSION}.aab"
    if [ -f "$SRC_AAB" ]; then
        cp "$SRC_AAB" "$DEST_AAB"
        echo "✓ Copied App Bundle to $DEST_AAB"
    else
        echo "Error: App Bundle build succeeded but output file not found."
        exit 1
    fi
fi

echo "========================================="
echo "✓ Android build(s) complete! Outputs located in $DIST_DIR"
echo "========================================="
