# Quadradius Missing Features PRD
**Project Requirements Document for Research Compliance Enhancements**

## 1. Project Overview

### 1.1 Purpose
This PRD addresses the identified gaps between the current Quadradius implementation and the research specifications documented in `/research/game.md`. The goal is to achieve near-perfect compliance (95%+) with the original Quadradius game mechanics and user experience.

### 1.2 Current State Assessment
- **Overall Compliance**: 82/100
- **High-quality foundation** with 45 powers, dual rendering, and sophisticated systems
- **Missing critical features** that prevent full research compliance
- **Excellent architecture** ready for enhancement

### 1.3 Success Criteria
- Achieve 95%+ compliance with research specifications
- Maintain existing code quality and performance
- Implement all high-priority missing features
- Preserve existing functionality during enhancements

## 2. Feature Requirements

### 2.1 HIGH PRIORITY FEATURES

#### 2.1.1 PowerCollection Phase Implementation
**Priority**: Critical
**Compliance Gap**: Turn Structure (70% → 95%)

**Requirements**:
- Add `PowerCollection` variant to `TurnPhase` enum
- Implement 3-phase turn structure: `PowerActivation` → `PieceMovement` → `PowerCollection`
- Fix turn transition to complete all phases before switching players
- Add UI indication for PowerCollection phase
- Maintain automatic power collection on piece movement
- Add phase timeout system (optional skip after X seconds)

**Acceptance Criteria**:
- Turn phases follow exact research specification sequence
- Power collection happens in dedicated phase
- UI clearly shows current phase
- Players cannot move pieces during PowerCollection phase
- Turn only switches after all three phases complete

#### 2.1.2 Chat System Implementation
**Priority**: Critical
**Compliance Gap**: UI Implementation (72% → 85%)

**Requirements**:
- Add right-side chat panel as specified in research
- Implement chat message input and display
- Support local multiplayer chat (foundation for network later)
- Chat history persistence during game session
- Chat timestamps and player identification
- Integration with existing UI layout without disrupting gameplay

**Acceptance Criteria**:
- Chat panel positioned on right side of screen
- Players can send and receive messages
- Chat history shows during entire game session
- Chat input doesn't interfere with game controls
- UI layout matches research specifications

#### 2.1.3 Per-Piece Power Storage System
**Priority**: High
**Compliance Gap**: Power System (75% → 80%)

**Requirements**:
- Refactor power storage from per-player to per-piece
- Each `GamePiece` maintains its own power inventory
- UI shows power inventory for selected piece
- Power activation applies to specific piece that owns the power
- Power collection adds to the piece that collected the orb
- Migration system for existing save data

**Acceptance Criteria**:
- Each piece has independent power inventory
- UI displays powers for currently selected piece
- Power activation affects only the piece that owns the power
- Power collection system works with per-piece storage
- Existing game save compatibility maintained

#### 2.1.4 Power Spawning Mechanics Fix
**Priority**: High
**Compliance Gap**: Power System (75% → 82%)

**Requirements**:
- Change from 50% chance per turn to every 7 rounds
- Implement territory-based spawn location bias
- Spawn approximately 80 power orbs throughout game
- Track territory control for spawn location influence
- Maintain spawn randomness within territorial bias

**Acceptance Criteria**:
- Power orbs spawn exactly every 7 rounds
- Territory control influences spawn locations
- Total orb count reaches ~80 per game
- Spawn locations favor player with more territorial control
- Spawn system matches research specifications

### 2.2 MEDIUM PRIORITY FEATURES

#### 2.2.1 Missing Power Implementations
**Priority**: Medium
**Compliance Gap**: Power System (75% → 90%)

**Requirements**:
- Research and implement missing 25-41 powers to reach 70-86 total
- Priority powers: "Grow Quadradius", "Jump Proof", "Teach Row/Radial", "Dredge Column"
- Implement "Acid" (permanent board holes), "Snake Tunneling", "Beneficiary" powers
- Add "Scramble Column" and other terrain manipulation powers
- Maintain existing power balance and testing framework

**Acceptance Criteria**:
- Total power count reaches 70-86 powers
- All new powers have complete visual effects
- Automated testing covers all new powers
- Power balance remains stable
- Implementation quality matches existing powers

#### 2.2.2 Camera Angle Precision
**Priority**: Medium
**Compliance Gap**: Isometric Rendering (85% → 90%)

**Requirements**:
- Update camera vertical angle from 35° to precise 35.264° (arcsin(1/√3))
- Verify mathematical accuracy of isometric projection
- Maintain existing coordinate transformation accuracy
- Test visual alignment after angle change

**Acceptance Criteria**:
- Camera uses exact 35.264° vertical angle
- Coordinate transformations remain accurate
- Visual appearance maintains isometric quality
- No regression in mouse interaction accuracy

#### 2.2.3 Visual Enhancement
**Priority**: Medium
**Compliance Gap**: UI Implementation (72% → 80%)

**Requirements**:
- Enhance power orbs to appear as "small metallic domes"
- Improve piece graphics for better differentiation
- Add metallic textures and professional polish
- Maintain performance while enhancing visuals

**Acceptance Criteria**:
- Power orbs have metallic dome appearance
- Pieces have enhanced visual differentiation
- Visual quality matches research specifications
- No performance degradation from visual enhancements

## 3. Technical Architecture

### 3.1 System Design Principles
- **Minimal Disruption**: Enhance existing systems without breaking changes
- **ECS Consistency**: Follow existing Bevy ECS patterns
- **Performance First**: Maintain current performance standards
- **Test Coverage**: All new features must have comprehensive tests

### 3.2 Implementation Strategy

#### Phase 1: Core Mechanics (Sprint 1-2)
1. PowerCollection phase implementation
2. Turn structure fixes
3. Per-piece power storage refactor

#### Phase 2: User Experience (Sprint 3-4)
1. Chat system implementation
2. Power spawning mechanics fix
3. UI layout adjustments

#### Phase 3: Content Expansion (Sprint 5-8)
1. Missing power research and implementation
2. Visual enhancements
3. Performance optimizations

### 3.3 Testing Strategy
- **Test-Driven Development**: Write tests before implementation
- **Integration Testing**: Verify interaction between new and existing systems
- **Performance Testing**: Ensure no performance regression
- **User Acceptance Testing**: Verify compliance with research specifications

## 4. Risk Assessment

### 4.1 Technical Risks
- **High**: Per-piece power storage refactor may affect game balance
- **Medium**: Chat system integration may impact UI layout
- **Low**: PowerCollection phase implementation risk

### 4.2 Mitigation Strategies
- Extensive testing of power storage refactor
- Gradual UI integration with fallback options
- Feature flags for new functionality

## 5. Success Metrics

### 5.1 Compliance Metrics
- **Target**: 95%+ overall compliance score
- **Turn Structure**: 70% → 95%
- **Power System**: 75% → 90%
- **UI Implementation**: 72% → 85%
- **Isometric Rendering**: 85% → 90%

### 5.2 Quality Metrics
- Zero performance regression
- 100% test coverage for new features
- Maintain existing code quality standards
- No breaking changes to existing functionality

## 6. Timeline and Milestones

### Sprint 1 (Week 1): PowerCollection Phase
- Implement PowerCollection phase enum
- Add turn structure logic
- Write comprehensive tests
- UI updates for phase indication

### Sprint 2 (Week 2): Power Storage Refactor
- Refactor power storage to per-piece
- Update UI for piece-specific powers
- Migration system for existing data
- Comprehensive testing

### Sprint 3 (Week 3): Chat System
- Design and implement chat UI
- Add chat functionality
- Integration with existing layout
- User experience testing

### Sprint 4 (Week 4): Power Spawning
- Implement 7-round spawn cycle
- Add territory-based spawn bias
- Testing and balance verification
- Performance optimization

### Sprint 5-8 (Weeks 5-8): Content Expansion
- Research missing powers
- Implement priority powers
- Visual enhancements
- Final testing and polish

## 7. Acceptance Criteria Summary

This PRD is complete when:
- ✅ All high-priority features are implemented and tested
- ✅ Overall compliance score reaches 95%+
- ✅ No regression in existing functionality
- ✅ Performance maintained or improved
- ✅ User experience matches research specifications
- ✅ Code quality standards maintained
- ✅ Comprehensive documentation updated

## 8. Dependencies

### 8.1 Research Dependencies
- Complete analysis of missing powers from `/research/game.md`
- UI layout specifications from research documents
- Original game behavior verification

### 8.2 Technical Dependencies
- Bevy ECS framework capabilities
- Existing UI system architecture
- Current power system design
- Performance monitoring tools

### 8.3 Resource Dependencies
- Development time allocation
- Testing environment setup
- Documentation updates
- Code review processes

This PRD serves as the foundation for achieving research compliance while maintaining the high quality of the existing Quadradius implementation.