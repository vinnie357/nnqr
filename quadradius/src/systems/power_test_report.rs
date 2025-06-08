use crate::{components::*, resources::*};
use bevy::prelude::*;

pub fn generate_power_test_report(keyboard: Res<Input<KeyCode>>) {
    if keyboard.just_pressed(KeyCode::F1) {
        println!("\n========== QUADRADIUS POWER STATUS REPORT ==========");
        println!("\nPHASE 2 POWERS (Core 5):");
        println!("1. Move Diagonal     - ✅ WORKING (pieces can move diagonally)");
        println!("2. Raise Column      - ⚠️  VISUAL ONLY (needs terrain height system)");
        println!("3. Lower Column      - ⚠️  VISUAL ONLY (needs terrain height system)");
        println!("4. Destroy Column    - ✅ WORKING (removes all pieces in column)");
        println!("5. Multiply          - ✅ WORKING (creates copy on adjacent tile)");

        println!("\nMOVEMENT POWERS:");
        println!("6. Teleport          - ❌ ACTIVATED BUT NO EFFECT (needs movement validation)");
        println!("7. Jump              - ❌ ACTIVATED BUT NO EFFECT (needs movement validation)");
        println!("8. Move Two          - ❌ ACTIVATED BUT NO EFFECT (needs movement validation)");
        println!("9. Knight            - ❌ ACTIVATED BUT NO EFFECT (needs movement validation)");
        println!("10. Slide            - ❌ ACTIVATED BUT NO EFFECT (needs special logic)");

        println!("\nCOMBAT POWERS:");
        println!("11. Smart Bomb       - ✅ WORKING (destroys 3x3 area)");
        println!("12. Sniper           - ✅ WORKING (eliminates any enemy piece)");
        println!("13. Assassin         - ✅ WORKING (eliminates ANY piece)");
        println!("14. Freeze           - ❌ NOT IMPLEMENTED (needs piece targeting)");
        println!("15. Shield           - ❌ NOT IMPLEMENTED (needs state tracking)");

        println!("\nOTHER POWERS:");
        println!("Most Phase 3 powers - ❌ NOT IMPLEMENTED");

        println!("\nSUMMARY:");
        println!("- 3/5 Phase 2 powers fully working");
        println!("- 3 combat powers now working (SmartBomb, Sniper, Assassin)");
        println!("- Movement powers activate but don't modify movement");
        println!("- Total working: 6/50 powers (12%)");
        println!("\n==================================================\n");
    }
}

// Test specific powers in isolation
pub fn test_individual_power(
    keyboard: Res<Input<KeyCode>>,
    commands: Commands,
    mut game_state: ResMut<GameState>,
    pieces: Query<(Entity, &GamePiece)>,
) {
    // F2 - Test Move Diagonal
    if keyboard.just_pressed(KeyCode::F2) {
        println!("\n=== TESTING MOVE DIAGONAL ===");
        // Add power to current player
        game_state.get_current_player_powers_mut().clear();
        game_state
            .get_current_player_powers_mut()
            .push(PowerType::MoveDiagonal);
        game_state.turn_phase = TurnPhase::PowerActivation;
        println!("1. Added Move Diagonal to {:?}", game_state.current_player);
        println!("2. Click the power button to activate");
        println!("3. Try dragging a piece diagonally");
    }

    // F3 - Test Destroy Column
    if keyboard.just_pressed(KeyCode::F3) {
        println!("\n=== TESTING DESTROY COLUMN ===");
        game_state.get_current_player_powers_mut().clear();
        game_state
            .get_current_player_powers_mut()
            .push(PowerType::DestroyColumn);
        game_state.turn_phase = TurnPhase::PowerActivation;
        println!("1. Added Destroy Column to {:?}", game_state.current_player);
        println!("2. Click the power button to activate");
        println!("3. Click on any column to destroy all pieces in it");
    }

    // F4 - Test Multiply
    if keyboard.just_pressed(KeyCode::F4) {
        println!("\n=== TESTING MULTIPLY ===");
        game_state.get_current_player_powers_mut().clear();
        game_state
            .get_current_player_powers_mut()
            .push(PowerType::Multiply);
        game_state.turn_phase = TurnPhase::PowerActivation;
        println!("1. Added Multiply to {:?}", game_state.current_player);
        println!("2. Click the power button to activate");
        println!("3. Click on one of your pieces to duplicate it");
    }
}
