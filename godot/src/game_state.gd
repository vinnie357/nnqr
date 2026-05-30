## GameState — data model for NNQR board state.
## Mirrors web/src/core/types.ts and board.ts (skeleton: board + pieces only).
## 10 cols × 8 rows; player 1 starts rows 1-2, player 2 starts rows 7-8.
##
## Usage:
##   const GameState = preload("res://src/game_state.gd")
##   var state = GameState.new()
##   GameState.init_board(state)          # initial 20+20 layout
##   GameState.from_dict(state, dict)     # load from JSON dict
extends RefCounted

const BOARD_COLS: int = 10
const BOARD_ROWS: int = 8

## Inner class representing a single piece on the board.
class Piece extends RefCounted:
	var id: String
	var player: int   ## 1 or 2
	var row: int      ## 1-indexed
	var col: int      ## 1-indexed

	func _init(p_id: String, p_player: int, p_row: int, p_col: int) -> void:
		id = p_id
		player = p_player
		row = p_row
		col = p_col

	func to_dict() -> Dictionary:
		return {"id": id, "player": player, "row": row, "col": col}


## Board dimensions.
var cols: int = BOARD_COLS
var rows: int = BOARD_ROWS

## All pieces still in play (Array of Piece).
var pieces: Array = []

## Whose turn it is: 1 or 2.
var current_player: int = 1

## Turn counter (starts at 0).
var turn: int = 0

## "playing" or "won".
var status: String = "playing"

## Winning player (1 or 2) or 0 when still playing.
var winner: int = 0


## Populate state with the standard initial board:
## 20 pieces per player; player 1 on rows 1-2, player 2 on rows 7-8.
func init_board() -> void:
	pieces.clear()
	for row: int in [1, 2]:
		for col: int in range(1, BOARD_COLS + 1):
			pieces.append(Piece.new("p1-%d-%d" % [row, col], 1, row, col))
	for row: int in [BOARD_ROWS - 1, BOARD_ROWS]:
		for col: int in range(1, BOARD_COLS + 1):
			pieces.append(Piece.new("p2-%d-%d" % [row, col], 2, row, col))


## Populate state from a Dictionary (loaded from JSON scenario file).
## Expected keys: pieces (array), current_player (int), turn (int).
## Optional: status (str), winner (int).
func load_dict(d: Dictionary) -> void:
	current_player = int(d.get("current_player", 1))
	turn = int(d.get("turn", 0))
	status = str(d.get("status", "playing"))
	winner = int(d.get("winner", 0))
	pieces.clear()
	var raw_pieces: Array = d.get("pieces", [])
	for rp: Dictionary in raw_pieces:
		var piece := Piece.new(
			str(rp.get("id", "")),
			int(rp.get("player", 1)),
			int(rp.get("row", 1)),
			int(rp.get("col", 1))
		)
		pieces.append(piece)


## Serialise to a plain Dictionary (for JSON output).
func to_dict() -> Dictionary:
	var piece_list: Array = []
	for p: Piece in pieces:
		piece_list.append(p.to_dict())
	return {
		"cols": cols,
		"rows": rows,
		"current_player": current_player,
		"turn": turn,
		"status": status,
		"winner": winner,
		"pieces": piece_list,
	}
