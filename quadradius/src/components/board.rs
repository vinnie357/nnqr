use bevy::prelude::*;

#[derive(Component)]
pub struct BoardTile {
    pub coordinates: (u8, u8),
    pub height: i8,
}

#[derive(Component)]
pub struct Board;

pub const BOARD_SIZE: u8 = 8;
pub const TILE_SIZE: f32 = 64.0;