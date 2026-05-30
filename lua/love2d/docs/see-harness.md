# Love2D SEE-Harness

Screenshot harness that lets the AI lead inspect the running Lua game visually.
Mirrors the pattern from `godot/src/scenario_runner.gd`.

## What it does

1. Accepts `--scenario <path>` on the love command line.
2. Loads the scenario JSON, builds the game's real state from it.
3. Renders ONE frame to an offscreen canvas.
4. Saves `lua/love2d/.qa/frame.png` (screenshot) and `lua/love2d/.qa/state.json` (state dump).
5. Quits immediately.

Normal `mise run love-start` (no `--scenario`) is unchanged.

## Running the harness

```bash
# From lua/love2d/
mise run scenario:initial       # standard board, Player 1 to move
mise run scenario:midgame       # mid-game snapshot with powers + terrain

# Or with a custom scenario:
SCENARIO=scenarios/initial.json mise run scenario
love . --scenario scenarios/initial.json   # direct invocation
```

## Output files

| File | Description |
|------|-------------|
| `lua/love2d/.qa/frame.png` | PNG screenshot of the rendered frame |
| `lua/love2d/.qa/state.json` | JSON dump of the Lua game state |

Both files are in `.gitignore` (transient artifacts).

## Scenario JSON format

```jsonc
{
  "description": "Human-readable label (optional)",
  "rows": 8,           // board rows (default 8)
  "cols": 10,          // board cols (default 10)
  "current_player": 1, // 1 or 2 (default 1)
  "turn": 0,           // turn counter (default 0)

  // Optional — overrides auto-generated initial pieces.
  // If absent, standard two-row setup per player is used.
  "pieces": [
    {"player": 1, "row": 1, "col": 3, "powers": []},
    {"player": 1, "row": 2, "col": 5, "powers": ["bomb"]},
    {"player": 2, "row": 7, "col": 4, "powers": ["recruit"]}
  ],

  // Optional — tile height overrides (default height is 0).
  "heights": [
    {"row": 4, "col": 5, "height": 2}
  ],

  // Optional — permanently destroyed tiles.
  "destroyed_tiles": [
    {"row": 5, "col": 3}
  ]
}
```

When `pieces` is omitted the standard initial placement is used (Player 1 rows 1-2, Player 2 rows 7-8, all columns, no powers).

## Implementation

| File | Role |
|------|------|
| `src/scenario_runner.lua` | Core module: arg parsing, state construction, canvas capture, file I/O |
| `main.lua` | Detects `--scenario`, delegates to ScenarioRunner before normal init |
| `scenarios/initial.json` | Example: standard board |
| `scenarios/midgame.json` | Example: mid-game with powers, raised terrain, destroyed tiles |
| `mise.toml` | `scenario`, `scenario:initial`, `scenario:midgame` tasks |

## Verification (AI lead checklist)

After running either scenario task:

```bash
ls -l lua/love2d/.qa/frame.png           # must be > 0 bytes
xxd lua/love2d/.qa/frame.png | head -1   # must start with 89 50 4e 47 (PNG magic)
cat lua/love2d/.qa/state.json | head -30 # should show board state
```

Then `Read lua/love2d/.qa/frame.png` in Claude Code to visually inspect the render.
