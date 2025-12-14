use crate::resources::game_state::TurnPhase;
use crate::systems::{isometric_camera::board_to_isometric, pieces_3d::GamePiece3D};
use crate::{components::*, resources::*};
use bevy::prelude::*;

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
    mut spawning_tracker: ResMut<PowerSpawningTracker>,
    mut last_turn: ResMut<crate::systems::power_orbs::LastTurnTracker>,
) {
    // Only spawn orbs during the PowerSpawning phase
    if game_state.turn_phase != TurnPhase::PowerSpawning {
        return;
    }

    // Check if this is a new turn
    if last_turn.last_player == Some(game_state.current_player) {
        return;
    }

    last_turn.last_player = Some(game_state.current_player);
    last_turn.turn_count += 1;

    // Increment round counter for 7-round cycle
    spawning_tracker.increment_round();

    println!(
        "3D Spawning Phase - Turn {} - Round {} since last spawn for {:?}",
        last_turn.turn_count, spawning_tracker.rounds_since_last_spawn, game_state.current_player
    );

    // Check if we should spawn an orb (every 7 rounds)
    if !spawning_tracker.should_spawn_orb() {
        println!(
            "3D: Not time to spawn orb yet (need {} more rounds)",
            7 - spawning_tracker.rounds_since_last_spawn
        );
        return;
    }

    // Calculate territory control from 3D pieces
    let mut player1_positions = Vec::new();
    let mut player2_positions = Vec::new();

    for piece in pieces.iter() {
        match piece.player {
            Player::Player1 => player1_positions.push(piece.board_position),
            Player::Player2 => player2_positions.push(piece.board_position),
        }
    }

    let total_pieces = (player1_positions.len() + player2_positions.len()) as f32;
    let (p1_control, p2_control) = if total_pieces == 0.0 {
        (0.5, 0.5)
    } else {
        (
            player1_positions.len() as f32 / total_pieces,
            player2_positions.len() as f32 / total_pieces,
        )
    };

    spawning_tracker.update_territory_control(p1_control, p2_control);

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

    // Spawn 3D orb on empty tile with territory bias
    if !empty_tiles.is_empty() {
        let territory_bias = (
            spawning_tracker.player1_territory_control,
            spawning_tracker.player2_territory_control,
        );

        // Use turn count as seed for deterministic but varied behavior
        let rng_seed = last_turn.turn_count as u64;

        if let Some(spawn_pos) =
            choose_spawn_location_with_bias(&empty_tiles, territory_bias, rng_seed)
        {
            let power_type = PowerType::random();

            spawn_orb_3d(
                &mut commands,
                &mut meshes,
                &mut materials,
                &tiles,
                power_type,
                spawn_pos,
            );

            // Mark orb as spawned
            spawning_tracker.orb_spawned();

            info!(
                "3D Power orb {} spawned: {} at {:?} (Total: {}, P1 Control: {:.1}%, P2 Control: {:.1}%)",
                spawning_tracker.total_orbs_spawned,
                power_type.name(),
                spawn_pos,
                spawning_tracker.total_orbs_spawned,
                spawning_tracker.player1_territory_control * 100.0,
                spawning_tracker.player2_territory_control * 100.0
            );
        }
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

    // Create larger, more visible orb sphere mesh
    let orb_mesh = meshes.add(Mesh::from(shape::UVSphere {
        radius: TILE_SIZE * 0.35, // Increased from 0.2 for better visibility
        sectors: 24,
        stacks: 16,
    }));

    // Create glow sphere mesh (larger, transparent)
    let glow_mesh = meshes.add(Mesh::from(shape::UVSphere {
        radius: TILE_SIZE * 0.5, // Increased from 0.35 for better visibility
        sectors: 16,
        stacks: 12,
    }));

    // Get power type color
    let power_color = power_type.color();

    // Create much brighter, more visible orb material
    let orb_material = materials.add(StandardMaterial {
        base_color: power_color, // Use power color directly instead of muted metallic
        emissive: power_color * 2.0, // Much brighter emission
        metallic: 0.0,           // Reduce metallic for better visibility
        perceptual_roughness: 0.0, // Very smooth for reflection
        reflectance: 1.0,        // Maximum reflectance
        ..default()
    });

    // Create even more intense glow material
    let glow_material = materials.add(StandardMaterial {
        base_color: Color::rgba(power_color.r(), power_color.g(), power_color.b(), 0.5),
        emissive: power_color * 5.0, // Very intense glow for visibility
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

            // Add bright light source for illumination
            parent.spawn(PointLightBundle {
                point_light: PointLight {
                    color: power_color,
                    intensity: 2000.0,      // Much brighter for visibility
                    range: TILE_SIZE * 4.0, // Larger range
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
    mut pieces: Query<(Entity, &GamePiece3D, &mut PowerInventory)>,
    orbs: Query<(Entity, &PowerOrb3D)>,
    // TODO: Add floating text events later
) {
    for (_piece_entity, piece, mut piece_inventory) in pieces.iter_mut() {
        if piece.player != game_state.current_player {
            continue;
        }

        for (orb_entity, orb) in orbs.iter() {
            if orb.board_position == piece.board_position {
                // Add power to the specific piece's inventory
                piece_inventory.add_power(orb.power_type);

                // Also add to player's inventory for backward compatibility (temporary)
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
