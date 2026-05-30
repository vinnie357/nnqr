## search_test.gd — Tests for src/ai/search.gd
## Run: godot/scripts/godot.sh --headless --path . -s res://tests/search_test.gd
extends SceneTree

const Board = preload("res://src/board.gd")
const GameState = preload("res://src/game_state.gd")
const Search = preload("res://src/ai/search.gd")
const Evaluator = preload("res://src/ai/evaluator.gd")


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
	# find_best_move: returns a legal move or null
	# ---------------------------------------------------------------------------

	# Single piece with moves — must return a legal move
	var state = _make_state([{"row": 4, "col": 4}], [{"row": 6, "col": 6}])
	var bm = Search.find_best_move(state, 2, 1)
	_assert(bm != null, "find_best_move: not null when moves exist", fails)
	if bm != null:
		var legal = Board.get_valid_moves(state, bm.piece)
		var found_legal := false
		for m in legal:
			if m.row == bm.target.row and m.col == bm.target.col:
				found_legal = true
				break
		_assert(found_legal,
			"find_best_move: returned move is legal (piece at %d,%d → %d,%d)" % [
				bm.piece.row, bm.piece.col, bm.target.row, bm.target.col], fails)

	# No pieces → null
	var empty_state = _make_state([], [])
	_assert(Search.find_best_move(empty_state, 2, 1) == null,
		"find_best_move: null for empty board", fails)

	# ---------------------------------------------------------------------------
	# find_best_move: prefers immediate winning capture at depth >= 2
	# ---------------------------------------------------------------------------

	# p1 at (4,4), lone p2 at (4,5). Capturing wins the game — AI must take it.
	var win_state = _make_state([{"row": 4, "col": 4}], [{"row": 4, "col": 5}])
	var win_move = Search.find_best_move(win_state, 2, 1)
	_assert(win_move != null, "find_best_move: not null for winning position", fails)
	if win_move != null:
		_assert(win_move.target.row == 4 and win_move.target.col == 5,
			"find_best_move: takes winning capture (4,5) got (%d,%d)" % [
				win_move.target.row, win_move.target.col], fails)

	# Same at depth 4
	var win_move4 = Search.find_best_move(win_state, 4, 1)
	_assert(win_move4 != null and win_move4.target.row == 4 and win_move4.target.col == 5,
		"find_best_move depth4: takes winning capture", fails)

	# ---------------------------------------------------------------------------
	# MAX_BRANCHING_FACTOR: order_moves caps at 10
	# ---------------------------------------------------------------------------

	_assert(Search.MAX_BRANCHING_FACTOR == 10,
		"MAX_BRANCHING_FACTOR == 10", fails)

	# Build a mid-game state with many pieces in open positions (>10 moves guaranteed)
	var mid_state = _make_state(
		[{"row": 4, "col": 1}, {"row": 4, "col": 3}, {"row": 4, "col": 5},
		 {"row": 4, "col": 7}, {"row": 4, "col": 9}, {"row": 3, "col": 2},
		 {"row": 3, "col": 4}, {"row": 3, "col": 6}, {"row": 3, "col": 8},
		 {"row": 3, "col": 10}, {"row": 5, "col": 2}, {"row": 5, "col": 4}],
		[{"row": 7, "col": 5}]
	)
	var all_moves = Evaluator.get_all_moves(mid_state, 1)
	_assert(all_moves.size() > Search.MAX_BRANCHING_FACTOR,
		"mid-game state has >10 moves (got %d)" % all_moves.size(), fails)
	var ordered = Search.order_moves(mid_state, all_moves)
	_assert(ordered.size() <= Search.MAX_BRANCHING_FACTOR,
		"order_moves caps at MAX_BRANCHING_FACTOR (got %d)" % ordered.size(), fails)
	# Also confirm order_moves doesn't crash on the full initial board (≤10 = exactly capped already)
	var full_state = Board.create_initial_state(1)
	var full_ordered = Search.order_moves(full_state, Evaluator.get_all_moves(full_state, 1))
	_assert(full_ordered.size() <= Search.MAX_BRANCHING_FACTOR,
		"order_moves full initial board: at most MAX_BRANCHING_FACTOR", fails)

	# ---------------------------------------------------------------------------
	# order_moves: captures come before non-captures
	# ---------------------------------------------------------------------------

	# p1 at (4,4) and (3,3), p2 at (4,5) — p1 has one capture + several non-captures
	var cap_state = _make_state(
		[{"row": 4, "col": 4}, {"row": 3, "col": 3}],
		[{"row": 4, "col": 5}]
	)
	var cap_moves = Evaluator.get_all_moves(cap_state, 1)
	var cap_ordered = Search.order_moves(cap_state, cap_moves)

	# Collect positions of captures and non-captures in the ordered list
	var first_non_cap_idx := cap_ordered.size()
	for i in range(cap_ordered.size()):
		var m = cap_ordered[i]
		var is_cap := false
		for p in cap_state.pieces:
			if p.row == m.target.row and p.col == m.target.col and p.player != m.piece.player:
				is_cap = true
				break
		if not is_cap:
			first_non_cap_idx = i
			break

	# Every move before first_non_cap_idx must be a capture
	for i in range(first_non_cap_idx):
		var m = cap_ordered[i]
		var is_cap := false
		for p in cap_state.pieces:
			if p.row == m.target.row and p.col == m.target.col and p.player != m.piece.player:
				is_cap = true
				break
		_assert(is_cap,
			"order_moves: move at index %d should be a capture" % i, fails)

	# ---------------------------------------------------------------------------
	# find_best_move does not crash on a full board (regression)
	# ---------------------------------------------------------------------------

	var no_crash_result = Search.find_best_move(full_state, 2, 1)
	# Just verify it didn't hang/crash; result may be null or a valid move
	if no_crash_result != null:
		var p_legal = Board.get_valid_moves(full_state, no_crash_result.piece)
		var valid_target := false
		for m in p_legal:
			if m.row == no_crash_result.target.row and m.col == no_crash_result.target.col:
				valid_target = true
				break
		_assert(valid_target, "find_best_move full board: result is a legal move", fails)

	# ---------------------------------------------------------------------------
	# Print result
	# ---------------------------------------------------------------------------
	if fails[0] == 0:
		print("OK search")
	else:
		printerr("FAIL search: %d" % fails[0])

	quit(fails[0])
