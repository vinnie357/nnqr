use crate::resources::render_config::RenderConfig;
use crate::systems::settings::*;
use crate::systems::*;
use bevy::prelude::*;

#[test]
fn test_board_view_switcher_default() {
    let render_config = RenderConfig::default();
    assert_eq!(
        render_config.use_3d, true,
        "Default should be 3D isometric view"
    );
}

#[test]
fn test_board_view_switcher_2d() {
    let render_config = RenderConfig::new_2d();
    assert_eq!(
        render_config.use_3d, false,
        "2D config should have use_3d = false"
    );
}

#[test]
fn test_board_view_switcher_3d() {
    let render_config = RenderConfig::new_3d();
    assert_eq!(
        render_config.use_3d, true,
        "3D config should have use_3d = true"
    );
}

#[test]
fn test_settings_menu_state() {
    let mut app = App::new();
    app.add_state::<SettingsMenuState>();

    // Default state should be Hidden
    let state = app.world.resource::<State<SettingsMenuState>>();
    assert_eq!(*state.get(), SettingsMenuState::Hidden);
}

#[test]
fn test_settings_button_actions() {
    let toggle_action = SettingsAction::ToggleBoardView;
    let back_action = SettingsAction::Back;

    // These should be different
    assert!(std::mem::discriminant(&toggle_action) != std::mem::discriminant(&back_action));
}

#[test]
fn test_render_config_toggle() {
    let mut render_config = RenderConfig::default();
    let original_use_3d = render_config.use_3d;

    // Toggle the value
    render_config.use_3d = !render_config.use_3d;

    assert_ne!(
        render_config.use_3d, original_use_3d,
        "Value should be toggled"
    );

    // Toggle back
    render_config.use_3d = !render_config.use_3d;

    assert_eq!(
        render_config.use_3d, original_use_3d,
        "Value should be back to original"
    );
}

#[test] 
fn test_2d_camera_setup() {
    let mut app = App::new();
    app.add_plugins(MinimalPlugins);
    
    // Test that we can spawn a 2D camera with proper marker
    app.world.spawn((Camera2dBundle::default(), Camera2D));
    
    // Check that camera has proper marker
    let cameras = app.world.query::<(&Camera, &Camera2D)>().iter(&app.world).count();
    assert_eq!(cameras, 1, "Should have one 2D camera with marker");
}

#[test]
fn test_board_view_components_exist() {
    // Test that the necessary component types exist for switching
    let mut app = App::new();
    app.add_plugins(MinimalPlugins);
    
    // Test that we can spawn entities with the required components
    app.world.spawn((Camera2D,));
    app.world.spawn((Camera3D,));
    
    let camera_2d_count = app.world.query::<&Camera2D>().iter(&app.world).count();
    let camera_3d_count = app.world.query::<&Camera3D>().iter(&app.world).count();
    
    assert_eq!(camera_2d_count, 1, "Should have one Camera2D component");
    assert_eq!(camera_3d_count, 1, "Should have one Camera3D component");
}

#[test]
fn test_enhanced_tile_size_consistency() {
    // Test that pieces and board use the same tile size calculation
    use crate::components::TILE_SIZE;
    
    let enhanced_tile_size = TILE_SIZE * 1.2;
    
    // This should match the calculation used in both board.rs and pieces.rs
    assert_eq!(enhanced_tile_size, 76.8, "Enhanced tile size should be consistent");
}

#[test]
fn test_switching_from_2d_to_3d() {
    let mut app = App::new();
    app.add_plugins(MinimalPlugins);
    app.init_resource::<RenderConfig>();
    
    // Start with 2D mode
    app.world.resource_mut::<RenderConfig>().use_3d = false;
    
    // Spawn entities for both views
    let board_2d = app.world.spawn((
        crate::components::Board,
        SpatialBundle::default(),
    )).id();
    let board_3d = app.world.spawn((
        crate::systems::board_3d::BoardTile3D {
            coordinates: (0, 0),
            height: 0,
        },
        SpatialBundle::default(),
    )).id();
    
    let piece_2d = app.world.spawn((
        crate::components::GamePiece {
            player: crate::components::Player::Player1,
            board_position: (0, 0),
        },
        SpatialBundle::default(),
    )).id();
    let piece_3d = app.world.spawn((
        crate::systems::pieces_3d::GamePiece3D {
            player: crate::components::Player::Player1,
            board_position: (0, 0),
        },
        SpatialBundle::default(),
    )).id();
    
    let camera_2d = app.world.spawn((Camera2dBundle::default(), Camera2D)).id();
    let camera_3d = app.world.spawn((Camera3dBundle::default(), Camera3D)).id();
    
    // Set initial visibility for 2D mode
    app.world.entity_mut(board_2d).insert(Visibility::Visible);
    app.world.entity_mut(board_3d).insert(Visibility::Hidden);
    app.world.entity_mut(piece_2d).insert(Visibility::Visible);
    app.world.entity_mut(piece_3d).insert(Visibility::Hidden);
    
    // Set initial camera states
    app.world.entity_mut(camera_2d).get_mut::<Camera>().unwrap().is_active = true;
    app.world.entity_mut(camera_3d).get_mut::<Camera>().unwrap().is_active = false;
    
    // Switch to 3D mode
    app.world.resource_mut::<RenderConfig>().use_3d = true;
    
    // Add the board view change system and run it
    app.add_systems(Update, handle_board_view_change);
    app.update();
    
    // Verify 3D entities are now visible and 2D are hidden
    assert_eq!(
        app.world.entity(board_2d).get::<Visibility>().unwrap(),
        &Visibility::Hidden,
        "2D board should be hidden after switch"
    );
    assert_eq!(
        app.world.entity(board_3d).get::<Visibility>().unwrap(),
        &Visibility::Visible,
        "3D board should be visible after switch"
    );
    assert_eq!(
        app.world.entity(piece_2d).get::<Visibility>().unwrap(),
        &Visibility::Hidden,
        "2D piece should be hidden after switch"
    );
    assert_eq!(
        app.world.entity(piece_3d).get::<Visibility>().unwrap(),
        &Visibility::Visible,
        "3D piece should be visible after switch"
    );
    
    // Verify camera states
    assert_eq!(
        app.world.entity(camera_2d).get::<Camera>().unwrap().is_active,
        false,
        "2D camera should be inactive after switch"
    );
    assert_eq!(
        app.world.entity(camera_3d).get::<Camera>().unwrap().is_active,
        true,
        "3D camera should be active after switch"
    );
}

#[test]
fn test_switching_from_3d_to_2d() {
    let mut app = App::new();
    app.add_plugins(MinimalPlugins);
    app.init_resource::<RenderConfig>();
    
    // Start with 3D mode (default)
    app.world.resource_mut::<RenderConfig>().use_3d = true;
    
    // Spawn entities for both views
    let board_2d = app.world.spawn((
        crate::components::Board,
        SpatialBundle::default(),
    )).id();
    let board_3d = app.world.spawn((
        crate::systems::board_3d::BoardTile3D {
            coordinates: (0, 0),
            height: 0,
        },
        SpatialBundle::default(),
    )).id();
    
    let piece_2d = app.world.spawn((
        crate::components::GamePiece {
            player: crate::components::Player::Player1,
            board_position: (0, 0),
        },
        SpatialBundle::default(),
    )).id();
    let piece_3d = app.world.spawn((
        crate::systems::pieces_3d::GamePiece3D {
            player: crate::components::Player::Player1,
            board_position: (0, 0),
        },
        SpatialBundle::default(),
    )).id();
    
    let camera_2d = app.world.spawn((Camera2dBundle::default(), Camera2D)).id();
    let camera_3d = app.world.spawn((Camera3dBundle::default(), Camera3D)).id();
    
    // Set initial visibility for 3D mode
    app.world.entity_mut(board_2d).insert(Visibility::Hidden);
    app.world.entity_mut(board_3d).insert(Visibility::Visible);
    app.world.entity_mut(piece_2d).insert(Visibility::Hidden);
    app.world.entity_mut(piece_3d).insert(Visibility::Visible);
    
    // Set initial camera states  
    app.world.entity_mut(camera_2d).get_mut::<Camera>().unwrap().is_active = false;
    app.world.entity_mut(camera_3d).get_mut::<Camera>().unwrap().is_active = true;
    
    // Switch to 2D mode
    app.world.resource_mut::<RenderConfig>().use_3d = false;
    
    // Add the board view change system and run it
    app.add_systems(Update, handle_board_view_change);
    app.update();
    
    // Verify 2D entities are now visible and 3D are hidden
    assert_eq!(
        app.world.entity(board_2d).get::<Visibility>().unwrap(),
        &Visibility::Visible,
        "2D board should be visible after switch"
    );
    assert_eq!(
        app.world.entity(board_3d).get::<Visibility>().unwrap(),
        &Visibility::Hidden,
        "3D board should be hidden after switch"
    );
    assert_eq!(
        app.world.entity(piece_2d).get::<Visibility>().unwrap(),
        &Visibility::Visible,
        "2D piece should be visible after switch"
    );
    assert_eq!(
        app.world.entity(piece_3d).get::<Visibility>().unwrap(),
        &Visibility::Hidden,
        "3D piece should be hidden after switch"
    );
    
    // Verify camera states
    assert_eq!(
        app.world.entity(camera_2d).get::<Camera>().unwrap().is_active,
        true,
        "2D camera should be active after switch"
    );
    assert_eq!(
        app.world.entity(camera_3d).get::<Camera>().unwrap().is_active,
        false,
        "3D camera should be inactive after switch"
    );
}

#[test]
fn test_multiple_view_switches() {
    let mut app = App::new();
    app.add_plugins(MinimalPlugins);
    app.init_resource::<RenderConfig>();
    
    // Start with 3D mode
    app.world.resource_mut::<RenderConfig>().use_3d = true;
    
    // Spawn test entities
    let camera_2d = app.world.spawn((Camera2dBundle::default(), Camera2D)).id();
    let camera_3d = app.world.spawn((Camera3dBundle::default(), Camera3D)).id();
    
    // Set initial camera states
    app.world.entity_mut(camera_2d).get_mut::<Camera>().unwrap().is_active = false;
    app.world.entity_mut(camera_3d).get_mut::<Camera>().unwrap().is_active = true;
    
    // Add the system
    app.add_systems(Update, handle_board_view_change);
    
    // Test multiple switches: 3D -> 2D -> 3D -> 2D
    for i in 0..4 {
        let use_3d = i % 2 == 1; // Start with 2D (false), then alternate
        app.world.resource_mut::<RenderConfig>().use_3d = use_3d;
        app.update();
        
        let camera_2d_active = app.world.entity(camera_2d).get::<Camera>().unwrap().is_active;
        let camera_3d_active = app.world.entity(camera_3d).get::<Camera>().unwrap().is_active;
        
        if use_3d {
            assert!(!camera_2d_active && camera_3d_active, "3D camera should be active on iteration {} (use_3d={})", i, use_3d);
        } else {
            assert!(camera_2d_active && !camera_3d_active, "2D camera should be active on iteration {} (use_3d={})", i, use_3d);
        }
    }
}

#[test]
fn test_drag_drop_camera_query_compatibility() {
    let mut app = App::new();
    app.add_plugins(MinimalPlugins);
    
    // Test that the 2D drag drop system can find the 2D camera
    let camera_2d = app.world.spawn((Camera2dBundle::default(), Camera2D)).id();
    let _camera_3d = app.world.spawn((Camera3dBundle::default(), Camera3D)).id();
    
    // Verify the 2D camera query works
    let mut camera_query = app.world.query_filtered::<(&Camera, &GlobalTransform), (With<Camera2D>, With<Camera>)>();
    let cameras: Vec<_> = camera_query.iter(&app.world).collect();
    
    assert_eq!(cameras.len(), 1, "Should find exactly one 2D camera");
}

#[test]
fn test_initial_visibility_setup() {
    let mut app = App::new();
    app.add_plugins(MinimalPlugins);
    app.init_resource::<RenderConfig>();
    
    // Test with 3D mode (default)
    app.world.resource_mut::<RenderConfig>().use_3d = true;
    
    // Spawn test entities with proper bundles
    let board_2d = app.world.spawn((
        crate::components::Board,
        SpatialBundle::default(),
    )).id();
    let board_3d = app.world.spawn((
        crate::systems::board_3d::BoardTile3D {
            coordinates: (0, 0),
            height: 0,
        },
        SpatialBundle::default(),
    )).id();
    
    let camera_2d = app.world.spawn((Camera2dBundle::default(), Camera2D)).id();
    let camera_3d = app.world.spawn((Camera3dBundle::default(), Camera3D)).id();
    
    // Add and run the initial visibility setup
    app.add_systems(Update, setup_initial_visibility);
    app.update();
    
    // Verify initial state is correct for 3D mode
    assert_eq!(
        app.world.entity(board_2d).get::<Visibility>().unwrap(),
        &Visibility::Hidden,
        "2D board should be hidden initially in 3D mode"
    );
    assert_eq!(
        app.world.entity(board_3d).get::<Visibility>().unwrap(),
        &Visibility::Visible,
        "3D board should be visible initially in 3D mode"
    );
    
    let camera_2d_active = app.world.entity(camera_2d).get::<Camera>().unwrap().is_active;
    let camera_3d_active = app.world.entity(camera_3d).get::<Camera>().unwrap().is_active;
    
    assert!(!camera_2d_active, "2D camera should be inactive initially in 3D mode");
    assert!(camera_3d_active, "3D camera should be active initially in 3D mode");
}
