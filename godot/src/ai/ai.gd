## ai.gd — AI dispatcher; choose_move selects the best {piece, move} for a player.
## Ported from web/src/core/ai/ai.ts.
##
## Difficulty tiers
## ────────────────
##   easy   → uniform-random legal move (uses seeded rng, never randf())
##   medium → best move by heuristic evaluate_board / score_move
##   hard   → minimax depth 2 with alpha-beta pruning
##   expert → minimax depth 4 with alpha-beta pruning
##            (breadth-capped at MAX_BRANCHING_FACTOR=10 per search.gd)
##
## POWER-ACTIVATION SEAM
## ─────────────────────
## Power activations are NOT included in the action set yet — the powers module
## is being built in parallel. When it lands, extend the candidate set here
## with power-activation actions and score them via score_power_activation
## from evaluator.gd. The seam is marked with the comment "# POWER SEAM"
## below and in evaluator.gd.
extends RefCounted

const Board = preload("res://src/board.gd")
const GameState = preload("res://src/game_state.gd")
const Evaluator = preload("res://src/ai/evaluator.gd")
const Search = preload("res://src/ai/search.gd")

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

## Convert an AiMove ({piece, target}) back to the Move shape used by the board
## contract ({row, col, capture}). Returns null if the target is not legal.
static func _to_move(
		state: GameState, piece: GameState.Piece, target: Dictionary):  # -> Dictionary or null
	var legal: Array = Board.get_valid_moves(state, piece)
	for m: Dictionary in legal:
		if m.row == target.row and m.col == target.col:
			return m
	return null

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Choose an action for `player` at the given `difficulty`.
##
## @param state      Current (immutable) game state
## @param player     The AI player (1 or 2)
## @param difficulty "easy" | "medium" | "hard" | "expert"
## @param rng        Seeded RNG — used for random tie-breaks and easy selection.
##                   Pass RNG.new(seed) from rng.gd; never use randf().
## @returns {"piece": Piece, "move": {"row":int,"col":int,"capture":bool}} or null
static func choose_move(
		state: GameState,
		player: int,
		difficulty: String,
		rng: Object):  # -> Dictionary or null

	# POWER SEAM: before building the move candidate set, gather power-activation
	# candidates for each of the player's pieces and score them via
	# score_power_activation(state, piece, power_id). If any activation scores
	# above the best movement score, return it as the decision instead.
	# Example skeleton (not active until powers module lands):
	#
	#   for piece in state.pieces.filter(func(p): return p.player == player):
	#     for power_id in piece.powers:
	#       var activation_score = Evaluator.score_power_activation(state, piece, power_id)
	#       if activation_score > threshold: ... return power_decision
	#
	# The Evaluator.score_power_activation reference is kept live so GDScript
	# confirms the seam compiles correctly even before the body is filled in.
	var _seam_ref = Evaluator.score_power_activation  # acknowledge import until powers module lands

	if difficulty == "easy":
		var moves: Array = Evaluator.get_all_moves(state, player)
		if moves.size() == 0:
			return null
		var chosen = rng.pick(moves)
		if chosen == null:
			return null
		var board_move = _to_move(state, chosen.piece, chosen.target)
		if board_move == null:
			return null
		return {"piece": chosen.piece, "move": board_move}

	if difficulty == "medium":
		var ai_move = Evaluator.get_best_move(state, player)
		if ai_move == null:
			return null
		var board_move = _to_move(state, ai_move.piece, ai_move.target)
		if board_move == null:
			return null
		return {"piece": ai_move.piece, "move": board_move}

	# hard = depth 2, expert = depth 4
	var depth: int = 2 if difficulty == "hard" else 4
	var ai_move = Search.find_best_move(state, depth, player)
	if ai_move == null:
		return null
	var board_move = _to_move(state, ai_move.piece, ai_move.target)
	if board_move == null:
		return null
	return {"piece": ai_move.piece, "move": board_move}
