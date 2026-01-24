# Research Suggestions & Future Enhancements

> Created: 2025-12-14
> Status: Suggestions for review

---

## Missing Content to Research

| Item | Description | Priority | Status |
|------|-------------|----------|--------|
| Starting Positions Diagram | Exact initial piece setup for each board size | High | Pending |
| Power Icons Reference | What do power icons look like in original UI? | Medium | Pending |
| Victory/Defeat Screens | End game UI, animations, stats shown | Medium | Pending |
| Tutorial Flow | What did "Learn The Game" actually teach? | Medium | Pending |
| Audio/SFX Reference | Original game sounds, music, announcer | Low | Pending |
| Animation Timings | How long do power effects animate? | Low | Pending |

---

## New NNQR Features to Design

### Gameplay Features

| Feature | Description | Notes |
|---------|-------------|-------|
| Replay System | Watch completed games, share replays | Could export as file or link |
| Undo/Redo | Allow move undos in single player mode | Maybe limited undos? |
| Pause Handling | What happens if player disconnects/pauses | Save state, resume later |
| Match History | Player's personal game history | Track wins/losses/stats |
| Achievements | Unlock badges for milestones | "First Win", "Power Collector", etc. |
| Custom Power Pools | Let players select which powers appear in orbs | For custom games |

### AI Enhancements

| Feature | Description | Notes |
|---------|-------------|-------|
| Opening Book | Pre-computed good early game moves | Speeds up AI, more natural play |
| Endgame Patterns | Recognize winning/losing positions | Better late-game AI |
| Named AI Opponents | Give AI personalities names and backstories | "General Tacticus", "Chaos Carl" |
| Tutorial AI | AI that intentionally teaches mechanics | Guides new players |
| Adaptive Difficulty | AI adjusts to player skill over time | Keeps games competitive |

### Social Features

| Feature | Description | Notes |
|---------|-------------|-------|
| Spectator Mode | Watch live games | For multiplayer |
| Challenge Friends | Send game invites | Via code or link |
| Leaderboards | Global and friends rankings | Weekly/monthly/all-time |
| Player Profiles | Stats, achievements, match history | Customizable avatars |

---

## Quality Improvements Needed

### Documentation Fixes

| Issue | Location | Status |
|-------|----------|--------|
| ~~Inconsistent text~~ | troubleshooting.md | Fixed |
| ~~Power count variation~~ | Multiple files | Fixed - standardized to "87 powers" |
| ~~Cross-references~~ | powers.md | Fixed - added related power links |

### Research Gaps - RESOLVED

All research gaps from Q&A session have been documented:

| Gap | Resolution |
|-----|------------|
| ✅ Overheat consequence | Piece explodes and is destroyed |
| ✅ Elevation specifics | ±4 levels, step up max 1, step down unlimited |
| ✅ Turn structure | Powers activate BEFORE moving, move ends turn |
| ✅ Orb spawn mechanics | Random timing/location, max 8, can land on occupied tiles |
| ✅ Power weighting | All 87 equally likely (tunable later) |

---

## Implementation Priority Suggestion

### Phase 1: Core Game
1. All 87 powers working
2. Basic AI (Easy/Medium)
3. Local multiplayer
4. Core UI

### Phase 2: Polish
1. Advanced AI (Hard/Expert)
2. Audio/SFX
3. Animations
4. Tutorial

### Phase 3: Social
1. Online multiplayer
2. Leaderboards
3. Replay system
4. Achievements

### Phase 4: Extras
1. Custom power pools
2. Spectator mode
3. Adaptive difficulty
4. Named AI personalities

---

## Notes

*This document will be updated as questions are answered and decisions are made.*
