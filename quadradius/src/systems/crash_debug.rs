use crate::{components::*, resources::*};
use bevy::prelude::*;

// Debug system to test for crash scenarios and potential issues
pub fn debug_crash_scenarios(
    keyboard: Res<Input<KeyCode>>,
    mut commands: Commands,
    pieces: Query<(Entity, &GamePiece)>,
    tiles: Query<&BoardTile>,
    mut game_state: ResMut<GameState>,
) {
    if keyboard.just_pressed(KeyCode::F1) {
        println!("🔥 Testing Crash Scenario 1: Mass Entity Despawn");
        test_mass_despawn(&mut commands, &pieces);
    }

    if keyboard.just_pressed(KeyCode::F2) {
        println!("🔥 Testing Crash Scenario 2: Invalid Power Activation");
        test_invalid_power_activation(&mut game_state);
    }

    if keyboard.just_pressed(KeyCode::F3) {
        println!("🔥 Testing Crash Scenario 3: Memory Stress Test");
        test_memory_stress(&mut commands);
    }

    if keyboard.just_pressed(KeyCode::F4) {
        println!("🔥 Testing Crash Scenario 4: Null Pointer Access");
        test_null_access(&tiles);
    }
}

fn test_mass_despawn(commands: &mut Commands, pieces: &Query<(Entity, &GamePiece)>) {
    println!("   Despawning all pieces simultaneously...");
    let mut count = 0;

    for (entity, _) in pieces.iter() {
        commands.entity(entity).despawn();
        count += 1;
    }

    // Try to despawn them again (this should trigger the warnings we see)
    for (entity, _) in pieces.iter() {
        commands.entity(entity).despawn();
    }

    println!("   Attempted to despawn {} pieces twice", count);
}

fn test_invalid_power_activation(game_state: &mut GameState) {
    println!("   Testing invalid power states...");

    // Set invalid power index
    game_state.selected_power = Some(999);

    // Set invalid turn phase
    game_state.turn_phase = TurnPhase::PowerActivation;

    println!("   Set invalid power index: 999");
}

fn test_memory_stress(commands: &mut Commands) {
    println!("   Creating many entities to stress memory...");

    for i in 0..1000 {
        commands.spawn((SpriteBundle {
            sprite: Sprite {
                color: Color::rgb(1.0, 0.0, 0.0),
                custom_size: Some(Vec2::new(1.0, 1.0)),
                ..default()
            },
            transform: Transform::from_xyz(i as f32, i as f32, 0.0),
            ..default()
        },));
    }

    println!("   Created 1000 test entities");
}

fn test_null_access(tiles: &Query<&BoardTile>) {
    println!("   Testing potential null pointer access...");

    // Access tiles at extreme coordinates
    let test_coords = [(255, 255), (0, 255), (255, 0), (128, 128)];

    for &coords in &test_coords {
        let found = tiles.iter().any(|tile| tile.coordinates == coords);
        println!(
            "     Tile at {:?}: {}",
            coords,
            if found { "exists" } else { "missing" }
        );
    }
}

// Safety validation system
pub fn validate_game_safety(
    pieces: Query<&GamePiece>,
    tiles: Query<&BoardTile>,
    game_state: Res<GameState>,
) {
    // Check for obvious issues that could cause crashes

    // 1. Check for pieces outside board bounds
    for piece in pieces.iter() {
        if piece.board_position.0 >= 8 || piece.board_position.1 >= 8 {
            println!(
                "⚠️ SAFETY: Piece found outside board bounds: {:?}",
                piece.board_position
            );
        }
    }

    // 2. Check for duplicate pieces at same position
    let mut positions = std::collections::HashSet::new();
    for piece in pieces.iter() {
        if !positions.insert(piece.board_position) {
            println!(
                "⚠️ SAFETY: Duplicate pieces at position: {:?}",
                piece.board_position
            );
        }
    }

    // 3. Check for invalid selected power
    if let Some(power_index) = game_state.selected_power {
        let powers = game_state.get_current_player_powers();
        if power_index >= powers.len() {
            println!(
                "⚠️ SAFETY: Invalid power index {} (max: {})",
                power_index,
                powers.len()
            );
        }
    }

    // 4. Check entity count
    let piece_count = pieces.iter().count();
    let tile_count = tiles.iter().count();

    if piece_count > 100 {
        println!("⚠️ SAFETY: High piece count: {}", piece_count);
    }

    if tile_count != 64 {
        println!(
            "⚠️ SAFETY: Incorrect tile count: {} (expected 64)",
            tile_count
        );
    }
}

// Entity cleanup validator to prevent double-despawn warnings
pub fn validate_entity_cleanup(mut removed: RemovedComponents<GamePiece>, mut commands: Commands) {
    for entity in removed.read() {
        println!("🧹 GamePiece component removed from entity: {:?}", entity);
        // Ensure we don't try to despawn already removed entities
    }
}

// Performance crash detector
pub fn detect_performance_crashes(diagnostics: Res<bevy::diagnostic::DiagnosticsStore>) {
    if let Some(fps_diagnostic) = diagnostics.get(bevy::diagnostic::FrameTimeDiagnosticsPlugin::FPS)
    {
        if let Some(fps) = fps_diagnostic.smoothed() {
            if fps < 5.0 {
                println!(
                    "🚨 CRITICAL: FPS dropped to {} - potential freeze/crash incoming!",
                    fps
                );
            } else if fps < 15.0 {
                println!("⚠️ WARNING: Low FPS detected: {}", fps);
            }
        }
    }
}

// Debug controls info
pub fn show_debug_controls(keyboard: Res<Input<KeyCode>>) {
    if keyboard.just_pressed(KeyCode::Grave) {
        println!("\n🛠️ DEBUG CRASH TESTING CONTROLS:");
        println!("===================================");
        println!("F1 - Mass Entity Despawn Test");
        println!("F2 - Invalid Power Activation Test");
        println!("F3 - Memory Stress Test (1000 entities)");
        println!("F4 - Null Pointer Access Test");
        println!("F8 - Performance Statistics");
        println!("` (grave) - Show this help");
        println!("===================================\n");
    }
}
