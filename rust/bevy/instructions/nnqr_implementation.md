# Quadradius Implementation Guide
**Current Status: Phase 4+ Complete - Advanced 3D Game with 38+ Powers**

## PROJECT STATUS OVERVIEW

### ✅ COMPLETED PHASES
- **Phase 1 Foundation**: EXCEEDED - 10x8 isometric board with advanced 3D rendering
- **Phase 2 Power Foundation**: EXCEEDED - 38+ powers implemented with sophisticated UI
- **Phase 3 Advanced Features**: EXCEEDED - PBR materials, lighting, comprehensive testing
- **Phase 4 Polish & Deployment**: COMPLETED - Cross-platform builds, Windows release v0.2.0

### 🎯 CURRENT FOCUS: Power System Completion
**Target**: Complete remaining 12+ powers to reach full game recreation
**Priority**: Fix broken power implementations and complete movement powers

---

## CURRENT IMPLEMENTATION GUIDE
*For developers working on the existing advanced codebase*

## PHASE 1: FOUNDATION - Historical Reference (COMPLETED)

### STEP 1: Project Setup (30 minutes)

#### 1.1 Create New Rust Project
```bash
# Create the project
cargo new quadradius --bin
cd quadradius

# Add required dependencies
cargo add bevy --features default
cargo add rand
```

#### 1.2 Create Basic Project Structure
```bash
# Create directory structure
mkdir -p src/{systems,components,resources,events}
touch src/systems/mod.rs
touch src/components/mod.rs
touch src/resources/mod.rs
touch src/events/mod.rs
```

#### 1.3 Setup Main Application File
**File: `src/main.rs`**
```rust
use bevy::prelude::*;

fn main() {
    App::new()
        .add_plugins(DefaultPlugins.set(WindowPlugin {
            primary_window: Some(Window {
                title: "Quadradius".into(),
                resolution: (800.0, 600.0).into(),
                ..default()
            }),
            ..default()
        }))
        .add_systems(Startup, setup)
        .run();
}

fn setup(mut commands: Commands) {
    // Spawn camera
    commands.spawn(Camera2dBundle::default());
    
    println!("Quadradius started!");
}
```

#### 1.4 Test Basic Setup
```bash
cargo run
```
**Expected Result**: Window opens with "Quadradius started!" in console

---

### STEP 2: Basic Board Rendering (2 hours)

#### 2.1 Create Board Components
**File: `src/components/board.rs`**
```rust
use bevy::prelude::*;

#[derive(Component)]
pub struct BoardTile {
    pub coordinates: (u8, u8),
    pub height: i8,
}

#[derive(Component)]
pub struct Board;

pub const BOARD_WIDTH: u8 = 10;
pub const BOARD_HEIGHT: u8 = 8;
pub const TILE_SIZE: f32 = 64.0;
```

**File: `src/components/mod.rs`**
```rust
pub mod board;
pub use board::*;
```

#### 2.2 Create Board System
**File: `src/systems/board.rs`**
```rust
use bevy::prelude::*;
use crate::components::*;

pub fn setup_board(mut commands: Commands) {
    // Create board entity
    let board_entity = commands.spawn((Board, Transform::from_xyz(0.0, 0.0, 0.0))).id();
    
    // Create tiles for 10x8 board
    for x in 0..BOARD_WIDTH {
        for y in 0..BOARD_HEIGHT {
            let height = if (x + y) % 3 == 0 { 1 } else { 0 }; // Varied heights for testing
            
            let tile_x = (x as f32 - BOARD_WIDTH as f32 / 2.0 + 0.5) * TILE_SIZE;
            let tile_y = (y as f32 - BOARD_HEIGHT as f32 / 2.0 + 0.5) * TILE_SIZE;
            
            let color = match height {
                0 => Color::srgb(0.3, 0.7, 0.3), // Green for low
                1 => Color::srgb(0.7, 0.7, 0.3), // Yellow for medium
                _ => Color::srgb(0.7, 0.3, 0.3), // Red for high
            };
            
            commands.spawn((
                BoardTile {
                    coordinates: (x, y),
                    height,
                },
                SpriteBundle {
                    sprite: Sprite {
                        color,
                        custom_size: Some(Vec2::splat(TILE_SIZE - 2.0)), // Small gap between tiles
                        ..default()
                    },
                    transform: Transform::from_xyz(tile_x, tile_y, 0.0),
                    ..default()
                },
            ));
        }
    }
}
```

**File: `src/systems/mod.rs`**
```rust
pub mod board;
pub use board::*;
```

#### 2.3 Update Main to Use Board System
**File: `src/main.rs`**
```rust
use bevy::prelude::*;

mod components;
mod systems;

use systems::*;

fn main() {
    App::new()
        .add_plugins(DefaultPlugins.set(WindowPlugin {
            primary_window: Some(Window {
                title: "Quadradius".into(),
                resolution: (800.0, 600.0).into(),
                ..default()
            }),
            ..default()
        }))
        .add_systems(Startup, (setup_camera, setup_board))
        .run();
}

fn setup_camera(mut commands: Commands) {
    commands.spawn(Camera2dBundle::default());
}
```

#### 2.4 Test Board Rendering
```bash
cargo run
```
**Expected Result**: 10x8 grid of colored squares with different heights visible

---

## CURRENT DEVELOPMENT PRIORITIES

### IMMEDIATE TASKS (Ready for Implementation)

#### Fix Broken Power Implementations
1. **Freeze Power** - Framework exists, needs implementation
2. **Assassin Power** - Framework exists, needs proper integration  
3. **MoveTwice Power** - Currently only prints message, needs actual functionality

#### Complete Movement Powers (5 Remaining)
1. **Swap** - Swap positions with another piece
2. **Push** - Push adjacent piece
3. **Pull** - Pull piece towards you
4. **Leap** - Jump to any empty square within 3 tiles
5. **MoveTwice** - Take two moves in one turn (fix existing)

### POWER IMPLEMENTATION WORKFLOW

#### Step 1: Analyze Existing Framework
```bash
# Review current power system
grep -r "PowerType" src/
grep -r "Freeze\|Assassin\|MoveTwice" src/
```

#### Step 2: Implement Missing Components
```rust
// Example: Freeze component
#[derive(Component)]
pub struct Frozen {
    pub remaining_turns: u32,
}

// Add to power effects system
fn apply_freeze_effect(
    mut commands: Commands,
    target_entity: Entity,
    duration: u32,
) {
    commands.entity(target_entity).insert(Frozen {
        remaining_turns: duration,
    });
}
```

#### Step 3: Update Power Activation
```rust
// In power_effects.rs
PowerType::Freeze => {
    if let Some(target) = targeting_system.get_target() {
        apply_freeze_effect(commands, target, 3);
    }
}
```

#### Step 4: Add Turn-Based Processing
```rust
// Process frozen pieces each turn
fn process_frozen_pieces(
    mut commands: Commands,
    mut frozen_query: Query<(Entity, &mut Frozen)>,
) {
    for (entity, mut frozen) in frozen_query.iter_mut() {
        frozen.remaining_turns -= 1;
        if frozen.remaining_turns == 0 {
            commands.entity(entity).remove::<Frozen>();
        }
    }
}
```

#### Step 5: Integrate with Movement System
```rust
// Prevent movement of frozen pieces
fn movement_validation(
    piece_query: Query<&Frozen>,
    piece_entity: Entity,
) -> bool {
    !piece_query.contains(piece_entity)
}
```

### TESTING WORKFLOW

#### Automated Testing
```bash
# Run power-specific tests
cargo test power_tests
cargo test freeze_power
cargo test movement_powers
```

#### Manual Testing
```bash
# Use test script for power validation
./test_powers.sh
# Test specific power
cargo run --bin power_test -- --power Freeze
```

---

## HISTORICAL IMPLEMENTATION STEPS (COMPLETED)
*These phases are complete but documented for reference*

---

### STEP 3: Add Player Pieces (1.5 hours)

#### 3.1 Create Piece Components
**File: `src/components/piece.rs`**
```rust
use bevy::prelude::*;

#[derive(Component, Clone, Copy, PartialEq)]
pub enum Player {
    Player1,
    Player2,
}

#[derive(Component)]
pub struct GamePiece {
    pub player: Player,
    pub board_position: (u8, u8),
}

#[derive(Component)]
pub struct Selected;
```

**Update `src/components/mod.rs`**
```rust
pub mod board;
pub mod piece;

pub use board::*;
pub use piece::*;
```

#### 3.2 Create Piece Setup System
**File: `src/systems/pieces.rs`**
```rust
use bevy::prelude::*;
use crate::components::*;

pub fn setup_pieces(mut commands: Commands) {
    // Player 1 pieces (bottom two rows)
    for y in 0..2 {
        for x in 0..BOARD_SIZE {
            if (x + y) % 2 == 0 { // Checkerboard pattern
                spawn_piece(&mut commands, Player::Player1, (x, y));
            }
        }
    }
    
    // Player 2 pieces (top two rows)
    for y in (BOARD_SIZE-2)..BOARD_SIZE {
        for x in 0..BOARD_SIZE {
            if (x + y) % 2 == 0 { // Checkerboard pattern
                spawn_piece(&mut commands, Player::Player2, (x, y));
            }
        }
    }
}

fn spawn_piece(commands: &mut Commands, player: Player, position: (u8, u8)) {
    let color = match player {
        Player::Player1 => Color::srgb(0.8, 0.2, 0.2), // Red
        Player::Player2 => Color::srgb(0.2, 0.2, 0.8), // Blue
    };
    
    let world_x = (position.0 as f32 - BOARD_SIZE as f32 / 2.0 + 0.5) * TILE_SIZE;
    let world_y = (position.1 as f32 - BOARD_SIZE as f32 / 2.0 + 0.5) * TILE_SIZE;
    
    commands.spawn((
        GamePiece {
            player,
            board_position: position,
        },
        SpriteBundle {
            sprite: Sprite {
                color,
                custom_size: Some(Vec2::splat(TILE_SIZE * 0.8)), // Slightly smaller than tiles
                ..default()
            },
            transform: Transform::from_xyz(world_x, world_y, 1.0), // Above tiles
            ..default()
        },
    ));
}
```

**Update `src/systems/mod.rs`**
```rust
pub mod board;
pub mod pieces;

pub use board::*;
pub use pieces::*;
```

#### 3.3 Update Main to Spawn Pieces
**Update `src/main.rs`**
```rust
.add_systems(Startup, (setup_camera, setup_board, setup_pieces))
```

#### 3.4 Test Piece Rendering
```bash
cargo run
```
**Expected Result**: Red and blue pieces on checkerboard pattern at top and bottom of board

---

### STEP 4: Piece Selection (2 hours)

#### 4.1 Add Game State Resource
**File: `src/resources/game_state.rs`**
```rust
use bevy::prelude::*;
use crate::components::Player;

#[derive(Resource)]
pub struct GameState {
    pub current_player: Player,
    pub selected_piece: Option<Entity>,
}

impl Default for GameState {
    fn default() -> Self {
        Self {
            current_player: Player::Player1,
            selected_piece: None,
        }
    }
}
```

**File: `src/resources/mod.rs`**
```rust
pub mod game_state;
pub use game_state::*;
```

#### 4.2 Create Input System
**File: `src/systems/input.rs`**
```rust
use bevy::prelude::*;
use crate::{components::*, resources::*};

pub fn handle_piece_selection(
    mut commands: Commands,
    mouse_input: Res<ButtonInput<MouseButton>>,
    windows: Query<&Window>,
    camera_q: Query<(&Camera, &GlobalTransform)>,
    mut game_state: ResMut<GameState>,
    mut pieces: Query<(Entity, &GamePiece, &mut Sprite), Without<Selected>>,
    mut selected_pieces: Query<(Entity, &GamePiece, &mut Sprite), With<Selected>>,
) {
    if !mouse_input.just_pressed(MouseButton::Left) {
        return;
    }
    
    let window = windows.single();
    let (camera, camera_transform) = camera_q.single();
    
    if let Some(cursor_pos) = window.cursor_position() {
        if let Some(world_pos) = camera.viewport_to_world_2d(camera_transform, cursor_pos) {
            let board_pos = world_to_board_position(world_pos);
            
            // Deselect currently selected piece
            for (entity, _, mut sprite) in selected_pieces.iter_mut() {
                commands.entity(entity).remove::<Selected>();
                // Reset color based on player
                let piece = pieces.get(entity).unwrap().1;
                sprite.color = match piece.player {
                    Player::Player1 => Color::srgb(0.8, 0.2, 0.2),
                    Player::Player2 => Color::srgb(0.2, 0.2, 0.8),
                };
            }
            game_state.selected_piece = None;
            
            // Try to select piece at clicked position
            for (entity, piece, mut sprite) in pieces.iter_mut() {
                if piece.board_position == board_pos && piece.player == game_state.current_player {
                    commands.entity(entity).insert(Selected);
                    sprite.color = Color::srgb(1.0, 1.0, 0.0); // Yellow for selected
                    game_state.selected_piece = Some(entity);
                    break;
                }
            }
        }
    }
}

fn world_to_board_position(world_pos: Vec2) -> (u8, u8) {
    let x = ((world_pos.x / TILE_SIZE) + BOARD_SIZE as f32 / 2.0 - 0.5) as u8;
    let y = ((world_pos.y / TILE_SIZE) + BOARD_SIZE as f32 / 2.0 - 0.5) as u8;
    (x.min(BOARD_SIZE - 1), y.min(BOARD_SIZE - 1))
}
```

**Update `src/systems/mod.rs`**
```rust
pub mod board;
pub mod pieces;
pub mod input;

pub use board::*;
pub use pieces::*;
pub use input::*;
```

#### 4.3 Update Main to Include Input and Game State
**Update `src/main.rs`**
```rust
use bevy::prelude::*;

mod components;
mod systems;
mod resources;

use systems::*;
use resources::*;

fn main() {
    App::new()
        .add_plugins(DefaultPlugins.set(WindowPlugin {
            primary_window: Some(Window {
                title: "Quadradius".into(),
                resolution: (800.0, 600.0).into(),
                ..default()
            }),
            ..default()
        }))
        .init_resource::<GameState>()
        .add_systems(Startup, (setup_camera, setup_board, setup_pieces))
        .add_systems(Update, handle_piece_selection)
        .run();
}

fn setup_camera(mut commands: Commands) {
    commands.spawn(Camera2dBundle::default());
}
```

#### 4.4 Test Piece Selection
```bash
cargo run
```
**Expected Result**: Clicking on pieces turns them yellow (selected), only current player's pieces can be selected

---

### STEP 5: Movement System (3 hours)

#### 5.1 Add Movement Validation
**File: `src/systems/movement.rs`**
```rust
use bevy::prelude::*;
use crate::{components::*, resources::*};

pub fn handle_piece_movement(
    mut commands: Commands,
    mouse_input: Res<ButtonInput<MouseButton>>,
    windows: Query<&Window>,
    camera_q: Query<(&Camera, &GlobalTransform)>,
    mut game_state: ResMut<GameState>,
    tiles: Query<&BoardTile>,
    mut pieces: Query<(Entity, &mut GamePiece, &mut Transform, &mut Sprite)>,
    selected_pieces: Query<Entity, With<Selected>>,
) {
    if !mouse_input.just_pressed(MouseButton::Right) {
        return;
    }
    
    let Some(selected_entity) = game_state.selected_piece else {
        return;
    };
    
    let window = windows.single();
    let (camera, camera_transform) = camera_q.single();
    
    if let Some(cursor_pos) = window.cursor_position() {
        if let Some(world_pos) = camera.viewport_to_world_2d(camera_transform, cursor_pos) {
            let target_pos = world_to_board_position(world_pos);
            
            if let Ok((_, mut piece, mut transform, mut sprite)) = pieces.get_mut(selected_entity) {
                if is_valid_move(piece.board_position, target_pos, &tiles, &pieces) {
                    // Move the piece
                    piece.board_position = target_pos;
                    let world_pos = board_to_world_position(target_pos);
                    transform.translation = Vec3::new(world_pos.x, world_pos.y, 1.0);
                    
                    // Deselect piece
                    commands.entity(selected_entity).remove::<Selected>();
                    sprite.color = match piece.player {
                        Player::Player1 => Color::srgb(0.8, 0.2, 0.2),
                        Player::Player2 => Color::srgb(0.2, 0.2, 0.8),
                    };
                    game_state.selected_piece = None;
                    
                    // Switch turns
                    game_state.current_player = match game_state.current_player {
                        Player::Player1 => Player::Player2,
                        Player::Player2 => Player::Player1,
                    };
                }
            }
        }
    }
}

fn is_valid_move(
    from: (u8, u8),
    to: (u8, u8),
    tiles: &Query<&BoardTile>,
    pieces: &Query<(Entity, &mut GamePiece, &mut Transform, &mut Sprite)>,
) -> bool {
    // Check bounds
    if to.0 >= BOARD_SIZE || to.1 >= BOARD_SIZE {
        return false;
    }
    
    // Check if target is occupied
    for (_, piece, _, _) in pieces.iter() {
        if piece.board_position == to {
            return false; // Occupied
        }
    }
    
    // Check if move is only horizontal or vertical and distance 1
    let dx = (to.0 as i8 - from.0 as i8).abs();
    let dy = (to.1 as i8 - from.1 as i8).abs();
    
    if (dx == 1 && dy == 0) || (dx == 0 && dy == 1) {
        // Check height restrictions
        let from_height = get_tile_height(from, tiles);
        let to_height = get_tile_height(to, tiles);
        
        // Can move down any levels, up only one level
        return to_height <= from_height + 1;
    }
    
    false
}

fn get_tile_height(pos: (u8, u8), tiles: &Query<&BoardTile>) -> i8 {
    for tile in tiles.iter() {
        if tile.coordinates == pos {
            return tile.height;
        }
    }
    0 // Default height if not found
}

fn world_to_board_position(world_pos: Vec2) -> (u8, u8) {
    let x = ((world_pos.x / TILE_SIZE) + BOARD_SIZE as f32 / 2.0 - 0.5) as u8;
    let y = ((world_pos.y / TILE_SIZE) + BOARD_SIZE as f32 / 2.0 - 0.5) as u8;
    (x.min(BOARD_SIZE - 1), y.min(BOARD_SIZE - 1))
}

fn board_to_world_position(board_pos: (u8, u8)) -> Vec2 {
    let x = (board_pos.0 as f32 - BOARD_SIZE as f32 / 2.0 + 0.5) * TILE_SIZE;
    let y = (board_pos.1 as f32 - BOARD_SIZE as f32 / 2.0 + 0.5) * TILE_SIZE;
    Vec2::new(x, y)
}
```

#### 5.2 Update Systems Module
**Update `src/systems/mod.rs`**
```rust
pub mod board;
pub mod pieces;
pub mod input;
pub mod movement;

pub use board::*;
pub use pieces::*;
pub use input::*;
pub use movement::*;
```

#### 5.3 Update Main to Include Movement
**Update `src/main.rs`**
```rust
.add_systems(Update, (handle_piece_selection, handle_piece_movement))
```

#### 5.4 Test Movement
```bash
cargo run
```
**Expected Result**: 
- Left click selects pieces
- Right click moves selected piece (if valid)
- Turns alternate between players
- Movement follows height and distance rules

---

### STEP 6: Add Piece Capture and Win Conditions (2 hours)

#### 6.1 Update Movement System for Capture
**Update `src/systems/movement.rs`** - Replace the `is_valid_move` function and add capture logic:

```rust
// Update the handle_piece_movement function to include capture
pub fn handle_piece_movement(
    mut commands: Commands,
    mouse_input: Res<ButtonInput<MouseButton>>,
    windows: Query<&Window>,
    camera_q: Query<(&Camera, &GlobalTransform)>,
    mut game_state: ResMut<GameState>,
    tiles: Query<&BoardTile>,
    mut pieces: Query<(Entity, &mut GamePiece, &mut Transform, &mut Sprite)>,
    selected_pieces: Query<Entity, With<Selected>>,
) {
    if !mouse_input.just_pressed(MouseButton::Right) {
        return;
    }
    
    let Some(selected_entity) = game_state.selected_piece else {
        return;
    };
    
    let window = windows.single();
    let (camera, camera_transform) = camera_q.single();
    
    if let Some(cursor_pos) = window.cursor_position() {
        if let Some(world_pos) = camera.viewport_to_world_2d(camera_transform, cursor_pos) {
            let target_pos = world_to_board_position(world_pos);
            
            if let Ok((_, mut piece, mut transform, mut sprite)) = pieces.get_mut(selected_entity) {
                let current_player = piece.player;
                
                if is_valid_move(piece.board_position, target_pos, &tiles, &pieces, current_player) {
                    // Check for capture
                    for (other_entity, other_piece, _, _) in pieces.iter() {
                        if other_entity != selected_entity && 
                           other_piece.board_position == target_pos &&
                           other_piece.player != current_player {
                            // Capture the piece
                            commands.entity(other_entity).despawn();
                            break;
                        }
                    }
                    
                    // Move the piece
                    piece.board_position = target_pos;
                    let world_pos = board_to_world_position(target_pos);
                    transform.translation = Vec3::new(world_pos.x, world_pos.y, 1.0);
                    
                    // Deselect piece
                    commands.entity(selected_entity).remove::<Selected>();
                    sprite.color = match piece.player {
                        Player::Player1 => Color::srgb(0.8, 0.2, 0.2),
                        Player::Player2 => Color::srgb(0.2, 0.2, 0.8),
                    };
                    game_state.selected_piece = None;
                    
                    // Switch turns
                    game_state.current_player = match game_state.current_player {
                        Player::Player1 => Player::Player2,
                        Player::Player2 => Player::Player1,
                    };
                }
            }
        }
    }
}

fn is_valid_move(
    from: (u8, u8),
    to: (u8, u8),
    tiles: &Query<&BoardTile>,
    pieces: &Query<(Entity, &mut GamePiece, &mut Transform, &mut Sprite)>,
    current_player: Player,
) -> bool {
    // Check bounds
    if to.0 >= BOARD_SIZE || to.1 >= BOARD_SIZE {
        return false;
    }
    
    // Check if target is occupied by friendly piece
    for (_, piece, _, _) in pieces.iter() {
        if piece.board_position == to && piece.player == current_player {
            return false; // Can't capture own piece
        }
    }
    
    // Check if move is only horizontal or vertical and distance 1
    let dx = (to.0 as i8 - from.0 as i8).abs();
    let dy = (to.1 as i8 - from.1 as i8).abs();
    
    if (dx == 1 && dy == 0) || (dx == 0 && dy == 1) {
        // Check height restrictions
        let from_height = get_tile_height(from, tiles);
        let to_height = get_tile_height(to, tiles);
        
        // Can move down any levels, up only one level
        return to_height <= from_height + 1;
    }
    
    false
}
```

#### 6.2 Add Win Condition System
**File: `src/systems/win_condition.rs`**
```rust
use bevy::prelude::*;
use crate::{components::*, resources::*};

#[derive(Resource)]
pub struct GameResult {
    pub winner: Option<Player>,
    pub game_over: bool,
}

impl Default for GameResult {
    fn default() -> Self {
        Self {
            winner: None,
            game_over: false,
        }
    }
}

pub fn check_win_condition(
    pieces: Query<&GamePiece>,
    mut game_result: ResMut<GameResult>,
) {
    if game_result.game_over {
        return;
    }
    
    let mut player1_count = 0;
    let mut player2_count = 0;
    
    for piece in pieces.iter() {
        match piece.player {
            Player::Player1 => player1_count += 1,
            Player::Player2 => player2_count += 1,
        }
    }
    
    if player1_count == 0 {
        game_result.winner = Some(Player::Player2);
        game_result.game_over = true;
        println!("Player 2 wins!");
    } else if player2_count == 0 {
        game_result.winner = Some(Player::Player1);
        game_result.game_over = true;
        println!("Player 1 wins!");
    }
}
```

#### 6.3 Update Resources Module
**Update `src/resources/mod.rs`**
```rust
pub mod game_state;
pub use game_state::*;

// Re-export from win_condition system
pub use crate::systems::win_condition::GameResult;
```

#### 6.4 Update Systems Module
**Update `src/systems/mod.rs`**
```rust
pub mod board;
pub mod pieces;
pub mod input;
pub mod movement;
pub mod win_condition;

pub use board::*;
pub use pieces::*;
pub use input::*;
pub use movement::*;
pub use win_condition::*;
```

#### 6.5 Update Main Application
**Update `src/main.rs`**
```rust
.init_resource::<GameState>()
.init_resource::<GameResult>()
.add_systems(Startup, (setup_camera, setup_board, setup_pieces))
.add_systems(Update, (
    handle_piece_selection, 
    handle_piece_movement, 
    check_win_condition
))
```

#### 6.6 Test Complete Game
```bash
cargo run
```
**Expected Result**: 
- Pieces can capture enemy pieces
- Game detects when all pieces of one player are eliminated
- Win message appears in console

---

## PHASE 1 COMPLETION CHECKLIST

Before proceeding to Phase 2, verify ALL of these work:

### Basic Functionality
- [ ] Game window opens and displays properly
- [ ] 8x8 board renders with varied terrain heights
- [ ] Pieces appear in correct starting positions
- [ ] Piece selection works (left click)
- [ ] Only current player can select their pieces
- [ ] Selected pieces are visually highlighted

### Movement System  
- [ ] Pieces move with right click
- [ ] Movement restricted to horizontal/vertical, one square
- [ ] Height restrictions work (down any, up one level max)
- [ ] Invalid moves are blocked
- [ ] Turns alternate automatically after valid moves

### Game Rules
- [ ] Pieces capture enemies by landing on them
- [ ] Captured pieces are removed from board
- [ ] Win condition detected when all enemy pieces eliminated
- [ ] Game announces winner

### Code Quality
- [ ] No compiler warnings
- [ ] Code is organized in modules
- [ ] No crashes during normal gameplay
- [ ] Performance is smooth (60 FPS)

### Manual Testing
- [ ] Can complete full game from start to finish
- [ ] All edge cases handled (board boundaries, invalid clicks)
- [ ] Game state remains consistent throughout

---

## NEXT STEPS

**ONLY after Phase 1 is 100% complete:**

1. **Phase 2 Setup**: Begin implementing power orb system
2. **First Power-Up**: Add "Move Diagonal" power
3. **Expand Gradually**: Add remaining 4 basic powers one at a time

**DO NOT PROCEED** to power-ups until Phase 1 passes all tests above.

---

## TROUBLESHOOTING

### Common Issues and Solutions

**Issue**: Pieces don't appear
- Check piece spawning coordinates
- Verify sprite rendering layer (z-index)
- Ensure camera is positioned correctly

**Issue**: Movement doesn't work
- Verify mouse coordinate conversion
- Check board position calculations
- Debug print clicked positions

**Issue**: Game crashes
- Add error handling to mouse input
- Check for None/unwrap panics
- Validate array bounds access

**Issue**: Performance problems
- Profile with `cargo run --release`
- Check for excessive system queries
- Optimize sprite rendering if needed
