# WSL2 Development Environment Fix PRD - Quadradius

## Overview
Enable Quadradius development and testing within WSL2 environment by addressing graphics and windowing limitations.

## Goals
- Get Quadradius running in WSL2 for development
- Enable visual testing without leaving WSL
- Maintain development workflow efficiency
- Document solutions for other WSL2 developers

## Current Issue
```
ERROR log: surface configuration failed: incompatible window kind
thread 'main' panicked at wgpu-0.17.2/src/backend/direct.rs:771:18:
Error in Surface::configure: Validation Error
Caused by: Invalid surface
```

## Root Causes
1. WSL2 lacks native GPU support (WSLg provides limited support)
2. Window surface creation fails due to display server mismatch
3. Bevy/wgpu expects native window system

## Solution Options

### Option 1: WSLg Configuration (Recommended)
WSLg provides built-in Wayland/X11 support for WSL2.

#### Prerequisites
- Windows 11 or Windows 10 Build 19044+
- WSL2 with Ubuntu 20.04+
- Updated graphics drivers

#### Setup Steps
```bash
# Update WSL2
wsl --update

# Install mesa drivers
sudo apt update
sudo apt install mesa-utils

# Test OpenGL support
glxinfo | grep "OpenGL"

# Install Vulkan support (optional)
sudo apt install vulkan-tools
vulkaninfo
```

#### Environment Variables
```bash
# Add to ~/.bashrc
export DISPLAY=:0
export WAYLAND_DISPLAY=wayland-0
export XDG_RUNTIME_DIR=/mnt/wslg/runtime-dir
export PULSE_SERVER=/mnt/wslg/PulseServer
```

#### Bevy Configuration for WSLg
```rust
// In main.rs
use bevy::window::WindowMode;

fn main() {
    let mut app = App::new();
    
    // WSL2-specific configuration
    #[cfg(target_os = "linux")]
    {
        if std::env::var("WSL_DISTRO_NAME").is_ok() {
            app.add_plugins(DefaultPlugins.set(WindowPlugin {
                primary_window: Some(Window {
                    title: "Quadradius".into(),
                    resolution: (800.0, 600.0).into(),
                    mode: WindowMode::Windowed,
                    // Force X11 backend for WSL2
                    ..default()
                }),
                ..default()
            }).set(RenderPlugin {
                wgpu_settings: WgpuSettings {
                    backends: Some(wgpu::Backends::GL),
                    ..default()
                },
            }));
        }
    }
}
```

### Option 2: X11 Forwarding with VcXsrv

#### Windows Side Setup
1. Download and install VcXsrv
2. Configure with:
   - Multiple windows
   - Start no client
   - Disable access control

#### WSL2 Side Setup
```bash
# Get WSL2 IP
export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0

# Test X11
sudo apt install x11-apps
xclock  # Should show a clock window

# Configure Bevy for X11
export WINIT_UNIX_BACKEND=x11
```

### Option 3: Software Rendering Fallback

#### Mesa Software Renderer
```bash
# Install software renderer
sudo apt install mesa-utils libgl1-mesa-dri

# Force software rendering
export LIBGL_ALWAYS_SOFTWARE=1
export GALLIUM_DRIVER=llvmpipe

# Run with reduced features
cargo run --features wsl2-compat
```

#### Code Changes for Software Mode
```toml
# Cargo.toml
[features]
wsl2-compat = []

[target.'cfg(all(target_os = "linux", feature = "wsl2-compat"))'.dependencies]
bevy = { version = "0.12", default-features = false, features = [
    "bevy_winit",
    "bevy_render",
    "bevy_sprite",
    "bevy_text",
    "bevy_ui",
    "x11"
]}
```

### Option 4: Browser-Based Development

#### Local Web Server
```bash
# Build for web
trunk serve --open

# Access from Windows browser
# http://localhost:8080
```

This bypasses WSL2 graphics entirely.

## Development Workflow Optimizations

### 1. Headless Testing
```rust
#[cfg(test)]
mod tests {
    use bevy::app::App;
    use bevy::MinimalPlugins;
    
    #[test]
    fn test_game_logic_headless() {
        let mut app = App::new();
        app.add_plugins(MinimalPlugins);
        // Test without rendering
    }
}
```

### 2. CI/CD Integration
```yaml
# .github/workflows/test.yml
name: Test
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: |
          sudo apt-get update
          sudo apt-get install -y libx11-dev libasound2-dev
      - run: cargo test --no-default-features
```

### 3. Conditional Compilation
```rust
#[cfg(not(target_os = "windows"))]
fn setup_display() {
    if is_wsl2() {
        setup_wsl2_display();
    } else {
        setup_native_display();
    }
}

fn is_wsl2() -> bool {
    std::env::var("WSL_DISTRO_NAME").is_ok()
}
```

## Testing Strategy

### Automated Tests (Headless)
- Unit tests: `cargo test`
- Integration tests without graphics
- Game logic verification

### Visual Tests (With Display)
- Manual testing via WSLg/X11
- Screenshot-based regression tests
- Performance profiling

### Native Testing
- Periodic testing on native Linux/Windows
- CI/CD on multiple platforms

## Common Issues & Solutions

### Issue: "Cannot open display"
```bash
# Solution
export DISPLAY=:0
xhost +local:
```

### Issue: "GL context creation failed"
```bash
# Solution
export MESA_GL_VERSION_OVERRIDE=3.3
export MESA_GLSL_VERSION_OVERRIDE=330
```

### Issue: Audio not working
```bash
# Solution
export PULSE_SERVER=tcp:$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}')
```

## Performance Considerations

### WSL2 Overhead
- ~10-20% performance penalty
- Higher with software rendering
- Minimize draw calls

### Optimization Tips
```rust
// Reduce texture sizes for WSL2
#[cfg(feature = "wsl2-compat")]
const TEXTURE_SCALE: f32 = 0.5;

#[cfg(not(feature = "wsl2-compat"))]
const TEXTURE_SCALE: f32 = 1.0;
```

## Documentation for Developers

### README Addition
```markdown
## Running in WSL2

Quadradius can run in WSL2 with some setup:

1. Ensure WSLg is enabled (Windows 11 or 10 build 19044+)
2. Install dependencies:
   ```bash
   sudo apt update
   sudo apt install mesa-utils libx11-dev libasound2-dev
   ```
3. Run with OpenGL backend:
   ```bash
   WGPU_BACKEND=gl cargo run
   ```

For better performance, consider running natively on Windows.
```

## Alternative Development Strategies

### 1. Dual Development
- Code in WSL2
- Test on native Windows
- Use VS Code Remote WSL

### 2. Docker with X11
```dockerfile
FROM rust:latest
RUN apt-get update && apt-get install -y \
    libx11-dev libasound2-dev mesa-utils
ENV DISPLAY=host.docker.internal:0
```

### 3. Remote Development
- Develop on WSL2
- Deploy to cloud Linux VM
- Test via remote desktop

## Estimated Timeline
- WSLg setup and testing: 1 day
- Code modifications: 1 day
- Documentation: 0.5 days
- **Total: 2.5 days**

## Success Metrics
- Game runs at 30+ FPS in WSL2
- All game features functional
- Development iteration time < 30 seconds
- Clear documentation for other developers