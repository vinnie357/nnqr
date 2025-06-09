# Not Not Quadradius, a Quadradius Recreation Project (NNQR)
 
 a beloved flash game was taken in its prime, and this is an effort to revive that game.

## Overview

A faithful recreation of **Quadradius**, the beloved Flash strategy game described as "checkers on steroids". Originally created by Jimmi Heiserman and Brad Kayal in 2007, this turn-based masterpiece combined simple movement mechanics with ~70 different power-ups that dramatically altered gameplay.

This project recreates Quadradius using modern technology: **Rust** and the **Bevy game engine**, featuring advanced 3D isometric rendering while maintaining the strategic depth that made the original unforgettable.

## 🚀 Quick Start

### Prerequisites
- **Rust 1.70+** - [Install Rust](https://rustup.rs/)
- **Git** - For cloning the repository
- **Linux/WSL** - Primary development environment (Windows cross-compilation supported)

### Install and Play

```bash
# Clone the repository
git clone https://github.com/your-username/nnqr.git
cd nnqr

# Navigate to game directory
cd quadradius

# Run the game (development mode)
cargo run

# Or run optimized version
cargo run --release
```

### Controls
- **Left Click**: Select your piece (highlighted in yellow)
- **Right Click**: Move selected piece or activate power
- **Mouse Drag**: Drag pieces to move them (3D mode)
- **Q/E Keys**: Zoom in/out (3D mode)

## 🎮 Game Features

### Current Implementation Status
- ✅ **Core Game**: 10×8 isometric board with terrain heights
- ✅ **3D Rendering**: Advanced isometric view with PBR materials
- ✅ **Power System**: 38+ powers implemented (12+ remaining)
- ✅ **Cross-Platform**: Linux development, Windows deployment
- ✅ **Production Ready**: Windows release v0.2.0 available

### Power Categories
- **Movement Powers**: Teleport, Jump, Diagonal movement, and more
- **Combat Powers**: Smart bombs, Sniper, area destruction
- **Terrain Powers**: Raise/lower columns, height manipulation
- **Special Powers**: Piece multiplication, power stealing, invisibility

## 🛠️ Development

### Project Structure
```
nnqr/
├── quadradius/           # Main game implementation
│   ├── src/             # Rust source code
│   ├── windows/         # Windows deployment
│   └── README.md        # Detailed game documentation
├── research/            # Game analysis and technical research
├── instructions/        # Implementation guides and task lists
├── features/           # Feature specifications (powers, deployment)
├── bug_reports/        # Bug tracking and fixes
└── readme.md           # This file
```

### Build Commands
```bash
# Development build (faster compilation)
cargo run

# Release build (optimized performance)
cargo run --release

# Run tests
cargo test

# Test specific systems
cargo test power_orb_tests     # Power system tests
cargo test board_10x8_tests    # 10x8 board tests
cargo test movement_tests      # Movement validation
cargo test ui_theme_tests      # UI and visual tests

# Windows cross-compilation
./deploy_windows.sh
```

### Development Environment
```bash
# Install Rust (if not already installed)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# Add Windows target for cross-compilation
rustup target add x86_64-pc-windows-gnu

# Install development dependencies
sudo apt update
sudo apt install build-essential pkg-config
```

## 📚 Documentation

### For Players
- **[Game README](quadradius/README.md)** - Complete game documentation
- **[How to Play](quadradius/README.md#how-to-play)** - Game rules and controls
- **[Power System](features/powers/)** - Power documentation and testing

### For Developers
- **[Implementation Guide](instructions/nnqr_implementation.md)** - Current development guide
- **[Task List](instructions/task_list.md)** - Current development priorities
- **[Research Documents](research/)** - Game analysis and technical patterns
- **[Testing Guide](instructions/testing.md)** - Comprehensive testing strategy

## 🎯 Current Development Focus

### Immediate Priorities (Week 1-2)
1. **Fix Broken Powers** - Complete Freeze, Assassin, MoveTwice implementations
2. **Movement Powers** - Complete remaining 5 powers (Swap, Push, Pull, Leap)
3. **Combat Powers** - Implement Shield, Invisible, Recruit, and other abilities

### Upcoming Features
- **Board Manipulation Powers** - Wall creation, area effects, terrain transformation
- **Meta Powers** - Power-on-power interactions and advanced mechanics
- **Enhanced Visual Effects** - Improved animations and particle systems
- **Multiplayer Support** - Network gameplay (future phase)

## 🏆 Project Goals

### Phase Status
- ✅ **Phase 1-4**: COMPLETED (Foundation, Powers, 3D Rendering, Deployment)
- 🚧 **Current**: Power System Completion (38+ implemented, 12+ remaining)
- 🎯 **Target**: Full recreation with all ~50 original powers

### Success Metrics
- **Authentic Recreation**: Faithful to original Quadradius gameplay
- **Modern Technology**: Leveraging Rust/Bevy for performance and maintainability
- **Cross-Platform**: Working on Linux and Windows
- **Production Quality**: Professional game with comprehensive testing

## 🤝 Contributing

This project welcomes contributions! Current high-priority areas:
- **Power Implementation** - Complete missing powers using existing framework
- **Testing** - Automated tests for power mechanics and game balance
- **Documentation** - Keep guides current with implementation
- **Bug Fixes** - Address issues in bug_reports/

## 📈 Version History

- **v0.1.0**: Basic board and movement (Phase 1 Foundation)
- **v0.2.0**: Advanced 3D rendering + 38 powers (Phase 2-4 Complete)
- **v0.3.0** *(In Progress)*: Complete power system recreation
- **v1.0.0** *(Target)*: Full Quadradius recreation

## 📄 License

This is a fan recreation of the original Quadradius Flash game. This project is not affiliated with the original creators but aims to preserve and celebrate this classic strategy game for modern platforms.

---

**Ready to play?** `cd quadradius && cargo run`

**Want to contribute?** Check out the [task list](instructions/task_list.md) for current priorities!
