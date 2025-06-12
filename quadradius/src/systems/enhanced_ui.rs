use crate::{components::*, resources::*};
use bevy::prelude::*;

// Components for enhanced UI
#[derive(Component)]
pub struct UIPanel;

#[derive(Component)]
pub struct PowerInventoryUI;

#[derive(Component)]
pub struct TurnIndicatorUI;

#[derive(Component)]
pub struct ScoreboardUI;

#[derive(Component)]
pub struct PowerTooltip {
    pub power_type: PowerType,
}

#[derive(Component)]
pub struct UIAnimation {
    pub start_time: f32,
    pub duration: f32,
    pub animation_type: UIAnimationType,
}

#[derive(Clone)]
pub enum UIAnimationType {
    FadeIn,
    SlideIn(Vec2),
    Pulse,
    Bounce,
}

// Enhanced UI setup with modern design
pub fn setup_enhanced_ui(mut commands: Commands, _asset_server: Res<AssetServer>) {
    // Main UI container - TRANSPARENT to not block the game board
    commands
        .spawn((
            NodeBundle {
                style: Style {
                    width: Val::Percent(100.0),
                    height: Val::Percent(100.0),
                    position_type: PositionType::Absolute,
                    ..default()
                },
                background_color: BackgroundColor(Color::NONE), // Transparent
                ..default()
            },
            UIPanel,
        ))
        .with_children(|parent| {
            // Top bar with game info
            setup_top_bar(parent);

            // Side panels for power inventory
            setup_side_panels(parent);

            // Bottom status bar
            setup_bottom_bar(parent);
        });
}

fn setup_top_bar(parent: &mut ChildBuilder) {
    parent
        .spawn(NodeBundle {
            style: Style {
                width: Val::Percent(100.0),
                height: Val::Px(60.0),
                position_type: PositionType::Absolute,
                top: Val::Px(0.0),
                padding: UiRect::all(Val::Px(10.0)),
                flex_direction: FlexDirection::Row,
                justify_content: JustifyContent::SpaceBetween,
                align_items: AlignItems::Center,
                ..default()
            },
            background_color: BackgroundColor(QuadradiusTheme::UI_BACKGROUND),
            ..default()
        })
        .with_children(|parent| {
            // Game title
            parent.spawn(TextBundle::from_section(
                "QUADRADIUS",
                TextStyle {
                    font_size: 32.0,
                    color: QuadradiusTheme::UI_TEXT_HIGHLIGHT,
                    ..default()
                },
            ));

            // Turn indicator
            parent
                .spawn((
                    NodeBundle {
                        style: Style {
                            padding: UiRect::all(Val::Px(15.0)),
                            border: UiRect::all(Val::Px(2.0)),
                            ..default()
                        },
                        background_color: BackgroundColor(QuadradiusTheme::UI_PANEL),
                        border_color: BorderColor(QuadradiusTheme::UI_BORDER),
                        ..default()
                    },
                    TurnIndicatorUI,
                ))
                .with_children(|parent| {
                    parent.spawn((
                        TextBundle::from_section(
                            "Player 1's Turn",
                            TextStyle {
                                font_size: 24.0,
                                color: QuadradiusTheme::UI_TEXT,
                                ..default()
                            },
                        ),
                        TurnIndicatorText,
                    ));
                });

            // Score display
            parent
                .spawn((
                    NodeBundle {
                        style: Style {
                            flex_direction: FlexDirection::Row,
                            column_gap: Val::Px(20.0),
                            ..default()
                        },
                        ..default()
                    },
                    ScoreboardUI,
                ))
                .with_children(|parent| {
                    // Player 1 score
                    parent.spawn(TextBundle::from_section(
                        "P1: 20",
                        TextStyle {
                            font_size: 20.0,
                            color: QuadradiusTheme::TEAM_1_ACCENT,
                            ..default()
                        },
                    ));

                    // Player 2 score
                    parent.spawn(TextBundle::from_section(
                        "P2: 20",
                        TextStyle {
                            font_size: 20.0,
                            color: QuadradiusTheme::TEAM_2_ACCENT,
                            ..default()
                        },
                    ));
                });
        });
}

fn setup_side_panels(parent: &mut ChildBuilder) {
    // Left panel - Player 1 powers
    parent
        .spawn((
            NodeBundle {
                style: Style {
                    width: Val::Px(120.0),
                    height: Val::Percent(60.0),
                    position_type: PositionType::Absolute,
                    left: Val::Px(10.0),
                    top: Val::Percent(20.0),
                    padding: UiRect::all(Val::Px(5.0)),
                    flex_direction: FlexDirection::Column,
                    row_gap: Val::Px(5.0),
                    ..default()
                },
                background_color: BackgroundColor(QuadradiusTheme::UI_PANEL),
                ..default()
            },
            PowerInventoryUI,
            Player1PowerPanel,
        ))
        .with_children(|parent| {
            parent.spawn(TextBundle::from_section(
                "P1 Powers",
                TextStyle {
                    font_size: 16.0,
                    color: QuadradiusTheme::TEAM_1_ACCENT,
                    ..default()
                },
            ));
        });

    // Right panel - Player 2 powers
    parent
        .spawn((
            NodeBundle {
                style: Style {
                    width: Val::Px(120.0),
                    height: Val::Percent(60.0),
                    position_type: PositionType::Absolute,
                    right: Val::Px(10.0),
                    top: Val::Percent(20.0),
                    padding: UiRect::all(Val::Px(5.0)),
                    flex_direction: FlexDirection::Column,
                    row_gap: Val::Px(5.0),
                    ..default()
                },
                background_color: BackgroundColor(QuadradiusTheme::UI_PANEL),
                ..default()
            },
            PowerInventoryUI,
            Player2PowerPanel,
        ))
        .with_children(|parent| {
            parent.spawn(TextBundle::from_section(
                "P2 Powers",
                TextStyle {
                    font_size: 16.0,
                    color: QuadradiusTheme::TEAM_2_ACCENT,
                    ..default()
                },
            ));
        });
}

fn setup_bottom_bar(parent: &mut ChildBuilder) {
    parent
        .spawn(NodeBundle {
            style: Style {
                width: Val::Percent(100.0),
                height: Val::Px(40.0),
                position_type: PositionType::Absolute,
                bottom: Val::Px(0.0),
                padding: UiRect::all(Val::Px(10.0)),
                justify_content: JustifyContent::Center,
                align_items: AlignItems::Center,
                ..default()
            },
            background_color: BackgroundColor(QuadradiusTheme::UI_BACKGROUND),
            ..default()
        })
        .with_children(|parent| {
            parent.spawn((
                TextBundle::from_section(
                    "🖱️ Left Click: Select piece  |  🖱️ Right Click: Move/Use power  |  ⌨️ Q/E: Zoom  |  🔧 1-5: Debug powers",
                    TextStyle {
                        font_size: 14.0,
                        color: QuadradiusTheme::UI_TEXT,
                        ..default()
                    },
                ),
                HelpText,
            ));
        });
}

// Markers for UI elements
#[derive(Component)]
pub struct Player1PowerPanel;

#[derive(Component)]
pub struct Player2PowerPanel;

#[derive(Component)]
pub struct TurnIndicatorText;

#[derive(Component)]
pub struct HelpText;

#[derive(Component)]
pub struct PowerPanelText;

#[derive(Component)]
pub struct PowerIcon {
    pub power_type: PowerType,
    pub player: Player,
}

// Update power inventory display
pub fn update_power_inventory_ui(
    mut commands: Commands,
    game_state: Res<GameState>,
    player1_panel: Query<Entity, With<Player1PowerPanel>>,
    player2_panel: Query<Entity, With<Player2PowerPanel>>,
    existing_icons: Query<Entity, With<PowerIcon>>,
    existing_texts: Query<Entity, With<PowerPanelText>>,
) {
    // Clear existing power icons and text
    for entity in existing_icons.iter() {
        commands.entity(entity).despawn_recursive();
    }
    for entity in existing_texts.iter() {
        commands.entity(entity).despawn_recursive();
    }

    // Update Player 1 powers
    if let Ok(panel) = player1_panel.get_single() {
        commands.entity(panel).with_children(|parent| {
            if game_state.player1_powers.is_empty() {
                parent.spawn((
                    TextBundle::from_section(
                        "No powers collected\n\n💫 Move over power orbs\n   to collect them!",
                        TextStyle {
                            font_size: 11.0,
                            color: Color::rgba(1.0, 1.0, 1.0, 0.7),
                            ..default()
                        },
                    ),
                    PowerPanelText,
                ));
            } else {
                for (i, power) in game_state.player1_powers.iter().enumerate() {
                    spawn_power_icon(parent, *power, Player::Player1, i);
                }
            }
        });
    }

    // Update Player 2 powers
    if let Ok(panel) = player2_panel.get_single() {
        commands.entity(panel).with_children(|parent| {
            if game_state.player2_powers.is_empty() {
                parent.spawn((
                    TextBundle::from_section(
                        "No powers collected\n\n💫 Move over power orbs\n   to collect them!",
                        TextStyle {
                            font_size: 11.0,
                            color: Color::rgba(1.0, 1.0, 1.0, 0.7),
                            ..default()
                        },
                    ),
                    PowerPanelText,
                ));
            } else {
                for (i, power) in game_state.player2_powers.iter().enumerate() {
                    spawn_power_icon(parent, *power, Player::Player2, i);
                }
            }
        });
    }
}

fn spawn_power_icon(
    parent: &mut ChildBuilder,
    power_type: PowerType,
    player: Player,
    index: usize,
) {
    parent
        .spawn((
            ButtonBundle {
                style: Style {
                    width: Val::Px(100.0),
                    height: Val::Px(40.0),
                    margin: UiRect::top(Val::Px(5.0 + index as f32 * 45.0)),
                    justify_content: JustifyContent::Center,
                    align_items: AlignItems::Center,
                    border: UiRect::all(Val::Px(2.0)),
                    ..default()
                },
                background_color: BackgroundColor(power_type.color()),
                border_color: BorderColor(Color::rgb(0.8, 0.8, 0.8)),
                ..default()
            },
            PowerIcon { power_type, player },
            UIAnimation {
                start_time: 0.0,
                duration: 0.5,
                animation_type: UIAnimationType::SlideIn(Vec2::new(-100.0, 0.0)),
            },
        ))
        .with_children(|parent| {
            parent.spawn(TextBundle::from_section(
                power_type.name(),
                TextStyle {
                    font_size: 12.0,
                    color: Color::WHITE,
                    ..default()
                },
            ));
        });
}

// Animate UI elements
pub fn animate_ui_elements(
    mut commands: Commands,
    time: Res<Time>,
    mut animated: Query<(
        Entity,
        &mut UIAnimation,
        &mut Style,
        Option<&mut BackgroundColor>,
    )>,
) {
    for (entity, mut animation, mut style, bg_color) in animated.iter_mut() {
        if animation.start_time == 0.0 {
            animation.start_time = time.elapsed_seconds();
        }

        let elapsed = time.elapsed_seconds() - animation.start_time;
        let progress = (elapsed / animation.duration).min(1.0);

        match &animation.animation_type {
            UIAnimationType::FadeIn => {
                if let Some(mut bg) = bg_color {
                    bg.0.set_a(progress);
                }
            }
            UIAnimationType::SlideIn(offset) => {
                let current_offset = *offset * (1.0 - progress);
                style.left = Val::Px(current_offset.x);
                style.top = Val::Px(current_offset.y);
            }
            UIAnimationType::Pulse => {
                let _scale = 1.0 + (progress * std::f32::consts::PI * 2.0).sin() * 0.1;
                // In a real implementation, we'd apply scale transform
            }
            UIAnimationType::Bounce => {
                let bounce = (progress * std::f32::consts::PI).sin();
                style.top = Val::Px(bounce * 10.0);
            }
        }

        if progress >= 1.0 {
            commands.entity(entity).remove::<UIAnimation>();
        }
    }
}

// Update turn indicator
pub fn update_turn_indicator_enhanced(
    game_state: Res<GameState>,
    mut turn_text: Query<&mut Text, With<TurnIndicatorText>>,
) {
    if let Ok(mut text) = turn_text.get_single_mut() {
        let player_name = match game_state.current_player {
            Player::Player1 => "Player 1",
            Player::Player2 => "Player 2",
        };

        let phase = match game_state.turn_phase {
            TurnPhase::PowerActivation => "Power Phase",
            TurnPhase::PieceMovement => "Move Phase",
            TurnPhase::PowerCollection => "Collection Phase",
        };

        text.sections[0].value = format!("{}'s Turn - {}", player_name, phase);
        text.sections[0].style.color = match game_state.current_player {
            Player::Player1 => QuadradiusTheme::TEAM_1_PRIMARY, // Blue for Player 1
            Player::Player2 => QuadradiusTheme::TEAM_2_PRIMARY, // Red for Player 2
        };
    }
}

// Tooltip system
pub fn show_power_tooltips(
    mut commands: Commands,
    windows: Query<&Window>,
    power_icons: Query<(&PowerIcon, &GlobalTransform, &Node)>,
    existing_tooltips: Query<Entity, With<PowerTooltip>>,
) {
    // Clear old tooltips
    for entity in existing_tooltips.iter() {
        commands.entity(entity).despawn_recursive();
    }

    let window = windows.single();
    if let Some(cursor_pos) = window.cursor_position() {
        for (icon, transform, node) in power_icons.iter() {
            let icon_pos = transform.translation().truncate();
            let icon_size = node.size();

            // Simple AABB check for hover
            if cursor_pos.x >= icon_pos.x - icon_size.x / 2.0
                && cursor_pos.x <= icon_pos.x + icon_size.x / 2.0
                && cursor_pos.y >= icon_pos.y - icon_size.y / 2.0
                && cursor_pos.y <= icon_pos.y + icon_size.y / 2.0
            {
                spawn_tooltip(&mut commands, icon.power_type, cursor_pos);
            }
        }
    }
}

fn spawn_tooltip(commands: &mut Commands, power_type: PowerType, position: Vec2) {
    commands
        .spawn((
            NodeBundle {
                style: Style {
                    position_type: PositionType::Absolute,
                    left: Val::Px(position.x + 10.0),
                    top: Val::Px(position.y - 30.0),
                    padding: UiRect::all(Val::Px(10.0)),
                    border: UiRect::all(Val::Px(2.0)),
                    ..default()
                },
                background_color: BackgroundColor(Color::rgba(0.1, 0.1, 0.15, 0.95)),
                border_color: BorderColor(power_type.color()),
                z_index: ZIndex::Global(100),
                ..default()
            },
            PowerTooltip { power_type },
        ))
        .with_children(|parent| {
            parent.spawn(TextBundle::from_section(
                get_power_description(power_type),
                TextStyle {
                    font_size: 14.0,
                    color: Color::rgb(0.9, 0.9, 0.9),
                    ..default()
                },
            ));
        });
}

fn get_power_description(power_type: PowerType) -> &'static str {
    match power_type {
        PowerType::MoveDiagonal => "Move diagonally for one turn",
        PowerType::RaiseColumn => "Raise all tiles in a column by 1 height",
        PowerType::LowerColumn => "Lower all tiles in a column by 1 height",
        PowerType::DestroyColumn => "Destroy an entire column and all pieces on it",
        PowerType::Multiply => "Create a copy of your piece on an adjacent tile",
        PowerType::Teleport => "Move to any empty square on the board",
        PowerType::Jump => "Jump over pieces in straight lines",
        PowerType::MoveTwo => "Move exactly 2 squares in one direction",
        PowerType::Knight => "Move in an L-shape like a chess knight",
        PowerType::SmartBomb => "Destroy all pieces in a 3x3 area",
        PowerType::Sniper => "Eliminate any enemy piece",
        PowerType::Assassin => "Eliminate ANY piece on the board",
        _ => "Power description not available",
    }
}
