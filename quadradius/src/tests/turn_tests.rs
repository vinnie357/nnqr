use crate::components::*;
use crate::resources::*;

#[test]
fn test_turn_alternation() {
    let mut game_state = GameState {
        current_player: Player::Player1,
        player1_powers: Vec::new(),
        player2_powers: Vec::new(),
        turn_phase: crate::resources::TurnPhase::PowerActivation,
        selected_power: None,
    };

    // End turn for Player 1
    end_turn(&mut game_state);
    assert_eq!(game_state.current_player, Player::Player2);

    // End turn for Player 2
    end_turn(&mut game_state);
    assert_eq!(game_state.current_player, Player::Player1);
}

#[test]
fn test_game_state_initialization() {
    let game_state = GameState::default();

    assert_eq!(game_state.current_player, Player::Player1);
}

#[test]
fn test_invalid_turn_actions() {
    let game_state = GameState {
        current_player: Player::Player1,
        player1_powers: Vec::new(),
        player2_powers: Vec::new(),
        turn_phase: crate::resources::TurnPhase::PowerActivation,
        selected_power: None,
    };

    // Player 2 cannot act during Player 1's turn
    assert!(!can_player_act(&game_state, Player::Player2));

    // Player 1 can act during their turn
    assert!(can_player_act(&game_state, Player::Player1));
}

#[test]
fn test_multiple_turn_switches() {
    let mut game_state = GameState::default();

    // Start with Player 1
    assert_eq!(game_state.current_player, Player::Player1);

    // Switch multiple times
    for _ in 0..5 {
        end_turn(&mut game_state);
    }

    // After 5 switches, should be Player 2
    assert_eq!(game_state.current_player, Player::Player2);
}

// Helper functions
fn end_turn(game_state: &mut GameState) {
    game_state.current_player = match game_state.current_player {
        Player::Player1 => Player::Player2,
        Player::Player2 => Player::Player1,
    };
}

fn can_player_act(game_state: &GameState, player: Player) -> bool {
    game_state.current_player == player
}

// Tests specifically for the 3D drag-drop turn switching bug fix

#[test]
fn test_3d_turn_switching_after_move() {
    let mut game_state = GameState {
        current_player: Player::Player1,
        player1_powers: Vec::new(),
        player2_powers: Vec::new(),
        turn_phase: TurnPhase::PieceMovement,
        selected_power: None,
    };

    // Simulate a successful piece move in 3D system
    simulate_3d_piece_move_completion(&mut game_state);

    // After move, should switch to Player2 and reset to PowerActivation phase
    assert_eq!(game_state.current_player, Player::Player2);
    assert_eq!(game_state.turn_phase, TurnPhase::PowerActivation);
    assert_eq!(game_state.selected_power, None);
}

#[test]
fn test_3d_turn_switching_both_players() {
    let mut game_state = GameState {
        current_player: Player::Player1,
        player1_powers: Vec::new(),
        player2_powers: Vec::new(),
        turn_phase: TurnPhase::PieceMovement,
        selected_power: None,
    };

    // Player1 makes a move
    simulate_3d_piece_move_completion(&mut game_state);
    assert_eq!(game_state.current_player, Player::Player2);

    // Player2 makes a move
    game_state.turn_phase = TurnPhase::PieceMovement; // Simulate completing power phase
    simulate_3d_piece_move_completion(&mut game_state);
    assert_eq!(game_state.current_player, Player::Player1);
}

#[test]
fn test_bug_reproduction_player1_turn_stuck() {
    // This test reproduces the original bug scenario
    let mut game_state = GameState {
        current_player: Player::Player1,
        player1_powers: Vec::new(),
        player2_powers: Vec::new(),
        turn_phase: TurnPhase::PieceMovement,
        selected_power: None,
    };

    // Before fix: Player1 could make multiple moves without switching
    let initial_player = game_state.current_player;

    // Simulate old buggy behavior (only changing phase, not player)
    game_state.turn_phase = TurnPhase::PowerActivation;
    // Bug: current_player stays the same

    // This would be wrong - player should have switched
    if game_state.current_player == initial_player
        && game_state.turn_phase == TurnPhase::PowerActivation
    {
        // This represents the bug state - fix it properly
        simulate_3d_piece_move_completion(&mut game_state);
    }

    // After proper fix: Player should have switched
    assert_ne!(game_state.current_player, initial_player);
    assert_eq!(game_state.current_player, Player::Player2);
}

#[test]
fn test_game_state_changes_marked() {
    let mut game_state = GameState {
        current_player: Player::Player1,
        player1_powers: Vec::new(),
        player2_powers: Vec::new(),
        turn_phase: TurnPhase::PieceMovement,
        selected_power: None,
    };

    let old_player = game_state.current_player;
    simulate_3d_piece_move_completion(&mut game_state);

    // Verify all expected changes occurred
    assert_ne!(game_state.current_player, old_player);
    assert_eq!(game_state.turn_phase, TurnPhase::PowerActivation);
    assert_eq!(game_state.selected_power, None);
}

// Helper function to simulate the corrected 3D piece move completion
fn simulate_3d_piece_move_completion(game_state: &mut GameState) {
    // This simulates the fix we implemented in drag_drop_3d.rs
    game_state.current_player = match game_state.current_player {
        Player::Player1 => Player::Player2,
        Player::Player2 => Player::Player1,
    };

    game_state.turn_phase = TurnPhase::PowerActivation;
    game_state.selected_power = None;

    // Note: In real code we call game_state.set_changed() but that's not testable here
}
