# Seeing the game — the AI QA loop

How an AI agent (Claude) sees, drives, and asserts on a running NNQR build. This
exists because the Love2D version is **blind to the agent**: CI proved the test
suite passed but never that the running game behaved — a pre-existing `centerpult`
crash shipped green and only surfaced in a human playthrough.

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
| **Read on PNG** | ✅ | — | — | universal; the backstop everything funnels into |
| **Playwright (npm lib) script** | ✅ | ✅ | ✅ `page.evaluate(window.NNQR…)` | works today via Bash; no MCP needed (see below) |
| **Playwright MCP** | ✅ | ✅ | ✅ | turnkey for `/qa`, but **not configured in this environment** |
| **macOS `screencapture`** | ✅ window→PNG | — | — | native windows (Godot/Bevy/Love2D desktop) |
| **`cliclick` / `osascript`** | — | ✅ OS click/key | — | driving native apps |
| **Engine screenshot API** | ✅ | — | ✅ dump JSON | Love2D `captureScreenshot`, Godot viewport→PNG |
| **Xvfb** | ✅ headless display | — | — | running windowed games in CI |

## Finding: the Playwright MCP is NOT required

The `/qa` skill prefers the Playwright **MCP server**, but it is not connected in
this environment. That does not block the loop — the Playwright **npm library**
run from a Bash script gives the same three capabilities and is more reproducible
and CI-friendly. The web implementation proves this with `web/scripts/shot.mjs`:
launch headless Chromium → `page.goto(localhost:1425)` → screenshot to `.qa/*.png`
→ `page.evaluate("window.NNQR.getState()")` → drive via `window.NNQR.api` → the
agent `Read`s the PNGs. **Validated 2026-05-30**: rendered the 10×8 board, the
yellow-outlined selected piece, the green valid-move marker, and the piece
advancing after a driven move — all matching the state JSON.

## The web loop (recommended, lowest friction)

1. `mise run web-dev` (serves at `http://localhost:1425`)
2. Run `web/scripts/shot.mjs` (or, when available, the Playwright MCP:
   `browser_navigate` → `browser_take_screenshot` → `browser_evaluate`).
3. `Read` the emitted PNG to verify the render; assert on the printed state JSON.
4. Iterate: drive `window.NNQR.api.select/move`, screenshot, assert.

Game state is exposed on `window.NNQR` (`getState()` + `api.select/move/reset`) so
assertions are deterministic, not pixel-diffed. Gherkin scenarios live in
`web/docs/user-stories/`.

## Native engines (Godot / Love2D)

Same shape, different capture: a scripted **scenario runner** sets a known state,
renders one frame, saves a PNG via the engine's screenshot API, and dumps state to
JSON — the agent `Read`s both. No browser. See `custom-tooling.md` for whether a
shared `gameshot` CLI is worth building.

## Lessons borrowed from prior attempts (`workrush`)

`workrush` was a prior browser game (Phaser + Colyseus) that stalled. What it
teaches this effort:

1. **Its biggest gap was exactly this loop** — it exposed `window.state` but never
   added browser automation, so it could not AI-test visuals. We make the see-loop
   the *first* milestone, not an afterthought.
2. **Determinism early.** `workrush` scattered `Date.now()` / `Math.random()` and
   became un-replayable. NNQR-web funnels all randomness through a seeded RNG
   (`web/src/core/rng.ts`) from day one.
3. **Separate logic from rendering.** `workrush`'s 38KB scene file tangled the two.
   NNQR-web keeps rules in `src/core/` (framework-free, unit-tested) and Phaser as
   a pure renderer — the same lesson that drove the Love2D `game.lua` split.
4. **Expose state to `window.*`** — cheap, huge payoff (we do, as `window.NNQR`).
5. **Lock tooling early** — `workrush` lost time to a mid-project beads→bees
   migration (so did this repo); avoid mid-stream tool churn.
