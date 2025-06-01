use bevy::prelude::*;
use crate::{components::*, resources::*};

pub fn handle_piece_movement(
    mut commands: Commands,
    mouse_input: Res<Input<MouseButton>>,
    windows: Query<&Window>,
    camera_q: Query<(&Camera, &GlobalTransform)>,
    mut game_state: ResMut<GameState>,
    tiles: Query<&BoardTile>,
    mut piece_queries: ParamSet<(
        Query<(Entity, &GamePiece, &Transform, &Sprite)>,
        Query<(Entity, &mut GamePiece, &mut Transform, &mut Sprite)>,
    )>,
) {
    if !mouse_input.just_pressed(MouseButton::Right) {
        return;
    }
    
    let Some(selected_entity) = game_state.selected_piece else {
        return;
    };
    
    let window = windows.single();
    let (camera, camera_transform) = camera_q.single();
    
    if let Some(cursor_pos) = window.cursor_position() {
        if let Some(world_pos) = camera.viewport_to_world_2d(camera_transform, cursor_pos) {
            let target_pos = world_to_board_position(world_pos);
            
            // Get piece info and validate move using readonly query
            let mut move_valid = false;
            let mut captured_entity = None;
            
            {
                let pieces_readonly = piece_queries.p0();
                if let Ok((_, piece, _, _)) = pieces_readonly.get(selected_entity) {
                    let current_player = piece.player;
                    let current_position = piece.board_position;
                    
                    if is_valid_move(current_position, target_pos, &tiles, &pieces_readonly, current_player) {
                        move_valid = true;
                        
                        // Find any piece to capture
                        for (other_entity, other_piece, _, _) in pieces_readonly.iter() {
                            if other_entity != selected_entity && 
                               other_piece.board_position == target_pos &&
                               other_piece.player != current_player {
                                captured_entity = Some(other_entity);
                                break;
                            }
                        }
                    }
                }
            }
            
            if move_valid {
                // Despawn captured piece if any
                if let Some(captured) = captured_entity {
                    commands.entity(captured).despawn();
                }
                
                // Update the moving piece using mutable query
                let mut pieces_mut = piece_queries.p1();
                if let Ok((_, mut piece, mut transform, mut sprite)) = pieces_mut.get_mut(selected_entity) {
                    // Move the piece
                    piece.board_position = target_pos;
                    let world_pos = board_to_world_position(target_pos);
                    transform.translation = Vec3::new(world_pos.x, world_pos.y, 1.0);
                    
                    // Deselect piece
                    commands.entity(selected_entity).remove::<Selected>();
                    sprite.color = match piece.player {
                        Player::Player1 => Color::rgb(0.8, 0.2, 0.2),
                        Player::Player2 => Color::rgb(0.2, 0.2, 0.8),
                    };
                }
                
                game_state.selected_piece = None;
                
                // Switch turns
                game_state.current_player = match game_state.current_player {
                    Player::Player1 => Player::Player2,
                    Player::Player2 => Player::Player1,
                };
            }
        }
    }
}

fn is_valid_move(
    from: (u8, u8),
    to: (u8, u8),
    tiles: &Query<&BoardTile>,
    pieces: &Query<(Entity, &GamePiece, &Transform, &Sprite)>,
    current_player: Player,
) -> bool {
    // Check bounds
    if to.0 >= BOARD_SIZE || to.1 >= BOARD_SIZE {
        return false;
    }
    
    // Check if target is occupied by friendly piece
    for (_, piece, _, _) in pieces.iter() {
        if piece.board_position == to && piece.player == current_player {
            return false; // Can't capture own piece
        }
    }
    
    // Check if move is only horizontal or vertical and distance 1
    let dx = (to.0 as i8 - from.0 as i8).abs();
    let dy = (to.1 as i8 - from.1 as i8).abs();
    
    if (dx == 1 && dy == 0) || (dx == 0 && dy == 1) {
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
    let x = ((world_pos.x / TILE_SIZE) + BOARD_SIZE as f32 / 2.0 - 0.5) as u8;
    let y = ((world_pos.y / TILE_SIZE) + BOARD_SIZE as f32 / 2.0 - 0.5) as u8;
    (x.min(BOARD_SIZE - 1), y.min(BOARD_SIZE - 1))
}

fn board_to_world_position(board_pos: (u8, u8)) -> Vec2 {
    let x = (board_pos.0 as f32 - BOARD_SIZE as f32 / 2.0 + 0.5) * TILE_SIZE;
    let y = (board_pos.1 as f32 - BOARD_SIZE as f32 / 2.0 + 0.5) * TILE_SIZE;
    Vec2::new(x, y)
}