use crate::components::*;
use crate::resources::QuadradiusTheme;
use crate::systems::{
    board_3d::BoardTile3D,
    depth_sorting::{IsometricDepthSort, PIECE_LAYER},
    isometric_camera::board_to_isometric,
};
use bevy::prelude::*;

/// 3D piece component
#[derive(Component)]
pub struct GamePiece3D {
    pub player: Player,
    pub board_position: (u8, u8),
}

/// Component for piece selection outline
#[derive(Component)]
pub struct PieceOutline {
    pub active: bool,
    pub pulse_timer: f32,
}

/// Component to mark outline mesh entities
#[derive(Component)]
pub struct OutlineMesh;

/// Setup 3D pieces with metallic appearance
pub fn setup_pieces_3d(
    mut commands: Commands,
    mut meshes: ResMut<Assets<Mesh>>,
    mut materials: ResMut<Assets<StandardMaterial>>,
) {
    // Create piece mesh - cylindrical shape like checkers
    let piece_mesh = meshes.add(Mesh::from(shape::Cylinder {
        radius: TILE_SIZE * 0.35,
        height: TILE_SIZE * 0.15,
        resolution: 32,
        segments: 1,
    }));

    // Create crown/rim mesh for piece top
    let rim_mesh = meshes.add(Mesh::from(shape::Torus {
        radius: TILE_SIZE * 0.32,
        ring_radius: TILE_SIZE * 0.03,
        subdivisions_segments: 24,
        subdivisions_sides: 12,
    }));

    // Create outline meshes (slightly larger for outline effect)
    let outline_piece_mesh = meshes.add(Mesh::from(shape::Cylinder {
        radius: TILE_SIZE * 0.38,
        height: TILE_SIZE * 0.16,
        resolution: 32,
        segments: 1,
    }));

    let outline_rim_mesh = meshes.add(Mesh::from(shape::Torus {
        radius: TILE_SIZE * 0.35,
        ring_radius: TILE_SIZE * 0.035,
        subdivisions_segments: 24,
        subdivisions_sides: 12,
    }));

    // Player 1 pieces (bottom two rows)
    for y in 0..2 {
        for x in 0..BOARD_WIDTH {
            if (x + y) % 2 == 0 {
                spawn_piece_3d(
                    &mut commands,
                    &mut materials,
                    piece_mesh.clone(),
                    rim_mesh.clone(),
                    outline_piece_mesh.clone(),
                    outline_rim_mesh.clone(),
                    Player::Player1,
                    (x, y),
                );
            }
        }
    }

    // Player 2 pieces (top two rows)
    for y in (BOARD_HEIGHT - 2)..BOARD_HEIGHT {
        for x in 0..BOARD_WIDTH {
            if (x + y) % 2 == 0 {
                spawn_piece_3d(
                    &mut commands,
                    &mut materials,
                    piece_mesh.clone(),
                    rim_mesh.clone(),
                    outline_piece_mesh.clone(),
                    outline_rim_mesh.clone(),
                    Player::Player2,
                    (x, y),
                );
            }
        }
    }
}

fn spawn_piece_3d(
    commands: &mut Commands,
    materials: &mut ResMut<Assets<StandardMaterial>>,
    piece_mesh: Handle<Mesh>,
    rim_mesh: Handle<Mesh>,
    outline_piece_mesh: Handle<Mesh>,
    outline_rim_mesh: Handle<Mesh>,
    player: Player,
    position: (u8, u8),
) {
    let (base_color, accent_color) = match player {
        Player::Player1 => (
            QuadradiusTheme::TEAM_1_PRIMARY,
            QuadradiusTheme::TEAM_1_ACCENT,
        ),
        Player::Player2 => (
            QuadradiusTheme::TEAM_2_PRIMARY,
            QuadradiusTheme::TEAM_2_ACCENT,
        ),
    };

    // Get board height at position (will be 0 initially)
    let height = 0.0; // TODO: Query actual tile height
    let world_pos = board_to_isometric(position, height);
    let piece_y = world_pos.y + TILE_SIZE * 0.35;

    // Create metallic material for the piece
    let piece_material = materials.add(StandardMaterial {
        base_color,
        metallic: QuadradiusTheme::METALLIC_VALUE,
        perceptual_roughness: QuadradiusTheme::ROUGHNESS_VALUE,
        reflectance: QuadradiusTheme::REFLECTANCE_VALUE,
        ..default()
    });

    // Create accent material for the rim
    let rim_material = materials.add(StandardMaterial {
        base_color: accent_color,
        metallic: 0.9,
        perceptual_roughness: 0.2,
        emissive: accent_color * 0.1, // Slight glow
        ..default()
    });

    // Create outline materials (bright, emissive for visibility)
    let outline_material = materials.add(StandardMaterial {
        base_color: Color::rgb(1.0, 1.0, 0.0),     // Bright yellow
        emissive: Color::rgb(1.0, 1.0, 0.0) * 0.3, // Glowing effect
        metallic: 0.0,
        perceptual_roughness: 1.0,
        alpha_mode: AlphaMode::Blend,
        ..default()
    });

    // Spawn piece entity with children
    commands
        .spawn((
            GamePiece3D {
                player,
                board_position: position,
            },
            GamePiece {
                player,
                board_position: position,
            },
            Transform::from_xyz(world_pos.x, piece_y, world_pos.z),
            GlobalTransform::default(),
            Visibility::Visible,
            InheritedVisibility::default(),
            ViewVisibility::default(),
            IsometricDepthSort {
                grid_x: position.0 as f32,
                grid_y: position.1 as f32,
                height,
                layer_offset: PIECE_LAYER,
            },
            PieceOutline {
                active: false,
                pulse_timer: 0.0,
            },
        ))
        .with_children(|parent| {
            // Main piece body
            parent.spawn(PbrBundle {
                mesh: piece_mesh,
                material: piece_material,
                transform: Transform::default(),
                visibility: Visibility::Visible,
                ..default()
            });

            // Decorative rim on top
            parent.spawn(PbrBundle {
                mesh: rim_mesh,
                material: rim_material,
                transform: Transform::from_xyz(0.0, TILE_SIZE * 0.075, 0.0),
                visibility: Visibility::Visible,
                ..default()
            });

            // Outline meshes (initially hidden)
            parent.spawn((
                PbrBundle {
                    mesh: outline_piece_mesh,
                    material: outline_material.clone(),
                    transform: Transform::from_xyz(0.0, -TILE_SIZE * 0.005, 0.0), // Slightly below main piece
                    visibility: Visibility::Hidden,
                    ..default()
                },
                OutlineMesh,
            ));

            parent.spawn((
                PbrBundle {
                    mesh: outline_rim_mesh,
                    material: outline_material,
                    transform: Transform::from_xyz(0.0, TILE_SIZE * 0.07, 0.0), // Slightly below rim
                    visibility: Visibility::Hidden,
                    ..default()
                },
                OutlineMesh,
            ));
        });
}

/// Update piece positions smoothly
pub fn update_piece_positions_3d(
    mut pieces: Query<(&GamePiece3D, &mut Transform), Without<BoardTile3D>>,
    tiles: Query<&BoardTile3D>,
    time: Res<Time>,
) {
    for (piece, mut transform) in pieces.iter_mut() {
        // Find the tile at piece position to get its height
        let tile_height = tiles
            .iter()
            .find(|tile| tile.coordinates == piece.board_position)
            .map(|tile| tile.height)
            .unwrap_or(0) as f32;

        let target_pos = board_to_isometric(piece.board_position, tile_height);
        let target_y = target_pos.y + TILE_SIZE * 0.35;

        // Smooth movement
        let current = transform.translation;
        let target = Vec3::new(target_pos.x, target_y, target_pos.z);
        transform.translation = current.lerp(target, 8.0 * time.delta_seconds());
    }
}

/// System to toggle piece outlines based on selection
pub fn update_piece_outlines(
    mut piece_query: Query<(Entity, &mut PieceOutline), With<GamePiece3D>>,
    mut outline_query: Query<&mut Visibility, With<OutlineMesh>>,
    children_query: Query<&Children>,
    time: Res<Time>,
) {
    for (piece_entity, mut outline) in piece_query.iter_mut() {
        // Update pulse timer
        outline.pulse_timer += time.delta_seconds() * 4.0;

        // Find outline mesh children and toggle visibility
        if let Ok(children) = children_query.get(piece_entity) {
            for &child in children.iter() {
                if let Ok(mut visibility) = outline_query.get_mut(child) {
                    if outline.active {
                        *visibility = Visibility::Visible;
                    } else {
                        *visibility = Visibility::Hidden;
                    }
                }
            }
        }
    }
}

/// System to handle piece outline pulsing animation
pub fn animate_piece_outlines(
    mut outline_query: Query<(&mut Transform, &Handle<StandardMaterial>), With<OutlineMesh>>,
    piece_query: Query<&PieceOutline, With<GamePiece3D>>,
    children_query: Query<&Children>,
    time: Res<Time>,
    mut materials: ResMut<Assets<StandardMaterial>>,
) {
    // Create a combined pulse effect for all active outlines
    let global_pulse_scale = 1.0 + 0.1 * (time.elapsed_seconds() * 4.0).sin();
    let global_alpha = 0.7 + 0.3 * (time.elapsed_seconds() * 8.0).sin();

    // Check if any pieces have active outlines
    let has_active_outlines = piece_query.iter().any(|outline| outline.active);

    if has_active_outlines {
        for (mut transform, material_handle) in outline_query.iter_mut() {
            // Apply pulsing scale effect
            transform.scale = Vec3::splat(global_pulse_scale);

            // Update material for pulsing glow effect
            if let Some(material) = materials.get_mut(material_handle) {
                let intensity = global_alpha;
                material.emissive = Color::rgb(1.0 * intensity, 1.0 * intensity, 0.0 * intensity);
            }
        }
    }
}

/// Public function to enable outline for a specific piece
pub fn enable_piece_outline(
    commands: &mut Commands,
    piece_entity: Entity,
    mut outline_query: Query<&mut PieceOutline>,
) {
    if let Ok(mut outline) = outline_query.get_mut(piece_entity) {
        outline.active = true;
        outline.pulse_timer = 0.0;
    }
}

/// Public function to disable outline for a specific piece
pub fn disable_piece_outline(
    commands: &mut Commands,
    piece_entity: Entity,
    mut outline_query: Query<&mut PieceOutline>,
) {
    if let Ok(mut outline) = outline_query.get_mut(piece_entity) {
        outline.active = false;
    }
}

/// Public function to disable all piece outlines
pub fn disable_all_piece_outlines(mut outline_query: Query<&mut PieceOutline>) {
    for mut outline in outline_query.iter_mut() {
        outline.active = false;
    }
}

/// Update selection highlighting for 3D pieces using the new outline system
pub fn update_selection_highlighting(
    selected_pieces: Query<Entity, (With<Selected>, With<GamePiece3D>)>,
    unselected_pieces: Query<Entity, (Without<Selected>, With<GamePiece3D>)>,
    mut outline_query: Query<&mut PieceOutline>,
) {
    // Enable outlines for selected pieces
    for piece_entity in selected_pieces.iter() {
        if let Ok(mut outline) = outline_query.get_mut(piece_entity) {
            outline.active = true;
            outline.pulse_timer = 0.0;
        }
    }

    // Disable outlines for unselected pieces
    for piece_entity in unselected_pieces.iter() {
        if let Ok(mut outline) = outline_query.get_mut(piece_entity) {
            outline.active = false;
        }
    }
}

/// Add visual effects to pieces (glow, shadows, etc.)
pub fn enhance_piece_visuals_3d(
    _pieces: Query<(Entity, &GamePiece3D, &Children)>,
    _commands: Commands,
    _materials: ResMut<Assets<StandardMaterial>>,
    _material_handles: Query<&Handle<StandardMaterial>>,
) {
    // This could be expanded to add:
    // - Power indicators as floating icons above pieces
    // - Glowing effects for pieces with powers
    // - Shadow projections
    // - Selection highlights
}
