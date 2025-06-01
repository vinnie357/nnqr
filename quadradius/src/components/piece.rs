use bevy::prelude::*;

#[derive(Component, Clone, Copy, PartialEq, Debug)]
pub enum Player {
    Player1,
    Player2,
}

#[derive(Component)]
pub struct GamePiece {
    pub player: Player,
    pub board_position: (u8, u8),
}

#[derive(Component)]
pub struct Selected;