#![allow(unused_variables)]
#![allow(dead_code)]
#![allow(ambiguous_glob_reexports)]
#![allow(clippy::too_many_arguments)]
#![allow(clippy::type_complexity)]

pub mod components;
pub mod events;
pub mod resources;
pub mod systems;

#[cfg(test)]
mod tests {
    mod board_10x8_tests;
    mod board_tests;
    mod chat_tests;
    mod coordinate_conversion_tests;
    mod integration_orb_visibility_tests;
    mod missing_powers_tests;
    mod movement_tests;
    mod movement_validation_tests;
    mod piece_selection_tests;
    mod power_orb_spawning_tests;
    mod power_orb_tests;
    mod power_spawning_fix_tests;
    mod power_storage_tests;
    mod turn_phase_tests;
    mod turn_tests;
    mod win_condition_tests;

    // New UI theme tests
    mod integration_ui_tests;
    mod isometric_camera_tests;
    mod power_orb_visual_tests;
    mod render_config_tests;
    mod ui_theme_tests;

    // Mouse interaction tests
    mod mouse_interaction_tests;

    // UI and interaction fix tests
    mod move_highlighting_3d_tests;
    mod settings_tests;
    mod ui_turn_indicator_tests;

    // 3D positioning tests
    mod piece_positioning_3d_tests;
    
    // Movement overlay tests
    mod movement_overlay_tests;
    
    // Coordinate debug test
    mod coordinate_debug_test;
    
    // Visual alignment test
    mod visual_alignment_test;
    
    // Coordinate consistency test
    mod coordinate_consistency_test;
}
