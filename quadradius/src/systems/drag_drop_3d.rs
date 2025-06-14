use crate::{
    components::*,
    resources::*,
    systems::{
        enhanced_move_indicators_3d::ValidMoveIndicator3D,
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


/// Handle drag start for 3D pieces
pub fn handle_drag_start_3d(
    mut commands: Commands,
    meshes: ResMut<Assets<Mesh>>,
    materials: ResMut<Assets<StandardMaterial>>,
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
        println!("Not in piece movement phase: {:?}", game_state.turn_phase);
        return;
    }

    println!(
        "Mouse clicked - attempting piece selection (current player: {:?})",
        game_state.current_player
    );

    let Ok(window) = windows.get_single() else {
        warn!("No window available for mouse input");
        return;
    };
    if let Some(cursor_pos) = window.cursor_position() {
        // Convert screen position to board coordinates
        if let Some(board_pos) = screen_to_board(&windows, &camera_q, cursor_pos) {
            println!("Board position: {:?}", board_pos);
            // Check if there's a piece at this position
            let mut found_piece = false;
            for (entity, piece) in pieces.iter() {
                if piece.board_position == board_pos {
                    println!(
                        "Found piece at {:?} belonging to {:?}",
                        board_pos, piece.player
                    );
                    if piece.player == game_state.current_player {
                        found_piece = true;
                        // Start dragging this piece
                        commands.entity(entity).insert(Dragging3D {
                            start_pos: board_pos,
                        });

                        // Add selection highlighting
                        commands.entity(entity).insert(Selected);

                        // Check if this piece can move diagonally
                        let can_move_diagonal = diagonal_pieces.iter().any(|e| e == entity);

                        // Valid moves will be shown by the enhanced_move_indicators_3d system
                        info!("Selected piece at {:?} - enhanced indicators will show valid moves", board_pos);

                        // Debug logging disabled to prevent spam
                        #[cfg(debug_assertions)]
                        if false {
                            info!("Started dragging piece at {:?}", board_pos);
                        }
                        break;
                    }
                }
            }
            if !found_piece {
                println!(
                    "No piece found at {:?} for current player {:?}",
                    board_pos, game_state.current_player
                );
            }
        } else {
            println!("Could not convert cursor position to board coordinates");
        }
    } else {
        println!("No cursor position available");
    }
}

/// Handle drag update for 3D pieces
pub fn handle_drag_update_3d(
    mut pieces: Query<(&mut Transform, &GamePiece3D), With<Dragging3D>>,
    windows: Query<&Window>,
    camera_q: Query<(&Camera, &GlobalTransform), With<IsometricCamera>>,
    tiles: Query<&BoardTile>,
) {
    let Ok(window) = windows.get_single() else {
        warn!("No window available for mouse input");
        return;
    };
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
                let world_pos =
                    crate::systems::isometric_camera::board_to_isometric(board_pos, height);
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
    all_pieces_2d: Query<(Entity, &GamePiece)>,
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

    let Ok(window) = windows.get_single() else {
        warn!("No window available for mouse input");
        return;
    };
    if let Some(cursor_pos) = window.cursor_position() {
        if let Some(target_pos) = screen_to_board(&windows, &camera_q, cursor_pos) {
            for (entity, mut piece, mut transform, dragging) in pieces.iter_mut() {
                let start_pos = dragging.start_pos;

                // Check if move is valid
                if is_valid_move_3d(start_pos, target_pos, piece.player, &tiles, &all_pieces) {
                    // Check if the piece actually moved to a different position  
                    let piece_actually_moved = target_pos != start_pos;
                    
                    if piece_actually_moved {
                        info!("3D: Piece moved from {:?} to {:?} - ending turn", start_pos, target_pos);
                        
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
                            // Debug logging disabled to prevent spam
                            #[cfg(debug_assertions)]
                            if false {
                                info!("Captured piece at {:?}", target_pos);
                            }
                        }

                        // Update piece position
                        piece.board_position = target_pos;

                        // Update transform to final position
                        let height = tiles
                            .iter()
                            .find(|tile| tile.coordinates == target_pos)
                            .map(|tile| tile.height)
                            .unwrap_or(0) as f32;

                        let world_pos =
                            crate::systems::isometric_camera::board_to_isometric(target_pos, height);
                        transform.translation =
                            Vec3::new(world_pos.x, world_pos.y + TILE_SIZE * 0.35, world_pos.z);

                        // Follow proper 3-phase turn sequence: PowerActivation → PieceMovement → PowerSpawning
                        // Only advance to PowerSpawning phase if piece actually moved to a different position
                        game_state.turn_phase = TurnPhase::PowerSpawning;
                        game_state.selected_power = None;

                        // Force the resource to be marked as changed
                        game_state.set_changed();

                        // Debug logging disabled to prevent spam
                        #[cfg(debug_assertions)]
                        if false {
                            info!("Moved piece from {:?} to {:?}", start_pos, target_pos);
                        }
                    } else {
                        info!("3D: Piece returned to original position {:?} - turn continues", start_pos);
                        
                        // Piece was dropped back on original position - just clean up, don't end turn
                        let height = tiles
                            .iter()
                            .find(|tile| tile.coordinates == start_pos)
                            .map(|tile| tile.height)
                            .unwrap_or(0) as f32;

                        let world_pos =
                            crate::systems::isometric_camera::board_to_isometric(start_pos, height);
                        transform.translation =
                            Vec3::new(world_pos.x, world_pos.y + TILE_SIZE * 0.35, world_pos.z);
                    }
                } else {
                    // Invalid move - return to original position
                    let height = tiles
                        .iter()
                        .find(|tile| tile.coordinates == start_pos)
                        .map(|tile| tile.height)
                        .unwrap_or(0) as f32;

                    let world_pos =
                        crate::systems::isometric_camera::board_to_isometric(start_pos, height);
                    transform.translation =
                        Vec3::new(world_pos.x, world_pos.y + TILE_SIZE * 0.35, world_pos.z);

                    // Debug logging disabled to prevent spam
                    #[cfg(debug_assertions)]
                    if false {
                        info!("Invalid move - returning piece to {:?}", start_pos);
                    }
                }

                // Remove dragging and selection components
                commands.entity(entity).remove::<Dragging3D>();
                commands.entity(entity).remove::<Selected>();
                
                // Also remove Selected from any 2D counterpart at the same position
                clear_selected_at_position_2d(&mut commands, start_pos, &all_pieces_2d);
            }
        }
    }
}



/// Check if a move is valid in 3D
fn is_valid_move_3d(
    from: (u8, u8),
    to: (u8, u8),
    current_player: Player,
    tiles: &Query<&BoardTile>,
    pieces: &Query<(Entity, &GamePiece3D), Without<Dragging3D>>,
) -> bool {
    // Allow dropping on same position (for piece selection/deselection)
    if from == to {
        return true;
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

    // Check if destination is occupied by same player (can't capture own pieces)
    for (_entity, piece) in pieces.iter() {
        if piece.board_position == to && piece.player == current_player {
            return false; // Can't capture own pieces
        }
        // Note: Can capture opponent pieces, so don't return false for different player
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
    selected_pieces: Query<Entity, (With<GamePiece3D>, With<Selected>)>,
    selected_pieces_2d: Query<Entity, (With<GamePiece>, With<Selected>)>,
) {
    // Clean up indicators if no pieces are being dragged AND no pieces are selected
    let no_dragging = dragging.is_empty();
    let no_selected = selected_pieces.is_empty() && selected_pieces_2d.is_empty();
    
    if no_dragging && no_selected {
        let indicator_count = indicators.iter().count();
        if indicator_count > 0 {
            info!("🗑️ Cleaning up {} indicators (no dragging, no selection)", indicator_count);
            for entity in indicators.iter() {
                commands.entity(entity).despawn();
            }
        }
    }
}

/// Helper function to clear Selected component from all 2D pieces at a given position
/// This ensures 2D and 3D representations stay synchronized
fn clear_selected_at_position_2d(
    commands: &mut Commands,
    position: (u8, u8),
    pieces_2d: &Query<(Entity, &GamePiece)>,
) {
    // Remove Selected component from any 2D pieces at this position
    for (entity, piece_2d) in pieces_2d.iter() {
        if piece_2d.board_position == position {
            commands.entity(entity).remove::<Selected>();
        }
    }
}
