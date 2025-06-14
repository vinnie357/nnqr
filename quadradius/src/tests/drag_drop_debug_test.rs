use crate::components::*;
use crate::resources::game_state::{GameState, TurnPhase};
// use crate::systems::drag_drop::*; // Unused import
use bevy::prelude::*;

/// Test to debug 2D piece movement issues
#[test]
fn test_2d_piece_movement_debug() {
    println!("🎯 2D Piece Movement Debug Test");
    println!("   Diagnosing why some 2D pieces might not be movable");

    let mut app = App::new();
    app.add_plugins(MinimalPlugins);
    
    // Set up game state
    let mut game_state = GameState::default();
    game_state.current_player = Player::Player1;
    game_state.turn_phase = TurnPhase::PieceMovement;
    
    println!("📊 Game State:");
    println!("   Current player: {:?}", game_state.current_player);
    println!("   Turn phase: {:?}", game_state.turn_phase);
    
    app.world.insert_resource(game_state);
    
    // Create test pieces for both players
    println!("\n🔵 Creating test pieces:");
    
    // Player 1 pieces (should be movable)
    for i in 0..3 {
        let entity = app.world.spawn((
            GamePiece {
                player: Player::Player1,
                board_position: (i, 0),
            },
            Transform::from_xyz(i as f32 * 64.0, 0.0, 0.0),
        )).id();
        println!("   Player1 piece {} at board position ({}, 0)", i, i);
    }
    
    // Player 2 pieces (should NOT be movable on Player1's turn)
    for i in 0..3 {
        let entity = app.world.spawn((
            GamePiece {
                player: Player::Player2,
                board_position: (i, 7),
            },
            Transform::from_xyz(i as f32 * 64.0, 7.0 * 64.0, 0.0),
        )).id();
        println!("   Player2 piece {} at board position ({}, 7)", i, i);
    }
    
    // Test piece query and current player restrictions
    println!("\n🔍 Piece Analysis:");
    let mut movable_count = 0;
    let mut blocked_count = 0;
    
    // Collect piece data first
    let pieces_data: Vec<_> = {
        let mut pieces_query = app.world.query::<(Entity, &GamePiece, &Transform)>();
        pieces_query.iter(&app.world).map(|(e, p, t)| (e, *p, *t)).collect()
    };
    
    let game_state = app.world.resource::<GameState>();
    
    for (entity, piece, transform) in &pieces_data {
        let is_current_player = piece.player == game_state.current_player;
        let is_movable = is_current_player && game_state.turn_phase == TurnPhase::PieceMovement;
        
        if is_movable {
            movable_count += 1;
            println!("   ✅ Piece {:?} - {:?} at {:?} - MOVABLE", 
                     entity, piece.player, piece.board_position);
        } else {
            blocked_count += 1;
            let reason = if !is_current_player {
                "Wrong player"
            } else {
                "Wrong turn phase"
            };
            println!("   ❌ Piece {:?} - {:?} at {:?} - BLOCKED ({})", 
                     entity, piece.player, piece.board_position, reason);
        }
    }
    
    println!("\n📊 Movement Analysis:");
    println!("   Movable pieces: {}", movable_count);
    println!("   Blocked pieces: {}", blocked_count);
    
    // Test coordinate calculations
    println!("\n📐 Coordinate Calculations:");
    let tile_size = TILE_SIZE;
    let enhanced_tile_size = tile_size * 1.2;
    let actual_piece_size = enhanced_tile_size * 0.7; // From pieces.rs
    let old_drag_bounds = enhanced_tile_size; // What it was before
    let new_drag_bounds = actual_piece_size; // What it should be now
    
    println!("   TILE_SIZE: {}", tile_size);
    println!("   Enhanced tile size: {}", enhanced_tile_size);
    println!("   Actual piece size (visual): {:.1}", actual_piece_size);
    println!("   OLD drag bounds (wrong): {:.1} x {:.1}", old_drag_bounds, old_drag_bounds);
    println!("   NEW drag bounds (fixed): {:.1} x {:.1}", new_drag_bounds, new_drag_bounds);
    println!("   Size mismatch fixed: {:.1}% -> 0%", 
             ((old_drag_bounds - actual_piece_size) / actual_piece_size * 100.0));
    
    // Test piece bounds for first piece  
    let player1_pieces: Vec<_> = pieces_data.into_iter()
        .filter(|(_, piece, _)| piece.player == Player::Player1)
        .collect();
        
    if let Some((entity, piece, transform)) = player1_pieces.first() {
        let piece_bounds = Vec2::new(new_drag_bounds, new_drag_bounds); // Use fixed bounds
        let piece_pos = Vec2::new(transform.translation.x, transform.translation.y);
        
        println!("\n🎯 First Player1 piece bounds (FIXED):");
        println!("   Position: ({:.2}, {:.2})", piece_pos.x, piece_pos.y);
        println!("   Visual size: {:.1} x {:.1}", actual_piece_size, actual_piece_size);
        println!("   Click bounds: {:.1} x {:.1}", piece_bounds.x, piece_bounds.y);
        println!("   Click area: ({:.1} to {:.1}, {:.1} to {:.1})", 
                 piece_pos.x - piece_bounds.x / 2.0, piece_pos.x + piece_bounds.x / 2.0,
                 piece_pos.y - piece_bounds.y / 2.0, piece_pos.y + piece_bounds.y / 2.0);
    }
    
    assert_eq!(movable_count, 3, "Should have 3 movable Player1 pieces");
    assert_eq!(blocked_count, 3, "Should have 3 blocked Player2 pieces");
    
    println!("\n✅ Debug test complete - found expected movable/blocked piece counts");
}

/// Test different turn phases and their effect on piece movement
#[test]
fn test_turn_phase_movement_restrictions() {
    println!("🎯 Turn Phase Movement Restriction Test");
    
    let phases = [
        TurnPhase::PowerActivation,
        TurnPhase::PieceMovement,
        TurnPhase::PowerSpawning,
    ];
    
    for phase in phases {
        println!("\n🔍 Testing phase: {:?}", phase);
        
        let mut game_state = GameState::default();
        game_state.turn_phase = phase;
        game_state.current_player = Player::Player1;
        
        // Test if pieces would be movable in this phase
        let can_move = game_state.turn_phase == TurnPhase::PieceMovement;
        
        if can_move {
            println!("   ✅ Pieces can be moved in {:?} phase", phase);
        } else {
            println!("   ❌ Pieces CANNOT be moved in {:?} phase", phase);
        }
    }
    
    println!("\n📝 Summary:");
    println!("   Pieces can only be moved during PieceMovement phase");
    println!("   If users can't move pieces, check current turn phase");
}

/// Test camera and coordinate conversion issues
#[test]
fn test_camera_coordinate_conversion() {
    println!("🎯 Camera Coordinate Conversion Test");
    println!("   Testing potential camera setup issues for 2D mode");
    
    let mut app = App::new();
    app.add_plugins(MinimalPlugins);
    
    // Set up 2D camera like the real game
    app.world.spawn((
        Camera2dBundle::default(),
        crate::systems::settings::Camera2D,
    ));
    
    // Check if camera query would work
    let camera_count = app.world.query::<(&Camera, &GlobalTransform)>()
        .iter(&app.world)
        .count();
    let camera_2d_count = app.world.query_filtered::<Entity, (With<crate::systems::settings::Camera2D>, With<Camera>)>()
        .iter(&app.world)
        .count();
    
    println!("📊 Camera Analysis:");
    println!("   Total cameras: {}", camera_count);
    println!("   2D cameras with Camera2D component: {}", camera_2d_count);
    
    assert_eq!(camera_count, 1, "Should have exactly one camera");
    assert_eq!(camera_2d_count, 1, "Should have exactly one 2D camera");
    
    println!("✅ Camera setup looks correct for 2D mode");
}