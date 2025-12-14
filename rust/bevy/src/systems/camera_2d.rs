use crate::systems::settings::Camera2D;
use bevy::prelude::*;

/// Setup the 2D camera for top-down view
pub fn setup_camera(mut commands: Commands) {
    commands.spawn((
        Camera2dBundle {
            camera: Camera {
                order: 0, // Same order as 3D camera, they'll be toggled via is_active
                ..default()
            },
            ..default()
        },
        Camera2D,
    ));
}
