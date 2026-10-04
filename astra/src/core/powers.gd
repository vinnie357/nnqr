extends RefCounted

const NEGATIVE = ["tripwire", "inhibit", "parasite_owner", "spyware"]
const FAMILIES = {
	"invert": ["Terrain", "Reverse tile heights."],
	"dredge": ["Terrain", "Raise allies to maximum height and lower enemies to minimum."],
	"teach": ["Inventory", "Copy your remaining inventory to allies in range."],
	"learn": ["Inventory", "Copy allied inventories into this piece."],
	"pilfer": ["Inventory", "Take enemy inventories in range."],
	"parasite": ["Network", "Infect enemies; their orb pickups feed your parasite network."],
	"scramble": ["Position", "Randomly redistribute pieces across usable tiles in range."],
	"swap": ["Control", "Reverse ownership of every piece in range, including this one."],
	"spyware": ["Intelligence", "Reveal enemy inventories to your squadron."],
	"orb_spy": ["Intelligence", "Reveal orb contents on marked tiles to your squadron."],
	"refurb": ["Terrain", "Restore tiles to height zero, repair holes, and clear tile devices."],
	"bankrupt": ["Control", "Mark empty tiles to strip enemy inventory and beneficial abilities."],
	"purify": ["Restoration", "Cleanse allied disabilities and remove enemy beneficial abilities."],
	"tripwire": ["Control", "Afflict enemies with destruction upon displacement."],
	"inhibit": ["Control", "Prevent affected enemies from absorbing orbs."],
	"kamikaze": ["Attack", "Destroy every piece in range, including this one."],
	"destroy": ["Attack", "Destroy enemy pieces in range."],
	"acidic": ["Attack", "Destroy enemies and leave holes beneath them."],
	"recruit": ["Control", "Convert enemies, preserving their inventories and abilities."]
}

static func catalog() -> Dictionary:
	var result: Dictionary = {}
	for family in FAMILIES:
		for shape in ["radial", "row", "column"]:
			var id: String = family + "_" + shape
			result[id] = {"name": id.capitalize(), "description": FAMILIES[family][1] + " Area: " + shape + ".", "category": FAMILIES[family][0], "target": "self"}
	var singles: Dictionary = {
		"multiply": ["Generation", "tile", "Create an empty allied piece on an adjacent vacant tile."],
		"orbic_rehash": ["Orbs", "self", "Redistribute the existing orbs across vacant usable tiles."],
		"grow_quadradius": ["Range", "self", "Expand area powers; maximum three upgrades."],
		"bombs": ["Attack", "self", "Drop 8 random impacts per range level; destroy pieces and depress tiles."],
		"smart_bombs": ["Attack", "self", "Drop 8 random impacts per range level, avoiding allied pieces."],
		"snake_tunneling": ["Attack", "self", "Tunnel randomly for 12 steps per range level, raising tiles and destroying enemies."],
		"raise_tile": ["Terrain", "self", "Raise the tile beneath this piece by one."],
		"lower_tile": ["Terrain", "self", "Lower the tile beneath this piece by one."],
		"climb_tile": ["Movement", "self", "Permanently ignore climbing height limits."],
		"plateau": ["Terrain", "self", "Raise your tile and the surrounding square to maximum height."],
		"moat": ["Terrain", "self", "Raise your tile to maximum; lower surrounding tiles to minimum."],
		"trench_row": ["Terrain", "self", "Lower your horizontal band to minimum height."],
		"trench_column": ["Terrain", "self", "Lower your vertical band to minimum height."],
		"wall_row": ["Terrain", "self", "Raise your horizontal band to maximum height."],
		"wall_column": ["Terrain", "self", "Raise your vertical band to maximum height."],
		"double_powers": ["Inventory", "self", "Double remaining inventory except other 2x powers."],
		"beneficiary": ["Inventory", "self", "Consolidate all other allied inventories into this piece."],
		"move_again": ["Movement", "self", "After this piece moves, retain the turn for another move."],
		"move_diagonal": ["Movement", "self", "Permanently allow diagonal steps."],
		"flat_to_sphere": ["Movement", "self", "Permanently allow movement across opposite board edges."],
		"relocate": ["Position", "self", "Randomly move to an empty intact tile without an orb; retain the turn."],
		"hotspot": ["Movement", "self", "Mark your current tile as a squadron teleport destination."],
		"scavenger": ["Network", "self", "Share captured inventories with scavengers and bridges; upgrade to capture allies."],
		"power_plant": ["Network", "self", "Install an orb distribution tile and join its squadron network."],
		"network_bridge": ["Network", "self", "Receive all friendly parasite, scavenger and power plant distributions."],
		"switcheroo": ["Movement", "self", "Enable allied position swaps; second activation swaps with enemies instead of capturing."],
		"centerpult": ["Movement", "self", "Move to a vacant center with four adjacent pieces in a plus or X formation."],
		"invisible": ["Stealth", "self", "Hide this piece from the opposing view; attacks can still hit it."],
		"jump_proof": ["Defense", "self", "Prevent capture by occupation; powers still affect this piece."]
	}
	for id in singles:
		result[id] = {"name": "2x" if id == "double_powers" else id.capitalize(), "description": singles[id][2], "category": singles[id][0], "target": singles[id][1]}
	return result

static func random_int(state: Dictionary, max_exclusive: int) -> int:
	state.rng = (int(state.get("rng", 1)) * 48271) % 2147483647
	if state.rng <= 0:
		state.rng = 1
	return int(state.rng) % maxi(1, max_exclusive)

static func _piece(state: Dictionary, id: int) -> Dictionary:
	for p in state.pieces:
		if int(p.id) == id:
			return p
	return {}

static func _at(state: Dictionary, row: int, col: int) -> Dictionary:
	for p in state.pieces:
		if int(p.row) == row and int(p.col) == col:
			return p
	return {}

static func _pos(p: Dictionary) -> Dictionary:
	return {"row": int(p.row), "col": int(p.col)}

static func _area(p: Dictionary, id: String) -> Array:
	var cells: Array = []
	var grow: int = clampi(int(p.flags.get("grow_quadradius", 0)), 0, 3)
	for row in range(8):
		for col in range(10):
			var dr: int = absi(row - int(p.row))
			var dc: int = absi(col - int(p.col))
			var inside: bool = dr <= grow + 1 and dc <= grow + 1
			if id.ends_with("_row"):
				inside = dr <= grow
			elif id.ends_with("_column"):
				inside = dc <= grow
			if id.ends_with("_radial") and dr == 0 and dc == 0 and not id.begins_with("scramble_") and not id.begins_with("swap_") and not id.begins_with("kamikaze_"):
				inside = false
			if inside:
				cells.append({"row": row, "col": col})
	return cells

static func targets(state: Dictionary, piece_id: int, power_id: String) -> Array:
	var p: Dictionary = _piece(state, piece_id)
	if p.is_empty() or not catalog().has(power_id):
		return []
	if power_id == "multiply":
		var cells: Array = []
		for pos in _area(p, power_id):
			if absi(int(pos.row) - int(p.row)) > 1 or absi(int(pos.col) - int(p.col)) > 1:
				continue
			if not state.tiles[int(pos.row) * 10 + int(pos.col)].destroyed and _at(state, pos.row, pos.col).is_empty():
				cells.append(pos)
		return cells
	if power_id == "grow_quadradius" and int(p.flags.get(power_id, 0)) >= 3:
		return []
	if power_id in ["scavenger", "switcheroo"] and int(p.flags.get(power_id, 0)) >= 2:
		return []
	if power_id == "raise_tile" and int(state.tiles[int(p.row) * 10 + int(p.col)].height) >= 4:
		return []
	if power_id == "lower_tile" and int(state.tiles[int(p.row) * 10 + int(p.col)].height) <= -4:
		return []
	if power_id.ends_with("_radial") or power_id.ends_with("_row") or power_id.ends_with("_column") or power_id in ["plateau", "moat"]:
		return _area(p, power_id)
	return [_pos(p)]

static func _add_inventory(p: Dictionary, inventory: Dictionary) -> void:
	for id in inventory:
		p.inventory[id] = int(p.inventory.get(id, 0)) + int(inventory[id])

static func strip_positive(p: Dictionary) -> void:
	for key in p.flags.keys():
		if key not in NEGATIVE:
			p.flags.erase(key)

static func _kill(state: Dictionary, p: Dictionary, events: Array, cause: String) -> void:
	if p.is_empty():
		return
	state.pieces.erase(p)
	events.append({"type": "destroy", "piece_id": p.id, "cause": cause, "row": p.row, "col": p.col})

static func apply(state: Dictionary, piece_id: int, power_id: String, target: Dictionary = {}) -> Dictionary:
	var p: Dictionary = _piece(state, piece_id)
	var entries: Dictionary = catalog()
	if p.is_empty() or not entries.has(power_id):
		return {"ok": false, "events": [], "error": "Unknown piece or power"}
	var cells: Array = targets(state, piece_id, power_id)
	if cells.is_empty():
		return {"ok": false, "events": [], "error": "No legal target or upgrade limit reached"}
	if entries[power_id].target == "tile":
		if not target.has("row") or not target.has("col") or not cells.has(target):
			return {"ok": false, "events": [], "error": "Invalid target"}
	elif not target.is_empty() and not cells.has(target):
		return {"ok": false, "events": [], "error": "Invalid target"}
	var events: Array = [{"type": "power", "piece_id": piece_id, "power_id": power_id}]
	var owner: int = int(p.owner)
	var tile: Dictionary = state.tiles[int(p.row) * 10 + int(p.col)]
	match power_id:
		"multiply":
			var child: Dictionary = {"id": int(state.next_id), "owner": owner, "row": int(target.row), "col": int(target.col), "inventory": {}, "flags": {}}
			state.next_id = int(state.next_id) + 1
			state.pieces.append(child)
			events.append({"type": "multiply", "piece_id": child.id, "row": child.row, "col": child.col})
		"grow_quadradius", "scavenger", "switcheroo":
			p.flags[power_id] = int(p.flags.get(power_id, 0)) + 1
		"move_again":
			p.flags.extra_moves = int(p.flags.get("extra_moves", 0)) + 1
		"climb_tile", "move_diagonal", "flat_to_sphere", "network_bridge", "centerpult", "invisible", "jump_proof":
			p.flags[power_id] = true
		"hotspot", "power_plant":
			tile.marks[power_id] = owner
			if power_id == "power_plant":
				p.flags.power_plant = true
		"raise_tile":
			tile.height = mini(4, int(tile.height) + 1)
		"lower_tile":
			tile.height = maxi(-4, int(tile.height) - 1)
		"double_powers":
			for id in p.inventory:
				if id != "double_powers":
					p.inventory[id] = int(p.inventory[id]) * 2
		"beneficiary":
			for other in state.pieces:
				if int(other.owner) == owner and int(other.id) != piece_id:
					_add_inventory(p, other.inventory)
					other.inventory.clear()
		"relocate":
			var available: Array = _vacant(state, true)
			if available.is_empty():
				return {"ok": false, "events": [], "error": "No empty relocation tile"}
			var destination: Dictionary = available[random_int(state, available.size())]
			_displace(p, destination, events, "relocate")
		"orbic_rehash":
			var orbs: Array = []
			for t in state.tiles:
				if not str(t.orb).is_empty():
					orbs.append(t.orb)
					t.orb = ""
			var available: Array = _vacant(state, false)
			for orb in orbs:
				if available.is_empty():
					break
				var index: int = random_int(state, available.size())
				var pos: Dictionary = available.pop_at(index)
				state.tiles[int(pos.row) * 10 + int(pos.col)].orb = orb
		"bombs", "smart_bombs":
			_bombs(state, p, power_id, events)
		"snake_tunneling":
			_snake(state, p, events)
		_:
			_area_effect(state, p, power_id, cells, events)
	return {"ok": true, "events": events, "error": ""}

static func _vacant(state: Dictionary, exclude_orbs: bool) -> Array:
	var cells: Array = []
	for index in range(80):
		var tile: Dictionary = state.tiles[index]
		var row: int = index / 10
		var col: int = index % 10
		if not tile.destroyed and _at(state, row, col).is_empty() and (not exclude_orbs or str(tile.orb).is_empty()):
			cells.append({"row": row, "col": col})
	return cells

static func _displace(p: Dictionary, destination: Dictionary, events: Array, kind: String) -> void:
	var origin: Dictionary = _pos(p)
	p.row = int(destination.row)
	p.col = int(destination.col)
	if origin != destination:
		events.append({"type": kind, "piece_id": p.id, "from": origin, "to": destination.duplicate()})

static func _area_effect(state: Dictionary, p: Dictionary, id: String, cells: Array, events: Array) -> void:
	var owner: int = int(p.owner)
	var family: String = id.trim_suffix("_radial").trim_suffix("_row").trim_suffix("_column")
	var occupants: Array = []
	for pos in cells:
		var other: Dictionary = _at(state, pos.row, pos.col)
		if not other.is_empty():
			occupants.append(other)
	if family == "scramble":
		var available: Array = []
		for pos in cells:
			if not state.tiles[int(pos.row) * 10 + int(pos.col)].destroyed:
				available.append(pos)
		for other in occupants:
			var destination: Dictionary = available.pop_at(random_int(state, available.size()))
			_displace(other, destination, events, "scramble")
		return
	if family == "parasite":
		p.flags.parasite = true
	var source_inventory: Dictionary = p.inventory.duplicate(true)
	for pos in cells:
		var tile: Dictionary = state.tiles[int(pos.row) * 10 + int(pos.col)]
		var other: Dictionary = _at(state, pos.row, pos.col)
		var enemy: bool = not other.is_empty() and int(other.owner) != owner
		match family:
			"plateau", "wall":
				if not tile.destroyed:
					tile.height = 4
			"moat":
				if not tile.destroyed:
					tile.height = 4 if pos == _pos(p) else -4
			"trench":
				if not tile.destroyed:
					tile.height = -4
			"invert":
				if not tile.destroyed:
					tile.height = -int(tile.height)
			"dredge":
				if not other.is_empty():
					tile.height = -4 if enemy else 4
			"refurb":
				tile.height = 0
				tile.destroyed = false
				tile.marks.clear()
			"orb_spy":
				tile.marks.orb_spy = owner
			"bankrupt":
				if other.is_empty() and not tile.destroyed:
					tile.marks.bankrupt = owner
			"teach":
				if not other.is_empty() and not enemy and int(other.id) != int(p.id):
					_add_inventory(other, source_inventory)
			"learn", "pilfer":
				if not other.is_empty() and int(other.id) != int(p.id) and enemy == (family == "pilfer"):
					_add_inventory(p, other.inventory)
					if family == "pilfer":
						other.inventory.clear()
			"parasite":
				if enemy:
					other.flags.parasite_owner = owner
			"spyware":
				if enemy:
					other.flags.spyware = owner
			"tripwire", "inhibit":
				if enemy:
					other.flags[family] = true
			"purify":
				if not other.is_empty():
					if enemy:
						strip_positive(other)
					else:
						for key in NEGATIVE:
							other.flags.erase(key)
			"swap":
				if not other.is_empty():
					other.owner = 3 - int(other.owner)
			"recruit":
				if enemy:
					other.owner = owner
			"destroy", "acidic", "kamikaze":
				if enemy or (family == "kamikaze" and not other.is_empty()):
					_kill(state, other, events, id)
					if family == "acidic":
						tile.destroyed = true
						tile.orb = ""
						tile.marks.clear()

static func _bombs(state: Dictionary, p: Dictionary, id: String, events: Array) -> void:
	var impacts: int = 8 * (1 + int(p.flags.get("grow_quadradius", 0)))
	var owner: int = int(p.owner)
	for hit in range(impacts):
		var candidates: Array = []
		for index in range(80):
			var other: Dictionary = _at(state, index / 10, index % 10)
			if not state.tiles[index].destroyed and (id != "smart_bombs" or other.is_empty() or int(other.owner) != owner):
				candidates.append(index)
		if candidates.is_empty():
			break
		var index: int = candidates[random_int(state, candidates.size())]
		var tile: Dictionary = state.tiles[index]
		_kill(state, _at(state, index / 10, index % 10), events, id)
		if int(tile.height) <= -4:
			tile.destroyed = true
			tile.orb = ""
			tile.marks.clear()
		else:
			tile.height = int(tile.height) - 1
		events.append({"type": "impact", "row": index / 10, "col": index % 10})

static func _snake(state: Dictionary, p: Dictionary, events: Array) -> void:
	var row: int = int(p.row)
	var col: int = int(p.col)
	var owner: int = int(p.owner)
	for step in range(12 * (1 + int(p.flags.get("grow_quadradius", 0)))):
		var tile: Dictionary = state.tiles[row * 10 + col]
		if not tile.destroyed:
			tile.height = mini(4, int(tile.height) + 1)
		var other: Dictionary = _at(state, row, col)
		if not other.is_empty() and int(other.owner) != owner:
			_kill(state, other, events, "snake_tunneling")
		events.append({"type": "tunnel", "row": row, "col": col})
		var next: Array = []
		for delta in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var nr: int = row + delta.y
			var nc: int = col + delta.x
			if nr >= 0 and nr < 8 and nc >= 0 and nc < 10:
				next.append({"row": nr, "col": nc})
		var destination: Dictionary = next[random_int(state, next.size())]
		row = destination.row
		col = destination.col
