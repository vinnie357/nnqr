use crate::components::{GamePiece, PowerType};
use crate::resources::game_state::TurnCounter;
use crate::systems::power_registry::{
    ActivePower, AmplifierType, InteractionResult, PowerAmplifier, PowerHistory, PowerRegistry,
    PowerUsage,
};
use bevy::prelude::*;
use rand::Rng;

/// Event triggered when a power activation is attempted
#[derive(Event)]
pub struct PowerActivationAttempt {
    pub power_type: PowerType,
    pub activator: Entity,
    pub target: Option<Entity>,
    pub target_position: Option<(u8, u8)>,
    pub current_turn: u32,
}

/// Event triggered when a power interaction occurs
#[derive(Event)]
pub struct PowerInteractionEvent {
    pub power1: PowerType,
    pub power2: PowerType,
    pub interaction_result: InteractionResult,
    pub entities_involved: Vec<Entity>,
}

/// Event for chain reactions
#[derive(Event)]
pub struct PowerChainReaction {
    pub triggering_power: PowerType,
    pub chain_powers: Vec<PowerType>,
    pub source_entity: Entity,
    pub affected_entities: Vec<Entity>,
}

/// Priority levels for power activation order
#[derive(PartialEq, Eq, PartialOrd, Ord, Clone, Copy, Debug)]
pub enum PowerPriority {
    Immediate = 0,    // Defensive reactions, interrupts
    High = 1,         // Meta powers that affect other powers
    Normal = 2,       // Regular powers
    Low = 3,          // Delayed effects
    Cleanup = 4,      // End-of-turn cleanup
}

/// Represents a power activation in the queue with priority
#[derive(Debug)]
pub struct QueuedPowerActivation {
    pub power_type: PowerType,
    pub activator: Entity,
    pub target: Option<Entity>,
    pub target_position: Option<(u8, u8)>,
    pub priority: PowerPriority,
    pub amplification: f32,
    pub is_chain_reaction: bool,
}

/// Resource that manages the power activation queue and priority system
#[derive(Resource, Default)]
pub struct PowerActivationQueue {
    pub queue: Vec<QueuedPowerActivation>,
    pub processing: bool,
}

impl PowerType {
    /// Get the priority level for this power type
    pub fn get_priority(&self) -> PowerPriority {
        match self {
            // Immediate defensive reactions
            PowerType::Shield | PowerType::Reflect | PowerType::Absorb => PowerPriority::Immediate,
            
            // High priority meta powers
            PowerType::NullifyPower | PowerType::DoublePower => PowerPriority::High,
            
            // Low priority delayed effects
            PowerType::Poison | PowerType::Freeze => PowerPriority::Low,
            
            // Everything else is normal priority
            _ => PowerPriority::Normal,
        }
    }

    /// Check if this power can trigger chain reactions
    pub fn can_chain_react(&self) -> bool {
        matches!(
            self,
            PowerType::TeachRow
                | PowerType::TeachRadial
                | PowerType::DoublePower
                | PowerType::Multiply
                | PowerType::GrowQuadradius
        )
    }

    /// Check if this power can be copied by meta powers
    pub fn can_be_copied(&self) -> bool {
        !matches!(
            self,
            PowerType::CopyPower | PowerType::StealPower | PowerType::PowerSwap
        )
    }

    /// Check if this power can be nullified
    pub fn can_be_nullified(&self) -> bool {
        !matches!(self, PowerType::NullifyPower | PowerType::JumpProof)
    }
}

/// System to handle power activation attempts and queue them properly
pub fn handle_power_activation_system(
    mut activation_events: EventReader<PowerActivationAttempt>,
    mut queue: ResMut<PowerActivationQueue>,
    mut registry: ResMut<PowerRegistry>,
    pieces: Query<&GamePiece>,
) {
    for event in activation_events.read() {
        // Check if we can start another activation (chain reaction prevention)
        if !registry.enter_activation() {
            warn!(
                "Power activation blocked due to chain depth limit: {:?}",
                event.power_type
            );
            continue;
        }

        // Get amplification for this power
        let amplification = registry.get_amplification(event.activator, event.power_type);

        // Check for defensive interrupts first
        if let Some(target) = event.target {
            if let Ok(target_piece) = pieces.get(target) {
                // Check if target has defensive powers that trigger immediately
                let defensive_powers = registry.get_active_powers(target);
                for power in defensive_powers {
                    if power.power_type.get_priority() == PowerPriority::Immediate {
                        // Queue defensive reaction first
                        queue.queue.push(QueuedPowerActivation {
                            power_type: power.power_type,
                            activator: target,
                            target: Some(event.activator),
                            target_position: None,
                            priority: PowerPriority::Immediate,
                            amplification: 1.0,
                            is_chain_reaction: false,
                        });
                    }
                }
            }
        }

        // Queue the main power activation
        queue.queue.push(QueuedPowerActivation {
            power_type: event.power_type,
            activator: event.activator,
            target: event.target,
            target_position: event.target_position,
            priority: event.power_type.get_priority(),
            amplification,
            is_chain_reaction: false,
        });

        // Sort queue by priority
        queue.queue.sort_by_key(|activation| activation.priority);
    }
}

/// System to process the power activation queue
pub fn process_power_queue_system(
    mut commands: Commands,
    mut queue: ResMut<PowerActivationQueue>,
    mut registry: ResMut<PowerRegistry>,
    mut interaction_events: EventWriter<PowerInteractionEvent>,
    mut chain_events: EventWriter<PowerChainReaction>,
    pieces: Query<(Entity, &GamePiece)>,
    mut power_histories: Query<&mut PowerHistory>,
    turn_counter: Res<TurnCounter>,
) {
    if queue.processing || queue.queue.is_empty() {
        return;
    }

    queue.processing = true;

    while let Some(activation) = queue.queue.pop() {
        // Check for power interactions with currently active powers
        if let Some(target) = activation.target {
            let active_powers = registry.get_active_powers(target);
            for active_power in active_powers {
                if let Some(interaction) = registry.check_interaction(activation.power_type, active_power.power_type) {
                    // Handle the interaction
                    match interaction {
                        InteractionResult::Cancel => {
                            info!("Power {:?} cancelled by {:?}", activation.power_type, active_power.power_type);
                            continue; // Skip this activation
                        }
                        InteractionResult::Block => {
                            info!("Power {:?} blocked by {:?}", activation.power_type, active_power.power_type);
                            continue; // Skip this activation
                        }
                        InteractionResult::Enhance(multiplier) => {
                            info!("Power {:?} enhanced by {:?} ({}x)", activation.power_type, active_power.power_type, multiplier);
                            // The amplification is already handled in the activation
                        }
                        InteractionResult::ChainReaction(chain_powers) => {
                            // Queue chain reaction powers
                            for chain_power in chain_powers {
                                queue.queue.push(QueuedPowerActivation {
                                    power_type: *chain_power,
                                    activator: activation.activator,
                                    target: activation.target,
                                    target_position: activation.target_position,
                                    priority: chain_power.get_priority(),
                                    amplification: 1.0,
                                    is_chain_reaction: true,
                                });
                            }
                            
                            chain_events.send(PowerChainReaction {
                                triggering_power: activation.power_type,
                                chain_powers: chain_powers.clone(),
                                source_entity: activation.activator,
                                affected_entities: vec![target],
                            });
                        }
                        _ => {}
                    }

                    interaction_events.send(PowerInteractionEvent {
                        power1: activation.power_type,
                        power2: active_power.power_type,
                        interaction_result: interaction.clone(),
                        entities_involved: vec![activation.activator, target],
                    });
                }
            }
        }

        // Execute the actual power activation
        let success = execute_power_activation(&mut commands, &activation, &mut registry, &pieces);

        // Record the power usage
        let usage = PowerUsage {
            power_type: activation.power_type,
            user: activation.activator,
            target: activation.target,
            target_position: activation.target_position,
            turn_used: turn_counter.turn_number,
            success,
            effects_triggered: vec![], // This would be populated by the actual power execution
        };

        registry.record_power_usage(usage.clone());

        // Update power history for the activator
        if let Ok(mut history) = power_histories.get_mut(activation.activator) {
            history.record_power_use(usage);
        }

        // If this was a chain reaction, we might want to limit further chains
        if activation.is_chain_reaction {
            // Additional chain reaction logic here if needed
        }
    }

    queue.processing = false;
    registry.exit_activation();
}

/// Execute a specific power activation (simplified version for now)
fn execute_power_activation(
    commands: &mut Commands,
    activation: &QueuedPowerActivation,
    registry: &mut PowerRegistry,
    pieces: &Query<(Entity, &GamePiece)>,
) -> bool {
    // This is a simplified version - the actual power effects would be handled
    // by the existing power_effects.rs system, but with interaction awareness
    
    match activation.power_type {
        PowerType::DoublePower => {
            // DoublePower creates an amplifier for the next power
            registry.add_amplifier(
                activation.activator,
                PowerAmplifier {
                    amplifier_type: AmplifierType::NextPowerOnly,
                    multiplier: 2.0,
                    remaining_uses: Some(1),
                    affects_powers: vec![],
                },
            );
            true
        }
        PowerType::NullifyPower => {
            // Remove a random active power from target
            if let Some(target) = activation.target {
                if let Some(powers) = registry.active_powers.get_mut(&target) {
                    if !powers.is_empty() {
                        let index = rand::thread_rng().gen_range(0..powers.len());
                        let removed_power = powers.remove(index);
                        info!("Nullified power {:?} on target", removed_power.power_type);
                        return true;
                    }
                }
            }
            false
        }
        PowerType::GrowQuadradius => {
            // Add a powerful amplifier to all powers
            registry.add_amplifier(
                activation.activator,
                PowerAmplifier {
                    amplifier_type: AmplifierType::Global,
                    multiplier: 3.0,
                    remaining_uses: Some(5),
                    affects_powers: vec![],
                },
            );
            
            // Also add the active power effect
            registry.add_active_power(
                activation.activator,
                ActivePower {
                    power_type: PowerType::GrowQuadradius,
                    source_entity: activation.activator,
                    target_entity: activation.activator,
                    duration_remaining: 999, // Permanent effect
                    effect_strength: 3.0,
                    can_be_copied: false,
                    can_be_stolen: false,
                    can_be_nullified: true,
                    activation_turn: 0, // Would use actual turn counter
                },
            );
            true
        }
        // For other powers, delegate to the existing power_effects.rs system
        _ => {
            // This would call the existing power activation logic
            // For now, just return true
            true
        }
    }
}

/// System to handle teaching powers (sharing powers with other pieces)
pub fn handle_teaching_powers_system(
    mut registry: ResMut<PowerRegistry>,
    pieces: Query<(Entity, &GamePiece)>,
    power_histories: Query<&PowerHistory>,
    turn_counter: Res<TurnCounter>,
) {
    // This system handles TeachRow and TeachRadial powers
    let entities_with_teaching: Vec<_> = registry
        .active_powers
        .iter()
        .filter_map(|(entity, powers)| {
            let teaching_power = powers.iter().find(|p| {
                p.power_type == PowerType::TeachRow || p.power_type == PowerType::TeachRadial
            });
            teaching_power.map(|power| (*entity, power.power_type))
        })
        .collect();

    for (teaching_entity, teaching_power) in entities_with_teaching {
        if let Ok((_, teacher_piece)) = pieces.get(teaching_entity) {
            if let Ok(teacher_history) = power_histories.get(teaching_entity) {
                if let Some(last_power) = teacher_history.get_last_used_power() {
                    // Find pieces to teach based on the teaching power type
                    let students: Vec<_> = pieces
                        .iter()
                        .filter(|(student_entity, student_piece)| {
                            *student_entity != teaching_entity
                                && student_piece.player == teacher_piece.player
                                && match teaching_power {
                                    PowerType::TeachRow => {
                                        student_piece.board_position.1 == teacher_piece.board_position.1
                                    }
                                    PowerType::TeachRadial => {
                                        let dx = (student_piece.board_position.0 as i8
                                            - teacher_piece.board_position.0 as i8)
                                            .abs();
                                        let dy = (student_piece.board_position.1 as i8
                                            - teacher_piece.board_position.1 as i8)
                                            .abs();
                                        dx <= 1 && dy <= 1
                                    }
                                    _ => false,
                                }
                        })
                        .collect();

                    // Give the last used power to all student pieces
                    for (student_entity, _) in students {
                        registry.add_active_power(
                            student_entity,
                            ActivePower {
                                power_type: last_power.power_type,
                                source_entity: teaching_entity,
                                target_entity: student_entity,
                                duration_remaining: 3, // Taught powers last 3 turns
                                effect_strength: 0.8,  // Slightly reduced effectiveness
                                can_be_copied: true,
                                can_be_stolen: true,
                                can_be_nullified: true,
                                activation_turn: turn_counter.turn_number,
                            },
                        );

                        info!(
                            "Taught power {:?} from {:?} to {:?}",
                            last_power.power_type, teaching_entity, student_entity
                        );
                    }
                }
            }
        }
    }
}

/// System to handle power echoing (PowerEcho effect)
pub fn handle_power_echo_system(
    mut activation_events: EventWriter<PowerActivationAttempt>,
    registry: Res<PowerRegistry>,
    pieces: Query<(Entity, &GamePiece)>,
    turn_counter: Res<TurnCounter>,
) {
    // Find pieces with PowerEcho active
    let echo_entities: Vec<_> = registry
        .active_powers
        .iter()
        .filter_map(|(entity, powers)| {
            powers
                .iter()
                .find(|p| p.power_type == PowerType::PowerEcho)
                .map(|_| *entity)
        })
        .collect();

    for echo_entity in echo_entities {
        if let Ok((_, echo_piece)) = pieces.get(echo_entity) {
            // Get the last opponent power
            if let Some(last_opponent_power) = registry.get_last_opponent_power(echo_entity) {
                // Echo the opponent's power back at them
                activation_events.send(PowerActivationAttempt {
                    power_type: last_opponent_power.power_type,
                    activator: echo_entity,
                    target: Some(last_opponent_power.user),
                    target_position: None,
                    current_turn: turn_counter.turn_number,
                });

                info!(
                    "Power Echo: {:?} echoed {:?} back to opponent",
                    echo_entity, last_opponent_power.power_type
                );
            }
        }
    }
}