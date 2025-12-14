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

    // Visual alignment test
    mod visual_alignment_test;

    // Coordinate consistency test
    mod coordinate_consistency_test;

    // 3D movement indicators test
    mod movement_indicators_3d_test;

    // Movement indicator positioning test
    mod movement_indicators_positioning_test;

    // 3D piece type compatibility test
    mod movement_indicators_3d_piece_type_test;

    // Movement indicator shape test
    mod movement_indicators_shape_test;

    // Movement indicators alignment fix verification
    mod movement_indicators_alignment_fix_verification;

    // Power spawning phase tests
    mod power_spawning_phase_tests;

    // Chat default state tests
    mod chat_default_state_test;

    // Chat 2D minimized state test
    mod chat_2d_minimized_test;

    // Piece color preservation test for invalid move flash bug
    mod capture_validation_test;
    mod movement_phase_validation_test;
    mod piece_color_preservation_test;
    mod piece_selection_cleanup_test;
    mod player2_auto_skip_bug_test;
    mod player2_turn_ending_test;
    mod power_spawning_timer_bug_test;
    mod turn_phase_blocking_fix_test;
}
