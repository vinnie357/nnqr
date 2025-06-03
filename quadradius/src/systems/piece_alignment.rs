use crate::components::*;
use bevy::prelude::*;

// Ensure pieces are always aligned to grid positions
pub fn align_pieces_to_grid(
    mut pieces: Query<(&GamePiece, &mut Transform), Without<Dragging>>,
) {
    for (piece, mut transform) in pieces.iter_mut() {
        let world_pos = board_to_world_position(piece.board_position);
        
        // Only update if the piece is not at the correct position
        let current_x = transform.translation.x;
        let current_y = transform.translation.y;
        
        if (current_x - world_pos.x).abs() > 0.1 || (current_y - world_pos.y).abs() > 0.1 {
            transform.translation.x = world_pos.x;
            transform.translation.y = world_pos.y;
            transform.translation.z = 1.0; // Ensure correct z-level
        }
    }
}

fn board_to_world_position(board_pos: (u8, u8)) -> Vec2 {
    let x = (board_pos.0 as f32 - BOARD_SIZE as f32 / 2.0 + 0.5) * TILE_SIZE;
    let y = (board_pos.1 as f32 - BOARD_SIZE as f32 / 2.0 + 0.5) * TILE_SIZE;
    Vec2::new(x, y)
}