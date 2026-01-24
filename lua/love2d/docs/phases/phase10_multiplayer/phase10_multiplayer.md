# Phase 10: Network Multiplayer

## Overview

Implement LAN multiplayer with lobby system using Love2D server.

**Estimated Sessions**: 4-5
**New Tests**: ~70

## Architecture

### Two-Server Strategy

```
┌─────────────────────────────────────────────────────────────────────┐
│                        LOVE2D CLIENT                                 │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  Connects via:                                               │    │
│  │  • TCP (luasocket) → Love2D LAN Server (this phase)          │    │
│  │  • WebSocket (löve-ws) → Elixir/Phoenix Server (future)      │    │
│  └─────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
          │
          │ TCP/LAN
          ▼
┌─────────────────────┐
│  LOVE2D SERVER      │
│                     │
│  • Headless default │
│  • --gui for admin  │
│  • File persistence │
│  • Config file      │
│  • LAN/Local        │
└─────────────────────┘
```

### Server Modes

```bash
# Headless mode (default) - for containers, LAN servers
love server/

# GUI mode - for local dev, monitoring
love server/ --gui
```

---

## Phase 10A: Love2D Server (~2 sessions, ~30 tests)

### Server Application Structure

```
lua/love2d/
├── server/
│   ├── main.lua           # Server entry point
│   ├── conf.lua           # Server Love2D config
│   ├── server.lua         # Core server logic
│   ├── lobby.lua          # Lobby management
│   ├── session.lua        # Player sessions
│   ├── game_session.lua   # Active game management
│   └── persistence.lua    # File-based save/load
├── server_config.lua      # Config file
└── spec/
    ├── server_spec.lua
    ├── lobby_spec.lua
    └── session_spec.lua
```

### 10A.1 Server Core

**Tests** (`spec/server_spec.lua`):
1. `Server.create(config)` initializes server state
2. `Server.start(server)` begins listening
3. `Server.stop(server)` stops cleanly
4. `Server.handleMessage(server, client, message)` routes messages
5. Server rejects invalid messages
6. Server handles client disconnect

**Implementation** (`server/server.lua`):
```lua
local Server = {}

function Server.create(config)
    return {
        port = config.port or 7777,
        maxGames = config.maxGames or 10,
        clients = {},
        lobby = Lobby.create(),
        games = {},
    }
end

function Server.start(server)
function Server.stop(server)
function Server.handleMessage(server, client, message)
```

### 10A.2 Lobby System

**Tests** (`spec/lobby_spec.lua`):
1. `Lobby.create()` returns empty lobby state
2. `Lobby.addPlayer(lobby, playerId, name)` adds player
3. `Lobby.removePlayer(lobby, playerId)` removes player
4. `Lobby.createGame(lobby, playerId, gameName)` creates game
5. `Lobby.joinGame(lobby, playerId, gameId)` joins existing game
6. `Lobby.leaveGame(lobby, playerId)` leaves game
7. `Lobby.listGames(lobby)` returns available games
8. Rejects duplicate player names
9. Rejects joining full games

**Implementation** (`server/lobby.lua`):
```lua
local Lobby = {}

function Lobby.create()
function Lobby.addPlayer(lobby, playerId, name)
function Lobby.removePlayer(lobby, playerId)
function Lobby.createGame(lobby, playerId, gameName)
function Lobby.joinGame(lobby, playerId, gameId)
function Lobby.leaveGame(lobby, playerId)
function Lobby.listGames(lobby)
```

### 10A.3 Game Session

**Tests** (`spec/game_session_spec.lua`):
1. `GameSession.create(gameId, player1Id)` creates waiting game
2. `GameSession.addPlayer(game, player2Id)` starts game
3. `GameSession.handleMove(game, playerId, move)` validates and applies
4. `GameSession.handlePower(game, playerId, power)` validates and applies
5. Rejects moves from wrong player
6. Rejects invalid moves
7. Detects game over

### 10A.4 Persistence

**Tests** (`spec/persistence_spec.lua`):
1. `Persistence.saveGames(filepath, games)` writes to file
2. `Persistence.loadGames(filepath)` reads from file
3. Handles missing file gracefully
4. Handles corrupted file gracefully

### 10A.5 Admin GUI (--gui mode)

**Features** (no tests, visual only):
- Server status panel (running, port, uptime)
- Connected players list with kick button
- Active games list with view/end options
- Scrollable server log
- Start/Stop button

---

## Phase 10B: Client Networking (~1-2 sessions, ~25 tests)

### Client Module Structure

```
src/
├── client/
│   ├── network.lua        # Connection management
│   ├── lobby_client.lua   # Lobby operations
│   └── game_client.lua    # Game sync
```

### 10B.1 Network Module

**Tests** (`spec/network_spec.lua`):
1. `Network.create()` returns network state
2. `Network.connect(net, host, port)` establishes connection
3. `Network.disconnect(net)` closes connection
4. `Network.send(net, message)` sends protocol message
5. `Network.receive(net)` returns pending messages
6. Handles connection failure gracefully
7. Detects disconnection

### 10B.2 Lobby Client

**Tests** (`spec/lobby_client_spec.lua`):
1. `LobbyClient.joinLobby(net, playerName)` sends JOIN_LOBBY
2. `LobbyClient.createGame(net, gameName)` sends CREATE_GAME
3. `LobbyClient.joinGame(net, gameId)` sends JOIN_GAME
4. `LobbyClient.leaveGame(net)` sends LEAVE_GAME
5. `LobbyClient.refreshGames(net)` requests game list

### 10B.3 Game Client

**Tests** (`spec/game_client_spec.lua`):
1. `GameClient.sendMove(net, from, to)` sends MOVE
2. `GameClient.sendPower(net, piece, powerId, target)` sends ACTIVATE_POWER
3. `GameClient.handleGameState(message)` updates local state
4. `GameClient.handleMoveResult(message)` processes result
5. `GameClient.handlePowerResult(message)` processes result

### 10B.4 UI Integration

**Implementation** (`src/game.lua`):
- Add "Multiplayer" to main menu
- Multiplayer lobby screen:
  - Enter player name
  - Server address input (default localhost:7777)
  - Connect button
- Connected lobby screen:
  - Game list with join buttons
  - Create game button
  - Disconnect button
- In-game:
  - Wait indicator for opponent's turn
  - Connection status
  - Opponent disconnect handling

---

## Phase 10C: Polish (~1 session, ~15 tests)

### 10C.1 Chat System

**Tests**:
1. `Chat.send(net, message)` sends CHAT
2. `Chat.receive(message)` processes CHAT_MESSAGE
3. Chat history maintained

### 10C.2 Reconnection

**Tests**:
1. Client detects disconnect
2. Client attempts reconnect
3. Server accepts reconnect within timeout
4. Game state restored after reconnect
5. Forfeit after timeout (60s)

### 10C.3 Match History

**Implementation**:
- File-based game result logging
- View past games screen
- Win/loss record per player name

---

## Protocol Reference

Full protocol specification: [network_protocol.md](network_protocol.md)

### Key Message Types

**Client → Server**:
- `CONNECT` - Initial handshake
- `JOIN_LOBBY` - Enter lobby
- `CREATE_GAME` - Create new game
- `JOIN_GAME` - Join existing game
- `LEAVE_GAME` - Leave current game
- `MOVE` - Make a move
- `ACTIVATE_POWER` - Use a power
- `CHAT` - Send chat message

**Server → Client**:
- `WELCOME` - Connection accepted
- `ERROR` - Error response
- `LOBBY_STATE` - Available games
- `GAME_CREATED` - Game creation confirmed
- `GAME_STATE` - Full game state sync
- `MOVE_RESULT` - Move outcome
- `POWER_RESULT` - Power outcome
- `GAME_OVER` - Game ended
- `CHAT_MESSAGE` - Chat from opponent

---

## Config File

`server_config.lua`:
```lua
return {
    port = 7777,
    maxGames = 10,
    maxPlayersPerGame = 2,
    disconnectTimeout = 60, -- seconds
    persistence = {
        enabled = true,
        filepath = "server_data.json",
        autoSaveInterval = 60, -- seconds
    },
    logging = {
        level = "info", -- "debug", "info", "warn", "error"
        filepath = "server.log",
    },
}
```

---

## Files to Create

| File | Purpose |
|------|---------|
| `server/main.lua` | Server entry point |
| `server/conf.lua` | Server Love2D config |
| `server/server.lua` | Core server logic |
| `server/lobby.lua` | Lobby management |
| `server/session.lua` | Player session tracking |
| `server/game_session.lua` | Active game management |
| `server/persistence.lua` | File save/load |
| `server/admin_gui.lua` | Admin interface (--gui mode) |
| `src/client/network.lua` | Client connection |
| `src/client/lobby_client.lua` | Lobby operations |
| `src/client/game_client.lua` | Game sync |
| `spec/server_spec.lua` | Server tests |
| `spec/lobby_spec.lua` | Lobby tests |
| `spec/session_spec.lua` | Session tests |
| `spec/game_session_spec.lua` | Game session tests |
| `spec/persistence_spec.lua` | Persistence tests |
| `spec/network_spec.lua` | Client network tests |
| `spec/lobby_client_spec.lua` | Lobby client tests |
| `spec/game_client_spec.lua` | Game client tests |

---

## Files to Modify

| File | Changes |
|------|---------|
| `src/game.lua` | Multiplayer UI, network integration |
| `src/shared/ui.lua` | Multiplayer menu items |
| `src/shared/protocol.lua` | Already complete! |

---

## Test Count

| Phase | Tests |
|-------|-------|
| 10A: Server | ~30 |
| 10B: Client | ~25 |
| 10C: Polish | ~15 |
| **Total new** | **~70** |
| Current total | ~817 |
| **New total** | **~887** |

---

## Execution Order

### Phase 10A
1. Create server directory structure
2. **RED/GREEN**: Server core tests
3. **RED/GREEN**: Lobby tests
4. **RED/GREEN**: Game session tests
5. **RED/GREEN**: Persistence tests
6. Implement admin GUI
7. Manual testing with telnet/nc
8. Commit 10A

### Phase 10B
1. **RED/GREEN**: Network module tests
2. **RED/GREEN**: Lobby client tests
3. **RED/GREEN**: Game client tests
4. UI integration
5. Manual 2-player testing
6. Commit 10B

### Phase 10C
1. **RED/GREEN**: Chat tests
2. **RED/GREEN**: Reconnection tests
3. Match history implementation
4. Polish and bug fixes
5. Commit 10C

---

## Future: Elixir Server

After Phase 10, development can proceed with the Elixir server:
- Phoenix Channels for WebSocket
- PostgreSQL for persistence
- Phoenix LiveView admin UI
- OAuth authentication
- Cloud deployment

See [elixir_notes.md](elixir_notes.md) for architecture details.

The Love2D client is already prepared to connect via WebSocket using `löve-ws`.
