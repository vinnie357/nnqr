use bevy::prelude::*;
use crate::components::*;
use crate::resources::QuadradiusTheme;
use crate::systems::isometric_camera::board_to_isometric;

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
    
    // Create tile mesh (cube with adjusted proportions)
    let tile_mesh = meshes.add(Mesh::from(shape::Box::new(
        TILE_SIZE * 0.95,  // Slightly smaller for gaps
        TILE_SIZE * 0.5,   // Height of tile
        TILE_SIZE * 0.95,  // Depth
    )));
    
    // Create border mesh for tile edges
    let border_mesh = meshes.add(Mesh::from(shape::Box::new(
        TILE_SIZE * 0.98,
        TILE_SIZE * 0.52,
        TILE_SIZE * 0.98,
    )));
    
    // Create tiles with varied heights
    for x in 0..BOARD_SIZE {
        for y in 0..BOARD_SIZE {
            // Create interesting height pattern
            let height = match (x, y) {
                (3, 3) | (4, 4) => 2,
                (2, 3) | (3, 2) | (4, 3) | (3, 4) | (5, 4) | (4, 5) => 1,
                _ => 0,
            };
            
            let position = board_to_isometric((x, y), height as f32);
            let tile_color = QuadradiusTheme::tile_color_for_height(height);
            
            // Create material with metallic properties
            let tile_material = materials.add(StandardMaterial {
                base_color: tile_color,
                metallic: QuadradiusTheme::METALLIC_VALUE * 0.5, // Less metallic for tiles
                perceptual_roughness: QuadradiusTheme::ROUGHNESS_VALUE * 1.5, // Rougher surface
                ..default()
            });
            
            // Spawn tile border (darker outline)
            commands.spawn((
                PbrBundle {
                    mesh: border_mesh.clone(),
                    material: materials.add(StandardMaterial {
                        base_color: QuadradiusTheme::METAL_GUNMETAL,
                        metallic: 0.8,
                        perceptual_roughness: 0.4,
                        ..default()
                    }),
                    transform: Transform::from_translation(
                        position - Vec3::Y * 0.01 // Slightly lower
                    ),
                    ..default()
                },
            ));
            
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
                    ..default()
                },
            ));
        }
    }
    
    // Add board base platform
    let base_size = BOARD_SIZE as f32 * TILE_SIZE * 1.2;
    let base_mesh = meshes.add(Mesh::from(shape::Box::new(
        base_size,
        TILE_SIZE * 0.2,
        base_size,
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
pub fn update_tile_heights(
    mut tiles: Query<(&BoardTile3D, &mut Transform)>,
    time: Res<Time>,
) {
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
    camera: Query<(&Camera, &GlobalTransform), With<crate::systems::isometric_camera::IsometricCamera>>,
    mut tiles: Query<(&BoardTile3D, &Handle<StandardMaterial>)>,
    mut materials: ResMut<Assets<StandardMaterial>>,
) {
    let Some(cursor_pos) = windows.single().cursor_position() else {
        return;
    };
    
    // Convert cursor to board coordinates
    if let Some(board_pos) = crate::systems::isometric_camera::screen_to_board(
        &windows,
        &camera,
        cursor_pos,
    ) {
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