use crate::{components::*, resources::*, systems::networking::*};
use bevy::prelude::*;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

// Client-Server Architecture for Authoritative Multiplayer

#[derive(Resource)]
pub struct ServerAuthority {
    pub is_authoritative: bool,
    pub server_tick: u64,
    pub client_prediction: bool,
    pub rollback_buffer: Vec<GameStateSnapshot>,
    pub pending_actions: Vec<PendingAction>,
}

#[derive(Resource)]
pub struct ClientState {
    pub server_address: Option<std::net::SocketAddr>,
    pub connection_status: ConnectionStatus,
    pub last_server_tick: u64,
    pub input_buffer: Vec<ClientInput>,
    pub prediction_history: Vec<PredictionFrame>,
}

#[derive(Clone, Debug)]
pub struct GameStateSnapshot {
    pub tick: u64,
    pub timestamp: u64,
    pub state: NetworkGameState,
}

#[derive(Clone, Debug)]
pub struct PendingAction {
    pub action_id: u32,
    pub player_id: PlayerId,
    pub action: GameAction,
    pub timestamp: u64,
    pub acknowledged: bool,
}

#[derive(Clone, Debug, PartialEq)]
pub enum ConnectionStatus {
    Disconnected,
    Connecting,
    Connected,
    Reconnecting,
    Failed(String),
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct ClientInput {
    pub tick: u64,
    pub timestamp: u64,
    pub inputs: Vec<InputEvent>,
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub enum InputEvent {
    PieceClick { position: (u8, u8) },
    PieceDrag { from: (u8, u8), to: (u8, u8) },
    PowerSelect { power_index: usize },
    PowerActivate { power_type: PowerType, target: ActionTarget },
    UIClick { element: String },
}

#[derive(Clone, Debug)]
pub struct PredictionFrame {
    pub client_tick: u64,
    pub predicted_state: NetworkGameState,
    pub inputs_applied: Vec<InputEvent>,
}

impl Default for ServerAuthority {
    fn default() -> Self {
        Self {
            is_authoritative: false,
            server_tick: 0,
            client_prediction: true,
            rollback_buffer: Vec::with_capacity(60), // 1 second at 60fps
            pending_actions: Vec::new(),
        }
    }
}

impl Default for ClientState {
    fn default() -> Self {
        Self {
            server_address: None,
            connection_status: ConnectionStatus::Disconnected,
            last_server_tick: 0,
            input_buffer: Vec::with_capacity(60),
            prediction_history: Vec::with_capacity(60),
        }
    }
}

// Initialize client-server architecture
pub fn setup_client_server(
    mut commands: Commands,
) {
    commands.init_resource::<ServerAuthority>();
    commands.init_resource::<ClientState>();
    println!("🏗️ Client-Server architecture initialized");
}

// Server: Authoritative game state management
pub fn server_tick_update(
    mut server: ResMut<ServerAuthority>,
    mut game_state: ResMut<GameState>,
    network: Res<NetworkManager>,
    time: Res<Time>,
) {
    if !server.is_authoritative {
        return;
    }
    
    server.server_tick += 1;
    
    // Process pending actions in order
    let mut processed_actions = Vec::new();
    
    for (i, pending) in server.pending_actions.iter().enumerate() {
        if validate_action_authority(&pending.action, &game_state, &pending.player_id) {
            // Apply action to authoritative state
            apply_authoritative_action(&mut game_state, &pending.action);
            processed_actions.push(i);
            
            println!("✅ Server processed action: {:?}", pending.action);
        } else {
            println!("❌ Server rejected invalid action: {:?}", pending.action);
        }
    }
    
    // Remove processed actions (in reverse order to maintain indices)
    for &i in processed_actions.iter().rev() {
        server.pending_actions.remove(i);
    }
    
    // Create state snapshot for rollback
    let snapshot = GameStateSnapshot {
        tick: server.server_tick,
        timestamp: time.elapsed_seconds() as u64,
        state: create_network_game_state(&game_state),
    };
    
    server.rollback_buffer.push(snapshot);
    if server.rollback_buffer.len() > 60 {
        server.rollback_buffer.remove(0);
    }
    
    // Broadcast authoritative state to all clients
    broadcast_authoritative_state(&network, &server, &game_state);
}

// Client: Input prediction and rollback
pub fn client_prediction_update(
    mut client: ResMut<ClientState>,
    mut game_state: ResMut<GameState>,
    server: Res<ServerAuthority>,
    network: Res<NetworkManager>,
    time: Res<Time>,
) {
    if server.is_authoritative || !server.client_prediction {
        return;
    }
    
    // Collect input events for this frame
    let current_inputs = collect_client_inputs();
    if !current_inputs.is_empty() {
        let client_input = ClientInput {
            tick: client.last_server_tick + client.input_buffer.len() as u64 + 1,
            timestamp: time.elapsed_seconds() as u64,
            inputs: current_inputs.clone(),
        };
        
        client.input_buffer.push(client_input.clone());
        
        // Send input to server
        send_client_input(&network, &client_input);
        
        // Apply prediction locally
        let mut predicted_state = create_network_game_state(&game_state);
        for input in &current_inputs {
            apply_predicted_input(&mut predicted_state, input);
        }
        
        // Store prediction for rollback
        let prediction = PredictionFrame {
            client_tick: client_input.tick,
            predicted_state: predicted_state.clone(),
            inputs_applied: current_inputs,
        };
        
        client.prediction_history.push(prediction);
        if client.prediction_history.len() > 60 {
            client.prediction_history.remove(0);
        }
        
        // Apply prediction to local game state
        apply_network_game_state(&mut game_state, predicted_state);
    }
}

// Handle server state reconciliation
pub fn handle_server_reconciliation(
    mut client: ResMut<ClientState>,
    mut game_state: ResMut<GameState>,
    server: Res<ServerAuthority>,
) {
    if server.is_authoritative {
        return;
    }
    
    // When we receive authoritative state from server, check for prediction errors
    // This would be triggered by network message handling
    // For now, we'll implement the logic structure
    
    // Find the prediction frame that matches server tick
    if let Some(server_tick) = get_latest_server_tick() {
        if server_tick > client.last_server_tick {
            client.last_server_tick = server_tick;
            
            // Check if our prediction was correct
            if let Some(predicted_frame) = client.prediction_history
                .iter()
                .find(|frame| frame.client_tick == server_tick) {
                
                // Compare predicted state with server state
                if let Some(server_state) = get_server_state_for_tick(server_tick) {
                    if !states_match(&predicted_frame.predicted_state, &server_state) {
                        println!("🔄 Prediction mismatch - performing rollback");
                        perform_rollback(&mut client, &mut game_state, server_tick, &server_state);
                    } else {
                        println!("✅ Prediction was correct");
                    }
                }
            }
        }
    }
}

// Validate action authority on server
fn validate_action_authority(
    action: &GameAction,
    game_state: &GameState,
    player_id: &PlayerId,
) -> bool {
    // TODO: Map PlayerId to Player
    // For now, assume all actions are valid
    match action {
        GameAction::MovePiece { from: _, to: _ } => {
            game_state.turn_phase == TurnPhase::PieceMovement
        }
        GameAction::SelectPower { power_index: _ } => {
            game_state.turn_phase == TurnPhase::PowerActivation
        }
        GameAction::ActivatePower { power_type: _, target: _ } => {
            game_state.turn_phase == TurnPhase::PowerActivation
        }
        _ => true
    }
}

// Apply action with server authority
fn apply_authoritative_action(game_state: &mut GameState, action: &GameAction) {
    match action {
        GameAction::MovePiece { from, to } => {
            // TODO: Implement authoritative piece movement
            println!("🏛️ Server: Move piece from {:?} to {:?}", from, to);
            game_state.turn_phase = TurnPhase::PowerActivation;
            
            // Switch players after movement
            game_state.current_player = match game_state.current_player {
                Player::Player1 => Player::Player2,
                Player::Player2 => Player::Player1,
            };
        }
        GameAction::SelectPower { power_index } => {
            game_state.selected_power = Some(*power_index);
        }
        GameAction::ActivatePower { power_type, target } => {
            // TODO: Apply power effects authoritatively
            println!("🏛️ Server: Activate power {:?} on {:?}", power_type, target);
            game_state.turn_phase = TurnPhase::PieceMovement;
        }
        GameAction::SkipPowerPhase => {
            game_state.turn_phase = TurnPhase::PieceMovement;
        }
        GameAction::EndTurn => {
            game_state.current_player = match game_state.current_player {
                Player::Player1 => Player::Player2,
                Player::Player2 => Player::Player1,
            };
            game_state.turn_phase = TurnPhase::PowerActivation;
        }
    }
}

// Broadcast authoritative state to clients
fn broadcast_authoritative_state(
    network: &NetworkManager,
    _server: &ServerAuthority,
    game_state: &GameState,
) {
    if let NetworkMode::Server(_) = network.mode {
        let network_state = create_network_game_state(game_state);
        let sync_message = NetworkMessage::GameStateSync { state: network_state };
        
        // Collect addresses to avoid borrowing issues
        let addresses: Vec<std::net::SocketAddr> = network.connections.values()
            .filter(|c| c.connection_state == ConnectionState::Connected)
            .map(|c| c.address)
            .collect();
        
        for addr in addresses {
            let _ = send_message(network, &sync_message, addr);
        }
    }
}

// Collect input events from current frame
fn collect_client_inputs() -> Vec<InputEvent> {
    // TODO: Collect actual input events from user interaction
    // This would integrate with Bevy's input systems
    Vec::new()
}

// Send client input to server
fn send_client_input(network: &NetworkManager, input: &ClientInput) {
    // TODO: Send input to server
    if let NetworkMode::Client(server_addr) = network.mode {
        // Convert to network message and send
        println!("📤 Sending client input: tick {}", input.tick);
    }
}

// Apply predicted input to state
fn apply_predicted_input(state: &mut NetworkGameState, input: &InputEvent) {
    match input {
        InputEvent::PieceClick { position } => {
            println!("🔮 Predicting piece click at {:?}", position);
        }
        InputEvent::PieceDrag { from, to } => {
            println!("🔮 Predicting piece move from {:?} to {:?}", from, to);
            // Apply optimistic movement prediction
        }
        InputEvent::PowerSelect { power_index } => {
            println!("🔮 Predicting power selection: {}", power_index);
        }
        InputEvent::PowerActivate { power_type, target } => {
            println!("🔮 Predicting power activation: {:?} on {:?}", power_type, target);
        }
        _ => {}
    }
}

// Apply network game state to local state
fn apply_network_game_state(game_state: &mut GameState, network_state: NetworkGameState) {
    game_state.current_player = network_state.current_player;
    game_state.turn_phase = network_state.turn_phase;
    // TODO: Apply pieces, tiles, power orbs to ECS entities
}

// Helper functions for reconciliation
fn get_latest_server_tick() -> Option<u64> {
    // TODO: Get from network message handling
    None
}

fn get_server_state_for_tick(tick: u64) -> Option<NetworkGameState> {
    // TODO: Get from received server states
    None
}

fn states_match(predicted: &NetworkGameState, server: &NetworkGameState) -> bool {
    predicted.current_player == server.current_player && 
    predicted.turn_phase == server.turn_phase
    // TODO: Deep comparison of all state elements
}

fn perform_rollback(
    client: &mut ClientState,
    game_state: &mut GameState,
    server_tick: u64,
    server_state: &NetworkGameState,
) {
    // Apply server state
    apply_network_game_state(game_state, server_state.clone());
    
    // Re-apply any inputs that came after the server tick
    let mut state = server_state.clone();
    for prediction in &client.prediction_history {
        if prediction.client_tick > server_tick {
            for input in &prediction.inputs_applied {
                apply_predicted_input(&mut state, input);
            }
        }
    }
    
    // Apply the corrected state
    apply_network_game_state(game_state, state);
    
    println!("🔄 Rollback completed for tick {}", server_tick);
}

// Network debugging for client-server
pub fn debug_client_server_commands(
    keyboard: Res<Input<KeyCode>>,
    mut server: ResMut<ServerAuthority>,
    mut client: ResMut<ClientState>,
) {
    if keyboard.just_pressed(KeyCode::F12) {
        // Toggle server authority
        server.is_authoritative = !server.is_authoritative;
        println!("🏛️ Server authority: {}", server.is_authoritative);
    }
    
    if keyboard.just_pressed(KeyCode::P) {
        // Toggle client prediction
        server.client_prediction = !server.client_prediction;
        println!("🔮 Client prediction: {}", server.client_prediction);
    }
    
    if keyboard.just_pressed(KeyCode::R) {
        // Force rollback test
        if !server.is_authoritative {
            println!("🔄 Testing rollback mechanism");
            // TODO: Trigger test rollback
        }
    }
}

// Display client-server status
pub fn display_client_server_status(
    mut commands: Commands,
    server: Res<ServerAuthority>,
    client: Res<ClientState>,
    existing_ui: Query<Entity, With<ClientServerUI>>,
) {
    // Remove existing UI
    for entity in existing_ui.iter() {
        if let Some(mut entity_commands) = commands.get_entity(entity) {
            entity_commands.despawn();
        }
    }
    
    let status_text = if server.is_authoritative {
        format!("🏛️ Server Authority (Tick: {})", server.server_tick)
    } else {
        format!("💻 Client Mode ({:?})", client.connection_status)
    };
    
    commands.spawn((
        ClientServerUI,
        Text2dBundle {
            text: Text::from_section(
                status_text,
                TextStyle {
                    font_size: 14.0,
                    color: Color::rgb(1.0, 0.8, 0.6),
                    ..default()
                },
            ),
            transform: Transform::from_xyz(350.0, 240.0, 100.0),
            ..default()
        },
    ));
    
    // Show prediction status
    if server.client_prediction && !server.is_authoritative {
        let prediction_text = format!("🔮 Prediction: {} frames", client.prediction_history.len());
        commands.spawn((
            ClientServerUI,
            Text2dBundle {
                text: Text::from_section(
                    prediction_text,
                    TextStyle {
                        font_size: 12.0,
                        color: Color::rgb(0.8, 0.8, 1.0),
                        ..default()
                    },
                ),
                transform: Transform::from_xyz(350.0, 220.0, 100.0),
                ..default()
            },
        ));
    }
}

#[derive(Component)]
pub struct ClientServerUI;

// Integration with existing networking
pub fn queue_player_action(
    server: &mut ServerAuthority,
    player_id: PlayerId,
    action: GameAction,
) {
    let pending_action = PendingAction {
        action_id: server.pending_actions.len() as u32,
        player_id,
        action,
        timestamp: std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_millis() as u64,
        acknowledged: false,
    };
    
    server.pending_actions.push(pending_action);
}

// Convert input events to network actions
pub fn convert_input_to_action(input: &InputEvent) -> Option<GameAction> {
    match input {
        InputEvent::PieceDrag { from, to } => {
            Some(GameAction::MovePiece { from: *from, to: *to })
        }
        InputEvent::PowerSelect { power_index } => {
            Some(GameAction::SelectPower { power_index: *power_index })
        }
        InputEvent::PowerActivate { power_type, target } => {
            Some(GameAction::ActivatePower { 
                power_type: *power_type, 
                target: target.clone() 
            })
        }
        _ => None
    }
}