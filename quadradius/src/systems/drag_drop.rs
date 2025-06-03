use crate::{components::*, resources::*, systems::{MoveDiagonalActive, TeleportActive, JumpActive, MoveTwoActive, KnightMoveActive}};
use bevy::prelude::*;

#[derive(Component)]
pub struct ValidMoveIndicator;

pub fn handle_drag_start(
    mut commands: Commands,
    mouse_input: Res<Input<MouseButton>>,
    windows: Query<&Window>,
    camera_q: Query<(&Camera, &GlobalTransform)>,
    game_state: Res<GameState>,
    pieces: Query<(Entity, &GamePiece, &Transform), Without<Dragging>>,
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
    let (camera, camera_transform) = camera_q.single();

    if let Some(cursor_pos) = window.cursor_position() {
        if let Some(world_pos) = camera.viewport_to_world_2d(camera_transform, cursor_pos) {
            // Check if we're clicking on a piece
            for (entity, piece, transform) in pieces.iter() {
                if piece.player != game_state.current_player {
                    continue;
                }

                let piece_bounds = Vec2::new(TILE_SIZE * 0.8, TILE_SIZE * 0.8);
                let piece_pos = Vec2::new(transform.translation.x, transform.translation.y);

                if (world_pos.x - piece_pos.x).abs() < piece_bounds.x / 2.0
                    && (world_pos.y - piece_pos.y).abs() < piece_bounds.y / 2.0
                {
                    // Start dragging this piece
                    let offset = piece_pos - world_pos;
                    commands.entity(entity).insert(Dragging { offset });

                    // Check if this piece has diagonal move
                    let has_diagonal = diagonal_pieces.contains(entity);
                    
                    // Show valid move indicators
                    spawn_valid_move_indicators(
                        &mut commands,
                        piece.board_position,
                        &pieces,
                        &tiles,
                        game_state.current_player,
                        has_diagonal,
                    );
                    break;
                }
            }
        }
    }
}

pub fn handle_drag_update(
    windows: Query<&Window>,
    camera_q: Query<(&Camera, &GlobalTransform)>,
    mut dragging_pieces: Query<(&Dragging, &mut Transform)>,
) {
    let window = windows.single();
    let (camera, camera_transform) = camera_q.single();

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
    camera_q: Query<(&Camera, &GlobalTransform)>,
    mut game_state: ResMut<GameState>,
    tiles: Query<&BoardTile>,
    mut dragging_pieces: Query<(Entity, &mut GamePiece, &mut Transform, &Dragging)>,
    diagonal_pieces: Query<Entity, With<MoveDiagonalActive>>,
    teleport_pieces: Query<Entity, With<TeleportActive>>,
    jump_pieces: Query<Entity, With<JumpActive>>,
    move_two_pieces: Query<Entity, With<MoveTwoActive>>,
    knight_pieces: Query<Entity, With<KnightMoveActive>>,
    other_pieces: Query<(Entity, &GamePiece), Without<Dragging>>,
    time: Res<Time>,
) {
    if !mouse_input.just_released(MouseButton::Left) {
        return;
    }

    let window = windows.single();
    let (camera, camera_transform) = camera_q.single();

    if let Some(cursor_pos) = window.cursor_position() {
        if let Some(world_pos) = camera.viewport_to_world_2d(camera_transform, cursor_pos) {
            // Collect info about pieces to move
            let mut moves_to_process = Vec::new();

            for (entity, piece, _, _) in dragging_pieces.iter() {
                let start_pos = piece.board_position;
                moves_to_process.push((entity, start_pos, piece.player));
            }

            // Process moves
            for (entity, start_pos, player) in moves_to_process {
                // First remove the Dragging component
                commands.entity(entity).remove::<Dragging>();

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
                    // Check for capture
                    let captured_entity = piece_positions
                        .iter()
                        .find(|(pos, p, e)| *pos == valid_target && *p != player && *e != entity)
                        .map(|(_, _, e)| *e);

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
                        
                        commands.entity(captured).despawn();
                    }

                    // Move is valid - update piece position
                    if let Ok((_, mut piece, mut transform, _)) = dragging_pieces.get_mut(entity) {
                        piece.board_position = valid_target;
                        let world_pos = board_to_world_position(valid_target);
                        transform.translation = Vec3::new(world_pos.x, world_pos.y, 1.0);
                    }

                    // Switch turns
                    game_state.current_player = match game_state.current_player {
                        Player::Player1 => Player::Player2,
                        Player::Player2 => Player::Player1,
                    };
                    
                    // Reset to power activation phase for next player
                    game_state.turn_phase = TurnPhase::PowerActivation;
                    game_state.selected_power = None;

                    // Remove MoveDiagonalActive from the piece that just moved
                    commands.entity(entity).remove::<MoveDiagonalActive>();

                    // Force the resource to be marked as changed
                    game_state.set_changed();
                } else {
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
    if to.0 >= BOARD_SIZE || to.1 >= BOARD_SIZE {
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
        (dx == 1 && dy == 1) || (dx == 1 && dy == 0) || (dx == 0 && dy == 1)
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
    let x = ((world_pos.x / TILE_SIZE) + BOARD_SIZE as f32 / 2.0).round() as i8;
    let y = ((world_pos.y / TILE_SIZE) + BOARD_SIZE as f32 / 2.0).round() as i8;

    let x = x.max(0).min(BOARD_SIZE as i8 - 1) as u8;
    let y = y.max(0).min(BOARD_SIZE as i8 - 1) as u8;

    (x, y)
}

fn board_to_world_position(board_pos: (u8, u8)) -> Vec2 {
    let x = (board_pos.0 as f32 - BOARD_SIZE as f32 / 2.0 + 0.5) * TILE_SIZE;
    let y = (board_pos.1 as f32 - BOARD_SIZE as f32 / 2.0 + 0.5) * TILE_SIZE;
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
    // First, check if the exact drop position is valid
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
    for x in 0..BOARD_SIZE {
        for y in 0..BOARD_SIZE {
            let target = (x, y);
            let world_pos = board_to_world_position(target);
            let distance = drop_world_pos.distance(world_pos);
            
            // Only consider positions within snapping range
            if distance < TILE_SIZE * 0.7 {
                if crate::systems::enhanced_movement::validate_enhanced_movement(
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
                ) {
                    if distance < best_distance {
                        best_distance = distance;
                        best_move = Some(target);
                    }
                }
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
        
        if new_x >= 0 && new_x < BOARD_SIZE as i8 && new_y >= 0 && new_y < BOARD_SIZE as i8 {
            let target_pos = (new_x as u8, new_y as u8);
            if is_valid_move_with_positions(from, target_pos, tiles, piece_positions, current_player, allow_diagonal) {
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

        if new_x >= 0 && new_x < BOARD_SIZE as i8 && new_y >= 0 && new_y < BOARD_SIZE as i8 {
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
                commands.spawn((
                    ValidMoveIndicator,
                    SpriteBundle {
                        sprite: Sprite {
                            color: Color::rgba(0.0, 1.0, 0.0, 0.4), // Semi-transparent green
                            custom_size: Some(Vec2::splat(TILE_SIZE * 0.85)),
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

pub fn cleanup_indicators(
    mut commands: Commands,
    indicators: Query<Entity, With<ValidMoveIndicator>>,
    dragging_query: Query<&Dragging>,
) {
    // Remove indicators when no pieces are being dragged
    if dragging_query.is_empty() {
        for entity in indicators.iter() {
            commands.entity(entity).despawn();
        }
    }
}
