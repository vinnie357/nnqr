use crate::components::{Player, PowerType};
use bevy::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Copy, PartialEq, Debug, Serialize, Deserialize)]
pub enum TurnPhase {
    PowerActivation,
    PieceMovement,
}

#[derive(Resource)]
pub struct GameState {
    pub current_player: Player,
    pub player1_powers: Vec<PowerType>,
    pub player2_powers: Vec<PowerType>,
    pub turn_phase: TurnPhase,
    pub selected_power: Option<usize>, // Index of selected power in player's inventory
}

impl Default for GameState {
    fn default() -> Self {
        Self {
            current_player: Player::Player1,
            player1_powers: Vec::new(),
            player2_powers: Vec::new(),
            turn_phase: TurnPhase::PowerActivation,
            selected_power: None,
        }
    }
}

impl GameState {
    pub fn get_current_player_powers(&self) -> &Vec<PowerType> {
        match self.current_player {
            Player::Player1 => &self.player1_powers,
            Player::Player2 => &self.player2_powers,
        }
    }

    pub fn get_current_player_powers_mut(&mut self) -> &mut Vec<PowerType> {
        match self.current_player {
            Player::Player1 => &mut self.player1_powers,
            Player::Player2 => &mut self.player2_powers,
        }
    }
}
