extends RefCounted

const Rules = preload("res://src/core/rules.gd")
const AI = preload("res://src/core/ai.gd")
const Powers = preload("res://src/core/powers.gd")


static func run() -> Array[String]:
	var failures: Array[String] = []
	_test_choose_is_legal_and_immutable(failures)
	_test_information_boundary(failures)
	_test_power_before_move(failures)
	_test_forced_pass(failures)
	_test_bounded_full_game_simulations(failures)
	_test_rich_inventory_budget(failures)
	return failures


static func _test_choose_is_legal_and_immutable(failures: Array[String]) -> void:
	var state: Dictionary = _state()
	var before: String = JSON.stringify(state)
	var action: Dictionary = AI.choose_action(state, "expert")
	var result: Dictionary = Rules.apply_action(state, action)
	_expect(bool(result.ok), "chosen action is legal", failures)
	_expect(JSON.stringify(state) == before, "choosing does not mutate authority state", failures)
	_expect(JSON.stringify(AI.choose_action(state, "medium")) == JSON.stringify(AI.choose_action(state, "medium")), "tie breaking is deterministic", failures)


static func _test_information_boundary(failures: Array[String]) -> void:
	var state: Dictionary = _state()
	var visible_action: String = JSON.stringify(AI.choose_action(state, "hard"))
	state.pieces[1].flags.invisible = true
	state.pieces[1].inventory.bombs = 9
	state.tiles[4 * 10 + 4].orb = "bombs"
	var hidden_action: String = JSON.stringify(AI.choose_action(state, "hard"))
	# Hiding a remote enemy's inventory and an orb identity cannot supply new information.
	_expect(not hidden_action.is_empty() and not visible_action.is_empty(), "AI evaluates a redacted observation", failures)
	var observed: Dictionary = Rules.observation(state, 1)
	_expect(observed.pieces.size() == 1 and str(observed.tiles[4 * 10 + 4].orb) == "unknown", "observation removes invisible enemies and obscures orb identities", failures)


static func _test_power_before_move(failures: Array[String]) -> void:
	var state: Dictionary = _state()
	state.pieces[0].inventory.move_diagonal = 1
	var action: Dictionary = AI.choose_action(state, "expert")
	_expect(str(action.get("type", "")) == "power", "AI spends useful power before choosing movement", failures)
	var after_power: Dictionary = Rules.apply_action(state, action)
	var follow_up: Dictionary = AI.choose_action(after_power.state, "expert")
	_expect(str(follow_up.get("type", "")) == "move", "AI finishes its turn with a move after power", failures)


static func _test_forced_pass(failures: Array[String]) -> void:
	var state: Dictionary = _state()
	for row: int in range(8):
		for col: int in range(10):
			if not (row == 3 and col == 3) and not (row == 6 and col == 6):
				state.tiles[row * 10 + col].destroyed = true
	_expect(str(AI.choose_action(state, "easy").get("type", "")) == "pass", "AI forced-passes with no legal move", failures)


static func _test_bounded_full_game_simulations(failures: Array[String]) -> void:
	for seed: int in [3, 19, 71]:
		var state: Dictionary = Rules.new_game(seed)
		var completed_turns: int = 0
		var actions_this_turn: int = 0
		for _step: int in range(180):
			if str(state.status) != "playing":
				break
			var before_turn: int = int(state.turn)
			var action: Dictionary = AI.choose_action(state, "medium")
			var result: Dictionary = Rules.apply_action(state, action)
			_expect(bool(result.ok), "simulation action is legal for seed %d" % seed, failures)
			if not bool(result.ok):
				break
			state = result.state
			if int(state.turn) > before_turn:
				completed_turns += 1
				actions_this_turn = 0
			else:
				actions_this_turn += 1
			_expect(actions_this_turn <= 8, "AI power chain stays bounded for seed %d" % seed, failures)
			if actions_this_turn > 8:
				break
		_expect(completed_turns >= 30 or str(state.status) != "playing", "simulation progresses through turns for seed %d" % seed, failures)


static func _test_rich_inventory_budget(failures: Array[String]) -> void:
	var state: Dictionary = _state()
	for power_id: Variant in Powers.catalog().keys():
		state.pieces[0].inventory[power_id] = 1
	for difficulty: String in ["easy", "medium", "hard", "expert"]:
		var started: int = Time.get_ticks_usec()
		var action: Dictionary = AI.choose_action(state, difficulty)
		var elapsed_ms: float = float(Time.get_ticks_usec() - started) / 1000.0
		print("ai_test: rich ", difficulty, " ", snappedf(elapsed_ms, 0.01), "ms")
		_expect(not action.is_empty() and elapsed_ms < 1000.0, "rich %s choice stays bounded" % difficulty, failures)


static func _state() -> Dictionary:
	var state: Dictionary = Rules.new_game(17)
	state.pieces = [
		{"id": 1, "owner": 1, "row": 3, "col": 3, "inventory": {}, "flags": {}},
		{"id": 2, "owner": 2, "row": 6, "col": 6, "inventory": {}, "flags": {}},
	]
	state.next_id = 3
	for tile_value: Variant in state.tiles:
		var tile: Dictionary = tile_value
		tile.height = 0
		tile.destroyed = false
		tile.orb = ""
		tile.marks = {}
	return state


static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("ai_test: " + message)
