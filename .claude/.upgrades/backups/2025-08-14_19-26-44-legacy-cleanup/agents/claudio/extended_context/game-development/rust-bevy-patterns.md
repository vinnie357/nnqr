# Rust/Bevy Game Development Patterns for Quadradius

## ECS Architecture Patterns for Turn-Based Strategy Games

### Component Design Patterns
```rust
// Game State Components
#[derive(Component)]
struct GamePiece {
    player: Player,
    piece_type: PieceType,
    position: BoardPosition,
}

#[derive(Component)]
struct PowerInventory {
    powers: Vec<PowerType>,
    active_effects: Vec<ActiveEffect>,
}

#[derive(Component)]
struct BoardTile {
    height: i32,
    tile_type: TileType,
    occupied_by: Option<Entity>,
}

// Visual Components
#[derive(Component)]
struct IsometricPosition {
    x: f32,
    y: f32,
    z: f32,
}

#[derive(Component)]
struct DepthSortable {
    layer: u8,
    sub_layer: f32,
}
```

### System Organization Patterns
```rust
// Turn Management System Set
#[derive(SystemSet, Debug, Hash, PartialEq, Eq, Clone)]
enum GameplaySet {
    Input,
    Logic,
    Effects,
    Animation,
    Rendering,
}

// System Implementation Pattern
fn power_effect_system(
    mut commands: Commands,
    mut pieces: Query<(&mut GamePiece, &mut PowerInventory)>,
    mut game_state: ResMut<GameState>,
    time: Res<Time>,
) {
    // Process turn-based effects
    for (mut piece, mut inventory) in pieces.iter_mut() {
        // Effect processing logic
    }
}
```

### Resource Management for Game State
```rust
#[derive(Resource)]
struct GameState {
    current_player: Player,
    turn_number: u32,
    phase: GamePhase,
    selected_piece: Option<Entity>,
}

#[derive(Resource)]
struct PowerRegistry {
    power_definitions: HashMap<PowerType, PowerDefinition>,
    effect_handlers: HashMap<EffectType, Box<dyn EffectHandler>>,
}

#[derive(Resource)]
struct BoardState {
    tiles: [[TileData; 8]; 10], // 10x8 board
    height_map: [[i32; 8]; 10],
}
```

## Power System Implementation Patterns

### Power Effect Framework
```rust
// Power Effect Trait
trait PowerEffect {
    fn apply(&self, target: Entity, world: &mut World) -> Result<(), PowerError>;
    fn can_target(&self, source: Entity, target: Entity, world: &World) -> bool;
    fn get_valid_targets(&self, source: Entity, world: &World) -> Vec<Entity>;
}

// Duration-Based Effects
#[derive(Component)]
struct DurationEffect {
    effect_type: EffectType,
    remaining_turns: u32,
    intensity: f32,
}

// Power Activation System
fn power_activation_system(
    mut commands: Commands,
    input: Res<Input<MouseButton>>,
    selected_piece: Query<&PowerInventory, With<SelectedPiece>>,
    mut game_state: ResMut<GameState>,
) {
    if input.just_pressed(MouseButton::Right) {
        // Power activation logic
    }
}
```

### Targeting System Patterns
```rust
#[derive(Component)]
struct TargetingMode {
    power: PowerType,
    valid_targets: Vec<Entity>,
    selection_area: TargetArea,
}

enum TargetArea {
    Single(BoardPosition),
    Area { center: BoardPosition, radius: u32 },
    Line { start: BoardPosition, end: BoardPosition },
    Column(u32),
    Row(u32),
}

// Area Targeting System
fn area_targeting_system(
    mut commands: Commands,
    input: Res<Input<MouseButton>>,
    cursor: Res<CursorWorldPosition>,
    targeting: Query<&TargetingMode>,
) {
    // Implement area selection logic
}
```

## 3D Isometric Rendering Patterns

### Camera and Coordinate Systems
```rust
fn setup_isometric_camera(mut commands: Commands) {
    commands.spawn((
        Camera3dBundle {
            transform: Transform::from_xyz(10.0, 10.0, 10.0)
                .looking_at(Vec3::ZERO, Vec3::Y),
            projection: Projection::Orthographic(OrthographicProjection {
                scaling_mode: ScalingMode::FixedVertical { viewport_height: 8.0 },
                ..default()
            }),
            ..default()
        },
        IsometricCamera,
    ));
}

// Coordinate Conversion
fn world_to_isometric(world_pos: Vec3) -> Vec3 {
    let iso_x = (world_pos.x - world_pos.z) * 0.866;
    let iso_y = world_pos.y + (world_pos.x + world_pos.z) * 0.5;
    Vec3::new(iso_x, iso_y, 0.0)
}
```

### Depth Sorting for Isometric View
```rust
fn depth_sorting_system(
    mut query: Query<(&mut Transform, &IsometricPosition), With<DepthSortable>>,
) {
    for (mut transform, iso_pos) in query.iter_mut() {
        // Calculate Z-depth for proper rendering order
        transform.translation.z = -(iso_pos.y * 1000.0 + iso_pos.x * 10.0 + iso_pos.z);
    }
}
```

## Performance Optimization Patterns

### Efficient Queries and System Organization
```rust
// Efficient Change Detection
fn piece_movement_system(
    mut moved_pieces: Query<
        (&mut Transform, &BoardPosition), 
        (Changed<BoardPosition>, With<GamePiece>)
    >,
) {
    for (mut transform, position) in moved_pieces.iter_mut() {
        // Only process pieces that actually moved
        transform.translation = board_to_world_position(*position);
    }
}

// Batch Processing
fn power_orb_spawning_system(
    mut commands: Commands,
    board_query: Query<&BoardState>,
    time: Res<Time>,
    mut spawn_timer: ResMut<OrbSpawnTimer>,
) {
    spawn_timer.timer.tick(time.delta());
    
    if spawn_timer.timer.finished() {
        // Batch spawn multiple orbs efficiently
        let spawn_positions = calculate_spawn_positions(&board_query);
        for position in spawn_positions {
            spawn_power_orb(&mut commands, position);
        }
    }
}
```

### Memory-Efficient Component Design
```rust
// Pack related data together
#[derive(Component)]
struct PieceVisuals {
    mesh: Handle<Mesh>,
    material: Handle<StandardMaterial>,
    scale: f32,
    color: Color,
}

// Use entity hierarchies for complex objects
fn spawn_game_piece(
    commands: &mut Commands,
    position: BoardPosition,
    player: Player,
) -> Entity {
    let piece_entity = commands.spawn((
        GamePiece { player, position, ..default() },
        IsometricPosition::from(position),
        DepthSortable { layer: 1, sub_layer: 0.0 },
    )).id();
    
    // Spawn visual representation as child
    let visual_entity = commands.spawn((
        PbrBundle {
            mesh: piece_mesh.clone(),
            material: piece_material.clone(),
            ..default()
        },
        PieceVisuals::default(),
    )).id();
    
    commands.entity(piece_entity).add_child(visual_entity);
    piece_entity
}
```

## Testing Patterns for Game Systems

### Component Testing
```rust
#[cfg(test)]
mod tests {
    use super::*;
    use bevy::ecs::system::SystemState;
    
    #[test]
    fn test_power_effect_application() {
        let mut world = World::new();
        
        // Spawn test entities
        let piece = world.spawn((
            GamePiece::new(Player::One),
            PowerInventory::default(),
        )).id();
        
        // Apply power effect
        let power = PowerType::MoveDiagonal;
        let result = apply_power_effect(&mut world, piece, power);
        
        assert!(result.is_ok());
        
        // Verify effect was applied
        let inventory = world.get::<PowerInventory>(piece).unwrap();
        assert!(inventory.has_active_effect(EffectType::MoveDiagonal));
    }
}
```

### System Testing
```rust
#[test]
fn test_turn_management_system() {
    let mut app = App::new();
    app.add_plugins(MinimalPlugins)
       .add_systems(Update, turn_management_system)
       .insert_resource(GameState::new());
    
    // Simulate turn completion
    let mut game_state = app.world.resource_mut::<GameState>();
    game_state.phase = GamePhase::MovementComplete;
    
    // Run system
    app.update();
    
    // Verify turn advanced
    let game_state = app.world.resource::<GameState>();
    assert_eq!(game_state.current_player, Player::Two);
}
```

## Error Handling and Validation

### Game State Validation
```rust
#[derive(Debug, Error)]
enum GameError {
    #[error("Invalid move: piece cannot move to position {0:?}")]
    InvalidMove(BoardPosition),
    #[error("Power not available: {0:?}")]
    PowerNotAvailable(PowerType),
    #[error("Target out of range")]
    TargetOutOfRange,
}

fn validate_move(
    piece: &GamePiece,
    target: BoardPosition,
    board: &BoardState,
) -> Result<(), GameError> {
    if !is_valid_position(target, board) {
        return Err(GameError::InvalidMove(target));
    }
    
    if !can_reach_position(piece.position, target, board) {
        return Err(GameError::InvalidMove(target));
    }
    
    Ok(())
}
```

This pattern library provides the foundation for implementing sophisticated game mechanics while maintaining clean, testable, and performant code architecture.