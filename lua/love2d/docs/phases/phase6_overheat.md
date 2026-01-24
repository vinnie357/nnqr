# Phase 6: Overheat Mechanic

## Overview

Prevent power hoarding by implementing the original Quadradius rule: 10+ of the same power on one piece causes it to explode.

**Estimated Sessions**: 1
**New Tests**: ~10

## Original Rule

From Quadradius documentation:
> "If a piece accumulates 10 or more of the same power, it overheats and explodes."

## Design

### Overheat Threshold
- **Threshold**: 10 of the same power ID
- **Trigger**: After any power is added to a piece
- **Effect**: Piece is destroyed (removed from game)

### Visual Feedback
- **Warning at 8+**: Piece glows orange/red
- **Warning at 9**: Piece pulses rapidly
- **Explosion**: Reuse bomb explosion animation

## Tasks

### 6.1 Overheat Logic (TDD)

**Tests** (`spec/powers_spec.lua`):
1. `Powers.countPowerById(piece, powerId)` - Returns count of specific power
2. `Powers.countPowerById()` returns 0 for empty piece
3. `Powers.countPowerById()` returns correct count with multiple powers
4. `Powers.checkOverheat(piece)` - Returns nil when under threshold
5. `Powers.checkOverheat(piece)` - Returns powerId when at threshold (10)
6. `Powers.checkOverheat(piece)` - Returns powerId when over threshold (11+)
7. Overheat check after `Powers.addPower()`

**Implementation** (`src/shared/powers.lua`):
```lua
--- Count occurrences of a specific power on a piece
---@param piece table Piece to check
---@param powerId string Power ID to count
---@return number Count of power
function Powers.countPowerById(piece, powerId)

--- Check if piece has overheated (10+ of same power)
---@param piece table Piece to check
---@return string|nil Power ID that caused overheat, or nil
function Powers.checkOverheat(piece)
```

### 6.2 Game Integration

**Files** (`src/game.lua`):
- After orb collection, call `Powers.checkOverheat(piece)`
- If overheated, trigger explosion animation and remove piece
- Add visual warning rendering for pieces at 8+ same power

### 6.3 Visual Warning

**Rendering** (`src/game.lua`):
- In `Game.drawPieces()`, check for high power counts
- 8-9 of same power: Orange glow around piece
- Uses piece flag or calculated on render

## Files to Modify

| File | Changes |
|------|---------|
| `src/shared/powers.lua` | Add `countPowerById()`, `checkOverheat()` |
| `spec/powers_spec.lua` | Add overheat tests (~7 tests) |
| `src/game.lua` | Integrate overheat check, visual warning |
| `spec/game_logic_spec.lua` | Add integration tests (~3 tests) |

## Test Count

| Change | Tests |
|--------|-------|
| Powers overheat logic | +7 |
| Game integration | +3 |
| **Total new** | **~10** |
| Current total | 492 |
| **New total** | **~502** |

## Execution Order

1. **RED**: Write failing tests for `countPowerById()`
2. **GREEN**: Implement `countPowerById()`
3. **RED**: Write failing tests for `checkOverheat()`
4. **GREEN**: Implement `checkOverheat()`
5. **RED**: Write integration tests
6. **GREEN**: Integrate into game.lua
7. Add visual warning rendering
8. Manual testing
9. Update `roadmap_progress.md`
10. Commit

## Edge Cases

- Multiple powers at exactly 10: Return first one found
- Power removed then re-added: Should still trigger at 10
- Newly created pieces (Multiply): Start with 0 powers, no overheat risk

## Future Considerations

Phase 9 powers that add powers (Teach, Learn) must also trigger overheat check.
