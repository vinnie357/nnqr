# 0003 — Deterministic state/action contract
Status: Accepted

## Context
Renderer, AI, diagnostics and future authority must share rules without scene dependencies.
## Decision
Use plain Dictionary state, all coordinates zero-based. Tiles are row-major index row*10+col. A state contains: version:1, seed:int, rng:int, next_id:int, turn:int (completed individual turns), active:int (1/2), status:String (playing/won/draw), winner:int (0/1/2), passes:int, pieces:Array[Dictionary], tiles:Array[Dictionary]. Piece: id:int, owner:int, row:int, col:int, inventory:Dictionary[String,int], flags:Dictionary. Tile: height:int, destroyed:bool, orb:String (empty absent), marks:Dictionary. Additional explicit serializable fields are allowed with defaults.
Rules script res://src/core/rules.gd static API:
- new_game(seed:int=1) -> Dictionary
- piece_at(state:Dictionary,row:int,col:int) -> Dictionary (empty absent)
- piece_by_id(state:Dictionary,id:int) -> Dictionary (empty absent)
- legal_moves(state:Dictionary,id:int) -> Array of {row,col,capture:bool}
- apply_action(state:Dictionary,action:Dictionary) -> {ok:bool,state:Dictionary,events:Array,error:String}; input is never mutated, failed actions return unchanged state.
Actions: {type:'move',piece_id:int,row:int,col:int}, {type:'power',piece_id:int,power_id:String,target:{row:int,col:int}}, {type:'pass'}, {type:'resign'}.
Rules invokes Powers.apply on a deep working copy, consumes powers only on success, checks overheat and victory, and advances turns after movement. Activated move_again increments piece.flags.extra_moves. Other persistent flags use power IDs, e.g. move_diagonal, climb_tile, flat_to_sphere, jump_proof, invisible, grow_quadradius.
## Alternatives
Godot objects and metadata are convenient but make complete serialization and cloning fragile.
## Consequences and interfaces
All authoritative randomness updates state.rng through a shared deterministic routine in Powers (random_int(state, max_exclusive)); bounded integer generator. No scene/global RNG in game rules. Renderer/UI state is separate. Save and replay use deep plain-data copies.
## Verification
Invalid-action immutability, deterministic sequences, clone/JSON preservation of every flag and tile mark.
