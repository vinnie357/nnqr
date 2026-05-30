## game_state_test.gd — Tests for extended game_state.gd (new fields round-trip).
## Run: godot/scripts/godot.sh --headless --path . -s res://tests/game_state_test.gd
extends SceneTree

const GameState = preload("res://src/game_state.gd")

func _assert(cond: bool, msg: String, fails: Array) -> void:
	if not cond:
		printerr("  FAIL: " + msg)
		fails[0] += 1


func _init() -> void:
	var fails := [0]

	# --- New GameState fields have correct defaults ---
	var gs = GameState.new()
	_assert(gs.height_map.size() == 0 or gs.height_map is Array,
		"height_map is Array", fails)
	_assert(gs.destroyed_tiles is Dictionary, "destroyed_tiles is Dictionary", fails)
	_assert(gs.orbs is Array, "orbs is Array", fails)
	_assert(gs.selected == null, "selected defaults to null", fails)
	_assert(gs.valid_moves is Array, "valid_moves is Array", fails)
	_assert(gs.seed == 0 or gs.seed is int, "seed is int", fails)

	# --- init_board initializes new fields ---
	var gs2 = GameState.new()
	gs2.init_board()
	_assert(gs2.height_map.size() == GameState.BOARD_ROWS,
		"init_board height_map has BOARD_ROWS rows", fails)
	_assert(gs2.height_map[0].size() == GameState.BOARD_COLS,
		"init_board height_map row has BOARD_COLS cols", fails)
	# All heights should be 0
	for r in range(GameState.BOARD_ROWS):
		for c in range(GameState.BOARD_COLS):
			_assert(gs2.height_map[r][c] == 0,
				"init_board height_map all zeros at [%d][%d]" % [r, c], fails)
	_assert(gs2.destroyed_tiles.size() == 0, "init_board destroyed_tiles empty", fails)
	_assert(gs2.orbs.size() == 0, "init_board orbs empty", fails)
	_assert(gs2.selected == null, "init_board selected is null", fails)
	_assert(gs2.valid_moves.size() == 0, "init_board valid_moves empty", fails)

	# --- Piece new fields default to false ---
	var piece = GameState.Piece.new("p1-1-1", 1, 1, 1)
	_assert(piece.powers is Array, "piece.powers is Array", fails)
	_assert(piece.powers.size() == 0, "piece.powers empty by default", fails)
	_assert(not piece.is_jump_proof, "piece.is_jump_proof default false", fails)
	_assert(not piece.can_move_diagonally, "piece.can_move_diagonally default false", fails)
	_assert(not piece.can_climb_any, "piece.can_climb_any default false", fails)
	_assert(not piece.can_wrap, "piece.can_wrap default false", fails)
	_assert(not piece.is_invisible, "piece.is_invisible default false", fails)

	# --- Piece to_dict includes new fields ---
	var p2 = GameState.Piece.new("p1-3-5", 1, 3, 5)
	p2.powers = ["fire", "ice"]
	p2.is_jump_proof = true
	p2.can_move_diagonally = true
	p2.can_climb_any = false
	p2.can_wrap = true
	p2.is_invisible = false
	var pd = p2.to_dict()
	_assert(pd.has("powers"), "piece to_dict has 'powers'", fails)
	_assert(pd["powers"] == ["fire", "ice"], "piece to_dict powers correct", fails)
	_assert(pd.has("is_jump_proof"), "piece to_dict has 'is_jump_proof'", fails)
	_assert(pd["is_jump_proof"] == true, "piece to_dict is_jump_proof correct", fails)
	_assert(pd.has("can_move_diagonally"), "piece to_dict has 'can_move_diagonally'", fails)
	_assert(pd["can_move_diagonally"] == true, "piece to_dict can_move_diagonally correct", fails)
	_assert(pd.has("can_wrap"), "piece to_dict has 'can_wrap'", fails)
	_assert(pd["can_wrap"] == true, "piece to_dict can_wrap correct", fails)
	_assert(pd.has("can_climb_any"), "piece to_dict has 'can_climb_any'", fails)
	_assert(pd.has("is_invisible"), "piece to_dict has 'is_invisible'", fails)

	# --- to_dict / load_dict round-trip for GameState ---
	var gs3 = GameState.new()
	gs3.init_board()
	gs3.seed = 42
	gs3.height_map[2][3] = 3
	gs3.height_map[5][7] = 2
	gs3.destroyed_tiles["4,5"] = true
	gs3.destroyed_tiles["3,3"] = true
	gs3.orbs.append({"row": 5, "col": 5, "power_id": "fire"})
	gs3.orbs.append({"row": 3, "col": 3, "power_id": "ice"})
	gs3.selected = {"row": 1, "col": 2}
	gs3.valid_moves.append({"row": 2, "col": 2, "capture": false})
	gs3.valid_moves.append({"row": 1, "col": 3, "capture": true})
	# Set powers on a piece
	gs3.pieces[0].powers = ["wind"]
	gs3.pieces[0].is_jump_proof = true
	gs3.pieces[0].can_move_diagonally = true
	gs3.pieces[0].can_wrap = true
	gs3.pieces[0].can_climb_any = false
	gs3.pieces[0].is_invisible = true

	var d = gs3.to_dict()

	# Verify to_dict emits new fields
	_assert(d.has("height_map"), "to_dict has height_map", fails)
	_assert(d.has("destroyed_tiles"), "to_dict has destroyed_tiles", fails)
	_assert(d.has("orbs"), "to_dict has orbs", fails)
	_assert(d.has("selected"), "to_dict has selected", fails)
	_assert(d.has("valid_moves"), "to_dict has valid_moves", fails)
	_assert(d.has("seed"), "to_dict has seed", fails)
	_assert(d["seed"] == 42, "to_dict seed == 42", fails)
	_assert(d["height_map"][2][3] == 3, "to_dict height_map[2][3]==3", fails)
	_assert(d["height_map"][5][7] == 2, "to_dict height_map[5][7]==2", fails)
	_assert(d["destroyed_tiles"].has("4,5"), "to_dict destroyed_tiles has '4,5'", fails)
	_assert(d["orbs"].size() == 2, "to_dict orbs size == 2", fails)
	_assert(d["selected"]["row"] == 1 and d["selected"]["col"] == 2,
		"to_dict selected correct", fails)
	_assert(d["valid_moves"].size() == 2, "to_dict valid_moves size == 2", fails)

	# Now round-trip through load_dict
	var gs4 = GameState.new()
	gs4.load_dict(d)
	_assert(gs4.seed == 42, "load_dict restores seed", fails)
	_assert(gs4.height_map[2][3] == 3, "load_dict height_map[2][3]==3", fails)
	_assert(gs4.height_map[5][7] == 2, "load_dict height_map[5][7]==2", fails)
	_assert(gs4.destroyed_tiles.has("4,5"), "load_dict destroyed_tiles has '4,5'", fails)
	_assert(gs4.orbs.size() == 2, "load_dict orbs size == 2", fails)
	_assert(gs4.orbs[0].row == 5 and gs4.orbs[0].col == 5 and gs4.orbs[0].power_id == "fire",
		"load_dict orb[0] correct", fails)
	_assert(gs4.selected != null and gs4.selected.row == 1 and gs4.selected.col == 2,
		"load_dict selected correct", fails)
	_assert(gs4.valid_moves.size() == 2, "load_dict valid_moves size == 2", fails)

	# Piece powers and flags round-trip
	var restored_piece: GameState.Piece = null
	for p in gs4.pieces:
		if p.id == gs3.pieces[0].id:
			restored_piece = p
			break
	_assert(restored_piece != null, "first piece found after load_dict", fails)
	_assert(restored_piece.powers.size() == 1, "restored piece has 1 power", fails)
	_assert(restored_piece.powers[0] == "wind", "restored piece power == 'wind'", fails)
	_assert(restored_piece.is_jump_proof == true, "restored is_jump_proof == true", fails)
	_assert(restored_piece.can_move_diagonally == true, "restored can_move_diagonally == true", fails)
	_assert(restored_piece.can_wrap == true, "restored can_wrap == true", fails)
	_assert(restored_piece.can_climb_any == false, "restored can_climb_any == false", fails)
	_assert(restored_piece.is_invisible == true, "restored is_invisible == true", fails)

	# --- load_dict with missing new fields uses defaults (backward compat) ---
	var gs5 = GameState.new()
	gs5.load_dict({
		"current_player": 2,
		"turn": 5,
		"status": "playing",
		"winner": 0,
		"pieces": [{"id": "p1-1-1", "player": 1, "row": 1, "col": 1}]
	})
	_assert(gs5.seed == 0, "missing seed defaults to 0", fails)
	_assert(gs5.height_map is Array, "missing height_map defaults to Array", fails)
	_assert(gs5.destroyed_tiles.size() == 0, "missing destroyed_tiles defaults to empty", fails)
	_assert(gs5.orbs.size() == 0, "missing orbs defaults to empty", fails)
	_assert(gs5.selected == null, "missing selected defaults to null", fails)
	_assert(gs5.valid_moves.size() == 0, "missing valid_moves defaults to empty", fails)

	# --- Existing fields not broken ---
	_assert(gs4.cols == 10, "cols still 10 after load_dict", fails)
	_assert(gs4.rows == 8, "rows still 8 after load_dict", fails)
	_assert(gs4.pieces.size() == 40, "pieces still 40 after load_dict", fails)

	if fails[0] == 0:
		print("OK game_state")
	else:
		printerr("FAIL game_state: %d" % fails[0])
	quit(fails[0])
