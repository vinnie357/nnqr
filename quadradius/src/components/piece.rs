use crate::components::PowerType;
use bevy::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Component, Clone, Copy, PartialEq, Eq, Hash, Debug, Serialize, Deserialize)]
pub enum Player {
    Player1,
    Player2,
}

#[derive(Component, Clone, Copy)]
pub struct GamePiece {
    pub player: Player,
    pub board_position: (u8, u8),
}

#[derive(Component)]
pub struct Dragging {
    pub offset: Vec2,
    pub original_position: (u8, u8), // Store the original board position
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

/// Component for per-piece power inventory
#[derive(Component, Clone, Debug, PartialEq, Serialize, Deserialize, Default)]
pub struct PowerInventory {
    pub powers: Vec<PowerType>,
}

impl PowerInventory {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn add_power(&mut self, power: PowerType) {
        self.powers.push(power);
    }

    pub fn remove_power(&mut self, index: usize) -> Option<PowerType> {
        if index < self.powers.len() {
            Some(self.powers.remove(index))
        } else {
            None
        }
    }

    pub fn has_power(&self, power: &PowerType) -> bool {
        self.powers.contains(power)
    }

    pub fn power_count(&self) -> usize {
        self.powers.len()
    }

    pub fn is_empty(&self) -> bool {
        self.powers.is_empty()
    }

    pub fn get_powers(&self) -> &Vec<PowerType> {
        &self.powers
    }

    pub fn clear(&mut self) {
        self.powers.clear();
    }
}
