use crate::components::*;
use crate::resources::*;

#[test]
fn test_power_type_creation() {
    let power = PowerType::MoveDiagonal;
    assert_eq!(power.name(), "Move Diagonal");

    let power2 = PowerType::RaiseColumn;
    assert_eq!(power2.name(), "Raise Column");
}

#[test]
fn test_power_orb_component() {
    let orb = PowerOrb {
        power_type: PowerType::Multiply,
        board_position: (3, 4),
    };

    assert_eq!(orb.power_type, PowerType::Multiply);
    assert_eq!(orb.board_position, (3, 4));
}

#[test]
fn test_game_state_power_inventory() {
    let mut game_state = GameState::default();

    // Initially empty
    assert!(game_state.player1_powers.is_empty());
    assert!(game_state.player2_powers.is_empty());

    // Add powers to player 1
    game_state.player1_powers.push(PowerType::MoveDiagonal);
    game_state.player1_powers.push(PowerType::DestroyColumn);

    assert_eq!(game_state.player1_powers.len(), 2);
    assert_eq!(game_state.player1_powers[0], PowerType::MoveDiagonal);
    assert_eq!(game_state.player1_powers[1], PowerType::DestroyColumn);

    // Player 2 still empty
    assert!(game_state.player2_powers.is_empty());
}

#[test]
fn test_get_current_player_powers() {
    let mut game_state = GameState::default();

    // Add power to player 1
    game_state.player1_powers.push(PowerType::RaiseColumn);

    // Current player is Player 1
    let powers = game_state.get_current_player_powers();
    assert_eq!(powers.len(), 1);
    assert_eq!(powers[0], PowerType::RaiseColumn);

    // Switch to Player 2
    game_state.current_player = Player::Player2;
    let powers = game_state.get_current_player_powers();
    assert!(powers.is_empty());

    // Add power to player 2
    game_state.player2_powers.push(PowerType::LowerColumn);
    let powers = game_state.get_current_player_powers();
    assert_eq!(powers.len(), 1);
    assert_eq!(powers[0], PowerType::LowerColumn);
}

#[test]
fn test_power_type_random() {
    // Test that random() returns valid power types
    for _ in 0..20 {
        let power = PowerType::random();
        match power {
            PowerType::MoveDiagonal
            | PowerType::RaiseColumn
            | PowerType::LowerColumn
            | PowerType::DestroyColumn
            | PowerType::Multiply
            | PowerType::Teleport
            | PowerType::Jump
            | PowerType::MoveTwo
            | PowerType::Knight
            | PowerType::Swap
            | PowerType::Push
            | PowerType::Pull
            | PowerType::Slide
            | PowerType::MoveTwice
            | PowerType::Leap
            | PowerType::SmartBomb
            | PowerType::Sniper
            | PowerType::Shield
            | PowerType::Invisible
            | PowerType::Recruit
            | PowerType::Freeze
            | PowerType::Poison
            | PowerType::Explode
            | PowerType::Assassin
            | PowerType::Resurrect
            | PowerType::RaiseArea
            | PowerType::LowerArea
            | PowerType::CreateWall
            | PowerType::DestroyWall
            | PowerType::Rotate
            | PowerType::Shuffle
            | PowerType::Earthquake
            | PowerType::Bridge
            | PowerType::Pit
            | PowerType::Terraform
            | PowerType::StealPower
            | PowerType::CopyPower
            | PowerType::NullifyPower
            | PowerType::DoublePower
            | PowerType::RandomPower
            | PowerType::PowerSwap
            | PowerType::PowerGift
            | PowerType::PowerDrain
            | PowerType::Reflect
            | PowerType::Absorb => {
                // Valid power type
            }
        }
    }
}

#[test]
fn test_power_colors() {
    assert_ne!(
        PowerType::MoveDiagonal.color(),
        PowerType::RaiseColumn.color()
    );
    assert_ne!(
        PowerType::LowerColumn.color(),
        PowerType::DestroyColumn.color()
    );
    assert_ne!(PowerType::Multiply.color(), PowerType::MoveDiagonal.color());
}
