use crate::components::PowerType;
use bevy::prelude::*;
use serde::{Deserialize, Serialize};
use std::collections::{HashMap, VecDeque};

/// Resource that tracks all power interactions and history across the game
#[derive(Resource, Default)]
pub struct PowerRegistry {
    /// Active powers currently in effect on entities
    pub active_powers: HashMap<Entity, Vec<ActivePower>>,
    /// Recent power usage history for power echoing and memory
    pub recent_usage: VecDeque<PowerUsage>,
    /// Rules for how different powers interact with each other
    pub interaction_rules: HashMap<(PowerType, PowerType), InteractionResult>,
    /// Chain reaction prevention - tracks current activation depth
    pub activation_depth: u32,
    /// Maximum allowed chain depth before stopping
    pub max_chain_depth: u32,
    /// Power amplifications currently active
    pub power_amplifiers: HashMap<Entity, Vec<PowerAmplifier>>,
}

/// Represents an active power effect on an entity
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct ActivePower {
    pub power_type: PowerType,
    pub source_entity: Entity,
    pub target_entity: Entity,
    pub duration_remaining: u32,
    pub effect_strength: f32,
    pub can_be_copied: bool,
    pub can_be_stolen: bool,
    pub can_be_nullified: bool,
    pub activation_turn: u32,
}

/// Records when and how a power was used
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct PowerUsage {
    pub power_type: PowerType,
    pub user: Entity,
    pub target: Option<Entity>,
    pub target_position: Option<(u8, u8)>,
    pub turn_used: u32,
    pub success: bool,
    pub effects_triggered: Vec<PowerType>,
}

/// Component that tracks power history for individual pieces
#[derive(Component, Clone, Debug)]
pub struct PowerHistory {
    pub used_powers: VecDeque<PowerUsage>,
    pub received_powers: VecDeque<ReceivedPower>,
    pub max_history_size: usize,
}

/// Record of powers received by this entity
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct ReceivedPower {
    pub power_type: PowerType,
    pub source_entity: Entity,
    pub turn_received: u32,
    pub still_active: bool,
}

/// Describes how two powers interact when used together
#[derive(Clone, Debug, PartialEq)]
pub enum InteractionResult {
    /// No interaction, both powers work independently
    Independent,
    /// Second power cancels the first
    Cancel,
    /// Second power enhances the first
    Enhance(f32), // Enhancement multiplier
    /// Powers combine into a new effect
    Combine(PowerType),
    /// First power prevents the second
    Block,
    /// Powers create a chain reaction
    ChainReaction(Vec<PowerType>),
}

/// Power amplification effects
#[derive(Clone, Debug)]
pub struct PowerAmplifier {
    pub amplifier_type: AmplifierType,
    pub multiplier: f32,
    pub remaining_uses: Option<u32>,
    pub affects_powers: Vec<PowerType>,
}

/// Types of power amplification
#[derive(Clone, Debug, PartialEq)]
pub enum AmplifierType {
    /// Affects all powers
    Global,
    /// Affects specific power categories
    Category(crate::components::power::PowerCategory),
    /// Affects only specific powers
    Specific(Vec<PowerType>),
    /// Affects next power only
    NextPowerOnly,
}

impl PowerRegistry {
    pub fn new() -> Self {
        let mut registry = Self {
            max_chain_depth: 5, // Prevent infinite loops
            ..Default::default()
        };
        registry.initialize_interaction_rules();
        registry
    }

    /// Initialize the rules for how powers interact with each other
    fn initialize_interaction_rules(&mut self) {
        // Meta power interactions
        self.add_interaction_rule(PowerType::DoublePower, PowerType::DoublePower, InteractionResult::Block);
        self.add_interaction_rule(PowerType::NullifyPower, PowerType::Shield, InteractionResult::Cancel);
        self.add_interaction_rule(PowerType::Reflect, PowerType::Sniper, InteractionResult::Combine(PowerType::Sniper));
        self.add_interaction_rule(PowerType::Absorb, PowerType::SmartBomb, InteractionResult::Enhance(0.5));
        
        // Power enhancement interactions
        self.add_interaction_rule(PowerType::GrowQuadradius, PowerType::Sniper, InteractionResult::Enhance(3.0));
        self.add_interaction_rule(PowerType::GrowQuadradius, PowerType::SmartBomb, InteractionResult::Enhance(2.0));
        self.add_interaction_rule(PowerType::GrowQuadradius, PowerType::DestroyColumn, InteractionResult::Enhance(1.5));
        
        // Defensive vs Offensive interactions
        self.add_interaction_rule(PowerType::Shield, PowerType::Assassin, InteractionResult::Block);
        self.add_interaction_rule(PowerType::JumpProof, PowerType::Recruit, InteractionResult::Block);
        self.add_interaction_rule(PowerType::Invisible, PowerType::SmartBomb, InteractionResult::Independent);
        
        // Teaching power interactions
        self.add_interaction_rule(PowerType::TeachRow, PowerType::DoublePower, InteractionResult::ChainReaction(vec![PowerType::DoublePower]));
        self.add_interaction_rule(PowerType::TeachRadial, PowerType::GrowQuadradius, InteractionResult::ChainReaction(vec![PowerType::GrowQuadradius]));
        
        // Chain reaction examples (dangerous combinations)
        self.add_interaction_rule(PowerType::Multiply, PowerType::TeachRadial, InteractionResult::ChainReaction(vec![PowerType::Multiply, PowerType::TeachRadial]));
    }

    fn add_interaction_rule(&mut self, power1: PowerType, power2: PowerType, result: InteractionResult) {
        self.interaction_rules.insert((power1, power2), result.clone());
        // Also add the reverse interaction unless it's asymmetric
        match result {
            InteractionResult::Independent | InteractionResult::Combine(_) => {
                self.interaction_rules.insert((power2, power1), result);
            }
            _ => {} // Asymmetric interactions
        }
    }

    /// Record that a power was used
    pub fn record_power_usage(&mut self, usage: PowerUsage) {
        // Keep only the last 20 power usages for memory
        if self.recent_usage.len() >= 20 {
            self.recent_usage.pop_front();
        }
        self.recent_usage.push_back(usage);
    }

    /// Get the most recent power usage by an opponent
    pub fn get_last_opponent_power(&self, current_player_entity: Entity) -> Option<&PowerUsage> {
        self.recent_usage
            .iter()
            .rev()
            .find(|usage| usage.user != current_player_entity)
    }

    /// Check if a power interaction will cause problems
    pub fn check_interaction(&self, power1: PowerType, power2: PowerType) -> Option<&InteractionResult> {
        self.interaction_rules.get(&(power1, power2))
    }

    /// Add an active power to an entity
    pub fn add_active_power(&mut self, entity: Entity, power: ActivePower) {
        self.active_powers.entry(entity).or_default().push(power);
    }

    /// Remove expired or cancelled powers
    pub fn cleanup_expired_powers(&mut self, current_turn: u32) {
        for (_, powers) in self.active_powers.iter_mut() {
            powers.retain(|power| {
                power.activation_turn + power.duration_remaining > current_turn
            });
        }
        self.active_powers.retain(|_, powers| !powers.is_empty());
    }

    /// Get all active powers on an entity
    pub fn get_active_powers(&self, entity: Entity) -> Vec<&ActivePower> {
        self.active_powers
            .get(&entity)
            .map(|powers| powers.iter().collect())
            .unwrap_or_default()
    }

    /// Check if an entity has a specific power active
    pub fn has_active_power(&self, entity: Entity, power_type: PowerType) -> bool {
        self.active_powers
            .get(&entity)
            .map(|powers| powers.iter().any(|p| p.power_type == power_type))
            .unwrap_or(false)
    }

    /// Add a power amplifier to an entity
    pub fn add_amplifier(&mut self, entity: Entity, amplifier: PowerAmplifier) {
        self.power_amplifiers.entry(entity).or_default().push(amplifier);
    }

    /// Get the amplification multiplier for a power on an entity
    pub fn get_amplification(&self, entity: Entity, power_type: PowerType) -> f32 {
        if let Some(amplifiers) = self.power_amplifiers.get(&entity) {
            let mut total_multiplier = 1.0;
            for amplifier in amplifiers {
                if self.amplifier_affects_power(amplifier, power_type) {
                    total_multiplier *= amplifier.multiplier;
                }
            }
            total_multiplier
        } else {
            1.0
        }
    }

    fn amplifier_affects_power(&self, amplifier: &PowerAmplifier, power_type: PowerType) -> bool {
        match &amplifier.amplifier_type {
            AmplifierType::Global => true,
            AmplifierType::Category(category) => power_type.power_category() == *category,
            AmplifierType::Specific(powers) => powers.contains(&power_type),
            AmplifierType::NextPowerOnly => true, // This needs special handling
        }
    }

    /// Use up a power amplifier
    pub fn consume_amplifier_use(&mut self, entity: Entity, power_type: PowerType) {
        // First, collect which amplifiers need updating
        let to_update: Vec<usize> = if let Some(amplifiers) = self.power_amplifiers.get(&entity) {
            amplifiers
                .iter()
                .enumerate()
                .filter_map(|(i, amplifier)| {
                    if self.amplifier_affects_power(amplifier, power_type) {
                        Some(i)
                    } else {
                        None
                    }
                })
                .collect()
        } else {
            return;
        };
        
        // Now update the amplifiers
        if let Some(amplifiers) = self.power_amplifiers.get_mut(&entity) {
            for i in to_update {
                if let Some(amplifier) = amplifiers.get_mut(i) {
                    if let Some(ref mut uses) = amplifier.remaining_uses {
                        *uses = uses.saturating_sub(1);
                    }
                }
            }
            
            // Remove expired amplifiers
            amplifiers.retain(|amp| {
                amp.remaining_uses.map(|uses| uses > 0).unwrap_or(true)
            });
        }
    }

    /// Increment activation depth for chain reaction tracking
    pub fn enter_activation(&mut self) -> bool {
        if self.activation_depth >= self.max_chain_depth {
            warn!("Power activation depth limit reached, preventing infinite loop");
            return false;
        }
        self.activation_depth += 1;
        true
    }

    /// Decrement activation depth
    pub fn exit_activation(&mut self) {
        self.activation_depth = self.activation_depth.saturating_sub(1);
    }

    /// Reset activation depth (used at end of turn)
    pub fn reset_activation_depth(&mut self) {
        self.activation_depth = 0;
    }
}

impl PowerHistory {
    pub fn new() -> Self {
        Self {
            used_powers: VecDeque::new(),
            received_powers: VecDeque::new(),
            max_history_size: 10,
        }
    }

    pub fn record_power_use(&mut self, usage: PowerUsage) {
        if self.used_powers.len() >= self.max_history_size {
            self.used_powers.pop_front();
        }
        self.used_powers.push_back(usage);
    }

    pub fn record_received_power(&mut self, received: ReceivedPower) {
        if self.received_powers.len() >= self.max_history_size {
            self.received_powers.pop_front();
        }
        self.received_powers.push_back(received);
    }

    pub fn get_last_used_power(&self) -> Option<&PowerUsage> {
        self.used_powers.back()
    }

    pub fn get_powers_used_this_turn(&self, current_turn: u32) -> Vec<&PowerUsage> {
        self.used_powers
            .iter()
            .filter(|usage| usage.turn_used == current_turn)
            .collect()
    }
}

impl Default for PowerHistory {
    fn default() -> Self {
        Self::new()
    }
}

/// System to clean up expired powers and reset activation depth each turn
pub fn cleanup_power_registry_system(
    mut registry: ResMut<PowerRegistry>,
    turn_counter: Res<crate::resources::game_state::TurnCounter>,
) {
    registry.cleanup_expired_powers(turn_counter.turn_number);
    registry.reset_activation_depth();
}

/// System to initialize power registry resource
pub fn setup_power_registry(mut commands: Commands) {
    commands.insert_resource(PowerRegistry::new());
}