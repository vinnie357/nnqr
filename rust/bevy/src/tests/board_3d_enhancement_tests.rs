use crate::components::*;
use crate::systems::board_3d::*;
use crate::systems::isometric_camera::board_to_isometric;
use bevy::prelude::*;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_enhanced_tile_height_multiplier() {
        // Test that height differences are more dramatic
        let height_0 = board_to_isometric((5, 5), 0.0);
        let height_1 = board_to_isometric((5, 5), 1.0);
        let height_2 = board_to_isometric((5, 5), 2.0);
        
        // Height difference should be at least 0.4 units per level (increased from 0.15)
        let diff_1 = (height_1.y - height_0.y).abs();
        let diff_2 = (height_2.y - height_1.y).abs();
        
        assert!(diff_1 >= 0.4, "Height difference between levels should be at least 0.4 units, got {}", diff_1);
        assert!(diff_2 >= 0.4, "Height difference between levels should be at least 0.4 units, got {}", diff_2);
    }

    #[test]
    fn test_tile_size_enhancement() {
        // Verify that enhanced tile size is properly applied
        let enhanced_size = TILE_SIZE * TILE_SIZE_MULTIPLIER_3D;
        assert!(enhanced_size > TILE_SIZE * 1.4, "3D tiles should be at least 40% larger");
        assert!(enhanced_size < TILE_SIZE * 2.0, "3D tiles shouldn't be too large");
    }

    #[test]
    fn test_height_multiplier_constants() {
        // Verify the enhanced constants are set correctly
        assert_eq!(TILE_SIZE_MULTIPLIER_3D, 1.5, "Tile size multiplier should be 1.5");
        assert_eq!(HEIGHT_MULTIPLIER_3D, 0.5, "Height multiplier should be 0.5");
        assert_eq!(GRID_LINE_THICKNESS, 0.02, "Grid line thickness should be 0.02");
        assert_eq!(BORDER_THICKNESS_3D, 0.15, "Border thickness should be 0.15");
    }
}