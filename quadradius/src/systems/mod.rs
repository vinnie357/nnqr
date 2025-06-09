pub mod automated_power_tests;
pub mod board;
pub mod board_3d;
pub mod crash_debug;
pub mod debug_powers;
pub mod depth_sorting;
pub mod drag_drop;
pub mod drag_drop_3d;
pub mod enhanced_board_visuals;
pub mod enhanced_movement;
pub mod enhanced_ui;
pub mod feedback_animations;
pub mod game_balance;
pub mod game_menu;
pub mod isometric_camera;
pub mod movement_powers;
pub mod performance;
pub mod piece_alignment;
pub mod piece_debug;
pub mod piece_visibility_fix;
pub mod pieces;
pub mod pieces_3d;
pub mod power_activation_ui;
pub mod power_balance;
pub mod power_effects;
pub mod power_orbs;
pub mod power_orbs_3d;
pub mod power_test_report;
pub mod power_testing;
pub mod scoreboard;
pub mod terrain_height;
pub mod ui;
pub mod visual_effects;
pub mod win_condition;
// pub mod networking;
// pub mod client_server;
// pub mod game_lobby;

pub use board::*;
pub use board_3d::*;
// pub use debug_powers::*; // Disabled for production builds
pub use drag_drop::*;
pub use drag_drop_3d::*;
// pub use enhanced_board_visuals::*; // Temporarily disabled due to HeightIndicator conflict
pub use automated_power_tests::*;
// pub use crash_debug::*; // Disabled for production builds
pub use depth_sorting::*;
pub use enhanced_movement::*;
pub use enhanced_ui::{
    animate_ui_elements, setup_enhanced_ui, show_power_tooltips, update_power_inventory_ui,
    update_turn_indicator_enhanced,
};
pub use feedback_animations::*;
pub use game_balance::*;
pub use game_menu::*;
pub use isometric_camera::*;
pub use movement_powers::*;
pub use performance::*;
pub use piece_alignment::*;
pub use piece_debug::*;
pub use piece_visibility_fix::*;
pub use pieces::*;
pub use pieces_3d::*;
pub use power_activation_ui::*;
pub use power_balance::*;
pub use power_effects::*;
pub use power_orbs::*;
pub use power_orbs_3d::*;
// pub use power_test_report::*; // Disabled for production builds
pub use power_testing::*;
pub use scoreboard::*;
pub use terrain_height::*;
pub use ui::*;
pub use visual_effects::*;
pub use win_condition::*;
// pub use networking::*;
// pub use client_server::*;
// pub use game_lobby::*;
