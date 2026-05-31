## power_menu.gd — UI node listing the selected piece's collected powers.
##
## When a piece is selected and has powers, draws a panel to the right of the
## board listing each power name + count. Clicking a row emits `power_chosen`
## with the power_id. When no piece is selected or it has no powers, the menu
## is empty / hidden.
##
## C5 enhancements:
##   - Number prefix on every row ("1. Name  ×2").
##   - Overheat warning: count >= 7 shows "⚠" suffix + orange warning colour.
##   - Targeting instruction line ("Click a highlighted tile · Esc to cancel")
##     when a power is armed (_active_power_id != "").
##
## C7 enhancements (responsive):
##   - Panel positioned in the reserved right strip via the renderer's
##     get_menu_x() / get_menu_y() — follows live viewport size.
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
# Layout constants (panel-relative dimensions — position is dynamic)
# ---------------------------------------------------------------------------

const MENU_W       : int = 210
const ROW_H        : int = 24
const HEADER_H     : int = 28
const PAD          : int = 8
## Extra height reserved for the targeting instruction line below the rows.
const INSTRUCT_H   : int = 32

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
## Overheat warning colour (mirrors web C.overheatWarning = #ff4422).
const COL_OVERHEAT    := Color(1.0, 0.267, 0.133)
## Instruction text (dim white).
const COL_INSTRUCT    := Color(0.800, 0.820, 0.880, 0.80)


## Internal state: ordered list of {power_id, count, name}.
var _entries: Array = []
## Currently active (armed) power id, or "".
var _active_power_id: String = ""
## Track hover row index for visual feedback (-1 = none).
var _hover_row: int = -1
## Reference to the renderer node so we can read its computed menu position.
var _renderer: Node2D = null


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Set the renderer reference so this menu can query its computed layout.
## Call this once after adding both nodes to the scene.
func set_renderer(r: Node2D) -> void:
	_renderer = r


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
# Dynamic position helpers
# ---------------------------------------------------------------------------

## Return the current menu X from the renderer's computed layout, or a fallback.
func _menu_x() -> float:
	if _renderer != null and _renderer.has_method("get_menu_x"):
		return _renderer.get_menu_x()
	# Fallback: right of a default-sized viewport.
	return get_viewport_rect().size.x - float(MENU_W) - 16.0


## Return the current menu Y from the renderer's computed layout, or a fallback.
func _menu_y() -> float:
	if _renderer != null and _renderer.has_method("get_menu_y"):
		return _renderer.get_menu_y()
	return 20.0


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
	var mx: float = _menu_x()
	var my: float = _menu_y()
	var rows_h := HEADER_H + _entries.size() * ROW_H + PAD
	if px.x < mx or px.x > mx + float(MENU_W):
		return -1
	if px.y < my + float(HEADER_H) or px.y > my + rows_h:
		return -1
	var rel_y := px.y - (my + float(HEADER_H))
	return int(rel_y / ROW_H)


# ---------------------------------------------------------------------------
# Draw
# ---------------------------------------------------------------------------

func _draw() -> void:
	if _entries.is_empty():
		return

	var mx: float = _menu_x()
	var my: float = _menu_y()

	# Total panel height: add instruction row when a power is armed.
	var instruct_extra: int = INSTRUCT_H if _active_power_id != "" else 0
	var total_h: int = HEADER_H + _entries.size() * ROW_H + PAD + instruct_extra
	# Background panel.
	draw_rect(Rect2(mx, my, float(MENU_W), float(total_h)), COL_BG)
	draw_rect(Rect2(mx, my, float(MENU_W), float(total_h)), COL_BORDER, false, 1.0)

	# Header.
	draw_string(
		ThemeDB.fallback_font,
		Vector2(mx + float(PAD), my + float(HEADER_H) - 6.0),
		"Powers",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		14,
		COL_HEADER_TEXT
	)

	# Rows.
	for i: int in range(_entries.size()):
		var entry: Dictionary = _entries[i]
		var ry := my + float(HEADER_H) + float(i * ROW_H)
		# Row background: active or hover.
		if entry.power_id == _active_power_id:
			draw_rect(Rect2(mx + 1.0, ry, float(MENU_W) - 2.0, float(ROW_H)), COL_ACTIVE)
		elif i == _hover_row:
			draw_rect(Rect2(mx + 1.0, ry, float(MENU_W) - 2.0, float(ROW_H)), COL_ITEM_HOVER)

		# Number prefix (1-based).
		var label: String = "%d. %s" % [i + 1, entry.name]
		if entry.count > 1:
			label = "%d. %s  ×%d" % [i + 1, entry.name, entry.count]

		# Overheat warning marker and colour.
		var text_col: Color = COL_ITEM_TEXT
		if entry.count >= 7:
			label = label + "  ⚠"
			text_col = COL_OVERHEAT

		draw_string(
			ThemeDB.fallback_font,
			Vector2(mx + float(PAD), ry + float(ROW_H) - 6.0),
			label,
			HORIZONTAL_ALIGNMENT_LEFT,
			MENU_W - PAD * 2,
			13,
			text_col
		)

	# Targeting instruction line when a power is armed.
	if _active_power_id != "":
		var iy: float = my + float(HEADER_H) + float(_entries.size() * ROW_H + PAD) + 2.0
		draw_string(
			ThemeDB.fallback_font,
			Vector2(mx + float(PAD), iy + 14.0),
			"Click a highlighted tile",
			HORIZONTAL_ALIGNMENT_LEFT,
			MENU_W - PAD * 2,
			12,
			COL_INSTRUCT
		)
		draw_string(
			ThemeDB.fallback_font,
			Vector2(mx + float(PAD), iy + 28.0),
			"Esc to cancel",
			HORIZONTAL_ALIGNMENT_LEFT,
			MENU_W - PAD * 2,
			12,
			COL_INSTRUCT
		)
