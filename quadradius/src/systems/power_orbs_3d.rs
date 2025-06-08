use crate::systems::{isometric_camera::board_to_isometric, pieces_3d::GamePiece3D};
use crate::{components::*, resources::*};
use bevy::prelude::*;
use rand::Rng;

/// Component for 3D power orbs with glow effects
#[derive(Component)]
pub struct PowerOrb3D {
    pub power_type: PowerType,
    pub board_position: (u8, u8),
    pub glow_intensity: f32,
    pub pulse_timer: f32,
}

/// Setup 3D power orbs with glow effects
pub fn spawn_power_orbs_3d(
    mut commands: Commands,
    mut meshes: ResMut<Assets<Mesh>>,
    mut materials: ResMut<Assets<StandardMaterial>>,
    tiles: Query<&BoardTile>,
    pieces: Query<&GamePiece3D>,
    orbs: Query<&PowerOrb3D>,
    game_state: Res<GameState>,
    mut last_turn: Local<crate::systems::power_orbs::LastTurnTracker>,
) {
    // Use same logic as 2D version but spawn 3D orbs
    if game_state.turn_phase != TurnPhase::PowerActivation {
        return;
    }

    if last_turn.last_player == Some(game_state.current_player) {
        return;
    }

    last_turn.last_player = Some(game_state.current_player);
    last_turn.turn_count += 1;

    let mut rng = rand::thread_rng();

    // 50% chance to spawn orb
    if rng.gen::<f32>() > 0.5 {
        return;
    }

    // Find empty tiles
    let mut empty_tiles = Vec::new();
    for x in 0..BOARD_WIDTH {
        for y in 0..BOARD_HEIGHT {
            let pos = (x, y);

            // Check if tile has a piece
            let has_piece = pieces.iter().any(|p| p.board_position == pos);

            // Check if tile already has an orb
            let has_orb = orbs.iter().any(|o| o.board_position == pos);

            if !has_piece && !has_orb {
                empty_tiles.push(pos);
            }
        }
    }

    // Spawn 3D orb on random empty tile
    if !empty_tiles.is_empty() {
        let spawn_pos = empty_tiles[rng.gen_range(0..empty_tiles.len())];
        let power_type = PowerType::random();

        spawn_orb_3d(
            &mut commands,
            &mut meshes,
            &mut materials,
            &tiles,
            power_type,
            spawn_pos,
        );

        info!(
            "3D Power orb spawned: {} at {:?}",
            power_type.name(),
            spawn_pos
        );
    }
}

/// Spawn a single 3D power orb with glow effects
fn spawn_orb_3d(
    commands: &mut Commands,
    meshes: &mut ResMut<Assets<Mesh>>,
    materials: &mut ResMut<Assets<StandardMaterial>>,
    tiles: &Query<&BoardTile>,
    power_type: PowerType,
    position: (u8, u8),
) {
    // Get tile height
    let height = tiles
        .iter()
        .find(|tile| tile.coordinates == position)
        .map(|tile| tile.height)
        .unwrap_or(0) as f32;

    let world_pos = board_to_isometric(position, height);
    let orb_y = world_pos.y + TILE_SIZE * 0.6; // Float above tile

    // Create orb sphere mesh
    let orb_mesh = meshes.add(Mesh::from(shape::UVSphere {
        radius: TILE_SIZE * 0.2,
        sectors: 24,
        stacks: 16,
    }));

    // Create glow sphere mesh (larger, transparent)
    let glow_mesh = meshes.add(Mesh::from(shape::UVSphere {
        radius: TILE_SIZE * 0.35,
        sectors: 16,
        stacks: 12,
    }));

    // Get power type color
    let power_color = power_type.color();

    // Create metallic orb material
    let orb_material = materials.add(StandardMaterial {
        base_color: QuadradiusTheme::ORB_BASE,
        emissive: power_color * 0.5, // Moderate glow
        metallic: QuadradiusTheme::METALLIC_VALUE,
        perceptual_roughness: 0.1, // Very smooth
        reflectance: 0.8,
        ..default()
    });

    // Create intense glow material
    let glow_material = materials.add(StandardMaterial {
        base_color: Color::rgba(power_color.r(), power_color.g(), power_color.b(), 0.3),
        emissive: power_color * 2.0, // Intense glow
        alpha_mode: AlphaMode::Blend,
        unlit: true, // Unlit for pure emission
        ..default()
    });

    // Spawn main orb entity with children
    commands
        .spawn((
            PowerOrb3D {
                power_type,
                board_position: position,
                glow_intensity: 1.0,
                pulse_timer: 0.0,
            },
            // Also add 2D PowerOrb for compatibility
            PowerOrb {
                power_type,
                board_position: position,
            },
            Transform::from_xyz(world_pos.x, orb_y, world_pos.z),
            GlobalTransform::default(),
            Visibility::default(),
            ViewVisibility::default(),
        ))
        .with_children(|parent| {
            // Inner metallic orb
            parent.spawn(PbrBundle {
                mesh: orb_mesh,
                material: orb_material,
                transform: Transform::default(),
                ..default()
            });

            // Outer glow effect
            parent.spawn(PbrBundle {
                mesh: glow_mesh,
                material: glow_material,
                transform: Transform::default(),
                ..default()
            });

            // Add floating light source for illumination
            parent.spawn(PointLightBundle {
                point_light: PointLight {
                    color: power_color,
                    intensity: 200.0,
                    range: TILE_SIZE * 2.0,
                    shadows_enabled: false,
                    ..default()
                },
                transform: Transform::from_xyz(0.0, TILE_SIZE * 0.1, 0.0),
                ..default()
            });
        });
}

/// Animate 3D power orbs with pulsing glow
pub fn animate_power_orbs_3d(
    time: Res<Time>,
    mut orbs: Query<(&mut PowerOrb3D, &mut Transform, &Children)>,
    mut materials: ResMut<Assets<StandardMaterial>>,
    children_query: Query<&Handle<StandardMaterial>>,
    mut lights: Query<&mut PointLight>,
) {
    for (mut orb, mut transform, children) in orbs.iter_mut() {
        orb.pulse_timer += time.delta_seconds() * 2.0;

        // Pulsing glow effect
        let pulse = (orb.pulse_timer.sin() * 0.5 + 0.5).clamp(0.3, 1.0);
        orb.glow_intensity = pulse;

        // Gentle floating animation
        let float_offset = (orb.pulse_timer * 0.5).sin() * TILE_SIZE * 0.05;
        transform.translation.y += float_offset * time.delta_seconds();

        // Gentle rotation
        transform.rotation *= Quat::from_rotation_y(time.delta_seconds() * 0.5);

        // Update glow materials and lights
        for &child in children.iter() {
            if let Ok(material_handle) = children_query.get(child) {
                if let Some(material) = materials.get_mut(material_handle) {
                    let power_color = orb.power_type.color();
                    material.emissive = power_color * pulse * 1.5;
                }
            }

            if let Ok(mut light) = lights.get_mut(child) {
                light.intensity = 200.0 * pulse;
            }
        }
    }
}

/// Handle collection of 3D power orbs
pub fn collect_power_orbs_3d(
    mut commands: Commands,
    mut game_state: ResMut<GameState>,
    pieces: Query<&GamePiece3D>,
    orbs: Query<(Entity, &PowerOrb3D)>,
    // TODO: Add floating text events later
) {
    for piece in pieces.iter() {
        if piece.player != game_state.current_player {
            continue;
        }

        for (orb_entity, orb) in orbs.iter() {
            if orb.board_position == piece.board_position {
                // Add power to player's inventory
                match game_state.current_player {
                    Player::Player1 => game_state.player1_powers.push(orb.power_type),
                    Player::Player2 => game_state.player2_powers.push(orb.power_type),
                }

                // TODO: Spawn floating text when event system is available

                // Remove orb
                commands.entity(orb_entity).despawn_recursive();

                info!(
                    "Player {:?} collected power: {}",
                    game_state.current_player,
                    orb.power_type.name()
                );
            }
        }
    }
}
