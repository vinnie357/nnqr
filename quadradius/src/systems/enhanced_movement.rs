use crate::{components::*, resources::*, systems::*};
use crate::components::board::{BOARD_WIDTH, BOARD_HEIGHT};
use bevy::prelude::*;

// Enhanced movement validation that checks for active movement powers
pub fn validate_enhanced_movement(
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
    knight_query: &Query<Entity, With<KnightMoveActive>>,
) -> bool {
    // Check bounds
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
        // Teleport can move to ANY empty square
        println!("Teleport active - can move anywhere!");
        return true;
    }

    if knight_query.contains(entity) {
        // Knight moves in L-shape
        let dx = (to.0 as i8 - from.0 as i8).abs();
        let dy = (to.1 as i8 - from.1 as i8).abs();
        if (dx == 2 && dy == 1) || (dx == 1 && dy == 2) {
            println!("Knight move validated");
            return true;
        }
    }

    if move_two_query.contains(entity) {
        // Move exactly 2 squares in one direction
        let dx = (to.0 as i8 - from.0 as i8).abs();
        let dy = (to.1 as i8 - from.1 as i8).abs();
        if (dx == 2 && dy == 0) || (dx == 0 && dy == 2) {
            println!("Move Two validated");
            return true;
        }
    }

    if jump_query.contains(entity) {
        // Jump can move in straight lines regardless of obstacles
        let dx = (to.0 as i8 - from.0 as i8).abs();
        let dy = (to.1 as i8 - from.1 as i8).abs();
        if dx == 0 || dy == 0 {
            println!("Jump move validated");
            return true;
        }
    }

    // Normal movement rules
    let dx = (to.0 as i8 - from.0 as i8).abs();
    let dy = (to.1 as i8 - from.1 as i8).abs();

    let allow_diagonal = diagonal_query.contains(entity);
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
    0
}

// System to show valid moves based on active powers
pub fn show_valid_moves_for_powers(
    mut commands: Commands,
    dragging_pieces: Query<(Entity, &GamePiece), With<Dragging>>,
    tiles: Query<&BoardTile>,
    pieces: Query<(Entity, &GamePiece)>,
    diagonal_query: Query<Entity, With<MoveDiagonalActive>>,
    teleport_query: Query<Entity, With<TeleportActive>>,
    jump_query: Query<Entity, With<JumpActive>>,
    move_two_query: Query<Entity, With<MoveTwoActive>>,
    knight_query: Query<Entity, With<KnightMoveActive>>,
    existing_indicators: Query<Entity, With<ValidMoveIndicator>>,
) {
    // Clear old indicators
    for entity in existing_indicators.iter() {
        if let Some(mut entity_commands) = commands.get_entity(entity) {
            entity_commands.despawn();
        }
    }

    for (entity, piece) in dragging_pieces.iter() {
        let from = piece.board_position;

        // Collect all piece positions
        let piece_positions: Vec<((u8, u8), Player, Entity)> = pieces
            .iter()
            .map(|(e, p)| (p.board_position, p.player, e))
            .collect();

        // Check all possible positions
        for x in 0..BOARD_WIDTH {
            for y in 0..BOARD_HEIGHT {
                let to = (x, y);

                if validate_enhanced_movement(
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
                    &knight_query,
                ) {
                    // Spawn indicator
                    let world_pos = board_to_world_position(to);
                    commands.spawn((
                        ValidMoveIndicator,
                        SpriteBundle {
                            sprite: Sprite {
                                color: Color::rgba(0.0, 1.0, 0.0, 0.3),
                                custom_size: Some(Vec2::splat(TILE_SIZE * 0.8)),
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
}

fn board_to_world_position(board_pos: (u8, u8)) -> Vec2 {
    let x = (board_pos.0 as f32 - BOARD_WIDTH as f32 / 2.0 + 0.5) * TILE_SIZE;
    let y = (board_pos.1 as f32 - BOARD_HEIGHT as f32 / 2.0 + 0.5) * TILE_SIZE;
    Vec2::new(x, y)
}

// Clean up movement power components after turn
pub fn cleanup_movement_powers(
    mut commands: Commands,
    game_state: ResMut<GameState>,
    pieces: Query<
        (Entity, &GamePiece),
        Or<(
            With<MoveDiagonalActive>,
            With<TeleportActive>,
            With<JumpActive>,
            With<MoveTwoActive>,
            With<KnightMoveActive>,
        )>,
    >,
) {
    // Only clean up when transitioning to next player's turn
    if game_state.is_changed() && game_state.turn_phase == TurnPhase::PowerActivation {
        for (entity, _) in pieces.iter() {
            commands
                .entity(entity)
                .remove::<MoveDiagonalActive>()
                .remove::<TeleportActive>()
                .remove::<JumpActive>()
                .remove::<MoveTwoActive>()
                .remove::<KnightMoveActive>();
        }
    }
}
