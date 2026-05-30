## ai_test.gd — Tests for src/ai/ai.gd
## Run: godot/scripts/godot.sh --headless --path . -s res://tests/ai_test.gd
extends SceneTree

const Board = preload("res://src/board.gd")
const GameState = preload("res://src/game_state.gd")
const RNG = preload("res://src/rng.gd")
const AI = preload("res://src/ai/ai.gd")


func _assert(cond: bool, msg: String, fails: Array) -> void:
	if not cond:
		printerr("  FAIL: " + msg)
		fails[0] += 1


func _make_state(p1_pieces: Array, p2_pieces: Array, overrides: Dictionary = {}) -> GameState:
	var state := GameState.new()
	state.cols = Board.BOARD_COLS
	state.rows = Board.BOARD_ROWS
	state.current_player = overrides.get("current_player", 1)
	state.turn = overrides.get("turn", 0)
	state.status = overrides.get("status", "playing")
	state.winner = overrides.get("winner", 0)
	state.seed = overrides.get("seed", 1)
	state.destroyed_tiles = overrides.get("destroyed_tiles", {})
	state.orbs = overrides.get("orbs", [])

	state.height_map = []
	for _r in range(Board.BOARD_ROWS):
		var row_arr: Array = []
		row_arr.resize(Board.BOARD_COLS)
		row_arr.fill(0)
		state.height_map.append(row_arr)

	state.pieces = []
	for i in range(p1_pieces.size()):
		var pp: Dictionary = p1_pieces[i]
		var piece := GameState.Piece.new("p1-%d" % i, 1, pp.row, pp.col)
		if pp.has("powers"):
			piece.powers = pp.powers.duplicate()
		state.pieces.append(piece)

	for i in range(p2_pieces.size()):
		var pp: Dictionary = p2_pieces[i]
		var piece := GameState.Piece.new("p2-%d" % i, 2, pp.row, pp.col)
		if pp.has("powers"):
			piece.powers = pp.powers.duplicate()
		state.pieces.append(piece)

	return state


func _init() -> void:
	var fails := [0]

	# ---------------------------------------------------------------------------
	# easy: uniform random, deterministic under same seed, legal move
	# ---------------------------------------------------------------------------

	var state = Board.create_initial_state(42)

	# Returns a legal move
	var d1 = AI.choose_move(state, 1, "easy", RNG.new(42))
	_assert(d1 != null, "easy: not null from initial state", fails)
	if d1 != null:
		_assert(d1.piece.player == 1, "easy: piece belongs to player 1", fails)
		var legal = Board.get_valid_moves(state, d1.piece)
		var found := false
		for m in legal:
			if m.row == d1.move.row and m.col == d1.move.col:
				found = true
				break
		_assert(found, "easy: move is in legal moves list", fails)

	# Deterministic under same seed
	var d1a = AI.choose_move(state, 1, "easy", RNG.new(7))
	var d1b = AI.choose_move(state, 1, "easy", RNG.new(7))
	_assert(d1a != null and d1b != null, "easy: both seeded calls non-null", fails)
	if d1a != null and d1b != null:
		_assert(d1a.piece.id == d1b.piece.id,
			"easy: deterministic piece id under same seed", fails)
		_assert(d1a.move.row == d1b.move.row and d1a.move.col == d1b.move.col,
			"easy: deterministic move under same seed", fails)

	# Returns null when player has no pieces
	var no_pieces = _make_state([], [{"row": 4, "col": 5}])
	_assert(AI.choose_move(no_pieces, 1, "easy", RNG.new(1)) == null,
		"easy: null when player has no pieces", fails)

	# ---------------------------------------------------------------------------
	# medium: takes an immediate capture
	# ---------------------------------------------------------------------------

	var cap_state = _make_state([{"row": 4, "col": 4}], [{"row": 4, "col": 5}])
	var d_med = AI.choose_move(cap_state, 1, "medium", RNG.new(1))
	_assert(d_med != null, "medium: not null with capture available", fails)
	if d_med != null:
		_assert(d_med.move.capture == true,
			"medium: takes capture (move.capture=true)", fails)
		_assert(d_med.move.row == 4 and d_med.move.col == 5,
			"medium: capture target is (4,5)", fails)

	# Returns a legal move from the full initial board
	var d_med2 = AI.choose_move(state, 1, "medium", RNG.new(1))
	_assert(d_med2 != null, "medium: legal move from initial board", fails)
	if d_med2 != null:
		var legal2 = Board.get_valid_moves(state, d_med2.piece)
		var found2 := false
		for m in legal2:
			if m.row == d_med2.move.row and m.col == d_med2.move.col:
				found2 = true
				break
		_assert(found2, "medium: returned move is in legal list", fails)

	# Returns null when player has no pieces
	_assert(AI.choose_move(no_pieces, 1, "medium", RNG.new(1)) == null,
		"medium: null when no pieces", fails)

	# ---------------------------------------------------------------------------
	# hard (depth 2): captures the lone enemy piece
	# ---------------------------------------------------------------------------

	var d_hard = AI.choose_move(cap_state, 1, "hard", RNG.new(1))
	_assert(d_hard != null, "hard: not null with capture available", fails)
	if d_hard != null:
		_assert(d_hard.move.capture == true, "hard: takes capture", fails)

	# Returns legal move from initial board
	var d_hard2 = AI.choose_move(state, 1, "hard", RNG.new(1))
	_assert(d_hard2 != null, "hard: not null from initial board", fails)
	if d_hard2 != null:
		var legal3 = Board.get_valid_moves(state, d_hard2.piece)
		var found3 := false
		for m in legal3:
			if m.row == d_hard2.move.row and m.col == d_hard2.move.col:
				found3 = true
				break
		_assert(found3, "hard: move is legal", fails)

	# Returns null when no pieces
	_assert(AI.choose_move(no_pieces, 1, "hard", RNG.new(1)) == null,
		"hard: null when no pieces", fails)

	# ---------------------------------------------------------------------------
	# expert (depth 4): captures the lone enemy piece
	# ---------------------------------------------------------------------------

	var d_exp = AI.choose_move(cap_state, 1, "expert", RNG.new(1))
	_assert(d_exp != null, "expert: not null with capture available", fails)
	if d_exp != null:
		_assert(d_exp.move.capture == true, "expert: takes capture", fails)

	# Returns null when no pieces
	_assert(AI.choose_move(no_pieces, 1, "expert", RNG.new(1)) == null,
		"expert: null when no pieces", fails)

	# ---------------------------------------------------------------------------
	# Print result
	# ---------------------------------------------------------------------------
	if fails[0] == 0:
		print("OK ai")
	else:
		printerr("FAIL ai: %d" % fails[0])

	quit(fails[0])
