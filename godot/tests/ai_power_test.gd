## ai_power_test.gd — TDD tests for nnqr-20: AI power activation.
##
## AC tested:
##  1. score_power_activation: destroy_row/column returns positive when ≥2 enemies in line.
##  2. score_power_activation: jump_proof returns positive ONLY when the piece is threatened.
##  3. score_power_activation: bomb/destroy_radial returns positive when ≥2 enemies in 3x3.
##  4. score_power_activation: single-use power with no worthwhile target → -INF.
##  5. choose_move (medium/hard/expert): prefers power activation over movement when gain is high.
##  6. choose_move returns a power_action when AI has destroy_row and ≥2 enemies in its row.
##  7. Expert search completes (does not blow the budget) when power candidates are included.
##
## Run: godot/scripts/godot.sh --headless --path . -s res://tests/ai_power_test.gd
extends SceneTree

const Board = preload("res://src/board.gd")
const GameState = preload("res://src/game_state.gd")
const Evaluator = preload("res://src/ai/evaluator.gd")
const AI = preload("res://src/ai/ai.gd")
const RNG = preload("res://src/rng.gd")


func _assert(cond: bool, msg: String, fails: Array) -> void:
	if not cond:
		printerr("  FAIL: " + msg)
		fails[0] += 1


## Build a minimal GameState with the given pieces.
## p1_pieces / p2_pieces: Array of {row, col} or {row, col, powers: [...]}.
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
	# AC 1: score_power_activation — destroy_row
	# Piece has destroy_row; ≥2 enemies in same row → positive score.
	# Piece has destroy_row; only 1 enemy in row → -INF (not worth wasting).
	# Piece has destroy_row; 0 enemies in row → -INF.
	# Piece lacks destroy_row → -INF regardless.
	# ---------------------------------------------------------------------------

	# 2 enemies in row → positive
	var dr_state = _make_state(
		[{"row": 4, "col": 1, "powers": ["destroy_row"]}],
		[{"row": 4, "col": 7}, {"row": 4, "col": 8}]
	)
	var dr_piece = dr_state.pieces[0]
	var dr_score = Evaluator.score_power_activation(dr_state, dr_piece, "destroy_row")
	_assert(dr_score > 0.0,
		"destroy_row: >=2 enemies in row → positive (got %.2f)" % dr_score, fails)

	# Only 1 enemy in row → -INF (wasteful)
	var dr_one_state = _make_state(
		[{"row": 4, "col": 1, "powers": ["destroy_row"]}],
		[{"row": 4, "col": 7}]
	)
	var dr_one_piece = dr_one_state.pieces[0]
	var dr_one_score = Evaluator.score_power_activation(dr_one_state, dr_one_piece, "destroy_row")
	_assert(dr_one_score == -INF,
		"destroy_row: only 1 enemy in row → -INF (got %.2f)" % dr_one_score, fails)

	# 0 enemies in row → -INF
	var dr_zero_state = _make_state(
		[{"row": 4, "col": 1, "powers": ["destroy_row"]}],
		[{"row": 5, "col": 7}]
	)
	var dr_zero_piece = dr_zero_state.pieces[0]
	var dr_zero_score = Evaluator.score_power_activation(dr_zero_state, dr_zero_piece, "destroy_row")
	_assert(dr_zero_score == -INF,
		"destroy_row: 0 enemies in row → -INF (got %.2f)" % dr_zero_score, fails)

	# Piece does not have destroy_row → -INF
	var dr_no_state = _make_state(
		[{"row": 4, "col": 1, "powers": []}],
		[{"row": 4, "col": 7}, {"row": 4, "col": 8}]
	)
	var dr_no_piece = dr_no_state.pieces[0]
	var dr_no_score = Evaluator.score_power_activation(dr_no_state, dr_no_piece, "destroy_row")
	_assert(dr_no_score == -INF,
		"destroy_row: piece lacks power → -INF (got %.2f)" % dr_no_score, fails)

	# Ally in same row should not trigger destroy_row (no pure enemy kill)
	var dr_ally_state = _make_state(
		[{"row": 4, "col": 1, "powers": ["destroy_row"]},
		 {"row": 4, "col": 3}],
		[{"row": 4, "col": 7}, {"row": 4, "col": 8}]
	)
	var dr_ally_piece = dr_ally_state.pieces[0]
	var dr_ally_score = Evaluator.score_power_activation(dr_ally_state, dr_ally_piece, "destroy_row")
	_assert(dr_ally_score == -INF,
		"destroy_row: ally in row → -INF (friendly fire) (got %.2f)" % dr_ally_score, fails)

	# ---------------------------------------------------------------------------
	# AC 2: score_power_activation — destroy_column (same pattern as row)
	# ---------------------------------------------------------------------------

	# 2 enemies in same column → positive
	var dc_state = _make_state(
		[{"row": 1, "col": 5, "powers": ["destroy_column"]}],
		[{"row": 4, "col": 5}, {"row": 7, "col": 5}]
	)
	var dc_piece = dc_state.pieces[0]
	var dc_score = Evaluator.score_power_activation(dc_state, dc_piece, "destroy_column")
	_assert(dc_score > 0.0,
		"destroy_column: >=2 enemies in col → positive (got %.2f)" % dc_score, fails)

	# 1 enemy in column → -INF
	var dc_one_state = _make_state(
		[{"row": 1, "col": 5, "powers": ["destroy_column"]}],
		[{"row": 4, "col": 5}]
	)
	var dc_one_piece = dc_one_state.pieces[0]
	var dc_one_score = Evaluator.score_power_activation(dc_one_state, dc_one_piece, "destroy_column")
	_assert(dc_one_score == -INF,
		"destroy_column: only 1 enemy in col → -INF (got %.2f)" % dc_one_score, fails)

	# ---------------------------------------------------------------------------
	# AC 3: score_power_activation — bomb / destroy_radial (3x3 area)
	# ≥2 enemies in 3x3, no allies → positive.
	# 1 enemy → -INF; 0 enemies → -INF.
	# ---------------------------------------------------------------------------

	# 2 adjacent enemies, no allies in 3x3 → positive
	var bomb_state = _make_state(
		[{"row": 4, "col": 5, "powers": ["bomb"]}],
		[{"row": 4, "col": 6}, {"row": 5, "col": 5}]
	)
	var bomb_piece = bomb_state.pieces[0]
	var bomb_score = Evaluator.score_power_activation(bomb_state, bomb_piece, "bomb")
	_assert(bomb_score > 0.0,
		"bomb: >=2 enemies in 3x3 → positive (got %.2f)" % bomb_score, fails)

	# 1 enemy in 3x3 → -INF (can just capture instead)
	var bomb_one_state = _make_state(
		[{"row": 4, "col": 5, "powers": ["bomb"]}],
		[{"row": 4, "col": 6}]
	)
	var bomb_one_piece = bomb_one_state.pieces[0]
	var bomb_one_score = Evaluator.score_power_activation(bomb_one_state, bomb_one_piece, "bomb")
	_assert(bomb_one_score == -INF,
		"bomb: only 1 enemy in 3x3 → -INF (got %.2f)" % bomb_one_score, fails)

	# Ally would be destroyed by bomb → -INF (friendly fire)
	var bomb_ally_state = _make_state(
		[{"row": 4, "col": 5, "powers": ["bomb"]},
		 {"row": 4, "col": 6}],
		[{"row": 4, "col": 7}, {"row": 5, "col": 5}]
	)
	var bomb_ally_piece = bomb_ally_state.pieces[0]
	var bomb_ally_score = Evaluator.score_power_activation(bomb_ally_state, bomb_ally_piece, "bomb")
	_assert(bomb_ally_score == -INF,
		"bomb: ally in 3x3 → -INF (friendly fire) (got %.2f)" % bomb_ally_score, fails)

	# destroy_radial same rule
	var drad_state = _make_state(
		[{"row": 4, "col": 5, "powers": ["destroy_radial"]}],
		[{"row": 4, "col": 6}, {"row": 5, "col": 5}]
	)
	var drad_piece = drad_state.pieces[0]
	var drad_score = Evaluator.score_power_activation(drad_state, drad_piece, "destroy_radial")
	_assert(drad_score > 0.0,
		"destroy_radial: >=2 enemies in 3x3 → positive (got %.2f)" % drad_score, fails)

	# ---------------------------------------------------------------------------
	# AC 4: score_power_activation — jump_proof
	# Returns positive ONLY when the piece is threatened; -INF otherwise.
	# ---------------------------------------------------------------------------

	# Piece is threatened by adjacent enemy → positive
	var jp_state = _make_state(
		[{"row": 4, "col": 5, "powers": ["jump_proof"]}],
		[{"row": 4, "col": 6}]  # enemy adjacent, can capture p1
	)
	var jp_piece = jp_state.pieces[0]
	var jp_score = Evaluator.score_power_activation(jp_state, jp_piece, "jump_proof")
	_assert(jp_score > 0.0,
		"jump_proof: piece threatened → positive (got %.2f)" % jp_score, fails)

	# Piece is NOT threatened (enemy far away) → -INF
	var jp_safe_state = _make_state(
		[{"row": 1, "col": 1, "powers": ["jump_proof"]}],
		[{"row": 8, "col": 10}]  # enemy far away, can't reach
	)
	var jp_safe_piece = jp_safe_state.pieces[0]
	var jp_safe_score = Evaluator.score_power_activation(jp_safe_state, jp_safe_piece, "jump_proof")
	_assert(jp_safe_score == -INF,
		"jump_proof: piece safe → -INF (got %.2f)" % jp_safe_score, fails)

	# Already jump_proof (flag set) → -INF (don't waste it again)
	var jp_already_state = _make_state(
		[{"row": 4, "col": 5, "powers": ["jump_proof"], "is_jump_proof": true}],
		[{"row": 4, "col": 6}]
	)
	var jp_already_piece = jp_already_state.pieces[0]
	var jp_already_score = Evaluator.score_power_activation(jp_already_state, jp_already_piece, "jump_proof")
	_assert(jp_already_score == -INF,
		"jump_proof: already active → -INF (got %.2f)" % jp_already_score, fails)

	# Piece does not have jump_proof → -INF
	var jp_no_power_state = _make_state(
		[{"row": 4, "col": 5, "powers": []}],
		[{"row": 4, "col": 6}]
	)
	var jp_no_piece = jp_no_power_state.pieces[0]
	var jp_no_score = Evaluator.score_power_activation(jp_no_power_state, jp_no_piece, "jump_proof")
	_assert(jp_no_score == -INF,
		"jump_proof: piece lacks power → -INF (got %.2f)" % jp_no_score, fails)

	# ---------------------------------------------------------------------------
	# AC 5: score_power_activation — no-worthwhile-target → -INF
	# A piece with a single-use offensive power but no valid target keeps -INF.
	# ---------------------------------------------------------------------------

	# bomb with no enemies nearby (enemies far away)
	var no_tgt_state = _make_state(
		[{"row": 4, "col": 5, "powers": ["bomb"]}],
		[{"row": 1, "col": 1}]
	)
	var no_tgt_piece = no_tgt_state.pieces[0]
	var no_tgt_score = Evaluator.score_power_activation(no_tgt_state, no_tgt_piece, "bomb")
	_assert(no_tgt_score == -INF,
		"bomb: no enemies in 3x3 → -INF (got %.2f)" % no_tgt_score, fails)

	# ---------------------------------------------------------------------------
	# AC 6: choose_move (medium) — prefers power activation over movement
	# when AI owns destroy_row and ≥2 enemies are in the same row.
	# Expected: returned dict has "power_action": true (not a board move).
	# ---------------------------------------------------------------------------

	var ai_dr_state = _make_state(
		[{"row": 4, "col": 1, "powers": ["destroy_row"]}],
		[{"row": 4, "col": 7}, {"row": 4, "col": 8}],
		{"current_player": 1}
	)
	var ai_dr_result = AI.choose_move(ai_dr_state, 1, "medium", RNG.new(42))
	_assert(ai_dr_result != null,
		"choose_move medium: not null when power activation available", fails)
	if ai_dr_result != null:
		_assert(ai_dr_result.get("power_action", false) == true,
			"choose_move medium: chose power_action over movement (got %s)" % str(ai_dr_result), fails)

	# ---------------------------------------------------------------------------
	# AC 7: choose_move (expert) — still terminates and returns a valid action
	# when power candidates are included (budget not blown up).
	# State: 3 p1 pieces with various powers, 5 p2 pieces.
	# We don't measure time precisely; just assert the call completes and returns
	# a non-null result.
	# ---------------------------------------------------------------------------

	var expert_state = _make_state(
		[
			{"row": 3, "col": 2, "powers": ["destroy_row"]},
			{"row": 5, "col": 5, "powers": ["jump_proof"]},
			{"row": 2, "col": 8, "powers": ["bomb"]},
		],
		[
			{"row": 3, "col": 7},
			{"row": 3, "col": 8},
			{"row": 5, "col": 4},
			{"row": 6, "col": 6},
			{"row": 7, "col": 3},
		],
		{"current_player": 1}
	)
	var expert_result = AI.choose_move(expert_state, 1, "expert", RNG.new(7))
	_assert(expert_result != null,
		"choose_move expert: not null with power candidates (expert must complete)", fails)

	# ---------------------------------------------------------------------------
	# AC 8: choose_move — a piece with a single-use offensive power does NOT
	# activate it when there is no worthwhile target.
	# P1 has bomb but all enemies are far away from it.
	# Expect: result is a movement action (no power_action key or power_action=false).
	# ---------------------------------------------------------------------------

	var no_power_use_state = _make_state(
		[{"row": 4, "col": 5, "powers": ["bomb"]}],
		[{"row": 1, "col": 1}, {"row": 1, "col": 2}],
		{"current_player": 1}
	)
	var no_power_result = AI.choose_move(no_power_use_state, 1, "medium", RNG.new(1))
	_assert(no_power_result != null,
		"choose_move: not null when movement is only option", fails)
	if no_power_result != null:
		_assert(no_power_result.get("power_action", false) == false,
			"choose_move: does NOT activate bomb when no worthwhile target (got %s)" % str(no_power_result), fails)

	# ---------------------------------------------------------------------------
	# Print result
	# ---------------------------------------------------------------------------
	if fails[0] == 0:
		print("OK ai_power")
	else:
		printerr("FAIL ai_power: %d failures" % fails[0])

	quit(fails[0])
