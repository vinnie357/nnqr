use crate::components::*;
use crate::resources::game_state::{GameState, TurnPhase};
use crate::systems::drag_drop::*;
use crate::systems::settings::Camera2D;
use bevy::prelude::*;
use bevy::ecs::system::RunSystemOnce;

/// Comprehensive test to verify that turn endings work correctly for typical user scenarios
#[test]
fn test_user_turn_ending_scenarios_comprehensive() {
    println!("🎯 Comprehensive User Turn Ending Verification Test");
    println!("   Testing all typical scenarios users report as problematic");
    
    let mut app = App::new();
    app.add_plugins(MinimalPlugins);
    app.insert_resource(Assets::<Mesh>::default());
    app.insert_resource(Assets::<StandardMaterial>::default());
    
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
    
    println!("\n📋 Testing scenarios that users commonly report:");
    
    // Scenario 1: Player clicks piece, immediately releases without moving
    test_user_scenario(&mut app, "Quick click without movement", |app, piece_entity, piece_pos| {
        simulate_quick_click(app, piece_entity, piece_pos)
    });
    
    // Scenario 2: Player clicks piece, drags very slightly, drops on same position
    test_user_scenario(&mut app, "Tiny drag to same position", |app, piece_entity, piece_pos| {
        simulate_tiny_drag_same_position(app, piece_entity, piece_pos)
    });
    
    // Scenario 3: Player clicks piece, drags to edge of same tile, drops
    test_user_scenario(&mut app, "Drag to edge of same tile", |app, piece_entity, piece_pos| {
        simulate_drag_to_tile_edge(app, piece_entity, piece_pos)
    });
    
    // Scenario 4: Player clicks piece, drags to adjacent tile, then back to original
    test_user_scenario(&mut app, "Drag to adjacent then back", |app, piece_entity, piece_pos| {
        simulate_drag_to_adjacent_then_back(app, piece_entity, piece_pos)
    });
    
    // Scenario 5: Player clicks piece, drags to valid adjacent position (should end turn)
    test_user_scenario(&mut app, "Valid move to adjacent tile", |app, piece_entity, piece_pos| {
        simulate_valid_move_to_adjacent(app, piece_entity, piece_pos)
    });
    
    println!("\n✅ Comprehensive User Turn Ending Test Results:");
    println!("   🔄 Quick clicks: Turns correctly preserved ✅");
    println!("   🔄 Same position drags: Turns correctly preserved ✅");
    println!("   🔄 Edge drags: Turns correctly preserved ✅");
    println!("   🔄 Back-and-forth drags: Turns correctly preserved ✅");
    println!("   🎯 Valid moves: Turns correctly ended ✅");
    println!("   🎮 User experience: Fixed - no unexpected turn endings!");
}

fn test_user_scenario<F>(app: &mut App, scenario_name: &str, scenario_fn: F) 
where 
    F: Fn(&mut App, Entity, Vec2)
{
    println!("\n🔍 Testing: {}", scenario_name);
    
    // Reset game state for each scenario
    let mut game_state = GameState::default();
    game_state.current_player = Player::Player1;
    game_state.turn_phase = TurnPhase::PieceMovement;
    app.world.insert_resource(game_state);
    
    // Create test piece
    let start_board_pos = (4, 3);
    let start_world_pos = board_to_world_position(start_board_pos);
    
    let piece_entity = app.world.spawn((
        GamePiece {
            player: Player::Player1,
            board_position: start_board_pos,
        },
        Transform::from_xyz(start_world_pos.x, start_world_pos.y, 5.0),
    )).id();
    
    let turn_phase_before = app.world.resource::<GameState>().turn_phase;
    let piece_pos_before = app.world.get::<GamePiece>(piece_entity).unwrap().board_position;
    
    // Run the scenario
    scenario_fn(app, piece_entity, start_world_pos);
    
    let turn_phase_after = app.world.resource::<GameState>().turn_phase;
    let piece_pos_after = app.world.get::<GamePiece>(piece_entity).unwrap().board_position;
    
    let turn_ended = turn_phase_after != turn_phase_before;
    let piece_moved = piece_pos_after != piece_pos_before;
    
    println!("   Before: Turn={:?}, Piece={:?}", turn_phase_before, piece_pos_before);
    println!("   After:  Turn={:?}, Piece={:?}", turn_phase_after, piece_pos_after);
    
    // Verify correct behavior based on scenario
    if scenario_name.contains("Valid move") {
        // This scenario should end the turn
        assert!(turn_ended, "Turn should end for valid moves");
        assert!(piece_moved, "Piece should move for valid moves");
        println!("   ✅ Turn correctly ended and piece moved");
    } else {
        // All other scenarios should NOT end the turn
        assert!(!turn_ended, "Turn should NOT end for {}", scenario_name);
        assert!(!piece_moved, "Piece should NOT move for {}", scenario_name);
        println!("   ✅ Turn correctly preserved and piece stayed");
    }
    
    // Clean up
    app.world.entity_mut(piece_entity).despawn();
    
    // Remove any valid move indicators
    let indicator_entities: Vec<Entity> = app.world.query::<Entity>()
        .iter(&app.world)
        .filter(|&e| app.world.get::<ValidMoveIndicator>(e).is_some())
        .collect();
    
    for entity in indicator_entities {
        app.world.entity_mut(entity).despawn();
    }
}

fn simulate_quick_click(app: &mut App, piece_entity: Entity, piece_pos: Vec2) {
    // Press and immediately release mouse at piece position
    set_cursor_and_mouse_state(app, piece_pos, true);
    app.world.run_system_once(handle_drag_start);
    
    set_cursor_and_mouse_state(app, piece_pos, false);
    app.world.run_system_once(handle_drag_end);
}

fn simulate_tiny_drag_same_position(app: &mut App, piece_entity: Entity, piece_pos: Vec2) {
    // Press mouse
    set_cursor_and_mouse_state(app, piece_pos, true);
    app.world.run_system_once(handle_drag_start);
    
    // Tiny movement (1 pixel)
    let tiny_offset = Vec2::new(piece_pos.x + 1.0, piece_pos.y + 1.0);
    set_cursor_position(app, tiny_offset);
    app.world.run_system_once(handle_drag_update);
    
    // Drop back very close to original position
    let drop_pos = Vec2::new(piece_pos.x + 0.5, piece_pos.y + 0.5);
    set_cursor_and_mouse_state(app, drop_pos, false);
    app.world.run_system_once(handle_drag_end);
}

fn simulate_drag_to_tile_edge(app: &mut App, piece_entity: Entity, piece_pos: Vec2) {
    // Press mouse
    set_cursor_and_mouse_state(app, piece_pos, true);
    app.world.run_system_once(handle_drag_start);
    
    // Drag to edge of tile (but still same tile)
    let enhanced_tile_size = TILE_SIZE * 1.2;
    let edge_pos = Vec2::new(piece_pos.x + enhanced_tile_size * 0.3, piece_pos.y);
    set_cursor_position(app, edge_pos);
    app.world.run_system_once(handle_drag_update);
    
    // Drop at edge
    set_cursor_and_mouse_state(app, edge_pos, false);
    app.world.run_system_once(handle_drag_end);
}

fn simulate_drag_to_adjacent_then_back(app: &mut App, piece_entity: Entity, piece_pos: Vec2) {
    // Press mouse
    set_cursor_and_mouse_state(app, piece_pos, true);
    app.world.run_system_once(handle_drag_start);
    
    // Drag to adjacent tile
    let enhanced_tile_size = TILE_SIZE * 1.2;
    let adjacent_pos = Vec2::new(piece_pos.x + enhanced_tile_size, piece_pos.y);
    set_cursor_position(app, adjacent_pos);
    app.world.run_system_once(handle_drag_update);
    
    // Drag back to original area
    let back_pos = Vec2::new(piece_pos.x + 2.0, piece_pos.y + 2.0);
    set_cursor_position(app, back_pos);
    app.world.run_system_once(handle_drag_update);
    
    // Drop near original position
    set_cursor_and_mouse_state(app, back_pos, false);
    app.world.run_system_once(handle_drag_end);
}

fn simulate_valid_move_to_adjacent(app: &mut App, piece_entity: Entity, piece_pos: Vec2) {
    // Press mouse
    set_cursor_and_mouse_state(app, piece_pos, true);
    app.world.run_system_once(handle_drag_start);
    
    // Move to adjacent valid position (one tile right)
    let enhanced_tile_size = TILE_SIZE * 1.2;
    let target_pos = Vec2::new(piece_pos.x + enhanced_tile_size, piece_pos.y);
    set_cursor_position(app, target_pos);
    app.world.run_system_once(handle_drag_update);
    
    // Drop on valid adjacent position
    set_cursor_and_mouse_state(app, target_pos, false);
    app.world.run_system_once(handle_drag_end);
}

fn set_cursor_and_mouse_state(app: &mut App, world_pos: Vec2, mouse_pressed: bool) {
    set_cursor_position(app, world_pos);
    
    let mut mouse_input = Input::<MouseButton>::default();
    if mouse_pressed {
        mouse_input.press(MouseButton::Left);
    } else {
        mouse_input.release(MouseButton::Left);
    }
    app.world.insert_resource(mouse_input);
}

fn set_cursor_position(app: &mut App, world_pos: Vec2) {
    if let Some(mut window) = app.world.query::<&mut Window>().get_single_mut(&mut app.world).ok() {
        let cursor_pos = simulate_world_to_screen_pos(world_pos);
        window.set_cursor_position(Some(cursor_pos));
    }
}

fn simulate_world_to_screen_pos(world_pos: Vec2) -> Vec2 {
    Vec2::new(world_pos.x + 400.0, 300.0 - world_pos.y)
}

fn board_to_world_position(board_pos: (u8, u8)) -> Vec2 {
    let enhanced_tile_size = TILE_SIZE * 1.2;
    let x = (board_pos.0 as f32 - BOARD_WIDTH as f32 / 2.0 + 0.5) * enhanced_tile_size;
    let y = (board_pos.1 as f32 - BOARD_HEIGHT as f32 / 2.0 + 0.5) * enhanced_tile_size;
    Vec2::new(x, y)
}