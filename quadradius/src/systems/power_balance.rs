use crate::resources::game_state::TurnCounter;
use crate::{components::*, resources::*};
use bevy::prelude::*;
use rand::Rng;
use std::collections::HashMap;

// Dynamic power balancing system
#[derive(Resource)]
pub struct PowerBalanceConfig {
    pub power_spawn_rates: HashMap<PowerType, f32>,
    pub power_cooldowns: HashMap<PowerType, u32>,
    pub power_usage_limits: HashMap<PowerType, u32>,
    pub power_strength_modifiers: HashMap<PowerType, f32>,
    pub global_spawn_rate: f32,
    pub balance_mode: BalanceMode,
}

impl Default for PowerBalanceConfig {
    fn default() -> Self {
        let mut config = Self {
            power_spawn_rates: HashMap::new(),
            power_cooldowns: HashMap::new(),
            power_usage_limits: HashMap::new(),
            power_strength_modifiers: HashMap::new(),
            global_spawn_rate: 0.5, // 50% base spawn rate
            balance_mode: BalanceMode::Dynamic,
        };

        // Initialize default spawn rates for all powers
        config.init_default_balance();
        config
    }
}

impl PowerBalanceConfig {
    fn init_default_balance(&mut self) {
        // Movement powers - common but not overpowered
        self.power_spawn_rates.insert(PowerType::MoveDiagonal, 0.8);
        self.power_spawn_rates.insert(PowerType::Jump, 0.7);
        self.power_spawn_rates.insert(PowerType::MoveTwo, 0.6);
        self.power_spawn_rates.insert(PowerType::Knight, 0.5);
        self.power_spawn_rates.insert(PowerType::Teleport, 0.4);

        // Terrain powers - moderate rarity
        self.power_spawn_rates.insert(PowerType::RaiseColumn, 0.6);
        self.power_spawn_rates.insert(PowerType::LowerColumn, 0.6);
        self.power_spawn_rates.insert(PowerType::DestroyColumn, 0.3);

        // Combat powers - rare but powerful
        self.power_spawn_rates.insert(PowerType::SmartBomb, 0.2);
        self.power_spawn_rates.insert(PowerType::Sniper, 0.3);
        self.power_spawn_rates.insert(PowerType::Assassin, 0.1);

        // Utility powers - moderate rarity
        self.power_spawn_rates.insert(PowerType::Multiply, 0.4);
        self.power_spawn_rates.insert(PowerType::Shield, 0.5);
        self.power_spawn_rates.insert(PowerType::Invisible, 0.4);

        // Movement manipulation - uncommon
        self.power_spawn_rates.insert(PowerType::Push, 0.5);
        self.power_spawn_rates.insert(PowerType::Pull, 0.5);
        self.power_spawn_rates.insert(PowerType::Swap, 0.4);

        // Set cooldowns (turns between uses)
        self.power_cooldowns.insert(PowerType::SmartBomb, 3);
        self.power_cooldowns.insert(PowerType::Assassin, 5);
        self.power_cooldowns.insert(PowerType::DestroyColumn, 3);
        self.power_cooldowns.insert(PowerType::Teleport, 2);

        // Set usage limits per game
        self.power_usage_limits.insert(PowerType::Assassin, 2);
        self.power_usage_limits.insert(PowerType::SmartBomb, 3);
        self.power_usage_limits.insert(PowerType::DestroyColumn, 2);
    }
}

#[derive(Debug, Clone)]
pub enum BalanceMode {
    Static,   // Fixed balance values
    Dynamic,  // Adjusts based on usage statistics
    Adaptive, // Real-time adjustment based on game state
}

#[derive(Resource, Default)]
pub struct PowerUsageTracker {
    pub usage_counts: HashMap<PowerType, u32>,
    pub success_rates: HashMap<PowerType, (u32, u32)>, // (successes, attempts)
    pub last_used: HashMap<PowerType, u32>,            // turn number
    pub game_usage_limits: HashMap<PowerType, u32>,    // current game usage
}

#[derive(Component)]
pub struct PowerCooldown {
    pub power_type: PowerType,
    pub remaining_turns: u32,
}

// Apply dynamic balance adjustments
pub fn apply_dynamic_balance(
    mut balance_config: ResMut<PowerBalanceConfig>,
    usage_tracker: Res<PowerUsageTracker>,
    keyboard: Res<Input<KeyCode>>,
) {
    if keyboard.just_pressed(KeyCode::F4) {
        println!("🔄 Applying dynamic balance adjustments...");

        match balance_config.balance_mode {
            BalanceMode::Dynamic => {
                adjust_spawn_rates_by_usage(&mut balance_config, &usage_tracker);
            }
            BalanceMode::Adaptive => {
                adjust_spawn_rates_adaptive(&mut balance_config, &usage_tracker);
            }
            BalanceMode::Static => {
                println!("   Static mode - no adjustments made");
                return;
            }
        }

        println!("✅ Balance adjustments applied");
        print_balance_changes(&balance_config);
    }
}

fn adjust_spawn_rates_by_usage(config: &mut PowerBalanceConfig, tracker: &PowerUsageTracker) {
    for (power_type, usage_count) in &tracker.usage_counts {
        let current_rate = config
            .power_spawn_rates
            .get(power_type)
            .copied()
            .unwrap_or(0.5);

        // Get success rate for this power
        let success_rate = if let Some((successes, total)) = tracker.success_rates.get(power_type) {
            if *total > 0 {
                *successes as f32 / *total as f32
            } else {
                0.5 // Default
            }
        } else {
            0.5
        };

        // Adjust spawn rate based on usage and success
        let adjustment_factor = calculate_balance_adjustment(*usage_count, success_rate);
        let new_rate = (current_rate * adjustment_factor).clamp(0.05, 1.0);

        config.power_spawn_rates.insert(*power_type, new_rate);

        println!(
            "   {:?}: {:.2} -> {:.2} (usage: {}, success: {:.1}%)",
            power_type,
            current_rate,
            new_rate,
            usage_count,
            success_rate * 100.0
        );
    }
}

fn adjust_spawn_rates_adaptive(config: &mut PowerBalanceConfig, tracker: &PowerUsageTracker) {
    // More aggressive real-time adjustments
    let total_usage: u32 = tracker.usage_counts.values().sum();

    if total_usage > 0 {
        for (power_type, usage_count) in &tracker.usage_counts {
            let usage_percentage = *usage_count as f32 / total_usage as f32;
            let current_rate = config
                .power_spawn_rates
                .get(power_type)
                .copied()
                .unwrap_or(0.5);

            // If power is overused, reduce spawn rate more aggressively
            let target_percentage = 1.0 / tracker.usage_counts.len() as f32; // Equal distribution
            let imbalance = usage_percentage / target_percentage;

            let new_rate = if imbalance > 1.5 {
                current_rate * 0.8 // Reduce spawn rate
            } else if imbalance < 0.5 {
                current_rate * 1.2 // Increase spawn rate
            } else {
                current_rate // Keep current rate
            };

            config
                .power_spawn_rates
                .insert(*power_type, new_rate.clamp(0.05, 1.0));
        }
    }
}

fn calculate_balance_adjustment(usage_count: u32, success_rate: f32) -> f32 {
    // Base adjustment on both usage frequency and success rate
    let usage_factor = if usage_count > 20 {
        0.8 // Reduce spawn rate for overused powers
    } else if usage_count < 5 {
        1.2 // Increase spawn rate for underused powers
    } else {
        1.0 // Keep current rate
    };

    let success_factor = if success_rate > 0.8 {
        0.9 // Slightly reduce spawn rate for overly successful powers
    } else if success_rate < 0.3 {
        1.1 // Slightly increase spawn rate for unsuccessful powers
    } else {
        1.0
    };

    usage_factor * success_factor
}

// Enhanced power orb spawning with balance considerations
pub fn spawn_balanced_power_orbs(
    mut commands: Commands,
    game_state: ResMut<GameState>,
    balance_config: Res<PowerBalanceConfig>,
    usage_tracker: Res<PowerUsageTracker>,
    board_tiles: Query<&BoardTile>,
    existing_orbs: Query<&PowerOrb>,
    turn_counter: Res<TurnCounter>,
) {
    // Only spawn orbs periodically and when state changes
    if !game_state.is_changed() || game_state.turn_phase != TurnPhase::PowerActivation {
        return;
    }

    // Don't spawn too many orbs at once
    let existing_orb_count = existing_orbs.iter().count();
    if existing_orb_count >= 3 {
        return;
    }

    let turn_id = format!(
        "{:?}-{:?}-{}",
        game_state.current_player, game_state.turn_phase, turn_counter.turn_number
    );

    println!(
        "Turn {} - checking balanced power orb spawn for {:?}",
        turn_counter.turn_number, game_state.current_player
    );

    // Use balanced spawn rate
    let spawn_chance = balance_config.global_spawn_rate;

    if rand::random::<f32>() < spawn_chance {
        // Select power type based on balanced spawn rates
        let power_type = select_balanced_power_type(&balance_config, &usage_tracker);

        // Find available spawn positions
        let occupied_positions: std::collections::HashSet<_> =
            existing_orbs.iter().map(|orb| orb.board_position).collect();

        let available_positions: Vec<_> = board_tiles
            .iter()
            .filter(|tile| !occupied_positions.contains(&tile.coordinates))
            .collect();

        if !available_positions.is_empty() {
            let spawn_pos =
                available_positions[rand::thread_rng().gen_range(0..available_positions.len())];

            commands.spawn((
                SpriteBundle {
                    sprite: Sprite {
                        color: power_type.color(),
                        custom_size: Some(Vec2::splat(64.0 * 0.4)), // Match ORB_SIZE from power_orbs.rs
                        ..default()
                    },
                    transform: Transform::from_translation(Vec3::new(
                        (spawn_pos.coordinates.0 as f32 - 4.0 + 0.5) * 64.0,
                        (spawn_pos.coordinates.1 as f32 - 4.0 + 0.5) * 64.0,
                        1.0,
                    )),
                    ..default()
                },
                PowerOrb {
                    power_type,
                    board_position: spawn_pos.coordinates,
                },
                crate::systems::visual_effects::PulseEffect {
                    min_scale: 0.8,
                    max_scale: 1.2,
                    speed: 2.0,
                },
            ));

            println!(
                "Balanced power orb spawned: {:?} at ({}, {}) [spawn rate: {:.1}%]",
                power_type,
                spawn_pos.coordinates.0,
                spawn_pos.coordinates.1,
                balance_config
                    .power_spawn_rates
                    .get(&power_type)
                    .unwrap_or(&0.5)
                    * 100.0
            );
        }
    }
}

fn select_balanced_power_type(
    config: &PowerBalanceConfig,
    tracker: &PowerUsageTracker,
) -> PowerType {
    // Build weighted selection based on spawn rates
    let mut weighted_powers = Vec::new();

    for (power_type, spawn_rate) in &config.power_spawn_rates {
        // Adjust spawn rate based on recent usage
        let recent_usage = tracker.usage_counts.get(power_type).unwrap_or(&0);
        let adjusted_rate = if *recent_usage > 10 {
            spawn_rate * 0.5 // Reduce chance for recently overused powers
        } else {
            *spawn_rate
        };

        let weight = (adjusted_rate * 100.0) as u32;
        for _ in 0..weight {
            weighted_powers.push(*power_type);
        }
    }

    if weighted_powers.is_empty() {
        // Fallback to basic powers
        PowerType::MoveDiagonal
    } else {
        weighted_powers[rand::thread_rng().gen_range(0..weighted_powers.len())]
    }
}

// Check power cooldowns and usage limits
pub fn enforce_power_limits(
    mut game_state: ResMut<GameState>,
    balance_config: Res<PowerBalanceConfig>,
    usage_tracker: ResMut<PowerUsageTracker>,
    turn_counter: Res<TurnCounter>,
) {
    let current_player = game_state.current_player;
    let current_powers = game_state.get_current_player_powers_mut();

    // Remove powers that are on cooldown or at usage limit
    current_powers.retain(|power| {
        // Check cooldown
        if let Some(cooldown_turns) = balance_config.power_cooldowns.get(power) {
            if let Some(last_used_turn) = usage_tracker.last_used.get(power) {
                if turn_counter.turn_number - last_used_turn < *cooldown_turns {
                    return false; // Power is on cooldown
                }
            }
        }

        // Check usage limit
        if let Some(usage_limit) = balance_config.power_usage_limits.get(power) {
            let current_usage = usage_tracker.game_usage_limits.get(power).unwrap_or(&0);
            if current_usage >= usage_limit {
                return false; // Power usage limit reached
            }
        }

        true // Power can be used
    });
}

// Track power usage for balancing
pub fn track_power_usage_for_balance(
    mut usage_tracker: ResMut<PowerUsageTracker>,
    mut power_events: EventReader<crate::systems::game_balance::PowerUsageEvent>,
    turn_counter: Res<TurnCounter>,
) {
    for event in power_events.read() {
        // Update usage count
        *usage_tracker
            .usage_counts
            .entry(event.power_type)
            .or_insert(0) += 1;

        // Update success rate
        let entry = usage_tracker
            .success_rates
            .entry(event.power_type)
            .or_insert((0, 0));
        if event.was_successful {
            entry.0 += 1;
        }
        entry.1 += 1;

        // Update last used turn
        usage_tracker
            .last_used
            .insert(event.power_type, turn_counter.turn_number);

        // Update game usage count
        *usage_tracker
            .game_usage_limits
            .entry(event.power_type)
            .or_insert(0) += 1;
    }
}

fn print_balance_changes(config: &PowerBalanceConfig) {
    println!("\n📊 CURRENT BALANCE SETTINGS:");
    println!(
        "   Global spawn rate: {:.1}%",
        config.global_spawn_rate * 100.0
    );
    println!("   Balance mode: {:?}", config.balance_mode);

    let mut sorted_rates: Vec<_> = config.power_spawn_rates.iter().collect();
    sorted_rates.sort_by(|a, b| b.1.partial_cmp(a.1).unwrap());

    println!("\n   Top spawn rates:");
    for (power, rate) in sorted_rates.iter().take(8) {
        println!("     {:?}: {:.1}%", power, *rate * 100.0);
    }
}

// Balance mode controls
pub fn balance_mode_controls(
    mut balance_config: ResMut<PowerBalanceConfig>,
    keyboard: Res<Input<KeyCode>>,
) {
    if keyboard.just_pressed(KeyCode::Key1) {
        balance_config.balance_mode = BalanceMode::Static;
        println!("🔒 Balance mode: STATIC (fixed rates)");
    }

    if keyboard.just_pressed(KeyCode::Key2) {
        balance_config.balance_mode = BalanceMode::Dynamic;
        println!("🔄 Balance mode: DYNAMIC (periodic adjustments)");
    }

    if keyboard.just_pressed(KeyCode::Key3) {
        balance_config.balance_mode = BalanceMode::Adaptive;
        println!("⚡ Balance mode: ADAPTIVE (real-time adjustments)");
    }
}
