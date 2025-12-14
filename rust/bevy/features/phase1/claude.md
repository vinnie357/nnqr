# Phase 1: Foundation & Power Integration Fixes - Context for Claude

## Phase Overview
**Status**: Core Foundation ✅ COMPLETE | Power Integration 🔧 IN PROGRESS  
**Current State**: 12-15 powers functional out of 71 defined  
**Critical Issue**: Most powers activate but don't affect gameplay mechanics

## Research Documents & Context

### Primary Research References
1. **Game Mechanics**: `/research/game.md`
   - Lines 11-12: Board specification - "10×8 grid (10 columns by 8 rows)"
   - Lines 14-16: Movement mechanics - "one space orthogonally"
   - Lines 17-23: Terrain height system - "move down any levels, up one level"
   - Lines 24-29: Turn structure and power activation phases

2. **Technical Implementation**: `/research/isometric_design_patterns_bevy.md`
   - Lines 15-85: Isometric camera setup and configuration
   - Lines 86-145: Coordinate systems and transformations
   - Lines 234-310: Mouse input and tile selection
   - Lines 311-415: Depth sorting and rendering order

3. **Project Requirements**: `/instructions/nnqr_prd.md`
   - Lines 18-19: Updated board structure (10x8)
   - Lines 95-115: Power-up system technical architecture
   - Lines 306-310: Power interaction challenges
   - Lines 298-311: Performance requirements

4. **Current Status**: `/instructions/implementation_status.md`
   - Complete analysis of current implementation gaps
   - Power implementation status breakdown
   - Critical technical tasks identified

## Key Architecture Files

### Power System Core
- `/quadradius/src/components/power.rs` - All 71 power definitions
- `/quadradius/src/systems/power_effects.rs` - Power activation logic (1500+ lines)
- `/quadradius/src/systems/movement_powers.rs` - Movement power implementations
- `/quadradius/src/systems/power_orbs.rs` - Orb spawning and collection

### Game Systems
- `/quadradius/src/systems/drag_drop.rs` - Movement validation logic
- `/quadradius/src/systems/terrain_height.rs` - Terrain system (not integrated)
- `/quadradius/src/systems/turn_management.rs` - Turn phases and state
- `/quadradius/src/components/board.rs` - Board and tile components

### Testing
- `/quadradius/src/tests/missing_powers_tests.rs` - Tests for unimplemented powers
- `/quadradius/src/tests/power_orb_tests.rs` - Power system tests

## Critical Integration Points

### 1. Movement Validation Integration
**Problem**: Movement powers activate but don't modify movement rules  
**Solution**: Add power state checking to movement validation in `drag_drop.rs`  
**Example**: MoveDiagonal works - use as reference implementation

### 2. Terrain System Integration  
**Problem**: Board manipulation powers don't connect to terrain height  
**Solution**: Create event system between power activation and terrain modification  
**Example**: DestroyColumn works - use similar pattern for height changes

### 3. Duration Effect Processing
**Problem**: Components exist but no turn-based updates  
**Solution**: Add effect duration system to turn management  
**Components**: Frozen, Poisoned, Shield, Invisible already defined

## Phase 1 Success Criteria

1. **Movement Powers Work**: Pieces can move differently when powers are active
2. **Terrain Powers Work**: Board heights change and affect movement
3. **Duration Effects Work**: Effects expire after correct number of turns
4. **Tests Pass**: More tests in `missing_powers_tests.rs` pass
5. **No Regressions**: Existing functionality still works

## Common Patterns to Follow

### Working Power Example (MoveDiagonal)
```rust
// In power_effects.rs
PowerType::MoveDiagonal => {
    // Adds component that movement validation checks
    commands.entity(piece_entity).insert(CanMoveDiagonally);
}

// In movement validation
if piece.has::<CanMoveDiagonally>() {
    // Allow diagonal moves
}
```

### Event Pattern (from DestroyColumn)
```rust
// Send event
column_destroy_events.send(DestroyColumnEvent { column: x });

// Handle in system
for event in column_destroy_events.read() {
    // Process destruction
}
```

## Development Approach

1. **Use TDD**: Tests exist for missing powers - make them pass
2. **Small Changes**: Connect existing systems, don't build new ones
3. **Reference Working Powers**: MoveDiagonal, DestroyColumn, Multiply
4. **Test Frequently**: Run `cargo test` after each change
5. **Visual Verification**: Always test in-game after implementation

## Phase 1 Completion
Phase 1 is complete when:
- All movement powers change how pieces can move
- All terrain powers modify board heights
- All duration effects process correctly each turn
- Integration tests pass
- Documentation is updated with implementation status