# Building Love2D isometric game

**Session ID:** ses_4e280f915ffeLjPOa1fPBfR7kp
**Created:** 12/14/2025, 10:33:42 AM
**Updated:** 12/14/2025, 9:32:24 PM

---

## User

---

## Assistant

Let me check the current state of the codebase to continue from where we left off.

```
Tool: read
```

```
Tool: bash
```

```
Tool: read
```

---

## Assistant

Good, I see the current state. Step 1 (Indicators module) is complete with tests. Now I need to continue with **Step 2: Add persistent indicator rendering in `Game.drawPieces()`**.

```
Tool: todowrite
```

---

## Assistant

Now I'll add the persistent indicator rendering in `Game.drawPieces()`. The indicators should be drawn after the piece body and power count badge, but before the selection ring.

Looking at `drawPieces()` (lines 259-327), I need to add the indicator rendering between line 309 (after power badge) and line 311 (before selection ring).

```
Tool: edit
```

---

## Assistant

```
Tool: read
```

---

## Assistant

Good, the require was added. Now let me add the indicator rendering code. I need to insert it after the power badge (line 309) and before the selection ring (line 312):

```
Tool: read
```

---

## Assistant

Now I'll add the persistent indicator rendering between the power badge (line 310) and the selection ring (line 312):

```
Tool: edit
```

---

## Assistant

Let me check for syntax issues:

```
Tool: bash
```

---

## Assistant

```
Tool: bash
```

---

## Assistant

```
Tool: bash
```

---

## Assistant

All 381 tests pass. The code is working. Let me verify the indicator rendering is in place:

```
Tool: read
```

---

## Assistant

Step 2 is complete. Now let me update the todo and move on to Step 4 - updating the Jump Proof activation animation to show the wrap-on effect:

```
Tool: todowrite
```

---

## Assistant

Now let me update the Jump Proof animation to show armor bands wrapping on (instead of shield bubble):

```
Tool: read
```

---

## Assistant

Now I'll update the Jump Proof animation to show armor bands wrapping around instead of a shield bubble:

```
Tool: edit
```

---

## Assistant

```
Tool: bash
```

---

## Assistant

Tests pass. Now let me update the Move Diagonal animation to show lines extending outward:

```
Tool: todowrite
```

---

## Assistant

```
Tool: read
```

---

## Assistant

Now let me update the Move Diagonal animation to show lines extending outward:

```
Tool: edit
```

---

## Assistant

```
Tool: bash
```

---

## Assistant

All tests pass. Now let me update the progress doc and then format the code:

```
Tool: todowrite
```

---

## Assistant

```
Tool: read
```

---

## Assistant

Now let me update the progress document:

```
Tool: edit
```

---

## Assistant

```
Tool: edit
```

---

## Assistant

```
Tool: edit
```

---

## Assistant

```
Tool: edit
```

---

## Assistant

Now let me add a Phase 4C section:

```
Tool: edit
```

---

## Assistant

Now let me format the code and run final tests:

```
Tool: todowrite
```

---

## Assistant

```
Tool: bash
```

---

## Assistant

All 381 tests pass. Let me check git status:

```
Tool: bash
```

---

## Assistant

```
Tool: todowrite
```

---

## Assistant

**Phase 4C complete!** Here's a summary of what was done:

## Completed - Phase 4C: Persistent Power Indicators

### Files Created
- `src/shared/indicators.lua` - Indicators module (29 lines)
- `spec/indicators_spec.lua` - 5 tests for indicator detection
- `docs/phase4c_indicators.md` - Plan document

### Files Modified
- `src/game.lua`:
  - Added `require` for Indicators module
  - Added persistent indicator rendering in `drawPieces()`:
    - **Jump Proof**: 2 metallic cyan armor bands wrapped around torus
    - **Move Diagonal**: 4 short green diagonal lines extending from piece
    - **Invisible**: Subtle shimmer effect overlay
  - Updated Jump Proof animation to show armor bands wrapping on
  - Updated Move Diagonal animation to show lines extending outward
- `docs/progress.md` - Updated test count and added Phase 4C section

### Test Count
**381 tests passing** (+5 from Phase 4C)

### Ready to Commit
Files staged for commit:
- `docs/phase4c_indicators.md`
- `docs/progress.md`
- `spec/indicators_spec.lua`
- `src/shared/indicators.lua`
- `src/game.lua`

Would you like me to commit these changes?

---

## User

stage the commit, and suggest a message ill commit it

---

## Assistant

```
Tool: bash
```

---

## Assistant

```
Tool: bash
```

---

## Assistant

Staged. Suggested commit message:

```
feat(love2d): add persistent visual indicators for permanent powers
```

---

## User

great what is next?

---

## Assistant

Looking at the project, let me check what's planned and what logical next steps would be:

```
Tool: read
```

---

## Assistant

```
Tool: read
```

---

## Assistant

Based on the progress tracker, **Phase 5: Polish & Integration** is next. Here are the options:

## Next Steps - Phase 5 Options

| Option | Description | Complexity |
|--------|-------------|------------|
| **Sound System** | Add audio feedback for moves, power activations, captures | Medium |
| **Particle Effects** | Enhanced visual feedback with Love2D particle system | Medium |
| **Complete UI** | Game menus, settings, better turn indicators | Medium-High |
| **Network Server** | Implement Love2D headless server for multiplayer | High |
| **Performance** | Optimize rendering, reduce allocations | Low |

## My Recommendation

Given the TDD approach and incremental progress, I'd suggest one of these paths:

1. **Complete UI** - Most impactful for playability. Would include:
   - Main menu (New Game, Quit)
   - Player turn banner/indicator improvements
   - Win/lose screen polish
   - Power tooltips on hover

2. **Sound System** - Quick win, adds polish:
   - Move sounds
   - Power activation sounds
   - Capture sounds
   - Background music (optional)

3. **Particle Effects** - Visual polish:
   - Enhance existing animations with Love2D particles
   - Dust on piece movement
   - Sparkles on power pickup

What direction interests you most? Or is there something else you'd like to tackle?

---

## User

lets takle all of these in that order, but make sure its planned 1. Complete UI ,2. Sound System ,3. Particle Effects , make sure its tdd in the plan also

---

## Assistant

I'll create a comprehensive TDD plan for Phase 5. Let me first explore the codebase to understand the current structure and what we're working with.

```
Tool: read
```

```
Tool: read
```

```
Tool: list
```

---

## Assistant

```
Tool: read
```

---

## Assistant

```
Tool: read
```

---

## Assistant

Now let me look at the existing spec structure:

```
Tool: bash
```

---

## Assistant

```
Tool: read
```

---

## Assistant

Now let me check for any existing assets folder:

```
Tool: bash
```

---

## Assistant

```
Tool: bash
```

---

## Assistant

Let me also check what game states exist:

```
Tool: read
```

---

## Assistant

Now I have enough context. Let me create a comprehensive TDD plan for Phase 5.

---

# Phase 5: Polish & Integration - TDD Plan

## Overview

Three sub-phases in order:
1. **Phase 5A: Complete UI** - Menus, improved HUD, tooltips
2. **Phase 5B: Sound System** - Audio feedback for game events
3. **Phase 5C: Particle Effects** - Enhanced visual feedback

---

## Phase 5A: Complete UI

### Goals
- Main menu (New Game, Quit)
- Improved turn indicator/banner
- Better game over screen
- Power tooltips on hover
- Settings menu (optional)

### TDD Approach

**Note:** UI state logic is testable, but rendering is not. We'll create a `UI` module for state management that can be fully tested.

#### Step 1: UI State Module (TDD)
**File:** `src/shared/ui.lua`
**Tests:** `spec/ui_spec.lua`

| Test | Description |
|------|-------------|
| `UI.createState()` returns initial UI state | Default screen is "menu" |
| `UI.getScreen()` returns current screen | "menu", "playing", "gameover", "settings" |
| `UI.setScreen()` changes current screen | Validates screen names |
| `UI.getMenuItems()` returns menu items for screen | Different items per screen |
| `UI.selectMenuItem()` changes selected index | Wraps around |
| `UI.getSelectedMenuItem()` returns current selection | Index-based |
| `UI.getHoveredPower()` returns hovered power info | nil if none |
| `UI.setHoveredPower()` sets power tooltip data | powerId, position |
| `UI.clearHoveredPower()` clears tooltip | Returns to nil |

**Estimated tests: ~12**

#### Step 2: Menu System Integration (No Tests)
**File:** `src/game.lua`

- Add UI state to Game
- Draw main menu screen
- Handle menu navigation (arrow keys, enter)
- Draw settings screen (basic)
- Transition between screens

#### Step 3: Turn Banner (No Tests)
**File:** `src/game.lua`

- Large animated "Player X's Turn" banner at turn start
- Fade in/out animation
- Player color themed

#### Step 4: Power Tooltips (No Tests)
**File:** `src/game.lua`

- Hover detection on power menu items
- Tooltip popup with power description
- Position near cursor

#### Step 5: Game Over Polish (No Tests)
**File:** `src/game.lua`

- Larger text, better styling
- Animated elements
- "Main Menu" and "Play Again" options

---

## Phase 5B: Sound System

### Goals
- Sound manager module
- Move sounds
- Power activation sounds
- Capture sounds
- UI feedback sounds

### TDD Approach

**Note:** Actual audio playback requires Love2D, but sound management logic is testable.

#### Step 1: Sound Manager Module (TDD)
**File:** `src/shared/sound_manager.lua`
**Tests:** `spec/sound_manager_spec.lua`

| Test | Description |
|------|-------------|
| `SoundManager.create()` returns manager instance | Initial state with volume settings |
| `SoundManager.setMasterVolume()` sets master volume | Clamps 0-1 |
| `SoundManager.getMasterVolume()` returns master volume | Default 1.0 |
| `SoundManager.setSFXVolume()` sets SFX volume | Clamps 0-1 |
| `SoundManager.getSFXVolume()` returns SFX volume | Default 1.0 |
| `SoundManager.setMusicVolume()` sets music volume | Clamps 0-1 |
| `SoundManager.getMusicVolume()` returns music volume | Default 0.5 |
| `SoundManager.isMuted()` returns mute state | Default false |
| `SoundManager.setMuted()` sets mute state | Boolean |
| `SoundManager.getSoundForEvent()` maps event to sound | "move" → "move.wav" |
| `SoundManager.getSoundForPower()` maps power to sound | "bomb" → "explosion.wav" |

**Estimated tests: ~15**

#### Step 2: Sound Asset Stubs
**Folder:** `assets/sounds/`

Create placeholder `.wav` or `.ogg` files (can be silent 0.1s files initially):
- `move.wav` - Piece movement
- `capture.wav` - Piece capture
- `select.wav` - Piece selection
- `power_activate.wav` - Generic power activation
- `explosion.wav` - Bomb, destroy row/column
- `teleport.wav` - Relocate
- `shield.wav` - Jump proof
- `recruit.wav` - Recruit
- `multiply.wav` - Multiply
- `menu_select.wav` - Menu navigation
- `menu_confirm.wav` - Menu selection

#### Step 3: Sound Integration (No Tests)
**File:** `src/game.lua`

- Initialize SoundManager in Game.init()
- Play sounds on events:
  - Piece selection
  - Piece movement
  - Piece capture
  - Power activation (per power type)
  - Menu navigation

---

## Phase 5C: Particle Effects

### Goals
- Particle system wrapper
- Movement dust particles
- Power activation particles
- Capture explosion particles
- Orb collection sparkles

### TDD Approach

**Note:** Love2D ParticleSystem is not testable, but particle configuration is.

#### Step 1: Particle Config Module (TDD)
**File:** `src/shared/particle_config.lua`
**Tests:** `spec/particle_config_spec.lua`

| Test | Description |
|------|-------------|
| `ParticleConfig.get("dust")` returns dust config | emission, lifetime, speed, colors |
| `ParticleConfig.get("explosion")` returns explosion config | More particles, faster |
| `ParticleConfig.get("sparkle")` returns sparkle config | Small, slow fade |
| `ParticleConfig.get("teleport")` returns teleport config | Purple colors |
| `ParticleConfig.get("power_orb")` returns orb pickup config | Yellow/gold |
| `ParticleConfig.getAll()` returns all configs | Table of all |
| `ParticleConfig.validate()` validates config structure | Required fields |

**Estimated tests: ~10**

#### Step 2: Particle Manager (Minimal TDD)
**File:** `src/shared/particles.lua`
**Tests:** `spec/particles_spec.lua`

| Test | Description |
|------|-------------|
| `Particles.create()` returns manager instance | Empty active list |
| `Particles.emit()` queues particle emission | Type, position, count |
| `Particles.getPendingEmissions()` returns queue | For Love2D to process |
| `Particles.clearPending()` clears queue | After processing |

**Estimated tests: ~6**

#### Step 3: Love2D Particle Integration (No Tests)
**File:** `src/game.lua`

- Create Love2D ParticleSystems from configs
- Process pending emissions each frame
- Emit particles on:
  - Piece movement (dust trail)
  - Piece capture (explosion)
  - Power activation (per-power effects)
  - Orb collection (sparkles)

---

## Summary

| Phase | New Tests | New Files | Modified Files |
|-------|-----------|-----------|----------------|
| 5A: UI | ~12 | `ui.lua`, `ui_spec.lua` | `game.lua`, `main.lua` |
| 5B: Sound | ~15 | `sound_manager.lua`, `sound_manager_spec.lua`, sound assets | `game.lua` |
| 5C: Particles | ~16 | `particle_config.lua`, `particles.lua`, specs | `game.lua` |
| **Total** | **~43** | **7 modules + assets** | **2** |

---

## Questions for You

1. **Main Menu**: Should it have background visuals (animated board) or simple solid color?

2. **Sound Assets**: Should I generate placeholder silent files, or would you provide actual sound files?

3. **Settings Menu**: Include volume controls in Phase 5A, or defer to later?

4. **Particle Complexity**: Simple particles (circles/squares) or should we plan for sprite-based particles?

5. **Turn Banner Animation**: Subtle fade, or more dramatic slide-in effect?

---

## User

1, animated is fine, 2 place holders are fine for now 3, yes have a sound settings menu, explain 4 more, explain 5 more

---

## Assistant

Great questions! Let me elaborate on #4 and #5, and also detail the sound settings menu.

---

## #3: Sound Settings Menu - Details

The settings menu would be accessible from the main menu and include:

```
┌─────────────────────────────┐
│       SETTINGS              │
├─────────────────────────────┤
│  Master Volume    [████░░] 70%  │
│  SFX Volume       [██████] 100% │
│  Music Volume     [███░░░] 50%  │
│                             │
│  [x] Sound Enabled          │
│                             │
│  < Back                     │
└─────────────────────────────┘
```

**Interactions:**
- Left/Right arrows adjust selected volume (10% increments)
- Enter toggles checkboxes
- Escape or "Back" returns to main menu

**TDD additions to UI module:**
- `UI.adjustVolume(setting, delta)` - Adjust volume by delta
- `UI.toggleSoundEnabled()` - Toggle mute
- `UI.getVolumeSettings()` - Return current settings

---

## #4: Particle Complexity - Options Explained

### Option A: Simple Geometric Particles
Use Love2D's built-in shapes (circles, rectangles).

**Pros:**
- No external assets needed
- Easy to implement
- Fast to render
- Fully procedural

**Example effects:**
- **Dust**: Small brown/gray circles that fade
- **Explosion**: Orange/red circles expanding outward
- **Sparkle**: Tiny white/yellow circles with quick fade
- **Teleport**: Purple circles spiraling

**Visual quality:** Clean, minimal, matches the current art style

---

### Option B: Sprite-Based Particles
Use small texture images for particles.

**Pros:**
- More visually rich
- Can have complex shapes (stars, smoke puffs, energy wisps)
- Professional look

**Cons:**
- Requires creating/sourcing sprite assets
- More complex to set up
- Slightly more overhead

**Example assets needed:**
- `particle_circle.png` (soft gradient circle)
- `particle_star.png` (4-point star)
- `particle_smoke.png` (wispy smoke)
- `particle_spark.png` (small bright point)

---

### Option C: Hybrid Approach (Recommended)
Start with simple geometric particles, but design the system to support sprites later.

**Implementation:**
1. `ParticleConfig` includes optional `sprite` field
2. If no sprite, use geometric shape
3. Can upgrade individual effects to sprites over time

**This gives us:**
- Quick implementation now
- Flexibility to enhance later
- No blocking on asset creation

---

## #5: Turn Banner Animation - Options Explained

### Option A: Subtle Fade
```
[Turn starts]
  - Banner fades in over 0.3s
  - Stays visible for 1.5s
  - Fades out over 0.3s
```

**Visual:** Clean, unobtrusive, doesn't interrupt flow.

**Best for:** Fast-paced gameplay, experienced players.

---

### Option B: Slide-In Effect
```
[Turn starts]
  - Banner slides in from top (or side)
  - Slight bounce/overshoot at rest
  - Stays 1.5s
  - Slides out
```

**Visual:** More dynamic, draws attention clearly.

**Best for:** Emphasizing turn changes, newer players.

---

### Option C: Dramatic Sweep (Recommended)
```
[Turn starts]
  - Dark overlay sweeps across screen (0.2s)
  - "PLAYER 1'S TURN" scales up from center with player color glow
  - Brief pulse/glow effect
  - Everything fades out together (0.3s)
```

**Visual:** Exciting, game-show feel, clear turn indication.

**Could include:**
- Player color accent (blue/red gradient behind text)
- Subtle screen shake (2-3 pixels)
- Sound effect trigger point

---

### Option D: Minimal Corner Indicator
```
[Turn starts]
  - Small banner appears in corner
  - Pulses player color
  - Stays until first action
```

**Visual:** Least intrusive, always visible.

**Best for:** Competitive play, minimal distraction.

---

## My Recommendations

| Item | Recommendation | Reasoning |
|------|----------------|-----------|
| Particles | **Option C: Hybrid** | Quick start, future flexibility |
| Turn Banner | **Option C: Dramatic Sweep** | Matches power animation style, clear feedback |

---

## Updated Test Estimates

With sound settings menu additions:

| Phase | Tests |
|-------|-------|
| 5A: UI (with settings) | ~18 |
| 5B: Sound | ~15 |
| 5C: Particles | ~16 |
| **Total** | **~49** |

---

What are your preferences for #4 and #5? Once confirmed, I'll finalize the full plan document.

---

## User

I am in agreement with your suggestion of option c for both 4 and 5 

---

## Assistant

Excellent! Let me finalize the comprehensive Phase 5 plan document.

```
Tool: todowrite
```

---

## Assistant

---

# Phase 5: Polish & Integration - Final TDD Plan

## Overview

| Phase | Focus | New Tests | Commits |
|-------|-------|-----------|---------|
| 5A | Complete UI | ~18 | 2-3 |
| 5B | Sound System | ~15 | 2 |
| 5C | Particle Effects | ~16 | 2 |
| **Total** | | **~49** | **6-7** |

---

## Phase 5A: Complete UI

### Step 1: UI State Module (TDD)

**New Files:**
- `src/shared/ui.lua`
- `spec/ui_spec.lua`

**Tests to Write (RED phase):**

```lua
describe("UI", function()
  describe("createState", function()
    it("returns initial state with menu screen")
    it("has selectedIndex of 1")
    it("has nil hoveredPower")
    it("has default volume settings")
  end)

  describe("screen management", function()
    it("getScreen returns current screen")
    it("setScreen changes to valid screen")
    it("setScreen rejects invalid screen names")
    it("setScreen resets selectedIndex to 1")
  end)

  describe("menu navigation", function()
    it("getMenuItems returns items for main menu")
    it("getMenuItems returns items for settings")
    it("getMenuItems returns items for gameover")
    it("selectNext increments selectedIndex")
    it("selectNext wraps to 1 at end")
    it("selectPrev decrements selectedIndex")
    it("selectPrev wraps to end at 1")
    it("getSelectedMenuItem returns current item")
  end)

  describe("power tooltips", function()
    it("getHoveredPower returns nil initially")
    it("setHoveredPower stores power info")
    it("clearHoveredPower resets to nil")
  end)

  describe("volume settings", function()
    it("getMasterVolume returns default 1.0")
    it("setMasterVolume clamps to 0-1")
    it("getSFXVolume returns default 1.0")
    it("setSFXVolume clamps to 0-1")
    it("getMusicVolume returns default 0.5")
    it("setMusicVolume clamps to 0-1")
    it("isMuted returns false by default")
    it("setMuted toggles mute state")
    it("adjustVolume changes by delta")
  end)
end)
```

**Estimated: 18 tests**

**Implementation (GREEN phase):**

```lua
-- src/shared/ui.lua structure
local UI = {}

UI.SCREENS = { "menu", "playing", "settings", "gameover" }

UI.MENU_ITEMS = {
  menu = { "New Game", "Settings", "Quit" },
  settings = { "Master Volume", "SFX Volume", "Music Volume", "Sound Enabled", "Back" },
  gameover = { "Play Again", "Main Menu" },
}

function UI.createState() end
function UI.getScreen(state) end
function UI.setScreen(state, screen) end
function UI.getMenuItems(state) end
function UI.selectNext(state) end
function UI.selectPrev(state) end
function UI.getSelectedMenuItem(state) end
function UI.setHoveredPower(state, powerId, x, y) end
function UI.getHoveredPower(state) end
function UI.clearHoveredPower(state) end
function UI.getMasterVolume(state) end
function UI.setMasterVolume(state, vol) end
-- ... etc

return UI
```

---

### Step 2: Menu System Integration (No Tests - Love2D specific)

**Modify:** `src/game.lua`, `main.lua`

**Changes:**
1. Add `Game.uiState = UI.createState()` to `Game.init()`
2. Add `Game.drawMenu()` function for main menu screen
3. Add `Game.drawSettings()` function for settings screen
4. Update `Game.draw()` to check current screen
5. Update `Game.keypressed()` for menu navigation
6. Add animated board background for menu (reuse existing draw code)

**Menu Layout:**
```
┌─────────────────────────────────────────────┐
│                                             │
│            ╔═══════════════════╗            │
│            ║   QUADRADIUS      ║            │
│            ║   NNQR Edition    ║            │
│            ╚═══════════════════╝            │
│                                             │
│              > New Game                     │
│                Settings                     │
│                Quit                         │
│                                             │
│    [Animated board in background]           │
│                                             │
└─────────────────────────────────────────────┘
```

**Settings Layout:**
```
┌─────────────────────────────────────────────┐
│                 SETTINGS                    │
│  ─────────────────────────────────────────  │
│                                             │
│    Master Volume    [████████░░]  80%       │
│    SFX Volume       [██████████] 100%       │
│    Music Volume     [█████░░░░░]  50%       │
│                                             │
│    Sound Enabled    [✓]                     │
│                                             │
│              > Back                         │
│                                             │
└─────────────────────────────────────────────┘
```

---

### Step 3: Turn Banner - Dramatic Sweep (No Tests)

**Modify:** `src/game.lua`

**Add to Game state:**
```lua
Game.turnBanner = {
  active = false,
  timer = 0,
  duration = 2.0,
  player = 1
}
```

**Animation Phases (2.0s total):**

| Phase | Time | Effect |
|-------|------|--------|
| Sweep In | 0.0 - 0.2s | Dark overlay sweeps left-to-right |
| Scale Up | 0.2 - 0.5s | "PLAYER X'S TURN" scales from 0 to 1.2 |
| Settle | 0.5 - 0.7s | Text settles to 1.0 scale with bounce |
| Hold | 0.7 - 1.5s | Text visible with subtle glow pulse |
| Fade Out | 1.5 - 2.0s | Everything fades out together |

**Visual Elements:**
- Dark semi-transparent overlay (alpha 0.7)
- Player color gradient behind text
- Text with slight drop shadow
- 2-3 pixel screen shake during sweep

---

### Step 4: Power Tooltips (No Tests)

**Modify:** `src/game.lua`

**Trigger:** Hover over power in power menu (right side)

**Tooltip Content:**
```
┌─────────────────────────┐
│ DESTROY ROW             │
│ ────────────────────    │
│ Destroys all enemy      │
│ pieces in your row.     │
│                         │
│ Type: Offensive         │
│ Use: Single             │
└─────────────────────────┘
```

**Implementation:**
1. Track mouse position over power menu items
2. Set hovered power in UI state
3. Draw tooltip near cursor (offset to stay on screen)
4. Pull description from `Powers.definitions[powerId]`

**Add to Powers.definitions:**
```lua
destroy_row = {
  name = "Destroy Row",
  description = "Destroys all enemy pieces in your row.",
  category = "Offensive",
  duration = "Single use",
  -- existing fields...
}
```

---

### Step 5: Game Over Polish (No Tests)

**Modify:** `src/game.lua`

**Enhanced Game Over Screen:**
```
┌─────────────────────────────────────────────┐
│                                             │
│         ╔═══════════════════════╗           │
│         ║                       ║           │
│         ║   PLAYER 1 WINS!      ║           │
│         ║                       ║           │
│         ╚═══════════════════════╝           │
│                                             │
│              > Play Again                   │
│                Main Menu                    │
│                                             │
│         Final Score: 8 - 0                  │
│         Turns: 24                           │
│                                             │
└─────────────────────────────────────────────┘
```

**Animations:**
- Text scales up with bounce
- Player color pulsing glow
- Confetti particles (Phase 5C integration)

---

## Phase 5B: Sound System

### Step 1: Sound Manager Module (TDD)

**New Files:**
- `src/shared/sound_manager.lua`
- `spec/sound_manager_spec.lua`

**Tests to Write (RED phase):**

```lua
describe("SoundManager", function()
  describe("create", function()
    it("returns manager with default settings")
    it("has master volume of 1.0")
    it("has sfx volume of 1.0")
    it("has music volume of 0.5")
    it("is not muted by default")
  end)

  describe("volume control", function()
    it("setMasterVolume updates value")
    it("setMasterVolume clamps to 0")
    it("setMasterVolume clamps to 1")
    it("setSFXVolume updates value")
    it("setMusicVolume updates value")
    it("getEffectiveVolume combines master and sfx")
    it("getEffectiveVolume returns 0 when muted")
  end)

  describe("event mapping", function()
    it("getSoundForEvent returns sound for move")
    it("getSoundForEvent returns sound for capture")
    it("getSoundForEvent returns sound for select")
    it("getSoundForEvent returns nil for unknown")
    it("getSoundForPower returns sound for bomb")
    it("getSoundForPower returns sound for relocate")
    it("getSoundForPower returns generic for unknown power")
  end)

  describe("sound queue", function()
    it("queueSound adds to pending list")
    it("getPendingSounds returns queue")
    it("clearPending empties queue")
  end)
end)
```

**Estimated: 15 tests**

**Implementation (GREEN phase):**

```lua
-- src/shared/sound_manager.lua structure
local SoundManager = {}

SoundManager.EVENT_SOUNDS = {
  move = "move.ogg",
  capture = "capture.ogg",
  select = "select.ogg",
  menu_move = "menu_select.ogg",
  menu_confirm = "menu_confirm.ogg",
}

SoundManager.POWER_SOUNDS = {
  bomb = "explosion.ogg",
  destroy_row = "explosion.ogg",
  destroy_column = "explosion.ogg",
  relocate = "teleport.ogg",
  jump_proof = "shield.ogg",
  recruit = "recruit.ogg",
  multiply = "multiply.ogg",
  -- default for others
  default = "power_activate.ogg",
}

function SoundManager.create() end
function SoundManager.setMasterVolume(mgr, vol) end
function SoundManager.getMasterVolume(mgr) end
-- ... etc

return SoundManager
```

---

### Step 2: Placeholder Sound Assets

**Create:** `assets/sounds/` directory with placeholder files

**Files needed (11 total):**

| File | Event | Duration |
|------|-------|----------|
| `move.ogg` | Piece movement | 0.2s |
| `capture.ogg` | Piece capture | 0.3s |
| `select.ogg` | Piece selection | 0.1s |
| `power_activate.ogg` | Generic power | 0.4s |
| `explosion.ogg` | Bomb, destroy row/col | 0.5s |
| `teleport.ogg` | Relocate | 0.4s |
| `shield.ogg` | Jump proof | 0.3s |
| `recruit.ogg` | Recruit | 0.4s |
| `multiply.ogg` | Multiply | 0.3s |
| `menu_select.ogg` | Menu navigation | 0.1s |
| `menu_confirm.ogg` | Menu selection | 0.2s |

**Note:** Will generate silent placeholder OGG files. Can be replaced with real sounds later.

---

### Step 3: Sound Integration (No Tests)

**Modify:** `src/game.lua`

**Add:**
```lua
Game.soundManager = nil
Game.sounds = {}  -- Love2D Source objects

function Game.initSounds()
  Game.soundManager = SoundManager.create()
  -- Load all sound files into Game.sounds table
end

function Game.playSound(event)
  local soundFile = SoundManager.getSoundForEvent(Game.soundManager, event)
  if soundFile and Game.sounds[soundFile] then
    local vol = SoundManager.getEffectiveVolume(Game.soundManager, "sfx")
    Game.sounds[soundFile]:setVolume(vol)
    Game.sounds[soundFile]:play()
  end
end

function Game.playPowerSound(powerId)
  local soundFile = SoundManager.getSoundForPower(Game.soundManager, powerId)
  -- similar to above
end
```

**Integration Points:**
- `Game.mousepressed` → `playSound("select")` on piece select
- `GameLogic.movePiece` callback → `playSound("move")` or `playSound("capture")`
- `Game.executepower` → `playPowerSound(powerId)`
- Menu navigation → `playSound("menu_move")` / `playSound("menu_confirm")`

---

## Phase 5C: Particle Effects

### Step 1: Particle Config Module (TDD)

**New Files:**
- `src/shared/particle_config.lua`
- `spec/particle_config_spec.lua`

**Tests to Write (RED phase):**

```lua
describe("ParticleConfig", function()
  describe("get", function()
    it("returns config for dust")
    it("returns config for explosion")
    it("returns config for sparkle")
    it("returns config for teleport")
    it("returns config for power_orb")
    it("returns config for confetti")
    it("returns nil for unknown type")
  end)

  describe("config structure", function()
    it("dust has required fields")
    it("explosion has higher particle count than dust")
    it("sparkle has slower speed than explosion")
    it("each config has colors array")
    it("each config has lifetime range")
  end)

  describe("getAll", function()
    it("returns table of all configs")
    it("contains at least 5 types")
  end)
end)
```

**Estimated: 10 tests**

**Implementation (GREEN phase):**

```lua
-- src/shared/particle_config.lua
local ParticleConfig = {}

ParticleConfig.configs = {
  dust = {
    particleCount = 8,
    emissionRate = 50,
    lifetime = { 0.3, 0.6 },
    speed = { 20, 40 },
    direction = { -math.pi, 0 },  -- upward spread
    spread = math.pi / 4,
    size = { 2, 4 },
    colors = {
      { 0.6, 0.5, 0.4, 1.0 },  -- start: brown
      { 0.6, 0.5, 0.4, 0.0 },  -- end: fade out
    },
    shape = "circle",  -- or "sprite" later
  },
  
  explosion = {
    particleCount = 24,
    emissionRate = 200,
    lifetime = { 0.4, 0.8 },
    speed = { 80, 150 },
    direction = 0,
    spread = math.pi * 2,  -- all directions
    size = { 3, 8 },
    colors = {
      { 1.0, 0.8, 0.2, 1.0 },  -- yellow
      { 1.0, 0.4, 0.1, 0.8 },  -- orange
      { 0.8, 0.2, 0.1, 0.0 },  -- red fade
    },
    shape = "circle",
  },

  sparkle = {
    particleCount = 12,
    emissionRate = 80,
    lifetime = { 0.5, 1.0 },
    speed = { 10, 30 },
    direction = -math.pi / 2,  -- upward
    spread = math.pi / 3,
    size = { 1, 3 },
    colors = {
      { 1.0, 1.0, 0.8, 1.0 },  -- white/yellow
      { 1.0, 0.9, 0.5, 0.0 },  -- fade
    },
    shape = "circle",
  },

  teleport = {
    particleCount = 16,
    emissionRate = 100,
    lifetime = { 0.3, 0.5 },
    speed = { 40, 80 },
    direction = 0,
    spread = math.pi * 2,
    size = { 2, 5 },
    colors = {
      { 0.7, 0.3, 1.0, 1.0 },  -- purple
      { 0.5, 0.2, 0.8, 0.0 },  -- fade
    },
    shape = "circle",
  },

  power_orb = {
    particleCount = 10,
    emissionRate = 60,
    lifetime = { 0.4, 0.7 },
    speed = { 20, 50 },
    direction = -math.pi / 2,
    spread = math.pi / 2,
    size = { 2, 4 },
    colors = {
      { 1.0, 0.9, 0.3, 1.0 },  -- gold
      { 1.0, 0.8, 0.2, 0.0 },  -- fade
    },
    shape = "circle",
  },

  confetti = {
    particleCount = 30,
    emissionRate = 150,
    lifetime = { 1.0, 2.0 },
    speed = { 50, 100 },
    direction = math.pi / 2,  -- downward
    spread = math.pi / 4,
    size = { 3, 6 },
    colors = {
      { 1.0, 0.3, 0.3, 1.0 },  -- red
      { 0.3, 1.0, 0.3, 1.0 },  -- green
      { 0.3, 0.3, 1.0, 1.0 },  -- blue
      { 1.0, 1.0, 0.3, 1.0 },  -- yellow
    },
    gravity = { 0, 100 },  -- falls down
    shape = "rectangle",
  },
}

function ParticleConfig.get(type) end
function ParticleConfig.getAll() end

return ParticleConfig
```

---

### Step 2: Particle Manager Module (TDD)

**New Files:**
- `src/shared/particles.lua`
- `spec/particles_spec.lua`

**Tests to Write (RED phase):**

```lua
describe("Particles", function()
  describe("create", function()
    it("returns manager with empty pending queue")
    it("returns manager with empty active list")
  end)

  describe("emit", function()
    it("queues emission with type and position")
    it("queues emission with optional count override")
    it("accepts x, y coordinates")
  end)

  describe("pending queue", function()
    it("getPendingEmissions returns all queued")
    it("clearPending empties the queue")
    it("multiple emits accumulate in queue")
  end)

  describe("emission data", function()
    it("emission contains type field")
    it("emission contains x, y position")
    it("emission contains count field")
  end)
end)
```

**Estimated: 6 tests**

**Implementation (GREEN phase):**

```lua
-- src/shared/particles.lua
local Particles = {}

function Particles.create()
  return {
    pending = {},
    active = {},  -- For Love2D ParticleSystems
  }
end

function Particles.emit(manager, type, x, y, count)
  table.insert(manager.pending, {
    type = type,
    x = x,
    y = y,
    count = count,
  })
end

function Particles.getPendingEmissions(manager)
  return manager.pending
end

function Particles.clearPending(manager)
  manager.pending = {}
end

return Particles
```

---

### Step 3: Love2D Particle Integration (No Tests)

**Modify:** `src/game.lua`

**Add:**
```lua
Game.particles = nil
Game.particleSystems = {}  -- Love2D ParticleSystem objects

function Game.initParticles()
  Game.particles = Particles.create()
  
  -- Create a ParticleSystem for each type
  for type, config in pairs(ParticleConfig.getAll()) do
    local ps = love.graphics.newParticleSystem(Game.particleImage, config.particleCount)
    ps:setParticleLifetime(config.lifetime[1], config.lifetime[2])
    ps:setSpeed(config.speed[1], config.speed[2])
    ps:setDirection(config.direction)
    ps:setSpread(config.spread)
    ps:setSizes(config.size[1] / 10, config.size[2] / 10)  -- normalized
    ps:setColors(unpack(config.colors))
    if config.gravity then
      ps:setLinearAcceleration(config.gravity[1], config.gravity[2])
    end
    Game.particleSystems[type] = ps
  end
end

function Game.updateParticles(dt)
  -- Process pending emissions
  for _, emission in ipairs(Particles.getPendingEmissions(Game.particles)) do
    local ps = Game.particleSystems[emission.type]
    if ps then
      ps:setPosition(emission.x, emission.y)
      ps:emit(emission.count or ParticleConfig.get(emission.type).particleCount)
    end
  end
  Particles.clearPending(Game.particles)
  
  -- Update all particle systems
  for _, ps in pairs(Game.particleSystems) do
    ps:update(dt)
  end
end

function Game.drawParticles()
  for _, ps in pairs(Game.particleSystems) do
    love.graphics.draw(ps)
  end
end
```

**Integration Points:**
- Piece movement → `Particles.emit(particles, "dust", x, y)`
- Piece capture → `Particles.emit(particles, "explosion", x, y)`
- Power: bomb/destroy → `Particles.emit(particles, "explosion", x, y)`
- Power: relocate → `Particles.emit(particles, "teleport", x, y)`
- Orb collection → `Particles.emit(particles, "power_orb", x, y)`
- Game over (win) → `Particles.emit(particles, "confetti", x, y)`

---

## Execution Order

### Phase 5A: Complete UI (~18 tests)
1. Write `spec/ui_spec.lua` tests (RED)
2. Implement `src/shared/ui.lua` (GREEN)
3. Run tests, verify 18 new tests pass
4. Add menu rendering to `game.lua`
5. Add settings screen
6. Add turn banner animation
7. Add power tooltips
8. Add game over polish
9. **Commit:** `feat(love2d): add complete UI with menus, settings, and turn banners`

### Phase 5B: Sound System (~15 tests)
1. Write `spec/sound_manager_spec.lua` tests (RED)
2. Implement `src/shared/sound_manager.lua` (GREEN)
3. Run tests, verify 15 new tests pass
4. Create placeholder sound assets
5. Add sound loading and playback to `game.lua`
6. Integrate sounds with game events
7. **Commit:** `feat(love2d): add sound system with configurable volume`

### Phase 5C: Particle Effects (~16 tests)
1. Write `spec/particle_config_spec.lua` tests (RED)
2. Implement `src/shared/particle_config.lua` (GREEN)
3. Write `spec/particles_spec.lua` tests (RED)
4. Implement `src/shared/particles.lua` (GREEN)
5. Run tests, verify 16 new tests pass
6. Add particle system initialization to `game.lua`
7. Integrate particles with game events
8. **Commit:** `feat(love2d): add particle effects for movement and powers`

---

## Final Test Count Projection

| Current | Phase 5A | Phase 5B | Phase 5C | Total |
|---------|----------|----------|----------|-------|
| 381 | +18 | +15 | +16 | **430** |

---

## Questions Before Execution

1. **Sound file format:** `.ogg` is preferred for Love2D. Is that OK, or prefer `.wav`?

2. **Particle image:** Should I create a simple 8x8 white circle PNG for the particle system, or use Love2D's built-in circle drawing?

3. **Menu font:** Use default Love2D font, or should I plan for custom font loading later?

4. **Turn banner text:** "PLAYER 1'S TURN" or "BLUE'S TURN" / "RED'S TURN"?

---

## User

1, ogg is fine 2 use love2d, 3 default is fine for now, 4 blue vs red 

---

## Assistant

Good choices! Let me finalize the plan document with all the decisions locked in.

---

# Phase 5: Polish & Integration - Final Plan

## Summary of Decisions

| Item | Decision |
|------|----------|
| Sound format | `.ogg` |
| Particle rendering | Love2D built-in circles (no sprite assets) |
| Font | Default Love2D font |
| Turn banner text | "BLUE'S TURN" / "RED'S TURN" |
| Particles | Hybrid approach (geometric now, sprite-ready later) |
| Turn banner | Dramatic sweep animation |
| Settings menu | Yes, with volume controls |

---

## Execution Plan

### Phase 5A: Complete UI

**Step 1: UI State Module (TDD)**
- Write 18 tests in `spec/ui_spec.lua`
- Implement `src/shared/ui.lua`
- Covers: screen management, menu navigation, tooltips, volume settings

**Step 2: Menu System (No Tests)**
- Modify `game.lua` and `main.lua`
- Main menu with animated board background
- Settings screen with volume sliders
- Menu items: "New Game", "Settings", "Quit"

**Step 3: Turn Banner (No Tests)**
- Dramatic sweep animation (2.0s)
- "BLUE'S TURN" / "RED'S TURN" with player color
- Dark overlay sweep, scale-up text, glow pulse, fade out

**Step 4: Power Tooltips (No Tests)**
- Hover detection on power menu
- Tooltip with name, description, category, duration
- Add descriptions to `Powers.definitions`

**Step 5: Game Over Polish (No Tests)**
- Enhanced styling with player color glow
- Menu options: "Play Again", "Main Menu"
- Final score display (pieces remaining, turns)

---

### Phase 5B: Sound System

**Step 1: Sound Manager Module (TDD)**
- Write 15 tests in `spec/sound_manager_spec.lua`
- Implement `src/shared/sound_manager.lua`
- Covers: volume control, event-to-sound mapping, sound queue

**Step 2: Placeholder Sound Assets**
- Create `assets/sounds/` with 11 silent `.ogg` placeholder files
- Can be replaced with real sounds later

**Step 3: Sound Integration (No Tests)**
- Load sounds in `Game.initSounds()`
- Play sounds on: select, move, capture, power activation, menu navigation
- Respect volume settings from UI state

---

### Phase 5C: Particle Effects

**Step 1: Particle Config Module (TDD)**
- Write 10 tests in `spec/particle_config_spec.lua`
- Implement `src/shared/particle_config.lua`
- Configs for: dust, explosion, sparkle, teleport, power_orb, confetti

**Step 2: Particle Manager Module (TDD)**
- Write 6 tests in `spec/particles_spec.lua`
- Implement `src/shared/particles.lua`
- Queue-based emission system

**Step 3: Love2D Particle Integration (No Tests)**
- Create ParticleSystems from configs (using circles, no sprites)
- Emit particles on: movement, capture, power activation, orb collection, game win

---

## File Changes Summary

### New Files (8)
| File | Phase | Type |
|------|-------|------|
| `src/shared/ui.lua` | 5A | Module |
| `spec/ui_spec.lua` | 5A | Tests |
| `src/shared/sound_manager.lua` | 5B | Module |
| `spec/sound_manager_spec.lua` | 5B | Tests |
| `assets/sounds/*.ogg` (11 files) | 5B | Assets |
| `src/shared/particle_config.lua` | 5C | Module |
| `spec/particle_config_spec.lua` | 5C | Tests |
| `src/shared/particles.lua` | 5C | Module |
| `spec/particles_spec.lua` | 5C | Tests |

### Modified Files (3)
| File | Changes |
|------|---------|
| `src/game.lua` | Menu rendering, turn banner, tooltips, sound/particle integration |
| `main.lua` | Screen-based game flow |
| `src/shared/powers.lua` | Add descriptions to power definitions |

---

## Test Count Projection

| Phase | New Tests | Running Total |
|-------|-----------|---------------|
| Current | 0 | 381 |
| 5A: UI | +18 | 399 |
| 5B: Sound | +15 | 414 |
| 5C: Particles | +16 | **430** |

---

## Commits Plan

1. `feat(love2d): add UI state module with menu and settings support`
2. `feat(love2d): add main menu, settings screen, and turn banner`
3. `feat(love2d): add sound manager module`
4. `feat(love2d): add sound assets and game audio integration`
5. `feat(love2d): add particle config and manager modules`
6. `feat(love2d): integrate particle effects with game events`

---

## Ready to Execute?

The plan is complete. When you're ready, say **"execute"** and I'll begin with Phase 5A Step 1: writing the UI state module tests (RED phase).

---

## User

execute

---

## Assistant

Starting Phase 5A Step 1: Writing the UI state module tests (RED phase).

```
Tool: todowrite
```

---

## Assistant

```
Tool: write
```

---

## Assistant

The test file is created. The warnings are expected since busted globals (`describe`, `it`, `setup`) are injected at runtime. Now let me run the tests to confirm they fail (RED phase):

```
Tool: bash
```

---

## Assistant

Tests fail because the module doesn't exist - this is expected RED phase. Now let me implement the UI module (GREEN phase):

```
Tool: todowrite
```

---

## Assistant

```
Tool: write
```

---

## Assistant

Now let's run the tests to verify they pass (GREEN phase):

```
Tool: bash
```

---

## Assistant

**418 tests passing** (+37 from Phase 5A UI module). Let me format the code:

```
Tool: bash
```

---

## Assistant

```
Tool: todowrite
```

---

## Assistant

Now let me implement the menu system integration in `game.lua`. This involves:
1. Adding UI state to Game
2. Drawing main menu screen with animated board background
3. Drawing settings screen
4. Handling menu navigation

```
Tool: read
```

---

## Assistant

```
Tool: edit
```

---

## Assistant

```
Tool: read
```

---

## Assistant

Now I need to update the `Game.init()` function to initialize UI state:

```
Tool: edit
```

---

## Assistant

```
Tool: bash
```

---

## Assistant

Tests pass. The editor is showing a false positive. Now let me update the `Game.draw()` function to handle different screens and add the menu drawing functions:

```
Tool: read
```

---

## Assistant

Now let me update the update and draw functions to handle screens:

```
Tool: edit
```

---

## Assistant

Now let me add the menu screen drawing functions. First, let me find where to add them (after drawUI):

```
Tool: read
```

---

## Assistant

```
Tool: read
```

---

## Assistant

I'll add the new screen drawing functions after the `drawUI` function. Let me find the exact place:

```
Tool: edit
```

---

## Assistant

```
Tool: bash
```

---

## Assistant

Tests pass. Now I need to update the keyboard input handling for menus. Let me find the keypressed function:

```
Tool: grep
```

---

## Assistant

```
Tool: read
```

---

## Assistant

Now I need to rewrite the keypressed function to handle menu navigation:

```
Tool: edit
```

---

## Assistant

```
Tool: bash
```

---

## Assistant

Tests pass. Now I need to update `main.lua` to not immediately quit on escape (let the game handle screen transitions) and also update the game over handling to transition to the gameover screen:

```
Tool: read
```

---

## Assistant

```
Tool: edit
```

---

## Assistant

Now I need to update the game logic to handle game over state - when the game detects gameover, we should transition to the gameover screen. Let me look at where game over is detected:

```
Tool: grep
```

---

## Assistant

The gameover is detected in `game_logic.lua`. I need to trigger the UI transition when this happens. Let me look at where `endTurn` is called:

```
Tool: grep
```

---

## Assistant

```
Tool: read
```

---

## Assistant

I need to add gameover detection after endTurn. Let me update that section:

```
Tool: edit
```

---

## Assistant

```
Tool: bash
```

---

## Assistant

Tests pass. Now let me format the code and run a quick sanity check:

```
Tool: bash
```

---

## Assistant

Excellent! Phase 5A Steps 2-5 are done. Let me update the todos:

```
Tool: todowrite
```

Excellent! Phase 5A is largely complete. Let me update the todos and check what's remaining:

```
Tool: todowrite
```

---

## Assistant

---

## User

continue

---

## Assistant

---

## User

messages.163: `tool_use` ids were found without `tool_result` blocks immediately after: toolu_011a58rbfWADsdi3PQNE9xpV. Each `tool_use` block must have a corresponding `tool_result` block in the next message. 

---

## Assistant

---

## User

messages.163: `tool_use` ids were found without `tool_result` blocks immediately after: toolu_011a58rbfWADsdi3PQNE9xpV. Each `tool_use` block must have a corresponding `tool_result` block in the next message. 

---

## Assistant

---

## User

continue

---

## Assistant

---

## User

continue

---

## Assistant

---

