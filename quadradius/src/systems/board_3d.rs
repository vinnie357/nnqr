use crate::components::*;
use crate::resources::QuadradiusTheme;
use crate::systems::{
    depth_sorting::{IsometricDepthSort, TILE_LAYER},
    drag_drop::ValidMoveIndicator,
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

    // Create larger tile mesh for better visibility
    let tile_size = TILE_SIZE * 1.2; // Increase tile size by 20% for better visibility
    let tile_mesh = meshes.add(Mesh::from(shape::Box::new(
        tile_size * 0.88, // Tiles with visible gaps between them
        tile_size * 0.4,  // Increased height for better 3D effect
        tile_size * 0.88, // Depth
    )));

    // Create prominent grid lines between tiles
    let grid_line_mesh = meshes.add(Mesh::from(shape::Box::new(
        tile_size * 0.95, // Slightly larger than tile
        tile_size * 0.15, // Thinner for clear separation
        tile_size * 0.95, // Depth
    )));

    // Create board border frame to define the board boundaries clearly
    let board_width = BOARD_WIDTH as f32 * tile_size;
    let board_height = BOARD_HEIGHT as f32 * tile_size;

    // Border frame material - highly visible
    let border_material = materials.add(StandardMaterial {
        base_color: Color::rgb(0.15, 0.15, 0.20), // Dark contrast
        metallic: 0.8,
        perceptual_roughness: 0.2,
        emissive: Color::rgb(0.1, 0.1, 0.15), // Subtle glow
        ..default()
    });

    // Create 4 border pieces to frame the board
    let border_thickness = tile_size * 0.1;
    let border_height = tile_size * 0.6;

    // Top border
    commands.spawn(PbrBundle {
        mesh: meshes.add(Mesh::from(shape::Box::new(
            board_width + border_thickness * 2.0,
            border_height,
            border_thickness,
        ))),
        material: border_material.clone(),
        transform: Transform::from_xyz(
            0.0,
            border_height * 0.3,
            board_height * 0.5 + border_thickness * 0.5,
        ),
        ..default()
    });

    // Bottom border
    commands.spawn(PbrBundle {
        mesh: meshes.add(Mesh::from(shape::Box::new(
            board_width + border_thickness * 2.0,
            border_height,
            border_thickness,
        ))),
        material: border_material.clone(),
        transform: Transform::from_xyz(
            0.0,
            border_height * 0.3,
            -board_height * 0.5 - border_thickness * 0.5,
        ),
        ..default()
    });

    // Left border
    commands.spawn(PbrBundle {
        mesh: meshes.add(Mesh::from(shape::Box::new(
            border_thickness,
            border_height,
            board_height,
        ))),
        material: border_material.clone(),
        transform: Transform::from_xyz(
            -board_width * 0.5 - border_thickness * 0.5,
            border_height * 0.3,
            0.0,
        ),
        ..default()
    });

    // Right border
    commands.spawn(PbrBundle {
        mesh: meshes.add(Mesh::from(shape::Box::new(
            border_thickness,
            border_height,
            board_height,
        ))),
        material: border_material,
        transform: Transform::from_xyz(
            board_width * 0.5 + border_thickness * 0.5,
            border_height * 0.3,
            0.0,
        ),
        ..default()
    });

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

            // Enhanced tile material with better contrast
            let tile_material = materials.add(StandardMaterial {
                base_color: tile_color,
                metallic: QuadradiusTheme::METALLIC_VALUE,
                perceptual_roughness: QuadradiusTheme::ROUGHNESS_VALUE,
                // Add subtle emissive glow for better visibility
                emissive: Color::rgb(
                    tile_color.r() * 0.1,
                    tile_color.g() * 0.1,
                    tile_color.b() * 0.1,
                ),
                ..default()
            });

            // Spawn prominent grid lines (dark lines between tiles for clear separation)
            commands.spawn(PbrBundle {
                mesh: grid_line_mesh.clone(),
                material: materials.add(StandardMaterial {
                    base_color: Color::rgb(0.1, 0.1, 0.15), // Very dark for high contrast
                    metallic: 0.3,
                    perceptual_roughness: 0.8,
                    emissive: Color::rgb(0.05, 0.05, 0.08), // Subtle dark glow
                    ..default()
                }),
                transform: Transform::from_translation(
                    position - Vec3::Y * tile_size * 0.12, // Lower than tile for clear grid lines
                ),
                ..default()
            });

            // Spawn main tile with enhanced visibility
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

    // Add board base platform with improved visibility
    let base_width = BOARD_WIDTH as f32 * tile_size * 1.1;
    let base_height = BOARD_HEIGHT as f32 * tile_size * 1.1;
    let base_mesh = meshes.add(Mesh::from(shape::Box::new(
        base_width,
        tile_size * 0.25,
        base_height,
    )));

    commands.spawn(PbrBundle {
        mesh: base_mesh,
        material: materials.add(StandardMaterial {
            base_color: Color::rgb(0.2, 0.22, 0.25), // Darker contrast base
            metallic: 0.8,
            perceptual_roughness: 0.4,
            emissive: Color::rgb(0.05, 0.05, 0.08), // Subtle base glow
            ..default()
        }),
        transform: Transform::from_xyz(0.0, -tile_size * 0.4, 0.0), // Adjusted for new tile size
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

/// Highlight tiles with enhanced visibility for valid moves
pub fn highlight_board_tiles(
    windows: Query<&Window>,
    camera: Query<
        (&Camera, &GlobalTransform),
        With<crate::systems::isometric_camera::IsometricCamera>,
    >,
    mut tiles: Query<(&BoardTile3D, &Handle<StandardMaterial>)>,
    mut materials: ResMut<Assets<StandardMaterial>>,
    valid_moves: Query<Entity, With<ValidMoveIndicator>>,
    selected_pieces: Query<&BoardTile, With<Selected>>,
) {
    let Some(cursor_pos) = windows.single().cursor_position() else {
        return;
    };

    // First, clear all highlights and reset to base colors
    for (tile, material_handle) in tiles.iter_mut() {
        if let Some(material) = materials.get_mut(material_handle) {
            let base_color = QuadradiusTheme::tile_color_for_height(tile.height);
            material.emissive = Color::rgb(
                base_color.r() * 0.1,
                base_color.g() * 0.1,
                base_color.b() * 0.1,
            );
        }
    }

    // Highlight valid move tiles with distinct green glow
    for valid_move_entity in valid_moves.iter() {
        // Valid move highlighting is handled by the ValidMoveIndicator component
        // This ensures it's not masked by other color overlays
    }

    // Highlight selected piece positions with blue glow
    for selected_tile in selected_pieces.iter() {
        for (tile, material_handle) in tiles.iter_mut() {
            if tile.coordinates == selected_tile.coordinates {
                if let Some(material) = materials.get_mut(material_handle) {
                    material.emissive = Color::rgb(0.3, 0.5, 0.8); // Strong blue highlight for selected pieces
                }
            }
        }
    }

    // Convert cursor to board coordinates for hover highlighting
    if let Some(board_pos) =
        crate::systems::isometric_camera::screen_to_board(&windows, &camera, cursor_pos)
    {
        // Update tile materials based on hover with subtle white glow
        for (tile, material_handle) in tiles.iter_mut() {
            if let Some(material) = materials.get_mut(material_handle) {
                if tile.coordinates == board_pos {
                    // Add subtle hover highlight that doesn't override other highlights
                    let current_emissive = material.emissive;
                    material.emissive = Color::rgb(
                        (current_emissive.r() + 0.15).min(1.0),
                        (current_emissive.g() + 0.15).min(1.0),
                        (current_emissive.b() + 0.15).min(1.0),
                    );
                }
            }
        }
    }
}
