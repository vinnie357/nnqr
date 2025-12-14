use crate::components::PowerType;
use crate::resources::QuadradiusTheme;
use bevy::prelude::*;

#[cfg(test)]
mod power_orb_tests {
    use super::*;

    #[test]
    fn test_metallic_orb_color() {
        // Test that power orbs use the metallic theme
        let orb_color = QuadradiusTheme::ORB_BASE;

        // Should not be pure black or white
        assert_ne!(orb_color, Color::BLACK);
        assert_ne!(orb_color, Color::WHITE);

        // Should have a metallic appearance (not too bright, not too dark)
        assert!(orb_color.r() > 0.3 && orb_color.r() < 0.9);
        assert!(orb_color.g() > 0.3 && orb_color.g() < 0.9);
        assert!(orb_color.b() > 0.3 && orb_color.b() < 0.9);
    }

    #[test]
    fn test_orb_glow_effect() {
        let glow_color = QuadradiusTheme::ORB_GLOW;

        // Glow should be semi-transparent
        assert!(glow_color.a() > 0.0);
        assert!(glow_color.a() < 1.0);

        // Should be lighter than base orb color
        let base_color = QuadradiusTheme::ORB_BASE;
        assert!(glow_color.r() >= base_color.r());
        assert!(glow_color.g() >= base_color.g());
        assert!(glow_color.b() >= base_color.b());
    }

    #[test]
    fn test_orb_highlight() {
        let highlight = QuadradiusTheme::ORB_HIGHLIGHT;
        let base = QuadradiusTheme::ORB_BASE;

        // Highlight should be brighter than base
        assert!(highlight.r() > base.r());
        assert!(highlight.g() > base.g());
        assert!(highlight.b() > base.b());

        // Should be close to white for specular highlight
        assert!(highlight.r() > 0.8);
        assert!(highlight.g() > 0.8);
        assert!(highlight.b() > 0.8);
    }

    #[test]
    fn test_power_types_still_have_colors() {
        // Ensure power types still have their original colors for identification
        // even though orbs render with metallic base
        let diagonal = PowerType::MoveDiagonal.color();
        let multiply = PowerType::Multiply.color();
        let teleport = PowerType::Teleport.color();

        // All should be different
        assert_ne!(diagonal, multiply);
        assert_ne!(diagonal, teleport);
        assert_ne!(multiply, teleport);

        // None should be black (indicating proper color assignment)
        assert_ne!(diagonal, Color::BLACK);
        assert_ne!(multiply, Color::BLACK);
        assert_ne!(teleport, Color::BLACK);
    }

    #[test]
    fn test_industrial_aesthetic_consistency() {
        // Test that all theme colors follow the industrial aesthetic
        let colors = [
            QuadradiusTheme::ORB_BASE,
            QuadradiusTheme::UI_BACKGROUND,
            QuadradiusTheme::UI_PANEL,
            QuadradiusTheme::TEAM_1_PRIMARY,
            QuadradiusTheme::TEAM_2_PRIMARY,
        ];

        for color in colors.iter() {
            // Industrial colors should be somewhat muted (not oversaturated)
            let max_component = color.r().max(color.g()).max(color.b());
            let min_component = color.r().min(color.g()).min(color.b());
            let saturation = max_component - min_component;

            // Should not be overly saturated for industrial feel
            assert!(
                saturation < 0.8,
                "Color too saturated for industrial theme: {:?}",
                color
            );
        }
    }
}
