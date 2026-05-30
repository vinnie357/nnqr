## Renderer — draws a GameState onto a Node2D using only built-in draw primitives.
## Top-down view: checkerboard tiles with height shading, circles for pieces.
##
## C4 enhancements:
##   - Per-tile height shading (mirrors web tileColor / heightShade math).
##   - Destroyed-tile hatch pattern.
##   - Orb markers (gold circle + glow ring).
##   - Selected-tile outline.
##   - Valid-move indicators (green dot = empty, orange ring+X = capture).
##   - Power-target highlight overlay (purple tint).
##   - Win banner when status == "won".
##   - Height bar at tile bottom.
##   - Power badge dot on pieces with powers.
##
## C5 enhancements:
##   - HUD piece counts (P1: N  P2: N) derived from state.pieces.
##   - AI-thinking indicator ("AI thinking…") from hud_info.ai_thinking.
##   - Mode/difficulty label ("vs AI — hard" / "Hotseat") from hud_info.mode+difficulty.
##
## Usage:
##   const Renderer = preload("res://src/renderer.gd")
##   var renderer = Renderer.new()
##   add_child(renderer)
##   renderer.load_state(state)
##   renderer.set_power_target_tiles(tiles)   # optional purple highlight
extends Node2D

const Height = preload("res://src/height.gd")

const TILE: int = 56           ## px per tile
const MARGIN: int = 40         ## px border
const PIECE_RADIUS: float = 18.0

# ---------------------------------------------------------------------------
# Color palette (mirroring web renderer.ts / targets.ts)
# ---------------------------------------------------------------------------

const COL_P1          := Color(0.290, 0.549, 0.941)
const COL_P2          := Color(0.941, 0.353, 0.353)
const COL_P1_OUTLINE  := Color(0.180, 0.345, 0.600)
const COL_P2_OUTLINE  := Color(0.600, 0.161, 0.161)
const COL_LABEL       := Color(1.0, 1.0, 1.0, 0.85)
const COL_WIN_BG      := Color(0.067, 0.075, 0.094, 0.85)
const COL_WIN_TEXT    := Color(1.0, 0.839, 0.200)
const COL_SEL_OUTLINE := Color(1.0, 0.839, 0.200)
const COL_MOVE_EMPTY  := Color(0.298, 0.878, 0.416)
const COL_MOVE_CAP    := Color(0.949, 0.502, 0.173)
const COL_ORB         := Color(1.0, 0.894, 0.302)
const COL_DESTROYED   := Color(0.067, 0.075, 0.094)
const COL_POWER_TGT   := Color(0.800, 0.400, 1.000, 0.35)
const COL_BADGE_NORM  := Color(1.0, 0.894, 0.302)
const COL_BADGE_WARN  := Color(1.0, 0.267, 0.133)
const COL_HB0         := Color(0.165, 0.184, 0.243, 0.6)
const COL_HB4         := Color(0.353, 0.376, 0.471, 0.9)
const COL_AI_IND      := Color(0.267, 0.667, 1.000)   ## ai indicator / thinking blue
const COL_MODE_LABEL  := Color(0.800, 0.850, 0.950, 0.85)  ## mode/difficulty label


var _state                = null           ## GameState
var _power_target_tiles: Array = []        ## [{row,col}] for purple highlight


## Optional HUD extras, set via load_state. Keys (all optional):
##   ai_thinking:bool, mode:String ("hotseat"|"vsai"), difficulty:String.
## Empty {} (the default) reproduces the original HUD — scenario_runner relies on this.
var _hud_info: Dictionary = {}

## Set or replace the state and request a redraw.
## hud_info carries HUD extras (piece counts are derived from state directly).
func load_state(state, hud_info := {}) -> void:
	_state = state
	_hud_info = hud_info
	queue_redraw()


## Overlay power-target highlight tiles (purple). Pass [] to clear.
func set_power_target_tiles(tiles: Array) -> void:
	_power_target_tiles = tiles
	queue_redraw()


## Convert 1-indexed board (row, col) to viewport pixel top-left corner.
func tile_top_left(row: int, col: int) -> Vector2:
	return Vector2(MARGIN + (col - 1) * TILE, MARGIN + (row - 1) * TILE)


## Convert 1-indexed board (row, col) to viewport pixel centre.
func tile_center(row: int, col: int) -> Vector2:
	return tile_top_left(row, col) + Vector2(TILE / 2.0, TILE / 2.0)


## Map pixel position back to board tile. Returns {"row":int,"col":int} or null.
func pixel_to_tile(px: Vector2) -> Variant:
	var c := int((px.x - MARGIN) / TILE) + 1
	var r := int((px.y - MARGIN) / TILE) + 1
	if r >= 1 and r <= 8 and c >= 1 and c <= 10:
		return {"row": r, "col": c}
	return null


# ---------------------------------------------------------------------------
# Height-based tile colour (mirrors web/src/core/powers/targets.ts:tileColor)
# ---------------------------------------------------------------------------
static func _tile_color(row: int, col: int, height: int) -> Color:
	var is_light: bool = (row + col) % 2 == 0
	var br: float = 0x33 / 255.0 if is_light else 0x2a / 255.0
	var bg_: float = 0x38 / 255.0 if is_light else 0x2f / 255.0
	var bb: float = 0x4a / 255.0 if is_light else 0x3e / 255.0
	var hr: float = 0x5a / 255.0
	var hg: float = 0x60 / 255.0
	var hb: float = 0x78 / 255.0
	var t: float = float(height) / 4.0
	return Color(lerp(br, hr, t), lerp(bg_, hg, t), lerp(bb, hb, t))


# ---------------------------------------------------------------------------
# Draw
# ---------------------------------------------------------------------------

func _draw() -> void:
	if _state == null:
		return
	_draw_board()
	_draw_orbs()
	_draw_power_targets()
	_draw_valid_moves()
	_draw_pieces()
	_draw_hud()
	_draw_win_banner()


func _draw_board() -> void:
	for r: int in range(1, _state.rows + 1):
		for c: int in range(1, _state.cols + 1):
			var tl := tile_top_left(r, c)
			var rect := Rect2(tl, Vector2(TILE - 1, TILE - 1))

			if _state.destroyed_tiles.has("%d,%d" % [r, c]):
				draw_rect(rect, COL_DESTROYED)
				var step := 8
				var i := 0
				while i < TILE:
					draw_line(Vector2(tl.x + i, tl.y), Vector2(tl.x, tl.y + i),
						Color(0.2, 0.2, 0.27, 0.5), 1.0)
					draw_line(Vector2(tl.x + TILE, tl.y + i),
						Vector2(tl.x + i, tl.y + TILE),
						Color(0.2, 0.2, 0.27, 0.5), 1.0)
					i += step
			else:
				var h: int = Height.get_height(_state.height_map, r, c)
				draw_rect(rect, _tile_color(r, c, h))

				# Height bar at bottom of tile.
				if h > 0:
					var bar_h := 4
					var bar_w := TILE - 8
					var bar_y := tl.y + TILE - bar_h - 2
					var bar_x := tl.x + 4
					draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), COL_HB0)
					var fill_w := int((float(h) / 4.0) * float(bar_w))
					if fill_w > 0:
						draw_rect(Rect2(bar_x, bar_y, fill_w, bar_h), COL_HB4)

				# Grid line.
				draw_rect(rect, Color(0.118, 0.137, 0.176, 0.4), false, 1.0)

	# Selected-tile bright outline.
	if _state.selected != null:
		var tl := tile_top_left(_state.selected.row, _state.selected.col)
		draw_rect(Rect2(tl.x + 2, tl.y + 2, TILE - 4, TILE - 4),
			COL_SEL_OUTLINE, false, 4.0)


func _draw_orbs() -> void:
	for orb in _state.orbs:
		var tl := tile_top_left(orb.row, orb.col)
		var cx := tl.x + TILE / 2.0
		var cy := tl.y + TILE / 2.0
		draw_circle(Vector2(cx, cy), 14.0,
			Color(COL_ORB.r, COL_ORB.g, COL_ORB.b, 0.25))
		draw_circle(Vector2(cx, cy), 8.0, COL_ORB)
		draw_circle(Vector2(cx - 2, cy - 2), 2.0, Color(1, 1, 1, 0.8))


func _draw_power_targets() -> void:
	for t in _power_target_tiles:
		var tl := tile_top_left(t.row, t.col)
		draw_rect(Rect2(tl.x + 2, tl.y + 2, TILE - 4, TILE - 4), COL_POWER_TGT)


func _draw_valid_moves() -> void:
	for m in _state.valid_moves:
		var tl := tile_top_left(m.row, m.col)
		var cx := tl.x + TILE / 2.0
		var cy := tl.y + TILE / 2.0
		if m.capture:
			draw_arc(Vector2(cx, cy), TILE / 2.0 - 6.0, 0.0, TAU,
				32, COL_MOVE_CAP, 4.0)
			draw_line(Vector2(cx - 8, cy - 8), Vector2(cx + 8, cy + 8),
				Color(COL_MOVE_CAP.r, COL_MOVE_CAP.g, COL_MOVE_CAP.b, 0.7), 2.0)
			draw_line(Vector2(cx + 8, cy - 8), Vector2(cx - 8, cy + 8),
				Color(COL_MOVE_CAP.r, COL_MOVE_CAP.g, COL_MOVE_CAP.b, 0.7), 2.0)
		else:
			draw_circle(Vector2(cx, cy), 9.0,
				Color(COL_MOVE_EMPTY.r, COL_MOVE_EMPTY.g, COL_MOVE_EMPTY.b, 0.85))


func _draw_pieces() -> void:
	for piece in _state.pieces:
		var centre: Vector2 = tile_center(piece.row, piece.col)
		var fill   := COL_P1         if piece.player == 1 else COL_P2
		var outline := COL_P1_OUTLINE if piece.player == 1 else COL_P2_OUTLINE

		var is_sel: bool = (
			_state.selected != null and
			_state.selected.row == piece.row and
			_state.selected.col == piece.col
		)

		draw_circle(centre, PIECE_RADIUS + 2.0, outline)
		draw_circle(centre, PIECE_RADIUS, fill)

		if is_sel:
			draw_arc(centre, PIECE_RADIUS + 5.0, 0.0, TAU, 48, COL_SEL_OUTLINE, 3.0)

		# Power badge.
		if piece.powers.size() > 0:
			var max_count := 0
			for pw: String in piece.powers:
				var cnt := 0
				for pw2: String in piece.powers:
					if pw2 == pw:
						cnt += 1
				if cnt > max_count:
					max_count = cnt
			var badge_col := COL_BADGE_WARN if max_count >= 7 else COL_BADGE_NORM
			draw_circle(
				Vector2(centre.x + PIECE_RADIUS - 3.0, centre.y - PIECE_RADIUS + 3.0),
				5.0, badge_col)


func _draw_hud() -> void:
	var board_bottom: float = MARGIN + _state.rows * TILE + 10.0
	var y: float = board_bottom + 20.0

	# Line 1: turn + current player (existing behaviour, kept verbatim for game-over path).
	var label: String
	if _state.status == "won":
		label = "Turn %d — Player %d WINS" % [_state.turn, _state.winner]
	else:
		label = "Turn %d — Player %d to move" % [_state.turn, _state.current_player]
	draw_string(
		ThemeDB.fallback_font,
		Vector2(MARGIN, y),
		label,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		COL_LABEL
	)

	# Do not draw C5 extras when game is won (win banner dominates).
	if _state.status == "won":
		return

	# Line 2 (same y, right-justified after the board): piece counts P1: N  P2: N
	var p1_count: int = 0
	var p2_count: int = 0
	for piece in _state.pieces:
		if piece.player == 1:
			p1_count += 1
		else:
			p2_count += 1
	var counts_label: String = "P1: %d   P2: %d" % [p1_count, p2_count]
	# Draw counts to the right of the turn label — x=320 avoids overlap on a 560px board.
	draw_string(
		ThemeDB.fallback_font,
		Vector2(320, y),
		counts_label,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		COL_LABEL
	)

	# Line 3 (y+20): mode/difficulty label + AI-thinking indicator.
	var mode: String = str(_hud_info.get("mode", ""))
	var difficulty: String = str(_hud_info.get("difficulty", ""))
	var ai_thinking: bool = bool(_hud_info.get("ai_thinking", false))

	var mode_text: String = ""
	if mode == "vsai":
		mode_text = "vs AI"
		if difficulty != "":
			mode_text = "vs AI — %s" % difficulty
	elif mode == "hotseat":
		mode_text = "Hotseat"

	if ai_thinking:
		var think_label: String = "AI thinking…"
		if mode_text != "":
			think_label = "%s  |  AI thinking…" % mode_text
		draw_string(
			ThemeDB.fallback_font,
			Vector2(MARGIN, y + 22.0),
			think_label,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			14,
			COL_AI_IND
		)
	elif mode_text != "":
		draw_string(
			ThemeDB.fallback_font,
			Vector2(MARGIN, y + 22.0),
			mode_text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			14,
			COL_MODE_LABEL
		)


func _draw_win_banner() -> void:
	if _state.status != "won":
		return
	var bw := 340.0
	var bh := 80.0
	var board_cx: float = MARGIN + float(_state.cols) * TILE / 2.0
	var board_cy: float = MARGIN + float(_state.rows) * TILE / 2.0
	draw_rect(Rect2(board_cx - bw / 2.0, board_cy - bh / 2.0, bw, bh), COL_WIN_BG)
	var msg := "PLAYER %d WINS! (turn %d)" % [_state.winner, _state.turn]
	draw_string(
		ThemeDB.fallback_font,
		Vector2(board_cx - bw / 2.0 + 20.0, board_cy - 5.0),
		msg,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		26,
		COL_WIN_TEXT
	)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(board_cx - bw / 2.0 + 20.0, board_cy + 22.0),
		"Press N for a new game",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		COL_LABEL
	)
