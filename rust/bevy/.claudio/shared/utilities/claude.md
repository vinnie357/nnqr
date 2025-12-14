# Quadradius Development Utilities and Helper Functions

## Testing Utilities

### Test World Setup
Common utilities for creating test environments across all power implementations.

```rust
/// Creates a basic test world with necessary systems and components
pub fn create_test_board(world: &mut World) {
    world.spawn((
        BoardComponent::new(10, 8), // 10x8 board
        Transform::default(),
    ));
    
    // Add necessary resources
    world.insert_resource(GameState::default());
    world.insert_resource(PowerInventory::default());
}

/// Spawns a test piece at specified position
pub fn spawn_test_piece(world: &mut World, position: BoardPosition) -> Entity {
    world.spawn((
        PieceComponent::new(PieceType::Regular),
        position,
        Transform::from_translation(position.to_world_coords()),
        PowerInventory::default(),
    )).id()
}

/// Adds a specific power to a piece for testing
pub fn add_power_to_piece(world: &mut World, piece: Entity, power: PowerType) {
    if let Some(mut inventory) = world.get_mut::<PowerInventory>(piece) {
        inventory.add_power(power);
    }
}

/// Activates a power with specified target for testing
pub fn activate_power(
    world: &mut World, 
    piece: Entity, 
    power: PowerType, 
    target: BoardPosition
) {
    world.send_event(PowerActivationEvent {
        piece,
        power,
        target,
    });
}
```

### Terrain Testing Utilities
Specialized utilities for terrain manipulation testing.

```rust
/// Sets terrain height at specific position
pub fn set_tile_height(world: &mut World, position: BoardPosition, height: u8) {
    // Implementation for setting terrain height in test scenarios
}

/// Gets terrain height at specific position
pub fn get_tile_height(world: &World, position: BoardPosition) -> u8 {
    // Implementation for querying terrain height
}

/// Sets heights for entire area for testing area effects
pub fn set_area_heights(world: &mut World, center: BoardPosition, heights: Vec<u8>) {
    let area_positions = get_3x3_area(center);
    for (pos, height) in area_positions.iter().zip(heights.iter()) {
        set_tile_height(world, *pos, *height);
    }
}

/// Gets area covering 3x3 grid around center position
pub fn get_3x3_area(center: BoardPosition) -> Vec<BoardPosition> {
    let mut positions = Vec::new();
    for dy in -1..=1 {
        for dx in -1..=1 {
            if let Some(pos) = center.offset(dx, dy) {
                positions.push(pos);
            }
        }
    }
    positions
}
```

### Power Effect Validation
Utilities for validating power effects and their integration.

```rust
/// Validates that a power effect was applied correctly
pub fn validate_power_effect(
    world: &World,
    power: PowerType,
    target: BoardPosition,
    expected_result: PowerEffectResult
) -> bool {
    match power {
        PowerType::LowerTile => {
            // Validate terrain height was reduced
        },
        PowerType::RaiseTile => {
            // Validate terrain height was increased
        },
        PowerType::Flatten => {
            // Validate area has uniform height
        },
        // ... other power validations
    }
}

/// Checks if tile is marked as impassable (for destructive powers)
pub fn is_tile_impassable(world: &World, position: BoardPosition) -> bool {
    // Implementation for checking tile accessibility
}

/// Counts number of modified tiles in area (for area effect validation)
pub fn count_modified_tiles(world: &World) -> usize {
    // Implementation for counting terrain modifications
}
```

## Performance Testing Utilities

### Frame Rate Monitoring
Utilities for monitoring and validating performance requirements.

```rust
/// Measures frame rate over specified duration
pub fn measure_frame_rate(world: &mut World, duration_seconds: f32) -> f32 {
    // Implementation for measuring actual frame rate
    // Returns average FPS over measurement period
}

/// Validates performance meets minimum requirements
pub fn validate_performance(world: &mut World) -> PerformanceResult {
    let fps = measure_frame_rate(world, 5.0); // 5 second measurement
    PerformanceResult {
        fps,
        meets_requirements: fps >= 60.0,
        memory_usage: get_memory_usage(),
    }
}

pub struct PerformanceResult {
    pub fps: f32,
    pub meets_requirements: bool,
    pub memory_usage: usize,
}
```

### Load Testing Utilities
Utilities for stress testing systems under maximum load conditions.

```rust
/// Creates maximum complexity scenario for performance testing
pub fn create_max_load_scenario(world: &mut World) {
    // Spawn maximum number of pieces
    // Apply all available powers simultaneously
    // Create complex terrain with all modification types
}

/// Simulates multiple simultaneous power activations
pub fn stress_test_powers(world: &mut World, power_count: usize) {
    for i in 0..power_count {
        let piece = spawn_test_piece(world, random_position());
        let power = random_power_type();
        activate_power(world, piece, power, random_target());
    }
}
```

## Board Position Utilities

### Position Validation and Conversion
Common utilities for working with board positions and coordinates.

```rust
impl BoardPosition {
    /// Creates new board position with validation
    pub fn new(x: i32, y: i32) -> Option<Self> {
        if x >= 0 && x < 10 && y >= 0 && y < 8 {
            Some(BoardPosition { x, y })
        } else {
            None
        }
    }
    
    /// Converts board position to world coordinates for 3D rendering
    pub fn to_world_coords(&self) -> Vec3 {
        Vec3::new(
            self.x as f32 * TILE_SIZE,
            0.0, // Y is up in world coordinates
            self.y as f32 * TILE_SIZE,
        )
    }
    
    /// Gets position offset by specified amounts
    pub fn offset(&self, dx: i32, dy: i32) -> Option<BoardPosition> {
        BoardPosition::new(self.x + dx, self.y + dy)
    }
    
    /// Calculates distance between two positions
    pub fn distance(&self, other: &BoardPosition) -> f32 {
        let dx = (self.x - other.x) as f32;
        let dy = (self.y - other.y) as f32;
        (dx * dx + dy * dy).sqrt()
    }
}
```

### Area Selection Utilities
Utilities for selecting and working with areas of tiles.

```rust
/// Gets all positions within specified radius of center
pub fn get_circular_area(center: BoardPosition, radius: u32) -> Vec<BoardPosition> {
    let mut positions = Vec::new();
    let radius = radius as i32;
    
    for dy in -radius..=radius {
        for dx in -radius..=radius {
            if let Some(pos) = center.offset(dx, dy) {
                let distance = center.distance(&pos);
                if distance <= radius as f32 {
                    positions.push(pos);
                }
            }
        }
    }
    positions
}

/// Gets rectangular area of specified size
pub fn get_rectangular_area(
    top_left: BoardPosition, 
    width: u32, 
    height: u32
) -> Vec<BoardPosition> {
    let mut positions = Vec::new();
    
    for dy in 0..height as i32 {
        for dx in 0..width as i32 {
            if let Some(pos) = top_left.offset(dx, dy) {
                positions.push(pos);
            }
        }
    }
    positions
}
```

## Visual Effect Utilities

### Effect Animation Support
Common utilities for creating and managing visual effects.

```rust
/// Creates standard power activation effect
pub fn create_power_effect(
    commands: &mut Commands,
    position: BoardPosition,
    power: PowerType,
    meshes: &mut Assets<Mesh>,
    materials: &mut Assets<StandardMaterial>
) {
    // Implementation for creating appropriate visual effect
    // Based on power type and position
}

/// Updates ongoing visual effects
pub fn update_visual_effects(
    mut commands: Commands,
    time: Res<Time>,
    mut query: Query<(Entity, &mut VisualEffect, &mut Transform)>
) {
    for (entity, mut effect, mut transform) in query.iter_mut() {
        effect.update(time.delta());
        
        if effect.is_complete() {
            commands.entity(entity).despawn();
        } else {
            // Update visual representation based on effect progress
        }
    }
}
```

## Random Number Utilities

### Controlled Randomization
Utilities for implementing random effects with proper testing support.

```rust
/// Random number generator with seed control for testing
pub struct GameRandom {
    rng: StdRng,
}

impl GameRandom {
    /// Creates new random generator with current time seed
    pub fn new() -> Self {
        Self {
            rng: StdRng::from_entropy(),
        }
    }
    
    /// Creates deterministic random generator for testing
    pub fn from_seed(seed: u64) -> Self {
        Self {
            rng: StdRng::seed_from_u64(seed),
        }
    }
    
    /// Generates random position on board
    pub fn random_board_position(&mut self) -> BoardPosition {
        let x = self.rng.gen_range(0..10);
        let y = self.rng.gen_range(0..8);
        BoardPosition::new(x, y).unwrap()
    }
    
    /// Generates random height within valid range
    pub fn random_height(&mut self) -> u8 {
        self.rng.gen_range(0..=10)
    }
}
```

## Error Handling Utilities

### Common Error Types and Handling
Standardized error types and handling patterns for consistent error management.

```rust
/// Common result type for power operations
pub type PowerResult<T> = Result<T, PowerError>;

/// Standard error types for power system
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum PowerError {
    InvalidTarget(BoardPosition),
    InsufficientRange { current: f32, required: f32 },
    PowerNotAvailable(PowerType),
    TerrainModificationFailed,
    PerformanceThresholdExceeded,
}

impl std::fmt::Display for PowerError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            PowerError::InvalidTarget(pos) => {
                write!(f, "Invalid target position: ({}, {})", pos.x, pos.y)
            },
            PowerError::InsufficientRange { current, required } => {
                write!(f, "Range {} insufficient, {} required", current, required)
            },
            // ... other error Display implementations
        }
    }
}
```

These utilities provide consistent, reusable functionality across all Quadradius development tasks, ensuring code quality and reducing duplication.