# Phase 4C: Persistent Power Indicators

## Overview

Add permanent visual indicators for activated permanent powers so players can see which pieces have special abilities at a glance.

## Reference

Based on original Quadradius documentation at https://quadradius.ddns.net/directions.html:
- **Jump Proof** is described as "armor" - "your armored piece", "Jump Proof armor"
- **Move Diagonal** shows "navigating arrows" on pieces

## Design Decisions

| Decision | Choice |
|----------|--------|
| Jump Proof indicator | Armor bands - 2 metallic cyan rings wrapped around torus |
| Move Diagonal indicator | Diagonal lines - 4 short lines extending from piece corners |
| Jump Proof activation | Armor wraps around piece during animation, then remains permanently |
| Move Diagonal activation | Lines extend outward during animation, then remain permanently |

## Piece Flags

Permanent powers set flags on pieces when activated:

| Flag | Set By | Visual Indicator |
|------|--------|------------------|
| `piece.isJumpProof` | `activateJumpProof()` | Armor bands |
| `piece.canMoveDiagonally` | `activateMoveDiagonal()` | Diagonal lines |
| `piece.isInvisible` | `activateInvisible()` | (Future: semi-transparent) |

## Task Breakdown (TDD Order)

### Step 1: Indicators Module (Tests First)

**Goal:** Create `src/shared/indicators.lua` with testable function to determine what visual indicators a piece should display.

**Tests first (`spec/indicators_spec.lua`):**

1. `getPieceIndicators(piece)` returns empty table for piece with no flags
2. `getPieceIndicators(piece)` returns `{"jump_proof"}` when `piece.isJumpProof == true`
3. `getPieceIndicators(piece)` returns `{"move_diagonal"}` when `piece.canMoveDiagonally == true`
4. `getPieceIndicators(piece)` returns multiple indicators when piece has multiple flags
5. `getPieceIndicators(piece)` returns `{"invisible"}` when `piece.isInvisible == true`

**Then implement in `src/shared/indicators.lua`:**

```lua
--- Get list of visual indicators for a piece based on its flags
---@param piece table Piece to check
---@return table Array of indicator names
function Indicators.getPieceIndicators(piece)
    local indicators = {}
    if piece.isJumpProof then
        table.insert(indicators, "jump_proof")
    end
    if piece.canMoveDiagonally then
        table.insert(indicators, "move_diagonal")
    end
    if piece.isInvisible then
        table.insert(indicators, "invisible")
    end
    return indicators
end
```

### Step 2: Visual Rendering - Persistent Indicators (No Tests)

**Goal:** Draw persistent indicators in `Game.drawPieces()` for pieces with active flags.

**Location:** `src/game.lua` in `Game.drawPieces()`, after drawing piece body, before selection ring.

**Jump Proof Armor Bands:**
- 2 horizontal metallic cyan bands/rings wrapped around the torus body
- Lower band at `y - 8`, upper band at `y - 16`
- Cyan metallic color (0.5, 0.8, 1.0) with white highlight arc
- Line width 2

**Move Diagonal Lines:**
- 4 short lines extending from piece center at diagonal angles
- Green color (0.3, 0.9, 0.5) for movement indication
- Lines from inner radius (18) to outer radius (28)
- Adjusted for isometric squash (y * 0.5)

### Step 3: Update Activation Animations (No Tests)

**Goal:** Make activation animations show the indicator "appearing/wrapping on" before transitioning to persistent state.

**Jump Proof Animation (`Game.drawJumpProofAnimation`):**

Current: Shield bubble appears, scales with bounce, fades out
New:
- Phase 1 (0-50%): Armor bands scale from 0 to full size (wrapping effect)
- Phase 2 (50-100%): Bands settle, metallic highlight appears
- After animation: Persistent indicator in `drawPieces()` takes over (flag already set)

**Move Diagonal Animation (`Game.drawMoveDiagonalAnimation`):**

Current: Diagonal arrows flash outward and fade
New:
- Phase 1 (0-50%): Lines extend outward from center (length grows)
- Phase 2 (50-100%): Lines reach full length, glow settles
- After animation: Persistent indicator in `drawPieces()` takes over (flag already set)

## Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `docs/phase4c_indicators.md` | CREATE | This plan document |
| `spec/indicators_spec.lua` | CREATE | Tests for Indicators module (~5 tests) |
| `src/shared/indicators.lua` | CREATE | Indicators module with `getPieceIndicators()` |
| `src/game.lua` | MODIFY | Add indicator rendering in `drawPieces()`, update animations |

## Test Count

| Change | Tests |
|--------|-------|
| `getPieceIndicators()` tests | +5 |
| Current total | 376 |
| **New total** | **381** |

## Execution Order

1. **RED:** Write 5 failing tests for `getPieceIndicators()` in `spec/indicators_spec.lua`
2. **GREEN:** Implement `getPieceIndicators()` in `src/shared/indicators.lua`
3. Run tests to verify pass
4. Add persistent indicator rendering in `Game.drawPieces()`
5. Update `Game.drawJumpProofAnimation()` for wrap-on effect
6. Update `Game.drawMoveDiagonalAnimation()` for extend effect
7. Manual testing with game
8. Update `docs/progress.md`
9. Commit
