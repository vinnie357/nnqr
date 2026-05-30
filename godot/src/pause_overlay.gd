## PauseOverlay — drawn with built-in primitives (no assets required).
##
## Shown when the game is paused (PAUSED state in main.gd).
## Renders a semi-transparent dim rect over the game board,
## a "Paused" banner, and two buttons: Resume and Quit to Title.
##
## Emits:
##   resume_pressed  — player wants to continue playing
##   quit_pressed    — player wants to return to the title screen
extends Node2D

signal resume_pressed
signal quit_pressed

# ---------------------------------------------------------------------------
# Layout constants
# ---------------------------------------------------------------------------
const W: int = 860
const H: int = 560

const COL_DIM       := Color(0.0, 0.0, 0.0, 0.65)
const COL_PANEL     := Color(0.10, 0.11, 0.15, 0.96)
const COL_PANEL_BDR := Color(0.30, 0.33, 0.45, 1.0)
const COL_TITLE     := Color(1.0, 0.839, 0.200)
const COL_LABEL     := Color(0.9, 0.9, 0.9, 1.0)
const COL_BTN_IDLE  := Color(0.18, 0.20, 0.27, 1.0)
const COL_BTN_HOVER := Color(0.25, 0.28, 0.38, 1.0)
const COL_BTN_BDR   := Color(0.35, 0.38, 0.50, 1.0)
const COL_QUIT_IDLE := Color(0.30, 0.10, 0.10, 1.0)
const COL_QUIT_HOVER := Color(0.50, 0.14, 0.14, 1.0)
const COL_QUIT_BDR  := Color(0.55, 0.20, 0.20, 1.0)

# Panel dimensions
const PANEL_W: float = 320.0
const PANEL_H: float = 220.0
const BTN_W: float   = 200.0
const BTN_H: float   = 44.0

var _btn_rects: Dictionary = {}
var _mouse_pos: Vector2    = Vector2.ZERO
var _hover: String         = ""


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
	# Full-screen dim
	draw_rect(Rect2(0, 0, W, H), COL_DIM)

	var font := ThemeDB.fallback_font
	var font_size_title: int = 36
	var font_size_btn: int   = 20

	# Panel
	var px: float = (W - PANEL_W) * 0.5
	var py: float = (H - PANEL_H) * 0.5
	draw_rect(Rect2(px, py, PANEL_W, PANEL_H), COL_PANEL)
	draw_rect(Rect2(px, py, PANEL_W, PANEL_H), COL_PANEL_BDR, false, 1.5)

	# "Paused" title
	var title_txt: String = "Paused"
	var title_w: float = font.get_string_size(title_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size_title).x
	draw_string(font, Vector2(px + (PANEL_W - title_w) * 0.5, py + 55),
		title_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size_title, COL_TITLE)

	# Resume button
	var btn_x: float = px + (PANEL_W - BTN_W) * 0.5
	_draw_btn("resume", Rect2(btn_x, py + 90, BTN_W, BTN_H),
		"Resume", false, font, font_size_btn)

	# Quit to Title button
	_draw_btn("quit", Rect2(btn_x, py + 148, BTN_W, BTN_H),
		"Quit to Title", true, font, font_size_btn)

	# Hint
	var hint: String = "Press Esc to resume"
	var hint_w: float = font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	draw_string(font, Vector2(px + (PANEL_W - hint_w) * 0.5, py + PANEL_H - 12),
		hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.6, 0.6, 0.7, 0.8))


## Draw a labeled button. is_quit=true uses the red quit colour scheme.
func _draw_btn(id: String, rect: Rect2, label: String, is_quit: bool,
	font: Font, font_size: int) -> void:
	_btn_rects[id] = rect

	var bg_col: Color
	var bdr_col: Color
	if is_quit:
		bg_col  = COL_QUIT_HOVER if _hover == id else COL_QUIT_IDLE
		bdr_col = COL_QUIT_BDR
	else:
		bg_col  = COL_BTN_HOVER if _hover == id else COL_BTN_IDLE
		bdr_col = COL_BTN_BDR

	draw_rect(rect, bg_col)
	draw_rect(rect, bdr_col, false, 1.5)

	var lbl_w: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var lbl_x: float = rect.position.x + (rect.size.x - lbl_w) * 0.5
	var lbl_y: float = rect.position.y + rect.size.y * 0.5 + font_size * 0.35
	draw_string(font, Vector2(lbl_x, lbl_y), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, COL_LABEL)


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
		"resume":
			emit_signal("resume_pressed")
		"quit":
			emit_signal("quit_pressed")
