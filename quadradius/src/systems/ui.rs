use crate::{components::*, resources::*};
use bevy::prelude::*;

#[derive(Component)]
pub struct TurnIndicator;

#[derive(Component)]
pub struct InstructionsText;

#[derive(Component)]
pub struct PowerInventoryUI;

pub fn setup_ui(mut commands: Commands) {
    // Turn indicator
    commands.spawn((
        TextBundle::from_section(
            "Player 1's Turn (Red)",
            TextStyle {
                font_size: 30.0,
                color: Color::WHITE,
                ..default()
            },
        )
        .with_text_alignment(TextAlignment::Center)
        .with_style(Style {
            position_type: PositionType::Absolute,
            top: Val::Px(10.0),
            left: Val::Percent(40.0),
            ..default()
        }),
        TurnIndicator,
    ));

    // Instructions
    commands.spawn((
        TextBundle::from_section(
            "Drag and drop pieces to move them",
            TextStyle {
                font_size: 20.0,
                color: Color::WHITE,
                ..default()
            },
        )
        .with_text_alignment(TextAlignment::Center)
        .with_style(Style {
            position_type: PositionType::Absolute,
            bottom: Val::Px(10.0),
            left: Val::Percent(30.0),
            ..default()
        }),
        InstructionsText,
    ));

    // Power inventory display
    commands.spawn((
        TextBundle::from_section(
            "Powers: None",
            TextStyle {
                font_size: 20.0,
                color: Color::WHITE,
                ..default()
            },
        )
        .with_style(Style {
            position_type: PositionType::Absolute,
            top: Val::Px(50.0),
            left: Val::Px(10.0),
            ..default()
        }),
        PowerInventoryUI,
    ));
}

pub fn update_turn_indicator(
    mut query: Query<&mut Text, With<TurnIndicator>>,
    game_state: Res<GameState>,
) {
    for mut text in query.iter_mut() {
        let player_text = match game_state.current_player {
            Player::Player1 => "Player 1's Turn (Red)",
            Player::Player2 => "Player 2's Turn (Blue)",
        };

        let phase_text = match game_state.turn_phase {
            TurnPhase::PowerActivation => " - Power Phase",
            TurnPhase::PieceMovement => " - Move Phase",
            TurnPhase::PowerSpawning => " - Spawning Phase ⚡",
        };

        text.sections[0].value = format!("{}{}", player_text, phase_text);
    }
}

pub fn update_power_inventory(
    mut query: Query<&mut Text, With<PowerInventoryUI>>,
    game_state: Res<GameState>,
) {
    for mut text in query.iter_mut() {
        let powers = game_state.get_current_player_powers();

        if powers.is_empty() {
            text.sections[0].value = "Powers: None".to_string();
        } else {
            let power_names: Vec<&str> = powers.iter().map(|p| p.name()).collect();
            text.sections[0].value = format!("Powers: {}", power_names.join(", "));
        }
    }
}
