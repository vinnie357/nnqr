# Elixir Server Implementation Notes

## Overview

Future dedicated server implementation using Elixir/OTP for robust,
scalable multiplayer support.

## Why Elixir?

1. **OTP Supervision** - Automatic restart of failed processes
2. **Concurrency** - Lightweight processes for each game session
3. **Fault Tolerance** - Isolated failures don't crash the system
4. **Hot Code Reload** - Update server without disconnecting players
5. **Pattern Matching** - Clean message handling
6. **Phoenix Channels** - WebSocket support out of the box

## Proposed Architecture

```
                    ┌─────────────────────────────────────┐
                    │          Elixir Application        │
                    │                                     │
┌──────────┐       │  ┌─────────────────────────────┐   │
│  Love2D  │───────┼─>│      Phoenix Channels       │   │
│  Client  │  WS   │  │    (WebSocket Handler)      │   │
└──────────┘       │  └──────────────┬──────────────┘   │
                    │                 │                   │
┌──────────┐       │  ┌──────────────▼──────────────┐   │
│  Browser │───────┼─>│        Lobby Server         │   │
│  Client  │  WS   │  │   (GenServer - Singleton)   │   │
└──────────┘       │  └──────────────┬──────────────┘   │
                    │                 │                   │
                    │  ┌──────────────▼──────────────┐   │
                    │  │       Game Supervisor       │   │
                    │  │    (DynamicSupervisor)      │   │
                    │  └──────────────┬──────────────┘   │
                    │                 │                   │
                    │       ┌─────────┼─────────┐        │
                    │       │         │         │        │
                    │  ┌────▼───┐ ┌───▼────┐ ┌──▼─────┐ │
                    │  │ Game 1 │ │ Game 2 │ │ Game N │ │
                    │  │(GenSrv)│ │(GenSrv)│ │(GenSrv)│ │
                    │  └────────┘ └────────┘ └────────┘ │
                    │                                     │
                    └─────────────────────────────────────┘
```

## Key Modules

### `NnqrServer.Application`
- Starts supervision tree
- Configures Phoenix endpoint

### `NnqrServer.Lobby`
- GenServer managing available games
- Handles: create_game, join_game, list_games
- Broadcasts lobby updates to all connected clients

### `NnqrServer.Game`
- GenServer per active game
- Holds authoritative game state
- Validates moves, applies powers
- Broadcasts state updates to players

### `NnqrServer.GameLogic`
- Pure functions for game rules
- Port of Lua logic.lua to Elixir
- No side effects, fully testable

### `NnqrServerWeb.GameChannel`
- Phoenix Channel for WebSocket communication
- Handles: move, activate_power, chat
- Joins players to game-specific topics

## Protocol Compatibility

Use same JSON message format as Love2D server:
- Messages defined in `network_protocol.md` (same directory)
- Same types: CONNECT, MOVE, GAME_STATE, etc.
- Clients don't need to know which server they're using

## Example Game GenServer

```elixir
defmodule NnqrServer.Game do
  use GenServer

  def start_link(game_id) do
    GenServer.start_link(__MODULE__, game_id, name: via(game_id))
  end

  def init(game_id) do
    state = %{
      game_id: game_id,
      players: [],
      board: GameLogic.create_board(),
      pieces: GameLogic.create_pieces(),
      current_player: 1,
      turn: 0
    }
    {:ok, state}
  end

  def handle_call({:move, player_id, from, to}, _from, state) do
    case GameLogic.validate_move(state, player_id, from, to) do
      {:ok, new_state} ->
        broadcast_state(new_state)
        {:reply, {:ok, new_state}, new_state}
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  # ... more handlers
end
```

## Implementation Steps

1. **Setup Phoenix project**
   ```bash
   mix phx.new nnqr_server --no-html --no-assets
   ```

2. **Add dependencies**
   ```elixir
   {:jason, "~> 1.4"},  # JSON encoding
   {:phoenix_pubsub, "~> 2.1"}  # Real-time broadcasts
   ```

3. **Implement modules in order**
   - GameLogic (pure functions)
   - Game GenServer
   - Lobby GenServer
   - GameChannel
   - Integration tests

4. **Deploy options**
   - Fly.io (easy, cheap)
   - Render.com
   - Self-hosted with Docker

## Testing

```elixir
# Test game logic
defmodule NnqrServer.GameLogicTest do
  use ExUnit.Case

  test "valid orthogonal move" do
    assert GameLogic.is_valid_move({5, 5}, {5, 6}, state)
  end

  test "invalid diagonal move" do
    refute GameLogic.is_valid_move({5, 5}, {6, 6}, state)
  end
end
```

## Timeline

- Phase 1: Port game logic to Elixir
- Phase 2: Implement Game/Lobby GenServers
- Phase 3: Add Phoenix Channels
- Phase 4: Deploy and test with Love2D client
- Phase 5: Add browser client support

## Resources

- [Phoenix Channels Guide](https://hexdocs.pm/phoenix/channels.html)
- [GenServer Docs](https://hexdocs.pm/elixir/GenServer.html)
- [Fly.io Elixir Deployment](https://fly.io/docs/elixir/)
