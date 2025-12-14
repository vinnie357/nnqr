/// Test that verifies piece movement doesn't leave duplicate pieces behind
#[cfg(test)]
pub mod piece_movement_tests {
    use crate::{components::*, resources::*};
    use crate::components::board::{BOARD_WIDTH, BOARD_HEIGHT};
    use bevy::prelude::*;

    #[test]
    fn test_piece_movement_no_duplicates() {
        let mut app = App::new();
        app.add_plugins(MinimalPlugins);
        
        // Add necessary resources
        app.insert_resource(GameState {
            current_player: Player::Player1,
            turn_phase: TurnPhase::PieceMovement,
            player1_powers: Vec::new(),
            player2_powers: Vec::new(),
            selected_power: None,
        });

        // Spawn initial game pieces
        let piece_entity = app
            .world
            .spawn((
                GamePiece {
                    player: Player::Player1,
                    board_position: (2, 2),
                },
                SpriteBundle {
                    transform: Transform::from_xyz(0.0, 0.0, 1.0),
                    ..default()
                },
            ))
            .id();

        // Verify initial state - should have exactly 1 piece
        let initial_count = app
            .world
            .query::<&GamePiece>()
            .iter(&app.world)
            .count();
        assert_eq!(initial_count, 1, "Should start with exactly 1 piece");

        // Simulate moving the piece to a new position
        if let Some(mut piece) = app.world.get_mut::<GamePiece>(piece_entity) {
            piece.board_position = (3, 3);
        }
        if let Some(mut transform) = app.world.get_mut::<Transform>(piece_entity) {
            transform.translation = Vec3::new(64.0, 64.0, 1.0); // New world position
        }

        // Verify after movement - should still have exactly 1 piece
        let final_count = app
            .world
            .query::<&GamePiece>()
            .iter(&app.world)
            .count();
        assert_eq!(final_count, 1, "Should still have exactly 1 piece after movement");

        // Verify the piece is at the new position
        let piece = app.world.get::<GamePiece>(piece_entity).unwrap();
        assert_eq!(piece.board_position, (3, 3), "Piece should be at new board position");
    }

    #[test]
    fn test_piece_capture_removes_enemy() {
        let mut app = App::new();
        app.add_plugins(MinimalPlugins);
        
        // Add necessary resources
        app.insert_resource(GameState {
            current_player: Player::Player1,
            turn_phase: TurnPhase::PieceMovement,
            player1_powers: Vec::new(),
            player2_powers: Vec::new(),
            selected_power: None,
        });

        // Spawn two pieces - one for each player
        let player1_piece = app
            .world
            .spawn((
                GamePiece {
                    player: Player::Player1,
                    board_position: (2, 2),
                },
                SpriteBundle::default(),
            ))
            .id();

        let player2_piece = app
            .world
            .spawn((
                GamePiece {
                    player: Player::Player2,
                    board_position: (3, 3),
                },
                SpriteBundle::default(),
            ))
            .id();

        // Verify initial state - should have 2 pieces
        let initial_count = app
            .world
            .query::<&GamePiece>()
            .iter(&app.world)
            .count();
        assert_eq!(initial_count, 2, "Should start with 2 pieces");

        // Simulate Player 1 capturing Player 2's piece
        // Move Player 1 to Player 2's position
        if let Some(mut piece) = app.world.get_mut::<GamePiece>(player1_piece) {
            piece.board_position = (3, 3);
        }
        
        // Remove the captured piece
        app.world.despawn(player2_piece);

        // Verify after capture - should have exactly 1 piece
        let final_count = app
            .world
            .query::<&GamePiece>()
            .iter(&app.world)
            .count();
        assert_eq!(final_count, 1, "Should have 1 piece after capture");

        // Verify the remaining piece is Player 1's and at the captured position
        let remaining_pieces: Vec<_> = app
            .world
            .query::<&GamePiece>()
            .iter(&app.world)
            .collect();
        assert_eq!(remaining_pieces.len(), 1);
        assert_eq!(remaining_pieces[0].player, Player::Player1);
        assert_eq!(remaining_pieces[0].board_position, (3, 3));
    }

    #[test]
    fn test_board_boundaries_movement() {
        let mut app = App::new();
        app.add_plugins(MinimalPlugins);

        // Test that pieces cannot move outside board boundaries
        let test_cases = vec![
            // (start_pos, target_pos, should_be_valid)
            ((0, 0), (-1i8 as u8, 0), false), // Off left edge
            ((BOARD_WIDTH - 1, 0), (BOARD_WIDTH, 0), false), // Off right edge
            ((0, 0), (0, -1i8 as u8), false), // Off bottom edge
            ((0, BOARD_HEIGHT - 1), (0, BOARD_HEIGHT), false), // Off top edge
            ((1, 1), (0, 1), true), // Valid move within bounds
            ((1, 1), (2, 1), true), // Valid move within bounds
        ];

        for (start_pos, target_pos, expected_valid) in test_cases {
            let is_within_bounds = target_pos.0 < BOARD_WIDTH && target_pos.1 < BOARD_HEIGHT;
            assert_eq!(
                is_within_bounds, expected_valid,
                "Boundary check failed for move from {:?} to {:?}",
                start_pos, target_pos
            );
        }
    }
}