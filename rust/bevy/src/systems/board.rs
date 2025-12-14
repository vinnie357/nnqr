use crate::components::*;
use crate::resources::QuadradiusTheme;
use bevy::prelude::*;

pub fn setup_board(mut commands: Commands) {
    // Create board entity
    commands.spawn((
        Board,
        Transform::from_xyz(0.0, 0.0, 0.0),
        Visibility::Visible, // Explicitly set visibility
    ));

    info!(
        "🎯 Setting up 2D board with {} x {} tiles",
        BOARD_WIDTH, BOARD_HEIGHT
    );

    // Add dark background for better board contrast
    let board_width = BOARD_WIDTH as f32 * TILE_SIZE * 1.2 * 1.1; // Account for enhanced tile size and padding
    let board_height = BOARD_HEIGHT as f32 * TILE_SIZE * 1.2 * 1.1;

    commands.spawn((
        SpriteBundle {
            sprite: Sprite {
                color: QuadradiusTheme::BOARD_BACKGROUND_2D,
                custom_size: Some(Vec2::new(board_width, board_height)),
                ..default()
            },
            transform: Transform::from_xyz(0.0, 0.0, -1.0), // Behind all tiles
            visibility: Visibility::Visible,
            ..default()
        },
        Board, // Add Board component so visibility system can find it
    ));

    // Create tiles
    for x in 0..BOARD_WIDTH {
        for y in 0..BOARD_HEIGHT {
            // Create more varied height pattern for testing
            let height = match (x, y) {
                (3, 3) | (4, 4) => 2,                                     // Center high points
                (2, 3) | (3, 2) | (4, 3) | (3, 4) | (5, 4) | (4, 5) => 1, // Medium ring
                _ => 0,                                                   // Rest are low
            };

            // Enhanced tile size for better visibility - match 3D version
            let enhanced_tile_size = TILE_SIZE * 1.2;
            let tile_x = (x as f32 - BOARD_WIDTH as f32 / 2.0 + 0.5) * enhanced_tile_size;
            let tile_y = (y as f32 - BOARD_HEIGHT as f32 / 2.0 + 0.5) * enhanced_tile_size;

            // Debug log first few tiles (commented for production)
            // if x < 2 && y < 2 {
            //     info!("🎲 Creating tile at ({}, {}) -> world pos ({:.1}, {:.1}), height {}",
            //           x, y, tile_x, tile_y, height);
            // }

            // 2D board uses color gradients to indicate height (enhancement for better UX)
            let tile_color = height_to_color(height);
            let border_color = Color::rgb(0.0, 0.0, 0.0); // Black borders

            // Spawn black border background (larger tile for border effect)
            commands.spawn((
                SpriteBundle {
                    sprite: Sprite {
                        color: border_color, // Black border
                        custom_size: Some(Vec2::splat(enhanced_tile_size)),
                        ..default()
                    },
                    transform: Transform::from_xyz(tile_x, tile_y, 0.0),
                    visibility: Visibility::Visible,
                    ..default()
                },
                Board, // Add Board component so visibility system can find it
            ));

            // Spawn main tile (smaller to show black border)
            commands.spawn((
                BoardTile {
                    coordinates: (x, y),
                    height, // Preserve height data for 3D mode
                },
                SpriteBundle {
                    sprite: Sprite {
                        color: tile_color, // Flat gray for all tiles in 2D
                        custom_size: Some(Vec2::splat(enhanced_tile_size * 0.85)), // Smaller to show black border
                        ..default()
                    },
                    transform: Transform::from_xyz(tile_x, tile_y, 0.1), // Above border
                    visibility: Visibility::Visible,
                    ..default()
                },
                Board, // Add Board component so visibility system can find it
            ));
        }
    }

    info!(
        "✅ 2D board setup complete: {} tiles created",
        BOARD_WIDTH * BOARD_HEIGHT
    );
}

/// Convert height to color gradient for 2D view
/// Low heights = darker grays, high heights = lighter grays with subtle blue tint
fn height_to_color(height: i8) -> Color {
    match height {
        0 => Color::rgb(0.6, 0.6, 0.65),  // Lowest - dark gray
        1 => Color::rgb(0.75, 0.75, 0.8), // Medium - original gray
        2 => Color::rgb(0.85, 0.87, 0.9), // High - light gray with blue tint
        3 => Color::rgb(0.9, 0.92, 0.95), // Very high - very light blue-gray
        _ => Color::rgb(0.5, 0.5, 0.55),  // Negative or extreme heights - very dark
    }
}
