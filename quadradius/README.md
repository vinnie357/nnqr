# Quadradius - Complete Implementation

## Status
**🎉 COMPLETE!** Full game implementation with 38 powers, 3D rendering, and enhanced UI.

## Quick Start

### Play the Game (Linux/Development)
```bash
cargo run
```

### Windows Deployment
```bash
./deploy_windows.sh ./windows    # Creates Windows package
./windows_deploy                 # Shortcut version
```

## How to Play

### Basic Controls
- **Left Click**: Select your piece (highlighted in yellow)
- **Right Click**: Move selected piece or activate power
- **Mouse Drag**: Drag pieces to move them (3D mode)
- **Q/E Keys**: Zoom in/out (3D mode)

### Game Rules
1. **Movement**: Pieces move horizontally/vertically (not diagonally)
2. **Terrain**: Can move down any levels, up only 1 level maximum
3. **Capture**: Move onto enemy pieces to capture them
4. **Powers**: Collect power orbs for special abilities
5. **Win**: Eliminate all opponent pieces

### Power System
- **38 Different Powers**: From simple moves to game-changing abilities
- **Power Orbs**: Appear randomly on the board after moves
- **Power Inventory**: Collect and activate strategic powers
- **Balanced Gameplay**: Powers are carefully balanced for fair play

## Features Implemented

### ✅ Core Game (Phase 1 Complete)
- **10×8 Board**: Extended from original 8×8 for better gameplay
- **Terrain Heights**: Multi-level board with movement restrictions
- **Turn-Based Gameplay**: Alternating player turns with visual feedback
- **Piece Capture**: Strategic piece elimination mechanics
- **Win Conditions**: Multiple victory scenarios

### ✅ Power System (All Phases Complete)
- **38 Unique Powers**: Complete recreation of original Flash game
- **Power Categories**: Movement, Attack, Defense, Terrain, Special
- **Power Balance**: Tested and balanced for competitive play
- **Power UI**: Enhanced interface for power selection and activation

### ✅ 3D Rendering
- **Isometric View**: True 3D isometric perspective
- **Enhanced Lighting**: Ambient and directional lighting system
- **3D Power Orbs**: Glowing orbs with metallic materials
- **Depth Sorting**: Proper Z-ordering for correct rendering
- **Camera Controls**: Zoom and perspective controls

### ✅ Enhanced UI
- **Turn Indicators**: Clear player turn visualization
- **Power Inventory**: Visual power collection and management
- **Score Tracking**: Piece count and game statistics
- **Visual Feedback**: Animations and highlights for all actions

### ✅ Performance & Testing
- **Automated Testing**: Comprehensive test suite for all features
- **Performance Monitoring**: FPS tracking and optimization
- **Debug Systems**: Extensive debugging and validation tools
- **Cross-Platform**: Linux development, Windows deployment

## Windows Deployment System

### Consistent Package Creation
```bash
./deploy_windows.sh [target_directory]
```

Creates exactly **4 essential files**:
1. **README_WINDOWS.md** - Complete Windows documentation
2. **quadradius.exe** - Game executable with all features
3. **build_windows.ps1** - PowerShell script for native Windows builds
4. **PLAY_GAME.bat** - One-click game launcher

### Deployment Targets
- **Primary**: `/mnt/c/quadradius-windows-build` (Windows mount)
- **Fallback**: `./windows` (local directory)
- **Custom**: Any specified directory

See `README_DEPLOYMENT.md` for detailed deployment documentation.

## Technical Architecture

### Built With
- **Rust**: Systems programming language for performance
- **Bevy Engine**: Modern ECS game engine
- **3D Graphics**: PBR materials and lighting
- **Cross-Platform**: Windows + Linux support

### Key Systems
- **ECS Architecture**: Entity-Component-System design
- **Conditional Rendering**: 2D/3D mode switching
- **State Management**: Game state and resource management
- **Event System**: Decoupled game event handling

## Development

### Build Requirements
- Rust 1.87+ with Cargo
- Windows cross-compilation target (for Windows builds)
- Linux development environment

### Testing
```bash
cargo test                    # Run all tests
cargo test board_10x8_tests   # Test 10×8 board specifically
```

### Performance
```bash
cargo run --release           # Optimized build
```

## Project Structure
```
quadradius/
├── src/
│   ├── components/          # ECS components
│   ├── systems/            # Game systems
│   ├── resources/          # Global resources
│   └── tests/              # Test suites
├── windows/                # Windows deployment package
├── deploy_windows.sh       # Deployment script
├── windows_deploy          # Quick deployment shortcut
└── README_DEPLOYMENT.md    # Deployment documentation
```

## Version History
- **v0.1.0**: Basic board and movement (Phase 1)
- **v0.2.0**: Complete power system + 3D rendering (All Phases)
- **Current**: Enhanced deployment + Windows packaging