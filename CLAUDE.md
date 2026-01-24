# CLAUDE.md - NNQR Multi-Implementation Development Guide

## Project Overview

NNQR (Not Not Quadradius) is a multi-implementation recreation of Quadradius, the classic 2007 Flash strategy game, built collaboratively with Claude AI. Each implementation demonstrates AI-assisted game development across different technologies.

**Key Features:**
- **10x8 Board**: Extended from original 8x8 for enhanced gameplay
- **70+ Power-ups**: Dramatic gameplay-altering abilities
- **Claude-Built Implementations**: Multiple versions in different languages/engines

## Implementations

### Rust/Bevy (Development)
**Path**: `rust/bevy/`
**Status**: v0.2.0 deployed with 38+ powers

```bash
mise run rust-start           # Development mode
mise run rust-start-release   # Optimized build
mise run rust-test            # Run tests
```

### Lua/Love2D (Development)
**Path**: `lua/love2d/`
**Status**: Phase 9B complete, 83 powers implemented, multiplayer in progress

```bash
mise run love-start      # Run game
mise run love-test-busted # Run unit tests
mise run love-server     # Run multiplayer server
mise run love-fmt        # Format code
```

## Project Structure

```
nnqr/
├── rust/bevy/           # Rust/Bevy implementation
│   ├── src/             # Source code
│   │   ├── components/  # ECS components
│   │   ├── systems/     # Game systems
│   │   ├── resources/   # Global resources
│   │   └── tests/       # Test suites
│   ├── features/        # Feature specifications
│   ├── instructions/    # Implementation guides
│   ├── bug_reports/     # Issue tracking
│   └── .claudio/        # Claudio configuration
├── lua/love2d/          # Love2D implementation
│   ├── src/             # Lua source
│   ├── assets/          # Game assets
│   ├── lib/             # External libraries
│   ├── features/        # Feature specs
│   └── instructions/    # Implementation guides
├── research/            # Shared research
├── mise.toml            # Task runner
└── CLAUDE.md            # This file
```

## Development Commands

### Rust/Bevy Tasks
```bash
mise run rust-start           # Run in dev mode
mise run rust-start-release   # Optimized release
mise run rust-test            # All tests
mise run rust-test-powers     # Power system tests
mise run rust-check           # Cargo check
mise run rust-clippy          # Lint
mise run rust-fmt             # Format
mise run quality              # Full quality check
mise run stats                # Project statistics
```

### Lua/Love2D Tasks
```bash
mise run love-start      # Run game
mise run love-debug      # With debug console
mise run love-fmt        # Format with stylua
mise run love-test-busted # Unit tests with busted
mise run love-ci         # Format check + tests
mise run love-check      # Check formatting
```

## Rust/Bevy Development

### Architecture
- **ECS Design**: Entity-Component-System using Bevy
- **3D Isometric**: True 3D perspective with PBR materials
- **Power Framework**: Targeting, effects, duration, visual feedback

### Key Components
- `components/board.rs`: Board state and tiles
- `components/piece.rs`: Game pieces and ownership
- `components/power.rs`: Power definitions and effects
- `systems/`: Game logic systems

### Testing
```bash
cargo test                    # All tests
cargo test power_tests        # Power system
cargo test board_10x8_tests   # Board mechanics
```

### Windows Deployment
```bash
cd rust/bevy
./deploy_windows.sh ./windows
```

## Lua/Love2D Development

### Architecture
- **Module-based**: Lua modules for game systems
- **Love2D Callbacks**: Standard load/update/draw cycle
- **Isometric Rendering**: 2.5D perspective

### Key Files
- `conf.lua`: Love2D configuration
- `main.lua`: Entry point and callbacks
- `src/game.lua`: Core game logic

### Future Libraries
- **3DreamEngine**: For 3D rendering
- **LuaPill**: For isometric maps
- **HUMP**: Helper utilities

## Development Rules

### Tool Execution with mise
All project tools are managed via mise. Always use:
- `mise run <task>` for defined tasks (see `mise tasks`)
- `mise exec -- <command>` for tools managed by mise (love, stylua, cargo, etc.)

Never run tools directly without mise - they may not be in PATH or may be wrong versions.

### Factual Accuracy (Anti-Fabrication)
Execute tools to verify before making claims. Never assume.

**Prohibited language:**
- ❌ Superlatives: "excellent", "comprehensive", "robust", "production-ready", "feature-complete"
- ❌ Unverified metrics: "improves by 30%", "989 tests passing" (without running them)
- ❌ Assumed capabilities: "handles edge cases", "supports X" (without checking)

**Required approach:**
- ✅ Run `mise run love-test-busted` before claiming test counts
- ✅ Run `mise run love-start` before claiming the game works
- ✅ Use Read/Grep to verify features exist before describing them
- ✅ Mark uncertainty: "Docs claim X, requires verification" or "Unable to confirm without running tests"

**Example:**
- ❌ "989 tests passing, production-ready game engine"
- ✅ "Docs claim 989 tests. Ran `mise run love-test-busted`: 987 passed, 2 failed. Game launches but multiplayer untested."

## Development Philosophy

### Test-Driven Development
- Write tests before implementation
- Validate with real execution
- Maintain 60+ FPS for Bevy version

### Quality-First
- Code formatting enforced
- Linting with clippy (Rust) / stylua (Lua)
- Comprehensive documentation

### Research-Driven
- Document patterns in `research/`
- Troubleshooting guides for common issues
- Performance optimization strategies

## Current Focus

### Rust/Bevy
- Complete remaining 12+ powers
- Board manipulation powers
- Meta powers (power-on-power)

### Lua/Love2D
- 83 powers implemented
- AI opponent (4 difficulty levels)
- Multiplayer server/client infrastructure
- See `lua/love2d/docs/roadmap_progress.md` for current status

## Resources

- **Rust/Bevy Docs**: `rust/bevy/README.md`
- **Love2D Docs**: `lua/love2d/README.md`
- **Research**: `research/`
- **mise Tasks**: `mise tasks` to list all
