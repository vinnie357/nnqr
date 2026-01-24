# Phase 8: AI Opponent

## Overview

Implement single player mode with AI opponent featuring 4 difficulty levels and optional personalities.

**Estimated Sessions**: 3-4
**New Tests**: ~65

## Architecture

```
src/
├── shared/
│   └── ai/
│       ├── ai.lua           # Main AI interface
│       ├── evaluator.lua    # Board evaluation heuristics
│       └── search.lua       # Minimax search (Hard/Expert)
```

## Difficulty Levels

| Level | Strategy | Search Depth | Description |
|-------|----------|--------------|-------------|
| Easy | Random | 0 | Random legal move |
| Medium | Heuristic | 0 | Rule-based evaluation |
| Hard | Minimax | 2-3 | Basic search |
| Expert | Minimax | 4+ | Deep search with power combos |

## Phase 8A: AI Framework (~1 session, ~20 tests)

### 8A.1 AI Module Structure

**Tests** (`spec/ai_spec.lua`):
1. `AI.create(difficulty)` returns AI state
2. `AI.create("easy")` creates easy AI
3. `AI.create("medium")` creates medium AI
4. `AI.create("hard")` creates hard AI
5. `AI.create("expert")` creates expert AI
6. `AI.chooseMove(aiState, gameState)` returns valid move
7. Move contains `piece`, `target`, `powers` fields

**Implementation** (`src/shared/ai/ai.lua`):
```lua
local AI = {}

--- Create an AI player
---@param difficulty string "easy"|"medium"|"hard"|"expert"
---@return table AI state
function AI.create(difficulty)

--- Choose a move for the AI
---@param aiState table AI state
---@param gameState table Current game state
---@return table {piece, target, powers} Move to make
function AI.chooseMove(aiState, gameState)
```

### 8A.2 Easy AI (Random)

**Tests**:
1. Easy AI returns random valid move
2. Easy AI never returns invalid move
3. Easy AI handles no valid moves (should return nil or pass)
4. Easy AI can capture when available

### 8A.3 Game Integration

**Tests** (`spec/game_logic_spec.lua`):
1. Game detects AI player turn
2. AI move is executed after delay
3. Turn switches after AI move

**Implementation** (`src/game.lua`):
- Add AI state to game
- Check if current player is AI
- Execute AI move with thinking delay

## Phase 8B: Rule-Based AI - Medium (~1 session, ~25 tests)

### 8B.1 Threat Detection

**Tests** (`spec/ai_spec.lua`):
1. `Evaluator.getThreatenedPieces(state, player)` finds pieces that can be captured
2. Correctly identifies multiple threats
3. No threats when safe

### 8B.2 Opportunity Detection

**Tests**:
1. `Evaluator.getCaptureOpportunities(state, player)` finds capture moves
2. Prioritizes high-value captures (pieces with powers)
3. No opportunities when none available

### 8B.3 Power Usage Triggers

**Tests**:
1. AI uses Jump Proof when threatened
2. AI uses Destroy Row/Column when enemies in range
3. AI uses Recruit when adjacent to enemy
4. AI uses Bomb when surrounded by enemies
5. AI doesn't waste powers unnecessarily

### 8B.4 Position Scoring

**Tests**:
1. Center positions score higher than edges
2. High ground scores higher than low ground
3. Protected positions (behind own pieces) score higher

### 8B.5 Orb Collection Priority

**Tests**:
1. AI prioritizes moving to orb tiles
2. AI weighs orb value vs risk

## Phase 8C: Search-Based AI - Hard/Expert (~1-2 sessions, ~20 tests)

### 8C.1 Board Evaluation

**Tests** (`spec/ai_evaluator_spec.lua`):
1. `Evaluator.evaluate(state, player)` returns numeric score
2. More pieces = higher score
3. Better positions = higher score
4. Powers add to score
5. Symmetric evaluation (negamax compatible)

**Implementation** (`src/shared/ai/evaluator.lua`):
```lua
--- Evaluate board position for a player
---@param state table Game state
---@param player number Player to evaluate for
---@return number Score (positive = good for player)
function Evaluator.evaluate(state, player)
```

### 8C.2 Minimax Search

**Tests** (`spec/ai_search_spec.lua`):
1. `Search.minimax(state, depth, player)` returns best move
2. Depth 1 makes simple captures
3. Depth 2 avoids giving up pieces
4. Alpha-beta pruning produces same result
5. Search respects time limit

**Implementation** (`src/shared/ai/search.lua`):
```lua
--- Find best move using minimax search
---@param state table Game state
---@param depth number Search depth
---@param player number Player to move
---@param alpha number Alpha for pruning (optional)
---@param beta number Beta for pruning (optional)
---@return table Best move, number Score
function Search.minimax(state, depth, player, alpha, beta)
```

### 8C.3 Move Ordering

**Tests**:
1. Captures searched first
2. Power activations searched early
3. Move ordering improves pruning efficiency

### 8C.4 Difficulty Scaling

**Tests**:
1. Hard AI uses depth 2-3
2. Expert AI uses depth 4+
3. Expert AI recognizes power combos

## AI Personalities (Optional)

| Personality | Behavior Bias |
|-------------|---------------|
| Aggressive | +50% attack weight, -25% defense |
| Defensive | +50% defense weight, prioritize Jump Proof |
| Balanced | Default weights |
| Chaotic | Use Scramble/Swap powers often |

## Files to Create

| File | Purpose |
|------|---------|
| `src/shared/ai/ai.lua` | Main AI interface |
| `src/shared/ai/evaluator.lua` | Board evaluation |
| `src/shared/ai/search.lua` | Minimax search |
| `spec/ai_spec.lua` | AI tests |
| `spec/ai_evaluator_spec.lua` | Evaluator tests |
| `spec/ai_search_spec.lua` | Search tests |

## Files to Modify

| File | Changes |
|------|---------|
| `src/game.lua` | AI player integration |
| `src/shared/ui.lua` | AI difficulty selection in menu |

## Test Count

| Phase | Tests |
|-------|-------|
| 8A: Framework | ~20 |
| 8B: Rule-Based | ~25 |
| 8C: Search-Based | ~20 |
| **Total new** | **~65** |
| Current total | ~517 |
| **New total** | **~582** |

## Execution Order

### Phase 8A
1. Create AI module structure
2. **RED/GREEN**: AI creation tests
3. **RED/GREEN**: Easy AI (random moves)
4. Integrate into game loop
5. Commit 8A

### Phase 8B
1. **RED/GREEN**: Threat/opportunity detection
2. **RED/GREEN**: Power usage triggers
3. **RED/GREEN**: Position scoring
4. Implement medium AI
5. Commit 8B

### Phase 8C
1. **RED/GREEN**: Board evaluation
2. **RED/GREEN**: Minimax search
3. **RED/GREEN**: Alpha-beta pruning
4. Implement hard/expert AI
5. Commit 8C

## Performance Considerations

- Cache move generation
- Transposition table for repeated positions
- Iterative deepening for time control
- Async move calculation to avoid frame drops
