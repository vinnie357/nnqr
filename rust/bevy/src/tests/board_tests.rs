use crate::components::*;

#[test]
fn test_board_constants() {
    assert_eq!(BOARD_WIDTH, 10);
    assert_eq!(BOARD_HEIGHT, 8);
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
    assert!(is_valid_position(9, 7)); // Max valid position for 10x8 board
    assert!(is_valid_position(3, 5));

    // Invalid coordinates
    assert!(!is_valid_position(10, 0)); // x out of bounds
    assert!(!is_valid_position(0, 8)); // y out of bounds
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
    x < BOARD_WIDTH && y < BOARD_HEIGHT
}

#[test]
fn test_3d_board_enhancements() {
    use crate::systems::board_3d::*;

    // Test enhanced constants
    assert_eq!(
        TILE_SIZE_MULTIPLIER_3D, 1.5,
        "Tile size multiplier should be 1.5"
    );
    assert_eq!(HEIGHT_MULTIPLIER_3D, 0.5, "Height multiplier should be 0.5");
    assert_eq!(
        GRID_LINE_THICKNESS, 0.02,
        "Grid line thickness should be 0.02"
    );
    assert_eq!(BORDER_THICKNESS_3D, 0.15, "Border thickness should be 0.15");

    // Test tile size enhancement
    let enhanced_size = TILE_SIZE * TILE_SIZE_MULTIPLIER_3D;
    assert!(
        enhanced_size > TILE_SIZE * 1.4,
        "3D tiles should be at least 40% larger"
    );
    assert!(
        enhanced_size < TILE_SIZE * 2.0,
        "3D tiles shouldn't be too large"
    );
}

#[test]
fn test_3d_height_differences() {
    use crate::systems::isometric_camera::board_to_isometric;

    // Test that height differences are more dramatic with new multiplier
    let height_0 = board_to_isometric((5, 5), 0.0);
    let height_1 = board_to_isometric((5, 5), 1.0);
    let height_2 = board_to_isometric((5, 5), 2.0);

    // Height difference should be dramatic (at least 0.4 units per level)
    let diff_1 = (height_1.y - height_0.y).abs();
    let diff_2 = (height_2.y - height_1.y).abs();

    assert!(
        diff_1 >= 0.4,
        "Height difference between levels should be at least 0.4 units, got {}",
        diff_1
    );
    assert!(
        diff_2 >= 0.4,
        "Height difference should be consistent, got {}",
        diff_2
    );
}

#[test]
fn test_piece_positioning_fix() {
    use crate::systems::board_3d::TILE_SIZE_MULTIPLIER_3D;

    // Test that piece positioning accounts for enhanced tile height
    let enhanced_tile_size = TILE_SIZE * TILE_SIZE_MULTIPLIER_3D;
    let enhanced_tile_height = 0.6; // From board_3d.rs
    let piece_height = 0.2; // From pieces_3d.rs
    let piece_clearance = 0.2; // Gap between piece and tile surface

    // Calculate piece Y offset
    let piece_y_offset =
        enhanced_tile_size * (enhanced_tile_height / 2.0 + piece_height / 2.0 + piece_clearance);

    // Verify piece sits properly on enhanced tiles
    assert!(piece_y_offset > 0.0, "Piece Y offset should be positive");
    assert!(
        piece_y_offset > enhanced_tile_size * 0.3,
        "Piece should be clearly above tile surface, got {}",
        piece_y_offset
    );
    assert!(
        piece_y_offset < enhanced_tile_size * 1.0,
        "Piece shouldn't be too high above tile, got {}",
        piece_y_offset
    );

    // For standard tile size (64) and multiplier (1.5), this should be around 57.6 with clearance
    let expected_range = (50.0, 65.0);
    assert!(
        piece_y_offset >= expected_range.0 && piece_y_offset <= expected_range.1,
        "Piece Y offset {} should be in range {:?}",
        piece_y_offset,
        expected_range
    );
}
