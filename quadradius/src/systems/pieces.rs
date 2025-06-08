use crate::components::*;
use crate::resources::QuadradiusTheme;
use bevy::prelude::*;

pub fn setup_pieces(mut commands: Commands) {
    // Player 1 pieces (bottom two rows)
    for y in 0..2 {
        for x in 0..BOARD_WIDTH {
            if (x + y) % 2 == 0 {
                // Checkerboard pattern
                spawn_piece(&mut commands, Player::Player1, (x, y));
            }
        }
    }

    // Player 2 pieces (top two rows)
    for y in (BOARD_HEIGHT - 2)..BOARD_HEIGHT {
        for x in 0..BOARD_WIDTH {
            if (x + y) % 2 == 0 {
                // Checkerboard pattern
                spawn_piece(&mut commands, Player::Player2, (x, y));
            }
        }
    }
}

fn spawn_piece(commands: &mut Commands, player: Player, position: (u8, u8)) {
    let color = match player {
        Player::Player1 => QuadradiusTheme::TEAM_1_PRIMARY,
        Player::Player2 => QuadradiusTheme::TEAM_2_PRIMARY,
    };

    let world_x = (position.0 as f32 - BOARD_WIDTH as f32 / 2.0 + 0.5) * TILE_SIZE;
    let world_y = (position.1 as f32 - BOARD_HEIGHT as f32 / 2.0 + 0.5) * TILE_SIZE;

    commands.spawn((
        GamePiece {
            player,
            board_position: position,
        },
        SpriteBundle {
            sprite: Sprite {
                color,
                custom_size: Some(Vec2::splat(TILE_SIZE * 0.8)), // Slightly smaller than tiles
                ..default()
            },
            transform: Transform::from_xyz(world_x, world_y, 1.0), // Above tiles
            ..default()
        },
    ));
}
