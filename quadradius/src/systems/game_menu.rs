use crate::{components::*, resources::*};
use bevy::app::AppExit;
use bevy::prelude::*;

// Game states for menu flow
#[derive(States, Debug, Clone, PartialEq, Eq, Hash, Default)]
pub enum GameMenuState {
    MainMenu,
    #[default]
    Playing,
    Paused,
    GameOver,
}

// Menu components
#[derive(Component)]
pub struct MainMenu;

#[derive(Component)]
pub struct MenuButton {
    pub action: MenuAction,
}

#[derive(Clone, Copy)]
pub enum MenuAction {
    StartGame,
    Settings,
    Quit,
    Resume,
    MainMenu,
    Restart,
}

#[derive(Component)]
pub struct PauseMenu;

#[derive(Component)]
pub struct GameOverMenu;

// Setup main menu
pub fn setup_main_menu(mut commands: Commands) {
    commands
        .spawn((
            NodeBundle {
                style: Style {
                    width: Val::Percent(100.0),
                    height: Val::Percent(100.0),
                    justify_content: JustifyContent::Center,
                    align_items: AlignItems::Center,
                    ..default()
                },
                background_color: BackgroundColor(Color::rgb(0.05, 0.05, 0.1)),
                ..default()
            },
            MainMenu,
        ))
        .with_children(|parent| {
            // Title
            parent.spawn(TextBundle {
                text: Text::from_section(
                    "QUADRADIUS",
                    TextStyle {
                        font_size: 72.0,
                        color: Color::rgb(0.9, 0.9, 0.95),
                        ..default()
                    },
                ),
                style: Style {
                    position_type: PositionType::Absolute,
                    top: Val::Percent(20.0),
                    ..default()
                },
                ..default()
            });

            // Menu container
            parent
                .spawn(NodeBundle {
                    style: Style {
                        flex_direction: FlexDirection::Column,
                        align_items: AlignItems::Center,
                        row_gap: Val::Px(20.0),
                        ..default()
                    },
                    ..default()
                })
                .with_children(|parent| {
                    // Start button
                    spawn_menu_button(parent, "Start Game", MenuAction::StartGame);

                    // Settings button
                    spawn_menu_button(parent, "Settings", MenuAction::Settings);

                    // Quit button
                    spawn_menu_button(parent, "Quit", MenuAction::Quit);
                });

            // Credits
            parent.spawn(TextBundle {
                text: Text::from_section(
                    "Checkers on Steroids - A Faithful Recreation",
                    TextStyle {
                        font_size: 16.0,
                        color: Color::rgb(0.6, 0.6, 0.7),
                        ..default()
                    },
                ),
                style: Style {
                    position_type: PositionType::Absolute,
                    bottom: Val::Px(20.0),
                    ..default()
                },
                ..default()
            });
        });
}

fn spawn_menu_button(parent: &mut ChildBuilder, text: &str, action: MenuAction) {
    parent
        .spawn((
            ButtonBundle {
                style: Style {
                    width: Val::Px(250.0),
                    height: Val::Px(60.0),
                    justify_content: JustifyContent::Center,
                    align_items: AlignItems::Center,
                    border: UiRect::all(Val::Px(3.0)),
                    ..default()
                },
                background_color: BackgroundColor(Color::rgb(0.15, 0.15, 0.2)),
                border_color: BorderColor(Color::rgb(0.4, 0.4, 0.5)),
                ..default()
            },
            MenuButton { action },
        ))
        .with_children(|parent| {
            parent.spawn(TextBundle::from_section(
                text,
                TextStyle {
                    font_size: 28.0,
                    color: Color::rgb(0.9, 0.9, 0.9),
                    ..default()
                },
            ));
        });
}

// Handle menu button interactions
pub fn handle_menu_buttons(
    mut interaction_query: Query<
        (&Interaction, &MenuButton, &mut BackgroundColor),
        Changed<Interaction>,
    >,
    mut next_state: ResMut<NextState<GameMenuState>>,
    mut app_exit_events: EventWriter<AppExit>,
) {
    for (interaction, button, mut background) in interaction_query.iter_mut() {
        match *interaction {
            Interaction::Pressed => {
                match button.action {
                    MenuAction::StartGame => {
                        next_state.set(GameMenuState::Playing);
                    }
                    MenuAction::Quit => {
                        app_exit_events.send(AppExit);
                    }
                    MenuAction::Resume => {
                        next_state.set(GameMenuState::Playing);
                    }
                    MenuAction::MainMenu => {
                        next_state.set(GameMenuState::MainMenu);
                    }
                    MenuAction::Restart => {
                        // Reset game state and start playing
                        next_state.set(GameMenuState::Playing);
                    }
                    _ => {}
                }
            }
            Interaction::Hovered => {
                background.0 = Color::rgb(0.25, 0.25, 0.35);
            }
            Interaction::None => {
                background.0 = Color::rgb(0.15, 0.15, 0.2);
            }
        }
    }
}

// Cleanup menu when changing states
pub fn cleanup_menu(
    mut commands: Commands,
    menu_query: Query<Entity, Or<(With<MainMenu>, With<PauseMenu>, With<GameOverMenu>)>>,
) {
    for entity in menu_query.iter() {
        commands.entity(entity).despawn_recursive();
    }
}

// Setup pause menu
pub fn setup_pause_menu(mut commands: Commands) {
    commands
        .spawn((
            NodeBundle {
                style: Style {
                    width: Val::Percent(100.0),
                    height: Val::Percent(100.0),
                    justify_content: JustifyContent::Center,
                    align_items: AlignItems::Center,
                    position_type: PositionType::Absolute,
                    ..default()
                },
                background_color: BackgroundColor(Color::rgba(0.0, 0.0, 0.0, 0.7)),
                z_index: ZIndex::Global(1000),
                ..default()
            },
            PauseMenu,
        ))
        .with_children(|parent| {
            parent
                .spawn(NodeBundle {
                    style: Style {
                        padding: UiRect::all(Val::Px(30.0)),
                        flex_direction: FlexDirection::Column,
                        align_items: AlignItems::Center,
                        row_gap: Val::Px(20.0),
                        ..default()
                    },
                    background_color: BackgroundColor(Color::rgb(0.1, 0.1, 0.15)),
                    ..default()
                })
                .with_children(|parent| {
                    // Pause title
                    parent.spawn(TextBundle::from_section(
                        "PAUSED",
                        TextStyle {
                            font_size: 48.0,
                            color: Color::rgb(0.9, 0.9, 0.9),
                            ..default()
                        },
                    ));

                    // Resume button
                    spawn_menu_button(parent, "Resume", MenuAction::Resume);

                    // Main menu button
                    spawn_menu_button(parent, "Main Menu", MenuAction::MainMenu);
                });
        });
}

// Handle pause input
pub fn handle_pause_input(
    keyboard: Res<Input<KeyCode>>,
    current_state: Res<State<GameMenuState>>,
    mut next_state: ResMut<NextState<GameMenuState>>,
) {
    if keyboard.just_pressed(KeyCode::Escape) {
        match current_state.get() {
            GameMenuState::Playing => next_state.set(GameMenuState::Paused),
            GameMenuState::Paused => next_state.set(GameMenuState::Playing),
            _ => {}
        }
    }
}

// Game over screen
pub fn setup_game_over_menu(
    mut commands: Commands,
    game_result: Res<crate::systems::win_condition::GameResult>,
) {
    let winner_text = match game_result.winner {
        Some(Player::Player1) => "Player 1 Wins!",
        Some(Player::Player2) => "Player 2 Wins!",
        None => "Draw!",
    };

    let winner_color = match game_result.winner {
        Some(Player::Player1) => Color::rgb(0.9, 0.3, 0.3),
        Some(Player::Player2) => Color::rgb(0.3, 0.3, 0.9),
        None => Color::rgb(0.7, 0.7, 0.7),
    };

    commands
        .spawn((
            NodeBundle {
                style: Style {
                    width: Val::Percent(100.0),
                    height: Val::Percent(100.0),
                    justify_content: JustifyContent::Center,
                    align_items: AlignItems::Center,
                    position_type: PositionType::Absolute,
                    ..default()
                },
                background_color: BackgroundColor(Color::rgba(0.0, 0.0, 0.0, 0.8)),
                z_index: ZIndex::Global(2000),
                ..default()
            },
            GameOverMenu,
        ))
        .with_children(|parent| {
            parent
                .spawn(NodeBundle {
                    style: Style {
                        padding: UiRect::all(Val::Px(40.0)),
                        flex_direction: FlexDirection::Column,
                        align_items: AlignItems::Center,
                        row_gap: Val::Px(30.0),
                        ..default()
                    },
                    background_color: BackgroundColor(Color::rgb(0.1, 0.1, 0.15)),
                    ..default()
                })
                .with_children(|parent| {
                    // Winner text
                    parent.spawn(TextBundle::from_section(
                        winner_text,
                        TextStyle {
                            font_size: 64.0,
                            color: winner_color,
                            ..default()
                        },
                    ));

                    // Play again button
                    spawn_menu_button(parent, "Play Again", MenuAction::Restart);

                    // Main menu button
                    spawn_menu_button(parent, "Main Menu", MenuAction::MainMenu);
                });
        });
}
