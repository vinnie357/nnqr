use crate::components::*;
use crate::resources::RenderConfig;
use bevy::prelude::*;

/// Debug system to force pieces to be visible and highlight them
pub fn debug_piece_visibility(
    mut pieces_2d: Query<
        (&mut Transform, &mut Sprite, &GamePiece),
        (
            With<crate::components::GamePiece>,
            Without<crate::systems::pieces_3d::GamePiece3D>,
        ),
    >,
    mut pieces_3d: Query<
        &mut Transform,
        (
            With<crate::systems::pieces_3d::GamePiece3D>,
            Without<crate::components::GamePiece>,
        ),
    >,
    render_config: Res<RenderConfig>,
    time: Res<Time>,
) {
    if !render_config.use_3d {
        // Debug 2D pieces - make them very visible
        for (mut transform, mut sprite, piece) in pieces_2d.iter_mut() {
            // Force high Z position
            transform.translation.z = 10.0;

            // Make pieces larger and very bright
            sprite.custom_size = Some(Vec2::splat(TILE_SIZE * 1.5));

            // Flash between bright colors to make them very obvious
            let flash = (time.elapsed_seconds() * 3.0).sin() * 0.5 + 0.5;
            sprite.color = Color::rgb(1.0, flash, 0.0); // Bright orange/yellow flash

            // Log piece position
            if piece.board_position == (0, 0) {
                info!(
                    "🐛 Debug: Piece at (0,0) world pos: ({:.1}, {:.1}, {:.1})",
                    transform.translation.x, transform.translation.y, transform.translation.z
                );
            }
        }
    } else {
        // Debug 3D pieces - force very high Y position
        for mut transform in pieces_3d.iter_mut() {
            // Force pieces way above everything
            transform.translation.y += 100.0;
        }
    }
}

/// Debug system to log all visible entities
pub fn debug_log_visible_entities(
    pieces_2d: Query<(&Transform, &Visibility, &GamePiece), With<crate::components::GamePiece>>,
    pieces_3d: Query<(&Transform, &Visibility), With<crate::systems::pieces_3d::GamePiece3D>>,
    board_2d: Query<&Visibility, With<crate::components::Board>>,
    mut logged: Local<bool>,
) {
    if !*logged {
        *logged = true;

        let visible_2d = pieces_2d
            .iter()
            .filter(|(_, vis, _)| **vis == Visibility::Visible)
            .count();
        let hidden_2d = pieces_2d
            .iter()
            .filter(|(_, vis, _)| **vis == Visibility::Hidden)
            .count();
        let visible_3d = pieces_3d
            .iter()
            .filter(|(_, vis)| **vis == Visibility::Visible)
            .count();
        let hidden_3d = pieces_3d
            .iter()
            .filter(|(_, vis)| **vis == Visibility::Hidden)
            .count();
        let visible_board = board_2d
            .iter()
            .filter(|vis| **vis == Visibility::Visible)
            .count();

        info!("🐛 Visibility Debug:");
        info!("   2D Pieces: {} visible, {} hidden", visible_2d, hidden_2d);
        info!("   3D Pieces: {} visible, {} hidden", visible_3d, hidden_3d);
        info!("   2D Board tiles: {} visible", visible_board);

        // Log first few piece positions
        for (transform, vis, piece) in pieces_2d.iter().take(3) {
            info!(
                "   Piece at ({}, {}): world ({:.1}, {:.1}, {:.1}), visibility: {:?}",
                piece.board_position.0,
                piece.board_position.1,
                transform.translation.x,
                transform.translation.y,
                transform.translation.z,
                vis
            );
        }
    }
}

/// Force all pieces to be bright and visible for debugging
pub fn force_piece_visibility(
    mut pieces_2d: Query<(&mut Visibility, &mut Sprite), With<crate::components::GamePiece>>,
    mut pieces_3d: Query<
        &mut Visibility,
        (
            With<crate::systems::pieces_3d::GamePiece3D>,
            Without<crate::components::GamePiece>,
        ),
    >,
    render_config: Res<RenderConfig>,
) {
    if !render_config.use_3d {
        for (mut visibility, mut sprite) in pieces_2d.iter_mut() {
            *visibility = Visibility::Visible;
            sprite.color = Color::rgb(1.0, 0.0, 1.0); // Bright magenta
        }
    } else {
        for mut visibility in pieces_3d.iter_mut() {
            *visibility = Visibility::Visible;
        }
    }
}

/// Debug 3D piece positioning specifically
pub fn debug_3d_piece_positions(
    pieces_3d: Query<(
        &Transform,
        &crate::systems::pieces_3d::GamePiece3D,
        &Visibility,
    )>,
    tiles_3d: Query<(&Transform, &crate::systems::board_3d::BoardTile3D)>,
    render_config: Res<RenderConfig>,
    mut logged: Local<bool>,
) {
    if render_config.use_3d && !*logged {
        *logged = true;

        info!("🐛 3D Piece Position Debug:");
        for (piece_transform, piece_3d, visibility) in pieces_3d.iter().take(3) {
            info!(
                "   Piece at ({}, {}): Y={:.1}, Z={:.1}, visibility={:?}",
                piece_3d.board_position.0,
                piece_3d.board_position.1,
                piece_transform.translation.y,
                piece_transform.translation.z,
                visibility
            );

            // Find corresponding tile
            for (tile_transform, tile_3d) in tiles_3d.iter() {
                if tile_3d.coordinates == piece_3d.board_position {
                    let height_diff = piece_transform.translation.y - tile_transform.translation.y;
                    info!(
                        "   Corresponding tile Y={:.1}, height difference={:.1}",
                        tile_transform.translation.y, height_diff
                    );
                    break;
                }
            }
        }
    }
}
