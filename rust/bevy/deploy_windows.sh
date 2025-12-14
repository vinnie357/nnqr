#!/bin/bash

# Quadradius Windows Deployment Script
# Creates a clean Windows build package with exactly 4 essential files

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
BUILD_LOG="windows_deploy.log"

# Default target directory
DEFAULT_TARGET="/mnt/c/quadradius-windows-build"
FALLBACK_TARGET="$PROJECT_ROOT/windows"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=================================${NC}"
    echo -e "${BLUE} $1 ${NC}"
    echo -e "${BLUE}=================================${NC}"
}

# Function to determine target directory
determine_target() {
    local target_dir="$1"
    
    if [ -z "$target_dir" ]; then
        # Try default location first
        if [ -d "$(dirname "$DEFAULT_TARGET")" ]; then
            target_dir="$DEFAULT_TARGET"
            print_status "Using default Windows mount: $target_dir"
        else
            target_dir="$FALLBACK_TARGET"
            print_warning "Windows mount not available, using local: $target_dir"
        fi
    fi
    
    echo "$target_dir"
}

# Function to build Windows executable
build_windows_exe() {
    print_header "Building Windows Executable"
    
    # Check if Windows target is installed
    if ! rustup target list --installed | grep -q "x86_64-pc-windows-gnu"; then
        print_status "Installing Windows target..."
        rustup target add x86_64-pc-windows-gnu
    fi
    
    print_status "Starting Windows build (this may take 5+ minutes)..."
    
    # Build in background with progress monitoring
    cargo build --release --target x86_64-pc-windows-gnu > "$BUILD_LOG" 2>&1 &
    local build_pid=$!
    
    # Monitor build progress
    while kill -0 $build_pid 2>/dev/null; do
        if [ -f "$BUILD_LOG" ]; then
            local last_line=$(tail -n 1 "$BUILD_LOG" 2>/dev/null || echo "Building...")
            echo -ne "\r${YELLOW}Building...${NC} $last_line"
        fi
        sleep 2
    done
    
    wait $build_pid
    local build_result=$?
    
    echo # New line after progress
    
    if [ $build_result -eq 0 ]; then
        print_status "Windows build completed successfully!"
        return 0
    else
        print_error "Windows build failed!"
        echo "Build log:"
        cat "$BUILD_LOG"
        return 1
    fi
}

# Function to create Windows README
create_windows_readme() {
    local target_dir="$1"
    
    cat > "$target_dir/README_WINDOWS.md" << 'EOF'
# Quadradius - Windows Release

## About
Quadradius is a turn-based strategy game - "checkers on steroids" - featuring a 10×8 board with terrain heights and 38 different power-ups that dramatically alter gameplay. This is a faithful recreation of the 2007 Flash game.

## How to Run
**Double-click `PLAY_GAME.bat` to start the game immediately**

Or run directly:
```bash
quadradius.exe
```

## Game Controls
- **Left Click**: Select your piece (highlighted in yellow)
- **Right Click**: Move selected piece or use power
- **Mouse Drag**: Drag pieces to move them (3D mode)
- **Q/E Keys**: Zoom in/out (3D mode)

## Game Rules
1. **Movement**: Pieces move horizontally/vertically (not diagonally)
2. **Terrain**: Can move down any levels, up only 1 level maximum
3. **Capture**: Move onto enemy pieces to capture them
4. **Powers**: Collect power orbs and use special abilities
5. **Win**: Eliminate all opponent pieces

## 3D Mode Features
- **Isometric 3D View**: Full 3D board with depth and shadows
- **Enhanced Lighting**: Ambient and directional lighting
- **Power Orb Effects**: Glowing 3D power orbs with metallic materials
- **Smooth Animations**: 3D piece movement and effects

## Game Modes
- **2D Mode**: Classic flat view (default)
- **3D Mode**: Isometric 3D perspective (automatically enabled)

## System Requirements
- Windows 10/11 (64-bit)
- DirectX 11 compatible graphics
- 4GB RAM minimum

## Build Information
- Version: 0.2.0
- Built with: Rust + Bevy Engine
- Features: 38 Powers, 3D Rendering, Enhanced UI
- Board: 10×8 with terrain heights

## Troubleshooting
If the game doesn't start:
1. Check Windows Defender hasn't blocked the executable
2. Install Visual C++ Redistributables if needed
3. Update your graphics drivers
4. Try running as administrator
EOF
}

# Function to create launcher script
create_launcher() {
    local target_dir="$1"
    
    cat > "$target_dir/PLAY_GAME.bat" << 'EOF'
@echo off
echo.
echo =====================================
echo    Starting Quadradius...
echo =====================================
echo.
start quadradius.exe
echo.
echo Game launched! If the window doesn't appear:
echo 1. Check if Windows Defender blocked it
echo 2. Make sure your graphics drivers are updated
echo 3. Try running as administrator
echo.
pause
EOF
}

# Function to create PowerShell build script
create_build_script() {
    local target_dir="$1"
    
    cat > "$target_dir/build_windows.ps1" << 'EOF'
# PowerShell build script for Windows
# Run this in PowerShell on Windows to build Quadradius natively

Write-Host "Building Quadradius for Windows..." -ForegroundColor Green

# Check if Rust is installed
try {
    $rustVersion = rustc --version
    Write-Host "Found Rust: $rustVersion" -ForegroundColor Cyan
} catch {
    Write-Host "Rust is not installed!" -ForegroundColor Red
    Write-Host "Please install Rust from https://rustup.rs/" -ForegroundColor Yellow
    exit 1
}

# Check and install Windows target if needed
$targets = rustup target list --installed
if (-not ($targets -match "x86_64-pc-windows-msvc")) {
    Write-Host "Installing Windows MSVC target..." -ForegroundColor Yellow
    rustup target add x86_64-pc-windows-msvc
}

# Build the release version
Write-Host "`nBuilding release executable..." -ForegroundColor Green
cargo build --release --target x86_64-pc-windows-msvc

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nBuild successful!" -ForegroundColor Green
    Write-Host "Executable location: target\x86_64-pc-windows-msvc\release\quadradius.exe" -ForegroundColor Cyan
    
    # Copy executable to current directory for easy access
    Copy-Item "target\x86_64-pc-windows-msvc\release\quadradius.exe" "quadradius.exe"
    Write-Host "Executable copied to: quadradius.exe" -ForegroundColor Cyan
    
    # Ask if user wants to run the game
    $response = Read-Host "`nDo you want to run the game now? (Y/N)"
    if ($response -eq 'Y' -or $response -eq 'y') {
        Write-Host "Starting Quadradius..." -ForegroundColor Green
        Start-Process "quadradius.exe"
    }
} else {
    Write-Host "`nBuild failed!" -ForegroundColor Red
    Write-Host "Please check the error messages above." -ForegroundColor Yellow
    Write-Host "Common solutions:" -ForegroundColor Yellow
    Write-Host "1. Install Visual Studio Build Tools" -ForegroundColor Yellow
    Write-Host "2. Install Windows 10/11 SDK" -ForegroundColor Yellow
    Write-Host "3. Run in 'Developer PowerShell for VS'" -ForegroundColor Yellow
}

pause
EOF
}

# Function to clean and prepare target directory
prepare_target_directory() {
    local target_dir="$1"
    
    print_status "Preparing target directory: $target_dir"
    
    # Create directory if it doesn't exist
    mkdir -p "$target_dir"
    
    # Clean existing files (keep only the 4 essential files if they exist)
    if [ -d "$target_dir" ]; then
        print_status "Cleaning existing deployment files..."
        
        # Remove all files except our 4 essential ones temporarily
        find "$target_dir" -type f -name "*.md" ! -name "README_WINDOWS.md" -delete 2>/dev/null || true
        find "$target_dir" -type f -name "*.txt" -delete 2>/dev/null || true
        find "$target_dir" -type f -name "*.lock" -delete 2>/dev/null || true
        find "$target_dir" -type f -name "*.toml" -delete 2>/dev/null || true
        find "$target_dir" -type f -name "*.zip" -delete 2>/dev/null || true
        find "$target_dir" -type f -name "quadradius_*" -delete 2>/dev/null || true
        
        # Remove directories
        rm -rf "$target_dir/src" "$target_dir/assets" 2>/dev/null || true
    fi
}

# Function to verify deployment
verify_deployment() {
    local target_dir="$1"
    
    print_header "Verifying Deployment"
    
    local files=(
        "README_WINDOWS.md"
        "quadradius.exe" 
        "build_windows.ps1"
        "PLAY_GAME.bat"
    )
    
    local all_present=true
    
    for file in "${files[@]}"; do
        if [ -f "$target_dir/$file" ]; then
            local size=$(ls -lh "$target_dir/$file" | awk '{print $5}')
            print_status "✓ $file ($size)"
        else
            print_error "✗ Missing: $file"
            all_present=false
        fi
    done
    
    # Check for extra files
    local file_count=$(find "$target_dir" -maxdepth 1 -type f | wc -l)
    if [ "$file_count" -eq 4 ]; then
        print_status "✓ Exactly 4 files present (clean deployment)"
    else
        print_warning "! $file_count files found (expected 4)"
        echo "Files present:"
        ls -la "$target_dir"
    fi
    
    if [ "$all_present" = true ]; then
        print_status "Deployment verification passed!"
        return 0
    else
        print_error "Deployment verification failed!"
        return 1
    fi
}

# Main deployment function
deploy_windows() {
    local target_dir=$(determine_target "$1")
    
    print_header "Quadradius Windows Deployment"
    print_status "Target directory: $target_dir"
    print_status "Project root: $PROJECT_ROOT"
    
    # Step 1: Build Windows executable
    if ! build_windows_exe; then
        print_error "Failed to build Windows executable"
        exit 1
    fi
    
    # Step 2: Prepare target directory
    prepare_target_directory "$target_dir"
    
    # Step 3: Copy executable
    print_status "Copying Windows executable..."
    if [ -f "target/x86_64-pc-windows-gnu/release/quadradius.exe" ]; then
        cp "target/x86_64-pc-windows-gnu/release/quadradius.exe" "$target_dir/"
    else
        print_error "Windows executable not found!"
        exit 1
    fi
    
    # Step 4: Create Windows-specific files
    print_status "Creating Windows documentation..."
    create_windows_readme "$target_dir"
    
    print_status "Creating launcher script..."
    create_launcher "$target_dir"
    
    print_status "Creating build script..."
    create_build_script "$target_dir"
    
    # Step 5: Verify deployment
    if verify_deployment "$target_dir"; then
        print_header "Deployment Complete!"
        print_status "Windows package ready at: $target_dir"
        print_status "Users can run: PLAY_GAME.bat"
        print_status "Or build locally with: build_windows.ps1"
    else
        print_error "Deployment verification failed"
        exit 1
    fi
    
    # Cleanup
    rm -f "$BUILD_LOG"
}

# Script usage
show_usage() {
    cat << EOF
Usage: $0 [TARGET_DIRECTORY]

Deploy Quadradius Windows build package with exactly 4 essential files:
  1. README_WINDOWS.md  - Windows documentation
  2. quadradius.exe     - Game executable  
  3. build_windows.ps1  - PowerShell build script
  4. PLAY_GAME.bat      - Game launcher

Arguments:
  TARGET_DIRECTORY    Optional. Target deployment directory.
                     Default: /mnt/c/quadradius-windows-build
                     Fallback: ./windows

Examples:
  $0                                    # Use default/fallback location
  $0 /mnt/c/quadradius-windows-build   # Deploy to Windows mount
  $0 ./windows                         # Deploy to local directory
  $0 ~/Desktop/quadradius              # Deploy to custom location

EOF
}

# Main script execution
main() {
    case "${1:-}" in
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            deploy_windows "$1"
            ;;
    esac
}

# Run main function with all arguments
main "$@"