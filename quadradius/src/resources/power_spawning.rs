use crate::components::*;
use bevy::prelude::*;

/// Resource to track power spawning according to research specifications
#[derive(Resource, Default)]
pub struct PowerSpawningTracker {
    pub rounds_since_last_spawn: u32,
    pub total_orbs_spawned: u32,
    pub player1_territory_control: f32, // 0.0 to 1.0
    pub player2_territory_control: f32, // 0.0 to 1.0
}

impl PowerSpawningTracker {
    pub fn new() -> Self {
        Self {
            rounds_since_last_spawn: 0,
            total_orbs_spawned: 0,
            player1_territory_control: 0.5, // Start with equal control
            player2_territory_control: 0.5,
        }
    }

    pub fn should_spawn_orb(&self) -> bool {
        self.rounds_since_last_spawn >= 7
    }

    pub fn increment_round(&mut self) {
        self.rounds_since_last_spawn += 1;
    }

    pub fn orb_spawned(&mut self) {
        self.rounds_since_last_spawn = 0;
        self.total_orbs_spawned += 1;
    }

    pub fn calculate_spawn_bias_for_player(&self, player: Player) -> f32 {
        match player {
            Player::Player1 => self.player1_territory_control,
            Player::Player2 => self.player2_territory_control,
        }
    }

    pub fn update_territory_control(&mut self, player1_control: f32, player2_control: f32) {
        // Normalize to ensure they add up to 1.0
        let total = player1_control + player2_control;
        if total > 0.0 {
            self.player1_territory_control = player1_control / total;
            self.player2_territory_control = player2_control / total;
        } else {
            // Equal control if no pieces
            self.player1_territory_control = 0.5;
            self.player2_territory_control = 0.5;
        }
    }
}

/// Calculate territory control based on piece positions
pub fn calculate_territory_control(pieces: &Query<&GamePiece>) -> (f32, f32) {
    let mut player1_positions = Vec::new();
    let mut player2_positions = Vec::new();

    for piece in pieces.iter() {
        match piece.player {
            Player::Player1 => player1_positions.push(piece.board_position),
            Player::Player2 => player2_positions.push(piece.board_position),
        }
    }

    if player1_positions.is_empty() && player2_positions.is_empty() {
        return (0.5, 0.5);
    }

    // Simple territory calculation: count pieces and their spread
    let p1_count = player1_positions.len() as f32;
    let p2_count = player2_positions.len() as f32;

    // Weight by piece count (more pieces = more control)
    let total_pieces = p1_count + p2_count;
    if total_pieces == 0.0 {
        (0.5, 0.5)
    } else {
        (p1_count / total_pieces, p2_count / total_pieces)
    }
}

/// Choose spawn location based on territory control
pub fn choose_spawn_location_with_bias(
    empty_positions: &[(u8, u8)],
    territory_bias: (f32, f32), // (player1_bias, player2_bias)
    rng_seed: u64,
) -> Option<(u8, u8)> {
    if empty_positions.is_empty() {
        return None;
    }

    // Divide board into player zones for bias calculation
    let board_height = BOARD_HEIGHT;
    let mid_point = board_height / 2;

    let mut player1_zone_positions = Vec::new();
    let mut player2_zone_positions = Vec::new();
    let mut neutral_positions = Vec::new();

    for &pos in empty_positions {
        if pos.1 < mid_point - 1 {
            player1_zone_positions.push(pos);
        } else if pos.1 > mid_point {
            player2_zone_positions.push(pos);
        } else {
            neutral_positions.push(pos);
        }
    }

    // Bias implementation with neutral zone consideration
    // Normalize biases to leave room for neutral spawning
    let total_bias = territory_bias.0 + territory_bias.1;
    let neutral_weight = 0.2; // 20% chance for neutral zone
    let adjusted_p1_bias = territory_bias.0 * (1.0 - neutral_weight) / total_bias;
    let adjusted_p2_bias = territory_bias.1 * (1.0 - neutral_weight) / total_bias;

    let random_value = (rng_seed % 100) as f32 / 100.0;

    if random_value < adjusted_p1_bias && !player1_zone_positions.is_empty() {
        // Favor player 1 zone
        let index = (rng_seed % player1_zone_positions.len() as u64) as usize;
        Some(player1_zone_positions[index])
    } else if random_value < adjusted_p1_bias + adjusted_p2_bias
        && !player2_zone_positions.is_empty()
    {
        // Favor player 2 zone
        let index = (rng_seed % player2_zone_positions.len() as u64) as usize;
        Some(player2_zone_positions[index])
    } else if !neutral_positions.is_empty() {
        // Neutral zone (remaining probability)
        let index = (rng_seed % neutral_positions.len() as u64) as usize;
        Some(neutral_positions[index])
    } else {
        // Fallback to any position if neutral zone is empty
        let index = (rng_seed % empty_positions.len() as u64) as usize;
        Some(empty_positions[index])
    }
}
