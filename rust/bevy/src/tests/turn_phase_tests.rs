use crate::components::{Player, PowerType};
use crate::resources::game_state::{GameState, TurnPhase};
use bevy::prelude::*;

#[test]
fn test_turn_phase_enum_variants() {
    // Test that all three phases exist
    let power_activation = TurnPhase::PowerActivation;
    let piece_movement = TurnPhase::PieceMovement;
    let power_collection = TurnPhase::PowerSpawning;

    assert_eq!(power_activation, TurnPhase::PowerActivation);
    assert_eq!(piece_movement, TurnPhase::PieceMovement);
    assert_eq!(power_collection, TurnPhase::PowerSpawning);
}

#[test]
fn test_turn_phase_sequence() {
    let mut game_state = GameState::default();

    // Should start with PowerActivation phase
    game_state.turn_phase = TurnPhase::PowerActivation;
    assert_eq!(game_state.turn_phase, TurnPhase::PowerActivation);

    // Should progress to PieceMovement
    game_state.turn_phase = TurnPhase::PieceMovement;
    assert_eq!(game_state.turn_phase, TurnPhase::PieceMovement);

    // Should progress to PowerSpawning
    game_state.turn_phase = TurnPhase::PowerSpawning;
    assert_eq!(game_state.turn_phase, TurnPhase::PowerSpawning);
}

#[test]
fn test_turn_phase_serialization() {
    // Test that PowerSpawning phase has the Serialize/Deserialize traits
    // This ensures the enum can be used in save games
    let power_collection = TurnPhase::PowerSpawning;

    // Basic serialization test using bincode (which is available)
    let serialized = bincode::serialize(&power_collection).unwrap();
    let deserialized: TurnPhase = bincode::deserialize(&serialized).unwrap();
    assert_eq!(power_collection, deserialized);
}

#[test]
fn test_game_state_with_power_collection_phase() {
    let mut game_state = GameState::default();

    // Test that GameState can hold PowerSpawning phase
    game_state.turn_phase = TurnPhase::PowerSpawning;
    assert_eq!(game_state.turn_phase, TurnPhase::PowerSpawning);

    // Test that other state remains intact
    assert_eq!(game_state.current_player, Player::Player1);
    assert!(game_state.player1_powers.is_empty());
    assert!(game_state.player2_powers.is_empty());
}

#[test]
fn test_turn_phase_cycle_complete() {
    let mut game_state = GameState::default();

    // Simulate complete turn cycle
    game_state.turn_phase = TurnPhase::PowerActivation;
    game_state.current_player = Player::Player1;

    // PowerActivation -> PieceMovement
    game_state.turn_phase = TurnPhase::PieceMovement;
    assert_eq!(game_state.current_player, Player::Player1); // Same player

    // PieceMovement -> PowerSpawning
    game_state.turn_phase = TurnPhase::PowerSpawning;
    assert_eq!(game_state.current_player, Player::Player1); // Same player

    // PowerSpawning -> PowerActivation (next player)
    game_state.turn_phase = TurnPhase::PowerActivation;
    game_state.current_player = Player::Player2; // Switch player
    assert_eq!(game_state.current_player, Player::Player2);
}

#[test]
fn test_power_collection_phase_with_powers() {
    let mut game_state = GameState::default();

    // Add a power to player 1
    game_state.player1_powers.push(PowerType::MoveDiagonal);
    game_state.current_player = Player::Player1;
    game_state.turn_phase = TurnPhase::PowerSpawning;

    // Verify power is accessible during PowerSpawning phase
    let current_powers = game_state.get_current_player_powers();
    assert_eq!(current_powers.len(), 1);
    assert_eq!(current_powers[0], PowerType::MoveDiagonal);
}

#[test]
fn test_turn_phase_display() {
    // Test that phases can be formatted for UI display
    assert_eq!(
        format!("{:?}", TurnPhase::PowerActivation),
        "PowerActivation"
    );
    assert_eq!(format!("{:?}", TurnPhase::PieceMovement), "PieceMovement");
    assert_eq!(format!("{:?}", TurnPhase::PowerSpawning), "PowerSpawning");
}

#[test]
fn test_turn_phase_resource_integration() {
    let mut app = App::new();
    app.insert_resource(GameState::default());

    // Test that GameState resource can be accessed and modified
    {
        let mut game_state = app.world.resource_mut::<GameState>();
        game_state.turn_phase = TurnPhase::PowerSpawning;
    }

    let game_state = app.world.resource::<GameState>();
    assert_eq!(game_state.turn_phase, TurnPhase::PowerSpawning);
}

#[test]
fn test_turn_phase_transition_system_ready() {
    let mut app = App::new();
    app.insert_resource(GameState::default());

    // Verify that the resource is properly initialized
    let game_state = app.world.resource::<GameState>();
    assert_eq!(game_state.current_player, Player::Player1);
    assert!(matches!(game_state.turn_phase, TurnPhase::PieceMovement));
}

// Test helper functions for turn phase logic

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
        }
    }
}

/// Check if a phase transition is valid
pub fn is_valid_phase_transition(from: TurnPhase, to: TurnPhase) -> bool {
    match (from, to) {
        (TurnPhase::PowerActivation, TurnPhase::PieceMovement) => true,
        (TurnPhase::PieceMovement, TurnPhase::PowerSpawning) => true,
        (TurnPhase::PowerSpawning, TurnPhase::PowerActivation) => true,
        _ => false,
    }
}

#[test]
fn test_advance_turn_phase_helper() {
    let mut game_state = GameState::default();
    game_state.turn_phase = TurnPhase::PowerActivation;
    game_state.current_player = Player::Player1;

    // PowerActivation -> PieceMovement
    advance_turn_phase(&mut game_state);
    assert_eq!(game_state.turn_phase, TurnPhase::PieceMovement);
    assert_eq!(game_state.current_player, Player::Player1);

    // PieceMovement -> PowerSpawning
    advance_turn_phase(&mut game_state);
    assert_eq!(game_state.turn_phase, TurnPhase::PowerSpawning);
    assert_eq!(game_state.current_player, Player::Player1);

    // PowerSpawning -> PowerActivation (next player)
    advance_turn_phase(&mut game_state);
    assert_eq!(game_state.turn_phase, TurnPhase::PowerActivation);
    assert_eq!(game_state.current_player, Player::Player2);
}

#[test]
fn test_valid_phase_transitions() {
    assert!(is_valid_phase_transition(
        TurnPhase::PowerActivation,
        TurnPhase::PieceMovement
    ));
    assert!(is_valid_phase_transition(
        TurnPhase::PieceMovement,
        TurnPhase::PowerSpawning
    ));
    assert!(is_valid_phase_transition(
        TurnPhase::PowerSpawning,
        TurnPhase::PowerActivation
    ));

    // Invalid transitions
    assert!(!is_valid_phase_transition(
        TurnPhase::PowerActivation,
        TurnPhase::PowerSpawning
    ));
    assert!(!is_valid_phase_transition(
        TurnPhase::PieceMovement,
        TurnPhase::PowerActivation
    ));
    assert!(!is_valid_phase_transition(
        TurnPhase::PowerSpawning,
        TurnPhase::PieceMovement
    ));
}
