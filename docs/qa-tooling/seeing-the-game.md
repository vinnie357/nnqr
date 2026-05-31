# Seeing the game — the AI QA loop

How an AI agent (Claude) sees, drives, and asserts on a running NNQR build. This
exists because CI proves the test suite passes but never that the running game
behaves correctly — a pre-existing `centerpult` crash shipped green and only
surfaced in a human playthrough.

## The core primitive: Read-on-PNG

The agent can view any image file with the Read tool. So the fundamental
requirement is simply: **the game can produce a PNG of its current frame.**
Everything else (browser vs native, MCP vs script) is just how the PNG and the
game state get produced. A loop needs three capabilities:

| Capability | Why |
|---|---|
| **See** — a PNG of the frame | visual correctness (layout, highlights, render bugs) |
| **Read state** — structured game state | deterministic assertions (`turn`, `pieces`, `winner`) |
| **Drive** — inject inputs | set up scenarios and exercise behavior |

## Toolbox

| Tool | See | Drive | Read state | Notes |
|---|---|---|---|---|
| **Read on PNG** | yes | — | — | universal; the backstop everything funnels into |
| **Playwright npm script** | yes | yes | yes `page.evaluate(window.NNQR…)` | works today via Bash; no MCP needed |
| **Playwright MCP** | yes | yes | yes | turnkey for `/qa`, but not configured in this environment |
| **Engine scenario runner** | yes | yes (via JSON inputs) | yes (state.json) | Godot + Love2D: native, no browser |
| **macOS `screencapture`** | yes window→PNG | — | — | native windows — not used; scenario runners are preferred |
| **Engine screenshot API** | yes | — | yes dump JSON | backstop if scenario runner is unavailable |

## Three see-loops — all built and verified

All three loops have produced real `.qa/` output.

### Web (Vite + Phaser)

**How it works.** `web/src/main.ts` exposes `window.NNQR` — a bridge with
`getState()` (returns a `structuredClone` of the game state) and
`api.select/move/activatePower/newGame`.
`web/scripts/shot.mjs` (Playwright, ~50 lines) launches headless Chromium, navigates
to `http://localhost:1425`, drives the game through `window.NNQR.api`, screenshots
each step to `web/.qa/`, and prints state JSON.

**Run it:**
```
# Start the dev server first (keep it running):
mise run web-dev          # root task → delegates to mise run -C web dev

# In a second terminal, run the harness:
cd web
node scripts/shot.mjs
# Screenshots written to web/.qa/01-initial.png, 02-selected.png, 03-moved.png
```

State assertions are exact, not pixel-based — `window.NNQR.getState()` returns
`{turn, currentPlayer, selected, validMoves, pieces, status, winner}`.

Additional scripts in `web/scripts/`: `qa-play.mjs`, `qa-orbs.mjs`, `qa-pause.mjs`,
`qa-collect.mjs`, `click-check.mjs`. Each drives a different scenario and screenshots
the result. Outputs land in `web/.qa/`.

The Playwright **MCP** server is not currently configured. The npm library scripts
provide the same three capabilities (see + drive + read-state) and are CI-friendly.

### Godot

**How it works.** `godot/src/scenario_runner.gd` is the main scene. It parses
`--scenario res://scenarios/<name>.json` from the command line, loads the scenario
into a `GameState`, optionally applies an `inputs` array (click, activate, ai_turn
actions) through the real Controller, waits for `RenderingServer.frame_post_draw`,
saves `godot/.qa/frame.png` and `godot/.qa/state.json`, then quits.

**Run a single scenario:**
```
bash godot/scripts/godot.sh --path godot/ -- \
  --scenario res://scenarios/qa_move_capture.json
# Artifacts: godot/.qa/frame.png, godot/.qa/state.json
```

Optional `--size WxH` flag resizes the window before capture:
```
bash godot/scripts/godot.sh --path godot/ -- \
  --scenario res://scenarios/qa_move_capture.json --size 1280x800
```

**Run all 7 QA stories** (with jq assertions on state.json):
```
bash godot/qa/run_stories.sh   # from the repo root or godot/ directory
```
Stories: `qa_move_capture`, `qa_collect_menu`, `qa_activate_power`, `qa_vs_ai`,
`qa_win`, `qa_move_again`, `qa_ai_power`. Named PNGs are written to `godot/.qa/`
(e.g. `qa_move_capture.png`) for visual review alongside the state assertions.

**Unit tests** (headless, separate from the see-loop):
```
bash godot/tests/run_all.sh   # runs all *_test.gd headlessly
```
Unit tests include `renderer_picking_test.gd` — the round-trip test described in
the "Lessons" section below.

**GOTCHA — do NOT use `--headless` for the see-loop.** The scenario runner's
docstring in `scenario_runner.gd` incorrectly shows `--headless`; ignore it.
`run_stories.sh` correctly omits the flag. The reason: `RenderingServer.frame_post_draw`
requires the GPU rendering pipeline to actually fire. With `--headless`, the signal
fires in a degraded path and the viewport texture is blank — `frame.png` will be an
empty image. Unit tests (`run_all.sh`) use `--headless` because they do not need the
renderer; the see-loop does not.

**Godot binary.** `godot/scripts/godot.sh` resolves the binary in order:
1. `$GODOT_BIN` if set and executable.
2. `~/.cache/nnqr-godot/<version>/` cached download.
3. Downloads the official release zip from GitHub, extracts, caches, runs.

The mise/aqua Godot install is broken on macOS (case-insensitive filesystem
self-symlink clobbers the binary). Do not use `mise exec -- godot`; use
`godot/scripts/godot.sh` directly. The default version is set by `GODOT_VERSION`
(currently `4.6.3-stable` per `godot/scripts/godot.sh`).

### Love2D

**How it works.** `lua/love2d/src/scenario_runner.lua` intercepts `--scenario <path>`
in the `love.load` arg table. It parses the scenario JSON (using a bundled minimal
parser — no external dependency), builds the game state via real `GameLogic` calls,
initialises the render pipeline, and returns the state so `love.draw` can render it.
On the first `love.draw` call, `ScenarioRunner.captureAndQuit` renders to an offscreen
canvas, encodes to PNG, writes `lua/love2d/.qa/frame.png` and `.qa/state.json`, then
calls `love.event.quit()`.

**Run a scenario:**
```
# From inside lua/love2d/:
mise run scenario                   # uses SCENARIO env var; defaults to scenarios/initial.json
mise run "scenario:initial"        # explicit: scenarios/initial.json
mise run "scenario:midgame"        # scenarios/midgame.json
mise run "scenario:history"        # scenarios/match_history.json (history screen)

# Or directly:
love . --scenario scenarios/initial.json
```

Scenario files live in `lua/love2d/scenarios/`: `initial.json`, `midgame.json`,
`match_history.json`. There is no separate `run_stories.sh` for Love2D; scenarios
are invoked one at a time via mise tasks or directly.

Note: the root `mise.toml` has `love-start`, `love-test-busted`, etc., but no
`love-scenario` task. Run scenario tasks from inside `lua/love2d/` with
`mise run -C lua/love2d "scenario:initial"` or from that directory directly.

## Bevy/Rust — no see-loop

The Rust/Bevy implementation has no scenario runner, no `window.NNQR` equivalent,
and no `.qa/` output pipeline. There is no see-loop for Bevy as of this writing.
`rust/bevy/src/tests/` contains unit tests exercisable via `cargo test` /
`mise run rust-test`, but those do not produce PNG output or exercise the renderer
visually.

## Lessons learned

These came from real bugs that shipped past CI in this project.

### Render-validation is not behavior-validation

The see-harness proves the frame **renders**. It does not prove input-mapping, live
window resize behavior, or gameplay-flow correctness. QA scenarios drive the
controller by row/col and bypass pixel picking — so clicking bugs need a dedicated
round-trip test.

Godot has exactly this test: `godot/tests/renderer_picking_test.gd`. It runs three
viewport sizes (860×560, 1280×800, 1600×1000) and checks every one of the 80 tiles
(8 rows × 10 cols) per size: a null check that the center pixel maps to a tile, plus
row and col round-trip checks. It also checks off-center displacements for a sample
of interior tiles, and out-of-bounds pixels return null. The test is headless and
part of `godot/tests/run_all.sh`. A real off-by-one click bug shipped because
clicking was never headless-validated before this test existed.

### Scenarios must drive the real flow, not pre-load end state

An orb/power bug slipped past because a fixture pre-loaded the end state instead of
exercising the chain. See-harness scenarios should start from a realistic initial
state and apply real inputs (click actions, activate actions, ai_turn) through the
controller. The `inputs` array in scenario JSON exists for this purpose: the scenario
runner applies each action through the real `Controller` in sequence before capturing
the frame. Assertions in `godot/qa/run_stories.sh` are on the produced `state.json`,
not hardcoded into the scenario file — this is deliberate to avoid the same
anti-pattern.

### Effects must be consumed, not just set

Two separate times, a power or feature was implemented (effect written to state) but
nothing in the game flow read and acted on the flag — the power was a no-op in play.
nnqr-40 tracked the audit of all power effects for this. When writing a new power:
trace the output field from `effects.gd` (Godot) or `powers/` (web) through the
controller, turn logic, and renderer. The see-loop catches missing renders; state
assertions on `state.json` catch missing mechanical effects.

### Godot `_copy_state` drops Object metas

`Board._copy_state` (in `godot/src/board.gd`) does not propagate GDScript Object
metadata set via `set_meta`. Flags stored as metas on a piece vanish after a state
copy. The controller works around this by re-propagating known metas immediately after
copying (see `godot/src/controller.gd`). When writing QA assertions that depend on
meta-carrying powers, assert on the final re-propagated field rather than relying on
the meta surviving the copy.

## Background: prior attempt (`workrush`)

`workrush` was a prior browser game (Phaser + Colyseus) that stalled. The main lesson
it provides for NNQR:

- Its biggest gap was this exact loop — it exposed `window.state` but never added
  browser automation. We treat the see-loop as a first-class requirement, not an
  afterthought.
- `workrush` scattered `Date.now()` / `Math.random()` and became un-replayable.
  NNQR-web funnels all randomness through a seeded RNG (`web/src/core/rng.ts`).
- `workrush`'s 38KB scene file tangled logic and rendering. NNQR-web keeps rules in
  `src/core/` (framework-free, unit-tested) and Phaser as a pure renderer.
- Lock tooling early — `workrush` lost time to a mid-project tool migration; so did
  this repo (beads → bees).
