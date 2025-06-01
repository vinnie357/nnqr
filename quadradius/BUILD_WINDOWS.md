# Building Quadradius for Windows

This guide explains how to build Quadradius as a native Windows executable.

## Prerequisites

### On Windows
1. Install Rust from https://rustup.rs/
2. Install Visual Studio Build Tools or Visual Studio Community (for MSVC linker)
   - Download from: https://visualstudio.microsoft.com/downloads/
   - During installation, select "Desktop development with C++"

### From WSL/Linux (Cross-compilation)
Due to toolchain limitations, we recommend building directly on Windows for best results.

## Building on Windows

1. Clone the repository:
```cmd
git clone https://github.com/yourusername/quadradius.git
cd quadradius
```

2. Build the release executable:
```cmd
cargo build --release
```

3. The executable will be created at:
```
target\release\quadradius.exe
```

## Running the Game

Simply double-click `quadradius.exe` or run from command prompt:
```cmd
.\target\release\quadradius.exe
```

## Creating a Standalone Distribution

To create a version that can be shared:

1. Create a new folder for distribution:
```cmd
mkdir quadradius-windows
copy target\release\quadradius.exe quadradius-windows\
```

2. If you have any asset files, copy them too:
```cmd
xcopy /E assets quadradius-windows\assets\
```

3. Create a simple batch file to run the game:
Create `quadradius-windows\play.bat`:
```batch
@echo off
start quadradius.exe
```

4. Zip the folder for distribution.

## Optimized Build

For smallest file size and best performance:
```cmd
cargo build --profile release-windows
```

This uses the optimized profile defined in Cargo.toml.

## Troubleshooting

### "VCRUNTIME140.dll not found"
Users need Visual C++ Redistributables. Include these in your distribution or direct users to:
https://support.microsoft.com/en-us/help/2977003/the-latest-supported-visual-c-downloads

### Performance Issues
- Ensure you're building in release mode
- Update graphics drivers
- Try running in compatibility mode if needed

## Next Steps

For professional distribution, consider:
1. Code signing (prevents security warnings)
2. Creating an installer with NSIS or WiX
3. Publishing on itch.io or Steam