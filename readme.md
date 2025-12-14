# Not Not Quadradius (NNQR)

A multi-implementation recreation of **Quadradius** built with **Claude AI**.

The original Quadradius was a beloved Flash strategy game described as "checkers on steroids", created by Jimmi Heiserman and Brad Kayal in 2007. This turn-based masterpiece combined simple movement mechanics with ~70 different power-ups that dramatically altered gameplay.

## About This Project

This project explores how Claude AI can assist in recreating a classic game across multiple programming languages and game engines. Each implementation is developed collaboratively with Claude, demonstrating AI-assisted game development workflows.

## Implementations

| Implementation | Status | Description |
|----------------|--------|-------------|
| [Rust/Bevy](rust/bevy/) | Production | Advanced 3D isometric with 38+ powers |
| [Lua/Love2D](lua/love2d/) | In Development | Lightweight 2D/isometric version |

## Quick Start

### Rust/Bevy (Production Ready)
```bash
cd rust/bevy
cargo run --release
```

### Lua/Love2D (Development)
```bash
cd lua/love2d
love .
```

### Using mise tasks
```bash
mise run rust-start      # Run Bevy version
mise run love-start      # Run Love2D version
```

## Game Overview

### Core Mechanics
- **10x8 Board**: Isometric grid with terrain heights
- **Turn-Based**: Alternating player turns
- **Movement**: Orthogonal movement with height restrictions
- **Capture**: Move onto enemy pieces to eliminate them
- **Powers**: Collect power orbs for special abilities

### Power System
The original Quadradius featured ~70 unique powers across categories:
- **Movement Powers**: Teleport, Jump, Diagonal, Knight moves
- **Combat Powers**: Smart Bomb, Sniper, Shield, Assassin
- **Terrain Powers**: Raise/Lower columns, Destroy terrain
- **Special Powers**: Multiply pieces, Steal powers, Invisibility

## Project Structure

```
nnqr/
├── rust/
│   └── bevy/              # Rust/Bevy implementation
│       ├── src/           # Source code
│       ├── features/      # Feature specifications
│       ├── instructions/  # Implementation guides
│       └── bug_reports/   # Issue tracking
├── lua/
│   └── love2d/            # Love2D implementation
│       ├── src/           # Lua source
│       ├── assets/        # Game assets
│       └── lib/           # External libraries
├── research/              # Shared research docs
├── mise.toml              # Task runner config
└── CLAUDE.md              # Development guide
```

## Development

### Prerequisites

**For Rust/Bevy:**
- Rust 1.87+ ([rustup.rs](https://rustup.rs/))

**For Lua/Love2D:**
- Love2D 11.5+ ([love2d.org](https://love2d.org/))

**Shared tools (managed by mise):**
- [mise](https://mise.jdx.dev/) - Runtime version manager
- nushell - Development scripts

### Common Tasks

```bash
# Rust/Bevy
mise run rust-start         # Development mode
mise run rust-start-release # Optimized release
mise run rust-test          # Run tests
mise run rust-clippy        # Lint code

# Lua/Love2D
mise run love-start         # Run game
mise run love-fmt           # Format code
```

## Contributing

See implementation-specific README files for detailed contribution guidelines:
- [Rust/Bevy Contributing](rust/bevy/README.md)
- [Lua/Love2D Contributing](lua/love2d/README.md)

## Version History

### Rust/Bevy
- **v0.2.0**: Advanced 3D rendering, 38+ powers, Windows deployment
- **v0.1.0**: Basic board and movement

### Lua/Love2D
- **v0.1.0** *(In Progress)*: Basic isometric board scaffold

## License

This is a fan recreation of the original Quadradius Flash game. This project is not affiliated with the original creators but aims to preserve and celebrate this classic strategy game for modern platforms.
