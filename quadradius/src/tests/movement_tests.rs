use crate::components::*;
use crate::resources::*;
use bevy::prelude::*;

#[test]
fn test_basic_movement_rules() {
    let mut app = App::new();
    app.insert_resource(GameState::default());
    app.add_plugins(MinimalPlugins);

    let mut world = app.world;

    // Create test board tiles
    for x in 0..BOARD_SIZE {
        for y in 0..BOARD_SIZE {
            world.spawn(BoardTile {
                coordinates: (x, y),
                height: 0,
            });
        }
    }

    // Test horizontal movement
    assert!(is_valid_basic_move((0, 0), (0, 1)));
    assert!(is_valid_basic_move((0, 0), (1, 0)));

    // Test invalid diagonal movement
    assert!(!is_valid_basic_move((0, 0), (1, 1)));

    // Test invalid distance
    assert!(!is_valid_basic_move((0, 0), (0, 2)));
    assert!(!is_valid_basic_move((0, 0), (2, 0)));

    // Test out of bounds
    assert!(!is_valid_basic_move((7, 7), (8, 7)));
    assert!(!is_valid_basic_move((7, 7), (7, 8)));
}

#[test]
fn test_height_movement_restrictions() {
    // Can move up one level
    assert!(can_move_with_height(0, 1));

    // Cannot move up two levels
    assert!(!can_move_with_height(0, 2));

    // Can always move down
    assert!(can_move_with_height(3, 0));
    assert!(can_move_with_height(2, -1));

    // Can move to same height
    assert!(can_move_with_height(1, 1));
}

#[test]
fn test_occupied_tile_blocking() {
    let mut app = App::new();
    app.add_plugins(MinimalPlugins);

    let mut world = app.world;

    // Create two pieces on the board
    let _piece1 = world
        .spawn(GamePiece {
            player: Player::Player1,
            board_position: (0, 0),
        })
        .id();

    let _piece2 = world
        .spawn(GamePiece {
            player: Player::Player2,
            board_position: (0, 1),
        })
        .id();

    let _piece3 = world
        .spawn(GamePiece {
            player: Player::Player1,
            board_position: (1, 0),
        })
        .id();

    // Cannot move to tile occupied by same player
    assert!(!can_move_to_occupied_tile(
        &mut world,
        (0, 0),
        (1, 0),
        Player::Player1
    ));

    // Can capture opponent piece
    assert!(can_move_to_occupied_tile(
        &mut world,
        (0, 0),
        (0, 1),
        Player::Player1
    ));
}

// Helper functions for testing
fn is_valid_basic_move(from: (u8, u8), to: (u8, u8)) -> bool {
    // Check bounds
    if to.0 >= BOARD_SIZE || to.1 >= BOARD_SIZE {
        return false;
    }

    // Check if move is only horizontal or vertical and distance 1
    let dx = (to.0 as i8 - from.0 as i8).abs();
    let dy = (to.1 as i8 - from.1 as i8).abs();

    (dx == 1 && dy == 0) || (dx == 0 && dy == 1)
}

fn can_move_with_height(from_height: i8, to_height: i8) -> bool {
    // Can move down any levels, up only one level
    to_height <= from_height + 1
}

fn can_move_to_occupied_tile(
    world: &mut World,
    _from: (u8, u8),
    to: (u8, u8),
    player: Player,
) -> bool {
    // Check all pieces
    let mut query = world.query::<(Entity, &GamePiece)>();
    for (_entity, piece) in query.iter(world) {
        if piece.board_position == to {
            // Cannot capture own piece
            if piece.player == player {
                return false;
            }
        }
    }
    true
}
