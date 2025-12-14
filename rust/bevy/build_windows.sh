#!/bin/bash

# Build script for creating Windows executable from Linux/WSL
# This creates a Windows binary that can be copied to Windows and run

echo "Building Quadradius for Windows..."

# Ensure we have the Windows target
echo "Checking for Windows target..."
rustup target add x86_64-pc-windows-gnu

# Build the Windows executable
echo "Building Windows executable..."
cargo build --release --target x86_64-pc-windows-gnu

# Check if build succeeded
if [ $? -eq 0 ]; then
    echo "Build successful!"
    echo "Windows executable created at: target/x86_64-pc-windows-gnu/release/quadradius.exe"
    echo ""
    echo "To run on Windows:"
    echo "1. Copy the .exe file to your Windows system"
    echo "2. Double-click to run, or run from Command Prompt"
else
    echo "Build failed. Please check the error messages above."
    exit 1
fi