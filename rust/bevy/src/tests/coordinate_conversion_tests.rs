use crate::components::*;
use crate::systems::isometric_camera::*;

/// Test suite for coordinate conversion between screen space, world space, and board coordinates
/// Critical for accurate mouse interaction and piece placement

#[test]
fn test_board_to_isometric_conversion() {
    // Test conversion of board coordinates to isometric world positions

    // Test origin
    let origin = board_to_isometric((0, 0), 0.0);
    assert!(origin.x.is_finite(), "Origin X should be finite");
    assert!(origin.y.is_finite(), "Origin Y should be finite");
    assert!(origin.z.is_finite(), "Origin Z should be finite");

    // Test that height affects Y coordinate
    let ground = board_to_isometric((5, 4), 0.0);
    let elevated = board_to_isometric((5, 4), 2.0);
    assert!(
        elevated.y > ground.y,
        "Higher tiles should have higher Y coordinate"
    );

    // Test that different board positions produce different world positions
    let pos1 = board_to_isometric((0, 0), 0.0);
    let pos2 = board_to_isometric((1, 0), 0.0);
    let pos3 = board_to_isometric((0, 1), 0.0);

    assert_ne!(
        pos1, pos2,
        "Different board positions should produce different world positions"
    );
    assert_ne!(
        pos1, pos3,
        "Different board positions should produce different world positions"
    );
    assert_ne!(
        pos2, pos3,
        "Different board positions should produce different world positions"
    );
}

#[test]
fn test_board_coordinate_bounds() {
    // Test that all valid board coordinates produce valid world positions

    for x in 0..BOARD_WIDTH {
        for y in 0..BOARD_HEIGHT {
            let world_pos = board_to_isometric((x, y), 0.0);

            assert!(
                world_pos.x.is_finite(),
                "X coordinate should be finite for ({}, {})",
                x,
                y
            );
            assert!(
                world_pos.y.is_finite(),
                "Y coordinate should be finite for ({}, {})",
                x,
                y
            );
            assert!(
                world_pos.z.is_finite(),
                "Z coordinate should be finite for ({}, {})",
                x,
                y
            );

            // Test with various heights
            for height in -3..=5 {
                let elevated_pos = board_to_isometric((x, y), height as f32);
                assert!(elevated_pos.x.is_finite(), "Elevated X should be finite");
                assert!(elevated_pos.y.is_finite(), "Elevated Y should be finite");
                assert!(elevated_pos.z.is_finite(), "Elevated Z should be finite");
            }
        }
    }
}

#[test]
fn test_isometric_projection_consistency() {
    // Test that isometric projection produces consistent results

    // Test center of board
    let center_x = BOARD_WIDTH / 2;
    let center_y = BOARD_HEIGHT / 2;
    let center_pos = board_to_isometric((center_x, center_y), 0.0);

    // Center should be close to world origin after centering offset
    assert!(
        center_pos.x.abs() < TILE_SIZE * 2.0,
        "Center X should be near origin"
    );
    assert!(
        center_pos.z.abs() < TILE_SIZE * 2.0,
        "Center Z should be near origin"
    );

    // Test symmetry properties
    let corner1 = board_to_isometric((0, 0), 0.0);
    let corner2 = board_to_isometric((BOARD_WIDTH - 1, BOARD_HEIGHT - 1), 0.0);

    // These should be equidistant from center in some sense
    let dist1 = (corner1.x.powi(2) + corner1.z.powi(2)).sqrt();
    let dist2 = (corner2.x.powi(2) + corner2.z.powi(2)).sqrt();

    // Allow some tolerance for floating point math
    let diff = (dist1 - dist2).abs();
    assert!(
        diff < TILE_SIZE,
        "Opposite corners should be roughly equidistant from center"
    );
}

#[test]
fn test_height_scaling() {
    // Test that height scaling works correctly

    let base_pos = board_to_isometric((3, 3), 0.0);

    // Test various heights
    for height in 1..=10 {
        let raised_pos = board_to_isometric((3, 3), height as f32);

        // Y should increase with height
        assert!(
            raised_pos.y > base_pos.y,
            "Higher positions should have higher Y"
        );

        // X and Z should remain the same
        assert!(
            (raised_pos.x - base_pos.x).abs() < 0.001,
            "X should not change with height"
        );
        assert!(
            (raised_pos.z - base_pos.z).abs() < 0.001,
            "Z should not change with height"
        );
    }

    // Test negative heights
    for height in -5..0 {
        let lowered_pos = board_to_isometric((3, 3), height as f32);

        // Y should decrease with negative height
        assert!(
            lowered_pos.y < base_pos.y,
            "Lower positions should have lower Y"
        );
    }
}

#[test]
fn test_tile_spacing() {
    // Test that adjacent tiles have appropriate spacing

    let pos1 = board_to_isometric((0, 0), 0.0);
    let pos2 = board_to_isometric((1, 0), 0.0);
    let pos3 = board_to_isometric((0, 1), 0.0);

    // Calculate distances
    let horizontal_distance = (pos2 - pos1).length();
    let vertical_distance = (pos3 - pos1).length();

    // Distances should be reasonable relative to TILE_SIZE
    assert!(
        horizontal_distance > 0.0,
        "Adjacent tiles should have non-zero distance"
    );
    assert!(
        vertical_distance > 0.0,
        "Adjacent tiles should have non-zero distance"
    );

    // Should be roughly related to TILE_SIZE
    assert!(
        horizontal_distance < TILE_SIZE * 2.0,
        "Distance should be reasonable"
    );
    assert!(
        vertical_distance < TILE_SIZE * 2.0,
        "Distance should be reasonable"
    );
}

#[test]
fn test_coordinate_edge_cases() {
    // Test edge cases for coordinate conversion

    // Test maximum valid coordinates
    let max_pos = board_to_isometric((BOARD_WIDTH - 1, BOARD_HEIGHT - 1), 0.0);
    assert!(max_pos.x.is_finite(), "Max position X should be finite");
    assert!(max_pos.y.is_finite(), "Max position Y should be finite");
    assert!(max_pos.z.is_finite(), "Max position Z should be finite");

    // Test extreme heights
    let extreme_high = board_to_isometric((5, 4), 100.0);
    let extreme_low = board_to_isometric((5, 4), -100.0);

    assert!(
        extreme_high.x.is_finite(),
        "Extreme high X should be finite"
    );
    assert!(
        extreme_high.y.is_finite(),
        "Extreme high Y should be finite"
    );
    assert!(
        extreme_high.z.is_finite(),
        "Extreme high Z should be finite"
    );

    assert!(extreme_low.x.is_finite(), "Extreme low X should be finite");
    assert!(extreme_low.y.is_finite(), "Extreme low Y should be finite");
    assert!(extreme_low.z.is_finite(), "Extreme low Z should be finite");

    // Extreme high should be much higher than extreme low
    assert!(
        extreme_high.y > extreme_low.y + 100.0,
        "Height difference should be significant"
    );
}

#[test]
fn test_coordinate_determinism() {
    // Test that coordinate conversion is deterministic

    // Convert the same position multiple times
    let pos1 = board_to_isometric((4, 3), 1.5);
    let pos2 = board_to_isometric((4, 3), 1.5);
    let pos3 = board_to_isometric((4, 3), 1.5);

    // Should be exactly equal
    assert_eq!(pos1, pos2, "Coordinate conversion should be deterministic");
    assert_eq!(pos2, pos3, "Coordinate conversion should be deterministic");
    assert_eq!(pos1, pos3, "Coordinate conversion should be deterministic");

    // Test with different inputs
    for x in 0..BOARD_WIDTH {
        for y in 0..BOARD_HEIGHT {
            let result1 = board_to_isometric((x, y), 0.0);
            let result2 = board_to_isometric((x, y), 0.0);
            assert_eq!(
                result1, result2,
                "Results should be identical for ({}, {})",
                x, y
            );
        }
    }
}

#[test]
fn test_coordinate_precision() {
    // Test that coordinate conversion maintains reasonable precision

    let pos = board_to_isometric((1, 1), 0.0);

    // Values should not be NaN or infinite
    assert!(!pos.x.is_nan(), "X should not be NaN");
    assert!(!pos.y.is_nan(), "Y should not be NaN");
    assert!(!pos.z.is_nan(), "Z should not be NaN");

    assert!(!pos.x.is_infinite(), "X should not be infinite");
    assert!(!pos.y.is_infinite(), "Y should not be infinite");
    assert!(!pos.z.is_infinite(), "Z should not be infinite");

    // Values should be within reasonable bounds for a game world
    assert!(
        pos.x.abs() < 10000.0,
        "X should be within reasonable bounds"
    );
    assert!(
        pos.y.abs() < 10000.0,
        "Y should be within reasonable bounds"
    );
    assert!(
        pos.z.abs() < 10000.0,
        "Z should be within reasonable bounds"
    );
}

#[test]
fn test_isometric_transformation_properties() {
    // Test mathematical properties of the isometric transformation

    // Test that moving in X direction affects both world X and Z
    let origin = board_to_isometric((0, 0), 0.0);
    let x_step = board_to_isometric((1, 0), 0.0);
    let y_step = board_to_isometric((0, 1), 0.0);

    let x_delta = x_step - origin;
    let y_delta = y_step - origin;

    // X movement should affect both world X and Z coordinates in isometric projection
    assert_ne!(x_delta.x, 0.0, "X movement should affect world X");
    assert_ne!(x_delta.z, 0.0, "X movement should affect world Z");

    // Y movement should affect both world X and Z coordinates in isometric projection
    assert_ne!(y_delta.x, 0.0, "Y movement should affect world X");
    assert_ne!(y_delta.z, 0.0, "Y movement should affect world Z");

    // Height should only affect Y coordinate
    let elevated = board_to_isometric((0, 0), 1.0);
    let height_delta = elevated - origin;

    assert_eq!(height_delta.x, 0.0, "Height should not affect world X");
    assert!(height_delta.y > 0.0, "Height should increase world Y");
    assert_eq!(height_delta.z, 0.0, "Height should not affect world Z");
}
