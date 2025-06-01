use bevy::prelude::*;
use crate::components::Player;

#[derive(Resource)]
pub struct GameState {
    pub current_player: Player,
    pub selected_piece: Option<Entity>,
}

impl Default for GameState {
    fn default() -> Self {
        Self {
            current_player: Player::Player1,
            selected_piece: None,
        }
    }
}