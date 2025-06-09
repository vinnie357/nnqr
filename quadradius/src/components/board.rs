use bevy::prelude::*;

#[derive(Component)]
pub struct BoardTile {
    pub coordinates: (u8, u8),
    pub height: i8,
}

#[derive(Component)]
pub struct Board;

pub const BOARD_WIDTH: u8 = 10;
pub const BOARD_HEIGHT: u8 = 8;
pub const BOARD_SIZE: u8 = 8; // Deprecated - use BOARD_WIDTH/HEIGHT for 10x8 board
pub const TILE_SIZE: f32 = 64.0;
