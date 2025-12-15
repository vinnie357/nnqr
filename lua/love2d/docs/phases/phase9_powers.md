# Phase 9: More Powers

## Overview

Implement the remaining 75 powers to reach full 87-power parity with original Quadradius.

**Estimated Sessions**: 6-8
**New Tests**: ~235

## Current State

**Implemented (12 powers)**:
- Movement: Move Diagonal, Move Again, Relocate
- Offensive: Destroy Row, Destroy Column, Bomb
- Defensive: Jump Proof
- Terrain: Raise Tile, Lower Tile
- Strategic: Recruit, Multiply
- Utility: Invisible

**Remaining (75 powers)** organized by implementation complexity.

---

## Phase 9A: Simple Powers (~2 sessions, ~60 tests)

Powers with straightforward effects similar to existing ones.

### 9A.1 Destroy Variants

| Power | Effect | Similar To |
|-------|--------|------------|
| Destroy Radial | Destroy 8 surrounding | Bomb (without terrain) |
| Kamikaze Radial | Destroy 8 surrounding + self | Bomb + self-destruct |
| Kamikaze Row | Destroy row + self | Destroy Row + self-destruct |
| Kamikaze Column | Destroy column + self | Destroy Column + self-destruct |

### 9A.2 Acidic Powers (Requires Phase 7)

| Power | Effect |
|-------|--------|
| Acidic Radial | Destroy 8 surrounding + destroy tiles |
| Acidic Row | Destroy row + destroy tiles |
| Acidic Column | Destroy column + destroy tiles |

### 9A.3 Extended Recruitment

| Power | Effect |
|-------|--------|
| Recruit Row | Convert all enemies in row |
| Recruit Column | Convert all enemies in column |

### 9A.4 Scramble Powers

| Power | Effect |
|-------|--------|
| Scramble Radial | Random swap positions in 3x3 |
| Scramble Row | Random swap all in row |
| Scramble Column | Random swap all in column |

### 9A.5 Smart Bombs

| Power | Effect |
|-------|--------|
| Smart Bombs | Destroy 8 surrounding, skip friendly |

---

## Phase 9B: Terrain Powers (~1-2 sessions, ~45 tests)

Complex terrain manipulation.

### 9B.1 Area Effects

| Power | Effect |
|-------|--------|
| Plateau | Raise 3x3 area to max height |
| Moat | Raise center, lower surrounding ring |
| Climb Tile | Piece ignores height restrictions (permanent flag) |

### 9B.2 Line Effects

| Power | Effect |
|-------|--------|
| Trench Row | Lower entire row by 2 |
| Trench Column | Lower entire column by 2 |
| Wall Row | Raise entire row by 2 |
| Wall Column | Raise entire column by 2 |

### 9B.3 Invert Powers

| Power | Effect |
|-------|--------|
| Invert Radial | Flip heights in 3x3 (4 becomes 0, etc.) |
| Invert Row | Flip heights in row |
| Invert Column | Flip heights in column |

### 9B.4 Dredge Powers

| Power | Effect |
|-------|--------|
| Dredge Radial | Raise friendly tiles, lower enemy tiles in 3x3 |
| Dredge Row | Raise friendly, lower enemy in row |
| Dredge Column | Raise friendly, lower enemy in column |

---

## Phase 9C: Power Transfer Powers (~1-2 sessions, ~40 tests)

Powers that affect other powers.

### 9C.1 Teach (Share to allies)

| Power | Target | Effect |
|-------|--------|--------|
| Teach Radial | Adjacent allies | Copy all powers to allies |
| Teach Row | Row allies | Copy all powers to allies |
| Teach Column | Column allies | Copy all powers to allies |

### 9C.2 Learn (Absorb from allies)

| Power | Target | Effect |
|-------|--------|--------|
| Learn Radial | Adjacent allies | Take all powers from allies |
| Learn Row | Row allies | Take all powers from allies |
| Learn Column | Column allies | Take all powers from allies |

### 9C.3 Pilfer (Steal from enemies)

| Power | Target | Effect |
|-------|--------|--------|
| Pilfer Radial | Adjacent enemies | Steal random power from each |
| Pilfer Row | Row enemies | Steal random power from each |
| Pilfer Column | Column enemies | Steal random power from each |

### 9C.4 Parasite (Ongoing leech)

| Power | Target | Effect |
|-------|--------|--------|
| Parasite Radial | Adjacent enemies | Leech future powers |
| Parasite Row | Row enemies | Leech future powers |
| Parasite Column | Column enemies | Leech future powers |

**Note**: Parasite requires persistent effect tracking.

---

## Phase 9D: Meta Powers (~1 session, ~30 tests)

Powers that modify the power system itself.

| Power | Effect |
|-------|--------|
| Grow Quadradius | Extend power range by 1 (stacks 3x) |
| 2x | Double all powers on piece |
| Beneficiary | All squadron powers transfer to this piece |
| Orbic Rehash | Respawn all orbs at new random locations |
| Cancel Multiply | Destroy the most recently multiplied piece |

**Grow Quadradius Implementation**:
- Add `growQuadradiusLevel` (0-3) to piece
- Range powers check this level
- Level 3 = row/column becomes 2 rows/columns

---

## Phase 9E: Movement & Control Powers (~1-2 sessions, ~60 tests)

### 9E.1 Special Movement

| Power | Effect |
|-------|--------|
| Flat To Sphere | Wraparound movement (permanent flag) |
| Hotspot | Create teleport destination tile |
| Switcheroo | Swap positions with ally or enemy |
| Centerpult | Jump to center of 4-piece square formation |
| Scavenger | Inherit powers from captured enemies |

### 9E.2 Trap Powers

| Power | Effect |
|-------|--------|
| Tripwire Radial | Adjacent enemies die if they move |
| Tripwire Row | Row enemies die if they move |
| Tripwire Column | Column enemies die if they move |

### 9E.3 Inhibit Powers

| Power | Effect |
|-------|--------|
| Inhibit Radial | Adjacent enemies can't collect powers |
| Inhibit Row | Row enemies can't collect powers |
| Inhibit Column | Column enemies can't collect powers |

### 9E.4 Bankrupt Powers

| Power | Effect |
|-------|--------|
| Bankrupt Radial | Create power-draining trap tiles in 3x3 |
| Bankrupt Row | Create power-draining trap in row |
| Bankrupt Column | Create power-draining trap in column |

### 9E.5 Intelligence Powers

| Power | Effect |
|-------|--------|
| Spyware Radial | Reveal adjacent enemy powers |
| Spyware Row | Reveal row enemy powers |
| Spyware Column | Reveal column enemy powers |
| Orb Spy Radial | Reveal adjacent orb contents |
| Orb Spy Row | Reveal row orb contents |
| Orb Spy Column | Reveal column orb contents |

### 9E.6 Restoration Powers

| Power | Effect |
|-------|--------|
| Purify Radial | Remove debuffs from adjacent allies |
| Purify Row | Remove debuffs from row allies |
| Purify Column | Remove debuffs from column allies |
| Refurb Radial | Repair adjacent destroyed tiles |
| Refurb Row | Repair row destroyed tiles |
| Refurb Column | Repair column destroyed tiles |

---

## Implementation Pattern

For each power:

1. **Define** in `powers.lua`:
```lua
Powers.DEFINITIONS.power_id = {
    name = "Power Name",
    description = "...",
    category = "offensive",
    duration = "single_use",
    targeting = "radial", -- or "row", "column", "self", "adjacent"
}
```

2. **Test targets** in `spec/power_effects_spec.lua`:
```lua
it("returns correct targets for power_id", function()
    local targets = PowerEffects.getPowerTargets(state, piece, "power_id")
    assert.are.equal(expectedCount, #targets)
end)
```

3. **Test activation** in `spec/power_effects_spec.lua`:
```lua
it("applies power_id effect correctly", function()
    PowerEffects.activatePower(state, piece, "power_id", target)
    -- Assert expected state changes
end)
```

4. **Implement** in `power_effects.lua`:
```lua
function PowerEffects.getPowerTargets(state, piece, powerId)
    -- Target selection logic
end

function PowerEffects.activatePower(state, piece, powerId, target)
    -- Effect application
end
```

---

## Test Count Summary

| Phase | Powers | Tests |
|-------|--------|-------|
| 9A: Simple | 20 | ~60 |
| 9B: Terrain | 15 | ~45 |
| 9C: Transfer | 12 | ~40 |
| 9D: Meta | 8 | ~30 |
| 9E: Movement | 20 | ~60 |
| **Total** | **75** | **~235** |

Current total: ~582
**New total**: **~817**

---

## Execution Order

Powers should be implemented in dependency order:

1. **9A.1-9A.4**: Simple destroy/recruit/scramble (no dependencies)
2. **9A.2**: Acidic powers (requires Phase 7 destroyed tiles)
3. **9B**: Terrain powers (no dependencies)
4. **9C.1-9C.3**: Teach/Learn/Pilfer (no dependencies)
5. **9D**: Meta powers (some require power tracking)
6. **9E.1-9E.2**: Movement/Trap powers
7. **9C.4, 9E.3-9E.4**: Persistent effect powers (Parasite, Tripwire, Inhibit, Bankrupt)
8. **9E.5-9E.6**: Intelligence/Restoration powers

---

## Files to Modify

| File | Changes |
|------|---------|
| `src/shared/powers.lua` | Add 75 power definitions |
| `src/shared/power_effects.lua` | Add 75 power effects |
| `spec/powers_spec.lua` | Power definition tests |
| `spec/power_effects_spec.lua` | Power effect tests |
| `src/shared/game_logic.lua` | Persistent effect tracking |
| `src/game.lua` | UI for new powers |

---

## Reference

Full power descriptions available in:
- `research/quadradius/game_details/powers.md`
