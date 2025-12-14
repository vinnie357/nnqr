use bevy::prelude::*;
use crate::{
    components::*,
    resources::*,
    systems::pieces_3d::{GamePiece3D, PieceOutline, update_selection_highlighting},
};

#[cfg(test)]
mod tests {
    use super::*;

    fn setup_test_app() -> App {
        let mut app = App::new();
        app.add_plugins(MinimalPlugins)
            .init_resource::<GameState>()
            .add_systems(Update, update_selection_highlighting);
        app
    }

    #[test]
    fn test_piece_outline_disabled_after_deselection() {
        let mut app = setup_test_app();
        
        // Set up game state
        let mut game_state = app.world.resource_mut::<GameState>();
        game_state.turn_phase = TurnPhase::PieceMovement;
        game_state.current_player = Player::Player1;

        // Spawn a 3D piece with outline
        let piece_entity = app.world.spawn((
            GamePiece3D {
                board_position: (0, 0),
                player: Player::Player1,
            },
            PieceOutline {
                active: false,
                pulse_timer: 0.0,
            },
            Selected,
        )).id();

        // Run one update to enable outline for selected piece
        app.update();

        // Check that outline was enabled
        let piece_outline = app.world.get::<PieceOutline>(piece_entity).unwrap();
        assert!(piece_outline.active, "Outline should be enabled for selected piece");

        // Deselect the piece (simulate drag end)
        app.world.entity_mut(piece_entity).remove::<Selected>();

        // Run update again to disable outline
        app.update();

        // Check that outline was disabled
        let piece_outline = app.world.get::<PieceOutline>(piece_entity).unwrap();
        assert!(!piece_outline.active, "Outline should be disabled after deselection");
    }

    #[test]
    fn test_outline_cleanup_on_first_move() {
        let mut app = setup_test_app();
        
        // Set up game state
        let mut game_state = app.world.resource_mut::<GameState>();
        game_state.turn_phase = TurnPhase::PieceMovement;
        game_state.current_player = Player::Player1;

        // Spawn a 3D piece with outline (simulating first selection)
        let piece_entity = app.world.spawn((
            GamePiece3D {
                board_position: (0, 0),
                player: Player::Player1,
            },
            PieceOutline {
                active: true, // Outline is initially active from first selection
                pulse_timer: 0.0,
            },
            Selected,
        )).id();

        // Verify outline is active initially
        let piece_outline = app.world.get::<PieceOutline>(piece_entity).unwrap();
        assert!(piece_outline.active, "Outline should be active initially");

        // Simulate first move completion - remove Selected component
        app.world.entity_mut(piece_entity).remove::<Selected>();

        // Run update to process deselection
        app.update();

        // Verify outline is now disabled (this should fix the visual artifact)
        let piece_outline = app.world.get::<PieceOutline>(piece_entity).unwrap();
        assert!(!piece_outline.active, "Outline should be disabled after first move to prevent artifacts");
    }

    #[test]
    fn test_multiple_pieces_outline_cleanup() {
        let mut app = setup_test_app();
        
        // Set up game state
        let mut game_state = app.world.resource_mut::<GameState>();
        game_state.turn_phase = TurnPhase::PieceMovement;
        game_state.current_player = Player::Player1;

        // Spawn multiple 3D pieces
        let piece1_entity = app.world.spawn((
            GamePiece3D {
                board_position: (0, 0),
                player: Player::Player1,
            },
            PieceOutline {
                active: false,
                pulse_timer: 0.0,
            },
            Selected,
        )).id();

        let piece2_entity = app.world.spawn((
            GamePiece3D {
                board_position: (1, 0),
                player: Player::Player1,
            },
            PieceOutline {
                active: false,
                pulse_timer: 0.0,
            },
        )).id();

        // Run update to enable outlines for selected pieces
        app.update();

        // Check that only selected piece has outline enabled
        let piece1_outline = app.world.get::<PieceOutline>(piece1_entity).unwrap();
        let piece2_outline = app.world.get::<PieceOutline>(piece2_entity).unwrap();
        assert!(piece1_outline.active, "Selected piece should have outline enabled");
        assert!(!piece2_outline.active, "Unselected piece should not have outline enabled");

        // Deselect piece1
        app.world.entity_mut(piece1_entity).remove::<Selected>();

        // Run update again
        app.update();

        // Check that both pieces have outlines disabled
        let piece1_outline = app.world.get::<PieceOutline>(piece1_entity).unwrap();
        let piece2_outline = app.world.get::<PieceOutline>(piece2_entity).unwrap();
        assert!(!piece1_outline.active, "Deselected piece should have outline disabled");
        assert!(!piece2_outline.active, "Unselected piece should remain without outline");
    }
}