use bevy::prelude::*;

/// Configuration for render mode
#[derive(Resource, Debug, Clone, Default)]
pub struct RenderConfig {
    pub use_3d: bool,
}

impl RenderConfig {
    pub fn new_2d() -> Self {
        Self { use_3d: false }
    }

    pub fn new_3d() -> Self {
        Self { use_3d: true }
    }
}
