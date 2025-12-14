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
