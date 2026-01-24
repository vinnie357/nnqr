# NNQR Love2D - Network Protocol Specification

## Overview

JSON-based protocol over TCP sockets.
All messages are newline-delimited JSON objects.

## Connection Flow

```
Client                          Server
   |                               |
   |------ CONNECT --------------->|
   |<----- WELCOME ----------------|
   |                               |
   |------ JOIN_LOBBY ------------>|
   |<----- LOBBY_STATE ------------|
   |                               |
   |------ CREATE_GAME ----------->|
   |<----- GAME_CREATED -----------|
   |                               |
   |------ JOIN_GAME ------------->|
   |<----- GAME_STATE -------------|
   |                               |
   |------ MOVE ------------------>|
   |<----- MOVE_RESULT ------------|
   |<----- GAME_STATE -------------|
   |                               |
   |------ ACTIVATE_POWER -------->|
   |<----- POWER_RESULT -----------|
   |<----- GAME_STATE -------------|
   |                               |
```

## Message Format

All messages follow this structure:

```json
{
  "type": "MESSAGE_TYPE",
  "payload": { ... },
  "timestamp": 1234567890,
  "seq": 1
}
```

- `type`: Message type identifier (string)
- `payload`: Message-specific data (object)
- `timestamp`: Unix timestamp in milliseconds
- `seq`: Sequence number for ordering

---

## Client -> Server Messages

### CONNECT
Initial connection handshake.

```json
{
  "type": "CONNECT",
  "payload": {
    "client_version": "0.1.0",
    "player_name": "PlayerOne"
  }
}
```

### JOIN_LOBBY
Request to join the game lobby.

```json
{
  "type": "JOIN_LOBBY",
  "payload": {}
}
```

### CREATE_GAME
Create a new game room.

```json
{
  "type": "CREATE_GAME",
  "payload": {
    "game_name": "My Game",
    "settings": {
      "power_spawn_interval": 7,
      "max_height": 4
    }
  }
}
```

### JOIN_GAME
Join an existing game room.

```json
{
  "type": "JOIN_GAME",
  "payload": {
    "game_id": "abc123"
  }
}
```

### LEAVE_GAME
Leave current game.

```json
{
  "type": "LEAVE_GAME",
  "payload": {}
}
```

### MOVE
Move a piece.

```json
{
  "type": "MOVE",
  "payload": {
    "from": { "col": 3, "row": 2 },
    "to": { "col": 3, "row": 3 }
  }
}
```

### ACTIVATE_POWER
Activate a power on a piece.

```json
{
  "type": "ACTIVATE_POWER",
  "payload": {
    "piece_pos": { "col": 3, "row": 2 },
    "power_id": "destroy_row",
    "target": null
  }
}
```

For targeted powers:
```json
{
  "type": "ACTIVATE_POWER",
  "payload": {
    "piece_pos": { "col": 3, "row": 2 },
    "power_id": "raise_tile",
    "target": { "col": 4, "row": 2 }
  }
}
```

### CHAT
Send chat message.

```json
{
  "type": "CHAT",
  "payload": {
    "message": "Good game!"
  }
}
```

---

## Server -> Client Messages

### WELCOME
Connection accepted.

```json
{
  "type": "WELCOME",
  "payload": {
    "server_version": "0.1.0",
    "player_id": "player_abc123"
  }
}
```

### ERROR
Error response.

```json
{
  "type": "ERROR",
  "payload": {
    "code": "INVALID_MOVE",
    "message": "Cannot move to occupied tile"
  }
}
```

Error codes:
- `INVALID_MOVE` - Move not allowed
- `NOT_YOUR_TURN` - Wrong player tried to act
- `INVALID_POWER` - Power activation failed
- `GAME_NOT_FOUND` - Game ID doesn't exist
- `GAME_FULL` - Game already has 2 players
- `INVALID_MESSAGE` - Malformed message

### LOBBY_STATE
Current lobby state.

```json
{
  "type": "LOBBY_STATE",
  "payload": {
    "games": [
      {
        "game_id": "abc123",
        "game_name": "My Game",
        "players": ["PlayerOne"],
        "status": "waiting"
      }
    ],
    "players_online": 5
  }
}
```

### GAME_CREATED
Game creation confirmed.

```json
{
  "type": "GAME_CREATED",
  "payload": {
    "game_id": "abc123"
  }
}
```

### GAME_STATE
Full game state sync.

```json
{
  "type": "GAME_STATE",
  "payload": {
    "game_id": "abc123",
    "turn": 15,
    "current_player": 1,
    "phase": "move",
    "board": {
      "cols": 10,
      "rows": 8,
      "tiles": [
        { "col": 0, "row": 0, "height": 0, "orb": null },
        { "col": 0, "row": 0, "height": 2, "orb": "move_diagonal" }
      ]
    },
    "pieces": [
      {
        "id": "p1",
        "col": 3,
        "row": 2,
        "player": 1,
        "powers": ["jump_proof", "move_diagonal"],
        "visible": true
      }
    ],
    "winner": null
  }
}
```

### MOVE_RESULT
Result of move action.

```json
{
  "type": "MOVE_RESULT",
  "payload": {
    "success": true,
    "captured": null,
    "orb_collected": "bomb"
  }
}
```

With capture:
```json
{
  "type": "MOVE_RESULT",
  "payload": {
    "success": true,
    "captured": {
      "piece_id": "p15",
      "player": 2
    },
    "orb_collected": null
  }
}
```

### POWER_RESULT
Result of power activation.

```json
{
  "type": "POWER_RESULT",
  "payload": {
    "success": true,
    "power_id": "destroy_row",
    "effects": [
      { "type": "piece_destroyed", "piece_id": "p5" },
      { "type": "piece_destroyed", "piece_id": "p12" }
    ]
  }
}
```

### GAME_OVER
Game ended.

```json
{
  "type": "GAME_OVER",
  "payload": {
    "winner": 1,
    "reason": "elimination"
  }
}
```

Reasons:
- `elimination` - All enemy pieces destroyed
- `resignation` - Opponent resigned
- `disconnect` - Opponent disconnected
- `timeout` - Turn time exceeded

### CHAT_MESSAGE
Chat message from another player.

```json
{
  "type": "CHAT_MESSAGE",
  "payload": {
    "player_name": "PlayerTwo",
    "message": "Nice move!"
  }
}
```

### ORB_SPAWN
New power orbs appeared.

```json
{
  "type": "ORB_SPAWN",
  "payload": {
    "orbs": [
      { "col": 5, "row": 3, "power_id": "bomb" },
      { "col": 2, "row": 5, "power_id": "recruit" }
    ]
  }
}
```

---

## State Synchronization

### Full Sync
- Sent on game join
- Sent on reconnection
- Contains complete game state

### Delta Updates
- After each action, server sends relevant result message
- Followed by full GAME_STATE for consistency
- Client can optimize by applying deltas first

---

## Reconnection

### Flow
1. Client reconnects with same player_id
2. Server validates session
3. Server sends full GAME_STATE
4. Game resumes

### Timeout
- If disconnected > 60 seconds, forfeit
- Configurable per game

---

## Security Considerations

### Server Authority
- Server validates ALL moves
- Server is source of truth for game state
- Client cannot trust other clients

### Validation
- Check it's player's turn
- Validate move is legal
- Validate power activation is legal
- Prevent replay attacks with sequence numbers

---

## Future: Alternative Transports

### WebSocket (planned)
Same JSON protocol over WebSocket for browser support.

### UDP (stub)
For real-time features if needed.

```
┌─────────────┐     ┌─────────────┐
│   Client    │────>│   Server    │
│  (Love2D)   │TCP  │  (Love2D)   │
└─────────────┘     └─────────────┘
       │                   │
       │    Future:        │
       │   WebSocket       │
       │                   │
┌─────────────┐     ┌─────────────┐
│   Browser   │────>│   Elixir    │
│   Client    │WS   │   Server    │
└─────────────┘     └─────────────┘
```
