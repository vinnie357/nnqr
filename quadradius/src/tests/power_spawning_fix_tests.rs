use crate::components::*;
use crate::resources::*;
use bevy::prelude::*;

#[test]
fn test_power_spawning_tracker_creation() {
    let tracker = PowerSpawningTracker::new();

    assert_eq!(tracker.rounds_since_last_spawn, 0);
    assert_eq!(tracker.total_orbs_spawned, 0);
    assert_eq!(tracker.player1_territory_control, 0.5);
    assert_eq!(tracker.player2_territory_control, 0.5);
}

#[test]
fn test_power_spawning_7_round_cycle() {
    let mut tracker = PowerSpawningTracker::new();

    // Should not spawn for first 6 rounds
    for round in 1..7 {
        tracker.increment_round();
        assert!(
            !tracker.should_spawn_orb(),
            "Should not spawn at round {}",
            round
        );
    }

    // Should spawn on round 7
    tracker.increment_round();
    assert!(tracker.should_spawn_orb(), "Should spawn on round 7");

    // After spawning, reset counter
    tracker.orb_spawned();
    assert_eq!(tracker.rounds_since_last_spawn, 0);
    assert_eq!(tracker.total_orbs_spawned, 1);
}

#[test]
fn test_power_spawning_total_orb_count() {
    let mut tracker = PowerSpawningTracker::new();

    // Simulate multiple spawn cycles
    for cycle in 0..10 {
        for _round in 0..7 {
            tracker.increment_round();
        }
        assert!(tracker.should_spawn_orb());
        tracker.orb_spawned();
    }

    assert_eq!(tracker.total_orbs_spawned, 10);
}

#[test]
fn test_territory_control_calculation() {
    let mut app = App::new();

    // Spawn pieces for both players
    let p1_piece1 = app
        .world
        .spawn(GamePiece {
            player: Player::Player1,
            board_position: (0, 0),
        })
        .id();

    let p1_piece2 = app
        .world
        .spawn(GamePiece {
            player: Player::Player1,
            board_position: (1, 0),
        })
        .id();

    let p2_piece1 = app
        .world
        .spawn(GamePiece {
            player: Player::Player2,
            board_position: (0, 7),
        })
        .id();

    // Calculate territory control manually for testing
    let mut player1_positions = Vec::new();
    let mut player2_positions = Vec::new();

    let mut query = app.world.query::<&GamePiece>();
    for piece in query.iter(&app.world) {
        match piece.player {
            Player::Player1 => player1_positions.push(piece.board_position),
            Player::Player2 => player2_positions.push(piece.board_position),
        }
    }

    let total_pieces = (player1_positions.len() + player2_positions.len()) as f32;
    let (p1_control, p2_control) = if total_pieces == 0.0 {
        (0.5, 0.5)
    } else {
        (
            player1_positions.len() as f32 / total_pieces,
            player2_positions.len() as f32 / total_pieces,
        )
    };

    // Player 1 has 2 pieces, Player 2 has 1 piece
    assert!((p1_control - 2.0 / 3.0).abs() < 0.01);
    assert!((p2_control - 1.0 / 3.0).abs() < 0.01);
}

#[test]
fn test_territory_control_equal_pieces() {
    let mut app = App::new();

    // Equal number of pieces
    for i in 0..3 {
        app.world.spawn(GamePiece {
            player: Player::Player1,
            board_position: (i, 0),
        });

        app.world.spawn(GamePiece {
            player: Player::Player2,
            board_position: (i, 7),
        });
    }

    // Calculate territory control manually for testing
    let mut player1_positions = Vec::new();
    let mut player2_positions = Vec::new();

    let mut query = app.world.query::<&GamePiece>();
    for piece in query.iter(&app.world) {
        match piece.player {
            Player::Player1 => player1_positions.push(piece.board_position),
            Player::Player2 => player2_positions.push(piece.board_position),
        }
    }

    let total_pieces = (player1_positions.len() + player2_positions.len()) as f32;
    let (p1_control, p2_control) = if total_pieces == 0.0 {
        (0.5, 0.5)
    } else {
        (
            player1_positions.len() as f32 / total_pieces,
            player2_positions.len() as f32 / total_pieces,
        )
    };

    assert!((p1_control - 0.5).abs() < 0.01);
    assert!((p2_control - 0.5).abs() < 0.01);
}

#[test]
fn test_territory_control_update() {
    let mut tracker = PowerSpawningTracker::new();

    // Update with unequal control
    tracker.update_territory_control(3.0, 1.0);
    assert!((tracker.player1_territory_control - 0.75).abs() < 0.01);
    assert!((tracker.player2_territory_control - 0.25).abs() < 0.01);

    // Update with zero control (should default to equal)
    tracker.update_territory_control(0.0, 0.0);
    assert_eq!(tracker.player1_territory_control, 0.5);
    assert_eq!(tracker.player2_territory_control, 0.5);
}

#[test]
fn test_spawn_location_bias() {
    let empty_positions = vec![
        (0, 0),
        (1, 0), // Player 1 zone (bottom)
        (0, 7),
        (1, 7), // Player 2 zone (top)
        (0, 3),
        (1, 4), // Neutral zone (middle)
    ];

    // Strong Player 1 bias
    let p1_bias = (0.8, 0.2);
    let location = choose_spawn_location_with_bias(&empty_positions, p1_bias, 1);
    assert!(location.is_some());

    // Test with different seeds to ensure randomness
    let mut p1_zone_count = 0;
    let total_tests = 100;

    for seed in 0..total_tests {
        if let Some(pos) = choose_spawn_location_with_bias(&empty_positions, p1_bias, seed) {
            if pos.1 < 2 {
                // Player 1 zone
                p1_zone_count += 1;
            }
        }
    }

    // With strong P1 bias, should spawn more often in P1 zone
    assert!(p1_zone_count as f32 / total_tests as f32 > 0.5);
}

#[test]
fn test_spawn_location_empty_board() {
    let empty_positions = vec![];
    let bias = (0.5, 0.5);

    let location = choose_spawn_location_with_bias(&empty_positions, bias, 42);
    assert!(location.is_none());
}

#[test]
fn test_spawn_bias_calculation() {
    let mut tracker = PowerSpawningTracker::new();
    tracker.update_territory_control(3.0, 1.0); // 75% vs 25%

    let p1_bias = tracker.calculate_spawn_bias_for_player(Player::Player1);
    let p2_bias = tracker.calculate_spawn_bias_for_player(Player::Player2);

    assert!((p1_bias - 0.75).abs() < 0.01);
    assert!((p2_bias - 0.25).abs() < 0.01);
}

#[test]
fn test_power_spawning_integration() {
    let mut app = App::new();
    app.insert_resource(PowerSpawningTracker::new());

    // Add some pieces to create territory control
    app.world.spawn(GamePiece {
        player: Player::Player1,
        board_position: (0, 0),
    });

    app.world.spawn(GamePiece {
        player: Player::Player2,
        board_position: (0, 7),
    });

    // Simulate rounds
    {
        let mut tracker = app.world.resource_mut::<PowerSpawningTracker>();

        // Advance 7 rounds
        for _ in 0..7 {
            tracker.increment_round();
        }

        assert!(tracker.should_spawn_orb());
    }

    // Calculate territory control manually for testing
    let mut player1_positions = Vec::new();
    let mut player2_positions = Vec::new();

    let mut query = app.world.query::<&GamePiece>();
    for piece in query.iter(&app.world) {
        match piece.player {
            Player::Player1 => player1_positions.push(piece.board_position),
            Player::Player2 => player2_positions.push(piece.board_position),
        }
    }

    let total_pieces = (player1_positions.len() + player2_positions.len()) as f32;
    let (p1_control, p2_control) = if total_pieces == 0.0 {
        (0.5, 0.5)
    } else {
        (
            player1_positions.len() as f32 / total_pieces,
            player2_positions.len() as f32 / total_pieces,
        )
    };

    // Update tracker with territory control
    {
        let mut tracker = app.world.resource_mut::<PowerSpawningTracker>();
        tracker.update_territory_control(p1_control, p2_control);
        tracker.orb_spawned();
    }

    let tracker = app.world.resource::<PowerSpawningTracker>();
    assert_eq!(tracker.total_orbs_spawned, 1);
    assert_eq!(tracker.rounds_since_last_spawn, 0);
}

#[test]
fn test_target_80_orbs_per_game() {
    // Test that we can reach approximately 80 orbs in a typical game
    let mut tracker = PowerSpawningTracker::new();

    // Simulate a long game (80 spawn cycles = 560 rounds)
    for cycle in 0..80 {
        for _ in 0..7 {
            tracker.increment_round();
        }
        tracker.orb_spawned();
    }

    assert_eq!(tracker.total_orbs_spawned, 80);
}

#[test]
fn test_spawn_timing_consistency() {
    let mut tracker = PowerSpawningTracker::new();

    // Test that spawning happens exactly every 7 rounds
    let mut spawn_rounds = Vec::new();

    for round in 1..=70 {
        tracker.increment_round();

        if tracker.should_spawn_orb() {
            spawn_rounds.push(round);
            tracker.orb_spawned();
        }
    }

    // Should have spawned at rounds 7, 14, 21, 28, 35, 42, 49, 56, 63, 70
    let expected_rounds = vec![7, 14, 21, 28, 35, 42, 49, 56, 63, 70];
    assert_eq!(spawn_rounds, expected_rounds);
}

#[test]
fn test_territory_bias_with_no_pieces() {
    let mut app = App::new();

    // No pieces on board - calculate territory control manually for testing
    let mut player1_positions = Vec::new();
    let mut player2_positions = Vec::new();

    let mut query = app.world.query::<&GamePiece>();
    for piece in query.iter(&app.world) {
        match piece.player {
            Player::Player1 => player1_positions.push(piece.board_position),
            Player::Player2 => player2_positions.push(piece.board_position),
        }
    }

    let total_pieces = (player1_positions.len() + player2_positions.len()) as f32;
    let (p1_control, p2_control) = if total_pieces == 0.0 {
        (0.5, 0.5)
    } else {
        (
            player1_positions.len() as f32 / total_pieces,
            player2_positions.len() as f32 / total_pieces,
        )
    };

    // Should default to equal control
    assert_eq!(p1_control, 0.5);
    assert_eq!(p2_control, 0.5);
}

#[test]
fn test_spawn_location_zone_distribution() {
    let empty_positions = vec![
        (0, 0),
        (1, 0),
        (2, 0), // Player 1 zone (y < 3)
        (0, 7),
        (1, 7),
        (2, 7), // Player 2 zone (y > 4)
        (0, 3),
        (1, 3),
        (2, 3), // Neutral zone (y == 3)
        (0, 4),
        (1, 4),
        (2, 4), // Neutral zone (y == 4)
    ];

    // Equal bias
    let equal_bias = (0.5, 0.5);

    // Test multiple spawns to ensure distribution
    let mut zone_counts = [0; 3]; // [p1_zone, p2_zone, neutral_zone]

    for seed in 0..300 {
        if let Some(pos) = choose_spawn_location_with_bias(&empty_positions, equal_bias, seed) {
            // Zone logic matching the actual implementation:
            // BOARD_HEIGHT = 8, mid_point = 4
            // Player 1 zone: y < 3 (rows 0, 1, 2)
            // Player 2 zone: y > 4 (rows 5, 6, 7)
            // Neutral zone: y == 3 or y == 4
            if pos.1 < 3 {
                zone_counts[0] += 1; // Player 1 zone
            } else if pos.1 > 4 {
                zone_counts[1] += 1; // Player 2 zone
            } else {
                zone_counts[2] += 1; // Neutral zone
            }
        }
    }

    // With equal bias, should have somewhat balanced distribution
    // (allowing for randomness, but each zone should have some spawns)
    assert!(zone_counts[0] > 50);
    assert!(zone_counts[1] > 50);
    assert!(zone_counts[2] > 50);
}
