# Native Linux Deployment PRD - Quadradius

## Overview
Deploy Quadradius as a native Linux application with broad distribution compatibility.

## Goals
- Support major Linux distributions
- Provide multiple installation methods
- Ensure graphics API compatibility (Vulkan/OpenGL)
- Follow Linux desktop integration standards

## Technical Requirements

### Build Requirements
- Rust toolchain for Linux
- Development libraries (libx11, libasound2, etc.)
- AppImage/Flatpak/Snap toolchains

### Runtime Requirements
- Linux kernel 4.15+ (Ubuntu 18.04 era)
- glibc 2.27+
- X11 or Wayland
- Vulkan 1.0+ or OpenGL 3.3+
- ALSA or PulseAudio

## Implementation Steps

### 1. Dependencies Setup
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y \
    libx11-dev \
    libasound2-dev \
    libudev-dev \
    libxkbcommon-x11-dev \
    libwayland-dev \
    libgl1-mesa-dev \
    libvulkan-dev

# Fedora
sudo dnf install \
    libX11-devel \
    alsa-lib-devel \
    systemd-devel \
    libxkbcommon-x11-devel \
    wayland-devel \
    mesa-libGL-devel \
    vulkan-loader-devel

# Arch
sudo pacman -S \
    libx11 \
    alsa-lib \
    systemd-libs \
    libxkbcommon-x11 \
    wayland \
    mesa \
    vulkan-icd-loader
```

### 2. Build Configuration

#### Cargo.toml Linux Features
```toml
[target.'cfg(target_os = "linux")'.dependencies]
bevy = { version = "0.12", features = ["wayland", "x11"] }

[package.metadata.deb]
maintainer = "Your Name <email@example.com>"
copyright = "2024 Your Name"
license-file = ["LICENSE", "4"]
extended-description = """
Quadradius is a strategic board game inspired by
checkers but with 70+ power-ups."""
depends = "$auto"
section = "games"
priority = "optional"
assets = [
    ["target/release/quadradius", "usr/bin/", "755"],
    ["assets/*", "usr/share/quadradius/assets/", "644"],
    ["quadradius.desktop", "usr/share/applications/", "644"],
    ["icon.png", "usr/share/pixmaps/quadradius.png", "644"],
]
```

### 3. Desktop Integration

#### Create quadradius.desktop
```ini
[Desktop Entry]
Type=Application
Name=Quadradius
GenericName=Strategy Board Game
Comment=Checkers on steroids with 70+ power-ups
Exec=quadradius
Icon=quadradius
Terminal=false
Categories=Game;BoardGame;StrategyGame;
Keywords=game;strategy;board;checkers;
StartupNotify=true
```

#### AppStream Metadata (quadradius.metainfo.xml)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<component type="desktop-application">
  <id>com.example.quadradius</id>
  <name>Quadradius</name>
  <summary>Strategic board game with power-ups</summary>
  <description>
    <p>Quadradius is a turn-based strategy game that takes
    the classic game of checkers and adds over 70 different
    power-ups for endless strategic possibilities.</p>
  </description>
  <launchable type="desktop-id">quadradius.desktop</launchable>
  <url type="homepage">https://example.com/quadradius</url>
  <screenshots>
    <screenshot type="default">
      <image>https://example.com/screenshot.png</image>
    </screenshot>
  </screenshots>
  <releases>
    <release version="1.0.0" date="2024-01-01"/>
  </releases>
</component>
```

### 4. Distribution Formats

#### A. AppImage (Universal)
```bash
# Install linuxdeploy
wget https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
chmod +x linuxdeploy-x86_64.AppImage

# Create AppDir structure
mkdir -p AppDir/usr/bin
mkdir -p AppDir/usr/share/applications
mkdir -p AppDir/usr/share/icons/hicolor/256x256/apps

# Copy files
cp target/release/quadradius AppDir/usr/bin/
cp quadradius.desktop AppDir/usr/share/applications/
cp icon.png AppDir/usr/share/icons/hicolor/256x256/apps/quadradius.png

# Create AppImage
./linuxdeploy-x86_64.AppImage --appdir AppDir --output appimage
```

#### B. Flatpak
Create `com.example.quadradius.yml`:
```yaml
app-id: com.example.quadradius
runtime: org.freedesktop.Platform
runtime-version: '23.08'
sdk: org.freedesktop.Sdk
command: quadradius
finish-args:
  - --share=ipc
  - --socket=x11
  - --socket=wayland
  - --device=dri
  - --socket=pulseaudio
modules:
  - name: quadradius
    buildsystem: simple
    build-commands:
      - install -D quadradius /app/bin/quadradius
      - install -D quadradius.desktop /app/share/applications/com.example.quadradius.desktop
      - install -D icon.png /app/share/icons/hicolor/256x256/apps/com.example.quadradius.png
    sources:
      - type: file
        path: target/release/quadradius
      - type: file
        path: quadradius.desktop
      - type: file
        path: icon.png
```

#### C. Snap
Create `snapcraft.yaml`:
```yaml
name: quadradius
version: '1.0.0'
summary: Strategic board game with power-ups
description: |
  Quadradius is a turn-based strategy game that takes
  the classic game of checkers and adds over 70 different
  power-ups for endless strategic possibilities.
grade: stable
confinement: strict
base: core22

apps:
  quadradius:
    command: bin/quadradius
    plugs:
      - desktop
      - desktop-legacy
      - x11
      - wayland
      - opengl
      - pulseaudio
      - joystick

parts:
  quadradius:
    plugin: rust
    source: .
    build-packages:
      - libx11-dev
      - libasound2-dev
      - libudev-dev
    stage-packages:
      - libx11-6
      - libasound2
      - libudev1
```

#### D. Native Packages

**DEB (Debian/Ubuntu)**
```bash
cargo install cargo-deb
cargo deb
```

**RPM (Fedora/OpenSUSE)**
```bash
cargo install cargo-generate-rpm
cargo generate-rpm
```

**AUR (Arch Linux)**
Create `PKGBUILD`:
```bash
pkgname=quadradius
pkgver=1.0.0
pkgrel=1
pkgdesc="Strategic board game with power-ups"
arch=('x86_64')
url="https://example.com/quadradius"
license=('MIT')
depends=('libx11' 'alsa-lib' 'vulkan-icd-loader')
makedepends=('rust' 'cargo')
source=("$pkgname-$pkgver.tar.gz::https://github.com/example/quadradius/archive/v$pkgver.tar.gz")
sha256sums=('SKIP')

build() {
    cd "$pkgname-$pkgver"
    cargo build --release
}

package() {
    cd "$pkgname-$pkgver"
    install -Dm755 "target/release/quadradius" "$pkgdir/usr/bin/quadradius"
    install -Dm644 "quadradius.desktop" "$pkgdir/usr/share/applications/quadradius.desktop"
    install -Dm644 "icon.png" "$pkgdir/usr/share/pixmaps/quadradius.png"
}
```

### 5. Graphics API Compatibility

#### Runtime Detection
```rust
// Detect and fallback graphics APIs
fn select_render_backend() -> RenderBackend {
    if vulkan_available() {
        RenderBackend::Vulkan
    } else if opengl_available() {
        RenderBackend::OpenGL
    } else {
        panic!("No compatible graphics API found");
    }
}
```

### 6. Save Game Location
```rust
// Follow XDG Base Directory Specification
fn get_save_dir() -> PathBuf {
    let xdg_dirs = xdg::BaseDirectories::with_prefix("quadradius").unwrap();
    xdg_dirs.place_data_file("saves").unwrap()
}
```

### 7. Wayland vs X11 Support
```rust
// Detect display server
fn detect_display_server() -> DisplayServer {
    if std::env::var("WAYLAND_DISPLAY").is_ok() {
        DisplayServer::Wayland
    } else {
        DisplayServer::X11
    }
}
```

## Testing Requirements

### Distribution Testing
- [ ] Ubuntu 20.04 LTS
- [ ] Ubuntu 22.04 LTS
- [ ] Fedora 38+
- [ ] Arch Linux (rolling)
- [ ] OpenSUSE Tumbleweed
- [ ] Debian 11+

### Display Server Testing
- [ ] X11 (with various WMs)
- [ ] Wayland (GNOME)
- [ ] Wayland (KDE Plasma)
- [ ] Wayland (Sway)

### Graphics API Testing
- [ ] Vulkan (NVIDIA)
- [ ] Vulkan (AMD)
- [ ] Vulkan (Intel)
- [ ] OpenGL fallback
- [ ] Software rendering

### Audio System Testing
- [ ] PulseAudio
- [ ] PipeWire
- [ ] ALSA direct
- [ ] JACK

## Steam Deck Optimization
- Controller support via Steam Input
- 800x1280 resolution support
- Deck-specific performance profile
- Touch controls for desktop mode

## Performance Considerations
- Use system libraries when possible
- Minimize binary size with LTO
- Profile on low-end hardware
- Support CPU frequency scaling

## Repository Integration

### Flathub Submission
1. Fork flathub/flathub
2. Add com.example.quadradius
3. Submit PR with manifest
4. Respond to review feedback

### Snap Store
```bash
snapcraft login
snapcraft upload quadradius_1.0.0_amd64.snap
snapcraft release quadradius 1.0.0 stable
```

## Post-Launch Support
- Launchpad PPA for Ubuntu
- COPR repo for Fedora
- OBS (Open Build Service) for multiple distros
- Automatic updates via distribution method

## Estimated Timeline
- Build setup and testing: 2 days
- Package creation (all formats): 3 days
- Distribution testing: 2 days
- Repository submissions: 2 days
- Steam Deck optimization: 1 day
- **Total: 10 days**

## Success Metrics
- Compatible with 95%+ of desktop Linux installs
- < 50MB download size
- Native performance (60+ FPS)
- Clean integration with desktop environments
- Positive distribution repository reviews