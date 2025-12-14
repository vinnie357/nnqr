use bevy::prelude::*;

/// Industrial metallic color theme for Quadradius
pub struct QuadradiusTheme;

impl QuadradiusTheme {
    // Core metallic colors
    pub const METAL_SILVER: Color = Color::rgb(0.75, 0.75, 0.80);
    pub const METAL_GUNMETAL: Color = Color::rgb(0.32, 0.35, 0.39);
    pub const METAL_CHROME: Color = Color::rgb(0.87, 0.89, 0.91);
    pub const METAL_BRONZE: Color = Color::rgb(0.55, 0.42, 0.32);
    pub const METAL_COPPER: Color = Color::rgb(0.72, 0.45, 0.33);

    // Industrial accent colors
    pub const INDUSTRIAL_BLUE: Color = Color::rgb(0.25, 0.45, 0.65);
    pub const INDUSTRIAL_ORANGE: Color = Color::rgb(0.85, 0.45, 0.15);
    pub const INDUSTRIAL_GREEN: Color = Color::rgb(0.35, 0.55, 0.35);
    pub const INDUSTRIAL_RED: Color = Color::rgb(0.75, 0.25, 0.25);

    // Team colors with metallic finish - enhanced contrast
    pub const TEAM_1_PRIMARY: Color = Color::rgb(0.1, 0.3, 0.8); // Bright metallic blue
    pub const TEAM_1_ACCENT: Color = Color::rgb(0.4, 0.6, 1.0); // Bright blue accent
    pub const TEAM_2_PRIMARY: Color = Color::rgb(0.8, 0.1, 0.1); // Bright metallic red
    pub const TEAM_2_ACCENT: Color = Color::rgb(1.0, 0.4, 0.4); // Bright red accent

    // Board and tile colors - Optimized for 2D visibility with "whiter = higher" principle
    pub const TILE_BASE: Color = Color::rgb(0.65, 0.67, 0.70); // Much brighter base for better visibility
    pub const TILE_ELEVATED_1: Color = Color::rgb(0.72, 0.75, 0.78); // Light grey with slight blue tint
    pub const TILE_ELEVATED_2: Color = Color::rgb(0.80, 0.83, 0.86); // Lighter for clear height distinction
    pub const TILE_ELEVATED_3: Color = Color::rgb(0.88, 0.91, 0.94); // Very light, approaching white
    pub const TILE_ELEVATED_4: Color = Color::rgb(0.95, 0.98, 1.0); // Almost pure white for highest elevation
    pub const TILE_DEPRESSED: Color = Color::rgb(0.35, 0.32, 0.30); // Warmer tone for craters, still visible

    // 2D specific colors for better contrast
    pub const TILE_BASE_2D: Color = Color::rgb(0.70, 0.72, 0.75); // Even brighter for 2D view
    pub const TILE_ELEVATED_1_2D: Color = Color::rgb(0.76, 0.79, 0.82); // Clear step up
    pub const TILE_ELEVATED_2_2D: Color = Color::rgb(0.82, 0.85, 0.88); // Noticeable elevation
    pub const TILE_ELEVATED_3_2D: Color = Color::rgb(0.88, 0.91, 0.94); // High elevation
    pub const TILE_ELEVATED_4_2D: Color = Color::rgb(0.94, 0.97, 1.0); // Maximum height
    pub const TILE_DEPRESSED_2D: Color = Color::rgb(0.40, 0.37, 0.35); // Visible depression

    // Grid and background colors for 2D
    pub const GRID_LINES_2D: Color = Color::rgb(0.30, 0.30, 0.35); // Lighter grid lines for visibility
    pub const BOARD_BACKGROUND_2D: Color = Color::rgb(0.15, 0.15, 0.18); // Dark background for contrast

    // UI element colors
    pub const UI_BACKGROUND: Color = Color::rgba(0.12, 0.14, 0.16, 0.95); // Dark semi-transparent
    pub const UI_PANEL: Color = Color::rgba(0.20, 0.22, 0.25, 0.90); // Panel background
    pub const UI_BORDER: Color = Color::rgb(0.45, 0.48, 0.52); // Metallic border
    pub const UI_TEXT: Color = Color::rgb(0.85, 0.87, 0.89); // Light metallic text
    pub const UI_TEXT_HIGHLIGHT: Color = Color::rgb(0.95, 0.96, 0.97); // Bright text

    // Power orb metallic colors
    pub const ORB_BASE: Color = Color::rgb(0.65, 0.68, 0.72); // Base metallic orb
    pub const ORB_GLOW: Color = Color::rgba(0.85, 0.88, 0.92, 0.6); // Glow effect
    pub const ORB_HIGHLIGHT: Color = Color::rgb(0.92, 0.94, 0.96); // Specular highlight

    // Effect colors
    pub const EFFECT_EXPLOSION: Color = Color::rgb(0.95, 0.65, 0.25); // Orange explosion
    pub const EFFECT_SELECTION: Color = Color::rgba(0.55, 0.75, 0.95, 0.4); // Blue selection
    pub const EFFECT_VALID_MOVE: Color = Color::rgba(0.35, 0.65, 0.35, 0.3); // Green valid move
    pub const EFFECT_INVALID: Color = Color::rgba(0.75, 0.25, 0.25, 0.3); // Red invalid

    // Height-based gradient for tiles
    pub fn tile_color_for_height(height: i8) -> Color {
        match height {
            h if h < 0 => Self::TILE_DEPRESSED,
            0 => Self::TILE_BASE,
            1 => Self::TILE_ELEVATED_1,
            2 => Self::TILE_ELEVATED_2,
            3 => Self::TILE_ELEVATED_3,
            _ => Self::TILE_ELEVATED_4,
        }
    }

    // Height-based gradient specifically for 2D view with better visibility
    pub fn tile_color_for_height_2d(height: i8) -> Color {
        match height {
            h if h < 0 => Self::TILE_DEPRESSED_2D,
            0 => Self::TILE_BASE_2D,
            1 => Self::TILE_ELEVATED_1_2D,
            2 => Self::TILE_ELEVATED_2_2D,
            3 => Self::TILE_ELEVATED_3_2D,
            _ => Self::TILE_ELEVATED_4_2D,
        }
    }

    // Metallic material properties
    pub const METALLIC_VALUE: f32 = 0.8;
    pub const ROUGHNESS_VALUE: f32 = 0.3;
    pub const REFLECTANCE_VALUE: f32 = 0.9;
}

/// UI style constants
pub struct UIStyle;

impl UIStyle {
    pub const PANEL_PADDING: f32 = 12.0;
    pub const BUTTON_HEIGHT: f32 = 40.0;
    pub const TEXT_SIZE_TITLE: f32 = 32.0;
    pub const TEXT_SIZE_HEADING: f32 = 24.0;
    pub const TEXT_SIZE_NORMAL: f32 = 16.0;
    pub const TEXT_SIZE_SMALL: f32 = 14.0;
    pub const BORDER_WIDTH: f32 = 2.0;
    pub const CORNER_RADIUS: f32 = 4.0;
    pub const SHADOW_OFFSET: Vec2 = Vec2::new(2.0, 2.0);
    pub const SHADOW_COLOR: Color = Color::rgba(0.0, 0.0, 0.0, 0.5);
}
