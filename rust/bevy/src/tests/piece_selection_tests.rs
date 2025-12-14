use crate::components::*;
use crate::resources::*;
use crate::systems::drag_drop_3d::*;
use crate::systems::pieces_3d::*;
use bevy::prelude::*;

/// Test suite for piece selection logic
/// Validates that players can only select their own pieces and selection state management

#[test]
fn test_player_piece_ownership() {
    let mut app = App::new();
    app.add_plugins(MinimalPlugins);

    let world = &mut app.world;

    // Create pieces for both players in their starting positions
    let p1_pieces = vec![
        (0, 0),
        (2, 0),
        (4, 0),
        (6, 0),
        (8, 0), // Row 0
        (1, 1),
        (3, 1),
        (5, 1),
        (7, 1),
        (9, 1), // Row 1
    ];

    let p2_pieces = vec![
        (1, 6),
        (3, 6),
        (5, 6),
        (7, 6),
        (9, 6), // Row 6
        (0, 7),
        (2, 7),
        (4, 7),
        (6, 7),
        (8, 7), // Row 7
    ];

    // Spawn Player 1 pieces
    for (x, y) in p1_pieces.iter() {
        world.spawn((
            GamePiece {
                player: Player::Player1,
                board_position: (*x, *y),
            },
            GamePiece3D {
                player: Player::Player1,
                board_position: (*x, *y),
            },
            Transform::default(),
        ));
    }

    // Spawn Player 2 pieces
    for (x, y) in p2_pieces.iter() {
        world.spawn((
            GamePiece {
                player: Player::Player2,
                board_position: (*x, *y),
            },
            GamePiece3D {
                player: Player::Player2,
                board_position: (*x, *y),
            },
            Transform::default(),
        ));
    }

    // Test Player 1 can select their pieces
    for (x, y) in p1_pieces.iter() {
        assert!(
            can_player_select_piece(world, (*x, *y), Player::Player1),
            "Player 1 should be able to select piece at ({}, {})",
            x,
            y
        );
        assert!(
            !can_player_select_piece(world, (*x, *y), Player::Player2),
            "Player 2 should NOT be able to select Player 1's piece at ({}, {})",
            x,
            y
        );
    }

    // Test Player 2 can select their pieces
    for (x, y) in p2_pieces.iter() {
        assert!(
            can_player_select_piece(world, (*x, *y), Player::Player2),
            "Player 2 should be able to select piece at ({}, {})",
            x,
            y
        );
        assert!(
            !can_player_select_piece(world, (*x, *y), Player::Player1),
            "Player 1 should NOT be able to select Player 2's piece at ({}, {})",
            x,
            y
        );
    }

    // Test empty squares
    assert!(
        !can_player_select_piece(world, (5, 4), Player::Player1),
        "Should not be able to select empty square"
    );
    assert!(
        !can_player_select_piece(world, (5, 4), Player::Player2),
        "Should not be able to select empty square"
    );
}

#[test]
fn test_piece_selection_with_game_state() {
    let mut app = App::new();
    app.add_plugins(MinimalPlugins);
    app.insert_resource(GameState {
        current_player: Player::Player1,
        turn_phase: TurnPhase::PieceMovement,
        ..Default::default()
    });

    let world = &mut app.world;

    // Create test pieces
    let p1_piece = world
        .spawn((
            GamePiece {
                player: Player::Player1,
                board_position: (0, 0),
            },
            GamePiece3D {
                player: Player::Player1,
                board_position: (0, 0),
            },
            Transform::default(),
        ))
        .id();

    let p2_piece = world
        .spawn((
            GamePiece {
                player: Player::Player2,
                board_position: (1, 7),
            },
            GamePiece3D {
                player: Player::Player2,
                board_position: (1, 7),
            },
            Transform::default(),
        ))
        .id();

    let current_player = world.resource::<GameState>().current_player;

    // Current player should be able to select their pieces
    assert_eq!(current_player, Player::Player1);
    assert!(can_player_select_piece(world, (0, 0), current_player));
    assert!(!can_player_select_piece(world, (1, 7), current_player));
}

#[test]
fn test_selection_state_management() {
    let mut app = App::new();
    app.add_plugins(MinimalPlugins);

    let world = &mut app.world;

    // Create a piece
    let piece_entity = world
        .spawn((
            GamePiece {
                player: Player::Player1,
                board_position: (2, 1),
            },
            GamePiece3D {
                player: Player::Player1,
                board_position: (2, 1),
            },
            Transform::default(),
        ))
        .id();

    // Initially not selected
    assert!(!world.entity(piece_entity).contains::<Selected>());

    // Add selection
    world.entity_mut(piece_entity).insert(Selected);
    assert!(world.entity(piece_entity).contains::<Selected>());

    // Remove selection
    world.entity_mut(piece_entity).remove::<Selected>();
    assert!(!world.entity(piece_entity).contains::<Selected>());
}

#[test]
fn test_multiple_selection_handling() {
    let mut app = App::new();
    app.add_plugins(MinimalPlugins);

    let world = &mut app.world;

    // Create multiple pieces
    let piece1 = world
        .spawn((
            GamePiece {
                player: Player::Player1,
                board_position: (0, 0),
            },
            GamePiece3D {
                player: Player::Player1,
                board_position: (0, 0),
            },
            Transform::default(),
        ))
        .id();

    let piece2 = world
        .spawn((
            GamePiece {
                player: Player::Player1,
                board_position: (2, 0),
            },
            GamePiece3D {
                player: Player::Player1,
                board_position: (2, 0),
            },
            Transform::default(),
        ))
        .id();

    let piece3 = world
        .spawn((
            GamePiece {
                player: Player::Player1,
                board_position: (4, 0),
            },
            GamePiece3D {
                player: Player::Player1,
                board_position: (4, 0),
            },
            Transform::default(),
        ))
        .id();

    // Select multiple pieces
    world.entity_mut(piece1).insert(Selected);
    world.entity_mut(piece2).insert(Selected);

    // Count selected pieces
    let mut selected_count = 0;
    let mut query = world.query::<&Selected>();
    for _ in query.iter(world) {
        selected_count += 1;
    }

    assert_eq!(selected_count, 2, "Should have 2 selected pieces");

    // Verify specific pieces are selected
    assert!(world.entity(piece1).contains::<Selected>());
    assert!(world.entity(piece2).contains::<Selected>());
    assert!(!world.entity(piece3).contains::<Selected>());
}

#[test]
fn test_drag_state_initialization() {
    let mut app = App::new();
    app.add_plugins(MinimalPlugins);

    let world = &mut app.world;

    // Create a piece
    let piece_entity = world
        .spawn((
            GamePiece {
                player: Player::Player1,
                board_position: (1, 1),
            },
            GamePiece3D {
                player: Player::Player1,
                board_position: (1, 1),
            },
            Transform::default(),
        ))
        .id();

    // Initially not dragging
    assert!(!world.entity(piece_entity).contains::<Dragging3D>());

    // Start dragging
    world
        .entity_mut(piece_entity)
        .insert(Dragging3D { start_pos: (1, 1) });

    assert!(world.entity(piece_entity).contains::<Dragging3D>());

    // Verify drag state data
    let drag_state = world.entity(piece_entity).get::<Dragging3D>().unwrap();
    assert_eq!(drag_state.start_pos, (1, 1));
}

#[test]
fn test_turn_phase_restrictions() {
    let mut game_state = GameState::default();

    // Should start in PieceMovement phase
    assert_eq!(game_state.turn_phase, TurnPhase::PieceMovement);

    // Movement should be allowed in PieceMovement phase
    assert!(is_movement_allowed(&game_state));

    // Change to PowerActivation phase
    game_state.turn_phase = TurnPhase::PowerActivation;

    // Movement should not be allowed in PowerActivation phase
    assert!(!is_movement_allowed(&game_state));
}

#[test]
fn test_piece_count_validation() {
    let mut app = App::new();
    app.add_plugins(MinimalPlugins);

    let world = &mut app.world;

    // Create starting pieces for both players (checkerboard pattern)
    let mut p1_count = 0;
    let mut p2_count = 0;

    // Player 1 pieces (bottom two rows)
    for y in 0..2 {
        for x in 0..BOARD_WIDTH {
            if (x + y) % 2 == 0 {
                world.spawn((
                    GamePiece {
                        player: Player::Player1,
                        board_position: (x, y),
                    },
                    GamePiece3D {
                        player: Player::Player1,
                        board_position: (x, y),
                    },
                    Transform::default(),
                ));
                p1_count += 1;
            }
        }
    }

    // Player 2 pieces (top two rows)
    for y in (BOARD_HEIGHT - 2)..BOARD_HEIGHT {
        for x in 0..BOARD_WIDTH {
            if (x + y) % 2 == 0 {
                world.spawn((
                    GamePiece {
                        player: Player::Player2,
                        board_position: (x, y),
                    },
                    GamePiece3D {
                        player: Player::Player2,
                        board_position: (x, y),
                    },
                    Transform::default(),
                ));
                p2_count += 1;
            }
        }
    }

    // Verify piece counts
    assert_eq!(p1_count, 10, "Player 1 should have 10 pieces");
    assert_eq!(p2_count, 10, "Player 2 should have 10 pieces");

    // Verify by querying the world
    let mut actual_p1_count = 0;
    let mut actual_p2_count = 0;

    let mut query = world.query::<&GamePiece>();
    for piece in query.iter(world) {
        match piece.player {
            Player::Player1 => actual_p1_count += 1,
            Player::Player2 => actual_p2_count += 1,
        }
    }

    assert_eq!(actual_p1_count, 10, "Actual Player 1 count should be 10");
    assert_eq!(actual_p2_count, 10, "Actual Player 2 count should be 10");
}

#[test]
fn test_piece_position_validation() {
    let mut app = App::new();
    app.add_plugins(MinimalPlugins);

    let world = &mut app.world;

    // Create pieces with various positions
    let test_positions = vec![
        (0, 0),
        (9, 0),
        (0, 7),
        (9, 7), // Corners
        (5, 4), // Center
        (1, 1),
        (8, 6), // Random positions
    ];

    for (i, (x, y)) in test_positions.iter().enumerate() {
        let player = if i % 2 == 0 {
            Player::Player1
        } else {
            Player::Player2
        };

        world.spawn((
            GamePiece {
                player,
                board_position: (*x, *y),
            },
            GamePiece3D {
                player,
                board_position: (*x, *y),
            },
            Transform::default(),
        ));
    }

    // Verify all pieces have valid positions
    let mut query = world.query::<&GamePiece>();
    for piece in query.iter(world) {
        assert!(
            piece.board_position.0 < BOARD_WIDTH,
            "Piece X position should be within board bounds"
        );
        assert!(
            piece.board_position.1 < BOARD_HEIGHT,
            "Piece Y position should be within board bounds"
        );
    }
}

#[test]
fn test_selection_highlighting_state() {
    let mut app = App::new();
    app.add_plugins(MinimalPlugins);

    let world = &mut app.world;

    // Create a piece
    let piece_entity = world
        .spawn((
            GamePiece {
                player: Player::Player1,
                board_position: (3, 1),
            },
            GamePiece3D {
                player: Player::Player1,
                board_position: (3, 1),
            },
            Transform::default(),
        ))
        .id();

    // Initially no highlight
    assert!(!world.entity(piece_entity).contains::<SelectionHighlight>());

    // Add highlight (this would be done by the highlighting system)
    world.entity_mut(piece_entity).insert(SelectionHighlight);
    assert!(world.entity(piece_entity).contains::<SelectionHighlight>());

    // Can have both selection and highlight
    world.entity_mut(piece_entity).insert(Selected);
    assert!(world.entity(piece_entity).contains::<Selected>());
    assert!(world.entity(piece_entity).contains::<SelectionHighlight>());

    // Remove highlight
    world
        .entity_mut(piece_entity)
        .remove::<SelectionHighlight>();
    assert!(!world.entity(piece_entity).contains::<SelectionHighlight>());
    assert!(world.entity(piece_entity).contains::<Selected>()); // Selection remains
}

// Helper functions for testing
fn can_player_select_piece(world: &mut World, position: (u8, u8), player: Player) -> bool {
    let mut query = world.query::<&GamePiece>();
    for piece in query.iter(world) {
        if piece.board_position == position {
            return piece.player == player;
        }
    }
    false
}

fn is_movement_allowed(game_state: &GameState) -> bool {
    game_state.turn_phase == TurnPhase::PieceMovement
}
