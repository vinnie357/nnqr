## power_menu.gd — UI node listing the selected piece's collected powers.
##
## When a piece is selected and has powers, draws a panel to the right of the
## board listing each power name + count. Clicking a row emits `power_chosen`
## with the power_id. When no piece is selected or it has no powers, the menu
## is empty / hidden.
##
## Usage:
##   const PowerMenu = preload("res://src/power_menu.gd")
##   var menu = PowerMenu.new()
##   add_child(menu)
##   menu.update(state)            # call after every state change
##   menu.power_chosen.connect(func(id): ...)
extends Node2D

const Renderer  = preload("res://src/renderer.gd")
const Board     = preload("res://src/board.gd")
const Targets   = preload("res://src/powers/targets.gd")
const Defs      = preload("res://src/powers/definitions.gd")

## Emitted when the player clicks a power row. Passes the power_id string.
signal power_chosen(power_id: String)

# ---------------------------------------------------------------------------
# Layout
# ---------------------------------------------------------------------------

const BOARD_W      : int = 10 * Renderer.TILE
const MENU_X       : int = Renderer.MARGIN + BOARD_W + 16
const MENU_Y       : int = Renderer.MARGIN
const MENU_W       : int = 210
const ROW_H        : int = 24
const HEADER_H     : int = 28
const PAD          : int = 8

# ---------------------------------------------------------------------------
# Colours
# ---------------------------------------------------------------------------

const COL_BG          := Color(0.094, 0.106, 0.149)
const COL_BORDER      := Color(0.227, 0.247, 0.333)
const COL_HEADER_TEXT := Color(1.0, 0.839, 0.200)
const COL_ITEM_TEXT   := Color(0.902, 0.910, 0.933)
const COL_ITEM_BG     := Color(0.0, 0.0, 0.0, 0.0)
const COL_ITEM_HOVER  := Color(0.600, 0.267, 0.800, 0.30)
const COL_ACTIVE      := Color(0.800, 0.400, 1.000, 0.40)


## Internal state: ordered list of {power_id, count, name}.
var _entries: Array = []
## Currently active (armed) power id, or "".
var _active_power_id: String = ""
## Track hover row index for visual feedback (-1 = none).
var _hover_row: int = -1


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Update the menu from the current GameState.
## Call this after every state transition.
func update(state) -> void:
	_entries.clear()
	_active_power_id = ""

	if state.selected == null:
		queue_redraw()
		return

	var piece = Board.piece_at(state, state.selected.row, state.selected.col)
	if piece == null or piece.powers.size() == 0:
		queue_redraw()
		return

	var counts: Dictionary = Targets.power_counts(piece)
	# Build an ordered, deduplicated list (insertion order from the Array).
	var seen: Dictionary = {}
	for pw_id: String in piece.powers:
		if seen.has(pw_id):
			continue
		seen[pw_id] = true
		var def = Defs.get_def(pw_id)
		var display_name: String = def.name if def != null else pw_id
		_entries.append({
			"power_id": pw_id,
			"count": counts.get(pw_id, 1),
			"name": display_name,
		})

	queue_redraw()


## Arm a power (mark it as the active power awaiting a target or confirm).
## Pass "" to clear.
func set_active_power(power_id: String) -> void:
	_active_power_id = power_id
	queue_redraw()


# ---------------------------------------------------------------------------
# Input
# ---------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var me := event as InputEventMouseButton
	if not me.pressed or me.button_index != MOUSE_BUTTON_LEFT:
		return

	var row := _row_at(me.position)
	if row >= 0:
		var entry: Dictionary = _entries[row]
		emit_signal("power_chosen", entry.power_id)
		get_viewport().set_input_as_handled()


func _input_event_notification(_event: InputEvent) -> void:
	pass


## Handle mouse motion to update hover row.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_MOUSE_ENTER:
		return


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var new_hover := _row_at((event as InputEventMouseMotion).position)
		if new_hover != _hover_row:
			_hover_row = new_hover
			queue_redraw()


## Return the menu entry row index under pixel position `px`, or -1.
func _row_at(px: Vector2) -> int:
	if _entries.is_empty():
		return -1
	var rows_h := HEADER_H + _entries.size() * ROW_H + PAD
	if px.x < MENU_X or px.x > MENU_X + MENU_W:
		return -1
	if px.y < MENU_Y + HEADER_H or px.y > MENU_Y + rows_h:
		return -1
	var rel_y := px.y - (MENU_Y + HEADER_H)
	return int(rel_y / ROW_H)


# ---------------------------------------------------------------------------
# Draw
# ---------------------------------------------------------------------------

func _draw() -> void:
	if _entries.is_empty():
		return

	var total_h: int = HEADER_H + _entries.size() * ROW_H + PAD
	# Background panel.
	draw_rect(Rect2(MENU_X, MENU_Y, MENU_W, total_h), COL_BG)
	draw_rect(Rect2(MENU_X, MENU_Y, MENU_W, total_h), COL_BORDER, false, 1.0)

	# Header.
	draw_string(
		ThemeDB.fallback_font,
		Vector2(MENU_X + PAD, MENU_Y + HEADER_H - 6.0),
		"Powers",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		14,
		COL_HEADER_TEXT
	)

	# Rows.
	for i: int in range(_entries.size()):
		var entry: Dictionary = _entries[i]
		var ry := MENU_Y + HEADER_H + i * ROW_H
		# Row background: active or hover.
		if entry.power_id == _active_power_id:
			draw_rect(Rect2(MENU_X + 1, ry, MENU_W - 2, ROW_H), COL_ACTIVE)
		elif i == _hover_row:
			draw_rect(Rect2(MENU_X + 1, ry, MENU_W - 2, ROW_H), COL_ITEM_HOVER)

		var label: String = entry.name
		if entry.count > 1:
			label = "%s  ×%d" % [entry.name, entry.count]
		draw_string(
			ThemeDB.fallback_font,
			Vector2(MENU_X + PAD, ry + ROW_H - 6.0),
			label,
			HORIZONTAL_ALIGNMENT_LEFT,
			MENU_W - PAD * 2,
			13,
			COL_ITEM_TEXT
		)
