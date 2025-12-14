# Phase 2: Combat Powers & Advanced Effects System

**Phase Status**: Awaiting Phase 1 Completion
**Duration**: 2-3 weeks  
**Priority**: High (core gameplay enhancement)

## Phase Overview

Phase 2 implements the comprehensive combat power system and advanced duration-based effects. Building on the solid foundation from Phase 1, this phase adds strategic depth through shields, invisibility, poison, conversion, and destruction mechanics.

## Phase Dependencies
- **Prerequisites**: Phase 1 (duration effect framework must be complete)
- **Enables**: Phase 3 (board manipulation requires combat system maturity)
- **Parallel Opportunities**: Documentation and testing can run in parallel

## Core Tasks

### Task 2.1: Advanced PowerEffect Component Framework
**Priority**: Critical | **Status**: Awaiting Phase 1
**Description**: Extend Phase 1 duration framework for complex combat effects

**Acceptance Criteria**:
- [ ] PowerEffect component handles stacking effects
- [ ] Effect priority system resolves conflicts
- [ ] Multiple effects can coexist with proper interaction rules
- [ ] Effect expiration system works reliably

### Task 2.2: Protection Powers Implementation  
**Priority**: High | **Status**: Awaiting Phase 1
**Description**: Implement shield and defensive combat powers

**Key Powers**: Shield, Absorption, Protection
**Acceptance Criteria**:
- [ ] Shield component blocks capture attempts
- [ ] Visual indicators clearly show protected pieces
- [ ] Shield destruction provides appropriate feedback
- [ ] Shield integrates with all attack types

### Task 2.3: Stealth and Invisibility Powers
**Priority**: High | **Status**: Awaiting Phase 1  
**Description**: Implement invisibility and stealth-based powers

**Key Powers**: Invisible, Stealth, Hidden
**Acceptance Criteria**:
- [ ] Invisible pieces cannot be targeted by opponents
- [ ] Owner retains full control of invisible pieces
- [ ] Invisibility breaks appropriately on actions
- [ ] Clear visual feedback for invisibility state

### Task 2.4: Conversion and State Change Powers
**Priority**: High | **Status**: Awaiting Phase 1
**Description**: Implement powers that change piece ownership and state

**Key Powers**: Recruit, Poison, Convert, Transform
**Acceptance Criteria**:
- [ ] Recruit power changes piece ownership correctly
- [ ] Poison effect causes delayed piece destruction
- [ ] Visual effects clearly indicate state changes
- [ ] Converted pieces integrate properly with win conditions

### Task 2.5: Destruction and Explosive Powers
**Priority**: High | **Status**: Awaiting Phase 1
**Description**: Implement explosive and area destruction combat powers

**Key Powers**: Explode, Bomb, Assassinate, Destroy
**Acceptance Criteria**:
- [ ] Explosive powers affect correct area (adjacent squares)
- [ ] Chain destruction effects work properly
- [ ] Visual effects show explosion radius and impact
- [ ] Destruction integrates with piece removal systems

### Task 2.6: Combat Power Integration Testing
**Priority**: High | **Status**: Awaiting Previous Tasks
**Description**: Comprehensive testing of combat power interactions

**Acceptance Criteria**:
- [ ] All combat powers work in multiplayer scenarios
- [ ] Power combinations produce expected results
- [ ] Edge cases handled gracefully
- [ ] Performance maintained with complex effect combinations

## Quality Gates

### Completion Criteria
- [ ] All combat powers implemented and tested
- [ ] Duration-based effects work reliably across turns
- [ ] Visual feedback clear and informative
- [ ] Multiplayer compatibility verified
- [ ] No performance degradation from combat effects

### Testing Requirements
- [ ] Unit tests for each combat power
- [ ] Integration tests for power combinations
- [ ] Performance tests with multiple simultaneous effects
- [ ] Manual testing for user experience validation

## Technical Implementation Notes

### Component Architecture
```rust
// Extended effect system
#[derive(Component)]
pub struct Shield {
    pub remaining_hits: u32,
    pub shield_type: ShieldType,
}

#[derive(Component)]
pub struct Invisible {
    pub turns_remaining: u32,
    pub break_on_action: bool,
}

#[derive(Component)]
pub struct Poisoned {
    pub turns_to_death: u32,
    pub poison_source: Entity,
}
```

### System Integration Points
- **Combat Resolution**: Integration with piece capture mechanics
- **Visual Effects**: Enhanced particle systems for combat effects
- **Turn Management**: Effect processing during turn transitions
- **Multiplayer Sync**: State synchronization for all effects

## Risk Assessment

### High-Risk Items
- **Effect Stacking Complexity**: Multiple effects on same piece may cause conflicts
- **Performance Impact**: Complex visual effects may reduce frame rate
- **Balance Issues**: Powerful combat effects may break game balance

### Mitigation Strategies
- Comprehensive effect interaction testing
- Performance profiling with maximum effect load
- Iterative balance testing with gameplay scenarios

## Success Metrics

### Functional Targets
- 100% of combat powers work correctly in all scenarios
- Effect duration accuracy within 1 turn
- Clear visual distinction between all effect types
- Zero crashes with maximum effect combinations

### Performance Targets
- Maintain 60+ FPS with 10+ simultaneous effects
- Effect processing time under 16ms per frame
- Memory usage increase under 100MB with all effects active

### User Experience Targets
- Players can clearly identify active effects on all pieces
- Combat power outcomes are predictable and logical
- Visual effects enhance gameplay without causing confusion