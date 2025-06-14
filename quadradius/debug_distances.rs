use bevy::math::Vec2;

const TILE_SIZE: f32 = 64.0;
const BOARD_WIDTH: u8 = 10;
const BOARD_HEIGHT: u8 = 8;

fn board_to_world_position(board_pos: (u8, u8)) -> Vec2 {
    let enhanced_tile_size = TILE_SIZE * 1.2; // 76.8
    let x = (board_pos.0 as f32 - BOARD_WIDTH as f32 / 2.0 + 0.5) * enhanced_tile_size;
    let y = (board_pos.1 as f32 - BOARD_HEIGHT as f32 / 2.0 + 0.5) * enhanced_tile_size;
    Vec2::new(x, y)
}

fn main() {
    let enhanced_tile_size = TILE_SIZE * 1.2;
    let threshold_95 = enhanced_tile_size * 0.95;
    
    println!("Enhanced tile size: {:.1}", enhanced_tile_size);
    println!("95% threshold: {:.1}", threshold_95);
    
    // Test the problematic move from the failing test
    let start_pos = (4, 3);
    let target_pos = (4, 4); // One square up
    
    let start_world = board_to_world_position(start_pos);
    let target_world = board_to_world_position(target_pos);
    
    let distance = start_world.distance(target_world);
    
    println!("\nTest move analysis:");
    println!("Start: {:?} -> world {:?}", start_pos, start_world);
    println!("Target: {:?} -> world {:?}", target_pos, target_world);
    println!("Distance: {:.1} pixels", distance);
    println!("Above 95% threshold: {}", distance >= threshold_95);
    
    // Show what movement would be needed
    println!("\nTo exceed 95% threshold, need at least: {:.1} pixels", threshold_95);
    println!("Adjacent tile movement gives: {:.1} pixels", distance);
    println!("Difference: {:.1} pixels short", threshold_95 - distance);
}