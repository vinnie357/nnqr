use crate::components::*;
use crate::resources::QuadradiusTheme;
use crate::systems::{
    depth_sorting::{IsometricDepthSort, TILE_LAYER},
    isometric_camera::board_to_isometric,
};
use bevy::prelude::*;

/// 3D tile component with mesh information
#[derive(Component)]
pub struct BoardTile3D {
    pub coordinates: (u8, u8),
    pub height: i8,
}

/// Setup 3D board with proper meshes and materials
pub fn setup_board_3d(
    mut commands: Commands,
    mut meshes: ResMut<Assets<Mesh>>,
    mut materials: ResMut<Assets<StandardMaterial>>,
) {
    // Create board entity
    commands.spawn((
        Board,
        Transform::from_xyz(0.0, 0.0, 0.0),
        GlobalTransform::default(),
        Visibility::default(),
        ViewVisibility::default(),
    ));

    // Create tile mesh (cube with adjusted proportions for more visible gaps)
    let tile_mesh = meshes.add(Mesh::from(shape::Box::new(
        TILE_SIZE * 0.85, // Smaller for larger gaps
        TILE_SIZE * 0.5,  // Height of tile
        TILE_SIZE * 0.85, // Depth
    )));

    // Create border mesh for tile edges (much more prominent)
    let border_mesh = meshes.add(Mesh::from(shape::Box::new(
        TILE_SIZE * 1.0,  // Full tile size for clear borders
        TILE_SIZE * 0.55, // Slightly higher than tile
        TILE_SIZE * 1.0,  // Full depth
    )));

    // Create tiles with varied heights
    for x in 0..BOARD_WIDTH {
        for y in 0..BOARD_HEIGHT {
            // Create interesting height pattern
            let height = match (x, y) {
                (3, 3) | (4, 4) => 2,
                (2, 3) | (3, 2) | (4, 3) | (3, 4) | (5, 4) | (4, 5) => 1,
                _ => 0,
            };

            let position = board_to_isometric((x, y), height as f32);
            let tile_color = QuadradiusTheme::tile_color_for_height(height);

            // Create material with proper metallic grey appearance
            let tile_material = materials.add(StandardMaterial {
                base_color: QuadradiusTheme::METAL_GUNMETAL, // Use the metallic grey base
                metallic: QuadradiusTheme::METALLIC_VALUE,   // Full metallic value
                perceptual_roughness: QuadradiusTheme::ROUGHNESS_VALUE, // Standard roughness
                ..default()
            });

            // Spawn tile border (much more contrasting outline)
            commands.spawn((PbrBundle {
                mesh: border_mesh.clone(),
                material: materials.add(StandardMaterial {
                    base_color: Color::rgb(0.05, 0.05, 0.05), // Much darker, almost black
                    metallic: 0.9,
                    perceptual_roughness: 0.2,
                    ..default()
                }),
                transform: Transform::from_translation(
                    position - Vec3::Y * 0.02, // Slightly lower than tile
                ),
                ..default()
            },));

            // Spawn main tile
            commands.spawn((
                BoardTile3D {
                    coordinates: (x, y),
                    height,
                },
                BoardTile {
                    coordinates: (x, y),
                    height,
                },
                PbrBundle {
                    mesh: tile_mesh.clone(),
                    material: tile_material,
                    transform: Transform::from_translation(position),
                    visibility: Visibility::Visible,
                    ..default()
                },
                IsometricDepthSort {
                    grid_x: x as f32,
                    grid_y: y as f32,
                    height: height as f32,
                    layer_offset: TILE_LAYER,
                },
            ));
        }
    }

    // Add board base platform
    let base_width = BOARD_WIDTH as f32 * TILE_SIZE * 1.2;
    let base_height = BOARD_HEIGHT as f32 * TILE_SIZE * 1.2;
    let base_mesh = meshes.add(Mesh::from(shape::Box::new(
        base_width,
        TILE_SIZE * 0.2,
        base_height,
    )));

    commands.spawn(PbrBundle {
        mesh: base_mesh,
        material: materials.add(StandardMaterial {
            base_color: QuadradiusTheme::METAL_GUNMETAL,
            metallic: 0.9,
            perceptual_roughness: 0.2,
            ..default()
        }),
        transform: Transform::from_xyz(0.0, -TILE_SIZE * 0.4, 0.0),
        ..default()
    });
}

/// Update tile heights dynamically
pub fn update_tile_heights(mut tiles: Query<(&BoardTile3D, &mut Transform)>, time: Res<Time>) {
    for (tile, mut transform) in tiles.iter_mut() {
        // Smooth height transitions
        let target_position = board_to_isometric(tile.coordinates, tile.height as f32);
        let current = transform.translation;

        // Lerp to target position for smooth transitions
        transform.translation = current.lerp(target_position, 5.0 * time.delta_seconds());
    }
}

/// Highlight tiles on hover
pub fn highlight_board_tiles(
    windows: Query<&Window>,
    camera: Query<
        (&Camera, &GlobalTransform),
        With<crate::systems::isometric_camera::IsometricCamera>,
    >,
    mut tiles: Query<(&BoardTile3D, &Handle<StandardMaterial>)>,
    mut materials: ResMut<Assets<StandardMaterial>>,
) {
    let Some(cursor_pos) = windows.single().cursor_position() else {
        return;
    };

    // Convert cursor to board coordinates
    if let Some(board_pos) =
        crate::systems::isometric_camera::screen_to_board(&windows, &camera, cursor_pos)
    {
        // Update tile materials based on hover
        for (tile, material_handle) in tiles.iter_mut() {
            if let Some(material) = materials.get_mut(material_handle) {
                if tile.coordinates == board_pos {
                    // Highlight hovered tile
                    material.emissive = QuadradiusTheme::ORB_GLOW;
                } else {
                    material.emissive = Color::BLACK;
                }
            }
        }
    }
}
