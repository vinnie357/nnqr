use crate::components::*;
use crate::resources::QuadradiusTheme;
use bevy::prelude::*;

pub fn setup_pieces(mut commands: Commands) {
    let mut p1_count = 0;
    let mut p2_count = 0;

    info!("🔵 Setting up Player 1 pieces (rows 0-1)");
    // Player 1 pieces (bottom two rows)
    for y in 0..2 {
        for x in 0..BOARD_WIDTH {
            if (x + y) % 2 == 0 {
                // Checkerboard pattern
                spawn_piece(&mut commands, Player::Player1, (x, y));
                p1_count += 1;
            }
        }
    }

    info!(
        "🔴 Setting up Player 2 pieces (rows {}-{})",
        BOARD_HEIGHT - 2,
        BOARD_HEIGHT - 1
    );
    // Player 2 pieces (top two rows)
    for y in (BOARD_HEIGHT - 2)..BOARD_HEIGHT {
        for x in 0..BOARD_WIDTH {
            if (x + y) % 2 == 0 {
                // Checkerboard pattern
                spawn_piece(&mut commands, Player::Player2, (x, y));
                p2_count += 1;
            }
        }
    }
    info!(
        "✅ Piece setup complete: {} Player1 pieces, {} Player2 pieces",
        p1_count, p2_count
    );
}

fn spawn_piece(commands: &mut Commands, player: Player, position: (u8, u8)) {
    // 2D pieces use team colors from theme
    let color = match player {
        Player::Player1 => QuadradiusTheme::TEAM_1_PRIMARY, // Bright metallic blue
        Player::Player2 => QuadradiusTheme::TEAM_2_PRIMARY, // Bright metallic red
    };

    // Use same enhanced tile size as board for proper alignment
    let enhanced_tile_size = TILE_SIZE * 1.2; // Must match board.rs tile size multiplier
    let world_x = (position.0 as f32 - BOARD_WIDTH as f32 / 2.0 + 0.5) * enhanced_tile_size;
    let world_y = (position.1 as f32 - BOARD_HEIGHT as f32 / 2.0 + 0.5) * enhanced_tile_size;

    // Debug log piece positions (commented for production)
    // info!("🎯 Spawning {:?} piece at board ({}, {}) -> world ({:.1}, {:.1})",
    //       player, position.0, position.1, world_x, world_y);

    // Spawn 2D-only pieces without 3D component
    commands.spawn((
        GamePiece {
            player,
            board_position: position,
        },
        PowerInventory::new(), // Add power inventory to each piece
        SpriteBundle {
            sprite: Sprite {
                color,
                // Square pieces for 2D view - using exact square dimensions
                custom_size: Some(Vec2::splat(enhanced_tile_size * 0.7)), // Square pieces that fit well in tiles
                ..default()
            },
            transform: Transform::from_xyz(world_x, world_y, 5.0), // High Z to ensure pieces are above tiles
            visibility: Visibility::Visible,
            ..default()
        },
    ));
}
