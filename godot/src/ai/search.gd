## search.gd — Minimax with alpha-beta pruning + capture-first move ordering.
## Ported from web/src/core/ai/search.ts.
##
## BREADTH CAP
## ───────────
## At each node we consider at most MAX_BRANCHING_FACTOR moves (captures first,
## then non-captures sorted by descending heuristic score). This keeps the
## expert search (depth 4) tractable even on a full 10×8 board where each
## player can have 20 pieces with up to 4 moves each (~80 raw moves).
##
## With cap=10 and depth=4 the worst-case node budget is 10^4 = 10 000 nodes.
## Without the cap, 80^4 ≈ 40 M nodes would be unacceptable for a game UI.
extends RefCounted

const Board = preload("res://src/board.gd")
const GameState = preload("res://src/game_state.gd")
const Evaluator = preload("res://src/ai/evaluator.gd")

## Maximum moves considered per node (captures always included first).
const MAX_BRANCHING_FACTOR: int = 10

# ---------------------------------------------------------------------------
# State deep-copy (local — AI is self-contained; does NOT call Board.move_to)
# ---------------------------------------------------------------------------

static func _copy_state(src: GameState) -> GameState:
	var dst := GameState.new()
	dst.cols = src.cols
	dst.rows = src.rows
	dst.current_player = src.current_player
	dst.turn = src.turn
	dst.status = src.status
	dst.winner = src.winner
	dst.selected = null
	dst.valid_moves = []
	dst.seed = src.seed

	# Deep-copy orbs
	dst.orbs = []
	for o: Dictionary in src.orbs:
		dst.orbs.append({"row": o.row, "col": o.col, "power_id": o.get("power_id", "")})

	# Deep-copy height_map (rows are arrays)
	dst.height_map = []
	for row_arr: Array in src.height_map:
		dst.height_map.append(row_arr.duplicate())

	# Deep-copy destroyed_tiles
	dst.destroyed_tiles = src.destroyed_tiles.duplicate()

	# Deep-copy pieces
	dst.pieces = []
	for p: GameState.Piece in src.pieces:
		var cp := GameState.Piece.new(p.id, p.player, p.row, p.col)
		cp.powers = p.powers.duplicate()
		cp.is_jump_proof = p.is_jump_proof
		cp.can_move_diagonally = p.can_move_diagonally
		cp.can_climb_any = p.can_climb_any
		cp.can_wrap = p.can_wrap
		cp.is_invisible = p.is_invisible
		dst.pieces.append(cp)

	return dst

# ---------------------------------------------------------------------------
# Apply a move to a copied state (mutates copy in place — never the original)
# ---------------------------------------------------------------------------

static func _apply_move(
		state: GameState, moving_piece: GameState.Piece, target: Dictionary) -> void:
	# Remove captured piece if any
	var capture_idx: int = -1
	for i in range(state.pieces.size()):
		var p: GameState.Piece = state.pieces[i]
		if p.row == target.row and p.col == target.col and p.player != moving_piece.player:
			capture_idx = i
			break
	if capture_idx != -1:
		state.pieces.remove_at(capture_idx)

	# Move the piece
	for p: GameState.Piece in state.pieces:
		if p.id == moving_piece.id:
			p.row = target.row
			p.col = target.col
			break

	state.current_player = 2 if state.current_player == 1 else 1
	state.turn += 1

# ---------------------------------------------------------------------------
# Move ordering: captures first, then non-captures by descending heuristic
# ---------------------------------------------------------------------------

## Order moves: captures first, then non-captures sorted by descending score,
## capped at MAX_BRANCHING_FACTOR total.
static func order_moves(state: GameState, moves: Array) -> Array:
	var captures: Array = []
	var others: Array = []

	for move: Dictionary in moves:
		var is_capture := false
		for p: GameState.Piece in state.pieces:
			if p.row == move.target.row and p.col == move.target.col \
					and p.player != move.piece.player:
				is_capture = true
				break
		if is_capture:
			captures.append(move)
		else:
			others.append(move)

	# Sort non-captures by descending heuristic score for better pruning
	others.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return Evaluator.score_move(state, a) > Evaluator.score_move(state, b)
	)

	var result: Array = captures + others
	if result.size() > MAX_BRANCHING_FACTOR:
		result = result.slice(0, MAX_BRANCHING_FACTOR)
	return result

# ---------------------------------------------------------------------------
# Negamax with alpha-beta pruning
# ---------------------------------------------------------------------------

## Negamax (minimax reformulation): score is always from the perspective of
## the player whose turn it is at this node. The caller negates when bubbling.
## Returns [best_move_or_null, score].
static func _negamax(
		state: GameState,
		depth: int,
		player: int,
		alpha: float,
		beta: float) -> Array:
	if depth == 0:
		return [null, Evaluator.evaluate_board(state, player)]

	var raw_moves: Array = Evaluator.get_all_moves(state, player)
	if raw_moves.size() == 0:
		return [null, Evaluator.evaluate_board(state, player)]

	var moves: Array = order_moves(state, raw_moves)
	var opponent: int = 2 if player == 1 else 1

	var best_move = null
	var best_score: float = -INF

	for move: Dictionary in moves:
		var copy: GameState = _copy_state(state)
		# Find the corresponding piece in the copy by id
		var piece_copy: GameState.Piece = null
		for p: GameState.Piece in copy.pieces:
			if p.id == move.piece.id:
				piece_copy = p
				break
		if piece_copy == null:
			continue

		_apply_move(copy, piece_copy, move.target)

		var child_result: Array = _negamax(copy, depth - 1, opponent, -beta, -alpha)
		var score: float = -float(child_result[1])

		if score > best_score:
			best_score = score
			best_move = move

		alpha = maxf(alpha, score)
		if alpha >= beta:
			break  # Beta cutoff

	return [best_move, best_score]

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Find the best move for `player` via minimax to `depth` plies.
## Returns null when no legal moves exist.
##
## Expert (depth 4) is capped at MAX_BRANCHING_FACTOR=10 moves per node,
## giving a worst-case budget of 10^4 = 10 000 nodes.
static func find_best_move(state: GameState, depth: int, player: int):  # -> Dictionary or null
	var result: Array = _negamax(state, depth, player, -INF, INF)
	return result[0]
