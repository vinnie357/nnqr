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
    mod coordinate_conversion_tests;
    mod movement_tests;
    mod movement_validation_tests;
    mod piece_selection_tests;
    mod power_orb_tests;
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
}
