use crate::components::chat::ChatState;

/// Test that chat window starts minimized by default
#[test]
fn test_chat_starts_minimized() {
    println!("🎯 Chat Default State Test");
    println!("   Verifying that chat window starts minimized");

    // Test using Default trait (like init_resource does)
    let chat_default = ChatState::default();
    assert!(chat_default.is_minimized, "Chat should start minimized when using Default trait");
    
    // Test using new() method
    let chat_new = ChatState::new();
    assert!(chat_new.is_minimized, "Chat should start minimized when using new() method");
    
    // Verify other default values
    assert_eq!(chat_default.messages.len(), 0, "Should start with no messages");
    assert_eq!(chat_default.current_input, "", "Should start with empty input");
    assert_eq!(chat_default.max_messages, 100, "Should have max_messages set to 100");
    assert_eq!(chat_default.unread_count, 0, "Should start with no unread messages");
    
    println!("   ✅ Chat starts minimized: {}", chat_default.is_minimized);
    println!("   ✅ Initial unread count: {}", chat_default.unread_count);
    println!("   ✅ Max messages: {}", chat_default.max_messages);
    
    // Test that adding a message while minimized increments unread count
    let mut chat = ChatState::default();
    assert!(chat.is_minimized, "Chat should start minimized");
    assert_eq!(chat.unread_count, 0, "Should start with 0 unread");
    
    // Add a message while minimized
    let message = crate::components::chat::ChatMessage::new(
        "Test message".to_string(),
        crate::components::Player::Player1,
        0.0
    );
    chat.add_message(message);
    
    assert_eq!(chat.unread_count, 1, "Should have 1 unread message after adding while minimized");
    println!("   ✅ Unread count increments when minimized: {}", chat.unread_count);
    
    // Test maximizing clears unread count
    chat.maximize();
    assert!(!chat.is_minimized, "Chat should be maximized after calling maximize()");
    assert_eq!(chat.unread_count, 0, "Unread count should be cleared when maximized");
    println!("   ✅ Maximizing clears unread count: {}", chat.unread_count);
    
    println!("✅ Chat Default State Test Complete");
}

/// Test chat toggle functionality
#[test]
fn test_chat_toggle_functionality() {
    println!("🎯 Chat Toggle Functionality Test");
    
    let mut chat = ChatState::default();
    assert!(chat.is_minimized, "Should start minimized");
    
    // Toggle to maximize
    chat.toggle_minimized();
    assert!(!chat.is_minimized, "Should be maximized after first toggle");
    
    // Toggle back to minimize
    chat.toggle_minimized();
    assert!(chat.is_minimized, "Should be minimized after second toggle");
    
    println!("   ✅ Toggle functionality works correctly");
    println!("✅ Chat Toggle Test Complete");
}

/// Test that the init_resource pattern works correctly
#[test]
fn test_init_resource_pattern() {
    println!("🎯 Init Resource Pattern Test");
    println!("   Verifying that .init_resource::<ChatState>() creates minimized chat");
    
    use bevy::prelude::*;
    
    // Simulate what happens in main.rs with .init_resource::<ChatState>()
    let mut app = App::new();
    app.add_plugins(MinimalPlugins);
    app.init_resource::<ChatState>();
    
    let chat_state = app.world.resource::<ChatState>();
    assert!(chat_state.is_minimized, "ChatState from init_resource should start minimized");
    
    println!("   ✅ init_resource pattern creates minimized chat");
    println!("✅ Init Resource Pattern Test Complete");
}