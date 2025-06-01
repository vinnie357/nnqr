use crate::components::*;
use crate::resources::*;
use bevy::prelude::*;

#[test]
fn test_turn_alternation() {
    let mut game_state = GameState {
        current_player: Player::Player1,
        selected_piece: None,
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
    assert_eq!(game_state.selected_piece, None);
}

#[test]
fn test_invalid_turn_actions() {
    let game_state = GameState {
        current_player: Player::Player1,
        selected_piece: None,
    };
    
    // Player 2 cannot act during Player 1's turn
    assert!(!can_player_act(&game_state, Player::Player2));
    
    // Player 1 can act during their turn
    assert!(can_player_act(&game_state, Player::Player1));
}

#[test]
fn test_piece_selection_state() {
    let mut game_state = GameState::default();
    let test_entity = Entity::from_raw(123);
    
    // Select a piece
    game_state.selected_piece = Some(test_entity);
    assert_eq!(game_state.selected_piece, Some(test_entity));
    
    // Deselect piece
    game_state.selected_piece = None;
    assert_eq!(game_state.selected_piece, None);
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