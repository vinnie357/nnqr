use crate::{
    components::*,
    resources::*,
    systems::{
        enhanced_move_indicators_3d::*,
        pieces_3d::GamePiece3D,
    },
};
use bevy::prelude::*;

#[cfg(test)]
mod tests {
    use super::*;

    fn setup_test_app() -> App {
        let mut app = App::new();
        app.add_plugins(MinimalPlugins)
            .init_resource::<GameState>()
            .add_systems(Update, (
                show_valid_moves_for_powers_3d,
                cleanup_orphaned_indicators_3d,
            ));
        app
    }

    #[test]
    fn test_indicators_cleanup_after_deselection() {
        let mut app = setup_test_app();
        
        // Set up game state for piece movement
        let mut game_state = app.world.resource_mut::<GameState>();
        game_state.turn_phase = TurnPhase::PieceMovement;
        game_state.current_player = Player::Player1;

        // Spawn a board tile
        let tile_entity = app.world.spawn(BoardTile {
            coordinates: (0, 0),
            height: 0,
        }).id();

        // Spawn a selected piece
        let piece_entity = app.world.spawn((
            GamePiece3D {
                board_position: (0, 0),
                player: Player::Player1,
            },
            Selected,
        )).id();

        // Run one update to spawn indicators
        app.update();

        // Check that indicators were spawned
        let mut indicator_query = app.world.query::<Entity, With<ValidMoveIndicator3D>>();
        let indicators_before = indicator_query.iter(&app.world).count();
        println!("Indicators spawned: {}", indicators_before);

        // Deselect the piece
        app.world.entity_mut(piece_entity).remove::<Selected>();

        // Run update again to clean up indicators
        app.update();

        // Check that indicators were cleaned up
        let indicators_after = indicator_query.iter(&app.world).count();
        println!("Indicators after cleanup: {}", indicators_after);

        assert_eq!(indicators_after, 0, "Indicators should be cleaned up after deselection");
    }

    #[test]
    fn test_indicators_cleanup_when_turn_phase_changes() {
        let mut app = setup_test_app();
        
        // Set up game state for piece movement
        let mut game_state = app.world.resource_mut::<GameState>();
        game_state.turn_phase = TurnPhase::PieceMovement;
        game_state.current_player = Player::Player1;

        // Spawn a board tile
        let tile_entity = app.world.spawn(BoardTile {
            coordinates: (0, 0),
            height: 0,
        }).id();

        // Spawn a selected piece
        let piece_entity = app.world.spawn((
            GamePiece3D {
                board_position: (0, 0),
                player: Player::Player1,
            },
            Selected,
        )).id();

        // Run one update to spawn indicators
        app.update();

        // Check that indicators were spawned
        let mut indicator_query = app.world.query::<Entity, With<ValidMoveIndicator3D>>();
        let indicators_before = indicator_query.iter(&app.world).count();
        println!("Indicators spawned: {}", indicators_before);

        // Change turn phase to PowerSpawning
        let mut game_state = app.world.resource_mut::<GameState>();
        game_state.turn_phase = TurnPhase::PowerSpawning;

        // Run update again to clean up indicators
        app.update();

        // Check that indicators were cleaned up
        let indicators_after = indicator_query.iter(&app.world).count();
        println!("Indicators after phase change: {}", indicators_after);

        assert_eq!(indicators_after, 0, "Indicators should be cleaned up when turn phase changes");
    }

    #[test]
    fn test_indicators_not_spawned_outside_movement_phase() {
        let mut app = setup_test_app();
        
        // Set up game state for power activation (NOT piece movement)
        let mut game_state = app.world.resource_mut::<GameState>();
        game_state.turn_phase = TurnPhase::PowerActivation;
        game_state.current_player = Player::Player1;

        // Spawn a board tile
        let tile_entity = app.world.spawn(BoardTile {
            coordinates: (0, 0),
            height: 0,
        }).id();

        // Spawn a selected piece
        let piece_entity = app.world.spawn((
            GamePiece3D {
                board_position: (0, 0),
                player: Player::Player1,
            },
            Selected,
        )).id();

        // Run one update
        app.update();

        // Check that no indicators were spawned
        let mut indicator_query = app.world.query::<Entity, With<ValidMoveIndicator3D>>();
        let indicators_count = indicator_query.iter(&app.world).count();
        println!("Indicators in PowerActivation phase: {}", indicators_count);

        assert_eq!(indicators_count, 0, "No indicators should be spawned outside PieceMovement phase");
    }

    #[test]
    fn test_indicators_persist_while_piece_selected() {
        let mut app = setup_test_app();
        
        // Set up game state for piece movement
        let mut game_state = app.world.resource_mut::<GameState>();
        game_state.turn_phase = TurnPhase::PieceMovement;
        game_state.current_player = Player::Player1;

        // Spawn a board tile
        let tile_entity = app.world.spawn(BoardTile {
            coordinates: (0, 0),
            height: 0,
        }).id();

        // Spawn a selected piece
        let piece_entity = app.world.spawn((
            GamePiece3D {
                board_position: (0, 0),
                player: Player::Player1,
            },
            Selected,
        )).id();

        // Run multiple updates
        app.update();
        app.update();
        app.update();

        // Check that indicators persist
        let mut indicator_query = app.world.query::<Entity, With<ValidMoveIndicator3D>>();
        let indicators_count = indicator_query.iter(&app.world).count();
        println!("Indicators after multiple updates: {}", indicators_count);

        assert!(indicators_count > 0, "Indicators should persist while piece is selected");
    }
}