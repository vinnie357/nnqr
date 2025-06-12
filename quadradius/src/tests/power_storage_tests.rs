use crate::components::{GamePiece, Player, PowerType};
use crate::resources::game_state::GameState;
use bevy::prelude::*;

/// Component for per-piece power inventory
#[derive(Component, Clone, Debug, PartialEq, serde::Serialize, serde::Deserialize, Default)]
pub struct PowerInventory {
    pub powers: Vec<PowerType>,
}

impl PowerInventory {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn add_power(&mut self, power: PowerType) {
        self.powers.push(power);
    }

    pub fn remove_power(&mut self, index: usize) -> Option<PowerType> {
        if index < self.powers.len() {
            Some(self.powers.remove(index))
        } else {
            None
        }
    }

    pub fn has_power(&self, power: &PowerType) -> bool {
        self.powers.contains(power)
    }

    pub fn power_count(&self) -> usize {
        self.powers.len()
    }

    pub fn is_empty(&self) -> bool {
        self.powers.is_empty()
    }

    pub fn get_powers(&self) -> &Vec<PowerType> {
        &self.powers
    }
}

#[test]
fn test_power_inventory_creation() {
    let inventory = PowerInventory::new();
    assert!(inventory.is_empty());
    assert_eq!(inventory.power_count(), 0);
}

#[test]
fn test_power_inventory_add_power() {
    let mut inventory = PowerInventory::new();

    inventory.add_power(PowerType::MoveDiagonal);
    assert_eq!(inventory.power_count(), 1);
    assert!(inventory.has_power(&PowerType::MoveDiagonal));
    assert!(!inventory.is_empty());

    inventory.add_power(PowerType::Teleport);
    assert_eq!(inventory.power_count(), 2);
    assert!(inventory.has_power(&PowerType::Teleport));
}

#[test]
fn test_power_inventory_remove_power() {
    let mut inventory = PowerInventory::new();
    inventory.add_power(PowerType::MoveDiagonal);
    inventory.add_power(PowerType::Teleport);

    let removed = inventory.remove_power(0);
    assert_eq!(removed, Some(PowerType::MoveDiagonal));
    assert_eq!(inventory.power_count(), 1);
    assert!(!inventory.has_power(&PowerType::MoveDiagonal));
    assert!(inventory.has_power(&PowerType::Teleport));

    // Test invalid index
    let invalid_remove = inventory.remove_power(10);
    assert_eq!(invalid_remove, None);
    assert_eq!(inventory.power_count(), 1);
}

#[test]
fn test_power_inventory_has_power() {
    let mut inventory = PowerInventory::new();
    inventory.add_power(PowerType::MoveDiagonal);

    assert!(inventory.has_power(&PowerType::MoveDiagonal));
    assert!(!inventory.has_power(&PowerType::Teleport));
}

#[test]
fn test_power_inventory_get_powers() {
    let mut inventory = PowerInventory::new();
    inventory.add_power(PowerType::MoveDiagonal);
    inventory.add_power(PowerType::Teleport);

    let powers = inventory.get_powers();
    assert_eq!(powers.len(), 2);
    assert_eq!(powers[0], PowerType::MoveDiagonal);
    assert_eq!(powers[1], PowerType::Teleport);
}

#[test]
fn test_piece_with_power_inventory() {
    let mut app = App::new();

    // Spawn a piece with power inventory
    let piece_entity = app
        .world
        .spawn((
            GamePiece {
                player: Player::Player1,
                board_position: (0, 0),
            },
            PowerInventory::new(),
        ))
        .id();

    // Verify the piece has an empty inventory
    let inventory = app
        .world
        .entity(piece_entity)
        .get::<PowerInventory>()
        .unwrap();
    assert!(inventory.is_empty());
}

#[test]
fn test_multiple_pieces_independent_inventories() {
    let mut app = App::new();

    // Spawn two pieces with separate inventories
    let piece1 = app
        .world
        .spawn((
            GamePiece {
                player: Player::Player1,
                board_position: (0, 0),
            },
            PowerInventory::new(),
        ))
        .id();

    let piece2 = app
        .world
        .spawn((
            GamePiece {
                player: Player::Player1,
                board_position: (1, 0),
            },
            PowerInventory::new(),
        ))
        .id();

    // Add different powers to each piece
    {
        let mut entity_mut = app.world.entity_mut(piece1);
        let mut inventory1 = entity_mut.get_mut::<PowerInventory>().unwrap();
        inventory1.add_power(PowerType::MoveDiagonal);
    }

    {
        let mut entity_mut = app.world.entity_mut(piece2);
        let mut inventory2 = entity_mut.get_mut::<PowerInventory>().unwrap();
        inventory2.add_power(PowerType::Teleport);
    }

    // Verify inventories are independent
    let inventory1 = app.world.entity(piece1).get::<PowerInventory>().unwrap();
    let inventory2 = app.world.entity(piece2).get::<PowerInventory>().unwrap();

    assert!(inventory1.has_power(&PowerType::MoveDiagonal));
    assert!(!inventory1.has_power(&PowerType::Teleport));

    assert!(inventory2.has_power(&PowerType::Teleport));
    assert!(!inventory2.has_power(&PowerType::MoveDiagonal));
}

#[test]
fn test_power_collection_adds_to_piece_inventory() {
    let mut app = App::new();

    // Spawn a piece
    let piece_entity = app
        .world
        .spawn((
            GamePiece {
                player: Player::Player1,
                board_position: (5, 5),
            },
            PowerInventory::new(),
        ))
        .id();

    // Simulate power collection
    {
        let mut entity_mut = app.world.entity_mut(piece_entity);
        let mut inventory = entity_mut.get_mut::<PowerInventory>().unwrap();
        inventory.add_power(PowerType::MoveDiagonal);
    }

    // Verify power was added to the specific piece
    let inventory = app
        .world
        .entity(piece_entity)
        .get::<PowerInventory>()
        .unwrap();
    assert_eq!(inventory.power_count(), 1);
    assert!(inventory.has_power(&PowerType::MoveDiagonal));
}

#[test]
fn test_power_activation_uses_piece_inventory() {
    let mut app = App::new();

    // Spawn a piece with a power
    let piece_entity = app
        .world
        .spawn((
            GamePiece {
                player: Player::Player1,
                board_position: (3, 3),
            },
            PowerInventory {
                powers: vec![PowerType::MoveDiagonal, PowerType::Teleport],
            },
        ))
        .id();

    // Simulate power activation (remove power from inventory)
    {
        let mut entity_mut = app.world.entity_mut(piece_entity);
        let mut inventory = entity_mut.get_mut::<PowerInventory>().unwrap();
        let activated_power = inventory.remove_power(0);
        assert_eq!(activated_power, Some(PowerType::MoveDiagonal));
    }

    // Verify power was removed and other power remains
    let inventory = app
        .world
        .entity(piece_entity)
        .get::<PowerInventory>()
        .unwrap();
    assert_eq!(inventory.power_count(), 1);
    assert!(!inventory.has_power(&PowerType::MoveDiagonal));
    assert!(inventory.has_power(&PowerType::Teleport));
}

#[test]
fn test_selected_piece_power_display() {
    let mut app = App::new();

    // Create a game state
    app.insert_resource(GameState {
        current_player: Player::Player1,
        player1_powers: Vec::new(), // This should become unused
        player2_powers: Vec::new(), // This should become unused
        turn_phase: crate::resources::game_state::TurnPhase::PowerActivation,
        selected_power: None,
    });

    // Spawn pieces with different powers
    let piece1 = app
        .world
        .spawn((
            GamePiece {
                player: Player::Player1,
                board_position: (0, 0),
            },
            PowerInventory {
                powers: vec![PowerType::MoveDiagonal],
            },
        ))
        .id();

    let piece2 = app
        .world
        .spawn((
            GamePiece {
                player: Player::Player1,
                board_position: (1, 0),
            },
            PowerInventory {
                powers: vec![PowerType::Teleport, PowerType::Jump],
            },
        ))
        .id();

    // Test getting powers for specific piece
    let inventory1 = app.world.entity(piece1).get::<PowerInventory>().unwrap();
    let inventory2 = app.world.entity(piece2).get::<PowerInventory>().unwrap();

    assert_eq!(inventory1.get_powers(), &vec![PowerType::MoveDiagonal]);
    assert_eq!(
        inventory2.get_powers(),
        &vec![PowerType::Teleport, PowerType::Jump]
    );
}

#[test]
fn test_migration_from_player_based_storage() {
    // Test that we can migrate from the old per-player storage to per-piece storage
    let mut app = App::new();

    // Simulate old game state with player-based powers
    let old_game_state = GameState {
        current_player: Player::Player1,
        player1_powers: vec![PowerType::MoveDiagonal, PowerType::Teleport],
        player2_powers: vec![PowerType::Jump],
        turn_phase: crate::resources::game_state::TurnPhase::PowerActivation,
        selected_power: None,
    };

    app.insert_resource(old_game_state);

    // Spawn pieces that should receive migrated powers
    let p1_piece1 = app
        .world
        .spawn((
            GamePiece {
                player: Player::Player1,
                board_position: (0, 0),
            },
            PowerInventory::new(),
        ))
        .id();

    let p1_piece2 = app
        .world
        .spawn((
            GamePiece {
                player: Player::Player1,
                board_position: (1, 0),
            },
            PowerInventory::new(),
        ))
        .id();

    let p2_piece1 = app
        .world
        .spawn((
            GamePiece {
                player: Player::Player2,
                board_position: (0, 7),
            },
            PowerInventory::new(),
        ))
        .id();

    // Simulate migration process (this would be done by a migration system)
    let game_state = app.world.resource::<GameState>();
    let p1_powers = game_state.player1_powers.clone();
    let p2_powers = game_state.player2_powers.clone();

    // Distribute Player 1 powers to first piece
    if !p1_powers.is_empty() {
        let mut entity_mut = app.world.entity_mut(p1_piece1);
        let mut inventory = entity_mut.get_mut::<PowerInventory>().unwrap();
        for power in p1_powers {
            inventory.add_power(power);
        }
    }

    // Distribute Player 2 powers to first piece
    if !p2_powers.is_empty() {
        let mut entity_mut = app.world.entity_mut(p2_piece1);
        let mut inventory = entity_mut.get_mut::<PowerInventory>().unwrap();
        for power in p2_powers {
            inventory.add_power(power);
        }
    }

    // Verify migration worked
    let p1_inventory = app.world.entity(p1_piece1).get::<PowerInventory>().unwrap();
    let p2_inventory = app.world.entity(p2_piece1).get::<PowerInventory>().unwrap();

    assert_eq!(p1_inventory.power_count(), 2);
    assert!(p1_inventory.has_power(&PowerType::MoveDiagonal));
    assert!(p1_inventory.has_power(&PowerType::Teleport));

    assert_eq!(p2_inventory.power_count(), 1);
    assert!(p2_inventory.has_power(&PowerType::Jump));
}

#[test]
fn test_power_inventory_serialization() {
    // Test that PowerInventory can be serialized for save games
    let inventory = PowerInventory {
        powers: vec![PowerType::MoveDiagonal, PowerType::Teleport],
    };

    let serialized = bincode::serialize(&inventory).unwrap();
    let deserialized: PowerInventory = bincode::deserialize(&serialized).unwrap();

    assert_eq!(inventory, deserialized);
}

#[test]
fn test_piece_selection_affects_power_ui() {
    let mut app = App::new();

    // Add a selected piece marker component
    #[derive(Component)]
    struct SelectedPiece;

    // Spawn pieces with different powers
    let piece1 = app
        .world
        .spawn((
            GamePiece {
                player: Player::Player1,
                board_position: (0, 0),
            },
            PowerInventory {
                powers: vec![PowerType::MoveDiagonal],
            },
        ))
        .id();

    let piece2 = app
        .world
        .spawn((
            GamePiece {
                player: Player::Player1,
                board_position: (1, 0),
            },
            PowerInventory {
                powers: vec![PowerType::Teleport, PowerType::Jump],
            },
            SelectedPiece, // This piece is selected
        ))
        .id();

    // Query for selected piece powers (simulating UI system)
    let mut selected_powers = Vec::new();
    for (inventory, _) in app
        .world
        .query::<(&PowerInventory, &SelectedPiece)>()
        .iter(&app.world)
    {
        selected_powers = inventory.get_powers().clone();
    }

    // Should show powers from selected piece only
    assert_eq!(selected_powers.len(), 2);
    assert_eq!(selected_powers[0], PowerType::Teleport);
    assert_eq!(selected_powers[1], PowerType::Jump);
}

#[test]
fn test_power_inventory_edge_cases() {
    let mut inventory = PowerInventory::new();

    // Test removing from empty inventory
    assert_eq!(inventory.remove_power(0), None);

    // Test duplicate powers
    inventory.add_power(PowerType::MoveDiagonal);
    inventory.add_power(PowerType::MoveDiagonal);
    assert_eq!(inventory.power_count(), 2);

    // Test removing all powers
    inventory.remove_power(0);
    inventory.remove_power(0);
    assert!(inventory.is_empty());
}
