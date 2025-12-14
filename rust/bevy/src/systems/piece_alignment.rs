use crate::components::*;
use crate::resources::RenderConfig;
use bevy::prelude::*;

// Ensure pieces are always aligned to grid positions (2D mode only)
pub fn align_pieces_to_grid(
    mut pieces: Query<(&GamePiece, &mut Transform), Without<Dragging>>,
    config: Res<RenderConfig>,
) {
    // Only run in 2D mode to avoid conflicts with 3D positioning systems
    if config.use_3d {
        return;
    }
    for (piece, mut transform) in pieces.iter_mut() {
        let world_pos = board_to_world_position(piece.board_position);

        // Only update if the piece is not at the correct position
        let current_x = transform.translation.x;
        let current_y = transform.translation.y;

        if (current_x - world_pos.x).abs() > 0.1 || (current_y - world_pos.y).abs() > 0.1 {
            transform.translation.x = world_pos.x;
            transform.translation.y = world_pos.y;
            transform.translation.z = 5.0; // Much higher Z to ensure pieces are above everything
        }
    }
}

fn board_to_world_position(board_pos: (u8, u8)) -> Vec2 {
    // Use correct board dimensions: 10x8 instead of deprecated 8x8
    let enhanced_tile_size = TILE_SIZE * 1.2; // Match the enhanced tile size from board.rs
    let x = (board_pos.0 as f32 - BOARD_WIDTH as f32 / 2.0 + 0.5) * enhanced_tile_size;
    let y = (board_pos.1 as f32 - BOARD_HEIGHT as f32 / 2.0 + 0.5) * enhanced_tile_size;
    Vec2::new(x, y)
}
