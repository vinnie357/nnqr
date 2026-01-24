# Reviewing session-ses_4e28.md

**Session ID:** ses_4e025325dffeHpqfQQ4Cefxu82
**Created:** 12/14/2025, 9:33:11 PM
**Updated:** 12/15/2025, 8:25:11 PM

---

## User

1 fix powers first, 2 use a generic animation for now, but suggest what one might be for that power, 3 allways TDD

---

## Assistant

Got it! **TDD approach, fix powers first, suggest animations as comments.** Let me build a comprehensive plan.

```
Tool: todowrite
```

---

## Assistant

```
Tool: read
```

```
Tool: bash
```

---

## Assistant

```
Tool: todowrite
```

---

## Assistant

Now let me check the existing animation system:

```
Tool: bash
```

```
Tool: read
```

---

## Assistant

```
Tool: read
```

---

## Assistant

Now let me analyze the targeting patterns and understand the dispatch structure needed:

```
Tool: bash
```

---

## Assistant

```
Tool: todowrite
```

---

## Assistant

Now let me look at how the 12 working powers are wired up in `Game.executepower()` vs how the 70 non-working powers need to be wired:

```
Tool: read
```

---

## Assistant

This is important - `Game.getPowerTargets()` also only handles 4 powers! Let me check if there are more `get*Targets` functions:

```
Tool: bash
```

---

## Assistant

Now let me understand the test file structure to design our integration tests:

```
Tool: bash
```

---

## Assistant

Now I have enough information. Let me create the comprehensive plan:

```
Tool: todowrite
```

---

## Assistant

---

# Implementation Plan: Power Integration Fix (TDD)

## Overview

**Bug**: `Game.executepower()` only has handlers for 12 powers. The 70+ newer powers have `PowerEffects.activate*()` functions that are never called.

**Fix**: Create `PowerExecutor` module that dispatches ALL powers correctly, with integration tests.

---

## Current State Analysis

### Powers by Targeting Type (82 total)

| Targeting | Count | Examples |
|-----------|-------|----------|
| `self` | 12 | move_diagonal, jump_proof, double_powers, grow_quadradius |
| `self_row` | 20 | destroy_row, recruit_row, scramble_row, trench_row |
| `self_column` | 20 | destroy_column, recruit_column, scramble_column |
| `area_3x3` | 21 | bomb, plateau, moat, smart_bombs, teach_radial |
| `adjacent` | 3 | raise_tile, lower_tile, switcheroo |
| `adjacent_enemy` | 1 | recruit |
| `adjacent_empty` | 1 | multiply |
| `adjacent_destroyed` | 1 | refurb |
| `global` | 2 | orbic_rehash, cancel_multiply |
| `special` | 1 | centerpult |

### Existing Animations (13 available)

```
createDestroyRow, createDestroyColumn, createBomb, createRelocate,
createRaiseTile, createLowerTile, createRecruit, createMultiply,
createMoveDiagonal, createJumpProof, createInvisible, createMoveAgain
```

---

## Files to Create/Modify

### 1. NEW: `src/shared/power_executor.lua`

Pure dispatch logic - no Love2D dependencies, fully testable.

```lua
-- Power Executor Module
-- Dispatches power activation to correct PowerEffects function
-- No Love2D dependencies - pure game logic

local PowerExecutor = {}

local PowerEffects = require("src.shared.power_effects")
local Powers = require("src.shared.powers")

--- Execute a power's game logic
---@param state table Game state
---@param piece table Piece activating
---@param powerId string Power ID
---@param target table|nil Target for targeted powers
---@param orbs table|nil Orbs array (for orb-related powers)
---@return table newState, table|nil animationType, table|nil animData
function PowerExecutor.execute(state, piece, powerId, target, orbs)
    local def = Powers.definitions[powerId]
    if not def then
        return state, nil, nil
    end
    
    -- Dispatch to correct PowerEffects function
    -- Returns: newState, animationType (string), animData (table)
    
    -- The massive dispatch table goes here...
end

--- Get valid targets for a targeted power
---@param state table Game state
---@param piece table Piece activating
---@param powerId string Power ID
---@return table Array of valid targets
function PowerExecutor.getTargets(state, piece, powerId)
    -- Dispatch to correct get*Targets function
end

return PowerExecutor
```

### 2. NEW: `spec/power_executor_spec.lua`

Integration tests verifying end-to-end power execution.

```lua
describe("PowerExecutor", function()
    local PowerExecutor, GameLogic, Powers

    setup(function()
        PowerExecutor = require("src.shared.power_executor")
        GameLogic = require("src.shared.game_logic")
        Powers = require("src.shared.powers")
    end)

    -- Test each power category
    describe("Meta Powers", function()
        it("double_powers doubles all powers on piece", function()
            local state = GameLogic.createInitialState()
            local piece = state.pieces[1]
            piece.powers = { "bomb", "recruit" }
            
            state = PowerExecutor.execute(state, piece, "double_powers")
            
            assert.are.equal(4, #piece.powers)
            -- Should have 2x bomb, 2x recruit
        end)
    end)
    
    -- ... tests for each power
end)
```

### 3. MODIFY: `src/game.lua`

Update `Game.executepower()` and `Game.getPowerTargets()` to use PowerExecutor.

**Before** (lines 2081-2166):
```lua
function Game.executepower(piece, powerId, target)
    -- 12 hardcoded if/elseif branches
end
```

**After**:
```lua
function Game.executepower(piece, powerId, target)
    Game.playSoundForPower(powerId)
    Game.spawnPowerParticles(powerId, piece.row, piece.col)
    
    -- Get animation info from executor
    local newState, animType, animData = PowerExecutor.execute(
        Game.state, piece, powerId, target, Game.orbs
    )
    
    -- Create animation with callback to apply state
    local anim = Game.createAnimationForPower(animType, animData, function()
        Game.state = newState
        Game.refreshSelection()
    end)
    
    if anim and Game.animations then
        Animations.AnimationQueue.add(Game.animations.queue, anim)
    end
    
    Game.powerMode = nil
    Game.powerTargets = {}
end
```

---

## Animation Strategy

Use **generic animation types** based on power category, with comments suggesting future custom animations.

### Generic Animation Types to Add

| Type | Use For | Visual |
|------|---------|--------|
| `power_self` | Self-targeting buffs | Glow/pulse on piece |
| `power_row` | Row effects | Horizontal sweep |
| `power_column` | Column effects | Vertical sweep |
| `power_radial` | 3x3 area effects | Expanding ring |
| `power_global` | Global effects | Screen flash |
| `power_swap` | Position swaps | Pieces trade places |
| `power_transfer` | Power transfers | Particles flow between |

### Animation Suggestions Per Power (as comments)

```lua
-- Suggested animations for future implementation:
local ANIMATION_SUGGESTIONS = {
    -- Meta
    double_powers = "Pieces glows, power icons multiply/duplicate",
    orbic_rehash = "All orbs shimmer and teleport to new positions",
    cancel_multiply = "Ghost of destroyed piece fades away",
    grow_quadradius = "Expanding aura ring around piece",
    beneficiary = "Glowing tether lines to allied pieces",
    
    -- Terrain
    plateau = "3x3 tiles rise dramatically",
    moat = "Center rises, ring sinks with water effect",
    trench_row = "Row tiles sink with dust clouds",
    wall_row = "Row tiles rise like barrier",
    invert_radial = "Tiles flip/rotate 180°",
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

## TDD Implementation Order

Execute in this order to get maximum coverage quickly:

### Batch 1: Self-Targeting (12 powers)
Most straightforward - no targeting UI needed.

1. `double_powers` - Test first, most reported broken
2. `grow_quadradius`
3. `beneficiary`
4. `scavenger`
5. `flat_to_sphere`
6. `climb_tile`
7. `move_diagonal` (already works, verify integration)
8. `move_again` (already works, verify integration)
9. `jump_proof` (already works, verify integration)
10. `invisible` (already works, verify integration)
11. `relocate` (already works, verify integration)
12. `hotspot` (special - creates OR teleports)

### Batch 2: Row Effects (20 powers)
All use same targeting pattern.

1. `scramble_row` - Second reported broken power
2. `destroy_row` (already works, verify)
3. `kamikaze_row`
4. `recruit_row`
5. `acidic_row`
6. `trench_row`
7. `wall_row`
8. `invert_row`
9. `dredge_row`
10. `teach_row`
11. `learn_row`
12. `pilfer_row`
13. `spyware_row`
14. `orb_spy_row`
15. `refurb_row`
16. `bankrupt_row`
17. `tripwire_row`
18. `inhibit_row`
19. `parasite_row`
20. `purify_row`

### Batch 3: Column Effects (20 powers)
Mirror of row effects.

(Same 20 powers with `_column` suffix)

### Batch 4: Radial/3x3 Effects (21 powers)

1. `bomb` (already works, verify)
2. `destroy_radial`
3. `kamikaze_radial`
4. `smart_bombs`
5. `scramble_radial`
6. `acidic_radial`
7. `plateau`
8. `moat`
9. `invert_radial`
10. `dredge_radial`
11. `teach_radial`
12. `learn_radial`
13. `pilfer_radial`
14. `spyware_radial`
15. `orb_spy_radial`
16. `refurb_radial`
17. `bankrupt_radial`
18. `tripwire_radial`
19. `inhibit_radial`
20. `parasite_radial`
21. `purify_radial`

### Batch 5: Targeted Powers (6 powers)

1. `raise_tile` (already works, verify)
2. `lower_tile` (already works, verify)
3. `recruit` (already works, verify)
4. `multiply` (already works, verify)
5. `refurb` (adjacent_destroyed)
6. `switcheroo` (adjacent)

### Batch 6: Global & Special (3 powers)

1. `orbic_rehash` (global, needs orbs param)
2. `cancel_multiply` (global)
3. `centerpult` (special targeting)

---

## Estimated Effort

| Task | Time |
|------|------|
| Create PowerExecutor skeleton + first test | 15 min |
| Batch 1: Self-targeting (12 powers) | 45 min |
| Batch 2: Row effects (20 powers) | 30 min |
| Batch 3: Column effects (20 powers) | 20 min |
| Batch 4: Radial effects (21 powers) | 30 min |
| Batch 5: Targeted powers (6 powers) | 20 min |
| Batch 6: Global & special (3 powers) | 15 min |
| Update Game.lua to use PowerExecutor | 20 min |
| Add generic animations | 30 min |
| **Total** | **~4 hours** |

---

## Questions Before Implementation

1. **Orb handling**: `orbic_rehash` and `orb_spy_*` need access to the orbs array. Should PowerExecutor:
   - Take orbs as a parameter (cleaner but requires passing)
   - Have orbs in state (requires state refactor)

2. **State mutation**: Currently `PowerEffects.activate*()` mutates state in place AND returns it. Should we:
   - Keep this pattern (simpler, less breaking)
   - Move to pure immutable state (cleaner, more refactoring)

3. **Animation blocking**: Some powers should block input (destroy effects), others shouldn't (self buffs). The current system handles this per-animation. Should we:
   - Determine blocking from power category
   - Store blocking preference in power definition

---

Ready to proceed when you confirm the approach or answer the questions above!

---

## User

1 orbs in state this will matter more later for a server, 2 pure state this will matter more for a server, 3 store in power

---

## Assistant

Excellent decisions! All three choices optimize for server/multiplayer readiness:

1. **Orbs in state** - Enables state sync between clients
2. **Pure immutable state** - Enables state snapshots, undo, replay
3. **Blocking in power definition** - Centralized, declarative

Let me explore what's needed for these architectural changes:

```
Tool: bash
```

```
Tool: bash
```

```
Tool: bash
```

---

## Assistant

```
Tool: read
```

---

## Assistant

Now let me check how PowerEffects currently mutates state:

```
Tool: bash
```

```
Tool: bash
```

---

## Assistant

```
Tool: bash
```

---

## Assistant

That's 54 mutation points to convert to pure functions. Let me check if there's a deep copy utility:

```
Tool: bash
```

---

## Assistant

No deep copy utility exists. Let me check what blocking info would need to be added to power definitions:

```
Tool: bash
```

---

## Assistant

```
Tool: bash
```

---

## Assistant

So non-blocking animations are for passive/permanent powers. Let me now create the comprehensive implementation plan:

```
Tool: todowrite
```

---

## Assistant

---

# Updated Implementation Plan: Power Integration Fix (TDD)

## Architectural Changes (Server-Ready)

Based on your decisions:

### 1. Orbs in State

**Current**: `Game.orbs = {}` (separate from state)

**New**: Add to `GameLogic.createInitialState()`:
```lua
local state = {
    -- existing fields...
    orbs = {},  -- NEW: Array of {row, col, powerId, revealed}
}
```

**Impact**: 
- Modify `GameLogic.createInitialState()` (+1 line)
- Modify `Game.lua` to use `Game.state.orbs` (~12 changes)
- Update tests that reference orbs

### 2. Pure Immutable State

**Current**: PowerEffects functions mutate state in place:
```lua
function PowerEffects.activateDestroyRow(state, piece)
    table.remove(state.pieces, i)  -- Mutates!
    return state
end
```

**New**: Return new state without mutation:
```lua
function PowerEffects.activateDestroyRow(state, piece)
    local newState = deepCopy(state)
    -- Work on newState...
    return newState
end
```

**Impact**:
- Create `src/shared/utils.lua` with `deepCopy()` function
- Modify all 97 `PowerEffects.activate*()` functions (~54 mutation points)
- This is the largest change but enables replay/undo/server sync

**Mitigation**: We can do this incrementally:
1. First pass: Add PowerExecutor with current mutation pattern
2. Second pass: Convert to pure functions one category at a time

### 3. Blocking in Power Definition

**Current**: Blocking determined per-animation factory

**New**: Add to each power definition:
```lua
double_powers = {
    id = "double_powers",
    name = "2x",
    category = "Meta",
    duration = "single_use",
    description = "Double all powers on this piece",
    targeting = "self",
    blocking = false,  -- NEW
},
```

**Pattern**:
- `blocking = true`: Offensive, terrain-altering, position-changing
- `blocking = false`: Self buffs, permanent effects, intelligence

---

## Implementation Order (TDD)

### Phase A: Foundation (Do First)

| Step | Task | Test First? |
|------|------|-------------|
| A1 | Create `src/shared/utils.lua` with `deepCopy()` | Yes |
| A2 | Add `orbs = {}` to `GameLogic.createInitialState()` | Yes |
| A3 | Add `blocking` field to all 82 power definitions | No (data only) |
| A4 | Create `spec/power_executor_spec.lua` skeleton | Yes |
| A5 | Create `src/shared/power_executor.lua` skeleton | After A4 |

### Phase B: First Power Working (Prove Pattern)

| Step | Task |
|------|------|
| B1 | Write failing test for `double_powers` integration |
| B2 | Implement `PowerExecutor.execute()` for `double_powers` |
| B3 | Verify test passes |
| B4 | Write failing test for `scramble_row` |
| B5 | Implement dispatch for `scramble_row` |
| B6 | Verify test passes |

### Phase C: Batch Implementation

Once pattern proven, implement remaining powers in batches:

| Batch | Powers | Count |
|-------|--------|-------|
| C1 | Remaining self-targeting | 10 |
| C2 | All row effects | 20 |
| C3 | All column effects | 20 |
| C4 | All radial effects | 21 |
| C5 | Targeted powers | 6 |
| C6 | Global & special | 3 |

### Phase D: Game Integration

| Step | Task |
|------|------|
| D1 | Update `Game.executepower()` to use PowerExecutor |
| D2 | Update `Game.getPowerTargets()` to use PowerExecutor |
| D3 | Update `Game.lua` to use `state.orbs` instead of `Game.orbs` |
| D4 | Add generic animations for new powers |
| D5 | Manual testing in game |

### Phase E: Pure State (Can Defer)

| Step | Task |
|------|------|
| E1 | Convert self-targeting PowerEffects to pure |
| E2 | Convert row PowerEffects to pure |
| E3 | Convert column PowerEffects to pure |
| E4 | Convert radial PowerEffects to pure |
| E5 | Convert targeted PowerEffects to pure |
| E6 | Convert global PowerEffects to pure |

---

## File Changes Summary

### New Files
```
src/shared/utils.lua           # deepCopy utility
src/shared/power_executor.lua  # Power dispatch module
spec/power_executor_spec.lua   # Integration tests
```

### Modified Files
```
src/shared/game_logic.lua      # Add orbs to state (+5 lines)
src/shared/powers.lua          # Add blocking to 82 definitions (+82 lines)
src/shared/power_effects.lua   # Pure state conversion (Phase E)
src/shared/animations.lua      # Add generic animations (+100 lines)
src/game.lua                   # Use PowerExecutor, state.orbs (~50 lines)
```

---

## Blocking Classification

Based on animation patterns and power behavior:

### `blocking = true` (Blocks input during animation)
- **Offensive**: destroy_*, bomb, kamikaze_*, acidic_*, smart_bombs
- **Terrain**: raise/lower_tile, plateau, moat, trench_*, wall_*, invert_*, dredge_*
- **Position**: relocate, switcheroo, scramble_*, hotspot (teleport), centerpult
- **Strategic**: recruit*, multiply
- **Transfer**: teach_*, learn_*, pilfer_*
- **Trap**: bankrupt_*, tripwire_*
- **Restoration**: refurb*

### `blocking = false` (Non-blocking, passive effects)
- **Permanent Buffs**: move_diagonal, jump_proof, invisible, climb_tile, flat_to_sphere, scavenger, beneficiary, grow_quadradius
- **Meta**: double_powers
- **Control**: inhibit_*, parasite_*
- **Intelligence**: spyware_*, orb_spy_*
- **Restoration**: purify_*
- **Global**: orbic_rehash, cancel_multiply

---

## Generic Animation Types

Add to `src/shared/animations.lua`:

```lua
-- Generic power animations by category
local DURATION_GENERIC = 0.5

function Animations.createPowerSelf(row, col, onComplete)
    -- Suggested: Glow/pulse on piece
    return Animations.createAnimation("power_self", DURATION_GENERIC, {
        row = row, col = col
    }, false, onComplete)
end

function Animations.createPowerRow(row, originCol, onComplete)
    -- Suggested: Horizontal sweep effect
    return Animations.createAnimation("power_row", DURATION_GENERIC, {
        row = row, originCol = originCol
    }, true, onComplete)
end

function Animations.createPowerColumn(col, originRow, onComplete)
    -- Suggested: Vertical sweep effect
    return Animations.createAnimation("power_column", DURATION_GENERIC, {
        col = col, originRow = originRow
    }, true, onComplete)
end

function Animations.createPowerRadial(row, col, onComplete)
    -- Suggested: Expanding ring from center
    return Animations.createAnimation("power_radial", DURATION_GENERIC, {
        row = row, col = col
    }, true, onComplete)
end

function Animations.createPowerGlobal(onComplete)
    -- Suggested: Screen flash/pulse
    return Animations.createAnimation("power_global", DURATION_GENERIC, {}, true, onComplete)
end
```

---

## Questions / Tradeoffs

### 1. Pure State Timing

**Option A**: Do pure state conversion now (Phase E integrated with C)
- Pro: One pass through code, cleaner result
- Con: Larger initial PR, more risk

**Option B**: Defer pure state (Phase E after D)
- Pro: Get powers working faster, smaller PRs
- Con: Two passes through PowerEffects code

**Recommendation**: Option B - Get powers working first, then clean up. The mutation pattern works, we just need the dispatch fixed.

### 2. Test Coverage Depth

**Option A**: One integration test per power (82 tests)
- Pro: Complete coverage
- Con: Time-consuming

**Option B**: One test per targeting type + spot checks (20 tests)
- Pro: Faster, proves patterns work
- Con: Might miss edge cases

**Recommendation**: Option B for Phase B-C, then add more tests as bugs appear.

### 3. Animation Rendering

The generic animations need visual rendering code in `Game.lua`. Should we:

**Option A**: Add rendering now (complete but more code)
**Option B**: Just apply effects immediately, add rendering later

**Recommendation**: Option A - Use simple visuals (colored flash, expanding circle) so powers feel responsive.

---

## Ready to Execute?

The plan is ready. Confirm these choices and I'll begin implementation:

1. **Pure state timing**: Defer (Option B) - fix dispatch first, purify later
2. **Test coverage**: Pattern-based (Option B) - ~20 integration tests initially  
3. **Animation rendering**: Add basic visuals now (Option A)

Or would you like to adjust any of these?

---

## User

1 option b, 2 option a, 3 a

---

## Assistant

Confirmed: **B, A, A** - Defer pure state, full test coverage (82 tests), add basic visuals.

Since I'm in **plan mode**, let me finalize the detailed execution plan before implementation.

```
Tool: todowrite
```

---

## Assistant

Let me gather a few more details to complete the plan:

```
Tool: bash
```

```
Tool: bash
```

---

## Assistant

```
Tool: read
```

---

## Assistant

```
Tool: read
```

---

## Assistant

This is very helpful - there's already a `GameAnimations` module that has the **same bug** (`createPowerAnimation` and `applyPowerEffect` only handle 8 powers). This is actually the right place to fix.

Let me check how Game.lua uses this vs direct animation:

```
Tool: bash
```

---

## Assistant

So `GameAnimations` is used, but `Game.executepower()` bypasses it and creates animations directly. The fix should update `GameAnimations` to handle all powers, then `Game.executepower()` should use it.

---

# Final Execution Plan

## Summary

**Goal**: Fix 70+ broken powers by creating proper dispatch logic

**Approach**: TDD with full coverage (82 integration tests)

**Key Insight**: There are TWO places with the bug:
1. `Game.executepower()` in `src/game.lua:2081-2166`
2. `GameAnimations.createPowerAnimation()` + `applyPowerEffect()` in `src/shared/game_animations.lua:51-97`

**Strategy**: Create `PowerExecutor` module, then update both `Game.lua` and `GameAnimations` to use it.

---

## Execution Steps

### Step 1: Foundation Setup

| File | Action |
|------|--------|
| `src/shared/game_logic.lua:17-30` | Add `orbs = {}` to initial state |
| `src/shared/powers.lua` | Add `blocking = true/false` to all 82 definitions |
| `spec/game_logic_spec.lua` | Add test for `state.orbs` initialization |

### Step 2: Create PowerExecutor (TDD)

| File | Action |
|------|--------|
| `spec/power_executor_spec.lua` | Create with 82 integration tests (write first) |
| `src/shared/power_executor.lua` | Implement dispatch for all powers |

### Step 3: Add Generic Animations

| File | Action |
|------|--------|
| `src/shared/animations.lua` | Add `createPowerSelf`, `createPowerRow`, `createPowerColumn`, `createPowerRadial`, `createPowerGlobal` |
| `spec/animations_spec.lua` | Add tests for new animation types |

### Step 4: Update GameAnimations

| File | Action |
|------|--------|
| `src/shared/game_animations.lua` | Replace `createPowerAnimation()` and `applyPowerEffect()` to use PowerExecutor |
| `spec/game_animations_spec.lua` | Update tests |

### Step 5: Update Game.lua

| File | Action |
|------|--------|
| `src/game.lua` | Update `executepower()` and `getPowerTargets()` to use PowerExecutor |
| `src/game.lua` | Change `Game.orbs` → `Game.state.orbs` (~12 places) |

### Step 6: Add Animation Rendering

| File | Action |
|------|--------|
| `src/game.lua` | Add rendering for generic animation types in draw loop |

---

## Test Structure: `spec/power_executor_spec.lua`

```lua
describe("PowerExecutor", function()
    -- Setup
    local PowerExecutor, GameLogic, Powers
    
    setup(function()
        PowerExecutor = require("src.shared.power_executor")
        GameLogic = require("src.shared.game_logic")
        Powers = require("src.shared.powers")
    end)

    -- Helper to create test state with piece having specific powers
    local function createTestState(pieceConfig)
        local state = GameLogic.createInitialState()
        -- Configure piece with powers for testing
        return state, piece
    end

    -- ==========================================
    -- Self-Targeting Powers (12)
    -- ==========================================
    describe("self-targeting powers", function()
        it("double_powers doubles all powers on piece", function() ... end)
        it("grow_quadradius increases piece range", function() ... end)
        it("beneficiary marks piece for power inheritance", function() ... end)
        it("scavenger marks piece for capture inheritance", function() ... end)
        it("flat_to_sphere enables wraparound movement", function() ... end)
        it("climb_tile ignores height restrictions", function() ... end)
        it("move_diagonal enables diagonal movement", function() ... end)
        it("move_again grants extra move", function() ... end)
        it("jump_proof prevents capture", function() ... end)
        it("invisible hides piece", function() ... end)
        it("relocate teleports to random tile", function() ... end)
        it("hotspot creates or uses teleport destination", function() ... end)
    end)

    -- ==========================================
    -- Row Powers (20)
    -- ==========================================
    describe("row powers", function()
        it("destroy_row destroys pieces in row", function() ... end)
        it("kamikaze_row destroys row including self", function() ... end)
        it("recruit_row converts enemies in row", function() ... end)
        it("scramble_row shuffles positions in row", function() ... end)
        it("acidic_row destroys pieces and tiles", function() ... end)
        it("trench_row lowers terrain", function() ... end)
        it("wall_row raises terrain", function() ... end)
        it("invert_row flips heights", function() ... end)
        it("dredge_row raises friendly, lowers enemy", function() ... end)
        it("teach_row copies powers to allies", function() ... end)
        it("learn_row absorbs powers from allies", function() ... end)
        it("pilfer_row steals from enemies", function() ... end)
        it("spyware_row reveals enemy powers", function() ... end)
        it("orb_spy_row reveals orb contents", function() ... end)
        it("refurb_row repairs tiles", function() ... end)
        it("bankrupt_row creates traps", function() ... end)
        it("tripwire_row marks enemies for death on move", function() ... end)
        it("inhibit_row blocks orb collection", function() ... end)
        it("parasite_row redirects power collection", function() ... end)
        it("purify_row removes debuffs", function() ... end)
    end)

    -- ==========================================
    -- Column Powers (20) - mirror of row
    -- ==========================================
    describe("column powers", function()
        -- Same 20 tests with _column suffix
    end)

    -- ==========================================
    -- Radial Powers (21)
    -- ==========================================
    describe("radial powers", function()
        it("bomb destroys 3x3 and lowers terrain", function() ... end)
        it("destroy_radial destroys 3x3 pieces", function() ... end)
        it("kamikaze_radial destroys 3x3 including self", function() ... end)
        it("smart_bombs destroys only enemies in 3x3", function() ... end)
        it("scramble_radial shuffles 3x3 positions", function() ... end)
        it("acidic_radial destroys pieces and tiles", function() ... end)
        it("plateau raises 3x3 to max", function() ... end)
        it("moat raises center, lowers ring", function() ... end)
        it("invert_radial flips heights in 3x3", function() ... end)
        it("dredge_radial raises friendly, lowers enemy", function() ... end)
        it("teach_radial copies powers to allies", function() ... end)
        it("learn_radial absorbs from allies", function() ... end)
        it("pilfer_radial steals from enemies", function() ... end)
        it("spyware_radial reveals enemy powers", function() ... end)
        it("orb_spy_radial reveals orb contents", function() ... end)
        it("refurb_radial repairs tiles", function() ... end)
        it("bankrupt_radial creates traps", function() ... end)
        it("tripwire_radial marks for death", function() ... end)
        it("inhibit_radial blocks collection", function() ... end)
        it("parasite_radial redirects collection", function() ... end)
        it("purify_radial removes debuffs", function() ... end)
    end)

    -- ==========================================
    -- Targeted Powers (6)
    -- ==========================================
    describe("targeted powers", function()
        it("raise_tile increases target height", function() ... end)
        it("lower_tile decreases target height", function() ... end)
        it("recruit converts adjacent enemy", function() ... end)
        it("multiply clones to adjacent empty", function() ... end)
        it("refurb repairs adjacent destroyed", function() ... end)
        it("switcheroo swaps with adjacent piece", function() ... end)
    end)

    -- ==========================================
    -- Global Powers (2)
    -- ==========================================
    describe("global powers", function()
        it("orbic_rehash respawns all orbs", function() ... end)
        it("cancel_multiply destroys last multiplied", function() ... end)
    end)

    -- ==========================================
    -- Special Powers (1)
    -- ==========================================
    describe("special powers", function()
        it("centerpult jumps to 2x2 center", function() ... end)
    end)

    -- ==========================================
    -- Targeting Functions
    -- ==========================================
    describe("getTargets", function()
        it("returns adjacent targets for raise_tile", function() ... end)
        it("returns adjacent enemies for recruit", function() ... end)
        it("returns adjacent empty for multiply", function() ... end)
        it("returns adjacent destroyed for refurb", function() ... end)
        it("returns adjacent pieces for switcheroo", function() ... end)
        it("returns hotspot tiles for hotspot", function() ... end)
        it("returns 2x2 centers for centerpult", function() ... end)
    end)

    -- ==========================================
    -- Animation Info
    -- ==========================================
    describe("getAnimationInfo", function()
        it("returns blocking=false for self buffs", function() ... end)
        it("returns blocking=true for offensive powers", function() ... end)
        it("returns correct animation type per category", function() ... end)
    end)
end)
```

---

## Blocking Classification (Final)

Add to each power definition in `src/shared/powers.lua`:

```lua
-- blocking = false (non-blocking, passive)
move_diagonal, move_again, jump_proof, invisible, climb_tile,
flat_to_sphere, scavenger, beneficiary, grow_quadradius,
double_powers, spyware_*, orb_spy_*, inhibit_*, parasite_*, purify_*

-- blocking = true (blocks input during animation)
destroy_*, bomb, kamikaze_*, acidic_*, smart_bombs, scramble_*,
raise_tile, lower_tile, plateau, moat, trench_*, wall_*, invert_*, dredge_*,
recruit*, multiply, relocate, switcheroo, hotspot, centerpult,
teach_*, learn_*, pilfer_*, refurb_*, bankrupt_*, tripwire_*,
orbic_rehash, cancel_multiply
```

---

## Estimated Line Counts

| File | Lines Added/Modified |
|------|---------------------|
| `spec/power_executor_spec.lua` | ~1500 (new) |
| `src/shared/power_executor.lua` | ~400 (new) |
| `src/shared/powers.lua` | +82 (blocking field) |
| `src/shared/game_logic.lua` | +5 (orbs in state) |
| `src/shared/animations.lua` | +50 (generic animations) |
| `src/shared/game_animations.lua` | ~50 (updated dispatch) |
| `src/game.lua` | ~100 (use PowerExecutor, state.orbs) |
| **Total** | ~2200 lines |

---

## Questions Before Implementation

1. **Test file organization**: Should `power_executor_spec.lua` be one file (~1500 lines) or split by category (e.g., `spec/power_executor/self_spec.lua`, `spec/power_executor/row_spec.lua`, etc.)?

2. **Animation rendering complexity**: For the generic animations, how elaborate should the visuals be initially?
   - **Minimal**: Just colored flash at piece position
   - **Basic**: Colored flash + expanding circle for area effects
   - **Medium**: Above + directional sweep for row/column

3. **Test helper location**: Should test helpers (like `createTestState`) go in a shared `spec/helpers.lua` file or stay local to each spec?

---

## User

1 split by category, 2 medium 

---

## Assistant

Confirmed: **Split by category, medium animation complexity.**

3. **Test helper location**: Should test helpers go in a shared `spec/helpers.lua` file or stay local to each spec?

This affects code reuse across the 6+ test files we'll create.

---

## Final Implementation Plan

### File Structure

```
lua/love2d/
├── src/shared/
│   ├── power_executor.lua          # NEW: Power dispatch module (~400 lines)
│   ├── powers.lua                  # MODIFY: Add blocking field (+82 lines)
│   ├── game_logic.lua              # MODIFY: Add orbs to state (+5 lines)
│   ├── animations.lua              # MODIFY: Add generic animations (+50 lines)
│   └── game_animations.lua         # MODIFY: Use PowerExecutor (~50 lines)
├── src/
│   └── game.lua                    # MODIFY: Use PowerExecutor, state.orbs (~100 lines)
└── spec/
    ├── helpers.lua                 # NEW: Shared test utilities (~100 lines)
    └── power_executor/             # NEW: Test directory
        ├── self_spec.lua           # 12 tests (~250 lines)
        ├── row_spec.lua            # 20 tests (~400 lines)
        ├── column_spec.lua         # 20 tests (~400 lines)
        ├── radial_spec.lua         # 21 tests (~420 lines)
        ├── targeted_spec.lua       # 6 tests (~150 lines)
        ├── global_spec.lua         # 2 tests (~80 lines)
        ├── special_spec.lua        # 1 test (~50 lines)
        └── targeting_spec.lua      # 7 tests (~150 lines)
```

### Execution Order

| Phase | Step | Files | Tests First? |
|-------|------|-------|--------------|
| **A** | A1. Add orbs to state | `game_logic.lua`, `spec/game_logic_spec.lua` | Yes |
| | A2. Add blocking to powers | `powers.lua` | No (data) |
| | A3. Create test helpers | `spec/helpers.lua` | No |
| **B** | B1. Self-targeting tests | `spec/power_executor/self_spec.lua` | Yes (RED) |
| | B2. Self-targeting impl | `power_executor.lua` | GREEN |
| **C** | C1. Row tests | `spec/power_executor/row_spec.lua` | Yes (RED) |
| | C2. Row impl | `power_executor.lua` | GREEN |
| **D** | D1. Column tests | `spec/power_executor/column_spec.lua` | Yes (RED) |
| | D2. Column impl | `power_executor.lua` | GREEN |
| **E** | E1. Radial tests | `spec/power_executor/radial_spec.lua` | Yes (RED) |
| | E2. Radial impl | `power_executor.lua` | GREEN |
| **F** | F1. Targeted tests | `spec/power_executor/targeted_spec.lua` | Yes (RED) |
| | F2. Targeted impl | `power_executor.lua` | GREEN |
| **G** | G1. Global tests | `spec/power_executor/global_spec.lua` | Yes (RED) |
| | G2. Global impl | `power_executor.lua` | GREEN |
| **H** | H1. Special tests | `spec/power_executor/special_spec.lua` | Yes (RED) |
| | H2. Special impl | `power_executor.lua` | GREEN |
| **I** | I1. Targeting tests | `spec/power_executor/targeting_spec.lua` | Yes (RED) |
| | I2. Targeting impl | `power_executor.lua` | GREEN |
| **J** | J1. Generic animations | `animations.lua`, `spec/animations_spec.lua` | Yes |
| **K** | K1. Update GameAnimations | `game_animations.lua`, `spec/game_animations_spec.lua` | Yes |
| **L** | L1. Update Game.lua | `game.lua` | No (integration) |
| | L2. Add animation rendering | `game.lua` | No |
| **M** | M1. Manual testing | Run game | No |

---

### Test Helpers (`spec/helpers.lua`)

```lua
-- Shared test utilities for power executor tests
local Helpers = {}

local GameLogic = require("src.shared.game_logic")

--- Create a test state with configurable pieces
---@param config table {pieces = {{row, col, player, powers}, ...}, orbs = {...}}
---@return table state
function Helpers.createTestState(config)
    local state = GameLogic.createInitialState()
    -- Clear default pieces
    state.pieces = {}
    
    -- Add configured pieces
    for _, p in ipairs(config.pieces or {}) do
        table.insert(state.pieces, {
            row = p.row,
            col = p.col,
            player = p.player,
            powers = p.powers or {},
            -- Status flags
            canMoveDiagonally = p.canMoveDiagonally or false,
            isJumpProof = p.isJumpProof or false,
            isInvisible = p.isInvisible or false,
            -- etc.
        })
    end
    
    -- Add configured orbs
    state.orbs = config.orbs or {}
    
    return state
end

--- Get piece at position from state
---@param state table
---@param row number
---@param col number
---@return table|nil
function Helpers.getPieceAt(state, row, col)
    for _, p in ipairs(state.pieces) do
        if p.row == row and p.col == col then
            return p
        end
    end
    return nil
end

--- Count pieces by player
---@param state table
---@param player number
---@return number
function Helpers.countPieces(state, player)
    local count = 0
    for _, p in ipairs(state.pieces) do
        if p.player == player then
            count = count + 1
        end
    end
    return count
end

--- Check if piece has power
---@param piece table
---@param powerId string
---@return boolean
function Helpers.hasPower(piece, powerId)
    for _, p in ipairs(piece.powers or {}) do
        if p == powerId then
            return true
        end
    end
    return false
end

--- Count power occurrences on piece
---@param piece table
---@param powerId string
---@return number
function Helpers.countPower(piece, powerId)
    local count = 0
    for _, p in ipairs(piece.powers or {}) do
        if p == powerId then
            count = count + 1
        end
    end
    return count
end

return Helpers
```

---

### Generic Animation Details (Medium Complexity)

```lua
-- In src/shared/animations.lua

local DURATION_GENERIC = 0.5

--- Create self-targeting power animation
-- Visual: Piece glows and pulses with expanding aura ring
function Animations.createPowerSelf(row, col, onComplete)
    return Animations.createAnimation("power_self", DURATION_GENERIC, {
        row = row,
        col = col,
        -- Rendering: glow intensity 0->1->0, aura radius 0->30
    }, false, onComplete)
end

--- Create row power animation
-- Visual: Horizontal sweep line travels across row from origin
function Animations.createPowerRow(row, originCol, onComplete)
    return Animations.createAnimation("power_row", DURATION_GENERIC, {
        row = row,
        originCol = originCol,
        -- Rendering: vertical line sweeps left-to-right or right-to-left
    }, true, onComplete)
end

--- Create column power animation
-- Visual: Vertical sweep line travels down/up column from origin
function Animations.createPowerColumn(col, originRow, onComplete)
    return Animations.createAnimation("power_column", DURATION_GENERIC, {
        col = col,
        originRow = originRow,
        -- Rendering: horizontal line sweeps up-to-down or down-to-up
    }, true, onComplete)
end

--- Create radial (3x3) power animation
-- Visual: Expanding circle/ring from center, affects 3x3 area
function Animations.createPowerRadial(row, col, onComplete)
    return Animations.createAnimation("power_radial", 0.6, {
        row = row,
        col = col,
        -- Rendering: circle expands from radius 0 to cover 3x3
    }, true, onComplete)
end

--- Create global power animation
-- Visual: Screen-wide flash/pulse effect
function Animations.createPowerGlobal(onComplete)
    return Animations.createAnimation("power_global", 0.4, {
        -- Rendering: full-screen color overlay fades in/out
    }, true, onComplete)
end

--- Create swap animation (for switcheroo, scramble)
-- Visual: Two pieces spiral around each other and swap
function Animations.createPowerSwap(positions, onComplete)
    return Animations.createAnimation("power_swap", 0.6, {
        positions = positions, -- Array of {fromRow, fromCol, toRow, toCol}
        -- Rendering: pieces follow curved paths to swap positions
    }, true, onComplete)
end
```

---

### Animation Rendering in Game.lua

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

### Blocking Field Values

For `src/shared/powers.lua`, here's the complete classification:

**`blocking = false`** (12 powers):
```
move_diagonal, move_again, jump_proof, invisible, climb_tile,
flat_to_sphere, scavenger, beneficiary, grow_quadradius, double_powers,
spyware_radial, spyware_row, spyware_column,
orb_spy_radial, orb_spy_row, orb_spy_column,
inhibit_radial, inhibit_row, inhibit_column,
parasite_radial, parasite_row, parasite_column,
purify_radial, purify_row, purify_column
```

**`blocking = true`** (57 powers):
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

## Summary

**Total new tests**: 89 (82 powers + 7 targeting functions)
**Total new/modified lines**: ~2400
**Estimated time**: 4-5 hours

### Ready to Execute?

The plan is complete. Before I begin implementation, please answer the final question:

**Test helpers**: Should they go in a shared `spec/helpers.lua` or stay local to each spec file?

Once confirmed, I'll exit plan mode and begin with:
1. Create `spec/helpers.lua` (if shared)
2. Add `orbs` to state with test
3. Add `blocking` to power definitions
4. Create first failing test (`spec/power_executor/self_spec.lua`)
5. Implement `PowerExecutor` to pass tests
6. Continue through phases B-M

---

## User

they should have a similar breakdown by category so its searchable like the tests that use them

---

## Assistant

Got it! **Helpers split by category to match test files.**

---

# Final Implementation Plan (Complete)

## File Structure

```
lua/love2d/
├── src/shared/
│   ├── power_executor.lua          # NEW: Power dispatch module (~400 lines)
│   ├── powers.lua                  # MODIFY: Add blocking field (+82 lines)
│   ├── game_logic.lua              # MODIFY: Add orbs to state (+5 lines)
│   ├── animations.lua              # MODIFY: Add generic animations (+50 lines)
│   └── game_animations.lua         # MODIFY: Use PowerExecutor (~50 lines)
├── src/
│   └── game.lua                    # MODIFY: Use PowerExecutor, state.orbs (~100 lines)
└── spec/
    ├── helpers/                    # NEW: Test helpers by category
    │   ├── init.lua                # Common utilities (~50 lines)
    │   ├── state.lua               # State creation helpers (~80 lines)
    │   ├── pieces.lua              # Piece helpers (~60 lines)
    │   ├── powers.lua              # Power assertion helpers (~60 lines)
    │   ├── orbs.lua                # Orb helpers (~40 lines)
    │   └── terrain.lua             # Height/terrain helpers (~40 lines)
    └── power_executor/             # NEW: Tests by category
        ├── self_spec.lua           # 12 tests (~250 lines)
        ├── row_spec.lua            # 20 tests (~400 lines)
        ├── column_spec.lua         # 20 tests (~400 lines)
        ├── radial_spec.lua         # 21 tests (~420 lines)
        ├── targeted_spec.lua       # 6 tests (~150 lines)
        ├── global_spec.lua         # 2 tests (~80 lines)
        ├── special_spec.lua        # 1 test (~50 lines)
        └── targeting_spec.lua      # 7 tests (~150 lines)
```

---

## Test Helpers Structure

### `spec/helpers/init.lua`
Common entry point, re-exports all helpers:
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
State creation and manipulation:
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
Piece creation and queries:
```lua
-- Piece helpers
local Pieces = {}

--- Create a piece with defaults
---@param row number
---@param col number
---@param player number
---@param powers string[]|nil
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
Power assertions and queries:
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
Orb creation and queries:
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
Height and terrain queries:
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

## Example Test File Usage

### `spec/power_executor/self_spec.lua`
```lua
describe("PowerExecutor - Self-Targeting Powers", function()
    local PowerExecutor
    local H  -- Helpers

    setup(function()
        PowerExecutor = require("src.shared.power_executor")
        H = require("spec.helpers")
    end)

    describe("double_powers", function()
        it("doubles all powers on piece", function()
            -- Arrange
            local piece = H.Pieces.create(4, 5, 1, { "double_powers", "bomb", "recruit" })
            local state = H.State.create({ pieces = { piece } })

            -- Act
            state = PowerExecutor.execute(state, piece, "double_powers")

            -- Assert
            H.Powers.assertConsumed(piece, "double_powers")
            H.Powers.assertCount(piece, "bomb", 2)
            H.Powers.assertCount(piece, "recruit", 2)
            assert.are.equal(4, #piece.powers)
        end)

        it("does nothing when piece has no other powers", function()
            local piece = H.Pieces.create(4, 5, 1, { "double_powers" })
            local state = H.State.create({ pieces = { piece } })

            state = PowerExecutor.execute(state, piece, "double_powers")

            H.Powers.assertConsumed(piece, "double_powers")
            assert.are.equal(0, #piece.powers)
        end)
    end)

    describe("grow_quadradius", function()
        it("increases piece quadradius level", function()
            local piece = H.Pieces.create(4, 5, 1, { "grow_quadradius" })
            local state = H.State.create({ pieces = { piece } })

            state = PowerExecutor.execute(state, piece, "grow_quadradius")

            H.Powers.assertConsumed(piece, "grow_quadradius")
            assert.are.equal(1, piece.quadradiusLevel or 0)
        end)
    end)

    -- ... 10 more tests for remaining self-targeting powers
end)
```

### `spec/power_executor/row_spec.lua`
```lua
describe("PowerExecutor - Row Powers", function()
    local PowerExecutor
    local H

    setup(function()
        PowerExecutor = require("src.shared.power_executor")
        H = require("spec.helpers")
    end)

    describe("destroy_row", function()
        it("destroys all other pieces in row", function()
            -- Arrange: activator at (4,5), enemies at (4,2) and (4,8)
            local activator = H.Pieces.create(4, 5, 1, { "destroy_row" })
            local enemy1 = H.Pieces.create(4, 2, 2, {})
            local enemy2 = H.Pieces.create(4, 8, 2, {})
            local safe = H.Pieces.create(3, 5, 2, {})  -- Different row
            local state = H.State.create({ pieces = { activator, enemy1, enemy2, safe } })

            -- Act
            state = PowerExecutor.execute(state, activator, "destroy_row")

            -- Assert
            H.Powers.assertConsumed(activator, "destroy_row")
            assert.is_true(H.Pieces.existsAt(state, 4, 5))   -- Activator survives
            assert.is_false(H.Pieces.existsAt(state, 4, 2))  -- Enemy destroyed
            assert.is_false(H.Pieces.existsAt(state, 4, 8))  -- Enemy destroyed
            assert.is_true(H.Pieces.existsAt(state, 3, 5))   -- Safe piece survives
        end)
    end)

    describe("scramble_row", function()
        it("randomly shuffles piece positions in row", function()
            -- Arrange: 3 pieces in row 4
            local p1 = H.Pieces.create(4, 2, 1, { "scramble_row" })
            local p2 = H.Pieces.create(4, 5, 2, {})
            local p3 = H.Pieces.create(4, 8, 1, {})
            local state = H.State.create({ pieces = { p1, p2, p3 } })

            -- Capture original positions
            local originalCols = { p1.col, p2.col, p3.col }

            -- Act
            state = PowerExecutor.execute(state, p1, "scramble_row")

            -- Assert: all pieces still exist, all in row 4, but positions shuffled
            H.Powers.assertConsumed(p1, "scramble_row")
            assert.are.equal(3, #state.pieces)
            for _, p in ipairs(state.pieces) do
                assert.are.equal(4, p.row)  -- All still in row 4
            end
            -- Note: Could be same positions by chance, so we don't assert different
        end)
    end)

    -- ... 18 more tests for remaining row powers
end)
```

---

## Execution Checklist

### Phase A: Foundation
- [ ] A1. Add `orbs = {}` to `GameLogic.createInitialState()` 
- [ ] A2. Add test for `state.orbs` in `spec/game_logic_spec.lua`
- [ ] A3. Add `blocking` field to all 82 power definitions in `powers.lua`
- [ ] A4. Create `spec/helpers/` directory and all helper modules

### Phase B: Self-Targeting (12 powers)
- [ ] B1. Create `spec/power_executor/self_spec.lua` with 12 tests (RED)
- [ ] B2. Create `src/shared/power_executor.lua` skeleton
- [ ] B3. Implement dispatch for 12 self-targeting powers (GREEN)

### Phase C: Row Powers (20 powers)
- [ ] C1. Create `spec/power_executor/row_spec.lua` with 20 tests (RED)
- [ ] C2. Implement dispatch for 20 row powers (GREEN)

### Phase D: Column Powers (20 powers)
- [ ] D1. Create `spec/power_executor/column_spec.lua` with 20 tests (RED)
- [ ] D2. Implement dispatch for 20 column powers (GREEN)

### Phase E: Radial Powers (21 powers)
- [ ] E1. Create `spec/power_executor/radial_spec.lua` with 21 tests (RED)
- [ ] E2. Implement dispatch for 21 radial powers (GREEN)

### Phase F: Targeted Powers (6 powers)
- [ ] F1. Create `spec/power_executor/targeted_spec.lua` with 6 tests (RED)
- [ ] F2. Implement dispatch for 6 targeted powers (GREEN)

### Phase G: Global Powers (2 powers)
- [ ] G1. Create `spec/power_executor/global_spec.lua` with 2 tests (RED)
- [ ] G2. Implement dispatch for 2 global powers (GREEN)

### Phase H: Special Powers (1 power)
- [ ] H1. Create `spec/power_executor/special_spec.lua` with 1 test (RED)
- [ ] H2. Implement dispatch for centerpult (GREEN)

### Phase I: Targeting Functions (7 functions)
- [ ] I1. Create `spec/power_executor/targeting_spec.lua` with 7 tests (RED)
- [ ] I2. Implement `PowerExecutor.getTargets()` for all targeted powers (GREEN)

### Phase J: Generic Animations
- [ ] J1. Add tests for generic animations in `spec/animations_spec.lua`
- [ ] J2. Implement 6 generic animation factories in `animations.lua`

### Phase K: Update GameAnimations
- [ ] K1. Update `game_animations.lua` to use PowerExecutor
- [ ] K2. Update `spec/game_animations_spec.lua`

### Phase L: Game Integration
- [ ] L1. Update `Game.executepower()` to use PowerExecutor
- [ ] L2. Update `Game.getPowerTargets()` to use PowerExecutor
- [ ] L3. Change `Game.orbs` → `Game.state.orbs` (~12 places)
- [ ] L4. Add rendering for generic animation types

### Phase M: Final Verification
- [ ] M1. Run full test suite (should be 810 + 89 = 899 tests)
- [ ] M2. Manual testing: verify `double_powers` works in game
- [ ] M3. Manual testing: verify `scramble_row` works in game
- [ ] M4. Manual testing: spot check 5 other powers

---

## Summary

| Metric | Value |
|--------|-------|
| **New test files** | 8 spec files + 6 helper files |
| **New tests** | 89 |
| **New source files** | 1 (`power_executor.lua`) |
| **Modified source files** | 5 |
| **Total new/modified lines** | ~2500 |
| **Expected final test count** | 899 |

---

## Ready to Execute

Plan is complete. All clarifications resolved:

1. ✅ Orbs in state (server-ready)
2. ✅ Defer pure state conversion
3. ✅ Blocking in power definition
4. ✅ Split tests by category
5. ✅ Full test coverage (82 powers + 7 targeting)
6. ✅ Medium animation complexity
7. ✅ Helpers split by category matching tests

**Say "execute" or "go" when ready to begin implementation.**

---

## User

is the plan documented as a phase? in docs?

---

## Assistant

Good catch! The plan is **not yet documented** in the project's docs folder. Let me check the existing documentation structure:

```
Tool: bash
```

```
Tool: bash
```

---

## Assistant

```
Tool: bash
```

```
Tool: read
```

---

## Assistant

```
Tool: read
```

```
Tool: read
```

---

## Assistant

Now I understand the documentation structure. The plan should be documented as a **new phase** since this is a significant bug fix that affects the architecture. Let me check what the naming convention should be:

```
Tool: read
```

---

## Assistant

I see `roadmap_progress.md` is outdated (shows Phase 8A as current when we're actually past Phase 9). The plan should be documented as **Phase 9.5** or **Phase 9-fix** since it's fixing a critical bug discovered after Phase 9 completion.

---

## Documentation Plan

The implementation plan should be documented as:

### New File: `docs/phases/phase9_fix_power_integration.md`

This follows the existing pattern in `docs/phases/` and will document:

1. **Problem Statement**: 70+ powers have `PowerEffects.activate*()` but aren't wired to `Game.executepower()`
2. **Root Cause**: Missing dispatch in `Game.executepower()` and `GameAnimations`
3. **Solution**: Create `PowerExecutor` module
4. **Architectural Changes**: orbs in state, blocking in power definition
5. **Implementation Phases A-M** (as outlined above)
6. **Test Plan**: 89 new integration tests
7. **File Changes**: Summary of all files created/modified

### Update: `docs/roadmap.md`

Add a new section between Phase 9 and Phase 10:

```markdown
### Phase 9-Fix: Power Integration ⏳ IN PROGRESS
Fix critical bug where 70+ powers show animations but don't execute game logic.

- **89 new tests**
- PowerExecutor module for centralized dispatch
- Orbs moved into game state (server-ready)
- Blocking field added to power definitions
- Generic animations for all power categories

[Details](phases/phase9_fix_power_integration.md)
```

### Update: `docs/roadmap_progress.md`

Update to reflect current state and new phase.

---

## Questions

1. **Naming**: Should it be:
   - `phase9_fix_power_integration.md` (indicates bug fix)
   - `phase9b_power_integration.md` (sub-phase of 9)
   - `phase9.5_power_executor.md` (between 9 and 10)
   
2. **Detail level**: Should the phase doc include:
   - Just the plan summary (like `phase6_overheat.md` ~100 lines)
   - Full implementation details (like `phase9_powers.md` ~140 lines)
   - Everything from this conversation (would be ~500+ lines)

3. **Checklist format**: Should it include the execution checklist (A1-M4) for tracking progress during implementation?

---

## User

1 sub phase of 9, 2 everything and details from this conversation 3 yes this was handled in a corresponding phase_progress.md  so we should follow that for this phase

---

## Assistant

Got it! **Sub-phase of 9, full details, with progress tracking doc.**

Let me check the existing progress doc pattern:

```
Tool: read
```

---

## Assistant

```
Tool: read
```

---

## Assistant

```
Tool: read
```

---

## Assistant

Excellent! Now I have the complete pattern. The progress file includes:
1. Current phase indicator
2. Overall progress checklist  
3. Detailed per-phase tests and implementation checklists
4. Session log with TDD cycles documented

---

# Documentation Files to Create

Based on the pattern, I need to create two files:

## 1. `docs/phases/phase9b_power_integration.md` (~500 lines)

Full phase specification with:
- Problem statement and root cause
- Solution overview
- Architectural changes (orbs in state, blocking in definitions)
- File structure (new files, modified files)
- Test structure (helpers + 8 spec files)
- Implementation phases A-M
- Blocking classification (all 82 powers)
- Animation specifications
- Animation rendering code snippets

## 2. `docs/phases/phase9b_power_integration_progress.md` (~200 lines)

Progress tracking with:
- Current phase indicator
- Overall progress checklist (A1-M4)
- Per-phase test/implementation checklists
- Session log (to be filled during implementation)

## 3. Update `docs/roadmap.md`

Add Phase 9B between Phase 9 and Phase 10.

## 4. Update `docs/roadmap_progress.md`

Update to reflect current state (Phase 9 complete, 9B in progress).

---

# Final Documentation Plan Summary

| File | Action | Lines |
|------|--------|-------|
| `docs/phases/phase9b_power_integration.md` | CREATE | ~500 |
| `docs/phases/phase9b_power_integration_progress.md` | CREATE | ~200 |
| `docs/roadmap.md` | UPDATE | +15 |
| `docs/roadmap_progress.md` | UPDATE | +20 |

---

## Plan Complete

The full implementation plan is now ready, including:

### Implementation Files
- `src/shared/power_executor.lua` (new)
- `src/shared/powers.lua` (add blocking)
- `src/shared/game_logic.lua` (add orbs)
- `src/shared/animations.lua` (add generic animations)
- `src/shared/game_animations.lua` (use PowerExecutor)
- `src/game.lua` (use PowerExecutor, state.orbs, render animations)

### Test Files  
- `spec/helpers/init.lua`, `state.lua`, `pieces.lua`, `powers.lua`, `orbs.lua`, `terrain.lua`
- `spec/power_executor/self_spec.lua`, `row_spec.lua`, `column_spec.lua`, `radial_spec.lua`, `targeted_spec.lua`, `global_spec.lua`, `special_spec.lua`, `targeting_spec.lua`

### Documentation Files
- `docs/phases/phase9b_power_integration.md`
- `docs/phases/phase9b_power_integration_progress.md`
- Update `docs/roadmap.md`
- Update `docs/roadmap_progress.md`

---

**Ready to execute when you say "go".**

Implementation will begin with:
1. Create documentation files first (phase9b_power_integration.md, progress.md)
2. Update roadmap files
3. Then begin Phase A: Foundation (orbs in state, blocking field, helpers)
4. Continue TDD through phases B-M

---

## User

go

---

## Assistant

Starting Phase 9B implementation. First, I'll create the documentation files, then begin the TDD implementation.

```
Tool: todowrite
```

---

## Assistant

```
Tool: write
```

---

## Assistant

Now let me create the progress tracker document:

```
Tool: write
```

---

## Assistant

```
Tool: todowrite
```

---

## Assistant

Now let me update the roadmap files:

```
Tool: edit
```

---

## User

---

## Assistant

# Session Summary: Phase 9B Power Integration Fix

## What We Did

### 1. Identified Critical Bug
User reported that powers like `double_powers` (2x) and `scramble_row` show animations but don't actually work.

**Root Cause**: `Game.executepower()` in `src/game.lua:2081-2166` only has handlers for **12 of 82 powers**. The 70+ Phase 9 powers have `PowerEffects.activate*()` functions that are **never called**.

### 2. Created Comprehensive Implementation Plan
Designed solution with architectural improvements for server-readiness:
- **Orbs in state**: Move `Game.orbs` → `Game.state.orbs`
- **Blocking in definition**: Add `blocking = true/false` to each power
- **PowerExecutor module**: Centralized dispatch for all 82 powers
- **89 integration tests**: One per power + targeting functions

### 3. Created Documentation
- ✅ `docs/phases/phase9b_power_integration.md` (~500 lines) - Full phase specification
- ✅ `docs/phases/phase9b_power_integration_progress.md` (~200 lines) - Progress tracker
- ✅ Updated `docs/roadmap.md` - Added Phase 9B section

---

## Current State

| Item | Status |
|------|--------|
| Tests | 810 passing |
| Documentation | Created |
| Implementation | Not started |

---

## Files Created This Session

```
docs/phases/phase9b_power_integration.md        # Full spec
docs/phases/phase9b_power_integration_progress.md  # Progress tracker
```

---

## Next Steps (Phase A: Foundation)

1. **A1**: Add `orbs = {}` to `GameLogic.createInitialState()` in `src/shared/game_logic.lua`
2. **A2**: Add test for `state.orbs` in `spec/game_logic_spec.lua`
3. **A3**: Add `blocking` field to all 82 power definitions in `src/shared/powers.lua`
4. **A4-A9**: Create test helpers in `spec/helpers/*.lua`

Then continue with Phase B (self-targeting powers tests/implementation).

---

## Prompt for Next Session

```
# Continue NNQR Love2D - Phase 9B Power Integration Fix

## Context
Building Love2D port of Quadradius. Found critical bug where 70+ powers 
show animations but don't execute game logic. Created full implementation
plan and documentation.

## The Bug
`Game.executepower()` in `src/game.lua:2081-2166` only handles 12 powers.
The 70 Phase 9 powers have `PowerEffects.activate*()` functions that 
are never called from the UI.

## Branch
`feature/love2d-isometric`

## Current Stats  
- 810 tests passing
- 82 powers defined
- Only 12 powers actually work in-game

## Documentation Created
- `docs/phases/phase9b_power_integration.md` - Full spec (~500 lines)
- `docs/phases/phase9b_power_integration_progress.md` - Progress tracker

## Key Decisions
1. Orbs in state (`state.orbs`) for server-ready architecture
2. `blocking` field in power definitions (true=blocks input, false=passive)
3. Full test coverage: 89 integration tests (one per power)
4. Medium animation complexity (sweep lines, expanding rings)
5. Tests split by category in `spec/power_executor/*.lua`
6. Helpers split by category in `spec/helpers/*.lua`

## Implementation Phases
- **A**: Foundation (orbs in state, blocking field, helpers) ← START HERE
- **B**: Self-targeting powers (12 tests)
- **C**: Row powers (20 tests)
- **D**: Column powers (20 tests)
- **E**: Radial powers (21 tests)
- **F**: Targeted powers (6 tests)
- **G**: Global powers (2 tests)
- **H**: Special powers (1 test)
- **I**: Targeting functions (7 tests)
- **J**: Generic animations
- **K**: Update GameAnimations
- **L**: Game integration
- **M**: Final verification

## Files to Create
```
src/shared/power_executor.lua       # Power dispatch module
spec/helpers/init.lua               # Helper index
spec/helpers/state.lua              # State creation
spec/helpers/pieces.lua             # Piece helpers
spec/helpers/powers.lua             # Power assertions
spec/helpers/orbs.lua               # Orb helpers
spec/helpers/terrain.lua            # Terrain helpers
spec/power_executor/self_spec.lua   # 12 tests
spec/power_executor/row_spec.lua    # 20 tests
spec/power_executor/column_spec.lua # 20 tests
spec/power_executor/radial_spec.lua # 21 tests
spec/power_executor/targeted_spec.lua # 6 tests
spec/power_executor/global_spec.lua # 2 tests
spec/power_executor/special_spec.lua # 1 test
spec/power_executor/targeting_spec.lua # 7 tests
```

## Files to Modify
```
src/shared/game_logic.lua    # Add orbs = {} to state
src/shared/powers.lua        # Add blocking field to 82 definitions
src/shared/animations.lua    # Add generic animations
src/shared/game_animations.lua # Use PowerExecutor
src/game.lua                 # Use PowerExecutor, state.orbs
```

## Commands
```bash
cd /Users/vinnie/github/nnqr/lua/love2d
~/.luarocks/bin/busted spec/           # Run tests
mise run love-fmt                       # Format code
mise run love-start                     # Run game
```

## TDD Approach
Always write failing test first, then implement to make it pass.

## Next Action
Begin Phase A: Foundation
1. Read current `src/shared/game_logic.lua` to see state structure
2. Add test for `state.orbs` initialization
3. Add `orbs = {}` to `createInitialState()`
4. Run tests to verify
5. Add `blocking` field to power definitions
6. Create helper modules
```

---

## User

---

## Assistant

I'll continue with Phase 9B Power Integration Fix. Let me first check the current state and then begin Phase A: Foundation.

```
Tool: read
```

```
Tool: read
```

---

## Assistant

Now let me create a todo list and start implementing Phase A. I'll begin by adding the test for `state.orbs` first (TDD approach), then implement the fix.

```
Tool: todowrite
```

```
Tool: read
```

---

## Assistant

Now I'll add the test for `state.orbs` initialization (RED first), then implement it (GREEN). Let me add the test to the "board initialization" describe block:

```
Tool: edit
```

---

## Assistant

Let me check if the edit was applied anyway and run the test:

```
Tool: bash
```

---

## Assistant

Test fails (RED) as expected. Now let's make it pass (GREEN) by adding `orbs = {}` to `createInitialState()`:

```
Tool: edit
```

---

## Assistant

```
Tool: bash
```

---

## Assistant

Test passes (GREEN). Now let me update the todo list and move to A3 (adding blocking field to power definitions). First, let me read the powers file:

```
Tool: todowrite
```

```
Tool: read
```

---

## Assistant

This is a large file with 82 power definitions. Looking at the phase spec, I need to add `blocking = true/false` to each power. Let me check the phase9b documentation to see the blocking categorization:

```
Tool: read
```

---

## Assistant

Now I have the blocking classification. Let me create a script to add the `blocking` field to all powers. Based on the documentation:
- **25 non-blocking powers** (passive/permanent effects)
- **57 blocking powers** (offensive/terrain/position changes)

```
Tool: edit
```

---

## Assistant

```
Tool: edit
```

---

## Assistant

```
Tool: edit
```

---

## Assistant

```
Tool: edit
```

---

## Assistant

```
Tool: edit
```

---

## Assistant

```
Tool: edit
```

---

## Assistant

```
Tool: edit
```

---

## Assistant

```
Tool: edit
```

---

## Assistant

```
Tool: edit
```

---

## Assistant

```
Tool: edit
```

---

## Assistant

```
Tool: edit
```

---

## Assistant

```
Tool: edit
```

---

## Assistant

```
Tool: edit
```

---

## Assistant

```
Tool: edit
```

---

## Assistant

```
Tool: edit
```

---

## Assistant

```
Tool: edit
```

---

## Assistant

```
Tool: edit
```

---

## Assistant

```
Tool: edit
```

---

## Assistant

```
Tool: edit
```

---

## Assistant

```
Tool: edit
```

---

## Assistant

```
Tool: edit
```

---

## Assistant

```
Tool: edit
```

---

## Assistant

```
Tool: edit
```

---

## Assistant

```
Tool: edit
```

---

## Assistant

```
Tool: edit
```

---

## Assistant

```
Tool: edit
```

---

## Assistant

```
Tool: edit
```

---

## Assistant

```
Tool: edit
```

---

## Assistant

```
Tool: edit
```

---

## Assistant

```
Tool: edit
```

---

## Assistant

Now let's verify the changes and run the tests:

```
Tool: bash
```

---

## Assistant

All 811 tests pass. Let me verify that all 82 powers have the `blocking` field by counting them:

```
Tool: bash
```

---

## Assistant

All 82 powers have the `blocking` field. Now let's update the todo list and create the test helpers.

```
Tool: todowrite
```

---

## Assistant

```
Tool: list
```

---

## Assistant

Now I'll create the helpers directory and the helper modules. Let me create them all:

```
Tool: bash
```

---

## Assistant

```
Tool: write
```

---

## Assistant

Now let me create the remaining helper modules. I'll create all of them:

```
Tool: write
```

```
Tool: write
```

```
Tool: write
```

```
Tool: write
```

```
Tool: write
```

---

## Assistant

---

