use crate::components::*;
use crate::resources::game_state::{GameState, TurnPhase};
use crate::systems::drag_drop::*;
use crate::systems::settings::Camera2D;
use bevy::ecs::system::RunSystemOnce;
use bevy::prelude::*;

/// Test to debug the specific user-reported issue: turns ending after clicking a piece
#[test]
fn test_2d_turn_ending_debug_user_scenario() {
    println!("🎯 2D Turn Ending Debug Test - User Scenario");
    println!("   Reproducing: 'turns ending unexpectedly after clicking a piece to move'");

    let mut app = App::new();
    app.add_plugins(MinimalPlugins);
    app.insert_resource(Assets::<Mesh>::default());
    app.insert_resource(Assets::<StandardMaterial>::default());

    // Set up game state exactly like actual game
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

    // Create a realistic piece setup like actual game
    let enhanced_tile_size = TILE_SIZE * 1.2;
    let start_board_pos = (2, 1); // Player 1 piece in normal starting area
    let start_world_pos = board_to_world_position(start_board_pos);

    let piece_entity = app
        .world
        .spawn((
            GamePiece {
                player: Player::Player1,
                board_position: start_board_pos,
            },
            Transform::from_xyz(start_world_pos.x, start_world_pos.y, 5.0),
        ))
        .id();

    println!("\n📋 Test Setup:");
    println!("   Player: {:?}", Player::Player1);
    println!("   Turn phase: {:?}", TurnPhase::PieceMovement);
    println!("   Piece at board: {:?}", start_board_pos);
    println!(
        "   Piece at world: ({:.1}, {:.1})",
        start_world_pos.x, start_world_pos.y
    );

    // Test multiple click scenarios that users might encounter
    let click_scenarios = vec![
        ("Exact center click", start_world_pos),
        (
            "Slightly off-center (+2px)",
            Vec2::new(start_world_pos.x + 2.0, start_world_pos.y + 2.0),
        ),
        (
            "Edge of piece (+15px)",
            Vec2::new(start_world_pos.x + 15.0, start_world_pos.y),
        ),
        (
            "Just outside piece (+30px)",
            Vec2::new(start_world_pos.x + 30.0, start_world_pos.y),
        ),
        (
            "Far off-center (+50px)",
            Vec2::new(start_world_pos.x + 50.0, start_world_pos.y + 25.0),
        ),
    ];

    for (scenario_name, click_pos) in click_scenarios {
        println!("\n🔍 Testing scenario: {}", scenario_name);
        println!("   Click at: ({:.1}, {:.1})", click_pos.x, click_pos.y);

        // Reset game state
        {
            let mut game_state = app.world.resource_mut::<GameState>();
            game_state.current_player = Player::Player1;
            game_state.turn_phase = TurnPhase::PieceMovement;
        }

        // Clean up any existing drag state
        if let Some(mut entity_commands) = app.world.get_entity_mut(piece_entity) {
            entity_commands.remove::<Dragging>();
        }

        // Reset piece position
        if let Some(mut piece) = app.world.get_mut::<GamePiece>(piece_entity) {
            piece.board_position = start_board_pos;
        }
        if let Some(mut transform) = app.world.get_mut::<Transform>(piece_entity) {
            transform.translation = Vec3::new(start_world_pos.x, start_world_pos.y, 5.0);
        }

        let turn_phase_before = app.world.resource::<GameState>().turn_phase;
        println!("   Turn phase before: {:?}", turn_phase_before);

        // Perform click and drag sequence
        let drag_result = perform_realistic_drag_sequence(&mut app, piece_entity, click_pos);

        let turn_phase_after = app.world.resource::<GameState>().turn_phase;
        let piece_position_after = app
            .world
            .get::<GamePiece>(piece_entity)
            .unwrap()
            .board_position;

        println!("   Turn phase after: {:?}", turn_phase_after);
        println!("   Piece position after: {:?}", piece_position_after);

        // Analyze results
        let turn_ended = turn_phase_after != turn_phase_before;
        let piece_moved = piece_position_after != start_board_pos;

        match (turn_ended, piece_moved) {
            (false, false) => println!("   ✅ CORRECT: Turn did not end, piece did not move"),
            (true, true) => println!("   ✅ CORRECT: Turn ended, piece moved to new position"),
            (true, false) => {
                println!("   ❌ BUG: Turn ended but piece did not move!");
                println!("   🚨 This is the user-reported issue!");

                // Additional debugging
                println!("   Debug info:");
                println!("     - Drag was detected: {}", drag_result.drag_detected);
                println!("     - Target found: {:?}", drag_result.target_found);
                println!(
                    "     - World click pos: ({:.1}, {:.1})",
                    click_pos.x, click_pos.y
                );
                println!(
                    "     - Converted board pos: {:?}",
                    world_to_board_position(click_pos)
                );

                panic!("Turn ending bug reproduced!");
            }
            (false, true) => {
                println!("   ❌ WEIRD: Piece moved but turn did not end");
                panic!("Unexpected state: piece moved without turn ending");
            }
        }
    }

    println!("\n✅ 2D Turn Ending Debug Test Complete");
    println!("   All scenarios behaved correctly - no premature turn endings detected");
}

#[derive(Debug)]
struct DragResult {
    drag_detected: bool,
    target_found: Option<(u8, u8)>,
}

fn perform_realistic_drag_sequence(
    app: &mut App,
    piece_entity: Entity,
    click_world_pos: Vec2,
) -> DragResult {
    let mut target_found = None;

    // Step 1: Mouse press (start drag)
    let mouse_input = Input::<MouseButton>::default();
    app.world.insert_resource(mouse_input);

    // Set cursor position
    if let Some(mut window) = app
        .world
        .query::<&mut Window>()
        .get_single_mut(&mut app.world)
        .ok()
    {
        let cursor_pos = simulate_world_to_screen_pos(click_world_pos);
        window.set_cursor_position(Some(cursor_pos));
    }

    // Press mouse button
    let mut mouse_input = Input::<MouseButton>::default();
    mouse_input.press(MouseButton::Left);
    app.world.insert_resource(mouse_input);

    // Run drag start system
    app.world.run_system_once(handle_drag_start);

    // Check if drag was detected
    let drag_detected = app.world.get::<Dragging>(piece_entity).is_some();

    if drag_detected {
        // Step 2: Mouse move (drag update) - simulate small movement
        let drag_pos = Vec2::new(click_world_pos.x + 1.0, click_world_pos.y + 1.0);
        if let Some(mut window) = app
            .world
            .query::<&mut Window>()
            .get_single_mut(&mut app.world)
            .ok()
        {
            let cursor_pos = simulate_world_to_screen_pos(drag_pos);
            window.set_cursor_position(Some(cursor_pos));
        }

        app.world.run_system_once(handle_drag_update);

        // Step 3: Mouse release (end drag) - drop very close to original position
        let drop_pos = Vec2::new(click_world_pos.x + 0.5, click_world_pos.y + 0.5);
        if let Some(mut window) = app
            .world
            .query::<&mut Window>()
            .get_single_mut(&mut app.world)
            .ok()
        {
            let cursor_pos = simulate_world_to_screen_pos(drop_pos);
            window.set_cursor_position(Some(cursor_pos));
        }

        // Release mouse button
        let mut mouse_input = Input::<MouseButton>::default();
        mouse_input.release(MouseButton::Left);
        app.world.insert_resource(mouse_input);

        // Run drag end system
        app.world.run_system_once(handle_drag_end);

        // Check what target was found
        target_found = Some(world_to_board_position(drop_pos));
    }

    DragResult {
        drag_detected,
        target_found,
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

fn world_to_board_position(world_pos: Vec2) -> (u8, u8) {
    let enhanced_tile_size = TILE_SIZE * 1.2;
    let x = ((world_pos.x / enhanced_tile_size) + BOARD_WIDTH as f32 / 2.0 - 0.5).round() as i8;
    let y = ((world_pos.y / enhanced_tile_size) + BOARD_HEIGHT as f32 / 2.0 - 0.5).round() as i8;

    let x = x.max(0).min(BOARD_WIDTH as i8 - 1) as u8;
    let y = y.max(0).min(BOARD_HEIGHT as i8 - 1) as u8;

    (x, y)
}

/// Test coordinate conversion precision
#[test]
fn test_coordinate_conversion_precision() {
    println!("🎯 Coordinate Conversion Precision Test");
    println!("   Testing if coordinate conversions cause precision issues");

    let start_pos = (4, 3);
    let start_world = board_to_world_position(start_pos);

    println!("\n🔍 Testing coordinate round-trip precision:");

    let test_cases = vec![
        ("Exact position", start_world),
        ("1px offset", Vec2::new(start_world.x + 1.0, start_world.y)),
        ("5px offset", Vec2::new(start_world.x + 5.0, start_world.y)),
        (
            "10px offset",
            Vec2::new(start_world.x + 10.0, start_world.y),
        ),
        (
            "20px offset",
            Vec2::new(start_world.x + 20.0, start_world.y),
        ),
        (
            "Half tile away",
            Vec2::new(start_world.x + 38.4, start_world.y),
        ),
    ];

    for (test_name, world_pos) in test_cases {
        let converted_board = world_to_board_position(world_pos);
        let back_to_world = board_to_world_position(converted_board);

        println!(
            "   {}: world ({:.1}, {:.1})",
            test_name, world_pos.x, world_pos.y
        );
        println!("     -> board: {:?}", converted_board);
        println!(
            "     -> back to world: ({:.1}, {:.1})",
            back_to_world.x, back_to_world.y
        );

        let is_same_board_position = converted_board == start_pos;
        println!(
            "     Same board position as start: {}",
            is_same_board_position
        );

        if is_same_board_position {
            println!("     ✅ Would correctly NOT end turn (same position)");
        } else {
            println!(
                "     ⚠️ Would end turn (different position: {:?})",
                converted_board
            );
        }
        println!();
    }

    println!("✅ Coordinate Conversion Test Complete");
}
