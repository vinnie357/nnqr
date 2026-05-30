## controller_test.gd — Tests for controller.gd (pure game-flow logic).
## Run: godot/scripts/godot.sh --headless --path . -s res://tests/controller_test.gd
extends SceneTree

const Board      = preload("res://src/board.gd")
const GameState  = preload("res://src/game_state.gd")
const Controller = preload("res://src/controller.gd")
const Orbs       = preload("res://src/orbs.gd")
const RNG        = preload("res://src/rng.gd")
const Executor   = preload("res://src/powers/executor.gd")
const Targets    = preload("res://src/powers/targets.gd")


func _assert(cond: bool, msg: String, fails: Array) -> void:
	if not cond:
		printerr("  FAIL: " + msg)
		fails[0] += 1


## Build a minimal 2-piece state: p1 at (3,5), p2 at (4,5) — adjacent.
func _two_piece_state() -> GameState:
	var state := GameState.new()
	state.current_player = 1
	state.turn = 0
	state.status = "playing"
	state.winner = 0
	state.height_map = []
	for _r in range(8):
		var row: Array = []
		row.resize(10)
		row.fill(0)
		state.height_map.append(row)
	state.destroyed_tiles = {}
	state.orbs = []
	state.selected = null
	state.valid_moves = []
	state.seed = 1
	var p1 := GameState.Piece.new("p1-a", 1, 3, 5)
	var p2 := GameState.Piece.new("p2-a", 2, 4, 5)
	state.pieces = [p1, p2]
	return state


## Build a 4-piece state so AI (player 2) always has a legal move.
func _ai_state() -> GameState:
	var state := GameState.new()
	state.current_player = 2
	state.turn = 0
	state.status = "playing"
	state.winner = 0
	state.height_map = []
	for _r in range(8):
		var row: Array = []
		row.resize(10)
		row.fill(0)
		state.height_map.append(row)
	state.destroyed_tiles = {}
	state.orbs = []
	state.selected = null
	state.valid_moves = []
	state.seed = 42
	# Two p1 pieces far away, two p2 pieces near centre.
	state.pieces = [
		GameState.Piece.new("p1-1", 1, 1, 1),
		GameState.Piece.new("p1-2", 1, 1, 2),
		GameState.Piece.new("p2-1", 2, 6, 5),
		GameState.Piece.new("p2-2", 2, 7, 5),
	]
	return state


func _init() -> void:
	var fails := [0]

	# ------------------------------------------------------------------
	# handle_tile_click: clicking own piece with nothing selected → select
	# ------------------------------------------------------------------
	var s0 := _two_piece_state()
	var s1: GameState = Controller.handle_tile_click(s0, 3, 5)
	_assert(s1.selected != null, "handle_tile_click own piece: selected != null", fails)
	_assert(s1.selected.row == 3 and s1.selected.col == 5,
		"handle_tile_click own piece: selected == {3,5}", fails)
	_assert(s1.valid_moves.size() > 0,
		"handle_tile_click own piece: valid_moves non-empty", fails)

	# ------------------------------------------------------------------
	# handle_tile_click: clicking a valid move → piece relocated, player flipped
	# ------------------------------------------------------------------
	# p1 is at (3,5); (3,4) should be a valid empty move.
	var s2: GameState = Controller.handle_tile_click(s1, 3, 4)
	_assert(s2.selected == null, "after move: selected cleared", fails)
	_assert(s2.current_player == 2, "after move: player flipped to 2", fails)
	var moved := Board.piece_at(s2, 3, 4)
	_assert(moved != null, "after move: piece found at (3,4)", fails)
	_assert(moved.player == 1, "after move: piece at (3,4) is player 1", fails)
	var gone := Board.piece_at(s2, 3, 5)
	_assert(gone == null, "after move: (3,5) vacated", fails)

	# ------------------------------------------------------------------
	# handle_tile_click: clicking empty / invalid tile → deselects
	# ------------------------------------------------------------------
	var s3: GameState = Controller.handle_tile_click(s2, 5, 5)  # p2's turn; click p1 territory
	_assert(s3.selected == null, "invalid click: selected cleared", fails)

	# ------------------------------------------------------------------
	# handle_tile_click: reselect / deselect — clicking a piece when
	# a different own piece is selected should reselect to that piece.
	# (From initial state, player 1 clicks p1-a twice then p1-b.)
	# ------------------------------------------------------------------
	var s_init := _two_piece_state()
	# Add a second p1 piece so we can re-select.
	var p1b := GameState.Piece.new("p1-b", 1, 3, 6)
	s_init.pieces.append(p1b)
	var sel_a: GameState = Controller.handle_tile_click(s_init, 3, 5)
	_assert(sel_a.selected != null and sel_a.selected.col == 5,
		"reselect: first select col 5", fails)
	var sel_b: GameState = Controller.handle_tile_click(sel_a, 3, 6)
	_assert(sel_b.selected != null and sel_b.selected.col == 6,
		"reselect: second select col 6", fails)

	# ------------------------------------------------------------------
	# activate_power: no-target power (e.g. "fast" — immediate, no tile needed)
	# We use "fast" which sets a flag; it should mutate state via executor.
	# ------------------------------------------------------------------
	var s_pw := _two_piece_state()
	var p_with_power := GameState.Piece.new("p1-pw", 1, 3, 5)
	p_with_power.powers = ["fast"]
	s_pw.pieces = [p_with_power, GameState.Piece.new("p2-a", 2, 4, 5)]
	s_pw.selected = {"row": 3, "col": 5}

	var exec_result: Dictionary = Controller.activate_power(s_pw, p_with_power, "fast", null)
	_assert(exec_result.has("state"), "activate_power: result has 'state' key", fails)
	_assert(exec_result.has("mode"), "activate_power: result has 'mode' key", fails)
	_assert(exec_result["mode"] == Controller.MODE_NORMAL,
		"activate_power no-target: mode == MODE_NORMAL", fails)

	# ------------------------------------------------------------------
	# activate_power: needs-target power → returns awaiting_target mode
	# ------------------------------------------------------------------
	var s_tgt := _two_piece_state()
	var p_raise := GameState.Piece.new("p1-rt", 1, 3, 5)
	p_raise.powers = ["raise_tile"]
	s_tgt.pieces = [p_raise, GameState.Piece.new("p2-a", 2, 4, 5)]
	s_tgt.selected = {"row": 3, "col": 5}

	var tgt_result: Dictionary = Controller.activate_power(s_tgt, p_raise, "raise_tile", null)
	_assert(tgt_result.has("mode"), "awaiting_target: result has 'mode' key", fails)
	_assert(tgt_result["mode"] == Controller.MODE_AWAITING_TARGET,
		"awaiting_target: mode == MODE_AWAITING_TARGET", fails)
	_assert(tgt_result.has("target_tiles"), "awaiting_target: result has 'target_tiles'", fails)
	_assert(tgt_result["target_tiles"] is Array, "awaiting_target: target_tiles is Array", fails)

	# ------------------------------------------------------------------
	# activate_power: needs-target power WITH a valid target → executes
	# ------------------------------------------------------------------
	var tgt_with := Controller.activate_power(
		s_tgt, p_raise, "raise_tile", {"row": 3, "col": 4})
	_assert(tgt_with["mode"] == Controller.MODE_NORMAL,
		"needs-target with valid target: mode normal", fails)

	# ------------------------------------------------------------------
	# ai_take_turn: produces a legal state change for player 2
	# ------------------------------------------------------------------
	var s_ai := _ai_state()
	var rng := RNG.new(42)
	var ai_next: GameState = Controller.ai_take_turn(s_ai, "easy", rng)
	_assert(ai_next != null, "ai_take_turn: returns non-null state", fails)
	_assert(ai_next.current_player == 1 or ai_next.status == "won",
		"ai_take_turn: player flipped to 1 (or game won)", fails)
	_assert(ai_next.turn == s_ai.turn + 1, "ai_take_turn: turn incremented", fails)

	# ------------------------------------------------------------------
	# ORB INTEGRATION: handle_tile_click collects orb at destination
	# p1 at (3,5), orb at (3,4) with power_id "raise_tile".
	# Select piece then move onto orb tile; piece should gain the power.
	# ------------------------------------------------------------------
	var s_orb := _two_piece_state()
	s_orb.orbs = [{"row": 3, "col": 4, "power_id": "raise_tile"}]
	# Select piece
	var s_orb1: GameState = Controller.handle_tile_click(s_orb, 3, 5)
	# Move onto orb tile
	var s_orb2: GameState = Controller.handle_tile_click(s_orb1, 3, 4)
	var collector := Board.piece_at(s_orb2, 3, 4)
	_assert(collector != null, "orb collect: piece at (3,4) after move", fails)
	_assert(collector.powers.has("raise_tile"),
		"orb collect: piece.powers contains 'raise_tile'", fails)
	_assert(s_orb2.orbs.size() == 0,
		"orb collect: orb removed from state.orbs", fails)

	# ------------------------------------------------------------------
	# ORB INTEGRATION: orbs spawn after turn == SPAWN_INTERVAL
	# Start at turn SPAWN_INTERVAL - 1 (turn = 6), move once → turn = 7.
	# Board has no orbs; after the move state.orbs should be non-empty.
	# ------------------------------------------------------------------
	var s_spawn := _two_piece_state()
	s_spawn.turn = Orbs.SPAWN_INTERVAL - 1  # 6
	s_spawn.seed = 7  # any value; deterministic with rng
	var s_spawn1: GameState = Controller.handle_tile_click(s_spawn, 3, 5)
	var s_spawn2: GameState = Controller.handle_tile_click(s_spawn1, 3, 4)
	_assert(s_spawn2.turn == Orbs.SPAWN_INTERVAL,
		"orb spawn: turn reached SPAWN_INTERVAL (%d)" % Orbs.SPAWN_INTERVAL, fails)
	_assert(s_spawn2.orbs.size() > 0,
		"orb spawn: orbs spawned after reaching SPAWN_INTERVAL", fails)

	# ------------------------------------------------------------------
	# ORB INTEGRATION: overheat — piece holding 9 of same power collects
	# a 10th copy → piece is destroyed (removed from pieces).
	# ------------------------------------------------------------------
	var s_heat := _two_piece_state()
	var hot_piece := Board.piece_at(s_heat, 3, 5)
	# Give the piece 9 copies of "bomb" without going through the controller.
	for _i in range(9):
		hot_piece.powers.append("bomb")
	# Place an orb with "bomb" at the move destination.
	s_heat.orbs = [{"row": 3, "col": 4, "power_id": "bomb"}]
	var s_heat1: GameState = Controller.handle_tile_click(s_heat, 3, 5)
	var s_heat2: GameState = Controller.handle_tile_click(s_heat1, 3, 4)
	var piece_ids: Array = []
	for p: GameState.Piece in s_heat2.pieces:
		piece_ids.append(p.id)
	_assert(not piece_ids.has("p1-a"),
		"overheat: piece with 10x same power is removed from state.pieces", fails)

	# ------------------------------------------------------------------
	# ORB INTEGRATION (AI path): ai_take_turn spawns orbs on interval
	# Start at turn SPAWN_INTERVAL - 1 with player 2 to move.
	# After ai_take_turn, turn == SPAWN_INTERVAL and orbs spawned.
	# ------------------------------------------------------------------
	var s_ai_orb := _ai_state()
	s_ai_orb.turn = Orbs.SPAWN_INTERVAL - 1  # 6
	s_ai_orb.seed = 13
	var rng_ai := RNG.new(s_ai_orb.seed + s_ai_orb.turn)
	var s_ai_after: GameState = Controller.ai_take_turn(s_ai_orb, "easy", rng_ai)
	_assert(s_ai_after.turn == Orbs.SPAWN_INTERVAL,
		"ai orb spawn: turn reached SPAWN_INTERVAL", fails)
	_assert(s_ai_after.orbs.size() > 0,
		"ai orb spawn: ai path spawns orbs on interval", fails)

	# ------------------------------------------------------------------
	# Results
	# ------------------------------------------------------------------
	if fails[0] == 0:
		print("controller_test: ALL PASS")
	else:
		printerr("controller_test: %d FAIL(s)" % fails[0])
	quit(fails[0])
