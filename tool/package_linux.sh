#!/bin/bash
set -e

# Define directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build/linux/x64/release/bundle"
DIST_DIR="$PROJECT_DIR/dist"

# ---------------------------------------------------------------------------
# Dynamically resolve Flutter binary
# Priority: PATH > common install locations > FLUTTER_HOME env var
# ---------------------------------------------------------------------------
resolve_flutter() {
    # 1. Already on PATH?
    if command -v flutter &>/dev/null; then
        echo "$(command -v flutter)"
        return
    fi

    # 2. Common install locations
    local candidates=(
        "$HOME/development/flutter/bin/flutter"
        "$HOME/flutter/bin/flutter"
        "/opt/flutter/bin/flutter"
        "/usr/local/flutter/bin/flutter"
        "/snap/flutter/current/usr/bin/flutter"
    )
    for candidate in "${candidates[@]}"; do
        if [ -x "$candidate" ]; then
            echo "$candidate"
            return
        fi
    done

    # 3. Honour explicit FLUTTER_HOME env var
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
    echo "  e.g. export FLUTTER_HOME=\"\$HOME/development/flutter\""
    exit 1
fi
echo "Using Flutter: $FLUTTER"

# Parse command line arguments
AUTO_YES=false
AUTO_NO=false
CLEAR_STATE_ARG=""
INSTALL_DEB_ARG=""
DEV_MODE=false

for arg in "$@"; do
    case "$arg" in
        -y|--yes|-Y|--YES)
            AUTO_YES=true
            ;;
        -n|--no|-N|--NO)
            AUTO_NO=true
            ;;
        -c|--clear|--clear-state)
            CLEAR_STATE_ARG="true"
            ;;
        -nc|--no-clear|--no-clear-state)
            CLEAR_STATE_ARG="false"
            ;;
        -i|--install)
            INSTALL_DEB_ARG="true"
            ;;
        -ni|--no-install)
            INSTALL_DEB_ARG="false"
            ;;
        -d|--dev|--local)
            DEV_MODE=true
            ;;
    esac
done

# ---------------------------------------------------------------------------
# Source and run the dependency resolver before any build step
# ---------------------------------------------------------------------------
LIB_RESOLVER="$SCRIPT_DIR/lib_resolver.sh"
if [ -f "$LIB_RESOLVER" ]; then
    # shellcheck source=lib_resolver.sh
    source "$LIB_RESOLVER"
else
    echo "Warning: lib_resolver.sh not found at $LIB_RESOLVER — skipping dependency check."
fi

# Extract version from pubspec.yaml (e.g., version: 1.0.0+1 -> 1.0.0)
VERSION=$(grep 'version: ' "$PROJECT_DIR/pubspec.yaml" | sed 's/version: //' | cut -d'+' -f1 | tr -d '[:space:]')
if [ -z "$VERSION" ]; then
    VERSION="1.0.0"
fi

if [ "$DEV_MODE" = "true" ]; then
    echo "========================================="
    echo "Setting up local developer desktop launcher..."
    echo "========================================="
    # Check & install missing native libs before building
    if declare -f resolve_build_deps &>/dev/null; then
        resolve_build_deps
        patch_plugin_sources
    fi
    cd "$PROJECT_DIR"
    "$FLUTTER" clean
    "$FLUTTER" build linux
    
    mkdir -p "$HOME/.local/share/applications"
    
    cat << EOF > "$HOME/.local/share/applications/blinkkind.desktop"
[Desktop Entry]
Name=BlinkKind
Comment=A focused eye break timer for healthier screen sessions
Exec=$PROJECT_DIR/build/linux/x64/release/bundle/eye_care_timer %u
Icon=$PROJECT_DIR/assets/app_icon.png
Terminal=false
Type=Application
Categories=Utility;
StartupNotify=true
StartupWMClass=com.jatin.eyecaretimer
EOF
    chmod +x "$HOME/.local/share/applications/blinkkind.desktop"
    
    if command -v update-desktop-database &> /dev/null; then
        update-desktop-database "$HOME/.local/share/applications"
    fi
    
    if pgrep -x eye_care_timer >/dev/null 2>&1; then
        echo "Stopping running application..."
        pkill -x eye_care_timer || true
        sleep 1
    fi
    
    echo "Restarting BlinkKind application..."
    gtk-launch blinkkind.desktop >/dev/null 2>&1 || gtk-launch blinkkind >/dev/null 2>&1 || ("$PROJECT_DIR/build/linux/x64/release/bundle/eye_care_timer" >/dev/null 2>&1 &)
    
    echo "========================================="
    echo "✓ Local developer desktop launcher ready!"
    echo "You can now run BlinkKind from your system Application Menu"
    echo "========================================="
    exit 0
fi

echo "========================================="
echo "Building BlinkKind version $VERSION..."
echo "========================================="
cd "$PROJECT_DIR"

# Option to reset application states
clear_state=""
if [ "$CLEAR_STATE_ARG" = "true" ]; then
    clear_state="y"
elif [ "$CLEAR_STATE_ARG" = "false" ]; then
    clear_state="n"
elif [ "$AUTO_YES" = true ]; then
    clear_state="y"
elif [ "$AUTO_NO" = true ]; then
    clear_state="n"
elif [ -t 0 ]; then
    read -p "Would you like to clear local user preferences/timer state (resets settings and history)? (y/N): " clear_state
else
    clear_state="n"
fi

if [[ "$clear_state" =~ ^[Yy]$ ]]; then
    rm -rf "$HOME/.local/share/com.jatin.eyecaretimer"
    rm -rf "$HOME/.local/share/com.example.eyeapptimer"
    echo "✓ Local application state files deleted."
fi

# Check & install missing native libs before building
if declare -f resolve_build_deps &>/dev/null; then
    resolve_build_deps
    patch_plugin_sources
fi

"$FLUTTER" clean
"$FLUTTER" build linux

# Verify build output
if [ ! -d "$BUILD_DIR" ]; then
    echo "Error: Build output directory not found at $BUILD_DIR"
    exit 1
fi

# Create distribution directory and clean old packages to ensure a fresh build
mkdir -p "$DIST_DIR"
rm -f "$DIST_DIR"/*.deb "$DIST_DIR"/*.rpm

# ---------------------------------------------------------------------------
# DEB Packaging
# ---------------------------------------------------------------------------
echo ""
echo "========================================="
echo "Packaging DEB (Debian/Ubuntu)..."
echo "========================================="

# Ensure dpkg-deb is available — install it if missing (cross-distro support)
if ! command -v dpkg-deb &>/dev/null; then
    echo "Notice: 'dpkg-deb' not found. Attempting to install 'dpkg'..."
    _PKG_MGR="$(command -v apt-get || command -v dnf || command -v yum || true)"
    case "$(basename "${_PKG_MGR}" 2>/dev/null)" in
        apt-get) sudo apt-get install -y dpkg ;;
        dnf)     sudo dnf install -y dpkg ;;
        yum)     sudo yum install -y dpkg ;;
        *)       echo "Notice: Cannot auto-install 'dpkg' — no supported package manager found." ;;
    esac
fi

if ! command -v dpkg-deb &>/dev/null; then
    echo "Notice: 'dpkg-deb' still not available. Skipping DEB packaging."
    echo "  To build DEB packages manually, install 'dpkg':"
    echo "    Fedora/RHEL : sudo dnf install -y dpkg"
    echo "    Ubuntu/Debian: sudo apt-get install -y dpkg"
    echo "========================================="
else
    DEB_STAGE="$PROJECT_DIR/build/deb_stage"
    rm -rf "$DEB_STAGE"
    mkdir -p "$DEB_STAGE/DEBIAN"
    mkdir -p "$DEB_STAGE/opt/blinkkind"
    mkdir -p "$DEB_STAGE/usr/bin"
    mkdir -p "$DEB_STAGE/usr/share/applications"
    mkdir -p "$DEB_STAGE/usr/share/pixmaps"

    # Copy binary bundle files
    cp -r "$BUILD_DIR"/* "$DEB_STAGE/opt/blinkkind/"

    # Copy application icon
    cp "$PROJECT_DIR/assets/app_icon.png" "$DEB_STAGE/usr/share/pixmaps/blinkkind.png"

    # Create /usr/bin launcher wrapper
    cat << 'EOF' > "$DEB_STAGE/usr/bin/blinkkind"
#!/bin/sh
# Launch via gtk-launch using the desktop entry if available to run in the proper desktop session environment,
# otherwise fall back to direct binary execution.
if command -v gtk-launch >/dev/null 2>&1; then
    exec gtk-launch blinkkind.desktop "$@"
else
    exec /opt/blinkkind/eye_care_timer "$@"
fi
EOF
    chmod +x "$DEB_STAGE/usr/bin/blinkkind"

    # Create desktop entry launcher
    cat << 'EOF' > "$DEB_STAGE/usr/share/applications/blinkkind.desktop"
[Desktop Entry]
Name=BlinkKind
Comment=A focused eye break timer for healthier screen sessions
Exec=/opt/blinkkind/eye_care_timer %u
Icon=blinkkind
Terminal=false
Type=Application
Categories=Utility;
StartupNotify=true
StartupWMClass=com.jatin.eyecaretimer
EOF
    chmod +x "$DEB_STAGE/usr/share/applications/blinkkind.desktop"

    # Create Debian control file (variable expansion enabled to insert $VERSION)
    cat << EOF > "$DEB_STAGE/DEBIAN/control"
Package: blinkkind
Version: $VERSION
Section: utils
Priority: optional
Architecture: amd64
Maintainer: Jatin Khattar <khattarjatin374@gmail.com>
Depends: libgtk-3-0, libayatana-appindicator3-1, libx11-6
Description: BlinkKind: Eye Break Timer
 A focused eye break timer for healthier screen sessions.
EOF

    # Build Debian Package
    dpkg-deb --build "$DEB_STAGE" "$DIST_DIR/blinkkind_${VERSION}_amd64.deb"
    echo "✓ DEB package created at: $DIST_DIR/blinkkind_${VERSION}_amd64.deb"
fi

# ---------------------------------------------------------------------------
# RPM Packaging
# ---------------------------------------------------------------------------
echo ""
echo "========================================="
echo "Packaging RPM (RedHat/Fedora)..."
echo "========================================="
if ! command -v rpmbuild &>/dev/null; then
    echo "Notice: 'rpmbuild' not found. Skipping RPM packaging."
    echo "  To build RPM packages, install 'rpm-build':"
    echo "    Fedora/RHEL : sudo dnf install -y rpm-build"
    echo "    Ubuntu/Debian: sudo apt-get install -y rpm"
else
    RPM_BUILD_ROOT="$PROJECT_DIR/build/rpm_build"
    rm -rf "$RPM_BUILD_ROOT"
    mkdir -p "$RPM_BUILD_ROOT"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
    
    # Bundle compile outputs into source package
    tar -czf "$RPM_BUILD_ROOT/SOURCES/blinkkind-${VERSION}.tar.gz" -C "$BUILD_DIR" .
    cp "$PROJECT_DIR/assets/app_icon.png" "$RPM_BUILD_ROOT/SOURCES/blinkkind.png"
    
    # Create desktop launcher file in SOURCES
    cat << 'EOF' > "$RPM_BUILD_ROOT/SOURCES/blinkkind.desktop"
[Desktop Entry]
Name=BlinkKind
Comment=A focused eye break timer for healthier screen sessions
Exec=/opt/blinkkind/eye_care_timer %u
Icon=blinkkind
Terminal=false
Type=Application
Categories=Utility;
StartupNotify=true
StartupWMClass=com.jatin.eyecaretimer
EOF

    # Create RPM Specification file (variable expansion enabled to insert $VERSION)
    cat << EOF > "$RPM_BUILD_ROOT/SPECS/blinkkind.spec"
Name:           blinkkind
Version:        $VERSION
Release:        1%{?dist}
Summary:        BlinkKind: Eye Break Timer
License:        MIT
URL:            https://github.com/JatinK3/eye-care-timer
Source0:        blinkkind-%{version}.tar.gz
Source1:        blinkkind.desktop
Source2:        blinkkind.png
Requires:       gtk3, libX11

%description
A focused eye break timer for healthier screen sessions.

%prep
# Unpack Source0 to BUILD
mkdir -p %{_builddir}/%{name}-%{version}
tar -xzf %{SOURCE0} -C %{_builddir}/%{name}-%{version}

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/opt/blinkkind
cp -r %{_builddir}/%{name}-%{version}/* %{buildroot}/opt/blinkkind/
mkdir -p %{buildroot}/usr/bin
cat << 'EOF' > %{buildroot}/usr/bin/blinkkind
#!/bin/sh
# Launch via gtk-launch using the desktop entry if available to run in the proper desktop session environment,
# otherwise fall back to direct binary execution.
if command -v gtk-launch >/dev/null 2>&1; then
    exec gtk-launch blinkkind.desktop "$@"
else
    exec /opt/blinkkind/eye_care_timer "$@"
fi
EOF
chmod +x %{buildroot}/usr/bin/blinkkind
mkdir -p %{buildroot}/usr/share/applications
cp %{SOURCE1} %{buildroot}/usr/share/applications/
mkdir -p %{buildroot}/usr/share/pixmaps
cp %{SOURCE2} %{buildroot}/usr/share/pixmaps/

%files
/opt/blinkkind/
/usr/bin/blinkkind
/usr/share/applications/blinkkind.desktop
/usr/share/pixmaps/blinkkind.png

%changelog
* Tue Jun 23 2026 Jatin Khattar <khattarjatin374@gmail.com> - 1.0.0-1
- Initial release
EOF

    # Build RPM package
    rpmbuild --define "_topdir $RPM_BUILD_ROOT" -bb "$RPM_BUILD_ROOT/SPECS/blinkkind.spec"
    
    # Copy build result to dist/
    find "$RPM_BUILD_ROOT/RPMS" -name "*.rpm" -exec cp {} "$DIST_DIR/" \;
    echo "✓ RPM package created in dist/ directory."
fi

# Optional installation step for DEB
if [ -f "$DIST_DIR/blinkkind_${VERSION}_amd64.deb" ]; then
    echo ""
    echo "========================================="
    install_deb=""
    if [ "$INSTALL_DEB_ARG" = "true" ]; then
        install_deb="y"
    elif [ "$INSTALL_DEB_ARG" = "false" ]; then
        install_deb="n"
    elif [ "$AUTO_YES" = true ]; then
        install_deb="y"
    elif [ "$AUTO_NO" = true ]; then
        install_deb="n"
    elif [ -t 0 ]; then
        read -p "Would you like to install the generated DEB package now? (y/N): " install_deb
    else
        install_deb="n"
    fi

    if [[ "$install_deb" =~ ^[Yy]$ ]]; then
        if dpkg-query -W -f='${Status}' blinkkind 2>/dev/null | grep -q "ok installed"; then
            echo "An older version of blinkkind is already installed. Removing it first for a clean install..."
            sudo dpkg -r blinkkind || true
            echo "✓ Older version of blinkkind has been removed."
            echo "Installing new version blinkkind_${VERSION}_amd64.deb..."
            sudo dpkg -i "$DIST_DIR/blinkkind_${VERSION}_amd64.deb" || {
                echo "Installing missing dependencies..."
                sudo apt-get install -f -y
            }
            echo "✓ Upgrade complete! Old version has been removed and the new version has been added."
        else
            echo "Installing blinkkind_${VERSION}_amd64.deb..."
            sudo dpkg -i "$DIST_DIR/blinkkind_${VERSION}_amd64.deb" || {
                echo "Installing missing dependencies..."
                sudo apt-get install -f -y
            }
            echo "✓ Installation complete! You can run 'blinkkind' or find it in your Applications menu."
        fi

        # Mandatory systemctl restart check if service is active
        restarted=false
        for svc in blinkkind blinkind; do
            if systemctl is-active --quiet "$svc" 2>/dev/null; then
                echo "Detected active system service: $svc (previously running)"
                echo "Restarting system service: $svc..."
                sudo systemctl restart "$svc"
                echo "✓ System service '$svc' restarted successfully."
                restarted=true
            fi
            if systemctl --user is-active --quiet "$svc" 2>/dev/null; then
                echo "Detected active user service: $svc (previously running)"
                echo "Restarting user service: $svc..."
                systemctl --user restart "$svc"
                echo "✓ User service '$svc' restarted successfully."
                restarted=true
            fi
        done

        # Restart running desktop application processes if detected
        if pgrep -x eye_care_timer >/dev/null 2>&1; then
            echo "Detected running BlinkKind application process (previously running)."
            echo "Stopping running application..."
            pkill -x eye_care_timer || true
            sleep 1
            echo "Restarting BlinkKind application..."
            # Launch via gtk-launch to run it in user's graphical session independently of script terminal
            gtk-launch blinkkind.desktop >/dev/null 2>&1 || gtk-launch blinkkind >/dev/null 2>&1 || (blinkkind >/dev/null 2>&1 &)
            echo "✓ BlinkKind application restarted successfully."
            restarted=true
        fi

        if [ "$restarted" = false ]; then
            echo "No active blinkkind/blinkind services or running app processes detected. Skipping restart."
        fi
    else
        echo "Skipping installation."
    fi
fi

echo ""
echo "========================================="
echo "Packaging Completed successfully!"
echo "========================================="
