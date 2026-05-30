# NNQR — Web implementation

A browser-native version of NNQR (Phaser 3 + TypeScript + Vite), built so the AI
QA loop can **see** the running game (Playwright screenshots), **read** its state
(`window.NNQR.getState()`), and **drive** it (`window.NNQR.api.select/move`).

## Status

Walking skeleton (Track B1): 10×8 board, 20 pieces/player, orthogonal movement,
capture, win-by-elimination. Height, powers, orbs, and AI follow in Track B2.

## Layout

- `src/core/` — pure game rules, no framework deps (vitest-tested)
- `src/main.ts` — Phaser renderer + input + the `window.NNQR` QA bridge
- `docs/user-stories/` — Gherkin scenarios for the `/qa` loop

## Commands (via mise)

```bash
mise run web-dev     # dev server at http://localhost:1425
mise run web-test    # vitest unit tests
mise run web-ci      # typecheck + tests
```

## The QA see-loop

1. `mise run web-dev`
2. `browser_navigate http://localhost:1425`
3. `browser_take_screenshot` → view the board
4. `browser_evaluate("window.NNQR.getState()")` → assert on state
5. `browser_evaluate("window.NNQR.api.select(2,5)")` / `.move(3,5)` → drive, or click the canvas
6. screenshot again → assert the change

See `../docs/qa-tooling/` for the full seeing toolbox and engine comparison.
