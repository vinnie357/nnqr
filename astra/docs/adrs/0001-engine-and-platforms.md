# 0001 — Engine and platforms
Status: Accepted

## Context
Astra needs native macOS and shareable browser play, 3D terrain, and deterministic headless tests. The previous plan targeted 4.7.2, but downloads are unavailable in this execution environment (github.com DNS fails); a working 4.6.3 binary is cached.
## Decision
Implement against Godot 4.6.3 GDScript and Compatibility rendering now. Pin engine and export templates together. The launcher permits GODOT_BIN and GODOT_VERSION overrides. Upgrade to a verified newer stable release when obtainable and rerun all platform checks. This is a documented feasibility exception, not a change to the user's upgrade authorization.
## Alternatives
Unreal adds tooling cost without a required rendering feature; Phaser is browser-friendly but 2D; Bevy adds compilation and integration overhead for this small board.
## Consequences and interfaces
Independent project under astra/. Use single-threaded web export. Do not change other implementations' engine requirements. Cache downloads inside ignored astra/.tools, not global system locations.
## Verification
Headless rules tests, actual native render/picking smoke, browser export and browser smoke when templates are available. Never claim an unavailable export was tested.
