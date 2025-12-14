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
