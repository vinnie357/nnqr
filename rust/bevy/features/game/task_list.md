# Quadradius Missing Features Implementation Task List

Based on the PRD for missing features implementation, this document tracks detailed tasks across all enhancement phases.

## Phase 1: Core Mechanics (Sprint 1-2)

### Sprint 1: PowerCollection Phase Implementation

#### Task 1.1: Extend TurnPhase Enum ⏳
**Status**: Not Started  
**Priority**: Critical  
**Estimate**: 2 hours  
**Files**: `src/resources/game_state.rs`

- [ ] Add `PowerCollection` variant to `TurnPhase` enum
- [ ] Update enum serialization/deserialization
- [ ] Update all pattern matching to handle new phase
- [ ] Add phase transition validation logic

#### Task 1.2: Implement Turn Structure Logic ⏳
**Status**: Not Started  
**Priority**: Critical  
**Estimate**: 4 hours  
**Files**: `src/systems/drag_drop.rs`, `src/systems/power_effects.rs`

- [ ] Modify turn transition to follow PowerActivation → PieceMovement → PowerCollection
- [ ] Add PowerCollection phase duration logic
- [ ] Implement automatic phase advancement
- [ ] Add skip functionality for PowerCollection phase
- [ ] Update turn switching to happen only after PowerCollection

#### Task 1.3: PowerCollection Phase Tests ⏳
**Status**: Not Started  
**Priority**: Critical  
**Estimate**: 3 hours  
**Files**: `src/tests/turn_phase_tests.rs` (new)

- [ ] Write tests for PowerCollection phase enum
- [ ] Test turn structure sequence validation
- [ ] Test phase transition timing
- [ ] Test skip functionality
- [ ] Test turn switching only after all phases

#### Task 1.4: UI Updates for Phase Indication ⏳
**Status**: Not Started  
**Priority**: High  
**Estimate**: 3 hours  
**Files**: `src/systems/enhanced_ui.rs`

- [ ] Add PowerCollection phase indicator to UI
- [ ] Update turn indicator to show current phase
- [ ] Add visual feedback for phase transitions
- [ ] Add skip button for PowerCollection phase

### Sprint 2: Per-Piece Power Storage Refactor

#### Task 2.1: Refactor Power Storage Components ⏳
**Status**: Not Started  
**Priority**: Critical  
**Estimate**: 6 hours  
**Files**: `src/components/piece.rs`, `src/components/power.rs`

- [ ] Add `PowerInventory` component to `GamePiece`
- [ ] Remove player-level power storage from `GameState`
- [ ] Update power collection to add to piece inventory
- [ ] Update power activation to use piece inventory
- [ ] Create migration system for existing saves

#### Task 2.2: Update Power UI System ⏳
**Status**: Not Started  
**Priority**: High  
**Estimate**: 4 hours  
**Files**: `src/systems/power_activation_ui.rs`, `src/systems/enhanced_ui.rs`

- [ ] Modify UI to show powers for selected piece
- [ ] Update power activation to work with piece selection
- [ ] Add piece selection indicator
- [ ] Update power tooltips and display

#### Task 2.3: Per-Piece Power Storage Tests ⏳
**Status**: Not Started  
**Priority**: Critical  
**Estimate**: 4 hours  
**Files**: `src/tests/power_storage_tests.rs` (new)

- [ ] Test power collection adds to piece inventory
- [ ] Test power activation uses piece powers
- [ ] Test piece selection affects power UI
- [ ] Test power inventory persistence
- [ ] Test migration from old save format

## Phase 2: User Experience (Sprint 3-4)

### Sprint 3: Chat System Implementation

#### Task 3.1: Chat System Components ⏳
**Status**: Not Started  
**Priority**: Critical  
**Estimate**: 4 hours  
**Files**: `src/components/chat.rs` (new), `src/resources/chat_state.rs` (new)

- [ ] Create `ChatMessage` component
- [ ] Create `ChatState` resource
- [ ] Add message history storage
- [ ] Add player identification for messages
- [ ] Add timestamp support

#### Task 3.2: Chat UI Implementation ⏳
**Status**: Not Started  
**Priority**: Critical  
**Estimate**: 6 hours  
**Files**: `src/systems/chat_ui.rs` (new)

- [ ] Create right-side chat panel
- [ ] Add message display scrollable area
- [ ] Add chat input field
- [ ] Add send message functionality
- [ ] Integrate with existing UI layout

#### Task 3.3: Chat System Tests ⏳
**Status**: Not Started  
**Priority**: High  
**Estimate**: 3 hours  
**Files**: `src/tests/chat_tests.rs` (new)

- [ ] Test message sending and receiving
- [ ] Test chat history persistence
- [ ] Test UI integration
- [ ] Test player identification
- [ ] Test message timestamps

### Sprint 4: Power Spawning Mechanics

#### Task 4.1: Implement 7-Round Spawn Cycle ⏳
**Status**: Not Started  
**Priority**: High  
**Estimate**: 3 hours  
**Files**: `src/systems/power_orbs.rs`

- [ ] Replace percentage-based spawning with round counter
- [ ] Implement exact 7-round spawn timing
- [ ] Add spawn counter tracking in GameState
- [ ] Update orb spawning system

#### Task 4.2: Territory-Based Spawn Bias ⏳
**Status**: Not Started  
**Priority**: High  
**Estimate**: 4 hours  
**Files**: `src/systems/power_orbs.rs`, `src/systems/territory_control.rs` (new)

- [ ] Implement territory control calculation
- [ ] Add spawn location bias based on territory
- [ ] Maintain randomness within territorial influence
- [ ] Target ~80 total orbs per game

#### Task 4.3: Power Spawning Tests ⏳
**Status**: Not Started  
**Priority**: High  
**Estimate**: 3 hours  
**Files**: `src/tests/power_spawning_tests.rs` (new)

- [ ] Test 7-round spawn timing
- [ ] Test territory-based spawn bias
- [ ] Test total orb count over game
- [ ] Test spawn location distribution

## Phase 3: Content Expansion (Sprint 5-8)

### Sprint 5-6: High Priority Missing Powers

#### Task 5.1: Research Missing Powers ⏳
**Status**: Not Started  
**Priority**: Medium  
**Estimate**: 4 hours  
**Files**: Documentation research

- [ ] Analyze research documents for missing powers
- [ ] Prioritize most important missing powers
- [ ] Document power specifications
- [ ] Create implementation roadmap

#### Task 5.2: Implement "Grow Quadradius" Power ⏳
**Status**: Not Started  
**Priority**: Medium  
**Estimate**: 6 hours  
**Files**: `src/components/power.rs`, `src/systems/power_effects.rs`

- [ ] Add GrowQuadradius power type
- [ ] Implement massively extended kill range
- [ ] Add visual effects for extended range
- [ ] Balance against other powers

#### Task 5.3: Implement "Jump Proof" Power ⏳
**Status**: Not Started  
**Priority**: Medium  
**Estimate**: 4 hours  
**Files**: `src/components/power.rs`, `src/systems/power_effects.rs`

- [ ] Add JumpProof power type
- [ ] Implement permanent immunity to capture
- [ ] Add visual indicator for jump proof pieces
- [ ] Update capture logic to respect immunity

#### Task 5.4: Missing Powers Tests ⏳
**Status**: Not Started  
**Priority**: Medium  
**Estimate**: 6 hours  
**Files**: `src/tests/new_powers_tests.rs` (new)

- [ ] Test GrowQuadradius extended range
- [ ] Test JumpProof immunity
- [ ] Test power interactions
- [ ] Test visual effects

### Sprint 7: Additional Missing Powers

#### Task 7.1: Implement "Teach Row/Radial" Powers ⏳
**Status**: Not Started  
**Priority**: Medium  
**Estimate**: 5 hours  
**Files**: `src/components/power.rs`, `src/systems/power_effects.rs`

- [ ] Add TeachRow and TeachRadial power types
- [ ] Implement power sharing mechanics
- [ ] Add area-of-effect power distribution
- [ ] Update power inventory for receiving pieces

#### Task 7.2: Implement "Dredge Column" Power ⏳
**Status**: Not Started  
**Priority**: Medium  
**Estimate**: 4 hours  
**Files**: `src/components/power.rs`, `src/systems/power_effects.rs`

- [ ] Add DredgeColumn power type
- [ ] Lower enemy pieces 2 levels
- [ ] Raise friendly pieces 2 levels
- [ ] Integrate with terrain height system

#### Task 7.3: Implement "Acid" and "Snake Tunneling" ⏳
**Status**: Not Started  
**Priority**: Medium  
**Estimate**: 6 hours  
**Files**: `src/components/power.rs`, `src/systems/power_effects.rs`

- [ ] Add Acid power (permanent board holes)
- [ ] Add SnakeTunneling power
- [ ] Implement board hole mechanics
- [ ] Add terrain raising effects

### Sprint 8: Visual Enhancements and Polish

#### Task 8.1: Camera Angle Precision ⏳
**Status**: Not Started  
**Priority**: Low  
**Estimate**: 2 hours  
**Files**: `src/systems/isometric_camera.rs`

- [ ] Update vertical angle to 35.264° (arcsin(1/√3))
- [ ] Test coordinate transformation accuracy
- [ ] Verify visual alignment

#### Task 8.2: Power Orb Visual Enhancement ⏳
**Status**: Not Started  
**Priority**: Low  
**Estimate**: 4 hours  
**Files**: `src/systems/power_orbs.rs`, asset files

- [ ] Create metallic dome power orb models
- [ ] Update orb rendering to use new models
- [ ] Add metallic material properties
- [ ] Test performance impact

#### Task 8.3: Piece Visual Enhancement ⏳
**Status**: Not Started  
**Priority**: Low  
**Estimate**: 3 hours  
**Files**: `src/systems/pieces.rs`, asset files

- [ ] Enhance piece graphics for better differentiation
- [ ] Add metallic textures
- [ ] Improve visual contrast
- [ ] Maintain performance

## Current Implementation Progress

### ✅ Completed Tasks
- [x] Implementation review and analysis
- [x] PRD creation for missing features
- [x] Detailed task list creation

### 🔄 In Progress Tasks
None currently

### ⏳ Pending Tasks
All implementation tasks pending - ready to begin with PowerCollection phase

## Risk Assessment

### High Risk Tasks
- **Per-piece power storage refactor**: Major system change affecting game balance
- **Chat system UI integration**: May impact existing layout

### Medium Risk Tasks
- **Power spawning mechanics**: Changes game flow and balance
- **Missing power implementations**: Complexity unknown until research complete

### Low Risk Tasks
- **PowerCollection phase**: Additive change to existing system
- **Visual enhancements**: Primarily cosmetic changes

## Success Metrics

### Phase 1 Success Criteria
- [ ] Turn structure follows exact 3-phase sequence
- [ ] Powers stored and managed per-piece
- [ ] All tests pass
- [ ] No performance regression

### Phase 2 Success Criteria
- [ ] Chat system fully functional
- [ ] Power spawning follows research specifications
- [ ] UI layout matches research
- [ ] User experience improved

### Phase 3 Success Criteria
- [ ] Power count reaches 70+ powers
- [ ] Visual quality matches research specifications
- [ ] Performance maintained or improved
- [ ] Overall compliance score reaches 95%+

## Task Dependencies

```
PowerCollection Phase → Per-Piece Storage → Chat System → Power Spawning → Missing Powers → Visual Polish
```

## Notes

- All tasks require comprehensive testing before implementation
- Follow existing code patterns and architecture
- Maintain performance standards throughout
- Document all new features thoroughly
- Regular compliance assessment against research specifications