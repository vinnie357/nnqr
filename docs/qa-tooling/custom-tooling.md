# Custom QA tooling — do we need a CLI or MCP?

Question the operator raised: do we build our own CLI/MCP to help the see-loop?

## Current state — three per-engine scripts exist

All three see-loops are now built and have produced real `.qa/` output. Their
invocation styles differ:

| Engine | Invocation | Output dir |
|---|---|---|
| **Web** | `node web/scripts/shot.mjs` (Playwright; requires `mise run web-dev` already running) | `web/.qa/` |
| **Godot** | `bash godot/scripts/godot.sh --path godot/ -- --scenario res://scenarios/<name>.json` | `godot/.qa/` |
| **Love2D** | `love . --scenario scenarios/<name>.json` (from `lua/love2d/`) or `mise run -C lua/love2d "scenario:initial"` | `lua/love2d/.qa/` |

In all three cases the output has the same shape: `frame.png` + `state.json`.

## The case for a `gameshot` CLI

A uniform CLI would collapse the per-engine invocation differences to one command:

```
gameshot --engine <web|godot|love2d> --scenario <file.json> --out <dir>
  → launch the engine in scenario mode
  → render one frame, save <dir>/frame.png
  → dump the resulting state to <dir>/state.json
  → exit non-zero on engine error
```

The agent then `Read`s `frame.png` and asserts on `state.json` — identical loop
shape regardless of engine. Each engine already implements its side of this contract.

### What a CLI would actually unify

The real friction between the three loops is not the output format (already uniform:
`frame.png` + `state.json`) but the launch ceremony:

- **Web** requires a running dev server before the Playwright script can connect.
  A CLI would need to start and stop the server, or document the pre-condition.
- **Godot** uses a non-standard binary resolution path (`godot.sh`), and the
  `--path` / `--` / `--scenario` flag split is unusual.
- **Love2D** works directly but `mise run -C lua/love2d` is verbose from the repo
  root, and there is no root-level `love-scenario` task.

A thin nushell wrapper that handles these differences for all three is achievable in
roughly 100 lines.

### Decision: defer unless friction proves it out

The per-engine scripts suffice for single-agent QA sessions. Three different
invocation styles are awkward when documenting or scripting cross-engine comparisons,
but not painful enough to justify a new tool right now.

**Do not build a `gameshot` CLI until:**
- A cross-engine comparison workflow is needed (e.g. verifying a scenario produces
  equivalent state in Godot and Love2D), OR
- An agent session loses time getting the per-engine invocation syntax right more
  than once.

**Do not wrap it in an MCP** unless the CLI is stable and used across multiple
sessions. An MCP buys nothing over a shell CLI for a single agent that can already
run scripts.

## Web: Playwright MCP assessment

The Playwright **MCP server** would make `browser_navigate`, `browser_take_screenshot`,
and `browser_evaluate` available as first-class tools — no shell script required.
It is not currently configured in this environment. The npm script approach
(`web/scripts/shot.mjs`) works today and requires no additional server process.
Configuring the Playwright MCP is worth doing when the web loop is used in
multi-session or multi-agent workflows where the shell-script invocation is genuinely
repetitive friction.
