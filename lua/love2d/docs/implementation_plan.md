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

## Phase 4B: Power Activation & Animations

### Design Decisions

| Decision | Choice |
|----------|--------|
| Animation style | Elaborate (~0.8s+) - particles, screen shake, multi-phase |
| Blocking behavior | Hybrid - destructive powers block, passive powers don't |
| Invisibility | Semi-transparent (30% opacity) for now, enhance with multiplayer |

### Development Methodology

**Strict TDD for all steps:**
1. Write failing tests first (RED)
2. Implement minimal code to pass tests (GREEN)
3. Refactor while keeping tests green (REFACTOR)

### Task Breakdown (TDD Order)

#### Step 1: Animation Module Foundation
**Goal:** Create `src/shared/animations.lua` with core animation state management

**Tests first (`spec/animations_spec.lua`):**
- `createAnimation()` returns valid animation state
- `updateAnimation(anim, dt)` updates elapsed time
- `getProgress(anim)` returns 0→1 based on elapsed/duration
- `isComplete(anim)` returns true when elapsed >= duration
- `ease.linear(t)` returns t unchanged
- `ease.easeOutQuad(t)` returns eased value
- `ease.easeInOutCubic(t)` returns eased value

**Then implement:** Core animation state, progress calculation, easing functions

#### Step 2: Animation Queue System
**Goal:** Manage multiple concurrent animations

**Tests first:**
- `AnimationQueue.add(anim)` adds to queue
- `AnimationQueue.update(dt)` updates all animations
- `AnimationQueue.update(dt)` removes completed animations
- `AnimationQueue.update(dt)` fires `onComplete` callback
- `AnimationQueue.getActive()` returns current animations
- `AnimationQueue.isBlocking()` returns true if any blocking animation active
- `AnimationQueue.clear()` removes all animations

**Then implement:** Queue management, blocking detection

#### Step 3: Animation Type Definitions
**Goal:** Define data structures for each power animation

**Tests first:**
- `Animations.createDestroyRow(row, originCol)` returns correct type/data
- `Animations.createDestroyColumn(col, originRow)` returns correct type/data
- `Animations.createBomb(row, col, radius)` returns correct type/data
- `Animations.createRelocate(fromRow, fromCol, toRow, toCol)` returns correct type/data
- `Animations.createRaiseTile(row, col, fromHeight, toHeight)` returns correct type/data
- `Animations.createLowerTile(row, col, fromHeight, toHeight)` returns correct type/data
- `Animations.createRecruit(row, col, fromPlayer, toPlayer)` returns correct type/data
- `Animations.createMultiply(originRow, originCol, targetRow, targetCol)` returns correct type/data
- `Animations.createMoveDiagonal(row, col)` returns correct type/data (non-blocking)
- `Animations.createJumpProof(row, col)` returns correct type/data (non-blocking)
- `Animations.createInvisible(row, col)` returns correct type/data (non-blocking)
- `Animations.createMoveAgain(row, col)` returns correct type/data (non-blocking)

**Then implement:** Factory functions for each animation type

#### Step 4: Animation Interpolation Helpers
**Goal:** Calculate visual properties at any point in animation

**Tests first:**
- `Animations.getDestroyRowWaveX(anim, progress)` returns X position of wave
- `Animations.getBombRadius(anim, progress)` returns current explosion radius
- `Animations.getRelocateFadeAlpha(anim, progress)` returns alpha (1→0→1)
- `Animations.getTileHeightOffset(anim, progress)` returns interpolated height
- `Animations.getRecruitColor(anim, progress)` returns blended RGB
- `Animations.getShieldScale(anim, progress)` returns scale (0→1.2→1 bounce)

**Then implement:** Interpolation functions for rendering

#### Step 5: Wire Up Missing Power Logic
**Goal:** Connect passive powers and fix valid move calculation

**Tests first (extend `spec/power_effects_spec.lua`):**
- `executepower` with "move_diagonal" calls `activateMoveDiagonal`
- `executepower` with "jump_proof" calls `activateJumpProof`
- `executepower` with "invisible" calls `activateInvisible`
- Capturing piece with `isInvisible` reveals it (calls `revealInvisible`)

**Tests first (extend `spec/game_logic_spec.lua`):**
- `selectPiece` uses `PowerEffects.getValidMovesWithPowers` for valid moves
- Piece with `canMoveDiagonally=true` shows diagonal moves
- Piece cannot capture defender with `isJumpProof=true`

**Then implement:** Update `game.lua` and `game_logic.lua`

#### Step 6: Integrate Animations into Game
**Goal:** Power activation triggers animations, state changes on completion

**Tests first (`spec/game_integration_spec.lua` - new):**
- Activating `destroy_row` queues blocking animation
- Activating `move_diagonal` queues non-blocking animation
- Blocking animation prevents player input
- Non-blocking animation allows player input
- `onComplete` callback applies power effect to game state

**Then implement:** Modify `Game.executepower()` to queue animations

#### Step 7: Render Animations (Visual - No Tests)
**Goal:** Draw animations in `Game.draw()`

**Implementation only (visual code, hard to test):**
- `Game.drawAnimations()` iterates active animations
- Each animation type has render function
- Particle spawning for elaborate effects
- Screen shake for bomb

### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `src/shared/animations.lua` | **CREATE** | Animation state, queue, factories, interpolation |
| `spec/animations_spec.lua` | **CREATE** | Animation module tests (~40 tests) |
| `spec/game_integration_spec.lua` | **CREATE** | Integration tests (~10 tests) |
| `src/game.lua` | MODIFY | Add animation queue, update executepower, add passive powers |
| `src/shared/game_logic.lua` | MODIFY | Use PowerEffects for valid moves |
| `spec/power_effects_spec.lua` | MODIFY | Add passive power activation tests |
| `spec/game_logic_spec.lua` | MODIFY | Add power-aware move tests |
| `docs/progress.md` | MODIFY | Update status |

### Estimated Test Count

| Spec File | New Tests |
|-----------|-----------|
| animations_spec.lua | ~40 |
| game_integration_spec.lua | ~10 |
| power_effects_spec.lua | +4 |
| game_logic_spec.lua | +3 |
| **Total New** | **~57** |

Current: 243 → Target: ~300 tests

### Execution Order

1. Step 1 → RED → GREEN (animation foundation)
2. Step 2 → RED → GREEN (queue system)
3. Step 3 → RED → GREEN (animation types)
4. Step 4 → RED → GREEN (interpolation)
5. Step 5 → RED → GREEN (power logic wiring)
6. Step 6 → RED → GREEN (game integration)
7. Step 7 → Implement (visual rendering)
8. Manual play testing
9. Update docs

---

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
