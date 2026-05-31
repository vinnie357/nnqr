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
## C7 enhancements (responsive layout):
##   - Layout computed from live viewport size each _draw.
##   - Board fills the available area (minus right power-menu strip + bottom HUD strip).
##   - Reconnects on viewport size_changed to redraw on resize.
##   - TILE_W clamped [24..120] for legibility.
##   - Pieces sized proportionally (PIECE_RADIUS = TILE_W * 0.33).
##
## Usage:
##   const Renderer = preload("res://src/renderer.gd")
##   var renderer = Renderer.new()
##   add_child(renderer)
##   renderer.load_state(state)
##   renderer.set_power_target_tiles(tiles)   # optional purple highlight
extends Node2D

const Height = preload("res://src/height.gd")

## Board dimensions (board cols x rows: 10 wide, 8 tall).
const BOARD_COLS: int = 10
const BOARD_ROWS: int = 8

## Strips reserved for the power menu (right) and HUD (bottom), in px.
const MENU_STRIP_W: int = 240   ## right strip for power menu
const HUD_STRIP_H: int  = 70    ## bottom strip for HUD text
const BOARD_MARGIN: int = 20    ## inset margin around the board within its area

## TILE_W clamping range (px, full diamond width).
## TILE_W_MAX is a high sanity bound only — the board grows with the window up
## to this cap so a maximized window shows a large board, not a small one in grey.
const TILE_W_MIN: int = 24
const TILE_W_MAX: int = 200

## Legacy TILE constant kept only so external scripts that import Renderer.TILE
## continue to compile.  power_menu.gd now positions itself from the viewport
## directly and no longer reads this field.
const TILE: int = 56

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

# ---------------------------------------------------------------------------
# Computed layout vars — updated by _compute_layout() before each draw.
# ---------------------------------------------------------------------------

## Computed each draw from viewport size.  Do NOT read these as compile-time constants.
var _tile_w: float     = 64.0   ## full diamond width
var _tile_h: float     = 32.0   ## full diamond height (= _tile_w / 2)
var _height_step: float = 12.0  ## px vertical lift per height level
var _origin_x: float   = 280.0  ## iso projection origin x
var _origin_y: float   = 40.0   ## iso projection origin y
var _piece_radius: float = 14.0 ## piece token radius
## Power menu left edge and top — used by power_menu.gd via get_menu_x() / get_menu_y().
var _menu_x: float = 600.0
var _menu_y: float = 20.0


func _enter_tree() -> void:
	# Connect viewport resize so the board stays filled when the window changes.
	get_viewport().size_changed.connect(_on_viewport_resized)


func _exit_tree() -> void:
	if get_viewport().size_changed.is_connected(_on_viewport_resized):
		get_viewport().size_changed.disconnect(_on_viewport_resized)


func _on_viewport_resized() -> void:
	queue_redraw()


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


## Public accessors for power_menu.gd to read computed layout.
func get_menu_x() -> float:
	return _menu_x

func get_menu_y() -> float:
	return _menu_y


# ---------------------------------------------------------------------------
# Responsive layout computation
# ---------------------------------------------------------------------------

## Compute tile size and iso origin from the current viewport size.
## Called at the start of _draw so all draw helpers use fresh values.
## Also prints layout info so the lead can sanity-check the math from CLI output.
func _compute_layout() -> void:
	var vp_size: Vector2 = get_viewport_rect().size
	var vp_w: float = vp_size.x
	var vp_h: float = vp_size.y

	# Board area excludes the right menu strip and the bottom HUD strip.
	var avail_w: float = vp_w - float(MENU_STRIP_W) - float(BOARD_MARGIN) * 2.0
	var avail_h: float = vp_h - float(HUD_STRIP_H) - float(BOARD_MARGIN) * 2.0

	# The iso diamond spans:
	#   width  = (cols + rows) * (TILE_W / 2)
	#   height = (cols + rows) * (TILE_H / 2)  + max_height * HEIGHT_STEP  [elevation]
	# With TILE_H = TILE_W / 2 the height equation becomes:
	#   height = (cols + rows) * (TILE_W / 4) + 4 * HEIGHT_STEP_effective
	#
	# We solve for TILE_W that makes the diamond fit in (avail_w, avail_h):
	#   TILE_W <= avail_w * 2 / (cols + rows)           [width constraint]
	#   TILE_W <= avail_h * 4 / (cols + rows)  (approx, ignoring small elevation term)
	#
	# HEIGHT_STEP is proportional to TILE_H = TILE_W/2, so the elevation term is small
	# relative to the diamond body; we use the simpler height constraint for the initial
	# tile size and accept a ~5% overestimate that we cover with BOARD_MARGIN.

	var n: float = float(BOARD_COLS + BOARD_ROWS)   # = 18 for 10x8 board
	var tw_from_w: float = avail_w * 2.0 / n
	var tw_from_h: float = avail_h * 4.0 / n
	var tile_w_raw: float = minf(tw_from_w, tw_from_h)
	_tile_w = clampf(floor(tile_w_raw), float(TILE_W_MIN), float(TILE_W_MAX))
	_tile_h = _tile_w / 2.0
	_height_step = _tile_h * 0.375   ## ~HEIGHT_STEP/TILE_H ratio from original (12/32 ≈ 0.375)
	_piece_radius = _tile_w * 0.33

	# Center the board within the available area (top-left corner = BOARD_MARGIN).
	var board_area_left: float = float(BOARD_MARGIN)
	var board_area_top: float  = float(BOARD_MARGIN)
	var board_area_w: float    = avail_w
	var board_area_h: float    = avail_h

	# The iso origin is the virtual point where (row=0, col=0) would project.
	# With 1-indexed board (rows 1..8, cols 1..10):
	#   leftmost tip  = origin_x + (1 - 8) * (TILE_W/2)  = origin_x - 3.5 * TILE_W
	#   rightmost tip = origin_x + (10 - 1) * (TILE_W/2) = origin_x + 4.5 * TILE_W
	#   topmost tip   = origin_y + (1 + 1) * (TILE_H/2)  = origin_y + TILE_H
	#   bottommost tip= origin_y + (8 + 10) * (TILE_H/2) = origin_y + 9 * TILE_H (base)
	#
	# Diamond x spans from (origin_x - 3.5 * TILE_W) to (origin_x + 4.5 * TILE_W).
	# We want the diamond centered in board_area:
	#   center_x = board_area_left + board_area_w/2
	#   origin_x = center_x + 0.5 * TILE_W   [because midpoint = (left+right)/2 = origin_x + 0.5*TILE_W]
	var hw: float = _tile_w / 2.0
	var hh: float = _tile_h / 2.0
	var board_center_x: float = board_area_left + board_area_w / 2.0
	# x midpoint of the diamond = origin_x + (col_mid - row_mid) * hw
	# col_mid = (1+10)/2 = 5.5, row_mid = (1+8)/2 = 4.5 → col_mid - row_mid = 1.0
	_origin_x = board_center_x - 1.0 * hw

	# y: vertically center the diamond within the available area.
	# Visual vertical extent of the board (top face centers + elevation headroom):
	#   topmost point  = origin_y + (1+1)*hh - 4*HEIGHT_STEP - hh   [tile (1,1), max lift, top tip]
	#                  = origin_y + hh - 4*HEIGHT_STEP
	#   bottommost     = origin_y + (8+10)*hh + hh                  [tile (8,10), h=0, bottom tip]
	#                  = origin_y + 19*hh
	# Diamond visual height = 18*hh + 4*HEIGHT_STEP.
	# Its vertical midpoint = origin_y + 10*hh - 2*HEIGHT_STEP.
	# Solve so that midpoint == board_area_top + board_area_h/2.
	var board_center_y: float = board_area_top + board_area_h / 2.0
	_origin_y = board_center_y - 10.0 * hh + 2.0 * _height_step

	# Power menu: right strip.
	_menu_x = vp_w - float(MENU_STRIP_W) + 8.0
	_menu_y = float(BOARD_MARGIN)

	# Print layout for lead verification (visible in CLI output).
	print("Renderer layout: vp=%.0fx%.0f  TILE_W=%.0f  TILE_H=%.0f  HEIGHT_STEP=%.1f  origin=(%.0f,%.0f)  piece_r=%.1f  menu_x=%.0f" % [
		vp_w, vp_h, _tile_w, _tile_h, _height_step, _origin_x, _origin_y, _piece_radius, _menu_x
	])


# ---------------------------------------------------------------------------
# Isometric projection helpers
# ---------------------------------------------------------------------------

## Compute the screen position of the TOP FACE CENTER of an iso tile.
## row/col are 1-indexed.  height shifts the tile upward.
func tile_iso_center(row: int, col: int, h: int) -> Vector2:
	var x := _origin_x + float(col - row) * (_tile_w / 2.0)
	var y := _origin_y + float(col + row) * (_tile_h / 2.0) - float(h) * _height_step
	return Vector2(x, y)


## Return the four corners of the top-face diamond for a tile at the given iso center.
## Order: top, right, bottom, left.
func _diamond(cx: float, cy: float) -> PackedVector2Array:
	var hw: float = _tile_w / 2.0
	var hh: float = _tile_h / 2.0
	var pts := PackedVector2Array()
	pts.append(Vector2(cx,        cy - hh))  # top
	pts.append(Vector2(cx + hw,   cy))       # right
	pts.append(Vector2(cx,        cy + hh))  # bottom
	pts.append(Vector2(cx - hw,   cy))       # left
	return pts


## Legacy top-left helper — kept for any callers that reference it indirectly.
func tile_top_left(row: int, col: int) -> Vector2:
	var h: int = 0
	if _state != null:
		h = Height.get_height(_state.height_map, row, col)
	return tile_iso_center(row, col, h) - Vector2(_tile_w / 2.0, _tile_h / 2.0)


## Convenience: tile iso center using the current state's height_map.
func tile_center(row: int, col: int) -> Vector2:
	var h: int = 0
	if _state != null:
		h = Height.get_height(_state.height_map, row, col)
	return tile_iso_center(row, col, h)


## Map pixel position back to board tile using the base-plane inverse.
## Inverts the same responsive transform used for drawing.
## Returns {"row":int,"col":int} or null.
func pixel_to_tile(px: Vector2) -> Variant:
	# Inverse of: iso_x = _origin_x + (col - row) * (_tile_w/2)
	#             iso_y = _origin_y + (col + row) * (_tile_h/2)
	# (ignoring height offset — base-plane pick)
	var hw: float = _tile_w / 2.0
	var hh: float = _tile_h / 2.0
	if hw <= 0.0 or hh <= 0.0:
		return null
	var dx: float = (px.x - _origin_x) / hw  # = col - row
	var dy: float = (px.y - _origin_y) / hh  # = col + row
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
	# Recompute layout from live viewport size before drawing.
	_compute_layout()
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
	var hw: float = _tile_w / 2.0
	var hh: float = _tile_h / 2.0
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
			var side_drop: float = float(h) * _height_step
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
	var hw: float = _tile_w / 2.0 - 2.0
	var hh: float = _tile_h / 2.0 - 1.0
	var pts := PackedVector2Array()
	pts.append(Vector2(ctr.x,       ctr.y - hh))
	pts.append(Vector2(ctr.x + hw,  ctr.y))
	pts.append(Vector2(ctr.x,       ctr.y + hh))
	pts.append(Vector2(ctr.x - hw,  ctr.y))
	draw_colored_polygon(pts, COL_POWER_TGT)


## Draw a valid-move indicator at the tile face center.
func _draw_valid_move(m: Dictionary, ctr: Vector2) -> void:
	var dot_r: float = maxf(_tile_h / 2.0 - 4.0, 3.0)
	if m.capture:
		draw_arc(ctr, dot_r, 0.0, TAU, 32, COL_MOVE_CAP, 3.0)
		var cross: float = minf(7.0, dot_r * 0.6)
		draw_line(Vector2(ctr.x - cross, ctr.y - cross), Vector2(ctr.x + cross, ctr.y + cross),
			Color(COL_MOVE_CAP.r, COL_MOVE_CAP.g, COL_MOVE_CAP.b, 0.7), 2.0)
		draw_line(Vector2(ctr.x + cross, ctr.y - cross), Vector2(ctr.x - cross, ctr.y + cross),
			Color(COL_MOVE_CAP.r, COL_MOVE_CAP.g, COL_MOVE_CAP.b, 0.7), 2.0)
	else:
		draw_circle(ctr, maxf(dot_r * 0.55, 3.0),
			Color(COL_MOVE_EMPTY.r, COL_MOVE_EMPTY.g, COL_MOVE_EMPTY.b, 0.85))


## Draw an orb marker at the tile face center.
func _draw_orb(ctr: Vector2) -> void:
	var orb_r: float = maxf(_tile_w * 0.19, 5.0)
	draw_circle(ctr, orb_r * 1.7, Color(COL_ORB.r, COL_ORB.g, COL_ORB.b, 0.25))
	draw_circle(ctr, orb_r, COL_ORB)
	draw_circle(Vector2(ctr.x - orb_r * 0.28, ctr.y - orb_r * 0.28), orb_r * 0.28, Color(1, 1, 1, 0.8))


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

	# Piece sits on the tile — draw as a slightly flattened token (ellipse via scaled circle).
	# We use draw_circle for simplicity (Godot 4 built-in ellipse not available here).
	var pr: float = _piece_radius
	draw_circle(ctr, pr + 2.0, outline)
	draw_circle(ctr, pr, fill)

	if is_sel:
		draw_arc(ctr, pr + 5.0, 0.0, TAU, 48, COL_SEL_OUTLINE, 3.0)

	# Power badge — positioned at upper-right of the token.
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
		var badge_r: float = maxf(pr * 0.35, 3.5)
		draw_circle(
			Vector2(ctr.x + pr - badge_r, ctr.y - pr + badge_r),
			badge_r, badge_col)


func _draw_hud() -> void:
	var vp_h: float = get_viewport_rect().size.y
	# HUD text sits in the reserved bottom strip.
	var y: float = vp_h - float(HUD_STRIP_H) + 20.0

	# Line 1: turn + current player.
	var label: String
	if _state.status == "won":
		label = "Turn %d — Player %d WINS" % [_state.turn, _state.winner]
	else:
		label = "Turn %d — Player %d to move" % [_state.turn, _state.current_player]
	draw_string(
		ThemeDB.fallback_font,
		Vector2(float(BOARD_MARGIN), y),
		label,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		COL_LABEL
	)

	# Do not draw C5 extras when game is won (win banner dominates).
	if _state.status == "won":
		return

	# Line 2 (same y, 260px right): piece counts P1: N  P2: N
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
		Vector2(float(BOARD_MARGIN) + 260.0, y),
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
			Vector2(float(BOARD_MARGIN), y + 22.0),
			think_label,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			14,
			COL_AI_IND
		)
	elif mode_text != "":
		draw_string(
			ThemeDB.fallback_font,
			Vector2(float(BOARD_MARGIN), y + 22.0),
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
	# Center banner on the iso board's computed visual center.
	# Board center: origin + (col_mid - row_mid)*hw, origin + (col_mid + row_mid)*hh
	# col_mid=5.5, row_mid=4.5 → diff=1, sum=10
	var board_cx: float = _origin_x + 1.0 * (_tile_w / 2.0)
	var board_cy: float = _origin_y + 10.0 * (_tile_h / 2.0)
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
