# Phase 2: Combat Powers & Effect Systems - Task List

**Phase Duration**: 14 days  
**Status**: ⏳ NOT STARTED (Blocked by Phase 1)  
**Prerequisites**: Phase 1 power integration complete  
**Last Updated**: January 2025

## Phase Overview
Implement combat powers focusing on duration-based effects, protection mechanics, and complex combat interactions. This phase introduces stateful effects that persist across turns.

## Task Status Summary
- ✅ Complete: 0/12 tasks
- 🔧 In Progress: 0/12 tasks
- ⏳ Not Started: 12/12 tasks
- 🚫 Blocked: 12/12 tasks (by Phase 1)

---

## Effect System Foundation (Days 1-3)

### Task 2.1: PowerEffect Component Framework ⏳
**Status**: NOT STARTED  
**Duration**: 4 hours  
**Dependencies**: Phase 1 complete  
**Description**: Create foundational duration-based effect system

**Subtasks**:
- [ ] Define PowerEffect component with duration tracking
- [ ] Create EffectData enum for different effect types
- [ ] Implement effect stacking rules
- [ ] Add effect expiration system
- [ ] Create visual effect indicator system

**Technical Requirements**:
```rust
#[derive(Component)]
pub struct PowerEffect {
    pub power_type: PowerType,
    pub duration_turns: u32,
    pub target_entity: Entity,
    pub effect_data: EffectData,
}
```

**Acceptance Criteria**:
- Effects track duration accurately
- Multiple effects can exist on same piece
- Effects expire at turn boundaries
- Clear visual indicators for active effects

### Task 2.2: Turn-Based Effect Processing ⏳
**Status**: NOT STARTED  
**Duration**: 3 hours  
**Dependencies**: Task 2.1  
**Description**: Integrate effect processing with turn management

**Subtasks**:
- [ ] Add effect processing phase to turn system
- [ ] Implement duration countdown logic
- [ ] Handle effect expiration cleanup
- [ ] Process death effects (poison)
- [ ] Update UI to show remaining duration

**Integration Points**:
- `turn_management.rs` - Add effect phase
- `game_state.rs` - Track active effects
- Turn order: Effects → Powers → Movement → Collection

**Acceptance Criteria**:
- Effects process exactly once per turn
- Countdown happens at correct phase
- Expired effects are removed cleanly
- No duplicate processing

### Task 2.3: Effect Component Implementation ⏳
**Status**: NOT STARTED  
**Duration**: 6 hours  
**Dependencies**: Task 2.1  
**Description**: Create specific effect components

**Components to Implement**:
1. **Shield Component**:
   - [ ] Damage absorption mechanics
   - [ ] Visual shield indicator
   - [ ] Shield break effects
   - [ ] Multi-hit shield variants

2. **Invisible Component**:
   - [ ] Hide from opponent view
   - [ ] Maintain for owner visibility
   - [ ] Targeting restrictions
   - [ ] Reveal conditions

3. **Frozen Component**:
   - [ ] Movement prevention
   - [ ] Visual ice effects
   - [ ] Interaction with push/pull
   - [ ] Thaw mechanics

4. **Poisoned Component**:
   - [ ] Death countdown
   - [ ] Visual poison effects
   - [ ] Cure possibilities
   - [ ] Spread mechanics

**Acceptance Criteria**:
- Each effect has distinct behavior
- Components are reusable
- Effects combine properly
- Visual feedback is clear

---

## Combat Power Implementation (Days 4-8)

### Task 2.4: Protection Powers ⏳
**Status**: NOT STARTED  
**Duration**: 4 hours  
**Dependencies**: Task 2.3  
**Description**: Implement defensive combat powers

**Powers to Implement**:
1. **Shield Power**:
   - [ ] Apply Shield component
   - [ ] Integrate with combat system
   - [ ] Handle different shield types
   - [ ] Balance shield strength

2. **Reflect Power**:
   - [ ] Bounce attacks back
   - [ ] Handle reflection chains
   - [ ] Visual reflection effects
   - [ ] Prevent infinite loops

3. **Immunity Power**:
   - [ ] Temporary damage immunity
   - [ ] Different from shield (time-based)
   - [ ] Stack with other protections
   - [ ] Clear immunity indicators

**Acceptance Criteria**:
- Protection prevents appropriate damage
- Visual feedback shows protection status
- Integration doesn't break combat
- Powers are balanced

### Task 2.5: Stealth Powers ⏳
**Status**: NOT STARTED  
**Duration**: 5 hours  
**Dependencies**: Task 2.3  
**Description**: Implement invisibility and detection

**Powers to Implement**:
1. **Invisible Power**:
   - [ ] 3-turn invisibility
   - [ ] Hide from opponent
   - [ ] Maintain owner control
   - [ ] Break on attack

2. **Cloak Area**:
   - [ ] 3x3 invisibility field
   - [ ] Affect multiple pieces
   - [ ] Duration management
   - [ ] Visual area indicator

3. **Reveal Power**:
   - [ ] Remove enemy invisibility
   - [ ] Area reveal option
   - [ ] Counter-stealth mechanics
   - [ ] Detection effects

**Technical Challenges**:
- Multiplayer visibility states
- Selective rendering
- UI indication without revealing position

**Acceptance Criteria**:
- Invisible pieces can't be targeted by opponents
- Owner maintains full control
- Reveal mechanics work correctly
- No information leaks

### Task 2.6: Destruction Powers ⏳
**Status**: NOT STARTED  
**Duration**: 4 hours  
**Dependencies**: Task 2.4  
**Description**: Implement offensive combat powers

**Powers to Implement**:
1. **Assassin Power**:
   - [ ] Kill without capture
   - [ ] Bypass shields
   - [ ] Range restrictions
   - [ ] Assassination effects

2. **Explode Power**:
   - [ ] Self-destruct mechanics
   - [ ] Area damage calculation
   - [ ] Chain reaction prevention
   - [ ] Explosion animation

3. **Sniper Power**:
   - [ ] Long-range targeting
   - [ ] Line-of-sight validation
   - [ ] Precision kill effects
   - [ ] Range indicators

**Acceptance Criteria**:
- Each power has unique destruction method
- Visual effects communicate action
- No unintended casualties
- Balanced damage output

### Task 2.7: Conversion Powers ⏳
**Status**: NOT STARTED  
**Duration**: 6 hours  
**Dependencies**: Task 2.3  
**Description**: Implement allegiance and state changes

**Powers to Implement**:
1. **Recruit Power**:
   - [ ] Change piece ownership
   - [ ] Update visual appearance
   - [ ] Handle power inventory
   - [ ] Recruitment effects

2. **Poison Power**:
   - [ ] Apply death countdown
   - [ ] Turn-based damage
   - [ ] Poison spread option
   - [ ] Antidote mechanics

3. **Freeze Power**:
   - [ ] Movement lock for 3 turns
   - [ ] Visual freeze effects
   - [ ] Interaction with other powers
   - [ ] Thaw conditions

**Technical Requirements**:
- Ownership change system
- State tracking across turns
- Visual state indicators

**Acceptance Criteria**:
- Conversion changes allegiance correctly
- Effects persist correct duration
- Visual feedback is clear
- Win conditions update properly

---

## Integration & Testing (Days 9-12)

### Task 2.8: Combat System Integration ⏳
**Status**: NOT STARTED  
**Duration**: 6 hours  
**Dependencies**: Tasks 2.4-2.7  
**Description**: Integrate all combat powers with game systems

**Integration Areas**:
1. **Movement System**:
   - [ ] Frozen pieces can't move
   - [ ] Invisible pieces remain selectable by owner
   - [ ] Pushed/pulled frozen pieces

2. **Combat Resolution**:
   - [ ] Shield damage absorption
   - [ ] Assassination bypasses
   - [ ] Reflection mechanics
   - [ ] Explosion chains

3. **Turn Management**:
   - [ ] Effect processing order
   - [ ] Power activation timing
   - [ ] State cleanup

4. **UI Systems**:
   - [ ] Effect duration display
   - [ ] Power preview with effects
   - [ ] Status indicators

**Acceptance Criteria**:
- All systems work together
- No timing conflicts
- Clear order of operations
- Consistent behavior

### Task 2.9: Effect Interaction System ⏳
**Status**: NOT STARTED  
**Duration**: 4 hours  
**Dependencies**: Task 2.8  
**Description**: Handle complex effect combinations

**Interaction Rules**:
1. **Shield + Freeze**:
   - [ ] Can be frozen while shielded
   - [ ] Shield blocks while frozen
   - [ ] Visual combination

2. **Invisible + Poison**:
   - [ ] Poison visible to owner
   - [ ] Death reveals position
   - [ ] Effect priorities

3. **Multiple Shields**:
   - [ ] Stacking rules
   - [ ] Maximum protection
   - [ ] Visual layering

**Edge Cases**:
- [ ] Effects on destroyed pieces
- [ ] Simultaneous effect application
- [ ] Conflicting effects
- [ ] Effect transfer on conversion

**Acceptance Criteria**:
- Predictable interaction rules
- No effect conflicts
- Visual clarity maintained
- Edge cases handled

### Task 2.10: Comprehensive Testing ⏳
**Status**: NOT STARTED  
**Duration**: 6 hours  
**Dependencies**: All previous tasks  
**Description**: Test all combat powers thoroughly

**Test Categories**:
1. **Unit Tests**:
   - [ ] Each power in isolation
   - [ ] Effect duration accuracy
   - [ ] Component behavior
   - [ ] Edge cases

2. **Integration Tests**:
   - [ ] Power combinations
   - [ ] System interactions
   - [ ] Turn sequencing
   - [ ] Multiplayer scenarios

3. **Performance Tests**:
   - [ ] Many active effects
   - [ ] Complex interactions
   - [ ] Visual effect load
   - [ ] Memory usage

4. **Balance Tests**:
   - [ ] Power effectiveness
   - [ ] Counter availability
   - [ ] Game length impact
   - [ ] Fun factor

**Deliverables**:
- Test report with coverage
- Bug list with priorities
- Performance metrics
- Balance recommendations

### Task 2.11: Polish & Optimization ⏳
**Status**: NOT STARTED  
**Duration**: 4 hours  
**Dependencies**: Task 2.10  
**Description**: Refine combat powers based on testing

**Areas to Polish**:
1. **Visual Effects**:
   - [ ] Enhance effect clarity
   - [ ] Improve animations
   - [ ] Optimize particle systems
   - [ ] Add sound effects

2. **Performance**:
   - [ ] Profile effect systems
   - [ ] Optimize hot paths
   - [ ] Reduce allocations
   - [ ] Batch effect updates

3. **User Experience**:
   - [ ] Clearer feedback
   - [ ] Better previews
   - [ ] Intuitive indicators
   - [ ] Consistent behavior

**Acceptance Criteria**:
- Smooth 60 FPS maintained
- Effects are visually appealing
- User feedback incorporated
- Code is production ready

### Task 2.12: Documentation & Handoff ⏳
**Status**: NOT STARTED  
**Duration**: 3 hours  
**Dependencies**: All tasks complete  
**Description**: Document implementation and prepare Phase 3

**Documentation Tasks**:
- [ ] Update power implementation guide
- [ ] Document effect system architecture
- [ ] Create interaction rule reference
- [ ] Write troubleshooting guide

**Phase 3 Preparation**:
- [ ] Identify integration points for board powers
- [ ] List required system extensions
- [ ] Document known limitations
- [ ] Create Phase 3 task estimates

**Deliverables**:
- Complete API documentation
- Effect interaction matrix
- Phase 2 retrospective
- Phase 3 readiness checklist

---

## Success Metrics

### Functional Requirements
- [ ] All combat powers functional
- [ ] Duration effects process correctly
- [ ] Combat integration complete
- [ ] Visual feedback clear

### Quality Metrics
- **Test Coverage**: >90% for combat systems
- **Performance**: 60 FPS with 20+ active effects
- **Bug Count**: <5 minor, 0 critical
- **Code Quality**: No tech debt introduced

### Phase Exit Criteria
1. All tasks complete and tested
2. Documentation updated
3. No blocking bugs
4. Performance targets met
5. Phase 3 can begin

---

## Notes for Implementation

### Priority Guidelines
1. Foundation first - effect system is critical
2. Simple effects before complex interactions
3. Test continuously - effects are stateful
4. Visual feedback is essential

### Technical Tips
- Use ECS queries efficiently for effects
- Batch effect updates per turn
- Consider effect rendering layers
- Plan for save/load compatibility

### Risk Mitigation
- Test effect combinations early
- Profile performance regularly
- Keep effects visually distinct
- Document all interaction rules

Phase 2 transforms combat from simple capture to strategic effect management.