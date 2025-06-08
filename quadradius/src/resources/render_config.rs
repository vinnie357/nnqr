use bevy::prelude::*;

/// Configuration for render mode
#[derive(Resource, Debug, Clone)]
pub struct RenderConfig {
    pub use_3d: bool,
}

impl Default for RenderConfig {
    fn default() -> Self {
        Self {
            use_3d: true, // Default to 3D isometric view
        }
    }
}

impl RenderConfig {
    pub fn new_2d() -> Self {
        Self { use_3d: false }
    }
    
    pub fn new_3d() -> Self {
        Self { use_3d: true }
    }
}