#!/bin/bash
# lib_resolver.sh — Native Linux dependency checker & installer for BlinkKind
#
# Ensures all system libraries required by the Flutter plugins are present
# before attempting a build. Supports apt-based (Ubuntu/Debian) and
# dnf-based (Fedora/RHEL/CentOS) distributions.
#
# Usage (standalone):   bash tool/lib_resolver.sh
# Usage (from script):  source tool/lib_resolver.sh && resolve_build_deps
#
# Set LIB_RESOLVER_DRY_RUN=1 to only print what would be installed.
# Set LIB_RESOLVER_QUIET=1   to suppress info-level output.

set -e

# ── helpers ─────────────────────────────────────────────────────────────────

_lr_info()  { [ "${LIB_RESOLVER_QUIET:-0}" = "1" ] || echo "  [lib_resolver] $*"; }
_lr_ok()    { echo "  ✓ $*"; }
_lr_warn()  { echo "  ⚠ $*" >&2; }
_lr_error() { echo "  ✗ $*" >&2; }

# ── distro detection ─────────────────────────────────────────────────────────

detect_pkg_manager() {
    if command -v apt-get &>/dev/null; then
        echo "apt"
    elif command -v dnf &>/dev/null; then
        echo "dnf"
    elif command -v yum &>/dev/null; then
        echo "yum"
    elif command -v pacman &>/dev/null; then
        echo "pacman"
    else
        echo "unknown"
    fi
}

# ── dependency map ───────────────────────────────────────────────────────────
# Format per entry: "check|apt_pkg|dnf_pkg|description"
#   check prefixes:
#     pkgcfg:<name>  → pkg-config --exists <name>
#     header:<path>  → checks /usr/include/<path>
#     (plain)        → command -v check

declare -a BUILD_DEPS=(
    # Core build tools
    "cmake|cmake|cmake|CMake build system"
    "ninja|ninja-build|ninja-build|Ninja build tool"
    "pkg-config|pkg-config|pkgconf-pkg-config|pkg-config tool"
    "clang|clang|clang|Clang C/C++ compiler"
    "patchelf|patchelf|patchelf|patchelf (fixes plugin .so RPATHs for RPM packaging)"

    # GTK / GLib (Flutter Linux embedder + file_picker + system_tray)
    "pkgcfg:gtk+-3.0|libgtk-3-dev|gtk3-devel|GTK3 development headers"
    "pkgcfg:glib-2.0|libglib2.0-dev|glib2-devel|GLib/GIO development headers"

    # Sentry → libcurl
    "pkgcfg:libcurl|libcurl4-openssl-dev|libcurl-devel|libcurl development headers (Sentry)"

    # hotkey_manager → keybinder-3.0
    "pkgcfg:keybinder-3.0|libkeybinder-3.0-dev|keybinder3-devel|keybinder-3.0 (hotkey_manager)"

    # system_tray → ayatana-appindicator3
    "pkgcfg:ayatana-appindicator3-0.1|libayatana-appindicator3-dev|libayatana-appindicator-gtk3-devel|ayatana-appindicator3 dev (system_tray)"

    # window_manager / screen_retriever → X11 + XTest
    "pkgcfg:x11|libx11-dev|libX11-devel|X11 development headers"
    "pkgcfg:xtst|libxtst-dev|libXtst-devel|XTest extension (window_manager)"

    # flutter_local_notifications → libnotify
    "pkgcfg:libnotify|libnotify-dev|libnotify-devel|libnotify (flutter_local_notifications)"

    # audioplayers → GStreamer
    "pkgcfg:gstreamer-1.0|libgstreamer1.0-dev|gstreamer1-devel|GStreamer core (audioplayers)"
    "pkgcfg:gstreamer-plugins-base-1.0|libgstreamer-plugins-base1.0-dev|gstreamer1-plugins-base-devel|GStreamer plugins-base"

    # launch_at_startup → GIO/DBus
    "pkgcfg:gio-2.0|libglib2.0-dev|glib2-devel|GIO (launch_at_startup)"

    # Runtime: ayatana-appindicator (needed at runtime for the built binary)
    "pkgcfg:ayatana-appindicator3-0.1|libayatana-appindicator3-1|libayatana-appindicator-gtk3|ayatana-appindicator3 runtime"
)

# ── optional runtime tools ────────────────────────────────────────────────────
# These are NOT required for the build to succeed, but enhance runtime features.
# Format: "check|apt_pkg|dnf_pkg|pacman_pkg|description|why_useful"
declare -a OPTIONAL_RUNTIME_DEPS=(
    # playerctl: MPRIS media player controller — used by the auto-pause media
    # filter to reliably classify browser audio streams (YouTube Music vs YouTube
    # video) via xesam:url when pactl media.role metadata is not available.
    "playerctl|playerctl|playerctl|playerctl|playerctl (MPRIS media controller)|Improves 'Music only' / 'Video only' auto-pause accuracy for browser streams (e.g. YouTube Music vs YouTube)"
)

# ── check helpers ─────────────────────────────────────────────────────────────

check_dep() {
    local check="$1"
    if [[ "$check" == pkgcfg:* ]]; then
        pkg-config --exists "${check#pkgcfg:}" 2>/dev/null
    elif [[ "$check" == header:* ]]; then
        local hdr="${check#header:}"
        [ -f "/usr/include/$hdr" ] || [ -f "/usr/local/include/$hdr" ]
    else
        command -v "$check" &>/dev/null
    fi
}

# ── install helpers ───────────────────────────────────────────────────────────

_do_install() {
    local pkg_manager="$1" pkg="$2"
    if [ "${LIB_RESOLVER_DRY_RUN:-0}" = "1" ]; then
        _lr_info "DRY-RUN: would install → $pkg"
        return 0
    fi
    case "$pkg_manager" in
        apt)    sudo apt-get install -y "$pkg" ;;
        dnf)    sudo dnf install -y "$pkg" ;;
        yum)    sudo yum install -y "$pkg" ;;
        pacman) sudo pacman -S --noconfirm "$pkg" ;;
    esac
}

# ── main resolver function ────────────────────────────────────────────────────

resolve_build_deps() {
    local pkg_manager
    pkg_manager="$(detect_pkg_manager)"

    echo ""
    echo "========================================="
    echo "Checking Linux build dependencies..."
    echo "  Package manager detected: $pkg_manager"
    echo "========================================="

    if [ "$pkg_manager" = "unknown" ]; then
        _lr_warn "No supported package manager found (apt / dnf / yum / pacman)."
        _lr_warn "Please manually install these libraries:"
        _lr_warn "  keybinder-3.0, gtk3, ayatana-appindicator3, libX11, libXtst,"
        _lr_warn "  libnotify, gstreamer-1.0, gstreamer-plugins-base-1.0, glib2"
        echo "========================================="
        echo ""
        return 0
    fi

    local apt_updated=false
    local missing_pkgs=()
    local seen_pkgs=()

    for entry in "${BUILD_DEPS[@]}"; do
        IFS='|' read -r check apt_pkg dnf_pkg desc <<< "$entry"

        local target_pkg
        case "$pkg_manager" in
            apt)             target_pkg="$apt_pkg" ;;
            dnf|yum|pacman)  target_pkg="$dnf_pkg" ;;
        esac

        # Deduplicate
        local already_queued=false
        for seen in "${seen_pkgs[@]}"; do
            [ "$seen" = "$target_pkg" ] && already_queued=true && break
        done
        $already_queued && continue
        seen_pkgs+=("$target_pkg")

        if check_dep "$check"; then
            _lr_ok "$desc"
        else
            _lr_warn "MISSING → $desc  (package: $target_pkg)"
            missing_pkgs+=("$target_pkg")
        fi
    done

    if [ ${#missing_pkgs[@]} -eq 0 ]; then
        echo ""
        _lr_ok "All build dependencies are satisfied."
        echo "========================================="
        echo ""
        return 0
    fi

    echo ""
    echo "  Packages to be installed:"
    for pkg in "${missing_pkgs[@]}"; do
        echo "    • $pkg"
    done
    echo ""

    # Respect AUTO_YES inherited from package_linux.sh, or prompt interactively
    local do_install="n"
    if [ "${AUTO_YES:-false}" = "true" ]; then
        do_install="y"
    elif [ -t 0 ]; then
        read -rp "  Install missing packages now? (Y/n): " do_install
        do_install="${do_install:-y}"
    fi

    if [[ "$do_install" =~ ^[Yy]$ ]]; then
        # apt: update index once before installing
        if [ "$pkg_manager" = "apt" ] && ! $apt_updated; then
            _lr_info "Running: sudo apt-get update"
            [ "${LIB_RESOLVER_DRY_RUN:-0}" = "1" ] || sudo apt-get update -qq
            apt_updated=true
        fi

        local failed=()
        for pkg in "${missing_pkgs[@]}"; do
            _lr_info "Installing: $pkg"
            if _do_install "$pkg_manager" "$pkg"; then
                _lr_ok "Installed $pkg"
            else
                _lr_error "Failed to install $pkg"
                failed+=("$pkg")
            fi
        done

        echo ""
        if [ ${#failed[@]} -gt 0 ]; then
            _lr_warn "Some packages could not be installed automatically:"
            for pkg in "${failed[@]}"; do
                _lr_warn "  • $pkg"
            done
            _lr_warn "Please install them manually before building."
        else
            _lr_ok "All missing dependencies installed successfully."
        fi
    else
        echo ""
        _lr_warn "Skipped. Build may fail if libraries are missing."
    fi

    echo "========================================="
    echo ""
}

# ── optional runtime deps check ───────────────────────────────────────────────

check_optional_deps() {
    local pkg_manager
    pkg_manager="$(detect_pkg_manager)"

    echo ""
    echo "========================================="
    echo "Checking optional runtime tools..."
    echo "========================================="

    local any_missing=false
    for entry in "${OPTIONAL_RUNTIME_DEPS[@]}"; do
        IFS='|' read -r check apt_pkg dnf_pkg pacman_pkg desc why <<< "$entry"

        local target_pkg
        case "$pkg_manager" in
            apt)    target_pkg="$apt_pkg" ;;
            dnf|yum) target_pkg="$dnf_pkg" ;;
            pacman) target_pkg="$pacman_pkg" ;;
            *)      target_pkg="$apt_pkg" ;;
        esac

        if check_dep "$check"; then
            _lr_ok "$desc"
        else
            any_missing=true
            _lr_warn "OPTIONAL missing → $desc"
            _lr_warn "  Why: $why"
            case "$pkg_manager" in
                apt)    _lr_warn "  Install: sudo apt-get install $apt_pkg" ;;
                dnf)    _lr_warn "  Install: sudo dnf install $dnf_pkg" ;;
                yum)    _lr_warn "  Install: sudo yum install $dnf_pkg" ;;
                pacman) _lr_warn "  Install: sudo pacman -S $pacman_pkg" ;;
                *)      _lr_warn "  Install: $apt_pkg  (apt) / $dnf_pkg  (dnf/rpm) / $pacman_pkg  (pacman)" ;;
            esac
        fi
    done

    if ! $any_missing; then
        _lr_ok "All optional runtime tools are present."
    fi
    echo "========================================="
    echo ""
}

# ── plugin source patches ─────────────────────────────────────────────────────
# Applies known C/C++ source-level fixes to Flutter plugin files that fail to
# compile on Clang (Fedora/Arch) due to -Werror flags that GCC (Ubuntu) ignores.
# Patches are idempotent — safe to run on every build.
# Both the pub-cache master copy and the in-project symlink are patched so the
# fix survives `flutter clean` + `flutter pub get` on any distro.

_patch_file() {
    local file="$1" description="$2"
    shift 2
    # Remaining args are sed -e expressions
    if [ ! -f "$file" ]; then
        return 0
    fi
    if sed "${@}" "$file" | diff -q "$file" - &>/dev/null; then
        _lr_ok "Already patched: $description"
        return 0
    fi
    if [ "${LIB_RESOLVER_DRY_RUN:-0}" = "1" ]; then
        _lr_info "DRY-RUN: would patch $file ($description)"
        return 0
    fi
    sed -i "${@}" "$file" && _lr_ok "Patched: $description" || _lr_warn "Could not patch: $file"
}

patch_plugin_sources() {
    echo ""
    echo "========================================="
    echo "Patching Flutter plugin C++ sources..."
    echo "========================================="

    # ── hotkey_manager_linux ──────────────────────────────────────────────
    # Fix: -Werror,-Wsometimes-uninitialized on `identifier` and `keystring`
    # Both variables are declared uninitialized and only assigned inside an
    # `if` block, which Clang treats as a hard error (GCC silently ignores it).
    local hotkey_patch_args=(
        -e 's/const char\* identifier;/const char* identifier = nullptr;/g'
        -e 's/const char\* keystring;/const char* keystring = nullptr;/g'
    )

    # 1. Pub-cache master copy (survives flutter clean / pub get)
    local pub_cache_hotkey
    pub_cache_hotkey="$(find "${PUB_CACHE:-$HOME/.pub-cache}" \
        -path "*/hotkey_manager_linux*/hotkey_manager_linux_plugin.cc" \
        2>/dev/null | head -1)"
    if [ -n "$pub_cache_hotkey" ]; then
        _patch_file "$pub_cache_hotkey" \
            "hotkey_manager_linux (pub cache) — uninitialized identifier/keystring" \
            "${hotkey_patch_args[@]}"
    else
        _lr_warn "hotkey_manager_linux not found in pub cache — skipping pub-cache patch."
    fi

    # 2. In-project symlink copy (active build tree)
    local symlink_hotkey
    symlink_hotkey="$(find "${PROJECT_DIR:-$PWD}" \
        -path "*/.plugin_symlinks/hotkey_manager_linux/linux/hotkey_manager_linux_plugin.cc" \
        2>/dev/null | head -1)"
    if [ -n "$symlink_hotkey" ]; then
        _patch_file "$symlink_hotkey" \
            "hotkey_manager_linux (symlink) — uninitialized identifier/keystring" \
            "${hotkey_patch_args[@]}"
    else
        _lr_info "hotkey_manager_linux symlink not yet generated — pub-cache patch is sufficient."
    fi

    # ── system_tray ───────────────────────────────────────────────────────
    # Fix: Segmentation fault in Fedora/GNOME when calling InitSystemTray
    # system_tray calls dlopen("libappindicator3.so.1") which crashes on Fedora.
    # We patch it to try libayatana-appindicator3.so.1 first, which is a drop-in
    # compatible replacement that handles modern DBus environments safely.
    local system_tray_patch_args=(
        -e 's/void\* handle = dlopen("libappindicator3.so.1", RTLD_LAZY);/void* handle = dlopen("libayatana-appindicator3.so.1", RTLD_LAZY); if (!handle) { handle = dlopen("libappindicator3.so.1", RTLD_LAZY); }/g'
    )

    # 1. Pub-cache master copy (survives flutter clean / pub get)
    local pub_cache_system_tray
    pub_cache_system_tray="$(find "${PUB_CACHE:-$HOME/.pub-cache}" \
        -path "*/system_tray*/linux/tray.cc" \
        2>/dev/null | head -1)"
    if [ -n "$pub_cache_system_tray" ]; then
        _patch_file "$pub_cache_system_tray" \
            "system_tray (pub cache) — load libayatana-appindicator3 first" \
            "${system_tray_patch_args[@]}"
    else
        _lr_warn "system_tray not found in pub cache — skipping pub-cache patch."
    fi

    # 2. In-project symlink copy (active build tree)
    local symlink_system_tray
    symlink_system_tray="$(find "${PROJECT_DIR:-$PWD}" \
        -path "*/.plugin_symlinks/system_tray/linux/tray.cc" \
        2>/dev/null | head -1)"
    if [ -n "$symlink_system_tray" ]; then
        _patch_file "$symlink_system_tray" \
            "system_tray (symlink) — load libayatana-appindicator3 first" \
            "${system_tray_patch_args[@]}"
    else
        _lr_info "system_tray symlink not yet generated — pub-cache patch is sufficient."
    fi

    # ── sentry_flutter (sentry-native.cmake) ──────────────────────────────
    # Fix: Space in path build error on Fedora when building sentry-native.
    # We patch sentry-native.cmake to extract the dependency, check if we are on Fedora,
    # and if so quote the exports.map path flag so clang/ld doesn't split it on spaces.
    local pub_cache_sentry
    pub_cache_sentry="$(find "${PUB_CACHE:-$HOME/.pub-cache}" \
        -path "*/sentry_flutter*/sentry-native/sentry-native.cmake" \
        2>/dev/null | head -1)"
    
    if [ -n "$pub_cache_sentry" ]; then
        # Check if already patched to avoid redundant warnings or prints
        if grep -q "sentry-native_POPULATED" "$pub_cache_sentry" || grep -q "SENTRY_PATCH_CMD" "$pub_cache_sentry"; then
            _lr_ok "Already patched: sentry-native.cmake (pub cache) — exports.map space issue"
        else
            # We add a PATCH_COMMAND to FetchContent_Declare to modify CMakeLists.txt when it is fetched,
            # but only if on Fedora. This avoids the deprecated FetchContent_Populate direct calls.
            cat << 'EOF' > /tmp/sentry_patch.py
import sys
import re

with open(sys.argv[1], 'r') as f:
    content = f.read()

pattern = r'FetchContent_Declare\(\s*sentry-native.*?EXCLUDE_FROM_ALL\s*\)\s*FetchContent_MakeAvailable\(sentry-native\)'
replacement = """
set(SENTRY_PATCH_CMD "")
if(EXISTS "/etc/os-release")
    file(READ "/etc/os-release" OS_RELEASE_CONTENT)
    if(OS_RELEASE_CONTENT MATCHES "ID=fedora")
        file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/patch_sentry.py" [=[
import os
content = open('CMakeLists.txt').read()
old_str = '-Wl,--build-id=sha1,--version-script=${PROJECT_SOURCE_DIR}/src/exports.map'
new_str = '-Wl,--build-id=sha1'
if old_str in content:
    open('CMakeLists.txt', 'w').write(content.replace(old_str, new_str))
    print("[sentry_flutter-patch] Successfully patched CMakeLists.txt to remove version-script (fixes space in path issue).")
]=])
        set(SENTRY_PATCH_CMD python3 "${CMAKE_CURRENT_BINARY_DIR}/patch_sentry.py")
    endif()
endif()

if(SENTRY_PATCH_CMD)
    FetchContent_Declare(
        sentry-native
        GIT_REPOSITORY ${SENTRY_NATIVE_repo}
        GIT_TAG ${SENTRY_NATIVE_version}
        EXCLUDE_FROM_ALL
        PATCH_COMMAND ${SENTRY_PATCH_CMD}
    )
else()
    FetchContent_Declare(
        sentry-native
        GIT_REPOSITORY ${SENTRY_NATIVE_repo}
        GIT_TAG ${SENTRY_NATIVE_version}
        EXCLUDE_FROM_ALL
    )
endif()
FetchContent_MakeAvailable(sentry-native)
"""
if re.search(pattern, content, re.DOTALL):
    content = re.sub(pattern, replacement, content, flags=re.DOTALL)
    with open(sys.argv[1], 'w') as f:
        f.write(content)
EOF
            if [ "${LIB_RESOLVER_DRY_RUN:-0}" = "1" ]; then
                _lr_info "DRY-RUN: would patch $pub_cache_sentry"
            else
                python3 /tmp/sentry_patch.py "$pub_cache_sentry" && _lr_ok "Patched: sentry-native.cmake (pub cache) — exports.map space issue" || _lr_warn "Could not patch: $pub_cache_sentry"
            fi
            rm -f /tmp/sentry_patch.py
        fi
    else
        _lr_warn "sentry_flutter not found in pub cache — skipping sentry-native patch."
    fi

    echo "========================================="
    echo ""
}

# Run directly if executed (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    resolve_build_deps
    patch_plugin_sources
    check_optional_deps
fi
