# 0009 — Repeatable development and playtest tools
Status: Accepted

## Context
The repository already uses mise and Nushell. User requested those tools for operations helpers need more than once.
## Decision
Expose root `astra-*` mise tasks and equivalent short tasks in `astra/mise.toml`. Use `astra/astra.nu` for artifact status, report listing, report replay, and recent logs. Keep small Bash wrappers for engine discovery/launch/export so a downloaded checkout can launch with standard macOS tools even before Nushell is activated. Do not duplicate rules in diagnostic utilities: replay calls the same GDScript action interface as live play.
## Alternatives
Repeated ad-hoc shell snippets drift and lose reproducibility. Rewriting the entire existing launcher into a new tool would add installation friction without improving the game.
## Consequences and interfaces
`mise run astra-replay -- <report.zip>` accepts a report bundle or replay.json and exits nonzero on divergence. `astra-status` reports artifact existence without pretending presence establishes acceptance. Tests use isolated data directories, explicit logs, and fail on GDScript runtime errors as well as process status.
Astra has project-local `mise run ci` and a matching GitHub Actions headless test job. Native screenshots and full-match testing remain separate acceptance checks.

## Verification
Run Nushell status/report listing; reconstruct a real report's actions and compare final state; exercise a corrupt final-state report to verify nonzero exit; run root test task.
