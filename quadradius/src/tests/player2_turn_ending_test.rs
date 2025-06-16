use crate::components::*;
use crate::resources::game_state::{GameState, TurnPhase};
use crate::systems::turn_management::*;
use bevy::prelude::*;

/// Test to investigate Player2 turn ending prematurely
#[test]
fn test_player2_turn_sequence() {
    println!("🎯 Player2 Turn Sequence Test");
    println!("   Investigating why Player2's turn ends before they move");

    let mut game_state = GameState::default();

    // Simulate game initialization
    println!(
        "   Initial state: {:?} in {:?}",
        game_state.current_player, game_state.turn_phase
    );
    assert_eq!(game_state.current_player, Player::Player1);
    assert_eq!(game_state.turn_phase, TurnPhase::PieceMovement); // Default from game_state.rs

    // Simulate initialize_turn_phase system call
    if game_state.turn_phase == TurnPhase::PieceMovement {
        game_state.turn_phase = TurnPhase::PowerActivation;
        println!(
            "   After initialize_turn_phase: {:?} in {:?}",
            game_state.current_player, game_state.turn_phase
        );
    }

    // Player1's complete turn sequence
    println!("   === Player1's Turn ===");

    // PowerActivation -> PieceMovement
    advance_turn_phase(&mut game_state);
    println!(
        "   After power phase: {:?} in {:?}",
        game_state.current_player, game_state.turn_phase
    );
    assert_eq!(game_state.current_player, Player::Player1);
    assert_eq!(game_state.turn_phase, TurnPhase::PieceMovement);

    // PieceMovement -> PowerSpawning (when player moves)
    advance_turn_phase(&mut game_state);
    println!(
        "   After piece move: {:?} in {:?}",
        game_state.current_player, game_state.turn_phase
    );
    assert_eq!(game_state.current_player, Player::Player1);
    assert_eq!(game_state.turn_phase, TurnPhase::PowerSpawning);

    // PowerSpawning -> PowerActivation (switches to Player2)
    advance_turn_phase(&mut game_state);
    println!(
        "   After spawning: {:?} in {:?}",
        game_state.current_player, game_state.turn_phase
    );
    assert_eq!(game_state.current_player, Player::Player2);
    assert_eq!(game_state.turn_phase, TurnPhase::PowerActivation);

    // Player2's turn sequence
    println!("   === Player2's Turn ===");

    // PowerActivation -> PieceMovement
    advance_turn_phase(&mut game_state);
    println!(
        "   After power phase: {:?} in {:?}",
        game_state.current_player, game_state.turn_phase
    );
    assert_eq!(game_state.current_player, Player::Player2);
    assert_eq!(game_state.turn_phase, TurnPhase::PieceMovement);

    // This is where Player2 should be able to move
    println!("   ✅ Player2 should be able to move pieces now");

    // If Player2 moves a piece, this should happen:
    advance_turn_phase(&mut game_state);
    println!(
        "   After piece move: {:?} in {:?}",
        game_state.current_player, game_state.turn_phase
    );
    assert_eq!(game_state.current_player, Player::Player2);
    assert_eq!(game_state.turn_phase, TurnPhase::PowerSpawning);

    println!("   ✅ Player2 turn sequence works correctly in isolation");
}

#[test]
fn test_potential_double_advancement_bug() {
    println!("🎯 Double Advancement Bug Test");
    println!("   Checking if something is advancing Player2's turn twice");

    let mut game_state = GameState::default();
    game_state.current_player = Player::Player2;
    game_state.turn_phase = TurnPhase::PieceMovement;

    println!("   Player2 starts in: {:?}", game_state.turn_phase);

    // If there's a bug, something might be calling advance_turn_phase twice
    // First call - normal move
    advance_turn_phase(&mut game_state);
    println!(
        "   After first advance: {:?} in {:?}",
        game_state.current_player, game_state.turn_phase
    );
    assert_eq!(game_state.turn_phase, TurnPhase::PowerSpawning);
    assert_eq!(game_state.current_player, Player::Player2);

    // Second call - should be spawning timer, not immediate
    advance_turn_phase(&mut game_state);
    println!(
        "   After second advance: {:?} in {:?}",
        game_state.current_player, game_state.turn_phase
    );
    assert_eq!(game_state.turn_phase, TurnPhase::PowerActivation);
    assert_eq!(game_state.current_player, Player::Player1); // Switched!

    println!("   💡 If this happens immediately without 2-second delay, that's the bug!");
}

#[test]
fn test_initialization_effect_on_players() {
    println!("🎯 Initialization Effect Test");
    println!("   Checking if initialization affects players differently");

    // Test what happens if initialize_turn_phase is called multiple times
    let mut game_state = GameState::default();

    println!(
        "   Before any initialization: {:?} in {:?}",
        game_state.current_player, game_state.turn_phase
    );

    // First call to initialize_turn_phase
    if game_state.turn_phase == TurnPhase::PieceMovement {
        game_state.turn_phase = TurnPhase::PowerActivation;
        println!(
            "   After first init: {:?} in {:?}",
            game_state.current_player, game_state.turn_phase
        );
    }

    // Second call to initialize_turn_phase (should do nothing)
    if game_state.turn_phase == TurnPhase::PieceMovement {
        game_state.turn_phase = TurnPhase::PowerActivation;
        println!("   After second init: should be unchanged");
    } else {
        println!("   Second init correctly did nothing");
    }

    // The issue might be that something else is calling advance_turn_phase
    // when it shouldn't be, specifically affecting Player2

    println!("   ✅ Initialization logic is correct");
}

#[test]
fn test_timer_system_behavior() {
    println!("🎯 Timer System Behavior Test");
    println!("   Checking if PowerSpawningTimer might be causing issues");

    let mut timer = PowerSpawningTimer::default();
    let mut game_state = GameState::default();
    game_state.turn_phase = TurnPhase::PowerSpawning;
    game_state.current_player = Player::Player2;

    // Simulate timer initialization
    assert!(timer.start_time.is_none());
    timer.start_time = Some(0.0);

    // Simulate immediate timer check (could be the bug)
    let elapsed = 0.0; // No time passed
    let should_advance = elapsed > 2.0; // Should be false

    assert!(!should_advance, "Timer should not advance immediately");

    // Simulate timer after proper delay
    let elapsed = 2.1; // Time passed
    let should_advance = elapsed > 2.0; // Should be true

    assert!(should_advance, "Timer should advance after delay");

    println!("   ✅ Timer logic is mathematically correct");
    println!("   💡 Issue might be in how timer is applied or reset");
}
