# PowerShell build script for Windows
# Run this in PowerShell on Windows to build Quadradius

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

# Build the release version
Write-Host "`nBuilding release executable..." -ForegroundColor Green
cargo build --release

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nBuild successful!" -ForegroundColor Green
    Write-Host "Executable location: target\release\quadradius.exe" -ForegroundColor Cyan
    
    # Ask if user wants to run the game
    $response = Read-Host "`nDo you want to run the game now? (Y/N)"
    if ($response -eq 'Y' -or $response -eq 'y') {
        Write-Host "Starting Quadradius..." -ForegroundColor Green
        Start-Process "target\release\quadradius.exe"
    }
    
    # Ask if user wants to create a distribution package
    $response = Read-Host "`nCreate distribution package? (Y/N)"
    if ($response -eq 'Y' -or $response -eq 'y') {
        $distDir = "quadradius-windows-dist"
        
        # Create distribution directory
        if (Test-Path $distDir) {
            Remove-Item -Recurse -Force $distDir
        }
        New-Item -ItemType Directory -Path $distDir | Out-Null
        
        # Copy executable
        Copy-Item "target\release\quadradius.exe" $distDir
        
        # Copy assets if they exist
        if (Test-Path "assets") {
            Copy-Item -Recurse "assets" "$distDir\assets"
        }
        
        # Create run batch file
        @"
@echo off
echo Starting Quadradius...
start quadradius.exe
"@ | Out-File -FilePath "$distDir\play.bat" -Encoding ASCII
        
        # Create README
        @"
Quadradius for Windows
======================

A strategic board game with 70+ power-ups!

HOW TO PLAY:
- Double-click play.bat or quadradius.exe to start
- Left click to select a piece
- Right click to move the selected piece
- Pieces can move up one level, down any levels
- Capture all opponent pieces to win!

REQUIREMENTS:
- Windows 7 or later
- DirectX 11 or Vulkan support

If the game doesn't start, you may need:
- Visual C++ Redistributables
- Updated graphics drivers

Enjoy the game!
"@ | Out-File -FilePath "$distDir\README.txt" -Encoding UTF8
        
        Write-Host "`nDistribution package created in: $distDir" -ForegroundColor Green
        Write-Host "You can now zip this folder and share it!" -ForegroundColor Cyan
    }
} else {
    Write-Host "`nBuild failed!" -ForegroundColor Red
    Write-Host "Please check the error messages above." -ForegroundColor Yellow
}