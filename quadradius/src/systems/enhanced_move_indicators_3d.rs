use crate::systems::{
    board_3d::TILE_SIZE_MULTIPLIER_3D,
    movement_powers::{JumpActive, MoveTwoActive, TeleportActive},
    pieces_3d::GamePiece3D,
    power_effects::MoveDiagonalActive,
};
use crate::{components::*, systems::isometric_camera::board_to_isometric};
use bevy::prelude::*;

// Constants matching pieces_3d.rs for consistent positioning
const ENHANCED_TILE_HEIGHT: f32 = 0.6; // Matches board_3d.rs tile height
const PIECE_HEIGHT: f32 = 0.2; // Height of piece cylinder
const PIECE_CLEARANCE: f32 = 2.0; // Same clearance as pieces

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
    selected_2d_pieces: Query<(Entity, &GamePiece), With<Selected>>,
    selected_3d_pieces: Query<(Entity, &GamePiece3D), With<Selected>>,
    existing_indicators: Query<Entity, With<ValidMoveIndicator3D>>,
    tiles: Query<&BoardTile>,
    all_2d_pieces: Query<(Entity, &GamePiece)>,
    all_3d_pieces: Query<(Entity, &GamePiece3D)>,
    diagonal_query: Query<Entity, With<MoveDiagonalActive>>,
    teleport_query: Query<Entity, With<TeleportActive>>,
    jump_query: Query<Entity, With<JumpActive>>,
    move_two_query: Query<Entity, With<MoveTwoActive>>,
    move_twice_query: Query<Entity, With<MoveTwiceActive>>,
) {
    // Clear existing indicators properly
    for entity in existing_indicators.iter() {
        commands.entity(entity).despawn();
    }
    
    // Debug: Check if any pieces are selected (both 2D and 3D)
    let selected_2d_count = selected_2d_pieces.iter().count();
    let selected_3d_count = selected_3d_pieces.iter().count();
    let total_selected = selected_2d_count + selected_3d_count;
    if total_selected > 0 {
        info!("🎯 3D Indicator System: Found {} selected pieces (2D: {}, 3D: {})", 
              total_selected, selected_2d_count, selected_3d_count);
    }

    // Create highlight mesh - square box to match board tile shape exactly
    let enhanced_tile_size = TILE_SIZE * TILE_SIZE_MULTIPLIER_3D;
    let highlight_mesh = meshes.add(Mesh::from(shape::Box::new(
        enhanced_tile_size * 0.85, // Match board tile width exactly
        enhanced_tile_size * 0.15, // Thinner than board tiles for distinction
        enhanced_tile_size * 0.85, // Match board tile depth exactly
    )));

    // Valid move material - very bright green with strong glow for visibility
    let valid_move_material = materials.add(StandardMaterial {
        base_color: Color::rgba(0.0, 1.0, 0.0, 0.9), // Bright pure green
        emissive: Color::rgb(0.2, 1.0, 0.2), // Strong green glow
        metallic: 0.2,
        perceptual_roughness: 0.1,
        alpha_mode: AlphaMode::Blend,
        ..default()
    });

    // Attack move material - very bright red with strong glow for visibility
    let attack_move_material = materials.add(StandardMaterial {
        base_color: Color::rgba(1.0, 0.0, 0.0, 0.9), // Bright pure red
        emissive: Color::rgb(1.0, 0.2, 0.2), // Strong red glow
        metallic: 0.2,
        perceptual_roughness: 0.1,
        alpha_mode: AlphaMode::Blend,
        ..default()
    });

    // Get piece positions for validation (both 2D and 3D pieces)
    let mut piece_positions: Vec<((u8, u8), Player, Entity)> = Vec::new();
    
    // Add 2D pieces
    for (entity, piece) in all_2d_pieces.iter() {
        piece_positions.push((piece.board_position, piece.player, entity));
    }
    
    // Add 3D pieces  
    for (entity, piece) in all_3d_pieces.iter() {
        piece_positions.push((piece.board_position, piece.player, entity));
    }

    // Process selected 2D pieces
    for (entity, piece) in selected_2d_pieces.iter() {
        let from = piece.board_position;
        info!("🎯 Processing selected 2D piece at {:?} for {:?}", from, piece.player);
        process_piece_indicators(
            &mut commands,
            &highlight_mesh,
            &valid_move_material,
            &attack_move_material,
            entity,
            from,
            piece.player,
            &tiles,
            &piece_positions,
            &diagonal_query,
            &teleport_query,
            &jump_query,
            &move_two_query,
            &move_twice_query,
        );
    }
    
    // Process selected 3D pieces
    for (entity, piece) in selected_3d_pieces.iter() {
        let from = piece.board_position;
        info!("🎯 Processing selected 3D piece at {:?} for {:?}", from, piece.player);
        process_piece_indicators(
            &mut commands,
            &highlight_mesh,
            &valid_move_material,
            &attack_move_material,
            entity,
            from,
            piece.player,
            &tiles,
            &piece_positions,
            &diagonal_query,
            &teleport_query,
            &jump_query,
            &move_two_query,
            &move_twice_query,
        );
    }
}

/// Helper function to process indicators for a single piece
fn process_piece_indicators(
    commands: &mut Commands,
    highlight_mesh: &Handle<Mesh>,
    valid_move_material: &Handle<StandardMaterial>,
    attack_move_material: &Handle<StandardMaterial>,
    entity: Entity,
    from: (u8, u8),
    player: Player,
    tiles: &Query<&BoardTile>,
    piece_positions: &[((u8, u8), Player, Entity)],
    diagonal_query: &Query<Entity, With<MoveDiagonalActive>>,
    teleport_query: &Query<Entity, With<TeleportActive>>,
    jump_query: &Query<Entity, With<JumpActive>>,
    move_two_query: &Query<Entity, With<MoveTwoActive>>,
    move_twice_query: &Query<Entity, With<MoveTwiceActive>>,
) {
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
                tiles,
                piece_positions,
                player,
                diagonal_query,
                teleport_query,
                jump_query,
                move_two_query,
                move_twice_query,
            ) {
                info!("✅ Valid move found: {:?} -> {:?}", from, to);
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
                    .any(|(pos, piece_player, _)| *pos == to && *piece_player != player);

                // Calculate indicator position to be at the bottom of where pieces would be
                let enhanced_tile_size = TILE_SIZE * TILE_SIZE_MULTIPLIER_3D;
                let tile_top_y = enhanced_tile_size * ENHANCED_TILE_HEIGHT / 2.0;
                let piece_bottom_y = world_pos.y + tile_top_y + PIECE_CLEARANCE;
                
                let indicator_pos = Vec3::new(
                    world_pos.x,
                    piece_bottom_y, // Position at piece bottom height
                    world_pos.z,
                );

                // Spawn enhanced 3D indicator at piece bottom height
                info!("🟢 Spawning 3D indicator at {:?} (world: {}, piece_bottom_y: {:.2})", 
                      to, world_pos, piece_bottom_y);
                commands.spawn((
                    ValidMoveIndicator3D { coordinates: to },
                    PbrBundle {
                        mesh: highlight_mesh.clone(),
                        material: if is_attack {
                            attack_move_material.clone()
                        } else {
                            valid_move_material.clone()
                        },
                        transform: Transform::from_translation(indicator_pos),
                        ..default()
                    },
                ));
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
