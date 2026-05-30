## board.gd — Core board rules, ported from web/src/core/board.ts.
##
## Mutability contract: functions that produce a new state construct a fresh
## GameState and copy all fields explicitly. GDScript 4's duplicate() returns
## Object (not the inner type), so we avoid it for typed fields and instead
## build new instances manually. The returned state is independent of the
## input; the input is NOT mutated.
##
## Usage:
##   const Board = preload("res://src/board.gd")
##   var state = Board.create_initial_state(seed)
##   state = Board.select_piece(state, row, col)
##   state = Board.move_to(state, row, col)
extends RefCounted

const GameState = preload("res://src/game_state.gd")
const Height = preload("res://src/height.gd")

const BOARD_COLS: int = 10
const BOARD_ROWS: int = 8

const ORTHOGONAL: Array = [[-1, 0], [1, 0], [0, -1], [0, 1]]
const DIAGONAL: Array   = [[-1, -1], [-1, 1], [1, -1], [1, 1]]


# ---------------------------------------------------------------------------
# Internal helper: shallow-copy a GameState (copies all scalar fields and
# top-level Array/Dictionary references; does NOT deep-clone pieces).
# ---------------------------------------------------------------------------
static func _copy_state(src: GameState) -> GameState:
	var dst := GameState.new()
	dst.cols = src.cols
	dst.rows = src.rows
	dst.current_player = src.current_player
	dst.turn = src.turn
	dst.status = src.status
	dst.winner = src.winner
	dst.seed = src.seed
	dst.pieces = src.pieces          # array ref shared (replaced on mutation)
	dst.height_map = src.height_map  # array ref shared (not mutated here)
	dst.destroyed_tiles = src.destroyed_tiles  # dict ref shared
	dst.orbs = src.orbs              # array ref shared
	dst.selected = src.selected      # null or dict (value-typed)
	dst.valid_moves = src.valid_moves
	return dst


# ---------------------------------------------------------------------------
# Factory
# ---------------------------------------------------------------------------

## Creates the standard initial 10×8 board state with 20 pieces per player.
## Player 1 occupies rows 1-2; player 2 occupies rows 7-8.
static func create_initial_state(seed: int = 1) -> GameState:
	var state := GameState.new()
	state.seed = seed
	state.init_board()
	return state


# ---------------------------------------------------------------------------
# Query helpers
# ---------------------------------------------------------------------------

## True when (row, col) is within the board.
static func in_bounds(row: int, col: int) -> bool:
	return row >= 1 and row <= BOARD_ROWS and col >= 1 and col <= BOARD_COLS


## Returns the Piece at (row, col), or null if the tile is empty.
static func piece_at(state: GameState, row: int, col: int) -> GameState.Piece:
	for p: GameState.Piece in state.pieces:
		if p.row == row and p.col == col:
			return p
	return null


## Returns true if the tile (row, col) is in the destroyed_tiles set.
static func is_destroyed(state: GameState, row: int, col: int) -> bool:
	return state.destroyed_tiles.has("%d,%d" % [row, col])


## A jump-proof piece cannot be captured by normal movement.
static func can_capture(_state: GameState, _attacker: GameState.Piece,
		target: GameState.Piece) -> bool:
	return not target.is_jump_proof


# ---------------------------------------------------------------------------
# Movement
# ---------------------------------------------------------------------------

## Wrap a (row, col) that has stepped off the board edge.
static func _wrap(row: int, col: int) -> Dictionary:
	var r := row
	var c := col
	if r < 1: r = BOARD_ROWS
	elif r > BOARD_ROWS: r = 1
	if c < 1: c = BOARD_COLS
	elif c > BOARD_COLS: c = 1
	return {"row": r, "col": c}


## Valid single-step moves for `piece`, honouring power flags:
##   can_move_diagonally — adds diagonal dirs
##   can_wrap            — wraps off-board steps to the opposite edge
##   can_climb_any       — ignores height climb limit
##   is_jump_proof       — immunity is checked on the *target*, not the mover
## Returns Array of {"row":int,"col":int,"capture":bool}.
static func get_valid_moves(state: GameState, piece: GameState.Piece) -> Array:
	var moves: Array = []
	var from_h := Height.get_height(state.height_map, piece.row, piece.col)
	var dirs: Array = ORTHOGONAL.duplicate()
	if piece.can_move_diagonally:
		dirs.append_array(DIAGONAL)

	for dir in dirs:
		var dr: int = dir[0]
		var dc: int = dir[1]
		var row := piece.row + dr
		var col := piece.col + dc
		if piece.can_wrap:
			var wrapped := _wrap(row, col)
			row = wrapped.row
			col = wrapped.col
		if not in_bounds(row, col):
			continue
		if is_destroyed(state, row, col):
			continue
		var to_h := Height.get_height(state.height_map, row, col)
		if not piece.can_climb_any and not Height.can_climb(from_h, to_h):
			continue
		var occupant := piece_at(state, row, col)
		if occupant == null:
			moves.append({"row": row, "col": col, "capture": false})
		elif occupant.player != piece.player and can_capture(state, piece, occupant):
			moves.append({"row": row, "col": col, "capture": true})

	return moves


# ---------------------------------------------------------------------------
# Win condition
# ---------------------------------------------------------------------------

## Returns 1 or 2 if that player wins (opponent has no pieces), 0 otherwise.
static func check_winner(state: GameState) -> int:
	var has_p1 := false
	var has_p2 := false
	for p: GameState.Piece in state.pieces:
		if p.player == 1: has_p1 = true
		else: has_p2 = true
	if not has_p1: return 2
	if not has_p2: return 1
	return 0


# ---------------------------------------------------------------------------
# State transitions
# ---------------------------------------------------------------------------

## Select a piece belonging to the current player. Clears selection otherwise.
## Returns a new GameState.
static func select_piece(state: GameState, row: int, col: int) -> GameState:
	if state.status != "playing":
		return state
	var piece := piece_at(state, row, col)
	var next: GameState = _copy_state(state)
	if piece == null or piece.player != state.current_player:
		next.selected = null
		next.valid_moves = []
		return next
	next.selected = {"row": row, "col": col}
	next.valid_moves = get_valid_moves(state, piece)
	return next


## Move the selected piece to (row, col) if legal. Captures an enemy on the
## target tile, flips current_player, increments turn, and resolves winner.
## Returns the state unchanged when the move is illegal.
static func move_to(state: GameState, row: int, col: int) -> GameState:
	if state.status != "playing" or state.selected == null:
		return state
	var legal: Dictionary = {}
	for m in state.valid_moves:
		if m.row == row and m.col == col:
			legal = m
			break
	if legal.is_empty():
		return state

	var mover := piece_at(state, state.selected.row, state.selected.col)
	if mover == null:
		return state

	# Build new pieces array: remove captured enemy, update mover position.
	var new_pieces: Array = []
	for p: GameState.Piece in state.pieces:
		if p.row == row and p.col == col and p.player != mover.player:
			continue  # captured — remove
		if p.id == mover.id:
			# Clone the piece and update position
			var moved := GameState.Piece.new(p.id, p.player, row, col)
			moved.powers = p.powers.duplicate()
			moved.is_jump_proof = p.is_jump_proof
			moved.can_move_diagonally = p.can_move_diagonally
			moved.can_climb_any = p.can_climb_any
			moved.can_wrap = p.can_wrap
			moved.is_invisible = p.is_invisible
			new_pieces.append(moved)
		else:
			new_pieces.append(p)

	var next: GameState = _copy_state(state)
	next.pieces = new_pieces
	next.selected = null
	next.valid_moves = []
	next.current_player = 2 if state.current_player == 1 else 1
	next.turn = state.turn + 1

	var winner := check_winner(next)
	if winner != 0:
		next.status = "won"
		next.winner = winner

	return next
