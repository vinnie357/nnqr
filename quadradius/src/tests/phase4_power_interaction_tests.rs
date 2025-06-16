use crate::components::{GamePiece, Player, PowerType};
use crate::resources::game_state::GameState;
use crate::systems::chain_reaction_detection::{ChainReactionGuard, PowerActivationRecord};
use crate::systems::power_interactions::{PowerActivationAttempt, PowerPriority};
use crate::systems::power_registry::{
    ActivePower, AmplifierType, InteractionResult, PowerAmplifier, PowerHistory, PowerRegistry,
    PowerUsage,
};
use bevy::prelude::*;

#[cfg(test)]
mod tests {
    use super::*;

    fn create_test_app() -> App {
        let mut app = App::new();
        app.add_plugins(MinimalPlugins)
            .insert_resource(PowerRegistry::new())
            .insert_resource(ChainReactionGuard::new())
            .add_event::<PowerActivationAttempt>();
        app
    }

    fn create_test_piece(player: Player, position: (u8, u8)) -> (GamePiece, Transform) {
        (
            GamePiece {
                player,
                board_position: position,
            },
            Transform::default(),
        )
    }

    #[test]
    fn test_power_registry_initialization() {
        let registry = PowerRegistry::new();
        
        // Test that interaction rules are properly initialized
        assert!(registry.interaction_rules.len() > 0);
        
        // Test specific interaction rules
        assert_eq!(
            registry.check_interaction(PowerType::DoublePower, PowerType::DoublePower),
            Some(&InteractionResult::Block)
        );
        
        assert_eq!(
            registry.check_interaction(PowerType::NullifyPower, PowerType::Shield),
            Some(&InteractionResult::Cancel)
        );
    }

    #[test]
    fn test_power_priorities() {
        // Test that defensive powers have immediate priority
        assert_eq!(PowerType::Shield.get_priority(), PowerPriority::Immediate);
        assert_eq!(PowerType::Reflect.get_priority(), PowerPriority::Immediate);
        
        // Test that meta powers have high priority
        assert_eq!(PowerType::NullifyPower.get_priority(), PowerPriority::High);
        assert_eq!(PowerType::DoublePower.get_priority(), PowerPriority::High);
        
        // Test that most powers have normal priority
        assert_eq!(PowerType::MoveDiagonal.get_priority(), PowerPriority::Normal);
        assert_eq!(PowerType::Teleport.get_priority(), PowerPriority::Normal);
        
        // Test that delayed effects have low priority
        assert_eq!(PowerType::Poison.get_priority(), PowerPriority::Low);
        assert_eq!(PowerType::Freeze.get_priority(), PowerPriority::Low);
    }

    #[test]
    fn test_power_can_be_copied() {
        // Test that most powers can be copied
        assert!(PowerType::MoveDiagonal.can_be_copied());
        assert!(PowerType::Shield.can_be_copied());
        assert!(PowerType::GrowQuadradius.can_be_copied());
        
        // Test that meta copy powers cannot be copied (prevent recursion)
        assert!(!PowerType::CopyPower.can_be_copied());
        assert!(!PowerType::StealPower.can_be_copied());
        assert!(!PowerType::PowerSwap.can_be_copied());
    }

    #[test]
    fn test_power_can_be_nullified() {
        // Test that most powers can be nullified
        assert!(PowerType::MoveDiagonal.can_be_nullified());
        assert!(PowerType::Shield.can_be_nullified());
        assert!(PowerType::GrowQuadradius.can_be_nullified());
        
        // Test that some powers cannot be nullified
        assert!(!PowerType::NullifyPower.can_be_nullified());
        assert!(!PowerType::JumpProof.can_be_nullified());
    }

    #[test]
    fn test_power_chain_reaction_capability() {
        // Test powers that can cause chain reactions
        assert!(PowerType::TeachRow.can_chain_react());
        assert!(PowerType::TeachRadial.can_chain_react());
        assert!(PowerType::DoublePower.can_chain_react());
        assert!(PowerType::Multiply.can_chain_react());
        assert!(PowerType::GrowQuadradius.can_chain_react());
        
        // Test powers that cannot cause chain reactions
        assert!(!PowerType::MoveDiagonal.can_chain_react());
        assert!(!PowerType::Shield.can_chain_react());
        assert!(!PowerType::Poison.can_chain_react());
    }

    #[test]
    fn test_power_registry_active_powers() {
        let mut registry = PowerRegistry::new();
        let entity = Entity::from_raw(1);
        
        // Test adding active power
        let active_power = ActivePower {
            power_type: PowerType::Shield,
            source_entity: entity,
            target_entity: entity,
            duration_remaining: 5,
            effect_strength: 1.0,
            can_be_copied: true,
            can_be_stolen: true,
            can_be_nullified: true,
            activation_turn: 1,
        };
        
        registry.add_active_power(entity, active_power);
        
        // Test querying active powers
        assert!(registry.has_active_power(entity, PowerType::Shield));
        assert!(!registry.has_active_power(entity, PowerType::MoveDiagonal));
        
        let powers = registry.get_active_powers(entity);
        assert_eq!(powers.len(), 1);
        assert_eq!(powers[0].power_type, PowerType::Shield);
    }

    #[test]
    fn test_power_amplification() {
        let mut registry = PowerRegistry::new();
        let entity = Entity::from_raw(1);
        
        // Test adding amplifier
        let amplifier = PowerAmplifier {
            amplifier_type: AmplifierType::Global,
            multiplier: 2.0,
            remaining_uses: Some(3),
            affects_powers: vec![],
        };
        
        registry.add_amplifier(entity, amplifier);
        
        // Test getting amplification
        let amp = registry.get_amplification(entity, PowerType::MoveDiagonal);
        assert_eq!(amp, 2.0);
        
        // Test consuming amplifier use
        registry.consume_amplifier_use(entity, PowerType::MoveDiagonal);
        
        // The amplifier should still be there but with reduced uses
        let amp = registry.get_amplification(entity, PowerType::MoveDiagonal);
        assert_eq!(amp, 2.0); // Still has uses remaining
    }

    #[test]
    fn test_power_history() {
        let mut history = PowerHistory::new();
        
        let usage = PowerUsage {
            power_type: PowerType::MoveDiagonal,
            user: Entity::from_raw(1),
            target: Some(Entity::from_raw(2)),
            target_position: Some((3, 4)),
            turn_used: 1,
            success: true,
            effects_triggered: vec![],
        };
        
        history.record_power_use(usage.clone());
        
        // Test getting last used power
        assert!(history.get_last_used_power().is_some());
        assert_eq!(history.get_last_used_power().unwrap().power_type, PowerType::MoveDiagonal);
        
        // Test getting powers used this turn
        let this_turn_powers = history.get_powers_used_this_turn(1);
        assert_eq!(this_turn_powers.len(), 1);
        assert_eq!(this_turn_powers[0].power_type, PowerType::MoveDiagonal);
        
        // Test getting powers used different turn
        let other_turn_powers = history.get_powers_used_this_turn(2);
        assert_eq!(other_turn_powers.len(), 0);
    }

    #[test]
    fn test_chain_reaction_guard_basic() {
        let mut guard = ChainReactionGuard::new();
        
        // Test starting chains
        assert!(guard.start_chain());
        assert_eq!(guard.current_depth, 1);
        
        assert!(guard.start_chain());
        assert_eq!(guard.current_depth, 2);
        
        // Test ending chains
        guard.end_chain();
        assert_eq!(guard.current_depth, 1);
        
        guard.end_chain();
        assert_eq!(guard.current_depth, 0);
    }

    #[test]
    fn test_chain_reaction_depth_limit() {
        let mut guard = ChainReactionGuard::new();
        guard.max_depth = 3;
        
        // Should allow up to max_depth
        assert!(guard.start_chain()); // depth 1
        assert!(guard.start_chain()); // depth 2
        assert!(guard.start_chain()); // depth 3
        
        // Should block further chains
        assert!(!guard.start_chain()); // Should fail
        assert_eq!(guard.current_depth, 3); // Should not have increased
    }

    #[test]
    fn test_chain_reaction_cycle_detection() {
        let mut guard = ChainReactionGuard::new();
        let entity1 = Entity::from_raw(1);
        let entity2 = Entity::from_raw(2);
        
        // Record first activation
        let record1 = PowerActivationRecord {
            power_type: PowerType::MoveDiagonal,
            activator: entity1,
            target: Some(entity2),
            activation_index: 0,
        };
        assert!(guard.record_activation(record1));
        
        // Record different activation (should work)
        let record2 = PowerActivationRecord {
            power_type: PowerType::Shield,
            activator: entity2,
            target: Some(entity1),
            activation_index: 1,
        };
        assert!(guard.record_activation(record2));
        
        // Try to record same activation as first (should detect cycle)
        let record3 = PowerActivationRecord {
            power_type: PowerType::MoveDiagonal,
            activator: entity1,
            target: Some(entity2),
            activation_index: 2,
        };
        assert!(!guard.record_activation(record3)); // Should detect cycle
    }

    #[test]
    fn test_dangerous_power_combinations() {
        let guard = ChainReactionGuard::new();
        
        // Test known dangerous combinations
        assert!(guard.is_dangerous_combination(PowerType::Multiply, PowerType::TeachRadial));
        assert!(guard.is_dangerous_combination(PowerType::TeachRadial, PowerType::Multiply));
        assert!(guard.is_dangerous_combination(PowerType::DoublePower, PowerType::DoublePower));
        assert!(guard.is_dangerous_combination(PowerType::GrowQuadradius, PowerType::TeachRow));
        
        // Test safe combinations
        assert!(!guard.is_dangerous_combination(PowerType::MoveDiagonal, PowerType::Shield));
        assert!(!guard.is_dangerous_combination(PowerType::Teleport, PowerType::Poison));
    }

    #[test]
    fn test_emergency_stop() {
        let mut guard = ChainReactionGuard::new();
        
        // Normal operation
        assert!(guard.start_chain());
        assert_eq!(guard.current_depth, 1);
        
        // Trigger emergency stop
        guard.emergency_stop();
        assert!(guard.emergency_stop);
        assert_eq!(guard.current_depth, 0);
        assert!(guard.activation_chain.is_empty());
        
        // Should block new chains
        assert!(!guard.start_chain());
        
        // Reset emergency stop
        guard.reset_emergency_stop();
        assert!(!guard.emergency_stop);
        assert!(guard.start_chain()); // Should work again
    }

    #[test]
    fn test_power_interaction_enhance() {
        let registry = PowerRegistry::new();
        
        // Test enhance interaction
        if let Some(InteractionResult::Enhance(multiplier)) = 
            registry.check_interaction(PowerType::GrowQuadradius, PowerType::Sniper) {
            assert_eq!(*multiplier, 3.0);
        } else {
            panic!("Expected enhance interaction");
        }
    }

    #[test]
    fn test_power_interaction_chain_reaction() {
        let registry = PowerRegistry::new();
        
        // Test chain reaction interaction
        if let Some(InteractionResult::ChainReaction(chain_powers)) = 
            registry.check_interaction(PowerType::TeachRow, PowerType::DoublePower) {
            assert!(chain_powers.contains(&PowerType::DoublePower));
        } else {
            panic!("Expected chain reaction interaction");
        }
    }

    #[test]
    fn test_activation_depth_tracking() {
        let mut registry = PowerRegistry::new();
        
        // Test depth tracking
        assert_eq!(registry.activation_depth, 0);
        
        assert!(registry.enter_activation());
        assert_eq!(registry.activation_depth, 1);
        
        assert!(registry.enter_activation());
        assert_eq!(registry.activation_depth, 2);
        
        registry.exit_activation();
        assert_eq!(registry.activation_depth, 1);
        
        registry.reset_activation_depth();
        assert_eq!(registry.activation_depth, 0);
    }

    #[test]
    fn test_activation_depth_limit() {
        let mut registry = PowerRegistry::new();
        registry.max_chain_depth = 2;
        
        assert!(registry.enter_activation()); // depth 1
        assert!(registry.enter_activation()); // depth 2
        assert!(!registry.enter_activation()); // Should fail at depth 3
        
        assert_eq!(registry.activation_depth, 2); // Should not have increased
    }

    #[test]
    fn test_power_usage_recording() {
        let mut registry = PowerRegistry::new();
        
        let usage = PowerUsage {
            power_type: PowerType::GrowQuadradius,
            user: Entity::from_raw(1),
            target: Some(Entity::from_raw(2)),
            target_position: None,
            turn_used: 5,
            success: true,
            effects_triggered: vec![PowerType::TeachRadial],
        };
        
        registry.record_power_usage(usage.clone());
        
        // Test that the usage was recorded
        assert_eq!(registry.recent_usage.len(), 1);
        assert_eq!(registry.recent_usage[0].power_type, PowerType::GrowQuadradius);
        assert_eq!(registry.recent_usage[0].turn_used, 5);
        assert!(registry.recent_usage[0].success);
    }

    #[test]
    fn test_get_last_opponent_power() {
        let mut registry = PowerRegistry::new();
        let player_entity = Entity::from_raw(1);
        let opponent_entity = Entity::from_raw(2);
        
        // Record player power
        let player_usage = PowerUsage {
            power_type: PowerType::MoveDiagonal,
            user: player_entity,
            target: None,
            target_position: None,
            turn_used: 1,
            success: true,
            effects_triggered: vec![],
        };
        registry.record_power_usage(player_usage);
        
        // Record opponent power
        let opponent_usage = PowerUsage {
            power_type: PowerType::Shield,
            user: opponent_entity,
            target: None,
            target_position: None,
            turn_used: 2,
            success: true,
            effects_triggered: vec![],
        };
        registry.record_power_usage(opponent_usage);
        
        // Test getting last opponent power
        let last_opponent = registry.get_last_opponent_power(player_entity);
        assert!(last_opponent.is_some());
        assert_eq!(last_opponent.unwrap().power_type, PowerType::Shield);
        assert_eq!(last_opponent.unwrap().user, opponent_entity);
    }
}

/// Integration test for complete power interaction flow
#[test]
fn test_complete_power_interaction_flow() {
    let mut app = create_test_app();
    
    // Spawn test entities
    let player1_entity = app.world.spawn(create_test_piece(Player::Player1, (2, 3))).id();
    let player2_entity = app.world.spawn(create_test_piece(Player::Player2, (5, 6))).id();
    
    // Get resources
    let mut registry = app.world.resource_mut::<PowerRegistry>();
    
    // Add an active power to player2
    let shield_power = ActivePower {
        power_type: PowerType::Shield,
        source_entity: player2_entity,
        target_entity: player2_entity,
        duration_remaining: 3,
        effect_strength: 1.0,
        can_be_copied: true,
        can_be_stolen: true,
        can_be_nullified: true,
        activation_turn: 1,
    };
    registry.add_active_power(player2_entity, shield_power);
    
    // Test interaction when player1 tries to attack shielded player2
    let interaction = registry.check_interaction(PowerType::Sniper, PowerType::Shield);
    
    // Should not find a specific interaction (independent powers)
    assert!(interaction.is_none() || matches!(interaction, Some(InteractionResult::Independent)));
    
    println!("✅ Complete power interaction flow test passed");
}

#[test]
fn test_meta_power_categorization() {
    let meta_powers = vec![
        PowerType::StealPower,
        PowerType::CopyPower,
        PowerType::NullifyPower,
        PowerType::DoublePower,
        PowerType::PowerSwap,
        PowerType::PowerDrain,
        PowerType::Reflect,
        PowerType::Absorb,
        PowerType::PowerEcho,
        PowerType::PowerMemory,
    ];
    
    for power in meta_powers {
        assert_eq!(
            power.power_category(),
            crate::components::power::PowerCategory::Meta,
            "Power {:?} should be categorized as Meta",
            power
        );
    }
    
    println!("✅ Meta power categorization test passed");
}

#[test]
fn test_teaching_power_categorization() {
    let strategic_powers = vec![
        PowerType::GrowQuadradius,
        PowerType::TeachRow,
        PowerType::TeachRadial,
        PowerType::Multiply,
        PowerType::RecruitRadial,
    ];
    
    for power in strategic_powers {
        assert_eq!(
            power.power_category(),
            crate::components::power::PowerCategory::Strategic,
            "Power {:?} should be categorized as Strategic",
            power
        );
    }
    
    println!("✅ Teaching power categorization test passed");
}