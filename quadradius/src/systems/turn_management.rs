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
            game_state.turn_phase = TurnPhase::PowerCollection;
        }
        TurnPhase::PowerCollection => {
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
            | (TurnPhase::PieceMovement, TurnPhase::PowerCollection)
            | (TurnPhase::PowerCollection, TurnPhase::PowerActivation)
    )
}

/// Resource to track PowerCollection phase timing
#[derive(Resource, Default)]
pub struct PowerCollectionTimer {
    pub start_time: Option<f32>,
}

/// System to handle PowerCollection phase timing and automatic advancement
pub fn handle_power_collection_phase(
    mut game_state: ResMut<GameState>,
    mut timer: ResMut<PowerCollectionTimer>,
    time: Res<Time>,
    input: Res<Input<KeyCode>>,
) {
    if game_state.turn_phase != TurnPhase::PowerCollection {
        timer.start_time = None;
        return;
    }

    // Initialize timer if entering PowerCollection phase
    if timer.start_time.is_none() {
        timer.start_time = Some(time.elapsed_seconds());
        println!(
            "PowerCollection phase started for {:?}",
            game_state.current_player
        );
    }

    let elapsed = time.elapsed_seconds() - timer.start_time.unwrap();

    // Auto-advance after 2 seconds or if player manually skips
    if elapsed > 2.0 || input.just_pressed(KeyCode::Space) {
        advance_turn_phase(&mut game_state);
        timer.start_time = None;
        println!(
            "PowerCollection phase completed, switching to {:?}'s turn",
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

/// System to provide visual feedback during PowerCollection phase
pub fn power_collection_phase_ui(
    game_state: Res<GameState>,
    mut text_query: Query<&mut Text, With<TurnIndicator>>,
) {
    if game_state.turn_phase != TurnPhase::PowerCollection {
        return;
    }

    for mut text in text_query.iter_mut() {
        // Update UI to show collection phase with instructions
        if let Some(section) = text.sections.get_mut(0) {
            section.value = format!(
                "{:?}'s Turn - Collection Phase (Press SPACE to continue)",
                game_state.current_player
            );
        }
    }
}

// Marker component for turn indicator UI
#[derive(Component)]
pub struct TurnIndicator;
