## main.gd — Interactive NNQR controller (C4).
##
## Launched by main.tscn when no --scenario arg is present.
## When --scenario IS present, ScenarioRunner takes over via its own scene.
##
## Mouse-only interaction:
##   - Left click on a board tile → controller.handle_tile_click
##   - Left click on power menu row → activate_power; if needs-target,
##     next board click resolves it.
##   - "New Game" affordance: press N to reset.
##
## vs-AI: player 1 = human, player 2 = AI (medium difficulty by default).
## After each human move the AI responds automatically.
extends Node2D

const GameState   = preload("res://src/game_state.gd")
const Board       = preload("res://src/board.gd")
const Renderer    = preload("res://src/renderer.gd")
const PowerMenu   = preload("res://src/power_menu.gd")
const Controller  = preload("res://src/controller.gd")
const RNG         = preload("res://src/rng.gd")
const AI          = preload("res://src/ai/ai.gd")
const ScenarioRunner = preload("res://src/scenario_runner.gd")

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

const VS_AI       : bool   = true
const AI_PLAYER   : int    = 2
const DIFFICULTY  : String = "medium"

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var _game_state               = null    ## GameState
var _renderer: Node2D         = null
var _power_menu: Node2D       = null
var _rng                      = null

## Power-targeting mode: null or {"piece": Piece, "power_id": String, "target_tiles": Array}
var _power_mode               = null
## True while the AI is computing its move (guard against double-clicks).
var _ai_thinking: bool        = false


# ---------------------------------------------------------------------------
# _ready — check for --scenario arg first; if present, hand off.
# ---------------------------------------------------------------------------

func _ready() -> void:
	# Check for --scenario arg; if present, delegate to ScenarioRunner inline.
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for i in range(args.size()):
		if args[i] == "--scenario":
			# Add a ScenarioRunner as a sibling node (deferred) and stop here.
			var runner: Node2D = ScenarioRunner.new()
			get_parent().call_deferred("add_child", runner)
			# Remove self after runner is added so it doesn't render.
			call_deferred("queue_free")
			return

	_start_game()


func _start_game() -> void:
	# Clean up previous nodes if restarting.
	if _renderer != null:
		_renderer.queue_free()
		_renderer = null
	if _power_menu != null:
		_power_menu.queue_free()
		_power_menu = null

	_rng = RNG.new(1)
	_game_state = Board.create_initial_state(1)
	_power_mode = null
	_ai_thinking = false

	_renderer = Renderer.new()
	add_child(_renderer)

	_power_menu = PowerMenu.new()
	_power_menu.power_chosen.connect(_on_power_chosen)
	add_child(_power_menu)

	_refresh_display()

	# If vs-AI and AI goes first, schedule the AI turn.
	if VS_AI and _game_state.current_player == AI_PLAYER:
		_schedule_ai_turn()


# ---------------------------------------------------------------------------
# Input
# ---------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	# N = new game.
	if event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed and ke.keycode == KEY_N:
			_start_game()
			return

	if not event is InputEventMouseButton:
		return
	var me := event as InputEventMouseButton
	if not me.pressed or me.button_index != MOUSE_BUTTON_LEFT:
		return

	if _ai_thinking or _game_state == null or _game_state.status != "playing":
		return
	# Block human input on AI's turn.
	if VS_AI and _game_state.current_player == AI_PLAYER:
		return

	var tile = _renderer.pixel_to_tile(me.position)
	if tile == null:
		# Click outside board: cancel power mode.
		if _power_mode != null:
			_power_mode = null
			_renderer.set_power_target_tiles([])
			_power_menu.set_active_power("")
		return

	var row: int = tile.row
	var col: int = tile.col

	if _power_mode != null:
		# In targeting mode: check if this tile is a valid target.
		var found_target: bool = false
		for t in _power_mode.target_tiles:
			if t.row == row and t.col == col:
				found_target = true
				break
		if found_target:
			_apply_power_with_target(row, col)
		else:
			# Cancel targeting.
			_power_mode = null
			_renderer.set_power_target_tiles([])
			_power_menu.set_active_power("")
		return

	# Normal tile click.
	_game_state = Controller.handle_tile_click(_game_state, row, col)
	_refresh_display()

	# After a successful human move, check if AI should respond.
	_maybe_trigger_ai()


func _on_power_chosen(power_id: String) -> void:
	if _ai_thinking or _game_state == null or _game_state.status != "playing":
		return
	if VS_AI and _game_state.current_player == AI_PLAYER:
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
		# Immediate power: apply and advance.
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
	if not VS_AI:
		return
	if _game_state.status != "playing":
		return
	if _game_state.current_player == AI_PLAYER:
		_schedule_ai_turn()


func _schedule_ai_turn() -> void:
	_ai_thinking = true
	# Defer one frame so the display updates before the AI runs.
	await get_tree().process_frame
	_run_ai_turn()


func _run_ai_turn() -> void:
	if _game_state.status != "playing" or _game_state.current_player != AI_PLAYER:
		_ai_thinking = false
		return
	var rng := RNG.new(_game_state.seed + _game_state.turn)
	_game_state = Controller.ai_take_turn(_game_state, DIFFICULTY, rng)
	_ai_thinking = false
	_refresh_display()


# ---------------------------------------------------------------------------
# Display
# ---------------------------------------------------------------------------

func _refresh_display() -> void:
	if _renderer != null:
		_renderer.load_state(_game_state)
	if _power_menu != null:
		_power_menu.update(_game_state)
