# NNQR — Godot implementation (Track C)

A native Godot 4 port of NNQR, built so the AI QA loop can **see** it via the
engine's viewport screenshot API (no browser): a scenario runner loads a known
state, renders one frame, saves a PNG, dumps state JSON — the agent `Read`s both.

## Status

Viability **proven** (2026-05-30): Godot 4.6.3 renders here (Metal on M4 Max) and
`get_viewport().get_texture().get_image().save_png()` works — see `probe.png`.
Next: a state-driven walking skeleton (board + pieces + scenario runner), then
port board/powers/AI from the spec (`research/`, `web/src/core/` is a clean
TS reference).

## Running

```bash
mise run -C godot godot -- --path godot/   # open/run (resolves a working binary)
```

`scripts/godot.sh` resolves Godot: `$GODOT_BIN` → cached download →
official-release download. The mise/aqua install is broken on case-insensitive
macOS (self-symlink); this avoids it. CI (Linux) uses the same downloader.

## The see-loop

scenario JSON (known state) → `godot.sh --path . <scenario>` → scene sets state,
renders, `save_png(".qa/frame.png")` + writes `.qa/state.json` → agent `Read`s
the PNG and asserts on the JSON.
