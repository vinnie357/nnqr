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

    info!("🎯 Setting up 2D board with {} x {} tiles", BOARD_WIDTH, BOARD_HEIGHT);

    // Create tiles
    for x in 0..BOARD_WIDTH {
        for y in 0..BOARD_HEIGHT {
            // Create more varied height pattern for testing
            let height = match (x, y) {
                (3, 3) | (4, 4) => 2,                                     // Center high points
                (2, 3) | (3, 2) | (4, 3) | (3, 4) | (5, 4) | (4, 5) => 1, // Medium ring
                _ => 0,                                                   // Rest are low
            };

            // Enhanced tile size for better visibility
            let enhanced_tile_size = TILE_SIZE * 0.8;
            let tile_x = (x as f32 - BOARD_WIDTH as f32 / 2.0 + 0.5) * enhanced_tile_size;
            let tile_y = (y as f32 - BOARD_HEIGHT as f32 / 2.0 + 0.5) * enhanced_tile_size;
            
            // Debug log first few tiles (commented for production)
            // if x < 2 && y < 2 {
            //     info!("🎲 Creating tile at ({}, {}) -> world pos ({:.1}, {:.1}), height {}", 
            //           x, y, tile_x, tile_y, height);
            // }

            // Use theme colors but brighter for better visibility
            let theme_color = QuadradiusTheme::tile_color_for_height(height);
            let color = Color::rgb(
                (theme_color.r() * 1.5).min(1.0),
                (theme_color.g() * 1.5).min(1.0), 
                (theme_color.b() * 1.5).min(1.0),
            );

            // Spawn grid line background (darker) for clear tile separation
            commands.spawn((
                SpriteBundle {
                    sprite: Sprite {
                        color: Color::rgb(0.1, 0.1, 0.1), // Very dark grid lines for contrast
                        custom_size: Some(Vec2::splat(enhanced_tile_size)),
                        ..default()
                    },
                    transform: Transform::from_xyz(tile_x, tile_y, -0.1),
                    visibility: Visibility::Visible, // Explicitly set visibility
                    ..default()
                },
                Board, // Add Board component so visibility system can find it
            ));

            // Spawn main tile with better contrast
            commands.spawn((
                BoardTile {
                    coordinates: (x, y),
                    height,
                },
                SpriteBundle {
                    sprite: Sprite {
                        color,
                        custom_size: Some(Vec2::splat(enhanced_tile_size * 0.88)), // Visible gap for grid lines
                        ..default()
                    },
                    transform: Transform::from_xyz(tile_x, tile_y, 0.0),
                    visibility: Visibility::Visible, // Explicitly set visibility
                    ..default()
                },
                Board, // Add Board component so visibility system can find it
            ));
        }
    }
    
    info!("✅ 2D board setup complete: {} tiles created", BOARD_WIDTH * BOARD_HEIGHT);
}
