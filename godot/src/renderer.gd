## Renderer — draws a GameState onto a Node2D using only built-in draw primitives.
## Top-down view: checkerboard tiles, circles for pieces (player 1=blue, player 2=red).
## Screenshot-friendly: clear colours, no external assets required.
##
## Usage:
##   const Renderer = preload("res://src/renderer.gd")
##   var renderer = Renderer.new()
##   add_child(renderer)
##   renderer.load_state(state)
extends Node2D

const TILE: int = 56          ## px per tile
const MARGIN: int = 40        ## px border around the board
const PIECE_RADIUS: float = 18.0

## Tile colours
const COL_DARK_TILE  := Color(0.20, 0.22, 0.29)
const COL_LIGHT_TILE := Color(0.27, 0.30, 0.38)
## Piece colours
const COL_P1         := Color(0.29, 0.55, 0.94)   ## blue — player 1
const COL_P2         := Color(0.94, 0.35, 0.35)   ## red  — player 2
const COL_P1_OUTLINE := Color(0.15, 0.35, 0.75)
const COL_P2_OUTLINE := Color(0.75, 0.18, 0.18)
## HUD text colour
const COL_LABEL      := Color(1.0, 1.0, 1.0, 0.85)

var _state = null  ## GameState instance (typed via duck-typing)


## Set or replace the state being rendered and request a redraw.
func load_state(state) -> void:
	_state = state
	queue_redraw()


## Convert 1-indexed board (row, col) to viewport pixel centre.
func tile_center(row: int, col: int) -> Vector2:
	return Vector2(
		MARGIN + (col - 1) * TILE + TILE / 2.0,
		MARGIN + (row - 1) * TILE + TILE / 2.0
	)


func _draw() -> void:
	if _state == null:
		return
	_draw_board()
	_draw_pieces()
	_draw_hud()


func _draw_board() -> void:
	for r: int in range(1, _state.rows + 1):
		for c: int in range(1, _state.cols + 1):
			var top_left := Vector2(MARGIN + (c - 1) * TILE, MARGIN + (r - 1) * TILE)
			var colour: Color = COL_DARK_TILE if (r + c) % 2 == 0 else COL_LIGHT_TILE
			draw_rect(Rect2(top_left, Vector2(TILE - 1, TILE - 1)), colour)


func _draw_pieces() -> void:
	for piece in _state.pieces:
		var centre: Vector2 = tile_center(piece.row, piece.col)
		var fill: Color    = COL_P1         if piece.player == 1 else COL_P2
		var outline: Color = COL_P1_OUTLINE if piece.player == 1 else COL_P2_OUTLINE
		draw_circle(centre, PIECE_RADIUS + 2.0, outline)
		draw_circle(centre, PIECE_RADIUS,        fill)


func _draw_hud() -> void:
	var board_bottom: float = MARGIN + _state.rows * TILE + 10.0
	var label: String
	if _state.status == "won":
		label = "Turn %d — Player %d WINS" % [_state.turn, _state.winner]
	else:
		label = "Turn %d — Player %d to move" % [_state.turn, _state.current_player]
	draw_string(
		ThemeDB.fallback_font,
		Vector2(MARGIN, board_bottom + 20.0),
		label,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		COL_LABEL
	)
