use bevy::prelude::*;
use crate::components::*;
use crate::resources::*;

#[derive(Component)]
pub struct TurnIndicator;

pub fn setup_ui(mut commands: Commands) {
    // Create turn indicator text
    commands.spawn((
        TextBundle::from_section(
            "Player 1's Turn",
            TextStyle {
                font_size: 30.0,
                color: Color::WHITE,
                ..default()
            },
        )
        .with_style(Style {
            position_type: PositionType::Absolute,
            top: Val::Px(10.0),
            left: Val::Px(10.0),
            ..default()
        }),
        TurnIndicator,
    ));
}

pub fn update_turn_indicator(
    game_state: Res<GameState>,
    mut query: Query<&mut Text, With<TurnIndicator>>,
) {
    if game_state.is_changed() {
        for mut text in query.iter_mut() {
            text.sections[0].value = match game_state.current_player {
                Player::Player1 => "Player 1's Turn".to_string(),
                Player::Player2 => "Player 2's Turn".to_string(),
            };
            text.sections[0].style.color = match game_state.current_player {
                Player::Player1 => Color::rgb(0.8, 0.2, 0.2),
                Player::Player2 => Color::rgb(0.2, 0.2, 0.8),
            };
        }
    }
}