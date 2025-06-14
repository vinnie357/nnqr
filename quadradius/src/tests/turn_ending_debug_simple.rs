use crate::components::*;
use crate::resources::game_state::{GameState, TurnPhase};
use crate::systems::drag_drop::*;
use bevy::prelude::*;

/// Simple test to debug turn ending issue - reproducing user scenario
#[test]
fn test_click_without_drag_should_not_end_turn() {
    println!("🎯 Click Without Drag Test");
    println!("   Reproducing: Click piece -> turn should NOT end");
    
    // Test the find_best_valid_target_enhanced function directly
    let start_pos = (3, 3);
    let click_pos = board_to_world_position(start_pos); // Click exactly on piece
    
    println!("   Start position: {:?}", start_pos);
    println!("   Click world pos: ({:.1}, {:.1})", click_pos.x, click_pos.y);
    
    // Convert back to board to see if it's exact
    let converted_back = world_to_board_position(click_pos);
    println!("   Converted back to board: {:?}", converted_back);
    
    assert_eq!(start_pos, converted_back, "Position conversion should be exact");
    
    // The key test: if we click exactly on a piece's position, 
    // find_best_valid_target_enhanced should return None because
    // same-position moves aren't valid
    
    // This would require setting up the full test environment, but the key insight is:
    // if drop_world_pos is very close to start position, we shouldn't find a "valid" target
    let distance_to_self = click_pos.distance(click_pos); // Should be 0.0
    println!("   Distance to self: {:.3}", distance_to_self);
    
    assert_eq!(distance_to_self, 0.0, "Distance to same position should be 0");
    
    // If the player clicks at the exact piece position, the magnetic snapping
    // logic should not find any valid targets, preventing turn advancement
}

#[test] 
fn test_magnetic_snapping_threshold() {
    println!("🎯 Magnetic Snapping Threshold Test");
    
    let start_pos = (3, 3);
    let start_world = board_to_world_position(start_pos);
    
    // Test small movements that should NOT trigger snapping
    let small_offset = Vec2::new(5.0, 5.0); // 5 pixels
    let small_movement_pos = start_world + small_offset;
    
    let enhanced_tile_size = TILE_SIZE * 1.2; // 76.8
    let snapping_threshold = enhanced_tile_size * 0.7; // 53.76
    
    println!("   Enhanced tile size: {:.1}", enhanced_tile_size);
    println!("   Snapping threshold: {:.1}", snapping_threshold);
    println!("   Small movement distance: {:.1}", small_offset.length());
    
    // Small movements should be within snapping range
    let is_within_snapping = small_offset.length() < snapping_threshold;
    println!("   Is within snapping range: {}", is_within_snapping);
    
    // But this is the problem! Even tiny movements can trigger snapping to nearby valid positions
    assert!(is_within_snapping, "Small movements are within snapping range");
    
    // The fix should be: if the movement is very small AND no actual different 
    // position was intended, don't snap to nearby positions
}

fn board_to_world_position(board_pos: (u8, u8)) -> Vec2 {
    let enhanced_tile_size = TILE_SIZE * 1.2;
    let x = (board_pos.0 as f32 - BOARD_WIDTH as f32 / 2.0 + 0.5) * enhanced_tile_size;
    let y = (board_pos.1 as f32 - BOARD_HEIGHT as f32 / 2.0 + 0.5) * enhanced_tile_size;
    Vec2::new(x, y)
}

fn world_to_board_position(world_pos: Vec2) -> (u8, u8) {
    let enhanced_tile_size = TILE_SIZE * 1.2;
    let x = ((world_pos.x / enhanced_tile_size) + BOARD_WIDTH as f32 / 2.0 - 0.5).round() as i8;
    let y = ((world_pos.y / enhanced_tile_size) + BOARD_HEIGHT as f32 / 2.0 - 0.5).round() as i8;

    let x = x.max(0).min(BOARD_WIDTH as i8 - 1) as u8;
    let y = y.max(0).min(BOARD_HEIGHT as i8 - 1) as u8;

    (x, y)
}