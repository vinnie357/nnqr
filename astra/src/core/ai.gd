## Deterministic, bounded action picker. It only evaluates an observation, never the
## authority state, so invisible pieces and enemy inventories cannot guide a choice.
extends RefCounted

const Rules = preload("res://src/core/rules.gd")
const Powers = preload("res://src/core/powers.gd")


static func choose_action(state: Dictionary, difficulty: String = "medium") -> Dictionary:
	var observed: Dictionary = Rules.observation(state, int(state.get("active", 1)))
	if str(observed.get("status", "")) != "playing":
		return {"type": "pass"}
	var budget: int = _budget(difficulty)
	var player: int = int(observed.active)
	var baseline: int = _score(observed, player)
	var best_power: Dictionary = {}
	var best_power_score: int = baseline
	var power_options: Array = []
	var considered: int = 0
	for piece_value: Variant in observed.pieces:
		var piece: Dictionary = piece_value
		if int(piece.owner) != player:
			continue
		var inventory: Dictionary = piece.get("inventory", {})
		var power_ids: Array = inventory.keys()
		power_ids.sort()
		for power_value: Variant in power_ids:
			if considered >= budget:
				break
			var power_id: String = str(power_value)
			var entry: Dictionary = Powers.catalog().get(power_id, {})
			var targets: Array = [{}] if str(entry.get("target", "self")) == "self" else Powers.targets(observed, int(piece.id), power_id)
			for target_value: Variant in targets:
				if considered >= budget:
					break
				considered += 1
				var target: Dictionary = target_value
				var candidate: Dictionary = {"type": "power", "piece_id": int(piece.id), "power_id": power_id, "target": target.duplicate(true)}
				var result: Dictionary = Rules.apply_action(observed, candidate)
				if not bool(result.ok):
					continue
				var score: int = _score(result.state, player) + _power_bias(power_id, result.events)
				power_options.append({"action": candidate, "state": result.state, "score": score})
				if score > best_power_score or (score == best_power_score and _prefer(candidate, best_power, observed, difficulty)):
					best_power = candidate
					best_power_score = score
		if considered >= budget:
			break
	if difficulty in ["hard", "expert"]:
		power_options.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return int(left.score) > int(right.score))
		var planned_count: int = mini(power_options.size(), 4 if difficulty == "hard" else 8)
		best_power = {}
		best_power_score = baseline
		for option_index: int in range(planned_count):
			var option: Dictionary = power_options[option_index]
			var follow: Dictionary = _best_follow_move(option.state, player, 12 if difficulty == "hard" else 28)
			var follow_delta: int = int(follow.score) - _score(option.state, player)
			var reply_score: int = _opponent_reply_score(follow.state, player, 6 if difficulty == "hard" else 12)
			var reply_delta: int = reply_score - int(follow.score)
			var planned_score: int = int(option.score) + follow_delta + reply_delta
			if planned_score > best_power_score or (planned_score == best_power_score and _prefer(option.action, best_power, observed, difficulty)):
				best_power = option.action
				best_power_score = planned_score
	if not best_power.is_empty() and best_power_score > baseline:
		return best_power

	var best_move: Dictionary = {}
	var best_move_score: int = -1000000
	for piece_value: Variant in observed.pieces:
		var piece: Dictionary = piece_value
		if int(piece.owner) != player:
			continue
		for move_value: Variant in Rules.legal_moves(observed, int(piece.id)):
			var move: Dictionary = move_value
			var candidate: Dictionary = {"type": "move", "piece_id": int(piece.id), "row": int(move.row), "col": int(move.col)}
			var result: Dictionary = Rules.apply_action(observed, candidate)
			if not bool(result.ok):
				continue
			var score: int = _score(result.state, player)
			if bool(move.get("capture", false)):
				score += 40
			if score > best_move_score or (score == best_move_score and _prefer(candidate, best_move, observed, difficulty)):
				best_move = candidate
				best_move_score = score
	if not best_move.is_empty():
		return best_move
	return {"type": "pass"}


static func _budget(difficulty: String) -> int:
	match difficulty:
		"easy": return 8
		"hard": return 64
		"expert": return 160
		_: return 24


static func _score(state: Dictionary, player: int) -> int:
	var own: int = 0
	var enemy: int = 0
	var inventory: int = 0
	var positional: int = 0
	for piece_value: Variant in state.get("pieces", []):
		var piece: Dictionary = piece_value
		if int(piece.owner) == player:
			own += 1
			for count_value: Variant in (piece.get("inventory", {}) as Dictionary).values():
				inventory += int(count_value)
			var flags: Dictionary = piece.get("flags", {})
			for flag_id: String in ["move_diagonal", "climb_tile", "flat_to_sphere", "jump_proof", "invisible", "centerpult", "network_bridge"]:
				if bool(flags.get(flag_id, false)):
					positional += 5
			positional += int(flags.get("grow_quadradius", 0)) * 6 + int(flags.get("extra_moves", 0)) * 8
		else:
			enemy += 1
	if str(state.get("status", "")) == "won":
		return 100000 if int(state.get("winner", 0)) == player else -100000
	if str(state.get("status", "")) == "draw":
		return 0
	# Known orb presence rewards progress, while nearby enemies make exposed positions less attractive.
	for tile_index: int in range(state.tiles.size()):
		if str((state.tiles[tile_index] as Dictionary).get("orb", "")).is_empty():
			continue
		var row: int = tile_index / 10
		var col: int = tile_index % 10
		var nearest: int = 99
		for piece_value: Variant in state.pieces:
			var piece: Dictionary = piece_value
			if int(piece.owner) == player:
				nearest = mini(nearest, absi(int(piece.row) - row) + absi(int(piece.col) - col))
		positional += maxi(0, 10 - nearest)
	for own_value: Variant in state.pieces:
		var own_piece: Dictionary = own_value
		if int(own_piece.owner) != player:
			continue
		for enemy_value: Variant in state.pieces:
			var enemy_piece: Dictionary = enemy_value
			if int(enemy_piece.owner) != player and absi(int(own_piece.row) - int(enemy_piece.row)) + absi(int(own_piece.col) - int(enemy_piece.col)) == 1:
				positional -= 3
	return own * 100 - enemy * 100 + inventory * 3 + positional


static func _best_follow_move(state: Dictionary, player: int, budget: int) -> Dictionary:
	var best: int = _score(state, player)
	var best_state: Dictionary = state
	var checked: int = 0
	for piece_value: Variant in state.pieces:
		var piece: Dictionary = piece_value
		if int(piece.owner) != player:
			continue
		for move_value: Variant in Rules.legal_moves(state, int(piece.id)):
			if checked >= budget:
				return {"score": best, "state": best_state}
			checked += 1
			var move: Dictionary = move_value
			var result: Dictionary = Rules.apply_action(state, {"type": "move", "piece_id": int(piece.id), "row": int(move.row), "col": int(move.col)})
			if bool(result.get("ok", false)):
				var score: int = _score(result.state, player)
				if score > best:
					best = score
					best_state = result.state
	return {"score": best, "state": best_state}


static func _opponent_reply_score(state: Dictionary, player: int, budget: int) -> int:
	if str(state.get("status", "")) != "playing" or int(state.get("active", 0)) == player:
		return _score(state, player)
	var worst: int = _score(state, player)
	var checked: int = 0
	for piece_value: Variant in state.pieces:
		var piece: Dictionary = piece_value
		if int(piece.owner) == player:
			continue
		for move_value: Variant in Rules.legal_moves(state, int(piece.id)):
			if checked >= budget:
				return worst
			checked += 1
			var move: Dictionary = move_value
			var result: Dictionary = Rules.apply_action(state, {"type": "move", "piece_id": int(piece.id), "row": int(move.row), "col": int(move.col)})
			if bool(result.get("ok", false)):
				worst = mini(worst, _score(result.state, player))
	return worst


static func _power_bias(power_id: String, events: Array) -> int:
	var bias: int = 8
	if power_id in ["move_again", "move_diagonal", "climb_tile", "flat_to_sphere", "grow_quadradius", "hotspot"]:
		bias = 12
	for event_value: Variant in events:
		var event: Dictionary = event_value
		if str(event.get("type", "")) in ["destroy", "capture", "recruit"]:
			bias += 50
	return bias


static func _prefer(candidate: Dictionary, current: Dictionary, state: Dictionary, difficulty: String) -> bool:
	if current.is_empty():
		return true
	# A pure seed-derived coin flip gives reproducible variation while preserving state.
	var candidate_key: String = JSON.stringify(candidate)
	var current_key: String = JSON.stringify(current)
	var salt: int = int(state.get("seed", 1)) + int(state.get("turn", 0)) * 31 + _budget(difficulty)
	var candidate_value: int = abs((candidate_key.hash() ^ salt) % 2147483647)
	var current_value: int = abs((current_key.hash() ^ salt) % 2147483647)
	return candidate_value < current_value
