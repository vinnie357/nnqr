# Astra working agreement

Astra owns integration and architectural decisions. Read `docs/adrs/README.md` and the ADRs named in your task before editing. Work only in assigned files; other agents share this checkout. Raise interface changes with the lead before making them. Never commit another agent's incomplete work.

Use `bees` for issues; parent issue nnqr-45. Each handoff reports changed files, tests run, failures, and remaining risks. Read the original research for semantics, not old implementation comments. Avoid copying old implementations wholesale.

Run `mise run astra-test` (or `bash astra/scripts/test.sh`) for the integrated suite with isolated data and writable log paths. Test scripts must exit nonzero on failed checks. Rendering verification requires an actual rendering viewport, not just headless parsing.

GDScript: use explicit variable types or `=` when expressions return Variant; avoid inferred-Variant warnings. Core state is plain serializable dictionaries; scene objects never enter it. All random game outcomes use the state RNG. No global class names required: preload scripts explicitly.

## Repeatable tooling

Use root mise tasks rather than reinventing shell sequences: `astra-test`, `astra-qa`, `astra-status`, `astra-reports`, `astra-replay -- <report.zip>`, and `astra-logs`. `astra/astra.nu` implements reusable diagnostic operations. Use `bash astra/scripts/test.sh` as the dependency-light fallback when mise cannot write its global cache. Always use launch wrappers with their explicit log path: a bare Godot invocation can crash if the platform user log directory is not writable.
