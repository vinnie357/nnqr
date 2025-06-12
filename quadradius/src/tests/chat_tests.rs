use crate::components::{
    ChatContentArea, ChatHeader, ChatInputField, ChatMessage, ChatMessageText, ChatMinimizeButton,
    ChatPanel, ChatScrollArea, ChatSendButton, ChatState, ChatUnreadIndicator, Player,
};
use bevy::prelude::*;

#[test]
fn test_chat_message_creation() {
    let message = ChatMessage::new("Hello world!".to_string(), Player::Player1, 123.456);

    assert_eq!(message.content, "Hello world!");
    assert_eq!(message.author, Player::Player1);
    assert_eq!(message.timestamp, 123.456);
}

#[test]
fn test_chat_state_creation() {
    let chat_state = ChatState::new();

    assert_eq!(chat_state.message_count(), 0);
    assert_eq!(chat_state.get_input(), "");
    assert_eq!(chat_state.max_messages, 100);
}

#[test]
fn test_chat_state_add_message() {
    let mut chat_state = ChatState::new();

    let message1 = ChatMessage::new("First message".to_string(), Player::Player1, 1.0);
    let message2 = ChatMessage::new("Second message".to_string(), Player::Player2, 2.0);

    chat_state.add_message(message1.clone());
    assert_eq!(chat_state.message_count(), 1);
    assert_eq!(chat_state.get_messages()[0], message1);

    chat_state.add_message(message2.clone());
    assert_eq!(chat_state.message_count(), 2);
    assert_eq!(chat_state.get_messages()[1], message2);
}

#[test]
fn test_chat_state_input_management() {
    let mut chat_state = ChatState::new();

    // Test setting input
    chat_state.set_input("Hello!".to_string());
    assert_eq!(chat_state.get_input(), "Hello!");

    // Test clearing input
    chat_state.clear_input();
    assert_eq!(chat_state.get_input(), "");
}

#[test]
fn test_chat_state_message_limit() {
    let mut chat_state = ChatState::new();
    chat_state.max_messages = 3; // Set small limit for testing

    // Add messages beyond the limit
    for i in 0..5 {
        let message = ChatMessage::new(format!("Message {}", i), Player::Player1, i as f64);
        chat_state.add_message(message);
    }

    // Should only keep the last 3 messages
    assert_eq!(chat_state.message_count(), 3);
    assert_eq!(chat_state.get_messages()[0].content, "Message 2");
    assert_eq!(chat_state.get_messages()[1].content, "Message 3");
    assert_eq!(chat_state.get_messages()[2].content, "Message 4");
}

#[test]
fn test_chat_message_serialization() {
    let message = ChatMessage::new("Test message".to_string(), Player::Player1, 123.456);

    let serialized = bincode::serialize(&message).unwrap();
    let deserialized: ChatMessage = bincode::deserialize(&serialized).unwrap();

    assert_eq!(message, deserialized);
}

#[test]
fn test_chat_panel_component_creation() {
    let mut app = App::new();

    // Spawn chat panel entity
    let panel_entity = app.world.spawn(ChatPanel).id();

    // Verify the panel exists
    assert!(app.world.entity(panel_entity).get::<ChatPanel>().is_some());
}

#[test]
fn test_chat_ui_components_integration() {
    let mut app = App::new();

    // Setup chat state
    app.insert_resource(ChatState::new());

    // Spawn chat UI components
    let panel = app.world.spawn(ChatPanel).id();
    let scroll_area = app.world.spawn(ChatScrollArea).id();
    let input_field = app.world.spawn(ChatInputField).id();
    let send_button = app.world.spawn(ChatSendButton).id();

    // Verify all components exist
    assert!(app.world.entity(panel).get::<ChatPanel>().is_some());
    assert!(app
        .world
        .entity(scroll_area)
        .get::<ChatScrollArea>()
        .is_some());
    assert!(app
        .world
        .entity(input_field)
        .get::<ChatInputField>()
        .is_some());
    assert!(app
        .world
        .entity(send_button)
        .get::<ChatSendButton>()
        .is_some());

    // Verify chat state is accessible
    let chat_state = app.world.resource::<ChatState>();
    assert_eq!(chat_state.message_count(), 0);
}

#[test]
fn test_chat_message_ordering() {
    let mut chat_state = ChatState::new();

    // Add messages with different timestamps
    let msg1 = ChatMessage::new("First".to_string(), Player::Player1, 1.0);
    let msg2 = ChatMessage::new("Second".to_string(), Player::Player2, 2.0);
    let msg3 = ChatMessage::new("Third".to_string(), Player::Player1, 3.0);

    chat_state.add_message(msg1);
    chat_state.add_message(msg2);
    chat_state.add_message(msg3);

    // Messages should be in order of addition (chronological)
    let messages = chat_state.get_messages();
    assert_eq!(messages[0].content, "First");
    assert_eq!(messages[1].content, "Second");
    assert_eq!(messages[2].content, "Third");

    assert_eq!(messages[0].timestamp, 1.0);
    assert_eq!(messages[1].timestamp, 2.0);
    assert_eq!(messages[2].timestamp, 3.0);
}

#[test]
fn test_chat_message_player_identification() {
    let mut chat_state = ChatState::new();

    let p1_message = ChatMessage::new("Player 1 message".to_string(), Player::Player1, 1.0);
    let p2_message = ChatMessage::new("Player 2 message".to_string(), Player::Player2, 2.0);

    chat_state.add_message(p1_message);
    chat_state.add_message(p2_message);

    let messages = chat_state.get_messages();
    assert_eq!(messages[0].author, Player::Player1);
    assert_eq!(messages[1].author, Player::Player2);
}

#[test]
fn test_chat_message_text_component() {
    let mut app = App::new();

    // Spawn message text component
    let message_entity = app.world.spawn(ChatMessageText { message_index: 5 }).id();

    // Verify component
    let message_text = app
        .world
        .entity(message_entity)
        .get::<ChatMessageText>()
        .unwrap();
    assert_eq!(message_text.message_index, 5);
}

#[test]
fn test_chat_system_integration() {
    let mut app = App::new();
    app.insert_resource(ChatState::new());

    // Add a message to the chat state
    {
        let mut chat_state = app.world.resource_mut::<ChatState>();
        chat_state.add_message(ChatMessage::new(
            "Integration test".to_string(),
            Player::Player1,
            1.0,
        ));
    }

    // Verify message was added
    let chat_state = app.world.resource::<ChatState>();
    assert_eq!(chat_state.message_count(), 1);
    assert_eq!(chat_state.get_messages()[0].content, "Integration test");
}

#[test]
fn test_chat_input_validation() {
    let mut chat_state = ChatState::new();

    // Test empty message handling
    chat_state.set_input("".to_string());
    assert_eq!(chat_state.get_input(), "");

    // Test whitespace-only message
    chat_state.set_input("   ".to_string());
    assert_eq!(chat_state.get_input(), "   ");

    // Test normal message
    chat_state.set_input("Valid message".to_string());
    assert_eq!(chat_state.get_input(), "Valid message");

    // Test long message
    let long_message = "a".repeat(1000);
    chat_state.set_input(long_message.clone());
    assert_eq!(chat_state.get_input(), &long_message);
}

#[test]
fn test_chat_history_persistence() {
    let mut chat_state = ChatState::new();

    // Add several messages
    for i in 0..10 {
        let message = ChatMessage::new(
            format!("Message {}", i),
            if i % 2 == 0 {
                Player::Player1
            } else {
                Player::Player2
            },
            i as f64,
        );
        chat_state.add_message(message);
    }

    assert_eq!(chat_state.message_count(), 10);

    // Verify all messages are preserved
    for i in 0..10 {
        assert_eq!(
            chat_state.get_messages()[i].content,
            format!("Message {}", i)
        );
    }
}

#[test]
fn test_chat_panel_layout_components() {
    let mut app = App::new();

    // Test spawning a complete chat panel hierarchy
    let main_panel = app
        .world
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
                    ..default()
                },
                background_color: BackgroundColor(Color::rgba(0.1, 0.1, 0.1, 0.9)),
                ..default()
            },
        ))
        .id();

    // Verify the panel has the correct components
    assert!(app.world.entity(main_panel).get::<ChatPanel>().is_some());
    assert!(app.world.entity(main_panel).get::<Node>().is_some());
}

#[test]
fn test_chat_state_edge_cases() {
    let mut chat_state = ChatState::new();

    // Test with max_messages = 0 (should handle gracefully)
    chat_state.max_messages = 0;
    chat_state.add_message(ChatMessage::new("Test".to_string(), Player::Player1, 1.0));
    assert_eq!(chat_state.message_count(), 0); // Should be removed immediately

    // Test with max_messages = 1
    chat_state.max_messages = 1;
    chat_state.add_message(ChatMessage::new("First".to_string(), Player::Player1, 1.0));
    assert_eq!(chat_state.message_count(), 1);

    chat_state.add_message(ChatMessage::new("Second".to_string(), Player::Player2, 2.0));
    assert_eq!(chat_state.message_count(), 1);
    assert_eq!(chat_state.get_messages()[0].content, "Second");
}

#[test]
fn test_chat_minimize_maximize_state() {
    let mut app = App::new();
    app.insert_resource(ChatState::new());

    // Test initial minimized state
    let chat_state = app.world.resource::<ChatState>();
    assert!(!chat_state.is_minimized);
    assert_eq!(chat_state.unread_count, 0);

    // Test minimizing chat
    {
        let mut chat_state = app.world.resource_mut::<ChatState>();
        chat_state.minimize();
        assert!(chat_state.is_minimized);
    }

    // Test maximizing chat
    {
        let mut chat_state = app.world.resource_mut::<ChatState>();
        chat_state.maximize();
        assert!(!chat_state.is_minimized);
        assert_eq!(chat_state.unread_count, 0); // Should reset unread count
    }
}

#[test]
fn test_chat_unread_message_tracking() {
    let mut app = App::new();
    app.insert_resource(ChatState::new());

    // Minimize chat and add messages
    {
        let mut chat_state = app.world.resource_mut::<ChatState>();
        chat_state.minimize();

        // Add messages while minimized
        chat_state.add_message(ChatMessage::new(
            "Message 1".to_string(),
            Player::Player1,
            1.0,
        ));
        chat_state.add_message(ChatMessage::new(
            "Message 2".to_string(),
            Player::Player2,
            2.0,
        ));

        assert_eq!(chat_state.unread_count, 2);
    }

    // Maximize should reset unread count
    {
        let mut chat_state = app.world.resource_mut::<ChatState>();
        chat_state.maximize();
        assert_eq!(chat_state.unread_count, 0);
    }
}

#[test]
fn test_chat_minimize_button_component() {
    let mut app = App::new();

    // Spawn minimize button component
    let button_entity = app.world.spawn(ChatMinimizeButton).id();

    // Verify component exists
    assert!(app
        .world
        .entity(button_entity)
        .get::<ChatMinimizeButton>()
        .is_some());
}

#[test]
fn test_chat_header_component() {
    let mut app = App::new();

    // Spawn chat header component
    let header_entity = app.world.spawn(ChatHeader).id();

    // Verify component exists
    assert!(app
        .world
        .entity(header_entity)
        .get::<ChatHeader>()
        .is_some());
}

#[test]
fn test_chat_content_area_component() {
    let mut app = App::new();

    // Spawn chat content area component
    let content_entity = app.world.spawn(ChatContentArea).id();

    // Verify component exists
    assert!(app
        .world
        .entity(content_entity)
        .get::<ChatContentArea>()
        .is_some());
}

#[test]
fn test_chat_unread_indicator_component() {
    let mut app = App::new();

    // Spawn unread indicator component
    let indicator_entity = app.world.spawn(ChatUnreadIndicator).id();

    // Verify component exists
    assert!(app
        .world
        .entity(indicator_entity)
        .get::<ChatUnreadIndicator>()
        .is_some());
}
