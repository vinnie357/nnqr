# Tauri desktop packaging — the web/desktop crossover

The operator's insight: the web version can be QA'd in a browser *and* shipped as
a desktop app, from one codebase, via Tauri (as `~/github/desknote` does).

## The crossover

A Tauri app is a thin Rust shell hosting a **web frontend** in the OS webview. So
the NNQR web frontend (Phaser + TS + Vite) is the shared core:

- **Develop + QA in a browser** — `mise run web-dev` at `localhost:1425`, the
  Playwright see-loop screenshots and drives it. No Tauri needed for the QA loop.
- **Ship to desktop** — Tauri wraps the *same* built frontend into
  `.dmg` / `.msi` / `.AppImage`.

## Pattern to reuse from desknote (Tauri v2)

Confirmed in `~/github/desknote`:

- `src-tauri/tauri.conf.json`: `build.devUrl` → the Vite dev URL,
  `build.frontendDist` → `../dist`, a `windows[]` entry (title, size, decorations).
  Pin Tauri CLI + Rust + node in `mise.toml`.
- **Stub-mode URL param** (`?stub=1`): the frontend runs standalone in a plain
  browser by returning mock data instead of calling the native backend — this is
  what makes Playwright QA possible without the Tauri runtime. NNQR's `window.NNQR`
  bridge already serves this role; the game logic lives entirely in `src/core` with
  zero `@tauri-apps/api` imports.
- **IPC isolation**: any native calls (save game, high scores) go through one thin
  `store` module; the game never imports Tauri APIs directly. Keep IPC to
  async/debounced operations (saves), never the per-frame loop.

## Plan

Tauri is **Track B3** — added only after the web game is playable. It is packaging,
not gameplay, and must not complicate the browser QA loop. NNQR-web already keeps
the right shape (pure `src/core`, no Tauri coupling), so wrapping later is a
drop-in: add `web/src-tauri/`, point `frontendDist` at the Vite build, and ship.

## Port note

desknote's Vite uses `1420`; NNQR-web uses **`1425`** (strict port) to avoid the
clash. A future `web/src-tauri/tauri.conf.json` must set `devUrl` to
`http://localhost:1425`.
