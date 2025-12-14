# Windows Native Deployment PRD - Quadradius

## Overview
This document outlines the requirements and process for deploying Quadradius as a native Windows application.

## Goals
- Create a standalone Windows executable (.exe)
- Ensure compatibility with Windows 7+ (64-bit)
- Provide easy installation/distribution method
- Maintain full game performance and features

## Technical Requirements

### Build Requirements
- Rust toolchain with Windows target
- Visual C++ Build Tools (for linking)
- Windows SDK

### Runtime Requirements
- Windows 7 SP1 or later (64-bit)
- DirectX 12 or Vulkan support
- Minimum 2GB RAM
- Graphics card with DX12/Vulkan support

## Implementation Steps

### 1. Setup Windows Build Target
```bash
# Add Windows target (if building from Linux/WSL)
rustup target add x86_64-pc-windows-gnu
# or for MSVC
rustup target add x86_64-pc-windows-msvc
```

### 2. Build Configuration
Update `Cargo.toml`:
```toml
[profile.release]
opt-level = 3
lto = true
strip = true

[package.metadata.winres]
ProductName = "Quadradius"
FileDescription = "Strategic board game"
```

### 3. Build Process
```bash
# From Windows or cross-compile
cargo build --release --target x86_64-pc-windows-msvc
```

### 4. Distribution Options

#### Option A: Standalone EXE
- Single executable file
- Include all assets embedded
- ~50-100MB file size

#### Option B: Installer (Recommended)
- Use NSIS or WiX toolset
- Include:
  - Game executable
  - Visual C++ Redistributables
  - DirectX runtime (if needed)
  - Start menu shortcuts
  - Uninstaller

### 5. Asset Bundling
```rust
// Use include_bytes! for small assets
const ICON: &[u8] = include_bytes!("../assets/icon.png");

// Or use Bevy's asset system with embedded assets
```

### 6. Windows-Specific Features
- Window icon
- File associations (for save games)
- Registry entries for settings
- Windows defender exclusion request

## Testing Requirements

### Compatibility Testing
- [ ] Windows 7 SP1
- [ ] Windows 8.1
- [ ] Windows 10
- [ ] Windows 11
- [ ] Both Intel/AMD and ARM64 (if applicable)

### Performance Testing
- [ ] 60 FPS on minimum specs
- [ ] Proper fullscreen support
- [ ] Multi-monitor handling
- [ ] High DPI scaling

### Integration Testing
- [ ] Antivirus compatibility
- [ ] UAC behavior
- [ ] Save game locations (%APPDATA%)

## Distribution

### Steam (Future)
- Steamworks SDK integration
- Cloud saves
- Achievements
- Steam Input API for controllers

### Itch.io (Immediate)
- Direct download
- Butler push for updates
- Simple distribution

### Microsoft Store (Optional)
- MSIX packaging
- Windows sandbox compliance
- Age rating submission

## Security Considerations
- Code signing certificate ($200-500/year)
- Reputation building to avoid SmartScreen warnings
- No elevation required (run as user)

## Performance Optimizations
- Enable Windows-specific Bevy features
- Use native Windows audio (WASAPI)
- Optimize for Windows scheduler

## Estimated Timeline
- Build setup: 1 day
- Testing on Windows versions: 2 days
- Installer creation: 1 day
- Distribution setup: 1 day
- **Total: 5 days**

## Success Metrics
- Downloads without SmartScreen warnings
- < 1% crash rate
- 60+ FPS on minimum spec hardware
- < 5 second startup time