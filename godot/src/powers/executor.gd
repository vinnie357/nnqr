## executor.gd — Power executor, ported from web/src/core/powers/executor.ts.
##
## Dispatch is GENERATED from definitions by naming convention at construction:
## id "destroy_row" → effects.activate_destroy_row. A construction-time assert
## confirms every definition resolves to a handler.
##
## Overrides handle powers that need target-piece resolution (recruit, switcheroo).
## Secondary actions handle powers with target forwarding
## (hotspot_teleport, multiply, raise_tile, lower_tile, refurb, centerpult).
##
## Usage:
##   const Executor = preload("res://src/powers/executor.gd")
##   var executor = Executor.new()
##   var new_state = executor.execute(state, piece, "destroy_row")
extends RefCounted

const GameState = preload("res://src/game_state.gd")
const Definitions = preload("res://src/powers/definitions.gd")
const Effects = preload("res://src/powers/effects.gd")

# The dispatch table: power_id -> Callable(state, piece, target?) -> GameState
var _dispatch: Dictionary = {}
var _effects: Effects


func _init() -> void:
	_effects = Effects.new()
	_build_dispatch()


## Convert snake_case power id to activate_* method name.
## e.g. "destroy_row" -> "activate_destroy_row"
static func _handler_name(id: String) -> String:
	return "activate_" + id


## Build the dispatch table from all 82 definitions.
func _build_dispatch() -> void:
	var all_ids := Definitions.all_ids()

	# Overrides — powers that need target-piece resolution
	var overrides: Dictionary = {
		"recruit": func(state: GameState, piece: GameState.Piece, target) -> GameState:
			if target == null:
				return state
			var t_row: int = target.get("row") if target is Dictionary else -1
			var t_col: int = target.get("col") if target is Dictionary else -1
			if t_row < 0 or t_col < 0:
				return state
			var target_piece: GameState.Piece = null
			for p: GameState.Piece in state.pieces:
				if p.row == t_row and p.col == t_col:
					target_piece = p
					break
			if target_piece == null:
				return state
			return _effects.activate_recruit(state, piece, target_piece),

		"switcheroo": func(state: GameState, piece: GameState.Piece, target) -> GameState:
			if target == null:
				return state
			var t_row: int = target.get("row") if target is Dictionary else -1
			var t_col: int = target.get("col") if target is Dictionary else -1
			if t_row < 0 or t_col < 0:
				return state
			var target_piece: GameState.Piece = null
			for p: GameState.Piece in state.pieces:
				if p.row == t_row and p.col == t_col:
					target_piece = p
					break
			if target_piece == null:
				return state
			return _effects.activate_switcheroo(state, piece, target_piece),
	}

	# Secondary actions — powers with target forwarding
	var secondary_actions: Dictionary = {
		"hotspot_teleport": func(state: GameState, piece: GameState.Piece, target) -> GameState:
			var t: Dictionary = target if target is Dictionary else {"row": piece.row, "col": piece.col}
			return _effects.activate_hotspot_teleport(state, piece, t),

		"multiply": func(state: GameState, piece: GameState.Piece, target) -> GameState:
			var t: Dictionary = target if target is Dictionary else {"row": piece.row, "col": piece.col}
			return _effects.activate_multiply(state, piece, t),

		"raise_tile": func(state: GameState, piece: GameState.Piece, target) -> GameState:
			var t: Dictionary = target if target is Dictionary else {"row": piece.row, "col": piece.col}
			return _effects.activate_raise_tile(state, piece, t),

		"lower_tile": func(state: GameState, piece: GameState.Piece, target) -> GameState:
			var t: Dictionary = target if target is Dictionary else {"row": piece.row, "col": piece.col}
			return _effects.activate_lower_tile(state, piece, t),

		"refurb": func(state: GameState, piece: GameState.Piece, target) -> GameState:
			return _effects.activate_refurb(state, piece, target),

		"centerpult": func(state: GameState, piece: GameState.Piece, target) -> GameState:
			return _effects.activate_centerpult(state, piece, target),
	}

	# Build dispatch for each definition id
	for id in all_ids:
		if overrides.has(id):
			_dispatch[id] = overrides[id]
			continue
		if secondary_actions.has(id):
			_dispatch[id] = secondary_actions[id]
			continue
		var fn_name := _handler_name(id)
		if not _effects.has_method(fn_name):
			push_error("PowerExecutor: power '%s' has no effect function %s" % [id, fn_name])
			assert(false, "PowerExecutor: missing handler for '%s' (effects.%s)" % [id, fn_name])
		# Wrap in lambda to normalize 3-arg call signature (state, piece, target=null)
		var fn_name_captured := fn_name
		_dispatch[id] = func(state: GameState, piece: GameState.Piece, _target) -> GameState:
			return _effects.call(fn_name_captured, state, piece)

	# Register secondary actions not in definitions (e.g. hotspot_teleport)
	for id in secondary_actions.keys():
		if not _dispatch.has(id):
			_dispatch[id] = secondary_actions[id]


## Execute a power's game logic. Returns unchanged state for unknown powers.
func execute(state: GameState, piece: GameState.Piece, power_id: String, target = null) -> GameState:
	if not _dispatch.has(power_id):
		return state
	var handler: Callable = _dispatch[power_id]
	return handler.call(state, piece, target)


## Whether a power id resolves to a registered handler.
func is_registered(power_id: String) -> bool:
	return _dispatch.has(power_id)


## All registered dispatch ids (defined powers + secondary actions).
func registered_ids() -> Array:
	return _dispatch.keys()
