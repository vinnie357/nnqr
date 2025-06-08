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
    // Remove any existing 2D cameras
    commands.spawn((
        Camera3dBundle {
            transform: Transform::from_xyz(0.0, CAMERA_HEIGHT, CAMERA_HEIGHT)
                .looking_at(Vec3::ZERO, Vec3::Y),
            projection: Projection::Orthographic(OrthographicProjection {
                scale: CAMERA_SCALE,
                ..default()
            }),
            ..default()
        },
        IsometricCamera,
    ));
    
    // Add ambient lighting for the 3D scene
    commands.insert_resource(AmbientLight {
        color: Color::WHITE,
        brightness: 0.6,
    });
    
    // Add directional light for shadows and depth
    commands.spawn(DirectionalLightBundle {
        directional_light: DirectionalLight {
            color: Color::WHITE,
            illuminance: 10000.0,
            shadows_enabled: true,
            ..default()
        },
        transform: Transform::from_xyz(4.0, 8.0, 4.0)
            .looking_at(Vec3::ZERO, Vec3::Y),
        ..default()
    });
}

/// Convert board coordinates to isometric world position
pub fn board_to_isometric(board_pos: (u8, u8), height: f32) -> Vec3 {
    let x = board_pos.0 as f32 - (BOARD_SIZE as f32 / 2.0) + 0.5;
    let z = board_pos.1 as f32 - (BOARD_SIZE as f32 / 2.0) + 0.5;
    
    // Apply isometric transformation
    let iso_x = (x - z) * TILE_SIZE * 0.866; // cos(30°)
    let iso_z = (x + z) * TILE_SIZE * 0.5;   // sin(30°)
    let iso_y = height * TILE_SIZE * 0.25;    // Height scaling
    
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
    
    // Since we're using orthographic projection, we can intersect with y=0 plane
    let distance = -ray.origin.y / ray.direction.y;
    let world_pos = ray.origin + ray.direction * distance;
    
    // Convert world position back to board coordinates
    let inv_x = world_pos.x / (TILE_SIZE * 0.866);
    let inv_z = world_pos.z / (TILE_SIZE * 0.5);
    
    let board_x = ((inv_x + inv_z) / 2.0 + (BOARD_SIZE as f32 / 2.0) - 0.5) as i32;
    let board_y = ((inv_z - inv_x) / 2.0 + (BOARD_SIZE as f32 / 2.0) - 0.5) as i32;
    
    // Check if within board bounds
    if board_x >= 0 && board_x < BOARD_SIZE as i32 && 
       board_y >= 0 && board_y < BOARD_SIZE as i32 {
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