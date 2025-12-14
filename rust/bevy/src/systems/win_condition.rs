use crate::components::*;
use bevy::prelude::*;

#[derive(Resource, Default)]
pub struct GameResult {
    pub winner: Option<Player>,
    pub game_over: bool,
}

pub fn check_win_condition(pieces: Query<&GamePiece>, mut game_result: ResMut<GameResult>) {
    if game_result.game_over {
        return;
    }

    let mut player1_count = 0;
    let mut player2_count = 0;

    for piece in pieces.iter() {
        match piece.player {
            Player::Player1 => player1_count += 1,
            Player::Player2 => player2_count += 1,
        }
    }

    if player1_count == 0 {
        game_result.winner = Some(Player::Player2);
        game_result.game_over = true;
        println!("Player 2 wins!");
    } else if player2_count == 0 {
        game_result.winner = Some(Player::Player1);
        game_result.game_over = true;
        println!("Player 1 wins!");
    }
}
