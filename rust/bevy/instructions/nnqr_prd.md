# Quadradius Rust/Bevy Implementation
## Project Requirements Document

### Project Overview
Implement a faithful recreation of the classic Flash game Quadradius using Rust and the Bevy game engine. Quadradius is described as "checkers on steroids" - a turn-based strategy game for two players featuring checker-like movement enhanced with approximately 70 different power-ups that dramatically alter gameplay.

### Core Technology Stack
- **Language**: Rust
- **Game Engine**: Bevy (latest stable version)
- **Rendering**: Bevy's built-in 2D renderer
- **Networking**: Bevy networking plugins for multiplayer (future phase)
- **State Management**: Bevy's state system

---

## Game Mechanics Specification

### Board Structure
- **Grid Size**: 10x8 board (80 squares total) - 10 columns by 8 rows
- **Terrain Heights**: Multi-level terrain system where tiles can be raised or lowered
- **Movement Rules**: 
  - Pieces can move down any number of levels
  - Pieces can only move up one level at a time
  - Movement is one square vertically or horizontally (like simplified checkers)

### Player Setup
- **Pieces per Player**: 20 pieces each
- **Starting Positions**: Blue player occupies bottom two rows, Teal player occupies top two rows
- **Initial Setup**: 40 pieces total on board, 40 empty squares in middle for gameplay
- **Piece Types**: Basic checker-like pieces that can acquire powers

### Power-Up System
- **Total Power-ups**: Approximately 70-86 different power-ups
- **Spawn Mechanism**: Power-ups appear as metallic dome orbs on random empty squares
- **Spawn Frequency**: Approximately every 7 rounds, ~80 orbs total per game
- **Territory Control**: More controlled territory = more orbs spawn on your side
- **Usage**: Power-ups must be activated before moving during turn
- **Storage**: Each piece maintains its own power-up inventory

#### Power-Up Categories (70-86 total powers):

**Movement Powers**:
- Move Diagonal: Enables diagonal movement
- Move Again: Grants additional movement
- Relocate: Random teleportation
- Invisible: Stealth capabilities

**Offensive Powers (~1/3 of all powers)**:
- Destroy Column/Row: Eliminates entire lines of pieces
- Bombs: Drops 16 random bombs destroying pieces and depressing terrain
- Snake Tunneling: Sends destructive snake across board while raising terrain 2 levels
- Acid: Creates permanent holes in the board

**Terrain Manipulation**:
- Dredge Column: Sinks enemy pieces 2 levels while raising friendly pieces 2 levels
- Lower/Raise Tile: Modifies individual tile heights
- Scramble Column: Major terrain alterations affecting multiple columns

**Strategic Powers**:
- Jump Proof: Permanent immunity to capture
- Recruit/Recruit Radial: Converts enemy pieces
- Multiply: Generates new pieces
- Teach Row/Radial: Shares powers with other pieces
- Grow Quadradius: Massively extends kill power range (most powerful)

---

## Technical Architecture Requirements

### Core Systems

#### 1. Board System
```rust
// Core data structures needed:
struct Board {
    grid: [[Tile; 10]; 8],  // 10 columns, 8 rows
    width: usize,  // 10
    height: usize, // 8
}

struct Tile {
    height: i32,          // Terrain elevation
    piece: Option<Piece>,  // Occupying piece
    power_orb: Option<PowerOrb>, // Available power-up
    coordinates: (usize, usize),
}
```

#### 2. Piece System
```rust
struct Piece {
    id: PieceId,
    player: PlayerId,
    position: (usize, usize),
    powers: Vec<PowerUp>,
    is_visible: bool,     // For invisibility power
}
```

#### 3. Power-Up System
```rust
enum PowerType {
    MoveDiagonal,
    RaiseColumn,
    LowerColumn,
    DestroyColumn,
    Multiply,
    Invisible,
    Recruit,
    SmartBomb,
    Teleport,
    StealPower,
    // ... (expand to ~70 total)
}

struct PowerUp {
    power_type: PowerType,
    uses_remaining: u32,
    target_type: TargetType, // Self, Enemy, Tile, etc.
}
```

#### 4. Turn Management System
```rust
struct GameState {
    current_player: PlayerId,
    phase: TurnPhase,     // PowerPhase, MovePhase, EndPhase
    selected_piece: Option<PieceId>,
    available_actions: Vec<Action>,
}

enum TurnPhase {
    PowerActivation,  // Must activate powers before moving
    Movement,         // Move one piece one space
    PowerCollection,  // Automatically collect orb on destination
}
```

#### 5. Networking Architecture (Future Phase)
- Client-server architecture for multiplayer
- Turn validation on server
- State synchronization between clients
- Reconnection handling

---

## Implementation Phases

### Phase 1: Foundation & Power Integration
**Priority**: Critical
**Timeline**: 2 weeks

**Deliverables**:
1. Fix power integration patterns (55+ powers currently broken)
2. Movement power functionality (teleport, jump, knight, etc.)
3. Terrain power functionality (raise/lower columns, areas)
4. Duration-based effect processing (freeze, poison, shields)

**Technical Tasks**:
- Connect power activation to movement validation
- Integrate terrain system with board manipulation powers
- Implement turn-based effect processing
- Establish patterns for all subsequent phases

### Phase 2: Combat Powers & Effects
**Priority**: High
**Timeline**: 2 weeks

**Deliverables**:
1. Duration-based effect framework
2. Combat power implementation (shield, invisible, recruit)
3. Protection and stealth mechanics
4. Visual effect integration

**Technical Tasks**:
- Implement PowerEffect component system
- Create turn-based effect processing
- Add combat system integration
- Develop visual feedback systems

### Phase 3: Board Manipulation & Terrain
**Priority**: High
**Timeline**: 2 weeks

**Deliverables**:
1. Area targeting and selection system
2. Terrain modification powers (raise/lower areas)
3. Wall and obstacle creation
4. Board transformation capabilities

**Technical Tasks**:
- Implement 3x3 area selection UI
- Create terrain modification framework
- Add wall and obstacle systems
- Develop board transformation powers

### Phase 4: Meta Powers & Complex Interactions
**Priority**: Medium
**Timeline**: 2 weeks

**Deliverables**:
1. Power interaction framework
2. Meta power implementation (steal, copy, nullify)
3. Complex strategic combinations
4. Priority resolution system

**Technical Tasks**:
- Create power registry and interaction system
- Implement power manipulation mechanics
- Add chain reaction prevention
- Develop balance validation tools

### Phase 5: Polish & Release Preparation
**Priority**: Medium
**Timeline**: 3 weeks

**Deliverables**:
1. Performance optimization
2. Visual and audio polish
3. Balance refinement
4. User experience enhancement

**Technical Tasks**:
- Optimize power system performance
- Enhance visual effects and animations
- Conduct comprehensive balance testing
- Improve UI/UX and accessibility

### Phase 6: Review & Code Quality
**Priority**: Medium
**Timeline**: 2 weeks

**Deliverables**:
1. Code quality review and cleanup
2. Technical debt resolution
3. Comprehensive testing (>98% coverage)
4. Documentation completion

**Technical Tasks**:
- Conduct architecture review
- Refactor and optimize code
- Complete test suite coverage
- Finalize documentation

### Phase 7: Web Deployment & WASM
**Priority**: Medium
**Timeline**: 3 weeks

**Deliverables**:
1. WebAssembly compilation and optimization
2. Browser compatibility and performance
3. Web multiplayer implementation
4. Progressive web app features

**Technical Tasks**:
- Configure WASM build pipeline
- Optimize for browser performance
- Implement web networking
- Add PWA capabilities

### Phase 8: Final Testing & Validation
**Priority**: High
**Timeline**: 3 weeks

**Deliverables**:
1. Comprehensive game testing (all 71 powers)
2. Cross-platform validation
3. Community beta testing
4. Release preparation

**Technical Tasks**:
- Test all power combinations
- Validate cross-platform compatibility
- Conduct multiplayer stress testing
- Prepare launch infrastructure

---

## Bevy-Specific Implementation Details

### Entity Component System Design

#### Components
```rust
#[derive(Component)]
struct BoardPosition(usize, usize);

#[derive(Component)]
struct TerrainHeight(i32);

#[derive(Component)]
struct GamePiece {
    player: PlayerId,
    powers: Vec<PowerUp>,
}

#[derive(Component)]
struct PowerOrb {
    power_type: PowerType,
    spawn_turn: u32,
}

#[derive(Component)]
struct Selectable;

#[derive(Component)]
struct Highlighted;
```

#### Systems
```rust
// Core systems to implement:
fn board_setup_system()
fn piece_movement_system()
fn power_activation_system()
fn orb_spawning_system()
fn turn_management_system()
fn win_condition_system()
fn input_handling_system()
fn ui_update_system()
```

### Resource Management
```rust
#[derive(Resource)]
struct GameConfig {
    board_size: (usize, usize),
    max_power_orbs: usize,
    orb_spawn_rate: f32,
}

#[derive(Resource)]
struct PowerUpDatabase {
    definitions: HashMap<PowerType, PowerDefinition>,
}
```

---

## UI/UX Requirements

### Game Interface
1. **Main Game View**: 3D isometric view of the 10x8 board with height variations
2. **Height Visualization**: Color gradients showing elevation (whiter = higher)
3. **Power Orbs**: Small metallic domes with futuristic appearance
2. **Piece Selection**: Click to select pieces, highlight valid moves
3. **Power Activation**: UI panel showing available powers for selected piece
4. **Turn Indicator**: Clear indication of whose turn it is
5. **Game Status**: Score, remaining pieces, game phase

### Visual Design
1. **Board Rendering**: Isometric 3D view with clear height differences
2. **Piece Visualization**: Circular disc pieces (Blue vs Teal) with power modifications
3. **Power Orbs**: Metallic dome orbs with futuristic sci-fi aesthetic
4. **Terrain Heights**: Color-coded elevation with gradient-based visualization
5. **Animations**: Smooth piece movement, complex cascade effects for area powers
6. **Art Direction**: Clean geometric design with metallic textures

---

## Testing Strategy

### Unit Tests
- Board state management
- Movement validation
- Power-up effect calculations
- Win conditions

### Integration Tests
- Complete turn cycles
- Power-up interactions
- Game state persistence

### Gameplay Testing
- Balance testing for power-ups
- User interface usability
- Performance with full power-up system

---

## Performance Considerations

### Optimization Targets
- **Frame Rate**: Maintain 60 FPS during gameplay
- **Memory Usage**: Efficient entity management for pieces and orbs
- **Network Latency**: < 100ms for multiplayer actions
- **Load Times**: < 3 seconds for game initialization

### Known Challenges
1. **Power-Up Complexity**: Managing interactions between 70+ different powers
2. **State Synchronization**: Keeping multiplayer games in sync
3. **Visual Clarity**: Making terrain heights and power effects clear
4. **Balance**: Ensuring no single power-up is overpowered

---

## Success Criteria

### Minimum Viable Product (MVP)
- [ ] Functional 10x8 isometric board with piece movement
- [ ] Basic power-up system (10+ powers working)
- [ ] Turn-based gameplay for local play
- [ ] Win condition detection
- [ ] Terrain height system

### Full Release
- [ ] All ~70-86 power-ups implemented and balanced
- [ ] Multiplayer networking functional
- [ ] Polished UI/UX matching original game feel
- [ ] Performance targets met
- [ ] Comprehensive testing completed

---

## Development Notes for Claude Code

### Key Implementation Priorities
1. Start with isometric 10x8 board and basic movement - get the foundation solid
2. Implement power-up system incrementally, testing each power thoroughly
3. Focus on clear, modular code structure for the complex power interactions
4. Use Bevy's ECS effectively - avoid putting too much logic in single systems
5. Plan for networking from the start, even if implementing it later

### Rust/Bevy Best Practices
- Use strong typing for game states and actions
- Leverage Bevy's query system for efficient game logic
- Implement proper error handling for all game actions
- Use Bevy's asset system for loading power-up definitions
- Consider using Bevy's reflection system for serialization

This document should provide sufficient detail for implementing a faithful Quadradius recreation while leaving room for creative technical decisions in the implementation details.
