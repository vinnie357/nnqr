use crate::components::*;
use crate::resources::QuadradiusTheme;
use bevy::prelude::*;

// Component for animated board tiles
#[derive(Component)]
pub struct AnimatedTile {
    pub base_color: Color,
    pub hover_color: Color,
    pub selected_color: Color,
}

// Component for height visualization
#[derive(Component)]
pub struct HeightIndicator {
    pub height: i8,
}

// Enhanced board setup with better visuals
pub fn setup_enhanced_board(
    mut commands: Commands,
    tiles: Query<(Entity, &BoardTile), Without<AnimatedTile>>,
) {
    for (entity, tile) in tiles.iter() {
        // Use theme colors based on height
        let base_color = QuadradiusTheme::tile_color_for_height(tile.height);

        commands.entity(entity).insert((
            AnimatedTile {
                base_color,
                hover_color: Color::rgb(
                    base_color.r() + 0.2,
                    base_color.g() + 0.2,
                    base_color.b() + 0.2,
                ),
                selected_color: Color::rgb(
                    base_color.r() + 0.4,
                    base_color.g() + 0.4,
                    base_color.b() + 0.1,
                ),
            },
            HeightIndicator {
                height: tile.height,
            },
        ));
    }
}

// Add gradient background for better depth perception
pub fn setup_board_background(mut commands: Commands) {
    use crate::components::board::{BOARD_WIDTH, TILE_SIZE};

    // Background gradient
    commands.spawn(SpriteBundle {
        sprite: Sprite {
            color: QuadradiusTheme::METAL_GUNMETAL.with_a(0.95),
            custom_size: Some(Vec2::new(1000.0, 1000.0)),
            ..default()
        },
        transform: Transform::from_xyz(0.0, 0.0, -10.0),
        ..default()
    });

    // Board frame
    let frame_thickness = 10.0;
    let board_size = BOARD_WIDTH as f32 * TILE_SIZE + frame_thickness * 2.0;

    // Top frame
    commands.spawn(SpriteBundle {
        sprite: Sprite {
            color: QuadradiusTheme::METAL_BRONZE,
            custom_size: Some(Vec2::new(board_size, frame_thickness)),
            ..default()
        },
        transform: Transform::from_xyz(0.0, board_size / 2.0, -5.0),
        ..default()
    });

    // Bottom frame
    commands.spawn(SpriteBundle {
        sprite: Sprite {
            color: QuadradiusTheme::METAL_BRONZE,
            custom_size: Some(Vec2::new(board_size, frame_thickness)),
            ..default()
        },
        transform: Transform::from_xyz(0.0, -board_size / 2.0, -5.0),
        ..default()
    });

    // Left frame
    commands.spawn(SpriteBundle {
        sprite: Sprite {
            color: QuadradiusTheme::METAL_BRONZE,
            custom_size: Some(Vec2::new(frame_thickness, board_size)),
            ..default()
        },
        transform: Transform::from_xyz(-board_size / 2.0, 0.0, -5.0),
        ..default()
    });

    // Right frame
    commands.spawn(SpriteBundle {
        sprite: Sprite {
            color: QuadradiusTheme::METAL_BRONZE,
            custom_size: Some(Vec2::new(frame_thickness, board_size)),
            ..default()
        },
        transform: Transform::from_xyz(board_size / 2.0, 0.0, -5.0),
        ..default()
    });
}

// Animate tiles when hovered
pub fn animate_tile_hover(
    mut tiles: Query<(&mut Sprite, &AnimatedTile, &Interaction), Changed<Interaction>>,
) {
    for (mut sprite, animated, interaction) in tiles.iter_mut() {
        sprite.color = match *interaction {
            Interaction::Pressed => animated.selected_color,
            Interaction::Hovered => animated.hover_color,
            Interaction::None => animated.base_color,
        };
    }
}

// Update tile colors when height changes
pub fn update_tile_colors_on_height_change(
    mut tiles: Query<(&BoardTile, &mut AnimatedTile), Changed<BoardTile>>,
) {
    for (tile, mut animated) in tiles.iter_mut() {
        let base_color = QuadradiusTheme::tile_color_for_height(tile.height);
        animated.base_color = base_color;
        animated.hover_color = Color::rgb(
            base_color.r() + 0.2,
            base_color.g() + 0.2,
            base_color.b() + 0.2,
        );
        animated.selected_color = Color::rgb(
            base_color.r() + 0.4,
            base_color.g() + 0.4,
            base_color.b() + 0.1,
        );
    }
}
