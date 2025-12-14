#!/bin/bash
# Build Windows executable using Docker (no sudo required)

echo "Building Quadradius for Windows using Docker..."

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Please install Docker first."
    exit 1
fi

# Build the Docker image
echo "Building Docker image..."
docker build -f Dockerfile.windows -t quadradius-windows-builder .

if [ $? -ne 0 ]; then
    echo "Docker build failed"
    exit 1
fi

# Create a container and copy the executable
echo "Creating container to extract executable..."
CONTAINER_ID=$(docker create quadradius-windows-builder)

# Copy the executable to /mnt/c/
echo "Copying executable to C:\..."
docker cp $CONTAINER_ID:/app/target/x86_64-pc-windows-gnu/release/quadradius.exe /mnt/c/quadradius.exe

# Clean up
docker rm $CONTAINER_ID

echo ""
echo "✅ Windows executable created at: C:\quadradius.exe"
echo ""
echo "You can now run the game on Windows by:"
echo "1. Opening File Explorer"
echo "2. Navigating to C:\"
echo "3. Double-clicking quadradius.exe"