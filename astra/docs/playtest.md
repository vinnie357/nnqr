# Astra playtest checklist

## First: rendered verification

From a normal Terminal at the repository root:

```nu
mise run astra-qa
```

The game briefly opens, saves `astra/.qa/arena.png`, `power.png`, and `state.json`, prints `ASTRA_QA_OK`, then closes. Tell Astra the result so it can inspect the generated files. This launch needs macOS GUI access; the restricted agent process cannot provide that access. Headless tests already verify controller/camera math, but cannot prove visual quality.

## Interactive test (about five minutes)

Run `mise run astra-start`, then:

1. Choose **Play against AI** on Medium. Select a cyan torus in the forward rank and move to a highlighted tile. Expect one move, Amber's reply, then Cyan's turn.
2. Move toward a luminous orb. After collecting it, select that piece and click its power in the inspector. Read the preview before activating; a power normally leaves movement available.
3. Open **Pause → New match → Power laboratory**. Add **Move Diagonal** to the selected piece, activate it, and check that diagonal destinations appear. Add **Raise Tile**, activate it, and inspect the changed height from Overhead.
4. Rotate in both directions, zoom, and resize the window. Check that pieces remain readable and clicking targets the intended tile. Click the selected piece again to deselect it.
5. Start a hotseat game and make a move. Expect an opaque handoff screen; only **Ready** should reveal the next player's view.
6. Close and relaunch. Choose **Continue saved match** and check board, powers, and turn restoration.
7. Use **Report issue**. Enter your feedback, export the ZIP, and use **Open reports folder**. Attach that ZIP in the conversation. Browser builds download the ZIP instead.

Please comment on three things: can you read elevations and legal moves quickly; does a power's explanation match the outcome; and does the board feel responsive? For a bug, include what you expected and your last few actions.

## Diagnostics

Development reports are under `astra/.userdata/reports`, and launch logs under `astra/.logs`. Reports include feedback, current full local match state, a bounded reproducible action history, build/platform/seed information, available engine log, and screenshot. Reports remain local until you share them. Failed actions are recorded too.

Use `mise run astra-reports`, `mise run astra-logs`, or `mise run astra-replay -- /absolute/path/report.zip` for repeatable inspection. A hard OS/engine crash may prevent a final stack trace; incremental records preserve earlier evidence. If the game fails before its report button is available, share the command's error text; Astra can inspect the existing local logs.

Browser acceptance follows successful export: start AI and hotseat games in both Safari and Chrome, test sound after clicking Play, save/reload, and report download. A static browser build does not yet provide remote multiplayer.
