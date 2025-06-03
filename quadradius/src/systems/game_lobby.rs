use crate::{components::*, resources::*, systems::networking::*};
use bevy::prelude::*;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::time::{Duration, Instant};

// Game Lobby and Matchmaking System

#[derive(Resource)]
pub struct LobbyManager {
    pub lobbies: HashMap<LobbyId, GameLobby>,
    pub player_queue: Vec<QueuedPlayer>,
    pub matchmaking_enabled: bool,
    pub next_lobby_id: u32,
}

#[derive(Clone, Debug, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct LobbyId(pub u32);

#[derive(Clone, Debug)]
pub struct GameLobby {
    pub id: LobbyId,
    pub name: String,
    pub host: PlayerId,
    pub players: Vec<LobbyPlayer>,
    pub max_players: u8,
    pub game_settings: GameSettings,
    pub state: LobbyState,
    pub created_at: Instant,
    pub password: Option<String>,
}

#[derive(Clone, Debug)]
pub struct LobbyPlayer {
    pub player_id: PlayerId,
    pub name: String,
    pub ready: bool,
    pub assigned_slot: Option<Player>,
    pub connection_status: ConnectionState,
}

#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
pub enum LobbyState {
    Waiting,     // Waiting for players to join
    Ready,       // All players ready, can start game
    Starting,    // Game is starting
    InProgress,  // Game in progress
    Finished,    // Game completed
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct GameSettings {
    pub max_powers_per_player: u8,
    pub power_spawn_rate: f32,
    pub turn_time_limit: Option<u32>, // seconds
    pub terrain_enabled: bool,
    pub board_size: u8,
    pub win_condition: WinCondition,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub enum WinCondition {
    EliminateAll,           // Eliminate all opponent pieces
    CaptureFlag,            // Capture specific position
    TimeLimit(u32),         // Time-based victory
    PowerGoal(u8),          // Collect X powers
}

#[derive(Clone, Debug)]
pub struct QueuedPlayer {
    pub player_id: PlayerId,
    pub name: String,
    pub skill_rating: u32,
    pub preferences: MatchmakingPreferences,
    pub queue_time: Instant,
}

#[derive(Clone, Debug)]
pub struct MatchmakingPreferences {
    pub preferred_game_mode: GameMode,
    pub max_wait_time: Duration,
    pub skill_range: (u32, u32), // min, max skill rating for opponents
}

#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
pub enum GameMode {
    Casual,
    Ranked,
    Custom,
    Tournament,
}

// Lobby network messages
#[derive(Serialize, Deserialize, Clone, Debug)]
pub enum LobbyMessage {
    // Lobby management
    CreateLobby { name: String, settings: GameSettings, password: Option<String> },
    JoinLobby { lobby_id: LobbyId, password: Option<String> },
    LeaveLobby { lobby_id: LobbyId },
    LobbyList { lobbies: Vec<LobbyInfo> },
    
    // Player management
    PlayerJoined { lobby_id: LobbyId, player: LobbyPlayer },
    PlayerLeft { lobby_id: LobbyId, player_id: PlayerId },
    PlayerReady { lobby_id: LobbyId, player_id: PlayerId, ready: bool },
    
    // Game control
    StartGame { lobby_id: LobbyId },
    GameStarted { lobby_id: LobbyId, game_state: NetworkGameState },
    
    // Matchmaking
    JoinQueue { preferences: MatchmakingPreferences },
    LeaveQueue,
    MatchFound { lobby_id: LobbyId, opponent: LobbyPlayer },
    
    // Errors
    LobbyError { error: LobbyError },
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct LobbyInfo {
    pub id: LobbyId,
    pub name: String,
    pub player_count: u8,
    pub max_players: u8,
    pub has_password: bool,
    pub state: LobbyState,
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub enum LobbyError {
    LobbyNotFound,
    LobbyFull,
    IncorrectPassword,
    NotAuthorized,
    AlreadyInLobby,
    GameInProgress,
}

impl Default for LobbyManager {
    fn default() -> Self {
        Self {
            lobbies: HashMap::new(),
            player_queue: Vec::new(),
            matchmaking_enabled: true,
            next_lobby_id: 1,
        }
    }
}

impl Default for GameSettings {
    fn default() -> Self {
        Self {
            max_powers_per_player: 5,
            power_spawn_rate: 0.5,
            turn_time_limit: Some(60),
            terrain_enabled: true,
            board_size: 8,
            win_condition: WinCondition::EliminateAll,
        }
    }
}

// Initialize lobby system
pub fn setup_lobby_system(
    mut commands: Commands,
) {
    commands.init_resource::<LobbyManager>();
    println!("🏛️ Lobby system initialized");
}

// Create a new game lobby
pub fn create_lobby(
    mut lobby_manager: ResMut<LobbyManager>,
    host_id: PlayerId,
    name: String,
    settings: GameSettings,
    password: Option<String>,
) -> Result<LobbyId, LobbyError> {
    let lobby_id = LobbyId(lobby_manager.next_lobby_id);
    lobby_manager.next_lobby_id += 1;
    
    let host_player = LobbyPlayer {
        player_id: host_id.clone(),
        name: "Host".to_string(), // TODO: Get actual player name
        ready: false,
        assigned_slot: Some(Player::Player1),
        connection_status: ConnectionState::Connected,
    };
    
    let lobby = GameLobby {
        id: lobby_id.clone(),
        name,
        host: host_id,
        players: vec![host_player],
        max_players: 2, // Quadradius is 2-player
        game_settings: settings,
        state: LobbyState::Waiting,
        created_at: Instant::now(),
        password,
    };
    
    lobby_manager.lobbies.insert(lobby_id.clone(), lobby);
    println!("🏛️ Created lobby: {:?}", lobby_id);
    
    Ok(lobby_id)
}

// Join an existing lobby
pub fn join_lobby(
    mut lobby_manager: ResMut<LobbyManager>,
    lobby_id: &LobbyId,
    player_id: PlayerId,
    password: Option<String>,
) -> Result<(), LobbyError> {
    let lobby = lobby_manager.lobbies.get_mut(lobby_id)
        .ok_or(LobbyError::LobbyNotFound)?;
    
    // Check password
    if let Some(ref lobby_password) = lobby.password {
        if password.as_ref() != Some(lobby_password) {
            return Err(LobbyError::IncorrectPassword);
        }
    }
    
    // Check if lobby is full
    if lobby.players.len() >= lobby.max_players as usize {
        return Err(LobbyError::LobbyFull);
    }
    
    // Check if game already started
    if lobby.state == LobbyState::InProgress {
        return Err(LobbyError::GameInProgress);
    }
    
    // Check if player already in lobby
    if lobby.players.iter().any(|p| p.player_id == player_id) {
        return Err(LobbyError::AlreadyInLobby);
    }
    
    let new_player = LobbyPlayer {
        player_id: player_id.clone(),
        name: "Player".to_string(), // TODO: Get actual player name
        ready: false,
        assigned_slot: Some(Player::Player2),
        connection_status: ConnectionState::Connected,
    };
    
    lobby.players.push(new_player);
    println!("👥 Player {:?} joined lobby {:?}", player_id, lobby_id);
    
    Ok(())
}

// Leave a lobby
pub fn leave_lobby(
    mut lobby_manager: ResMut<LobbyManager>,
    lobby_id: &LobbyId,
    player_id: &PlayerId,
) -> Result<(), LobbyError> {
    let lobby = lobby_manager.lobbies.get_mut(lobby_id)
        .ok_or(LobbyError::LobbyNotFound)?;
    
    let player_index = lobby.players.iter()
        .position(|p| p.player_id == *player_id)
        .ok_or(LobbyError::NotAuthorized)?;
    
    lobby.players.remove(player_index);
    
    // If host left, transfer ownership or close lobby
    if lobby.host == *player_id {
        if let Some(new_host) = lobby.players.first() {
            lobby.host = new_host.player_id.clone();
            println!("👑 Transferred lobby host to {:?}", new_host.player_id);
        } else {
            // Lobby is empty, remove it
            lobby_manager.lobbies.remove(lobby_id);
            println!("🗑️ Removed empty lobby {:?}", lobby_id);
            return Ok(());
        }
    }
    
    println!("👋 Player {:?} left lobby {:?}", player_id, lobby_id);
    Ok(())
}

// Set player ready status
pub fn set_player_ready(
    mut lobby_manager: ResMut<LobbyManager>,
    lobby_id: &LobbyId,
    player_id: &PlayerId,
    ready: bool,
) -> Result<(), LobbyError> {
    let lobby = lobby_manager.lobbies.get_mut(lobby_id)
        .ok_or(LobbyError::LobbyNotFound)?;
    
    let player = lobby.players.iter_mut()
        .find(|p| p.player_id == *player_id)
        .ok_or(LobbyError::NotAuthorized)?;
    
    player.ready = ready;
    
    // Check if all players are ready
    let all_ready = lobby.players.len() >= 2 && 
                   lobby.players.iter().all(|p| p.ready);
    
    if all_ready && lobby.state == LobbyState::Waiting {
        lobby.state = LobbyState::Ready;
        println!("✅ Lobby {:?} is ready to start", lobby_id);
    } else if !all_ready && lobby.state == LobbyState::Ready {
        lobby.state = LobbyState::Waiting;
        println!("⏳ Lobby {:?} waiting for players", lobby_id);
    }
    
    Ok(())
}

// Start game in lobby
pub fn start_lobby_game(
    mut lobby_manager: ResMut<LobbyManager>,
    lobby_id: &LobbyId,
    player_id: &PlayerId,
) -> Result<NetworkGameState, LobbyError> {
    let lobby = lobby_manager.lobbies.get_mut(lobby_id)
        .ok_or(LobbyError::LobbyNotFound)?;
    
    // Only host can start game
    if lobby.host != *player_id {
        return Err(LobbyError::NotAuthorized);
    }
    
    // Check if lobby is ready
    if lobby.state != LobbyState::Ready {
        return Err(LobbyError::GameInProgress);
    }
    
    lobby.state = LobbyState::Starting;
    
    // Create initial game state
    let initial_state = create_initial_game_state(&lobby.game_settings);
    
    lobby.state = LobbyState::InProgress;
    println!("🚀 Started game in lobby {:?}", lobby_id);
    
    Ok(initial_state)
}

// Matchmaking system
pub fn update_matchmaking(
    mut lobby_manager: ResMut<LobbyManager>,
    time: Res<Time>,
) {
    if !lobby_manager.matchmaking_enabled || lobby_manager.player_queue.len() < 2 {
        return;
    }
    
    let mut matched_pairs = Vec::new();
    let current_time = Instant::now();
    
    // Simple matchmaking: find players with compatible skill ratings
    for i in 0..lobby_manager.player_queue.len() {
        if matched_pairs.iter().any(|(a, b)| *a == i || *b == i) {
            continue; // Already matched
        }
        
        let player1 = &lobby_manager.player_queue[i];
        
        for j in (i + 1)..lobby_manager.player_queue.len() {
            if matched_pairs.iter().any(|(a, b)| *a == j || *b == j) {
                continue; // Already matched
            }
            
            let player2 = &lobby_manager.player_queue[j];
            
            // Check skill compatibility
            let skill_diff = (player1.skill_rating as i32 - player2.skill_rating as i32).abs();
            let max_skill_diff = 200; // Allow 200 rating difference
            
            // Increase tolerance over time
            let wait_time_bonus = current_time.duration_since(player1.queue_time).as_secs() * 10;
            let adjusted_max_diff = max_skill_diff + wait_time_bonus as i32;
            
            if skill_diff <= adjusted_max_diff {
                matched_pairs.push((i, j));
                break;
            }
        }
    }
    
    // Create lobbies for matched pairs
    for (i, j) in matched_pairs.iter().rev() { // Reverse to maintain indices
        let player1 = lobby_manager.player_queue.remove(*i);
        let player2 = lobby_manager.player_queue.remove(*j - 1); // Adjust index
        
        create_matchmade_lobby(&mut lobby_manager, player1, player2);
    }
}

// Create lobby for matched players
fn create_matchmade_lobby(
    lobby_manager: &mut LobbyManager,
    player1: QueuedPlayer,
    player2: QueuedPlayer,
) {
    let lobby_name = format!("Match: {} vs {}", player1.name, player2.name);
    let settings = GameSettings::default(); // Use default settings for matchmaking
    
    let lobby_id = LobbyId(lobby_manager.next_lobby_id);
    lobby_manager.next_lobby_id += 1;
    
    let lobby_player1 = LobbyPlayer {
        player_id: player1.player_id.clone(),
        name: player1.name,
        ready: true, // Auto-ready for matchmade games
        assigned_slot: Some(Player::Player1),
        connection_status: ConnectionState::Connected,
    };
    
    let lobby_player2 = LobbyPlayer {
        player_id: player2.player_id.clone(),
        name: player2.name,
        ready: true, // Auto-ready for matchmade games
        assigned_slot: Some(Player::Player2),
        connection_status: ConnectionState::Connected,
    };
    
    let lobby = GameLobby {
        id: lobby_id.clone(),
        name: lobby_name,
        host: player1.player_id,
        players: vec![lobby_player1, lobby_player2],
        max_players: 2,
        game_settings: settings,
        state: LobbyState::Ready,
        created_at: Instant::now(),
        password: None,
    };
    
    lobby_manager.lobbies.insert(lobby_id.clone(), lobby);
    println!("🎯 Created matchmade lobby: {:?}", lobby_id);
}

// Handle lobby network messages
pub fn handle_lobby_message(
    mut lobby_manager: ResMut<LobbyManager>,
    message: LobbyMessage,
    from_player: PlayerId,
) -> Option<LobbyMessage> {
    match message {
        LobbyMessage::CreateLobby { name, settings, password } => {
            match create_lobby(&mut lobby_manager, from_player, name, settings, password) {
                Ok(lobby_id) => {
                    if let Some(lobby) = lobby_manager.lobbies.get(&lobby_id) {
                        Some(LobbyMessage::PlayerJoined { 
                            lobby_id, 
                            player: lobby.players[0].clone() 
                        })
                    } else {
                        None
                    }
                }
                Err(error) => Some(LobbyMessage::LobbyError { error })
            }
        }
        
        LobbyMessage::JoinLobby { lobby_id, password } => {
            match join_lobby(&mut lobby_manager, &lobby_id, from_player, password) {
                Ok(()) => {
                    if let Some(lobby) = lobby_manager.lobbies.get(&lobby_id) {
                        if let Some(player) = lobby.players.iter().find(|p| p.player_id == from_player) {
                            Some(LobbyMessage::PlayerJoined { 
                                lobby_id, 
                                player: player.clone() 
                            })
                        } else {
                            None
                        }
                    } else {
                        None
                    }
                }
                Err(error) => Some(LobbyMessage::LobbyError { error })
            }
        }
        
        LobbyMessage::PlayerReady { lobby_id, player_id, ready } => {
            match set_player_ready(&mut lobby_manager, &lobby_id, &player_id, ready) {
                Ok(()) => Some(LobbyMessage::PlayerReady { lobby_id, player_id, ready }),
                Err(error) => Some(LobbyMessage::LobbyError { error })
            }
        }
        
        LobbyMessage::JoinQueue { preferences } => {
            let queued_player = QueuedPlayer {
                player_id: from_player,
                name: "Player".to_string(), // TODO: Get actual name
                skill_rating: 1000, // TODO: Get actual rating
                preferences,
                queue_time: Instant::now(),
            };
            
            lobby_manager.player_queue.push(queued_player);
            println!("🎯 Player {:?} joined matchmaking queue", from_player);
            None
        }
        
        LobbyMessage::LeaveQueue => {
            lobby_manager.player_queue.retain(|p| p.player_id != from_player);
            println!("🚪 Player {:?} left matchmaking queue", from_player);
            None
        }
        
        _ => {
            println!("🔍 Unhandled lobby message: {:?}", message);
            None
        }
    }
}

// Get list of public lobbies
pub fn get_lobby_list(lobby_manager: &LobbyManager) -> Vec<LobbyInfo> {
    lobby_manager.lobbies.values()
        .filter(|lobby| lobby.password.is_none()) // Only public lobbies
        .map(|lobby| LobbyInfo {
            id: lobby.id.clone(),
            name: lobby.name.clone(),
            player_count: lobby.players.len() as u8,
            max_players: lobby.max_players,
            has_password: lobby.password.is_some(),
            state: lobby.state.clone(),
        })
        .collect()
}

// Create initial game state for lobby
fn create_initial_game_state(settings: &GameSettings) -> NetworkGameState {
    NetworkGameState {
        current_player: Player::Player1,
        turn_phase: TurnPhase::PowerActivation,
        board_pieces: Vec::new(), // TODO: Create initial piece setup
        board_tiles: Vec::new(),  // TODO: Create board tiles
        power_orbs: Vec::new(),
        player_powers: HashMap::new(),
        turn_count: 1,
        match_timer: 0.0,
    }
}

// Lobby UI debug commands
pub fn debug_lobby_commands(
    keyboard: Res<Input<KeyCode>>,
    mut lobby_manager: ResMut<LobbyManager>,
) {
    if keyboard.just_pressed(KeyCode::L) {
        // Create test lobby
        let test_player = PlayerId(999);
        let settings = GameSettings::default();
        
        if let Ok(lobby_id) = create_lobby(&mut lobby_manager, test_player, 
                                         "Test Lobby".to_string(), settings, None) {
            println!("🧪 Created test lobby: {:?}", lobby_id);
        }
    }
    
    if keyboard.just_pressed(KeyCode::M) {
        // Toggle matchmaking
        lobby_manager.matchmaking_enabled = !lobby_manager.matchmaking_enabled;
        println!("🎯 Matchmaking: {}", lobby_manager.matchmaking_enabled);
    }
    
    if keyboard.just_pressed(KeyCode::Q) {
        // Show queue status
        println!("\n🎯 MATCHMAKING QUEUE");
        println!("====================");
        println!("Players in queue: {}", lobby_manager.player_queue.len());
        for (i, player) in lobby_manager.player_queue.iter().enumerate() {
            println!("  {}. {} (Rating: {}, Wait: {}s)", 
                i + 1, player.name, player.skill_rating,
                Instant::now().duration_since(player.queue_time).as_secs());
        }
        println!("====================\n");
    }
}