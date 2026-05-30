## main.gd — Interactive NNQR controller (C5).
##
## State machine: TITLE → PLAYING → PAUSED (→ TITLE or back to PLAYING).
##
## Launched by main.tscn when no --scenario arg is present.
## When --scenario IS present, ScenarioRunner takes over via its own scene
## and this node removes itself immediately — no title screen appears.
##
## Mouse interaction:
##   - Title screen: click to select mode/difficulty, click Start Game.
##   - Board tile click → controller.handle_tile_click
##   - Power menu click → activate_power; if needs-target, next board click
##     resolves it.
##   - Keys 1-9: activate Nth power of selected piece (deduplicated order).
##   - N: new game (jumps back to title).
##   - Escape: cancel power targeting (priority) OR toggle pause overlay.
##
## vs-AI: player 1 = human, player 2 = AI.
## Hotseat: both players human — AI never fires.
extends Node2D

const GameState      = preload("res://src/game_state.gd")
const Board          = preload("res://src/board.gd")
const Renderer       = preload("res://src/renderer.gd")
const PowerMenu      = preload("res://src/power_menu.gd")
const Controller     = preload("res://src/controller.gd")
const RNG            = preload("res://src/rng.gd")
const AI             = preload("res://src/ai/ai.gd")
const ScenarioRunner = preload("res://src/scenario_runner.gd")
const TitleScreen    = preload("res://src/title.gd")
const PauseOverlay   = preload("res://src/pause_overlay.gd")

# ---------------------------------------------------------------------------
# State machine
# ---------------------------------------------------------------------------

enum AppState { TITLE, PLAYING, PAUSED }

var _app_state: AppState = AppState.TITLE

# ---------------------------------------------------------------------------
# Runtime config (set from title screen signal)
# ---------------------------------------------------------------------------

const AI_PLAYER: int = 2

var _vs_ai: bool       = true
var _difficulty: String = "medium"

# ---------------------------------------------------------------------------
# Nodes
# ---------------------------------------------------------------------------

var _title: Node2D        = null
var _game_state           = null    ## GameState
var _renderer: Node2D     = null
var _power_menu: Node2D   = null
var _pause_overlay: Node2D = null

## Power-targeting mode: null or {piece, power_id, target_tiles}.
var _power_mode           = null
## True while the AI is computing its move.
var _ai_thinking: bool    = false


# ---------------------------------------------------------------------------
# _ready — check for --scenario arg first; if present, hand off immediately.
# ---------------------------------------------------------------------------

func _ready() -> void:
	# CRITICAL: preserve the scenario early-return so the QA see-harness works.
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for i: int in range(args.size()):
		if args[i] == "--scenario":
			var runner: Node2D = ScenarioRunner.new()
			get_parent().call_deferred("add_child", runner)
			call_deferred("queue_free")
			return

	_show_title()


# ---------------------------------------------------------------------------
# Title screen
# ---------------------------------------------------------------------------

func _show_title() -> void:
	_app_state = AppState.TITLE

	# Tear down any running game.
	_teardown_game()

	# Tear down previous title if any.
	if _title != null:
		_title.queue_free()
		_title = null

	_title = TitleScreen.new()
	_title.start_requested.connect(_on_start_requested)
	add_child(_title)


func _on_start_requested(mode: String, difficulty: String) -> void:
	_vs_ai = (mode == "vsai")
	_difficulty = difficulty

	if _title != null:
		_title.queue_free()
		_title = null

	_start_game()


# ---------------------------------------------------------------------------
# Game start / teardown
# ---------------------------------------------------------------------------

func _start_game() -> void:
	_app_state = AppState.PLAYING

	_teardown_game()

	var seed: int = Time.get_ticks_msec()
	_game_state = Board.create_initial_state(seed)
	_power_mode = null
	_ai_thinking = false

	_renderer = Renderer.new()
	add_child(_renderer)

	_power_menu = PowerMenu.new()
	_power_menu.power_chosen.connect(_on_power_chosen)
	add_child(_power_menu)

	_refresh_display()

	if _vs_ai and _game_state.current_player == AI_PLAYER:
		_schedule_ai_turn()


func _teardown_game() -> void:
	if _pause_overlay != null:
		_pause_overlay.queue_free()
		_pause_overlay = null
	if _renderer != null:
		_renderer.queue_free()
		_renderer = null
	if _power_menu != null:
		_power_menu.queue_free()
		_power_menu = null
	_game_state = null
	_power_mode = null
	_ai_thinking = false


# ---------------------------------------------------------------------------
# Pause overlay
# ---------------------------------------------------------------------------

func _show_pause() -> void:
	_app_state = AppState.PAUSED
	if _pause_overlay != null:
		_pause_overlay.queue_free()
		_pause_overlay = null
	_pause_overlay = PauseOverlay.new()
	_pause_overlay.resume_pressed.connect(_on_resume_pressed)
	_pause_overlay.quit_pressed.connect(_on_quit_to_title)
	add_child(_pause_overlay)


func _hide_pause() -> void:
	_app_state = AppState.PLAYING
	if _pause_overlay != null:
		_pause_overlay.queue_free()
		_pause_overlay = null


func _on_resume_pressed() -> void:
	_hide_pause()


func _on_quit_to_title() -> void:
	_show_title()


# ---------------------------------------------------------------------------
# Input
# ---------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		_handle_mouse_input(event)
		return

	var ke := event as InputEventKey
	if not ke.pressed:
		return

	match _app_state:
		AppState.TITLE:
			pass  # Title screen handles its own input.

		AppState.PLAYING:
			_handle_key_playing(ke)

		AppState.PAUSED:
			# Esc while paused → resume.
			if ke.keycode == KEY_ESCAPE:
				_hide_pause()


func _handle_key_playing(ke: InputEventKey) -> void:
	match ke.keycode:
		KEY_N:
			_show_title()
		KEY_ESCAPE:
			if _power_mode != null:
				# Targeting mode takes priority over pause.
				_power_mode = null
				_renderer.set_power_target_tiles([])
				_power_menu.set_active_power("")
			else:
				_show_pause()
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9:
			_handle_number_key(ke.keycode)


## Activate the Nth power of the currently selected piece (1-indexed).
## Power list = deduplicated first-occurrence order of selected_piece.powers.
func _handle_number_key(keycode: Key) -> void:
	if _game_state == null or _game_state.status != "playing":
		return
	if _ai_thinking:
		return
	if _vs_ai and _game_state.current_player == AI_PLAYER:
		return

	var sel = _game_state.selected
	if sel == null:
		return
	var piece = Board.piece_at(_game_state, sel.row, sel.col)
	if piece == null:
		return

	# Deduplicate powers preserving first-occurrence order.
	var seen: Dictionary = {}
	var ordered: Array = []
	for p_id: String in piece.powers:
		if not seen.has(p_id):
			seen[p_id] = true
			ordered.append(p_id)

	# Map keycode → 0-indexed slot.
	var idx: int = keycode - KEY_1   # KEY_1=0, KEY_2=1, …, KEY_9=8
	if idx < 0 or idx >= ordered.size():
		return

	_on_power_chosen(ordered[idx])


func _handle_mouse_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var me := event as InputEventMouseButton
	if not me.pressed or me.button_index != MOUSE_BUTTON_LEFT:
		return

	if _app_state != AppState.PLAYING:
		return
	if _ai_thinking or _game_state == null or _game_state.status != "playing":
		return
	if _vs_ai and _game_state.current_player == AI_PLAYER:
		return

	var tile = _renderer.pixel_to_tile(me.position)
	if tile == null:
		if _power_mode != null:
			_power_mode = null
			_renderer.set_power_target_tiles([])
			_power_menu.set_active_power("")
		return

	var row: int = tile.row
	var col: int = tile.col

	if _power_mode != null:
		var found_target: bool = false
		for t: Dictionary in _power_mode.target_tiles:
			if t.row == row and t.col == col:
				found_target = true
				break
		if found_target:
			_apply_power_with_target(row, col)
		else:
			_power_mode = null
			_renderer.set_power_target_tiles([])
			_power_menu.set_active_power("")
		return

	_game_state = Controller.handle_tile_click(_game_state, row, col)
	_refresh_display()
	_maybe_trigger_ai()


func _on_power_chosen(power_id: String) -> void:
	if _ai_thinking or _game_state == null or _game_state.status != "playing":
		return
	if _vs_ai and _game_state.current_player == AI_PLAYER:
		return

	var sel = _game_state.selected
	if sel == null:
		return
	var piece = Board.piece_at(_game_state, sel.row, sel.col)
	if piece == null or not piece.powers.has(power_id):
		return

	# Toggle off if already armed.
	if _power_mode != null and _power_mode.power_id == power_id:
		_power_mode = null
		_renderer.set_power_target_tiles([])
		_power_menu.set_active_power("")
		return

	var result: Dictionary = Controller.activate_power(_game_state, piece, power_id, null)
	if result.mode == Controller.MODE_AWAITING_TARGET:
		_power_mode = {
			"piece": piece,
			"power_id": power_id,
			"target_tiles": result.target_tiles,
		}
		_renderer.set_power_target_tiles(result.target_tiles)
		_power_menu.set_active_power(power_id)
	else:
		_game_state = result.state
		_power_mode = null
		_renderer.set_power_target_tiles([])
		_power_menu.set_active_power("")
		_refresh_display()
		_maybe_trigger_ai()


func _apply_power_with_target(row: int, col: int) -> void:
	if _power_mode == null:
		return
	var result: Dictionary = Controller.activate_power(
		_game_state, _power_mode.piece, _power_mode.power_id, {"row": row, "col": col})
	_game_state = result.state
	_power_mode = null
	_renderer.set_power_target_tiles([])
	_power_menu.set_active_power("")
	_refresh_display()
	_maybe_trigger_ai()


# ---------------------------------------------------------------------------
# AI
# ---------------------------------------------------------------------------

func _maybe_trigger_ai() -> void:
	if not _vs_ai:
		return   # Hotseat: no AI.
	if _game_state == null or _game_state.status != "playing":
		return
	if _game_state.current_player == AI_PLAYER:
		_schedule_ai_turn()


func _schedule_ai_turn() -> void:
	_ai_thinking = true
	await get_tree().process_frame
	_run_ai_turn()


func _run_ai_turn() -> void:
	if _game_state == null or _game_state.status != "playing" or _game_state.current_player != AI_PLAYER:
		_ai_thinking = false
		return
	var rng := RNG.new(_game_state.seed + _game_state.turn)
	_game_state = Controller.ai_take_turn(_game_state, _difficulty, rng)
	_ai_thinking = false
	_refresh_display()


# ---------------------------------------------------------------------------
# Display
# ---------------------------------------------------------------------------

func _refresh_display() -> void:
	if _renderer != null:
		var mode_str: String = "vsai" if _vs_ai else "hotseat"
		_renderer.load_state(_game_state, {
			"ai_thinking": _ai_thinking,
			"mode": mode_str,
			"difficulty": _difficulty,
		})
	if _power_menu != null:
		_power_menu.update(_game_state)
