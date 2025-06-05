use crate::{components::Player, resources::*};
use bevy::prelude::*;

#[derive(Component)]
pub struct PowerButton {
    pub power_index: usize,
}

#[derive(Component)]
pub struct SkipPowerButton;

#[derive(Component)]
pub struct PowerActivationPanel;

pub fn setup_power_activation_ui(mut commands: Commands) {
    // Power activation panel (initially hidden)
    commands
        .spawn((
            NodeBundle {
                style: Style {
                    width: Val::Percent(100.0),
                    height: Val::Px(120.0),
                    position_type: PositionType::Absolute,
                    bottom: Val::Px(0.0),
                    padding: UiRect::all(Val::Px(10.0)),
                    flex_direction: FlexDirection::Column,
                    align_items: AlignItems::Center,
                    justify_content: JustifyContent::Center,
                    ..default()
                },
                background_color: BackgroundColor(Color::rgba(0.1, 0.1, 0.1, 0.9)),
                visibility: Visibility::Hidden,
                ..default()
            },
            PowerActivationPanel,
        ))
        .with_children(|parent| {
            // Title
            parent.spawn(TextBundle::from_section(
                "Select a Power to Use",
                TextStyle {
                    font_size: 24.0,
                    color: Color::WHITE,
                    ..default()
                },
            ));

            // Power buttons container
            parent
                .spawn(NodeBundle {
                    style: Style {
                        flex_direction: FlexDirection::Row,
                        align_items: AlignItems::Center,
                        justify_content: JustifyContent::Center,
                        column_gap: Val::Px(10.0),
                        margin: UiRect::top(Val::Px(10.0)),
                        ..default()
                    },
                    ..default()
                })
                .with_children(|parent| {
                    // Skip button
                    parent
                        .spawn((
                            ButtonBundle {
                                style: Style {
                                    width: Val::Px(100.0),
                                    height: Val::Px(50.0),
                                    border: UiRect::all(Val::Px(2.0)),
                                    justify_content: JustifyContent::Center,
                                    align_items: AlignItems::Center,
                                    ..default()
                                },
                                background_color: BackgroundColor(Color::rgb(0.3, 0.3, 0.3)),
                                border_color: BorderColor(Color::WHITE),
                                ..default()
                            },
                            SkipPowerButton,
                        ))
                        .with_children(|parent| {
                            parent.spawn(TextBundle::from_section(
                                "Skip",
                                TextStyle {
                                    font_size: 20.0,
                                    color: Color::WHITE,
                                    ..default()
                                },
                            ));
                        });
                });
        });
}

pub fn update_power_activation_ui(
    mut commands: Commands,
    mut game_state: ResMut<GameState>,
    mut panel_query: Query<(&mut Visibility, Entity), With<PowerActivationPanel>>,
    button_query: Query<Entity, With<PowerButton>>,
) {
    let (mut visibility, panel_entity) = panel_query.single_mut();

    // Show/hide panel based on turn phase
    match game_state.turn_phase {
        TurnPhase::PowerActivation => {
            // Auto-skip if no powers available
            let powers = game_state.get_current_player_powers();
            if powers.is_empty() {
                println!(
                    "Player {:?} has no powers - auto-skipping to movement phase",
                    game_state.current_player
                );
                game_state.turn_phase = TurnPhase::PieceMovement;
                *visibility = Visibility::Hidden;
                return;
            }

            // Only log once when first entering power phase
            static mut LAST_LOG: Option<(Player, usize)> = None;
            unsafe {
                if LAST_LOG != Some((game_state.current_player, powers.len())) {
                    println!(
                        "Player {:?} has {} powers available",
                        game_state.current_player,
                        powers.len()
                    );
                    LAST_LOG = Some((game_state.current_player, powers.len()));
                }
            }

            *visibility = Visibility::Visible;

            // Remove old power buttons
            for entity in button_query.iter() {
                commands.entity(entity).despawn_recursive();
            }

            // Get current player's powers
            let powers = game_state.get_current_player_powers();

            if !powers.is_empty() {
                // Add power buttons
                if let Some(mut panel_commands) = commands.get_entity(panel_entity) {
                    panel_commands.with_children(|parent| {
                        // Find the button container (second child)
                        parent
                            .spawn(NodeBundle {
                                style: Style {
                                    flex_direction: FlexDirection::Row,
                                    align_items: AlignItems::Center,
                                    justify_content: JustifyContent::Center,
                                    column_gap: Val::Px(10.0),
                                    margin: UiRect::left(Val::Px(120.0)), // Leave space for skip button
                                    ..default()
                                },
                                ..default()
                            })
                            .with_children(|parent| {
                                for (index, power) in powers.iter().enumerate() {
                                    parent
                                        .spawn((
                                            ButtonBundle {
                                                style: Style {
                                                    width: Val::Px(100.0),
                                                    height: Val::Px(50.0),
                                                    border: UiRect::all(Val::Px(2.0)),
                                                    justify_content: JustifyContent::Center,
                                                    align_items: AlignItems::Center,
                                                    ..default()
                                                },
                                                background_color: BackgroundColor(power.color()),
                                                border_color: BorderColor(Color::WHITE),
                                                ..default()
                                            },
                                            PowerButton { power_index: index },
                                        ))
                                        .with_children(|parent| {
                                            parent.spawn(TextBundle::from_section(
                                                power.name(),
                                                TextStyle {
                                                    font_size: 14.0,
                                                    color: Color::WHITE,
                                                    ..default()
                                                },
                                            ));
                                        });
                                }
                            });
                    });
                }
            }
        }
        TurnPhase::PieceMovement => {
            *visibility = Visibility::Hidden;
        }
    }
}

pub fn handle_power_button_interaction(
    mut game_state: ResMut<GameState>,
    mut interaction_query: Query<
        (&Interaction, &PowerButton, &mut BackgroundColor),
        Changed<Interaction>,
    >,
) {
    for (interaction, button, mut background) in interaction_query.iter_mut() {
        match *interaction {
            Interaction::Pressed => {
                game_state.selected_power = Some(button.power_index);
                // Visual feedback will be handled by power targeting system
            }
            Interaction::Hovered => {
                // Brighten on hover
                let powers = game_state.get_current_player_powers();
                if let Some(power) = powers.get(button.power_index) {
                    let color = power.color();
                    background.0 = Color::rgb(
                        (color.r() * 1.2).min(1.0),
                        (color.g() * 1.2).min(1.0),
                        (color.b() * 1.2).min(1.0),
                    );
                }
            }
            Interaction::None => {
                // Restore original color
                let powers = game_state.get_current_player_powers();
                if let Some(power) = powers.get(button.power_index) {
                    background.0 = power.color();
                }
            }
        }
    }
}

pub fn handle_skip_button_interaction(
    mut game_state: ResMut<GameState>,
    mut interaction_query: Query<
        (&Interaction, &mut BackgroundColor),
        (Changed<Interaction>, With<SkipPowerButton>),
    >,
) {
    for (interaction, mut background) in interaction_query.iter_mut() {
        match *interaction {
            Interaction::Pressed => {
                // Skip power phase and go to movement
                game_state.turn_phase = TurnPhase::PieceMovement;
                game_state.selected_power = None;
            }
            Interaction::Hovered => {
                background.0 = Color::rgb(0.4, 0.4, 0.4);
            }
            Interaction::None => {
                background.0 = Color::rgb(0.3, 0.3, 0.3);
            }
        }
    }
}
