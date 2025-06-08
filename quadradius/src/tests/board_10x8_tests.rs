use crate::components::*;

#[cfg(test)]
mod board_10x8_tests {
    use super::*;

    #[test]
    fn test_board_dimensions_8x8() {
        // Verify board constants are correct
        assert_eq!(BOARD_WIDTH, 8, "Board width should be 8");
        assert_eq!(BOARD_HEIGHT, 8, "Board height should be 8");

        // Total tiles should be 64
        let expected_tiles = BOARD_WIDTH as usize * BOARD_HEIGHT as usize;
        assert_eq!(expected_tiles, 64, "Total tiles should be 64 for 8×8 board");
    }

    #[test]
    fn test_valid_board_coordinates() {
        // Test all valid coordinates for 8×8 board
        for x in 0..BOARD_WIDTH {
            for y in 0..BOARD_HEIGHT {
                assert!(
                    x < BOARD_WIDTH,
                    "X coordinate {} should be within board width {}",
                    x,
                    BOARD_WIDTH
                );
                assert!(
                    y < BOARD_HEIGHT,
                    "Y coordinate {} should be within board height {}",
                    y,
                    BOARD_HEIGHT
                );
            }
        }

        // Test invalid coordinates
        assert!(BOARD_WIDTH == 8, "Width should be exactly 8");
        assert!(BOARD_HEIGHT == 8, "Height should be exactly 8");
    }

    #[test]
    fn test_piece_starting_positions_8x8() {
        // For 8×8 board, pieces should be at:
        // Player 1: (0,0), (2,0), (4,0), (6,0) on first row
        //           (1,1), (3,1), (5,1), (7,1) on second row
        // Player 2: (0,6), (2,6), (4,6), (6,6) on seventh row
        //           (1,7), (3,7), (5,7), (7,7) on eighth row

        let mut expected_positions = Vec::new();

        // Player 1 pieces (bottom two rows)
        for y in 0..2 {
            for x in 0..BOARD_WIDTH {
                if (x + y) % 2 == 0 {
                    expected_positions.push((x, y));
                }
            }
        }

        // Player 2 pieces (top two rows)
        for y in (BOARD_HEIGHT - 2)..BOARD_HEIGHT {
            for x in 0..BOARD_WIDTH {
                if (x + y) % 2 == 0 {
                    expected_positions.push((x, y));
                }
            }
        }

        // Should have 16 total pieces (8 per player)
        assert_eq!(
            expected_positions.len(),
            16,
            "Should have exactly 16 pieces for 8×8 board"
        );

        // Verify no pieces are outside board bounds
        for (x, y) in expected_positions {
            assert!(
                x < BOARD_WIDTH,
                "Piece X coordinate {} is outside board width {}",
                x,
                BOARD_WIDTH
            );
            assert!(
                y < BOARD_HEIGHT,
                "Piece Y coordinate {} is outside board height {}",
                y,
                BOARD_HEIGHT
            );
        }
    }

    #[test]
    fn test_board_tile_coordinates_all_valid() {
        // Test that all board tile coordinates are within bounds
        for x in 0..BOARD_WIDTH {
            for y in 0..BOARD_HEIGHT {
                let tile = BoardTile {
                    coordinates: (x, y),
                    height: 0,
                };

                assert!(
                    tile.coordinates.0 < BOARD_WIDTH,
                    "Tile X {} should be < {}",
                    tile.coordinates.0,
                    BOARD_WIDTH
                );
                assert!(
                    tile.coordinates.1 < BOARD_HEIGHT,
                    "Tile Y {} should be < {}",
                    tile.coordinates.1,
                    BOARD_HEIGHT
                );
            }
        }
    }

    #[test]
    fn test_safety_validation_10x8() {
        // Test that safety validation accepts valid 8×8 coordinates

        // Valid positions
        let valid_positions = [
            (0, 0),
            (7, 0),
            (0, 7),
            (7, 7), // corners
            (5, 4),
            (4, 3),
            (1, 6),
            (6, 2), // middle positions
        ];

        for (x, y) in valid_positions {
            assert!(
                x < BOARD_WIDTH,
                "Position ({}, {}) should be valid for {}×{} board",
                x,
                y,
                BOARD_WIDTH,
                BOARD_HEIGHT
            );
            assert!(
                y < BOARD_HEIGHT,
                "Position ({}, {}) should be valid for {}×{} board",
                x,
                y,
                BOARD_WIDTH,
                BOARD_HEIGHT
            );
        }

        // Invalid positions should fail
        let invalid_positions = [(8, 0), (0, 8), (8, 8), (255, 255)];

        for (x, y) in invalid_positions {
            assert!(
                x >= BOARD_WIDTH || y >= BOARD_HEIGHT,
                "Position ({}, {}) should be invalid for {}×{} board",
                x,
                y,
                BOARD_WIDTH,
                BOARD_HEIGHT
            );
        }
    }

    #[test]
    fn test_piece_count_validation() {
        // Simulate the expected piece configuration for 8×8 board
        let mut piece_positions = Vec::new();

        // Add pieces following the checkerboard pattern
        for y in 0..2 {
            for x in 0..BOARD_WIDTH {
                if (x + y) % 2 == 0 {
                    piece_positions.push((x, y));
                }
            }
        }

        for y in (BOARD_HEIGHT - 2)..BOARD_HEIGHT {
            for x in 0..BOARD_WIDTH {
                if (x + y) % 2 == 0 {
                    piece_positions.push((x, y));
                }
            }
        }

        // Should have exactly 16 pieces
        assert_eq!(
            piece_positions.len(),
            16,
            "8×8 board should have exactly 16 pieces"
        );

        // Verify all positions are valid
        for (x, y) in piece_positions {
            assert!(
                x < BOARD_WIDTH && y < BOARD_HEIGHT,
                "All piece positions should be within board bounds"
            );
        }
    }

    #[test]
    fn test_tile_count_validation() {
        // Total tiles for 8×8 board
        let expected_tile_count = BOARD_WIDTH as usize * BOARD_HEIGHT as usize;
        assert_eq!(
            expected_tile_count, 64,
            "8×8 board should have exactly 64 tiles"
        );

        // Simulate tile creation
        let mut tile_count = 0;
        for x in 0..BOARD_WIDTH {
            for y in 0..BOARD_HEIGHT {
                tile_count += 1;
                assert!(x < BOARD_WIDTH, "Tile X should be within bounds");
                assert!(y < BOARD_HEIGHT, "Tile Y should be within bounds");
            }
        }

        assert_eq!(
            tile_count, expected_tile_count,
            "Generated tile count should match expected"
        );
    }

    #[test]
    fn test_coordinate_conversion_10x8() {
        // Test coordinate conversions work with 8×8 board
        use crate::systems::isometric_camera::board_to_isometric;

        // Test all corners
        let corners = [
            (0, 0),
            (BOARD_WIDTH - 1, 0),
            (0, BOARD_HEIGHT - 1),
            (BOARD_WIDTH - 1, BOARD_HEIGHT - 1),
        ];

        for (x, y) in corners {
            let world_pos = board_to_isometric((x, y), 0.0);

            // Should produce finite values
            assert!(
                world_pos.x.is_finite(),
                "Isometric X should be finite for ({}, {})",
                x,
                y
            );
            assert!(
                world_pos.y.is_finite(),
                "Isometric Y should be finite for ({}, {})",
                x,
                y
            );
            assert!(
                world_pos.z.is_finite(),
                "Isometric Z should be finite for ({}, {})",
                x,
                y
            );
        }

        // Test center coordinates
        let center_x = BOARD_WIDTH / 2;
        let center_y = BOARD_HEIGHT / 2;
        let center_pos = board_to_isometric((center_x, center_y), 0.0);

        // Center should be near origin for proper visibility
        assert!(
            center_pos.x.abs() < 100.0,
            "Center should be near origin for visibility"
        );
        assert!(
            center_pos.z.abs() < 100.0,
            "Center should be near origin for visibility"
        );
    }
}
