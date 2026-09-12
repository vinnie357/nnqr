# NNQR — Astra Edition

**Made by GPT Astra.** An independent 3D recreation of Quadradius: a machined strategy table, torus squadrons, mutable terrain, and 86 collectible powers. Research informs the rules; this version has its own architecture and presentation.

## Get the testing branch

```nu
git clone --branch feature/nnqr-45-astra git@github.com:vinnie357/nnqr.git
cd nnqr
mise run astra-start
```

For an existing clone, fetch `origin` and switch to `feature/nnqr-45-astra`.
Testers need repository access. Use **Report issue** to export a diagnostic ZIP,
then attach it to a GitHub issue or share it with the maintainer. Include your
commit (`git rev-parse --short HEAD`), macOS version, steps, expected result, and
actual result. Reports are not uploaded automatically.

## Start on macOS

From the repository root:

```nu
mise run astra-start
```

The launcher uses the locally cached Godot 4.6.3, or `GODOT_BIN`, or downloads the pinned engine into ignored `astra/.tools/`. Development saves and reports live in `astra/.userdata/`; engine output lives in `astra/.logs/astra.log`. Exported builds use Godot's platform user-data directory. `GODOT_VERSION` permits a deliberate engine change; templates must match. See [the engine ADR](docs/adrs/0001-engine-and-platforms.md).

Choose **Play against AI**, **Hotseat**, or **Power laboratory**. Click a friendly torus, optionally preview and activate powers, then click a destination. Click the selected torus again to deselect. Scroll over the board to zoom; use Rotate and Overhead to inspect terrain. Escape cancels a preview or pauses. Hotseat conceals the arena until the next player is ready.

The laboratory lets you select a torus, add any power, and raise/lower its terrain. Sandbox changes reset the replay baseline. **How to play** includes a searchable power encyclopedia. **Report issue** exports feedback, state, replay, engine log, and a screenshot into a ZIP for sharing manually.

## Repeatable tools

| Root command | Purpose |
| --- | --- |
| `mise run astra-test` | Rules, powers, AI, diagnostics, controller and camera tests |
| `mise run astra-qa` | Open a representative arena, capture PNGs/state, verify picking, exit |
| `mise run astra-status` | Nushell table of actual test/build artifacts |
| `mise run astra-reports` | List local diagnostic ZIPs |
| `mise run astra-replay -- /absolute/path/report.zip` | Replay actions and compare the reported final state |
| `mise run astra-logs` | Recent game log output |
| `mise run astra-export-web` | Export browser game using matching templates |
| `mise run astra-serve` | Serve exported game at `http://127.0.0.1:8060` |

Equivalent short tasks are in `astra/mise.toml`. Reusable diagnostic operations live in `astra.nu`; launch/export wrappers are in `scripts/`. Tests isolate their saves in `.testdata/`; use `ASTRA_TEST_DATA_DIR` to override it. Runtime errors cause the test wrapper to fail even if an engine process returns zero.

## Current verification status

The headless rules, all-power semantics/interaction tests, repeated AI simulations, real save/report tests, and controller/camera tests pass on the development Mac. Native rendered QA has also passed through a user-run launch: Astra inspected both screenshots, verified the clean native log, and replayed its diagnostic report successfully. Full interactive match acceptance, native packaging, and Safari/Chrome exported-game tests remain pending. The agent execution sandbox cannot register a macOS GUI application; native launches abort before game code. Matching export templates are not installed, and engine/template download access was unavailable during initial implementation. These platform checks remain incomplete; publishing the source branch does not imply that exported builds have passed.

Run `mise run astra-qa` from a normal Terminal to generate `astra/.qa/arena.png`, `power.png`, and `state.json`. Basic rendered acceptance is complete; the next step is the interactive checklist. See [playtest instructions](docs/playtest.md).

## Browser and native packaging

Install Godot 4.6.3 templates using **Editor → Manage Export Templates**. Then run `mise run astra-export-web` and `mise run astra-serve`. The server binds to loopback by default; this is local browser play, not remote multiplayer. A public build requires static hosting. Native packaging is `mise run -C astra export-native`; signing/notarization is not configured for public distribution.

The browser export uses Compatibility rendering and a single thread. No rendering feature assumes desktop-only post-processing. Browser report download and persistence must be checked in real browsers before declaring that platform ready.

## Architecture and roadmap

Start with [ADRs](docs/adrs/README.md), [rules and tuning](docs/rules.md), and [agent instructions](AGENTS.md). `src/core/` holds scene-independent state/actions/powers/AI; `src/view/` renders observations; `main.gd` coordinates local play; `src/services/` owns diagnostics and persistence.

Bees epic `nnqr-45` tracks the edition. Local implementation work is `nnqr-46` through `nnqr-49`; private online authority, invite/reconnect flow, and deployment follow in `nnqr-50` through `nnqr-52`. The online design uses a headless authoritative Godot server and filtered WebSocket observations. It is not implemented in this local milestone.

This is a fan recreation, unaffiliated with Quadradius's original creators. Existing Claude-built implementations retain their attribution.
