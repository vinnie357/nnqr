## targets.gd — Power target resolution, ported from web/src/core/powers/targets.ts.
##
## Game-logic helpers only. Renderer color helpers belong to C4.
##
## Usage:
##   const Targets = preload("res://src/powers/targets.gd")
##   var tiles = Targets.get_target_tiles(state, piece, "raise_tile")
##   if Targets.needs_target("recruit"): ...
extends RefCounted

const GameState = preload("res://src/game_state.gd")
const Board = preload("res://src/board.gd")

const ADJACENT: Array = [[-1, 0], [1, 0], [0, -1], [0, 1]]
const ADJACENT8: Array = [
	[-1, -1], [-1, 0], [-1, 1],
	[0, -1],           [0, 1],
	[1, -1],  [1, 0],  [1, 1],
]

const NEEDS_TARGET_SET: Array = [
	"raise_tile", "lower_tile", "switcheroo", "recruit",
	"multiply", "refurb", "centerpult", "hotspot",
]


## Returns adjacent 4-directional tiles that are in bounds.
static func _adj_tiles(piece: GameState.Piece) -> Array:
	var result: Array = []
	for d in ADJACENT:
		var dr: int = d[0]
		var dc: int = d[1]
		var r := piece.row + dr
		var c := piece.col + dc
		if Board.in_bounds(r, c):
			result.append({"row": r, "col": c})
	return result


## Returns adjacent 8-directional tiles that are in bounds.
static func _adj8_tiles(piece: GameState.Piece) -> Array:
	var result: Array = []
	for d in ADJACENT8:
		var dr: int = d[0]
		var dc: int = d[1]
		var r := piece.row + dr
		var c := piece.col + dc
		if Board.in_bounds(r, c):
			result.append({"row": r, "col": c})
	return result


## Returns valid target tiles for a power that requires a target click.
## Powers without an entry here (immediate powers) return [].
static func get_target_tiles(state: GameState, piece: GameState.Piece, power_id: String) -> Array:
	match power_id:
		"raise_tile", "lower_tile":
			var result: Array = []
			for t in _adj_tiles(piece):
				if not Board.is_destroyed(state, t.row, t.col):
					result.append(t)
			return result

		"switcheroo":
			var result: Array = []
			for t in _adj_tiles(piece):
				if Board.piece_at(state, t.row, t.col) != null:
					result.append(t)
			return result

		"recruit":
			var result: Array = []
			for t in _adj8_tiles(piece):
				var p := Board.piece_at(state, t.row, t.col)
				if p != null and p.player != piece.player:
					result.append(t)
			return result

		"multiply":
			var result: Array = []
			for t in _adj_tiles(piece):
				if not Board.is_destroyed(state, t.row, t.col) and Board.piece_at(state, t.row, t.col) == null:
					result.append(t)
			return result

		"refurb":
			var result: Array = []
			for t in _adj_tiles(piece):
				if Board.is_destroyed(state, t.row, t.col):
					result.append(t)
			return result

		"centerpult":
			var targets: Array = []
			var seen: Dictionary = {}
			for r in range(1, state.rows):
				for c in range(1, state.cols):
					var corners := [
						{"row": r, "col": c},
						{"row": r, "col": c + 1},
						{"row": r + 1, "col": c},
						{"row": r + 1, "col": c + 1},
					]
					var all_occupied := true
					for corner in corners:
						if Board.piece_at(state, corner.row, corner.col) == null:
							all_occupied = false
							break
					if all_occupied:
						for corner in corners:
							var key := "%d,%d" % [corner.row, corner.col]
							if not seen.has(key):
								seen[key] = true
								targets.append(corner)
			return targets

		"hotspot":
			var hotspot_tiles = state.get_meta("hotspot_tiles", null)
			if hotspot_tiles == null:
				return []
			var result: Array = []
			for key in hotspot_tiles.keys():
				if hotspot_tiles[key] == piece.player:
					var parts := (key as String).split(",")
					if parts.size() == 2:
						var r := parts[0].to_int()
						var c := parts[1].to_int()
						if Board.in_bounds(r, c):
							result.append({"row": r, "col": c})
			return result

		_:
			return []


## Returns true when this power needs the player to click a target tile/piece
## before execution.
static func needs_target(power_id: String) -> bool:
	return NEEDS_TARGET_SET.has(power_id)


## Count occurrences of each power id in a piece's inventory.
## Returns a Dictionary {power_id: count}.
static func power_counts(piece: GameState.Piece) -> Dictionary:
	var counts: Dictionary = {}
	for id in piece.powers:
		var n: int = counts.get(id) if counts.has(id) else 0
		counts[id] = n + 1
	return counts


## Returns the power id that has 10+ copies in the piece's inventory,
## or "" (empty string) if none.
static func overheat_power(piece: GameState.Piece) -> String:
	var counts := power_counts(piece)
	for id in counts.keys():
		if counts[id] >= 10:
			return id
	return ""
