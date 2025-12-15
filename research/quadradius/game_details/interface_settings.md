# Quadradius Interface & Settings Reference

> Research Date: 2025-12-14
> Sources: JayIsGames, Pong and Beyond, Isley Unruh, MobyGames, quadradius.ddns.net (screenshots)

---

## Original UI Reference (From Screenshots)

### Login Screen

```
┌─────────────────────────────────────┐  ← Weathered metal panel
│  ⊙                            ⊙    │  ← Corner screws
│  ┌─────────────────────────────┐   │
│  │                             │   │
│  │      ╭───────────────╮      │   │
│  │      │   ╱       ╲   │      │   │  ← Q Logo: Circle with
│  │      │  ●         ╲  │      │   │     diagonal line + 2 dots
│  │      │             ● │      │   │
│  │      ╰───────────────╯      │   │
│  │                             │   │
│  │      Q U A D R A D I U S    │   │  ← Spaced lettering
│  │                             │   │
│  └─────────────────────────────┘   │
│                                    │
│  ┌────────────────────────────┐    │
│  │    LEARN THE GAME          │    │  ← Steel blue button
│  └────────────────────────────┘    │
│                                    │
│  ┌────────────────────────────┐    │
│  │ Player                  :: │    │  ← Dark maroon input
│  └────────────────────────────┘    │     LED dot-matrix font
│                                    │
│  ┌────────────────────────────┐    │
│  │         START              │    │  ← Large red/orange button
│  └────────────────────────────┘    │
│                                    │
│  ┌────────────────────────────┐    │
│  │ Member Name                │    │  ← Member login fields
│  └────────────────────────────┘    │
│  ┌────────────────────────────┐    │
│  │ Password               ▣  │    │  ← Password with icon
│  └────────────────────────────┘    │
│  ⊙                            ⊙    │
└─────────────────────────────────────┘
```

#### Login Screen Elements

| Element | Color/Style | Purpose |
|---------|-------------|---------|
| Logo Panel | Inset gray, dark border | Brand identity |
| Q Symbol | Circle + diagonal + 2 dots | Represents game pieces |
| "LEARN THE GAME" | Steel blue (#4A7090) | Tutorial access |
| Player Input | Dark maroon (#3C0000) | Guest username entry |
| START Button | Red/orange gradient | Begin game as guest |
| Member Name | Dark maroon | Registered user login |
| Password | Dark maroon + icon | Account authentication |
| Panel Frame | Weathered gray metal | Industrial aesthetic |
| Corner Screws | Dark metal circles | Decorative detail |

### Main Lobby Screen

```
┌──────────────┬────────────────────────────────────┬─────────────────────┐
│              │                                    │       S T A T S     │
│   ╭──────╮   │  Player GUEST ▲  │ COMMUNIQUÉ     │                     │
│   │  Q   │   │  ┌──────────────┐ ┌──────────────┐ │ MOST RECENT BATTLES │
│   ╰──────╯   │  │              │ │              │ │ ─────────────────── │
│  QUADRADIUS  │  │ [Online      │ │ [Chat Area]  │ │ em GUEST beat       │
│              │  │  Players     │ │              │ │   Clignote    2-0   │
│  ┌────────┐  │  │  List]       │ │              │ │ Clignote beat       │
│  │FACEBOOK│  │  │              │ │              │ │   em GUEST    6-0   │
│  └────────┘  │  └──────────────┘ └──────────────┘ │ DaBinD beat         │
│  ┌────────┐  │       OPPONENTS                    │   dancomono   7-4   │
│  │ STATS  │  │                                    │ ...                 │
│  └────────┘  ├────────────────────────────────────┼─────────────────────┤
│  ┌────────┐  │ ################################## │ ┌─────────────────┐ │
│  │MEMBERS │  │ # QRNews           2025.04.03 #   │ │ DECEMBER 2025   │ │
│  └────────┘  │ ################################## │ ├─────────────────┤ │
│  ┌────────┐  │ Join Discord to register:         │ │RANK MEMBER    % │ │
│  │ NEWS   │  │ discord.gg/cVkV8pah4d             │ │001 f133t    55.6│ │
│  └────────┘  │                                    │ │002 DaBinD   70.8│ │
│  ┌────────┐  │ Registration remains free          │ │003 QRsaurus 75.0│ │
│  │DIRECTNS│  │                                    │ │004 zakzyz   78.6│ │
│  └────────┘  │ Welcome to Quadradius              │ │005 lOde     71.4│ │
│  ┌────────┐  │                                    │ │006 platypus 83.3│ │
│  │ ABOUT  │  │ 90 GUEST was here 5 minutes ago   │ │...              │ │
│  └────────┘  │                                    │ └─────────────────┘ │
│  ┌────────┐  │ Click on a person above to        │    MEMBER STATS     │
│  │PRESS/  │  │ challenge them to a Quadradius    │                     │
│  │REVIEWS │  │ Battle!                           │                     │
│  └────────┘  │                                    │                     │
│  ┌────────┐  │ ┌────────────────────────────┐    │                     │
│  │FAN     │  │ │ [Message input field]   :b │    │                     │
│  │CREATONS│  │ └────────────────────────────┘    │                     │
│  └────────┘  │                                    │                     │
│  ┌────────┐  │                                    │                     │
│  │QUADBORD│  │                                    │                     │
│  └────────┘  │                                    │                     │
│  ┌────────┐  │                                    │                     │
│  │MERCHNDS│  │                                    │                     │
│  └────────┘  │                                    │                     │
│  ┌────────┐  │                                    │                     │
│  │CONTACT │  │                                    │                     │
│  └────────┘  │                                    │                     │
└──────────────┴────────────────────────────────────┴─────────────────────┘
```

#### Left Sidebar Navigation

| Button | Color | Function |
|--------|-------|----------|
| FACEBOOK | Olive/green | Social media link |
| STATS | Olive/green | View statistics |
| MEMBERS | Olive/green | Member directory |
| NEWS | Olive/green | Game announcements |
| DIRECTIONS | Olive/green | Game rules/tutorial |
| ABOUT | Olive/green | Game information |
| PRESS/REVIEWS | Olive/green | Media coverage |
| FAN CREATIONS | Olive/green | Community content |
| QUADBOARD | Olive/green | Leaderboard |
| MERCHANDISE | Olive/green | Store |
| CONTACT | Olive/green | Support |

#### Center Panel - Matchmaking

| Section | Content |
|---------|---------|
| Player Dropdown | "Player GUEST" with scroll arrows |
| Player List | Online players available to challenge |
| OPPONENTS | Section header |
| COMMUNIQUÉ | Chat/message display area |
| News Panel | Date-stamped announcements, Discord link |
| Message Input | Text field with emoticon button |

#### Right Panel - Statistics

**MOST RECENT BATTLES**
| Match Result | Score | Time |
|--------------|-------|------|
| em GUEST beat Clignote | 2-0 | 14:06 |
| Clignote beat em GUEST | 6-0 | 7:37 |
| DaBinD beat dancomono | 7-4 | 11:01 |
| Clignote beat em GUEST | 4-3 | 11:00 |
| DaBinD beat dancomono | 15-4 | 9:39 |

**MEMBER STATS (December 2025)**
| Rank | Member | Win % | W/G |
|------|--------|-------|-----|
| 001 | f133t | 55.6 | 15/27 |
| 002 | DaBinD | 70.8 | 34/48 |
| 003 | QRsaurus Rex | 75.0 | 12/16 |
| 004 | zakzyz | 78.6 | 11/14 |
| 005 | lOde | 71.4 | 10/14 |
| 006 | platypuss | 83.3 | 5/6 |
| 007 | DisMember | 75.0 | 6/8 |
| 008 | ANUBIS | 70.0 | 14/20 |

#### Ranking Display
- "TO RANK: 000 WINS > 0.0%" indicator
- Monthly competition cycles
- Scroll arrows for navigation

### In-Game Screen (During Match)

```
┌─────────────────────────────────────────────────┬──────────────────────────┐
│                                                 │      QUADRADIUS          │
│   ┌─────────────────────────────────────────┐   │ ● 003 Guest#3139  10 1500│
│   │  ○   ○   ●̲   ○      ○                   │   │ ● 004 Professor Forb     │
│   │          ↑                              │   │                          │
│   │      [POWERS (CLICK PIECE)]             │   │ ORBS: 2 ■■■■■■           │
│   │      [MOVE DIAGONAL        ]            │   ├──────────────────────────┤
│   │                                         │   │ CHAT                     │
│   │  ●   ●       ●̃        ○                 │   │ ─────                    │
│   │              ↑                          │   │ activated GROW           │
│   │         (blue glow =                    │   │   QUADRADIUS             │
│   │          has powers)                    │   │ activated DESTROY COLUMN │
│   │  ●   ●               ■   ●̃   ●̃         │   │ activated PILFER RADIAL  │
│   │                      ↑                  │   │ activated PILFER COLUMN  │
│   │              (black hole =              │   │ activated RELOCATE       │
│   │               destroyed tile)           │   │ activated WALL ROW       │
│   │  ●   ●   ■       ●̃       ●̃   ○         │   │ Guest#3139 activated     │
│   │          ↑                              │   │   MULTIPLY               │
│   │  ════════════════════════════════════   │   │ Professor Forb activated │
│   │  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓   │   │   GROW QUADRADIUS        │
│   │  (yellow/black hazard stripe =          │   │ ...                      │
│   │   board edge / lower level)             │   │                          │
│   │                                         │   ├──────────────────────────┤
│   │  ○   ○   ●   ●   ○   ○   ●   ○   ●     │   │ POWER POOL │ MY POWERS   │
│   │                                         │   │ ────────────────────────│
│   │  ■       ○   ○   ○       ●   ○   ○     │   │ MOVE DIAGONAL            │
│   │                                         │   │                          │
│   └─────────────────────────────────────────┘   │                          │
│                                                 │                          │
│   [X ROBOT DREAMING ABOUT A NICE GAME OF CHESS] │                          │
│   (loading/thinking indicator)                  ├──────────────────────────┤
│                                                 │ [RESIGN]    [🔊] [⚙]    │
└─────────────────────────────────────────────────┴──────────────────────────┘

Legend:
  ○  = White/silver piece (Player 1)
  ●  = Black piece (Player 2)
  ●̃  = Piece with blue glow (has powers)
  ●̲  = Selected piece (red ring)
  ■  = Destroyed tile (black hole - impassable)
```

#### In-Game UI Elements

| Element | Location | Description |
|---------|----------|-------------|
| Game Board | Left/Center | 3D view with elevation, damaged tiles visible |
| Power Popup | Above selected piece | Shows "POWERS (CLICK PIECE)" + power name |
| Player Info | Top right | Names, piece counts, orb indicator |
| ORBS Display | Right panel | Shows orb count with visual bars |
| CHAT Log | Right panel | Activity feed of power activations |
| POWER POOL Tab | Bottom right | Available powers from orbs |
| MY POWERS Tab | Bottom right | Powers on selected piece |
| RESIGN Button | Bottom right | Forfeit match |
| Sound/Settings | Bottom right | Audio toggle, settings gear |
| Loading Indicator | Board overlay | "ROBOT DREAMING..." during AI/network wait |

#### Board Visual States

| Visual | Meaning |
|--------|---------|
| Silver/white torus | Player 1 piece |
| Black torus | Player 2 piece |
| Blue glow ring | Piece has powers |
| Red selection ring | Currently selected piece |
| Black hexagonal hole | Destroyed tile (Acidic/Bombs) - IMPASSABLE |
| Yellow/black stripes | Board edge / hazard area |
| Elevated tiles | Higher terrain (shadows visible) |
| Depressed tiles | Lower terrain |
| Metallic dome | Power orb (uncollected) |

#### Destroyed Tiles (From Acidic/Bombs)

Powers that create permanent holes:
- **Acidic Radial/Row/Column** - Destroys piece AND tile
- **Bombs** - Compresses tiles, eventually creates holes
- **Smart Bombs** - Same as Bombs but avoids friendly pieces

Power that repairs holes:
- **Refurb Radial/Row/Column** - Replaces damaged/destroyed tiles

---

## Original Game Settings (Member Custom Games)

The original Quadradius allowed members to customize matches with these options:

### Arena Settings

| Setting | Options | Default |
|---------|---------|---------|
| **Board Size** | 8×8 or 10×10 | 8×8 |
| **Squadron Size** | Variable (standard: 20 pieces per side) | 20 |
| **Squadron Color** | Custom color selection | Red/Blue |
| **Time Limit** | Per-turn time limit | Variable |

### Gameplay Modifiers

| Setting | Description |
|---------|-------------|
| Power Orb Frequency | How often orbs spawn (every ~7 rounds) |
| Starting Elevation | Initial terrain configuration |
| Power Pool | Which powers are available in orbs |

---

## In-Game Interface Elements

### Board View

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│   ┌─────────────────────────────────────┐  ┌─────────┐  │
│   │                                     │  │ POWERS  │  │
│   │                                     │  │         │  │
│   │         10 × 8 GAME BOARD           │  │ [Icon]  │  │
│   │                                     │  │ [Icon]  │  │
│   │    ○ ○ ○ ○ ○ ○ ○ ○ ○ ○             │  │ [Icon]  │  │
│   │    ○ ○ ○ ○ ○ ○ ○ ○ ○ ○  (Player 1) │  │ [Icon]  │  │
│   │                                     │  │   ...   │  │
│   │         ◊ (Power Orb)               │  │         │  │
│   │                                     │  │         │  │
│   │    ● ● ● ● ● ● ● ● ● ●  (Player 2) │  │         │  │
│   │    ● ● ● ● ● ● ● ● ● ●             │  │         │  │
│   │                                     │  │         │  │
│   └─────────────────────────────────────┘  └─────────┘  │
│                                                         │
│   [Turn Indicator]  [Timer]  [Chat/Messages]            │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Interface Components

| Element | Location | Function |
|---------|----------|----------|
| Game Board | Center | 3D isometric grid with elevation |
| Power Panel | Right side | Shows selected piece's powers |
| Turn Indicator | Bottom | Shows whose turn it is |
| Timer | Bottom | Turn time remaining |
| Chat/Communiqué | Bottom/Side | In-game messaging |
| Piece Selection | Board | Click to select piece |
| Move Indication | Board | Valid moves highlighted |

### Visual Indicators

| Indicator | Meaning |
|-----------|---------|
| Metallic dome on tile | Power orb (uncollected) |
| Glowing piece | Has powers |
| Shaded piece | Power possession (type hidden from opponent) |
| Elevated tiles | Higher terrain (movement restricted) |
| Depressed tiles | Lower terrain (bomb damage) |
| Holes in tiles | Destroyed tiles (impassable) |

### Controls

| Action | Control |
|--------|---------|
| Select piece | Click on piece |
| Move piece | Click and drag to destination |
| Use power | Click power icon in right panel |
| View piece powers | Hover/click on own piece |
| Chat | Type in message field |

---

## NNQR New Features - Settings Design

### Main Menu

```
┌─────────────────────────────────────────┐
│                                         │
│            [NNQR LOGO]                  │
│         NOT NOT QUADRADIUS              │
│                                         │
│    ┌─────────────────────────────┐      │
│    │      SINGLE PLAYER          │      │  ← NEW
│    └─────────────────────────────┘      │
│    ┌─────────────────────────────┐      │
│    │      MULTIPLAYER            │      │
│    └─────────────────────────────┘      │
│    ┌─────────────────────────────┐      │
│    │      SETTINGS               │      │
│    └─────────────────────────────┘      │
│    ┌─────────────────────────────┐      │
│    │      HOW TO PLAY            │      │
│    └─────────────────────────────┘      │
│                                         │
└─────────────────────────────────────────┘
```

### Single Player Menu (NEW)

```
┌─────────────────────────────────────────┐
│                                         │
│           SINGLE PLAYER                 │
│                                         │
│   AI Difficulty:                        │
│   ┌─────┐ ┌────────┐ ┌──────┐ ┌──────┐  │
│   │Easy │ │ Medium │ │ Hard │ │Expert│  │
│   └─────┘ └────────┘ └──────┘ └──────┘  │
│                                         │
│   AI Personality:           (Optional)  │
│   ┌───────────┐ ┌───────────┐           │
│   │Aggressive │ │ Defensive │           │
│   └───────────┘ └───────────┘           │
│   ┌───────────┐ ┌───────────┐           │
│   │ Balanced  │ │  Chaotic  │           │
│   └───────────┘ └───────────┘           │
│                                         │
│   ┌─────────────────────────────┐       │
│   │        START GAME           │       │
│   └─────────────────────────────┘       │
│                                         │
│   [ARENA SETTINGS]  [BACK]              │
│                                         │
└─────────────────────────────────────────┘
```

### AI Difficulty Settings

| Difficulty | Description | Think Time |
|------------|-------------|------------|
| **Easy** | Makes mistakes, slow to use powers | Instant |
| **Medium** | Competent play, basic combos | 0.5-1s |
| **Hard** | Strategic planning, good power usage | 1-2s |
| **Expert** | Near-optimal play, advanced combos | 2-3s |

### AI Personality Options

| Personality | Behavior |
|-------------|----------|
| **Aggressive** | Prioritizes attacks, risky plays |
| **Defensive** | Jump Proof focus, terrain control |
| **Balanced** | Adapts to situation |
| **Chaotic** | Unpredictable, uses Scramble/Swap often |

### Arena Settings (Shared)

```
┌─────────────────────────────────────────┐
│                                         │
│           ARENA SETTINGS                │
│                                         │
│   Board Size:                           │
│   ┌───────┐ ┌───────┐                   │
│   │  8×8  │ │ 10×10 │  (default: 8×8)   │
│   └───────┘ └───────┘                   │
│                                         │
│   Pieces Per Side:                      │
│   ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐   │
│   │  10  │ │  15  │ │  20  │ │  25  │   │
│   └──────┘ └──────┘ └──────┘ └──────┘   │
│                                         │
│   Turn Time Limit:                      │
│   ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐   │
│   │ None │ │ 30s  │ │ 60s  │ │ 90s  │   │
│   └──────┘ └──────┘ └──────┘ └──────┘   │
│                                         │
│   Power Orb Spawn Rate:                 │
│   ┌──────┐ ┌──────┐ ┌──────┐            │
│   │ Slow │ │Normal│ │ Fast │            │
│   └──────┘ └──────┘ └──────┘            │
│                                         │
│   Starting Terrain:                     │
│   ┌──────┐ ┌──────┐ ┌──────┐            │
│   │ Flat │ │Random│ │Preset│            │
│   └──────┘ └──────┘ └──────┘            │
│                                         │
│   [APPLY]  [DEFAULTS]  [BACK]           │
│                                         │
└─────────────────────────────────────────┘
```

### Game Settings (Options Menu)

```
┌─────────────────────────────────────────┐
│                                         │
│             SETTINGS                    │
│                                         │
│   ─── AUDIO ───                         │
│   Music Volume:    [████████░░] 80%     │
│   SFX Volume:      [██████████] 100%    │
│   Announcer:       [ON] [OFF]           │
│                                         │
│   ─── DISPLAY ───                       │
│   Resolution:      [1920×1080 ▼]        │
│   Fullscreen:      [ON] [OFF]           │
│   VSync:           [ON] [OFF]           │
│   Camera Angle:    [███████░░░] 70°     │
│                                         │
│   ─── GAMEPLAY ───                      │
│   Show Move Hints: [ON] [OFF]           │
│   Show Power Info: [ON] [OFF]           │
│   Confirm Actions: [ON] [OFF]           │
│   Animation Speed: [Slow][Normal][Fast] │
│                                         │
│   ─── ACCESSIBILITY ───                 │
│   Colorblind Mode: [OFF] [Type1] [Type2]│
│   High Contrast:   [ON] [OFF]           │
│   Screen Reader:   [ON] [OFF]           │
│                                         │
│   [APPLY]  [DEFAULTS]  [BACK]           │
│                                         │
└─────────────────────────────────────────┘
```

### Multiplayer Menu

```
┌─────────────────────────────────────────┐
│                                         │
│           MULTIPLAYER                   │
│                                         │
│   ┌─────────────────────────────┐       │
│   │      LOCAL (Same Screen)    │       │
│   └─────────────────────────────┘       │
│   ┌─────────────────────────────┐       │
│   │      ONLINE LOBBY           │       │
│   └─────────────────────────────┘       │
│   ┌─────────────────────────────┐       │
│   │      HOST PRIVATE GAME      │       │
│   └─────────────────────────────┘       │
│   ┌─────────────────────────────┐       │
│   │      JOIN BY CODE           │       │
│   └─────────────────────────────┘       │
│                                         │
│   [BACK]                                │
│                                         │
└─────────────────────────────────────────┘
```

---

## In-Game HUD Design

### During Gameplay

```
┌─────────────────────────────────────────────────────────────────┐
│ PLAYER 1: ●●●●●●●●●● (15)          PLAYER 2: ○○○○○○○○ (12)      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   ┌───────────────────────────────────────────┐  ┌───────────┐  │
│   │                                           │  │  POWERS   │  │
│   │                                           │  │           │  │
│   │                                           │  │ [Destroy] │  │
│   │                                           │  │ [JumpPrf] │  │
│   │              GAME BOARD                   │  │ [MoveAgn] │  │
│   │                                           │  │ [Teach R] │  │
│   │                                           │  │           │  │
│   │                                           │  │  ───────  │  │
│   │                                           │  │ Selected: │  │
│   │                                           │  │  Piece 7  │  │
│   └───────────────────────────────────────────┘  └───────────┘  │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  YOUR TURN        [⏱ 0:45]        [💬 Chat]  [⚙ Menu]  [❓Help] │
└─────────────────────────────────────────────────────────────────┘
```

### HUD Elements

| Element | Purpose |
|---------|---------|
| Piece Count | Shows remaining pieces per player |
| Power Panel | Lists powers on selected piece |
| Turn Indicator | Whose turn / AI thinking |
| Timer | Time remaining (if enabled) |
| Quick Actions | Chat, Menu, Help buttons |

### AI Opponent Indicator

```
┌─────────────────────────────────────┐
│  🤖 AI (Hard) is thinking...       │
│  [████████░░░░░░░░░░░░] 2.1s       │
└─────────────────────────────────────┘
```

---

## Visual Style Reference

### Original Quadradius Aesthetic

- **Theme**: Industrial, metallic, sci-fi
- **Colors**: Dark grays, deep reds, muted greens
- **Textures**: Weathered metal, scratches, rivets
- **Typography**: LED dot-matrix, monospace
- **Effects**: Glows, energy pulses, explosions

### NNQR Style Considerations

| Element | Original | NNQR Option |
|---------|----------|-------------|
| Board | 2D top-down with 3D effects | True 3D isometric |
| Pieces | Flat torus shapes | 3D rendered pieces |
| Powers | Icon-based | Animated icons + tooltips |
| Terrain | Elevation shading | Full 3D elevation |
| Effects | Flash animations | Modern particle systems |

---

## Sources

- [JayIsGames Review](https://jayisgames.com/review/quadradius.php) - Custom game options
- [Pong and Beyond](https://pongandbeyond.wordpress.com/2011/03/21/game-40-quadradius/) - Interface details
- [Isley Unruh](https://isleyunruh.com/brilliant-board-games-3-quadradius/) - Board size, piece count, power system
- [MobyGames](https://www.mobygames.com/game/206703/quadradius/) - Technical specs
- [QuadradiusR GitHub](https://github.com/Fruktus/QuadradiusR) - Reimplementation reference
