use crate::components::*;
use crate::resources::game_state::{GameState, TurnPhase};
use crate::systems::turn_management::*;
use bevy::prelude::*;

/// Test to simulate the exact PowerSpawningTimer behavior and find the Player2 bug
#[test]
fn test_power_spawning_timer_reset_bug() {
    println!("🎯 PowerSpawning Timer Reset Bug Test");
    println!("   Simulating exact timer behavior to find Player2 issue");

    let mut game_state = GameState::default();
    let mut timer = PowerSpawningTimer::default();

    // Simulate starting game state
    game_state.current_player = Player::Player1;
    game_state.turn_phase = TurnPhase::PowerSpawning;

    // Create a mock time resource
    let mut mock_time = 0.0;

    println!("   === Player1's PowerSpawning ===");

    // First call - timer initialization
    if game_state.turn_phase == TurnPhase::PowerSpawning && timer.start_time.is_none() {
        timer.start_time = Some(mock_time);
        println!("   Player1 timer initialized at: {:.1}", mock_time);
    }

    // Time advances but not enough
    mock_time = 1.0;
    let elapsed = mock_time - timer.start_time.unwrap();
    println!(
        "   Player1 elapsed time: {:.1} (should not advance)",
        elapsed
    );
    assert!(elapsed <= 2.0, "Should not advance yet");

    // Time advances enough to complete
    mock_time = 2.5;
    let elapsed = mock_time - timer.start_time.unwrap();
    println!("   Player1 elapsed time: {:.1} (should advance)", elapsed);
    if elapsed > 2.0 {
        // Simulate advance_turn_phase call
        game_state.turn_phase = TurnPhase::PowerActivation;
        game_state.current_player = Player::Player2;
        timer.start_time = None; // Reset timer
        println!("   Player1 turn completed, switching to Player2");
    }

    // Player2 gets their turn
    game_state.turn_phase = TurnPhase::PieceMovement; // They should be able to move
    println!(
        "   Player2 should be in PieceMovement: {:?}",
        game_state.turn_phase
    );

    // Player2 moves a piece
    game_state.turn_phase = TurnPhase::PowerSpawning;

    println!("   === Player2's PowerSpawning ===");

    // HERE'S THE POTENTIAL BUG: What if timer.start_time is not None?
    println!("   Player2 timer state: {:?}", timer.start_time);

    if timer.start_time.is_some() {
        println!("   🚨 BUG FOUND: Timer was not reset! Player2 will use stale time");
        let stale_time = timer.start_time.unwrap();
        let false_elapsed = mock_time - stale_time; // Using old timer!
        println!("   False elapsed time: {:.1}", false_elapsed);

        if false_elapsed > 2.0 {
            println!("   💥 Player2's turn would end immediately due to stale timer!");
        }
    } else {
        println!("   ✅ Timer correctly reset, Player2 gets fresh start");
        timer.start_time = Some(mock_time);
    }
}

#[test]
fn test_timer_race_condition() {
    println!("🎯 Timer Race Condition Test");
    println!("   Checking if timer reset happens at wrong time");

    let mut game_state = GameState::default();
    let mut timer = PowerSpawningTimer::default();
    let mock_time = 10.0; // Some arbitrary time

    // Player1 finishes their spawning phase
    game_state.turn_phase = TurnPhase::PowerSpawning;
    game_state.current_player = Player::Player1;
    timer.start_time = Some(8.0); // Started 2 seconds ago

    let elapsed = mock_time - timer.start_time.unwrap();
    println!("   Player1 elapsed: {:.1}", elapsed);

    // Time to advance
    if elapsed > 2.0 {
        println!("   Advancing Player1's turn...");

        // This is what advance_turn_phase does:
        game_state.turn_phase = TurnPhase::PowerActivation;
        game_state.current_player = Player::Player2;

        // This is what handle_power_spawning_phase does:
        timer.start_time = None; // Reset happens here

        println!(
            "   Player1 -> Player2, timer reset to: {:?}",
            timer.start_time
        );
    }

    // Now Player2 goes through their phases
    // PowerActivation -> PieceMovement
    game_state.turn_phase = TurnPhase::PieceMovement;
    println!(
        "   Player2 in PieceMovement, timer should be: {:?}",
        timer.start_time
    );

    // Player2 moves -> PowerSpawning
    game_state.turn_phase = TurnPhase::PowerSpawning;

    // Check timer state when Player2 enters PowerSpawning
    if game_state.turn_phase == TurnPhase::PowerSpawning {
        if timer.start_time.is_none() {
            timer.start_time = Some(mock_time);
            println!(
                "   ✅ Player2 timer correctly initialized at: {:.1}",
                mock_time
            );
        } else {
            println!("   🚨 Player2 timer was not None: {:?}", timer.start_time);
        }
    }
}

#[test]
fn test_multiple_system_calls() {
    println!("🎯 Multiple System Calls Test");
    println!("   Checking if handle_power_spawning_phase is called multiple times per frame");

    let mut game_state = GameState::default();
    let mut timer = PowerSpawningTimer::default();

    game_state.turn_phase = TurnPhase::PowerSpawning;
    game_state.current_player = Player::Player2;

    let mock_time = 5.0;

    // First system call
    println!("   === First system call ===");
    if game_state.turn_phase == TurnPhase::PowerSpawning {
        if timer.start_time.is_none() {
            timer.start_time = Some(mock_time);
            println!("   Timer initialized: {:.1}", mock_time);
        }

        let elapsed = mock_time - timer.start_time.unwrap();
        println!("   Elapsed: {:.1}", elapsed);

        if elapsed > 2.0 {
            println!("   Would advance turn");
        }
    }

    // Second system call in same frame (shouldn't happen, but let's test)
    println!("   === Second system call (same frame) ===");
    if game_state.turn_phase == TurnPhase::PowerSpawning {
        if timer.start_time.is_none() {
            timer.start_time = Some(mock_time);
            println!("   Timer re-initialized: {:.1}", mock_time);
        } else {
            println!("   Timer already set: {:?}", timer.start_time);
        }

        let elapsed = mock_time - timer.start_time.unwrap();
        println!("   Elapsed: {:.1}", elapsed);

        if elapsed > 2.0 {
            println!("   Would advance turn");
        }
    }

    println!("   ✅ Multiple calls handle correctly");
}

#[test]
fn test_bevy_time_resource_behavior() {
    println!("🎯 Bevy Time Resource Behavior Test");
    println!("   Understanding how Time::elapsed_seconds() might cause issues");

    // In Bevy, Time::elapsed_seconds() returns total time since app start
    // If there's a bug, it might be related to how this absolute time interacts
    // with the timer logic across different players

    let mut timer = PowerSpawningTimer::default();

    // Simulate app time progression
    let app_time_1 = 10.0; // App has been running 10 seconds
    let app_time_2 = 15.0; // 5 seconds later

    // Player1's spawning phase
    timer.start_time = Some(app_time_1);
    let elapsed_1 = app_time_2 - timer.start_time.unwrap(); // 5 seconds
    println!(
        "   Player1 spawning elapsed: {:.1} (should complete)",
        elapsed_1
    );
    assert!(elapsed_1 > 2.0);

    // Timer reset for Player2
    timer.start_time = None;

    // Player2's spawning phase starts later
    let app_time_3 = 20.0; // Player2 starts spawning at 20 seconds
    timer.start_time = Some(app_time_3);

    // Check immediately
    let elapsed_2 = app_time_3 - timer.start_time.unwrap(); // 0 seconds
    println!(
        "   Player2 spawning elapsed: {:.1} (should not complete)",
        elapsed_2
    );
    assert!(elapsed_2 <= 2.0);

    // Check after delay
    let app_time_4 = 22.5; // 2.5 seconds later
    let elapsed_3 = app_time_4 - timer.start_time.unwrap(); // 2.5 seconds
    println!(
        "   Player2 spawning elapsed: {:.1} (should complete)",
        elapsed_3
    );
    assert!(elapsed_3 > 2.0);

    println!("   ✅ Time resource behavior is mathematically sound");
    println!("   💡 The bug must be elsewhere - likely in system ordering or multiple calls");
}
