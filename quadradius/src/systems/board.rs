use crate::components::*;
use crate::resources::QuadradiusTheme;
use bevy::prelude::*;

pub fn setup_board(mut commands: Commands) {
    // Create board entity
    commands.spawn((Board, Transform::from_xyz(0.0, 0.0, 0.0)));

    // Create tiles
    for x in 0..BOARD_WIDTH {
        for y in 0..BOARD_HEIGHT {
            // Create more varied height pattern for testing
            let height = match (x, y) {
                (3, 3) | (4, 4) => 2,                                     // Center high points
                (2, 3) | (3, 2) | (4, 3) | (3, 4) | (5, 4) | (4, 5) => 1, // Medium ring
                _ => 0,                                                   // Rest are low
            };

            let tile_x = (x as f32 - BOARD_WIDTH as f32 / 2.0 + 0.5) * TILE_SIZE;
            let tile_y = (y as f32 - BOARD_HEIGHT as f32 / 2.0 + 0.5) * TILE_SIZE;

            let color = QuadradiusTheme::tile_color_for_height(height);

            commands.spawn((
                BoardTile {
                    coordinates: (x, y),
                    height,
                },
                SpriteBundle {
                    sprite: Sprite {
                        color,
                        custom_size: Some(Vec2::splat(TILE_SIZE - 2.0)), // Small gap between tiles
                        ..default()
                    },
                    transform: Transform::from_xyz(tile_x, tile_y, 0.0),
                    ..default()
                },
            ));
        }
    }
}
