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
## Note: Board.select_piece uses board.gd's _copy_state which does not copy
## Object metas.  We manually re-attach the extended-state metas onto the
## selection result so _apply_move can still read them on the subsequent move
## click.  Extended state metas propagated: extra_move, bankrupt_tiles,
## hotspot_tiles, multiplied_pieces.
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
	var selected_state: GameState = Board.select_piece(state, row, col)

	# Re-propagate extended-state metas across the selection boundary.
	# Board._copy_state does not copy metas, so power-set flags would be
	# silently dropped on the selection step.  Re-attach them here so
	# _apply_move can read them on the next click.
	for key in ["extra_move", "bankrupt_tiles", "hotspot_tiles", "multiplied_pieces"]:
		if state.has_meta(key):
			selected_state.set_meta(key, state.get_meta(key))

	return selected_state


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
##
## Power flags read from PRE-move state (before Board.move_to strips metas):
##   extra_move     — same player moves again (already wired)
##   is_tripwired   — mover is destroyed after completing the move
##   is_scavenger   — mover inherits captured enemy's powers
##   is_inhibited   — mover cannot collect orbs this move
##   parasitized_by — parasitizer also receives any orb the mover collects
##   bankrupt_tiles — destination tile strips mover's powers + buff flags
##
## These flags live on pieces/state in the PRE-move GameState and are NOT
## copied by Board.move_to (Board._copy_state does not propagate Object metas),
## so we capture them BEFORE calling Board.move_to.
static func _apply_move(state: GameState, row: int, col: int) -> GameState:
	# Capture the mover's player and extra_move flag BEFORE the move.
	var mover_player: int = state.current_player
	var had_extra: bool = state.has_meta("extra_move") and bool(state.get_meta("extra_move"))

	# Capture moving piece id and pre-move meta flags BEFORE Board.move_to.
	var moving_piece_id: String = ""
	var mover_is_tripwired: bool = false
	var mover_is_scavenger: bool = false
	var mover_is_inhibited: bool = false
	var mover_parasitized_by: String = ""       # "" means not parasitized
	var captured_enemy_powers: Array = []        # powers of the enemy at (row,col)

	if state.selected != null:
		for p: GameState.Piece in state.pieces:
			if p.row == state.selected.row and p.col == state.selected.col:
				moving_piece_id = p.id
				mover_is_tripwired   = p.has_meta("is_tripwired") and bool(p.get_meta("is_tripwired"))
				mover_is_scavenger   = p.has_meta("is_scavenger") and bool(p.get_meta("is_scavenger"))
				mover_is_inhibited   = p.has_meta("is_inhibited") and bool(p.get_meta("is_inhibited"))
				if p.has_meta("parasitized_by"):
					mover_parasitized_by = str(p.get_meta("parasitized_by"))
				break

	# Capture enemy powers at the destination tile (for scavenger).
	# Only relevant when the move is a capture (enemy present).
	if mover_is_scavenger:
		for p: GameState.Piece in state.pieces:
			if p.row == row and p.col == col and p.player != state.current_player:
				captured_enemy_powers = p.powers.duplicate()
				break

	# Capture bankrupt_tiles from the pre-move state (propagated through
	# handle_tile_click's extended-meta re-propagation).
	var bankrupt_tiles: Dictionary = {}
	if state.has_meta("bankrupt_tiles"):
		bankrupt_tiles = state.get_meta("bankrupt_tiles") as Dictionary

	var next: GameState = Board.move_to(state, row, col)

	# --- Post-move: scavenger — inherit captured enemy's powers.
	if mover_is_scavenger and moving_piece_id != "" and captured_enemy_powers.size() > 0:
		var new_pieces: Array = []
		for p: GameState.Piece in next.pieces:
			if p.id == moving_piece_id:
				var np := GameState.Piece.new(p.id, p.player, p.row, p.col)
				np.powers = p.powers.duplicate()
				for pw in captured_enemy_powers:
					np.powers.append(pw)
				np.is_jump_proof       = p.is_jump_proof
				np.can_move_diagonally = p.can_move_diagonally
				np.can_climb_any       = p.can_climb_any
				np.can_wrap            = p.can_wrap
				np.is_invisible        = p.is_invisible
				np.set_meta("is_scavenger", true)   # re-propagate flag
				new_pieces.append(np)
			else:
				new_pieces.append(p)
		var scav_state := _copy_state(next)
		scav_state.pieces = new_pieces
		next = scav_state

	# Collect orb at destination (inhibited pieces skip this).
	if moving_piece_id != "" and not mover_is_inhibited:
		var orb_result: Dictionary = Orbs.collect_orb(next, row, col)
		if orb_result["collected"] != null:
			next = orb_result["state"]
			var collected_power: String = orb_result["collected"]

			# --- Parasite: parasitizer also receives a copy of the collected power.
			if mover_parasitized_by != "":
				var new_pieces2: Array = []
				for p: GameState.Piece in next.pieces:
					if p.id == mover_parasitized_by:
						var np := GameState.Piece.new(p.id, p.player, p.row, p.col)
						np.powers = p.powers.duplicate()
						np.powers.append(collected_power)
						np.is_jump_proof       = p.is_jump_proof
						np.can_move_diagonally = p.can_move_diagonally
						np.can_climb_any       = p.can_climb_any
						np.can_wrap            = p.can_wrap
						np.is_invisible        = p.is_invisible
						new_pieces2.append(np)
					else:
						new_pieces2.append(p)
				var par_state := _copy_state(next)
				par_state.pieces = new_pieces2
				next = par_state

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

	# --- Post-move: bankrupt tile — strip powers and positive flags from mover.
	var dest_key: String = "%d,%d" % [row, col]
	if moving_piece_id != "" and bankrupt_tiles.get(dest_key, false) == true:
		var new_pieces3: Array = []
		for p: GameState.Piece in next.pieces:
			if p.id == moving_piece_id:
				var np := GameState.Piece.new(p.id, p.player, p.row, p.col)
				np.powers = []                  # strip all powers
				np.is_jump_proof       = false  # strip positive flags
				np.can_move_diagonally = false
				np.can_climb_any       = false
				np.can_wrap            = false
				np.is_invisible        = false
				# Debuff flags (is_inhibited, is_tripwired, etc.) are NOT cleared —
				# bankrupt removes positive capabilities only (per documented semantics).
				new_pieces3.append(np)
			else:
				new_pieces3.append(p)
		var bk_state := _copy_state(next)
		bk_state.pieces = new_pieces3
		next = bk_state

	# --- Post-move: tripwire — destroy the mover after completing the move.
	# The mover's is_tripwired flag was set by the opponent; the piece is
	# destroyed when it moves (any move, not just captures).
	if mover_is_tripwired and moving_piece_id != "":
		var surviving: Array = []
		for p: GameState.Piece in next.pieces:
			if p.id != moving_piece_id:
				surviving.append(p)
		var tw_state := _copy_state(next)
		tw_state.pieces = surviving
		# Re-check winner (tripwire may have ended the game).
		var winner := Board.check_winner(tw_state)
		if winner != 0:
			tw_state.status = "won"
			tw_state.winner = winner
		next = tw_state

	# Spawn orbs on turn boundary.
	if Orbs.should_spawn_orbs(next.turn):
		var spawn_rng := Rng.new(next.seed + next.turn)
		next = Orbs.spawn_orbs(next, Defs.all_ids(), spawn_rng)

	# Consume extra_move: if the pre-move state had it set AND the game is
	# still in progress, restore current_player to the mover so they move
	# again.  The flag does not carry forward into `next` (fresh state from
	# Board.move_to), so no explicit clear is needed.
	if had_extra and next.status == "playing":
		var unlocked := _copy_state(next)
		unlocked.current_player = mover_player
		next = unlocked

	return next


## Shallow copy a GameState, propagating extended-state metas.
## Mirrors effects.gd _copy_state meta propagation.
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
	# Propagate extended-state metas (same list as effects.gd line 46).
	for key in ["extra_move", "bankrupt_tiles", "hotspot_tiles", "multiplied_pieces"]:
		if src.has_meta(key):
			dst.set_meta(key, src.get_meta(key))
	return dst
