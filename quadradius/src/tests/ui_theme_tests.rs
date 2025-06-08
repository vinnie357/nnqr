use crate::resources::QuadradiusTheme;
use bevy::prelude::*;

#[cfg(test)]
mod theme_tests {
    use super::*;

    #[test]
    fn test_metallic_theme_colors() {
        // Test that metallic colors are properly defined
        assert_ne!(QuadradiusTheme::METAL_SILVER, Color::BLACK);
        assert_ne!(QuadradiusTheme::METAL_GUNMETAL, Color::BLACK);
        assert_ne!(QuadradiusTheme::TEAM_1_PRIMARY, Color::BLACK);
        assert_ne!(QuadradiusTheme::TEAM_2_PRIMARY, Color::BLACK);
    }

    #[test]
    fn test_team_colors_different() {
        // Ensure team colors are distinct
        assert_ne!(QuadradiusTheme::TEAM_1_PRIMARY, QuadradiusTheme::TEAM_2_PRIMARY);
        assert_ne!(QuadradiusTheme::TEAM_1_ACCENT, QuadradiusTheme::TEAM_2_ACCENT);
    }

    #[test]
    fn test_tile_height_colors() {
        // Test height-based tile coloring
        let base_color = QuadradiusTheme::tile_color_for_height(0);
        let elevated_color = QuadradiusTheme::tile_color_for_height(1);
        let high_color = QuadradiusTheme::tile_color_for_height(3);
        let depressed_color = QuadradiusTheme::tile_color_for_height(-1);

        // Colors should be different for different heights
        assert_ne!(base_color, elevated_color);
        assert_ne!(base_color, high_color);
        assert_ne!(base_color, depressed_color);
        
        // Ensure progression makes sense (lighter for higher)
        assert!(elevated_color.r() >= base_color.r());
        assert!(high_color.r() >= elevated_color.r());
    }

    #[test]
    fn test_ui_colors_have_contrast() {
        // Ensure UI colors have proper contrast
        let background = QuadradiusTheme::UI_BACKGROUND;
        let text = QuadradiusTheme::UI_TEXT;
        let highlight = QuadradiusTheme::UI_TEXT_HIGHLIGHT;

        // Text should be lighter than background
        assert!(text.r() > background.r());
        assert!(text.g() > background.g());
        assert!(text.b() > background.b());

        // Highlight should be brighter than regular text
        assert!(highlight.r() >= text.r());
        assert!(highlight.g() >= text.g());
        assert!(highlight.b() >= text.b());
    }

    #[test]
    fn test_metallic_material_properties() {
        // Test that metallic values are in valid range [0.0, 1.0]
        assert!(QuadradiusTheme::METALLIC_VALUE >= 0.0);
        assert!(QuadradiusTheme::METALLIC_VALUE <= 1.0);
        assert!(QuadradiusTheme::ROUGHNESS_VALUE >= 0.0);
        assert!(QuadradiusTheme::ROUGHNESS_VALUE <= 1.0);
        assert!(QuadradiusTheme::REFLECTANCE_VALUE >= 0.0);
        assert!(QuadradiusTheme::REFLECTANCE_VALUE <= 1.0);
    }

    #[test]
    fn test_effect_colors_have_transparency() {
        // Effect colors should have appropriate alpha values
        let selection = QuadradiusTheme::EFFECT_SELECTION;
        let valid_move = QuadradiusTheme::EFFECT_VALID_MOVE;
        let invalid = QuadradiusTheme::EFFECT_INVALID;

        assert!(selection.a() < 1.0); // Should be semi-transparent
        assert!(valid_move.a() < 1.0);
        assert!(invalid.a() < 1.0);
        assert!(selection.a() > 0.0); // But not completely transparent
    }
}