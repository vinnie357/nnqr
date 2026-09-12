# 0004 — Mechanical strategy table
Status: Accepted

## Context
Astra should improve clarity and style rather than reskin prior versions.
## Decision
Graphite machined arena, beveled tiles and elevation strata, torus pieces with luminous cyan/amber cores and separate team markings. Orthographic orbit/zoom/overhead controls. Ivory type, compact contextual inspector, strong readable selection rings. Procedural meshes/materials are first-class assets and avoid external asset dependencies. Effects communicate state changes; reduced motion is supported.
## Alternatives
Flat grid lacks terrain legibility; excessive bloom hides legal moves and hurts web portability.
## Consequences and interfaces
Scene rendering consumes state, never mutates it. Invisible enemies and unrevealed powers must be omitted from presentation. Tile picking intersects visible top faces; camera changes must not break it.
## Verification
Representative native screenshots, board extremes, foreground occlusion, resize and actual pointer input. Target 60 FPS on this Mac at default size; measure rather than assert.
