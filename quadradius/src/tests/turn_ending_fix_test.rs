use crate::components::*;
use crate::resources::game_state::{GameState, TurnPhase};
use crate::systems::drag_drop::*;
use crate::systems::settings::Camera2D;
use bevy::prelude::*;
use bevy::ecs::system::RunSystemOnce;

/// Test to verify that turns only end when pieces actually move, not when just selected
#[test]
fn test_turn_ending_only_on_actual_move() {
    println!("🎯 Turn Ending Fix Test");
    println!("   Verifying turns only end when pieces actually move to different positions");
    
    let mut app = App::new();
    app.add_plugins(MinimalPlugins);
    app.insert_resource(Assets::<Mesh>::default());
    app.insert_resource(Assets::<StandardMaterial>::default());
    
    // Set up game state
    let mut game_state = GameState::default();
    game_state.current_player = Player::Player1;
    game_state.turn_phase = TurnPhase::PieceMovement;
    app.world.insert_resource(game_state);
    
    // Set up camera and window
    app.world.spawn((
        Camera2dBundle {
            transform: Transform::from_xyz(0.0, 0.0, 1000.0),
            global_transform: GlobalTransform::from_xyz(0.0, 0.0, 1000.0),
            ..default()
        },
        Camera2D,
    ));
    app.world.spawn(Window::default());
    
    // Set up board tiles
    for x in 0..BOARD_WIDTH {
        for y in 0..BOARD_HEIGHT {
            app.world.spawn(BoardTile {
                coordinates: (x, y),
                height: 0,
            });
        }
    }
    
    // Create test piece at (4, 3) - center of board
    let enhanced_tile_size = TILE_SIZE * 1.2;
    let start_board_pos = (4, 3);
    let start_world_pos = board_to_world_position(start_board_pos);
    
    let piece_entity = app.world.spawn((
        GamePiece {
            player: Player::Player1,
            board_position: start_board_pos,
        },
        Transform::from_xyz(start_world_pos.x, start_world_pos.y, 5.0),
    )).id();
    
    println!("\n📋 Test Setup:");
    println!("   Piece at board position: {:?}", start_board_pos);
    println!("   World position: ({:.1}, {:.1})", start_world_pos.x, start_world_pos.y);
    println!("   Initial turn phase: {:?}", TurnPhase::PieceMovement);
    println!("   Current player: {:?}", Player::Player1);
    
    // Test 1: Select piece and drop back on same position (should NOT end turn)
    println!("\n1️⃣ Testing: Select and drop on same position (should NOT end turn)");
    
    test_drag_to_position(&mut app, piece_entity, start_world_pos, start_board_pos, false);
    
    // Verify turn did NOT end
    let game_state = app.world.resource::<GameState>();
    assert_eq!(game_state.turn_phase, TurnPhase::PieceMovement, 
               "Turn should still be in PieceMovement phase after dropping on same position");
    assert_eq!(game_state.current_player, Player::Player1,
               "Should still be Player1's turn");
    
    println!("   ✅ Turn correctly continued (phase: {:?}, player: {:?})", 
             game_state.turn_phase, game_state.current_player);
    
    // Test 2: Move piece to adjacent position (should end turn)
    println!("\n2️⃣ Testing: Move piece to adjacent position (should end turn)");
    
    let target_board_pos = (4, 4); // One square up
    let target_world_pos = board_to_world_position(target_board_pos);
    
    test_drag_to_position(&mut app, piece_entity, target_world_pos, target_board_pos, true);
    
    // Verify turn DID end
    let game_state = app.world.resource::<GameState>();
    assert_eq!(game_state.turn_phase, TurnPhase::PowerSpawning,
               "Turn should advance to PowerSpawning phase after actual move");
    
    println!("   ✅ Turn correctly ended (phase: {:?})", game_state.turn_phase);
    
    // Verify piece position updated
    let piece_transform = app.world.get::<Transform>(piece_entity).unwrap();
    let piece_game_piece = app.world.get::<GamePiece>(piece_entity).unwrap();
    
    assert_eq!(piece_game_piece.board_position, target_board_pos,
               "Piece board position should be updated");
    
    println!("   ✅ Piece position updated to {:?}", piece_game_piece.board_position);
    
    println!("\n✅ Turn Ending Fix Test Results:");
    println!("   🔄 Same position drop: Turn continues ✅");
    println!("   🎯 Actual movement: Turn ends ✅");
    println!("   📍 Position tracking: Accurate ✅");
    println!("   🎮 Player experience: Fixed - no unexpected turn endings!");
}

fn test_drag_to_position(
    app: &mut App,
    piece_entity: Entity,
    target_world_pos: Vec2,
    expected_board_pos: (u8, u8),
    should_end_turn: bool,
) {
    // Step 1: Start drag
    let mut mouse_input = Input::<MouseButton>::default();
    app.world.insert_resource(mouse_input);
    
    // Set cursor at piece position for selection
    let piece_transform = app.world.get::<Transform>(piece_entity).unwrap();
    let piece_world_pos = Vec2::new(piece_transform.translation.x, piece_transform.translation.y);
    
    if let Some(mut window) = app.world.query::<&mut Window>().get_single_mut(&mut app.world).ok() {
        let cursor_pos = simulate_world_to_screen_pos(piece_world_pos);
        window.set_cursor_position(Some(cursor_pos));
    }
    
    // Press mouse to start drag
    let mut mouse_input = Input::<MouseButton>::default();
    mouse_input.press(MouseButton::Left);
    app.world.insert_resource(mouse_input);
    
    app.world.run_system_once(handle_drag_start);
    
    // Verify piece is being dragged
    let has_dragging = app.world.get::<Dragging>(piece_entity).is_some();
    println!("     Piece selected for dragging: {}", has_dragging);
    
    // Step 2: Drag to target position
    if let Some(mut window) = app.world.query::<&mut Window>().get_single_mut(&mut app.world).ok() {
        let cursor_pos = simulate_world_to_screen_pos(target_world_pos);
        window.set_cursor_position(Some(cursor_pos));
    }
    
    app.world.run_system_once(handle_drag_update);
    
    // Step 3: End drag (release mouse)
    let mut mouse_input = Input::<MouseButton>::default();
    mouse_input.release(MouseButton::Left);
    app.world.insert_resource(mouse_input);
    
    app.world.run_system_once(handle_drag_end);
    
    // Verify piece is no longer being dragged
    let still_dragging = app.world.get::<Dragging>(piece_entity).is_some();
    println!("     Drag completed (no longer dragging): {}", !still_dragging);
    
    // Clean up any drag indicators
    let indicator_entities: Vec<Entity> = app.world.query::<Entity>()
        .iter(&app.world)
        .filter(|&e| app.world.get::<ValidMoveIndicator>(e).is_some())
        .collect();
    
    for entity in indicator_entities {
        app.world.entity_mut(entity).despawn();
    }
}

fn simulate_world_to_screen_pos(world_pos: Vec2) -> Vec2 {
    // Simple 1:1 mapping for test purposes
    Vec2::new(world_pos.x + 400.0, 300.0 - world_pos.y)
}

fn board_to_world_position(board_pos: (u8, u8)) -> Vec2 {
    let enhanced_tile_size = TILE_SIZE * 1.2;
    let x = (board_pos.0 as f32 - BOARD_WIDTH as f32 / 2.0 + 0.5) * enhanced_tile_size;
    let y = (board_pos.1 as f32 - BOARD_HEIGHT as f32 / 2.0 + 0.5) * enhanced_tile_size;
    Vec2::new(x, y)
}

/// Test multiple piece selection scenarios
#[test]
fn test_multiple_piece_selection_scenarios() {
    println!("🎯 Multiple Piece Selection Scenarios Test");
    println!("   Testing various selection patterns that should not end turn");
    
    let mut app = App::new();
    app.add_plugins(MinimalPlugins);
    app.insert_resource(Assets::<Mesh>::default());
    app.insert_resource(Assets::<StandardMaterial>::default());
    
    // Set up game state
    let mut game_state = GameState::default();
    game_state.current_player = Player::Player1;
    game_state.turn_phase = TurnPhase::PieceMovement;
    app.world.insert_resource(game_state);
    
    // Set up camera and window
    app.world.spawn((
        Camera2dBundle {
            transform: Transform::from_xyz(0.0, 0.0, 1000.0),
            global_transform: GlobalTransform::from_xyz(0.0, 0.0, 1000.0),
            ..default()
        },
        Camera2D,
    ));
    app.world.spawn(Window::default());
    
    // Set up board tiles
    for x in 0..BOARD_WIDTH {
        for y in 0..BOARD_HEIGHT {
            app.world.spawn(BoardTile {
                coordinates: (x, y),
                height: 0,
            });
        }
    }
    
    // Create multiple test pieces
    let test_positions = vec![(2, 2), (4, 2), (6, 2)];
    let mut piece_entities = Vec::new();
    
    for (i, &board_pos) in test_positions.iter().enumerate() {
        let world_pos = board_to_world_position(board_pos);
        let entity = app.world.spawn((
            GamePiece {
                player: Player::Player1,
                board_position: board_pos,
            },
            Transform::from_xyz(world_pos.x, world_pos.y, 5.0),
        )).id();
        
        piece_entities.push((entity, board_pos, world_pos));
        println!("   Created piece {} at board {:?}", i + 1, board_pos);
    }
    
    println!("\n🔍 Testing scenarios that should NOT end turn:");
    
    // Scenario 1: Select piece A, drop on same position
    println!("\n   1️⃣ Select piece 1, drop on same position");
    let (entity1, board_pos1, world_pos1) = piece_entities[0];
    test_drag_to_position(&mut app, entity1, world_pos1, board_pos1, false);
    
    let game_state = app.world.resource::<GameState>();
    assert_eq!(game_state.turn_phase, TurnPhase::PieceMovement);
    assert_eq!(game_state.current_player, Player::Player1);
    println!("     ✅ Turn continued correctly");
    
    // Scenario 2: Select piece B, drop on same position
    println!("\n   2️⃣ Select piece 2, drop on same position");
    let (entity2, board_pos2, world_pos2) = piece_entities[1];
    test_drag_to_position(&mut app, entity2, world_pos2, board_pos2, false);
    
    let game_state = app.world.resource::<GameState>();
    assert_eq!(game_state.turn_phase, TurnPhase::PieceMovement);
    assert_eq!(game_state.current_player, Player::Player1);
    println!("     ✅ Turn continued correctly");
    
    // Scenario 3: Select piece C, drop on same position
    println!("\n   3️⃣ Select piece 3, drop on same position");
    let (entity3, board_pos3, world_pos3) = piece_entities[2];
    test_drag_to_position(&mut app, entity3, world_pos3, board_pos3, false);
    
    let game_state = app.world.resource::<GameState>();
    assert_eq!(game_state.turn_phase, TurnPhase::PieceMovement);
    assert_eq!(game_state.current_player, Player::Player1);
    println!("     ✅ Turn continued correctly");
    
    println!("\n🎯 Testing scenario that SHOULD end turn:");
    
    // Scenario 4: Actually move piece 1 to adjacent position
    println!("\n   4️⃣ Move piece 1 to adjacent position");
    let new_board_pos = (board_pos1.0, board_pos1.1 + 1); // Move up one square
    let new_world_pos = board_to_world_position(new_board_pos);
    
    test_drag_to_position(&mut app, entity1, new_world_pos, new_board_pos, true);
    
    let game_state = app.world.resource::<GameState>();
    assert_eq!(game_state.turn_phase, TurnPhase::PowerSpawning);
    println!("     ✅ Turn ended correctly (advanced to {:?})", game_state.turn_phase);
    
    println!("\n✅ Multiple Selection Scenarios Test Results:");
    println!("   🔄 Multiple piece selections without movement: All continued turn ✅");
    println!("   🎯 Actual piece movement: Correctly ended turn ✅");
    println!("   🎮 User experience: Fixed - players can explore pieces without ending turn!");
}