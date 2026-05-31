## GameState — data model for NNQR board state.
## Mirrors web/src/core/types.ts and board.ts.
## 10 cols × 8 rows; player 1 starts rows 1-2, player 2 starts rows 7-8.
##
## C2 extension: added height_map, destroyed_tiles, orbs, selected,
## valid_moves, seed fields and extended Piece with powers + flag booleans.
## Existing init_board() / load_dict() / to_dict() signatures are preserved.
##
## Usage:
##   const GameState = preload("res://src/game_state.gd")
##   var state = GameState.new()
##   state.init_board()          # initial 20+20 layout
##   state.load_dict(dict)       # load from JSON dict
##   var d = state.to_dict()     # serialise to plain Dictionary
extends RefCounted

const BOARD_COLS: int = 10
const BOARD_ROWS: int = 8

## Inner class representing a single piece on the board.
class Piece extends RefCounted:
	var id: String
	var player: int      ## 1 or 2
	var row: int         ## 1-indexed
	var col: int         ## 1-indexed

	## Power orb inventory (Array of String power_ids; may hold duplicates).
	var powers: Array = []

	## Permanent-power flags (set by activating specific powers).
	var is_jump_proof: bool = false
	var can_move_diagonally: bool = false
	var can_climb_any: bool = false
	var can_wrap: bool = false
	var is_invisible: bool = false

	func _init(p_id: String, p_player: int, p_row: int, p_col: int) -> void:
		id = p_id
		player = p_player
		row = p_row
		col = p_col

	func to_dict() -> Dictionary:
		var d: Dictionary = {
			"id": id,
			"player": player,
			"row": row,
			"col": col,
			"powers": powers.duplicate(),
			"is_jump_proof": is_jump_proof,
			"can_move_diagonally": can_move_diagonally,
			"can_climb_any": can_climb_any,
			"can_wrap": can_wrap,
			"is_invisible": is_invisible,
		}
		# nnqr-43: persist dynamic meta flags into the serialised dict so
		# state.json captures them (useful for QA assertions and round-trips).
		if has_meta("powers_revealed"):
			d["powers_revealed"] = get_meta("powers_revealed")
		return d


# ---------------------------------------------------------------------------
# Board dimensions (unchanged from skeleton).
# ---------------------------------------------------------------------------
var cols: int = BOARD_COLS
var rows: int = BOARD_ROWS

## All pieces still in play (Array of Piece).
var pieces: Array = []

## Whose turn it is: 1 or 2.
var current_player: int = 1

## Turn counter (starts at 0).
var turn: int = 0

## "playing" or "won".
var status: String = "playing"

## Winning player (1 or 2) or 0 when still playing.
var winner: int = 0

# ---------------------------------------------------------------------------
# New fields added by C2.
# ---------------------------------------------------------------------------

## Terrain height per tile. Array of Array[int]; height_map[row-1][col-1]; range 0..4.
var height_map: Array = []

## Destroyed (impassable) tiles, keyed "row,col" -> true.
var destroyed_tiles: Dictionary = {}

## Power orbs on the board. Array of {"row":int, "col":int, "power_id":String}.
var orbs: Array = []

## Currently selected tile as {"row":int,"col":int}, or null.
var selected = null  # Dictionary or null

## Valid moves for the selected piece. Array of {"row":int,"col":int,"capture":bool}.
var valid_moves: Array = []

## Seed for deterministic RNG (orb spawning, AI tie-breaks).
var seed: int = 0


# ---------------------------------------------------------------------------
# Initialisation
# ---------------------------------------------------------------------------

## Populate state with the standard initial board:
## 20 pieces per player; player 1 on rows 1-2, player 2 on rows 7-8.
## Also initialises the new fields to their zero/empty defaults.
func init_board() -> void:
	pieces.clear()
	for row: int in [1, 2]:
		for col: int in range(1, BOARD_COLS + 1):
			pieces.append(Piece.new("p1-%d-%d" % [row, col], 1, row, col))
	for row: int in [BOARD_ROWS - 1, BOARD_ROWS]:
		for col: int in range(1, BOARD_COLS + 1):
			pieces.append(Piece.new("p2-%d-%d" % [row, col], 2, row, col))

	# Initialise height_map to all-zero.
	height_map = []
	for _r in range(BOARD_ROWS):
		var row_arr: Array = []
		row_arr.resize(BOARD_COLS)
		row_arr.fill(0)
		height_map.append(row_arr)

	destroyed_tiles = {}
	orbs = []
	selected = null
	valid_moves = []


# ---------------------------------------------------------------------------
# Deserialisation (load_dict)
# ---------------------------------------------------------------------------

## Populate state from a Dictionary (loaded from JSON scenario file).
## Existing keys: pieces (array), current_player (int), turn (int),
##                status (str), winner (int).
## New keys (all optional; defaults apply when absent for backward compat):
##   height_map, destroyed_tiles, orbs, selected, valid_moves, seed.
func load_dict(d: Dictionary) -> void:
	current_player = int(d.get("current_player", 1))
	turn = int(d.get("turn", 0))
	status = str(d.get("status", "playing"))
	winner = int(d.get("winner", 0))
	seed = int(d.get("seed", 0))

	# Pieces — deserialise including new flags.
	pieces.clear()
	var raw_pieces: Array = d.get("pieces", [])
	for rp: Dictionary in raw_pieces:
		var piece := Piece.new(
			str(rp.get("id", "")),
			int(rp.get("player", 1)),
			int(rp.get("row", 1)),
			int(rp.get("col", 1))
		)
		var raw_powers = rp.get("powers", [])
		piece.powers = Array(raw_powers)
		piece.is_jump_proof = bool(rp.get("is_jump_proof", false))
		piece.can_move_diagonally = bool(rp.get("can_move_diagonally", false))
		piece.can_climb_any = bool(rp.get("can_climb_any", false))
		piece.can_wrap = bool(rp.get("can_wrap", false))
		piece.is_invisible = bool(rp.get("is_invisible", false))
		# nnqr-43: dynamic flags stored as object meta (set by effects.gd at runtime,
		# also loadable from scenario JSON for see-harness visual QA).
		if rp.get("powers_revealed", false):
			piece.set_meta("powers_revealed", true)
		pieces.append(piece)

	# height_map — default to empty array (caller may rebuild it).
	if d.has("height_map"):
		height_map = []
		var raw_hm: Array = d["height_map"]
		for raw_row in raw_hm:
			var row_arr: Array = []
			for v in raw_row:
				row_arr.append(int(v))
			height_map.append(row_arr)
	else:
		height_map = []

	# destroyed_tiles
	if d.has("destroyed_tiles"):
		destroyed_tiles = {}
		var raw_dt: Dictionary = d["destroyed_tiles"]
		for k in raw_dt.keys():
			destroyed_tiles[str(k)] = true
	else:
		destroyed_tiles = {}

	# orbs
	if d.has("orbs"):
		orbs = []
		for raw_orb in d["orbs"]:
			orbs.append({
				"row": int(raw_orb.get("row", 0)),
				"col": int(raw_orb.get("col", 0)),
				"power_id": str(raw_orb.get("power_id", "")),
			})
	else:
		orbs = []

	# selected
	if d.has("selected") and d["selected"] != null:
		var sel = d["selected"]
		selected = {"row": int(sel.get("row", 0)), "col": int(sel.get("col", 0))}
	else:
		selected = null

	# valid_moves
	if d.has("valid_moves"):
		valid_moves = []
		for raw_mv in d["valid_moves"]:
			valid_moves.append({
				"row": int(raw_mv.get("row", 0)),
				"col": int(raw_mv.get("col", 0)),
				"capture": bool(raw_mv.get("capture", false)),
			})
	else:
		valid_moves = []


# ---------------------------------------------------------------------------
# Serialisation (to_dict)
# ---------------------------------------------------------------------------

## Serialise to a plain Dictionary (for JSON output).
## Emits all existing fields plus the new C2 fields.
func to_dict() -> Dictionary:
	var piece_list: Array = []
	for p: Piece in pieces:
		piece_list.append(p.to_dict())

	# height_map: convert inner Arrays to plain Arrays for JSON safety.
	var hm_out: Array = []
	for row_arr in height_map:
		hm_out.append(row_arr.duplicate())

	# orbs
	var orbs_out: Array = []
	for o in orbs:
		orbs_out.append({"row": o.row, "col": o.col, "power_id": o.power_id})

	# valid_moves
	var moves_out: Array = []
	for m in valid_moves:
		moves_out.append({"row": m.row, "col": m.col, "capture": m.capture})

	return {
		"cols": cols,
		"rows": rows,
		"current_player": current_player,
		"turn": turn,
		"status": status,
		"winner": winner,
		"pieces": piece_list,
		"height_map": hm_out,
		"destroyed_tiles": destroyed_tiles.duplicate(),
		"orbs": orbs_out,
		"selected": selected,
		"valid_moves": moves_out,
		"seed": seed,
	}
