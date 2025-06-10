use crate::systems::{
    movement_powers::{JumpActive, MoveTwoActive, TeleportActive},
    power_effects::MoveDiagonalActive,
};
use crate::{components::*, systems::isometric_camera::board_to_isometric};
use bevy::prelude::*;

/// 3D Valid move indicator component
#[derive(Component)]
pub struct ValidMoveIndicator3D {
    pub coordinates: (u8, u8),
}

/// Enhanced system to show valid moves with proper 3D highlighting
pub fn show_valid_moves_for_powers_3d(
    mut commands: Commands,
    mut meshes: ResMut<Assets<Mesh>>,
    mut materials: ResMut<Assets<StandardMaterial>>,
    selected_pieces: Query<(Entity, &GamePiece, &BoardTile), With<Selected>>,
    tiles: Query<&BoardTile>,
    piece_query: Query<&BoardTile, With<GamePiece>>,
    diagonal_query: Query<Entity, With<MoveDiagonalActive>>,
    teleport_query: Query<Entity, With<TeleportActive>>,
    jump_query: Query<Entity, With<JumpActive>>,
    move_two_query: Query<Entity, With<MoveTwoActive>>,
    move_twice_query: Query<Entity, With<MoveTwiceActive>>,
) {
    // Clear existing indicators
    let indicators = commands
        .spawn_empty()
        .insert(ValidMoveIndicator3D {
            coordinates: (0, 0),
        })
        .id();
    commands.entity(indicators).despawn();

    // Create highlight mesh - glowing ring above tiles
    let highlight_mesh = meshes.add(Mesh::from(shape::Cylinder {
        radius: TILE_SIZE * 0.6,
        height: TILE_SIZE * 0.05,
        resolution: 16,
        segments: 1,
    }));

    // Valid move material - bright green with strong glow
    let valid_move_material = materials.add(StandardMaterial {
        base_color: Color::rgba(0.2, 1.0, 0.3, 0.8),
        emissive: Color::rgb(0.1, 0.6, 0.15),
        metallic: 0.0,
        perceptual_roughness: 0.1,
        alpha_mode: AlphaMode::Blend,
        ..default()
    });

    // Attack move material - red with strong glow
    let attack_move_material = materials.add(StandardMaterial {
        base_color: Color::rgba(1.0, 0.3, 0.2, 0.8),
        emissive: Color::rgb(0.6, 0.15, 0.1),
        metallic: 0.0,
        perceptual_roughness: 0.1,
        alpha_mode: AlphaMode::Blend,
        ..default()
    });

    // Get piece positions for validation
    let piece_positions: Vec<((u8, u8), Player, Entity)> = piece_query
        .iter()
        .enumerate()
        .map(|(i, tile)| {
            (
                tile.coordinates,
                Player::Player1,
                Entity::from_raw(i as u32),
            )
        })
        .collect();

    for (entity, piece, tile) in selected_pieces.iter() {
        let from = tile.coordinates;

        // Check all possible positions on the enhanced 10x8 board
        for x in 0..BOARD_WIDTH {
            for y in 0..BOARD_HEIGHT {
                let to = (x, y);

                // Skip if same position
                if from == to {
                    continue;
                }

                if validate_enhanced_movement_3d(
                    from,
                    to,
                    entity,
                    &tiles,
                    &piece_positions,
                    piece.player,
                    &diagonal_query,
                    &teleport_query,
                    &jump_query,
                    &move_two_query,
                    &move_twice_query,
                ) {
                    // Get the height of the target tile
                    let target_height = tiles
                        .iter()
                        .find(|t| t.coordinates == to)
                        .map(|t| t.height as f32)
                        .unwrap_or(0.0);

                    let world_pos = board_to_isometric(to, target_height);

                    // Check if target is occupied by enemy (attack move)
                    let is_attack = piece_positions
                        .iter()
                        .any(|(pos, player, _)| *pos == to && *player != piece.player);

                    // Spawn enhanced 3D indicator above the tile
                    commands.spawn((
                        ValidMoveIndicator3D { coordinates: to },
                        PbrBundle {
                            mesh: highlight_mesh.clone(),
                            material: if is_attack {
                                attack_move_material.clone()
                            } else {
                                valid_move_material.clone()
                            },
                            transform: Transform::from_translation(
                                world_pos + Vec3::Y * TILE_SIZE * 0.3, // Hover above tile
                            ),
                            ..default()
                        },
                    ));
                }
            }
        }
    }
}

/// Enhanced movement validation for 3D board
fn validate_enhanced_movement_3d(
    from: (u8, u8),
    to: (u8, u8),
    entity: Entity,
    tiles: &Query<&BoardTile>,
    piece_positions: &[((u8, u8), Player, Entity)],
    current_player: Player,
    diagonal_query: &Query<Entity, With<MoveDiagonalActive>>,
    teleport_query: &Query<Entity, With<TeleportActive>>,
    jump_query: &Query<Entity, With<JumpActive>>,
    move_two_query: &Query<Entity, With<MoveTwoActive>>,
    move_twice_query: &Query<Entity, With<MoveTwiceActive>>,
) -> bool {
    // Check bounds for 10x8 board
    if to.0 >= BOARD_WIDTH || to.1 >= BOARD_HEIGHT {
        return false;
    }

    // Check if target is occupied by friendly piece
    for (pos, player, _) in piece_positions.iter() {
        if *pos == to && *player == current_player {
            return false; // Can't capture own piece
        }
    }

    // Check for special movement powers
    if teleport_query.contains(entity) {
        return true; // Teleport can move anywhere
    }

    if move_two_query.contains(entity) {
        let dx = (to.0 as i8 - from.0 as i8).abs();
        let dy = (to.1 as i8 - from.1 as i8).abs();
        return (dx == 2 && dy == 0) || (dx == 0 && dy == 2);
    }

    if move_twice_query.contains(entity) {
        // Move twice allows normal movement rules but twice per turn
        let dx = (to.0 as i8 - from.0 as i8).abs();
        let dy = (to.1 as i8 - from.1 as i8).abs();
        return (dx == 1 && dy == 0)
            || (dx == 0 && dy == 1)
            || (diagonal_query.contains(entity) && dx == 1 && dy == 1);
    }

    // Enhanced movement with diagonal support
    let dx = (to.0 as i8 - from.0 as i8).abs();
    let dy = (to.1 as i8 - from.1 as i8).abs();

    // Basic orthogonal movement (always allowed)
    if (dx == 1 && dy == 0) || (dx == 0 && dy == 1) {
        return validate_height_movement(from, to, tiles);
    }

    // Diagonal movement (if power is active)
    if diagonal_query.contains(entity) && dx == 1 && dy == 1 {
        return validate_height_movement(from, to, tiles);
    }

    false
}

/// Validate height-based movement rules
fn validate_height_movement(from: (u8, u8), to: (u8, u8), tiles: &Query<&BoardTile>) -> bool {
    let from_height = tiles
        .iter()
        .find(|t| t.coordinates == from)
        .map(|t| t.height)
        .unwrap_or(0);

    let to_height = tiles
        .iter()
        .find(|t| t.coordinates == to)
        .map(|t| t.height)
        .unwrap_or(0);

    // Can move down any amount, can only move up 1 level
    if to_height > from_height {
        (to_height - from_height) <= 1
    } else {
        true // Can always move down or stay level
    }
}

/// Clean up valid move indicators
pub fn cleanup_valid_move_indicators_3d(
    mut commands: Commands,
    indicators: Query<Entity, With<ValidMoveIndicator3D>>,
) {
    for entity in indicators.iter() {
        commands.entity(entity).despawn();
    }
}
