use crate::components::*;
use crate::resources::*;
use crate::systems::isometric_camera::board_to_isometric;
use bevy::prelude::*;

#[cfg(test)]
mod integration_tests {
    use super::*;

    #[test]
    fn test_correct_board_dimensions() {
        // Verify the board uses correct Quadradius dimensions (10x8)
        assert_eq!(BOARD_WIDTH, 10);
        assert_eq!(BOARD_HEIGHT, 8);

        // Total tile count should be 80 (10x8)
        let total_tiles = BOARD_WIDTH as u16 * BOARD_HEIGHT as u16;
        assert_eq!(total_tiles, 80);
    }

    #[test]
    fn test_all_board_positions_have_theme_colors() {
        // Test that every position on the 8x8 board gets a theme color
        for x in 0..BOARD_WIDTH {
            for y in 0..BOARD_HEIGHT {
                for height in -2..5 {
                    let color = QuadradiusTheme::tile_color_for_height(height);

                    // Should not be black (indicating unset)
                    assert_ne!(color, Color::BLACK);

                    // Should be a valid color
                    assert!(color.r().is_finite());
                    assert!(color.g().is_finite());
                    assert!(color.b().is_finite());
                    assert!(color.a().is_finite());
                }
            }
        }
    }

    #[test]
    fn test_piece_positions_on_new_board() {
        // Test that pieces can be placed on all valid positions of 8x8 board

        // Player 1 starting positions (bottom 2 rows, checkerboard)
        let mut player1_positions = Vec::new();
        for y in 0..2 {
            for x in 0..BOARD_WIDTH {
                if (x + y) % 2 == 0 {
                    player1_positions.push((x, y));
                }
            }
        }

        // Player 2 starting positions (top 2 rows, checkerboard)
        let mut player2_positions = Vec::new();
        for y in (BOARD_HEIGHT - 2)..BOARD_HEIGHT {
            for x in 0..BOARD_WIDTH {
                if (x + y) % 2 == 0 {
                    player2_positions.push((x, y));
                }
            }
        }

        // Should have same number of pieces for each player
        assert_eq!(player1_positions.len(), player2_positions.len());

        // Should have reasonable number of pieces (10 for 10x8 board, 2 rows each)
        assert_eq!(player1_positions.len(), 10);

        // No overlapping positions
        for p1_pos in &player1_positions {
            assert!(!player2_positions.contains(p1_pos));
        }
    }

    #[test]
    fn test_isometric_coordinates_for_rectangular_board() {
        // Test isometric conversion works for 10x8 board
        let corner_tl = board_to_isometric((0, 0), 0.0);
        let corner_tr = board_to_isometric((BOARD_WIDTH - 1, 0), 0.0);
        let corner_bl = board_to_isometric((0, BOARD_HEIGHT - 1), 0.0);
        let corner_br = board_to_isometric((BOARD_WIDTH - 1, BOARD_HEIGHT - 1), 0.0);

        // All corners should be different
        assert_ne!(corner_tl, corner_tr);
        assert_ne!(corner_tl, corner_bl);
        assert_ne!(corner_tl, corner_br);
        assert_ne!(corner_tr, corner_bl);
        assert_ne!(corner_tr, corner_br);
        assert_ne!(corner_bl, corner_br);

        // Should form a reasonable board shape (wider than tall in isometric)
        let width_span = (corner_tr.x - corner_tl.x)
            .abs()
            .max((corner_br.x - corner_bl.x).abs());
        let height_span = (corner_bl.y - corner_tl.y)
            .abs()
            .max((corner_br.y - corner_tr.y).abs());

        // Since the board is 10x8 (wider), the width span should be larger
        assert!(width_span > height_span);
    }

    #[test]
    fn test_metallic_theme_consistency() {
        // Test that all major UI elements use consistent metallic theme
        let ui_colors = [
            QuadradiusTheme::UI_BACKGROUND,
            QuadradiusTheme::UI_PANEL,
            QuadradiusTheme::UI_BORDER,
        ];

        let piece_colors = [
            QuadradiusTheme::TEAM_1_PRIMARY,
            QuadradiusTheme::TEAM_2_PRIMARY,
        ];

        let orb_colors = [
            QuadradiusTheme::ORB_BASE,
            QuadradiusTheme::ORB_GLOW,
            QuadradiusTheme::ORB_HIGHLIGHT,
        ];

        // All colors should be defined (not black)
        for color in ui_colors
            .iter()
            .chain(piece_colors.iter())
            .chain(orb_colors.iter())
        {
            assert_ne!(*color, Color::BLACK);
            assert!(color.r() >= 0.0 && color.r() <= 1.0);
            assert!(color.g() >= 0.0 && color.g() <= 1.0);
            assert!(color.b() >= 0.0 && color.b() <= 1.0);
            assert!(color.a() >= 0.0 && color.a() <= 1.0);
        }

        // Team colors should be distinguishable
        let team1 = QuadradiusTheme::TEAM_1_PRIMARY;
        let team2 = QuadradiusTheme::TEAM_2_PRIMARY;
        let color_distance = ((team1.r() - team2.r()).powi(2)
            + (team1.g() - team2.g()).powi(2)
            + (team1.b() - team2.b()).powi(2))
        .sqrt();
        assert!(color_distance > 0.3, "Team colors too similar");
    }

    #[test]
    fn test_render_config_integration() {
        // Test that render config works with default settings
        let config = RenderConfig::default();
        assert!(!config.use_3d); // Currently defaults to 2D mode for debugging

        // Test 2D fallback
        let config_2d = RenderConfig::new_2d();
        assert!(!config_2d.use_3d);

        // Test explicit 3D
        let config_3d = RenderConfig::new_3d();
        assert!(config_3d.use_3d);
    }

    #[test]
    fn test_power_orb_uses_metallic_appearance() {
        // Verify power orbs use metallic base color instead of power-specific colors
        let orb_color = QuadradiusTheme::ORB_BASE;

        // Should look metallic (balanced RGB, not oversaturated)
        let max_component = orb_color.r().max(orb_color.g()).max(orb_color.b());
        let min_component = orb_color.r().min(orb_color.g()).min(orb_color.b());
        let saturation = max_component - min_component;

        // Metallic colors should be relatively neutral/unsaturated
        assert!(
            saturation < 0.5,
            "Orb base color too saturated for metallic appearance"
        );

        // Should be in middle range (not pure black or white)
        assert!(max_component > 0.3 && max_component < 0.9);
    }
}
