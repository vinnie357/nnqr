# User Story: Pause Overlay and Leave to Title

## Story

As a player mid-game, I want to pause the game and optionally return to the title
screen so that I can change mode, start a fresh game, or take a break without
killing the process.

## Scenarios

### Scenario 1: Escape key opens pause overlay

**Given** the game is in the PLAYING state with no power targeting active  
**When** the player presses Escape  
**Then** a semi-transparent overlay appears over the board with a "Paused" banner,
a "Resume" button, and a "Quit to Title" button; the game is in PAUSED state.

### Scenario 2: Escape key cancels power targeting (takes priority over pause)

**Given** a power is currently in targeting mode (the player clicked a power
and the board shows target highlights)  
**When** the player presses Escape  
**Then** targeting is cancelled (no pause overlay appears); the game remains PLAYING.

### Scenario 3: Resume via button

**Given** the pause overlay is visible  
**When** the player clicks "Resume"  
**Then** the overlay disappears and the game continues from where it was paused.

### Scenario 4: Resume via Escape key

**Given** the pause overlay is visible  
**When** the player presses Escape  
**Then** the overlay disappears and the game continues (same as clicking Resume).

### Scenario 5: Quit to Title

**Given** the pause overlay is visible  
**When** the player clicks "Quit to Title"  
**Then** the game state is torn down, the overlay is removed, and the title screen
is shown, allowing the player to choose a new mode.

### Scenario 6: AI turn does not fire while paused

**Given** the game is paused and it is the AI's turn  
**When** the overlay is visible  
**Then** no AI move fires; the game is frozen until the player resumes.

## Visual verification

Run the ui_shot harness to render the pause overlay over a mid-game board:

```bash
cd godot
bash scripts/godot.sh --path . --script res://tools/ui_shot.gd -- pause
```

Expected stdout:
```
ui_shot: mode=pause
ui_shot: frame.png saved err=0 size=860x560
```

The PNG at `.qa/frame.png` should show:
- The game board visible but darkened behind a semi-transparent black overlay
- A dark panel centred on screen with a border
- "Paused" in gold text near the top of the panel
- A "Resume" button (blue-grey) below the title
- A "Quit to Title" button (dark red) below Resume
- Small "Press Esc to resume" hint text at the bottom of the panel
