# Quadradius Web Interface Reference

> Research Date: 2025-12-14
> Source: https://quadradius.ddns.net/

## Visual Design

### Aesthetic Theme
- **Industrial/Metallic**: Weathered metal panel appearance
- **Color Palette**:
  - Background: Dark gray/black
  - Panels: Weathered gray metal with visible screws
  - Primary buttons: Deep maroon/red (#8B0000 range)
  - Secondary buttons: Muted olive/green (#808000 range)
  - Accent: Steel blue (#4682B4 range)
  - Text: LED-style dot matrix font (red on dark)
- **Corner screws**: Decorative metal screws on panel corners
- **Scratched/worn texture**: Subtle wear marks on metal surfaces

### Typography
- **Display text**: Custom dot-matrix/LED style font
- **All caps**: Navigation and headers use uppercase
- **Monospace**: Stats and data displays

---

## Login Screen

### Layout Elements

```
┌─────────────────────────────┐
│  ┌───────────────────────┐  │
│  │                       │  │
│  │    [Q LOGO]           │  │
│  │    QUADRADIUS         │  │
│  │                       │  │
│  └───────────────────────┘  │
│                             │
│  ┌───────────────────────┐  │
│  │  LEARN THE GAME       │  │ ← Blue button
│  └───────────────────────┘  │
│                             │
│  ┌───────────────────────┐  │
│  │  Player               │  │ ← Guest name input
│  └───────────────────────┘  │
│                             │
│  ┌───────────────────────┐  │
│  │      START            │  │ ← Red/orange button
│  └───────────────────────┘  │
│                             │
│  ┌───────────────────────┐  │
│  │  Member Name          │  │ ← Member login
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │  Password             │  │
│  └───────────────────────┘  │
└─────────────────────────────┘
```

### Components

| Element | Style | Purpose |
|---------|-------|---------|
| Logo Panel | Inset gray with Q symbol | Branding |
| Learn The Game | Blue button | Tutorial access |
| Player Input | Dark maroon field | Guest username |
| START | Large red button | Begin as guest |
| Member Name | Dark maroon field | Registered login |
| Password | Dark maroon field | Account auth |

### Logo Design
- Circle with diagonal line through it
- Two dots at circle edge (representing game pieces)
- "QUADRADIUS" text below in spaced letters

---

## Main Lobby Screen

### Layout Structure

```
┌──────────┬─────────────────────────────────┬──────────────────────┐
│          │  Player GUEST ▼ │ COMMUNIQUÉ   │      STATS           │
│  LOGO    │  ┌─────────────┐ ┌────────────┐│ MOST RECENT BATTLES  │
│          │  │             │ │            ││ [Match history list] │
│ NAV MENU │  │ Player List │ │ Chat Area  ││                      │
│          │  │             │ │            ││                      │
│ - Stats  │  └─────────────┘ └────────────┘│                      │
│ - Members│     OPPONENTS                  │                      │
│ - News   │                                │                      │
│ - Direct.├────────────────────────────────┤──────────────────────┤
│ - About  │  # QRNews          2025.04.03 #│    DECEMBER 2025     │
│ - Press  │  Join Discord to register:     │ RANK MEMBER  % W/G   │
│ - Fans   │  discord.gg/cVkV8pah4d         │ 001  f133t   55.6    │
│ - Board  │  Registration remains free     │ 002  DaBinD  70.8    │
│ - Merch  │                                │ 003  QRsaurus 75.0   │
│ - Contact│  Welcome to Quadradius         │ ...                  │
│          │  90 GUEST was here 5 min ago   │    MEMBER STATS      │
│          │  Click to challenge!           │                      │
└──────────┴────────────────────────────────┴──────────────────────┘
```

### Left Sidebar Navigation

| Button | Function |
|--------|----------|
| FACEBOOK | Social link |
| STATS | View statistics |
| MEMBERS | Member directory |
| NEWS | Game updates |
| DIRECTIONS | Game rules/help |
| ABOUT | Game information |
| PRESS/REVIEWS | Media coverage |
| FAN CREATIONS | Community content |
| QUADBOARD | Leaderboard |
| MERCHANDISE | Store |
| CONTACT | Support |

### Center Panel - Matchmaking

#### Player List
- Dropdown showing "Player GUEST"
- Lists online players available to challenge
- Scrollable list with scroll arrows

#### Opponents Section
- Shows available opponents
- "Click on a person above to challenge them to a Quadradius Battle!"

#### Communiqué (Chat)
- Message display area
- Text input field at bottom
- Real-time chat between players

#### News Panel
- Date-stamped announcements
- Discord invite link for registration
- Welcome message
- Recent activity ("90 GUEST was here 5 minutes ago")

### Right Panel - Statistics

#### Most Recent Battles
| Column | Content |
|--------|---------|
| Match | "PlayerA beat PlayerB" |
| Score | e.g., "2-0", "7-4" |
| Time | Match duration (mm:ss) |

Example entries:
- em GUEST beat Clignote (2-0, 14:06)
- Clignote beat em GUEST (6-0, 7:37)
- DaBinD beat dancomono (7-4, 11:01)

#### Member Stats (Monthly Leaderboard)
| Column | Content |
|--------|---------|
| RANK | Position (001, 002...) |
| MEMBER NAME | Username |
| % | Win percentage |
| WINS/GAMES | Win count / Total games |

Top ranked players (December 2025):
1. f133t - 55.6% (15/27)
2. DaBinD - 70.8% (34/48)
3. QRsaurus Rex - 75.0% (12/16)
4. zakzyz - 78.6% (11/14)
5. lOde - 71.4% (10/14)

#### Ranking System
- "TO RANK: 000 WINS > 0.0%" indicator
- Monthly competition cycles
- Persistent statistics for members

---

## UI Components Reference

### Buttons

#### Primary Action (Red/Maroon)
```css
background: linear-gradient(#8B0000, #5C0000);
border: 2px inset #3C0000;
color: #FF4444;
font-family: "LED Dot Matrix";
text-transform: uppercase;
```

#### Secondary Action (Olive/Green)
```css
background: linear-gradient(#6B6B00, #4A4A00);
border: 2px inset #2A2A00;
color: #AAAA00;
```

#### Accent (Blue)
```css
background: linear-gradient(#4A7090, #2A4A60);
border: 2px inset #1A3040;
color: #AACCEE;
```

### Input Fields
```css
background: #3C0000;
border: 2px inset #2C0000;
color: #FF4444;
font-family: "LED Dot Matrix";
```

### Panels
```css
background: #808080;
border: 3px ridge #606060;
box-shadow: inset 0 0 10px rgba(0,0,0,0.5);
/* Corner screws as pseudo-elements */
```

### Data Tables
```css
background: #1A1A2A;
border: 2px solid #3A3A4A;
font-family: monospace;
color: #AAAAAA;
/* Alternating row colors for readability */
```

---

## NNQR Implementation Notes

### For Rust/Bevy
- Consider egui or bevy_ui for similar industrial aesthetic
- LED dot-matrix font can be achieved with bitmap fonts
- Metal texture as background sprites

### For Lua/Love2D
- Similar achievable with love.graphics
- Nine-slice panels for scalable metal frames
- Custom bitmap font for LED text

### Key Features to Replicate
1. Guest vs Member login flow
2. Real-time player list
3. Challenge system (click to challenge)
4. Chat/communiqué system
5. Live match history
6. Monthly leaderboard
7. Statistics tracking

### Networking Requirements
- WebSocket or similar for real-time updates
- Player presence system
- Match history storage
- Leaderboard calculations
