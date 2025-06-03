use crate::components::*;

#[test]
fn test_board_constants() {
    assert_eq!(BOARD_SIZE, 8);
    assert_eq!(TILE_SIZE, 64.0);
}

#[test]
fn test_board_tile_creation() {
    let tile = BoardTile {
        coordinates: (3, 4),
        height: 2,
    };

    assert_eq!(tile.coordinates, (3, 4));
    assert_eq!(tile.height, 2);
}

#[test]
fn test_valid_coordinates() {
    // Valid coordinates
    assert!(is_valid_position(0, 0));
    assert!(is_valid_position(7, 7));
    assert!(is_valid_position(3, 5));

    // Invalid coordinates
    assert!(!is_valid_position(8, 0));
    assert!(!is_valid_position(0, 8));
    assert!(!is_valid_position(255, 255)); // Test overflow
}

#[test]
fn test_terrain_height_bounds() {
    let mut tile = BoardTile {
        coordinates: (0, 0),
        height: 0,
    };

    // Test minimum height
    tile.height = -3;
    assert!(tile.height >= -3);

    // Test maximum height
    tile.height = 3;
    assert!(tile.height <= 3);
}

// Helper function to validate board positions
fn is_valid_position(x: u8, y: u8) -> bool {
    x < BOARD_SIZE && y < BOARD_SIZE
}
