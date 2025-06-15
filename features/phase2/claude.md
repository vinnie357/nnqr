# Phase 2: Combat Powers & Effect Systems - Context for Claude

## Phase Overview
**Status**: ⏳ NOT STARTED (Blocked by Phase 1)  
**Prerequisites**: Phase 1 power integration must be complete  
**Focus**: Combat powers with duration-based effects and complex interactions

## Research Documents & Context

### Primary Research References
1. **Combat Powers**: `/research/game.md`
   - Lines 50-67: Combat power categories and examples
   - Lines 58-59: "Destroy Column/Row: Eliminates entire lines"
   - Lines 60: "Bombs: Drops 16 random bombs"
   - Lines 62-67: Strategic powers (Shield, Invisible, Recruit)

2. **Turn Structure**: `/research/game.md`
   - Lines 24-29: Power activation phases
   - Line 25: "Power Activation Phase: Activate any collected power-ups (must be done before moving)"
   - Lines 31-33: Power collection mechanics

3. **Technical Architecture**: `/instructions/nnqr_prd.md`
   - Lines 95-115: Power-up system technical details
   - Lines 106-108: "Duration-based effects (shields, invisibility)"
   - Lines 109-111: "Area-of-effect powers"
   - Lines 306-310: Power interaction complexity

4. **Balance Considerations**: `/research/game.md`
   - Lines 193-197: Power balance and combinations
   - Line 194: "Grow Quadradius + area kill powers" noted as overpowered
   - Line 195: "Early Jump Proof creating significant advantages"

## Key Architecture Requirements

### Duration-Based Effect System
**Components Needed**:
```rust
#[derive(Component)]
pub struct PowerEffect {
    pub power_type: PowerType,
    pub duration_turns: u32,
    pub target_entity: Entity,
    pub effect_data: EffectData,
}

#[derive(Component)]
pub struct Frozen { pub turns_remaining: u32 }

#[derive(Component)]
pub struct Poisoned { pub death_countdown: u32 }

#[derive(Component)]
pub struct Invisible { pub turns_remaining: u32 }

#[derive(Component)]
pub struct Shield { pub hits_remaining: u32 }
```

### Turn-Based Processing
- Effects must decrement each turn
- Expired effects must be removed
- Death effects (poison) must trigger
- Visual indicators must update

### Combat Power Categories

#### Protection Powers
1. **Shield** - Blocks next attack
2. **JumpProof** - Permanent capture immunity
3. **Reflect** - Returns attacks to sender

#### Stealth Powers
1. **Invisible** - Hidden for 3 turns
2. **Cloak** - Area invisibility
3. **Reveal** - Remove enemy invisibility

#### Destruction Powers
1. **SmartBomb** - 3x3 area destruction
2. **Explode** - Self-destruct with area damage
3. **Assassin** - Kill without capture
4. **Sniper** - Long-range elimination

#### Conversion Powers
1. **Recruit** - Convert enemy piece
2. **Poison** - Delayed destruction
3. **Freeze** - Temporary immobilization

## Phase 2 Dependencies

### From Phase 1 (Must be Complete)
1. **Power Integration Framework** - How powers modify game rules
2. **Component Addition System** - Adding effects to entities
3. **Turn Management Integration** - Processing at turn boundaries
4. **Visual Feedback System** - Showing active effects

### Systems to Extend
1. **Turn Management** - Add effect processing phase
2. **Combat Resolution** - Check for shields/protection
3. **Targeting System** - Handle invisibility
4. **UI System** - Show effect durations

## Implementation Patterns

### Duration Effect Pattern
```rust
// On power activation
commands.entity(target).insert((
    Frozen,
    PowerEffect {
        power_type: PowerType::Freeze,
        duration_turns: 3,
        target_entity: target,
        effect_data: EffectData::Movement(MovementRestriction::None),
    }
));

// Each turn
for (entity, mut effect) in effects.iter_mut() {
    effect.duration_turns -= 1;
    if effect.duration_turns == 0 {
        commands.entity(entity).remove::<Frozen>();
        commands.entity(entity).remove::<PowerEffect>();
    }
}
```

### Shield Integration Pattern
```rust
// In capture/combat system
if target.has::<Shield>() {
    // Block attack
    commands.entity(target).remove::<Shield>();
    // Show shield break effect
    return; // Don't capture piece
}
```

### Invisibility Pattern
```rust
// In rendering
if piece.has::<Invisible>() && piece.owner != current_player {
    // Don't render for opponent
    visibility.is_visible = false;
}

// In targeting
if target.has::<Invisible>() && targeting_player != owner {
    // Can't target invisible enemy pieces
    return false;
}
```

## Testing Requirements

### Unit Tests Needed
1. Effect duration countdown
2. Shield damage absorption
3. Invisibility targeting restrictions
4. Poison death timing
5. Freeze movement prevention

### Integration Tests
1. Multiple effects on same piece
2. Effect expiration at turn boundary
3. Combat with protected pieces
4. Area effects with mixed targets

## Phase 2 Success Criteria

1. **Duration System Works**: Effects count down and expire correctly
2. **Combat Integration**: Shields block attacks, invisibility prevents targeting
3. **Visual Clarity**: All effects have clear indicators
4. **No Side Effects**: Effects don't break existing gameplay
5. **Performance**: Game maintains 60 FPS with many active effects

## Common Pitfalls

1. **Effect Stacking**: Multiple shields/effects on same piece
2. **Turn Timing**: Effects processing at wrong phase
3. **Multiplayer Sync**: Invisibility state differences
4. **Visual Overload**: Too many effect indicators
5. **Edge Cases**: Effects on destroyed pieces

## Development Order

1. **Effect Component System** (Task 2.1)
2. **Turn-Based Processing** (Task 2.2)
3. **Shield Implementation** (Task 2.3)
4. **Invisibility System** (Task 2.4)
5. **Poison/Freeze Effects** (Task 2.5)
6. **Combat Integration** (Task 2.6)

## Resources

- Working examples: MoveDiagonal, DestroyColumn
- Test files: `combat_powers_tests.rs`
- Effect components: Already defined in `components/power.rs`
- Turn system: `systems/turn_management.rs`

Phase 2 begins when Phase 1 integration is complete and tested.