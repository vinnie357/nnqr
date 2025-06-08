use crate::{components::*, resources::*};
use bevy::prelude::*;
use rand::Rng;

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
    mut last_turn: Local<LastTurnTracker>,
) {
    // Check if we're in a new turn
    let current_turn_id = (game_state.current_player, game_state.turn_phase);

    // Only spawn when transitioning to PowerActivation phase
    if game_state.turn_phase != TurnPhase::PowerActivation {
        return;
    }

    // Check if this is a new turn
    if last_turn.last_player == Some(game_state.current_player) {
        return;
    }

    last_turn.last_player = Some(game_state.current_player);
    last_turn.turn_count += 1;

    println!(
        "Turn {} - checking power orb spawn for {:?}",
        last_turn.turn_count, game_state.current_player
    );

    let mut rng = rand::thread_rng();

    // Random chance to spawn an orb
    if rng.gen::<f32>() > ORB_SPAWN_CHANCE {
        return;
    }

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

    // Spawn orb on random empty tile
    if !empty_tiles.is_empty() {
        let spawn_pos = empty_tiles[rng.gen_range(0..empty_tiles.len())];
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

        println!(
            "Power orb spawned: {} at {:?}",
            power_type.name(),
            spawn_pos
        );
    }
}

pub fn collect_power_orbs(
    mut commands: Commands,
    mut game_state: ResMut<GameState>,
    pieces: Query<&GamePiece>,
    orbs: Query<(Entity, &PowerOrb)>,
) {
    for (orb_entity, orb) in orbs.iter() {
        // Check if any piece is on the same tile as the orb
        for piece in pieces.iter() {
            if piece.board_position == orb.board_position {
                // Add power to the piece's player inventory
                match piece.player {
                    Player::Player1 => {
                        game_state.player1_powers.push(orb.power_type);
                        println!("Player 1 collected: {}", orb.power_type.name());
                    }
                    Player::Player2 => {
                        game_state.player2_powers.push(orb.power_type);
                        println!("Player 2 collected: {}", orb.power_type.name());
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
    let x = (board_pos.0 as f32 - BOARD_SIZE as f32 / 2.0 + 0.5) * TILE_SIZE;
    let y = (board_pos.1 as f32 - BOARD_SIZE as f32 / 2.0 + 0.5) * TILE_SIZE;
    Vec2::new(x, y)
}

// Visual indicator system for orbs (make them pulse)
pub fn animate_power_orbs(time: Res<Time>, mut orbs: Query<(&PowerOrb, &mut Transform)>) {
    for (_orb, mut transform) in orbs.iter_mut() {
        let scale = 1.0 + (time.elapsed_seconds() * 3.0).sin() * 0.1;
        transform.scale = Vec3::splat(scale);
    }
}
