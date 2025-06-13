use crate::components::Player;
use crate::resources::game_state::{GameState, TurnPhase};
use bevy::prelude::*;

/// Advance turn phase following the proper sequence
pub fn advance_turn_phase(game_state: &mut GameState) {
    match game_state.turn_phase {
        TurnPhase::PowerActivation => {
            game_state.turn_phase = TurnPhase::PieceMovement;
        }
        TurnPhase::PieceMovement => {
            game_state.turn_phase = TurnPhase::PowerSpawning;
        }
        TurnPhase::PowerSpawning => {
            // Complete the turn and switch to next player
            game_state.turn_phase = TurnPhase::PowerActivation;
            game_state.current_player = match game_state.current_player {
                Player::Player1 => Player::Player2,
                Player::Player2 => Player::Player1,
            };
            game_state.selected_power = None;
        }
    }
}

/// Check if a phase transition is valid
pub fn is_valid_phase_transition(from: TurnPhase, to: TurnPhase) -> bool {
    matches!(
        (from, to),
        (TurnPhase::PowerActivation, TurnPhase::PieceMovement)
            | (TurnPhase::PieceMovement, TurnPhase::PowerSpawning)
            | (TurnPhase::PowerSpawning, TurnPhase::PowerActivation)
    )
}

/// Resource to track PowerSpawning phase timing
#[derive(Resource, Default)]
pub struct PowerSpawningTimer {
    pub start_time: Option<f32>,
}

/// System to handle PowerSpawning phase timing and automatic advancement
pub fn handle_power_spawning_phase(
    mut game_state: ResMut<GameState>,
    mut timer: ResMut<PowerSpawningTimer>,
    time: Res<Time>,
    input: Res<Input<KeyCode>>,
) {
    if game_state.turn_phase != TurnPhase::PowerSpawning {
        timer.start_time = None;
        return;
    }

    // Initialize timer if entering PowerSpawning phase
    if timer.start_time.is_none() {
        timer.start_time = Some(time.elapsed_seconds());
        println!(
            "🎯 PowerSpawning phase started for {:?} - Power orbs may spawn on the board!",
            game_state.current_player
        );
    }

    let elapsed = time.elapsed_seconds() - timer.start_time.unwrap();

    // Auto-advance after 2 seconds or if player manually skips
    if elapsed > 2.0 || input.just_pressed(KeyCode::Space) {
        advance_turn_phase(&mut game_state);
        timer.start_time = None;
        println!(
            "PowerSpawning phase completed, switching to {:?}'s turn",
            game_state.current_player
        );
    }
}

/// System to initialize the turn phase correctly at game start
pub fn initialize_turn_phase(mut game_state: ResMut<GameState>) {
    // Ensure game starts with PowerActivation phase
    if game_state.turn_phase == TurnPhase::PieceMovement {
        game_state.turn_phase = TurnPhase::PowerActivation;
        println!(
            "Game initialized: Starting with {:?}'s PowerActivation phase",
            game_state.current_player
        );
    }
}

/// System to provide visual feedback during PowerSpawning phase
pub fn power_spawning_phase_ui(
    game_state: Res<GameState>,
    mut text_query: Query<&mut Text, With<TurnIndicator>>,
) {
    if game_state.turn_phase != TurnPhase::PowerSpawning {
        return;
    }

    for mut text in text_query.iter_mut() {
        // Update UI to show spawning phase with instructions
        if let Some(section) = text.sections.get_mut(0) {
            section.value = format!(
                "{:?}'s Turn - Spawning Phase ⚡ (Power orbs may spawn! Press SPACE to continue)",
                game_state.current_player
            );
        }
    }
}

// Marker component for turn indicator UI
#[derive(Component)]
pub struct TurnIndicator;
