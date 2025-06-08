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

    // Player 1 pieces (bottom two rows)
    for y in 0..2 {
        for x in 0..BOARD_WIDTH {
            if (x + y) % 2 == 0 {
                spawn_piece_3d(
                    &mut commands,
                    &mut materials,
                    piece_mesh.clone(),
                    rim_mesh.clone(),
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

/// Update selection highlighting for 3D pieces
pub fn update_selection_highlighting(
    mut commands: Commands,
    selected_pieces: Query<(Entity, &Children), (With<Selected>, With<GamePiece3D>)>,
    unselected_pieces: Query<(Entity, &Children), (Without<Selected>, With<GamePiece3D>)>,
    mut materials: ResMut<Assets<StandardMaterial>>,
    material_handles: Query<&Handle<StandardMaterial>>,
    highlight_markers: Query<Entity, With<SelectionHighlight>>,
) {
    // Remove old highlight markers
    for entity in highlight_markers.iter() {
        commands.entity(entity).despawn_recursive();
    }

    // Add highlights to selected pieces
    for (piece_entity, children) in selected_pieces.iter() {
        // Find the main piece mesh child
        for &child in children.iter() {
            if let Ok(material_handle) = material_handles.get(child) {
                // Create a bright yellow highlight material
                let highlight_material = materials.add(StandardMaterial {
                    base_color: Color::rgb(1.0, 1.0, 0.0), // Yellow
                    emissive: Color::rgb(0.3, 0.3, 0.0),   // Slight glow
                    metallic: 0.8,
                    perceptual_roughness: 0.2,
                    ..default()
                });

                // Temporarily change the material to highlight
                commands.entity(child).insert(highlight_material);
                commands.entity(child).insert(SelectionHighlight);
                break; // Only highlight the first mesh (main piece body)
            }
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
