# Quadradius Windows Deployment Guide

## Overview
This document describes the standardized process for creating Windows deployment packages for Quadradius.

## Quick Deployment

### Option 1: Local Windows Directory (Recommended)
```bash
./deploy_windows.sh ./windows
```
Creates a clean Windows package in `quadradius/windows/` with exactly 4 files.

### Option 2: Windows Mount (if available)
```bash
./deploy_windows.sh /mnt/c/quadradius-windows-build
```
Deploys directly to Windows mount point (requires write permissions).

### Option 3: Custom Location
```bash
./deploy_windows.sh /path/to/custom/location
```
Deploy to any specified directory.

## What Gets Created

The deployment script creates exactly **4 essential files**:

1. **📖 README_WINDOWS.md** - Complete Windows documentation
   - Game description and features
   - Installation instructions
   - Controls and gameplay rules
   - System requirements
   - Troubleshooting guide

2. **🎮 quadradius.exe** - Game executable
   - Latest version with all fixes
   - 3D isometric rendering support
   - 38 powers implemented
   - 10×8 board with terrain heights

3. **📜 build_windows.ps1** - PowerShell build script
   - Native Windows compilation
   - Automatic Rust/target installation
   - Error handling and troubleshooting
   - User-friendly prompts

4. **▶️ PLAY_GAME.bat** - One-click game launcher
   - Simple double-click to start
   - Error troubleshooting messages
   - Windows-optimized execution

## Deployment Script Features

### ✅ **Automated Build Process**
- Cross-compiles for Windows (`x86_64-pc-windows-gnu`)
- Progress monitoring with real-time feedback
- Automatic error detection and reporting
- Build log generation

### ✅ **Clean Package Management**
- Removes all unnecessary files (docs, configs, source)
- Maintains exactly 4 essential files
- Prevents file proliferation
- Consistent packaging every time

### ✅ **Smart Target Detection**
- Primary: `/mnt/c/quadradius-windows-build` (Windows mount)
- Fallback: `./windows` (local directory)
- Custom: User-specified path
- Automatic directory creation

### ✅ **Verification System**
- Checks all 4 files are present
- Validates file sizes
- Counts total files (ensures no extras)
- Reports deployment status

## Usage Examples

### Standard Development Workflow
```bash
# Make changes to the game
# Then deploy:
./deploy_windows.sh ./windows

# Package is ready in quadradius/windows/
# Can be zipped and shared with users
```

### Continuous Integration
```bash
# Automated deployment in CI/CD
./deploy_windows.sh ./dist/windows
zip -r quadradius-windows-v0.2.0.zip ./dist/windows/
```

### Manual Testing
```bash
# Deploy to temp location for testing
./deploy_windows.sh /tmp/quadradius-test
cd /tmp/quadradius-test
# Test the 4 files work correctly
```

## File Consistency

### Why Only 4 Files?
- **Simplicity**: Users get exactly what they need
- **Clarity**: No confusion about which files to use
- **Maintenance**: Easy to package and distribute
- **Standards**: Consistent deployment every time

### What Gets Excluded?
- Source code (`src/` directory)
- Assets directory (embedded in executable)
- Documentation markdown files (except Windows README)
- Configuration files (`Cargo.toml`, `Cargo.lock`)
- Build artifacts and logs
- Old executable versions
- Zip files and archives

## Windows User Experience

### For End Users:
1. Download/receive the 4-file package
2. Double-click `PLAY_GAME.bat` to start immediately
3. Read `README_WINDOWS.md` for help if needed

### For Developers:
1. Use `build_windows.ps1` to compile natively on Windows
2. Requires Rust + Windows SDK/Build Tools
3. Automatic target installation and setup

## Troubleshooting

### Permission Issues (Windows Mount)
If deployment to `/mnt/c/` fails with permission errors:
```bash
# Use local directory instead
./deploy_windows.sh ./windows
# Then manually copy files to Windows if needed
```

### Missing Windows Target
The script automatically installs the Windows target:
```bash
rustup target add x86_64-pc-windows-gnu
```

### Build Failures
Check the generated `windows_deploy.log` file for detailed error messages.

### File Count Issues
If verification shows more than 4 files:
- Re-run the deployment script (it cleans automatically)
- Check for hidden files or system files
- Manually remove unwanted files

## Advanced Usage

### Custom README
To customize the Windows README, edit the `create_windows_readme()` function in `deploy_windows.sh`.

### Different Launcher
To modify the launcher script, edit the `create_launcher()` function.

### Build Script Changes
To update the PowerShell build script, edit the `create_build_script()` function.

### Adding Files
If you need to add a 5th essential file:
1. Update the `files` array in `verify_deployment()`
2. Add creation logic in the main `deploy_windows()` function
3. Update this documentation

## Version History
- **v1.0**: Initial deployment script with 4-file standard
- **Current**: Automatic build, smart targeting, verification system