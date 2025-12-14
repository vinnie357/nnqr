# NNQR Love2D Implementation Plan

## Overview

2D isometric recreation of Quadradius using Love2D with a clean, modern visual style.
Network multiplayer from the start with dedicated server architecture.

## Key Decisions

| Decision | Choice |
|----------|--------|
| Power scope | Minimal (~10-15 core powers) |
| Art style | Clean/modern (vector, gradients, smooth shapes) |
| Terrain heights | Yes - full height mechanics (0-4 levels) |
| Multiplayer | Network from start |
| Server architecture | Dedicated server (primary) |
| Server tech | Love2D headless (primary), Elixir stub (future) |
| Other stubs | Peer-to-peer, client-hosted |

## Development Methodology

**Test-Driven Development (TDD)**
1. Write failing tests first (RED)
2. Implement minimal code to pass tests (GREEN)
3. Refactor while keeping tests green (REFACTOR)

## Phase 1: Visual Foundation

### Goals
- Upgrade isometric rendering with clean modern style
- Smooth gradients and anti-aliased shapes
- Valid move indicators when piece selected
- Basic piece movement animations
- Proper depth sorting for rendering order

### Tasks
- [ ] Refactor rendering into `src/client/rendering.lua`
- [ ] Implement gradient tile rendering (height visualization)
- [ ] Add smooth shape drawing with anti-aliasing
- [ ] Implement move indicator overlays
- [ ] Add tween-based movement animations
- [ ] Implement depth sorting algorithm

### Tests
- Depth sorting correctness
- Animation state transitions
- Coordinate conversion accuracy

## Phase 2: Terrain Height System

### Goals
- Height levels per tile (0-4 range)
- Visual height representation (gradient colors - whiter = higher)
- Movement rules: drop any levels, climb max 1

### Tasks
- [ ] Add height field to board tiles
- [ ] Implement height validation (0-4 range)
- [ ] Update `isValidMove()` for height rules
- [ ] Visual gradient rendering based on height
- [ ] Height affects piece rendering (y-offset)

### Tests
- Height bounds validation
- Climb rule (max 1 level)
- Drop rule (any levels)
- Valid moves affected by height
- Height initialization

## Phase 3: Network Architecture

### Goals
- Shared game logic module (client & server)
- Love2D headless dedicated server
- Client-server protocol (JSON over TCP)
- Lobby system (create/join games)
- Stubs for future implementations

### Tasks
- [ ] Extract shared logic to `src/shared/`
- [ ] Define protocol messages in `src/shared/protocol.lua`
- [ ] Implement Love2D headless server
- [ ] Implement client networking
- [ ] Build lobby system
- [ ] Create stubs for P2P, client-hosted, Elixir

### Tests
- Message serialization/deserialization
- Game state sync validation
- Turn validation on server
- Lobby operations (create/join/leave)

## Phase 4: Power-Up Framework

### Goals
- Power orb spawning (every 7 turns)
- Power inventory per piece
- Power activation UI
- ~12 core powers implemented

### Tasks
- [ ] Implement orb spawning system
- [ ] Add power inventory to pieces
- [ ] Build power activation UI
- [ ] Implement each power (see powers.md)

### Tests
- Orb spawning (timing, placement)
- Inventory management
- Each power's effect validation

## Phase 5: Polish & Integration

### Goals
- Sound effects
- Particle effects for powers
- Complete UI
- Reconnection handling

### Tasks
- [ ] Add sound system
- [ ] Implement particle effects
- [ ] Complete UI (power display, chat placeholder)
- [ ] Handle network reconnection
- [ ] Performance optimization

## Directory Structure

```
lua/love2d/
├── docs/
│   ├── implementation_plan.md    # This file
│   ├── progress.md               # Progress tracking
│   ├── network_protocol.md       # Protocol specification
│   └── powers.md                 # Power definitions
├── src/
│   ├── client/
│   │   ├── rendering.lua         # Clean modern rendering
│   │   ├── input.lua             # Input handling
│   │   ├── animations.lua        # Smooth animations
│   │   ├── ui.lua                # UI components
│   │   └── network.lua           # Client networking
│   ├── server/
│   │   ├── main.lua              # Headless server entry
│   │   ├── lobby.lua             # Game lobby management
│   │   └── session.lua           # Game session handling
│   ├── shared/
│   │   ├── logic.lua             # Core game rules
│   │   ├── board.lua             # Board state management
│   │   ├── height.lua            # Height system
│   │   ├── powers.lua            # Power definitions & effects
│   │   ├── protocol.lua          # Message serialization
│   │   └── constants.lua         # Shared constants
│   ├── stubs/
│   │   ├── p2p.lua               # Peer-to-peer stub
│   │   ├── client_hosted.lua     # Client-hosted stub
│   │   └── elixir_notes.md       # Elixir server notes
│   ├── game.lua                  # Main game module (client)
│   └── logic.lua                 # Legacy (migrate to shared/)
├── spec/
│   ├── logic_spec.lua            # Existing logic tests
│   ├── height_spec.lua           # Height system tests
│   ├── protocol_spec.lua         # Protocol tests
│   └── powers_spec.lua           # Power system tests
├── assets/                       # Future assets
├── main.lua                      # Client entry point
├── server_main.lua               # Server entry point
└── conf.lua                      # Love2D configuration
```

## Timeline

| Phase | Estimated Duration |
|-------|-------------------|
| Phase 1 | 1-2 sessions |
| Phase 2 | 1 session |
| Phase 3 | 2-3 sessions |
| Phase 4 | 2-3 sessions |
| Phase 5 | 1-2 sessions |

## References

- Original game research: `research/game.md`
- Rust/Bevy implementation: `rust/bevy/`
- Love2D docs: https://love2d.org/wiki/Main_Page
