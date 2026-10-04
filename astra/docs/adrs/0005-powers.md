# 0005 — Catalog and effect pipeline
Status: Accepted

## Context
A complete catalog needs common targeting and coherent persistent effects.
## Decision
res://src/core/powers.gd provides static catalog() -> Dictionary keyed snake_case ID, each entry {name,description,category,target:String}. target is self, tile, ally, enemy, or piece. Static targets(state,piece_id,power_id) -> Array of {row,col}; static apply(state,piece_id,power_id,target:Dictionary={}) -> {ok:bool,events:Array,error:String} mutates ONLY the already-cloned state passed by Rules. apply validates its targets, performs the effect, but does NOT consume inventory or switch turns. Rules owns consumption and finalization. random_int(state,max_exclusive) owns deterministic RNG. Do not preload Rules from Powers (avoid circular preload); local helpers permitted.
All powers use permanent flags keyed by power ID where applicable. Row/column/radial family effects use shared targeting. Grow expands bands/radius and caps at three. Catalog IDs: snake_case research names, with '2x' named 'double_powers' and Bombs named 'bombs'.
## Alternatives
One bespoke scene script per power duplicates lifecycle and cannot run on a server.
## Consequences and interfaces
Catalog prose is original concise explanation. Persistent flags and tile marks must remain serializable. UI previews use targets and the catalog, not its own geometric guesses.
## Verification
Every collectible has an executable non-placeholder effect and meaningful positive/negative tests. Test interactions, not just catalog counts.
