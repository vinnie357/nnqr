## executor_test.gd — Tests for powers/executor.gd (dispatch completeness + API).
## Run: godot/scripts/godot.sh --headless --path . -s res://tests/executor_test.gd
extends SceneTree

const GameState = preload("res://src/game_state.gd")
const Definitions = preload("res://src/powers/definitions.gd")
const Executor = preload("res://src/powers/executor.gd")


func _assert(cond: bool, msg: String, fails: Array) -> void:
	if not cond:
		printerr("  FAIL: " + msg)
		fails[0] += 1


func _make_piece(id: String, player: int, row: int, col: int, powers: Array = []) -> GameState.Piece:
	var p := GameState.Piece.new(id, player, row, col)
	p.powers = powers.duplicate()
	return p


func _empty_state() -> GameState:
	var s := GameState.new()
	s.pieces = []
	s.height_map = []
	for _r in range(8):
		var row_arr: Array = []
		row_arr.resize(10)
		row_arr.fill(0)
		s.height_map.append(row_arr)
	s.destroyed_tiles = {}
	s.orbs = []
	s.seed = 42
	s.turn = 1
	return s


func _init() -> void:
	var fails := [0]

	var executor := Executor.new()

	# -------------------------------------------------------------------------
	# Dispatch completeness: every one of the 82 definition ids resolves to a handler
	# -------------------------------------------------------------------------
	var all_ids := Definitions.all_ids()
	_assert(all_ids.size() == 82, "definitions: exactly 82 powers, got %d" % all_ids.size(), fails)

	var missing := []
	for id in all_ids:
		if not executor.is_registered(id):
			missing.append(id)
	if missing.size() > 0:
		printerr("  FAIL: missing handlers for: " + ", ".join(missing))
		fails[0] += missing.size()
	_assert(missing.size() == 0, "all 82 definition ids have registered handlers", fails)

	# -------------------------------------------------------------------------
	# is_registered: true for all definition ids
	# -------------------------------------------------------------------------
	for id in all_ids:
		_assert(executor.is_registered(id), "is_registered(%s)==true" % id, fails)

	# -------------------------------------------------------------------------
	# is_registered: false for unknown ids
	# -------------------------------------------------------------------------
	_assert(not executor.is_registered("nonexistent_xyz"), "is_registered(nonexistent)==false", fails)
	_assert(not executor.is_registered(""), "is_registered('')==false", fails)

	# -------------------------------------------------------------------------
	# registered_ids: contains all definition ids
	# -------------------------------------------------------------------------
	var reg_ids := executor.registered_ids()
	for id in all_ids:
		_assert(reg_ids.has(id), "registered_ids contains %s" % id, fails)

	# -------------------------------------------------------------------------
	# execute() with unknown power id returns state unchanged
	# -------------------------------------------------------------------------
	var s0 := _empty_state()
	var p0 := _make_piece("p0", 1, 3, 3)
	s0.pieces = [p0]
	var s0_after = executor.execute(s0, p0, "nonexistent_xyz_power")
	_assert(s0_after == s0, "execute(unknown) returns same state", fails)

	# -------------------------------------------------------------------------
	# execute() — smoke test: destroy_row removes row pieces
	# -------------------------------------------------------------------------
	var s_dr := _empty_state()
	var p_dr := _make_piece("pd", 1, 3, 5, ["destroy_row"])
	var enemy_dr := _make_piece("ed", 2, 3, 2)
	s_dr.pieces = [p_dr, enemy_dr]
	var s_dr_after = executor.execute(s_dr, p_dr, "destroy_row")
	var ids_dr := []
	for p in s_dr_after.pieces:
		ids_dr.append(p.id)
	_assert(ids_dr.has("pd"), "destroy_row: caster survives", fails)
	_assert(not ids_dr.has("ed"), "destroy_row: row enemy removed", fails)

	# -------------------------------------------------------------------------
	# execute() — smoke test: raise_tile via secondary action
	# -------------------------------------------------------------------------
	var s_rt := _empty_state()
	var p_rt := _make_piece("pr", 1, 3, 3, ["raise_tile"])
	s_rt.pieces = [p_rt]
	var target_rt := {"row": 3, "col": 4}
	var s_rt_after = executor.execute(s_rt, p_rt, "raise_tile", target_rt)
	var h_after = s_rt_after.height_map[2][3]  # row=3,col=4 -> [2][3]
	_assert(h_after == 1, "raise_tile via execute: height increased to 1, got %d" % h_after, fails)

	if fails[0] == 0:
		print("OK executor")
	else:
		printerr("FAIL executor: %d" % fails[0])
	quit(fails[0])
