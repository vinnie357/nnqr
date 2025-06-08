use bevy::prelude::*;
use crate::components::*;

/// Marker component for the isometric camera
#[derive(Component)]
pub struct IsometricCamera;

/// Constants for isometric projection
pub const ISOMETRIC_ANGLE: f32 = 30.0; // Classic isometric angle in degrees
pub const CAMERA_HEIGHT: f32 = 800.0;  // Height of camera for proper board view
pub const CAMERA_SCALE: f32 = 1.5;     // Zoom level for the camera

/// Setup the isometric camera system
pub fn setup_isometric_camera(mut commands: Commands) {
    // Calculate proper isometric camera position
    let distance = 10.0;
    let horizontal_angle = 45.0_f32.to_radians();
    let vertical_angle = 35.264_f32.to_radians(); // arcsin(1/√3) for true isometric
    
    let camera_pos = Vec3::new(
        distance * horizontal_angle.cos() * vertical_angle.cos(),
        distance * vertical_angle.sin(),
        distance * horizontal_angle.sin() * vertical_angle.cos(),
    );
    
    // Use modern Camera3d setup with proper scaling
    commands.spawn((
        Camera3d::default(),
        Projection::from(OrthographicProjection {
            scaling_mode: bevy::render::camera::ScalingMode::FixedVertical { 
                viewport_height: 8.0  // Smaller viewport for better board fit
            },
            near: -1000.0,
            far: 1000.0,
            ..OrthographicProjection::default_3d()
        }),
        Transform::from_translation(camera_pos).looking_at(Vec3::ZERO, Vec3::Y),
        IsometricCamera,
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
        transform: Transform::from_xyz(4.0, 8.0, 4.0)
            .looking_at(Vec3::ZERO, Vec3::Y),
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
        transform: Transform::from_xyz(-3.0, 6.0, -3.0)
            .looking_at(Vec3::ZERO, Vec3::Y),
        ..default()
    });
}

/// Convert board coordinates to isometric world position
pub fn board_to_isometric(board_pos: (u8, u8), height: f32) -> Vec3 {
    // Center the board on screen - offset by half board dimensions
    let centered_x = board_pos.0 as f32 - (BOARD_WIDTH as f32 / 2.0);
    let centered_z = board_pos.1 as f32 - (BOARD_HEIGHT as f32 / 2.0);
    
    // Use standard isometric transformation matrix
    // This creates a classic diamond-shaped isometric view
    let iso_x = (centered_x - centered_z) * 0.5;
    let iso_z = (centered_x + centered_z) * 0.25;
    let iso_y = height * 0.25; // Height scaling
    
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
    
    // Convert world position back to board coordinates using inverse transformation
    let board_x_f = (2.0 * world_pos.x + 4.0 * world_pos.z) + (BOARD_WIDTH as f32 / 2.0);
    let board_y_f = (4.0 * world_pos.z - 2.0 * world_pos.x) + (BOARD_HEIGHT as f32 / 2.0);
    
    let board_x = board_x_f.round() as i32;
    let board_y = board_y_f.round() as i32;
    
    // Check if within board bounds
    if board_x >= 0 && board_x < BOARD_WIDTH as i32 && 
       board_y >= 0 && board_y < BOARD_HEIGHT as i32 {
        Some((board_x as u8, board_y as u8))
    } else {
        None
    }
}

/// Update system to handle camera controls (optional zoom/pan)
pub fn update_isometric_camera(
    keyboard: Res<Input<KeyCode>>,
    mut camera_query: Query<&mut Projection, With<IsometricCamera>>,
    time: Res<Time>,
) {
    if let Ok(mut projection) = camera_query.get_single_mut() {
        if let Projection::Orthographic(ref mut ortho) = projection.as_mut() {
            // Zoom controls
            if keyboard.pressed(KeyCode::Q) {
                ortho.scale = (ortho.scale - 0.5 * time.delta_seconds()).max(0.5);
            }
            if keyboard.pressed(KeyCode::E) {
                ortho.scale = (ortho.scale + 0.5 * time.delta_seconds()).min(3.0);
            }
        }
    }
}