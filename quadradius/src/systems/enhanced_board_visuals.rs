use crate::components::*;
use bevy::prelude::*;

// Component for animated board tiles
#[derive(Component)]
pub struct AnimatedTile {
    pub base_color: Color,
    pub hover_color: Color,
    pub selected_color: Color,
}

// Component for height visualization
#[derive(Component)]
pub struct HeightIndicator {
    pub height: i8,
}

// Enhanced board setup with better visuals
pub fn setup_enhanced_board(
    mut commands: Commands,
    tiles: Query<(Entity, &BoardTile), Without<AnimatedTile>>,
) {
    for (entity, tile) in tiles.iter() {
        // Calculate color based on height for visual depth
        let height_factor = (tile.height as f32 + 2.0) / 4.0; // Normalize height to 0-1 range
        let base_color = Color::rgb(
            0.2 + height_factor * 0.3,
            0.3 + height_factor * 0.3,
            0.4 + height_factor * 0.2,
        );

        commands.entity(entity).insert((
            AnimatedTile {
                base_color,
                hover_color: Color::rgb(
                    base_color.r() + 0.2,
                    base_color.g() + 0.2,
                    base_color.b() + 0.2,
                ),
                selected_color: Color::rgb(
                    base_color.r() + 0.4,
                    base_color.g() + 0.4,
                    base_color.b() + 0.1,
                ),
            },
            HeightIndicator {
                height: tile.height,
            },
        ));
    }
}

// Add gradient background for better depth perception
pub fn setup_board_background(mut commands: Commands) {
    // Background gradient
    commands.spawn(SpriteBundle {
        sprite: Sprite {
            color: Color::rgb(0.05, 0.05, 0.1),
            custom_size: Some(Vec2::new(1000.0, 1000.0)),
            ..default()
        },
        transform: Transform::from_xyz(0.0, 0.0, -10.0),
        ..default()
    });

    // Board frame
    let frame_thickness = 10.0;
    let board_size = BOARD_SIZE as f32 * TILE_SIZE + frame_thickness * 2.0;

    // Top frame
    commands.spawn(SpriteBundle {
        sprite: Sprite {
            color: Color::rgb(0.3, 0.25, 0.2),
            custom_size: Some(Vec2::new(board_size, frame_thickness)),
            ..default()
        },
        transform: Transform::from_xyz(0.0, board_size / 2.0 - frame_thickness / 2.0, -1.0),
        ..default()
    });

    // Bottom frame
    commands.spawn(SpriteBundle {
        sprite: Sprite {
            color: Color::rgb(0.3, 0.25, 0.2),
            custom_size: Some(Vec2::new(board_size, frame_thickness)),
            ..default()
        },
        transform: Transform::from_xyz(0.0, -board_size / 2.0 + frame_thickness / 2.0, -1.0),
        ..default()
    });

    // Left frame
    commands.spawn(SpriteBundle {
        sprite: Sprite {
            color: Color::rgb(0.3, 0.25, 0.2),
            custom_size: Some(Vec2::new(frame_thickness, board_size)),
            ..default()
        },
        transform: Transform::from_xyz(-board_size / 2.0 + frame_thickness / 2.0, 0.0, -1.0),
        ..default()
    });

    // Right frame
    commands.spawn(SpriteBundle {
        sprite: Sprite {
            color: Color::rgb(0.3, 0.25, 0.2),
            custom_size: Some(Vec2::new(frame_thickness, board_size)),
            ..default()
        },
        transform: Transform::from_xyz(board_size / 2.0 - frame_thickness / 2.0, 0.0, -1.0),
        ..default()
    });
}

// Animate tiles based on game state
pub fn animate_board_tiles(
    time: Res<Time>,
    mut tiles: Query<(&AnimatedTile, &HeightIndicator, &mut Sprite, &mut Transform)>,
    windows: Query<&Window>,
    camera_q: Query<(&Camera, &GlobalTransform)>,
) {
    let window = windows.single();
    let (camera, camera_transform) = camera_q.single();

    if let Some(cursor_pos) = window.cursor_position() {
        if let Some(world_pos) = camera.viewport_to_world_2d(camera_transform, cursor_pos) {
            for (anim_tile, height_ind, mut sprite, mut transform) in tiles.iter_mut() {
                let tile_pos = Vec2::new(transform.translation.x, transform.translation.y);
                let distance = tile_pos.distance(world_pos);

                // Hover effect
                if distance < TILE_SIZE / 2.0 {
                    sprite.color = anim_tile.hover_color;
                    // Subtle scale animation on hover
                    let scale = 1.0 + (time.elapsed_seconds() * 3.0).sin() * 0.02;
                    transform.scale = Vec3::splat(scale);
                } else {
                    sprite.color = anim_tile.base_color;
                    transform.scale = Vec3::ONE;
                }

                // Height-based animation
                let height_offset =
                    (time.elapsed_seconds() * 2.0 + height_ind.height as f32).sin() * 0.5;
                transform.translation.z =
                    -5.0 + height_ind.height as f32 * 0.1 + height_offset * 0.1;
            }
        }
    }
}

// Enhanced piece rendering with shadows
pub fn enhance_piece_visuals(
    mut commands: Commands,
    pieces: Query<(Entity, &GamePiece, &Transform), Without<PieceShadow>>,
) {
    for (entity, piece, transform) in pieces.iter() {
        // Add shadow
        let shadow_entity = commands
            .spawn((
                PieceShadow { parent: entity },
                SpriteBundle {
                    sprite: Sprite {
                        color: Color::rgba(0.0, 0.0, 0.0, 0.3),
                        custom_size: Some(Vec2::splat(TILE_SIZE * 0.7)),
                        ..default()
                    },
                    transform: Transform::from_xyz(
                        transform.translation.x + 5.0,
                        transform.translation.y - 5.0,
                        transform.translation.z - 0.1,
                    ),
                    ..default()
                },
            ))
            .id();

        // Add glow effect to pieces
        commands.entity(entity).insert(PieceGlow {
            intensity: 0.0,
            color: match piece.player {
                Player::Player1 => Color::rgb(1.0, 0.3, 0.3),
                Player::Player2 => Color::rgb(0.3, 0.3, 1.0),
            },
        });
    }
}

#[derive(Component)]
pub struct PieceShadow {
    pub parent: Entity,
}

#[derive(Component)]
pub struct PieceGlow {
    pub intensity: f32,
    pub color: Color,
}

// Update shadows to follow pieces
pub fn update_piece_shadows(
    pieces: Query<&Transform, With<GamePiece>>,
    mut shadows: Query<(&PieceShadow, &mut Transform), Without<GamePiece>>,
) {
    for (shadow, mut shadow_transform) in shadows.iter_mut() {
        if let Ok(piece_transform) = pieces.get(shadow.parent) {
            shadow_transform.translation.x = piece_transform.translation.x + 5.0;
            shadow_transform.translation.y = piece_transform.translation.y - 5.0;
            shadow_transform.translation.z = piece_transform.translation.z - 0.1;
        }
    }
}

// Glow effect for selected pieces
pub fn update_piece_glow(
    time: Res<Time>,
    mut pieces: Query<(&PieceGlow, &mut Sprite, Option<&Dragging>)>,
) {
    for (glow, mut sprite, dragging) in pieces.iter_mut() {
        if dragging.is_some() {
            // Pulsing glow when dragging
            let intensity = (time.elapsed_seconds() * 4.0).sin() * 0.5 + 0.5;
            let glow_color = Color::rgb(
                sprite.color.r() + glow.color.r() * intensity * 0.3,
                sprite.color.g() + glow.color.g() * intensity * 0.3,
                sprite.color.b() + glow.color.b() * intensity * 0.3,
            );
            sprite.color = glow_color;
        }
    }
}
