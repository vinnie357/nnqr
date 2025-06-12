use crate::components::*;
use bevy::prelude::*;

/// Debug test to verify exact coordinate positioning
#[test]
fn test_coordinate_positioning_debug() {
    println!("🔍 Debug: Coordinate Positioning Analysis");
    
    let enhanced_tile_size = TILE_SIZE * 1.2; // 76.8
    
    println!("Enhanced tile size: {}", enhanced_tile_size);
    println!("Board dimensions: {}x{}", BOARD_WIDTH, BOARD_HEIGHT);
    
    // Test a few key positions to see the exact coordinates
    let test_positions = vec![
        (0, 0),   // Top-left corner
        (4, 3),   // Center of board  
        (9, 7),   // Bottom-right corner
        (1, 6),   // Blue piece position (from screenshot)
        (3, 6),   // Another blue piece position
    ];
    
    println!("\n📍 Position Analysis:");
    for &(x, y) in &test_positions {
        // Using the exact formula from pieces.rs (how pieces are positioned)
        let piece_world_x = (x as f32 - BOARD_WIDTH as f32 / 2.0 + 0.5) * enhanced_tile_size;
        let piece_world_y = (y as f32 - BOARD_HEIGHT as f32 / 2.0 + 0.5) * enhanced_tile_size;
        
        // Using the exact formula from board.rs (how tiles are positioned)  
        let tile_world_x = (x as f32 - BOARD_WIDTH as f32 / 2.0 + 0.5) * enhanced_tile_size;
        let tile_world_y = (y as f32 - BOARD_HEIGHT as f32 / 2.0 + 0.5) * enhanced_tile_size;
        
        // Using the drag_drop.rs board_to_world_position (how indicators are positioned)
        let indicator_world_x = (x as f32 - BOARD_WIDTH as f32 / 2.0 + 0.5) * enhanced_tile_size;
        let indicator_world_y = (y as f32 - BOARD_HEIGHT as f32 / 2.0 + 0.5) * enhanced_tile_size;
        
        println!("  Board({}, {}):", x, y);
        println!("    Piece:     ({:6.1}, {:6.1})", piece_world_x, piece_world_y);
        println!("    Tile:      ({:6.1}, {:6.1})", tile_world_x, tile_world_y);
        println!("    Indicator: ({:6.1}, {:6.1})", indicator_world_x, indicator_world_y);
        
        // Check if they're identical
        let piece_tile_match = (piece_world_x - tile_world_x).abs() < 0.01 && (piece_world_y - tile_world_y).abs() < 0.01;
        let piece_indicator_match = (piece_world_x - indicator_world_x).abs() < 0.01 && (piece_world_y - indicator_world_y).abs() < 0.01;
        
        if piece_tile_match && piece_indicator_match {
            println!("    ✅ All coordinates match perfectly");
        } else {
            println!("    ❌ MISMATCH DETECTED!");
        }
        println!();
    }
    
    // Test center of board calculation
    let center_x_calc = BOARD_WIDTH as f32 / 2.0;  // Should be 5.0
    let center_y_calc = BOARD_HEIGHT as f32 / 2.0; // Should be 4.0
    
    println!("📐 Board center calculations:");
    println!("  BOARD_WIDTH / 2.0 = {}", center_x_calc);
    println!("  BOARD_HEIGHT / 2.0 = {}", center_y_calc);
    println!("  Center position should be around ({}, {})", center_x_calc - 0.5, center_y_calc - 0.5);
    
    // Test that board (4, 3) should be near world (0, 0)
    let center_world_x = (4.0 - BOARD_WIDTH as f32 / 2.0 + 0.5) * enhanced_tile_size;
    let center_world_y = (3.0 - BOARD_HEIGHT as f32 / 2.0 + 0.5) * enhanced_tile_size;
    
    println!("  Board (4, 3) -> World ({:.1}, {:.1})", center_world_x, center_world_y);
    println!("  This should be close to (0, 0) since (4,3) is roughly center");
    
    // Analysis: if coordinates are mathematically identical but visually misaligned,
    // the issue might be in sprite sizing, z-layering, or viewport rendering
    println!("\n🔧 If coordinates match but visual alignment is wrong, check:");
    println!("  1. Sprite custom_size values");
    println!("  2. Transform Z values (layering)");
    println!("  3. Camera projection or viewport settings"); 
    println!("  4. Sprite anchor/origin points");
}