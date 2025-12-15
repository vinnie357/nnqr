# AI Opponent Design for NNQR

> Research Date: 2025-12-14
> Status: New feature (not in original Quadradius)

## Overview

The original Quadradius was purely multiplayer. NNQR will implement an AI opponent for single player mode, allowing players to practice and play offline.

---

## Game State Analysis

### Information the AI Has Access To

| Information | Visibility |
|-------------|------------|
| Board layout & terrain elevations | Full |
| All piece positions | Full |
| Own piece powers | Full |
| Enemy piece powers | Hidden (unless Spyware applied) |
| Power orb locations | Full |
| Power orb contents | Hidden (unless Orb Spy applied) |
| Turn order | Full |

### Key Decision Points Per Turn

1. **Which piece to move?** (from N pieces)
2. **Which direction?** (4 cardinal, or 8 with Move Diagonal)
3. **Which powers to activate?** (0 to many)
4. **Power targeting** (for targeted powers)

---

## AI Difficulty Levels

### Easy
- Random or semi-random piece selection
- Basic threat avoidance
- No power combo planning
- Delayed power usage
- Makes occasional "mistakes"

### Medium
- Evaluates immediate threats/opportunities
- Uses powers reactively
- Basic positional awareness
- Some orb collection priority

### Hard
- Multi-turn planning
- Power combo execution
- Terrain manipulation strategy
- Aggressive orb denial
- Predicts player moves

### Expert
- Minimax or MCTS-based decisions
- Optimal power timing
- Counter-strategy adaptation
- Hidden information estimation
- Near-perfect play

---

## Evaluation Heuristics

### Board State Scoring

```
Score = Σ(piece_values) + Σ(position_values) + Σ(power_values) + terrain_control
```

#### Piece Value
```
base_piece_value = 100
piece_value = base_piece_value + Σ(power_values_on_piece)
```

#### Position Value Factors

| Factor | Score Modifier |
|--------|----------------|
| Adjacent to enemy (can jump) | +20 |
| Can be jumped by enemy | -30 |
| On high ground | +10 |
| Trapped in pit | -25 |
| Near power orb | +15 |
| Center board control | +5 |
| Edge/corner (limited mobility) | -5 |

#### Power Value Estimates

| Power Category | Base Value | Notes |
|----------------|------------|-------|
| Destroy (any) | 80-100 | High value, immediate threat |
| Recruit (any) | 90-120 | Swings piece count |
| Jump Proof | 60 | Defensive staple |
| Move Again | 50 | Action economy |
| Acidic (any) | 70-90 | Destroy + terrain denial |
| Teach (any) | 40 | Force multiplier |
| Grow Quadradius | 30 | Range amplifier |
| Terrain powers | 20-40 | Situational |
| Intelligence powers | 15-25 | Information value |

#### Terrain Control
```
terrain_score = (friendly_high_tiles - enemy_high_tiles) * 5
             + (enemy_trapped_pieces * 20)
             - (friendly_trapped_pieces * 20)
```

---

## Decision-Making Approaches

### 1. Rule-Based System (Easy/Medium)

```
Priority Order:
1. If can safely eliminate enemy piece → do it
2. If piece in immediate danger → move/defend
3. If can collect power orb → collect
4. If have powerful attack ready → position for use
5. Otherwise → improve position
```

#### Threat Detection Rules
```
is_threatened(piece) =
    any adjacent enemy can jump us AND
    we don't have Jump Proof AND
    enemy moves next (or has Move Again)
```

#### Opportunity Detection Rules
```
can_attack(piece) =
    (adjacent enemy AND no Jump Proof on enemy) OR
    (has Destroy/Acidic/Kamikaze in range of enemy)
```

### 2. Minimax with Alpha-Beta Pruning (Hard)

```
function minimax(state, depth, alpha, beta, maximizing):
    if depth == 0 or game_over(state):
        return evaluate(state)

    if maximizing:
        value = -∞
        for each move in get_moves(state):
            value = max(value, minimax(apply(state, move), depth-1, alpha, beta, false))
            alpha = max(alpha, value)
            if beta <= alpha:
                break
        return value
    else:
        value = +∞
        for each move in get_moves(state):
            value = min(value, minimax(apply(state, move), depth-1, alpha, beta, true))
            beta = min(beta, value)
            if beta <= alpha:
                break
        return value
```

**Challenges:**
- High branching factor (pieces × directions × power combinations)
- Hidden information (enemy powers, orb contents)
- Need move ordering for efficiency

### 3. Monte Carlo Tree Search (Expert)

```
function mcts(state, iterations):
    root = Node(state)

    for i in 1..iterations:
        node = select(root)           # UCB1 selection
        child = expand(node)          # Add new move
        result = simulate(child)      # Random playout
        backpropagate(child, result)  # Update statistics

    return best_child(root).move
```

**Advantages:**
- Handles high branching factor
- No evaluation function needed (learns from playouts)
- Can handle uncertainty well

**Configuration:**
- Iterations: 1000-10000 depending on time budget
- Exploration constant (C): ~1.414 (√2)
- Playout depth limit: 50-100 moves

---

## Power Usage Strategy

### Immediate Use Powers
Use as soon as beneficial:
- Destroy/Acidic/Kamikaze (when enemies in range)
- Recruit (when enemies in range)
- Jump Proof (when threatened)
- Tripwire (when enemy adjacent)

### Setup Powers
Use to create advantage:
- Teach (when allies nearby to receive)
- Grow Quadradius (before using ranged powers)
- Terrain manipulation (to trap or create paths)
- Hotspot (strategic positioning)

### Reactive Powers
Hold until needed:
- Scramble (when surrounded/losing)
- Relocate (when trapped)
- Purify (when debuffed)
- Move Again (for combos or escape)

### Power Combos to Recognize

| Combo | Effect |
|-------|--------|
| Grow Quadradius × 3 + Destroy Row | Near-board-wide elimination |
| Move Again + Jump | Double attack turn |
| Teach + 2x | Exponential power multiplication |
| Tripwire + Terrain trap | Lock enemy in place |
| Pilfer + Learn | Massive power accumulation |
| Plateau + Jump Proof | Impenetrable fortress |

---

## Hidden Information Handling

### Enemy Power Estimation

Without Spyware, AI must estimate enemy powers:

```
estimated_powers(enemy_piece) =
    orbs_collected(piece) × average_power_value
    + observed_power_uses
    - used_powers
```

### Bayesian Updating

Track probability of enemy having specific powers:
```
P(has_power | collected_orb) = P(power) / total_powers
P(has_power | used_different_power) = unchanged
P(has_power | didn't_use_when_optimal) = decreased
```

### Conservative Play (Hard+)
- Assume enemy has Jump Proof until proven otherwise
- Assume enemy has counter-powers when they act confident
- Track which orbs enemy collected for power inference

---

## Performance Optimization

### Move Generation
- Pre-compute valid moves per piece
- Cache threat maps
- Lazy power evaluation

### State Representation
- Bitboards for piece positions
- Compact power storage
- Incremental evaluation updates

### Search Optimization
- Transposition tables
- Killer move heuristic
- Late move reductions
- Iterative deepening

---

## Implementation Phases

### Phase 1: Basic AI
- Random legal moves
- Basic piece safety
- Simple orb collection

### Phase 2: Rule-Based AI
- Threat/opportunity detection
- Power usage triggers
- Position evaluation

### Phase 3: Search-Based AI
- Minimax (depth 2-3)
- Alpha-beta pruning
- Move ordering

### Phase 4: Advanced AI
- MCTS implementation
- Hidden information handling
- Difficulty scaling
- Personality variations

---

## Difficulty Scaling Techniques

### Evaluation Noise
Add random noise to evaluation at lower difficulties:
```
effective_score = score + random(-noise, +noise)
noise_easy = 50
noise_medium = 20
noise_hard = 5
noise_expert = 0
```

### Search Depth Limiting
| Difficulty | Max Depth | Time Limit |
|------------|-----------|------------|
| Easy | 1 | 100ms |
| Medium | 2 | 500ms |
| Hard | 3-4 | 2s |
| Expert | 5+ | 5s |

### Intentional Suboptimal Play
- Easy: 30% chance to pick 2nd-best move
- Medium: 10% chance
- Hard: 0%

### Power Blindness
- Easy: Ignores some power synergies
- Medium: Recognizes basic combos
- Hard+: Full combo awareness

---

## Testing & Validation

### AI vs AI Testing
- Run thousands of games at each difficulty
- Verify win rates scale with difficulty
- Check for degenerate strategies

### Metrics to Track
- Average game length
- Piece elimination rate
- Power usage efficiency
- Territory control over time

### Player Feedback Integration
- Track player win rates vs each difficulty
- Adjust difficulty parameters based on data
- Add difficulty auto-scaling option

---

## References

- [Chess Programming Wiki - Evaluation](https://www.chessprogramming.org/Evaluation)
- [MCTS Survey Paper](https://ieeexplore.ieee.org/document/6145622)
- [Game AI Pro](http://www.gameaipro.com/) - Various board game AI techniques
- [Alpha-Beta Pruning](https://en.wikipedia.org/wiki/Alpha%E2%80%93beta_pruning)
