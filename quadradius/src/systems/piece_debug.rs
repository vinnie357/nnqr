use crate::components::*;
use crate::systems::isometric_camera::{screen_to_board, IsometricCamera};
use crate::systems::pieces_3d::GamePiece3D;
use bevy::prelude::*;

/// Debug system to count and log piece information
pub fn debug_piece_count(
    pieces_2d: Query<(Entity, &GamePiece), Without<GamePiece3D>>,
    pieces_3d: Query<(Entity, &GamePiece3D)>,
    keyboard: Res<Input<KeyCode>>,
) {
    // Press P to print piece debug info
    if keyboard.just_pressed(KeyCode::P) {
        info!("=== PIECE DEBUG INFO ===");

        // Count 2D pieces
        let mut player1_2d = 0;
        let mut player2_2d = 0;
        let mut positions_2d = Vec::new();

        for (entity, piece) in pieces_2d.iter() {
            match piece.player {
                Player::Player1 => player1_2d += 1,
                Player::Player2 => player2_2d += 1,
            }
            positions_2d.push((entity, piece.player, piece.board_position));
        }

        // Count 3D pieces
        let mut player1_3d = 0;
        let mut player2_3d = 0;
        let mut positions_3d = Vec::new();

        for (entity, piece) in pieces_3d.iter() {
            match piece.player {
                Player::Player1 => player1_3d += 1,
                Player::Player2 => player2_3d += 1,
            }
            positions_3d.push((entity, piece.player, piece.board_position));
        }

        info!(
            "2D Pieces - Player1: {}, Player2: {}, Total: {}",
            player1_2d,
            player2_2d,
            player1_2d + player2_2d
        );
        info!(
            "3D Pieces - Player1: {}, Player2: {}, Total: {}",
            player1_3d,
            player2_3d,
            player1_3d + player2_3d
        );

        // Log all piece positions
        if !positions_2d.is_empty() {
            info!("2D Piece positions:");
            for (entity, player, pos) in positions_2d {
                info!("  Entity {:?}: {:?} at {:?}", entity, player, pos);
            }
        }

        if !positions_3d.is_empty() {
            info!("3D Piece positions:");
            for (entity, player, pos) in positions_3d {
                info!("  Entity {:?}: {:?} at {:?}", entity, player, pos);
            }
        }

        // Expected piece count
        let expected_per_player = calculate_expected_pieces();
        info!("Expected pieces per player: {}", expected_per_player);
        info!("Total expected pieces: {}", expected_per_player * 2);
    }
}

fn calculate_expected_pieces() -> usize {
    let mut count = 0;
    // Player 1 pieces (bottom two rows)
    for y in 0..2 {
        for x in 0..BOARD_WIDTH {
            if (x + y) % 2 == 0 {
                count += 1;
            }
        }
    }
    count
}

/// Debug system to visualize piece hitboxes and selection areas
pub fn debug_piece_selection(
    mut gizmos: Gizmos,
    pieces: Query<(&Transform, &GamePiece3D)>,
    keyboard: Res<Input<KeyCode>>,
) {
    // Press H to show hitboxes
    if keyboard.pressed(KeyCode::H) {
        for (transform, piece) in pieces.iter() {
            let color = match piece.player {
                Player::Player1 => Color::BLUE,
                Player::Player2 => Color::RED,
            };

            // Draw a sphere around the piece position
            gizmos.sphere(
                transform.translation,
                Quat::IDENTITY,
                TILE_SIZE * 0.4,
                color.with_a(0.3),
            );

            // Draw board position text
            let text_pos = transform.translation + Vec3::Y * TILE_SIZE;
            gizmos.line(transform.translation, text_pos, color);
        }
    }
}

/// Debug mouse clicks and board position detection
pub fn debug_mouse_clicks(
    mouse_input: Res<Input<MouseButton>>,
    windows: Query<&Window>,
    camera_q: Query<(&Camera, &GlobalTransform), With<IsometricCamera>>,
    pieces: Query<(Entity, &GamePiece3D, &Transform)>,
    keyboard: Res<Input<KeyCode>>,
) {
    // Only debug when D key is held
    if !keyboard.pressed(KeyCode::D) {
        return;
    }

    if mouse_input.just_pressed(MouseButton::Left) {
        let window = windows.single();
        if let Some(cursor_pos) = window.cursor_position() {
            info!("=== MOUSE CLICK DEBUG ===");
            info!("Screen position: {:?}", cursor_pos);

            // Try to convert to board position
            if let Some(board_pos) = screen_to_board(&windows, &camera_q, cursor_pos) {
                info!("Board position: {:?}", board_pos);

                // Check what pieces are at this position
                let mut found_pieces = Vec::new();
                for (entity, piece, transform) in pieces.iter() {
                    if piece.board_position == board_pos {
                        found_pieces.push((entity, piece.player, transform.translation));
                    }
                }

                if found_pieces.is_empty() {
                    info!("No pieces found at this board position");
                } else {
                    info!("Found {} pieces at this position:", found_pieces.len());
                    for (entity, player, pos) in found_pieces {
                        info!("  Entity {:?}: {:?} at world pos {:?}", entity, player, pos);
                    }
                }

                // Also check nearby positions
                info!("Checking nearby positions:");
                for dx in -1i8..=1 {
                    for dy in -1i8..=1 {
                        if dx == 0 && dy == 0 {
                            continue;
                        }
                        let check_x = board_pos.0 as i8 + dx;
                        let check_y = board_pos.1 as i8 + dy;
                        if check_x >= 0
                            && check_x < BOARD_WIDTH as i8
                            && check_y >= 0
                            && check_y < BOARD_HEIGHT as i8
                        {
                            let check_pos = (check_x as u8, check_y as u8);
                            for (_, piece, _) in pieces.iter() {
                                if piece.board_position == check_pos {
                                    info!(
                                        "  Found {:?} piece at ({}, {})",
                                        piece.player, check_x, check_y
                                    );
                                }
                            }
                        }
                    }
                }
            } else {
                info!("Could not convert to board position (out of bounds?)");
            }

            // Ray cast debug
            let (camera, camera_transform) = camera_q.single();
            if let Some(ray) = camera.viewport_to_world(camera_transform, cursor_pos) {
                info!("Ray origin: {:?}", ray.origin);
                info!("Ray direction: {:?}", ray.direction);
            }
        }
    }
}
