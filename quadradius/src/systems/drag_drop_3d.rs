use crate::{
    components::*,
    resources::*,
    systems::{
        isometric_camera::{screen_to_board, IsometricCamera},
        pieces_3d::GamePiece3D,
        MoveDiagonalActive,
    },
};
use bevy::prelude::*;

/// Component to track which piece is being dragged in 3D
#[derive(Component)]
pub struct Dragging3D {
    pub start_pos: (u8, u8),
}

/// Component for valid move indicators in 3D
#[derive(Component)]
pub struct ValidMoveIndicator3D;

/// Handle drag start for 3D pieces
pub fn handle_drag_start_3d(
    mut commands: Commands,
    mouse_input: Res<Input<MouseButton>>,
    windows: Query<&Window>,
    camera_q: Query<(&Camera, &GlobalTransform), With<IsometricCamera>>,
    game_state: Res<GameState>,
    pieces: Query<(Entity, &GamePiece3D), Without<Dragging3D>>,
    diagonal_pieces: Query<Entity, With<MoveDiagonalActive>>,
    tiles: Query<&BoardTile>,
) {
    if !mouse_input.just_pressed(MouseButton::Left) {
        return;
    }

    // Only allow dragging during piece movement phase
    if game_state.turn_phase != TurnPhase::PieceMovement {
        return;
    }

    let window = windows.single();
    if let Some(cursor_pos) = window.cursor_position() {
        // Convert screen position to board coordinates
        if let Some(board_pos) = screen_to_board(&windows, &camera_q, cursor_pos) {
            // Check if there's a piece at this position
            for (entity, piece) in pieces.iter() {
                if piece.board_position == board_pos && piece.player == game_state.current_player {
                    // Start dragging this piece
                    commands.entity(entity).insert(Dragging3D {
                        start_pos: board_pos,
                    });

                    // Check if this piece can move diagonally
                    let can_move_diagonal = diagonal_pieces.iter().any(|e| e == entity);

                    // TODO: Show valid moves in 3D - needs to be a separate system
                    // For now, just log that we started dragging

                    info!("Started dragging piece at {:?}", board_pos);
                    break;
                }
            }
        }
    }
}

/// Handle drag update for 3D pieces
pub fn handle_drag_update_3d(
    mut pieces: Query<(&mut Transform, &GamePiece3D), With<Dragging3D>>,
    windows: Query<&Window>,
    camera_q: Query<(&Camera, &GlobalTransform), With<IsometricCamera>>,
    tiles: Query<&BoardTile>,
) {
    let window = windows.single();
    if let Some(cursor_pos) = window.cursor_position() {
        if let Some(board_pos) = screen_to_board(&windows, &camera_q, cursor_pos) {
            for (mut transform, _piece) in pieces.iter_mut() {
                // Get tile height at hover position
                let height = tiles
                    .iter()
                    .find(|tile| tile.coordinates == board_pos)
                    .map(|tile| tile.height)
                    .unwrap_or(0) as f32;

                // Update piece position to follow cursor
                let world_pos = crate::systems::isometric_camera::board_to_isometric(board_pos, height);
                transform.translation = Vec3::new(
                    world_pos.x,
                    world_pos.y + TILE_SIZE * 0.5, // Float above tile
                    world_pos.z,
                );
            }
        }
    }
}

/// Handle drag end for 3D pieces
pub fn handle_drag_end_3d(
    mut commands: Commands,
    mouse_input: Res<Input<MouseButton>>,
    windows: Query<&Window>,
    camera_q: Query<(&Camera, &GlobalTransform), With<IsometricCamera>>,
    mut game_state: ResMut<GameState>,
    mut pieces: Query<(Entity, &mut GamePiece3D, &mut Transform, &Dragging3D)>,
    all_pieces: Query<(Entity, &GamePiece3D), Without<Dragging3D>>,
    tiles: Query<&BoardTile>,
    valid_indicators: Query<Entity, With<ValidMoveIndicator3D>>,
    // No turn complete events for now
) {
    if !mouse_input.just_released(MouseButton::Left) {
        return;
    }

    // Clean up indicators
    for entity in valid_indicators.iter() {
        commands.entity(entity).despawn();
    }

    let window = windows.single();
    if let Some(cursor_pos) = window.cursor_position() {
        if let Some(target_pos) = screen_to_board(&windows, &camera_q, cursor_pos) {
            for (entity, mut piece, mut transform, dragging) in pieces.iter_mut() {
                let start_pos = dragging.start_pos;

                // Check if move is valid
                if is_valid_move(start_pos, target_pos, &tiles, &all_pieces) {
                    // Check for capture
                    let mut captured_entity = None;
                    for (other_entity, other_piece) in all_pieces.iter() {
                        if other_piece.board_position == target_pos {
                            captured_entity = Some(other_entity);
                            break;
                        }
                    }

                    // Perform capture if needed
                    if let Some(captured) = captured_entity {
                        commands.entity(captured).despawn_recursive();
                        info!("Captured piece at {:?}", target_pos);
                    }

                    // Update piece position
                    piece.board_position = target_pos;
                    
                    // Update transform to final position
                    let height = tiles
                        .iter()
                        .find(|tile| tile.coordinates == target_pos)
                        .map(|tile| tile.height)
                        .unwrap_or(0) as f32;
                    
                    let world_pos = crate::systems::isometric_camera::board_to_isometric(target_pos, height);
                    transform.translation = Vec3::new(
                        world_pos.x,
                        world_pos.y + TILE_SIZE * 0.35,
                        world_pos.z,
                    );

                    // End turn
                    game_state.turn_phase = TurnPhase::PowerActivation;

                    info!("Moved piece from {:?} to {:?}", start_pos, target_pos);
                } else {
                    // Invalid move - return to original position
                    let height = tiles
                        .iter()
                        .find(|tile| tile.coordinates == start_pos)
                        .map(|tile| tile.height)
                        .unwrap_or(0) as f32;
                    
                    let world_pos = crate::systems::isometric_camera::board_to_isometric(start_pos, height);
                    transform.translation = Vec3::new(
                        world_pos.x,
                        world_pos.y + TILE_SIZE * 0.35,
                        world_pos.z,
                    );

                    info!("Invalid move - returning piece to {:?}", start_pos);
                }

                // Remove dragging component
                commands.entity(entity).remove::<Dragging3D>();
            }
        }
    }
}

/// Show valid moves for a piece in 3D
pub fn show_valid_moves_3d(
    mut commands: Commands,
    mut meshes: ResMut<Assets<Mesh>>,
    mut materials: ResMut<Assets<StandardMaterial>>,
    from: (u8, u8),
    tiles: &Query<&BoardTile>,
    game_state: &GameState,
    can_move_diagonal: bool,
) {
    let valid_tiles = get_valid_tiles_3d(from, tiles, can_move_diagonal);

    // Create shared mesh and material for indicators
    let indicator_mesh = meshes.add(Mesh::from(shape::Cylinder {
        radius: TILE_SIZE * 0.4,
        height: TILE_SIZE * 0.05,
        resolution: 16,
        segments: 1,
    }));

    let indicator_material = materials.add(StandardMaterial {
        base_color: Color::rgba(0.2, 1.0, 0.2, 0.5),
        emissive: Color::rgb(0.0, 1.0, 0.0),
        alpha_mode: AlphaMode::Blend,
        ..default()
    });

    for (x, y) in valid_tiles {
        let height = tiles
            .iter()
            .find(|tile| tile.coordinates == (x, y))
            .map(|tile| tile.height)
            .unwrap_or(0) as f32;

        let world_pos = crate::systems::isometric_camera::board_to_isometric((x, y), height);

        // Spawn a glowing indicator
        commands.spawn((
            PbrBundle {
                mesh: indicator_mesh.clone(),
                material: indicator_material.clone(),
                transform: Transform::from_translation(Vec3::new(
                    world_pos.x,
                    world_pos.y + 0.1,
                    world_pos.z,
                )),
                ..default()
            },
            ValidMoveIndicator3D,
        ));
    }
}

/// Get valid tiles for a piece (simplified version)
fn get_valid_tiles_3d(
    from: (u8, u8),
    tiles: &Query<&BoardTile>,
    _can_move_diagonal: bool,
) -> Vec<(u8, u8)> {
    let mut valid_tiles = Vec::new();
    
    // Check all adjacent positions
    for dx in -1i32..=1 {
        for dy in -1i32..=1 {
            if dx == 0 && dy == 0 {
                continue;
            }
            
            let new_x = from.0 as i32 + dx;
            let new_y = from.1 as i32 + dy;
            
            if new_x >= 0 && new_x < BOARD_WIDTH as i32 && 
               new_y >= 0 && new_y < BOARD_HEIGHT as i32 {
                let pos = (new_x as u8, new_y as u8);
                
                // Check height restrictions
                let from_height = tiles
                    .iter()
                    .find(|t| t.coordinates == from)
                    .map(|t| t.height)
                    .unwrap_or(0);
                
                let to_height = tiles
                    .iter()
                    .find(|t| t.coordinates == pos)
                    .map(|t| t.height)
                    .unwrap_or(0);
                
                // Can't move up more than 1 level
                if to_height <= from_height + 1 {
                    valid_tiles.push(pos);
                }
            }
        }
    }
    
    valid_tiles
}

/// Check if a move is valid
fn is_valid_move(
    from: (u8, u8),
    to: (u8, u8),
    tiles: &Query<&BoardTile>,
    pieces: &Query<(Entity, &GamePiece3D), Without<Dragging3D>>,
) -> bool {
    // Can't move to same position
    if from == to {
        return false;
    }

    // Check board bounds
    if to.0 >= BOARD_WIDTH || to.1 >= BOARD_HEIGHT {
        return false;
    }

    // Get height difference
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

    // Can't move up more than 1 level
    if to_height > from_height + 1 {
        return false;
    }

    // Check if destination is occupied by same player
    for (_entity, piece) in pieces.iter() {
        if piece.board_position == to {
            // Can capture opponent pieces but not own pieces
            return false; // This should check player, but simplified for now
        }
    }

    // Check basic movement (adjacent tiles)
    let dx = (to.0 as i32 - from.0 as i32).abs();
    let dy = (to.1 as i32 - from.1 as i32).abs();
    
    dx <= 1 && dy <= 1 && (dx + dy) > 0
}

/// Cleanup indicators when not dragging
pub fn cleanup_indicators_3d(
    mut commands: Commands,
    indicators: Query<Entity, With<ValidMoveIndicator3D>>,
    dragging: Query<&Dragging3D>,
) {
    if dragging.is_empty() {
        for entity in indicators.iter() {
            commands.entity(entity).despawn();
        }
    }
}