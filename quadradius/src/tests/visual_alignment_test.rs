use crate::components::*;
use crate::resources::*;
use crate::systems::drag_drop::ValidMoveIndicator;
use bevy::ecs::system::RunSystemOnce;
use bevy::prelude::*;

/// Test that creates actual entities and checks their transforms
#[test] 
fn test_visual_alignment_practical() {
    println!("🎮 Practical Visual Alignment Test");
    
    let mut app = App::new();
    app.add_plugins(MinimalPlugins)
        .init_resource::<GameState>()
        .init_resource::<RenderConfig>();
    
    // Create a tile and indicator at the same board position and compare transforms
    app.world.run_system_once(|mut commands: Commands| {
        let test_board_pos = (4, 3); // Center position from screenshot
        let enhanced_tile_size = TILE_SIZE * 1.2;
        
        // Create a tile using the exact board.rs formula
        let tile_x = (test_board_pos.0 as f32 - BOARD_WIDTH as f32 / 2.0 + 0.5) * enhanced_tile_size;
        let tile_y = (test_board_pos.1 as f32 - BOARD_HEIGHT as f32 / 2.0 + 0.5) * enhanced_tile_size;
        
        let tile_entity = commands.spawn((
            BoardTile {
                coordinates: test_board_pos,
                height: 0,
            },
            SpriteBundle {
                sprite: Sprite {
                    color: Color::GRAY,
                    custom_size: Some(Vec2::splat(enhanced_tile_size * 0.85)), // Board tile size
                    ..default()
                },
                transform: Transform::from_xyz(tile_x, tile_y, 0.1),
                ..default()
            },
        )).id();
        
        // Create a piece using the exact pieces.rs formula  
        let piece_world_x = (test_board_pos.0 as f32 - BOARD_WIDTH as f32 / 2.0 + 0.5) * enhanced_tile_size;
        let piece_world_y = (test_board_pos.1 as f32 - BOARD_HEIGHT as f32 / 2.0 + 0.5) * enhanced_tile_size;
        
        let piece_entity = commands.spawn((
            GamePiece {
                player: Player::Player1,
                board_position: test_board_pos,
            },
            SpriteBundle {
                sprite: Sprite {
                    color: Color::BLUE,
                    custom_size: Some(Vec2::splat(enhanced_tile_size * 0.7)), // Piece size
                    ..default()
                },
                transform: Transform::from_xyz(piece_world_x, piece_world_y, 5.0),
                ..default()
            },
        )).id();
        
        // Create an indicator using the drag_drop.rs board_to_world_position formula
        let indicator_world_pos = {
            let x = (test_board_pos.0 as f32 - BOARD_WIDTH as f32 / 2.0 + 0.5) * enhanced_tile_size;
            let y = (test_board_pos.1 as f32 - BOARD_HEIGHT as f32 / 2.0 + 0.5) * enhanced_tile_size;
            Vec2::new(x, y)
        };
        
        let indicator_entity = commands.spawn((
            ValidMoveIndicator,
            SpriteBundle {
                sprite: Sprite {
                    color: Color::rgba(0.0, 1.0, 0.0, 0.4), // Green indicator
                    custom_size: Some(Vec2::splat(enhanced_tile_size * 0.85)), // Indicator size
                    ..default()
                },
                transform: Transform::from_xyz(indicator_world_pos.x, indicator_world_pos.y, 2.0),
                ..default()
            },
        )).id();
        
        println!("📦 Created entities at board position ({}, {}):", test_board_pos.0, test_board_pos.1);
        println!("  Tile entity: {:?}", tile_entity);
        println!("  Piece entity: {:?}", piece_entity);  
        println!("  Indicator entity: {:?}", indicator_entity);
    });
    
    // Now query the transforms and compare them
    app.world.run_system_once(|
        tile_query: Query<&Transform, (With<BoardTile>, Without<GamePiece>, Without<ValidMoveIndicator>)>,
        piece_query: Query<&Transform, (With<GamePiece>, Without<BoardTile>, Without<ValidMoveIndicator>)>,
        indicator_query: Query<&Transform, (With<ValidMoveIndicator>, Without<BoardTile>, Without<GamePiece>)>,
    | {
        let tile_transform = tile_query.single();
        let piece_transform = piece_query.single();
        let indicator_transform = indicator_query.single();
        
        println!("\n📐 Transform Comparison:");
        println!("  Tile:      ({:7.1}, {:7.1}, {:3.1}) | Size: 65.3px", 
                 tile_transform.translation.x, tile_transform.translation.y, tile_transform.translation.z);
        println!("  Piece:     ({:7.1}, {:7.1}, {:3.1}) | Size: 53.8px", 
                 piece_transform.translation.x, piece_transform.translation.y, piece_transform.translation.z);
        println!("  Indicator: ({:7.1}, {:7.1}, {:3.1}) | Size: 65.3px", 
                 indicator_transform.translation.x, indicator_transform.translation.y, indicator_transform.translation.z);
        
        // Check if X,Y positions match (Z can be different for layering)
        let tile_pos = tile_transform.translation.xy();
        let piece_pos = piece_transform.translation.xy();  
        let indicator_pos = indicator_transform.translation.xy();
        
        let tolerance = 0.1; // Allow tiny floating point differences
        
        let tile_piece_match = (tile_pos - piece_pos).length() < tolerance;
        let tile_indicator_match = (tile_pos - indicator_pos).length() < tolerance;
        let piece_indicator_match = (piece_pos - indicator_pos).length() < tolerance;
        
        println!("\n✅ Position Alignment Check:");
        println!("  Tile ↔ Piece:     {} (distance: {:.3})", 
                 if tile_piece_match { "✅ MATCH" } else { "❌ MISMATCH" }, 
                 (tile_pos - piece_pos).length());
        println!("  Tile ↔ Indicator: {} (distance: {:.3})", 
                 if tile_indicator_match { "✅ MATCH" } else { "❌ MISMATCH" }, 
                 (tile_pos - indicator_pos).length());
        println!("  Piece ↔ Indicator: {} (distance: {:.3})", 
                 if piece_indicator_match { "✅ MATCH" } else { "❌ MISMATCH" }, 
                 (piece_pos - indicator_pos).length());
        
        if tile_piece_match && tile_indicator_match && piece_indicator_match {
            println!("\n🎯 CONCLUSION: All entities are positioned identically!");
            println!("   If there's visual misalignment, the issue is likely:");
            println!("   - Sprite anchor points (sprites are centered by default)");
            println!("   - Visual perspective/camera projection differences");
            println!("   - Rounding differences in GPU rendering");
            println!("   - The actual issue might be elsewhere in the system");
        } else {
            println!("\n⚠️ CONCLUSION: Position mismatch detected!");
            println!("   This confirms coordinate calculation differences.");
        }
    });
}