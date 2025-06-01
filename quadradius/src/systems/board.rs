use bevy::prelude::*;
use crate::components::*;

pub fn setup_board(mut commands: Commands) {
    // Create board entity
    commands.spawn((Board, Transform::from_xyz(0.0, 0.0, 0.0)));
    
    // Create tiles
    for x in 0..BOARD_SIZE {
        for y in 0..BOARD_SIZE {
            let height = if (x + y) % 3 == 0 { 1 } else { 0 }; // Varied heights for testing
            
            let tile_x = (x as f32 - BOARD_SIZE as f32 / 2.0 + 0.5) * TILE_SIZE;
            let tile_y = (y as f32 - BOARD_SIZE as f32 / 2.0 + 0.5) * TILE_SIZE;
            
            let color = match height {
                0 => Color::rgb(0.3, 0.7, 0.3), // Green for low
                1 => Color::rgb(0.7, 0.7, 0.3), // Yellow for medium
                _ => Color::rgb(0.7, 0.3, 0.3), // Red for high
            };
            
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