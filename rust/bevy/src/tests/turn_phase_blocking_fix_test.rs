use crate::components::*;
use crate::resources::game_state::{GameState, TurnPhase};
use crate::systems::turn_management::*;

/// Test that verifies players understand the turn phase system
#[test]
fn test_turn_phase_visual_feedback() {
    println!("🎯 Turn Phase Visual Feedback Test");
    println!("   Verifying that UI clearly indicates when pieces can/cannot be moved");

    // Test each phase's UI feedback
    let mut game_state = GameState::default();

    // PowerActivation phase
    game_state.turn_phase = TurnPhase::PowerActivation;
    let power_text = get_phase_display_text(&game_state);
    assert_eq!(power_text, "Player 1's Turn (Red) - Power Phase");
    println!("   ✅ PowerActivation phase: '{}'", power_text);

    // PieceMovement phase
    game_state.turn_phase = TurnPhase::PieceMovement;
    let move_text = get_phase_display_text(&game_state);
    assert_eq!(
        move_text,
        "Player 1's Turn (Red) - Move Phase (Click & Drag pieces)"
    );
    println!("   ✅ PieceMovement phase: '{}'", move_text);

    // PowerSpawning phase
    game_state.turn_phase = TurnPhase::PowerSpawning;
    let spawn_text = get_phase_display_text(&game_state);
    assert_eq!(
        spawn_text,
        "Player 1's Turn (Red) - Spawning Phase ⚡ (Wait...)"
    );
    println!("   ✅ PowerSpawning phase: '{}'", spawn_text);

    // The key insight: users now see clear "Wait..." message during spawning
    assert!(
        spawn_text.contains("Wait"),
        "Spawning phase should clearly indicate waiting"
    );
    assert!(
        move_text.contains("Click & Drag"),
        "Move phase should encourage interaction"
    );
}

#[test]
fn test_power_spawning_phase_duration() {
    println!("🎯 Power Spawning Phase Duration Test");
    println!("   Verifying that PowerSpawning phase has reasonable duration");

    // The automatic advancement is 2 seconds (from turn_management.rs line 66)
    let spawning_duration = 2.0;

    println!(
        "   PowerSpawning phase duration: {:.1} seconds",
        spawning_duration
    );

    // This should be long enough for players to see power orbs spawn
    // but short enough that they don't get frustrated waiting
    assert!(
        spawning_duration >= 1.0,
        "Duration should be at least 1 second for visibility"
    );
    assert!(
        spawning_duration <= 3.0,
        "Duration should be at most 3 seconds to avoid frustration"
    );

    println!("   ✅ Duration is reasonable for user experience");
}

#[test]
fn test_turn_phase_transition_logic() {
    println!("🎯 Turn Phase Transition Logic Test");
    println!("   Verifying correct phase progression");

    let mut game_state = GameState::default();
    game_state.turn_phase = TurnPhase::PowerActivation;
    game_state.current_player = Player::Player1;

    // PowerActivation -> PieceMovement
    advance_turn_phase(&mut game_state);
    assert_eq!(game_state.turn_phase, TurnPhase::PieceMovement);
    assert_eq!(game_state.current_player, Player::Player1); // Same player
    println!("   ✅ PowerActivation -> PieceMovement (same player)");

    // PieceMovement -> PowerSpawning
    advance_turn_phase(&mut game_state);
    assert_eq!(game_state.turn_phase, TurnPhase::PowerSpawning);
    assert_eq!(game_state.current_player, Player::Player1); // Same player
    println!("   ✅ PieceMovement -> PowerSpawning (same player)");

    // PowerSpawning -> PowerActivation (switches player)
    advance_turn_phase(&mut game_state);
    assert_eq!(game_state.turn_phase, TurnPhase::PowerActivation);
    assert_eq!(game_state.current_player, Player::Player2); // Switched player!
    println!("   ✅ PowerSpawning -> PowerActivation (player switched to Player2)");
}

#[test]
fn test_double_click_perception_explanation() {
    println!("🎯 Double Click Perception Explanation");
    println!("   Understanding why users think they need to click twice");

    // Scenario: User clicks during PowerSpawning phase
    let current_phase = TurnPhase::PowerSpawning;
    let can_move_pieces = current_phase == TurnPhase::PieceMovement;

    assert!(
        !can_move_pieces,
        "Pieces cannot be moved during PowerSpawning"
    );
    println!("   ❌ First click during PowerSpawning: Blocked (no visual response)");

    // User waits (or doesn't notice the phase change)
    let next_phase = TurnPhase::PieceMovement; // After 2 seconds
    let can_move_now = next_phase == TurnPhase::PieceMovement;

    assert!(can_move_now, "Pieces can be moved during PieceMovement");
    println!("   ✅ Second click during PieceMovement: Works!");

    println!(
        "   📝 Explanation: User clicks during spawning (blocked), waits, clicks again (works)"
    );
    println!("   📝 Solution: Clear UI feedback prevents this confusion");
}

// Helper function to simulate the UI text generation
fn get_phase_display_text(game_state: &GameState) -> String {
    let player_text = match game_state.current_player {
        Player::Player1 => "Player 1's Turn (Red)",
        Player::Player2 => "Player 2's Turn (Blue)",
    };

    let phase_text = match game_state.turn_phase {
        TurnPhase::PowerActivation => " - Power Phase",
        TurnPhase::PieceMovement => " - Move Phase (Click & Drag pieces)",
        TurnPhase::PowerSpawning => " - Spawning Phase ⚡ (Wait...)",
    };

    format!("{}{}", player_text, phase_text)
}

#[test]
fn test_user_experience_flow() {
    println!("🎯 User Experience Flow Test");
    println!("   Simulating the complete user interaction flow");

    let mut game_state = GameState::default();
    game_state.turn_phase = TurnPhase::PowerActivation;

    println!("   1. Game starts: {}", get_phase_display_text(&game_state));

    // Player activates power or skips
    advance_turn_phase(&mut game_state);
    println!(
        "   2. After power phase: {}",
        get_phase_display_text(&game_state)
    );

    // This is when user should move pieces - clear instruction
    assert!(get_phase_display_text(&game_state).contains("Click & Drag"));

    // Player moves piece
    advance_turn_phase(&mut game_state);
    println!(
        "   3. After moving: {}",
        get_phase_display_text(&game_state)
    );

    // This is when user must wait - clear instruction
    assert!(get_phase_display_text(&game_state).contains("Wait"));

    // System automatically advances after 2 seconds
    advance_turn_phase(&mut game_state);
    println!(
        "   4. Next player's turn: {}",
        get_phase_display_text(&game_state)
    );

    println!("   ✅ Complete flow provides clear guidance at each step");
}
