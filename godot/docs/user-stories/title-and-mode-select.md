# User Story: Title Screen and Mode Selection

## Story

As a player launching NNQR, I want to choose my game mode and AI difficulty before
the board appears so that I can play the way I want without restarting.

## Scenarios

### Scenario 1: Title screen appears on launch

**Given** the game is launched normally (no --scenario flag)  
**When** the main scene initialises  
**Then** the title screen is shown with the game name "NNQR" and subtitle
"Not Not Quadradius", a Mode selector with "vs AI" (default selected) and
"Hotseat 2P" options, a Difficulty selector with Easy / Medium / Hard / Expert
(Medium default selected), and a "Start Game" button.

### Scenario 2: Scenario harness is not blocked by title screen

**Given** the game is launched with `-- --scenario res://scenarios/<name>.json`  
**When** main.gd _ready() runs  
**Then** ScenarioRunner takes over immediately and the title screen never appears,
preserving the QA see-harness contract.

### Scenario 3: vs AI mode with Easy difficulty

**Given** the title screen is displayed  
**When** the player clicks "vs AI" (or it is already selected), then clicks "Easy",
then clicks "Start Game"  
**Then** the game board appears and the AI plays at Easy difficulty;
the human is player 1, the AI is player 2.

### Scenario 4: Hotseat mode — difficulty selector is dimmed

**Given** the title screen is displayed  
**When** the player clicks "Hotseat 2P"  
**Then** the Difficulty buttons become visually dimmed (they are not applicable),
and clicking a difficulty button has no effect.

### Scenario 5: Hotseat mode — both players are human

**Given** the player selected "Hotseat 2P" and clicked "Start Game"  
**When** player 1 makes a move  
**Then** the game waits for a human click for player 2; no AI turn fires automatically.

### Scenario 6: N key returns to title

**Given** a game is in progress  
**When** the player presses N  
**Then** the game tears down and the title screen is shown again.

## Visual verification

Run the ui_shot harness to render the title screen:

```bash
cd godot
bash scripts/godot.sh --path . --script res://tools/ui_shot.gd -- title
```

Expected stdout:
```
ui_shot: mode=title
ui_shot: frame.png saved err=0 size=860x560
```

The PNG at `.qa/frame.png` should show:
- Dark background (near-black, #111319)
- "NNQR" in large gold text, centred near the top
- "Not Not Quadradius" subtitle below in lighter grey-blue
- Two side-by-side mode buttons: "vs AI" filled in blue (selected), "Hotseat 2P" darker
- Four difficulty buttons in a row: "Easy" "Medium" (filled blue, selected) "Hard" "Expert"
- A blue "Start Game" button centred lower
- Small hint text at the bottom
