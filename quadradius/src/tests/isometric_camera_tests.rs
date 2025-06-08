use crate::systems::isometric_camera::*;
use crate::components::{BOARD_WIDTH, BOARD_HEIGHT};

#[cfg(test)]
mod isometric_tests {
    use super::*;

    #[test]
    fn test_board_to_isometric_conversion() {
        // Test conversion from board coordinates to isometric world position
        // For 10x8 board, center is (5, 4)
        let center_pos = board_to_isometric((BOARD_WIDTH / 2, BOARD_HEIGHT / 2), 0.0);
        let corner_pos = board_to_isometric((0, 0), 0.0);
        let opposite_corner = board_to_isometric((BOARD_WIDTH - 1, BOARD_HEIGHT - 1), 0.0);

        // Center should be near origin (allowing for isometric transform)
        assert!(center_pos.x.abs() < 100.0); // Increased tolerance for 10x8 board
        assert!(center_pos.z.abs() < 100.0);
        assert_eq!(center_pos.y, 0.0);

        // Corners should be different
        assert_ne!(corner_pos, opposite_corner);
        assert_ne!(corner_pos, center_pos);
    }

    #[test]
    fn test_height_affects_y_coordinate() {
        let base_pos = board_to_isometric((4, 4), 0.0);
        let elevated_pos = board_to_isometric((4, 4), 2.0);

        // Higher tiles should have higher Y coordinates
        assert!(elevated_pos.y > base_pos.y);
        
        // X and Z should remain the same
        assert_eq!(base_pos.x, elevated_pos.x);
        assert_eq!(base_pos.z, elevated_pos.z);
    }

    #[test]
    fn test_isometric_constants() {
        // Validate isometric constants are reasonable
        assert!(ISOMETRIC_ANGLE > 0.0);
        assert!(ISOMETRIC_ANGLE < 90.0);
        assert!(CAMERA_HEIGHT > 0.0);
        assert!(CAMERA_SCALE > 0.0);
    }

    #[test]
    fn test_board_coordinate_bounds() {
        // Test that all valid board coordinates convert without panic
        for x in 0..BOARD_WIDTH {
            for y in 0..BOARD_HEIGHT {
                let pos = board_to_isometric((x, y), 1.0);
                
                // Should produce finite values
                assert!(pos.x.is_finite());
                assert!(pos.y.is_finite());
                assert!(pos.z.is_finite());
            }
        }
    }

    #[test]
    fn test_negative_heights() {
        // Test that negative heights (bomb craters) work correctly
        let normal_pos = board_to_isometric((4, 4), 0.0);
        let crater_pos = board_to_isometric((4, 4), -1.0);

        // Crater should be below normal level
        assert!(crater_pos.y < normal_pos.y);
    }
}