use crate::components::*;
use bevy::prelude::*;

// Height-based movement rules and terrain system
pub const MAX_HEIGHT: i8 = 5;
pub const MIN_HEIGHT: i8 = -2;
pub const HEIGHT_VISUAL_SCALE: f32 = 10.0; // Visual elevation per height level

#[derive(Component)]
pub struct TerrainHeight {
    pub height: i8,
    pub visual_offset: f32,
}

#[derive(Component)]
pub struct HeightIndicator;

#[derive(Component)]
pub struct TerrainAnimation {
    pub start_height: i8,
    pub target_height: i8,
    pub duration: f32,
    pub elapsed: f32,
}

// Initialize board with default heights
pub fn initialize_terrain_heights(
    mut commands: Commands,
    mut tiles: Query<(Entity, &mut BoardTile)>,
) {
    for (entity, mut tile) in tiles.iter_mut() {
        // Initialize all tiles to height 0 (ground level)
        tile.height = 0;

        commands.entity(entity).insert(TerrainHeight {
            height: 0,
            visual_offset: 0.0,
        });
    }

    println!("🏔️ Terrain height system initialized - all tiles at ground level");
}

// Update visual representation based on tile heights
pub fn update_terrain_visuals(
    mut tiles: Query<(&BoardTile, &mut Transform, &TerrainHeight), Changed<TerrainHeight>>,
) {
    for (tile, mut transform, terrain) in tiles.iter_mut() {
        // Adjust Y position based on height
        let base_y = tile.coordinates.1 as f32 * 75.0 - 262.5;
        transform.translation.y = base_y + (terrain.height as f32 * HEIGHT_VISUAL_SCALE);

        // Adjust Z position for proper layering
        transform.translation.z = 0.1 + (terrain.height as f32 * 0.01);
    }
}

// Update tile sprites to show height differences
pub fn update_height_sprite_colors(
    mut tiles: Query<(&BoardTile, &mut Sprite, &TerrainHeight), Changed<TerrainHeight>>,
) {
    for (_, mut sprite, terrain) in tiles.iter_mut() {
        // Color tiles based on height for visual feedback
        let height_factor = (terrain.height + 2) as f32 / 7.0; // Normalize to 0-1

        sprite.color = match terrain.height {
            h if h < 0 => Color::rgb(0.3, 0.3, 0.6), // Blue for below ground
            0 => Color::rgb(0.5, 0.4, 0.3),          // Brown for ground level
            1 => Color::rgb(0.6, 0.5, 0.4),          // Light brown for level 1
            2 => Color::rgb(0.7, 0.6, 0.5),          // Lighter brown for level 2
            3 => Color::rgb(0.8, 0.7, 0.6),          // Tan for level 3
            4 => Color::rgb(0.9, 0.8, 0.7),          // Light tan for level 4
            _ => Color::rgb(1.0, 0.9, 0.8),          // Nearly white for max height
        };
    }
}

// Validate movement based on height differences
pub fn is_valid_height_movement(
    from_pos: (u8, u8),
    to_pos: (u8, u8),
    tiles: &Query<&BoardTile>,
) -> bool {
    let from_tile = tiles.iter().find(|tile| tile.coordinates == from_pos);
    let to_tile = tiles.iter().find(|tile| tile.coordinates == to_pos);

    if let (Some(from), Some(to)) = (from_tile, to_tile) {
        let height_diff = to.height - from.height;

        // Core Quadradius rule: Can move down any amount, can only move up 1 level
        if height_diff <= 1 {
            return true;
        } else {
            println!("❌ Cannot move up {} levels (max 1)", height_diff);
            return false;
        }
    }

    false
}

// Raise a column of tiles
pub fn raise_column(
    column: u8,
    tiles: &mut Query<(Entity, &mut BoardTile, &mut TerrainHeight)>,
    commands: &mut Commands,
) {
    println!("⬆️ Raising column {}", column);

    let mut affected_tiles = 0;

    for (entity, mut tile, mut terrain) in tiles.iter_mut() {
        if tile.coordinates.0 == column && tile.height < MAX_HEIGHT {
            let old_height = tile.height;
            tile.height += 1;
            terrain.height = tile.height;

            // Add animation component
            commands.entity(entity).insert(TerrainAnimation {
                start_height: old_height,
                target_height: tile.height,
                duration: 0.5,
                elapsed: 0.0,
            });

            affected_tiles += 1;
            println!(
                "  Tile ({}, {}) raised from {} to {}",
                tile.coordinates.0, tile.coordinates.1, old_height, tile.height
            );
        }
    }

    if affected_tiles == 0 {
        println!("  No tiles could be raised (already at max height)");
    }
}

// Lower a column of tiles
pub fn lower_column(
    column: u8,
    tiles: &mut Query<(Entity, &mut BoardTile, &mut TerrainHeight)>,
    commands: &mut Commands,
) {
    println!("⬇️ Lowering column {}", column);

    let mut affected_tiles = 0;

    for (entity, mut tile, mut terrain) in tiles.iter_mut() {
        if tile.coordinates.0 == column && tile.height > MIN_HEIGHT {
            let old_height = tile.height;
            tile.height -= 1;
            terrain.height = tile.height;

            // Add animation component
            commands.entity(entity).insert(TerrainAnimation {
                start_height: old_height,
                target_height: tile.height,
                duration: 0.5,
                elapsed: 0.0,
            });

            affected_tiles += 1;
            println!(
                "  Tile ({}, {}) lowered from {} to {}",
                tile.coordinates.0, tile.coordinates.1, old_height, tile.height
            );
        }
    }

    if affected_tiles == 0 {
        println!("  No tiles could be lowered (already at min height)");
    }
}

// Destroy a column (set to minimum height and remove pieces)
pub fn destroy_column(
    column: u8,
    tiles: &mut Query<(Entity, &mut BoardTile, &mut TerrainHeight)>,
    pieces: &Query<(Entity, &GamePiece)>,
    commands: &mut Commands,
) {
    println!("💥 Destroying column {}", column);

    // Lower all tiles in column to minimum height
    for (entity, mut tile, mut terrain) in tiles.iter_mut() {
        if tile.coordinates.0 == column {
            let old_height = tile.height;
            tile.height = MIN_HEIGHT;
            terrain.height = tile.height;

            // Add dramatic animation
            commands.entity(entity).insert(TerrainAnimation {
                start_height: old_height,
                target_height: tile.height,
                duration: 1.0,
                elapsed: 0.0,
            });

            println!(
                "  Tile ({}, {}) destroyed (height {} -> {})",
                tile.coordinates.0, tile.coordinates.1, old_height, tile.height
            );
        }
    }

    // Remove all pieces in the column
    let mut destroyed_pieces = 0;
    for (entity, piece) in pieces.iter() {
        if piece.board_position.0 == column {
            if let Some(mut entity_commands) = commands.get_entity(entity) {
                entity_commands.despawn();
            }
            destroyed_pieces += 1;
            println!(
                "  Destroyed piece at ({}, {})",
                piece.board_position.0, piece.board_position.1
            );
        }
    }

    // Spawn destruction visual effect
    spawn_column_destruction_effect(commands, column);

    println!(
        "  Column {} destroyed: {} pieces removed",
        column, destroyed_pieces
    );
}

// Animate terrain height changes
pub fn animate_terrain_changes(
    mut commands: Commands,
    time: Res<Time>,
    mut animated_tiles: Query<(Entity, &mut TerrainHeight, &mut TerrainAnimation)>,
) {
    for (entity, mut terrain, mut animation) in animated_tiles.iter_mut() {
        animation.elapsed += time.delta_seconds();

        if animation.elapsed >= animation.duration {
            // Animation complete
            terrain.height = animation.target_height;
            commands.entity(entity).remove::<TerrainAnimation>();
        } else {
            // Interpolate height for smooth animation
            let progress = animation.elapsed / animation.duration;
            let current_height = animation.start_height as f32
                + (animation.target_height - animation.start_height) as f32 * progress;

            terrain.visual_offset = (current_height - terrain.height as f32) * HEIGHT_VISUAL_SCALE;
        }
    }
}

// Spawn visual effects for column destruction
fn spawn_column_destruction_effect(commands: &mut Commands, column: u8) {
    for row in 0..8 {
        let world_x = column as f32 * 75.0 - 262.5;
        let world_y = row as f32 * 75.0 - 262.5;

        // Spawn explosion particles
        for _ in 0..5 {
            let offset_x = (rand::random::<f32>() - 0.5) * 40.0;
            let offset_y = (rand::random::<f32>() - 0.5) * 40.0;

            commands.spawn((
                SpriteBundle {
                    sprite: Sprite {
                        color: Color::rgb(1.0, 0.5, 0.0),
                        custom_size: Some(Vec2::new(8.0, 8.0)),
                        ..default()
                    },
                    transform: Transform::from_translation(Vec3::new(
                        world_x + offset_x,
                        world_y + offset_y,
                        2.0,
                    )),
                    ..default()
                },
                crate::systems::visual_effects::ParticleEffect {
                    lifetime: 1.0,
                    max_lifetime: 1.0,
                    velocity: Vec3::new(
                        (rand::random::<f32>() - 0.5) * 200.0,
                        (rand::random::<f32>() - 0.5) * 200.0,
                        0.0,
                    ),
                    color: Color::rgb(1.0, 0.5, 0.0),
                    size: 8.0,
                },
            ));
        }
    }
}

// Create height indicators for tiles
pub fn spawn_height_indicators(
    mut commands: Commands,
    tiles: Query<(&BoardTile, &TerrainHeight), Added<TerrainHeight>>,
) {
    for (tile, terrain) in tiles.iter() {
        if terrain.height != 0 {
            let world_x = tile.coordinates.0 as f32 * 75.0 - 262.5;
            let world_y = tile.coordinates.1 as f32 * 75.0 - 262.5;

            commands.spawn((
                Text2dBundle {
                    text: Text::from_section(
                        format!("{}", terrain.height),
                        TextStyle {
                            font_size: 16.0,
                            color: if terrain.height > 0 {
                                Color::WHITE
                            } else {
                                Color::rgb(0.8, 0.8, 1.0)
                            },
                            ..default()
                        },
                    ),
                    transform: Transform::from_translation(Vec3::new(
                        world_x + 25.0,
                        world_y + 25.0,
                        3.0,
                    )),
                    ..default()
                },
                HeightIndicator,
            ));
        }
    }
}

// Update height indicators when terrain changes
pub fn update_height_indicators(
    mut commands: Commands,
    changed_tiles: Query<(&BoardTile, &TerrainHeight), Changed<TerrainHeight>>,
    indicators: Query<(Entity, &mut Text, &Transform), With<HeightIndicator>>,
) {
    if !changed_tiles.is_empty() {
        // Remove old indicators
        for (entity, _, _) in indicators.iter() {
            if let Some(mut entity_commands) = commands.get_entity(entity) {
                entity_commands.despawn();
            }
        }

        // Respawn all indicators (simplified approach)
        // In a real implementation, we'd only update changed ones
        for (tile, terrain) in changed_tiles.iter() {
            if terrain.height != 0 {
                let world_x = tile.coordinates.0 as f32 * 75.0 - 262.5;
                let world_y = tile.coordinates.1 as f32 * 75.0 - 262.5;

                commands.spawn((
                    Text2dBundle {
                        text: Text::from_section(
                            format!("{}", terrain.height),
                            TextStyle {
                                font_size: 16.0,
                                color: if terrain.height > 0 {
                                    Color::WHITE
                                } else {
                                    Color::rgb(0.8, 0.8, 1.0)
                                },
                                ..default()
                            },
                        ),
                        transform: Transform::from_translation(Vec3::new(
                            world_x + 25.0,
                            world_y + 25.0,
                            3.0,
                        )),
                        ..default()
                    },
                    HeightIndicator,
                ));
            }
        }
    }
}

// Debug commands for testing terrain
pub fn debug_terrain_commands(
    keyboard: Res<Input<KeyCode>>,
    tiles: Query<&BoardTile>,
    mut terrain_tiles: Query<(Entity, &mut BoardTile, &mut TerrainHeight)>,
    pieces: Query<(Entity, &GamePiece)>,
    mut commands: Commands,
) {
    // Column raise/lower debug controls
    if keyboard.just_pressed(KeyCode::F1) {
        raise_column(0, &mut terrain_tiles, &mut commands);
    }
    if keyboard.just_pressed(KeyCode::F2) {
        lower_column(0, &mut terrain_tiles, &mut commands);
    }
    if keyboard.just_pressed(KeyCode::F3) {
        destroy_column(0, &mut terrain_tiles, &pieces, &mut commands);
    }

    // Test height movement validation
    if keyboard.just_pressed(KeyCode::F4) {
        println!("\n🔍 Testing height movement validation:");
        for tile in tiles.iter() {
            if tile.coordinates == (0, 0) {
                println!("  Tile (0,0) height: {}", tile.height);

                // Test movement to adjacent tiles
                let adjacent = [(0, 1), (1, 0), (1, 1)];
                for &pos in &adjacent {
                    if is_valid_height_movement((0, 0), pos, &tiles) {
                        println!("    ✅ Can move to ({}, {})", pos.0, pos.1);
                    } else {
                        println!("    ❌ Cannot move to ({}, {})", pos.0, pos.1);
                    }
                }
                break;
            }
        }
    }

    // Print height map
    if keyboard.just_pressed(KeyCode::H) {
        println!("\n🗺️ TERRAIN HEIGHT MAP:");
        for row in (0..8).rev() {
            print!("  Row {}: ", row);
            for col in 0..8 {
                if let Some(tile) = tiles.iter().find(|t| t.coordinates == (col, row)) {
                    print!("{:3}", tile.height);
                } else {
                    print!("  ?");
                }
            }
            println!();
        }
        println!("       Col: 0  1  2  3  4  5  6  7");
    }
}

// Integrate terrain rules into movement validation
pub fn validate_movement_with_terrain(
    from_pos: (u8, u8),
    to_pos: (u8, u8),
    tiles: &Query<&BoardTile>,
) -> bool {
    // First check basic movement rules (diagonal, distance, etc.)
    let dx = (to_pos.0 as i8 - from_pos.0 as i8).abs();
    let dy = (to_pos.1 as i8 - from_pos.1 as i8).abs();

    // Basic checkers movement (diagonal only, one step)
    if dx != 1 || dy != 1 {
        return false;
    }

    // Then check height restrictions
    is_valid_height_movement(from_pos, to_pos, tiles)
}

// Get terrain height at position
pub fn get_terrain_height(pos: (u8, u8), tiles: &Query<&BoardTile>) -> Option<i8> {
    tiles
        .iter()
        .find(|tile| tile.coordinates == pos)
        .map(|tile| tile.height)
}

// Check if position is accessible (not too deep)
pub fn is_position_accessible(pos: (u8, u8), tiles: &Query<&BoardTile>) -> bool {
    if let Some(height) = get_terrain_height(pos, tiles) {
        height > MIN_HEIGHT
    } else {
        false
    }
}

// Helper functions for power effects
pub fn raise_single_tile(
    x: u8,
    y: u8,
    tiles: &mut Query<(Entity, &mut BoardTile, &mut TerrainHeight)>,
    commands: &mut Commands,
) {
    for (entity, mut tile, mut terrain) in tiles.iter_mut() {
        if tile.coordinates == (x, y) {
            let old_height = tile.height;
            tile.height = (tile.height + 1).min(MAX_HEIGHT);
            terrain.height = tile.height;

            // Add animation
            commands.entity(entity).insert(TerrainAnimation {
                start_height: old_height,
                target_height: tile.height,
                duration: 0.3,
                elapsed: 0.0,
            });
            break;
        }
    }
}

pub fn lower_single_tile(
    x: u8,
    y: u8,
    tiles: &mut Query<(Entity, &mut BoardTile, &mut TerrainHeight)>,
    commands: &mut Commands,
) {
    for (entity, mut tile, mut terrain) in tiles.iter_mut() {
        if tile.coordinates == (x, y) {
            let old_height = tile.height;
            tile.height = (tile.height - 1).max(MIN_HEIGHT);
            terrain.height = tile.height;

            // Add animation
            commands.entity(entity).insert(TerrainAnimation {
                start_height: old_height,
                target_height: tile.height,
                duration: 0.3,
                elapsed: 0.0,
            });
            break;
        }
    }
}

pub fn set_tile_height(
    x: u8,
    y: u8,
    height: i8,
    tiles: &mut Query<(Entity, &mut BoardTile, &mut TerrainHeight)>,
    commands: &mut Commands,
) {
    for (entity, mut tile, mut terrain) in tiles.iter_mut() {
        if tile.coordinates == (x, y) {
            let old_height = tile.height;
            tile.height = height.clamp(MIN_HEIGHT, MAX_HEIGHT);
            terrain.height = tile.height;

            // Add animation
            commands.entity(entity).insert(TerrainAnimation {
                start_height: old_height,
                target_height: tile.height,
                duration: 0.5,
                elapsed: 0.0,
            });
            break;
        }
    }
}
