#[cfg(test)]
mod tests {
    use crate::components::power::*;
    use crate::resources::*;
    use crate::systems::effect_processing::*;
    use bevy::prelude::*;

    #[test]
    fn test_power_effect_creation() {
        let entity = Entity::from_raw(1);
        let effect = PowerEffect::new(
            PowerType::Shield,
            3,
            entity,
            EffectData::Protection(ProtectionType::Shield { hits_remaining: 1 }),
            Player::Player1,
            1,
        );

        assert_eq!(effect.power_type, PowerType::Shield);
        assert_eq!(effect.duration_turns, 3);
        assert_eq!(effect.target_entity, entity);
        assert_eq!(effect.source_player, Player::Player1);
        assert_eq!(effect.turn_applied, 1);
    }

    #[test]
    fn test_effect_expiration() {
        let entity = Entity::from_raw(1);
        let effect = PowerEffect::new(
            PowerType::Frozen,
            3,
            entity,
            EffectData::Status(StatusEffect::Frozen),
            Player::Player1,
            1,
        );

        // Not expired on the same turn
        assert!(!effect.is_expired(1));
        
        // Not expired within duration
        assert!(!effect.is_expired(3));
        
        // Expired after duration
        assert!(effect.is_expired(4));
        assert!(effect.is_expired(5));
    }

    #[test]
    fn test_remaining_turns() {
        let entity = Entity::from_raw(1);
        let effect = PowerEffect::new(
            PowerType::Invisible,
            3,
            entity,
            EffectData::Status(StatusEffect::Invisible),
            Player::Player1,
            1,
        );

        assert_eq!(effect.remaining_turns(1), 3);
        assert_eq!(effect.remaining_turns(2), 2);
        assert_eq!(effect.remaining_turns(3), 1);
        assert_eq!(effect.remaining_turns(4), 0);
        assert_eq!(effect.remaining_turns(5), 0);
    }

    #[test]
    fn test_effect_stacking_rules() {
        let entity = Entity::from_raw(1);
        
        // Two shield effects - should not stack
        let shield1 = PowerEffect::new(
            PowerType::Shield,
            3,
            entity,
            EffectData::Protection(ProtectionType::Shield { hits_remaining: 1 }),
            Player::Player1,
            1,
        );
        
        let shield2 = PowerEffect::new(
            PowerType::Shield,
            3,
            entity,
            EffectData::Protection(ProtectionType::Shield { hits_remaining: 1 }),
            Player::Player1,
            2,
        );
        
        assert!(!shield1.can_stack_with(&shield2));
        
        // Shield and invisibility - should stack
        let invisibility = PowerEffect::new(
            PowerType::Invisible,
            3,
            entity,
            EffectData::Status(StatusEffect::Invisible),
            Player::Player1,
            1,
        );
        
        assert!(shield1.can_stack_with(&invisibility));
        assert!(invisibility.can_stack_with(&shield1));
    }

    #[test]
    fn test_active_effects_component() {
        let entity = Entity::from_raw(1);
        let mut active_effects = ActiveEffects::default();
        
        // Add a shield effect
        let shield_effect = PowerEffect::new(
            PowerType::Shield,
            3,
            entity,
            EffectData::Protection(ProtectionType::Shield { hits_remaining: 1 }),
            Player::Player1,
            1,
        );
        
        assert!(active_effects.add_effect(shield_effect));
        assert_eq!(active_effects.effects.len(), 1);
        assert!(active_effects.has_effect("Shield"));
        
        // Try to add another shield - should replace the first one
        let shield_effect2 = PowerEffect::new(
            PowerType::Shield,
            5,
            entity,
            EffectData::Protection(ProtectionType::Shield { hits_remaining: 2 }),
            Player::Player1,
            2,
        );
        
        assert!(active_effects.add_effect(shield_effect2));
        assert_eq!(active_effects.effects.len(), 1); // Should still be 1, replaced
        
        // Add invisibility - should stack
        let invisibility_effect = PowerEffect::new(
            PowerType::Invisible,
            3,
            entity,
            EffectData::Status(StatusEffect::Invisible),
            Player::Player1,
            1,
        );
        
        assert!(active_effects.add_effect(invisibility_effect));
        assert_eq!(active_effects.effects.len(), 2); // Now should be 2
        assert!(active_effects.has_effect("Shield"));
        assert!(active_effects.has_effect("Invisible"));
    }

    #[test]
    fn test_effect_expiration_removal() {
        let entity = Entity::from_raw(1);
        let mut active_effects = ActiveEffects::default();
        
        // Add effects that expire at different times
        let short_effect = PowerEffect::new(
            PowerType::Frozen,
            2,
            entity,
            EffectData::Status(StatusEffect::Frozen),
            Player::Player1,
            1,
        );
        
        let long_effect = PowerEffect::new(
            PowerType::Invisible,
            5,
            entity,
            EffectData::Status(StatusEffect::Invisible),
            Player::Player1,
            1,
        );
        
        active_effects.add_effect(short_effect);
        active_effects.add_effect(long_effect);
        assert_eq!(active_effects.effects.len(), 2);
        
        // After 3 turns, short effect should expire
        let expired = active_effects.remove_expired_effects(3);
        assert_eq!(expired.len(), 1);
        assert_eq!(active_effects.effects.len(), 1);
        assert!(!active_effects.has_effect("Frozen"));
        assert!(active_effects.has_effect("Invisible"));
        
        // After 6 turns, long effect should also expire
        let expired = active_effects.remove_expired_effects(6);
        assert_eq!(expired.len(), 1);
        assert_eq!(active_effects.effects.len(), 0);
        assert!(!active_effects.has_effect("Invisible"));
    }

    #[test]
    fn test_effect_visual_priority() {
        let entity = Entity::from_raw(1);
        
        let poison_effect = PowerEffect::new(
            PowerType::Poison,
            3,
            entity,
            EffectData::Status(StatusEffect::Poisoned { death_timer: 3 }),
            Player::Player1,
            1,
        );
        
        let shield_effect = PowerEffect::new(
            PowerType::Shield,
            3,
            entity,
            EffectData::Protection(ProtectionType::Shield { hits_remaining: 1 }),
            Player::Player1,
            1,
        );
        
        let movement_effect = PowerEffect::new(
            PowerType::MoveDiagonal,
            3,
            entity,
            EffectData::Movement(MovementRestriction::Enhanced(MovementType::Diagonal)),
            Player::Player1,
            1,
        );
        
        // Poison should have highest priority
        assert!(poison_effect.get_visual_priority() > shield_effect.get_visual_priority());
        assert!(shield_effect.get_visual_priority() > movement_effect.get_visual_priority());
    }

    #[test]
    fn test_effect_data_names() {
        let shield_data = EffectData::Protection(ProtectionType::Shield { hits_remaining: 1 });
        assert_eq!(shield_data.get_effect_name(), "Shield");
        
        let frozen_data = EffectData::Status(StatusEffect::Frozen);
        assert_eq!(frozen_data.get_effect_name(), "Frozen");
        
        let diagonal_data = EffectData::Movement(MovementRestriction::Enhanced(MovementType::Diagonal));
        assert_eq!(diagonal_data.get_effect_name(), "Diagonal Movement");
        
        let poison_data = EffectData::Status(StatusEffect::Poisoned { death_timer: 3 });
        assert_eq!(poison_data.get_effect_name(), "Poisoned");
    }

    #[test]
    fn test_stacking_rules() {
        let shield_data = EffectData::Protection(ProtectionType::Shield { hits_remaining: 1 });
        let frozen_data = EffectData::Status(StatusEffect::Frozen);
        let diagonal_data = EffectData::Movement(MovementRestriction::Enhanced(MovementType::Diagonal));
        
        // Check stacking rules
        match shield_data.stacking_rule() {
            StackingRule::Replace => assert!(true),
            _ => panic!("Shield should use Replace stacking rule"),
        }
        
        match frozen_data.stacking_rule() {
            StackingRule::NoStack => assert!(true),
            _ => panic!("Frozen should use NoStack stacking rule"),
        }
        
        match diagonal_data.stacking_rule() {
            StackingRule::Combine => assert!(true),
            _ => panic!("Enhanced movement should use Combine stacking rule"),
        }
    }
}