extends RefCounted
const Powers = preload("res://src/core/powers.gd")

static func _state() -> Dictionary:
	var tiles: Array = []
	for index in range(80):
		tiles.append({"height": 0, "destroyed": false, "orb": "", "marks": {}})
	return {"rng": 13, "next_id": 4, "turn": 0, "active": 1, "tiles": tiles, "pieces": [
		{"id": 1, "owner": 1, "row": 3, "col": 4, "inventory": {"raise_tile": 2, "double_powers": 2}, "flags": {}},
		{"id": 2, "owner": 1, "row": 3, "col": 5, "inventory": {"climb_tile": 2}, "flags": {}},
		{"id": 3, "owner": 2, "row": 4, "col": 4, "inventory": {"jump_proof": 2}, "flags": {"jump_proof": true}}
	]}

static func _expect(failures: Array, condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

static func run() -> Array[String]:
	var failures: Array[String] = []
	var entries: Dictionary = Powers.catalog()
	_expect(failures, entries.size() == 86, "Catalog must contain all 86 collectible names, excluding Cancel Multiply")
	_expect(failures, not entries.has("cancel_multiply"), "Cancel Multiply is not loot")
	for id in entries:
		var state: Dictionary = _state()
		# A meaningful initial condition ensures every effect changes authoritative state.
		state.pieces.append({"id": 4, "owner": 1, "row": 2, "col": 4, "inventory": {"climb_tile": 1}, "flags": {}})
		state.pieces.append({"id": 5, "owner": 2, "row": 3, "col": 3, "inventory": {"jump_proof": 1}, "flags": {"jump_proof": true}})
		state.next_id = 6
		state.tiles[34].height = 1
		state.tiles[35].height = 1
		state.tiles[44].height = 1
		state.tiles[0].orb = "raise_tile"
		state.pieces[1].flags.inhibit = true
		var before: Dictionary = state.duplicate(true)
		var target: Dictionary = {"row": 2, "col": 3} if id == "multiply" else {}
		var result: Dictionary = Powers.apply(state, 1, id, target)
		_expect(failures, result.ok, "Catalog power fails activation: " + id)
		_expect(failures, state != before, "Catalog power has no effect: " + id)
		_expect(failures, state.turn == 0 and state.active == 1, "Power switched turn: " + id)
	var state: Dictionary = _state()
	var before: Dictionary = state.duplicate(true)
	_expect(failures, not Powers.apply(state, 1, "multiply", {"row": 3, "col": 5}).ok and state == before, "Occupied multiply must reject immutably")
	_expect(failures, not Powers.apply(state, 1, "unknown").ok and state == before, "Unknown power must reject immutably")
	Powers.apply(state, 1, "double_powers")
	_expect(failures, state.pieces[0].inventory.raise_tile == 4 and state.pieces[0].inventory.double_powers == 2, "2x must not double itself")
	state = _state()
	Powers.apply(state, 1, "teach_row")
	_expect(failures, state.pieces[1].inventory.raise_tile == 2 and state.pieces[0].inventory.raise_tile == 2, "Teach copies rather than transfers")
	state = _state()
	Powers.apply(state, 1, "pilfer_column")
	_expect(failures, state.pieces[2].inventory.is_empty() and state.pieces[0].inventory.jump_proof == 2, "Pilfer removes enemy inventory")
	state = _state()
	Powers.apply(state, 1, "learn_row")
	_expect(failures, state.pieces[0].inventory.climb_tile == 2 and state.pieces[1].inventory.climb_tile == 2, "Learn preserves donor inventory")
	state = _state()
	Powers.apply(state, 1, "beneficiary")
	_expect(failures, state.pieces[1].inventory.is_empty() and state.pieces[0].inventory.climb_tile == 2, "Beneficiary transfers all allied inventory")
	state = _state()
	state.pieces[1].flags = {"inhibit": true, "jump_proof": true}
	state.pieces[2].flags = {"inhibit": true, "jump_proof": true}
	Powers.apply(state, 1, "purify_radial")
	_expect(failures, state.pieces[1].flags.has("jump_proof") and not state.pieces[1].flags.has("inhibit"), "Purify preserves friendly enhancements")
	_expect(failures, state.pieces[2].flags.has("inhibit") and not state.pieces[2].flags.has("jump_proof"), "Purify strips enemy enhancements only")
	state = _state()
	Powers.apply(state, 1, "acidic_radial")
	_expect(failures, state.pieces.size() == 2 and state.tiles[44].destroyed, "Acid bypasses jump proof and leaves a hole")
	Powers.apply(state, 1, "refurb_radial")
	_expect(failures, not state.tiles[44].destroyed and state.tiles[44].height == 0, "Refurb repairs acid holes")
	state = _state()
	_expect(failures, Powers.targets(state, 1, "destroy_radial").size() == 8, "Base radial footprint is eight neighboring tiles")
	Powers.apply(state, 1, "grow_quadradius")
	_expect(failures, Powers.targets(state, 1, "destroy_radial").size() == 24, "First grow extends radial to 24")
	Powers.apply(state, 1, "grow_quadradius")
	_expect(failures, Powers.targets(state, 1, "destroy_radial").size() == 48, "Second grow extends radial to 48")
	Powers.apply(state, 1, "grow_quadradius")
	before = state.duplicate(true)
	_expect(failures, not Powers.apply(state, 1, "grow_quadradius").ok and state == before, "Fourth grow rejects without mutation")
	state = _state()
	before = state.duplicate(true)
	Powers.apply(state, 1, "bombs")
	Powers.apply(before, 1, "bombs")
	_expect(failures, state == before, "Bombs must be seed deterministic")
	state = _state()
	for index in range(80):
		state.tiles[index].height = -4
	for attempt in range(20):
		Powers.apply(state, 1, "smart_bombs")
	_expect(failures, not Powers._piece(state, 1).is_empty() and not Powers._piece(state, 2).is_empty(), "Smart bombs protect every allied tile")
	state = _state()
	for index in range(80):
		state.tiles[index].orb = "raise_tile"
	before = state.duplicate(true)
	_expect(failures, not Powers.apply(state, 1, "relocate").ok and state == before, "Relocate excludes all orb tiles and rejects if none remain")
	state = _state()
	Powers.apply(state, 1, "parasite_radial")
	_expect(failures, state.pieces[0].flags.parasite and state.pieces[2].flags.parasite_owner == 1, "Parasite connects caster and infection")
	state = _state()
	Powers.apply(state, 1, "swap_radial")
	_expect(failures, state.pieces[0].owner == 2 and state.pieces[1].owner == 2 and state.pieces[2].owner == 1, "Swap flips caster, allies and enemies")
	failures.append_array(family_checks())
	failures.append_array(integration_checks())
	return failures

static func family_checks() -> Array[String]:
	var failures: Array[String] = []
	for shape in ["radial", "row", "column"]:
		for family in Powers.FAMILIES:
			var state: Dictionary = _state()
			if shape == "row":
				state.pieces[2].row = 3
				state.pieces[2].col = 3
			elif shape == "column":
				state.pieces[1].row = 2
				state.pieces[1].col = 4
			var ally: Dictionary = state.pieces[1]
			var enemy: Dictionary = state.pieces[2]
			var enemy_index: int = int(enemy.row) * 10 + int(enemy.col)
			var ally_index: int = int(ally.row) * 10 + int(ally.col)
			state.tiles[enemy_index].height = 2
			state.tiles[ally_index].height = -2
			ally.flags.inhibit = true
			var far: Dictionary = {"id": 9, "owner": 2, "row": 7, "col": 9, "inventory": {"raise_tile": 1}, "flags": {}}
			state.pieces.append(far)
			var far_before: Dictionary = far.duplicate(true)
			Powers.apply(state, 1, family + "_" + shape)
			_expect(failures, far == far_before, "Area effect leaked beyond " + family + "_" + shape)
			var valid: bool = true
			match family:
				"invert":
					valid = state.tiles[enemy_index].height == -2 and state.tiles[ally_index].height == 2
				"dredge":
					valid = state.tiles[enemy_index].height == -4 and state.tiles[ally_index].height == 4
				"teach":
					valid = ally.inventory.get("raise_tile", 0) == 2 and not enemy.inventory.has("raise_tile")
				"learn":
					valid = state.pieces[0].inventory.get("climb_tile", 0) == 2 and ally.inventory.climb_tile == 2
				"pilfer":
					valid = enemy.inventory.is_empty() and state.pieces[0].inventory.get("jump_proof", 0) == 2
				"parasite":
					valid = enemy.flags.get("parasite_owner", 0) == 1 and not ally.flags.has("parasite_owner")
				"swap":
					valid = enemy.owner == 1 and ally.owner == 2 and state.pieces[0].owner == 2
				"spyware":
					valid = enemy.flags.get("spyware", 0) == 1 and not ally.flags.has("spyware")
				"orb_spy":
					valid = state.tiles[enemy_index].marks.get("orb_spy", 0) == 1
				"refurb":
					valid = state.tiles[enemy_index].height == 0 and state.tiles[ally_index].height == 0
				"bankrupt":
					valid = not state.tiles[enemy_index].marks.has("bankrupt") and not state.tiles[ally_index].marks.has("bankrupt")
					var count: int = 0
					for tile in state.tiles:
						if tile.marks.has("bankrupt"):
							count += 1
					valid = valid and count > 0
				"purify":
					valid = not ally.flags.has("inhibit") and not enemy.flags.has("jump_proof")
				"tripwire", "inhibit":
					valid = enemy.flags.get(family, false)
				"kamikaze":
					valid = state.pieces.size() == 1 and state.pieces[0].id == 9
				"destroy", "acidic":
					valid = Powers._piece(state, 3).is_empty() and not Powers._piece(state, 1).is_empty() and not Powers._piece(state, 2).is_empty()
					if family == "acidic":
						valid = valid and state.tiles[enemy_index].destroyed
				"recruit":
					valid = enemy.owner == 1 and enemy.inventory.jump_proof == 2 and enemy.flags.jump_proof
				"scramble":
					var occupied: Array = []
					for piece in state.pieces:
						var pos: Dictionary = {"row": piece.row, "col": piece.col}
						valid = valid and not occupied.has(pos)
						occupied.append(pos)
			_expect(failures, valid, "Incorrect family semantics: " + family + "_" + shape)
	return failures

static func _game() -> Dictionary:
	var state: Dictionary = _state()
	state.merge({"version": 1, "seed": 13, "status": "playing", "winner": 0, "passes": 0})
	return state

static func integration_checks() -> Array[String]:
	var rules = load("res://src/core/rules.gd")
	var failures: Array[String] = []
	var state: Dictionary = _game()
	state.pieces[0].inventory.teach_row = 1
	var result: Dictionary = rules.apply_action(state, {"type": "power", "piece_id": 1, "power_id": "teach_row"})
	_expect(failures, result.ok and not result.state.pieces[1].inventory.has("teach_row") and state.pieces[0].inventory.teach_row == 1, "Rules consumes Teach before copying, preserving input")
	state = _game()
	state.pieces[0].inventory.teach_row = 1
	state.pieces[1].inventory.raise_tile = 8
	result = rules.apply_action(state, {"type": "power", "piece_id": 1, "power_id": "teach_row"})
	_expect(failures, result.ok and rules.piece_by_id(result.state, 2).is_empty() and result.state.tiles[35].destroyed, "Teach causes recipient overheat and hole")
	state = _game()
	state.pieces[1].flags.scavenger = 1
	state.pieces[2].flags.clear()
	result = rules.apply_action(state, {"type": "move", "piece_id": 1, "row": 4, "col": 4})
	_expect(failures, result.ok and not rules.piece_by_id(result.state, 2).inventory.has("jump_proof"), "Ordinary capture must not trigger scavenger network")
	state = _game()
	state.pieces[0].flags.scavenger = 2
	state.pieces[2].flags.network_bridge = true
	result = rules.apply_action(state, {"type": "move", "piece_id": 1, "row": 3, "col": 5})
	_expect(failures, result.ok and rules.piece_by_id(result.state, 2).is_empty() and rules.piece_by_id(result.state, 1).inventory.get("climb_tile", 0) == 2, "Scavenger stage two captures allies and inherits powers")
	state = _game()
	state.pieces[0].flags.switcheroo = 1
	state.pieces[1].row = 0
	state.pieces[1].col = 0
	state.pieces[1].flags.tripwire = true
	state.tiles[0].height = 4
	result = rules.apply_action(state, {"type": "move", "piece_id": 1, "row": 0, "col": 0})
	_expect(failures, result.ok and rules.piece_by_id(result.state, 2).is_empty() and rules.piece_by_id(result.state, 1).row == 0, "Switcheroo ignores distance/height and triggers victim tripwire")
	state = _game()
	state.pieces[0].flags.switcheroo = 2
	state.pieces[2].row = 7
	state.pieces[2].col = 9
	result = rules.apply_action(state, {"type": "move", "piece_id": 1, "row": 7, "col": 9})
	_expect(failures, result.ok and rules.piece_by_id(result.state, 3).row == 3, "Switcheroo stage two swaps Jump Proof enemies")
	state = _game()
	state.pieces[0].flags.centerpult = true
	state.pieces.append({"id": 4, "owner": 2, "row": 5, "col": 7, "inventory": {}, "flags": {}})
	state.pieces.append({"id": 5, "owner": 1, "row": 7, "col": 7, "inventory": {}, "flags": {}})
	state.pieces.append({"id": 6, "owner": 2, "row": 6, "col": 6, "inventory": {}, "flags": {}})
	state.pieces.append({"id": 7, "owner": 1, "row": 6, "col": 8, "inventory": {}, "flags": {}})
	state.tiles[67].height = 4
	state.tiles[67].orb = "invisible"
	result = rules.apply_action(state, {"type": "move", "piece_id": 1, "row": 6, "col": 7})
	_expect(failures, result.ok and rules.piece_by_id(result.state, 1).inventory.get("invisible", 0) == 1 and result.state.active == 2, "Centerpult mixed formation ignores height, collects orb and ends turn")
	state = _game()
	state.pieces[0].flags.parasite_owner = 2
	state.pieces[2].flags.network_bridge = true
	state.pieces[2].inventory.raise_tile = 9
	state.tiles[24].orb = "raise_tile"
	result = rules.apply_action(state, {"type": "move", "piece_id": 1, "row": 2, "col": 4})
	_expect(failures, result.ok and rules.piece_by_id(result.state, 3).is_empty() and result.state.tiles[44].destroyed and result.state.winner == 1, "Parasite bridge receipt overheats distant recipient and resolves victory")
	state = _game()
	state.pieces[0].flags.network_bridge = true
	state.pieces[0].inventory.raise_tile = 9
	state.pieces[0].inventory.orbic_rehash = 1
	state.tiles[0].orb = "raise_tile"
	for tile in state.tiles:
		tile.marks.power_plant = 1
	result = rules.apply_action(state, {"type": "power", "piece_id": 1, "power_id": "orbic_rehash"})
	_expect(failures, result.ok and rules.piece_by_id(result.state, 1).is_empty(), "Rehashed orbs feed plant bridges and overheat receivers")
	state = _game()
	state.passes = 1
	state.pieces[0].inventory.raise_tile = 1
	result = rules.apply_action(state, {"type": "power", "piece_id": 1, "power_id": "raise_tile"})
	_expect(failures, result.ok and result.state.passes == 0, "Successful terrain change resets forced-pass streak")
	state = _game()
	state.pieces[2].flags.spyware = 1
	state.tiles[0].orb = "raise_tile"
	state.tiles[1].orb = "invisible"
	state.tiles[1].marks.orb_spy = 1
	var observed: Dictionary = rules.observation(state, 1)
	_expect(failures, rules.piece_by_id(observed, 3).inventory.get("jump_proof", 0) == 2, "Spyware reveals inventory to its owner")
	_expect(failures, not str(observed.tiles[0].orb).is_empty() and observed.tiles[0].orb != "raise_tile" and observed.tiles[1].orb == "invisible", "Observation preserves orb presence and reveals only orb-spy identities")
	return failures
