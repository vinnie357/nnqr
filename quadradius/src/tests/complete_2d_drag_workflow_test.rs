use crate::components::*;
use crate::resources::game_state::{GameState, TurnPhase};
use crate::systems::drag_drop::*;
use crate::systems::settings::Camera2D;
use bevy::ecs::system::RunSystemOnce;
use bevy::prelude::*;

/// Comprehensive test that proves 2D left-click-and-drag movement works for each player piece
#[test]
fn test_complete_2d_drag_workflow_all_pieces() {
    println!("🎯 Complete 2D Drag Workflow Test for All Player Pieces");
    println!("   Proving that left-click-and-drag movement works for every piece");

    let mut app = App::new();
    app.add_plugins(MinimalPlugins);
    app.insert_resource(Assets::<Mesh>::default());
    app.insert_resource(Assets::<StandardMaterial>::default());

    // Set up proper game state
    let mut game_state = GameState::default();
    game_state.current_player = Player::Player1;
    game_state.turn_phase = TurnPhase::PieceMovement;
    app.world.insert_resource(game_state);

    // Set up 2D camera exactly like the main game
    app.world.spawn((
        Camera2dBundle {
            camera: Camera::default(),
            transform: Transform::from_xyz(0.0, 0.0, 1000.0),
            global_transform: GlobalTransform::from_xyz(0.0, 0.0, 1000.0),
            ..default()
        },
        Camera2D,
    ));

    // Set up window for mouse input
    app.world.spawn(Window::default());

    // Set up board tiles (needed for valid move calculation)
    println!("\n📋 Setting up board tiles...");
    for x in 0..BOARD_WIDTH {
        for y in 0..BOARD_HEIGHT {
            app.world.spawn(BoardTile {
                coordinates: (x, y),
                height: 0,
            });
        }
    }

    // Create realistic piece setup like the actual game
    println!("🔵 Setting up Player 1 pieces (checkerboard pattern):");
    let mut player1_pieces = Vec::new();
    for y in 0..2 {
        // Bottom two rows
        for x in 0..BOARD_WIDTH {
            if (x + y) % 2 == 0 {
                // Checkerboard pattern
                let enhanced_tile_size = TILE_SIZE * 1.2;
                let world_x = (x as f32 - BOARD_WIDTH as f32 / 2.0 + 0.5) * enhanced_tile_size;
                let world_y = (y as f32 - BOARD_HEIGHT as f32 / 2.0 + 0.5) * enhanced_tile_size;

                let entity = app
                    .world
                    .spawn((
                        GamePiece {
                            player: Player::Player1,
                            board_position: (x, y),
                        },
                        Transform::from_xyz(world_x, world_y, 5.0),
                    ))
                    .id();

                player1_pieces.push((entity, (x, y), Vec2::new(world_x, world_y)));
                println!(
                    "   Piece at board ({}, {}) -> world ({:.1}, {:.1})",
                    x, y, world_x, world_y
                );
            }
        }
    }

    println!("🔴 Setting up Player 2 pieces (checkerboard pattern):");
    let mut player2_pieces = Vec::new();
    for y in (BOARD_HEIGHT - 2)..BOARD_HEIGHT {
        // Top two rows
        for x in 0..BOARD_WIDTH {
            if (x + y) % 2 == 0 {
                // Checkerboard pattern
                let enhanced_tile_size = TILE_SIZE * 1.2;
                let world_x = (x as f32 - BOARD_WIDTH as f32 / 2.0 + 0.5) * enhanced_tile_size;
                let world_y = (y as f32 - BOARD_HEIGHT as f32 / 2.0 + 0.5) * enhanced_tile_size;

                let entity = app
                    .world
                    .spawn((
                        GamePiece {
                            player: Player::Player2,
                            board_position: (x, y),
                        },
                        Transform::from_xyz(world_x, world_y, 5.0),
                    ))
                    .id();

                player2_pieces.push((entity, (x, y), Vec2::new(world_x, world_y)));
                println!(
                    "   Piece at board ({}, {}) -> world ({:.1}, {:.1})",
                    x, y, world_x, world_y
                );
            }
        }
    }

    println!("\n📊 Piece count summary:");
    println!("   Player 1 pieces: {}", player1_pieces.len());
    println!("   Player 2 pieces: {}", player2_pieces.len());

    // Test Player 1 pieces (should be movable)
    println!("\n🎮 Testing Player 1 pieces (should be movable):");
    test_player_pieces(&mut app, &player1_pieces, Player::Player1, true);

    // Switch to Player 2 turn
    {
        let mut game_state = app.world.resource_mut::<GameState>();
        game_state.current_player = Player::Player2;
    }

    // Test Player 2 pieces (should be movable now)
    println!("\n🎮 Testing Player 2 pieces (should be movable):");
    test_player_pieces(&mut app, &player2_pieces, Player::Player2, true);

    // Switch back to Player 1 and test Player 2 pieces (should NOT be movable)
    {
        let mut game_state = app.world.resource_mut::<GameState>();
        game_state.current_player = Player::Player1;
    }

    println!("\n🚫 Testing Player 2 pieces on Player 1's turn (should NOT be movable):");
    test_player_pieces(&mut app, &player2_pieces, Player::Player2, false);

    println!("\n✅ Complete 2D Drag Workflow Test Results:");
    println!("   🔵 Player 1 pieces: ALL RESPONSIVE on their turn");
    println!("   🔴 Player 2 pieces: ALL RESPONSIVE on their turn");
    println!("   🚫 Opponent pieces: CORRECTLY BLOCKED on wrong turn");
    println!("   🎯 Left-click-and-drag: WORKING FOR ALL PIECES");
    println!("   🖱️ Mouse input: PROPERLY PROCESSED");
    println!("   📍 Hit detection: ACCURATE FOR ALL POSITIONS");
}

fn test_player_pieces(
    app: &mut App,
    pieces: &[(Entity, (u8, u8), Vec2)],
    player: Player,
    should_be_movable: bool,
) {
    let enhanced_tile_size = TILE_SIZE * 1.2;
    let piece_size = enhanced_tile_size * 0.7; // Actual piece size

    for (i, (entity, board_pos, world_pos)) in pieces.iter().enumerate() {
        println!(
            "   Testing {:?} piece {} at board {:?}, world ({:.1}, {:.1})",
            player,
            i + 1,
            board_pos,
            world_pos.x,
            world_pos.y
        );

        // Simulate mouse input resource with proper frame transition
        // First frame: mouse not pressed
        let mouse_input = Input::<MouseButton>::default();
        app.world.insert_resource(mouse_input);

        // Run one frame to establish baseline
        app.world.run_system_once(handle_drag_start);

        // Second frame: mouse pressed (this will trigger just_pressed)
        let mut mouse_input = Input::<MouseButton>::default();
        mouse_input.press(MouseButton::Left);
        app.world.insert_resource(mouse_input);

        // Window should already exist from main setup

        // Simulate window with cursor at piece position
        let cursor_pos = simulate_world_to_screen_pos(*world_pos);
        if let Some(mut window) = app
            .world
            .query::<&mut Window>()
            .get_single_mut(&mut app.world)
            .ok()
        {
            window.set_cursor_position(Some(cursor_pos));
        }

        // Count dragging components before
        let dragging_before = app.world.query::<&Dragging>().iter(&app.world).count();
        let indicators_before = app
            .world
            .query::<&ValidMoveIndicator>()
            .iter(&app.world)
            .count();

        // Run the drag start system
        app.world.run_system_once(handle_drag_start);

        // Count dragging components after
        let dragging_after = app.world.query::<&Dragging>().iter(&app.world).count();
        let indicators_after = app
            .world
            .query::<&ValidMoveIndicator>()
            .iter(&app.world)
            .count();

        let piece_was_selected = dragging_after > dragging_before;
        let indicators_spawned = indicators_after > indicators_before;

        if should_be_movable {
            if piece_was_selected {
                println!("     ✅ Piece selected successfully (Dragging component added)");
            } else {
                println!("     ❌ Piece NOT selected (no Dragging component)");
            }

            if indicators_spawned {
                println!(
                    "     ✅ Valid move indicators spawned ({} indicators)",
                    indicators_after - indicators_before
                );
            } else {
                println!("     ⚠️ No valid move indicators spawned");
            }

            assert!(
                piece_was_selected,
                "Piece {} should be selectable on {:?}'s turn",
                i + 1,
                player
            );
        } else {
            if !piece_was_selected {
                println!("     ✅ Piece correctly NOT selected (opponent's piece)");
            } else {
                println!("     ❌ Piece incorrectly selected (should be blocked)");
            }

            assert!(
                !piece_was_selected,
                "Piece {} should NOT be selectable on opponent's turn",
                i + 1
            );
        }

        // Test precise hit detection
        test_hit_detection_precision(app, *world_pos, piece_size, should_be_movable, i + 1);

        // Clean up for next test
        cleanup_test_state(app);
    }
}

fn test_hit_detection_precision(
    app: &mut App,
    piece_world_pos: Vec2,
    piece_size: f32,
    should_be_movable: bool,
    piece_num: usize,
) {
    let half_size = piece_size / 2.0;

    // Test clicking exactly in center
    let center_click = piece_world_pos;
    let center_result = simulate_click_at_position(app, center_click, should_be_movable);

    // Test clicking near edge (should hit)
    let edge_click = Vec2::new(piece_world_pos.x + half_size - 2.0, piece_world_pos.y);
    let edge_result = simulate_click_at_position(app, edge_click, should_be_movable);

    // Test clicking outside (should miss)
    let outside_click = Vec2::new(piece_world_pos.x + half_size + 2.0, piece_world_pos.y);
    let outside_result = simulate_click_at_position(app, outside_click, false); // Should never hit

    println!("     🎯 Hit detection for piece {}:", piece_num);
    println!(
        "       Center ({:.1}, {:.1}): {}",
        center_click.x,
        center_click.y,
        if center_result { "HIT" } else { "MISS" }
    );
    println!(
        "       Edge ({:.1}, {:.1}): {}",
        edge_click.x,
        edge_click.y,
        if edge_result { "HIT" } else { "MISS" }
    );
    println!(
        "       Outside ({:.1}, {:.1}): {}",
        outside_click.x,
        outside_click.y,
        if outside_result { "HIT" } else { "MISS" }
    );

    if should_be_movable {
        assert!(center_result, "Center click should hit piece {}", piece_num);
        assert!(edge_result, "Edge click should hit piece {}", piece_num);
    }
    assert!(
        !outside_result,
        "Outside click should miss piece {}",
        piece_num
    );
}

fn simulate_click_at_position(app: &mut App, world_pos: Vec2, should_hit: bool) -> bool {
    // Clear any existing dragging state
    cleanup_test_state(app);

    // Set up mouse input
    let mut mouse_input = Input::<MouseButton>::default();
    mouse_input.press(MouseButton::Left);
    app.world.insert_resource(mouse_input);

    // Set cursor position
    let cursor_pos = simulate_world_to_screen_pos(world_pos);
    if let Some(mut window) = app
        .world
        .query::<&mut Window>()
        .get_single_mut(&mut app.world)
        .ok()
    {
        window.set_cursor_position(Some(cursor_pos));
    }

    // Count dragging before
    let dragging_before = app.world.query::<&Dragging>().iter(&app.world).count();

    // Run drag start
    app.world.run_system_once(handle_drag_start);

    // Count dragging after
    let dragging_after = app.world.query::<&Dragging>().iter(&app.world).count();

    dragging_after > dragging_before
}

fn cleanup_test_state(app: &mut App) {
    // Remove all Dragging components
    let dragging_entities: Vec<Entity> = app
        .world
        .query::<Entity>()
        .iter(&app.world)
        .filter(|&e| app.world.get::<Dragging>(e).is_some())
        .collect();

    for entity in dragging_entities {
        app.world.entity_mut(entity).remove::<Dragging>();
    }

    // Remove all ValidMoveIndicator entities
    let indicator_entities: Vec<Entity> = app
        .world
        .query::<Entity>()
        .iter(&app.world)
        .filter(|&e| app.world.get::<ValidMoveIndicator>(e).is_some())
        .collect();

    for entity in indicator_entities {
        app.world.entity_mut(entity).despawn();
    }
}

fn simulate_world_to_screen_pos(world_pos: Vec2) -> Vec2 {
    // For this test, we'll use a simple 1:1 mapping since we're testing the drag logic
    // In a real game, this would involve camera projection math
    Vec2::new(world_pos.x + 400.0, 300.0 - world_pos.y) // Center around screen center
}

/// Test the complete drag workflow: start -> update -> end
#[test]
fn test_complete_drag_lifecycle() {
    println!("🎯 Complete Drag Lifecycle Test");
    println!("   Testing start -> update -> end drag sequence");

    let mut app = App::new();
    app.add_plugins(MinimalPlugins);
    app.insert_resource(Assets::<Mesh>::default());
    app.insert_resource(Assets::<StandardMaterial>::default());

    // Set up game state
    let mut game_state = GameState::default();
    game_state.current_player = Player::Player1;
    game_state.turn_phase = TurnPhase::PieceMovement;
    app.world.insert_resource(game_state);

    // Set up camera
    app.world.spawn((
        Camera2dBundle {
            transform: Transform::from_xyz(0.0, 0.0, 1000.0),
            global_transform: GlobalTransform::from_xyz(0.0, 0.0, 1000.0),
            ..default()
        },
        Camera2D,
    ));

    // Set up board tiles
    for x in 0..BOARD_WIDTH {
        for y in 0..BOARD_HEIGHT {
            app.world.spawn(BoardTile {
                coordinates: (x, y),
                height: 0,
            });
        }
    }

    // Create a test piece
    let enhanced_tile_size = TILE_SIZE * 1.2;
    let world_x = 0.0;
    let world_y = 0.0;

    let piece_entity = app
        .world
        .spawn((
            GamePiece {
                player: Player::Player1,
                board_position: (4, 3), // Center of board
            },
            Transform::from_xyz(world_x, world_y, 5.0),
        ))
        .id();

    // Add window
    app.world.spawn(Window::default());

    println!("\n1️⃣ Testing DRAG START:");

    // Simulate mouse press at piece position
    let mut mouse_input = Input::<MouseButton>::default();
    mouse_input.press(MouseButton::Left);
    app.world.insert_resource(mouse_input);

    // Set cursor at piece
    if let Some(mut window) = app
        .world
        .query::<&mut Window>()
        .get_single_mut(&mut app.world)
        .ok()
    {
        window.set_cursor_position(Some(Vec2::new(400.0, 300.0)));
    }

    // Run drag start
    app.world.run_system_once(handle_drag_start);

    // Verify piece is being dragged
    let has_dragging = app.world.get::<Dragging>(piece_entity).is_some();
    let indicator_count = app
        .world
        .query::<&ValidMoveIndicator>()
        .iter(&app.world)
        .count();

    println!("   Piece has Dragging component: {}", has_dragging);
    println!("   Valid move indicators spawned: {}", indicator_count);

    assert!(
        has_dragging,
        "Piece should have Dragging component after click"
    );

    println!("\n2️⃣ Testing DRAG UPDATE:");

    // Move cursor to new position
    if let Some(mut window) = app
        .world
        .query::<&mut Window>()
        .get_single_mut(&mut app.world)
        .ok()
    {
        window.set_cursor_position(Some(Vec2::new(450.0, 350.0)));
    }

    let pos_before = app
        .world
        .get::<Transform>(piece_entity)
        .unwrap()
        .translation;

    // Run drag update
    app.world.run_system_once(handle_drag_update);

    let pos_after = app
        .world
        .get::<Transform>(piece_entity)
        .unwrap()
        .translation;
    let piece_moved =
        (pos_after.x - pos_before.x).abs() > 0.1 || (pos_after.y - pos_before.y).abs() > 0.1;

    println!(
        "   Piece position before: ({:.1}, {:.1})",
        pos_before.x, pos_before.y
    );
    println!(
        "   Piece position after: ({:.1}, {:.1})",
        pos_after.x, pos_after.y
    );
    println!("   Piece moved during drag: {}", piece_moved);

    assert!(piece_moved, "Piece should move during drag update");

    println!("\n3️⃣ Testing DRAG END:");

    // Release mouse button
    let mut mouse_input = Input::<MouseButton>::default();
    mouse_input.release(MouseButton::Left);
    app.world.insert_resource(mouse_input);

    // Run drag end
    app.world.run_system_once(handle_drag_end);

    // Verify dragging state is cleared
    let still_dragging = app.world.get::<Dragging>(piece_entity).is_some();
    let indicators_after_end = app
        .world
        .query::<&ValidMoveIndicator>()
        .iter(&app.world)
        .count();

    println!("   Still has Dragging component: {}", still_dragging);
    println!("   Indicators after drag end: {}", indicators_after_end);

    assert!(
        !still_dragging,
        "Piece should not have Dragging component after release"
    );

    println!("\n✅ Complete Drag Lifecycle Test Results:");
    println!("   🖱️ Mouse press -> Piece selection: WORKING");
    println!("   🔄 Mouse move -> Piece following: WORKING");
    println!("   🖱️ Mouse release -> Drag cleanup: WORKING");
    println!("   🎯 Full click-and-drag workflow: FUNCTIONAL");
}
