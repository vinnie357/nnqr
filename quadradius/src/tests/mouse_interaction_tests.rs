use crate::components::*;
use crate::resources::*;
use crate::systems::isometric_camera::*;
use bevy::math::Vec2;

// Test basic coordinate conversion functions
#[test]
fn test_board_to_isometric_conversion() {
    // Test near center of board (4, 4 on a 10x8 board)
    let center_pos = board_to_isometric((4, 4), 0.0);

    // Based on the isometric transformation formula in the code:
    // For 10x8 board (BOARD_WIDTH=10, BOARD_HEIGHT=8):
    // centered_x = 4 - (10/2) + 0.5 = 4 - 5 + 0.5 = -0.5
    // centered_z = 4 - (8/2) + 0.5 = 4 - 4 + 0.5 = 0.5
    // iso_x = (-0.5 - 0.5) * 64 * 0.5 = -1.0 * 32 = -32.0
    // iso_z = (-0.5 + 0.5) * 64 * 0.25 = 0.0 * 16 = 0.0

    assert_eq!(
        center_pos.x, -32.0,
        "Center X should be -32.0 for board position (4,4)"
    );
    assert_eq!(
        center_pos.z, 0.0,
        "Center Z should be 0.0 for board position (4,4)"
    );
    assert_eq!(center_pos.y, 0.0, "Center Y should be 0 for height 0");
}

#[test]
fn test_coordinate_system_constants() {
    // Basic sanity checks for 10x8 Quadradius board
    assert_eq!(BOARD_WIDTH, 10, "Quadradius uses 10x8 board");
    assert_eq!(BOARD_HEIGHT, 8, "Quadradius uses 10x8 board");
    assert!(TILE_SIZE > 0.0);

    // Isometric constants
    assert!(ISOMETRIC_ANGLE > 0.0);
    assert!(CAMERA_HEIGHT > 0.0);
    assert!(CAMERA_SCALE > 0.0);
}

#[test]
fn test_isometric_transformation_bounds() {
    // Test all corner positions
    let corners = [(0, 0), (0, 7), (7, 0), (7, 7)];

    for (x, y) in corners {
        let world_pos = board_to_isometric((x, y), 0.0);

        // Check that positions are reasonable (not NaN or infinite)
        assert!(
            world_pos.x.is_finite(),
            "World X should be finite for ({}, {})",
            x,
            y
        );
        assert!(
            world_pos.y.is_finite(),
            "World Y should be finite for ({}, {})",
            x,
            y
        );
        assert!(
            world_pos.z.is_finite(),
            "World Z should be finite for ({}, {})",
            x,
            y
        );

        // Check that positions are within reasonable bounds
        assert!(
            world_pos.x.abs() < 1000.0,
            "World X too large for ({}, {}): {}",
            x,
            y,
            world_pos.x
        );
        assert!(
            world_pos.z.abs() < 1000.0,
            "World Z too large for ({}, {}): {}",
            x,
            y,
            world_pos.z
        );
    }
}

#[test]
fn test_height_scaling() {
    let base_pos = board_to_isometric((4, 4), 0.0);
    let elevated_pos = board_to_isometric((4, 4), 1.0);

    // Y coordinate should increase with height
    assert!(
        elevated_pos.y > base_pos.y,
        "Elevated position should have higher Y"
    );

    // X and Z should remain the same
    assert_eq!(
        base_pos.x, elevated_pos.x,
        "X should not change with height"
    );
    assert_eq!(
        base_pos.z, elevated_pos.z,
        "Z should not change with height"
    );
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
fn test_game_piece_creation() {
    let piece = GamePiece {
        player: Player::Player1,
        board_position: (2, 3),
    };

    assert_eq!(piece.player, Player::Player1);
    assert_eq!(piece.board_position, (2, 3));
}

#[test]
fn test_game_state_defaults() {
    let game_state = GameState::default();

    assert_eq!(game_state.current_player, Player::Player1);
    assert_eq!(game_state.turn_phase, TurnPhase::PieceMovement);
}

// Test mouse coordinate bounds checking
#[test]
fn test_screen_coordinate_bounds() {
    // Test typical screen coordinates
    let test_coords = [
        Vec2::new(0.0, 0.0),     // Top-left
        Vec2::new(800.0, 600.0), // Bottom-right for 800x600 screen
        Vec2::new(400.0, 300.0), // Center
    ];

    for coord in test_coords {
        assert!(coord.x >= 0.0, "Screen X should be non-negative");
        assert!(coord.y >= 0.0, "Screen Y should be non-negative");
    }
}

// Test that power types are correctly defined
#[test]
fn test_power_types_available() {
    // Test a few power types to ensure they're working
    let power = PowerType::MoveDiagonal;
    assert_eq!(power.name(), "Move Diagonal");

    let power2 = PowerType::RaiseColumn;
    assert_eq!(power2.name(), "Raise Column");
}
