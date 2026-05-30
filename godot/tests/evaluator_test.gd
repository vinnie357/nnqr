## evaluator_test.gd — Tests for src/ai/evaluator.gd
## Run: godot/scripts/godot.sh --headless --path . -s res://tests/evaluator_test.gd
extends SceneTree

const Board = preload("res://src/board.gd")
const GameState = preload("res://src/game_state.gd")
const Evaluator = preload("res://src/ai/evaluator.gd")


func _assert(cond: bool, msg: String, fails: Array) -> void:
	if not cond:
		printerr("  FAIL: " + msg)
		fails[0] += 1


## Build a minimal state with the given pieces (player 1 and player 2 lists).
## Each item: {"row": int, "col": int} — optionally {"powers": [], flags...}
func _make_state(
		p1_pieces: Array,
		p2_pieces: Array,
		overrides: Dictionary = {}
) -> GameState:
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

	# flat zero height_map
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
		if pp.has("is_jump_proof"):
			piece.is_jump_proof = pp.is_jump_proof
		if pp.has("can_move_diagonally"):
			piece.can_move_diagonally = pp.can_move_diagonally
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
	# get_all_moves: returns one entry per piece × legal move
	# ---------------------------------------------------------------------------

	# Single piece in center — orthogonal moves only → exactly 4 moves
	var state = _make_state([{"row": 4, "col": 5}], [])
	var all_moves = Evaluator.get_all_moves(state, 1)
	_assert(all_moves.size() == 4,
		"get_all_moves: center piece has 4 orthogonal moves, got %d" % all_moves.size(), fails)

	# Each move dict must have piece and target keys
	for m in all_moves:
		_assert(m.has("piece"), "get_all_moves: move has 'piece' key", fails)
		_assert(m.has("target"), "get_all_moves: move has 'target' key", fails)
		_assert(m.target.has("row") and m.target.has("col"),
			"get_all_moves: target has row/col", fails)

	# No moves when player has no pieces
	var empty_state = _make_state([], [{"row": 4, "col": 5}])
	_assert(Evaluator.get_all_moves(empty_state, 1).size() == 0,
		"get_all_moves: 0 moves when no pieces", fails)

	# Corner piece (1,1) has exactly 2 valid orthogonal moves
	var corner_state = _make_state([{"row": 1, "col": 1}], [])
	_assert(Evaluator.get_all_moves(corner_state, 1).size() == 2,
		"get_all_moves: corner piece has 2 moves", fails)

	# Both players in a known state: get_all_moves for p1 only includes p1 pieces
	var dual_state = _make_state(
		[{"row": 4, "col": 4}],
		[{"row": 6, "col": 6}]
	)
	var p1_moves = Evaluator.get_all_moves(dual_state, 1)
	for m in p1_moves:
		_assert(m.piece.player == 1, "get_all_moves: all moves are for player 1", fails)

	# ---------------------------------------------------------------------------
	# score_move: prefers captures over plain movement
	# ---------------------------------------------------------------------------

	# p1 at (4,4), p2 at (4,5): capture move should score higher than sideways
	var cap_state = _make_state(
		[{"row": 4, "col": 4}],
		[{"row": 4, "col": 5}]
	)
	# Build an AiMove dict for the capture (toward p2)
	var capture_move = {"piece": cap_state.pieces[0], "target": {"row": 4, "col": 5}}
	# Build an AiMove dict for a non-capture (away from p2)
	var noncap_move = {"piece": cap_state.pieces[0], "target": {"row": 4, "col": 3}}
	var cap_score = Evaluator.score_move(cap_state, capture_move)
	var noncap_score = Evaluator.score_move(cap_state, noncap_move)
	_assert(cap_score > noncap_score,
		"score_move: capture > non-capture (cap=%.1f, noncap=%.1f)" % [cap_score, noncap_score],
		fails)

	# ---------------------------------------------------------------------------
	# evaluate_board: favors material advantage
	# ---------------------------------------------------------------------------

	# p1 has one piece, p2 has none → big positive value
	var win_state = _make_state([{"row": 4, "col": 5}], [])
	var win_score = Evaluator.evaluate_board(win_state, 1)
	_assert(win_score > 0, "evaluate_board: +score when p1 has piece, p2 none (got %.1f)" % win_score, fails)

	# p1 has no pieces, p2 has one → big negative value
	var lose_state = _make_state([], [{"row": 4, "col": 5}])
	var lose_score = Evaluator.evaluate_board(lose_state, 1)
	_assert(lose_score < 0, "evaluate_board: -score when p2 has piece, p1 none (got %.1f)" % lose_score, fails)

	# Empty board → 0
	var empty2 = _make_state([], [])
	_assert(Evaluator.evaluate_board(empty2, 1) == 0,
		"evaluate_board: 0 for empty board", fails)

	# p1 has more pieces → positive score
	var adv_state = _make_state(
		[{"row": 4, "col": 4}, {"row": 4, "col": 6}],
		[{"row": 5, "col": 5}]
	)
	_assert(Evaluator.evaluate_board(adv_state, 1) > 0,
		"evaluate_board: positive when p1 outnumbers p2", fails)

	# ---------------------------------------------------------------------------
	# get_best_move: returns null when no pieces, otherwise a valid move
	# ---------------------------------------------------------------------------

	_assert(Evaluator.get_best_move(empty2, 1) == null,
		"get_best_move: null for empty board", fails)

	var bm = Evaluator.get_best_move(
		_make_state([{"row": 4, "col": 4}], []),
		1
	)
	_assert(bm != null, "get_best_move: not null when legal moves exist", fails)

	# get_best_move prefers capture when available
	var bm_cap = Evaluator.get_best_move(cap_state, 1)
	_assert(bm_cap != null, "get_best_move: not null with capture available", fails)
	_assert(bm_cap.target.row == 4 and bm_cap.target.col == 5,
		"get_best_move: picks capture target (4,5)", fails)

	# ---------------------------------------------------------------------------
	# score_power_activation: stub returns -INF for any input (seam preserved)
	# ---------------------------------------------------------------------------

	var seam_state = _make_state([{"row": 4, "col": 5}], [])
	var seam_piece = seam_state.pieces[0]
	var seam_score = Evaluator.score_power_activation(seam_state, seam_piece, "bomb")
	_assert(seam_score == -INF,
		"score_power_activation: stub returns -INF (got %s)" % seam_score, fails)

	# ---------------------------------------------------------------------------
	# Print result
	# ---------------------------------------------------------------------------
	if fails[0] == 0:
		print("OK evaluator")
	else:
		printerr("FAIL evaluator: %d" % fails[0])

	quit(fails[0])
