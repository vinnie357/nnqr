# Comprehensive Technical Guide: Isometric Game Development in Bevy

## 1. Isometric Camera Setup and Configuration

### Camera fundamentals for isometric projection

For isometric games in Bevy, you need an orthographic projection camera positioned at specific angles. The standard approach uses a 3D camera with orthographic projection for maximum flexibility.

#### 3D Isometric Camera (Recommended)
```rust
use bevy::{prelude::*, render::camera::ScalingMode};

fn setup_isometric_camera(mut commands: Commands) {
    commands.spawn((
        Camera3d::default(),
        Projection::from(OrthographicProjection {
            // Fixed viewport height in world units
            scaling_mode: ScalingMode::FixedVertical { 
                viewport_height: 6.0 
            },
            // Depth range for proper sorting
            near: -1000.0,
            far: 1000.0,
            ..OrthographicProjection::default_3d()
        }),
        // Standard isometric angles: 45° horizontal, ~35.264° vertical
        Transform::from_xyz(5.0, 5.0, 5.0).looking_at(Vec3::ZERO, Vec3::Y),
    ));
}
```

#### Camera Angle Calculations
```rust
// Precise isometric camera positioning
fn calculate_isometric_camera_position(distance: f32) -> Transform {
    let horizontal_angle = 45.0_f32.to_radians();
    let vertical_angle = 35.264_f32.to_radians(); // arcsin(1/√3)
    
    Transform::from_xyz(
        distance * horizontal_angle.cos() * vertical_angle.cos(),
        distance * vertical_angle.sin(),
        distance * horizontal_angle.sin() * vertical_angle.cos(),
    ).looking_at(Vec3::ZERO, Vec3::Y)
}
```

#### Zoom Controls
```rust
fn camera_zoom_system(
    mut query: Query<&mut OrthographicProjection, With<Camera>>,
    input: Res<ButtonInput<KeyCode>>,
    time: Res<Time>,
) {
    if let Ok(mut projection) = query.get_single_mut() {
        let zoom_speed = 0.9_f32.powf(time.delta_secs() * 10.0);
        
        if input.pressed(KeyCode::Equal) {
            projection.scale *= zoom_speed;
        }
        if input.pressed(KeyCode::Minus) {
            projection.scale /= zoom_speed;
        }
        
        projection.scale = projection.scale.clamp(0.1, 5.0);
    }
}
```

## 2. Isometric Coordinate Systems and Transformations

### Coordinate conversion mathematics

Bevy uses a right-handed Y-up coordinate system. Converting between world, isometric, and screen coordinates requires specific transformation formulas.

```rust
#[derive(Resource)]
pub struct IsometricProjection {
    pub tile_width: f32,
    pub tile_height: f32,
    pub map_offset: Vec2,
}

impl IsometricProjection {
    pub fn world_to_screen(&self, world_pos: Vec2) -> Vec2 {
        let iso_x = (world_pos.x - world_pos.y) * (self.tile_width / 2.0);
        let iso_y = (world_pos.x + world_pos.y) * (self.tile_height / 2.0);
        Vec2::new(iso_x, iso_y) + self.map_offset
    }
    
    pub fn screen_to_world(&self, screen_pos: Vec2) -> Vec2 {
        let adjusted_pos = screen_pos - self.map_offset;
        let world_x = (adjusted_pos.x / (self.tile_width / 2.0) + 
                      adjusted_pos.y / (self.tile_height / 2.0)) / 2.0;
        let world_y = (adjusted_pos.y / (self.tile_height / 2.0) - 
                      adjusted_pos.x / (self.tile_width / 2.0)) / 2.0;
        Vec2::new(world_x, world_y)
    }
}

// Matrix-based transformation for efficiency
fn create_isometric_matrix(tile_size: Vec2) -> Mat2 {
    Mat2::from_cols(
        Vec2::new(0.5 * tile_size.x, 0.25 * tile_size.y),
        Vec2::new(-0.5 * tile_size.x, 0.25 * tile_size.y),
    )
}
```

## 3. Grid-Based Tile Systems

### Using bevy_ecs_tilemap for efficient tile rendering

The `bevy_ecs_tilemap` crate provides the most mature solution for isometric tilemaps in Bevy, with each tile as an entity for maximum flexibility.

```rust
use bevy::prelude::*;
use bevy_ecs_tilemap::prelude::*;

fn setup_isometric_tilemap(
    mut commands: Commands, 
    asset_server: Res<AssetServer>
) {
    let texture_handle: Handle<Image> = asset_server.load("iso_tiles.png");
    let map_size = TilemapSize { x: 100, y: 100 };
    let mut tile_storage = TileStorage::empty(map_size);
    let tilemap_entity = commands.spawn_empty().id();
    let tilemap_id = TilemapId(tilemap_entity);

    // Create tiles
    for x in 0..map_size.x {
        for y in 0..map_size.y {
            let tile_pos = TilePos { x, y };
            let tile_entity = commands
                .spawn(TileBundle {
                    position: tile_pos,
                    tilemap_id,
                    texture_index: TileTextureIndex(0),
                    ..Default::default()
                })
                .id();
            tile_storage.set(&tile_pos, tile_entity);
        }
    }

    // Configure for isometric rendering
    let tile_size = TilemapTileSize { x: 64.0, y: 32.0 };
    let grid_size = tile_size.into();
    let map_type = TilemapType::Isometric(IsoCoordSystem::Diamond);

    commands.entity(tilemap_entity).insert(TilemapBundle {
        grid_size,
        size: map_size,
        storage: tile_storage,
        texture: TilemapTexture::Single(texture_handle),
        tile_size,
        map_type,
        anchor: TilemapAnchor::Center,
        ..Default::default()
    });
}
```

### Custom tile entity management
```rust
#[derive(Component)]
struct TileData {
    tile_type: TileType,
    walkable: bool,
    height: f32,
}

#[derive(Component)]
struct BuildingTile {
    building_type: BuildingType,
    health: f32,
}

fn update_building_tiles(
    mut tile_query: Query<
        (&mut TileTextureIndex, &mut BuildingTile), 
        Changed<BuildingTile>
    >,
) {
    for (mut texture_index, building) in tile_query.iter_mut() {
        texture_index.0 = match (building.building_type, building.health > 0.5) {
            (BuildingType::Factory, true) => 1,
            (BuildingType::Factory, false) => 2,
            (BuildingType::House, _) => 3,
        };
    }
}
```

## 4. Mouse Input Handling

### Screen-to-world coordinate conversion

Accurate mouse input requires converting screen coordinates through the camera transformation to world coordinates, then to tile positions.

```rust
use bevy::window::PrimaryWindow;

#[derive(Resource, Default)]
struct CursorWorldPosition(Vec2);

fn update_cursor_position(
    mut cursor_pos: ResMut<CursorWorldPosition>,
    q_window: Query<&Window, With<PrimaryWindow>>,
    q_camera: Query<(&Camera, &GlobalTransform)>,
) {
    let (camera, camera_transform) = q_camera.single();
    let window = q_window.single();

    if let Some(world_position) = window.cursor_position()
        .and_then(|cursor| camera.viewport_to_world_2d(camera_transform, cursor).ok())
    {
        cursor_pos.0 = world_position;
    }
}

fn screen_to_tile_coordinates(
    cursor_pos: Res<CursorWorldPosition>,
    tilemap_query: Query<(
        &TilemapSize,
        &TilemapGridSize,
        &TilemapTileSize,
        &TilemapType,
        &Transform,
        &TilemapAnchor,
    )>,
) -> Option<TilePos> {
    for (map_size, grid_size, tile_size, map_type, transform, anchor) in tilemap_query.iter() {
        // Transform cursor to map local coordinates
        let cursor_in_map_pos = {
            let cursor_pos = Vec4::from((cursor_pos.0, 0.0, 1.0));
            let cursor_in_map_pos = transform.compute_matrix().inverse() * cursor_pos;
            cursor_in_map_pos.xy()
        };

        // Convert to tile position
        if let Some(tile_pos) = TilePos::from_world_pos(
            &cursor_in_map_pos,
            map_size,
            grid_size,
            tile_size,
            map_type,
            anchor,
        ) {
            return Some(tile_pos);
        }
    }
    None
}
```

### Tile selection and highlighting
```rust
#[derive(Component)]
struct HighlightedTile;

#[derive(Component)]
struct SelectedTile;

fn handle_tile_interaction(
    mut commands: Commands,
    cursor_pos: Res<CursorWorldPosition>,
    tilemap_q: Query<(&TileStorage, &Transform, /* tilemap components */)>,
    highlighted_q: Query<Entity, With<HighlightedTile>>,
    mouse_input: Res<ButtonInput<MouseButton>>,
) {
    // Clear previous highlights
    for entity in highlighted_q.iter() {
        commands.entity(entity).remove::<HighlightedTile>();
    }

    // Find tile under cursor
    if let Some(tile_pos) = screen_to_tile_coordinates(cursor_pos, tilemap_q) {
        if let Some(tile_entity) = get_tile_entity_at_pos(&tilemap_q, tile_pos) {
            commands.entity(tile_entity).insert(HighlightedTile);
            
            if mouse_input.just_pressed(MouseButton::Left) {
                commands.entity(tile_entity).insert(SelectedTile);
            }
        }
    }
}
```

## 5. Rendering Order and Depth Sorting

### Z-order calculation for isometric sprites

Proper depth sorting is crucial for isometric games to maintain the illusion of 3D space.

```rust
#[derive(Component)]
struct IsometricPosition {
    x: f32,
    y: f32,
    z: f32, // Height/elevation
}

fn update_isometric_depth(
    mut query: Query<(&IsometricPosition, &mut Transform)>,
) {
    for (iso_pos, mut transform) in query.iter_mut() {
        // Calculate depth: further back and lower objects render first
        let depth_order = (iso_pos.y * 1000.0) - (iso_pos.z * 100.0) - (iso_pos.x * 10.0);
        transform.translation.z = depth_order;
    }
}

// Advanced topological sorting for complex overlaps
fn topological_depth_sort(
    mut query: Query<(Entity, &mut Transform, &DepthSortable)>,
) {
    let mut entities: Vec<_> = query.iter_mut().collect();
    
    entities.sort_by(|a, b| {
        let bounds_a = &a.2.bounds;
        let bounds_b = &b.2.bounds;
        
        if bounds_a.overlaps(bounds_b) {
            if bounds_a.is_behind(bounds_b) {
                Ordering::Less
            } else if bounds_b.is_behind(bounds_a) {
                Ordering::Greater
            } else {
                // Handle cyclic dependencies
                let center_a_y = (bounds_a.min_y + bounds_a.max_y) / 2.0;
                let center_b_y = (bounds_b.min_y + bounds_b.max_y) / 2.0;
                center_b_y.partial_cmp(&center_a_y).unwrap_or(Ordering::Equal)
            }
        } else {
            // No overlap, use simple comparison
            let depth_a = bounds_a.min_y + bounds_a.min_x + bounds_a.min_z;
            let depth_b = bounds_b.min_y + bounds_b.min_x + bounds_b.min_z;
            depth_b.partial_cmp(&depth_a).unwrap_or(Ordering::Equal)
        }
    });
    
    // Apply sorted Z values
    for (i, (_, mut transform, _)) in entities.into_iter().enumerate() {
        transform.translation.z = i as f32;
    }
}
```

## 6. Asset Creation and Management

### Isometric sprite specifications

Standard isometric tiles use a 2:1 width-to-height ratio with power-of-two dimensions for optimal performance.

```rust
// Standard tile dimensions
const TILE_WIDTH: u32 = 64;
const TILE_HEIGHT: u32 = 32;

#[derive(Resource)]
struct GameAssets {
    tile_atlas: Handle<TextureAtlasLayout>,
    tile_texture: Handle<Image>,
    character_sprites: HashMap<Direction8, Vec<Handle<Image>>>,
}

fn load_game_assets(
    mut commands: Commands,
    asset_server: Res<AssetServer>,
    mut texture_atlases: ResMut<Assets<TextureAtlasLayout>>,
) {
    // Load and create texture atlas
    let tile_texture = asset_server.load("textures/isometric_tiles.png");
    let tile_atlas = TextureAtlasLayout::from_grid(
        UVec2::new(64, 32),
        16, 8, // 16 columns, 8 rows
        Some(UVec2::new(2, 2)), // 2px padding
        None
    );
    let tile_atlas_handle = texture_atlases.add(tile_atlas);

    // Store handles
    commands.insert_resource(GameAssets {
        tile_atlas: tile_atlas_handle,
        tile_texture,
        character_sprites: load_directional_sprites(&asset_server),
    });
}
```

### 3D mesh-based approach
```rust
fn create_isometric_mesh() -> Mesh {
    // Create a diamond-shaped quad for isometric tiles
    let mut mesh = Mesh::new(PrimitiveTopology::TriangleList, RenderAssetUsages::RENDER_WORLD);
    
    // Vertices for isometric diamond
    let vertices = vec![
        [0.0, 0.0, 0.0],      // Bottom
        [0.5, 0.25, 0.0],     // Right
        [0.0, 0.5, 0.0],      // Top
        [-0.5, 0.25, 0.0],    // Left
    ];
    
    let indices = vec![0, 1, 2, 0, 2, 3];
    let uvs = vec![[0.5, 0.0], [1.0, 0.5], [0.5, 1.0], [0.0, 0.5]];
    
    mesh.insert_attribute(Mesh::ATTRIBUTE_POSITION, vertices);
    mesh.insert_attribute(Mesh::ATTRIBUTE_UV_0, uvs);
    mesh.insert_indices(Indices::U32(indices));
    
    mesh
}
```

## 7. Animation Systems

### Smooth grid-based movement

Separating logical position from visual position enables smooth animations between grid cells.

```rust
#[derive(Component)]
struct GridPosition {
    x: i32,
    y: i32,
}

#[derive(Component)]
struct MovementAnimation {
    start_pos: Vec3,
    target_pos: Vec3,
    timer: Timer,
    is_moving: bool,
}

fn smooth_grid_movement(
    time: Res<Time>,
    mut query: Query<(&mut Transform, &mut MovementAnimation)>,
) {
    for (mut transform, mut animation) in &mut query {
        if !animation.is_moving {
            continue;
        }

        animation.timer.tick(time.delta());
        let progress = animation.timer.fraction();
        
        // Use easing for natural movement
        let eased_progress = ease_in_out_cubic(progress);
        
        transform.translation = animation.start_pos.lerp(
            animation.target_pos, 
            eased_progress
        );
        
        if animation.timer.finished() {
            transform.translation = animation.target_pos;
            animation.is_moving = false;
        }
    }
}

fn ease_in_out_cubic(t: f32) -> f32 {
    if t < 0.5 {
        4.0 * t * t * t
    } else {
        1.0 - (-2.0 * t + 2.0).powi(3) / 2.0
    }
}
```

### Directional character animation
```rust
#[derive(Component)]
struct DirectionalSprite {
    current_direction: Direction8,
    sprites: HashMap<Direction8, AnimationData>,
    animation_timer: Timer,
    current_frame: usize,
}

#[derive(Hash, Eq, PartialEq, Clone, Copy)]
enum Direction8 {
    North, NorthEast, East, SouthEast,
    South, SouthWest, West, NorthWest,
}

impl Direction8 {
    fn from_movement(delta: Vec2) -> Self {
        let angle = delta.y.atan2(delta.x);
        let octant = ((angle + PI + PI / 8.0) / (PI / 4.0)) as i32 % 8;
        
        match octant {
            0 => Direction8::East,
            1 => Direction8::NorthEast,
            2 => Direction8::North,
            3 => Direction8::NorthWest,
            4 => Direction8::West,
            5 => Direction8::SouthWest,
            6 => Direction8::South,
            7 => Direction8::SouthEast,
            _ => Direction8::South,
        }
    }
}

struct AnimationData {
    frames: Vec<Handle<Image>>,
    frame_duration: f32,
    looping: bool,
}

fn animate_directional_sprite(
    time: Res<Time>,
    mut query: Query<(&mut DirectionalSprite, &mut Sprite)>,
) {
    for (mut directional, mut sprite) in &mut query {
        directional.animation_timer.tick(time.delta());
        
        if directional.animation_timer.finished() {
            let anim_data = &directional.sprites[&directional.current_direction];
            directional.current_frame = 
                (directional.current_frame + 1) % anim_data.frames.len();
            sprite.image = anim_data.frames[directional.current_frame].clone();
            directional.animation_timer.reset();
        }
    }
}
```

## 8. Tile Highlighting and Selection

### Multi-layer selection system

Implementing various selection patterns for different gameplay scenarios.

```rust
#[derive(Component)]
struct SelectableTile {
    is_highlighted: bool,
    is_selected: bool,
    base_color: Color,
    highlight_color: Color,
    selection_color: Color,
}

#[derive(Resource)]
struct SelectionTool {
    selection_type: SelectionType,
}

enum SelectionType {
    Single,
    Square(i32),
    Circle(i32),
    Line { start: Option<TilePos>, end: Option<TilePos> },
}

fn handle_area_selection(
    cursor_world_pos: Res<CursorWorldPosition>,
    mut tile_query: Query<(&GridPosition, &mut SelectableTile)>,
    mouse_input: Res<ButtonInput<MouseButton>>,
    selection_tool: Res<SelectionTool>,
) {
    let center_grid = world_to_grid(cursor_world_pos.0);
    
    for (tile_pos, mut selectable) in &mut tile_query {
        let in_selection = match &selection_tool.selection_type {
            SelectionType::Single => {
                tile_pos.x == center_grid.x && tile_pos.y == center_grid.y
            }
            SelectionType::Square(size) => {
                (tile_pos.x - center_grid.x).abs() <= size / 2 && 
                (tile_pos.y - center_grid.y).abs() <= size / 2
            }
            SelectionType::Circle(radius) => {
                let dx = tile_pos.x - center_grid.x;
                let dy = tile_pos.y - center_grid.y;
                (dx * dx + dy * dy) <= radius * radius
            }
            SelectionType::Line { start, end } => {
                // Implement Bresenham's line algorithm
                false
            }
        };

        selectable.is_highlighted = in_selection;
        
        if in_selection && mouse_input.just_pressed(MouseButton::Left) {
            selectable.is_selected = !selectable.is_selected;
        }
    }
}
```

### Visual feedback overlays
```rust
#[derive(Component)]
struct SelectionOverlay {
    overlay_type: OverlayType,
}

enum OverlayType {
    Highlight,
    Selection,
    ValidMove,
    AttackRange,
}

fn spawn_selection_overlays(
    mut commands: Commands,
    asset_server: Res<AssetServer>,
    query: Query<(&GridPosition, &SelectableTile), Changed<SelectableTile>>,
) {
    for (grid_pos, selectable) in &query {
        if selectable.is_selected {
            let world_pos = grid_to_world(*grid_pos);
            
            commands.spawn((
                Sprite {
                    image: asset_server.load("ui/selection_ring.png"),
                    color: Color::srgba(0.0, 1.0, 0.0, 0.8),
                    ..default()
                },
                Transform::from_translation(world_pos.extend(100.0)),
                SelectionOverlay {
                    overlay_type: OverlayType::Selection,
                },
            ));
        }
    }
}
```

## 9. Multi-Layer Rendering

### Render layer configuration

Bevy's `RenderLayers` component enables sophisticated multi-layer rendering setups.

```rust
use bevy::render::view::RenderLayers;

// Define layer constants
const BACKGROUND_LAYER: u8 = 0;
const TILE_LAYER: u8 = 1;
const UNIT_LAYER: u8 = 2;
const EFFECT_LAYER: u8 = 3;
const UI_LAYER: u8 = 4;

fn setup_layered_cameras(mut commands: Commands) {
    // Main world camera
    commands.spawn((
        Camera2dBundle {
            camera: Camera {
                order: 0,
                ..default()
            },
            ..default()
        },
        RenderLayers::from_layers(&[BACKGROUND_LAYER, TILE_LAYER, UNIT_LAYER]),
    ));
    
    // Effects overlay camera
    commands.spawn((
        Camera2dBundle {
            camera: Camera {
                order: 1,
                clear_color: ClearColorConfig::None,
                ..default()
            },
            ..default()
        },
        RenderLayers::from_layers(&[EFFECT_LAYER]),
    ));
    
    // UI camera
    commands.spawn((
        Camera2dBundle {
            camera: Camera {
                order: 2,
                clear_color: ClearColorConfig::None,
                ..default()
            },
            ..default()
        },
        RenderLayers::layer(UI_LAYER),
    ));
}

fn spawn_layered_entity(
    commands: &mut Commands,
    sprite: Sprite,
    position: Vec3,
    layer: u8,
) -> Entity {
    commands.spawn((
        SpriteBundle {
            sprite,
            transform: Transform::from_translation(position),
            ..default()
        },
        RenderLayers::layer(layer),
    )).id()
}
```

### Dynamic layer management
```rust
#[derive(Component)]
struct LayerManager {
    base_layer: u8,
    auto_adjust: bool,
}

fn auto_assign_render_layers(
    mut query: Query<
        (&Transform, &mut RenderLayers, &LayerManager), 
        Changed<Transform>
    >,
) {
    for (transform, mut render_layers, manager) in query.iter_mut() {
        if manager.auto_adjust {
            let layer = if transform.translation.y > 100.0 {
                EFFECT_LAYER
            } else if transform.translation.z > 50.0 {
                UNIT_LAYER
            } else {
                manager.base_layer
            };
            
            *render_layers = RenderLayers::layer(layer);
        }
    }
}
```

## 10. Performance Optimization

### Batching and instancing strategies

Maximizing rendering performance through efficient batching and GPU instancing.

```rust
// Use texture atlases for automatic batching
fn setup_optimized_tilemap(
    mut commands: Commands,
    asset_server: Res<AssetServer>,
    mut texture_atlases: ResMut<Assets<TextureAtlasLayout>>,
) {
    let texture = asset_server.load("tiles/tileset.png");
    let atlas_layout = TextureAtlasLayout::from_grid(
        UVec2::new(64, 32),
        32, 16,
        None,
        None
    );
    let atlas_handle = texture_atlases.add(atlas_layout);
    
    // All tiles using same texture and atlas will batch automatically
    for i in 0..1000 {
        commands.spawn((
            SpriteBundle {
                texture: texture.clone(),
                ..default()
            },
            TextureAtlas {
                layout: atlas_handle.clone(),
                index: i % 512,
            },
        ));
    }
}
```

### Chunk-based rendering
```rust
const CHUNK_SIZE: usize = 32;

#[derive(Component)]
struct TileChunk {
    tiles: [[TileType; CHUNK_SIZE]; CHUNK_SIZE],
    position: IVec2,
}

#[derive(Resource)]
struct ChunkManager {
    active_chunks: HashMap<IVec2, Entity>,
    view_distance: i32,
}

fn manage_chunks(
    mut commands: Commands,
    mut chunk_manager: ResMut<ChunkManager>,
    camera_query: Query<&Transform, With<Camera>>,
    chunk_query: Query<(Entity, &TileChunk)>,
) {
    let camera_transform = camera_query.single();
    let camera_chunk = world_to_chunk(camera_transform.translation.truncate());
    
    let mut needed_chunks = HashSet::new();
    
    // Determine which chunks should be active
    for dx in -chunk_manager.view_distance..=chunk_manager.view_distance {
        for dy in -chunk_manager.view_distance..=chunk_manager.view_distance {
            let chunk_pos = camera_chunk + IVec2::new(dx, dy);
            needed_chunks.insert(chunk_pos);
            
            // Spawn chunk if not exists
            if !chunk_manager.active_chunks.contains_key(&chunk_pos) {
                let entity = spawn_chunk(&mut commands, chunk_pos);
                chunk_manager.active_chunks.insert(chunk_pos, entity);
            }
        }
    }
    
    // Despawn distant chunks
    chunk_manager.active_chunks.retain(|&pos, &mut entity| {
        if !needed_chunks.contains(&pos) {
            commands.entity(entity).despawn_recursive();
            false
        } else {
            true
        }
    });
}
```

### GPU-driven rendering optimizations
```rust
use bevy::pbr::ClusterConfig;

fn optimize_for_isometric(mut commands: Commands) {
    commands.spawn((
        Camera3dBundle {
            projection: Projection::Orthographic(OrthographicProjection {
                scaling_mode: ScalingMode::FixedVertical { 
                    viewport_height: 10.0 
                },
                ..default()
            }),
            ..default()
        },
        // Optimize clustered forward rendering for isometric view
        ClusterConfig::FixedZ {
            total: 4096,
            z_slices: 1, // Single slice for 2D-like rendering
            dynamic_resizing: true,
            z_config: Default::default(),
        },
    ));
}
```

### Profiling and diagnostics
```rust
use bevy::diagnostic::{DiagnosticsStore, FrameTimeDiagnosticsPlugin};

fn setup_diagnostics(app: &mut App) {
    app.add_plugins(FrameTimeDiagnosticsPlugin)
        .add_systems(Update, log_performance);
}

fn log_performance(
    diagnostics: Res<DiagnosticsStore>,
    time: Res<Time>,
    mut last_log: Local<f32>,
) {
    if time.elapsed_secs() - *last_log > 1.0 {
        if let Some(fps) = diagnostics.get(&FrameTimeDiagnosticsPlugin::FPS) {
            if let Some(avg) = fps.smoothed() {
                info!("FPS: {:.1}", avg);
            }
        }
        *last_log = time.elapsed_secs();
    }
}
```

## 11. Code Architecture Best Practices

### Plugin-based modular design

Organizing isometric game systems into reusable plugins.

```rust
pub struct IsometricGamePlugin;

impl Plugin for IsometricGamePlugin {
    fn build(&self, app: &mut App) {
        app.add_plugins((
            IsometricRenderingPlugin,
            IsometricInputPlugin,
            IsometricTilemapPlugin,
        ))
        .init_resource::<IsometricProjection>()
        .add_systems(Startup, setup_isometric_camera)
        .add_systems(Update, (
            update_isometric_depth,
            handle_tile_selection,
        ).chain());
    }
}

pub struct IsometricRenderingPlugin;

impl Plugin for IsometricRenderingPlugin {
    fn build(&self, app: &mut App) {
        app.configure_sets(Update, (
            IsometricSet::Input,
            IsometricSet::Logic,
            IsometricSet::Animation,
            IsometricSet::Rendering,
        ).chain())
        .add_systems(Update, (
            sort_sprites_by_depth.in_set(IsometricSet::Rendering),
            update_sprite_positions.in_set(IsometricSet::Animation),
        ));
    }
}

#[derive(SystemSet, Debug, Hash, PartialEq, Eq, Clone)]
enum IsometricSet {
    Input,
    Logic,
    Animation,
    Rendering,
}
```

### Component design patterns
```rust
// Separate concerns with focused components
#[derive(Component)]
struct IsometricPosition { x: i32, y: i32, z: i32 }

#[derive(Component)]
struct WorldPosition(Vec3);

#[derive(Component)]
struct TileLogic {
    tile_type: TileType,
    walkable: bool,
    occupied_by: Option<Entity>,
}

#[derive(Component)]
struct TileVisuals {
    base_sprite: usize,
    overlay_sprite: Option<usize>,
    tint_color: Color,
}

// Marker components for efficient queries
#[derive(Component)]
struct Interactable;

#[derive(Component)]
struct Animated;

#[derive(Component)]
struct NeedsDepthSort;
```

### State management
```rust
#[derive(States, Default, Clone, Eq, PartialEq, Debug, Hash)]
enum GameState {
    #[default]
    Loading,
    MainMenu,
    InGame,
    Paused,
}

#[derive(States, Default, Clone, Eq, PartialEq, Debug, Hash)]
enum InGameState {
    #[default]
    PlayerTurn,
    EnemyTurn,
    AnimatingActions,
    ProcessingEffects,
}

fn configure_states(app: &mut App) {
    app.init_state::<GameState>()
        .init_state::<InGameState>()
        .add_systems(OnEnter(GameState::InGame), setup_game_world)
        .add_systems(OnExit(GameState::InGame), cleanup_game_world)
        .add_systems(
            Update,
            handle_player_input.run_if(
                in_state(GameState::InGame)
                    .and(in_state(InGameState::PlayerTurn))
            ),
        );
}
```

## 12. Common Pitfalls and Solutions

### Floating point precision issues

Large world coordinates can cause precision problems. Here are proven solutions:

```rust
// Solution 1: Origin shifting
#[derive(Resource)]
struct WorldOrigin {
    offset: DVec3, // Double precision for accumulated offset
}

fn shift_world_origin(
    mut world_origin: ResMut<WorldOrigin>,
    mut transforms: Query<&mut Transform>,
    camera_query: Query<&Transform, (With<Camera>, Without<Player>)>,
) {
    if let Ok(camera_transform) = camera_query.get_single() {
        if camera_transform.translation.length() > 1000.0 {
            let shift = -camera_transform.translation;
            world_origin.offset += shift.as_dvec3();
            
            for mut transform in transforms.iter_mut() {
                transform.translation += shift;
            }
        }
    }
}

// Solution 2: Fixed-point coordinates
#[derive(Component)]
struct FixedPosition {
    x: i64,
    y: i64,
    scale: i64, // e.g., 1000 for 3 decimal places
}

impl FixedPosition {
    fn to_vec3(&self) -> Vec3 {
        Vec3::new(
            self.x as f32 / self.scale as f32,
            self.y as f32 / self.scale as f32,
            0.0,
        )
    }
}
```

### Z-fighting and rendering artifacts

Preventing flickering with proper depth management:

```rust
// Consistent Z-ordering formula
fn calculate_iso_z_order(iso_pos: &IsometricPosition) -> f32 {
    let base_depth = -((iso_pos.y as f32 * 1000.0) + 
                      (iso_pos.x as f32 * 10.0) + 
                      (iso_pos.z as f32 * 0.1));
    
    // Add small offsets for different entity types
    base_depth
}

// Z-offset constants
const TILE_Z_OFFSET: f32 = 0.0;
const OBJECT_Z_OFFSET: f32 = 0.01;
const UNIT_Z_OFFSET: f32 = 0.02;
const EFFECT_Z_OFFSET: f32 = 0.03;
const UI_Z_OFFSET: f32 = 0.1;

#[derive(Component)]
struct ZSortLayer {
    layer: u8,
    sub_layer: f32,
}

fn apply_z_sort_layers(
    mut query: Query<(&mut Transform, &IsometricPosition, &ZSortLayer)>,
) {
    for (mut transform, iso_pos, z_layer) in query.iter_mut() {
        let base_z = calculate_iso_z_order(iso_pos);
        let layer_offset = z_layer.layer as f32 * 100.0;
        transform.translation.z = base_z + layer_offset + z_layer.sub_layer;
    }
}
```

### Input accuracy problems

Ensuring clicks map correctly to tiles:

```rust
fn accurate_tile_picking(
    windows: Query<&Window>,
    camera_q: Query<(&Camera, &GlobalTransform)>,
    tilemap_q: Query<(&Transform, &TilemapSize, &TilemapGridSize)>,
    mouse_pos: Vec2,
) -> Option<TilePos> {
    let (camera, camera_transform) = camera_q.single();
    
    // Get world position with sub-pixel accuracy
    let world_pos = camera.viewport_to_world_2d(camera_transform, mouse_pos)?;
    
    for (tilemap_transform, map_size, grid_size) in tilemap_q.iter() {
        // Transform to tilemap space
        let local_pos = tilemap_transform
            .compute_matrix()
            .inverse()
            .transform_point3(world_pos.extend(0.0))
            .truncate();
        
        // Apply half-pixel offset for diamond tiles
        let adjusted_pos = local_pos + Vec2::new(grid_size.x / 2.0, 0.0);
        
        // Convert to tile coordinates
        let tile_x = ((adjusted_pos.x / grid_size.x) + 
                     (adjusted_pos.y / grid_size.y)).round() as u32;
        let tile_y = ((adjusted_pos.y / grid_size.y) - 
                     (adjusted_pos.x / grid_size.x)).round() as u32;
        
        if tile_x < map_size.x && tile_y < map_size.y {
            return Some(TilePos { x: tile_x, y: tile_y });
        }
    }
    
    None
}
```

### Performance bottlenecks

Critical optimizations for maintaining 60+ FPS:

```rust
// Build configuration (Cargo.toml)
[profile.dev]
opt-level = 1

[profile.dev.package."*"]
opt-level = 3

[profile.release]
lto = true
codegen-units = 1
strip = "debuginfo"

// Efficient entity management
const MAX_VISIBLE_TILES: usize = 10000;

fn cull_distant_tiles(
    mut commands: Commands,
    camera_q: Query<&Transform, With<Camera>>,
    tile_q: Query<(Entity, &Transform), With<Tile>>,
    mut visible_count: Local<usize>,
) {
    let camera_pos = camera_q.single().translation.truncate();
    let max_distance = 500.0;
    
    let mut tiles: Vec<_> = tile_q.iter().collect();
    tiles.sort_by_key(|(_, t)| {
        FloatOrd(t.translation.truncate().distance_squared(camera_pos))
    });
    
    *visible_count = 0;
    for (entity, transform) in tiles {
        let distance = transform.translation.truncate().distance(camera_pos);
        
        if distance > max_distance || *visible_count > MAX_VISIBLE_TILES {
            commands.entity(entity).insert(Visibility::Hidden);
        } else {
            commands.entity(entity).insert(Visibility::Visible);
            *visible_count += 1;
        }
    }
}
```

## 13. Complete Example: Minimal Isometric Game

Here's a complete, working example that brings together all the concepts:

```rust
use bevy::prelude::*;
use bevy_ecs_tilemap::prelude::*;

fn main() {
    App::new()
        .add_plugins(DefaultPlugins)
        .add_plugins(TilemapPlugin)
        .add_plugins(IsometricGamePlugin)
        .run();
}

pub struct IsometricGamePlugin;

impl Plugin for IsometricGamePlugin {
    fn build(&self, app: &mut App) {
        app.init_resource::<CursorWorldPosition>()
            .add_systems(Startup, (setup_camera, setup_tilemap))
            .add_systems(Update, (
                update_cursor_position,
                update_isometric_depth,
                handle_tile_selection,
                animate_selected_tiles,
            ).chain());
    }
}

#[derive(Resource, Default)]
struct CursorWorldPosition(Vec2);

#[derive(Component)]
struct IsometricPosition { x: i32, y: i32 }

#[derive(Component)]
struct SelectedTile;

fn setup_camera(mut commands: Commands) {
    commands.spawn((
        Camera2d,
        OrthographicProjection {
            scaling_mode: ScalingMode::FixedVertical { 
                viewport_height: 10.0 
            },
            ..default()
        },
    ));
}

fn setup_tilemap(
    mut commands: Commands,
    asset_server: Res<AssetServer>,
) {
    let texture = asset_server.load("tiles.png");
    let map_size = TilemapSize { x: 20, y: 20 };
    let mut tile_storage = TileStorage::empty(map_size);
    let tilemap_entity = commands.spawn_empty().id();

    for x in 0..map_size.x {
        for y in 0..map_size.y {
            let tile_pos = TilePos { x, y };
            let tile_entity = commands.spawn((
                TileBundle {
                    position: tile_pos,
                    tilemap_id: TilemapId(tilemap_entity),
                    texture_index: TileTextureIndex(0),
                    ..default()
                },
                IsometricPosition { 
                    x: x as i32, 
                    y: y as i32 
                },
            )).id();
            
            tile_storage.set(&tile_pos, tile_entity);
        }
    }

    commands.entity(tilemap_entity).insert(TilemapBundle {
        grid_size: TilemapGridSize { x: 64.0, y: 32.0 },
        size: map_size,
        storage: tile_storage,
        texture: TilemapTexture::Single(texture),
        tile_size: TilemapTileSize { x: 64.0, y: 32.0 },
        map_type: TilemapType::Isometric(IsoCoordSystem::Diamond),
        anchor: TilemapAnchor::Center,
        ..default()
    });
}

fn update_cursor_position(
    cameras: Query<(&Camera, &GlobalTransform)>,
    windows: Query<&Window>,
    mut cursor_pos: ResMut<CursorWorldPosition>,
) {
    let (camera, camera_transform) = cameras.single();
    let window = windows.single();
    
    if let Some(position) = window.cursor_position() {
        if let Ok(world_pos) = camera.viewport_to_world_2d(
            camera_transform, 
            position
        ) {
            cursor_pos.0 = world_pos;
        }
    }
}

fn update_isometric_depth(
    mut tiles: Query<(&IsometricPosition, &mut Transform)>,
) {
    for (iso_pos, mut transform) in tiles.iter_mut() {
        transform.translation.z = 
            -(iso_pos.y as f32 * 1000.0 + iso_pos.x as f32);
    }
}

fn handle_tile_selection(
    mut commands: Commands,
    cursor_pos: Res<CursorWorldPosition>,
    tilemap_q: Query<(&Transform, &TileStorage)>,
    tile_q: Query<(Entity, &TilePos)>,
    selected_q: Query<Entity, With<SelectedTile>>,
    mouse: Res<ButtonInput<MouseButton>>,
) {
    if mouse.just_pressed(MouseButton::Left) {
        // Clear previous selection
        for entity in selected_q.iter() {
            commands.entity(entity).remove::<SelectedTile>();
        }
        
        // Select tile under cursor
        for (transform, storage) in tilemap_q.iter() {
            let local_pos = transform
                .compute_matrix()
                .inverse()
                .transform_point3(cursor_pos.0.extend(0.0))
                .truncate();
            
            let tile_x = ((local_pos.x / 32.0 + local_pos.y / 16.0) / 2.0)
                .round() as u32;
            let tile_y = ((local_pos.y / 16.0 - local_pos.x / 32.0) / 2.0)
                .round() as u32;
            
            if let Some(entity) = storage.get(&TilePos { x: tile_x, y: tile_y }) {
                commands.entity(entity).insert(SelectedTile);
            }
        }
    }
}

fn animate_selected_tiles(
    mut selected: Query<&mut TileTextureIndex, With<SelectedTile>>,
    time: Res<Time>,
) {
    for mut texture in selected.iter_mut() {
        texture.0 = ((time.elapsed_secs() * 2.0) as u32) % 4;
    }
}
```

## Conclusion

This comprehensive guide provides all the essential components for building isometric games in Bevy. The key to success lies in understanding the coordinate transformations, implementing proper depth sorting, and leveraging Bevy's ECS architecture for clean, performant code. Start with the basic camera setup and coordinate systems, then gradually add complexity with tilemaps, animations, and optimizations as your game grows.

Remember to profile early and often, use release builds for testing performance, and leverage community crates like `bevy_ecs_tilemap` for battle-tested implementations. With these patterns and techniques, you can build sophisticated isometric games that run smoothly even with thousands of entities.
