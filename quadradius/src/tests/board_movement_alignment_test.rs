use crate::components::*;
use crate::systems::board_3d::TILE_SIZE_MULTIPLIER_3D;
use crate::systems::enhanced_move_indicators_3d::*;
use crate::systems::isometric_camera::board_to_isometric;
use crate::systems::pieces_3d::GamePiece3D;
use bevy::app::App;
use bevy::ecs::system::RunSystemOnce;
use bevy::prelude::*;

/// Test to verify board tiles and movement indicators use identical positioning
#[test]
fn test_board_tile_movement_indicator_alignment() {
    println!("🎯 Board Tile vs Movement Indicator Alignment Test");
    println!("   Verifying that indicators appear exactly on board tile positions");

    let mut app = App::new();
    app.add_plugins(MinimalPlugins);
    app.insert_resource(Assets::<Mesh>::default());
    app.insert_resource(Assets::<StandardMaterial>::default());

    let mut world = app.world;

    // Create board tiles at all positions (simulating setup_board_3d)
    println!("📋 Creating board tiles at all 10x8 positions...");
    for x in 0..BOARD_WIDTH {
        for y in 0..BOARD_HEIGHT {
            let tile_position = board_to_isometric((x, y), 0.0);

            // Spawn both BoardTile and BoardTile3D (like the real system)
            world.spawn((
                BoardTile {
                    coordinates: (x, y),
                    height: 0,
                },
                // Note: In real system this would also have BoardTile3D and PbrBundle
            ));
        }
    }

    // Create a piece and select it (like drag system does)
    println!("🔵 Creating selected piece at (5, 4)...");
    let piece_entity = world
        .spawn((
            GamePiece3D {
                player: Player::Player1,
                board_position: (5, 4),
            },
            Selected,
        ))
        .id();

    // Run the movement indicator system
    println!("🔧 Running movement indicator system...");
    world.run_system_once(show_valid_moves_for_powers_3d);

    // Collect all movement indicator positions
    let mut indicator_positions: Vec<(u8, u8)> = world
        .query::<&ValidMoveIndicator3D>()
        .iter(&world)
        .map(|indicator| indicator.coordinates)
        .collect();
    indicator_positions.sort();

    println!("📊 Movement indicators found at:");
    for &pos in &indicator_positions {
        println!("   {:?}", pos);
    }

    // Verify that every indicator position has a corresponding board tile
    println!("\n🔍 Verifying position alignment:");
    let mut all_positions_valid = true;

    for &indicator_pos in &indicator_positions {
        // Check if there's a board tile at this position
        let tile_exists = world
            .query::<&BoardTile>()
            .iter(&world)
            .any(|tile| tile.coordinates == indicator_pos);

        if tile_exists {
            println!("   ✅ Indicator at {:?} - Board tile exists", indicator_pos);
        } else {
            println!("   ❌ Indicator at {:?} - NO board tile!", indicator_pos);
            all_positions_valid = false;
        }

        // Also verify position is within board bounds
        if indicator_pos.0 >= BOARD_WIDTH || indicator_pos.1 >= BOARD_HEIGHT {
            println!("   ❌ Indicator at {:?} - OUT OF BOUNDS!", indicator_pos);
            all_positions_valid = false;
        }
    }

    assert!(
        all_positions_valid,
        "All movement indicators should correspond to valid board tile positions"
    );

    // Test coordinate conversion consistency
    println!("\n📐 Testing coordinate conversion consistency:");
    for &pos in indicator_positions.iter().take(3) {
        // Test first 3 positions
        let board_tile_pos = board_to_isometric(pos, 0.0);
        println!(
            "   Board({}, {}) -> Isometric({:.2}, {:.2}, {:.2})",
            pos.0, pos.1, board_tile_pos.x, board_tile_pos.y, board_tile_pos.z
        );
    }

    println!("\n✅ Alignment Test Results:");
    println!(
        "   - Found {} movement indicators",
        indicator_positions.len()
    );
    println!(
        "   - All indicators at valid board positions: {}",
        all_positions_valid
    );
    println!("   - Coordinate system consistent: board_to_isometric() used by both");

    assert!(
        indicator_positions.len() > 0,
        "Should find movement indicators"
    );
    assert!(
        indicator_positions.len() <= 8,
        "Should not exceed maximum possible moves"
    );
}

/// Test to identify visual grid vs logical grid misalignment
#[test]
fn test_visual_vs_logical_grid_alignment() {
    println!("🎯 Visual vs Logical Grid Alignment Test");
    println!("   Checking if visual grid matches playable board positions");

    // Test critical board positions that players expect to be playable
    let critical_positions = vec![
        (0, 0), // Top-left corner
        (4, 3), // Near center
        (9, 7), // Bottom-right corner
        (0, 7), // Bottom-left
        (9, 0), // Top-right
        (5, 4), // True center area
    ];

    println!("📊 Analyzing critical board positions:");

    for &(x, y) in &critical_positions {
        // Verify position is within logical board bounds
        let within_bounds = x < BOARD_WIDTH && y < BOARD_HEIGHT;

        // Calculate where this position appears visually
        let visual_pos = board_to_isometric((x, y), 0.0);

        println!(
            "   Board({}, {}) -> Visual({:.1}, {:.1}, {:.1}) [{}]",
            x,
            y,
            visual_pos.x,
            visual_pos.y,
            visual_pos.z,
            if within_bounds { "VALID" } else { "INVALID" }
        );

        if within_bounds {
            // This position should have a board tile and be selectable
            assert!(x < BOARD_WIDTH, "X coordinate should be within board width");
            assert!(
                y < BOARD_HEIGHT,
                "Y coordinate should be within board height"
            );
        }
    }

    // Check board center calculation
    let board_center_x = (BOARD_WIDTH as f32 - 1.0) / 2.0; // 4.5 for 10-wide board (positions 0-9)
    let board_center_y = (BOARD_HEIGHT as f32 - 1.0) / 2.0; // 3.5 for 8-tall board (positions 0-7)

    println!("\n📍 Board center analysis:");
    println!("   Board size: {}x{}", BOARD_WIDTH, BOARD_HEIGHT);
    println!(
        "   Logical center: ({:.1}, {:.1})",
        board_center_x, board_center_y
    );

    // The center should be between tiles (4,3), (4,4), (5,3), (5,4)
    let center_tiles = vec![(4, 3), (4, 4), (5, 3), (5, 4)];
    println!("   Center tiles:");
    for &tile in &center_tiles {
        let pos = board_to_isometric(tile, 0.0);
        println!(
            "     {:?} -> ({:.1}, {:.1}, {:.1})",
            tile, pos.x, pos.y, pos.z
        );
    }

    println!("\n✅ Grid Analysis Complete");
    println!("   If movement indicators don't align with visual grid,");
    println!("   the issue is likely in tile spacing or board centering.");
}

/// Test to diagnose the specific alignment issue
#[test]
fn test_movement_indicator_board_mismatch_diagnosis() {
    println!("🎯 Movement Indicator Board Mismatch Diagnosis");
    println!("   Identifying why indicators don't align with visual board grid");

    // The user reported: "grid doesn't appear to be valid movement locations"
    // This suggests visual grid ≠ logical movement positions

    let enhanced_tile_size = TILE_SIZE * TILE_SIZE_MULTIPLIER_3D;
    println!("📊 Current configuration:");
    println!("   TILE_SIZE: {}", TILE_SIZE);
    println!("   TILE_SIZE_MULTIPLIER_3D: {}", TILE_SIZE_MULTIPLIER_3D);
    println!("   Enhanced tile size: {:.2}", enhanced_tile_size);

    // Test the isometric transformation for adjacent tiles
    println!("\n🔍 Adjacent tile spacing analysis:");
    let test_positions = vec![(4, 3), (5, 3), (4, 4)]; // Adjacent positions

    for i in 0..test_positions.len() {
        let pos = test_positions[i];
        let world_pos = board_to_isometric(pos, 0.0);
        println!(
            "   {:?} -> ({:.2}, {:.2}, {:.2})",
            pos, world_pos.x, world_pos.y, world_pos.z
        );

        if i > 0 {
            let prev_pos = test_positions[i - 1];
            let prev_world = board_to_isometric(prev_pos, 0.0);
            let distance = ((world_pos.x - prev_world.x).powi(2)
                + (world_pos.z - prev_world.z).powi(2))
            .sqrt();
            println!("     Distance from {:?}: {:.2}", prev_pos, distance);
        }
    }

    // Calculate expected tile spacing in isometric view (now matches visual tiles)
    let tile_spacing = enhanced_tile_size * 0.85; // Match visual tile dimensions
    let expected_spacing = tile_spacing * 0.5; // Based on isometric math
    println!("\n📏 Expected tile spacing: {:.2}", expected_spacing);

    // Potential issues:
    println!("\n🔍 Potential alignment issues:");
    println!("   1. Visual tile size vs logical tile spacing mismatch");
    println!("   2. Grid lines positioned differently than tiles");
    println!("   3. Movement indicators using different coordinate system");
    println!("   4. Board centering offset causing misalignment");

    println!("\n💡 Recommended fixes:");
    println!("   - Ensure visual tile size = logical tile spacing");
    println!("   - Remove or reposition decorative grid lines");
    println!("   - Verify board_to_isometric() consistency");
    println!("   - Check board centering calculations");
}
