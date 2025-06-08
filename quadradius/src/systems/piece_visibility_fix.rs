use crate::components::*;
use crate::resources::{GameState, TurnPhase};
use crate::systems::pieces_3d::GamePiece3D;
use bevy::prelude::*;

/// Fix piece visibility by ensuring they're properly rendered with correct isometric positioning
pub fn fix_piece_visibility(
    mut pieces: Query<(Entity, &mut Transform, &GamePiece3D), Without<Selected>>,
    mut visibility_query: Query<&mut Visibility>,
) {
    for (entity, mut piece_transform, piece) in pieces.iter_mut() {
        // Use the proper isometric conversion function
        let world_pos =
            crate::systems::isometric_camera::board_to_isometric(piece.board_position, 0.0);

        // Position piece slightly above the board
        piece_transform.translation = Vec3::new(
            world_pos.x,
            world_pos.y + TILE_SIZE * 0.35, // Piece height above board
            world_pos.z,
        );

        // Ensure piece is visible
        piece_transform.scale = Vec3::splat(1.0);

        // Make sure visibility is set
        if let Ok(mut visibility) = visibility_query.get_mut(entity) {
            *visibility = Visibility::Visible;
        }
    }
}

/// Enhanced piece visibility system that ensures all pieces are visible and clickable
pub fn ensure_piece_visibility(mut pieces: Query<(&mut Transform, &GamePiece3D, &mut Visibility)>) {
    for (mut transform, piece, mut visibility) in pieces.iter_mut() {
        // Use the standard board to isometric conversion
        let world_pos =
            crate::systems::isometric_camera::board_to_isometric(piece.board_position, 0.0);

        // Update position with proper height
        transform.translation = Vec3::new(
            world_pos.x,
            world_pos.y + TILE_SIZE * 0.35, // Elevated above board
            world_pos.z,
        );

        // Ensure scale is normal
        transform.scale = Vec3::splat(1.0);

        // Force visibility
        *visibility = Visibility::Visible;

        // Debug info only on demand - disabled to prevent log spam
        #[cfg(debug_assertions)]
        if false {
            // Enable this only for debugging specific issues
            if piece.board_position == (0, 0) || piece.board_position == (7, 7) {
                info!(
                    "Piece at {:?} positioned at world {:?}",
                    piece.board_position, transform.translation
                );
            }
        }
    }
}

/// Alternative piece selection using 3D raycasting
pub fn raycast_piece_selection(
    mouse_input: Res<Input<MouseButton>>,
    windows: Query<&Window>,
    camera_q: Query<
        (&Camera, &GlobalTransform),
        With<crate::systems::isometric_camera::IsometricCamera>,
    >,
    pieces: Query<(Entity, &GamePiece3D, &Transform, &GlobalTransform)>,
    game_state: Res<GameState>,
    mut commands: Commands,
) {
    if !mouse_input.just_pressed(MouseButton::Left) {
        return;
    }

    if game_state.turn_phase != TurnPhase::PieceMovement {
        return;
    }

    let Ok(window) = windows.get_single() else {
        warn!("No window available for raycast selection");
        return;
    };
    let Some(cursor_pos) = window.cursor_position() else {
        return;
    };

    let Ok((camera, camera_transform)) = camera_q.get_single() else {
        warn!("No camera available for raycast selection");
        return;
    };
    let Some(ray) = camera.viewport_to_world(camera_transform, cursor_pos) else {
        return;
    };

    // Find the closest piece to the ray
    let mut closest_piece = None;
    let mut closest_distance = f32::MAX;

    for (entity, piece, _transform, global_transform) in pieces.iter() {
        // Only select current player's pieces
        if piece.player != game_state.current_player {
            continue;
        }

        // Simple sphere collision with ray
        let piece_pos = global_transform.translation();
        let piece_radius = TILE_SIZE * 0.4;

        // Calculate distance from ray to piece center
        let ray_to_piece = piece_pos - ray.origin;
        let ray_distance = ray_to_piece.dot(ray.direction);

        if ray_distance < 0.0 {
            continue; // Piece is behind camera
        }

        let closest_point = ray.origin + ray.direction * ray_distance;
        let distance_to_piece = (closest_point - piece_pos).length();

        if distance_to_piece <= piece_radius && ray_distance < closest_distance {
            closest_distance = ray_distance;
            closest_piece = Some((entity, piece.board_position));
        }
    }

    if let Some((entity, pos)) = closest_piece {
        // Debug logging only in debug builds and when needed
        #[cfg(debug_assertions)]
        if false {
            // Enable for debugging piece selection issues
            info!("Selected piece at {:?} via raycast", pos);
        }
        commands.entity(entity).insert(Selected);
        commands
            .entity(entity)
            .insert(crate::systems::drag_drop_3d::Dragging3D { start_pos: pos });
    }
}
