#!/bin/bash

echo "Preparing Quadradius for Windows build..."

# Create a directory on Windows C: drive
WIN_DIR="/mnt/c/quadradius-windows-build"

echo "Creating build directory at C:\\quadradius-windows-build"
mkdir -p "$WIN_DIR"

# Copy all source files
echo "Copying source files..."
cp -r src "$WIN_DIR/"
cp Cargo.toml "$WIN_DIR/"
cp Cargo.lock "$WIN_DIR/"

# Copy build scripts
cp build_windows.ps1 "$WIN_DIR/" 2>/dev/null || true
cp BUILD_WINDOWS.md "$WIN_DIR/" 2>/dev/null || true

# Create a simple build instruction file
cat > "$WIN_DIR/BUILD_INSTRUCTIONS.txt" << EOF
Quadradius Windows Build Instructions
=====================================

This folder contains the Quadradius source code ready to build on Windows.

Quick Build:
1. Open PowerShell in this directory
2. Run: cargo build --release
3. Find the executable at: target\\release\\quadradius.exe

Or use the included PowerShell script:
1. Right-click build_windows.ps1
2. Select "Run with PowerShell"

Requirements:
- Rust (install from https://rustup.rs/)
- Visual Studio Build Tools or Visual Studio Community

The game will be built as a native Windows application with full performance.
EOF

echo ""
echo "✅ Source files copied to C:\\quadradius-windows-build"
echo ""
echo "To build on Windows:"
echo "1. Open PowerShell or Command Prompt"
echo "2. Navigate to C:\\quadradius-windows-build"
echo "3. Run: cargo build --release"
echo ""
echo "Or simply run the build_windows.ps1 script in PowerShell!"