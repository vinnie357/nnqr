use bevy::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Component, Clone, Copy, PartialEq, Eq, Hash, Debug, Serialize, Deserialize)]
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
pub struct Dragging {
    pub offset: Vec2,
}

#[derive(Component)]
pub struct InvalidMoveAnimation {
    pub start_time: f32,
    pub duration: f32,
    pub original_pos: Vec3,
}

#[derive(Component)]
pub struct InvalidMoveFlash {
    pub start_time: f32,
    pub duration: f32,
}

#[derive(Component)]
pub struct Selected;

#[derive(Component)]
pub struct SelectionHighlight;
