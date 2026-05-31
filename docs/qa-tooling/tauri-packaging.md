# Tauri desktop packaging — the web/desktop crossover

The web version can be QA'd in a browser and shipped as a desktop app from one
codebase via Tauri (as `~/github/desknote` does).

## The crossover

A Tauri app is a thin Rust shell hosting a **web frontend** in the OS webview. So
the NNQR web frontend (Phaser + TS + Vite) is the shared core:

- **Develop + QA in a browser** — `mise run web-dev` at `localhost:1425`, the
  Playwright see-loop screenshots and drives it. No Tauri needed for the QA loop.
- **Ship to desktop** — Tauri wraps the same built frontend into
  `.dmg` / `.msi` / `.AppImage`.

## Pattern from desknote (Tauri v2) — verified facts

Read from `~/github/desknote/src-tauri/tauri.conf.json`:

- `build.devUrl`: `"http://localhost:1420"` — the Vite dev server URL.
- `build.frontendDist`: `"../dist"` — the production Vite build output.
- `app.windows[]`: one entry: title `"Desknote"`, width `1280`, height `800`,
  minWidth `960`, minHeight `600`, `titleBarStyle: "Overlay"`, `hiddenTitle: true`,
  `decorations: true`, `resizable: true`.
- `bundle.targets`: `"all"` — builds `.dmg`/`.msi`/`.AppImage`.

When wrapping NNQR-web, a `web/src-tauri/tauri.conf.json` following this structure
would set `devUrl` to `http://localhost:1425` (NNQR's strict port) and
`frontendDist` to `../dist`.

**IPC isolation pattern.** In desknote, native calls go through one thin module;
the frontend never imports `@tauri-apps/api` directly in game logic. The same
pattern applies to NNQR: any future native features (save game, leaderboard) should
go through a single `store` module. Keep IPC to async operations, never the
per-frame loop.

## NNQR-web QA without Tauri — the `window.NNQR` bridge

`web/src/main.ts` exposes `window.NNQR` with `getState()` and
`api.select/move/activatePower/newGame`. This is what makes Playwright QA possible
without the Tauri runtime — the game logic is entirely in `web/src/core/` with no
`@tauri-apps/api` imports, so it runs standalone in headless Chromium.

**Note on stub-mode:** desknote's documentation mentions a `?stub=1` URL param for
returning mock data in a plain browser. NNQR-web does not have a `?stub=1` param or
equivalent mock-data path — verified by grepping `web/src/` for `stub`. NNQR does
not need one: all game logic runs in `src/core/` and `window.NNQR` exposes the full
real state; there is no native backend to stub out. The `window.NNQR` bridge itself
plays the role that stub-mode plays in desknote.

## Status

Tauri packaging is tracked as nnqr-26. It is deferred until the web game is
playable. Tauri is packaging, not gameplay, and must not complicate the browser QA
loop. The web frontend already keeps the right shape (pure `src/core`, no Tauri
coupling), so the wrap is a later addition: create `web/src-tauri/`, point
`frontendDist` at the Vite build, and ship.

## Port note

desknote's Vite dev server uses port `1420`; NNQR-web uses `1425` (set in
`web/vite.config.ts` / `web/mise.toml`). A future `web/src-tauri/tauri.conf.json`
must set `devUrl` to `http://localhost:1425` to avoid the clash.
