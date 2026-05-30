## controller.gd — Pure game-flow logic for NNQR.
## No input or render dependencies — fully unit-testable.
##
## handle_tile_click: selection → move flow (mirrors web/src/game/controller.ts).
## activate_power: routes through executor; returns a result dict with
##   "state" (GameState), "mode" (MODE_NORMAL or MODE_AWAITING_TARGET),
##   and "target_tiles" (Array, non-empty when mode == MODE_AWAITING_TARGET).
## ai_take_turn: calls ai.choose_move and applies the result.
##
## Mode constants:
##   Controller.MODE_NORMAL           — normal play
##   Controller.MODE_AWAITING_TARGET  — waiting for player to click a target tile
extends RefCounted

const Board    = preload("res://src/board.gd")
const GameState = preload("res://src/game_state.gd")
const Executor = preload("res://src/powers/executor.gd")
const Targets  = preload("res://src/powers/targets.gd")
const AI       = preload("res://src/ai/ai.gd")
const Orbs     = preload("res://src/orbs.gd")
const Rng      = preload("res://src/rng.gd")
const Defs     = preload("res://src/powers/definitions.gd")

## Mode values returned by activate_power.
const MODE_NORMAL           : String = "normal"
const MODE_AWAITING_TARGET  : String = "awaiting_target"


# ---------------------------------------------------------------------------
# handle_tile_click
# ---------------------------------------------------------------------------

## Handle a board tile click during the current player's turn.
##
## Flow (mirrors web controller.ts handleTileClick / applyMove):
##   1. If game is over, return state unchanged.
##   2. If a valid move is selected and the click is on a valid move tile → move,
##      then collect any orb at the destination, check overheat, and spawn orbs.
##   3. Otherwise → (re)select or deselect via board.select_piece.
##
## Returns a new GameState (immutable pattern — never mutates input).
static func handle_tile_click(state: GameState, row: int, col: int) -> GameState:
	if state.status != "playing":
		return state

	# If a piece is selected and the clicked tile is a valid move, execute the move.
	if state.selected != null:
		for m: Dictionary in state.valid_moves:
			if m.row == row and m.col == col:
				return _apply_move(state, row, col)

	# Otherwise (re)select: board.select_piece handles empty tiles, enemy pieces,
	# and clicking the same tile (clears selection).
	return Board.select_piece(state, row, col)


# ---------------------------------------------------------------------------
# activate_power
# ---------------------------------------------------------------------------

## Activate a power for `piece` on `state`.
##
## If the power needs a target and no target is provided:
##   Returns {"state": state, "mode": MODE_AWAITING_TARGET, "target_tiles": Array}.
##   The caller should highlight target_tiles and call activate_power again with
##   the chosen tile once the player clicks.
##
## If the power needs a target and a valid target is provided, or if the power
## is immediate (no target needed):
##   Returns {"state": <new_state>, "mode": MODE_NORMAL, "target_tiles": []}.
##
## `target` is a {"row":int, "col":int} Dictionary or null.
static func activate_power(
		state: GameState,
		piece: GameState.Piece,
		power_id: String,
		target) -> Dictionary:   # -> {"state":GameState, "mode":String, "target_tiles":Array}

	if Targets.needs_target(power_id) and target == null:
		var tiles: Array = Targets.get_target_tiles(state, piece, power_id)
		return {
			"state": state,
			"mode": MODE_AWAITING_TARGET,
			"target_tiles": tiles,
		}

	# Execute the power (with or without a target).
	var executor := Executor.new()
	var new_state: GameState = executor.execute(state, piece, power_id, target)
	return {
		"state": new_state,
		"mode": MODE_NORMAL,
		"target_tiles": [],
	}


# ---------------------------------------------------------------------------
# ai_take_turn
# ---------------------------------------------------------------------------

## Apply the AI's move for the current player in `state`.
##
## Calls AI.choose_move, then board.select_piece + board.move_to.
## After the move: collects any orb at the destination, checks overheat,
## and spawns orbs on the turn interval (mirrors web runAiTurn).
## If no move is available (no legal moves), returns the state unchanged.
##
## @param state      Current game state (AI player must be current_player).
## @param difficulty "easy" | "medium" | "hard" | "expert"
## @param rng        Seeded RNG instance from rng.gd.
## @returns New GameState after the AI move, or original state if no move found.
static func ai_take_turn(state: GameState, difficulty: String, rng: Object) -> GameState:
	if state.status != "playing":
		return state

	var decision = AI.choose_move(state, state.current_player, difficulty, rng)
	if decision == null:
		return state

	var piece: GameState.Piece = decision["piece"]
	var move: Dictionary = decision["move"]

	# Select the piece (populates valid_moves in the intermediate state)
	var mid: GameState = Board.select_piece(state, piece.row, piece.col)
	# Apply the move
	var next: GameState = Board.move_to(mid, move.row, move.col)

	# Collect orb at destination (mirrors web runAiTurn).
	var orb_result: Dictionary = Orbs.collect_orb(next, move.row, move.col)
	if orb_result["collected"] != null:
		next = orb_result["state"]
		# Check overheat: ≥10 of same power destroys the piece.
		var updated: GameState.Piece = null
		for p: GameState.Piece in next.pieces:
			if p.id == piece.id:
				updated = p
				break
		if updated != null:
			var overheat_id: String = Targets.overheat_power(updated)
			if overheat_id != "":
				var surviving: Array = []
				for p: GameState.Piece in next.pieces:
					if p.id != piece.id:
						surviving.append(p)
				var pruned := _copy_state(next)
				pruned.pieces = surviving
				next = pruned

	# Spawn orbs on turn boundary (mirrors web shouldSpawnOrbs / spawnOrbs).
	if Orbs.should_spawn_orbs(next.turn):
		var spawn_rng := Rng.new(next.seed + next.turn)
		next = Orbs.spawn_orbs(next, Defs.all_ids(), spawn_rng)

	return next


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

## Apply a validated move: move_to, collect orb, check overheat, spawn orbs.
## Mirrors web controller.ts applyMove.
static func _apply_move(state: GameState, row: int, col: int) -> GameState:
	# Capture moving piece id before the move.
	var moving_piece_id: String = ""
	if state.selected != null:
		for p: GameState.Piece in state.pieces:
			if p.row == state.selected.row and p.col == state.selected.col:
				moving_piece_id = p.id
				break

	var next: GameState = Board.move_to(state, row, col)

	# Collect orb at destination.
	if moving_piece_id != "":
		var orb_result: Dictionary = Orbs.collect_orb(next, row, col)
		if orb_result["collected"] != null:
			next = orb_result["state"]
			# Check overheat: ≥10 of same power destroys the piece.
			var moved_piece: GameState.Piece = null
			for p: GameState.Piece in next.pieces:
				if p.id == moving_piece_id:
					moved_piece = p
					break
			if moved_piece != null:
				var overheat_id: String = Targets.overheat_power(moved_piece)
				if overheat_id != "":
					var surviving: Array = []
					for p: GameState.Piece in next.pieces:
						if p.id != moving_piece_id:
							surviving.append(p)
					var pruned := _copy_state(next)
					pruned.pieces = surviving
					next = pruned

	# Spawn orbs on turn boundary.
	if Orbs.should_spawn_orbs(next.turn):
		var spawn_rng := Rng.new(next.seed + next.turn)
		next = Orbs.spawn_orbs(next, Defs.all_ids(), spawn_rng)

	return next


## Shallow copy a GameState (same pattern as orbs.gd _copy_state).
static func _copy_state(src: GameState) -> GameState:
	var dst := GameState.new()
	dst.cols = src.cols
	dst.rows = src.rows
	dst.current_player = src.current_player
	dst.turn = src.turn
	dst.status = src.status
	dst.winner = src.winner
	dst.seed = src.seed
	dst.pieces = src.pieces
	dst.height_map = src.height_map
	dst.destroyed_tiles = src.destroyed_tiles
	dst.orbs = src.orbs
	dst.selected = src.selected
	dst.valid_moves = src.valid_moves
	return dst
