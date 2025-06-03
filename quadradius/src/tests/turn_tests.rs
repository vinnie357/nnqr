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
