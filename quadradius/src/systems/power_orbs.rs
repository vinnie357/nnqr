use crate::components::board::{BOARD_HEIGHT, BOARD_WIDTH};
use crate::resources::game_state::TurnPhase;
use crate::{components::*, resources::*};
use bevy::prelude::*;

const ORB_SPAWN_CHANCE: f32 = 0.5; // 50% chance per turn (increased for better gameplay)
const ORB_SIZE: f32 = TILE_SIZE * 0.4;

// Resource to track last turn for orb spawning
#[derive(Resource, Default)]
pub struct LastTurnTracker {
    pub last_player: Option<Player>,
    pub turn_count: u32,
}

pub fn spawn_power_orbs(
    mut commands: Commands,
    tiles: Query<&BoardTile>,
    pieces: Query<&GamePiece>,
    orbs: Query<&PowerOrb>,
    game_state: Res<GameState>,
    mut spawning_tracker: ResMut<PowerSpawningTracker>,
    mut last_turn: ResMut<LastTurnTracker>,
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
        "Spawning Phase - Turn {} - Round {} since last spawn for {:?}",
        last_turn.turn_count, spawning_tracker.rounds_since_last_spawn, game_state.current_player
    );

    // Check if we should spawn an orb (every 7 rounds)
    if !spawning_tracker.should_spawn_orb() {
        println!(
            "Not time to spawn orb yet (need {} more rounds)",
            7 - spawning_tracker.rounds_since_last_spawn
        );
        return;
    }

    // Calculate territory control
    let (p1_control, p2_control) = calculate_territory_control(&pieces);
    spawning_tracker.update_territory_control(p1_control, p2_control);

    // Find all empty tiles
    let mut empty_tiles = Vec::new();

    for tile in tiles.iter() {
        let pos = tile.coordinates;

        // Check if tile is occupied by a piece
        let has_piece = pieces.iter().any(|p| p.board_position == pos);

        // Check if tile already has an orb
        let has_orb = orbs.iter().any(|o| o.board_position == pos);

        if !has_piece && !has_orb {
            empty_tiles.push(pos);
        }
    }

    // Spawn orb on empty tile with territory bias
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
            let world_pos = board_to_world_position(spawn_pos);

            commands.spawn((
                PowerOrb {
                    power_type,
                    board_position: spawn_pos,
                },
                SpriteBundle {
                    sprite: Sprite {
                        color: QuadradiusTheme::ORB_BASE,
                        custom_size: Some(Vec2::splat(ORB_SIZE)),
                        ..default()
                    },
                    transform: Transform::from_xyz(world_pos.x, world_pos.y, 0.5),
                    ..default()
                },
            ));

            // Mark orb as spawned
            spawning_tracker.orb_spawned();

            println!(
                "Power orb {} spawned: {} at {:?} (Total: {}, P1 Control: {:.1}%, P2 Control: {:.1}%)",
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

pub fn collect_power_orbs(
    mut commands: Commands,
    mut game_state: ResMut<GameState>,
    mut pieces: Query<(Entity, &GamePiece, &mut PowerInventory)>,
    orbs: Query<(Entity, &PowerOrb)>,
) {
    for (orb_entity, orb) in orbs.iter() {
        // Check if any piece is on the same tile as the orb
        for (piece_entity, piece, mut piece_inventory) in pieces.iter_mut() {
            if piece.board_position == orb.board_position {
                // Add power to the specific piece's inventory
                piece_inventory.add_power(orb.power_type);
                println!(
                    "{:?} piece at ({}, {}) collected: {}",
                    piece.player,
                    piece.board_position.0,
                    piece.board_position.1,
                    orb.power_type.name()
                );

                // Also add to player inventory for backward compatibility (temporary)
                match piece.player {
                    Player::Player1 => {
                        game_state.player1_powers.push(orb.power_type);
                    }
                    Player::Player2 => {
                        game_state.player2_powers.push(orb.power_type);
                    }
                }

                // Remove the orb
                if let Some(mut entity_commands) = commands.get_entity(orb_entity) {
                    entity_commands.despawn();
                }
            }
        }
    }
}

fn board_to_world_position(board_pos: (u8, u8)) -> Vec2 {
    // Use enhanced tile size to match 2D board layout
    let enhanced_tile_size = TILE_SIZE * 1.2; // Match board.rs enhanced tile size
    let x = (board_pos.0 as f32 - BOARD_WIDTH as f32 / 2.0 + 0.5) * enhanced_tile_size;
    let y = (board_pos.1 as f32 - BOARD_HEIGHT as f32 / 2.0 + 0.5) * enhanced_tile_size;
    Vec2::new(x, y)
}

// Visual indicator system for orbs (make them pulse)
pub fn animate_power_orbs(time: Res<Time>, mut orbs: Query<(&PowerOrb, &mut Transform)>) {
    for (_orb, mut transform) in orbs.iter_mut() {
        let scale = 1.0 + (time.elapsed_seconds() * 3.0).sin() * 0.1;
        transform.scale = Vec3::splat(scale);
    }
}
