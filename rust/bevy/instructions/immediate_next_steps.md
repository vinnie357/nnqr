# Immediate Next Steps for Quadradius Power Implementation

**Generated**: January 2025  
**Current State**: 12-15 powers functional out of 71 defined  
**Critical Gap**: Most powers activate but don't affect gameplay

## 🚨 CRITICAL PRIORITY: Fix Broken Power Implementations

### Prerequisites Check
Before starting, verify these files exist:
- `/src/systems/power_effects.rs` - Main power activation logic
- `/src/components/power.rs` - Power definitions
- `/src/systems/movement_powers.rs` - Movement power implementations
- `/src/tests/missing_powers_tests.rs` - Tests for unimplemented powers

### Task 0: Analyze Current Power System (30 minutes)
**Goal**: Understand why powers activate but don't affect gameplay

1. **Run power activation tests**:
   ```bash
   cd /Users/vinnie/github/nnqr/quadradius
   cargo test test_power_activation -- --nocapture
   ```

2. **Check movement validation integration**:
   - Look for `MoveDiagonal` implementation in `power_effects.rs`
   - Find where movement validation happens in `drag_drop.rs`
   - Identify the disconnect between power activation and movement rules

3. **Document findings**:
   - Which powers have complete implementations
   - Which powers only print messages
   - Where movement validation needs power integration

## 🔧 Task 1: Fix Movement Power Integration (4-6 hours)

### Problem
Movement powers (Teleport, Jump, MoveTwo, Knight, etc.) activate but don't modify the movement validation system.

### Step 1.1: Integrate Power Effects with Movement Validation
**File**: `src/systems/drag_drop.rs` or `src/systems/movement_validation.rs`

1. **Find the movement validation function**:
   ```rust
   // Look for something like:
   fn is_valid_move(from: Position, to: Position, piece: &Piece) -> bool
   ```

2. **Add power state checking**:
   ```rust
   // Add component query for active powers
   fn is_valid_move(
       from: Position, 
       to: Position, 
       piece: &Piece,
       active_powers: &ActivePowers, // NEW
   ) -> bool {
       // Check for movement-modifying powers
       if active_powers.has(PowerType::MoveDiagonal) {
           // Allow diagonal movement
       }
       if active_powers.has(PowerType::Knight) {
           // Allow L-shaped movement
       }
       // ... etc
   }
   ```

### Step 1.2: Implement Specific Movement Powers

#### Fix MoveTwice Power
**Current**: Only prints "Move Twice power activated!"  
**File**: `src/systems/power_effects.rs`

```rust
// CURRENT (broken):
PowerType::MoveTwice => {
    println!("Move Twice power activated!");
}

// IMPLEMENT:
PowerType::MoveTwice => {
    // Add component to track remaining moves
    commands.entity(piece_entity).insert(RemainingMoves(2));
    
    // Update turn management to check for RemainingMoves
    // Don't end turn if RemainingMoves > 1
}
```

#### Fix Teleport Power
**Current**: Activates but doesn't change movement  
**Implementation needed**:
```rust
PowerType::Teleport => {
    // Add component to allow next move to any empty tile
    commands.entity(piece_entity).insert(TeleportActive);
    
    // In movement validation:
    // if piece.has(TeleportActive) && target.is_empty() { return true; }
}
```

#### Fix Jump Power
```rust
PowerType::Jump => {
    // Allow jumping over pieces
    commands.entity(piece_entity).insert(CanJump);
    
    // In movement validation:
    // Check if straight line path has pieces to jump over
}
```

### Step 1.3: Test Each Implementation
For each power fixed:
1. Run specific test: `cargo test test_[power_name]_power`
2. Manual test in game
3. Verify no side effects

## 🔧 Task 2: Fix Terrain Integration (4-6 hours)

### Problem
Board manipulation powers (RaiseColumn, LowerColumn, RaiseArea, etc.) activate but don't modify terrain.

### Step 2.1: Connect Terrain System
**File**: `src/systems/terrain_height.rs`

1. **Find terrain height component**:
   ```rust
   #[derive(Component)]
   struct TerrainHeight(i8); // or similar
   ```

2. **Create terrain modification system**:
   ```rust
   pub fn apply_terrain_power(
       power: PowerType,
       target: BoardPosition,
       mut terrain_query: Query<&mut TerrainHeight>,
   ) {
       match power {
           PowerType::RaiseColumn => {
               // Raise all tiles in column by 1
               for y in 0..BOARD_HEIGHT {
                   if let Ok(mut height) = terrain_query.get_mut(tile_at(target.x, y)) {
                       height.0 = (height.0 + 1).min(MAX_HEIGHT);
                   }
               }
           }
           PowerType::LowerColumn => {
               // Lower all tiles in column by 1
               // Similar implementation
           }
           // ... etc
       }
   }
   ```

### Step 2.2: Update Power Effects
**File**: `src/systems/power_effects.rs`

```rust
// Find terrain manipulation powers
PowerType::RaiseColumn => {
    // CURRENT: Just visual effect or print
    // ADD: Call terrain modification system
    terrain_events.send(ModifyTerrainEvent {
        power_type: PowerType::RaiseColumn,
        target: selected_position,
    });
}
```

### Step 2.3: Update Visual Representation
- Ensure terrain height changes update the visual mesh/sprite
- Update color coding for height levels
- Test height restrictions on movement still work

## 🔧 Task 3: Implement Duration-Based Effects (3-4 hours)

### Problem
Components exist for Frozen, Poisoned, Shield, Invisible but no turn-based processing.

### Step 3.1: Create Effect Processing System
**New file**: `src/systems/effect_duration.rs`

```rust
use bevy::prelude::*;

#[derive(Component)]
pub struct DurationEffect {
    pub effect_type: EffectType,
    pub turns_remaining: u32,
}

pub fn process_duration_effects(
    mut commands: Commands,
    mut effect_query: Query<(Entity, &mut DurationEffect)>,
    turn_state: Res<TurnState>,
) {
    // Only process at turn end
    if !turn_state.is_changed() || !turn_state.turn_ending {
        return;
    }
    
    for (entity, mut effect) in effect_query.iter_mut() {
        effect.turns_remaining -= 1;
        
        if effect.turns_remaining == 0 {
            // Remove effect
            match effect.effect_type {
                EffectType::Frozen => commands.entity(entity).remove::<Frozen>(),
                EffectType::Poisoned => {
                    // Destroy piece
                    commands.entity(entity).despawn_recursive();
                }
                EffectType::Invisible => commands.entity(entity).remove::<Invisible>(),
                // ... etc
            }
            commands.entity(entity).remove::<DurationEffect>();
        }
    }
}
```

### Step 3.2: Add System to App
**File**: `src/main.rs` or plugin file

```rust
app.add_systems(
    Update,
    process_duration_effects
        .run_if(in_state(GameState::Playing))
        .after(TurnSystemSet::TurnEnd)
);
```

### Step 3.3: Update Power Activations
```rust
PowerType::Freeze => {
    commands.entity(target).insert((
        Frozen,
        DurationEffect {
            effect_type: EffectType::Frozen,
            turns_remaining: 3,
        }
    ));
}
```

## 🧪 Task 4: Verify Implementations (2 hours)

### Run Comprehensive Tests
```bash
# Run all power tests
cargo test test_power -- --nocapture

# Run specific categories
cargo test test_movement_powers
cargo test test_terrain_powers
cargo test test_duration_effects
```

### Manual Testing Checklist
For each implemented power:
- [ ] Power activates correctly
- [ ] Game mechanics change as expected
- [ ] Visual feedback is clear
- [ ] No crashes or side effects
- [ ] Works in edge cases (board edges, max height, etc.)

### Update Power Status Document
Create/update a tracking document:
```markdown
# Power Implementation Status

## Fully Implemented ✅
- MoveDiagonal: Movement validation integrated
- RaiseColumn: Terrain system connected
- Freeze: Duration tracking active

## Partially Implemented ⚠️
- Teleport: Activation works, movement validation pending

## Not Implemented ❌
- GrowQuadradius: No framework exists
```

## 📋 Success Criteria

You'll know the implementation is successful when:

1. **Movement Powers**: Pieces can actually move differently when powers are active
2. **Terrain Powers**: Board heights visually change and affect movement
3. **Duration Effects**: Effects expire after correct number of turns
4. **Tests Pass**: `cargo test` shows more passing tests
5. **No Regressions**: Existing functionality still works

## 🚫 Common Pitfalls to Avoid

1. **Don't create new systems** - Integrate with existing ones
2. **Don't break existing tests** - Run tests frequently
3. **Don't skip visual feedback** - Players need to see effects
4. **Don't forget edge cases** - Board boundaries, height limits
5. **Don't implement all at once** - Fix one power completely before moving to next

## 📝 Project Context

This is Phase 1 of an 8-phase project:

### Project Roadmap
- **Phase 1** (Current): Foundation & Power Integration
- **Phase 2**: Combat Powers & Effects  
- **Phase 3**: Board Manipulation & Terrain
- **Phase 4**: Meta Powers & Complex Interactions
- **Phase 5**: Polish & Release Preparation
- **Phase 6**: Review & Code Quality
- **Phase 7**: Web Deployment & WASM
- **Phase 8**: Final Testing & Validation

### Phase 1 Success = Project Success
Getting the power integration patterns right in Phase 1 is critical because:
- All subsequent phases depend on these patterns
- 55+ powers need the same integration approach
- Web deployment (Phase 7) requires stable foundation
- Final testing (Phase 8) validates everything works

## 📋 Final Notes

The architecture is excellent - you're not building new systems, just connecting existing ones. The gap is specifically in the integration layer between power activation and game mechanics.

Focus on making 5-10 powers work completely rather than 50 powers partially. Use TDD: make the existing tests pass by implementing the missing functionality.

**This work enables 6 more phases and 127 days of development.** Get the foundation right!

Good luck! The foundation is solid, you just need to wire up the connections.