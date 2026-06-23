#!/bin/bash
set -e

# Define directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build/linux/x64/release/bundle"
DIST_DIR="$PROJECT_DIR/dist"

echo "========================================="
echo "Building Linux Release Bundle..."
echo "========================================="
cd "$PROJECT_DIR"
/home/jatin/development/flutter/bin/flutter clean
/home/jatin/development/flutter/bin/flutter build linux

# Verify build output
if [ ! -d "$BUILD_DIR" ]; then
    echo "Error: Build output directory not found at $BUILD_DIR"
    exit 1
fi

# Create distribution directory
mkdir -p "$DIST_DIR"

# ---------------------------------------------------------------------------
# DEB Packaging
# ---------------------------------------------------------------------------
echo ""
echo "========================================="
echo "Packaging DEB (Debian/Ubuntu)..."
echo "========================================="
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
exec /opt/blinkkind/eye_care_timer "$@"
EOF
chmod +x "$DEB_STAGE/usr/bin/blinkkind"

# Create desktop entry launcher
cat << 'EOF' > "$DEB_STAGE/usr/share/applications/blinkkind.desktop"
[Desktop Entry]
Name=BlinkKind
Comment=A focused eye break timer for healthier screen sessions
Exec=blinkkind
Icon=blinkkind
Terminal=false
Type=Application
Categories=Utility;
StartupNotify=true
EOF
chmod +x "$DEB_STAGE/usr/share/applications/blinkkind.desktop"

# Create Debian control file
cat << 'EOF' > "$DEB_STAGE/DEBIAN/control"
Package: blinkkind
Version: 1.0.0
Section: utils
Priority: optional
Architecture: amd64
Maintainer: Jatin Khattar <khattarjatin374@gmail.com>
Depends: libgtk-3-0, libayatana-appindicator3-1, libx11-6
Description: BlinkKind: Eye Break Timer
 A focused eye break timer for healthier screen sessions.
EOF

# Build Debian Package
dpkg-deb --build "$DEB_STAGE" "$DIST_DIR/blinkkind_1.0.0_amd64.deb"
echo "✓ DEB package created at: $DIST_DIR/blinkkind_1.0.0_amd64.deb"

# ---------------------------------------------------------------------------
# RPM Packaging
# ---------------------------------------------------------------------------
echo ""
echo "========================================="
echo "Packaging RPM (RedHat/Fedora)..."
echo "========================================="
if ! command -v rpmbuild &> /dev/null; then
    echo "Notice: 'rpmbuild' not found. Skip RPM packaging."
    echo "To build RPM packages, please install 'rpm' (e.g. 'sudo apt-get install -y rpm') and rerun this script."
else
    RPM_BUILD_ROOT="$PROJECT_DIR/build/rpm_build"
    rm -rf "$RPM_BUILD_ROOT"
    mkdir -p "$RPM_BUILD_ROOT"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
    
    # Bundle compile outputs into source package
    tar -czf "$RPM_BUILD_ROOT/SOURCES/blinkkind-1.0.0.tar.gz" -C "$BUILD_DIR" .
    cp "$PROJECT_DIR/assets/app_icon.png" "$RPM_BUILD_ROOT/SOURCES/blinkkind.png"
    
    # Create desktop launcher file in SOURCES
    cat << 'EOF' > "$RPM_BUILD_ROOT/SOURCES/blinkkind.desktop"
[Desktop Entry]
Name=BlinkKind
Comment=A focused eye break timer for healthier screen sessions
Exec=blinkkind
Icon=blinkkind
Terminal=false
Type=Application
Categories=Utility;
StartupNotify=true
EOF

    # Create RPM Specification file
    cat << 'EOF' > "$RPM_BUILD_ROOT/SPECS/blinkkind.spec"
Name:           blinkkind
Version:        1.0.0
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
ln -sf /opt/blinkkind/eye_care_timer %{buildroot}/usr/bin/blinkkind
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

echo ""
echo "========================================="
echo "Packaging Completed successfully!"
echo "========================================="
