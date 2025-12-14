use crate::components::*;
use crate::resources::QuadradiusTheme;
use crate::systems::{
    depth_sorting::{IsometricDepthSort, TILE_LAYER},
    drag_drop::ValidMoveIndicator,
    isometric_camera::board_to_isometric,
};
use bevy::prelude::*;

// Enhanced 3D board constants
pub const TILE_SIZE_MULTIPLIER_3D: f32 = 1.5; // Increased from 1.2 for better visibility
pub const HEIGHT_MULTIPLIER_3D: f32 = 0.5; // Increased from 0.15 for dramatic height differences
pub const GRID_LINE_THICKNESS: f32 = 0.02; // Thickness for grid lines
pub const BORDER_THICKNESS_3D: f32 = 0.15; // Thicker borders for visibility

/// Component for coordinate labels
#[derive(Component)]
pub struct CoordinateLabel;

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

    // Create enhanced tile mesh for dramatically better visibility
    let tile_size = TILE_SIZE * TILE_SIZE_MULTIPLIER_3D; // Use enhanced multiplier
    let tile_mesh = meshes.add(Mesh::from(shape::Box::new(
        tile_size * 0.85, // Tiles with clear gaps between them
        tile_size * 0.6,  // Much taller for better 3D effect
        tile_size * 0.85, // Depth
    )));

    // Create enhanced grid lines for better tile separation
    let grid_line_mesh = meshes.add(Mesh::from(shape::Box::new(
        tile_size * 0.98,                // Nearly full tile size for clear borders
        tile_size * GRID_LINE_THICKNESS, // Thin but visible grid lines
        tile_size * 0.98,                // Depth
    )));

    // Create board border frame to define the board boundaries clearly
    let board_width = BOARD_WIDTH as f32 * tile_size;
    let board_height = BOARD_HEIGHT as f32 * tile_size;

    // Enhanced border frame material - highly visible with metallic finish
    let border_material = materials.add(StandardMaterial {
        base_color: Color::rgb(0.25, 0.27, 0.30), // Brighter for better visibility
        metallic: 0.9,
        perceptual_roughness: 0.1,
        emissive: Color::rgb(0.15, 0.17, 0.20), // Stronger glow for prominence
        ..default()
    });

    // Create enhanced border pieces with better proportions
    let border_thickness = tile_size * BORDER_THICKNESS_3D; // Use constant
    let border_height = tile_size * 0.8; // Taller borders for clear definition

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

            // Enhanced tile material with dramatic improvements
            let tile_material = materials.add(StandardMaterial {
                base_color: tile_color,
                metallic: 0.8,             // Increased metallic for better reflections
                perceptual_roughness: 0.2, // Smoother for better light reflection
                // Enhanced emissive glow based on height for better visibility
                emissive: Color::rgb(
                    tile_color.r() * (0.2 + height as f32 * 0.08), // Even brighter glow for height distinction
                    tile_color.g() * (0.2 + height as f32 * 0.08),
                    tile_color.b() * (0.2 + height as f32 * 0.08),
                ),
                // Add subtle ambient occlusion effect for depth
                unlit: false, // Ensure proper lighting calculations
                alpha_mode: AlphaMode::Opaque,
                ..default()
            });

            // Spawn enhanced grid lines for dramatic tile separation
            commands.spawn(PbrBundle {
                mesh: grid_line_mesh.clone(),
                material: materials.add(StandardMaterial {
                    base_color: Color::rgb(0.12, 0.12, 0.18), // Slightly brighter for visibility
                    metallic: 0.4,
                    perceptual_roughness: 0.7,
                    emissive: Color::rgb(0.08, 0.08, 0.12), // Enhanced glow for grid visibility
                    ..default()
                }),
                transform: Transform::from_translation(
                    position - Vec3::Y * tile_size * 0.08, // Closer to tiles for clearer separation
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

    // Add coordinate labels for better board navigation
    setup_coordinate_labels(&mut commands, &mut meshes, &mut materials, tile_size);

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

/// Setup enhanced lighting system for dramatic 3D board visibility
pub fn setup_enhanced_lighting(mut commands: Commands) {
    // Enhanced ambient lighting for better overall visibility
    commands.insert_resource(AmbientLight {
        color: Color::rgb(0.85, 0.87, 0.90), // Cool ambient light
        brightness: 0.4,                     // Moderate ambient to preserve shadows
    });

    // Primary key light - main illumination
    commands.spawn(DirectionalLightBundle {
        directional_light: DirectionalLight {
            color: Color::rgb(1.0, 0.98, 0.95), // Warm main light
            illuminance: 60000.0,               // Increased brightness for clear visibility
            shadows_enabled: true,
            shadow_depth_bias: 0.02,
            shadow_normal_bias: 0.02,
        },
        transform: Transform::from_xyz(8.0, 12.0, 8.0).looking_at(Vec3::ZERO, Vec3::Y),
        ..default()
    });

    // Fill light to reduce harsh shadows
    commands.spawn(DirectionalLightBundle {
        directional_light: DirectionalLight {
            color: Color::rgb(0.7, 0.8, 1.0), // Cool fill light
            illuminance: 20000.0,             // Moderate fill
            shadows_enabled: false,
            ..default()
        },
        transform: Transform::from_xyz(-6.0, 8.0, -6.0).looking_at(Vec3::ZERO, Vec3::Y),
        ..default()
    });

    // Rim light for edge definition
    commands.spawn(DirectionalLightBundle {
        directional_light: DirectionalLight {
            color: Color::rgb(0.9, 0.95, 1.0), // Bright rim light
            illuminance: 15000.0,              // Strong rim lighting
            shadows_enabled: false,
            ..default()
        },
        transform: Transform::from_xyz(0.0, 6.0, -10.0).looking_at(Vec3::ZERO, Vec3::Y),
        ..default()
    });
}

/// Setup coordinate labels around the board edges
fn setup_coordinate_labels(
    commands: &mut Commands,
    meshes: &mut ResMut<Assets<Mesh>>,
    materials: &mut ResMut<Assets<StandardMaterial>>,
    tile_size: f32,
) {
    let label_material = materials.add(StandardMaterial {
        base_color: Color::rgb(0.9, 0.9, 0.95), // Bright white for visibility
        metallic: 0.1,
        perceptual_roughness: 0.8,
        emissive: Color::rgb(0.3, 0.3, 0.35), // Strong glow for readability
        ..default()
    });

    let label_mesh = meshes.add(Mesh::from(shape::Box::new(
        tile_size * 0.3,
        tile_size * 0.1,
        tile_size * 0.3,
    )));

    let board_edge_offset = BOARD_WIDTH.max(BOARD_HEIGHT) as f32 * tile_size * 0.6;

    // Column labels (A-J)
    for x in 0..BOARD_WIDTH {
        let pos = board_to_isometric((x, 0), 0.0);
        commands.spawn((
            PbrBundle {
                mesh: label_mesh.clone(),
                material: label_material.clone(),
                transform: Transform::from_xyz(pos.x, tile_size * 0.2, pos.z - board_edge_offset),
                ..default()
            },
            CoordinateLabel,
        ));
    }

    // Row labels (1-8)
    for y in 0..BOARD_HEIGHT {
        let pos = board_to_isometric((0, y), 0.0);
        commands.spawn((
            PbrBundle {
                mesh: label_mesh.clone(),
                material: label_material.clone(),
                transform: Transform::from_xyz(pos.x - board_edge_offset, tile_size * 0.2, pos.z),
                ..default()
            },
            CoordinateLabel,
        ));
    }
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
    for _valid_move_entity in valid_moves.iter() {
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
