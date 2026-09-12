## Authoritative, scene-free Quadradius rules.
## State is deliberately only Dictionaries and Arrays so saves/replays need no conversion.
extends RefCounted

const WIDTH: int = 10
const HEIGHT: int = 8
const INITIAL_PIECES_PER_PLAYER: int = 20
const ORBS_PER_WAVE: int = 5
const TURNS_PER_ORB_WAVE: int = 14
const OVERHEAT_COUNT: int = 10
const Powers = preload("res://src/core/powers.gd")


static func new_game(seed: int = 1) -> Dictionary:
	var state: Dictionary = {
		"version": 1,
		"seed": seed,
		"rng": seed,
		"next_id": 1,
		"turn": 0,
		"active": 1,
		"status": "playing",
		"winner": 0,
		"passes": 0,
		"pieces": [],
		"tiles": [],
	}
	for row: int in range(HEIGHT):
		for col: int in range(WIDTH):
			state.tiles.append({"height": 0, "destroyed": false, "orb": "", "marks": {}})
	for row: int in range(2):
		for col: int in range(WIDTH):
			_add_piece(state, 1, row, col)
	for row: int in range(HEIGHT - 2, HEIGHT):
		for col: int in range(WIDTH):
			_add_piece(state, 2, row, col)
	_spawn_orbs(state, ORBS_PER_WAVE)
	return state


static func piece_at(state: Dictionary, row: int, col: int) -> Dictionary:
	for piece_value: Variant in state.get("pieces", []):
		var piece: Dictionary = piece_value
		if int(piece.get("row", -1)) == row and int(piece.get("col", -1)) == col:
			return piece
	return {}


static func piece_by_id(state: Dictionary, id: int) -> Dictionary:
	for piece_value: Variant in state.get("pieces", []):
		var piece: Dictionary = piece_value
		if int(piece.get("id", -1)) == id:
			return piece
	return {}


static func legal_moves(state: Dictionary, id: int) -> Array:
	var piece: Dictionary = piece_by_id(state, id)
	if piece.is_empty() or not _in_bounds_piece(piece):
		return []
	var source: Dictionary = _tile(state, int(piece.row), int(piece.col))
	if source.is_empty() or bool(source.get("destroyed", false)):
		return []
	var flags: Dictionary = piece.get("flags", {})
	var directions: Array = [[-1, 0], [1, 0], [0, -1], [0, 1]]
	if bool(flags.get("move_diagonal", false)):
		directions.append_array([[-1, -1], [-1, 1], [1, -1], [1, 1]])
	var moves: Array = []
	for direction: Array in directions:
		var row: int = int(piece.row) + int(direction[0])
		var col: int = int(piece.col) + int(direction[1])
		if bool(flags.get("flat_to_sphere", false)):
			row = posmod(row, HEIGHT)
			col = posmod(col, WIDTH)
		if _can_land(state, piece, row, col, int(source.height), flags, false, int(flags.get("switcheroo", 0)) >= 1 or int(flags.get("scavenger", 0)) >= 2):
			var occupant: Dictionary = piece_at(state, row, col)
			moves.append({"row": row, "col": col, "capture": not occupant.is_empty()})
	# A friendly hotspot is a deliberate long-range destination.
	for row: int in range(HEIGHT):
		for col: int in range(WIDTH):
			var tile: Dictionary = _tile(state, row, col)
			var marks: Dictionary = tile.get("marks", {})
			if int(marks.get("hotspot", 0)) == int(piece.owner) and _can_land(state, piece, row, col, int(source.height), flags, true, int(flags.get("switcheroo", 0)) >= 1 or int(flags.get("scavenger", 0)) >= 2):
				var existing: bool = false
				for move_value: Variant in moves:
					var move: Dictionary = move_value
					if int(move.row) == row and int(move.col) == col:
						existing = true
				if not existing:
					var occupant: Dictionary = piece_at(state, row, col)
					moves.append({"row": row, "col": col, "capture": not occupant.is_empty()})
	# Switcheroo is an intentional board-wide exchange; stage two can exchange enemies.
	var switch_stage: int = int(flags.get("switcheroo", 0))
	if switch_stage > 0:
		for other_value: Variant in state.pieces:
			var other: Dictionary = other_value
			if int(other.id) == id or (int(other.owner) != int(piece.owner) and switch_stage < 2):
				continue
			moves.append({"row": int(other.row), "col": int(other.col), "capture": false, "switch": true})
	if bool(flags.get("centerpult", false)):
		for row: int in range(1, HEIGHT - 1):
			for col: int in range(1, WIDTH - 1):
				if not piece_at(state, row, col).is_empty() or bool(_tile(state, row, col).get("destroyed", false)):
					continue
				var plus: bool = not piece_at(state, row - 1, col).is_empty() and not piece_at(state, row + 1, col).is_empty() and not piece_at(state, row, col - 1).is_empty() and not piece_at(state, row, col + 1).is_empty()
				var cross: bool = not piece_at(state, row - 1, col - 1).is_empty() and not piece_at(state, row - 1, col + 1).is_empty() and not piece_at(state, row + 1, col - 1).is_empty() and not piece_at(state, row + 1, col + 1).is_empty()
				if plus or cross:
					moves.append({"row": row, "col": col, "capture": false, "centerpult": true})
	return moves


static func apply_action(state: Dictionary, action: Dictionary) -> Dictionary:
	var original: Dictionary = state.duplicate(true)
	if state.get("status", "") != "playing":
		return _failure(original, "game is finished")
	var kind: String = str(action.get("type", ""))
	if kind == "move":
		return _apply_move(original, action)
	if kind == "power":
		return _apply_power(original, action)
	if kind == "pass":
		return _apply_pass(original)
	if kind == "resign":
		return _apply_resign(original)
	return _failure(original, "unknown action")


static func observation(state: Dictionary, viewer: int) -> Dictionary:
	var observed: Dictionary = state.duplicate(true)
	# Thinking must not sample or infer the authority RNG stream.
	observed.seed = 1000003 + int(state.get("turn", 0)) * 97 + viewer * 17
	observed.rng = int(observed.seed)
	for index: int in range(observed.pieces.size() - 1, -1, -1):
		var piece: Dictionary = observed.pieces[index]
		if int(piece.owner) != viewer:
			if bool((piece.get("flags", {}) as Dictionary).get("invisible", false)):
				observed.pieces.remove_at(index)
			elif int((piece.get("flags", {}) as Dictionary).get("spyware", 0)) != viewer:
				piece.inventory = {}
	for tile_value: Variant in observed.tiles:
		var tile: Dictionary = tile_value
		if not str(tile.get("orb", "")).is_empty() and int((tile.get("marks", {}) as Dictionary).get("orb_spy", 0)) != viewer:
			tile.orb = "unknown" # Presence is visible; identity is not.
	return observed


static func _apply_move(working: Dictionary, action: Dictionary) -> Dictionary:
	var id: int = int(action.get("piece_id", -1))
	var piece: Dictionary = piece_by_id(working, id)
	if piece.is_empty() or int(piece.owner) != int(working.active):
		return _failure(working, "piece is not active player's")
	var row: int = int(action.get("row", -1))
	var col: int = int(action.get("col", -1))
	var legal: bool = false
	for move_value: Variant in legal_moves(working, id):
		var move: Dictionary = move_value
		if int(move.row) == row and int(move.col) == col:
			legal = true
			break
	if not legal:
		return _failure(working, "illegal move")
	var events: Array = []
	var victim: Dictionary = piece_at(working, row, col)
	var origin_row: int = int(piece.row)
	var origin_col: int = int(piece.col)
	if not victim.is_empty():
		var switch_stage: int = int((piece.get("flags", {}) as Dictionary).get("switcheroo", 0))
		var scavenger_stage: int = int((piece.get("flags", {}) as Dictionary).get("scavenger", 0))
		if int(victim.owner) == int(piece.owner) and switch_stage < 1 and scavenger_stage < 2:
			return _failure(working, "cannot land on ally")
		if switch_stage >= 1 and (int(victim.owner) == int(piece.owner) or switch_stage >= 2):
			victim.row = origin_row
			victim.col = origin_col
			events.append({"type": "switch", "piece_id": id, "other_id": int(victim.id)})
		else:
			var captured_inventory: Dictionary = victim.get("inventory", {}).duplicate(true)
			_remove_piece(working, int(victim.id))
			events.append({"type": "capture", "piece_id": id, "victim_id": int(victim.id)})
			if scavenger_stage > 0:
				_share_capture(working, int(piece.owner), captured_inventory, events)
	piece.row = row
	piece.col = col
	_collect_orb(working, piece, events)
	_apply_landing_effects(working, piece, events)
	if not victim.is_empty() and not piece_by_id(working, int(victim.id)).is_empty():
		_collect_orb(working, victim, events)
		_apply_landing_effects(working, victim, events)
	_finalize_all(working, events)
	_check_victory(working, events)
	if working.status == "playing":
		var flags: Dictionary = piece.get("flags", {})
		if int(flags.get("extra_moves", 0)) > 0:
			flags.extra_moves = int(flags.extra_moves) - 1
			events.append({"type": "extra_move", "piece_id": id})
		else:
			_end_turn(working, events)
	else:
		# A successful move is a completed turn even when it ended the match.
		_end_turn(working, events)
	return {"ok": true, "state": working, "events": events, "error": ""}


static func _apply_power(working: Dictionary, action: Dictionary) -> Dictionary:
	var id: int = int(action.get("piece_id", -1))
	var piece: Dictionary = piece_by_id(working, id)
	var power_id: String = str(action.get("power_id", ""))
	if piece.is_empty() or int(piece.owner) != int(working.active):
		return _failure(working, "piece is not active player's")
	var inventory: Dictionary = piece.get("inventory", {})
	if int(inventory.get(power_id, 0)) < 1:
		return _failure(working, "power not owned")
	var before_effect: Dictionary = working.duplicate(true)
	# Consumption happens on the working copy before effect application. This matters for
	# double/teach effects, which must never reproduce their consumed source item.
	inventory[power_id] = int(inventory[power_id]) - 1
	if int(inventory[power_id]) <= 0:
		inventory.erase(power_id)
	var target: Dictionary = action.get("target", {})
	var result: Dictionary = Powers.apply(working, id, power_id, target)
	if not bool(result.get("ok", false)):
		return _failure(before_effect, str(result.get("error", "invalid power target")))
	var events: Array = result.get("events", []).duplicate(true)
	_process_displacements(working, events)
	if power_id == "orbic_rehash":
		_process_power_plants(working, events)
	if power_id == "multiply":
		for event_value: Variant in events:
			var event: Dictionary = event_value
			if str(event.get("type", "")) == "multiply":
				var child: Dictionary = piece_by_id(working, int(event.piece_id))
				if not child.is_empty():
					_collect_orb(working, child, events)
					_apply_landing_effects(working, child, events)
	working.passes = 0
	_finalize_all(working, events)
	_check_victory(working, events)
	return {"ok": true, "state": working, "events": events, "error": ""}


static func _apply_pass(working: Dictionary) -> Dictionary:
	var has_move: bool = false
	for piece_value: Variant in working.pieces:
		var piece: Dictionary = piece_value
		if int(piece.owner) == int(working.active) and not legal_moves(working, int(piece.id)).is_empty():
			has_move = true
			break
	if has_move:
		return _failure(working, "pass requires no legal moves")
	var events: Array = [{"type": "pass", "player": int(working.active)}]
	working.passes = int(working.passes) + 1
	if int(working.passes) >= 2:
		working.status = "draw"
		working.winner = 0
		events.append({"type": "draw", "reason": "two forced passes"})
	else:
		_end_turn(working, events, false)
	return {"ok": true, "state": working, "events": events, "error": ""}


static func _apply_resign(working: Dictionary) -> Dictionary:
	working.status = "won"
	working.winner = 2 if int(working.active) == 1 else 1
	return {"ok": true, "state": working, "events": [{"type": "resign", "player": int(working.active)}], "error": ""}


static func _end_turn(state: Dictionary, events: Array, reset_passes: bool = true) -> void:
	state.turn = int(state.turn) + 1
	state.active = 2 if int(state.active) == 1 else 1
	if reset_passes:
		state.passes = 0
	if int(state.turn) % TURNS_PER_ORB_WAVE == 0:
		_spawn_orbs(state, ORBS_PER_WAVE, events)
		_finalize_all(state, events)
		_check_victory(state, events)


static func _process_displacements(state: Dictionary, events: Array) -> void:
	for event_value: Variant in events.duplicate(true):
		var event: Dictionary = event_value
		if event.has("piece_id") and (str(event.get("type", "")) == "relocate" or str(event.get("type", "")) == "scramble"):
			var piece: Dictionary = piece_by_id(state, int(event.piece_id))
			if not piece.is_empty():
				_collect_orb(state, piece, events)
				_apply_landing_effects(state, piece, events)
				_finalize_piece(state, int(piece.id), events)


static func _collect_orb(state: Dictionary, piece: Dictionary, events: Array) -> void:
	var tile: Dictionary = _tile(state, int(piece.row), int(piece.col))
	var orb: String = str(tile.get("orb", ""))
	if orb.is_empty():
		return
	if bool((piece.get("flags", {}) as Dictionary).get("inhibit", false)):
		events.append({"type": "inhibited_orb", "piece_id": int(piece.id), "power_id": orb})
		return
	tile.orb = ""
	var inventory: Dictionary = piece.get("inventory", {})
	inventory[orb] = int(inventory.get(orb, 0)) + 1
	events.append({"type": "collect_orb", "piece_id": int(piece.id), "power_id": orb})
	_share_orb_pickup(state, piece, orb, tile, events)


static func _apply_landing_effects(state: Dictionary, piece: Dictionary, events: Array) -> void:
	var marks: Dictionary = _tile(state, int(piece.row), int(piece.col)).get("marks", {})
	if int(marks.get("bankrupt", 0)) != 0 and int(marks.get("bankrupt", 0)) != int(piece.owner):
		piece.inventory.clear()
		Powers.strip_positive(piece)
		events.append({"type": "bankrupt", "piece_id": int(piece.id)})
	if bool((piece.get("flags", {}) as Dictionary).get("tripwire", false)):
		_remove_piece(state, int(piece.id))
		events.append({"type": "tripwire", "piece_id": int(piece.id)})


static func _share_orb_pickup(state: Dictionary, recipient: Dictionary, power_id: String, tile: Dictionary, events: Array) -> void:
	var parasite_owner: int = int((recipient.get("flags", {}) as Dictionary).get("parasite_owner", 0))
	var plant_owner: int = int((tile.get("marks", {}) as Dictionary).get("power_plant", 0))
	for piece_value: Variant in state.pieces:
		var piece: Dictionary = piece_value
		var flags: Dictionary = piece.get("flags", {})
		var parasite_target: bool = parasite_owner != 0 and int(piece.owner) == parasite_owner and (bool(flags.get("parasite", false)) or bool(flags.get("network_bridge", false)))
		var plant_target: bool = plant_owner != 0 and int(piece.owner) == plant_owner and (bool(flags.get("power_plant", false)) or bool(flags.get("network_bridge", false)))
		if parasite_target or plant_target:
			piece.inventory[power_id] = int(piece.inventory.get(power_id, 0)) + 1
			events.append({"type": "network_share", "piece_id": int(piece.id), "power_id": power_id})


static func _share_capture(state: Dictionary, owner: int, inventory: Dictionary, events: Array) -> void:
	for piece_value: Variant in state.pieces:
		var piece: Dictionary = piece_value
		var flags: Dictionary = piece.get("flags", {})
		if int(piece.owner) == owner and (int(flags.get("scavenger", 0)) > 0 or bool(flags.get("network_bridge", false))):
			for power_id: Variant in inventory:
				piece.inventory[power_id] = int(piece.inventory.get(power_id, 0)) + int(inventory[power_id])
			events.append({"type": "scavenger_share", "piece_id": int(piece.id)})


static func _finalize_piece(state: Dictionary, id: int, events: Array) -> void:
	var piece: Dictionary = piece_by_id(state, id)
	if piece.is_empty():
		return
	for power_value: Variant in (piece.get("inventory", {}) as Dictionary).values():
		if int(power_value) >= OVERHEAT_COUNT:
			var row: int = int(piece.row)
			var col: int = int(piece.col)
			_remove_piece(state, id)
			var tile: Dictionary = _tile(state, row, col)
			tile.destroyed = true
			tile.orb = ""
			events.append({"type": "overheat", "piece_id": id, "row": row, "col": col})
			return


static func _finalize_all(state: Dictionary, events: Array) -> void:
	var ids: Array = []
	for piece_value: Variant in state.pieces:
		ids.append(int((piece_value as Dictionary).id))
	for id: int in ids:
		_finalize_piece(state, id, events)


static func _check_victory(state: Dictionary, events: Array) -> void:
	var one: int = 0
	var two: int = 0
	for piece_value: Variant in state.pieces:
		var piece: Dictionary = piece_value
		if int(piece.owner) == 1:
			one += 1
		elif int(piece.owner) == 2:
			two += 1
	if one == 0 and two == 0:
		state.status = "draw"
		state.winner = 0
		events.append({"type": "draw", "reason": "simultaneous elimination"})
	elif one == 0 or two == 0:
		state.status = "won"
		state.winner = 2 if one == 0 else 1
		events.append({"type": "victory", "winner": int(state.winner)})


static func _spawn_orbs(state: Dictionary, count: int, events: Array = []) -> void:
	var available: Array = []
	for row: int in range(HEIGHT):
		for col: int in range(WIDTH):
			var tile: Dictionary = _tile(state, row, col)
			if not bool(tile.get("destroyed", false)) and str(tile.get("orb", "")).is_empty() and piece_at(state, row, col).is_empty():
				available.append({"row": row, "col": col})
	var catalog: Dictionary = Powers.catalog()
	var keys: Array = catalog.keys()
	keys.sort()
	for _number: int in range(mini(count, available.size())):
		var location_index: int = Powers.random_int(state, available.size())
		var location: Dictionary = available.pop_at(location_index)
		var power_id: String = str(keys[Powers.random_int(state, keys.size())])
		var tile: Dictionary = _tile(state, int(location.row), int(location.col))
		tile.orb = power_id
		events.append({"type": "spawn_orb", "row": int(location.row), "col": int(location.col)})
	_process_power_plants(state, events)


static func _process_power_plants(state: Dictionary, events: Array) -> void:
	# Empty plant tiles absorb an arriving/rehashed orb immediately and distribute it to
	# their owner network. Occupied plants are handled by ordinary landing collection.
	for tile_index: int in range(state.tiles.size()):
		var tile_value: Variant = state.tiles[tile_index]
		var tile: Dictionary = tile_value
		if not piece_at(state, tile_index / WIDTH, tile_index % WIDTH).is_empty():
			continue
		var owner: int = int((tile.get("marks", {}) as Dictionary).get("power_plant", 0))
		var orb: String = str(tile.get("orb", ""))
		if owner == 0 or orb.is_empty():
			continue
		tile.orb = ""
		for piece_value: Variant in state.pieces:
			var piece: Dictionary = piece_value
			var flags: Dictionary = piece.get("flags", {})
			if int(piece.owner) == owner and (bool(flags.get("power_plant", false)) or bool(flags.get("network_bridge", false))):
				piece.inventory[orb] = int(piece.inventory.get(orb, 0)) + 1
				events.append({"type": "power_plant_absorb", "piece_id": int(piece.id), "power_id": orb})


static func _can_land(state: Dictionary, piece: Dictionary, row: int, col: int, source_height: int, flags: Dictionary, ignore_height: bool = false, allow_ally: bool = false) -> bool:
	if not _in_bounds(row, col):
		return false
	var tile: Dictionary = _tile(state, row, col)
	if bool(tile.get("destroyed", false)):
		return false
	var occupant: Dictionary = piece_at(state, row, col)
	if not occupant.is_empty() and int(occupant.owner) == int(piece.owner) and not allow_ally:
		return false
	if not occupant.is_empty() and int(occupant.owner) != int(piece.owner) and bool((occupant.get("flags", {}) as Dictionary).get("jump_proof", false)):
		return false
	if not ignore_height and not bool(flags.get("climb_tile", false)) and int(tile.height) > source_height + 1:
		return false
	return true


static func _in_bounds(row: int, col: int) -> bool:
	return row >= 0 and row < HEIGHT and col >= 0 and col < WIDTH


static func _in_bounds_piece(piece: Dictionary) -> bool:
	return _in_bounds(int(piece.get("row", -1)), int(piece.get("col", -1)))


static func _tile(state: Dictionary, row: int, col: int) -> Dictionary:
	if not _in_bounds(row, col):
		return {}
	return state.tiles[row * WIDTH + col]


static func _add_piece(state: Dictionary, owner: int, row: int, col: int) -> Dictionary:
	var piece: Dictionary = {"id": int(state.next_id), "owner": owner, "row": row, "col": col, "inventory": {}, "flags": {}}
	state.next_id = int(state.next_id) + 1
	state.pieces.append(piece)
	return piece


static func _remove_piece(state: Dictionary, id: int) -> void:
	for index: int in range(state.pieces.size()):
		if int((state.pieces[index] as Dictionary).get("id", -1)) == id:
			state.pieces.remove_at(index)
			return


static func _failure(original: Dictionary, error: String) -> Dictionary:
	return {"ok": false, "state": original, "events": [], "error": error}
