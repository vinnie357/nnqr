## Renderer — draws a GameState onto a Node2D using only built-in draw primitives.
## Isometric 2.5D view: 2:1 diamond tiles with height rendered as 3D elevation.
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
## C6 enhancements (isometric):
##   - 2:1 isometric projection: iso_x = origin_x + (col-row)*(TILE_W/2)
##                                iso_y = origin_y + (col+row)*(TILE_H/2) - height*HEIGHT_STEP
##   - Height renders as visible elevation (side face, painter's depth order).
##   - pixel_to_tile inverts the iso transform (base-plane pick).
##
## Usage:
##   const Renderer = preload("res://src/renderer.gd")
##   var renderer = Renderer.new()
##   add_child(renderer)
##   renderer.load_state(state)
##   renderer.set_power_target_tiles(tiles)   # optional purple highlight
extends Node2D

const Height = preload("res://src/height.gd")

## Legacy TILE constant kept for power_menu.gd layout compatibility.
## power_menu.gd uses Renderer.TILE to compute BOARD_W (10*TILE) and MENU_X.
## With the iso board the horizontal half-step is TILE_W/2 = 32 = old TILE/2,
## but the board pixel width is (cols + rows)*TILE_W/2 = 576 rather than 10*TILE.
## We keep TILE=56 so that MENU_X = MARGIN + 10*TILE + 16 = 40+560+16 = 616
## which sits safely to the right of the iso board (rightmost tile tip ≈ 584).
const TILE: int = 56           ## legacy constant — kept for power_menu layout
const MARGIN: int = 40         ## px border / iso origin_y base

## Isometric tile dimensions.
const TILE_W: int = 64         ## full diamond width  (half-step = 32)
const TILE_H: int = 32         ## full diamond height (half-step = 16)
const HEIGHT_STEP: int = 12    ## px of vertical lift per height level

## Iso origin: the screen point where tile (row=0, col=0) would sit (virtual).
## Board uses 1-indexed rows/cols (1..8, 1..10).
## origin_x chosen so leftmost board edge (col=1,row=8) lands at ≥ MARGIN.
## Leftmost tip offset from origin: (1-8)*(TILE_W/2) = -7*32 = -224.
## → origin_x = MARGIN + 224 = 264.  Add a bit of breathing room: 280.
const ISO_ORIGIN_X: int = 280
const ISO_ORIGIN_Y: int = 40   ## top of board rows

const PIECE_RADIUS: float = 14.0

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


# ---------------------------------------------------------------------------
# Isometric projection helpers
# ---------------------------------------------------------------------------

## Compute the screen position of the TOP FACE CENTER of an iso tile.
## row/col are 1-indexed.  height shifts the tile upward.
func tile_iso_center(row: int, col: int, h: int) -> Vector2:
	var x := float(ISO_ORIGIN_X) + float(col - row) * float(TILE_W / 2)
	var y := float(ISO_ORIGIN_Y) + float(col + row) * float(TILE_H / 2) - float(h) * float(HEIGHT_STEP)
	return Vector2(x, y)


## Return the four corners of the top-face diamond for a tile at the given iso center.
## Order: top, right, bottom, left.
func _diamond(cx: float, cy: float) -> PackedVector2Array:
	var hw: float = float(TILE_W) / 2.0
	var hh: float = float(TILE_H) / 2.0
	var pts := PackedVector2Array()
	pts.append(Vector2(cx,        cy - hh))  # top
	pts.append(Vector2(cx + hw,   cy))       # right
	pts.append(Vector2(cx,        cy + hh))  # bottom
	pts.append(Vector2(cx - hw,   cy))       # left
	return pts


## Legacy top-left helper — kept for internal use only; not used for iso drawing.
## Kept so pixel_to_tile callers referencing this indirectly still compile.
func tile_top_left(row: int, col: int) -> Vector2:
	var h: int = 0
	if _state != null:
		h = Height.get_height(_state.height_map, row, col)
	return tile_iso_center(row, col, h) - Vector2(float(TILE_W) / 2.0, float(TILE_H) / 2.0)


## Convenience: tile iso center using the current state's height_map.
func tile_center(row: int, col: int) -> Vector2:
	var h: int = 0
	if _state != null:
		h = Height.get_height(_state.height_map, row, col)
	return tile_iso_center(row, col, h)


## Map pixel position back to board tile using the base-plane inverse.
## Ignores height for hit-testing (base-plane pick is acceptable per spec).
## Returns {"row":int,"col":int} or null.
func pixel_to_tile(px: Vector2) -> Variant:
	# Inverse of: iso_x = ISO_ORIGIN_X + (col - row) * (TILE_W/2)
	#             iso_y = ISO_ORIGIN_Y + (col + row) * (TILE_H/2)
	# (ignoring height offset)
	var hw: float = float(TILE_W) / 2.0
	var hh: float = float(TILE_H) / 2.0
	var dx: float = (px.x - float(ISO_ORIGIN_X)) / hw  # = col - row
	var dy: float = (px.y - float(ISO_ORIGIN_Y)) / hh  # = col + row
	var col_f: float = (dx + dy) / 2.0
	var row_f: float = (dy - dx) / 2.0
	var c: int = int(floor(col_f)) + 1
	var r: int = int(floor(row_f)) + 1
	if r >= 1 and r <= 8 and c >= 1 and c <= 10:
		return {"row": r, "col": c}
	return null


# ---------------------------------------------------------------------------
# Height-based tile colour (mirrors web/src/core/powers/targets.ts:tileColor)
# ---------------------------------------------------------------------------
static func _tile_color(row: int, col: int, h: int) -> Color:
	var is_light: bool = (row + col) % 2 == 0
	var br: float = 0x33 / 255.0 if is_light else 0x2a / 255.0
	var bg_: float = 0x38 / 255.0 if is_light else 0x2f / 255.0
	var bb: float = 0x4a / 255.0 if is_light else 0x3e / 255.0
	var hr: float = 0x5a / 255.0
	var hg: float = 0x60 / 255.0
	var hb: float = 0x78 / 255.0
	var t: float = float(h) / 4.0
	return Color(lerp(br, hr, t), lerp(bg_, hg, t), lerp(bb, hb, t))


# ---------------------------------------------------------------------------
# Draw
# ---------------------------------------------------------------------------

func _draw() -> void:
	if _state == null:
		return
	# Painter's order: iterate tiles by (row + col) ascending so back tiles
	# render first and front tiles occlude them correctly.
	_draw_board_sorted()
	_draw_hud()
	_draw_win_banner()


## Draw all tiles, orbs, power-target overlays, valid-move indicators, and pieces
## in painter's order (back → front by row+col depth key).
func _draw_board_sorted() -> void:
	# Build a depth-sorted list of (row, col) pairs.
	var pairs: Array = []
	for r: int in range(1, _state.rows + 1):
		for c: int in range(1, _state.cols + 1):
			pairs.append([r, c])
	pairs.sort_custom(func(a: Array, b: Array) -> bool:
		return (a[0] + a[1]) < (b[0] + b[1])
	)

	# Pre-build lookup sets for efficiency.
	var piece_map: Dictionary = {}
	for piece in _state.pieces:
		piece_map["%d,%d" % [piece.row, piece.col]] = piece

	var orb_map: Dictionary = {}
	for orb in _state.orbs:
		orb_map["%d,%d" % [orb.row, orb.col]] = orb

	var target_set: Dictionary = {}
	for t in _power_target_tiles:
		target_set["%d,%d" % [t.row, t.col]] = true

	var move_map: Dictionary = {}
	for m in _state.valid_moves:
		move_map["%d,%d" % [m.row, m.col]] = m

	for pair in pairs:
		var r: int = pair[0]
		var c: int = pair[1]
		var key: String = "%d,%d" % [r, c]
		var h: int = Height.get_height(_state.height_map, r, c)
		var ctr: Vector2 = tile_iso_center(r, c, h)

		_draw_tile(r, c, h, ctr)

		# Overlays drawn on top of tile face, in depth order.
		if target_set.has(key):
			_draw_power_target_overlay(ctr)

		if move_map.has(key):
			_draw_valid_move(move_map[key], ctr)

		if orb_map.has(key):
			_draw_orb(ctr)

		if piece_map.has(key):
			_draw_piece(piece_map[key], ctr)


## Draw one isometric tile (top face + optional side face for elevated tiles).
func _draw_tile(r: int, c: int, h: int, ctr: Vector2) -> void:
	var hw: float = float(TILE_W) / 2.0
	var hh: float = float(TILE_H) / 2.0
	var top_pts: PackedVector2Array = _diamond(ctr.x, ctr.y)

	var is_destroyed: bool = _state.destroyed_tiles.has("%d,%d" % [r, c])

	if is_destroyed:
		# Destroyed tile: dark fill + hatch marks on top face.
		draw_colored_polygon(top_pts, COL_DESTROYED)
		# Hatch lines from top-corner toward bottom-corner inside diamond.
		var steps := 6
		for i: int in range(1, steps):
			var t: float = float(i) / float(steps)
			var from_l: Vector2 = lerp(top_pts[3], top_pts[0], t)  # left->top
			var to_r: Vector2   = lerp(top_pts[3], top_pts[2], t)  # left->bottom
			var from_r: Vector2 = lerp(top_pts[1], top_pts[0], t)  # right->top
			var to_l: Vector2   = lerp(top_pts[1], top_pts[2], t)  # right->bottom
			draw_line(from_l, to_r, Color(0.2, 0.2, 0.27, 0.5), 1.0)
			draw_line(from_r, to_l, Color(0.2, 0.2, 0.27, 0.5), 1.0)
	else:
		# Side face (elevation): only when height > 0.
		if h > 0:
			var side_drop: float = float(h) * float(HEIGHT_STEP)
			# Left side face (bottom-left of diamond drops down).
			var left_face := PackedVector2Array()
			left_face.append(top_pts[3])             # left tip of top face
			left_face.append(top_pts[2])             # bottom tip of top face
			left_face.append(Vector2(top_pts[2].x, top_pts[2].y + side_drop))
			left_face.append(Vector2(top_pts[3].x, top_pts[3].y + side_drop))
			var base_col: Color = _tile_color(r, c, h)
			var left_col: Color = base_col.darkened(0.35)
			draw_colored_polygon(left_face, left_col)

			# Right side face.
			var right_face := PackedVector2Array()
			right_face.append(top_pts[1])             # right tip of top face
			right_face.append(top_pts[2])             # bottom tip of top face
			right_face.append(Vector2(top_pts[2].x, top_pts[2].y + side_drop))
			right_face.append(Vector2(top_pts[1].x, top_pts[1].y + side_drop))
			var right_col: Color = base_col.darkened(0.20)
			draw_colored_polygon(right_face, right_col)

		# Top face fill.
		draw_colored_polygon(top_pts, _tile_color(r, c, h))
		# Thin grid outline.
		draw_polyline(top_pts, Color(0.118, 0.137, 0.176, 0.35), 1.0, true)

	# Selected-tile bright outline on top face.
	if _state.selected != null and _state.selected.row == r and _state.selected.col == c:
		draw_polyline(top_pts, COL_SEL_OUTLINE, 3.0, true)


## Draw a purple power-target highlight on the tile face center.
func _draw_power_target_overlay(ctr: Vector2) -> void:
	var hw: float = float(TILE_W) / 2.0 - 2.0
	var hh: float = float(TILE_H) / 2.0 - 1.0
	var pts := PackedVector2Array()
	pts.append(Vector2(ctr.x,       ctr.y - hh))
	pts.append(Vector2(ctr.x + hw,  ctr.y))
	pts.append(Vector2(ctr.x,       ctr.y + hh))
	pts.append(Vector2(ctr.x - hw,  ctr.y))
	draw_colored_polygon(pts, COL_POWER_TGT)


## Draw a valid-move indicator at the tile face center.
func _draw_valid_move(m: Dictionary, ctr: Vector2) -> void:
	if m.capture:
		draw_arc(ctr, float(TILE_H) / 2.0 - 4.0, 0.0, TAU, 32, COL_MOVE_CAP, 3.0)
		draw_line(Vector2(ctr.x - 7, ctr.y - 7), Vector2(ctr.x + 7, ctr.y + 7),
			Color(COL_MOVE_CAP.r, COL_MOVE_CAP.g, COL_MOVE_CAP.b, 0.7), 2.0)
		draw_line(Vector2(ctr.x + 7, ctr.y - 7), Vector2(ctr.x - 7, ctr.y + 7),
			Color(COL_MOVE_CAP.r, COL_MOVE_CAP.g, COL_MOVE_CAP.b, 0.7), 2.0)
	else:
		draw_circle(ctr, 7.0,
			Color(COL_MOVE_EMPTY.r, COL_MOVE_EMPTY.g, COL_MOVE_EMPTY.b, 0.85))


## Draw an orb marker at the tile face center.
func _draw_orb(ctr: Vector2) -> void:
	draw_circle(ctr, 12.0, Color(COL_ORB.r, COL_ORB.g, COL_ORB.b, 0.25))
	draw_circle(ctr, 7.0, COL_ORB)
	draw_circle(Vector2(ctr.x - 2, ctr.y - 2), 2.0, Color(1, 1, 1, 0.8))


## Draw a piece token sitting on its tile surface.
## piece may be a GameState.Piece object or a plain Dictionary.
func _draw_piece(piece: Variant, ctr: Vector2) -> void:
	var fill    := COL_P1         if piece.player == 1 else COL_P2
	var outline := COL_P1_OUTLINE if piece.player == 1 else COL_P2_OUTLINE

	var is_sel: bool = (
		_state.selected != null and
		_state.selected.row == piece.row and
		_state.selected.col == piece.col
	)

	draw_circle(ctr, PIECE_RADIUS + 2.0, outline)
	draw_circle(ctr, PIECE_RADIUS, fill)

	if is_sel:
		draw_arc(ctr, PIECE_RADIUS + 5.0, 0.0, TAU, 48, COL_SEL_OUTLINE, 3.0)

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
			Vector2(ctr.x + PIECE_RADIUS - 3.0, ctr.y - PIECE_RADIUS + 3.0),
			5.0, badge_col)


func _draw_hud() -> void:
	# Place HUD below the iso board.
	# Bottom-most tile tip: row=8, col=1 (or row=1, col=10 — same depth sum).
	# Deepest tile center y (base, h=0): ISO_ORIGIN_Y + (8+10)*(TILE_H/2) = 40 + 18*16 = 328.
	# Add TILE_H/2 for diamond bottom tip + a few px gap.
	var board_bottom: float = float(ISO_ORIGIN_Y) + float(_state.rows + _state.cols) * float(TILE_H) / 2.0 + 12.0
	var y: float = board_bottom + 16.0

	# Line 1: turn + current player.
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

	# Line 2 (same y, offset right): piece counts.
	var p1_count: int = 0
	var p2_count: int = 0
	for piece in _state.pieces:
		if piece.player == 1:
			p1_count += 1
		else:
			p2_count += 1
	var counts_label: String = "P1: %d   P2: %d" % [p1_count, p2_count]
	draw_string(
		ThemeDB.fallback_font,
		Vector2(320, y),
		counts_label,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		COL_LABEL
	)

	# Line 3 (y+22): mode/difficulty label + AI-thinking indicator.
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
	# Center banner on the iso board's visual center.
	var board_cx: float = float(ISO_ORIGIN_X)
	var board_cy: float = float(ISO_ORIGIN_Y) + float(_state.rows + _state.cols) * float(TILE_H) / 4.0
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
