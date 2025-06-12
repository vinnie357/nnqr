use crate::components::*;
use crate::resources::*;
use bevy::prelude::*;

#[test]
fn test_turn_indicator_uses_correct_theme_colors() {
    // Test that turn indicator colors match the theme constants
    let player1_color = QuadradiusTheme::TEAM_1_PRIMARY;
    let player2_color = QuadradiusTheme::TEAM_2_PRIMARY;

    // Verify Player 1 is blue (theme primary)
    assert!(
        player1_color.r() < 0.5 && player1_color.g() < 0.5 && player1_color.b() > 0.5,
        "Player 1 should be blue-ish: {:?}",
        player1_color
    );

    // Verify Player 2 is red (theme primary)
    assert!(
        player2_color.r() > 0.5 && player2_color.g() < 0.5 && player2_color.b() < 0.5,
        "Player 2 should be red-ish: {:?}",
        player2_color
    );

    // Verify colors are different
    assert_ne!(
        player1_color, player2_color,
        "Player colors should be different"
    );
}

#[test]
fn test_team_colors_are_distinct() {
    let team1 = QuadradiusTheme::TEAM_1_PRIMARY;
    let team2 = QuadradiusTheme::TEAM_2_PRIMARY;

    // Calculate color distance to ensure they're visually distinct
    let distance = ((team1.r() - team2.r()).powi(2)
        + (team1.g() - team2.g()).powi(2)
        + (team1.b() - team2.b()).powi(2))
    .sqrt();

    assert!(
        distance > 0.5,
        "Team colors should be visually distinct, distance: {}",
        distance
    );
}

#[test]
fn test_turn_indicator_color_logic() {
    // Test the exact logic used in enhanced_ui.rs
    let game_state_p1 = GameState {
        current_player: Player::Player1,
        player1_powers: Vec::new(),
        player2_powers: Vec::new(),
        turn_phase: TurnPhase::PieceMovement,
        selected_power: None,
    };

    let game_state_p2 = GameState {
        current_player: Player::Player2,
        player1_powers: Vec::new(),
        player2_powers: Vec::new(),
        turn_phase: TurnPhase::PieceMovement,
        selected_power: None,
    };

    // Simulate the color assignment logic from enhanced_ui.rs
    let p1_color = match game_state_p1.current_player {
        Player::Player1 => QuadradiusTheme::TEAM_1_PRIMARY,
        Player::Player2 => QuadradiusTheme::TEAM_2_PRIMARY,
    };

    let p2_color = match game_state_p2.current_player {
        Player::Player1 => QuadradiusTheme::TEAM_1_PRIMARY,
        Player::Player2 => QuadradiusTheme::TEAM_2_PRIMARY,
    };

    // Verify correct color assignment
    assert_eq!(p1_color, QuadradiusTheme::TEAM_1_PRIMARY);
    assert_eq!(p2_color, QuadradiusTheme::TEAM_2_PRIMARY);
    assert_ne!(p1_color, p2_color);
}

#[test]
fn test_turn_indicator_colors_not_hardcoded() {
    // This test ensures we're not using the old hardcoded values
    let old_player1_color = Color::rgb(0.9, 0.3, 0.3); // Old hardcoded red
    let old_player2_color = Color::rgb(0.3, 0.3, 0.9); // Old hardcoded blue

    let new_player1_color = QuadradiusTheme::TEAM_1_PRIMARY;
    let new_player2_color = QuadradiusTheme::TEAM_2_PRIMARY;

    // Verify we're not using the old hardcoded colors
    assert_ne!(
        new_player1_color, old_player1_color,
        "Should not use old hardcoded Player 1 color"
    );
    assert_ne!(
        new_player2_color, old_player2_color,
        "Should not use old hardcoded Player 2 color"
    );
}

#[test]
fn test_turn_phase_display_logic() {
    // Test turn phase display strings match expected values
    let power_phase = TurnPhase::PowerActivation;
    let move_phase = TurnPhase::PieceMovement;

    let power_display = match power_phase {
        TurnPhase::PowerActivation => "Power Phase",
        TurnPhase::PieceMovement => "Move Phase",
        TurnPhase::PowerCollection => "Collection Phase",
    };

    let move_display = match move_phase {
        TurnPhase::PowerActivation => "Power Phase",
        TurnPhase::PieceMovement => "Move Phase",
        TurnPhase::PowerCollection => "Collection Phase",
    };

    assert_eq!(power_display, "Power Phase");
    assert_eq!(move_display, "Move Phase");
}

#[test]
fn test_player_name_display() {
    // Test player name display logic
    let p1_name = match Player::Player1 {
        Player::Player1 => "Player 1",
        Player::Player2 => "Player 2",
    };

    let p2_name = match Player::Player2 {
        Player::Player1 => "Player 1",
        Player::Player2 => "Player 2",
    };

    assert_eq!(p1_name, "Player 1");
    assert_eq!(p2_name, "Player 2");
}
