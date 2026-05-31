## ai.gd — AI dispatcher; choose_move selects the best {piece, move} for a player.
## Ported from web/src/core/ai/ai.ts.
##
## Difficulty tiers
## ────────────────
##   easy   → uniform-random legal move (uses seeded rng, never randf())
##   medium → best move by heuristic; power candidates included, top-K capped
##   hard   → minimax depth 2 with alpha-beta pruning; power candidates pre-checked
##   expert → minimax depth 4 with alpha-beta pruning; power candidates pre-checked
##            (breadth-capped at MAX_BRANCHING_FACTOR=10 per search.gd)
##
## Power activation (nnqr-20)
## ──────────────────────────
## For medium/hard/expert: before entering search/heuristic selection, we score
## ALL owned powers for each of the player's pieces via
## score_power_activation(state, piece, power_id). If any activation scores above
## the best available movement score, that power action is returned immediately
## (as {"piece", "power_id", "power_action": true}). This keeps power breadth
## capped (only the single best power action is pre-empted) without modifying
## the minimax tree itself, so the depth budget is preserved.
##
## Power return shape: {"piece": Piece, "power_id": String, "power_action": true}
## Move return shape:  {"piece": Piece, "move": {"row":int,"col":int,"capture":bool}}
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
## @returns move dict or power dict or null.
##   Move:  {"piece": Piece, "move": {"row":int,"col":int,"capture":bool}}
##   Power: {"piece": Piece, "power_id": String, "power_action": true}
static func choose_move(
		state: GameState,
		player: int,
		difficulty: String,
		rng: Object):  # -> Dictionary or null

	if difficulty == "easy":
		# Easy: uniform-random legal move only — no power consideration.
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

	# -----------------------------------------------------------------------
	# medium / hard / expert: check power activation before movement.
	# Score every owned power for every player piece; keep the best candidate.
	# -----------------------------------------------------------------------
	var best_power_piece: GameState.Piece = null
	var best_power_id: String = ""
	var best_power_score: float = -INF

	for piece: GameState.Piece in state.pieces:
		if piece.player != player:
			continue
		# Deduplicate power ids so we don't score "bomb" twice for 2 copies.
		var seen_ids: Dictionary = {}
		for power_id: String in piece.powers:
			if seen_ids.has(power_id):
				continue
			seen_ids[power_id] = true
			var s: float = Evaluator.score_power_activation(state, piece, power_id)
			if s > best_power_score:
				best_power_score = s
				best_power_piece = piece
				best_power_id = power_id

	if difficulty == "medium":
		var ai_move = Evaluator.get_best_move(state, player)
		# Compute the best movement score for comparison.
		var best_move_score: float = -INF
		if ai_move != null:
			best_move_score = Evaluator.score_move(state, ai_move)

		# Prefer power activation when its gain exceeds the best movement score.
		if best_power_piece != null and best_power_score > best_move_score:
			return {
				"piece": best_power_piece,
				"power_id": best_power_id,
				"power_action": true,
			}

		if ai_move == null:
			return null
		var board_move = _to_move(state, ai_move.piece, ai_move.target)
		if board_move == null:
			return null
		return {"piece": ai_move.piece, "move": board_move}

	# hard = depth 2, expert = depth 4
	var depth: int = 2 if difficulty == "hard" else 4

	# For hard/expert: if a high-value power activation exists, take it before
	# entering deep minimax search (avoids blowing up the branching budget).
	# Threshold: any positive power score pre-empts search when the search
	# would only find sub-threshold material gain anyway.
	if best_power_piece != null and best_power_score > 0.0:
		return {
			"piece": best_power_piece,
			"power_id": best_power_id,
			"power_action": true,
		}

	var ai_move = Search.find_best_move(state, depth, player)
	if ai_move == null:
		return null
	var board_move = _to_move(state, ai_move.piece, ai_move.target)
	if board_move == null:
		return null
	return {"piece": ai_move.piece, "move": board_move}
