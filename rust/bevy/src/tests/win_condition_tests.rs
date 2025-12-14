use crate::components::*;
use crate::systems::win_condition::GameResult;
use bevy::prelude::*;

#[test]
fn test_game_result_initialization() {
    let game_result = GameResult::default();

    assert_eq!(game_result.winner, None);
    assert!(!game_result.game_over);
}

#[test]
fn test_win_condition_no_pieces() {
    let mut app = App::new();
    app.add_plugins(MinimalPlugins);

    let mut world = app.world;

    // Only Player 1 has pieces
    world.spawn(GamePiece {
        player: Player::Player1,
        board_position: (0, 0),
    });

    // Player 2 has no pieces - Player 1 should win
    let result = check_win_condition(&mut world);
    assert_eq!(result.winner, Some(Player::Player1));
    assert!(result.game_over);
}

#[test]
fn test_win_condition_both_have_pieces() {
    let mut app = App::new();
    app.add_plugins(MinimalPlugins);

    let mut world = app.world;

    // Both players have pieces
    world.spawn(GamePiece {
        player: Player::Player1,
        board_position: (0, 0),
    });

    world.spawn(GamePiece {
        player: Player::Player2,
        board_position: (7, 7),
    });

    // Game should not be over
    let result = check_win_condition(&mut world);
    assert_eq!(result.winner, None);
    assert!(!result.game_over);
}

#[test]
fn test_piece_capture_scenario() {
    let mut app = App::new();
    app.add_plugins(MinimalPlugins);

    let mut world = app.world;

    // Create initial pieces
    let _piece1 = world
        .spawn(GamePiece {
            player: Player::Player1,
            board_position: (3, 3),
        })
        .id();

    let piece2 = world
        .spawn(GamePiece {
            player: Player::Player2,
            board_position: (3, 4),
        })
        .id();

    // Simulate capture by removing Player 2's piece
    world.entity_mut(piece2).despawn();

    // Check win condition
    let result = check_win_condition(&mut world);
    assert_eq!(result.winner, Some(Player::Player1));
    assert!(result.game_over);
}

// Helper function to check win conditions
fn check_win_condition(world: &mut World) -> GameResult {
    let mut player1_pieces = 0;
    let mut player2_pieces = 0;

    let mut query = world.query::<&GamePiece>();
    for piece in query.iter(world) {
        match piece.player {
            Player::Player1 => player1_pieces += 1,
            Player::Player2 => player2_pieces += 1,
        }
    }

    if player1_pieces == 0 {
        GameResult {
            winner: Some(Player::Player2),
            game_over: true,
        }
    } else if player2_pieces == 0 {
        GameResult {
            winner: Some(Player::Player1),
            game_over: true,
        }
    } else {
        GameResult::default()
    }
}
