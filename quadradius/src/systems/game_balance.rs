use crate::components::*;
use bevy::prelude::*;
use std::collections::HashMap;

// Game balance tracking and analysis system
#[derive(Resource, Default)]
pub struct GameBalanceData {
    pub power_usage_count: HashMap<PowerType, u32>,
    pub power_success_rate: HashMap<PowerType, (u32, u32)>, // (successes, total_uses)
    pub game_length_samples: Vec<f32>,
    pub turn_count_samples: Vec<u32>,
    pub player_win_counts: [u32; 2], // [player1_wins, player2_wins]
    pub power_spawn_locations: Vec<(u8, u8)>,
    pub average_powers_per_player: f32,
    pub longest_game_turns: u32,
    pub shortest_game_turns: u32,
}

#[derive(Component)]
pub struct GameBalanceTracker;

#[derive(Event)]
pub struct PowerUsageEvent {
    pub player: Player,
    pub power_type: PowerType,
    pub was_successful: bool,
    pub turn_number: u32,
}

#[derive(Event)]
pub struct GameEndEvent {
    pub winner: Option<Player>,
    pub game_duration: f32,
    pub turn_count: u32,
    pub final_power_counts: [u32; 2],
}

// Track power usage for balance analysis
pub fn track_power_usage(
    mut balance_data: ResMut<GameBalanceData>,
    mut power_events: EventReader<PowerUsageEvent>,
) {
    for event in power_events.read() {
        // Update usage count
        *balance_data
            .power_usage_count
            .entry(event.power_type)
            .or_insert(0) += 1;

        // Update success rate
        let entry = balance_data
            .power_success_rate
            .entry(event.power_type)
            .or_insert((0, 0));
        if event.was_successful {
            entry.0 += 1;
        }
        entry.1 += 1;

        println!(
            "Power used: {:?} by {:?} - Success: {} (Turn {})",
            event.power_type, event.player, event.was_successful, event.turn_number
        );
    }
}

// Track game completion for balance analysis
pub fn track_game_completion(
    mut balance_data: ResMut<GameBalanceData>,
    mut game_events: EventReader<GameEndEvent>,
) {
    for event in game_events.read() {
        balance_data.game_length_samples.push(event.game_duration);
        balance_data.turn_count_samples.push(event.turn_count);

        // Track win counts
        match event.winner {
            Some(Player::Player1) => balance_data.player_win_counts[0] += 1,
            Some(Player::Player2) => balance_data.player_win_counts[1] += 1,
            None => {} // Draw
        }

        // Update game length records
        if balance_data.longest_game_turns < event.turn_count {
            balance_data.longest_game_turns = event.turn_count;
        }
        if balance_data.shortest_game_turns == 0
            || balance_data.shortest_game_turns > event.turn_count
        {
            balance_data.shortest_game_turns = event.turn_count;
        }

        println!(
            "Game completed - Winner: {:?}, Duration: {:.1}s, Turns: {}",
            event.winner, event.game_duration, event.turn_count
        );
    }
}

// Generate balance report
pub fn generate_balance_report(balance_data: Res<GameBalanceData>, keyboard: Res<Input<KeyCode>>) {
    if keyboard.just_pressed(KeyCode::F9) {
        println!("\n=== GAME BALANCE REPORT ===");

        // Power usage statistics
        println!("\nPOWER USAGE FREQUENCY:");
        let mut usage_vec: Vec<_> = balance_data.power_usage_count.iter().collect();
        usage_vec.sort_by(|a, b| b.1.cmp(a.1));

        for (power, count) in usage_vec.iter().take(10) {
            let success_rate =
                if let Some((successes, total)) = balance_data.power_success_rate.get(power) {
                    if *total > 0 {
                        (*successes as f32 / *total as f32) * 100.0
                    } else {
                        0.0
                    }
                } else {
                    0.0
                };
            println!(
                "  {:?}: {} uses ({:.1}% success rate)",
                power, count, success_rate
            );
        }

        // Game length statistics
        if !balance_data.game_length_samples.is_empty() {
            let avg_duration = balance_data.game_length_samples.iter().sum::<f32>()
                / balance_data.game_length_samples.len() as f32;
            let avg_turns = balance_data.turn_count_samples.iter().sum::<u32>() as f32
                / balance_data.turn_count_samples.len() as f32;

            println!("\nGAME LENGTH STATISTICS:");
            println!("  Average game duration: {:.1} seconds", avg_duration);
            println!("  Average turns per game: {:.1}", avg_turns);
            println!("  Longest game: {} turns", balance_data.longest_game_turns);
            println!(
                "  Shortest game: {} turns",
                balance_data.shortest_game_turns
            );
        }

        // Win rate balance
        let total_games = balance_data.player_win_counts[0] + balance_data.player_win_counts[1];
        if total_games > 0 {
            let p1_winrate =
                (balance_data.player_win_counts[0] as f32 / total_games as f32) * 100.0;
            let p2_winrate =
                (balance_data.player_win_counts[1] as f32 / total_games as f32) * 100.0;

            println!("\nWIN RATE BALANCE:");
            println!(
                "  Player 1: {}% ({}/{})",
                p1_winrate, balance_data.player_win_counts[0], total_games
            );
            println!(
                "  Player 2: {}% ({}/{})",
                p2_winrate, balance_data.player_win_counts[1], total_games
            );

            let balance_rating = if (p1_winrate - 50.0).abs() < 5.0 {
                "EXCELLENT"
            } else if (p1_winrate - 50.0).abs() < 10.0 {
                "GOOD"
            } else if (p1_winrate - 50.0).abs() < 20.0 {
                "NEEDS ATTENTION"
            } else {
                "SEVERELY IMBALANCED"
            };
            println!("  Balance Rating: {}", balance_rating);
        }

        println!("\n=== END BALANCE REPORT ===\n");
        println!("Press F9 to generate another report");
    }
}

// Automated balance testing system
#[derive(Resource)]
pub struct AutoBalanceTest {
    pub enabled: bool,
    pub test_iterations: u32,
    pub current_iteration: u32,
    pub test_results: Vec<BalanceTestResult>,
}

impl Default for AutoBalanceTest {
    fn default() -> Self {
        Self {
            enabled: false,
            test_iterations: 100,
            current_iteration: 0,
            test_results: Vec::new(),
        }
    }
}

#[derive(Clone)]
pub struct BalanceTestResult {
    pub game_duration: f32,
    pub turn_count: u32,
    pub winner: Option<Player>,
    pub powers_used: HashMap<PowerType, u32>,
    pub final_piece_counts: [u32; 2],
}

// Power effectiveness analyzer
pub fn analyze_power_effectiveness(
    balance_data: Res<GameBalanceData>,
    keyboard: Res<Input<KeyCode>>,
) {
    if keyboard.just_pressed(KeyCode::F10) {
        println!("\n=== POWER EFFECTIVENESS ANALYSIS ===");

        // Calculate power effectiveness scores
        let mut effectiveness_scores: Vec<(PowerType, f32)> = Vec::new();

        for (power, (successes, total)) in &balance_data.power_success_rate {
            if *total > 0 {
                let success_rate = *successes as f32 / *total as f32;
                let usage_frequency =
                    *balance_data.power_usage_count.get(power).unwrap_or(&0) as f32;

                // Effectiveness score = success_rate * log(usage_frequency + 1)
                // This rewards both high success rate and reasonable usage
                let effectiveness = success_rate * (usage_frequency + 1.0).ln();
                effectiveness_scores.push((*power, effectiveness));
            }
        }

        effectiveness_scores.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap());

        println!("\nPOWER EFFECTIVENESS RANKING:");
        for (i, (power, score)) in effectiveness_scores.iter().enumerate() {
            let usage = balance_data.power_usage_count.get(power).unwrap_or(&0);
            let (successes, total) = balance_data
                .power_success_rate
                .get(power)
                .unwrap_or(&(0, 0));
            let success_rate = if *total > 0 {
                *successes as f32 / *total as f32 * 100.0
            } else {
                0.0
            };

            println!(
                "  {}. {:?}: {:.2} effectiveness ({} uses, {:.1}% success)",
                i + 1,
                power,
                score,
                usage,
                success_rate
            );
        }

        // Identify overpowered and underpowered abilities
        if let Some((most_effective, _)) = effectiveness_scores.first() {
            println!("\nMOST EFFECTIVE POWER: {:?}", most_effective);
        }
        if let Some((least_effective, _)) = effectiveness_scores.last() {
            println!("LEAST EFFECTIVE POWER: {:?}", least_effective);
        }

        println!("\n=== END POWER ANALYSIS ===\n");
    }
}

// Power spawn balance analyzer
pub fn analyze_power_spawn_balance(
    mut balance_data: ResMut<GameBalanceData>,
    orbs: Query<&PowerOrb, Added<PowerOrb>>,
    keyboard: Res<Input<KeyCode>>,
) {
    // Track new power orb spawns
    for orb in orbs.iter() {
        balance_data.power_spawn_locations.push(orb.board_position);
    }

    // Generate spawn analysis report
    if keyboard.just_pressed(KeyCode::F11) {
        println!("\n=== POWER SPAWN ANALYSIS ===");

        if !balance_data.power_spawn_locations.is_empty() {
            // Calculate spawn distribution
            let mut spawn_counts = HashMap::new();
            for (x, y) in &balance_data.power_spawn_locations {
                *spawn_counts.entry((*x, *y)).or_insert(0) += 1;
            }

            // Find hotspots and cold spots
            let total_spawns = balance_data.power_spawn_locations.len();
            let expected_per_tile = total_spawns as f32 / 64.0; // 8x8 board

            println!("Total power orb spawns tracked: {}", total_spawns);
            println!("Expected spawns per tile: {:.2}", expected_per_tile);

            // Find most and least common spawn locations
            let mut sorted_spawns: Vec<_> = spawn_counts.iter().collect();
            sorted_spawns.sort_by(|a, b| b.1.cmp(a.1));

            println!("\nTOP 5 SPAWN HOTSPOTS:");
            for (i, ((x, y), count)) in sorted_spawns.iter().take(5).enumerate() {
                let percentage = **count as f32 / total_spawns as f32 * 100.0;
                println!(
                    "  {}. ({}, {}): {} spawns ({:.1}%)",
                    i + 1,
                    x,
                    y,
                    count,
                    percentage
                );
            }

            // Check for spawn balance issues
            if let Some((_, max_spawns)) = sorted_spawns.first() {
                if let Some((_, min_spawns)) = sorted_spawns.last() {
                    let imbalance_ratio = **max_spawns as f32 / (*min_spawns + 1) as f32;

                    println!("\nSPAWN BALANCE:");
                    if imbalance_ratio > 3.0 {
                        println!(
                            "  WARNING: Significant spawn imbalance detected ({}x difference)",
                            imbalance_ratio
                        );
                    } else if imbalance_ratio > 2.0 {
                        println!(
                            "  CAUTION: Moderate spawn imbalance ({}x difference)",
                            imbalance_ratio
                        );
                    } else {
                        println!("  GOOD: Spawn distribution is reasonably balanced");
                    }
                }
            }
        } else {
            println!("No power spawn data collected yet.");
        }

        println!("\n=== END SPAWN ANALYSIS ===\n");
    }
}

// Game balance recommendations
pub fn generate_balance_recommendations(
    balance_data: Res<GameBalanceData>,
    keyboard: Res<Input<KeyCode>>,
) {
    if keyboard.just_pressed(KeyCode::F12) {
        println!("\n=== BALANCE RECOMMENDATIONS ===");

        let mut recommendations = Vec::<String>::new();

        // Check win rate balance
        let total_games = balance_data.player_win_counts[0] + balance_data.player_win_counts[1];
        if total_games > 10 {
            let p1_winrate = balance_data.player_win_counts[0] as f32 / total_games as f32;
            if (p1_winrate - 0.5).abs() > 0.15 {
                recommendations.push(
                    "🔧 CRITICAL: Adjust starting positions or first-turn advantage".to_string(),
                );
            } else if (p1_winrate - 0.5).abs() > 0.1 {
                recommendations
                    .push("⚠️  Consider minor balance adjustments for player parity".to_string());
            }
        }

        // Check power usage distribution
        if !balance_data.power_usage_count.is_empty() {
            let max_usage = balance_data.power_usage_count.values().max().unwrap_or(&0);
            let min_usage = balance_data.power_usage_count.values().min().unwrap_or(&0);

            if max_usage > &0 && *max_usage / (min_usage + 1) > 5 {
                recommendations.push(
                    "🔧 Some powers are heavily overused while others are ignored".to_string(),
                );
                recommendations
                    .push("   → Consider buffing weak powers or nerfing dominant ones".to_string());
            }
        }

        // Check power success rates
        for (power, (successes, total)) in &balance_data.power_success_rate {
            if *total > 5 {
                let success_rate = *successes as f32 / *total as f32;
                if success_rate < 0.3 {
                    recommendations.push(format!(
                        "🔧 {:?} has low success rate ({:.1}%) - consider buffing",
                        power,
                        success_rate * 100.0
                    ));
                } else if success_rate > 0.9 {
                    recommendations.push(format!(
                        "⚠️  {:?} has very high success rate ({:.1}%) - might be overpowered",
                        power,
                        success_rate * 100.0
                    ));
                }
            }
        }

        // Check game length
        if !balance_data.turn_count_samples.is_empty() {
            let avg_turns = balance_data.turn_count_samples.iter().sum::<u32>() as f32
                / balance_data.turn_count_samples.len() as f32;
            if avg_turns < 10.0 {
                recommendations.push(
                    "⚠️  Games are very short - consider slowing down win conditions".to_string(),
                );
            } else if avg_turns > 50.0 {
                recommendations.push(
                    "⚠️  Games are very long - consider accelerating win conditions".to_string(),
                );
            }
        }

        if recommendations.is_empty() {
            println!("✅ Game appears to be well balanced!");
            println!("   Continue monitoring with more data for validation.");
        } else {
            println!("RECOMMENDATIONS:");
            for rec in recommendations {
                println!("  {}", rec);
            }
        }

        println!("\n=== END RECOMMENDATIONS ===\n");
        println!("Press F9: Balance Report | F10: Power Analysis | F11: Spawn Analysis | F12: Recommendations");
    }
}
