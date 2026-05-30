## orbs.gd — Power orb spawning and collection, ported from web/src/core/orbs.ts.
##
## Orbs spawn every SPAWN_INTERVAL turns on random empty tiles (2-4 at a time).
## A piece that lands on an orb collects it; the power_id is added to its
## powers inventory. All randomness is drawn from rng.gd (never randf/randi).
##
## Usage:
##   const Orbs = preload("res://src/orbs.gd")
##   if Orbs.should_spawn_orbs(state.turn):
##       state = Orbs.spawn_orbs(state, power_ids)
##   var result = Orbs.collect_orb(state, row, col)
##   state = result.state; var collected = result.collected
extends RefCounted

const Rng = preload("res://src/rng.gd")
const GameState = preload("res://src/game_state.gd")

const SPAWN_INTERVAL: int = 7
const MIN_ORBS: int = 2
const MAX_ORBS: int = 4


# ---------------------------------------------------------------------------
# Internal: shallow copy of a GameState (avoids duplicate() type issue).
# ---------------------------------------------------------------------------
static func _copy_state(src: GameState) -> GameState:
	var dst := GameState.new()
	dst.cols = src.cols
	dst.rows = src.rows
	dst.current_player = src.current_player
	dst.turn = src.turn
	dst.status = src.status
	dst.winner = src.winner
	dst.seed = src.seed
	dst.pieces = src.pieces
	dst.height_map = src.height_map
	dst.destroyed_tiles = src.destroyed_tiles
	dst.orbs = src.orbs
	dst.selected = src.selected
	dst.valid_moves = src.valid_moves
	return dst


## True when orbs should spawn this turn.
static func should_spawn_orbs(turn: int) -> bool:
	return turn > 0 and turn % SPAWN_INTERVAL == 0


## Returns all tiles that are empty (no piece, no orb, not destroyed).
static func empty_tiles(state: GameState) -> Array:
	# Build occupied set as "row,col" strings.
	var occupied: Dictionary = {}
	for p: GameState.Piece in state.pieces:
		occupied["%d,%d" % [p.row, p.col]] = true
	for o in state.orbs:
		occupied["%d,%d" % [o.row, o.col]] = true

	var tiles: Array = []
	for row in range(1, state.rows + 1):
		for col in range(1, state.cols + 1):
			var key := "%d,%d" % [row, col]
			if not occupied.has(key) and not state.destroyed_tiles.has(key):
				tiles.append({"row": row, "col": col})
	return tiles


## Spawn 2-4 orbs on random empty tiles, each with a random power_id.
## Deterministic: uses rng seeded with (state.seed + state.turn).
## Returns a new state with orbs appended. Unchanged if power_ids is empty.
static func spawn_orbs(state: GameState, power_ids: Array, rng: Rng = null) -> GameState:
	if power_ids.size() == 0:
		return state
	var _rng: Rng
	if rng == null:
		_rng = Rng.new(state.seed + state.turn)
	else:
		_rng = rng

	var open := empty_tiles(state)
	var count := mini(_rng.int(MIN_ORBS, MAX_ORBS), open.size())
	var chosen: Dictionary = {}
	var new_orbs: Array = []
	while chosen.size() < count:
		var idx := _rng.int(0, open.size() - 1)
		if chosen.has(idx):
			continue
		chosen[idx] = true
		var tile: Dictionary = open[idx]
		var power_id: String = power_ids[_rng.int(0, power_ids.size() - 1)]
		new_orbs.append({"row": tile.row, "col": tile.col, "power_id": power_id})

	var next: GameState = _copy_state(state)
	next.orbs = state.orbs.duplicate() + new_orbs
	return next


## Collect an orb at (row, col): adds its power_id to the piece there.
## Returns {"state": GameState, "collected": String|null}.
static func collect_orb(state: GameState, row: int, col: int) -> Dictionary:
	# Find orb at this position.
	var orb: Dictionary = {}
	for o in state.orbs:
		if o.row == row and o.col == col:
			orb = o
			break
	if orb.is_empty():
		return {"state": state, "collected": null}

	# Find piece at this position.
	var piece: GameState.Piece = null
	for p: GameState.Piece in state.pieces:
		if p.row == row and p.col == col:
			piece = p
			break
	if piece == null:
		return {"state": state, "collected": null}

	# Build new pieces array with updated powers on the collector.
	var new_pieces: Array = []
	for p: GameState.Piece in state.pieces:
		if p.id == piece.id:
			var updated := GameState.Piece.new(p.id, p.player, p.row, p.col)
			updated.powers = p.powers.duplicate()
			updated.powers.append(orb.power_id)
			updated.is_jump_proof = p.is_jump_proof
			updated.can_move_diagonally = p.can_move_diagonally
			updated.can_climb_any = p.can_climb_any
			updated.can_wrap = p.can_wrap
			updated.is_invisible = p.is_invisible
			new_pieces.append(updated)
		else:
			new_pieces.append(p)

	# Remove the collected orb.
	var new_orbs: Array = []
	for o in state.orbs:
		if o != orb:
			new_orbs.append(o)

	var next: GameState = _copy_state(state)
	next.pieces = new_pieces
	next.orbs = new_orbs
	return {"state": next, "collected": orb.power_id}
