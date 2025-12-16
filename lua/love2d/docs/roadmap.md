# NNQR Love2D - Roadmap

## Overview

Multi-phase implementation plan to bring NNQR Love2D to feature parity with original Quadradius (87 powers, multiplayer, AI opponent).

**Current Status**: 810 tests passing, 82 powers implemented, Phase 9 complete.

## Architecture

### Two-Server Strategy

```
┌─────────────────────────────────────────────────────────────────────┐
│                        LOVE2D CLIENT                                 │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  Connects via:                                               │    │
│  │  • TCP (luasocket) → Love2D LAN Server                       │    │
│  │  • WebSocket (löve-ws) → Elixir/Phoenix Server               │    │
│  └─────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
          │                                    │
          │ TCP/LAN                            │ WebSocket
          ▼                                    ▼
┌─────────────────────┐              ┌─────────────────────┐
│  LOVE2D SERVER      │              │  ELIXIR SERVER      │
│  (Phase 10)         │              │  (Future)           │
│                     │              │                     │
│  • Headless default │              │  • Phoenix Channels │
│  • --gui for admin  │              │  • PostgreSQL       │
│  • File persistence │              │  • Phoenix Web UI   │
│  • Config file      │              │  • OAuth auth       │
│  • LAN/Local        │              │  • Cloud deployment │
└─────────────────────┘              └─────────────────────┘
```

## Phases

### Phase 1-5: Foundation ✅ COMPLETE
Core game engine with terrain, 12 powers, animations, UI, sound, and particles.

- **492 tests passing**
- 12 powers implemented
- Full animation system
- UI with menus and settings
- Sound and particle systems

[Details](phases/phase1-5_foundation.md) | [Progress](phases/phase1-5_progress.md)

---

### Phase 6: Overheat Mechanic ✅ COMPLETE
Prevent power hoarding - 10+ of same power on one piece causes explosion.

- Overheat check after power collection
- Visual warning at 8+ powers
- Explosion animation on overheat

[Details](phases/phase6_overheat.md)

---

### Phase 7: Destroyed Tiles ✅ COMPLETE
Enable permanent tile destruction for Acidic and heavy Bomb damage.

- Destroyed tile state in game
- Movement blocked on destroyed tiles
- Visual rendering (black pits)
- Refurb power to repair tiles

[Details](phases/phase7_destroyed_tiles.md)

---

### Phase 8: AI Opponent ✅ COMPLETE
Single player mode with 4 difficulty levels and AI personalities.

- **8A**: AI framework, random moves (Easy)
- **8B**: Rule-based AI (Medium) - threats, opportunities, power usage
- **8C**: Search-based AI (Hard/Expert) - minimax, alpha-beta pruning

| Difficulty | Strategy |
|------------|----------|
| Easy | Random legal moves |
| Medium | Rule-based heuristics |
| Hard | Minimax depth 2-3 |
| Expert | Minimax depth 4+ with power combos |

[Details](phases/phase8_ai.md)

---

### Phase 9: More Powers ✅ COMPLETE
Implemented 70 additional powers to reach 82-power parity.

- **810 tests passing**
- **9A**: Simple powers - Destroy variants, Scramble, Kamikaze
- **9B**: Terrain powers - Plateau, Moat, Trench, Wall, Invert, Dredge
- **9C**: Power transfer - Teach, Learn, Pilfer, Parasite
- **9D**: Meta powers - Grow Quadradius, 2x, Beneficiary, Orbic Rehash
- **9E**: Movement & control - Switcheroo, Tripwire, Spyware, Bankrupt, Inhibit, Purify, Hotspot, Centerpult

[Details](phases/phase9_powers.md)

---

### Phase 10: Network Multiplayer
LAN multiplayer with lobby system using Love2D server.

- **~70 new tests**
- **10A**: Love2D server (headless default, --gui for admin)
- **10B**: Client networking (connect, lobby UI, game sync)
- **10C**: Polish (chat, match history, reconnection)

Server features:
- Config file for containerized deployment
- File-based persistence
- Guest authentication (unique names)
- Admin GUI (optional)

[Details](phases/phase10_multiplayer/phase10_multiplayer.md) | [Protocol](phases/phase10_multiplayer/network_protocol.md)

---

## Test Projections

| Phase | Status | Tests | Powers |
|-------|--------|-------|--------|
| 1-5 | ✅ Complete | 492 | 12 |
| 6 | ✅ Complete | +10 | 12 |
| 7 | ✅ Complete | +15 | 13 |
| 8 | ✅ Complete | +65 | 13 |
| 9 | ✅ Complete | +228 | 82 |
| **Current** | **810 tests** | | **82 powers** |
| 10 | Planned | +70 | 82 |
| **Total** | **~880** | | **82** |

## Timeline Estimates

| Phase | Sessions | Description | Status |
|-------|----------|-------------|--------|
| 6 | 1 | Overheat mechanic | ✅ |
| 7 | 1 | Destroyed tiles | ✅ |
| 8 | 3-4 | AI opponent (3 sub-phases) | ✅ |
| 9 | 6-8 | 70 powers (5 sub-phases) | ✅ |
| 10 | 4-5 | Multiplayer (3 sub-phases) | Planned |

## Future (Not This Roadmap)

After Phase 10, Elixir server development:
- Phoenix Channels for WebSocket
- PostgreSQL persistence
- Phoenix LiveView admin UI
- OAuth authentication (Discord, etc.)
- Cloud deployment (Fly.io, Gigalixir)
- Ranked matchmaking
- Leaderboards
- Spectator mode

## References

- [Original Quadradius Powers](../../../research/quadradius/game_details/powers.md) - All 87 powers
- [AI Design Document](../../../research/quadradius/game_details/ai_opponent.md) - AI architecture
- [Elixir Server Notes](phases/phase10_multiplayer/elixir_notes.md) - Future server plans
