use crate::components::*;
use crate::resources::game_state::TurnCounter;
use crate::resources::*;
use crate::systems::power_effects::MoveDiagonalActive;
use bevy::prelude::*;

/// System for processing duration-based effects each turn
#[derive(Resource, Default)]
pub struct EffectProcessor {
    pub current_turn: u32,
    pub effects_processed_this_turn: bool,
}

/// Component to track all active effects on an entity
#[derive(Component, Default)]
pub struct ActiveEffects {
    pub effects: Vec<PowerEffect>,
}

impl ActiveEffects {
    pub fn add_effect(&mut self, effect: PowerEffect) -> bool {
        // Check if effect can stack with existing effects
        for existing_effect in &self.effects {
            if !effect.can_stack_with(existing_effect) {
                match effect.effect_data.stacking_rule() {
                    StackingRule::NoStack => {
                        println!(
                            "Effect {:?} cannot stack - rejected",
                            effect.effect_data.get_effect_name()
                        );
                        return false;
                    }
                    StackingRule::Replace => {
                        // Remove the old effect and add the new one
                        self.effects.retain(|e| {
                            !e.effect_data
                                .get_effect_name()
                                .eq(effect.effect_data.get_effect_name())
                        });
                        break;
                    }
                    StackingRule::Combine => {
                        // Combine effects (implementation depends on effect type)
                        if let Some(combined) = self.combine_effects(existing_effect, &effect) {
                            self.effects.retain(|e| {
                                !e.effect_data
                                    .get_effect_name()
                                    .eq(effect.effect_data.get_effect_name())
                            });
                            self.effects.push(combined);
                            return true;
                        }
                        break;
                    }
                    StackingRule::Independent => {
                        // Effects work independently - just add
                        break;
                    }
                }
            }
        }

        println!(
            "Added effect: {} (duration: {} turns)",
            effect.effect_data.get_effect_name(),
            effect.duration_turns
        );
        self.effects.push(effect);
        true
    }

    pub fn remove_expired_effects(&mut self, current_turn: u32) -> Vec<PowerEffect> {
        let (expired, active): (Vec<_>, Vec<_>) = self
            .effects
            .drain(..)
            .partition(|effect| effect.is_expired(current_turn));

        self.effects = active;

        if !expired.is_empty() {
            println!("Removed {} expired effects", expired.len());
        }

        expired
    }

    pub fn has_effect(&self, effect_name: &str) -> bool {
        self.effects
            .iter()
            .any(|e| e.effect_data.get_effect_name() == effect_name)
    }

    pub fn get_effect(&self, effect_name: &str) -> Option<&PowerEffect> {
        self.effects
            .iter()
            .find(|e| e.effect_data.get_effect_name() == effect_name)
    }

    fn combine_effects(&self, existing: &PowerEffect, new: &PowerEffect) -> Option<PowerEffect> {
        match (&existing.effect_data, &new.effect_data) {
            // Combine shield hits
            (
                EffectData::Protection(ProtectionType::Shield { hits_remaining: h1 }),
                EffectData::Protection(ProtectionType::Shield { hits_remaining: h2 }),
            ) => {
                let combined_effect = PowerEffect::new(
                    new.power_type,
                    new.duration_turns.max(existing.duration_turns),
                    new.target_entity,
                    EffectData::Protection(ProtectionType::Shield {
                        hits_remaining: h1 + h2,
                    }),
                    new.source_player,
                    new.turn_applied,
                );
                Some(combined_effect)
            }
            // Combine movement enhancements
            (
                EffectData::Movement(MovementRestriction::Enhanced(_)),
                EffectData::Movement(MovementRestriction::Enhanced(_)),
            ) => {
                // For now, just use the new effect with extended duration
                let combined_effect = PowerEffect::new(
                    new.power_type,
                    new.duration_turns.max(existing.duration_turns),
                    new.target_entity,
                    new.effect_data.clone(),
                    new.source_player,
                    new.turn_applied,
                );
                Some(combined_effect)
            }
            _ => None,
        }
    }
}

/// System to process effects at the start of each turn
pub fn process_turn_effects(
    mut effect_processor: ResMut<EffectProcessor>,
    game_state: Res<GameState>,
    turn_counter: Res<TurnCounter>,
    mut commands: Commands,
    mut entities_with_effects: Query<(Entity, &mut ActiveEffects, Option<&GamePiece>)>,
) {
    // Only process once per turn
    if effect_processor.current_turn == turn_counter.turn_number
        && effect_processor.effects_processed_this_turn
    {
        return;
    }

    // Update turn tracking
    effect_processor.current_turn = turn_counter.turn_number;
    effect_processor.effects_processed_this_turn = true;

    println!(
        "🔄 Processing effects for turn {}",
        turn_counter.turn_number
    );

    for (entity, mut active_effects, piece) in entities_with_effects.iter_mut() {
        // Process death effects first (poison)
        for effect in &active_effects.effects {
            if let EffectData::Status(StatusEffect::Poisoned { death_timer }) = &effect.effect_data
            {
                if effect.remaining_turns(turn_counter.turn_number) <= 1 {
                    println!("💀 Piece dies from poison!");
                    // Spawn death effect
                    if let Some(piece) = piece {
                        let world_pos = board_to_world_position(piece.board_position);
                        crate::systems::visual_effects::spawn_capture_explosion(
                            &mut commands,
                            Vec3::new(world_pos.x, world_pos.y, 0.0),
                            Color::rgb(0.4, 0.8, 0.2), // Green poison explosion
                        );
                    }
                    // Despawn the entity
                    commands.entity(entity).despawn();
                    continue;
                }
            }
        }

        // Remove expired effects
        let expired_effects = active_effects.remove_expired_effects(turn_counter.turn_number);

        // Log expired effects
        for expired in expired_effects {
            println!(
                "⏰ Effect expired: {}",
                expired.effect_data.get_effect_name()
            );
        }

        // Update component states based on active effects
        update_component_states(&mut commands, entity, &active_effects);
    }

    println!(
        "✅ Effect processing complete for turn {}",
        turn_counter.turn_number
    );
}

/// System to mark turn effects as not processed when turn changes
pub fn reset_effect_processing(
    mut effect_processor: ResMut<EffectProcessor>,
    game_state: Res<GameState>,
    turn_counter: Res<TurnCounter>,
) {
    if effect_processor.current_turn != turn_counter.turn_number {
        effect_processor.effects_processed_this_turn = false;
    }
}

/// Update entity components based on active effects
fn update_component_states(
    commands: &mut Commands,
    entity: Entity,
    active_effects: &ActiveEffects,
) {
    // Remove all effect-related components first
    commands
        .entity(entity)
        .remove::<Frozen>()
        .remove::<Invisible>()
        .remove::<Shield>()
        .remove::<Poisoned>()
        .remove::<MoveDiagonalActive>();

    // Add components based on active effects
    for effect in &active_effects.effects {
        match &effect.effect_data {
            EffectData::Status(StatusEffect::Frozen) => {
                commands.entity(entity).insert(Frozen {
                    remaining_turns: effect.remaining_turns(effect.turn_applied + 1),
                });
            }
            EffectData::Status(StatusEffect::Invisible) => {
                commands.entity(entity).insert(Invisible {
                    remaining_turns: effect.remaining_turns(effect.turn_applied + 1),
                });
            }
            EffectData::Protection(ProtectionType::Shield { hits_remaining }) => {
                commands.entity(entity).insert(Shield {
                    remaining_hits: *hits_remaining,
                });
            }
            EffectData::Status(StatusEffect::Poisoned { death_timer }) => {
                commands.entity(entity).insert(Poisoned {
                    remaining_turns: *death_timer,
                });
            }
            EffectData::Movement(MovementRestriction::Enhanced(MovementType::Diagonal)) => {
                commands.entity(entity).insert(MoveDiagonalActive);
            }
            _ => {} // Other effects don't need specific components yet
        }
    }
}

/// Helper function to add an effect to an entity
pub fn add_effect_to_entity(commands: &mut Commands, entity: Entity, effect: PowerEffect) {
    // Get or create ActiveEffects component
    commands.entity(entity).try_insert(ActiveEffects::default());

    // We'll update the ActiveEffects in a separate system since we can't query and mutate in the same system
    commands.entity(entity).insert(PendingEffect(effect));
}

/// Component for effects that need to be added
#[derive(Component)]
pub struct PendingEffect(pub PowerEffect);

/// System to process pending effects
pub fn process_pending_effects(
    mut commands: Commands,
    mut entities: Query<(Entity, &mut ActiveEffects, &PendingEffect)>,
) {
    for (entity, mut active_effects, pending) in entities.iter_mut() {
        active_effects.add_effect(pending.0.clone());
        commands.entity(entity).remove::<PendingEffect>();
    }
}

/// Helper function for coordinate conversion
fn board_to_world_position(board_pos: (u8, u8)) -> Vec2 {
    use crate::components::board::{BOARD_HEIGHT, BOARD_WIDTH};
    use crate::components::TILE_SIZE;

    let enhanced_tile_size = TILE_SIZE * 1.2;
    let x = (board_pos.0 as f32 - BOARD_WIDTH as f32 / 2.0 + 0.5) * enhanced_tile_size;
    let y = (board_pos.1 as f32 - BOARD_HEIGHT as f32 / 2.0 + 0.5) * enhanced_tile_size;
    Vec2::new(x, y)
}

/// System to handle effect visualization
pub fn update_effect_indicators(
    mut commands: Commands,
    entities_with_effects: Query<
        (Entity, &ActiveEffects, &Transform),
        (With<GamePiece>, Changed<ActiveEffects>),
    >,
    existing_indicators: Query<Entity, With<EffectIndicator>>,
) {
    // Clear old indicators
    for indicator_entity in existing_indicators.iter() {
        commands.entity(indicator_entity).despawn();
    }

    // Create new indicators
    for (entity, active_effects, transform) in entities_with_effects.iter() {
        let mut y_offset = 0.0;

        // Sort effects by visual priority
        let mut sorted_effects = active_effects.effects.clone();
        sorted_effects.sort_by_key(|e| std::cmp::Reverse(e.get_visual_priority()));

        for effect in sorted_effects.iter().take(3) {
            // Show max 3 indicators
            spawn_effect_indicator(
                &mut commands,
                entity,
                effect,
                Vec3::new(
                    transform.translation.x,
                    transform.translation.y + y_offset,
                    transform.translation.z + 0.1,
                ),
            );
            y_offset += 15.0; // Stack indicators vertically
        }
    }
}

/// Component to mark effect indicators
#[derive(Component)]
pub struct EffectIndicator {
    pub effect_type: String,
    pub parent_entity: Entity,
}

/// Spawn a visual indicator for an effect
fn spawn_effect_indicator(
    commands: &mut Commands,
    parent_entity: Entity,
    effect: &PowerEffect,
    position: Vec3,
) {
    let (color, icon) = get_effect_visual_data(&effect.effect_data);

    commands.spawn((
        EffectIndicator {
            effect_type: effect.effect_data.get_effect_name().to_string(),
            parent_entity,
        },
        Text2dBundle {
            text: Text::from_section(
                icon,
                TextStyle {
                    font_size: 16.0,
                    color,
                    ..default()
                },
            ),
            transform: Transform::from_translation(position),
            ..default()
        },
    ));
}

/// Get visual data for an effect
fn get_effect_visual_data(effect_data: &EffectData) -> (Color, &'static str) {
    match effect_data {
        EffectData::Status(StatusEffect::Poisoned { .. }) => (Color::rgb(0.4, 0.8, 0.2), "☠"),
        EffectData::Status(StatusEffect::Frozen) => (Color::rgb(0.4, 0.8, 1.0), "❄"),
        EffectData::Protection(ProtectionType::Shield { .. }) => (Color::rgb(0.7, 0.7, 0.9), "🛡"),
        EffectData::Status(StatusEffect::Invisible) => (Color::rgba(0.5, 0.5, 0.5, 0.7), "👻"),
        EffectData::Movement(MovementRestriction::Enhanced(MovementType::Diagonal)) => {
            (Color::rgb(0.6, 0.6, 1.0), "⤡")
        }
        EffectData::Movement(MovementRestriction::Enhanced(MovementType::Teleport)) => {
            (Color::rgb(0.2, 0.2, 1.0), "⚡")
        }
        EffectData::Movement(MovementRestriction::Enhanced(MovementType::Jump)) => {
            (Color::rgb(0.3, 0.5, 1.0), "🦘")
        }
        EffectData::Movement(MovementRestriction::Enhanced(MovementType::Knight)) => {
            (Color::rgb(0.5, 0.7, 1.0), "♞")
        }
        EffectData::Movement(MovementRestriction::Enhanced(MovementType::Double)) => {
            (Color::rgb(0.6, 0.4, 0.9), "2×")
        }
        EffectData::Protection(ProtectionType::Reflection { .. }) => {
            (Color::rgb(0.8, 0.7, 0.9), "↩")
        }
        _ => (Color::rgb(0.8, 0.8, 0.8), "?"),
    }
}
