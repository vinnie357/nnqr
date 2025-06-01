pub mod components;
pub mod events;
pub mod resources;
pub mod systems;

#[cfg(test)]
mod tests {
    mod board_tests;
    mod movement_tests;
    mod turn_tests;
    mod win_condition_tests;
}