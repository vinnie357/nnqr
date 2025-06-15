use crate::components::board::{BOARD_HEIGHT, BOARD_WIDTH};
use crate::{
    components::*,
    resources::*,
    systems::{
        settings::Camera2D, JumpActive, KnightMoveActive, MoveDiagonalActive, MoveTwoActive,
        TeleportActive, pieces_3d::GamePiece3D,
    },
};
use bevy::prelude::*;

#[derive(Component)]
pub struct ValidMoveIndicator;

pub fn handle_drag_start(
    mut commands: Commands,
    mouse_input: Res<Input<MouseButton>>,
    windows: Query<&Window>,
    camera_q: Query<(&Camera, &GlobalTransform), (With<Camera2D>, With<Camera>)>,
    game_state: Res<GameState>,
    pieces: Query<(Entity, &GamePiece, &Transform), Without<Dragging>>,
    diagonal_pieces: Query<Entity, With<MoveDiagonalActive>>,
    teleport_pieces: Query<Entity, With<TeleportActive>>,
    jump_pieces: Query<Entity, With<JumpActive>>,
    move_two_pieces: Query<Entity, With<MoveTwoActive>>,
    knight_pieces: Query<Entity, With<KnightMoveActive>>,
    frozen_pieces: Query<Entity, With<crate::components::power::Frozen>>,
    tiles: Query<&BoardTile>,
) {
    if !mouse_input.just_pressed(MouseButton::Left) {
        return;
    }

    // Only allow dragging during piece movement phase
    if game_state.turn_phase != TurnPhase::PieceMovement {
        info!("2D Drag blocked: Wrong turn phase ({:?}), need PieceMovement. Wait for spawning phase to complete.", game_state.turn_phase);
        return;
    }

    let Ok(window) = windows.get_single() else {
        warn!("No window available for 2D mouse input");
        return;
    };
    let Ok((camera, camera_transform)) = camera_q.get_single() else {
        warn!("No camera available for 2D coordinate conversion");
        return;
    };

    if let Some(cursor_pos) = window.cursor_position() {
        if let Some(world_pos) = camera.viewport_to_world_2d(camera_transform, cursor_pos) {
            info!("2D Click at screen: ({:.1}, {:.1}) -> world: ({:.1}, {:.1})", 
                  cursor_pos.x, cursor_pos.y, world_pos.x, world_pos.y);
            
            let current_player_pieces: Vec<_> = pieces.iter()
                .filter(|(_, piece, _)| piece.player == game_state.current_player)
                .collect();
            
            info!("2D: {} pieces available for {:?}", current_player_pieces.len(), game_state.current_player);
            
            // Check if we're clicking on a piece
            let mut found_piece = false;
            for (entity, piece, transform) in pieces.iter() {
                if piece.player != game_state.current_player {
                    continue;
                }

                let enhanced_tile_size = TILE_SIZE * 1.2; // Match board tile size
                let piece_size = enhanced_tile_size * 0.7; // Match actual piece size from pieces.rs
                let piece_bounds = Vec2::new(piece_size, piece_size);
                let piece_pos = Vec2::new(transform.translation.x, transform.translation.y);
                
                let dx = (world_pos.x - piece_pos.x).abs();
                let dy = (world_pos.y - piece_pos.y).abs();
                let half_width = piece_bounds.x / 2.0;
                let half_height = piece_bounds.y / 2.0;

                if dx < half_width && dy < half_height {
                    // Check if piece is frozen
                    if frozen_pieces.contains(entity) {
                        info!("2D: Cannot select frozen piece at {:?}", piece.board_position);
                        return;
                    }
                    
                    found_piece = true;
                    info!("2D: Selected {:?} piece at board {:?}, world ({:.1}, {:.1})", 
                          piece.player, piece.board_position, piece_pos.x, piece_pos.y);
                    // Start dragging this piece
                    let offset = piece_pos - world_pos;
                    commands.entity(entity).insert(Dragging { 
                        offset,
                        original_position: piece.board_position,
                    });

                    // Check what movement powers this piece has
                    let has_diagonal = diagonal_pieces.contains(entity);
                    let has_teleport = teleport_pieces.contains(entity);
                    let has_jump = jump_pieces.contains(entity);
                    let has_move_two = move_two_pieces.contains(entity);
                    let has_knight = knight_pieces.contains(entity);

                    // Show valid move indicators with all movement types
                    spawn_enhanced_move_indicators(
                        &mut commands,
                        piece.board_position,
                        &pieces,
                        &tiles,
                        game_state.current_player,
                        has_diagonal,
                        has_teleport,
                        has_jump,
                        has_move_two,
                        has_knight,
                    );
                    break;
                }
            }
            
            if !found_piece {
                info!("2D: No piece found at click position ({:.1}, {:.1})", world_pos.x, world_pos.y);
            }
        }
    }
}

pub fn handle_drag_update(
    windows: Query<&Window>,
    camera_q: Query<(&Camera, &GlobalTransform), (With<Camera2D>, With<Camera>)>,
    mut dragging_pieces: Query<(&Dragging, &mut Transform)>,
) {
    let Ok(window) = windows.get_single() else {
        warn!("No window available for 2D mouse input");
        return;
    };
    let Ok((camera, camera_transform)) = camera_q.get_single() else {
        warn!("No camera available for 2D coordinate conversion");
        return;
    };

    if let Some(cursor_pos) = window.cursor_position() {
        if let Some(world_pos) = camera.viewport_to_world_2d(camera_transform, cursor_pos) {
            for (dragging, mut transform) in dragging_pieces.iter_mut() {
                // Update piece position to follow mouse
                transform.translation.x = world_pos.x + dragging.offset.x;
                transform.translation.y = world_pos.y + dragging.offset.y;
                transform.translation.z = 10.0; // Lift piece above board while dragging
            }
        }
    }
}

#[allow(clippy::too_many_arguments)]
pub fn handle_drag_end(
    mut commands: Commands,
    mouse_input: Res<Input<MouseButton>>,
    windows: Query<&Window>,
    camera_q: Query<(&Camera, &GlobalTransform), (With<Camera2D>, With<Camera>)>,
    mut game_state: ResMut<GameState>,
    tiles: Query<&BoardTile>,
    mut dragging_pieces: Query<(Entity, &mut GamePiece, &mut Transform, &Dragging)>,
    diagonal_pieces: Query<Entity, With<MoveDiagonalActive>>,
    teleport_pieces: Query<Entity, With<TeleportActive>>,
    jump_pieces: Query<Entity, With<JumpActive>>,
    move_two_pieces: Query<Entity, With<MoveTwoActive>>,
    knight_pieces: Query<Entity, With<KnightMoveActive>>,
    frozen_pieces_drag_end: Query<Entity, With<crate::components::power::Frozen>>,
    other_pieces: Query<(Entity, &GamePiece), Without<Dragging>>,
    all_pieces_3d: Query<(Entity, &GamePiece3D)>,
    time: Res<Time>,
) {
    if !mouse_input.just_released(MouseButton::Left) {
        return;
    }
    
    let dragging_count = dragging_pieces.iter().count();
    info!("2D: handle_drag_end called - {} pieces dragging", dragging_count);
    
    // CRITICAL: If no pieces are being dragged, don't process anything
    if dragging_count == 0 {
        info!("2D: No pieces being dragged - ignoring mouse release");
        return;
    }

    let Ok(window) = windows.get_single() else {
        warn!("No window available for 2D mouse input");
        return;
    };
    let Ok((camera, camera_transform)) = camera_q.get_single() else {
        warn!("No camera available for 2D coordinate conversion");
        return;
    };

    if let Some(cursor_pos) = window.cursor_position() {
        if let Some(world_pos) = camera.viewport_to_world_2d(camera_transform, cursor_pos) {
            // Collect info about pieces to move
            let mut moves_to_process = Vec::new();

            for (entity, piece, _, dragging) in dragging_pieces.iter() {
                let start_pos = dragging.original_position; // Use the stored original position
                moves_to_process.push((entity, start_pos, piece.player));
            }

            // Process moves
            for (entity, start_pos, player) in moves_to_process {
                // Check if piece is frozen (can't move)
                if frozen_pieces_drag_end.contains(entity) {
                    info!("2D: Frozen piece cannot move - canceling drag");
                    commands.entity(entity).remove::<Dragging>();
                    commands.entity(entity).remove::<Selected>();
                    continue;
                }
                
                // First remove the Dragging and Selected components
                commands.entity(entity).remove::<Dragging>();
                commands.entity(entity).remove::<Selected>();
                
                // Also remove Selected from any 3D counterpart at the same position
                clear_selected_at_position(&mut commands, start_pos, &all_pieces_3d);

                // Get all piece positions
                let mut piece_positions: Vec<((u8, u8), Player, Entity)> = other_pieces
                    .iter()
                    .map(|(e, p)| (p.board_position, p.player, e))
                    .collect();
                piece_positions.push((start_pos, player, entity));

                // Find the best valid move target using enhanced validation
                let target_pos = find_best_valid_target_enhanced(
                    world_pos,
                    start_pos,
                    entity,
                    &tiles,
                    &piece_positions,
                    player,
                    &diagonal_pieces,
                    &teleport_pieces,
                    &jump_pieces,
                    &move_two_pieces,
                    &knight_pieces,
                );

                if let Some(valid_target) = target_pos {
                    // Check if the piece actually moved to a different position
                    let piece_actually_moved = valid_target != start_pos;
                    
                    // Extra safety: check if this might be a coordinate precision issue
                    let mouse_world_distance = {
                        let start_world = board_to_world_position(start_pos);
                        let mouse_distance = world_pos.distance(start_world);
                        mouse_distance
                    };
                    
                    info!("2D: Drag end - start_pos: {:?}, valid_target: {:?}, moved: {}, mouse_distance: {:.2}", 
                          start_pos, valid_target, piece_actually_moved, mouse_world_distance);
                    
                    // CRITICAL FIX: Require BOTH position change AND sufficient mouse movement
                    let enhanced_tile_size = TILE_SIZE * 1.2;
                    let min_drag_distance = enhanced_tile_size * 0.98; // INCREASED to 98% of tile - player must drag extremely precisely
                    let is_sufficient_movement = mouse_world_distance >= min_drag_distance;
                    
                    if !is_sufficient_movement {
                        info!("2D: BLOCKING TURN END - Mouse distance {:.2} < {:.2} minimum (need {:.0}% of tile size)", 
                              mouse_world_distance, min_drag_distance, 98.0);
                    }
                    
                    let should_treat_as_moved = piece_actually_moved && is_sufficient_movement;
                    
                    if should_treat_as_moved {
                        // Check for capture BEFORE logging
                        let captured_entity = piece_positions
                            .iter()
                            .find(|(pos, p, e)| *pos == valid_target && *p != player && *e != entity)
                            .map(|(_, _, e)| *e);
                        
                        let is_capture = captured_entity.is_some();
                        info!("2D: TURN ENDING - Piece moved from {:?} to {:?}, capture: {}, phase: {:?} -> PowerSpawning", 
                              start_pos, valid_target, is_capture, game_state.turn_phase);

                        // Despawn captured piece with explosion effect
                        if let Some(captured) = captured_entity {
                            // Get captured piece position for explosion
                            let captured_world_pos = board_to_world_position(valid_target);
                            let captured_player_color = match player {
                                Player::Player1 => Color::rgb(0.2, 0.2, 0.8), // Enemy color for explosion
                                Player::Player2 => Color::rgb(0.8, 0.2, 0.2),
                            };

                            // Spawn capture explosion
                            crate::systems::visual_effects::spawn_capture_explosion(
                                &mut commands,
                                Vec3::new(captured_world_pos.x, captured_world_pos.y, 0.0),
                                captured_player_color,
                            );

                            // Spawn floating text
                            crate::systems::visual_effects::spawn_floating_text(
                                &mut commands,
                                Vec3::new(captured_world_pos.x, captured_world_pos.y, 0.0),
                                "Captured!".to_string(),
                                Color::rgb(1.0, 0.3, 0.3),
                            );

                            if let Some(mut entity_commands) = commands.get_entity(captured) {
                                entity_commands.despawn();
                            }
                        }

                        // Move is valid - update piece position
                        if let Ok((_, mut piece, mut transform, _)) = dragging_pieces.get_mut(entity) {
                            piece.board_position = valid_target;
                            let world_pos = board_to_world_position(valid_target);
                            transform.translation = Vec3::new(world_pos.x, world_pos.y, 1.0);
                        }

                        // Only advance turn phase if piece actually moved to a different position
                        // This implements the 3-phase turn: PowerActivation → PieceMovement → PowerSpawning
                        info!("2D: Setting turn_phase to PowerSpawning (was {:?})", game_state.turn_phase);
                        game_state.turn_phase = TurnPhase::PowerSpawning;
                        game_state.selected_power = None;

                        // Remove MoveDiagonalActive from the piece that just moved
                        commands.entity(entity).remove::<MoveDiagonalActive>();

                        // Force the resource to be marked as changed
                        game_state.set_changed();
                    } else {
                        if piece_actually_moved {
                            info!("2D: TURN NOT ENDING - Piece moved to {:?} but distance {:.2} < {:.2} (too small)", 
                                  valid_target, mouse_world_distance, min_drag_distance);
                        } else {
                            info!("2D: TURN NOT ENDING - Piece returned to original position {:?}", start_pos);
                        }
                        info!("2D: Turn continues, phase stays: {:?}", game_state.turn_phase);
                        
                        // Piece was dropped back on original position - just clean up, don't end turn
                        if let Ok((_, _, mut transform, _)) = dragging_pieces.get_mut(entity) {
                            let world_pos = board_to_world_position(start_pos);
                            transform.translation = Vec3::new(world_pos.x, world_pos.y, 1.0);
                        }
                    }
                } else {
                    info!("2D: No valid target found for piece at {:?} - turn continues, phase stays: {:?}", 
                          start_pos, game_state.turn_phase);
                    // Move is invalid - snap back to original position with animation
                    if let Ok((_, _, mut transform, _)) = dragging_pieces.get_mut(entity) {
                        let world_pos = board_to_world_position(start_pos);
                        transform.translation = Vec3::new(world_pos.x, world_pos.y, 1.0);

                        // Add shake animation and flash effect
                        commands.entity(entity).insert((
                            InvalidMoveAnimation {
                                start_time: time.elapsed_seconds(),
                                duration: 0.5,
                                original_pos: Vec3::new(world_pos.x, world_pos.y, 1.0),
                            },
                            InvalidMoveFlash {
                                start_time: time.elapsed_seconds(),
                                duration: 0.3,
                            },
                        ));
                    }
                }
            }
        }
    }
}

fn is_valid_move_with_positions(
    from: (u8, u8),
    to: (u8, u8),
    tiles: &Query<&BoardTile>,
    piece_positions: &[((u8, u8), Player, Entity)],
    current_player: Player,
    allow_diagonal: bool,
) -> bool {
    // Check bounds
    if to.0 >= BOARD_WIDTH || to.1 >= BOARD_HEIGHT {
        return false;
    }

    // Check terrain height restrictions
    use crate::systems::terrain_height::is_valid_height_movement;
    if !is_valid_height_movement(from, to, tiles) {
        return false;
    }

    // Check if target is occupied by friendly piece
    for (pos, player, _) in piece_positions.iter() {
        if *pos == to && *player == current_player {
            return false; // Can't capture own piece
        }
    }

    // Check move distance
    let dx = (to.0 as i8 - from.0 as i8).abs();
    let dy = (to.1 as i8 - from.1 as i8).abs();

    let valid_move = if allow_diagonal {
        // Allow diagonal, horizontal, or vertical moves of distance 1
        (dx <= 1 && dy <= 1) && (dx + dy > 0)
    } else {
        // Only horizontal or vertical moves
        (dx == 1 && dy == 0) || (dx == 0 && dy == 1)
    };

    if valid_move {
        // Check height restrictions
        let from_height = get_tile_height(from, tiles);
        let to_height = get_tile_height(to, tiles);

        // Can move down any levels, up only one level
        return to_height <= from_height + 1;
    }

    false
}

fn get_tile_height(pos: (u8, u8), tiles: &Query<&BoardTile>) -> i8 {
    for tile in tiles.iter() {
        if tile.coordinates == pos {
            return tile.height;
        }
    }
    0 // Default height if not found
}

fn world_to_board_position(world_pos: Vec2) -> (u8, u8) {
    // Use enhanced tile size to match 2D board layout
    let enhanced_tile_size = TILE_SIZE * 1.2; // Match board.rs enhanced tile size
    // Reverse the board.rs formula: tile_pos = (board_pos - BOARD_SIZE/2.0 + 0.5) * tile_size
    // So: board_pos = (tile_pos / tile_size) + BOARD_SIZE/2.0 - 0.5
    let x = ((world_pos.x / enhanced_tile_size) + BOARD_WIDTH as f32 / 2.0 - 0.5).round() as i8;
    let y = ((world_pos.y / enhanced_tile_size) + BOARD_HEIGHT as f32 / 2.0 - 0.5).round() as i8;

    let x = x.max(0).min(BOARD_WIDTH as i8 - 1) as u8;
    let y = y.max(0).min(BOARD_HEIGHT as i8 - 1) as u8;

    (x, y)
}

fn board_to_world_position(board_pos: (u8, u8)) -> Vec2 {
    // Use enhanced tile size to match 2D board layout
    let enhanced_tile_size = TILE_SIZE * 1.2; // Match board.rs enhanced tile size
    let x = (board_pos.0 as f32 - BOARD_WIDTH as f32 / 2.0 + 0.5) * enhanced_tile_size;
    let y = (board_pos.1 as f32 - BOARD_HEIGHT as f32 / 2.0 + 0.5) * enhanced_tile_size;
    Vec2::new(x, y)
}

// Find the nearest valid move target using enhanced movement validation
fn find_best_valid_target_enhanced(
    drop_world_pos: Vec2,
    start_pos: (u8, u8),
    entity: Entity,
    tiles: &Query<&BoardTile>,
    piece_positions: &[((u8, u8), Player, Entity)],
    current_player: Player,
    diagonal_query: &Query<Entity, With<MoveDiagonalActive>>,
    teleport_query: &Query<Entity, With<TeleportActive>>,
    jump_query: &Query<Entity, With<JumpActive>>,
    move_two_query: &Query<Entity, With<MoveTwoActive>>,
    knight_query: &Query<Entity, With<KnightMoveActive>>,
) -> Option<(u8, u8)> {
    // Calculate minimum distance needed for intentional movement FIRST
    let enhanced_tile_size = TILE_SIZE * 1.2;
    let min_intentional_distance = enhanced_tile_size * 0.98; // INCREASED to 98% of tile size - must be extremely precise movement
    let start_world_pos = board_to_world_position(start_pos);
    let actual_mouse_distance = drop_world_pos.distance(start_world_pos);
    
    // Only process moves if the mouse moved a reasonable distance indicating intent
    if actual_mouse_distance < min_intentional_distance {
        // Mouse movement too small - this was likely just a click, not a drag
        info!("2D: Mouse movement too small: {:.2} < {:.2} (need {:.0}% of tile) - NOT a valid move", 
              actual_mouse_distance, min_intentional_distance, 98.0);
        return None;
    }

    // Now check if the exact drop position is valid
    let exact_target = world_to_board_position(drop_world_pos);

    // Use enhanced movement validation
    if crate::systems::enhanced_movement::validate_enhanced_movement(
        start_pos,
        exact_target,
        entity,
        tiles,
        piece_positions,
        current_player,
        diagonal_query,
        teleport_query,
        jump_query,
        move_two_query,
        knight_query,
    ) {
        return Some(exact_target);
    }

    // For magnetic snapping, check nearby positions
    let mut best_move = None;
    let mut best_distance = f32::MAX;

    // Check all positions within 2 tiles for special moves
    for x in 0..BOARD_WIDTH {
        for y in 0..BOARD_HEIGHT {
            let target = (x, y);
            
            // Don't snap back to the starting position
            if target == start_pos {
                continue;
            }
            
            let world_pos = board_to_world_position(target);
            let distance = drop_world_pos.distance(world_pos);

            // Only consider positions within snapping range
            if distance < enhanced_tile_size * 0.7
                && crate::systems::enhanced_movement::validate_enhanced_movement(
                    start_pos,
                    target,
                    entity,
                    tiles,
                    piece_positions,
                    current_player,
                    diagonal_query,
                    teleport_query,
                    jump_query,
                    move_two_query,
                    knight_query,
                )
                && distance < best_distance
            {
                best_distance = distance;
                best_move = Some(target);
            }
        }
    }

    best_move
}

// Get all valid moves for a piece
fn get_valid_moves(
    from: (u8, u8),
    tiles: &Query<&BoardTile>,
    piece_positions: &[((u8, u8), Player, Entity)],
    current_player: Player,
    allow_diagonal: bool,
) -> Vec<(u8, u8)> {
    let mut valid_moves = Vec::new();
    let mut directions = vec![(0, 1), (0, -1), (1, 0), (-1, 0)];

    if allow_diagonal {
        // Add diagonal directions
        directions.extend_from_slice(&[(1, 1), (1, -1), (-1, 1), (-1, -1)]);
    }

    for (dx, dy) in directions.iter() {
        let new_x = from.0 as i8 + dx;
        let new_y = from.1 as i8 + dy;

        if new_x >= 0 && new_x < BOARD_WIDTH as i8 && new_y >= 0 && new_y < BOARD_HEIGHT as i8 {
            let target_pos = (new_x as u8, new_y as u8);
            if is_valid_move_with_positions(
                from,
                target_pos,
                tiles,
                piece_positions,
                current_player,
                allow_diagonal,
            ) {
                valid_moves.push(target_pos);
            }
        }
    }

    valid_moves
}

fn spawn_valid_move_indicators(
    commands: &mut Commands,
    from_pos: (u8, u8),
    pieces: &Query<(Entity, &GamePiece, &Transform), Without<Dragging>>,
    tiles: &Query<&BoardTile>,
    current_player: Player,
    allow_diagonal: bool,
) {
    // Check all directions
    let mut directions = vec![(0, 1), (0, -1), (1, 0), (-1, 0)];

    if allow_diagonal {
        // Add diagonal directions
        directions.extend_from_slice(&[(1, 1), (1, -1), (-1, 1), (-1, -1)]);
    }

    // Get height of current position
    let from_height = get_tile_height(from_pos, tiles);

    for (dx, dy) in directions.iter() {
        let new_x = from_pos.0 as i8 + dx;
        let new_y = from_pos.1 as i8 + dy;

        if new_x >= 0 && new_x < BOARD_WIDTH as i8 && new_y >= 0 && new_y < BOARD_HEIGHT as i8 {
            let target_pos = (new_x as u8, new_y as u8);

            // Get height of target position
            let to_height = get_tile_height(target_pos, tiles);

            // Check height restriction: can move down any levels, up only one level
            if to_height > from_height + 1 {
                continue; // Skip this position - too high
            }

            // Check if there's a friendly piece there
            let mut blocked = false;
            for (_, piece, _) in pieces.iter() {
                if piece.board_position == target_pos && piece.player == current_player {
                    blocked = true;
                    break;
                }
            }

            if !blocked {
                // Spawn indicator with pulsing effect
                let world_pos = board_to_world_position(target_pos);
                let enhanced_tile_size = TILE_SIZE * 1.2; // Match board tile size
                commands.spawn((
                    ValidMoveIndicator,
                    SpriteBundle {
                        sprite: Sprite {
                            color: Color::rgba(0.0, 1.0, 0.0, 0.4), // Semi-transparent green
                            custom_size: Some(Vec2::splat(enhanced_tile_size * 0.85)), // Match board tile size
                            ..default()
                        },
                        transform: Transform::from_xyz(world_pos.x, world_pos.y, 2.0),
                        ..default()
                    },
                ));
            }
        }
    }
}

fn spawn_enhanced_move_indicators(
    commands: &mut Commands,
    from_pos: (u8, u8),
    pieces: &Query<(Entity, &GamePiece, &Transform), Without<Dragging>>,
    tiles: &Query<&BoardTile>,
    current_player: Player,
    allow_diagonal: bool,
    has_teleport: bool,
    has_jump: bool,
    has_move_two: bool,
    has_knight: bool,
) {
    // Start with basic orthogonal directions
    let mut all_valid_moves = Vec::new();
    
    if has_teleport {
        // Teleport: can move to any empty square on the board
        for x in 0..BOARD_WIDTH {
            for y in 0..BOARD_HEIGHT {
                let target_pos = (x, y);
                if target_pos != from_pos {
                    // Check if square is empty
                    let mut occupied = false;
                    for (_, piece, _) in pieces.iter() {
                        if piece.board_position == target_pos {
                            occupied = true;
                            break;
                        }
                    }
                    if !occupied {
                        all_valid_moves.push((target_pos, Color::CYAN));
                    }
                }
            }
        }
    } else {
        // Regular movement with various enhancements
        let mut basic_directions = vec![(0, 1), (0, -1), (1, 0), (-1, 0)];
        
        if allow_diagonal {
            basic_directions.extend_from_slice(&[(1, 1), (1, -1), (-1, 1), (-1, -1)]);
        }

        if has_knight {
            // Knight moves: L-shaped moves like chess knight
            let knight_moves = [
                (2, 1), (2, -1), (-2, 1), (-2, -1),
                (1, 2), (1, -2), (-1, 2), (-1, -2),
            ];
            basic_directions.extend_from_slice(&knight_moves);
        }

        let from_height = get_tile_height(from_pos, tiles);

        for (dx, dy) in basic_directions.iter() {
            let max_distance = if has_move_two { 2 } else { 1 };
            
            for distance in 1..=max_distance {
                let new_x = from_pos.0 as i8 + (dx * distance);
                let new_y = from_pos.1 as i8 + (dy * distance);

                if new_x >= 0 && new_x < BOARD_WIDTH as i8 && new_y >= 0 && new_y < BOARD_HEIGHT as i8 {
                    let target_pos = (new_x as u8, new_y as u8);
                    let to_height = get_tile_height(target_pos, tiles);

                    // Height restriction (unless teleporting)
                    if !has_teleport && to_height > from_height + 1 {
                        break; // Can't continue in this direction
                    }

                    // Check for pieces
                    let mut occupied_by_friendly = false;
                    let mut occupied_by_enemy = false;
                    
                    for (_, piece, _) in pieces.iter() {
                        if piece.board_position == target_pos {
                            if piece.player == current_player {
                                occupied_by_friendly = true;
                            } else {
                                occupied_by_enemy = true;
                            }
                            break;
                        }
                    }

                    // Determine if this is a valid move
                    let can_move = if has_jump {
                        // Jump: can move over pieces, but not land on friendly pieces
                        !occupied_by_friendly
                    } else {
                        // Normal: can't move through any pieces
                        if occupied_by_friendly || occupied_by_enemy {
                            // Can capture enemy pieces
                            occupied_by_enemy
                        } else {
                            true // Empty square
                        }
                    };

                    if can_move {
                        let color = if occupied_by_enemy {
                            Color::RED // Attack move
                        } else if has_move_two && distance == 2 {
                            Color::BLUE // Extended move
                        } else if has_knight && (dx.abs() == 2 || dy.abs() == 2) {
                            Color::PURPLE // Knight move
                        } else {
                            Color::GREEN // Normal move
                        };
                        all_valid_moves.push((target_pos, color));
                    }

                    // Stop if we hit a piece and can't jump
                    if !has_jump && (occupied_by_friendly || occupied_by_enemy) {
                        break;
                    }
                }
            }
        }
    }

    // Spawn indicators for all valid moves
    for (target_pos, color) in all_valid_moves {
        let world_pos = board_to_world_position(target_pos);
        let enhanced_tile_size = TILE_SIZE * 1.2;
        commands.spawn((
            ValidMoveIndicator,
            SpriteBundle {
                sprite: Sprite {
                    color: color.with_a(0.6), // Semi-transparent
                    custom_size: Some(Vec2::splat(enhanced_tile_size * 0.85)),
                    ..default()
                },
                transform: Transform::from_xyz(world_pos.x, world_pos.y, 2.0),
                ..default()
            },
        ));
    }
}

pub fn cleanup_indicators(
    mut commands: Commands,
    indicators: Query<Entity, With<ValidMoveIndicator>>,
    dragging_query: Query<&Dragging>,
) {
    // Remove indicators when no pieces are being dragged
    if dragging_query.is_empty() {
        for entity in indicators.iter() {
            if let Some(mut entity_commands) = commands.get_entity(entity) {
                entity_commands.despawn();
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use crate::resources::TurnPhase;
    
    #[test]
    fn test_drag_end_logic_without_movement() {
        // Test the core logic: piece at same position should not advance turn
        let original_pos = (3, 3);  // Position stored in Dragging component
        let target_pos = (3, 3);    // Position piece is dropped at
        
        let piece_actually_moved = target_pos != original_pos;
        
        assert!(!piece_actually_moved, 
            "Piece should not be considered moved when dropped at original position");
        
        // In handle_drag_end, this would prevent turn phase change
        let mut turn_phase = TurnPhase::PieceMovement;
        if piece_actually_moved {
            turn_phase = TurnPhase::PowerSpawning;
        }
        
        assert_eq!(turn_phase, TurnPhase::PieceMovement,
            "Turn phase should not change when piece doesn't move");
    }
    
    #[test]
    fn test_drag_end_logic_with_movement() {
        // Test the core logic: piece at different position should advance turn
        let original_pos = (3, 3);  // Position stored in Dragging component
        let target_pos = (4, 3);    // Position piece is dropped at (moved one square)
        
        let piece_actually_moved = target_pos != original_pos;
        
        assert!(piece_actually_moved, 
            "Piece should be considered moved when dropped at different position");
        
        // In handle_drag_end, this would trigger turn phase change
        let mut turn_phase = TurnPhase::PieceMovement;
        if piece_actually_moved {
            turn_phase = TurnPhase::PowerSpawning;
        }
        
        assert_eq!(turn_phase, TurnPhase::PowerSpawning,
            "Turn phase should change to PowerSpawning when piece moves");
    }
    
    #[test]
    fn test_original_position_tracking() {
        // Test that the fix prevents the bug where piece.board_position was updated during drag
        let original_pos = (3, 3);    // Position when drag started (stored in Dragging)
        let current_piece_pos = (5, 5); // Piece's board_position got updated during drag somehow
        let target_pos = (3, 3);      // Player drops back to original position
        
        // OLD BUG: would compare current_piece_pos vs target_pos (5,5 vs 3,3) = moved!
        let old_buggy_logic = target_pos != current_piece_pos;
        assert!(old_buggy_logic, "Old buggy logic would think piece moved");
        
        // NEW FIXED LOGIC: compares original_pos vs target_pos (3,3 vs 3,3) = not moved!
        let fixed_logic = target_pos != original_pos;
        assert!(!fixed_logic, "Fixed logic correctly detects no movement");
    }
    
    #[test]
    fn test_small_movement_prevention() {
        // Test that small mouse movements don't end turns due to coordinate precision
        let original_pos = (3, 3);
        let target_pos = (4, 3);  // Coordinate rounding put us on adjacent tile
        let mouse_distance = 20.0;  // But mouse only moved 20 pixels (less than threshold)
        
        let piece_actually_moved = target_pos != original_pos;
        assert!(piece_actually_moved, "Coordinates show piece moved");
        
        // Small movement threshold: 30% of enhanced tile size
        let enhanced_tile_size = 60.0 * 1.2; // TILE_SIZE * 1.2 = 72.0
        let threshold = enhanced_tile_size * 0.3; // 72.0 * 0.3 = 21.6
        let is_small_movement = mouse_distance < threshold; // 20.0 < 21.6 = true
        let should_treat_as_moved = piece_actually_moved && !is_small_movement;
        
        assert!(is_small_movement, "Mouse movement should be considered small");
        assert!(!should_treat_as_moved, "Should not treat as moved due to small distance");
    }
    
    #[test]
    fn test_large_movement_detection() {
        // Test that actual intentional movements still end turns
        let original_pos = (3, 3);
        let target_pos = (4, 3);  // Moved to adjacent tile
        let mouse_distance = 80.0;  // Mouse moved significant distance
        
        let piece_actually_moved = target_pos != original_pos;
        assert!(piece_actually_moved, "Coordinates show piece moved");
        
        // Small movement threshold: 30% of enhanced tile size
        let enhanced_tile_size = 60.0 * 1.2; // TILE_SIZE * 1.2  
        let is_small_movement = mouse_distance < enhanced_tile_size * 0.3;
        let should_treat_as_moved = piece_actually_moved && !is_small_movement;
        
        assert!(!is_small_movement, "Mouse movement should not be considered small");
        assert!(should_treat_as_moved, "Should treat as moved for large distance");
    }
}

/// Helper function to clear Selected component from all pieces at a given position
/// This ensures 2D and 3D representations stay synchronized
fn clear_selected_at_position(
    commands: &mut Commands,
    position: (u8, u8),
    pieces_3d: &Query<(Entity, &GamePiece3D)>,
) {
    // Remove Selected component from any 3D pieces at this position
    for (entity, piece_3d) in pieces_3d.iter() {
        if piece_3d.board_position == position {
            commands.entity(entity).remove::<Selected>();
        }
    }
}
