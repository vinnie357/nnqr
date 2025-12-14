#!/bin/bash
# Alternative Windows build using cargo-zigbuild (no mingw required)

echo "Setting up Zig-based Windows build..."

# Use mise environment
eval "$(mise env)"

# Check if cargo-zigbuild is installed
if ! command -v cargo-zigbuild &> /dev/null; then
    echo "Installing cargo-zigbuild..."
    cargo install cargo-zigbuild
fi

# Check if zig is available
if ! command -v zig &> /dev/null; then
    echo "Zig is required but not found."
    echo "Please install Zig from: https://ziglang.org/download/"
    echo "Or add to mise.toml: zig = 'latest'"
    exit 1
fi

# Build for Windows
echo "Building Windows executable with Zig..."
cargo zigbuild --release --target x86_64-pc-windows-gnu

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build successful!"
    echo "Copying to C:\..."
    
    cp target/x86_64-pc-windows-gnu/release/quadradius.exe /mnt/c/quadradius.exe
    
    echo "Windows executable created at: C:\quadradius.exe"
else
    echo "Build failed. Check error messages above."
fi