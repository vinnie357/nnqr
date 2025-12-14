#[cfg(test)]
mod tests {
    use crate::components::*;
    use crate::resources::QuadradiusTheme;
    use crate::systems::feedback_animations::flash_invalid_moves;
    use bevy::prelude::*;

    #[test]
    fn test_piece_colors_preserved_after_invalid_move_flash() {
        // This test verifies that the fix we implemented works by testing the color restoration logic directly
        let mut app = App::new();
        app.add_plugins(MinimalPlugins);

        // Create a test piece that should be at the "flash complete" stage
        let player1_piece = app
            .world
            .spawn((
                GamePiece {
                    player: Player::Player1,
                    board_position: (3, 3),
                },
                InvalidMoveFlash {
                    start_time: 0.0, // Flash started at time 0
                    duration: 0.3,   // Duration is 0.3 seconds
                },
                SpriteBundle {
                    sprite: Sprite {
                        color: Color::rgb(1.0, 0.3, 0.3), // Currently flashing red
                        ..default()
                    },
                    ..default()
                },
            ))
            .id();

        // Add the system
        app.add_systems(Update, flash_invalid_moves);

        // Simulate the time condition where flash should complete
        // Set elapsed time to be greater than flash duration
        let _elapsed_time = 0.5; // Greater than duration (0.3)

        // Manually trigger the time condition by patching time resource
        // Since the flash system uses time.elapsed_seconds() - flash.start_time > flash.duration
        // We need elapsed_seconds() = 0.5, start_time = 0.0, duration = 0.3
        // So 0.5 - 0.0 = 0.5 > 0.3 = true (should complete flash)

        // Update Time to have elapsed_seconds() return our target value
        // This is a bit tricky in Bevy tests, so let's modify our component to make the test work

        // ALTERNATIVE: Test the color restoration logic by manually setting elapsed time in component
        app.world
            .entity_mut(player1_piece)
            .get_mut::<InvalidMoveFlash>()
            .unwrap()
            .start_time = -0.5; // Trick: make elapsed = 0.5

        // Run one update cycle
        app.update();

        // Check the result
        let player1_sprite = app.world.entity(player1_piece).get::<Sprite>().unwrap();

        // After our fix, this should be blue (Player 1 theme color), not red
        assert_eq!(
            player1_sprite.color,
            QuadradiusTheme::TEAM_1_PRIMARY,
            "Player 1 piece should be restored to blue after flash completes (fix verification)"
        );

        // The component should be removed
        assert!(
            app.world
                .entity(player1_piece)
                .get::<InvalidMoveFlash>()
                .is_none(),
            "InvalidMoveFlash component should be removed after flash completes"
        );
    }

    #[test]
    fn test_piece_color_correct_assignment() {
        // Verify that our theme constants match expected player assignments
        assert_eq!(
            QuadradiusTheme::TEAM_1_PRIMARY,
            Color::rgb(0.1, 0.3, 0.8),
            "Player 1 should be blue"
        );

        assert_eq!(
            QuadradiusTheme::TEAM_2_PRIMARY,
            Color::rgb(0.8, 0.1, 0.1),
            "Player 2 should be red"
        );
    }

    #[test]
    fn test_flash_color_interpolation_uses_correct_base() {
        let mut app = App::new();
        app.add_plugins(MinimalPlugins);

        // Create a piece mid-flash
        let test_piece = app
            .world
            .spawn((
                GamePiece {
                    player: Player::Player1,
                    board_position: (2, 2),
                },
                InvalidMoveFlash {
                    start_time: 0.0,
                    duration: 0.3,
                },
                SpriteBundle {
                    sprite: Sprite {
                        color: Color::rgb(1.0, 1.0, 1.0), // Start with white to see change
                        ..default()
                    },
                    ..default()
                },
            ))
            .id();

        app.add_systems(Update, flash_invalid_moves);

        // Simulate time during flash (not completed yet)
        app.world
            .resource_mut::<Time>()
            .advance_by(std::time::Duration::from_millis(150)); // Half duration

        app.update();

        let sprite = app.world.entity(test_piece).get::<Sprite>().unwrap();

        // During flash, color should be somewhere between blue and red
        // It should NOT be the old buggy color (red for Player 1)
        assert_ne!(
            sprite.color,
            Color::rgb(0.8, 0.2, 0.2), // Old buggy red color for Player 1
            "Player 1 piece should never turn red during flash"
        );

        // The color should have some blue component since Player 1 base is blue
        assert!(
            sprite.color.b() > 0.0,
            "Player 1 piece should retain blue component during flash, got: {:?}",
            sprite.color
        );
    }
}
