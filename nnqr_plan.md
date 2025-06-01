# Quadradius Implementation Plan for Claude Code

## Project Overview
**Objective**: Implement Quadradius (turn-based strategy game "checkers on steroids") in Rust using Bevy engine
**Key Challenge**: Managing ~70 power-ups while maintaining clean, extensible code
**Success Metric**: Two humans can play complete games with engaging power-up mechanics

---

## PHASE 1: FOUNDATION (MANDATORY FIRST)
**Timeline**: Complete before any other work
**Goal**: Playable basic game without power-ups

### Step 1.1: Project Setup & Basic Board
**Commands to execute**:
```bash
cargo new quadradius --bin
cd quadradius
cargo add bevy
```

**Implementation Tasks**:
1. Create basic Bevy app with window
2. Implement 8x8 board rendering system
3. Add terrain height visualization (different colors/heights)
4. Create board tile entities with coordinates and height components

**Acceptance Criteria**:
- [ ] Window opens showing 8x8 grid
- [ ] Tiles display different heights visually
- [ ] Board is centered and properly scaled
- [ ] No crashes or performance issues

### Step 1.2: Player Pieces & Selection
**Implementation Tasks**:
1. Create player piece entities (20 pieces each)
2. Place pieces in starting positions (opposite sides)
3. Implement piece selection via mouse clicks
4. Add visual feedback for selected pieces

**Acceptance Criteria**:
- [ ] 40 total pieces visible on board (20 per player)
- [ ] Clicking selects/deselects pieces
- [ ] Selected pieces are visually highlighted
- [ ] Only current player can select their pieces

### Step 1.3: Movement System
**Implementation Tasks**:
1. Implement movement validation (horizontal/vertical only)
2. Add terrain height restrictions (down any levels, up one level max)
3. Create move preview system (show valid moves)
4. Handle piece movement and board updates

**Acceptance Criteria**:
- [ ] Valid moves are highlighted when piece selected
- [ ] Invalid moves are blocked (wrong direction, height, occupied)
- [ ] Pieces move smoothly to new positions
- [ ] Board state updates correctly after moves

### Step 1.4: Turn Management & Game Rules
**Implementation Tasks**:
1. Implement turn alternation between players
2. Add piece capture mechanics (land on opponent piece)
3. Create win condition detection (eliminate all opponent pieces)
4. Add basic UI showing current player and game status

**Acceptance Criteria**:
- [ ] Turns alternate automatically after valid moves
- [ ] Pieces are captured and removed when landed on
- [ ] Game detects and announces winner
- [ ] UI clearly shows whose turn it is

**PHASE 1 COMPLETE WHEN**: Two humans can play a complete game from start to finish with all basic rules working correctly.

---

## PHASE 2: POWER-UP FOUNDATION (ONLY AFTER PHASE 1)
**Goal**: Add core power-up mechanics with 5 simple powers

### Step 2.1: Power Orb System
**Implementation Tasks**:
1. Create power orb spawning system (random empty tiles)
2. Add visual representation of orbs on board
3. Implement orb collection when pieces move over them
4. Create power inventory system for players

**Acceptance Criteria**:
- [ ] Power orbs appear randomly on empty tiles
- [ ] Orbs are visually distinct and appealing
- [ ] Moving over orbs adds them to player inventory
- [ ] Orbs disappear after collection

### Step 2.2: Power Activation Framework
**Implementation Tasks**:
1. Create power activation UI panel
2. Implement "use power before move" turn phase
3. Add power targeting system (select targets)
4. Create power effect application framework

**Acceptance Criteria**:
- [ ] Players can see their collected powers
- [ ] Powers can be activated before moving
- [ ] Target selection works for different power types
- [ ] Powers are consumed after use

### Step 2.3: First 5 Powers Implementation
**Powers to implement (in order)**:

1. **Move Diagonal**
   - Allows one diagonal move this turn
   - Simple movement rule modification

2. **Raise Column**
   - Increases height of selected column by 1
   - Affects movement possibilities

3. **Lower Column (Dredge)**
   - Decreases height of selected column by 1
   - Cannot go below minimum height

4. **Destroy Column**
   - Removes column from play entirely
   - Pieces on destroyed column are eliminated

5. **Multiply**
   - Creates copy of selected piece
   - Places copy on adjacent empty tile

**Acceptance Criteria for Each Power**:
- [ ] Power can be selected and activated
- [ ] Effect works as expected
- [ ] No crashes or unintended side effects
- [ ] Visual feedback shows power activation

**PHASE 2 COMPLETE WHEN**: All 5 powers work correctly and game remains stable and fun.

---

## PHASE 3: EXPANDED POWER SYSTEM
**Goal**: Implement remaining ~65 powers in manageable groups

### Step 3.1: Movement Powers (Next 10 powers)
**Power Group**: Movement modification powers
- Teleportation abilities
- Multi-square movement
- Jump over pieces
- Swap positions

### Step 3.2: Combat Powers (Next 10 powers)
**Power Group**: Direct piece interaction
- Smart bombs (area destruction)
- Invisible pieces
- Recruit enemy pieces (flip allegiance)
- Shield/protection effects

### Step 3.3: Board Manipulation Powers (Next 10 powers)
**Power Group**: Advanced terrain modification
- Shuffle board sections
- Create barriers/walls
- Modify multiple columns
- Reset terrain areas

### Step 3.4: Meta Powers (Remaining powers)
**Power Group**: Powers that affect other powers
- Steal opponent powers
- Copy own powers
- Nullify enemy powers
- Power multiplication

**Implementation Strategy for Each Group**:
1. Design and implement 2-3 powers at a time
2. Test thoroughly before moving to next powers
3. Balance power effects and spawn rates
4. Ensure no game-breaking combinations

---

## PHASE 4: POLISH & MULTIPLAYER
**Goal**: Production-ready game with networking

### Step 4.1: Game Polish
- Improved graphics and animations
- Sound effects and music
- Better UI/UX design
- Game configuration options

### Step 4.2: Networking Implementation
- Client-server architecture
- Turn synchronization
- Reconnection handling
- Spectator mode

---

## CRITICAL RULES FOR IMPLEMENTATION

### Rule 1: Phase Completion
**NEVER move to next phase until current phase is 100% complete**
- All acceptance criteria must be met
- Manual testing must pass
- Code must be clean and documented

### Rule 2: Incremental Development
**Add one feature at a time**
- Implement → Test → Commit → Repeat
- Each commit should represent working functionality
- Fix bugs immediately, don't accumulate technical debt

### Rule 3: Power-Up Implementation Order
**Always implement simpler powers first**
- Start with powers that modify single values
- Move to powers affecting multiple entities
- Save complex interaction powers for last

### Rule 4: Testing Requirements
**Test every feature thoroughly**
- Unit tests for core logic
- Manual testing for gameplay
- Performance testing with multiple powers active
- Edge case testing (empty board, full inventory, etc.)

---

## DEVELOPMENT COMMANDS & WORKFLOW

### Initial Setup
```bash
# Project creation
cargo new quadradius --bin
cd quadradius

# Add dependencies
cargo add bevy
cargo add bevy_inspector_egui  # For debugging
cargo add rand                 # For power orb spawning
cargo add serde               # For game state serialization
```

### Development Workflow
```bash
# Run with debug info
cargo run --features bevy/debug

# Run tests
cargo test

# Check for issues
cargo clippy
cargo fmt
```

### Debugging Setup
Add to main.rs for development:
```rust
use bevy::diagnostic::{FrameTimeDiagnosticsPlugin, LogDiagnosticsPlugin};
use bevy_inspector_egui::quick::WorldInspectorPlugin;

app.add_plugins((
    FrameTimeDiagnosticsPlugin::default(),
    LogDiagnosticsPlugin::default(),
    WorldInspectorPlugin::new(),
));
```

---

## SUCCESS CHECKPOINTS

### Phase 1 Success Criteria
- [ ] Game runs without crashes
- [ ] Complete games can be played start to finish
- [ ] All movement rules work correctly
- [ ] Win conditions are properly detected
- [ ] Code is well-organized and documented

### Phase 2 Success Criteria
- [ ] Power orbs spawn and can be collected
- [ ] 5 different powers work as intended
- [ ] No regressions in basic gameplay
- [ ] Power effects are visually clear
- [ ] Game remains balanced and fun

### Phase 3 Success Criteria
- [ ] Majority of original powers implemented
- [ ] Complex power interactions work correctly
- [ ] Game performance remains good
- [ ] Power balance is maintained
- [ ] Comprehensive testing completed

### Final Release Criteria
- [ ] All features from original game recreated
- [ ] Multiplayer networking functional
- [ ] Polished user experience
- [ ] Stable performance under all conditions
- [ ] Ready for public release

---

## EMERGENCY PROCEDURES

### If Stuck on Complex Feature
1. Break it down into smaller pieces
2. Implement the simplest version first
3. Ask for help with specific technical problems
4. Consider temporary workarounds to maintain progress

### If Performance Issues Arise
1. Profile using Bevy's diagnostic tools
2. Optimize the specific bottleneck found
3. Consider reducing visual effects temporarily
4. Focus on gameplay over visual polish

### If Code Becomes Messy
1. Stop adding features immediately
2. Refactor current code before continuing
3. Add missing tests and documentation
4. Clean up before moving to next phase

---

## FINAL NOTES

This plan prioritizes **working gameplay over perfect code**. The goal is to recreate the fun and strategic depth of the original Quadradius while building a maintainable codebase.

Remember: A simple game that works completely is infinitely better than a complex game that's half-finished. Focus on completing each phase fully before moving forward.

The original game was beloved for its strategic depth and chaotic power interactions. Keep this experience as the north star throughout development.
