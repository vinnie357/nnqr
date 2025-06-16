use crate::components::PowerType;
use crate::systems::power_interactions::{PowerActivationAttempt, PowerChainReaction};
use crate::systems::power_registry::PowerRegistry;
use bevy::prelude::*;
use std::collections::HashSet;

/// Resource to track and prevent infinite chain reactions
#[derive(Resource, Default)]
pub struct ChainReactionGuard {
    /// Current activation chain depth
    pub current_depth: u32,
    /// Maximum allowed chain depth before stopping
    pub max_depth: u32,
    /// Track which powers have been activated in current chain to detect cycles
    pub activation_chain: Vec<PowerActivationRecord>,
    /// Entities currently involved in chain reactions (to prevent re-triggering)
    pub entities_in_chain: HashSet<Entity>,
    /// Emergency brake - if true, stop all chain reactions immediately
    pub emergency_stop: bool,
}

/// Record of a power activation in the current chain
#[derive(Clone, Debug)]
pub struct PowerActivationRecord {
    pub power_type: PowerType,
    pub activator: Entity,
    pub target: Option<Entity>,
    pub activation_index: u32,
}

/// Component to mark entities that are currently part of a chain reaction
#[derive(Component)]
pub struct InChainReaction {
    pub chain_id: u32,
    pub depth: u32,
}

impl ChainReactionGuard {
    pub fn new() -> Self {
        Self {
            max_depth: 8, // Conservative limit to prevent infinite loops
            ..Default::default()
        }
    }

    /// Start a new chain reaction monitoring
    pub fn start_chain(&mut self) -> bool {
        if self.emergency_stop {
            warn!("Chain reactions disabled due to emergency stop");
            return false;
        }

        if self.current_depth >= self.max_depth {
            warn!("Chain reaction depth limit ({}) reached, stopping chain", self.max_depth);
            return false;
        }

        self.current_depth += 1;
        true
    }

    /// End the current chain reaction level
    pub fn end_chain(&mut self) {
        if self.current_depth > 0 {
            self.current_depth -= 1;
        }

        // If we're back to depth 0, clear the chain
        if self.current_depth == 0 {
            self.clear_chain();
        }
    }

    /// Clear all chain reaction tracking
    pub fn clear_chain(&mut self) {
        self.activation_chain.clear();
        self.entities_in_chain.clear();
        self.current_depth = 0;
    }

    /// Add a power activation to the current chain
    pub fn record_activation(&mut self, record: PowerActivationRecord) -> bool {
        // Check for infinite loops by detecting cycles
        if self.has_cycle(&record) {
            warn!("Cycle detected in power chain, breaking loop");
            return false;
        }

        // Check if this entity is already heavily involved in the chain
        let entity_activation_count = self
            .activation_chain
            .iter()
            .filter(|r| r.activator == record.activator)
            .count();

        if entity_activation_count >= 3 {
            warn!("Entity {:?} has activated too many powers in this chain, limiting", record.activator);
            return false;
        }

        self.activation_chain.push(record);
        true
    }

    /// Check if adding this activation would create a cycle
    fn has_cycle(&self, new_record: &PowerActivationRecord) -> bool {
        // Simple cycle detection: check if the same power by the same entity
        // targeting the same target has happened recently in this chain
        let recent_window = 3; // Check last 3 activations
        let start_index = self.activation_chain.len().saturating_sub(recent_window);

        for existing_record in &self.activation_chain[start_index..] {
            if existing_record.power_type == new_record.power_type
                && existing_record.activator == new_record.activator
                && existing_record.target == new_record.target
            {
                return true; // Cycle detected
            }
        }

        // Advanced cycle detection: check for A->B->A patterns
        if self.activation_chain.len() >= 2 {
            let last_two: Vec<_> = self.activation_chain.iter().rev().take(2).collect();
            if let [second_last, last] = &last_two[..] {
                if last.activator == new_record.activator
                    && second_last.target == Some(new_record.activator)
                    && last.target == Some(second_last.activator)
                {
                    return true; // A->B->A cycle
                }
            }
        }

        false
    }

    /// Emergency stop all chain reactions
    pub fn emergency_stop(&mut self) {
        self.emergency_stop = true;
        self.clear_chain();
        warn!("EMERGENCY STOP: All chain reactions halted");
    }

    /// Reset emergency stop (for next turn)
    pub fn reset_emergency_stop(&mut self) {
        self.emergency_stop = false;
    }

    /// Check if a power combination is known to be dangerous
    pub fn is_dangerous_combination(&self, power1: PowerType, power2: PowerType) -> bool {
        // Known dangerous combinations that can cause infinite loops
        matches!(
            (power1, power2),
            (PowerType::Multiply, PowerType::TeachRadial)
                | (PowerType::TeachRadial, PowerType::Multiply)
                | (PowerType::DoublePower, PowerType::DoublePower)
                | (PowerType::GrowQuadradius, PowerType::TeachRow)
                | (PowerType::TeachRow, PowerType::GrowQuadradius)
        )
    }
}

/// System to monitor and prevent dangerous chain reactions
pub fn chain_reaction_monitoring_system(
    mut guard: ResMut<ChainReactionGuard>,
    mut activation_events: EventReader<PowerActivationAttempt>,
    chain_events: EventWriter<PowerChainReaction>,
    mut commands: Commands,
    registry: Res<PowerRegistry>,
) {
    for event in activation_events.read() {
        // Check if this activation could start a dangerous chain
        if guard.current_depth > 0 {
            // We're already in a chain, check for dangerous combinations
            if let Some(last_activation) = guard.activation_chain.last() {
                if guard.is_dangerous_combination(last_activation.power_type, event.power_type) {
                    warn!(
                        "Dangerous power combination detected: {:?} + {:?}, blocking",
                        last_activation.power_type, event.power_type
                    );
                    continue; // Skip this activation
                }
            }
        }

        // Record this activation
        let record = PowerActivationRecord {
            power_type: event.power_type,
            activator: event.activator,
            target: event.target,
            activation_index: guard.activation_chain.len() as u32,
        };

        if !guard.record_activation(record) {
            // Chain was blocked due to cycle detection
            continue;
        }

        // Mark entities as being in a chain reaction
        if guard.current_depth > 1 {
            commands.entity(event.activator).insert(InChainReaction {
                chain_id: guard.current_depth,
                depth: guard.current_depth,
            });

            if let Some(target) = event.target {
                commands.entity(target).insert(InChainReaction {
                    chain_id: guard.current_depth,
                    depth: guard.current_depth,
                });
            }
        }
    }
}

/// System to handle chain reaction events and apply limits
pub fn handle_chain_reactions_system(
    mut guard: ResMut<ChainReactionGuard>,
    mut chain_events: EventReader<PowerChainReaction>,
    mut activation_events: EventWriter<PowerActivationAttempt>,
) {
    for event in chain_events.read() {
        if !guard.start_chain() {
            warn!("Chain reaction blocked: {:?}", event.triggering_power);
            continue;
        }

        // Limit the number of chain powers that can be activated
        let max_chain_powers = match guard.current_depth {
            1..=2 => 3, // Allow 3 chain powers at shallow depth
            3..=4 => 2, // Allow 2 chain powers at medium depth
            _ => 1,     // Allow only 1 chain power at deep levels
        };

        let limited_chain_powers: Vec<_> = event
            .chain_powers
            .iter()
            .take(max_chain_powers)
            .cloned()
            .collect();

        info!(
            "Chain reaction: {:?} triggers {} powers (limited from {})",
            event.triggering_power,
            limited_chain_powers.len(),
            event.chain_powers.len()
        );

        // Queue the limited chain powers
        for (i, chain_power) in limited_chain_powers.iter().enumerate() {
            activation_events.send(PowerActivationAttempt {
                power_type: *chain_power,
                activator: event.source_entity,
                target: event.affected_entities.get(i).copied(),
                target_position: None,
                current_turn: 0, // Would use actual turn counter
            });
        }
    }
}

/// System to clean up chain reaction components at end of turn
pub fn cleanup_chain_reactions_system(
    mut commands: Commands,
    mut guard: ResMut<ChainReactionGuard>,
    chain_entities: Query<Entity, With<InChainReaction>>,
) {
    // Remove chain reaction components from all entities
    for entity in chain_entities.iter() {
        commands.entity(entity).remove::<InChainReaction>();
    }

    // Reset the guard for next turn
    guard.clear_chain();
    guard.reset_emergency_stop();
}

/// System to detect runaway chain reactions and activate emergency stop
pub fn emergency_chain_detection_system(
    mut guard: ResMut<ChainReactionGuard>,
    registry: Res<PowerRegistry>,
    time: Res<Time>,
) {
    // If we've been in a chain for too long (in terms of activations), emergency stop
    if guard.activation_chain.len() > 20 {
        guard.emergency_stop();
        return;
    }

    // If the registry shows too much activation depth, emergency stop
    if registry.activation_depth > 10 {
        guard.emergency_stop();
        return;
    }

    // Check for rapid-fire activations (too many in a short time)
    // This would require timing data, which could be added to PowerActivationRecord
}

/// Plugin to add all chain reaction detection systems
pub struct ChainReactionPlugin;

impl Plugin for ChainReactionPlugin {
    fn build(&self, app: &mut App) {
        app.insert_resource(ChainReactionGuard::new())
            .add_systems(
                Update,
                (
                    chain_reaction_monitoring_system,
                    handle_chain_reactions_system,
                    emergency_chain_detection_system,
                )
                    .chain(),
            )
            .add_systems(PostUpdate, cleanup_chain_reactions_system);
    }
}