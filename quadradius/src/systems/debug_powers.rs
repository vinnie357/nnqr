use crate::{components::*, resources::*};
use bevy::prelude::*;

// Debug system to spawn specific powers for testing
pub fn debug_spawn_powers(
    keyboard: Res<Input<KeyCode>>,
    mut game_state: ResMut<GameState>,
) {
    // Number keys 1-5 for Phase 2 powers
    if keyboard.just_pressed(KeyCode::Key1) {
        game_state.get_current_player_powers_mut().push(PowerType::MoveDiagonal);
        println!("DEBUG: Added MoveDiagonal to current player");
    }
    if keyboard.just_pressed(KeyCode::Key2) {
        game_state.get_current_player_powers_mut().push(PowerType::RaiseColumn);
        println!("DEBUG: Added RaiseColumn to current player");
    }
    if keyboard.just_pressed(KeyCode::Key3) {
        game_state.get_current_player_powers_mut().push(PowerType::LowerColumn);
        println!("DEBUG: Added LowerColumn to current player");
    }
    if keyboard.just_pressed(KeyCode::Key4) {
        game_state.get_current_player_powers_mut().push(PowerType::DestroyColumn);
        println!("DEBUG: Added DestroyColumn to current player");
    }
    if keyboard.just_pressed(KeyCode::Key5) {
        game_state.get_current_player_powers_mut().push(PowerType::Multiply);
        println!("DEBUG: Added Multiply to current player");
    }
    
    // Q-T for movement powers
    if keyboard.just_pressed(KeyCode::Q) {
        game_state.get_current_player_powers_mut().push(PowerType::Teleport);
        println!("DEBUG: Added Teleport to current player");
    }
    if keyboard.just_pressed(KeyCode::W) {
        game_state.get_current_player_powers_mut().push(PowerType::Jump);
        println!("DEBUG: Added Jump to current player");
    }
    if keyboard.just_pressed(KeyCode::E) {
        game_state.get_current_player_powers_mut().push(PowerType::MoveTwo);
        println!("DEBUG: Added MoveTwo to current player");
    }
    if keyboard.just_pressed(KeyCode::R) {
        game_state.get_current_player_powers_mut().push(PowerType::Knight);
        println!("DEBUG: Added Knight to current player");
    }
    if keyboard.just_pressed(KeyCode::T) {
        game_state.get_current_player_powers_mut().push(PowerType::Slide);
        println!("DEBUG: Added Slide to current player");
    }
    
    // A-F for combat powers
    if keyboard.just_pressed(KeyCode::A) {
        game_state.get_current_player_powers_mut().push(PowerType::SmartBomb);
        println!("DEBUG: Added SmartBomb to current player");
    }
    if keyboard.just_pressed(KeyCode::S) {
        game_state.get_current_player_powers_mut().push(PowerType::Sniper);
        println!("DEBUG: Added Sniper to current player");
    }
    if keyboard.just_pressed(KeyCode::D) {
        game_state.get_current_player_powers_mut().push(PowerType::Assassin);
        println!("DEBUG: Added Assassin to current player");
    }
    if keyboard.just_pressed(KeyCode::F) {
        game_state.get_current_player_powers_mut().push(PowerType::Freeze);
        println!("DEBUG: Added Freeze to current player");
    }
    
    // Space to force power activation phase
    if keyboard.just_pressed(KeyCode::Space) {
        game_state.turn_phase = TurnPhase::PowerActivation;
        println!("DEBUG: Forced PowerActivation phase");
    }
}

// Debug display to show current powers
pub fn debug_display_powers(
    game_state: Res<GameState>,
    mut last_display: Local<String>,
) {
    let current_display = format!(
        "Player {:?} Powers: {:?}", 
        game_state.current_player,
        game_state.get_current_player_powers().iter()
            .map(|p| p.name())
            .collect::<Vec<_>>()
    );
    
    if *last_display != current_display {
        println!("{}", current_display);
        *last_display = current_display;
    }
}