# Phase 9B: Power Integration Fix

## Overview

**Status**: In Progress  
**Problem**: 70+ powers show animations but don't execute game logic  
**Solution**: Create `PowerExecutor` module for centralized dispatch  
**New Tests**: 89  
**Architectural Changes**: Orbs in state, blocking in power definitions

---

## Problem Statement

### The Bug

After Phase 9 completion (82 powers, 810 tests), user testing revealed that powers like `double_powers` (2x) and `scramble_row` show animations but don't actually work.

### Root Cause

`Game.executepower()` in `src/game.lua` (lines 2081-2166) only has handlers for the **original 12 powers**:

```lua
-- Only these 12 powers are wired up:
destroy_row, destroy_column, raise_tile, lower_tile,
recruit, multiply, bomb, relocate, move_again,
move_diagonal, jump_proof, invisible
```

The **70+ newer powers** implemented in Phase 9 have their logic in `PowerEffects.activate*()` functions, but are **never called** from the game UI. The function plays sounds/particles but falls through without executing the effect.

### Testing Gap

Our tests only verify `PowerEffects.activate*()` works in isolation - we never tested that `Game.executepower()` actually calls these functions. This is an integration testing gap.

### Affected Files

Two files have the same bug:
1. `src/game.lua:2081-2166` - `Game.executepower()` 
2. `src/shared/game_animations.lua:51-97` - `createPowerAnimation()` and `applyPowerEffect()`

---

## Solution

### PowerExecutor Module

Create `src/shared/power_executor.lua` - a pure dispatch module that:
1. Maps power IDs to their `PowerEffects.activate*()` functions
2. Returns animation metadata (type, blocking, data)
3. Has no Love2D dependencies (fully testable)

### Architectural Improvements (Server-Ready)

1. **Orbs in State**: Move `Game.orbs` into `Game.state.orbs` for state sync
2. **Blocking in Definition**: Add `blocking = true/false` to each power definition
3. **Integration Tests**: 89 new tests verifying end-to-end power execution

---

## File Structure

### New Files

```
lua/love2d/
├── src/shared/
│   └── power_executor.lua          # Power dispatch module (~400 lines)
└── spec/
    ├── helpers/                    # Test helpers by category
    │   ├── init.lua                # Common utilities (~50 lines)
    │   ├── state.lua               # State creation helpers (~80 lines)
    │   ├── pieces.lua              # Piece helpers (~60 lines)
    │   ├── powers.lua              # Power assertion helpers (~60 lines)
    │   ├── orbs.lua                # Orb helpers (~40 lines)
    │   └── terrain.lua             # Height/terrain helpers (~40 lines)
    └── power_executor/             # Tests by category
        ├── self_spec.lua           # 12 tests (~250 lines)
        ├── row_spec.lua            # 20 tests (~400 lines)
        ├── column_spec.lua         # 20 tests (~400 lines)
        ├── radial_spec.lua         # 21 tests (~420 lines)
        ├── targeted_spec.lua       # 6 tests (~150 lines)
        ├── global_spec.lua         # 2 tests (~80 lines)
        ├── special_spec.lua        # 1 test (~50 lines)
        └── targeting_spec.lua      # 7 tests (~150 lines)
```

### Modified Files

```
src/shared/powers.lua              # Add blocking field (+82 lines)
src/shared/game_logic.lua          # Add orbs to state (+5 lines)
src/shared/animations.lua          # Add generic animations (+100 lines)
src/shared/game_animations.lua     # Use PowerExecutor (~50 lines changed)
src/game.lua                       # Use PowerExecutor, state.orbs (~100 lines)
```

---

## Powers by Targeting Type

| Targeting | Count | Powers |
|-----------|-------|--------|
| `self` | 12 | move_diagonal, move_again, relocate, jump_proof, invisible, climb_tile, flat_to_sphere, scavenger, beneficiary, grow_quadradius, double_powers, hotspot |
| `self_row` | 20 | destroy_row, kamikaze_row, recruit_row, scramble_row, acidic_row, trench_row, wall_row, invert_row, dredge_row, teach_row, learn_row, pilfer_row, spyware_row, orb_spy_row, refurb_row, bankrupt_row, tripwire_row, inhibit_row, parasite_row, purify_row |
| `self_column` | 20 | (same pattern with _column suffix) |
| `area_3x3` | 21 | bomb, destroy_radial, kamikaze_radial, smart_bombs, scramble_radial, acidic_radial, plateau, moat, invert_radial, dredge_radial, teach_radial, learn_radial, pilfer_radial, spyware_radial, orb_spy_radial, refurb_radial, bankrupt_radial, tripwire_radial, inhibit_radial, parasite_radial, purify_radial |
| `adjacent` | 3 | raise_tile, lower_tile, switcheroo |
| `adjacent_enemy` | 1 | recruit |
| `adjacent_empty` | 1 | multiply |
| `adjacent_destroyed` | 1 | refurb |
| `global` | 2 | orbic_rehash, cancel_multiply |
| `special` | 1 | centerpult |

**Total: 82 powers**

---

## Blocking Classification

### `blocking = false` (25 powers)

Non-blocking animations for passive/permanent effects:

```
move_diagonal, move_again, jump_proof, invisible, climb_tile,
flat_to_sphere, scavenger, beneficiary, grow_quadradius, double_powers,
spyware_radial, spyware_row, spyware_column,
orb_spy_radial, orb_spy_row, orb_spy_column,
inhibit_radial, inhibit_row, inhibit_column,
parasite_radial, parasite_row, parasite_column,
purify_radial, purify_row, purify_column
```

### `blocking = true` (57 powers)

Blocking animations for offensive/terrain/position changes:

```
destroy_row, destroy_column, destroy_radial,
bomb, kamikaze_radial, kamikaze_row, kamikaze_column,
recruit, recruit_row, recruit_column,
multiply, smart_bombs, scramble_radial, scramble_row, scramble_column,
acidic_radial, acidic_row, acidic_column,
raise_tile, lower_tile, plateau, moat,
trench_row, trench_column, wall_row, wall_column,
invert_radial, invert_row, invert_column,
dredge_radial, dredge_row, dredge_column,
teach_radial, teach_row, teach_column,
learn_radial, learn_row, learn_column,
pilfer_radial, pilfer_row, pilfer_column,
refurb, refurb_radial, refurb_row, refurb_column,
bankrupt_radial, bankrupt_row, bankrupt_column,
tripwire_radial, tripwire_row, tripwire_column,
relocate, switcheroo, hotspot, centerpult,
orbic_rehash, cancel_multiply
```

---

## Generic Animation Types

Add to `src/shared/animations.lua`:

### Animation Factories

```lua
-- Duration constants
local DURATION_GENERIC = 0.5

--- Create self-targeting power animation
-- Visual: Piece glows and pulses with expanding aura ring
function Animations.createPowerSelf(row, col, onComplete)
    return Animations.createAnimation("power_self", DURATION_GENERIC, {
        row = row,
        col = col,
    }, false, onComplete)
end

--- Create row power animation
-- Visual: Horizontal sweep line travels across row from origin
function Animations.createPowerRow(row, originCol, onComplete)
    return Animations.createAnimation("power_row", DURATION_GENERIC, {
        row = row,
        originCol = originCol,
    }, true, onComplete)
end

--- Create column power animation
-- Visual: Vertical sweep line travels down/up column from origin
function Animations.createPowerColumn(col, originRow, onComplete)
    return Animations.createAnimation("power_column", DURATION_GENERIC, {
        col = col,
        originRow = originRow,
    }, true, onComplete)
end

--- Create radial (3x3) power animation
-- Visual: Expanding circle/ring from center, affects 3x3 area
function Animations.createPowerRadial(row, col, onComplete)
    return Animations.createAnimation("power_radial", 0.6, {
        row = row,
        col = col,
    }, true, onComplete)
end

--- Create global power animation
-- Visual: Screen-wide flash/pulse effect
function Animations.createPowerGlobal(onComplete)
    return Animations.createAnimation("power_global", 0.4, {
    }, true, onComplete)
end

--- Create swap animation (for switcheroo, scramble)
-- Visual: Two pieces spiral around each other and swap
function Animations.createPowerSwap(positions, onComplete)
    return Animations.createAnimation("power_swap", 0.6, {
        positions = positions,
    }, true, onComplete)
end
```

### Animation Rendering (Game.lua)

```lua
-- In Game.draw(), add cases for new animation types:

elseif anim.type == "power_self" then
    -- Glow effect on piece
    local progress = Animations.getProgress(anim)
    local intensity = math.sin(progress * math.pi)  -- 0->1->0
    local x, y = Game.boardToScreen(anim.data.row, anim.data.col)
    
    love.graphics.setColor(1, 1, 0.5, intensity * 0.6)  -- Yellow glow
    love.graphics.circle("fill", x, y, 30 + intensity * 20)
    love.graphics.setColor(1, 1, 1, 1)

elseif anim.type == "power_row" then
    -- Horizontal sweep
    local progress = Animations.getProgress(anim)
    local easedProgress = Animations.ease.easeOutQuad(progress)
    
    local startX = Game.boardToScreenX(1)
    local endX = Game.boardToScreenX(Game.state.cols)
    local currentX = startX + (endX - startX) * easedProgress
    local y = Game.boardToScreenY(anim.data.row)
    
    love.graphics.setColor(1, 0.8, 0.2, 1 - progress)  -- Fading yellow
    love.graphics.setLineWidth(4)
    love.graphics.line(currentX - 20, y - 40, currentX - 20, y + 40)
    love.graphics.setColor(1, 1, 1, 1)

elseif anim.type == "power_column" then
    -- Vertical sweep
    local progress = Animations.getProgress(anim)
    local easedProgress = Animations.ease.easeOutQuad(progress)
    
    local startY = Game.boardToScreenY(1)
    local endY = Game.boardToScreenY(Game.state.rows)
    local currentY = startY + (endY - startY) * easedProgress
    local x = Game.boardToScreenX(anim.data.col)
    
    love.graphics.setColor(1, 0.8, 0.2, 1 - progress)
    love.graphics.setLineWidth(4)
    love.graphics.line(x - 40, currentY, x + 40, currentY)
    love.graphics.setColor(1, 1, 1, 1)

elseif anim.type == "power_radial" then
    -- Expanding ring
    local progress = Animations.getProgress(anim)
    local easedProgress = Animations.ease.easeOutQuad(progress)
    local x, y = Game.boardToScreen(anim.data.row, anim.data.col)
    local maxRadius = 80  -- Covers 3x3 tiles
    local radius = maxRadius * easedProgress
    
    love.graphics.setColor(1, 0.6, 0.2, 1 - progress)
    love.graphics.setLineWidth(3)
    love.graphics.circle("line", x, y, radius)
    love.graphics.setColor(1, 1, 1, 1)

elseif anim.type == "power_global" then
    -- Screen flash
    local progress = Animations.getProgress(anim)
    local intensity = math.sin(progress * math.pi) * 0.3
    
    love.graphics.setColor(1, 1, 0.8, intensity)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setColor(1, 1, 1, 1)
```

---

## Animation Suggestions (Future)

Comments for future custom animations per power:

```lua
-- Suggested animations for future implementation:
local ANIMATION_SUGGESTIONS = {
    -- Meta
    double_powers = "Piece glows, power icons multiply/duplicate",
    orbic_rehash = "All orbs shimmer and teleport to new positions",
    cancel_multiply = "Ghost of destroyed piece fades away",
    grow_quadradius = "Expanding aura ring around piece",
    beneficiary = "Glowing tether lines to allied pieces",
    
    -- Terrain
    plateau = "3x3 tiles rise dramatically",
    moat = "Center rises, ring sinks with water effect",
    trench_row = "Row tiles sink with dust clouds",
    wall_row = "Row tiles rise like barrier",
    invert_radial = "Tiles flip/rotate 180 degrees",
    dredge_radial = "Friendly tiles glow green+rise, enemy red+sink",
    
    -- Offensive
    destroy_radial = "Explosion ring expands from center",
    kamikaze_* = "Piece explodes with self included",
    acidic_* = "Green acid spreads, dissolves tiles",
    smart_bombs = "Targeted missiles at enemy pieces only",
    
    -- Strategic
    recruit_row = "Wave of color change sweeps across row",
    teach_* = "Glowing particles flow from piece to allies",
    learn_* = "Glowing particles flow from allies to piece",
    pilfer_* = "Dark tendrils steal from enemies",
    
    -- Chaos
    scramble_* = "Pieces spin and swap positions rapidly",
    
    -- Movement
    switcheroo = "Two pieces spiral around each other",
    flat_to_sphere = "Brief globe overlay showing wraparound",
    hotspot = "Portal effect on tile",
    centerpult = "Piece launches toward 4-piece center",
    
    -- Intelligence
    spyware_* = "Scanning beam reveals enemy powers",
    orb_spy_* = "X-ray effect reveals orb contents",
    
    -- Control/Trap
    tripwire_* = "Red warning lines appear on tiles",
    inhibit_* = "Purple inhibitor field on enemies",
    parasite_* = "Green parasite attaches to enemies",
    bankrupt_* = "Drain symbols appear on tiles",
    
    -- Restoration
    refurb_* = "Tiles regenerate from rubble",
    purify_* = "Cleansing light removes debuffs",
}
```

---

## Test Helpers Structure

### `spec/helpers/init.lua`

```lua
-- Test helpers index
-- Usage: local H = require("spec.helpers")
local Helpers = {}

Helpers.State = require("spec.helpers.state")
Helpers.Pieces = require("spec.helpers.pieces")
Helpers.Powers = require("spec.helpers.powers")
Helpers.Orbs = require("spec.helpers.orbs")
Helpers.Terrain = require("spec.helpers.terrain")

return Helpers
```

### `spec/helpers/state.lua`

```lua
-- State creation helpers
local State = {}
local GameLogic = require("src.shared.game_logic")

--- Create empty state (no default pieces)
function State.createEmpty()
    local state = GameLogic.createInitialState()
    state.pieces = {}
    state.orbs = {}
    return state
end

--- Create state with specific configuration
---@param config {pieces: table[], orbs: table[], heights: table}
function State.create(config) ... end

--- Clone state (shallow, for comparison)
function State.clone(state) ... end

return State
```

### `spec/helpers/pieces.lua`

```lua
-- Piece helpers
local Pieces = {}

--- Create a piece with defaults
function Pieces.create(row, col, player, powers) ... end

--- Get piece at position
function Pieces.getAt(state, row, col) ... end

--- Count pieces by player
function Pieces.countByPlayer(state, player) ... end

--- Count total pieces
function Pieces.countTotal(state) ... end

--- Get all pieces in row
function Pieces.inRow(state, row) ... end

--- Get all pieces in column
function Pieces.inColumn(state, col) ... end

--- Get all pieces in 3x3 area
function Pieces.inRadial(state, centerRow, centerCol) ... end

--- Check if piece exists at position
function Pieces.existsAt(state, row, col) ... end

return Pieces
```

### `spec/helpers/powers.lua`

```lua
-- Power helpers
local Powers = {}

--- Check if piece has power
function Powers.has(piece, powerId) ... end

--- Count power occurrences on piece
function Powers.count(piece, powerId) ... end

--- Get all powers on piece
function Powers.getAll(piece) ... end

--- Assert piece has exactly N of power
function Powers.assertCount(piece, powerId, expected) ... end

--- Assert piece has power (at least one)
function Powers.assertHas(piece, powerId) ... end

--- Assert piece does NOT have power
function Powers.assertNotHas(piece, powerId) ... end

--- Assert power was consumed (removed from piece)
function Powers.assertConsumed(piece, powerId) ... end

return Powers
```

### `spec/helpers/orbs.lua`

```lua
-- Orb helpers
local Orbs = {}

--- Create an orb
function Orbs.create(row, col, powerId) ... end

--- Get orb at position
function Orbs.getAt(state, row, col) ... end

--- Count orbs
function Orbs.count(state) ... end

--- Check if orb exists at position
function Orbs.existsAt(state, row, col) ... end

return Orbs
```

### `spec/helpers/terrain.lua`

```lua
-- Terrain helpers
local Terrain = {}

--- Get height at position
function Terrain.getHeight(state, row, col) ... end

--- Set height at position
function Terrain.setHeight(state, row, col, height) ... end

--- Check if tile is destroyed
function Terrain.isDestroyed(state, row, col) ... end

--- Assert height equals expected
function Terrain.assertHeight(state, row, col, expected) ... end

--- Assert tile is destroyed
function Terrain.assertDestroyed(state, row, col) ... end

return Terrain
```

---

## PowerExecutor Module Design

### Interface

```lua
-- Power Executor Module
-- Dispatches power activation to correct PowerEffects function
-- No Love2D dependencies - pure game logic

local PowerExecutor = {}

local PowerEffects = require("src.shared.power_effects")
local Powers = require("src.shared.powers")

--- Execute a power's game logic
---@param state table Game state (includes orbs)
---@param piece table Piece activating
---@param powerId string Power ID
---@param target table|nil Target for targeted powers
---@return table newState
function PowerExecutor.execute(state, piece, powerId, target)
    -- Dispatch to correct PowerEffects function
end

--- Get valid targets for a targeted power
---@param state table Game state
---@param piece table Piece activating
---@param powerId string Power ID
---@return table Array of valid targets
function PowerExecutor.getTargets(state, piece, powerId)
    -- Dispatch to correct get*Targets function
end

--- Get animation info for a power
---@param powerId string Power ID
---@param piece table Piece activating
---@param target table|nil Target if applicable
---@return string animationType, table animData, boolean blocking
function PowerExecutor.getAnimationInfo(powerId, piece, target)
    -- Return animation metadata from power definition
end

return PowerExecutor
```

### Dispatch Implementation

The `execute()` function uses a dispatch table:

```lua
local DISPATCH = {
    -- Self-targeting (12)
    move_diagonal = function(state, piece) return PowerEffects.activateMoveDiagonal(state, piece) end,
    move_again = function(state, piece) return PowerEffects.activateMoveAgain(state, piece) end,
    jump_proof = function(state, piece) return PowerEffects.activateJumpProof(state, piece) end,
    invisible = function(state, piece) return PowerEffects.activateInvisible(state, piece) end,
    relocate = function(state, piece) return PowerEffects.activateRelocate(state, piece) end,
    climb_tile = function(state, piece) return PowerEffects.activateClimbTile(state, piece) end,
    flat_to_sphere = function(state, piece) return PowerEffects.activateFlatToSphere(state, piece) end,
    scavenger = function(state, piece) return PowerEffects.activateScavenger(state, piece) end,
    beneficiary = function(state, piece) return PowerEffects.activateBeneficiary(state, piece) end,
    grow_quadradius = function(state, piece) return PowerEffects.activateGrowQuadradius(state, piece) end,
    double_powers = function(state, piece) return PowerEffects.activateDoublePowers(state, piece) end,
    hotspot = function(state, piece) return PowerEffects.activateHotspot(state, piece) end,
    
    -- Row powers (20)
    destroy_row = function(state, piece) return PowerEffects.activateDestroyRow(state, piece) end,
    kamikaze_row = function(state, piece) return PowerEffects.activateKamikazeRow(state, piece) end,
    -- ... etc
    
    -- Column powers (20)
    -- ... etc
    
    -- Radial powers (21)
    -- ... etc
    
    -- Targeted powers (6) - need target parameter
    raise_tile = function(state, piece, target) return PowerEffects.activateRaiseTile(state, piece, target) end,
    -- ... etc
    
    -- Global powers (2) - may need orbs from state
    orbic_rehash = function(state, piece) return PowerEffects.activateOrbicRehash(state, piece, state.orbs) end,
    -- ... etc
    
    -- Special (1)
    centerpult = function(state, piece, target) return PowerEffects.activateCenterpult(state, piece, target) end,
}

function PowerExecutor.execute(state, piece, powerId, target)
    local handler = DISPATCH[powerId]
    if handler then
        return handler(state, piece, target)
    end
    return state  -- Unknown power, no change
end
```

---

## Implementation Phases

### Phase A: Foundation

| Step | Task | Files |
|------|------|-------|
| A1 | Add `orbs = {}` to state | `game_logic.lua`, `spec/game_logic_spec.lua` |
| A2 | Add `blocking` to 82 power definitions | `powers.lua` |
| A3 | Create test helpers | `spec/helpers/*.lua` |

### Phase B: Self-Targeting Powers (12)

| Step | Task |
|------|------|
| B1 | Create `spec/power_executor/self_spec.lua` (RED) |
| B2 | Create `src/shared/power_executor.lua` skeleton |
| B3 | Implement dispatch for 12 self-targeting powers (GREEN) |

### Phase C: Row Powers (20)

| Step | Task |
|------|------|
| C1 | Create `spec/power_executor/row_spec.lua` (RED) |
| C2 | Implement dispatch for 20 row powers (GREEN) |

### Phase D: Column Powers (20)

| Step | Task |
|------|------|
| D1 | Create `spec/power_executor/column_spec.lua` (RED) |
| D2 | Implement dispatch for 20 column powers (GREEN) |

### Phase E: Radial Powers (21)

| Step | Task |
|------|------|
| E1 | Create `spec/power_executor/radial_spec.lua` (RED) |
| E2 | Implement dispatch for 21 radial powers (GREEN) |

### Phase F: Targeted Powers (6)

| Step | Task |
|------|------|
| F1 | Create `spec/power_executor/targeted_spec.lua` (RED) |
| F2 | Implement dispatch for 6 targeted powers (GREEN) |

### Phase G: Global Powers (2)

| Step | Task |
|------|------|
| G1 | Create `spec/power_executor/global_spec.lua` (RED) |
| G2 | Implement dispatch for 2 global powers (GREEN) |

### Phase H: Special Powers (1)

| Step | Task |
|------|------|
| H1 | Create `spec/power_executor/special_spec.lua` (RED) |
| H2 | Implement dispatch for centerpult (GREEN) |

### Phase I: Targeting Functions (7)

| Step | Task |
|------|------|
| I1 | Create `spec/power_executor/targeting_spec.lua` (RED) |
| I2 | Implement `PowerExecutor.getTargets()` (GREEN) |

### Phase J: Generic Animations

| Step | Task |
|------|------|
| J1 | Add tests for generic animations |
| J2 | Implement 6 generic animation factories |

### Phase K: Update GameAnimations

| Step | Task |
|------|------|
| K1 | Update `game_animations.lua` to use PowerExecutor |
| K2 | Update tests |

### Phase L: Game Integration

| Step | Task |
|------|------|
| L1 | Update `Game.executepower()` to use PowerExecutor |
| L2 | Update `Game.getPowerTargets()` to use PowerExecutor |
| L3 | Change `Game.orbs` to `Game.state.orbs` |
| L4 | Add rendering for generic animation types |

### Phase M: Final Verification

| Step | Task |
|------|------|
| M1 | Run full test suite (expect 899 tests) |
| M2 | Manual test: `double_powers` |
| M3 | Manual test: `scramble_row` |
| M4 | Manual test: 5 other random powers |

---

## Test Count Summary

| Category | Tests |
|----------|-------|
| Self-targeting | 12 |
| Row powers | 20 |
| Column powers | 20 |
| Radial powers | 21 |
| Targeted powers | 6 |
| Global powers | 2 |
| Special powers | 1 |
| Targeting functions | 7 |
| **Total New** | **89** |
| **Previous** | **810** |
| **Expected Total** | **899** |

---

## Files Summary

| File | Action | Lines |
|------|--------|-------|
| `src/shared/power_executor.lua` | CREATE | ~400 |
| `src/shared/powers.lua` | MODIFY | +82 |
| `src/shared/game_logic.lua` | MODIFY | +5 |
| `src/shared/animations.lua` | MODIFY | +100 |
| `src/shared/game_animations.lua` | MODIFY | ~50 |
| `src/game.lua` | MODIFY | ~100 |
| `spec/helpers/*.lua` (6 files) | CREATE | ~330 |
| `spec/power_executor/*.lua` (8 files) | CREATE | ~1900 |
| **Total** | | ~2967 |

---

## References

- [Phase 9 Powers](phase9_powers.md) - Original power implementation
- [Original Quadradius Powers](../../../research/quadradius/game_details/powers.md) - All 87 powers
- [Progress Tracker](phase9b_power_integration_progress.md) - Implementation progress
