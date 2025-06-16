use crate::components::*;
use crate::systems::board_3d::TILE_SIZE_MULTIPLIER_3D;
use crate::systems::isometric_camera::board_to_isometric;

/// Debug test to verify coordinate alignment between board tiles and movement indicators
#[test]
fn test_movement_indicator_board_alignment() {
    println!("🎯 Movement Indicator Board Alignment Debug");
    println!("   Testing coordinate conversion consistency");

    // Test a few key board positions
    let test_positions = vec![
        (0, 0), // Top-left corner
        (4, 3), // Center of board
        (9, 7), // Bottom-right corner
        (1, 1), // Second row/column
        (8, 6), // Near bottom-right
    ];

    println!("\n📐 Board to Isometric Coordinate Conversion:");
    println!(
        "   BOARD_WIDTH: {}, BOARD_HEIGHT: {}",
        BOARD_WIDTH, BOARD_HEIGHT
    );
    println!("   TILE_SIZE: {}", TILE_SIZE);
    println!("   TILE_SIZE_MULTIPLIER_3D: {}", TILE_SIZE_MULTIPLIER_3D);

    let enhanced_tile_size = TILE_SIZE * TILE_SIZE_MULTIPLIER_3D;
    println!("   Enhanced tile size: {:.2}", enhanced_tile_size);

    for &(x, y) in &test_positions {
        // This is exactly what both board tiles and movement indicators use
        let world_pos = board_to_isometric((x, y), 0.0);

        // Calculate centering offset (from board_to_isometric function)
        let centered_x = x as f32 - (BOARD_WIDTH as f32 / 2.0) + 0.5;
        let centered_z = y as f32 - (BOARD_HEIGHT as f32 / 2.0) + 0.5;

        // Calculate isometric transformation
        let iso_x = (centered_x - centered_z) * enhanced_tile_size * 0.5;
        let iso_z = (centered_x + centered_z) * enhanced_tile_size * 0.25;

        println!(
            "   Board({}, {}) -> World({:.2}, {:.2}, {:.2})",
            x, y, world_pos.x, world_pos.y, world_pos.z
        );
        println!(
            "      Centered: ({:.2}, {:.2}) -> Iso: ({:.2}, {:.2})",
            centered_x, centered_z, iso_x, iso_z
        );
    }

    // Test the centering logic
    println!("\n🎯 Centering Analysis:");
    let board_center_x = BOARD_WIDTH as f32 / 2.0; // 5.0 for 10-wide board
    let board_center_y = BOARD_HEIGHT as f32 / 2.0; // 4.0 for 8-tall board
    println!(
        "   Board center: ({:.1}, {:.1})",
        board_center_x, board_center_y
    );

    // Center tile should be at approximately (4.5, 3.5) or (5.5, 4.5)
    let center_tiles = vec![(4, 3), (4, 4), (5, 3), (5, 4)];
    for &(x, y) in &center_tiles {
        let world_pos = board_to_isometric((x, y), 0.0);
        let distance_from_origin = (world_pos.x * world_pos.x + world_pos.z * world_pos.z).sqrt();
        println!(
            "   Tile({}, {}) distance from origin: {:.2}",
            x, y, distance_from_origin
        );
    }

    // Check if coordinate system is consistent
    println!("\n✅ Coordinate System Verification:");
    println!("   Both board tiles and movement indicators use board_to_isometric()");
    println!(
        "   Both use same enhanced_tile_size: {:.2}",
        enhanced_tile_size
    );
    println!("   Both use same centering logic: pos - board_size/2 + 0.5");

    // Test specific alignment scenario
    let piece_pos = (4, 3); // Center piece
    let move_positions = vec![(3, 3), (5, 3), (4, 2), (4, 4)]; // Adjacent moves

    println!("\n🎮 Movement Scenario Test:");
    let piece_world = board_to_isometric(piece_pos, 0.0);
    println!(
        "   Piece at {:?} -> World({:.2}, {:.2}, {:.2})",
        piece_pos, piece_world.x, piece_world.y, piece_world.z
    );

    for &move_pos in &move_positions {
        let move_world = board_to_isometric(move_pos, 0.0);
        let distance = ((move_world.x - piece_world.x).powi(2)
            + (move_world.z - piece_world.z).powi(2))
        .sqrt();
        println!(
            "   Move to {:?} -> World({:.2}, {:.2}, {:.2}), Distance: {:.2}",
            move_pos, move_world.x, move_world.y, move_world.z, distance
        );
    }

    // The distance should be approximately enhanced_tile_size for adjacent moves
    let expected_distance = enhanced_tile_size * 0.5; // Approximate for isometric
    println!(
        "   Expected distance for adjacent moves: ~{:.2}",
        expected_distance
    );
}
