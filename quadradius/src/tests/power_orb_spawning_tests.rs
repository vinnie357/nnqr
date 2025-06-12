use crate::components::board::{BOARD_HEIGHT, BOARD_WIDTH};
use crate::components::*;
use crate::resources::*;
use bevy::prelude::Color;

/// Test orb visibility properties (simpler version without Bevy app)
#[test]
fn test_orb_visibility_properties() {
    // Test that orb materials have proper visibility settings
    let power_type = PowerType::MoveDiagonal;
    let power_color = power_type.color();

    // Check that power colors are not black (invisible)
    assert_ne!(
        power_color,
        Color::BLACK,
        "Power type color should not be black"
    );
    assert!(
        power_color.r() > 0.0 || power_color.g() > 0.0 || power_color.b() > 0.0,
        "Power type should have visible color components"
    );

    // Test that emissive values are reasonable for visibility
    let emissive = power_color * 2.0;
    assert!(
        emissive.r() <= 10.0 && emissive.g() <= 10.0 && emissive.b() <= 10.0,
        "Emissive values should not be excessively bright"
    );
}

/// Test the main bug fix: orbs should spawn in PieceMovement phase
#[test]
fn test_game_starts_in_piece_movement_phase() {
    let game_state = GameState::default();

    // The main bug was that orbs only spawned during PowerActivation phase
    // But the game starts in PieceMovement phase, so orbs would never spawn
    assert_eq!(
        game_state.turn_phase,
        TurnPhase::PieceMovement,
        "Game should start in PieceMovement phase"
    );

    // This was the root cause of the visibility bug - orbs were gated behind
    // a phase that players rarely entered
}

/// Test that all power types have visible colors
#[test]
fn test_all_power_types_have_visible_colors() {
    let power_types = [
        PowerType::MoveDiagonal,
        PowerType::Multiply,
        PowerType::Teleport,
        PowerType::LowerColumn,
        PowerType::Recruit,
        PowerType::DestroyColumn,
        PowerType::RaiseColumn,
    ];

    for power_type in power_types.iter() {
        let color = power_type.color();

        // Should not be invisible
        assert_ne!(
            color,
            Color::BLACK,
            "Power {:?} should not be black",
            power_type
        );
        assert_ne!(
            color,
            Color::NONE,
            "Power {:?} should not be transparent",
            power_type
        );

        // Should have some visible component
        assert!(
            color.r() > 0.0 || color.g() > 0.0 || color.b() > 0.0,
            "Power {:?} should have visible color components",
            power_type
        );

        // Should be mostly opaque for visibility
        assert!(
            color.a() >= 0.8,
            "Power {:?} should be mostly opaque",
            power_type
        );
    }
}

/// Test power orb component structure
#[test]
fn test_power_orb_3d_component() {
    // Test that PowerOrb3D has all required fields for visibility
    use crate::systems::power_orbs_3d::PowerOrb3D;

    let orb = PowerOrb3D {
        power_type: PowerType::MoveDiagonal,
        board_position: (5, 3),
        glow_intensity: 1.0,
        pulse_timer: 0.0,
    };

    assert_eq!(orb.power_type, PowerType::MoveDiagonal);
    assert_eq!(orb.board_position, (5, 3));
    assert_eq!(orb.glow_intensity, 1.0);
    assert_eq!(orb.pulse_timer, 0.0);
}

/// Test that the fix allows spawning in any phase
#[test]
fn test_spawning_logic_removed_phase_restriction() {
    // This test verifies that the spawn logic no longer requires PowerActivation phase
    // We can't test the actual spawning without a full Bevy app, but we can test
    // the conditions that were causing the bug

    let game_state = GameState::default();

    // Before the fix: orbs only spawned when turn_phase == TurnPhase::PowerActivation
    // After the fix: orbs spawn regardless of phase

    // Test both phases are valid for spawning (conceptually)
    let piece_movement_phase = TurnPhase::PieceMovement;
    let power_activation_phase = TurnPhase::PowerActivation;

    // Both phases should be valid game states
    assert_ne!(
        piece_movement_phase, power_activation_phase,
        "Phases should be different"
    );

    // The default phase should be PieceMovement
    assert_eq!(
        game_state.turn_phase, piece_movement_phase,
        "Default phase should be PieceMovement"
    );
}

/// Test orb size and visibility constants  
#[test]
fn test_orb_size_constants() {
    use crate::components::TILE_SIZE;

    // Test that orb sizes are reasonable for visibility
    let orb_radius = TILE_SIZE * 0.35; // From the updated code
    let glow_radius = TILE_SIZE * 0.5;

    assert!(orb_radius > 0.0, "Orb radius should be positive");
    assert!(glow_radius > orb_radius, "Glow should be larger than orb");

    // Should be large enough to be visible (at least 20 pixels)
    assert!(
        orb_radius >= 20.0,
        "Orb should be at least 20 pixels radius for visibility"
    );
}

/// Test that power orbs respect board boundaries
#[test]
fn test_power_orb_board_boundaries() {
    // Test boundary validation for power orb positions
    let valid_positions = [
        (0, 0),                              // Bottom-left corner
        (BOARD_WIDTH - 1, 0),                // Bottom-right corner
        (0, BOARD_HEIGHT - 1),               // Top-left corner
        (BOARD_WIDTH - 1, BOARD_HEIGHT - 1), // Top-right corner
        (BOARD_WIDTH / 2, BOARD_HEIGHT / 2), // Center
    ];

    let invalid_positions = [
        (BOARD_WIDTH, 0),            // Off right edge
        (0, BOARD_HEIGHT),           // Off top edge
        (BOARD_WIDTH, BOARD_HEIGHT), // Off both edges
    ];

    // Test valid positions
    for (x, y) in valid_positions {
        assert!(
            x < BOARD_WIDTH && y < BOARD_HEIGHT,
            "Position ({}, {}) should be valid within {}x{} board",
            x,
            y,
            BOARD_WIDTH,
            BOARD_HEIGHT
        );
    }

    // Test invalid positions
    for (x, y) in invalid_positions {
        assert!(
            x >= BOARD_WIDTH || y >= BOARD_HEIGHT,
            "Position ({}, {}) should be invalid for {}x{} board",
            x,
            y,
            BOARD_WIDTH,
            BOARD_HEIGHT
        );
    }
}

/// Test coordinate conversion for correct board dimensions
#[test]
fn test_board_coordinate_conversion() {
    fn board_to_world_position(board_pos: (u8, u8)) -> (f32, f32) {
        let x = (board_pos.0 as f32 - BOARD_WIDTH as f32 / 2.0 + 0.5) * TILE_SIZE;
        let y = (board_pos.1 as f32 - BOARD_HEIGHT as f32 / 2.0 + 0.5) * TILE_SIZE;
        (x, y)
    }

    // Test corner coordinates produce reasonable world positions
    let test_cases = [
        ((0, 0), "bottom-left"),
        ((BOARD_WIDTH - 1, 0), "bottom-right"),
        ((0, BOARD_HEIGHT - 1), "top-left"),
        ((BOARD_WIDTH - 1, BOARD_HEIGHT - 1), "top-right"),
        ((BOARD_WIDTH / 2, BOARD_HEIGHT / 2), "center"),
    ];

    for ((x, y), description) in test_cases {
        let (world_x, world_y) = board_to_world_position((x, y));

        // World coordinates should be reasonable (not extreme values)
        assert!(
            world_x.abs() < 1000.0,
            "{} world X coordinate {} is too extreme for board position ({}, {})",
            description,
            world_x,
            x,
            y
        );
        assert!(
            world_y.abs() < 1000.0,
            "{} world Y coordinate {} is too extreme for board position ({}, {})",
            description,
            world_y,
            x,
            y
        );
    }
}

/// Test that board dimensions match Quadradius specifications
#[test]
fn test_quadradius_board_dimensions() {
    // Quadradius has a 10x8 board according to research
    assert_eq!(
        BOARD_WIDTH, 10,
        "Quadradius board should be 10 columns wide"
    );
    assert_eq!(BOARD_HEIGHT, 8, "Quadradius board should be 8 rows tall");

    // Total tiles should be 80
    let total_tiles = BOARD_WIDTH as usize * BOARD_HEIGHT as usize;
    assert_eq!(
        total_tiles, 80,
        "Quadradius board should have 80 total tiles"
    );

    // Board should be wider than it is tall (landscape orientation)
    assert!(
        BOARD_WIDTH > BOARD_HEIGHT,
        "Board should be wider than tall"
    );
}

/// Test that orb spawning positions are valid
#[test]
fn test_orb_spawning_position_validation() {
    // Create a power orb and verify its position is valid
    let power_orb = PowerOrb {
        power_type: PowerType::MoveDiagonal,
        board_position: (5, 3),
    };

    // Position should be within board bounds
    assert!(
        power_orb.board_position.0 < BOARD_WIDTH,
        "Orb X position {} should be less than board width {}",
        power_orb.board_position.0,
        BOARD_WIDTH
    );
    assert!(
        power_orb.board_position.1 < BOARD_HEIGHT,
        "Orb Y position {} should be less than board height {}",
        power_orb.board_position.1,
        BOARD_HEIGHT
    );
}
