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

### Phase 1: Core Foundation (MVP)
**Priority**: Critical
**Timeline**: 2-3 weeks

**Deliverables**:
1. Basic 10x8 board rendering with isometric view in Bevy
2. Piece placement and basic movement (horizontal/vertical, one square)
3. Turn-based gameplay loop
4. Simple terrain height visualization
5. Win condition detection (eliminate all opponent pieces)

**Technical Tasks**:
- Set up Bevy project structure
- Implement board rendering system
- Create piece entities and movement validation
- Implement basic game state management
- Add simple UI for turn indication

### Phase 2: Power-Up Foundation
**Priority**: High
**Timeline**: 2-3 weeks

**Deliverables**:
1. Power orb spawning system
2. Core 10-15 power-ups implemented
3. Power activation UI
4. Terrain manipulation (raise/lower)

**Technical Tasks**:
- Implement random orb spawning algorithm
- Create power-up activation system
- Add terrain height modification mechanics
- Implement basic power-up effects

### Phase 3: Complete Power-Up System
**Priority**: Medium
**Timeline**: 3-4 weeks

**Deliverables**:
1. All ~70 power-ups implemented
2. Complex interactions between powers
3. Power balancing and testing
4. Advanced UI for power management

### Phase 4: Polish and Multiplayer
**Priority**: Medium
**Timeline**: 2-3 weeks

**Deliverables**:
1. Network multiplayer support
2. Improved graphics and animations
3. Sound effects and music
4. Game persistence and replay system

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
