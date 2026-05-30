## evaluator.gd — AI heuristic board scoring.
## Ported from web/src/core/ai/evaluator.ts.
##
## POWER-ACTIVATION SEAM
## ─────────────────────
## The evaluator currently scores only piece *moves* (position, capture, orb).
## When the powers module is ready, power activation candidates should be added
## to the action set at the call site in ai.gd (see the comment "POWER SEAM"
## there). Here, the relevant hook surface is score_power_activation:
##
##   score_power_activation(state: GameState, piece: Piece, power_id: String) -> float
##
## Implement it to return the expected gain of activating power_id for piece
## in state (positive = beneficial). The signature is intentionally left as a
## stub so the powers module author can drop in the implementation without
## touching search.gd or ai.gd.
extends RefCounted

const Board = preload("res://src/board.gd")
const GameState = preload("res://src/game_state.gd")
const Height = preload("res://src/height.gd")

# ---------------------------------------------------------------------------
# Scoring weights (direct port of TS WEIGHTS table)
# ---------------------------------------------------------------------------

const WEIGHTS := {
	"CENTER_BONUS": 10.0,
	"HEIGHT_BONUS": 5.0,
	"POWER_BONUS": 8.0,
	"JUMP_PROOF_BONUS": 15.0,
	"DIAGONAL_BONUS": 10.0,
	"ORB_BASE_VALUE": 15.0,
	"CAPTURE_BONUS": 50.0,
	"CAPTURE_VALUE_MULT": 2.0,
	"THREAT_PENALTY": 30.0,
	"POSITION_WEIGHT": 1.0,
	"RISKY_ORB_PENALTY": 20.0,
	"PIECE_VALUE": 100.0,
	"WIN_BONUS": 10000.0,
}

# Power value scores for orb collection priority
const POWER_VALUES := {
	"bomb": 25.0,
	"destroy_row": 20.0,
	"destroy_column": 20.0,
	"recruit": 22.0,
	"jump_proof": 18.0,
	"move_diagonal": 15.0,
	"move_again": 12.0,
	"relocate": 10.0,
	"raise_tile": 8.0,
	"lower_tile": 8.0,
	"multiply": 18.0,
	"invisible": 12.0,
	"refurb": 6.0,
}

# Board centre coordinates (1-based, fractional for even dimensions)
const CENTER_ROW: float = (8.0 + 1.0) / 2.0  # 4.5
const CENTER_COL: float = (10.0 + 1.0) / 2.0  # 5.5
const MAX_DIST: float = 6.519613  # sqrt(4.5^2 + 5.5^2)

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

## Score a board tile by its centrality and height. Returns 0 for destroyed tiles.
static func _score_position(state: GameState, row: int, col: int) -> float:
	if state.destroyed_tiles.has("%d,%d" % [row, col]):
		return 0.0
	var dr: float = float(row) - CENTER_ROW
	var dc: float = float(col) - CENTER_COL
	var dist_from_center: float = sqrt(dr * dr + dc * dc)
	var center_factor: float = 1.0 - dist_from_center / MAX_DIST
	var height_val: float = float(Height.get_height(state.height_map, row, col))
	return center_factor * WEIGHTS.CENTER_BONUS + height_val * WEIGHTS.HEIGHT_BONUS


## Score a piece's position including power inventory and flag bonuses.
static func _score_piece_position(state: GameState, piece: GameState.Piece) -> float:
	var score: float = _score_position(state, piece.row, piece.col)
	score += float(piece.powers.size()) * WEIGHTS.POWER_BONUS
	if piece.is_jump_proof:
		score += WEIGHTS.JUMP_PROOF_BONUS
	if piece.can_move_diagonally:
		score += WEIGHTS.DIAGONAL_BONUS
	return score


## True if an enemy can reach `target` on their next move.
static func _is_orb_collection_risky(
		state: GameState, player: int, target_row: int, target_col: int) -> bool:
	var opponent: int = 2 if player == 1 else 1
	for enemy: GameState.Piece in state.pieces:
		if enemy.player != opponent:
			continue
		for move: Dictionary in Board.get_valid_moves(state, enemy):
			if move.row == target_row and move.col == target_col:
				return true
	return false


## Score an orb's value (power-specific or base).
static func _score_orb_value(orb: Dictionary) -> float:
	var pid: String = orb.get("power_id", "")
	if POWER_VALUES.has(pid):
		return POWER_VALUES[pid]
	return WEIGHTS.ORB_BASE_VALUE

# ---------------------------------------------------------------------------
# Public API — AiMove dict format: {"piece": Piece, "target": {"row":int,"col":int}}
# ---------------------------------------------------------------------------

## All legal moves for `player` as AiMove dicts.
static func get_all_moves(state: GameState, player: int) -> Array:
	var moves: Array = []
	for piece: GameState.Piece in state.pieces:
		if piece.player != player:
			continue
		for m: Dictionary in Board.get_valid_moves(state, piece):
			moves.append({"piece": piece, "target": {"row": m.row, "col": m.col}})
	return moves


## Score a single move using heuristics. Higher = better for the moving player.
static func score_move(state: GameState, ai_move: Dictionary) -> float:
	var piece: GameState.Piece = ai_move.piece
	var target: Dictionary = ai_move.target
	var player: int = piece.player
	var score: float = 0.0

	# 1. Position improvement
	var cur_pos_score: float = _score_position(state, piece.row, piece.col)
	var new_pos_score: float = _score_position(state, target.row, target.col)
	score += (new_pos_score - cur_pos_score) * WEIGHTS.POSITION_WEIGHT
	score += new_pos_score * 0.5  # base attractiveness of destination

	# 2. Capture bonus
	var target_piece: GameState.Piece = null
	for p: GameState.Piece in state.pieces:
		if p.row == target.row and p.col == target.col and p.player != player:
			target_piece = p
			break
	if target_piece != null:
		score += WEIGHTS.CAPTURE_BONUS
		score += _score_piece_position(state, target_piece) * WEIGHTS.CAPTURE_VALUE_MULT

	# 3. Orb collection bonus
	var orb_at_target = null
	for o: Dictionary in state.orbs:
		if o.row == target.row and o.col == target.col:
			orb_at_target = o
			break
	if orb_at_target != null:
		score += _score_orb_value(orb_at_target)
		if _is_orb_collection_risky(state, player, target.row, target.col):
			score -= WEIGHTS.RISKY_ORB_PENALTY

	# 4. Threat penalty (moving into a square the opponent can immediately capture)
	if target_piece == null:
		if _is_orb_collection_risky(state, player, target.row, target.col):
			score -= WEIGHTS.THREAT_PENALTY

	return score


## Return the best move for `player` by heuristic evaluation alone.
## Returns null when player has no legal moves.
static func get_best_move(state: GameState, player: int):  # -> Dictionary or null
	var moves: Array = get_all_moves(state, player)
	if moves.size() == 0:
		return null

	var best = null
	var best_score: float = -INF

	for move: Dictionary in moves:
		var s: float = score_move(state, move)
		if s > best_score:
			best_score = s
			best = move

	return best


## Full board evaluation from `player`'s perspective.
## Positive = good for player, negative = bad.
static func evaluate_board(state: GameState, player: int) -> float:
	if state.pieces.size() == 0:
		return 0.0

	var my_score: float = 0.0
	var opp_score: float = 0.0
	var my_count: int = 0
	var opp_count: int = 0

	for piece: GameState.Piece in state.pieces:
		var val: float = WEIGHTS.PIECE_VALUE + _score_piece_position(state, piece)
		if piece.player == player:
			my_score += val
			my_count += 1
		else:
			opp_score += val
			opp_count += 1

	if opp_count == 0 and my_count > 0:
		return WEIGHTS.WIN_BONUS + my_score
	if my_count == 0 and opp_count > 0:
		return -(WEIGHTS.WIN_BONUS + opp_score)

	return my_score - opp_score


# ---------------------------------------------------------------------------
# POWER-ACTIVATION SEAM (stub — implement when powers module lands)
# ---------------------------------------------------------------------------

## Score the expected gain of activating `power_id` for `piece` in `state`.
##
## Positive return value means activation is beneficial for the piece's owner.
## Returns -INF to mark a power as not applicable in the current position.
##
## This stub always returns -INF (no power use), which keeps the AI playing
## pure movement until the powers module author drops in the real implementation.
## The ai.gd choose_move function references this function for the power seam.
static func score_power_activation(
		_state: GameState, _piece: GameState.Piece, _power_id: String) -> float:
	return -INF
