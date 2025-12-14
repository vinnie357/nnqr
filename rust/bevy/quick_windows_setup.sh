#!/bin/bash

echo "🎮 Quadradius Windows Setup"
echo "=========================="

# Update the Windows build directory with latest code
WIN_DIR="/mnt/c/quadradius-windows-build"

echo "📁 Updating Windows build directory..."

# Refresh all source files
rm -rf "$WIN_DIR"
mkdir -p "$WIN_DIR"

# Copy current source
cp -r src "$WIN_DIR/"
cp Cargo.toml "$WIN_DIR/"
cp Cargo.lock "$WIN_DIR/"

# Copy all build scripts and documentation
cp build_windows.ps1 "$WIN_DIR/" 2>/dev/null || true
cp BUILD_WINDOWS.md "$WIN_DIR/" 2>/dev/null || true
cp .github/workflows/build-windows.yml "$WIN_DIR/.github/workflows/" 2>/dev/null || true

# Create updated build instructions
cat > "$WIN_DIR/QUICK_BUILD.txt" << 'EOF'
QUADRADIUS - QUICK WINDOWS BUILD
================================

FASTEST METHOD:
1. Open PowerShell in this directory
2. Run: .\build_windows.ps1
3. Follow the prompts

MANUAL METHOD:
1. Open PowerShell in this directory  
2. Run: cargo build --release
3. Find exe at: target\release\quadradius.exe

REQUIREMENTS:
- Rust (https://rustup.rs/)
- Visual Studio Build Tools

The PowerShell script will:
✓ Build the game
✓ Offer to run it immediately
✓ Create a distribution package
✓ Include README and launcher

Enjoy playing Quadradius!
EOF

# Create a simple batch file for quick building
cat > "$WIN_DIR/build.bat" << 'EOF'
@echo off
echo Building Quadradius for Windows...
cargo build --release
if %errorlevel% equ 0 (
    echo.
    echo Build successful!
    echo Executable: target\release\quadradius.exe
    echo.
    set /p answer=Run the game now? (Y/N): 
    if /i "%answer%"=="Y" start target\release\quadradius.exe
) else (
    echo Build failed!
    pause
)
EOF

echo ""
echo "✅ Windows build directory updated!"
echo ""
echo "🪟 ON WINDOWS:"
echo "   1. Open File Explorer"
echo "   2. Go to C:\\quadradius-windows-build"
echo "   3. Double-click build.bat (simple)"
echo "   4. OR right-click build_windows.ps1 → Run with PowerShell (advanced)"
echo ""
echo "📦 This will create a Windows .exe file you can share with others!"
echo ""
echo "🚀 The game will run natively on Windows with full performance!"