# 0007 — Saves, replay and playtest reports
Status: Accepted

## Context
User will playtest and needs actionable feedback capture, including errors.
## Decision
Versioned JSON autosave after successful actions, written to a temporary file and atomically renamed so interruption does not truncate the prior save. Validate the complete plain-data state and board invariants before loading it into the controller. Keep initial state and bounded action records alongside build ID, seed, platform and timestamp. When old actions are removed, advance the replay baseline to their resulting checkpoint so the retained history remains reproducible. Report issue gathers feedback text, current full local match state, recent actions, engine log where readable, and a viewport screenshot in a ZIP; native reports saved under user://reports and browser downloads via JavaScriptBridge.download_buffer. Development launchers may set `ASTRA_DATA_DIR` to an ignored project-local directory so sandboxed tools use writable storage; exported builds leave it unset and retain `user://`. Exclude online credentials/tokens. Persist diagnostics incrementally. Capture engine errors through the launcher-selected log output; never claim every hard crash yields a stack trace.
Service res://src/services/diagnostics.gd extends RefCounted: start(state), record(action,result), save(state), load_save()->Dictionary, report(state,feedback,viewport)->String path/status, report_directory()->String. Root controller integrates these calls; service owns I/O only.
## Alternatives
Chat-only reports lose reproduction state; automatic remote telemetry is unnecessary.
## Consequences and interfaces
Reports remain local until user shares them. Include build version in UI and report. Sandbox mutations reset replay baseline.
## Verification
Save roundtrip, bundle contents, failed action evidence, recoverable log after interrupted play, native export and browser download.
