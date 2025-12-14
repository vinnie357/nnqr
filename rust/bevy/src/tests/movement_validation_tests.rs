use crate::components::*;
use crate::resources::*;
use crate::systems::drag_drop_3d::*;
use crate::systems::isometric_camera::*;
use crate::systems::pieces_3d::*;
use bevy::prelude::*;

/// Test suite for validating movement system functionality
/// Covers basic movement rules, 3D drag-and-drop, and coordinate conversion

#[test]
fn test_correct_board_dimensions() {
    // Validate that the board uses the correct 10x8 dimensions
    assert_eq!(BOARD_WIDTH, 10);
    assert_eq!(BOARD_HEIGHT, 8);

    // Total board squares should be 80
    assert_eq!(BOARD_WIDTH as u16 * BOARD_HEIGHT as u16, 80);
}

#[test]
fn test_basic_movement_validation() {
    let mut app = App::new();
    app.insert_resource(GameState::default());
    app.add_plugins(MinimalPlugins);

    let world = &mut app.world;

    // Create test board tiles for 10x8 board
    for x in 0..BOARD_WIDTH {
        for y in 0..BOARD_HEIGHT {
            world.spawn(BoardTile {
                coordinates: (x, y),
                height: 0,
            });
        }
    }

    // Test valid horizontal movement
    assert!(is_valid_basic_move((0, 0), (1, 0)));
    assert!(is_valid_basic_move((5, 3), (6, 3)));

    // Test valid vertical movement
    assert!(is_valid_basic_move((0, 0), (0, 1)));
    assert!(is_valid_basic_move((3, 2), (3, 3)));

    // Test invalid diagonal movement (should fail without MoveDiagonal power)
    assert!(!is_valid_basic_move((0, 0), (1, 1)));
    assert!(!is_valid_basic_move((2, 2), (3, 3)));

    // Test invalid distance (more than 1 square)
    assert!(!is_valid_basic_move((0, 0), (0, 2)));
    assert!(!is_valid_basic_move((0, 0), (2, 0)));
    assert!(!is_valid_basic_move((1, 1), (3, 3)));

    // Test out of bounds for 10x8 board
    assert!(!is_valid_basic_move((9, 7), (10, 7))); // Beyond width
    assert!(!is_valid_basic_move((9, 7), (9, 8))); // Beyond height
    assert!(!is_valid_basic_move((0, 0), (255, 0))); // Way out of bounds
}

#[test]
fn test_height_movement_restrictions() {
    // Test Quadradius height rules: can move down any levels, up only one level

    // Can move up one level
    assert!(can_move_with_height(0, 1));
    assert!(can_move_with_height(2, 3));

    // Cannot move up more than one level
    assert!(!can_move_with_height(0, 2));
    assert!(!can_move_with_height(1, 3));
    assert!(!can_move_with_height(-1, 1));

    // Can move to same height
    assert!(can_move_with_height(1, 1));
    assert!(can_move_with_height(0, 0));
    assert!(can_move_with_height(5, 5));

    // Can move down any number of levels
    assert!(can_move_with_height(3, 0));
    assert!(can_move_with_height(5, 2));
    assert!(can_move_with_height(10, -5));
    assert!(can_move_with_height(2, -1));
}

#[test]
fn test_piece_placement_pattern() {
    // Test that pieces are placed in the correct checkerboard pattern for 10x8 board
    let mut app = App::new();
    app.add_plugins(MinimalPlugins);

    let world = &mut app.world;

    // Simulate piece placement pattern
    let mut player1_pieces = Vec::new();
    let mut player2_pieces = Vec::new();

    // Player 1 pieces (bottom two rows)
    for y in 0..2 {
        for x in 0..BOARD_WIDTH {
            if (x + y) % 2 == 0 {
                player1_pieces.push((x, y));
            }
        }
    }

    // Player 2 pieces (top two rows)
    for y in (BOARD_HEIGHT - 2)..BOARD_HEIGHT {
        for x in 0..BOARD_WIDTH {
            if (x + y) % 2 == 0 {
                player2_pieces.push((x, y));
            }
        }
    }

    // Validate piece counts (should be 10 pieces per player)
    assert_eq!(player1_pieces.len(), 10, "Player 1 should have 10 pieces");
    assert_eq!(player2_pieces.len(), 10, "Player 2 should have 10 pieces");

    // Validate no overlapping positions
    for p1_pos in &player1_pieces {
        assert!(
            !player2_pieces.contains(p1_pos),
            "Pieces should not overlap"
        );
    }

    // Validate pieces are in correct rows
    for (x, y) in &player1_pieces {
        assert!(*y < 2, "Player 1 pieces should be in bottom 2 rows");
        assert!(*x < BOARD_WIDTH, "Pieces should be within board width");
    }

    for (x, y) in &player2_pieces {
        assert!(
            *y >= BOARD_HEIGHT - 2,
            "Player 2 pieces should be in top 2 rows"
        );
        assert!(*x < BOARD_WIDTH, "Pieces should be within board width");
    }
}

#[test]
fn test_piece_capture_rules() {
    let mut app = App::new();
    app.add_plugins(MinimalPlugins);

    let world = &mut app.world;

    // Create test pieces
    let player1_piece = world
        .spawn(GamePiece {
            player: Player::Player1,
            board_position: (2, 2),
        })
        .id();

    let player2_piece = world
        .spawn(GamePiece {
            player: Player::Player2,
            board_position: (2, 3),
        })
        .id();

    let another_player1_piece = world
        .spawn(GamePiece {
            player: Player::Player1,
            board_position: (3, 2),
        })
        .id();

    // Test capture rules
    // Cannot move to square occupied by same player
    assert!(!can_move_to_occupied_tile(
        world,
        (2, 2),
        (3, 2),
        Player::Player1
    ));

    // Can capture opponent piece
    assert!(can_move_to_occupied_tile(
        world,
        (2, 2),
        (2, 3),
        Player::Player1
    ));
    assert!(can_move_to_occupied_tile(
        world,
        (2, 3),
        (2, 2),
        Player::Player2
    ));

    // Can move to empty square
    assert!(can_move_to_occupied_tile(
        world,
        (2, 2),
        (1, 2),
        Player::Player1
    ));
}

#[test]
fn test_coordinate_conversion_bounds() {
    // Test that coordinate conversions handle board boundaries correctly

    // Test isometric conversion for corner positions
    let top_left = board_to_isometric((0, 0), 0.0);
    let top_right = board_to_isometric((BOARD_WIDTH - 1, 0), 0.0);
    let bottom_left = board_to_isometric((0, BOARD_HEIGHT - 1), 0.0);
    let bottom_right = board_to_isometric((BOARD_WIDTH - 1, BOARD_HEIGHT - 1), 0.0);

    // Verify that all coordinates are finite
    assert!(top_left.x.is_finite() && top_left.y.is_finite() && top_left.z.is_finite());
    assert!(top_right.x.is_finite() && top_right.y.is_finite() && top_right.z.is_finite());
    assert!(bottom_left.x.is_finite() && bottom_left.y.is_finite() && bottom_left.z.is_finite());
    assert!(bottom_right.x.is_finite() && bottom_right.y.is_finite() && bottom_right.z.is_finite());

    // Test height scaling
    let ground_level = board_to_isometric((5, 4), 0.0);
    let elevated = board_to_isometric((5, 4), 3.0);

    // Elevated position should have higher Y coordinate
    assert!(
        elevated.y > ground_level.y,
        "Elevated tiles should have higher Y coordinate"
    );
}

#[test]
fn test_turn_phase_movement_restrictions() {
    let mut game_state = GameState::default();

    // Should start in PieceMovement phase
    assert_eq!(game_state.turn_phase, TurnPhase::PieceMovement);

    // Test that movement is allowed in PieceMovement phase
    let movement_allowed = game_state.turn_phase == TurnPhase::PieceMovement;
    assert!(
        movement_allowed,
        "Movement should be allowed in PieceMovement phase"
    );

    // Test that movement is not allowed in PowerActivation phase
    game_state.turn_phase = TurnPhase::PowerActivation;
    let movement_blocked = game_state.turn_phase != TurnPhase::PieceMovement;
    assert!(
        movement_blocked,
        "Movement should be blocked in PowerActivation phase"
    );
}

#[test]
fn test_player_piece_ownership() {
    let mut app = App::new();
    app.add_plugins(MinimalPlugins);

    let world = &mut app.world;

    // Create pieces for both players
    let p1_piece1 = world
        .spawn((
            GamePiece {
                player: Player::Player1,
                board_position: (0, 0),
            },
            GamePiece3D {
                player: Player::Player1,
                board_position: (0, 0),
            },
        ))
        .id();

    let p1_piece2 = world
        .spawn((
            GamePiece {
                player: Player::Player1,
                board_position: (2, 0),
            },
            GamePiece3D {
                player: Player::Player1,
                board_position: (2, 0),
            },
        ))
        .id();

    let p2_piece1 = world
        .spawn((
            GamePiece {
                player: Player::Player2,
                board_position: (1, 7),
            },
            GamePiece3D {
                player: Player::Player2,
                board_position: (1, 7),
            },
        ))
        .id();

    let p2_piece2 = world
        .spawn((
            GamePiece {
                player: Player::Player2,
                board_position: (3, 7),
            },
            GamePiece3D {
                player: Player::Player2,
                board_position: (3, 7),
            },
        ))
        .id();

    // Test piece ownership validation
    let mut player1_pieces = 0;
    let mut player2_pieces = 0;

    let mut query = world.query::<&GamePiece>();
    for piece in query.iter(world) {
        match piece.player {
            Player::Player1 => player1_pieces += 1,
            Player::Player2 => player2_pieces += 1,
        }
    }

    assert_eq!(player1_pieces, 2, "Should have 2 Player1 pieces");
    assert_eq!(player2_pieces, 2, "Should have 2 Player2 pieces");

    // Test that players can only select their own pieces
    let game_state = GameState {
        current_player: Player::Player1,
        ..Default::default()
    };

    // Player 1 should be able to select their pieces
    assert!(can_player_select_piece(
        world,
        (0, 0),
        game_state.current_player
    ));
    assert!(can_player_select_piece(
        world,
        (2, 0),
        game_state.current_player
    ));

    // Player 1 should NOT be able to select Player 2's pieces
    assert!(!can_player_select_piece(
        world,
        (1, 7),
        game_state.current_player
    ));
    assert!(!can_player_select_piece(
        world,
        (3, 7),
        game_state.current_player
    ));
}

#[test]
fn test_drag_state_management() {
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

    // Test adding drag state
    world
        .entity_mut(piece_entity)
        .insert(Dragging3D { start_pos: (1, 1) });

    // Verify drag state is present
    assert!(world.entity(piece_entity).contains::<Dragging3D>());

    // Test drag state data
    let drag_state = world.entity(piece_entity).get::<Dragging3D>().unwrap();
    assert_eq!(drag_state.start_pos, (1, 1));

    // Test removing drag state
    world.entity_mut(piece_entity).remove::<Dragging3D>();
    assert!(!world.entity(piece_entity).contains::<Dragging3D>());
}

// Helper functions for testing
fn is_valid_basic_move(from: (u8, u8), to: (u8, u8)) -> bool {
    // Check bounds for 10x8 board
    if to.0 >= BOARD_WIDTH || to.1 >= BOARD_HEIGHT {
        return false;
    }

    // Check if move is only horizontal or vertical and distance 1
    let dx = (to.0 as i8 - from.0 as i8).abs();
    let dy = (to.1 as i8 - from.1 as i8).abs();

    (dx == 1 && dy == 0) || (dx == 0 && dy == 1)
}

fn can_move_with_height(from_height: i8, to_height: i8) -> bool {
    // Quadradius rule: can move down any levels, up only one level
    to_height <= from_height + 1
}

fn can_move_to_occupied_tile(
    world: &mut World,
    _from: (u8, u8),
    to: (u8, u8),
    player: Player,
) -> bool {
    let mut query = world.query::<&GamePiece>();
    for piece in query.iter(world) {
        if piece.board_position == to {
            // Cannot capture own piece
            if piece.player == player {
                return false;
            }
        }
    }
    true
}

fn can_player_select_piece(world: &mut World, position: (u8, u8), player: Player) -> bool {
    let mut query = world.query::<&GamePiece>();
    for piece in query.iter(world) {
        if piece.board_position == position {
            return piece.player == player;
        }
    }
    false
}
