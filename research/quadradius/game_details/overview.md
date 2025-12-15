# Quadradius Game Details

> Research Date: 2025-12-14
> Source: https://quadradius.ddns.net/directions.html

---

## Related Documentation

| Document | Description |
|----------|-------------|
| **[index.md](./index.md)** | Research index - start here for navigation |
| **[powers.md](./powers.md)** | Complete reference for all 87 powers |
| **[interface_settings.md](./interface_settings.md)** | UI/UX design, screenshots, game settings |
| **[web_interface.md](./web_interface.md)** | Original web interface documentation |
| **[ai_opponent.md](./ai_opponent.md)** | AI design for single player mode (NEW) |
| **[troubleshooting.md](./troubleshooting.md)** | Strategy guide, common mistakes, tips |

---

## Game Overview

Quadradius is a two-player head-to-head strategy game originally released as a Flash game in 2007. Players compete to eliminate all opponent pieces through jumping attacks or power-up abilities.

## Core Mechanics

### Objective

Eliminate all opponent pieces to achieve victory.

### Board Setup

- Rectangular arena with tiles at varying elevations
- Both players start with equal pieces positioned in their squadrons
- Power orbs are scattered across the arena

### Piece Movement

- Players move **one piece per turn**
- Movement is **one tile** in **four cardinal directions** (up, down, left, right)
- **No diagonal movement** by default (requires power-up)
- Victory occurs when one player eliminates all opponent pieces

### Elimination Methods

1. **Jumping** - Land on an opponent's piece to eliminate it
2. **Power Attacks** - Use offensive powers to destroy pieces

## Turn Structure

1. Active player selects one piece
2. **Optionally activate powers** (any number, in any order)
3. **Move the piece** one tile in a cardinal direction
4. **Moving ends the turn** (unless piece has Move Again power)

**Key Rule**: Powers activate BEFORE moving. The move is always the final action that ends your turn.

A turn indicator shows whose action is pending. Time limits prevent stalling.

## Power System

### Acquiring Powers

- Landing on a **power orb** grants one of 87 distinct powers
- Powers are stored on the piece that collected them
- Powers can be deployed strategically
- **Power weighting**: All 87 powers are equally likely (may be tuned later)

### Power Orb Spawning

| Aspect | Behavior |
|--------|----------|
| **Timing** | Random - can spawn on any turn |
| **Location** | Random tiles (empty OR occupied) |
| **If occupied** | Piece on that tile receives the power directly |
| **Count** | Varies, maximum 8 orbs per spawn |
| **Favoritism** | None - no player advantage |

### Overheat Warning

> "If you get 10 or more of any single power on any single piece, you can overheat."

**Consequence: The piece explodes and is destroyed.**

This mechanic prevents power hoarding on a single piece.

## Power Categories

> **See [powers.md](./powers.md) for complete power descriptions with full details.**

| Category | Count | Examples |
|----------|-------|----------|
| Piece Generation | 2 | Multiply, Cancel Multiply |
| Arena Control | 1 | Orbic Rehash |
| Range Enhancement | 1 | Grow Quadradius |
| Explosive | 3 | Bombs, Smart Bombs, Snake Tunneling |
| Terrain Manipulation | 15 | Raise/Lower Tile, Plateau, Moat, Trench, Wall, Invert, Dredge |
| Power Transfer | 12 | Teach, Learn, Pilfer, Parasite |
| Power Multiplication | 2 | 2x, Beneficiary |
| Movement | 6 | Move Again, Move Diagonal, Flat To Sphere, Relocate, Hotspot |
| Positioning | 3 | Switcheroo, Centerpult, Scavenger |
| Stealth | 1 | Invisible |
| Defense | 1 | Jump Proof |
| Chaos | 9 | Scramble, Swap (Radial/Row/Column) |
| Intelligence | 9 | Spyware, Orb Spy (Radial/Row/Column) |
| Restoration | 6 | Refurb, Purify (Radial/Row/Column) |
| Control | 9 | Bankrupt, Tripwire, Inhibit (Radial/Row/Column) |
| Offensive | 12 | Destroy, Acidic, Kamikaze (Radial/Row/Column) |
| Recruitment | 3 | Recruit (Radial/Row/Column) |

### Power Targeting Variants

Most powers come in three variants:
- **Radial**: Affects 8 surrounding tiles/pieces
- **Row**: Affects entire horizontal row
- **Column**: Affects entire vertical column

## Strategic Elements

### Power Combinations

> "Many tactical combinations of powers can be used to attack, defend, or foil your opponent's plans."

The depth of Quadradius comes from combining powers strategically:

- **Offensive combos**: Stack range boosters with attack powers
- **Defensive setups**: Jump Proof + terrain advantage
- **Control strategies**: Tripwire + terrain manipulation
- **Transfer plays**: Teach/Learn to distribute powers efficiently

### Terrain Elevation

**Elevation Range**: ±4 levels from starting height (9 total levels)

**Movement Rules**:
- **Step UP**: Maximum 1 level higher without Climb Tile
- **Step UP 2+**: Requires Climb Tile power
- **Step DOWN**: Unlimited - can descend any number of levels
- **Walls**: Terrain 2+ levels higher acts as a wall (blocks movement)

**Strategic Advantages**:
- Higher elevation provides defensive benefits
- Terrain manipulation can block opponent movement
- Walls and trenches restrict pathways
- Trapped pieces in deep pits cannot escape without Climb Tile or terrain powers

### Time Management

Time limits enforce active play and prevent indefinite stalling.

## NNQR Implementation Notes

For the NNQR recreation project:

### Current Implementation (Rust/Bevy v0.2.0)

- **Board**: 8x8 default (10x10 option available)
- **Powers**: 38+ powers implemented
- **Remaining**: 12+ powers to complete

### Key Differences

| Aspect | Original Quadradius | NNQR |
|--------|---------------------|------|
| Board Size | 8x8 or 10x10 | 8x8 default, 10x10 option |
| Platform | Flash (web) | Rust/Bevy + Lua/Love2D |
| Powers | 87 | All 87 available |
| Single Player | None | AI opponent (NEW) |
| Rendering | Flash 2D | True 3D isometric |

### New Features (Not in Original)

| Feature | Documentation |
|---------|---------------|
| **AI Opponent** | See [ai_opponent.md](./ai_opponent.md) |
| **Difficulty Levels** | Easy, Medium, Hard, Expert |
| **AI Personalities** | Aggressive, Defensive, Balanced, Chaotic |
| **Accessibility** | Colorblind mode, high contrast |
| **Extended Settings** | Board size options, spawn rates |

See [interface_settings.md](./interface_settings.md) for complete UI/settings design.

## References

### External Sources
- [Quadradius Directions](https://quadradius.ddns.net/directions.html) - Official rules reference
- [Quadradius Site](https://quadradius.ddns.net/) - Live game and lobby
- [JayIsGames Review](https://jayisgames.com/review/quadradius.php) - Custom game options
- [MobyGames](https://www.mobygames.com/game/206703/quadradius/) - Technical specs

### Related Research Documents
- **[index.md](./index.md)** - Full research index with navigation guide
- **[powers.md](./powers.md)** - All 87 powers with complete descriptions
- **[interface_settings.md](./interface_settings.md)** - UI layouts, settings, NNQR menus
- **[web_interface.md](./web_interface.md)** - Original web UI style guide
- **[ai_opponent.md](./ai_opponent.md)** - AI opponent design (single player)
- **[troubleshooting.md](./troubleshooting.md)** - Strategy and gameplay tips
