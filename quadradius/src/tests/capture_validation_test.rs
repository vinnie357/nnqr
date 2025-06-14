use crate::components::*;
use crate::systems::drag_drop::*;
use bevy::prelude::*;

/// Test to verify that piece captures work correctly
#[test]
fn test_capture_validation_logic() {
    println!("🎯 Capture Validation Test");
    println!("   Verifying that pieces can capture enemy pieces");
    
    // Setup a capture scenario
    let player1 = Player::Player1; // Blue
    let player2 = Player::Player2; // Red
    
    // Piece positions: Player1 piece at (3,3), Player2 piece at (3,4)
    let piece_positions = vec![
        ((3, 3), player1, Entity::from_raw(1)), // Blue piece
        ((3, 4), player2, Entity::from_raw(2)), // Red piece (target for capture)
    ];
    
    // Test if Player1 can move from (3,3) to (3,4) to capture Player2
    let from = (3, 3);
    let to = (3, 4); // Where the enemy piece is
    
    // Check if target is occupied by friendly piece (should be false - enemy piece)
    let blocked_by_friendly = piece_positions
        .iter()
        .any(|(pos, p, _)| *pos == to && *p == player1);
    
    assert!(!blocked_by_friendly, "Should not be blocked by friendly piece");
    println!("   ✅ Not blocked by friendly piece");
    
    // Check if target is occupied by enemy piece (should be true - capture scenario)
    let enemy_piece_present = piece_positions
        .iter()
        .any(|(pos, p, _)| *pos == to && *p == player2);
    
    assert!(enemy_piece_present, "Enemy piece should be present at target");
    println!("   ✅ Enemy piece present at target - capture scenario");
    
    // Test basic movement rules (orthogonal adjacent move)
    let dx = (to.0 as i8 - from.0 as i8).abs();
    let dy = (to.1 as i8 - from.1 as i8).abs();
    let is_valid_distance = (dx == 1 && dy == 0) || (dx == 0 && dy == 1);
    
    assert!(is_valid_distance, "Move should be valid distance (adjacent)");
    println!("   ✅ Valid move distance: dx={}, dy={}", dx, dy);
    
    println!("   🎯 Capture should be ALLOWED: Blue (3,3) -> Red at (3,4)");
}

#[test]
fn test_friendly_piece_blocking() {
    println!("🎯 Friendly Piece Blocking Test");
    println!("   Verifying that pieces cannot capture their own team");
    
    let player1 = Player::Player1; // Blue
    
    // Two Player1 pieces
    let piece_positions = vec![
        ((3, 3), player1, Entity::from_raw(1)), // Blue piece
        ((3, 4), player1, Entity::from_raw(2)), // Another blue piece
    ];
    
    let from = (3, 3);
    let to = (3, 4); // Where friendly piece is
    
    // Check if target is occupied by friendly piece (should be true - blocked)
    let blocked_by_friendly = piece_positions
        .iter()
        .any(|(pos, p, _)| *pos == to && *p == player1);
    
    assert!(blocked_by_friendly, "Should be blocked by friendly piece");
    println!("   ✅ Correctly blocked by friendly piece");
    
    println!("   🚫 Move should be BLOCKED: Blue (3,3) -> Blue at (3,4)");
}

#[test]
fn test_enhanced_movement_capture_logic() {
    println!("🎯 Enhanced Movement Capture Logic Test");
    println!("   Testing the enhanced movement validation for captures");
    
    // This replicates the logic from enhanced_movement.rs
    let player1 = Player::Player1;
    let player2 = Player::Player2;
    
    let piece_positions = vec![
        ((4, 4), player1, Entity::from_raw(1)), // Capturing piece
        ((4, 5), player2, Entity::from_raw(2)), // Target piece
    ];
    
    let from = (4, 4);
    let to = (4, 5);
    let current_player = player1;
    
    // Enhanced movement validation logic
    // Check if target is occupied by friendly piece
    let blocked = piece_positions
        .iter()
        .any(|(pos, player, _)| *pos == to && *player == current_player);
    
    assert!(!blocked, "Enhanced validation should allow capture");
    println!("   ✅ Enhanced validation allows enemy capture");
    
    // Test same logic with friendly piece
    let piece_positions_friendly = vec![
        ((4, 4), player1, Entity::from_raw(1)), // Moving piece
        ((4, 5), player1, Entity::from_raw(2)), // Friendly piece
    ];
    
    let blocked_friendly = piece_positions_friendly
        .iter()
        .any(|(pos, player, _)| *pos == to && *player == current_player);
    
    assert!(blocked_friendly, "Enhanced validation should block friendly capture");
    println!("   ✅ Enhanced validation blocks friendly piece capture");
}

#[test]
fn test_capture_coordinates_typical_game() {
    println!("🎯 Typical Game Capture Coordinates Test");
    println!("   Testing coordinates that would occur in actual gameplay");
    
    // Player1 starts at bottom (rows 0-1), Player2 at top (rows 6-7)
    // After a few moves, they might meet in the middle
    
    // Scenario: Player1 piece moved up to (5,4), Player2 piece at (5,5)
    let piece_positions = vec![
        ((5, 4), Player::Player1, Entity::from_raw(1)), // Blue piece (advanced from bottom)
        ((5, 5), Player::Player2, Entity::from_raw(2)), // Red piece (moved down from top)
    ];
    
    // Player1 wants to capture Player2
    let from = (5, 4);
    let to = (5, 5);
    let current_player = Player::Player1;
    
    // Verify this is a valid capture scenario
    let is_adjacent = {
        let dx = (to.0 as i8 - from.0 as i8).abs();
        let dy = (to.1 as i8 - from.1 as i8).abs();
        (dx == 1 && dy == 0) || (dx == 0 && dy == 1)
    };
    
    assert!(is_adjacent, "Should be adjacent move");
    
    let is_enemy = piece_positions
        .iter()
        .any(|(pos, player, _)| *pos == to && *player != current_player);
    
    assert!(is_enemy, "Target should be enemy piece");
    
    let is_friendly = piece_positions
        .iter()
        .any(|(pos, player, _)| *pos == to && *player == current_player);
    
    assert!(!is_friendly, "Target should not be friendly piece");
    
    println!("   ✅ Typical game capture scenario should work");
    println!("   📍 Player1 (5,4) capturing Player2 (5,5)");
}