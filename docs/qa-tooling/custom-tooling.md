# Custom QA tooling — do we need a CLI or MCP?

Question the operator raised: do we build our own CLI/MCP to help the see-loop?

## Finding so far

For the **web** implementation: **no custom tooling needed yet.** The Playwright
npm library in a ~40-line script (`web/scripts/shot.mjs`) already delivers
see + drive + read-state, and the agent `Read`s the PNGs. The Playwright MCP would
be a nicety (turnkey `/qa` integration) but is not required and is not currently
configured.

## Candidate: a `gameshot` CLI (for native engines)

The case for custom tooling appears with **native engines** (Godot, Bevy, Love2D),
where there is no browser and each engine has a different screenshot API. A small,
uniform CLI would pay off if we run native see-loops repeatedly:

```
gameshot --engine <godot|love2d|bevy> --scenario <file.json> --out <dir>
  → launch the engine in a scripted scenario mode
  → set the known state from the scenario file
  → render one frame, save <dir>/frame.png
  → dump the resulting state to <dir>/state.json
  → exit non-zero on engine error
```

The agent then `Read`s `frame.png` and asserts on `state.json` — identical loop
shape across engines. Each engine implements a thin `--scenario` entry point
(Godot: viewport→PNG; Love2D: `love . --scenario` + `captureScreenshot`).

### Decision criteria

- **Build it** once two native engines (e.g. Godot + Love2D-rescue) each need a
  scenario runner — extract the shared CLI rather than duplicating launch/IO glue.
- **Wrap it in an MCP** only if the CLI is invoked often enough that the per-call
  Bash ceremony becomes friction, AND multiple sessions/agents need it. An MCP buys
  nothing over a Bash CLI for a single agent that can already run scripts.

### Recommendation

Defer custom tooling until Track C (Godot) lands its scenario runner. At that point
extract `gameshot` as a CLI shared by Godot + the Love2D rescue (Track D). Hold on
an MCP unless repeated friction proves it out. The web loop stays script-based.
