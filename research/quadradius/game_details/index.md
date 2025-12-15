# Quadradius Research Index

> Research Date: 2025-12-14
> Project: NNQR (Not Not Quadradius)

This directory contains comprehensive research documentation for recreating Quadradius. Use this index to find the right document for your task.

---

## Document Overview

| Document | Purpose | Key Contents |
|----------|---------|--------------|
| [index.md](./index.md) | This file | Navigation and document summaries |
| [overview.md](./overview.md) | Start here | Core mechanics, rules, game structure |
| [powers.md](./powers.md) | Power reference | All 87 powers with full descriptions |
| [interface_settings.md](./interface_settings.md) | UI/UX design | Screenshots, layouts, settings design |
| [web_interface.md](./web_interface.md) | Original web UI | Login, lobby, matchmaking screens |
| [ai_opponent.md](./ai_opponent.md) | AI design | Single player AI implementation |
| [troubleshooting.md](./troubleshooting.md) | Strategy guide | Common mistakes, tips, rule clarifications |

---

## Document Details

### overview.md
**Start here for understanding the game.**

Contains:
- Game objective (eliminate all opponent pieces)
- Board setup (10×8 grid, 20 pieces per side)
- Movement rules (cardinal directions, one tile per turn)
- Turn structure (move, then optionally use powers)
- Power system overview (orbs, collection, overheat rule)
- Power categories summary (17 categories)
- Strategic elements (combos, terrain, time limits)
- NNQR implementation notes (differences from original)

Use when: Starting development, understanding core mechanics, onboarding.

---

### powers.md
**Complete power reference - all 87 powers.**

Contains:
- Full descriptions quoted from official source
- All power variants (Radial/Row/Column)
- Use cases and strategic notes for each power
- Power categories breakdown
- All 87 powers documented
- Power interaction rules (overheat, stacking)
- Defensive counters table
- NNQR implementation status section

Use when: Implementing powers, balancing, understanding specific power behavior.

**Power Count by Category:**
| Category | Count |
|----------|-------|
| Piece Generation | 2 |
| Arena Control | 1 |
| Range Enhancement | 1 |
| Explosive | 3 |
| Terrain Manipulation | 15 |
| Power Transfer | 12 |
| Power Multiplication | 2 |
| Movement | 6 |
| Positioning | 3 |
| Stealth | 1 |
| Defense | 1 |
| Chaos | 9 |
| Intelligence | 9 |
| Restoration | 6 |
| Control | 9 |
| Offensive | 12 |
| Recruitment | 3 |

---

### interface_settings.md
**UI/UX design reference with screenshots.**

Contains:
- **Original UI from screenshots:**
  - Login screen (ASCII layout, elements, colors)
  - Main lobby screen (navigation, matchmaking, stats)
  - In-game screen (board, powers panel, chat)
- **Original game settings** (board size, squadron size, time limits)
- **Board visual states** (pieces, destroyed tiles, power indicators)
- **NNQR new features:**
  - Main menu design
  - Single player menu (AI difficulty, personality)
  - Arena settings (board size, pieces, spawn rate)
  - Game settings (audio, display, gameplay, accessibility)
  - Multiplayer menu
  - In-game HUD design
- Visual style reference (industrial, metallic aesthetic)

Use when: Designing UI, implementing menus, understanding visual feedback.

---

### web_interface.md
**Original Quadradius web interface documentation.**

Contains:
- Visual design theme (industrial, metallic, sci-fi)
- Color palette (maroon, olive, steel blue)
- Typography (LED dot-matrix style)
- Login screen layout and components
- Main lobby layout and components
- UI component CSS reference
- Networking requirements for multiplayer

Use when: Matching original aesthetic, implementing web-based version.

---

### ai_opponent.md
**AI design for single player mode (NEW feature).**

Contains:
- Game state analysis (visible vs hidden information)
- Difficulty levels (Easy, Medium, Hard, Expert)
- Evaluation heuristics (piece value, position scoring)
- Decision-making approaches:
  - Rule-based system (Easy/Medium)
  - Minimax with alpha-beta pruning (Hard)
  - Monte Carlo Tree Search (Expert)
- Power usage strategy (immediate, setup, reactive)
- Power combo recognition
- Hidden information handling (Bayesian estimation)
- Performance optimization techniques
- Implementation phases (4 phases)
- Difficulty scaling techniques
- Testing and validation approaches

Use when: Implementing AI opponent, tuning difficulty, single player mode.

---

### troubleshooting.md
**Strategy guide and common mistakes.**

Contains:
- Power management errors (overheat, hoarding)
- Movement mistakes (diagonal, edges)
- Tactical errors (protection, terrain)
- Rule clarifications (power timing, jumps, orbs)
- Strategy tips (early/mid/late game)
- Diagnostic questions for improvement
- NNQR implementation differences

Use when: Writing tutorials, testing gameplay, debugging rules.

---

## Quick Reference

### For Implementing Core Game
1. Read [overview.md](./overview.md) first
2. Reference [powers.md](./powers.md) for power implementation
3. Use [interface_settings.md](./interface_settings.md) for UI

### For Implementing AI
1. Read [ai_opponent.md](./ai_opponent.md)
2. Reference [powers.md](./powers.md) for power values
3. Use [troubleshooting.md](./troubleshooting.md) for strategy logic

### For UI/UX Design
1. Read [interface_settings.md](./interface_settings.md) for layouts
2. Reference [web_interface.md](./web_interface.md) for original style
3. Check screenshots in interface_settings.md

### For Testing/QA
1. Use [troubleshooting.md](./troubleshooting.md) for edge cases
2. Reference [powers.md](./powers.md) for power interactions
3. Check [overview.md](./overview.md) for rule verification

---

## Source Information

| Source | URL | Content |
|--------|-----|---------|
| Official Directions | https://quadradius.ddns.net/directions.html | Rules, all 87 powers |
| Official Site | https://quadradius.ddns.net/ | Screenshots, lobby |
| JayIsGames | jayisgames.com/review/quadradius.php | Custom game options |
| Isley Unruh | isleyunruh.com/brilliant-board-games-3-quadradius/ | Board size, mechanics |
| MobyGames | mobygames.com/game/206703/quadradius/ | Technical specs |
| QuadradiusR | github.com/Fruktus/QuadradiusR | Reimplementation reference |

---

## NNQR-Specific Notes

Features unique to NNQR (not in original):
- **Single Player Mode** - AI opponent (see ai_opponent.md)
- **Extended Board Options** - 8×8, 10×8, 12×10
- **All 87 Powers** - Complete power set available
- **Modern Rendering** - True 3D isometric (Bevy/Love2D)
- **Accessibility Options** - Colorblind mode, high contrast
