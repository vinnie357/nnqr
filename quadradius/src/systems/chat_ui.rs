use crate::components::*;
use crate::resources::*;
use bevy::prelude::*;

/// Setup the chat UI panel on the right side of the screen
pub fn setup_chat_ui(mut commands: Commands) {
    // Main chat panel - positioned on the right side
    commands
        .spawn((
            ChatPanel,
            NodeBundle {
                style: Style {
                    width: Val::Px(300.0),
                    height: Val::Px(400.0),
                    position_type: PositionType::Absolute,
                    right: Val::Px(10.0),
                    top: Val::Px(10.0),
                    flex_direction: FlexDirection::Column,
                    border: UiRect::all(Val::Px(2.0)),
                    padding: UiRect::all(Val::Px(5.0)),
                    ..default()
                },
                background_color: BackgroundColor(Color::rgba(0.1, 0.1, 0.15, 0.9)),
                border_color: BorderColor(QuadradiusTheme::UI_BORDER),
                ..default()
            },
        ))
        .with_children(|parent| {
            // Chat header with title and minimize button
            parent
                .spawn((
                    ChatHeader,
                    NodeBundle {
                        style: Style {
                            width: Val::Percent(100.0),
                            height: Val::Px(30.0),
                            flex_direction: FlexDirection::Row,
                            justify_content: JustifyContent::SpaceBetween,
                            align_items: AlignItems::Center,
                            margin: UiRect::bottom(Val::Px(5.0)),
                            ..default()
                        },
                        ..default()
                    },
                ))
                .with_children(|parent| {
                    // Chat title
                    parent.spawn(TextBundle::from_section(
                        "Chat",
                        TextStyle {
                            font_size: 18.0,
                            color: QuadradiusTheme::UI_TEXT_HIGHLIGHT,
                            ..default()
                        },
                    ));

                    // Container for unread indicator and minimize button
                    parent
                        .spawn(NodeBundle {
                            style: Style {
                                flex_direction: FlexDirection::Row,
                                align_items: AlignItems::Center,
                                column_gap: Val::Px(5.0),
                                ..default()
                            },
                            ..default()
                        })
                        .with_children(|parent| {
                            // Unread indicator (hidden by default)
                            parent.spawn((
                                ChatUnreadIndicator,
                                TextBundle {
                                    text: Text::from_section(
                                        "",
                                        TextStyle {
                                            font_size: 12.0,
                                            color: QuadradiusTheme::INDUSTRIAL_ORANGE,
                                            ..default()
                                        },
                                    ),
                                    visibility: Visibility::Hidden,
                                    ..default()
                                },
                            ));

                            // Minimize/Maximize button
                            parent
                                .spawn((
                                    ChatMinimizeButton,
                                    ButtonBundle {
                                        style: Style {
                                            width: Val::Px(20.0),
                                            height: Val::Px(20.0),
                                            justify_content: JustifyContent::Center,
                                            align_items: AlignItems::Center,
                                            border: UiRect::all(Val::Px(1.0)),
                                            ..default()
                                        },
                                        background_color: BackgroundColor(
                                            QuadradiusTheme::UI_PANEL,
                                        ),
                                        border_color: BorderColor(QuadradiusTheme::UI_BORDER),
                                        ..default()
                                    },
                                ))
                                .with_children(|parent| {
                                    parent.spawn(TextBundle::from_section(
                                        "−", // Minimize symbol
                                        TextStyle {
                                            font_size: 14.0,
                                            color: QuadradiusTheme::UI_TEXT,
                                            ..default()
                                        },
                                    ));
                                });
                        });
                });

            // Chat content area (scrollable messages and input)
            parent
                .spawn((
                    ChatContentArea,
                    NodeBundle {
                        style: Style {
                            width: Val::Percent(100.0),
                            flex_grow: 1.0,
                            flex_direction: FlexDirection::Column,
                            ..default()
                        },
                        ..default()
                    },
                ))
                .with_children(|parent| {
                    // Scroll area for messages
                    parent
                        .spawn((
                            ChatScrollArea,
                            NodeBundle {
                                style: Style {
                                    width: Val::Percent(100.0),
                                    height: Val::Px(320.0),
                                    flex_direction: FlexDirection::Column,
                                    overflow: Overflow::clip(),
                                    margin: UiRect::vertical(Val::Px(5.0)),
                                    padding: UiRect::all(Val::Px(5.0)),
                                    ..default()
                                },
                                background_color: BackgroundColor(Color::rgba(
                                    0.05, 0.05, 0.1, 0.8,
                                )),
                                ..default()
                            },
                        ))
                        .with_children(|parent| {
                            // Initial placeholder message
                            parent.spawn((
                                TextBundle::from_section(
                                    "Welcome to Quadradius! Chat with your opponent here.",
                                    TextStyle {
                                        font_size: 12.0,
                                        color: Color::rgb(0.7, 0.7, 0.7),
                                        ..default()
                                    },
                                ),
                                ChatMessageText { message_index: 0 },
                            ));
                        });

                    // Input area
                    parent
                        .spawn(NodeBundle {
                            style: Style {
                                width: Val::Percent(100.0),
                                height: Val::Px(40.0),
                                flex_direction: FlexDirection::Row,
                                align_items: AlignItems::Center,
                                column_gap: Val::Px(5.0),
                                ..default()
                            },
                            ..default()
                        })
                        .with_children(|parent| {
                            // Input field (simulated with text for now)
                            parent.spawn((
                                ChatInputField,
                                NodeBundle {
                                    style: Style {
                                        width: Val::Percent(75.0),
                                        height: Val::Px(30.0),
                                        border: UiRect::all(Val::Px(1.0)),
                                        padding: UiRect::all(Val::Px(5.0)),
                                        align_items: AlignItems::Center,
                                        ..default()
                                    },
                                    background_color: BackgroundColor(Color::rgba(
                                        0.2, 0.2, 0.25, 1.0,
                                    )),
                                    border_color: BorderColor(Color::rgb(0.4, 0.4, 0.5)),
                                    ..default()
                                },
                            ));

                            // Send button
                            parent
                                .spawn((
                                    ChatSendButton,
                                    ButtonBundle {
                                        style: Style {
                                            width: Val::Percent(20.0),
                                            height: Val::Px(30.0),
                                            justify_content: JustifyContent::Center,
                                            align_items: AlignItems::Center,
                                            border: UiRect::all(Val::Px(1.0)),
                                            ..default()
                                        },
                                        background_color: BackgroundColor(
                                            QuadradiusTheme::INDUSTRIAL_BLUE,
                                        ),
                                        border_color: BorderColor(QuadradiusTheme::UI_BORDER),
                                        ..default()
                                    },
                                ))
                                .with_children(|parent| {
                                    parent.spawn(TextBundle::from_section(
                                        "Send",
                                        TextStyle {
                                            font_size: 12.0,
                                            color: Color::WHITE,
                                            ..default()
                                        },
                                    ));
                                });
                        });
                });
        });

    info!("💬 Chat UI initialized");
}

/// Handle chat input and message sending
pub fn handle_chat_input(
    mut chat_state: ResMut<ChatState>,
    game_state: Res<GameState>,
    time: Res<Time>,
    input: Res<Input<KeyCode>>,
    mut button_query: Query<&Interaction, (Changed<Interaction>, With<ChatSendButton>)>,
) {
    // Simple chat simulation - pressing 'T' sends a test message
    if input.just_pressed(KeyCode::T) {
        let message = ChatMessage::new(
            format!("Test message from {:?}", game_state.current_player),
            game_state.current_player,
            time.elapsed_seconds_f64(),
        );
        chat_state.add_message(message);
        println!("💬 Test message sent");
    }

    // Handle send button interaction
    for interaction in button_query.iter_mut() {
        if *interaction == Interaction::Pressed {
            // For now, send a predefined message
            let message = ChatMessage::new(
                "Hello from button!".to_string(),
                game_state.current_player,
                time.elapsed_seconds_f64(),
            );
            chat_state.add_message(message);
            println!("💬 Button message sent");
        }
    }
}

/// Update chat message display (simplified version)
pub fn update_chat_display(
    chat_state: Res<ChatState>,
    scroll_area_query: Query<Entity, With<ChatScrollArea>>,
    children_query: Query<&Children>,
    mut commands: Commands,
) {
    if !chat_state.is_changed() {
        return;
    }

    // Find the scroll area entity
    if let Some(scroll_area_entity) = scroll_area_query.iter().next() {
        // Clear existing message texts except the first one (placeholder)
        if let Ok(children) = children_query.get(scroll_area_entity) {
            for (index, &child) in children.iter().enumerate() {
                if index > 0 {
                    commands.entity(child).despawn_recursive();
                }
            }
        }

        // Add all chat messages
        commands.entity(scroll_area_entity).with_children(|parent| {
            for (index, message) in chat_state.get_messages().iter().enumerate() {
                let author_color = match message.author {
                    Player::Player1 => QuadradiusTheme::TEAM_1_PRIMARY,
                    Player::Player2 => QuadradiusTheme::TEAM_2_PRIMARY,
                };

                let formatted_message = format!(
                    "[{:.1}s] {:?}: {}",
                    message.timestamp % 1000.0, // Show relative time
                    message.author,
                    message.content
                );

                parent.spawn((
                    TextBundle::from_section(
                        formatted_message,
                        TextStyle {
                            font_size: 12.0,
                            color: author_color,
                            ..default()
                        },
                    ),
                    ChatMessageText {
                        message_index: index + 1,
                    },
                ));
            }
        });
    }
}

/// Handle chat visibility toggle
pub fn toggle_chat_visibility(
    mut chat_panel_query: Query<&mut Visibility, With<ChatPanel>>,
    input: Res<Input<KeyCode>>,
) {
    if input.just_pressed(KeyCode::C) {
        for mut visibility in chat_panel_query.iter_mut() {
            *visibility = match *visibility {
                Visibility::Visible => Visibility::Hidden,
                _ => Visibility::Visible,
            };
            println!("💬 Chat visibility toggled");
        }
    }
}

/// Handle chat minimize/maximize functionality
pub fn handle_chat_minimize_maximize(
    mut chat_state: ResMut<ChatState>,
    mut minimize_button_query: Query<
        (&Interaction, &Children),
        (Changed<Interaction>, With<ChatMinimizeButton>),
    >,
    mut content_area_query: Query<&mut Visibility, With<ChatContentArea>>,
    mut panel_query: Query<&mut Style, With<ChatPanel>>,
    mut button_text_query: Query<&mut Text>,
) {
    for (interaction, children) in minimize_button_query.iter_mut() {
        if *interaction == Interaction::Pressed {
            chat_state.toggle_minimized();

            // Update content area visibility
            if let Ok(mut content_visibility) = content_area_query.get_single_mut() {
                *content_visibility = if chat_state.is_minimized {
                    Visibility::Hidden
                } else {
                    Visibility::Visible
                };
            }

            // Update panel height
            if let Ok(mut panel_style) = panel_query.get_single_mut() {
                panel_style.height = if chat_state.is_minimized {
                    Val::Px(50.0) // Just show header
                } else {
                    Val::Px(400.0) // Full chat panel
                };
            }

            // Update button text
            for &child in children.iter() {
                if let Ok(mut text) = button_text_query.get_mut(child) {
                    text.sections[0].value = if chat_state.is_minimized {
                        "⬜".to_string() // Maximize symbol
                    } else {
                        "−".to_string() // Minimize symbol
                    };
                }
            }

            println!(
                "💬 Chat {}",
                if chat_state.is_minimized {
                    "minimized"
                } else {
                    "maximized"
                }
            );
        }
    }
}

/// Update unread message indicator
pub fn update_unread_indicator(
    chat_state: Res<ChatState>,
    mut indicator_query: Query<(&mut Text, &mut Visibility), With<ChatUnreadIndicator>>,
) {
    if let Ok((mut text, mut visibility)) = indicator_query.get_single_mut() {
        if chat_state.is_minimized && chat_state.unread_count > 0 {
            text.sections[0].value = format!("({})", chat_state.unread_count);
            *visibility = Visibility::Visible;
        } else {
            *visibility = Visibility::Hidden;
        }
    }
}

/// Add some demo messages for testing
pub fn add_demo_chat_messages(
    mut chat_state: ResMut<ChatState>,
    time: Res<Time>,
    input: Res<Input<KeyCode>>,
) {
    if input.just_pressed(KeyCode::F11) {
        // Add a series of demo messages
        let demo_messages = [
            ("Good luck!", Player::Player1),
            ("Thanks! You too!", Player::Player2),
            ("That was a nice move", Player::Player1),
            ("Still learning the powers", Player::Player2),
            ("The terrain system is really cool", Player::Player1),
        ];

        for (i, (content, author)) in demo_messages.iter().enumerate() {
            let message = ChatMessage::new(
                content.to_string(),
                *author,
                time.elapsed_seconds_f64() + i as f64,
            );
            chat_state.add_message(message);
        }

        println!("💬 Demo messages added");
    }
}
