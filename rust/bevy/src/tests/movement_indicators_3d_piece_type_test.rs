use crate::components::*;
use crate::resources::*;
use crate::systems::enhanced_move_indicators_3d::*;
use crate::systems::pieces_3d::GamePiece3D;
use bevy::app::App;
use bevy::ecs::system::RunSystemOnce;
use bevy::prelude::*;

fn setup_test_app() -> App {
    let mut app = App::new();
    
    // Add minimal plugins required for testing
    app.add_plugins(MinimalPlugins);
    
    // Add required resources that the systems expect
    app.insert_resource(GameState::default())
       .insert_resource(RenderConfig::default())
       .insert_resource(crate::resources::game_state::TurnCounter::default())
       .insert_resource(PowerSpawningTracker::default())
       .insert_resource(Assets::<Mesh>::default())
       .insert_resource(Assets::<StandardMaterial>::default());
    
    app
}

/// Test to verify 3D movement indicators work with GamePiece3D entities (not just GamePiece)
#[test]
fn test_3d_movement_indicators_with_gamepiece3d() {
    println!("🎯 3D Movement Indicators with GamePiece3D Test");
    println!("   This test verifies the fix for querying both GamePiece and GamePiece3D");

    let app = setup_test_app();

    let mut world = app.world;

    // Setup board tiles
    for x in 0..BOARD_WIDTH {
        for y in 0..BOARD_HEIGHT {
            world.spawn(BoardTile {
                coordinates: (x, y),
                height: 0,
            });
        }
    }

    // Create a GamePiece3D entity (what the 3D drag system actually selects)
    println!("🔵 Creating GamePiece3D at (4, 3) with Selected component...");
    let piece_3d_entity = world
        .spawn((
            GamePiece3D {
                player: Player::Player1,
                board_position: (4, 3),
            },
            Selected, // This is what drag_drop_3d.rs adds
        ))
        .id();

    // Also create some regular GamePiece entities for position validation
    world.spawn(GamePiece {
        player: Player::Player2,
        board_position: (5, 3), // Enemy piece for attack moves
    });

    // Verify initial state
    let selected_3d_count = world
        .query::<(&GamePiece3D, &Selected)>()
        .iter(&world)
        .count();
    let selected_2d_count = world
        .query::<(&GamePiece, &Selected)>()
        .iter(&world)
        .count();
    let initial_indicators = world.query::<&ValidMoveIndicator3D>().iter(&world).count();

    println!("📊 Initial state:");
    println!("   Selected 3D pieces: {}", selected_3d_count);
    println!("   Selected 2D pieces: {}", selected_2d_count);
    println!("   Initial indicators: {}", initial_indicators);

    assert_eq!(selected_3d_count, 1, "Should have 1 selected GamePiece3D");
    assert_eq!(selected_2d_count, 0, "Should have no selected GamePiece");
    assert_eq!(initial_indicators, 0, "Should start with no indicators");

    // Run the enhanced 3D movement indicator system
    println!("🔧 Running enhanced movement indicator system...");
    world.run_system_once(show_valid_moves_for_powers_3d);

    // Verify indicators were spawned for the GamePiece3D
    let final_indicators = world.query::<&ValidMoveIndicator3D>().iter(&world).count();
    println!("📊 Indicators spawned: {}", final_indicators);

    // The fix should now detect GamePiece3D entities
    assert!(
        final_indicators > 0,
        "❌ CRITICAL: No indicators spawned for GamePiece3D! The alignment issue persists."
    );

    // Verify expected number of moves (should be 3-4 for center position)
    assert!(
        (3..=8).contains(&final_indicators),
        "Should spawn 3-8 movement indicators for center piece, got {}",
        final_indicators
    );

    // Verify indicators have proper 3D rendering components
    let indicators_with_components = world
        .query::<(
            &ValidMoveIndicator3D,
            &Handle<Mesh>,
            &Handle<StandardMaterial>,
        )>()
        .iter(&world)
        .count();
    assert_eq!(
        indicators_with_components, final_indicators,
        "All indicators should have 3D rendering components"
    );

    println!("✅ SUCCESS: GamePiece3D entities now trigger movement indicators!");
    println!("   This should fix the board alignment issue in the actual game.");
    println!("   3D drag system selects GamePiece3D -> indicators appear correctly");
}

/// Test the specific scenario that was failing: GamePiece3D selection in 3D mode
#[test]
fn test_3d_drag_system_compatibility() {
    println!("🎯 3D Drag System Compatibility Test");
    println!("   Testing the exact workflow: drag_drop_3d -> enhanced_move_indicators_3d");

    let app = setup_test_app();

    let mut world = app.world;

    // Setup board
    for x in 0..BOARD_WIDTH {
        for y in 0..BOARD_HEIGHT {
            world.spawn(BoardTile {
                coordinates: (x, y),
                height: 0,
            });
        }
    }

    // Simulate what drag_drop_3d.rs does:
    // 1. It queries GamePiece3D entities
    // 2. When clicked, it adds Selected component to the GamePiece3D entity

    println!("🎮 Simulating 3D drag system workflow:");
    println!("   1. Player clicks on 3D piece");

    let piece_entity = world
        .spawn(GamePiece3D {
            player: Player::Player1,
            board_position: (3, 4),
        })
        .id();

    println!("   2. Drag system adds Selected component to GamePiece3D");
    world.entity_mut(piece_entity).insert(Selected);

    println!("   3. Enhanced indicator system should detect selected GamePiece3D");

    // Before fix: system only queried GamePiece, would miss GamePiece3D
    // After fix: system queries both GamePiece and GamePiece3D

    world.run_system_once(show_valid_moves_for_powers_3d);

    let indicators = world.query::<&ValidMoveIndicator3D>().iter(&world).count();
    println!("   4. Result: {} movement indicators spawned", indicators);

    assert!(
        indicators > 0,
        "Should spawn indicators for selected GamePiece3D"
    );

    // Verify specific positions are accessible from (3,4)
    let expected_moves = vec![(2, 4), (4, 4), (3, 3), (3, 5)];
    let mut found_moves = 0;

    for &expected_pos in &expected_moves {
        if expected_pos.0 < BOARD_WIDTH && expected_pos.1 < BOARD_HEIGHT {
            let found = world
                .query::<&ValidMoveIndicator3D>()
                .iter(&world)
                .any(|indicator| indicator.coordinates == expected_pos);
            if found {
                found_moves += 1;
                println!("   ✅ Found indicator at {:?}", expected_pos);
            }
        }
    }

    assert!(
        found_moves >= 2,
        "Should find at least 2 adjacent move indicators"
    );

    println!("✅ 3D drag workflow compatibility verified!");
    println!("   The movement grid should now align correctly with board spaces!");
}
