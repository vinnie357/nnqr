# Test-Driven Development for Quadradius

## TDD Methodology for Game Development

### Test-First Development Cycle for Game Features
```
1. RED: Write failing test that describes desired behavior
2. GREEN: Write minimal code to make test pass
3. REFACTOR: Improve code while keeping tests passing
4. INTEGRATE: Ensure new feature works with existing systems
```

### Power System TDD Patterns
```rust
// Step 1: Write failing test first
#[test]
fn test_move_diagonal_power_allows_diagonal_movement() {
    let mut world = World::new();
    
    // Setup: Create piece without diagonal movement ability
    let piece = world.spawn((
        GamePiece::new(Player::One, BoardPosition::new(2, 2)),
        PowerInventory::empty(),
    )).id();
    
    // Verify piece cannot move diagonally initially
    let result = validate_move(&world, piece, BoardPosition::new(3, 3));
    assert!(result.is_err());
    
    // Apply MoveDiagonal power
    apply_power(&mut world, piece, PowerType::MoveDiagonal);
    
    // Verify piece can now move diagonally
    let result = validate_move(&world, piece, BoardPosition::new(3, 3));
    assert!(result.is_ok());
}

// Step 2: Implement minimal functionality
impl PowerInventory {
    pub fn has_active_effect(&self, effect: EffectType) -> bool {
        self.active_effects.iter().any(|e| e.effect_type == effect)
    }
}

fn validate_move(world: &World, piece: Entity, target: BoardPosition) -> Result<(), GameError> {
    let piece_data = world.get::<GamePiece>(piece).unwrap();
    let inventory = world.get::<PowerInventory>(piece).unwrap();
    
    let dx = (target.x - piece_data.position.x).abs();
    let dy = (target.y - piece_data.position.y).abs();
    
    // Normal orthogonal movement
    if (dx == 1 && dy == 0) || (dx == 0 && dy == 1) {
        return Ok(());
    }
    
    // Diagonal movement with power
    if dx == 1 && dy == 1 && inventory.has_active_effect(EffectType::MoveDiagonal) {
        return Ok(());
    }
    
    Err(GameError::InvalidMove(target))
}
```

### Integration Testing Patterns
```rust
#[test]
fn test_power_orb_collection_integration() {
    let mut app = App::new();
    app.add_plugins(MinimalPlugins)
       .add_systems(Update, (
           piece_movement_system,
           power_orb_collection_system,
           power_activation_system,
       ).chain());
    
    // Setup initial game state
    let piece = app.world.spawn((
        GamePiece::new(Player::One, BoardPosition::new(2, 2)),
        PowerInventory::empty(),
    )).id();
    
    let orb = app.world.spawn((
        PowerOrb::new(PowerType::MoveDiagonal),
        BoardPosition::new(3, 3),
    )).id();
    
    // Simulate piece movement to orb position
    let mut piece_data = app.world.get_mut::<GamePiece>(piece).unwrap();
    piece_data.position = BoardPosition::new(3, 3);
    
    // Run collection system
    app.update();
    
    // Verify orb was collected and power added
    let inventory = app.world.get::<PowerInventory>(piece).unwrap();
    assert!(inventory.powers.contains(&PowerType::MoveDiagonal));
    
    // Verify orb entity was despawned
    assert!(app.world.get_entity(orb).is_none());
}
```

## Testing Framework for Game Systems

### Board State Testing
```rust
#[test]
fn test_10x8_board_creation() {
    let mut world = World::new();
    
    // Test board initialization
    create_game_board(&mut world);
    
    // Verify board dimensions
    let board = world.resource::<BoardState>();
    assert_eq!(board.width(), 10);
    assert_eq!(board.height(), 8);
    
    // Verify all tiles initialized
    for x in 0..10 {
        for y in 0..8 {
            let tile = board.get_tile(x, y);
            assert!(tile.is_some());
            assert_eq!(tile.unwrap().height, 0); // Default height
        }
    }
}

#[test]
fn test_terrain_height_system() {
    let mut world = World::new();
    create_game_board(&mut world);
    
    // Apply height modification
    let position = BoardPosition::new(5, 4);
    modify_terrain_height(&mut world, position, 2);
    
    // Verify height change
    let board = world.resource::<BoardState>();
    assert_eq!(board.get_height(position), 2);
    
    // Test movement restrictions
    let piece = world.spawn((
        GamePiece::new(Player::One, BoardPosition::new(5, 3)),
        PowerInventory::empty(),
    )).id();
    
    // Should be able to move up 1 level
    let result = validate_move(&world, piece, position);
    assert!(result.is_ok());
    
    // Should not be able to move up 2+ levels
    modify_terrain_height(&mut world, position, 3);
    let result = validate_move(&world, piece, position);
    assert!(result.is_err());
}
```

### Visual System Testing
```rust
#[test]
fn test_isometric_depth_sorting() {
    let mut app = App::new();
    app.add_plugins(MinimalPlugins)
       .add_systems(Update, depth_sorting_system);
    
    // Create pieces at different positions
    let piece1 = app.world.spawn((
        IsometricPosition { x: 2.0, y: 2.0, z: 0.0 },
        Transform::default(),
        DepthSortable { layer: 1, sub_layer: 0.0 },
    )).id();
    
    let piece2 = app.world.spawn((
        IsometricPosition { x: 3.0, y: 3.0, z: 1.0 },
        Transform::default(),
        DepthSortable { layer: 1, sub_layer: 0.0 },
    )).id();
    
    // Run depth sorting
    app.update();
    
    // Verify correct Z-ordering
    let transform1 = app.world.get::<Transform>(piece1).unwrap();
    let transform2 = app.world.get::<Transform>(piece2).unwrap();
    
    // Piece further back should have lower Z value
    assert!(transform2.translation.z < transform1.translation.z);
}
```

## Performance Testing Patterns

### FPS and Performance Validation
```rust
#[test]
fn test_performance_with_many_effects() {
    let mut app = App::new();
    app.add_plugins(DefaultPlugins)
       .add_systems(Update, (
           power_effect_system,
           visual_effect_system,
           depth_sorting_system,
       ));
    
    // Spawn many pieces with active effects
    for i in 0..100 {
        app.world.spawn((
            GamePiece::new(Player::One, BoardPosition::new(i % 10, i / 10)),
            PowerInventory::with_effects(vec![
                ActiveEffect::new(EffectType::Frozen, 5),
                ActiveEffect::new(EffectType::Poison, 3),
            ]),
            IsometricPosition::default(),
            Transform::default(),
        ));
    }
    
    // Measure frame time
    let start = std::time::Instant::now();
    
    // Run 60 frames
    for _ in 0..60 {
        app.update();
    }
    
    let elapsed = start.elapsed();
    let avg_frame_time = elapsed / 60;
    
    // Should maintain 60+ FPS (< 16.67ms per frame)
    assert!(avg_frame_time.as_millis() < 16, 
            "Average frame time: {:?}", avg_frame_time);
}
```

### Memory Usage Testing
```rust
#[test]
fn test_memory_efficiency_with_large_board() {
    let mut world = World::new();
    
    // Create large game state
    create_game_board(&mut world);
    
    // Spawn maximum pieces and power orbs
    for x in 0..10 {
        for y in 0..2 {
            world.spawn((
                GamePiece::new(Player::One, BoardPosition::new(x, y)),
                PowerInventory::with_capacity(10),
            ));
        }
    }
    
    for x in 0..10 {
        for y in 6..8 {
            world.spawn((
                GamePiece::new(Player::Two, BoardPosition::new(x, y)),
                PowerInventory::with_capacity(10),
            ));
        }
    }
    
    // Spawn power orbs
    for _ in 0..20 {
        world.spawn((
            PowerOrb::random(),
            BoardPosition::random(),
        ));
    }
    
    // Memory usage should be reasonable
    let entity_count = world.entities().len();
    assert!(entity_count < 200, "Too many entities: {}", entity_count);
}
```

## Test Organization and Automation

### Test Categories for Game Development
```rust
// Unit tests for individual components
mod unit_tests {
    use super::*;
    
    #[test]
    fn test_power_inventory_operations() { /* ... */ }
    
    #[test]
    fn test_board_position_validation() { /* ... */ }
}

// Integration tests for system interactions
mod integration_tests {
    use super::*;
    
    #[test]
    fn test_complete_turn_cycle() { /* ... */ }
    
    #[test]
    fn test_power_activation_workflow() { /* ... */ }
}

// Performance and stress tests
mod performance_tests {
    use super::*;
    
    #[test]
    fn test_frame_rate_with_effects() { /* ... */ }
    
    #[test]
    fn test_memory_usage_patterns() { /* ... */ }
}
```

### Automated Test Execution
```bash
# Run all tests
cargo test

# Run specific test categories
cargo test unit_tests
cargo test integration_tests
cargo test performance_tests

# Run tests with output
cargo test -- --nocapture

# Run tests in release mode for performance testing
cargo test --release performance_tests
```

### Continuous Integration Testing
```yaml
# .github/workflows/test.yml
name: Quadradius Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions-rs/toolchain@v1
        with:
          toolchain: stable
      - name: Run tests
        run: |
          cargo test --all-features
          cargo test --release performance_tests
      - name: Check formatting
        run: cargo fmt -- --check
      - name: Run clippy
        run: cargo clippy -- -D warnings
```

This TDD framework ensures that all game features are thoroughly tested, performance requirements are met, and code quality remains high throughout development.