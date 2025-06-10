use crate::components::*;
use bevy::prelude::*;

/// Marker component for the isometric camera
#[derive(Component)]
pub struct IsometricCamera;

/// Constants for isometric projection
pub const ISOMETRIC_ANGLE: f32 = 30.0; // Classic isometric angle in degrees
pub const CAMERA_HEIGHT: f32 = 800.0; // Height of camera for proper board view
pub const CAMERA_SCALE: f32 = 1.5; // Zoom level for the camera

/// Setup the isometric camera system
pub fn setup_isometric_camera(mut commands: Commands) {
    // Calculate optimal isometric camera position for 10x8 board with enhanced visibility
    let distance = 900.0; // Increased distance for better overview of larger tiles
    let horizontal_angle = 45.0_f32.to_radians();
    let vertical_angle = 35.0_f32.to_radians(); // Better isometric angle for board visibility

    let camera_pos = Vec3::new(
        distance * horizontal_angle.cos() * vertical_angle.cos(),
        distance * vertical_angle.sin(),
        distance * horizontal_angle.sin() * vertical_angle.cos(),
    );

    // Use modern Camera3d setup with optimal scaling for enhanced 10x8 board
    commands.spawn((
        Camera3dBundle {
            projection: Projection::Orthographic(OrthographicProjection {
                scaling_mode: bevy::render::camera::ScalingMode::FixedVertical(750.0), // Larger scale to accommodate bigger tiles
                near: -2000.0,
                far: 2000.0,
                ..default()
            }),
            transform: Transform::from_translation(camera_pos).looking_at(Vec3::ZERO, Vec3::Y),
            ..default()
        },
        IsometricCamera,
        crate::systems::settings::Camera3D,
    ));

    // Add ambient lighting for the 3D scene - brighter for better visibility
    commands.insert_resource(AmbientLight {
        color: Color::rgb(0.9, 0.9, 1.0), // Slightly cool ambient
        brightness: 0.8,
    });

    // Add main directional light for shadows and depth
    commands.spawn(DirectionalLightBundle {
        directional_light: DirectionalLight {
            color: Color::rgb(1.0, 0.98, 0.95), // Warm main light
            illuminance: 15000.0,
            shadows_enabled: true,
            ..default()
        },
        transform: Transform::from_xyz(4.0, 8.0, 4.0).looking_at(Vec3::ZERO, Vec3::Y),
        ..default()
    });

    // Add fill light to reduce harsh shadows
    commands.spawn(DirectionalLightBundle {
        directional_light: DirectionalLight {
            color: Color::rgb(0.8, 0.85, 1.0), // Cool fill light
            illuminance: 5000.0,
            shadows_enabled: false,
            ..default()
        },
        transform: Transform::from_xyz(-3.0, 6.0, -3.0).looking_at(Vec3::ZERO, Vec3::Y),
        ..default()
    });
}

/// Convert board coordinates to isometric world position
pub fn board_to_isometric(board_pos: (u8, u8), height: f32) -> Vec3 {
    // Center the board on screen - offset by half board dimensions
    let centered_x = board_pos.0 as f32 - (BOARD_WIDTH as f32 / 2.0) + 0.5;
    let centered_z = board_pos.1 as f32 - (BOARD_HEIGHT as f32 / 2.0) + 0.5;

    // Use isometric transformation with enhanced tile size for better visibility
    let enhanced_tile_size = TILE_SIZE * 1.2; // Match the enhanced tile size from board_3d
    let iso_x = (centered_x - centered_z) * enhanced_tile_size * 0.5;
    let iso_z = (centered_x + centered_z) * enhanced_tile_size * 0.25;
    let iso_y = height * enhanced_tile_size * 0.15; // Slightly enhanced height scaling

    Vec3::new(iso_x, iso_y, iso_z)
}

/// Convert screen position to board coordinates (for mouse picking)
pub fn screen_to_board(
    windows: &Query<&Window>,
    camera: &Query<(&Camera, &GlobalTransform), With<IsometricCamera>>,
    screen_pos: Vec2,
) -> Option<(u8, u8)> {
    let (camera, camera_transform) = camera.single();
    let _window = windows.single();

    // Convert screen coordinates to world coordinates
    let ray = camera.viewport_to_world(camera_transform, screen_pos)?;

    // Since we're using orthographic projection, intersect with y=0 plane
    let distance = if ray.direction.y.abs() > 0.001 {
        -ray.origin.y / ray.direction.y
    } else {
        return None;
    };

    let world_pos = ray.origin + ray.direction * distance;

    // Convert world position back to board coordinates using inverse transformation with enhanced tile size
    let enhanced_tile_size = TILE_SIZE * 1.2; // Match the enhanced tile size

    // Reverse the isometric transformation:
    // iso_x = (centered_x - centered_z) * enhanced_tile_size * 0.5
    // iso_z = (centered_x + centered_z) * enhanced_tile_size * 0.25
    //
    // Solving for centered_x and centered_z:
    // centered_x = (iso_x / (enhanced_tile_size * 0.5) + iso_z / (enhanced_tile_size * 0.25)) / 2.0
    // centered_z = (iso_z / (enhanced_tile_size * 0.25) - iso_x / (enhanced_tile_size * 0.5)) / 2.0

    let centered_x = (world_pos.x / (enhanced_tile_size * 0.5)
        + world_pos.z / (enhanced_tile_size * 0.25))
        / 2.0;
    let centered_z = (world_pos.z / (enhanced_tile_size * 0.25)
        - world_pos.x / (enhanced_tile_size * 0.5))
        / 2.0;

    // Convert back to board coordinates
    let board_x_f = centered_x + (BOARD_WIDTH as f32 / 2.0) - 0.5;
    let board_y_f = centered_z + (BOARD_HEIGHT as f32 / 2.0) - 0.5;

    let board_x = board_x_f.round() as i32;
    let board_y = board_y_f.round() as i32;

    // Check if within board bounds
    if board_x >= 0 && board_x < BOARD_WIDTH as i32 && board_y >= 0 && board_y < BOARD_HEIGHT as i32
    {
        Some((board_x as u8, board_y as u8))
    } else {
        None
    }
}

/// Update system to handle camera controls (zoom and rotation)
pub fn update_isometric_camera(
    keyboard: Res<Input<KeyCode>>,
    mut camera_query: Query<&mut Transform, With<IsometricCamera>>,
    mut projection_query: Query<&mut Projection, With<IsometricCamera>>,
    time: Res<Time>,
) {
    // Handle zoom controls
    if let Ok(mut projection) = projection_query.get_single_mut() {
        if let Projection::Orthographic(ref mut ortho) = projection.as_mut() {
            if keyboard.pressed(KeyCode::Q) {
                ortho.scale = (ortho.scale - 0.5 * time.delta_seconds()).max(0.5);
            }
            if keyboard.pressed(KeyCode::E) {
                ortho.scale = (ortho.scale + 0.5 * time.delta_seconds()).min(3.0);
            }
        }
    }

    // Handle camera rotation controls
    if let Ok(mut transform) = camera_query.get_single_mut() {
        let rotation_speed = 60.0_f32.to_radians(); // degrees per second
        let mut rotation_changed = false;

        // A/D keys for horizontal rotation around Y-axis
        if keyboard.pressed(KeyCode::A) {
            transform.rotate_around(
                Vec3::ZERO,
                Quat::from_rotation_y(rotation_speed * time.delta_seconds()),
            );
            rotation_changed = true;
        }
        if keyboard.pressed(KeyCode::D) {
            transform.rotate_around(
                Vec3::ZERO,
                Quat::from_rotation_y(-rotation_speed * time.delta_seconds()),
            );
            rotation_changed = true;
        }

        // W/S keys for vertical rotation (limited range to prevent flipping)
        if keyboard.pressed(KeyCode::W) {
            let current_angle = transform
                .translation
                .y
                .atan2((transform.translation.x.powi(2) + transform.translation.z.powi(2)).sqrt());
            if current_angle < 80.0_f32.to_radians() {
                let axis = transform.translation.cross(Vec3::Y).normalize();
                transform.rotate_around(
                    Vec3::ZERO,
                    Quat::from_axis_angle(axis, rotation_speed * time.delta_seconds()),
                );
                rotation_changed = true;
            }
        }
        if keyboard.pressed(KeyCode::S) {
            let current_angle = transform
                .translation
                .y
                .atan2((transform.translation.x.powi(2) + transform.translation.z.powi(2)).sqrt());
            if current_angle > 10.0_f32.to_radians() {
                let axis = transform.translation.cross(Vec3::Y).normalize();
                transform.rotate_around(
                    Vec3::ZERO,
                    Quat::from_axis_angle(axis, -rotation_speed * time.delta_seconds()),
                );
                rotation_changed = true;
            }
        }

        // R key to reset camera to default position
        if keyboard.just_pressed(KeyCode::R) {
            let distance = 900.0; // Match the enhanced setup camera distance
            let horizontal_angle = 45.0_f32.to_radians();
            let vertical_angle = 35.0_f32.to_radians(); // Match the enhanced setup camera angle

            let camera_pos = Vec3::new(
                distance * horizontal_angle.cos() * vertical_angle.cos(),
                distance * vertical_angle.sin(),
                distance * horizontal_angle.sin() * vertical_angle.cos(),
            );

            transform.translation = camera_pos;
            transform.look_at(Vec3::ZERO, Vec3::Y);
            rotation_changed = true;
        }

        // Always look at the center when rotation changes
        if rotation_changed {
            transform.look_at(Vec3::ZERO, Vec3::Y);
        }
    }
}
