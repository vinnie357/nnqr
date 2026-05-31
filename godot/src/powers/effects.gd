## effects.gd — Power effect handlers, ported from web/src/core/powers/effects.ts.
##
## Design rules (mirror effects.ts):
##   • All functions are PURE — return a new GameState, never mutate inputs.
##   • _copy_state() is used for all state construction (same as board.gd).
##   • RNG uses RNG.new(state.seed + state.turn) — never randf()/randi().
##   • 82 activate_* handlers mirror the TS naming (snake_case).
##   • Extended-state fields (bankrupt_tiles, hotspot_tiles, multiplied_pieces,
##     extra_move) are carried as Dictionary keys on the returned state via
##     GameState.set() — GDScript has no index-type extension so we use set/get.
##
## Usage:
##   const Effects = preload("res://src/powers/effects.gd")
##   var effects = Effects.new()
##   var new_state = effects.activate_destroy_row(state, piece)
extends RefCounted

const GameState = preload("res://src/game_state.gd")
const Height = preload("res://src/height.gd")
const RNG = preload("res://src/rng.gd")

const BOARD_ROWS: int = 8
const BOARD_COLS: int = 10


# ---------------------------------------------------------------------------
# State copy helper — must match board.gd's _copy_state convention.
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
	# Copy extended fields
	for key in ["extra_move", "bankrupt_tiles", "hotspot_tiles", "multiplied_pieces"]:
		if src.has_meta(key):
			dst.set_meta(key, src.get_meta(key))
	return dst


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

## Returns pieces array with `next` replacing the piece with the same id.
static func _replace_piece(pieces: Array, next: GameState.Piece) -> Array:
	var result: Array = []
	for p: GameState.Piece in pieces:
		if p.id == next.id:
			result.append(next)
		else:
			result.append(p)
	return result


## Returns pieces array with the piece whose id matches removed.
static func _remove_piece_by_id(pieces: Array, id: String) -> Array:
	var result: Array = []
	for p: GameState.Piece in pieces:
		if p.id != id:
			result.append(p)
	return result


## Returns a new Piece with one copy of power_id removed from powers.
static func _consume_power(piece: GameState.Piece, power_id: String) -> GameState.Piece:
	var idx := piece.powers.find(power_id)
	if idx == -1:
		return piece
	var new_powers: Array = []
	for i in range(piece.powers.size()):
		if i != idx:
			new_powers.append(piece.powers[i])
	var np := GameState.Piece.new(piece.id, piece.player, piece.row, piece.col)
	np.powers = new_powers
	np.is_jump_proof = piece.is_jump_proof
	np.can_move_diagonally = piece.can_move_diagonally
	np.can_climb_any = piece.can_climb_any
	np.can_wrap = piece.can_wrap
	np.is_invisible = piece.is_invisible
	# Copy dynamic flags
	for key in ["powers_revealed", "is_tripwired", "is_inhibited", "parasitized_by",
		"is_scavenger", "is_beneficiary", "grow_quadradius_level"]:
		if piece.has_meta(key):
			np.set_meta(key, piece.get_meta(key))
	return np


## Returns a new Piece (full copy).
static func _clone_piece(piece: GameState.Piece) -> GameState.Piece:
	return _consume_power(piece, "__none__")  # no-op consume clones fields


## Returns a new state where piece has had power_id consumed.
static func _with_consumed_power(state: GameState, piece: GameState.Piece, power_id: String) -> GameState:
	var updated := _consume_power(piece, power_id)
	var dst := _copy_state(state)
	dst.pieces = _replace_piece(state.pieces, updated)
	return dst


## Returns height_map deep copy.
static func _copy_height_map(hm: Array) -> Array:
	var result: Array = []
	for row_arr in hm:
		result.append(row_arr.duplicate())
	return result


## Returns all empty non-destroyed tiles.
static func _empty_tiles(state: GameState) -> Array:
	var occupied: Dictionary = {}
	for p: GameState.Piece in state.pieces:
		occupied["%d,%d" % [p.row, p.col]] = true
	var tiles: Array = []
	for r in range(1, state.rows + 1):
		for c in range(1, state.cols + 1):
			var key := "%d,%d" % [r, c]
			var is_destroyed: bool = state.destroyed_tiles.get(key, false) == true
			if not occupied.has(key) and not is_destroyed:
				tiles.append({"row": r, "col": c})
	return tiles


## Returns all pieces in the given area (excluding the activating piece).
##
## Honoured grow_quadradius_level on the activating piece:
##   radial: Chebyshev distance 1+L
##   row:    band [row-L, row+L]  (2L+1 rows)
##   column: band [col-L, col+L]  (2L+1 cols)
## L=0 reproduces the original behaviour exactly.
static func _area_pieces(state: GameState, piece: GameState.Piece, area: String) -> Array:
	var L: int = piece.get_meta("grow_quadradius_level", 0)
	var result: Array = []
	for p: GameState.Piece in state.pieces:
		if p.id == piece.id:
			continue
		match area:
			"row":
				if abs(p.row - piece.row) <= L:
					result.append(p)
			"column":
				if abs(p.col - piece.col) <= L:
					result.append(p)
			"radial":
				var dist: int = 1 + L
				if abs(p.row - piece.row) <= dist and abs(p.col - piece.col) <= dist:
					result.append(p)
	return result


## Returns all tile coords in the given area, excluding the activating piece's own tile.
##
## Honoured grow_quadradius_level on the activating piece:
##   radial: Chebyshev distance 1+L
##   row:    band [row-L, row+L]  (2L+1 rows)
##   column: band [col-L, col+L]  (2L+1 cols)
## L=0 reproduces the original behaviour exactly.
static func _area_tile_coords(state: GameState, piece: GameState.Piece, area: String) -> Array:
	var L: int = piece.get_meta("grow_quadradius_level", 0)
	var tiles: Array = []
	match area:
		"row":
			for dr in range(-L, L + 1):
				var r := piece.row + dr
				if r < 1 or r > state.rows:
					continue
				for c in range(1, state.cols + 1):
					if r == piece.row and c == piece.col:
						continue
					tiles.append({"row": r, "col": c})
		"column":
			for dc in range(-L, L + 1):
				var c := piece.col + dc
				if c < 1 or c > state.cols:
					continue
				for r in range(1, state.rows + 1):
					if r == piece.row and c == piece.col:
						continue
					tiles.append({"row": r, "col": c})
		"radial":
			var dist: int = 1 + L
			for dr in range(-dist, dist + 1):
				for dc in range(-dist, dist + 1):
					if dr == 0 and dc == 0:
						continue
					var r := piece.row + dr
					var c := piece.col + dc
					if r >= 1 and r <= state.rows and c >= 1 and c <= state.cols:
						tiles.append({"row": r, "col": c})
	return tiles


# ---------------------------------------------------------------------------
# Core family implementations
# ---------------------------------------------------------------------------

## Core: destroy pieces in area. Does NOT affect terrain.
static func _destroy_area(state: GameState, piece: GameState.Piece, area: String, power_id: String) -> GameState:
	var targets := _area_pieces(state, piece, area)
	var target_ids: Dictionary = {}
	for t: GameState.Piece in targets:
		target_ids[t.id] = true
	var pieces: Array = []
	for p: GameState.Piece in state.pieces:
		if not target_ids.has(p.id):
			pieces.append(p)
	var updated := _consume_power(piece, power_id)
	var dst := _copy_state(state)
	dst.pieces = _replace_piece(pieces, updated)
	return dst


## Core: destroy pieces AND mark tiles as destroyed.
static func _acidic_area(state: GameState, piece: GameState.Piece, area: String, power_id: String) -> GameState:
	var targets := _area_pieces(state, piece, area)
	var target_ids: Dictionary = {}
	for t: GameState.Piece in targets:
		target_ids[t.id] = true
	var pieces: Array = []
	for p: GameState.Piece in state.pieces:
		if not target_ids.has(p.id):
			pieces.append(p)
	var tiles := _area_tile_coords(state, piece, area)
	var destroyed_tiles: Dictionary = state.destroyed_tiles.duplicate()
	for t in tiles:
		destroyed_tiles["%d,%d" % [t.row, t.col]] = true
	var updated := _consume_power(piece, power_id)
	var dst := _copy_state(state)
	dst.pieces = _replace_piece(pieces, updated)
	dst.destroyed_tiles = destroyed_tiles
	return dst


## Core: recruit (convert) enemy pieces in area.
static func _recruit_area(state: GameState, piece: GameState.Piece, area: String, power_id: String) -> GameState:
	var targets := _area_pieces(state, piece, area)
	var target_ids: Dictionary = {}
	for t: GameState.Piece in targets:
		if t.player != piece.player:
			target_ids[t.id] = true
	var pieces: Array = []
	for p: GameState.Piece in state.pieces:
		if target_ids.has(p.id):
			var np := _clone_piece(p)
			np.player = piece.player
			pieces.append(np)
		else:
			pieces.append(p)
	var updated := _consume_power(piece, power_id)
	var dst := _copy_state(state)
	dst.pieces = _replace_piece(pieces, updated)
	return dst


## Core: scramble (shuffle) column positions of pieces in row area.
static func _scramble_row(state: GameState, piece: GameState.Piece, power_id: String) -> GameState:
	var rng := RNG.new(state.seed + state.turn)
	var in_row: Array = []
	for p: GameState.Piece in state.pieces:
		if p.row == piece.row:
			in_row.append(p)
	var cols: Array = []
	for p: GameState.Piece in in_row:
		cols.append(p.col)
	# Fisher-Yates shuffle
	for i in range(cols.size() - 1, 0, -1):
		var j := rng.int(0, i)
		var tmp = cols[i]
		cols[i] = cols[j]
		cols[j] = tmp
	# Build shuffled map
	var shuffled: Dictionary = {}
	for i in range(in_row.size()):
		shuffled[in_row[i].id] = cols[i]
	var pieces: Array = []
	for p: GameState.Piece in state.pieces:
		if shuffled.has(p.id):
			var np := _clone_piece(p)
			np.col = shuffled[p.id]
			pieces.append(np)
		else:
			pieces.append(p)
	var updated := _consume_power(piece, power_id)
	var dst := _copy_state(state)
	dst.pieces = _replace_piece(pieces, updated)
	return dst


## Core: scramble (shuffle) row positions of pieces in column area.
static func _scramble_column(state: GameState, piece: GameState.Piece, power_id: String) -> GameState:
	var rng := RNG.new(state.seed + state.turn)
	var in_col: Array = []
	for p: GameState.Piece in state.pieces:
		if p.col == piece.col:
			in_col.append(p)
	var rows: Array = []
	for p: GameState.Piece in in_col:
		rows.append(p.row)
	for i in range(rows.size() - 1, 0, -1):
		var j := rng.int(0, i)
		var tmp = rows[i]
		rows[i] = rows[j]
		rows[j] = tmp
	var shuffled: Dictionary = {}
	for i in range(in_col.size()):
		shuffled[in_col[i].id] = rows[i]
	var pieces: Array = []
	for p: GameState.Piece in state.pieces:
		if shuffled.has(p.id):
			var np := _clone_piece(p)
			np.row = shuffled[p.id]
			pieces.append(np)
		else:
			pieces.append(p)
	var updated := _consume_power(piece, power_id)
	var dst := _copy_state(state)
	dst.pieces = _replace_piece(pieces, updated)
	return dst


## Core: scramble radial (shuffle {row,col} pairs in area).
## Respects grow_quadradius_level on the activating piece.
static func _scramble_radial(state: GameState, piece: GameState.Piece, power_id: String) -> GameState:
	var L: int = piece.get_meta("grow_quadradius_level", 0)
	var dist: int = 1 + L
	var rng := RNG.new(state.seed + state.turn)
	var in_area: Array = []
	for p: GameState.Piece in state.pieces:
		if abs(p.row - piece.row) <= dist and abs(p.col - piece.col) <= dist:
			in_area.append(p)
	var positions: Array = []
	for p: GameState.Piece in in_area:
		positions.append({"row": p.row, "col": p.col})
	for i in range(positions.size() - 1, 0, -1):
		var j := rng.int(0, i)
		var tmp = positions[i]
		positions[i] = positions[j]
		positions[j] = tmp
	var shuffled: Dictionary = {}
	for i in range(in_area.size()):
		shuffled[in_area[i].id] = positions[i]
	var pieces: Array = []
	for p: GameState.Piece in state.pieces:
		if shuffled.has(p.id):
			var np := _clone_piece(p)
			np.row = shuffled[p.id].row
			np.col = shuffled[p.id].col
			pieces.append(np)
		else:
			pieces.append(p)
	var updated := _consume_power(piece, power_id)
	var dst := _copy_state(state)
	dst.pieces = _replace_piece(pieces, updated)
	return dst


## Core: raise/lower tiles in area by delta.
static func _adjust_height_area(state: GameState, piece: GameState.Piece, area: String,
		delta: int, power_id: String, include_own: bool = false) -> GameState:
	var tiles := _area_tile_coords(state, piece, area)
	if include_own:
		tiles.append({"row": piece.row, "col": piece.col})
	var height_map := _copy_height_map(state.height_map)
	for t in tiles:
		var cur := Height.get_height(height_map, t.row, t.col)
		height_map[t.row - 1][t.col - 1] = clampi(cur + delta, 0, 4)
	var updated := _consume_power(piece, power_id)
	var dst := _copy_state(state)
	dst.height_map = height_map
	dst.pieces = _replace_piece(state.pieces, updated)
	return dst


## Core: invert heights in area.
static func _invert_area(state: GameState, piece: GameState.Piece, area: String, power_id: String) -> GameState:
	var tiles := _area_tile_coords(state, piece, area)
	tiles.append({"row": piece.row, "col": piece.col})
	var height_map := _copy_height_map(state.height_map)
	for t in tiles:
		var cur := Height.get_height(height_map, t.row, t.col)
		height_map[t.row - 1][t.col - 1] = clampi(Height.MAX_HEIGHT - cur, 0, 4)
	var updated := _consume_power(piece, power_id)
	var dst := _copy_state(state)
	dst.height_map = height_map
	dst.pieces = _replace_piece(state.pieces, updated)
	return dst


## Core: dredge — raise ally tiles, lower enemy tiles in area.
static func _dredge_area(state: GameState, piece: GameState.Piece, area: String, power_id: String) -> GameState:
	var tiles := _area_tile_coords(state, piece, area)
	tiles.append({"row": piece.row, "col": piece.col})
	var height_map := _copy_height_map(state.height_map)
	for t in tiles:
		var occupant: GameState.Piece = null
		for p: GameState.Piece in state.pieces:
			if p.row == t.row and p.col == t.col:
				occupant = p
				break
		if occupant == null:
			continue
		var cur := Height.get_height(height_map, t.row, t.col)
		var delta := 1 if occupant.player == piece.player else -1
		height_map[t.row - 1][t.col - 1] = clampi(cur + delta, 0, 4)
	var updated := _consume_power(piece, power_id)
	var dst := _copy_state(state)
	dst.height_map = height_map
	dst.pieces = _replace_piece(state.pieces, updated)
	return dst


## Core: teach — copy caster's powers to allied pieces in area.
static func _teach_area(state: GameState, piece: GameState.Piece, area: String, power_id: String) -> GameState:
	var caster_updated := _consume_power(piece, power_id)
	var allies := _area_pieces(state, piece, area)
	var ally_ids: Dictionary = {}
	for a: GameState.Piece in allies:
		if a.player == piece.player:
			ally_ids[a.id] = true
	var base_pieces := _replace_piece(state.pieces, caster_updated)
	var pieces: Array = []
	for p: GameState.Piece in base_pieces:
		if ally_ids.has(p.id):
			var np := _clone_piece(p)
			for pw in caster_updated.powers:
				np.powers.append(pw)
			pieces.append(np)
		else:
			pieces.append(p)
	var dst := _copy_state(state)
	dst.pieces = pieces
	return dst


## Core: learn — absorb powers from allied pieces in area.
static func _learn_area(state: GameState, piece: GameState.Piece, area: String, power_id: String) -> GameState:
	var caster_updated := _consume_power(piece, power_id)
	var allies := _area_pieces(state, piece, area)
	var drain_ids: Dictionary = {}
	for a: GameState.Piece in allies:
		if a.player == piece.player:
			drain_ids[a.id] = true
	var gained: Array = []
	var base_pieces := _replace_piece(state.pieces, caster_updated)
	var pieces: Array = []
	for p: GameState.Piece in base_pieces:
		if drain_ids.has(p.id):
			for pw in p.powers:
				gained.append(pw)
			var np := _clone_piece(p)
			np.powers = []
			pieces.append(np)
		else:
			pieces.append(p)
	# Give gained powers to caster
	var final_pieces: Array = []
	for p: GameState.Piece in pieces:
		if p.id == piece.id:
			var np := _clone_piece(p)
			for pw in gained:
				np.powers.append(pw)
			final_pieces.append(np)
		else:
			final_pieces.append(p)
	var dst := _copy_state(state)
	dst.pieces = final_pieces
	return dst


## Core: pilfer — steal one random power from each enemy in area.
static func _pilfer_area(state: GameState, piece: GameState.Piece, area: String, power_id: String) -> GameState:
	var rng := RNG.new(state.seed + state.turn)
	var enemies := _area_pieces(state, piece, area)
	var caster_updated := _consume_power(piece, power_id)
	var working_pieces := _replace_piece(state.pieces, caster_updated)
	var stolen_powers: Array = []
	for enemy: GameState.Piece in enemies:
		if enemy.player == piece.player:
			continue
		var current: GameState.Piece = null
		for p: GameState.Piece in working_pieces:
			if p.id == enemy.id:
				current = p
				break
		if current == null or current.powers.size() == 0:
			continue
		var idx := rng.int(0, current.powers.size() - 1)
		var stolen: String = current.powers[idx]
		stolen_powers.append(stolen)
		var new_enemy_powers: Array = []
		for i in range(current.powers.size()):
			if i != idx:
				new_enemy_powers.append(current.powers[i])
		var np := _clone_piece(current)
		np.powers = new_enemy_powers
		working_pieces = _replace_piece(working_pieces, np)
	# Give stolen to caster
	var final_pieces: Array = []
	for p: GameState.Piece in working_pieces:
		if p.id == piece.id:
			var np := _clone_piece(p)
			for pw in stolen_powers:
				np.powers.append(pw)
			final_pieces.append(np)
		else:
			final_pieces.append(p)
	var dst := _copy_state(state)
	dst.pieces = final_pieces
	return dst


## Core: flag-mark enemy pieces in area with a debuff flag.
static func _flag_enemies_area(state: GameState, piece: GameState.Piece, area: String,
		power_id: String, flag_key: String, flag_value) -> GameState:
	var enemies := _area_pieces(state, piece, area)
	var enemy_ids: Dictionary = {}
	for e: GameState.Piece in enemies:
		if e.player != piece.player:
			enemy_ids[e.id] = true
	var pieces: Array = []
	for p: GameState.Piece in state.pieces:
		if enemy_ids.has(p.id):
			var np := _clone_piece(p)
			np.set_meta(flag_key, flag_value)
			pieces.append(np)
		else:
			pieces.append(p)
	var updated := _consume_power(piece, power_id)
	var dst := _copy_state(state)
	dst.pieces = _replace_piece(pieces, updated)
	return dst


## Core: refurb area — repair destroyed tiles in area.
static func _refurb_area(state: GameState, piece: GameState.Piece, area: String, power_id: String) -> GameState:
	if state.destroyed_tiles.is_empty():
		return _with_consumed_power(state, piece, power_id)
	var tiles := _area_tile_coords(state, piece, area)
	tiles.append({"row": piece.row, "col": piece.col})
	var destroyed_tiles: Dictionary = state.destroyed_tiles.duplicate()
	var height_map := _copy_height_map(state.height_map)
	for t in tiles:
		var key := "%d,%d" % [t.row, t.col]
		if destroyed_tiles.has(key):
			destroyed_tiles.erase(key)
			height_map[t.row - 1][t.col - 1] = 0
	var updated := _consume_power(piece, power_id)
	var dst := _copy_state(state)
	dst.pieces = _replace_piece(state.pieces, updated)
	dst.destroyed_tiles = destroyed_tiles
	dst.height_map = height_map
	return dst


## Core: bankrupt — mark tiles in area as bankrupt traps.
static func _bankrupt_area(state: GameState, piece: GameState.Piece, area: String, power_id: String) -> GameState:
	var bankrupt_tiles: Dictionary = (state.get_meta("bankrupt_tiles", {}) as Dictionary).duplicate()
	var tiles := _area_tile_coords(state, piece, area)
	for t in tiles:
		bankrupt_tiles["%d,%d" % [t.row, t.col]] = true
	var updated := _consume_power(piece, power_id)
	var dst := _copy_state(state)
	dst.pieces = _replace_piece(state.pieces, updated)
	dst.set_meta("bankrupt_tiles", bankrupt_tiles)
	return dst


## Core: purify — remove debuffs from allies, buffs from enemies in area.
static func _purify_area(state: GameState, piece: GameState.Piece, area: String, power_id: String) -> GameState:
	var candidates := _area_pieces(state, piece, area)
	var cand_ids: Dictionary = {}
	for c: GameState.Piece in candidates:
		cand_ids[c.id] = true
	var pieces: Array = []
	for p: GameState.Piece in state.pieces:
		if not cand_ids.has(p.id):
			pieces.append(p)
		elif p.player == piece.player:
			# Remove debuffs from ally
			var np := _clone_piece(p)
			if np.has_meta("powers_revealed"): np.remove_meta("powers_revealed")
			if np.has_meta("is_tripwired"): np.remove_meta("is_tripwired")
			if np.has_meta("is_inhibited"): np.remove_meta("is_inhibited")
			if np.has_meta("parasitized_by"): np.remove_meta("parasitized_by")
			pieces.append(np)
		else:
			# Remove buffs from enemy
			var np := _clone_piece(p)
			if np.has_meta("grow_quadradius_level"): np.remove_meta("grow_quadradius_level")
			np.can_climb_any = false
			np.can_move_diagonally = false
			np.is_jump_proof = false
			np.can_wrap = false
			np.is_invisible = false
			if np.has_meta("is_scavenger"): np.remove_meta("is_scavenger")
			if np.has_meta("is_beneficiary"): np.remove_meta("is_beneficiary")
			pieces.append(np)
	var updated := _consume_power(piece, power_id)
	var dst := _copy_state(state)
	dst.pieces = _replace_piece(pieces, updated)
	return dst


# ---------------------------------------------------------------------------
# Individual effect functions (public — called by executor)
# ---------------------------------------------------------------------------

# --- Movement ---

func activate_move_diagonal(state: GameState, piece: GameState.Piece) -> GameState:
	var updated := _consume_power(piece, "move_diagonal")
	updated.can_move_diagonally = true
	var dst := _copy_state(state)
	dst.pieces = _replace_piece(state.pieces, updated)
	return dst


func activate_move_again(state: GameState, piece: GameState.Piece) -> GameState:
	var updated := _consume_power(piece, "move_again")
	var dst := _copy_state(state)
	dst.pieces = _replace_piece(state.pieces, updated)
	dst.set_meta("extra_move", true)
	return dst


func activate_relocate(state: GameState, piece: GameState.Piece) -> GameState:
	var rng := RNG.new(state.seed + state.turn)
	var open := _empty_tiles(state)
	if open.size() == 0:
		return _with_consumed_power(state, piece, "relocate")
	var target = rng.pick(open)
	var updated := _consume_power(piece, "relocate")
	updated.row = target.row
	updated.col = target.col
	var dst := _copy_state(state)
	dst.pieces = _replace_piece(state.pieces, updated)
	return dst


func activate_switcheroo(state: GameState, piece: GameState.Piece, target: GameState.Piece) -> GameState:
	var updated := _consume_power(piece, "switcheroo")
	var pieces: Array = []
	for p: GameState.Piece in state.pieces:
		if p.id == piece.id:
			var np := _clone_piece(updated)
			np.row = target.row
			np.col = target.col
			pieces.append(np)
		elif p.id == target.id:
			var np := _clone_piece(p)
			np.row = piece.row
			np.col = piece.col
			pieces.append(np)
		else:
			pieces.append(p)
	var dst := _copy_state(state)
	dst.pieces = pieces
	return dst


func activate_flat_to_sphere(state: GameState, piece: GameState.Piece) -> GameState:
	var updated := _consume_power(piece, "flat_to_sphere")
	updated.can_wrap = true
	var dst := _copy_state(state)
	dst.pieces = _replace_piece(state.pieces, updated)
	return dst


func activate_climb_tile(state: GameState, piece: GameState.Piece) -> GameState:
	var updated := _consume_power(piece, "climb_tile")
	updated.can_climb_any = true
	var dst := _copy_state(state)
	dst.pieces = _replace_piece(state.pieces, updated)
	return dst


func activate_hotspot(state: GameState, piece: GameState.Piece) -> GameState:
	var hotspot_tiles: Dictionary = (state.get_meta("hotspot_tiles", {}) as Dictionary).duplicate()
	hotspot_tiles["%d,%d" % [piece.row, piece.col]] = piece.player
	var updated := _consume_power(piece, "hotspot")
	var dst := _copy_state(state)
	dst.pieces = _replace_piece(state.pieces, updated)
	dst.set_meta("hotspot_tiles", hotspot_tiles)
	return dst


func activate_hotspot_teleport(state: GameState, piece: GameState.Piece, target: Dictionary) -> GameState:
	var updated := _consume_power(piece, "hotspot")
	updated.row = int(target.get("row", piece.row))
	updated.col = int(target.get("col", piece.col))
	var dst := _copy_state(state)
	dst.pieces = _replace_piece(state.pieces, updated)
	return dst


func activate_centerpult(state: GameState, piece: GameState.Piece, target) -> GameState:
	if target == null:
		return state
	var t_row: int = target.get("row", -1)
	var t_col: int = target.get("col", -1)
	if t_row < 0:
		return state
	# Displace piece at target (excluding self)
	var displaced: GameState.Piece = null
	for p: GameState.Piece in state.pieces:
		if p.id != piece.id and p.row == t_row and p.col == t_col:
			displaced = p
			break
	var pieces := state.pieces.duplicate()
	if displaced != null:
		pieces = _remove_piece_by_id(pieces, displaced.id)
	var updated := _consume_power(piece, "centerpult")
	updated.row = t_row
	updated.col = t_col
	var dst := _copy_state(state)
	dst.pieces = _replace_piece(pieces, updated)
	return dst


# --- Offensive ---

func activate_destroy_row(state: GameState, piece: GameState.Piece) -> GameState:
	return _destroy_area(state, piece, "row", "destroy_row")


func activate_destroy_column(state: GameState, piece: GameState.Piece) -> GameState:
	return _destroy_area(state, piece, "column", "destroy_column")


func activate_destroy_radial(state: GameState, piece: GameState.Piece) -> GameState:
	return _destroy_area(state, piece, "radial", "destroy_radial")


func activate_bomb(state: GameState, piece: GameState.Piece) -> GameState:
	var targets := _area_pieces(state, piece, "radial")
	var target_ids: Dictionary = {}
	for t: GameState.Piece in targets:
		target_ids[t.id] = true
	var pieces: Array = []
	for p: GameState.Piece in state.pieces:
		if not target_ids.has(p.id):
			pieces.append(p)
	var height_map := _copy_height_map(state.height_map)
	var destroyed_tiles: Dictionary = state.destroyed_tiles.duplicate()
	for dr in range(-1, 2):
		for dc in range(-1, 2):
			var r := piece.row + dr
			var c := piece.col + dc
			if r < 1 or r > state.rows or c < 1 or c > state.cols:
				continue
			var cur := Height.get_height(height_map, r, c)
			var next := cur - 1
			height_map[r - 1][c - 1] = clampi(next, 0, 4)
			if next <= 0:
				destroyed_tiles["%d,%d" % [r, c]] = true
	var updated := _consume_power(piece, "bomb")
	var dst := _copy_state(state)
	dst.pieces = _replace_piece(pieces, updated)
	dst.height_map = height_map
	dst.destroyed_tiles = destroyed_tiles
	return dst


func activate_kamikaze_radial(state: GameState, piece: GameState.Piece) -> GameState:
	# Kamikaze includes self; respects grow_quadradius_level.
	var L: int = piece.get_meta("grow_quadradius_level", 0)
	var dist: int = 1 + L
	var pieces: Array = []
	for p: GameState.Piece in state.pieces:
		if abs(p.row - piece.row) > dist or abs(p.col - piece.col) > dist:
			pieces.append(p)
	var dst := _copy_state(state)
	dst.pieces = pieces
	return dst


func activate_kamikaze_row(state: GameState, piece: GameState.Piece) -> GameState:
	# Respects grow_quadradius_level: destroys 2L+1 rows including self.
	var L: int = piece.get_meta("grow_quadradius_level", 0)
	var pieces: Array = []
	for p: GameState.Piece in state.pieces:
		if abs(p.row - piece.row) > L:
			pieces.append(p)
	var dst := _copy_state(state)
	dst.pieces = pieces
	return dst


func activate_kamikaze_column(state: GameState, piece: GameState.Piece) -> GameState:
	# Respects grow_quadradius_level: destroys 2L+1 columns including self.
	var L: int = piece.get_meta("grow_quadradius_level", 0)
	var pieces: Array = []
	for p: GameState.Piece in state.pieces:
		if abs(p.col - piece.col) > L:
			pieces.append(p)
	var dst := _copy_state(state)
	dst.pieces = pieces
	return dst


func activate_smart_bombs(state: GameState, piece: GameState.Piece) -> GameState:
	var enemies := _area_pieces(state, piece, "radial")
	var enemy_ids: Dictionary = {}
	for e: GameState.Piece in enemies:
		if e.player != piece.player:
			enemy_ids[e.id] = true
	var pieces: Array = []
	for p: GameState.Piece in state.pieces:
		if not enemy_ids.has(p.id):
			pieces.append(p)
	var updated := _consume_power(piece, "smart_bombs")
	var dst := _copy_state(state)
	dst.pieces = _replace_piece(pieces, updated)
	return dst


func activate_acidic_radial(state: GameState, piece: GameState.Piece) -> GameState:
	return _acidic_area(state, piece, "radial", "acidic_radial")


func activate_acidic_row(state: GameState, piece: GameState.Piece) -> GameState:
	return _acidic_area(state, piece, "row", "acidic_row")


func activate_acidic_column(state: GameState, piece: GameState.Piece) -> GameState:
	return _acidic_area(state, piece, "column", "acidic_column")


func activate_pilfer_radial(state: GameState, piece: GameState.Piece) -> GameState:
	return _pilfer_area(state, piece, "radial", "pilfer_radial")


func activate_pilfer_row(state: GameState, piece: GameState.Piece) -> GameState:
	return _pilfer_area(state, piece, "row", "pilfer_row")


func activate_pilfer_column(state: GameState, piece: GameState.Piece) -> GameState:
	return _pilfer_area(state, piece, "column", "pilfer_column")


# --- Defensive ---

func activate_jump_proof(state: GameState, piece: GameState.Piece) -> GameState:
	var updated := _consume_power(piece, "jump_proof")
	updated.is_jump_proof = true
	var dst := _copy_state(state)
	dst.pieces = _replace_piece(state.pieces, updated)
	return dst


# --- Terrain ---

func activate_raise_tile(state: GameState, piece: GameState.Piece, target: Dictionary) -> GameState:
	var height_map := _copy_height_map(state.height_map)
	var r: int = target.get("row", 0)
	var c: int = target.get("col", 0)
	height_map[r - 1][c - 1] = clampi(Height.get_height(height_map, r, c) + 1, 0, 4)
	var updated := _consume_power(piece, "raise_tile")
	var dst := _copy_state(state)
	dst.height_map = height_map
	dst.pieces = _replace_piece(state.pieces, updated)
	return dst


func activate_lower_tile(state: GameState, piece: GameState.Piece, target: Dictionary) -> GameState:
	var height_map := _copy_height_map(state.height_map)
	var r: int = target.get("row", 0)
	var c: int = target.get("col", 0)
	height_map[r - 1][c - 1] = clampi(Height.get_height(height_map, r, c) - 1, 0, 4)
	var updated := _consume_power(piece, "lower_tile")
	var dst := _copy_state(state)
	dst.height_map = height_map
	dst.pieces = _replace_piece(state.pieces, updated)
	return dst


func activate_plateau(state: GameState, piece: GameState.Piece) -> GameState:
	var height_map := _copy_height_map(state.height_map)
	for dr in range(-1, 2):
		for dc in range(-1, 2):
			var r := piece.row + dr
			var c := piece.col + dc
			if r >= 1 and r <= state.rows and c >= 1 and c <= state.cols:
				height_map[r - 1][c - 1] = Height.MAX_HEIGHT
	var updated := _consume_power(piece, "plateau")
	var dst := _copy_state(state)
	dst.height_map = height_map
	dst.pieces = _replace_piece(state.pieces, updated)
	return dst


func activate_moat(state: GameState, piece: GameState.Piece) -> GameState:
	var height_map := _copy_height_map(state.height_map)
	# Raise center to max
	height_map[piece.row - 1][piece.col - 1] = Height.MAX_HEIGHT
	# Lower surrounding ring by 1
	for dr in range(-1, 2):
		for dc in range(-1, 2):
			if dr == 0 and dc == 0:
				continue
			var r := piece.row + dr
			var c := piece.col + dc
			if r >= 1 and r <= state.rows and c >= 1 and c <= state.cols:
				height_map[r - 1][c - 1] = clampi(Height.get_height(height_map, r, c) - 1, 0, 4)
	var updated := _consume_power(piece, "moat")
	var dst := _copy_state(state)
	dst.height_map = height_map
	dst.pieces = _replace_piece(state.pieces, updated)
	return dst


func activate_trench_row(state: GameState, piece: GameState.Piece) -> GameState:
	return _adjust_height_area(state, piece, "row", -2, "trench_row", true)


func activate_trench_column(state: GameState, piece: GameState.Piece) -> GameState:
	return _adjust_height_area(state, piece, "column", -2, "trench_column", true)


func activate_wall_row(state: GameState, piece: GameState.Piece) -> GameState:
	return _adjust_height_area(state, piece, "row", 2, "wall_row", true)


func activate_wall_column(state: GameState, piece: GameState.Piece) -> GameState:
	return _adjust_height_area(state, piece, "column", 2, "wall_column", true)


func activate_invert_radial(state: GameState, piece: GameState.Piece) -> GameState:
	return _invert_area(state, piece, "radial", "invert_radial")


func activate_invert_row(state: GameState, piece: GameState.Piece) -> GameState:
	return _invert_area(state, piece, "row", "invert_row")


func activate_invert_column(state: GameState, piece: GameState.Piece) -> GameState:
	return _invert_area(state, piece, "column", "invert_column")


func activate_dredge_radial(state: GameState, piece: GameState.Piece) -> GameState:
	return _dredge_area(state, piece, "radial", "dredge_radial")


func activate_dredge_row(state: GameState, piece: GameState.Piece) -> GameState:
	return _dredge_area(state, piece, "row", "dredge_row")


func activate_dredge_column(state: GameState, piece: GameState.Piece) -> GameState:
	return _dredge_area(state, piece, "column", "dredge_column")


# --- Strategic ---

func activate_recruit(state: GameState, piece: GameState.Piece, target: GameState.Piece) -> GameState:
	var pieces: Array = []
	for p: GameState.Piece in state.pieces:
		if p.id == target.id:
			var np := _clone_piece(p)
			np.player = piece.player
			pieces.append(np)
		else:
			pieces.append(p)
	var updated := _consume_power(piece, "recruit")
	var dst := _copy_state(state)
	dst.pieces = _replace_piece(pieces, updated)
	return dst


func activate_multiply(state: GameState, piece: GameState.Piece, target: Dictionary) -> GameState:
	var new_id := "%s-mul-%d" % [piece.id, state.turn]
	var new_piece := GameState.Piece.new(new_id, piece.player, int(target.get("row", 1)), int(target.get("col", 1)))
	new_piece.powers = []
	var multiplied_pieces: Array = (state.get_meta("multiplied_pieces", []) as Array).duplicate()
	multiplied_pieces.append(new_id)
	var updated := _consume_power(piece, "multiply")
	var dst := _copy_state(state)
	dst.pieces = _replace_piece(state.pieces, updated) + [new_piece]
	dst.set_meta("multiplied_pieces", multiplied_pieces)
	return dst


func activate_recruit_row(state: GameState, piece: GameState.Piece) -> GameState:
	return _recruit_area(state, piece, "row", "recruit_row")


func activate_recruit_column(state: GameState, piece: GameState.Piece) -> GameState:
	return _recruit_area(state, piece, "column", "recruit_column")


func activate_teach_radial(state: GameState, piece: GameState.Piece) -> GameState:
	return _teach_area(state, piece, "radial", "teach_radial")


func activate_teach_row(state: GameState, piece: GameState.Piece) -> GameState:
	return _teach_area(state, piece, "row", "teach_row")


func activate_teach_column(state: GameState, piece: GameState.Piece) -> GameState:
	return _teach_area(state, piece, "column", "teach_column")


func activate_learn_radial(state: GameState, piece: GameState.Piece) -> GameState:
	return _learn_area(state, piece, "radial", "learn_radial")


func activate_learn_row(state: GameState, piece: GameState.Piece) -> GameState:
	return _learn_area(state, piece, "row", "learn_row")


func activate_learn_column(state: GameState, piece: GameState.Piece) -> GameState:
	return _learn_area(state, piece, "column", "learn_column")


func activate_scavenger(state: GameState, piece: GameState.Piece) -> GameState:
	var updated := _consume_power(piece, "scavenger")
	updated.set_meta("is_scavenger", true)
	var dst := _copy_state(state)
	dst.pieces = _replace_piece(state.pieces, updated)
	return dst


# --- Utility ---

func activate_invisible(state: GameState, piece: GameState.Piece) -> GameState:
	var updated := _consume_power(piece, "invisible")
	updated.is_invisible = true
	var dst := _copy_state(state)
	dst.pieces = _replace_piece(state.pieces, updated)
	return dst


# --- Restoration ---

func activate_refurb(state: GameState, piece: GameState.Piece, target) -> GameState:
	if target == null:
		return _with_consumed_power(state, piece, "refurb")
	var key := "%d,%d" % [int(target.get("row", 0)), int(target.get("col", 0))]
	if not state.destroyed_tiles.has(key):
		return _with_consumed_power(state, piece, "refurb")
	var destroyed_tiles: Dictionary = state.destroyed_tiles.duplicate()
	destroyed_tiles.erase(key)
	var height_map := _copy_height_map(state.height_map)
	height_map[int(target.get("row", 1)) - 1][int(target.get("col", 1)) - 1] = 0
	var updated := _consume_power(piece, "refurb")
	var dst := _copy_state(state)
	dst.destroyed_tiles = destroyed_tiles
	dst.height_map = height_map
	dst.pieces = _replace_piece(state.pieces, updated)
	return dst


func activate_refurb_radial(state: GameState, piece: GameState.Piece) -> GameState:
	return _refurb_area(state, piece, "radial", "refurb_radial")


func activate_refurb_row(state: GameState, piece: GameState.Piece) -> GameState:
	return _refurb_area(state, piece, "row", "refurb_row")


func activate_refurb_column(state: GameState, piece: GameState.Piece) -> GameState:
	return _refurb_area(state, piece, "column", "refurb_column")


func activate_purify_radial(state: GameState, piece: GameState.Piece) -> GameState:
	return _purify_area(state, piece, "radial", "purify_radial")


func activate_purify_row(state: GameState, piece: GameState.Piece) -> GameState:
	return _purify_area(state, piece, "row", "purify_row")


func activate_purify_column(state: GameState, piece: GameState.Piece) -> GameState:
	return _purify_area(state, piece, "column", "purify_column")


# --- Chaos ---

func activate_scramble_radial(state: GameState, piece: GameState.Piece) -> GameState:
	return _scramble_radial(state, piece, "scramble_radial")


func activate_scramble_row(state: GameState, piece: GameState.Piece) -> GameState:
	return _scramble_row(state, piece, "scramble_row")


func activate_scramble_column(state: GameState, piece: GameState.Piece) -> GameState:
	return _scramble_column(state, piece, "scramble_column")


# --- Meta ---

func activate_double_powers(state: GameState, piece: GameState.Piece) -> GameState:
	var consumed := _consume_power(piece, "double_powers")
	var doubled: Array = []
	for pw in consumed.powers:
		doubled.append(pw)
	for pw in consumed.powers:
		doubled.append(pw)
	consumed.powers = doubled
	var dst := _copy_state(state)
	dst.pieces = _replace_piece(state.pieces, consumed)
	return dst


func activate_orbic_rehash(state: GameState, piece: GameState.Piece) -> GameState:
	var rng := RNG.new(state.seed + state.turn)
	if state.orbs.size() == 0:
		return _with_consumed_power(state, piece, "orbic_rehash")
	var power_ids: Array = []
	for o in state.orbs:
		power_ids.append(o.power_id)
	var open := _empty_tiles(state)
	# Fisher-Yates shuffle open tiles
	var shuffled := open.duplicate()
	for i in range(shuffled.size() - 1, 0, -1):
		var j := rng.int(0, i)
		var tmp = shuffled[i]
		shuffled[i] = shuffled[j]
		shuffled[j] = tmp
	var new_orbs: Array = []
	var count := mini(power_ids.size(), shuffled.size())
	for i in range(count):
		new_orbs.append({"row": shuffled[i].row, "col": shuffled[i].col, "power_id": power_ids[i]})
	var updated := _consume_power(piece, "orbic_rehash")
	var dst := _copy_state(state)
	dst.orbs = new_orbs
	dst.pieces = _replace_piece(state.pieces, updated)
	return dst


func activate_cancel_multiply(state: GameState, piece: GameState.Piece) -> GameState:
	var multiplied_set: Dictionary = {}
	for id in state.get_meta("multiplied_pieces", []):
		multiplied_set[id] = true
	var pieces: Array = []
	for p: GameState.Piece in state.pieces:
		if not multiplied_set.has(p.id):
			pieces.append(p)
	var updated := _consume_power(piece, "cancel_multiply")
	var dst := _copy_state(state)
	dst.pieces = _replace_piece(pieces, updated)
	dst.set_meta("multiplied_pieces", [])
	return dst


func activate_grow_quadradius(state: GameState, piece: GameState.Piece) -> GameState:
	var current: int = piece.get_meta("grow_quadradius_level", 0)
	var new_level := mini(3, current + 1)
	var updated := _consume_power(piece, "grow_quadradius")
	updated.set_meta("grow_quadradius_level", new_level)
	var dst := _copy_state(state)
	dst.pieces = _replace_piece(state.pieces, updated)
	return dst


func activate_beneficiary(state: GameState, piece: GameState.Piece) -> GameState:
	# Correct semantics (research/quadradius/game_details/powers.md):
	# All OTHER pieces on the activating player's side sacrifice their entire
	# power inventories to the activating piece.  Immediate, activation-time
	# transfer — no death trigger, no capture trigger.
	var caster_consumed := _consume_power(piece, "beneficiary")
	# Collect all donor powers (same player, not self)
	var gained: Array = []
	for p: GameState.Piece in state.pieces:
		if p.id != piece.id and p.player == piece.player:
			for pw in p.powers:
				gained.append(pw)
	# Build updated pieces: empty donors, fill caster
	var pieces: Array = []
	for p: GameState.Piece in state.pieces:
		if p.id == piece.id:
			var np := _clone_piece(caster_consumed)
			np.powers = caster_consumed.powers.duplicate()
			for pw in gained:
				np.powers.append(pw)
			pieces.append(np)
		elif p.player == piece.player:
			var np := _clone_piece(p)
			np.powers = []
			pieces.append(np)
		else:
			pieces.append(p)
	var dst := _copy_state(state)
	dst.pieces = pieces
	return dst


# --- Intelligence ---

func activate_spyware_radial(state: GameState, piece: GameState.Piece) -> GameState:
	return _flag_enemies_area(state, piece, "radial", "spyware_radial", "powers_revealed", true)


func activate_spyware_row(state: GameState, piece: GameState.Piece) -> GameState:
	return _flag_enemies_area(state, piece, "row", "spyware_row", "powers_revealed", true)


func activate_spyware_column(state: GameState, piece: GameState.Piece) -> GameState:
	return _flag_enemies_area(state, piece, "column", "spyware_column", "powers_revealed", true)


func activate_orb_spy_radial(state: GameState, piece: GameState.Piece) -> GameState:
	var L: int = piece.get_meta("grow_quadradius_level", 0)
	var dist: int = 1 + L
	var orbs: Array = []
	for o in state.orbs:
		if abs(o.row - piece.row) <= dist and abs(o.col - piece.col) <= dist:
			var no: Dictionary = o.duplicate()
			no["revealed"] = true
			orbs.append(no)
		else:
			orbs.append(o)
	var updated := _consume_power(piece, "orb_spy_radial")
	var dst := _copy_state(state)
	dst.orbs = orbs
	dst.pieces = _replace_piece(state.pieces, updated)
	return dst


func activate_orb_spy_row(state: GameState, piece: GameState.Piece) -> GameState:
	var orbs: Array = []
	for o in state.orbs:
		if o.row == piece.row:
			var no: Dictionary = o.duplicate()
			no["revealed"] = true
			orbs.append(no)
		else:
			orbs.append(o)
	var updated := _consume_power(piece, "orb_spy_row")
	var dst := _copy_state(state)
	dst.orbs = orbs
	dst.pieces = _replace_piece(state.pieces, updated)
	return dst


func activate_orb_spy_column(state: GameState, piece: GameState.Piece) -> GameState:
	var orbs: Array = []
	for o in state.orbs:
		if o.col == piece.col:
			var no: Dictionary = o.duplicate()
			no["revealed"] = true
			orbs.append(no)
		else:
			orbs.append(o)
	var updated := _consume_power(piece, "orb_spy_column")
	var dst := _copy_state(state)
	dst.orbs = orbs
	dst.pieces = _replace_piece(state.pieces, updated)
	return dst


# --- Trap ---

func activate_bankrupt_radial(state: GameState, piece: GameState.Piece) -> GameState:
	return _bankrupt_area(state, piece, "radial", "bankrupt_radial")


func activate_bankrupt_row(state: GameState, piece: GameState.Piece) -> GameState:
	return _bankrupt_area(state, piece, "row", "bankrupt_row")


func activate_bankrupt_column(state: GameState, piece: GameState.Piece) -> GameState:
	return _bankrupt_area(state, piece, "column", "bankrupt_column")


func activate_tripwire_radial(state: GameState, piece: GameState.Piece) -> GameState:
	return _flag_enemies_area(state, piece, "radial", "tripwire_radial", "is_tripwired", true)


func activate_tripwire_row(state: GameState, piece: GameState.Piece) -> GameState:
	return _flag_enemies_area(state, piece, "row", "tripwire_row", "is_tripwired", true)


func activate_tripwire_column(state: GameState, piece: GameState.Piece) -> GameState:
	return _flag_enemies_area(state, piece, "column", "tripwire_column", "is_tripwired", true)


# --- Control ---

func activate_inhibit_radial(state: GameState, piece: GameState.Piece) -> GameState:
	return _flag_enemies_area(state, piece, "radial", "inhibit_radial", "is_inhibited", true)


func activate_inhibit_row(state: GameState, piece: GameState.Piece) -> GameState:
	return _flag_enemies_area(state, piece, "row", "inhibit_row", "is_inhibited", true)


func activate_inhibit_column(state: GameState, piece: GameState.Piece) -> GameState:
	return _flag_enemies_area(state, piece, "column", "inhibit_column", "is_inhibited", true)


func activate_parasite_radial(state: GameState, piece: GameState.Piece) -> GameState:
	return _flag_enemies_area(state, piece, "radial", "parasite_radial", "parasitized_by", piece.id)


func activate_parasite_row(state: GameState, piece: GameState.Piece) -> GameState:
	return _flag_enemies_area(state, piece, "row", "parasite_row", "parasitized_by", piece.id)


func activate_parasite_column(state: GameState, piece: GameState.Piece) -> GameState:
	return _flag_enemies_area(state, piece, "column", "parasite_column", "parasitized_by", piece.id)
