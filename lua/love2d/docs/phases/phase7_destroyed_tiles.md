# Phase 7: Destroyed Tiles

## Overview

Enable permanent tile destruction for Acidic powers and heavy Bomb damage, creating impassable holes in the board.

**Estimated Sessions**: 1
**New Tests**: ~15

## Original Rule

From Quadradius documentation:
> "Acidic powers destroy tiles permanently, leaving holes that pieces cannot occupy or cross."

## Design

### Destroyed Tile State
- Stored in game state as `destroyedTiles` map: `{["row,col"] = true}`
- Tiles are permanently destroyed (cannot be restored except by Refurb power)
- Pieces cannot move onto or through destroyed tiles

### Visual Rendering
- Black hexagonal pit
- Subtle depth effect (darker in center)
- No interaction highlighting

### Destruction Triggers
- **Acidic powers** (Phase 9): Destroy target tile after effect
- **Heavy Bomb**: Destroy tiles at minimum height (0) in blast radius
- **Refurb power**: Repair destroyed tiles

## Tasks

### 7.1 Destroyed Tile State (TDD)

**Tests** (`spec/game_logic_spec.lua`):
1. `GameLogic.createInitialState()` includes empty `destroyedTiles`
2. `GameLogic.destroyTile(state, row, col)` marks tile as destroyed
3. `GameLogic.isTileDestroyed(state, row, col)` returns true for destroyed
4. `GameLogic.isTileDestroyed(state, row, col)` returns false for intact
5. Cannot destroy out-of-bounds tiles
6. Destroying already-destroyed tile is no-op

**Implementation** (`src/shared/game_logic.lua`):
```lua
--- Destroy a tile permanently
---@param state table Game state
---@param row number Row position
---@param col number Column position
---@return table Updated game state
function GameLogic.destroyTile(state, row, col)

--- Check if a tile is destroyed
---@param state table Game state
---@param row number Row position
---@param col number Column position
---@return boolean True if tile is destroyed
function GameLogic.isTileDestroyed(state, row, col)
```

### 7.2 Movement Validation (TDD)

**Tests** (`spec/game_logic_spec.lua`):
1. Cannot move onto destroyed tile
2. Destroyed tiles excluded from valid moves
3. Cannot select piece on destroyed tile (piece died)

**Implementation** (`src/shared/power_effects.lua`):
- Update `getValidMovesWithPowers()` to exclude destroyed tiles

### 7.3 Bomb Integration

**Tests** (`spec/power_effects_spec.lua`):
1. Bomb at height 0 destroys center tile
2. Bomb at height 0 destroys adjacent tiles at height 0
3. Bomb at height > 0 only lowers, doesn't destroy

**Implementation** (`src/shared/power_effects.lua`):
- Update `activateBomb()` to destroy tiles at minimum height

### 7.4 Refurb Power

**Tests** (`spec/power_effects_spec.lua`):
1. Refurb power defined with correct properties
2. `getRefurbTargets()` returns adjacent destroyed tiles
3. `activateRefurb()` repairs target tile
4. Repaired tile has height 0

**Implementation**:
- Add Refurb power definition to `powers.lua`
- Add effect to `power_effects.lua`

### 7.5 Visual Rendering

**Implementation** (`src/game.lua`):
- In `Game.drawBoard()`, render destroyed tiles as black pits
- Skip normal tile rendering for destroyed tiles
- Add subtle depth gradient effect

## Files to Modify

| File | Changes |
|------|---------|
| `src/shared/game_logic.lua` | Add `destroyedTiles` state, `destroyTile()`, `isTileDestroyed()` |
| `src/shared/power_effects.lua` | Update movement validation, bomb destruction |
| `src/shared/powers.lua` | Add Refurb power definition |
| `src/game.lua` | Render destroyed tiles |
| `spec/game_logic_spec.lua` | Destroyed tile tests (~6) |
| `spec/power_effects_spec.lua` | Bomb destruction tests (~4), Refurb tests (~4) |
| `spec/powers_spec.lua` | Refurb power definition test (~1) |

## Test Count

| Change | Tests |
|--------|-------|
| Destroyed tile state | +6 |
| Movement validation | +3 |
| Bomb destruction | +4 |
| Refurb power | +4 |
| **Total new** | **~15** (some overlap) |
| Current total | ~502 |
| **New total** | **~517** |

## Execution Order

1. **RED**: Write state tests for destroyedTiles
2. **GREEN**: Implement state management
3. **RED**: Write movement validation tests
4. **GREEN**: Update movement validation
5. **RED**: Write bomb destruction tests
6. **GREEN**: Update bomb effect
7. **RED**: Write Refurb tests
8. **GREEN**: Implement Refurb power
9. Add visual rendering
10. Manual testing
11. Update `roadmap_progress.md`
12. Commit

## Future Considerations

Phase 9 Acidic powers will use `destroyTile()` after destroying pieces.
