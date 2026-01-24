# NNQR Love2D - Power Definitions

## Overview

Minimal power set (~12 powers) covering core gameplay categories.
Powers spawn as orbs every 7 turns on random empty tiles.

## Power Categories

1. **Movement** - Modify how pieces can move
2. **Offensive** - Destroy enemy pieces
3. **Defensive** - Protect your pieces
4. **Terrain** - Modify board height
5. **Strategic** - Convert or create pieces
6. **Utility** - Special abilities

---

## Power List

### Movement Powers

#### Move Diagonal
- **ID**: `move_diagonal`
- **Category**: Movement
- **Duration**: Permanent (until piece captured)
- **Effect**: Piece can move diagonally in addition to orthogonally
- **Targeting**: Self (automatic)
- **Visual**: Piece gains diagonal indicator

#### Move Again
- **ID**: `move_again`
- **Category**: Movement
- **Duration**: Single use
- **Effect**: Take another move immediately after this one
- **Targeting**: Self (automatic)
- **Visual**: Brief speed lines on piece

#### Relocate
- **ID**: `relocate`
- **Category**: Movement
- **Duration**: Single use
- **Effect**: Teleport to a random empty tile on the board
- **Targeting**: Self (automatic)
- **Visual**: Fade out, particles, fade in at new location

---

### Offensive Powers

#### Destroy Row
- **ID**: `destroy_row`
- **Category**: Offensive
- **Duration**: Single use
- **Effect**: Destroy all pieces (friend and foe) in the piece's row
- **Targeting**: Self row (automatic)
- **Visual**: Horizontal energy wave

#### Destroy Column
- **ID**: `destroy_column`
- **Category**: Offensive
- **Duration**: Single use
- **Effect**: Destroy all pieces (friend and foe) in the piece's column
- **Targeting**: Self column (automatic)
- **Visual**: Vertical energy wave

#### Bomb
- **ID**: `bomb`
- **Category**: Offensive
- **Duration**: Single use
- **Effect**: Destroy all pieces in 3x3 area centered on piece, lower terrain by 1
- **Targeting**: 3x3 area around self
- **Visual**: Explosion effect, terrain sinks
- **Note**: The activating piece survives

---

### Defensive Powers

#### Jump Proof
- **ID**: `jump_proof`
- **Category**: Defensive
- **Duration**: Permanent (until piece captured by special means)
- **Effect**: Piece cannot be captured by normal movement
- **Targeting**: Self (automatic)
- **Visual**: Shield/barrier indicator on piece
- **Note**: Can still be destroyed by powers like Destroy Row/Column

---

### Terrain Powers

#### Raise Tile
- **ID**: `raise_tile`
- **Category**: Terrain
- **Duration**: Single use (permanent terrain change)
- **Effect**: Increase target tile height by 1 (max 4)
- **Targeting**: Select adjacent tile
- **Visual**: Tile rises with particles

#### Lower Tile
- **ID**: `lower_tile`
- **Category**: Terrain
- **Duration**: Single use (permanent terrain change)
- **Effect**: Decrease target tile height by 1 (min 0)
- **Targeting**: Select adjacent tile
- **Visual**: Tile sinks with particles

---

### Strategic Powers

#### Recruit
- **ID**: `recruit`
- **Category**: Strategic
- **Duration**: Single use
- **Effect**: Convert one adjacent enemy piece to your side
- **Targeting**: Select adjacent enemy piece
- **Visual**: Color transition effect

#### Multiply
- **ID**: `multiply`
- **Category**: Strategic
- **Duration**: Single use
- **Effect**: Create a copy of this piece on an adjacent empty tile
- **Targeting**: Select adjacent empty tile
- **Visual**: Split/clone animation

---

### Utility Powers

#### Invisible
- **ID**: `invisible`
- **Category**: Utility
- **Duration**: Permanent (until piece attacks or is revealed)
- **Effect**: Piece is hidden from opponent's view
- **Targeting**: Self (automatic)
- **Visual**: Piece fades to semi-transparent (for owner), invisible to opponent
- **Note**: Revealed when capturing an enemy piece

---

## Power Orb Spawning

### Rules
- Orbs spawn every **7 turns** (both players combined = 1 round, so ~14 individual turns)
- Spawn on **random empty tiles** only
- Number of orbs per spawn: **2-4** (scales with remaining empty tiles)
- Territory influence: More orbs spawn on the side with fewer pieces (catch-up mechanic)

### Orb Visual
- Small glowing sphere
- Subtle pulse animation
- Color indicates power category (optional, could be mystery)

---

## Power Activation

### Turn Phase Order
1. **Power Phase**: Activate any powers (optional, before moving)
2. **Move Phase**: Move one piece
3. **Collection Phase**: Auto-collect orb if landed on one

### Activation Rules
- Powers must be activated BEFORE moving
- Multiple powers can be activated in one turn
- Some powers require targeting (Raise/Lower Tile, Recruit, Multiply)
- Some powers are automatic (Jump Proof, Move Diagonal, Invisible)

---

## Future Powers (Not in Minimal Set)

These may be added later:
- Grow Quadradius (extended capture range)
- Teach Row/Radial (share powers)
- Snake Tunneling (destructive path)
- Acid (permanent board holes)
- Dredge Column (height manipulation)
- Beneficiary (inherit powers on capture)
