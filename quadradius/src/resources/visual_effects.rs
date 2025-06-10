use bevy::prelude::*;

/// Resource for managing screen shake effects
#[derive(Resource)]
pub struct ScreenShake {
    pub intensity: f32,
    pub duration: f32,
    pub remaining: f32,
}

impl Default for ScreenShake {
    fn default() -> Self {
        Self {
            intensity: 0.0,
            duration: 0.0,
            remaining: 0.0,
        }
    }
}
