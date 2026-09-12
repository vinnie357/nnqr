extends RefCounted

const Rules = preload("res://src/core/rules.gd")


static func run() -> Array[String]:
	var failures: Array[String] = []
	_test_new_game_and_serialization(failures)
	_test_movement_capture_and_turns(failures)
	_test_invalid_actions_preserve_input(failures)
	_test_forced_pass_draw(failures)
	_test_overheat(failures)
	return failures


static func _test_new_game_and_serialization(failures: Array[String]) -> void:
	var state: Dictionary = Rules.new_game(42)
	_expect(state.version == 1 and state.pieces.size() == 40 and state.tiles.size() == 80, "new game has explicit board and pieces", failures)
	var orbs: int = 0
	for tile_value: Variant in state.tiles:
		if not str((tile_value as Dictionary).get("orb", "")).is_empty():
			orbs += 1
	_expect(orbs == 5, "new game seeds five orbs", failures)
	var restored: Dictionary = JSON.parse_string(JSON.stringify(state))
	_expect(int(restored.get("version", 0)) == 1 and int(restored.get("seed", 0)) == 42 and (restored.get("pieces", []) as Array).size() == 40 and (restored.get("tiles", []) as Array).size() == 80, "state remains JSON-safe plain data", failures)
	_expect(JSON.stringify(Rules.new_game(42)) == JSON.stringify(state), "seeded setup is deterministic", failures)


static func _test_movement_capture_and_turns(failures: Array[String]) -> void:
	var state: Dictionary = _arena()
	state.pieces = [_piece(1, 1, 3, 3), _piece(2, 2, 3, 4)]
	state.next_id = 3
	var result: Dictionary = Rules.apply_action(state, {"type": "move", "piece_id": 1, "row": 3, "col": 4})
	_expect(bool(result.ok), "orthogonal enemy occupation captures", failures)
	_expect(result.state.pieces.size() == 1 and int(result.state.active) == 2 and int(result.state.turn) == 1, "capture advances one completed turn", failures)
	_expect(int(result.state.winner) == 1 and str(result.state.status) == "won", "last capture wins", failures)
	var steep: Dictionary = _arena()
	steep.pieces = [_piece(1, 1, 2, 2), _piece(2, 2, 7, 7)]
	steep.tiles[3 * 10 + 2].height = 2
	_expect(Rules.legal_moves(steep, 1).filter(func(m: Dictionary) -> bool: return int(m.row) == 3 and int(m.col) == 2).is_empty(), "cannot climb more than one level without flag", failures)
	steep.pieces[0].flags.climb_tile = true
	_expect(not Rules.legal_moves(steep, 1).filter(func(m: Dictionary) -> bool: return int(m.row) == 3 and int(m.col) == 2).is_empty(), "climb flag permits steep move", failures)


static func _test_invalid_actions_preserve_input(failures: Array[String]) -> void:
	var state: Dictionary = _arena()
	state.pieces = [_piece(1, 1, 3, 3), _piece(2, 2, 6, 6)]
	var before: String = JSON.stringify(state)
	var result: Dictionary = Rules.apply_action(state, {"type": "move", "piece_id": 1, "row": 3, "col": 6})
	_expect(not bool(result.ok) and JSON.stringify(state) == before and JSON.stringify(result.state) == before, "invalid move leaves original and returned state unchanged", failures)
	state.pieces[0].inventory.raise_tile = 1
	before = JSON.stringify(state)
	result = Rules.apply_action(state, {"type": "power", "piece_id": 1, "power_id": "raise_tile", "target": {"row": -1, "col": 0}})
	_expect(not bool(result.ok) and JSON.stringify(state) == before and JSON.stringify(result.state) == before, "failed power restores consumed inventory", failures)


static func _test_forced_pass_draw(failures: Array[String]) -> void:
	var state: Dictionary = _arena()
	state.pieces = [_piece(1, 1, 0, 0), _piece(2, 2, 7, 9)]
	for row: int in range(8):
		for col: int in range(10):
			if not (row == 0 and col == 0) and not (row == 7 and col == 9):
				state.tiles[row * 10 + col].destroyed = true
	var first: Dictionary = Rules.apply_action(state, {"type": "pass"})
	var second: Dictionary = Rules.apply_action(first.state, {"type": "pass"})
	_expect(bool(first.ok) and bool(second.ok) and str(second.state.status) == "draw", "two consecutive forced passes draw", failures)


static func _test_overheat(failures: Array[String]) -> void:
	var state: Dictionary = _arena()
	state.pieces = [_piece(1, 1, 3, 3), _piece(2, 2, 6, 6)]
	state.tiles[3 * 10 + 4].orb = "raise_tile"
	state.pieces[0].inventory.raise_tile = 9
	var result: Dictionary = Rules.apply_action(state, {"type": "move", "piece_id": 1, "row": 3, "col": 4})
	_expect(bool(result.ok) and Rules.piece_by_id(result.state, 1).is_empty() and bool(result.state.tiles[3 * 10 + 4].destroyed), "tenth matching power overheats piece and destroys tile", failures)


static func _arena() -> Dictionary:
	var state: Dictionary = Rules.new_game(9)
	state.pieces = []
	state.next_id = 1
	for tile_value: Variant in state.tiles:
		var tile: Dictionary = tile_value
		tile.height = 0
		tile.destroyed = false
		tile.orb = ""
		tile.marks = {}
	return state


static func _piece(id: int, owner: int, row: int, col: int) -> Dictionary:
	return {"id": id, "owner": owner, "row": row, "col": col, "inventory": {}, "flags": {}}


static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("core_test: " + message)
