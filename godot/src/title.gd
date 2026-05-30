## TitleScreen — drawn with built-in primitives (no assets required).
##
## Displays game name, mode selector (vs AI / Hotseat 2P), and
## difficulty selector (Easy / Medium / Hard / Expert).
## Difficulty applies only when mode == "vsai".
##
## Emits start_requested(mode, difficulty) when the player confirms.
## mode is "vsai" or "hotseat".
extends Node2D

signal start_requested(mode: String, difficulty: String)

# ---------------------------------------------------------------------------
# Layout constants
# ---------------------------------------------------------------------------
const W: int = 860
const H: int = 560

const COL_BG          := Color(0.067, 0.075, 0.094, 1.0)
const COL_TITLE       := Color(1.0, 0.839, 0.200)
const COL_SUBTITLE    := Color(0.7, 0.7, 0.8, 1.0)
const COL_LABEL       := Color(0.9, 0.9, 0.9, 1.0)
const COL_SELECTED    := Color(0.290, 0.549, 0.941)
const COL_SELECTED_TXT := Color(1.0, 1.0, 1.0, 1.0)
const COL_BTN_IDLE    := Color(0.18, 0.20, 0.27, 1.0)
const COL_BTN_HOVER   := Color(0.25, 0.28, 0.38, 1.0)
const COL_BTN_BORDER  := Color(0.35, 0.38, 0.50, 1.0)
const COL_START       := Color(0.290, 0.549, 0.941)
const COL_START_TXT   := Color(1.0, 1.0, 1.0, 1.0)
const COL_START_HOVER := Color(0.380, 0.649, 1.0)
const COL_DIM         := Color(0.5, 0.5, 0.5, 0.5)

const DIFFICULTIES: Array = ["easy", "medium", "hard", "expert"]
const DIFF_LABELS: Array  = ["Easy", "Medium", "Hard", "Expert"]

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var _mode: String       = "vsai"
var _difficulty: String = "medium"
var _hover: String      = ""
var _btn_rects: Dictionary = {}
var _mouse_pos: Vector2 = Vector2.ZERO


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	set_process_input(true)
	set_process(true)


func _process(_delta: float) -> void:
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_mouse_pos = (event as InputEventMouseMotion).position
		_update_hover()
	elif event is InputEventMouseButton:
		var me := event as InputEventMouseButton
		if me.pressed and me.button_index == MOUSE_BUTTON_LEFT:
			_handle_click(me.position)


# ---------------------------------------------------------------------------
# Drawing
# ---------------------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(0, 0, W, H), COL_BG)

	var font := ThemeDB.fallback_font
	var font_size_title: int = 56
	var font_size_sub: int   = 22
	var font_size_label: int = 18
	var font_size_btn: int   = 20

	# Title
	var title_text: String = "NNQR"
	var title_w: float = font.get_string_size(title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size_title).x
	draw_string(font, Vector2((W - title_w) * 0.5, 120), title_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size_title, COL_TITLE)

	var sub_text: String = "Not Not Quadradius"
	var sub_w: float = font.get_string_size(sub_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size_sub).x
	draw_string(font, Vector2((W - sub_w) * 0.5, 155), sub_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size_sub, COL_SUBTITLE)

	var center_x: float = W * 0.5

	# ---- Mode section ----
	var mode_y: float = 210.0
	var mode_lbl: String = "Mode"
	var mode_lbl_w: float = font.get_string_size(mode_lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size_label).x
	draw_string(font, Vector2((W - mode_lbl_w) * 0.5, mode_y),
		mode_lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size_label, COL_LABEL)

	var btn_w: float   = 150.0
	var btn_h: float   = 40.0
	var btn_gap: float = 16.0
	var modes_total: float = btn_w * 2 + btn_gap
	var mode_btn_y: float = mode_y + 12.0

	_draw_btn("mode_vsai",    Rect2(center_x - modes_total * 0.5, mode_btn_y, btn_w, btn_h),
		"vs AI",      _mode == "vsai",    font, font_size_btn)
	_draw_btn("mode_hotseat", Rect2(center_x - modes_total * 0.5 + btn_w + btn_gap, mode_btn_y, btn_w, btn_h),
		"Hotseat 2P", _mode == "hotseat", font, font_size_btn)

	# ---- Difficulty section ----
	var diff_y: float   = 305.0
	var diff_lbl: String = "Difficulty"
	var diff_lbl_w: float = font.get_string_size(diff_lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size_label).x

	var diff_col: Color = COL_LABEL if _mode == "vsai" else COL_DIM
	draw_string(font, Vector2((W - diff_lbl_w) * 0.5, diff_y),
		diff_lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size_label, diff_col)

	var diff_total: float  = btn_w * 4.0 + btn_gap * 3.0
	var diff_btn_y: float  = diff_y + 12.0
	var diff_start_x: float = center_x - diff_total * 0.5

	for i: int in range(DIFFICULTIES.size()):
		var d_id: String    = DIFFICULTIES[i]
		var d_label: String = DIFF_LABELS[i]
		var rx: float = diff_start_x + i * (btn_w + btn_gap)
		var selected_diff: bool = (_mode == "vsai") and (_difficulty == d_id)
		_draw_btn("diff_" + d_id, Rect2(rx, diff_btn_y, btn_w, btn_h),
			d_label, selected_diff, font, font_size_btn, _mode != "vsai")

	# ---- Start button ----
	var start_btn_w: float = 200.0
	var start_btn_h: float = 50.0
	var start_btn_x: float = (W - start_btn_w) * 0.5
	var start_btn_y: float = 420.0
	_draw_start_btn(Rect2(start_btn_x, start_btn_y, start_btn_w, start_btn_h), font, font_size_btn + 2)

	# ---- Key hint ----
	var hint: String = "Click to select  ·  Click Start Game to begin"
	var hint_w: float = font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	draw_string(font, Vector2((W - hint_w) * 0.5, 498), hint,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COL_SUBTITLE)


func _draw_btn(id: String, rect: Rect2, label: String, selected: bool,
	font: Font, font_size: int, dimmed: bool = false) -> void:
	_btn_rects[id] = rect

	var bg_col: Color
	var txt_col: Color
	var border_col: Color

	if dimmed:
		bg_col = Color(0.12, 0.13, 0.18)
		txt_col = COL_DIM
		border_col = Color(0.20, 0.22, 0.30)
	elif selected:
		bg_col = COL_SELECTED
		txt_col = COL_SELECTED_TXT
		border_col = COL_SELECTED
	elif _hover == id:
		bg_col = COL_BTN_HOVER
		txt_col = COL_LABEL
		border_col = COL_BTN_BORDER
	else:
		bg_col = COL_BTN_IDLE
		txt_col = COL_LABEL
		border_col = COL_BTN_BORDER

	draw_rect(rect, bg_col)
	draw_rect(rect, border_col, false, 1.5)

	var lbl_w: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var lbl_x: float = rect.position.x + (rect.size.x - lbl_w) * 0.5
	var lbl_y: float = rect.position.y + rect.size.y * 0.5 + font_size * 0.35
	draw_string(font, Vector2(lbl_x, lbl_y), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, txt_col)


func _draw_start_btn(rect: Rect2, font: Font, font_size: int) -> void:
	_btn_rects["start"] = rect
	var bg_col: Color = COL_START_HOVER if _hover == "start" else COL_START
	draw_rect(rect, bg_col)

	var label: String = "Start Game"
	var lbl_w: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var lbl_x: float = rect.position.x + (rect.size.x - lbl_w) * 0.5
	var lbl_y: float = rect.position.y + rect.size.y * 0.5 + font_size * 0.35
	draw_string(font, Vector2(lbl_x, lbl_y), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, COL_START_TXT)


# ---------------------------------------------------------------------------
# Interaction
# ---------------------------------------------------------------------------

func _update_hover() -> void:
	_hover = ""
	for id: String in _btn_rects:
		if (_btn_rects[id] as Rect2).has_point(_mouse_pos):
			_hover = id
			break


func _handle_click(pos: Vector2) -> void:
	for id: String in _btn_rects:
		if (_btn_rects[id] as Rect2).has_point(pos):
			_on_btn_pressed(id)
			return


func _on_btn_pressed(id: String) -> void:
	match id:
		"mode_vsai":
			_mode = "vsai"
		"mode_hotseat":
			_mode = "hotseat"
		"diff_easy":
			if _mode == "vsai":
				_difficulty = "easy"
		"diff_medium":
			if _mode == "vsai":
				_difficulty = "medium"
		"diff_hard":
			if _mode == "vsai":
				_difficulty = "hard"
		"diff_expert":
			if _mode == "vsai":
				_difficulty = "expert"
		"start":
			emit_signal("start_requested", _mode, _difficulty)
