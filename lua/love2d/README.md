# Quadradius - Love2D Implementation

A Lua/Love2D implementation of Quadradius, the classic Flash strategy game.

## Prerequisites

- [Love2D](https://love2d.org/) 11.5 or later

### Installation

**macOS:**
```bash
brew install love
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt install love
```

**Windows:**
Download from https://love2d.org/

## Running the Game

From the project root:
```bash
mise run love-start
```

Or directly:
```bash
cd lua/love2d
love .
```

## Controls

- **Left Click**: Select piece / Move piece
- **R**: Reset game
- **ESC**: Quit

## Project Structure

```
lua/love2d/
├── conf.lua          # Love2D configuration
├── main.lua          # Entry point and callbacks
├── src/
│   └── game.lua      # Core game logic
├── assets/           # Game assets (sprites, sounds)
├── lib/              # External libraries (3DreamEngine, etc.)
├── features/         # Feature specifications
└── instructions/     # Implementation guides
```

## Development

### Code Formatting

```bash
mise run love-fmt      # Format code
mise run love-check    # Check formatting
```

### Future Enhancements

- [ ] 3D isometric rendering with 3DreamEngine
- [ ] Power-up system (70+ powers)
- [ ] Terrain heights
- [ ] Sound effects and music
- [ ] Multiplayer support

## Libraries

Consider adding these for enhanced features:
- [3DreamEngine](https://github.com/3dreamengine/3DreamEngine) - 3D rendering
- [LuaPill](https://github.com/Kyrremann/LuaPill) - Isometric maps
- [HUMP](https://github.com/vrld/hump) - Helper utilities
