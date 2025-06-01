use bevy::prelude::*;
use crate::{components::*, resources::*};

pub fn handle_piece_selection(
    mut commands: Commands,
    mouse_input: Res<Input<MouseButton>>,
    windows: Query<&Window>,
    camera_q: Query<(&Camera, &GlobalTransform)>,
    mut game_state: ResMut<GameState>,
    mut pieces: Query<(Entity, &GamePiece, &mut Sprite), Without<Selected>>,
    mut selected_pieces: Query<(Entity, &GamePiece, &mut Sprite), With<Selected>>,
) {
    if !mouse_input.just_pressed(MouseButton::Left) {
        return;
    }
    
    let window = windows.single();
    let (camera, camera_transform) = camera_q.single();
    
    if let Some(cursor_pos) = window.cursor_position() {
        if let Some(world_pos) = camera.viewport_to_world_2d(camera_transform, cursor_pos) {
            let board_pos = world_to_board_position(world_pos);
            
            // Deselect currently selected piece
            for (entity, _, mut sprite) in selected_pieces.iter_mut() {
                commands.entity(entity).remove::<Selected>();
                // Reset color based on player
                let piece = pieces.get(entity).unwrap().1;
                sprite.color = match piece.player {
                    Player::Player1 => Color::rgb(0.8, 0.2, 0.2),
                    Player::Player2 => Color::rgb(0.2, 0.2, 0.8),
                };
            }
            game_state.selected_piece = None;
            
            // Try to select piece at clicked position
            for (entity, piece, mut sprite) in pieces.iter_mut() {
                if piece.board_position == board_pos && piece.player == game_state.current_player {
                    commands.entity(entity).insert(Selected);
                    sprite.color = Color::rgb(1.0, 1.0, 0.0); // Yellow for selected
                    game_state.selected_piece = Some(entity);
                    break;
                }
            }
        }
    }
}

fn world_to_board_position(world_pos: Vec2) -> (u8, u8) {
    let x = ((world_pos.x / TILE_SIZE) + BOARD_SIZE as f32 / 2.0 - 0.5) as u8;
    let y = ((world_pos.y / TILE_SIZE) + BOARD_SIZE as f32 / 2.0 - 0.5) as u8;
    (x.min(BOARD_SIZE - 1), y.min(BOARD_SIZE - 1))
}