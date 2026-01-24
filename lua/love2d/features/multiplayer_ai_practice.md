# Feature: Multiplayer AI Practice & Player Stats

## Overview

This feature adds server-side AI opponents for multiplayer games, allowing players to practice against AI with their stats recorded. It also adds a player ranking system based on PvP performance.

## User Stories

### US1: View Available Players While Waiting
As a player who created a game, I want to see how many players are available to join, so I can decide whether to wait or play against AI.

**Acceptance Criteria:**
- Waiting screen shows count of players online and not in a game
- Count updates in real-time as players join/leave lobby
- Option to start local AI game while waiting (press 'A')

### US2: Create AI Practice Game
As a player, I want to create a game against an AI opponent on the server, so my practice games are recorded in my stats.

**Acceptance Criteria:**
- "Create Game" flow shows opponent selection (Wait for Player / AI Practice)
- AI Practice shows difficulty options (Easy/Medium/Hard/Expert)
- AI game starts immediately without waiting
- Game plays like normal multiplayer but AI makes moves

### US3: Track Game Statistics
As a player, I want my wins/losses/games tracked, so I can see my progress over time.

**Acceptance Criteria:**
- Track AI games by difficulty (wins/losses/games)
- Track PvP games (wins/losses/games)
- Stats persist across server restarts
- Stats shown on welcome/in lobby

### US4: Player Ranking System
As a player, I want to have a rank based on my PvP performance, so I can compare myself to others.

**Acceptance Criteria:**
- ELO-style rating starting at 1000
- Rating changes based on opponent's rating
- Rank tiers: Bronze (<800), Silver (800-1199), Gold (1200-1599), Platinum (1600-1999), Diamond (2000+)
- Rank displayed in lobby/profile

---

## Technical Design

### Data Structures

#### Player Stats
```lua
player.stats = {
    ai = {
        easy   = { wins = 0, losses = 0, games = 0 },
        medium = { wins = 0, losses = 0, games = 0 },
        hard   = { wins = 0, losses = 0, games = 0 },
        expert = { wins = 0, losses = 0, games = 0 },
    },
    pvp = {
        wins = 0,
        losses = 0,
        games = 0,
    },
    rating = 1000,
}
```

#### Rank Tiers
| Rating Range | Rank |
|--------------|------|
| 0-799 | Bronze |
| 800-1199 | Silver |
| 1200-1599 | Gold |
| 1600-1999 | Platinum |
| 2000+ | Diamond |

#### ELO Configuration
- K-factor: 32 (standard, responsive to wins/losses)
- Starting rating: 1000
- Minimum rating: 0 (can't go negative)

### Protocol Messages

#### New Message Types
```lua
-- Create AI game request
CREATE_AI_GAME = {
    type = "CREATE_AI_GAME",
    payload = {
        difficulty = "easy" | "medium" | "hard" | "expert"
    }
}

-- AI game created response
AI_GAME_CREATED = {
    type = "AI_GAME_CREATED",
    payload = {
        gameId = string,
        difficulty = string,
        playerNumber = 1  -- Human is always player 1
    }
}

-- Stats update (sent after game ends)
STATS_UPDATE = {
    type = "STATS_UPDATE",
    payload = {
        stats = { ... },  -- Full stats object
        ratingChange = number,  -- Delta for this game (PvP only)
    }
}
```

#### Modified Messages
```lua
-- LOBBY_STATE now includes available players
LOBBY_STATE = {
    type = "LOBBY_STATE",
    payload = {
        games = [...],
        availablePlayers = number,  -- NEW
    }
}

-- WELCOME now includes stats
WELCOME = {
    type = "WELCOME",
    payload = {
        playerId = string,
        playerName = string,
        stats = { ... },  -- NEW
    }
}
```

### Server Components

#### `server/stats.lua` - Stats Module
```lua
Stats.create()                              -- Create new stats object
Stats.recordAIGame(stats, difficulty, won)  -- Update AI stats
Stats.recordPvPGame(stats, opponentRating, won)  -- Update PvP stats & rating
Stats.calculateRating(currentRating, opponentRating, won, kFactor)
Stats.getRank(rating)                       -- Get rank string from rating
Stats.getWinRate(stats, category)           -- Calculate win rate %
```

#### `server/game_session.lua` - AI Game Support
- Add `aiGame` flag
- Add `aiDifficulty` field
- Add `aiThinkTimer` for delayed AI moves
- Integrate with AI module for move selection

#### `server/lobby.lua` - Available Players
- Track which players are in games
- `getAvailablePlayers()` returns count of idle players

### Client Components

#### `src/client/lobby_client.lua`
- Store `availablePlayers` from LOBBY_STATE
- `getAvailablePlayerCount()` accessor

#### `src/client/multiplayer.lua`
- `createAIGame(difficulty)` function
- Handle AI_GAME_CREATED message
- Store/update player stats

### UI Screens

#### New Screen: `mpopponent` (Opponent Selection)
```
CREATE GAME
-----------
> Wait for Player
  AI Practice - Easy
  AI Practice - Medium
  AI Practice - Hard
  AI Practice - Expert
  Cancel
```

#### Modified Screen: `mpwaiting`
```
WAITING FOR OPPONENT
--------------------
2 players available

Press A to play vs AI instead
Press Escape to cancel
```

---

## Implementation Phases

### Phase 1: Player Count Tracking (~10 tests)
- Server tracks available players
- Broadcast count in LOBBY_STATE
- Client stores and displays count

### Phase 2: Stats System (~25 tests)
- Create stats module
- ELO rating calculations
- Rank tier system
- Persistence integration

### Phase 3: Server-Side AI Games (~30 tests)
- Protocol additions
- GameSession AI support
- AI move scheduling
- Stats recording on game end

### Phase 4: UI Changes (~8 tests)
- Opponent selection screen
- Wait screen enhancements
- Input handlers

### Phase 5: Client Integration (~15 tests)
- Multiplayer module updates
- Message handling
- Stats display

---

## Test Plan

### Stats Module Tests
- create() returns valid stats structure
- recordAIGame() increments correct difficulty stats
- recordAIGame() increments wins on win
- recordAIGame() increments losses on loss
- recordPvPGame() updates rating correctly
- calculateRating() with win vs equal opponent
- calculateRating() with loss vs equal opponent
- calculateRating() with win vs higher opponent
- calculateRating() with loss vs lower opponent
- calculateRating() respects minimum rating of 0
- getRank() returns correct tier for each range
- getWinRate() calculates correctly
- getWinRate() handles zero games

### Lobby Available Players Tests
- getAvailablePlayers() returns all when no games
- getAvailablePlayers() excludes players in games
- getAvailablePlayers() updates when player joins game
- getAvailablePlayers() updates when player leaves game
- LOBBY_STATE includes availablePlayers count

### Server AI Game Tests
- CREATE_AI_GAME creates game session
- AI game starts immediately (no waiting)
- AI game has correct difficulty set
- AI makes move after human move
- AI move respects think delay
- AI game records stats on completion
- AI game broadcasts state updates
- Human player is always player 1

### UI Tests
- mpopponent screen has correct menu items
- mpopponent navigation works
- Selecting "Wait for Player" goes to mpwaiting
- Selecting AI Practice sends CREATE_AI_GAME
- mpwaiting shows available player count
- mpwaiting 'A' key starts local AI game

### Client Tests
- createAIGame() sends correct message
- handleAIGameCreated() updates state
- availablePlayers stored from LOBBY_STATE
- Stats stored from WELCOME message
- Stats updated from STATS_UPDATE message
