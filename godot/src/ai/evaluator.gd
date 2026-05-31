## evaluator.gd — AI heuristic board scoring.
## Ported from web/src/core/ai/evaluator.ts.
##
## POWER-ACTIVATION SEAM
## ─────────────────────
## score_power_activation(state, piece, power_id) returns the expected gain of
## activating power_id for piece in state.  Positive = beneficial.
## -INF = not applicable (no valid target, wrong conditions, piece lacks power).
##
## Implemented heuristics (nnqr-20):
##   destroy_row / destroy_column / acidic_row / acidic_column / kamikaze_row /
##   kamikaze_column / pilfer_row / pilfer_column / recruit_row / recruit_column —
##     score by enemy count in line; -INF if < MIN_LINE_ENEMIES or any ally in line
##     (kamikaze variants allow self-sacrifice when gain > 1 enemy).
##   bomb / destroy_radial / acidic_radial / smart_bombs / kamikaze_radial /
##   pilfer_radial / destroy_radial —
##     score by enemy count in 3x3; -INF if < MIN_AREA_ENEMIES or ally in area.
##   jump_proof —
##     positive only when piece is threatened AND not already jump_proof.
##   All others —
##     -INF (not handled; no beneficial heuristic defined).
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
# POWER-ACTIVATION SEAM (nnqr-20 implementation)
# ---------------------------------------------------------------------------

## Minimum number of enemies needed in a line to justify activating a line power.
const MIN_LINE_ENEMIES: int = 2

## Minimum number of enemies needed in a 3x3 area to justify activating an area power.
const MIN_AREA_ENEMIES: int = 2

## Score per enemy piece eliminated by an area/line attack.
const POWER_ENEMY_VALUE: float = 80.0

## Score for activating jump_proof when threatened.
const JUMP_PROOF_VALUE: float = 40.0


## True when `piece` is threatened — i.e. an opponent can capture it on their
## next standard move. Used for jump_proof heuristic.
static func _piece_is_threatened(state: GameState, piece: GameState.Piece) -> bool:
	var opponent: int = 2 if piece.player == 1 else 1
	for enemy: GameState.Piece in state.pieces:
		if enemy.player != opponent:
			continue
		for m: Dictionary in Board.get_valid_moves(state, enemy):
			if m.row == piece.row and m.col == piece.col:
				return true
	return false


## Count enemies and allies in the same row as `piece` (excluding self).
## Returns {"enemies": int, "allies": int}.
static func _count_row(state: GameState, piece: GameState.Piece) -> Dictionary:
	var enemies: int = 0
	var allies: int = 0
	for p: GameState.Piece in state.pieces:
		if p.id == piece.id:
			continue
		if p.row != piece.row:
			continue
		if p.player == piece.player:
			allies += 1
		else:
			enemies += 1
	return {"enemies": enemies, "allies": allies}


## Count enemies and allies in the same column as `piece` (excluding self).
static func _count_col(state: GameState, piece: GameState.Piece) -> Dictionary:
	var enemies: int = 0
	var allies: int = 0
	for p: GameState.Piece in state.pieces:
		if p.id == piece.id:
			continue
		if p.col != piece.col:
			continue
		if p.player == piece.player:
			allies += 1
		else:
			enemies += 1
	return {"enemies": enemies, "allies": allies}


## Count enemies and allies in the 3x3 area centred on `piece` (excluding self).
static func _count_area3x3(state: GameState, piece: GameState.Piece) -> Dictionary:
	var enemies: int = 0
	var allies: int = 0
	for p: GameState.Piece in state.pieces:
		if p.id == piece.id:
			continue
		var dr: int = abs(p.row - piece.row)
		var dc: int = abs(p.col - piece.col)
		if dr <= 1 and dc <= 1:
			if p.player == piece.player:
				allies += 1
			else:
				enemies += 1
	return {"enemies": enemies, "allies": allies}


## Score the expected gain of activating `power_id` for `piece` in `state`.
##
## Positive return value means activation is beneficial for the piece's owner.
## Returns -INF to mark a power as not applicable in the current position.
static func score_power_activation(
		state: GameState, piece: GameState.Piece, power_id: String) -> float:

	# Guard: piece must own at least one copy of the power.
	if not piece.powers.has(power_id):
		return -INF

	match power_id:
		# ---------------------------------------------------------------
		# Line powers — row variants
		# ---------------------------------------------------------------
		"destroy_row", "acidic_row", "pilfer_row", "recruit_row":
			var counts := _count_row(state, piece)
			# Don't use if any ally would be caught in the blast.
			if counts.allies > 0:
				return -INF
			if counts.enemies < MIN_LINE_ENEMIES:
				return -INF
			return float(counts.enemies) * POWER_ENEMY_VALUE

		# Kamikaze row: sacrifice self; only worthwhile when killing more enemies
		# than the 1 piece we lose.
		"kamikaze_row":
			var counts := _count_row(state, piece)
			if counts.enemies < 2:
				return -INF
			return (float(counts.enemies) - 1.0) * POWER_ENEMY_VALUE

		# ---------------------------------------------------------------
		# Line powers — column variants
		# ---------------------------------------------------------------
		"destroy_column", "acidic_column", "pilfer_column", "recruit_column":
			var counts := _count_col(state, piece)
			if counts.allies > 0:
				return -INF
			if counts.enemies < MIN_LINE_ENEMIES:
				return -INF
			return float(counts.enemies) * POWER_ENEMY_VALUE

		"kamikaze_column":
			var counts := _count_col(state, piece)
			if counts.enemies < 2:
				return -INF
			return (float(counts.enemies) - 1.0) * POWER_ENEMY_VALUE

		# ---------------------------------------------------------------
		# Area powers — 3x3
		# ---------------------------------------------------------------
		"bomb", "destroy_radial", "acidic_radial", "pilfer_radial":
			var counts := _count_area3x3(state, piece)
			if counts.allies > 0:
				return -INF
			if counts.enemies < MIN_AREA_ENEMIES:
				return -INF
			return float(counts.enemies) * POWER_ENEMY_VALUE

		# smart_bombs only hurts enemies — allies are safe.
		"smart_bombs":
			var counts := _count_area3x3(state, piece)
			if counts.enemies < MIN_AREA_ENEMIES:
				return -INF
			return float(counts.enemies) * POWER_ENEMY_VALUE

		# kamikaze_radial: self-sacrifice; worthwhile when net enemy kill ≥ 1.
		"kamikaze_radial":
			var counts := _count_area3x3(state, piece)
			if counts.enemies < 2:
				return -INF
			return (float(counts.enemies) - 1.0) * POWER_ENEMY_VALUE

		# ---------------------------------------------------------------
		# Defensive powers
		# ---------------------------------------------------------------
		"jump_proof":
			# Don't waste it if it's already active.
			if piece.is_jump_proof:
				return -INF
			# Only activate when the piece is actually under threat.
			if _piece_is_threatened(state, piece):
				return JUMP_PROOF_VALUE
			return -INF

		# ---------------------------------------------------------------
		# Default: no heuristic defined for this power.
		# ---------------------------------------------------------------
		_:
			return -INF
