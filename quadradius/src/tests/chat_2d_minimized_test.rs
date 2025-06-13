use crate::components::chat::*;
use crate::resources::render_config::RenderConfig;
use crate::systems::chat_ui::*;
use bevy::prelude::*;
use bevy::ecs::system::RunSystemOnce;

/// Test to verify that chat starts minimized by default in 2D view
#[test]
fn test_chat_starts_minimized_in_2d_view() {
    println!("🎯 Chat 2D Minimized State Test");
    println!("   Verifying chat starts minimized by default in 2D view");
    
    let mut app = App::new();
    app.add_plugins(MinimalPlugins);
    
    // Set up 2D view configuration
    let mut render_config = RenderConfig::default();
    render_config.use_3d = false; // Explicitly set to 2D mode
    app.world.insert_resource(render_config);
    
    // Initialize chat state (should start minimized)
    app.world.init_resource::<ChatState>();
    
    // Set up chat UI
    app.world.run_system_once(setup_chat_ui);
    
    println!("\n📊 Chat State Verification:");
    
    // Verify chat state is minimized
    let chat_state = app.world.resource::<ChatState>();
    assert!(chat_state.is_minimized, "Chat should start minimized by default");
    println!("   ✅ ChatState.is_minimized: {}", chat_state.is_minimized);
    
    // Verify chat panel height is minimized
    let mut panel_query = app.world.query::<(&Style, &ChatPanel)>();
    let mut found_panel = false;
    for (style, _) in panel_query.iter(&app.world) {
        found_panel = true;
        match style.height {
            Val::Px(height) => {
                assert_eq!(height, 50.0, "Chat panel should have minimized height of 50px");
                println!("   ✅ Chat panel height: {}px (minimized)", height);
            }
            _ => panic!("Chat panel height should be in pixels"),
        }
    }
    assert!(found_panel, "Chat panel should exist");
    
    // Verify chat content area is hidden
    let mut content_query = app.world.query::<(&Visibility, &ChatContentArea)>();
    let mut found_content = false;
    for (visibility, _) in content_query.iter(&app.world) {
        found_content = true;
        assert_eq!(*visibility, Visibility::Hidden, "Chat content area should be hidden when minimized");
        println!("   ✅ Chat content area visibility: Hidden");
    }
    assert!(found_content, "Chat content area should exist");
    
    // Verify minimize button shows maximize symbol
    let mut button_query = app.world.query_filtered::<Entity, With<ChatMinimizeButton>>();
    let button_entities: Vec<Entity> = button_query.iter(&app.world).collect();
    assert_eq!(button_entities.len(), 1, "Should have exactly one minimize button");
    
    let button_entity = button_entities[0];
    let children = app.world.get::<Children>(button_entity).expect("Button should have children");
    let text_entity = children[0];
    let text = app.world.get::<Text>(text_entity).expect("Button child should have Text component");
    
    assert_eq!(text.sections[0].value, "⬜", "Minimize button should show maximize symbol when chat is minimized");
    println!("   ✅ Minimize button symbol: '{}' (maximize)", text.sections[0].value);
    
    println!("\n📋 2D View Configuration:");
    let render_config = app.world.resource::<RenderConfig>();
    assert!(!render_config.use_3d, "Should be in 2D mode");
    println!("   ✅ Render mode: 2D (use_3d: {})", render_config.use_3d);
    
    println!("\n✅ Chat 2D Minimized State Test Results:");
    println!("   🔽 Chat state: Minimized by default ✅");
    println!("   📐 Panel height: 50px (minimized) ✅");
    println!("   👁️ Content area: Hidden ✅");
    println!("   🔘 Button symbol: Maximize (⬜) ✅");
    println!("   🎮 2D view: Chat correctly minimized ✅");
}

/// Test toggling chat minimize/maximize in 2D view
#[test]
fn test_chat_toggle_in_2d_view() {
    println!("🎯 Chat Toggle in 2D View Test");
    println!("   Testing chat minimize/maximize functionality in 2D mode");
    
    let mut app = App::new();
    app.add_plugins(MinimalPlugins);
    
    // Set up 2D view configuration
    let mut render_config = RenderConfig::default();
    render_config.use_3d = false;
    app.world.insert_resource(render_config);
    
    // Initialize chat state and UI
    app.world.init_resource::<ChatState>();
    app.world.run_system_once(setup_chat_ui);
    
    println!("\n1️⃣ Initial State (should be minimized):");
    
    let chat_state = app.world.resource::<ChatState>();
    assert!(chat_state.is_minimized, "Chat should start minimized");
    println!("   Chat minimized: ✅");
    
    println!("\n2️⃣ Simulating click on minimize button (should maximize):");
    
    // Find the minimize button and simulate click
    let mut button_query = app.world.query_filtered::<Entity, With<ChatMinimizeButton>>();
    let button_entities: Vec<Entity> = button_query.iter(&app.world).collect();
    let button_entity = button_entities[0];
    
    // Set button interaction to Pressed
    app.world.entity_mut(button_entity).insert(Interaction::Pressed);
    
    // Run the minimize/maximize handler system
    app.world.run_system_once(handle_chat_minimize_maximize);
    
    // Verify chat is now maximized
    let chat_state = app.world.resource::<ChatState>();
    assert!(!chat_state.is_minimized, "Chat should be maximized after click");
    println!("   Chat maximized: ✅");
    
    // Verify panel height changed
    let mut panel_query = app.world.query::<(&Style, &ChatPanel)>();
    for (style, _) in panel_query.iter(&app.world) {
        match style.height {
            Val::Px(height) => {
                assert_eq!(height, 400.0, "Chat panel should have maximized height");
                println!("   Panel height: {}px (maximized) ✅", height);
            }
            _ => panic!("Chat panel height should be in pixels"),
        }
    }
    
    // Verify content area is visible
    let mut content_query = app.world.query::<(&Visibility, &ChatContentArea)>();
    for (visibility, _) in content_query.iter(&app.world) {
        assert_eq!(*visibility, Visibility::Visible, "Content should be visible when maximized");
        println!("   Content area visible: ✅");
    }
    
    println!("\n3️⃣ Simulating second click (should minimize again):");
    
    // Reset interaction and click again
    app.world.entity_mut(button_entity).insert(Interaction::Pressed);
    app.world.run_system_once(handle_chat_minimize_maximize);
    
    // Verify chat is minimized again
    let chat_state = app.world.resource::<ChatState>();
    assert!(chat_state.is_minimized, "Chat should be minimized after second click");
    println!("   Chat minimized again: ✅");
    
    println!("\n✅ Chat Toggle in 2D View Test Results:");
    println!("   🔽 Initial state: Minimized ✅");
    println!("   🔼 After first click: Maximized ✅");
    println!("   🔽 After second click: Minimized ✅");
    println!("   🎮 2D view: Toggle functionality working ✅");
}

/// Test that chat behavior is consistent across view switches
#[test]
fn test_chat_consistent_across_view_switches() {
    println!("🎯 Chat Consistency Across View Switches Test");
    println!("   Testing that chat state persists when switching between 2D and 3D");
    
    let mut app = App::new();
    app.add_plugins(MinimalPlugins);
    
    // Start in 2D mode
    let mut render_config = RenderConfig::default();
    render_config.use_3d = false;
    app.world.insert_resource(render_config);
    
    // Initialize chat
    app.world.init_resource::<ChatState>();
    app.world.run_system_once(setup_chat_ui);
    
    println!("\n📋 Testing scenario:");
    println!("   1. Start in 2D mode (chat should be minimized)");
    println!("   2. Switch to 3D mode (chat state should persist)");
    println!("   3. Switch back to 2D mode (chat state should persist)");
    
    // Verify initial 2D state
    let chat_state = app.world.resource::<ChatState>();
    assert!(chat_state.is_minimized, "Chat should start minimized in 2D");
    println!("\n✅ 2D mode: Chat minimized");
    
    // Switch to 3D mode
    {
        let mut render_config = app.world.resource_mut::<RenderConfig>();
        render_config.use_3d = true;
    }
    
    // Chat state should persist
    let chat_state = app.world.resource::<ChatState>();
    assert!(chat_state.is_minimized, "Chat state should persist when switching to 3D");
    println!("✅ 3D mode: Chat state persisted (minimized)");
    
    // Maximize chat in 3D mode
    let mut button_query = app.world.query_filtered::<Entity, With<ChatMinimizeButton>>();
    let button_entities: Vec<Entity> = button_query.iter(&app.world).collect();
    let button_entity = button_entities[0];
    
    app.world.entity_mut(button_entity).insert(Interaction::Pressed);
    app.world.run_system_once(handle_chat_minimize_maximize);
    
    let chat_state = app.world.resource::<ChatState>();
    assert!(!chat_state.is_minimized, "Chat should be maximized in 3D");
    println!("✅ 3D mode: Chat maximized");
    
    // Switch back to 2D mode
    {
        let mut render_config = app.world.resource_mut::<RenderConfig>();
        render_config.use_3d = false;
    }
    
    // Chat state should persist
    let chat_state = app.world.resource::<ChatState>();
    assert!(!chat_state.is_minimized, "Chat state should persist when switching back to 2D");
    println!("✅ 2D mode: Chat state persisted (maximized)");
    
    println!("\n✅ Chat Consistency Test Results:");
    println!("   🔄 2D → 3D: State persisted ✅");
    println!("   🎯 3D manipulation: Working ✅");
    println!("   🔄 3D → 2D: State persisted ✅");
    println!("   📱 View switching: Chat behavior consistent ✅");
}