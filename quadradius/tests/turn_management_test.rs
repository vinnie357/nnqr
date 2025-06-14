use bevy::prelude::*;
use quadradius::components::{GamePiece, Player, Selected};
use quadradius::systems::GamePiece3D;
use quadradius::systems::drag_drop_3d::Dragging3D;
use quadradius::resources::{GameState, TurnPhase};

#[test]
fn test_clicking_piece_without_moving_does_not_end_turn() {
    let mut app = App::new();
    
    // Add minimal plugins needed for testing
    app.add_plugins(MinimalPlugins);
    
    // Add game resources
    app.insert_resource(GameState {
        current_player: Player::Player1,
        turn_phase: TurnPhase::PieceMovement,
        ..default()
    });
    
    // Add test systems
    app.add_systems(Update, (
        quadradius::systems::drag_drop::handle_drag_start,
        quadradius::systems::drag_drop::handle_drag_update,
        quadradius::systems::drag_drop::handle_drag_end,
    ).chain());
    
    // Spawn a test piece at position (0, 0)
    let piece_entity = app.world.spawn((
        GamePiece {
            player: Player::Player1,
            board_position: (0, 0),
        },
        Transform::from_xyz(0.0, 0.0, 0.0),
        GlobalTransform::default(),
    )).id();
    
    // Simulate clicking on the piece
    app.world.entity_mut(piece_entity).insert(Selected);
    app.world.entity_mut(piece_entity).insert(quadradius::components::piece::Dragging {
        offset: Vec2::ZERO,
        original_position: (0, 0),
    });
    
    // Update the app
    app.update();
    
    // Simulate releasing at the same position (no movement)
    app.world.entity_mut(piece_entity).remove::<quadradius::components::piece::Dragging>();
    app.insert_resource(bevy::input::Input::<MouseButton>::default());
    
    // Update again to process the release
    app.update();
    
    // Check that the turn phase hasn't changed
    let game_state = app.world.resource::<GameState>();
    assert_eq!(game_state.turn_phase, TurnPhase::PieceMovement, 
        "Turn phase should still be PieceMovement after clicking without moving");
    assert_eq!(game_state.current_player, Player::Player1, 
        "Current player should not change when piece is not moved");
}

#[test]
fn test_moving_piece_to_new_square_ends_turn() {
    let mut app = App::new();
    
    // Add minimal plugins needed for testing
    app.add_plugins(MinimalPlugins);
    
    // Add game resources
    app.insert_resource(GameState {
        current_player: Player::Player1,
        turn_phase: TurnPhase::PieceMovement,
        ..default()
    });
    
    // Add test systems
    app.add_systems(Update, (
        quadradius::systems::drag_drop::handle_drag_start,
        quadradius::systems::drag_drop::handle_drag_update,
        quadradius::systems::drag_drop::handle_drag_end,
    ).chain());
    
    // Spawn a test piece at position (0, 0)
    let piece_entity = app.world.spawn((
        GamePiece {
            player: Player::Player1,
            board_position: (0, 0),
        },
        Transform::from_xyz(0.0, 0.0, 0.0),
        GlobalTransform::default(),
    )).id();
    
    // Simulate dragging the piece
    app.world.entity_mut(piece_entity).insert(Selected);
    app.world.entity_mut(piece_entity).insert(quadradius::components::piece::Dragging {
        offset: Vec2::ZERO,
        original_position: (0, 0),
    });
    
    // Update the app
    app.update();
    
    // Move the piece to a new position
    app.world.entity_mut(piece_entity).insert(GamePiece {
        player: Player::Player1,
        board_position: (1, 0), // Moved to new position
    });
    
    // Simulate releasing at the new position
    app.world.entity_mut(piece_entity).remove::<quadradius::components::piece::Dragging>();
    
    // Update again to process the release
    app.update();
    
    // Check that the turn phase has changed to PowerSpawning
    let game_state = app.world.resource::<GameState>();
    assert_eq!(game_state.turn_phase, TurnPhase::PowerSpawning, 
        "Turn phase should change to PowerSpawning after moving piece");
}

#[test]
fn test_raycast_selection_does_not_interfere_with_drag() {
    let mut app = App::new();
    
    // Add minimal plugins needed for testing
    app.add_plugins(MinimalPlugins);
    
    // Add game resources
    app.insert_resource(GameState {
        current_player: Player::Player1,
        turn_phase: TurnPhase::PieceMovement,
        ..default()
    });
    
    // Add window plugin for proper window handling
    app.add_plugins(WindowPlugin::default());
    
    // Add camera for raycast testing
    let camera_entity = app.world.spawn((
        Camera3dBundle::default(),
        quadradius::systems::isometric_camera::IsometricCamera,
    )).id();
    
    // Add test systems including raycast selection
    app.add_systems(Update, (
        quadradius::systems::piece_visibility_fix::raycast_piece_selection,
        quadradius::systems::drag_drop_3d::handle_drag_start_3d,
        quadradius::systems::drag_drop_3d::handle_drag_update_3d,
        quadradius::systems::drag_drop_3d::handle_drag_end_3d,
    ).chain());
    
    // Spawn a test piece
    let piece_entity = app.world.spawn((
        GamePiece3D {
            player: Player::Player1,
            board_position: (0, 0),
        },
        Transform::from_xyz(0.0, 0.0, 0.0),
        GlobalTransform::default(),
    )).id();
    
    // First, simulate a piece already being dragged
    app.world.entity_mut(piece_entity).insert(Dragging3D {
        start_pos: (0, 0),
    });
    
    // Simulate mouse click (which would trigger raycast)
    let mut mouse_input = bevy::input::Input::<MouseButton>::default();
    mouse_input.press(MouseButton::Left);
    app.insert_resource(mouse_input);
    
    // Update the app
    app.update();
    
    // Check that no additional Dragging3D components were added
    let dragging_count = app.world
        .query::<&Dragging3D>()
        .iter(&app.world)
        .count();
    
    assert_eq!(dragging_count, 1, 
        "Only one piece should be dragging, raycast should not add more");
    
    // Verify turn phase hasn't changed
    let game_state = app.world.resource::<GameState>();
    assert_eq!(game_state.turn_phase, TurnPhase::PieceMovement, 
        "Turn phase should remain unchanged when raycast is prevented");
}

#[test]
fn test_raycast_only_selects_not_drags() {
    let mut app = App::new();
    
    // Add minimal plugins needed for testing
    app.add_plugins(MinimalPlugins);
    
    // Add game resources
    app.insert_resource(GameState {
        current_player: Player::Player1,
        turn_phase: TurnPhase::PieceMovement,
        ..default()
    });
    
    // Add test systems
    app.add_systems(Update, 
        quadradius::systems::piece_visibility_fix::raycast_piece_selection
    );
    
    // Spawn a test piece
    let piece_entity = app.world.spawn((
        GamePiece3D {
            player: Player::Player1,
            board_position: (0, 0),
        },
        Transform::from_xyz(0.0, 0.0, 0.0),
        GlobalTransform::default(),
    )).id();
    
    // Update the app (raycast will run but won't select without proper setup)
    app.update();
    
    // Check that no Dragging3D component was added
    let has_dragging = app.world
        .get::<Dragging3D>(piece_entity)
        .is_some();
    
    assert!(!has_dragging, 
        "Raycast selection should not add Dragging3D component");
    
    // The piece might be Selected but not Dragging
    let has_selected = app.world
        .get::<Selected>(piece_entity)
        .is_some();
    
    // This is okay - raycast can select, just not drag
    if has_selected {
        assert!(!has_dragging, 
            "Piece can be Selected but should not have Dragging3D from raycast");
    }
}