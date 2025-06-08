use crate::{components::*, resources::*};
use bevy::prelude::*;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::net::{SocketAddr, UdpSocket};
use std::time::{Duration, Instant};

// Networking foundation for multiplayer Quadradius
// Implements client-server architecture with authoritative game state

#[derive(Resource)]
pub struct NetworkManager {
    pub mode: NetworkMode,
    pub socket: Option<UdpSocket>,
    pub connections: HashMap<PlayerId, NetworkConnection>,
    pub last_heartbeat: Instant,
    pub packet_buffer: Vec<u8>,
}

#[derive(Clone, Debug)]
pub enum NetworkMode {
    Local,           // Single player or local multiplayer
    Server(u16),     // Server mode with port
    Client(SocketAddr), // Client connecting to server
}

#[derive(Clone, Debug)]
pub struct NetworkConnection {
    pub address: SocketAddr,
    pub player_id: PlayerId,
    pub last_seen: Instant,
    pub ping: Duration,
    pub connection_state: ConnectionState,
}

#[derive(Clone, Debug, PartialEq)]
pub enum ConnectionState {
    Connecting,
    Connected,
    Disconnected,
    Timeout,
}

#[derive(Clone, Debug, PartialEq, Hash, Eq, Serialize, Deserialize)]
pub struct PlayerId(pub u32);

// Network protocol messages
#[derive(Serialize, Deserialize, Clone, Debug)]
pub enum NetworkMessage {
    // Connection management
    HandshakeRequest { player_name: String, version: String },
    HandshakeResponse { player_id: PlayerId, assigned_player: Player },
    Heartbeat { timestamp: u64 },
    Disconnect { reason: String },
    
    // Game state synchronization  
    GameStateSync { state: NetworkGameState },
    GameStateUpdate { delta: GameStateDelta },
    
    // Player actions
    PlayerAction { player_id: PlayerId, action: GameAction },
    ActionAck { sequence_id: u32, success: bool },
    
    // Power system
    PowerActivated { player_id: PlayerId, power: PowerType, target: ActionTarget },
    PowerCollected { player_id: PlayerId, power: PowerType, position: (u8, u8) },
    
    // Error handling
    Error { message: String, error_code: u32 },
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct NetworkGameState {
    pub current_player: Player,
    pub turn_phase: TurnPhase,
    pub board_pieces: Vec<NetworkPiece>,
    pub board_tiles: Vec<NetworkTile>,
    pub power_orbs: Vec<NetworkPowerOrb>,
    pub player_powers: HashMap<Player, Vec<PowerType>>,
    pub turn_count: u32,
    pub match_timer: f32,
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct GameStateDelta {
    pub sequence_id: u32,
    pub timestamp: u64,
    pub changes: Vec<StateChange>,
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub enum StateChange {
    PieceMoved { from: (u8, u8), to: (u8, u8) },
    PieceAdded { piece: NetworkPiece },
    PieceRemoved { position: (u8, u8) },
    TileHeightChanged { position: (u8, u8), new_height: i8 },
    PowerOrbSpawned { orb: NetworkPowerOrb },
    PowerOrbCollected { position: (u8, u8) },
    PlayerTurnChanged { new_player: Player },
    TurnPhaseChanged { new_phase: TurnPhase },
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct NetworkPiece {
    pub player: Player,
    pub position: (u8, u8),
    pub piece_type: PieceType, // For future piece variants
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct NetworkTile {
    pub coordinates: (u8, u8),
    pub height: i8,
    pub tile_type: TileType, // For future tile variants
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct NetworkPowerOrb {
    pub power_type: PowerType,
    pub position: (u8, u8),
    pub spawn_time: u64,
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub enum PieceType {
    Standard,
    // Future: King, Queen, Rook, etc.
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub enum TileType {
    Normal,
    // Future: Water, Lava, Ice, etc.
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub enum GameAction {
    MovePiece { from: (u8, u8), to: (u8, u8) },
    SelectPower { power_index: usize },
    ActivatePower { power_type: PowerType, target: ActionTarget },
    SkipPowerPhase,
    EndTurn,
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub enum ActionTarget {
    Position(u8, u8),
    Piece(u8, u8),
    Column(u8),
    Area { center: (u8, u8), radius: u8 },
    None,
}

impl Default for NetworkManager {
    fn default() -> Self {
        Self {
            mode: NetworkMode::Local,
            socket: None,
            connections: HashMap::new(),
            last_heartbeat: Instant::now(),
            packet_buffer: vec![0; 8192], // 8KB buffer
        }
    }
}

// Initialize networking system
pub fn setup_networking(
    mut commands: Commands,
) {
    commands.init_resource::<NetworkManager>();
    println!("🌐 Networking system initialized");
}

// Start server on specified port
pub fn start_server(
    mut network: ResMut<NetworkManager>,
    port: u16,
) -> Result<(), String> {
    match UdpSocket::bind(format!("0.0.0.0:{}", port)) {
        Ok(socket) => {
            socket.set_nonblocking(true)
                .map_err(|e| format!("Failed to set non-blocking: {}", e))?;
            
            network.socket = Some(socket);
            network.mode = NetworkMode::Server(port);
            
            println!("🚀 Server started on port {}", port);
            Ok(())
        }
        Err(e) => Err(format!("Failed to bind to port {}: {}", port, e))
    }
}

// Connect to server as client
pub fn connect_to_server(
    mut network: ResMut<NetworkManager>,
    server_address: SocketAddr,
) -> Result<(), String> {
    let socket = UdpSocket::bind("0.0.0.0:0")
        .map_err(|e| format!("Failed to create client socket: {}", e))?;
    
    socket.set_nonblocking(true)
        .map_err(|e| format!("Failed to set non-blocking: {}", e))?;
    
    network.socket = Some(socket);
    network.mode = NetworkMode::Client(server_address);
    
    // Send initial handshake
    let handshake = NetworkMessage::HandshakeRequest {
        player_name: "Player".to_string(),
        version: "1.0.0".to_string(),
    };
    
    send_message(&mut network, &handshake, server_address)?;
    println!("🔗 Connecting to server at {}", server_address);
    
    Ok(())
}

// Main networking update system
pub fn update_networking(
    mut network: ResMut<NetworkManager>,
    mut game_state: ResMut<GameState>,
    _time: Res<Time>,
) {
    // Create temporary buffer to avoid borrowing issues
    let mut temp_buffer = vec![0; 8192];
    let mut incoming_messages = Vec::new();
    
    if let Some(ref socket) = network.socket {
        // Receive messages using temporary buffer
        while let Ok((size, addr)) = socket.recv_from(&mut temp_buffer) {
            if let Ok(message) = bincode::deserialize::<NetworkMessage>(&temp_buffer[..size]) {
                incoming_messages.push((message, addr));
            }
        }
    }
    
    // Process messages with mutable access to network
    for (message, addr) in incoming_messages {
        handle_network_message(&mut network, &mut game_state, message, addr);
    }
    
    // Send heartbeats
    let now = Instant::now();
    if now.duration_since(network.last_heartbeat) > Duration::from_secs(5) {
        send_heartbeats(&mut network);
        network.last_heartbeat = now;
    }
    
    // Check for timeouts
    check_connection_timeouts(&mut network);
}

// Handle incoming network messages
fn handle_network_message(
    network: &mut NetworkManager,
    game_state: &mut GameState,
    message: NetworkMessage,
    from_addr: SocketAddr,
) {
    match message {
        NetworkMessage::HandshakeRequest { player_name, version } => {
            if let NetworkMode::Server(_) = network.mode {
                handle_handshake_request(network, player_name, version, from_addr);
            }
        }
        
        NetworkMessage::HandshakeResponse { player_id, assigned_player } => {
            if let NetworkMode::Client(_) = network.mode {
                handle_handshake_response(network, player_id, assigned_player, from_addr);
            }
        }
        
        NetworkMessage::Heartbeat { timestamp: _ } => {
            update_connection_heartbeat(network, from_addr);
        }
        
        NetworkMessage::PlayerAction { player_id, action } => {
            if let NetworkMode::Server(_) = network.mode {
                handle_player_action(network, game_state, player_id, action, from_addr);
            }
        }
        
        NetworkMessage::GameStateSync { state } => {
            if let NetworkMode::Client(_) = network.mode {
                apply_game_state_sync(game_state, state);
            }
        }
        
        NetworkMessage::GameStateUpdate { delta } => {
            apply_game_state_delta(game_state, delta);
        }
        
        NetworkMessage::PowerActivated { player_id, power, target } => {
            handle_power_activated(game_state, player_id, power, target);
        }
        
        NetworkMessage::Error { message, error_code } => {
            println!("❌ Network error {}: {}", error_code, message);
        }
        
        _ => {
            println!("🔍 Unhandled network message: {:?}", message);
        }
    }
}

// Server: Handle client handshake
fn handle_handshake_request(
    network: &mut NetworkManager,
    player_name: String,
    version: String,
    from_addr: SocketAddr,
) {
    // Assign player ID and slot
    let player_id = PlayerId(network.connections.len() as u32 + 1);
    let assigned_player = if network.connections.len() == 0 { 
        Player::Player1 
    } else { 
        Player::Player2 
    };
    
    // Create connection
    let connection = NetworkConnection {
        address: from_addr,
        player_id: player_id.clone(),
        last_seen: Instant::now(),
        ping: Duration::from_millis(0),
        connection_state: ConnectionState::Connected,
    };
    
    network.connections.insert(player_id.clone(), connection);
    
    // Send response
    let response = NetworkMessage::HandshakeResponse {
        player_id: player_id.clone(),
        assigned_player,
    };
    
    if let Err(e) = send_message(network, &response, from_addr) {
        println!("❌ Failed to send handshake response: {}", e);
    } else {
        println!("✅ Player '{}' connected as {:?} (ID: {:?})", player_name, assigned_player, player_id);
    }
}

// Client: Handle server handshake response
fn handle_handshake_response(
    network: &mut NetworkManager,
    player_id: PlayerId,
    assigned_player: Player,
    from_addr: SocketAddr,
) {
    let connection = NetworkConnection {
        address: from_addr,
        player_id: player_id.clone(),
        last_seen: Instant::now(),
        ping: Duration::from_millis(0),
        connection_state: ConnectionState::Connected,
    };
    
    network.connections.insert(player_id, connection);
    println!("✅ Connected to server as {:?}", assigned_player);
}

// Handle player actions on server
fn handle_player_action(
    network: &mut NetworkManager,
    game_state: &mut GameState,
    player_id: PlayerId,
    action: GameAction,
    from_addr: SocketAddr,
) {
    // Validate action authority
    if !is_valid_player_action(&player_id, &action, game_state) {
        let error = NetworkMessage::Error {
            message: "Invalid action for current player".to_string(),
            error_code: 403,
        };
        let _ = send_message(network, &error, from_addr);
        return;
    }
    
    // Apply action to game state
    let success = apply_action_to_game_state(game_state, action.clone());
    
    // Send acknowledgment
    let ack = NetworkMessage::ActionAck {
        sequence_id: 0, // TODO: Implement sequence tracking
        success,
    };
    let _ = send_message(network, &ack, from_addr);
    
    if success {
        // Broadcast state change to all clients
        broadcast_state_change(network, game_state, action);
    }
}

// Validate if player can perform action
fn is_valid_player_action(
    player_id: &PlayerId,
    action: &GameAction,
    game_state: &GameState,
) -> bool {
    // TODO: Implement proper player ID to Player mapping
    // For now, assume valid
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

// Apply action to local game state
fn apply_action_to_game_state(game_state: &mut GameState, action: GameAction) -> bool {
    match action {
        GameAction::MovePiece { from, to } => {
            // TODO: Implement move validation and application
            println!("📦 Move piece from {:?} to {:?}", from, to);
            true
        }
        GameAction::SelectPower { power_index } => {
            game_state.selected_power = Some(power_index);
            true
        }
        GameAction::ActivatePower { power_type, target } => {
            println!("⚡ Activate power {:?} on target {:?}", power_type, target);
            // TODO: Implement power activation
            true
        }
        GameAction::SkipPowerPhase => {
            game_state.turn_phase = TurnPhase::PieceMovement;
            true
        }
        GameAction::EndTurn => {
            // Switch players
            game_state.current_player = match game_state.current_player {
                Player::Player1 => Player::Player2,
                Player::Player2 => Player::Player1,
            };
            game_state.turn_phase = TurnPhase::PowerActivation;
            true
        }
    }
}

// Broadcast state changes to all clients
fn broadcast_state_change(
    network: &mut NetworkManager,
    _game_state: &GameState,
    action: GameAction,
) {
    let changes = vec![action_to_state_change(action)];
    let delta = GameStateDelta {
        sequence_id: 0, // TODO: Implement sequence tracking
        timestamp: std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_millis() as u64,
        changes,
    };
    
    let message = NetworkMessage::GameStateUpdate { delta };
    
    // Collect addresses to avoid borrowing issues
    let addresses: Vec<SocketAddr> = network.connections.values()
        .filter(|c| c.connection_state == ConnectionState::Connected)
        .map(|c| c.address)
        .collect();
    
    for addr in addresses {
        let _ = send_message(network, &message, addr);
    }
}

fn action_to_state_change(action: GameAction) -> StateChange {
    match action {
        GameAction::MovePiece { from, to } => StateChange::PieceMoved { from, to },
        GameAction::EndTurn => StateChange::PlayerTurnChanged { 
            new_player: Player::Player1 // TODO: Get actual new player
        },
        _ => StateChange::TurnPhaseChanged { 
            new_phase: TurnPhase::PieceMovement 
        },
    }
}

// Apply game state synchronization
fn apply_game_state_sync(game_state: &mut GameState, network_state: NetworkGameState) {
    game_state.current_player = network_state.current_player;
    game_state.turn_phase = network_state.turn_phase;
    // TODO: Apply pieces, tiles, power orbs
    println!("🔄 Game state synchronized from server");
}

// Apply incremental state changes
fn apply_game_state_delta(game_state: &mut GameState, delta: GameStateDelta) {
    for change in delta.changes {
        match change {
            StateChange::PlayerTurnChanged { new_player } => {
                game_state.current_player = new_player;
            }
            StateChange::TurnPhaseChanged { new_phase } => {
                game_state.turn_phase = new_phase;
            }
            StateChange::PieceMoved { from: _, to: _ } => {
                // TODO: Apply piece movement
            }
            _ => {
                // TODO: Implement other state changes
            }
        }
    }
}

fn handle_power_activated(
    game_state: &mut GameState, 
    player_id: PlayerId, 
    power: PowerType, 
    target: ActionTarget
) {
    println!("⚡ Player {:?} activated power {:?} on {:?}", player_id, power, target);
    // TODO: Apply power effects
}

// Send network message
pub fn send_message(
    network: &NetworkManager, 
    message: &NetworkMessage, 
    to_addr: SocketAddr
) -> Result<(), String> {
    if let Some(ref socket) = network.socket {
        let data = bincode::serialize(message)
            .map_err(|e| format!("Serialization error: {}", e))?;
        
        socket.send_to(&data, to_addr)
            .map_err(|e| format!("Send error: {}", e))?;
        
        Ok(())
    } else {
        Err("No socket available".to_string())
    }
}

// Send heartbeats to all connections
fn send_heartbeats(network: &mut NetworkManager) {
    let heartbeat = NetworkMessage::Heartbeat {
        timestamp: std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_millis() as u64,
    };
    
    // Collect addresses to avoid borrowing issues
    let addresses: Vec<SocketAddr> = network.connections.values()
        .filter(|c| c.connection_state == ConnectionState::Connected)
        .map(|c| c.address)
        .collect();
    
    for addr in addresses {
        let _ = send_message(network, &heartbeat, addr);
    }
}

// Update connection heartbeat timestamp
fn update_connection_heartbeat(network: &mut NetworkManager, from_addr: SocketAddr) {
    for connection in network.connections.values_mut() {
        if connection.address == from_addr {
            connection.last_seen = Instant::now();
            break;
        }
    }
}

// Check for connection timeouts
fn check_connection_timeouts(network: &mut NetworkManager) {
    let timeout_duration = Duration::from_secs(30);
    let now = Instant::now();
    
    for connection in network.connections.values_mut() {
        if now.duration_since(connection.last_seen) > timeout_duration {
            connection.connection_state = ConnectionState::Timeout;
            println!("⏰ Connection timeout: {:?}", connection.player_id);
        }
    }
}

// Network debugging commands
pub fn debug_network_commands(
    keyboard: Res<Input<KeyCode>>,
    mut network: ResMut<NetworkManager>,
) {
    if keyboard.just_pressed(KeyCode::F5) {
        // Start server on port 7777
        if let Err(e) = start_server(network.reborrow(), 7777) {
            println!("❌ Failed to start server: {}", e);
        }
    }
    
    if keyboard.just_pressed(KeyCode::F6) {
        // Connect to localhost server
        let server_addr = "127.0.0.1:7777".parse().unwrap();
        if let Err(e) = connect_to_server(network.reborrow(), server_addr) {
            println!("❌ Failed to connect to server: {}", e);
        }
    }
    
    if keyboard.just_pressed(KeyCode::F7) {
        // Display network status
        println!("\n🌐 NETWORK STATUS");
        println!("================");
        println!("Mode: {:?}", network.mode);
        println!("Connections: {}", network.connections.len());
        
        for (player_id, connection) in &network.connections {
            println!("  Player {:?}: {} ({:?})", 
                player_id, connection.address, connection.connection_state);
        }
        println!("================\n");
    }
}

// Network UI overlay
pub fn display_network_info(
    mut commands: Commands,
    network: Res<NetworkManager>,
    existing_ui: Query<Entity, With<NetworkInfoUI>>,
) {
    // Remove existing UI
    for entity in existing_ui.iter() {
        if let Some(mut entity_commands) = commands.get_entity(entity) {
            entity_commands.despawn();
        }
    }
    
    // Show network status in top-right corner
    let status_text = match &network.mode {
        NetworkMode::Local => "🏠 Local".to_string(),
        NetworkMode::Server(port) => format!("🚀 Server :{}", port),
        NetworkMode::Client(addr) => format!("🔗 Client -> {}", addr),
    };
    
    commands.spawn((
        NetworkInfoUI,
        Text2dBundle {
            text: Text::from_section(
                status_text,
                TextStyle {
                    font_size: 16.0,
                    color: Color::rgb(0.8, 0.8, 1.0),
                    ..default()
                },
            ),
            transform: Transform::from_xyz(350.0, 280.0, 100.0),
            ..default()
        },
    ));
    
    // Show connection count if server
    if let NetworkMode::Server(_) = network.mode {
        let connection_text = format!("👥 {} players", network.connections.len());
        commands.spawn((
            NetworkInfoUI,
            Text2dBundle {
                text: Text::from_section(
                    connection_text,
                    TextStyle {
                        font_size: 14.0,
                        color: Color::rgb(0.6, 0.8, 0.6),
                        ..default()
                    },
                ),
                transform: Transform::from_xyz(350.0, 260.0, 100.0),
                ..default()
            },
        ));
    }
}

#[derive(Component)]
pub struct NetworkInfoUI;

// Convert local game state to network format
pub fn create_network_game_state(game_state: &GameState) -> NetworkGameState {
    NetworkGameState {
        current_player: game_state.current_player,
        turn_phase: game_state.turn_phase.clone(),
        board_pieces: Vec::new(), // TODO: Convert from ECS entities
        board_tiles: Vec::new(),  // TODO: Convert from ECS entities  
        power_orbs: Vec::new(),   // TODO: Convert from ECS entities
        player_powers: HashMap::new(), // TODO: Convert power inventories
        turn_count: 0, // TODO: Get from turn counter
        match_timer: 0.0, // TODO: Get from match timer
    }
}

// Synchronization helper for authoritative server
pub fn sync_game_state_to_clients(
    network: Res<NetworkManager>,
    game_state: Res<GameState>,
) {
    if let NetworkMode::Server(_) = network.mode {
        if network.connections.len() > 0 {
            let network_state = create_network_game_state(&game_state);
            let sync_message = NetworkMessage::GameStateSync { state: network_state };
            
            // Collect addresses to avoid borrowing issues
            let addresses: Vec<SocketAddr> = network.connections.values()
                .filter(|c| c.connection_state == ConnectionState::Connected)
                .map(|c| c.address)
                .collect();
            
            for addr in addresses {
                let _ = send_message(&network, &sync_message, addr);
            }
        }
    }
}