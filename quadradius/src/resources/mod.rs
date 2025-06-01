pub mod game_state;
pub use game_state::*;

// Re-export from win_condition system
pub use crate::systems::win_condition::GameResult;