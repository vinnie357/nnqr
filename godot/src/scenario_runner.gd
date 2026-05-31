## ScenarioRunner — see-harness for the AI QA loop.
##
## Invoked with:
##   godot --headless --path . -- --scenario res://scenarios/<name>.json
##
## Reads the scenario JSON, builds a GameState, optionally applies an
## "inputs" action list through the controller, renders one frame,
## writes .qa/frame.png (viewport screenshot) and .qa/state.json,
## then quits.  With no --scenario flag the initial board is used.
##
## Backward compatible: scenarios without an "inputs" key behave exactly
## as before.
##
## Input action format (each item in the "inputs" array):
##   {"type": "click",    "row": R, "col": C}
##     — routes through Controller.handle_tile_click(state, R, C)
##   {"type": "activate", "power_id": "...", "row": R, "col": C}
##     — routes through Controller.activate_power with target {row,col}
##   {"type": "activate", "power_id": "..."}
##     — immediate power activation (no target)
##   {"type": "ai_turn", "difficulty": "medium"}
##     — applies one AI turn (default difficulty "medium")
extends Node2D

const GameState  = preload("res://src/game_state.gd")
const Renderer   = preload("res://src/renderer.gd")
const Controller = preload("res://src/controller.gd")
const Board      = preload("res://src/board.gd")
const RNG        = preload("res://src/rng.gd")
const PowerMenu  = preload("res://src/power_menu.gd")

const QA_DIR: String = "res://.qa"

var _renderer: Node2D = null
var _menu: Node2D = null


func _ready() -> void:
	# Apply optional --size WxH override before rendering so captures are at
	# the requested resolution.  This lets the lead validate fill at multiple sizes.
	_apply_size_arg()

	_renderer = Renderer.new()
	add_child(_renderer)

	var parse_result: Dictionary = _resolve_state_and_inputs()
	var state = parse_result["state"]
	var inputs: Array = parse_result.get("inputs", [])
	var hud_info: Dictionary = parse_result.get("hud_info", {})

	# Apply input actions before rendering.
	state = _apply_inputs(state, inputs)

	# Pass hud_info to renderer so C5 HUD extras are visible in QA screenshots.
	_renderer.load_state(state, hud_info)

	_menu = PowerMenu.new()
	add_child(_menu)
	_menu.set_renderer(_renderer)
	_menu.update(state)

	# Wait for one rendered frame before capturing.
	await RenderingServer.frame_post_draw
	_save_artifacts(state)
	get_tree().quit()


# ---------------------------------------------------------------------------
# Window size override (--size WxH)
# ---------------------------------------------------------------------------

## Parse --size WxH from user CLI args and resize the window + viewport.
## Example: --size 1600x1000  → window becomes 1600×1000 before capture.
## If the arg is absent or malformed the project default is used unchanged.
func _apply_size_arg() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for i: int in range(args.size()):
		if args[i] == "--size" and i + 1 < args.size():
			var size_str: String = args[i + 1]
			var parts: PackedStringArray = size_str.split("x")
			if parts.size() == 2:
				var w: int = int(parts[0])
				var h: int = int(parts[1])
				if w > 0 and h > 0:
					get_window().size = Vector2i(w, h)
					print("ScenarioRunner: window resized to %dx%d" % [w, h])
				else:
					push_warning("ScenarioRunner: --size has zero/negative values: " + size_str)
			else:
				push_warning("ScenarioRunner: --size format must be WxH, got: " + size_str)
			break


# ---------------------------------------------------------------------------
# State + inputs resolution
# ---------------------------------------------------------------------------

## Parse --scenario from user CLI args; return initial state when absent.
## Returns {"state": GameState, "inputs": Array}.
func _resolve_state_and_inputs() -> Dictionary:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var scenario_path: String = ""
	for i: int in range(args.size()):
		if args[i] == "--scenario" and i + 1 < args.size():
			scenario_path = args[i + 1]
			break

	if scenario_path == "":
		print("ScenarioRunner: no --scenario arg; using initial board.")
		var state = GameState.new()
		state.init_board()
		return {"state": state, "inputs": [], "hud_info": {}}

	print("ScenarioRunner: loading scenario: ", scenario_path)
	return _load_scenario(scenario_path)


## Load a JSON scenario file and return {"state": GameState, "inputs": Array}.
func _load_scenario(path: String) -> Dictionary:
	var fallback_state = GameState.new()
	fallback_state.init_board()
	var fallback: Dictionary = {"state": fallback_state, "inputs": []}

	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("ScenarioRunner: cannot open scenario file: " + path)
		return fallback
	var text: String = f.get_as_text()
	f.close()

	var result: Variant = JSON.parse_string(text)
	if result == null:
		push_error("ScenarioRunner: invalid JSON in: " + path)
		return fallback

	var dict: Dictionary = result as Dictionary
	var state = GameState.new()
	state.load_dict(dict)

	var inputs: Array = []
	if dict.has("inputs") and dict["inputs"] is Array:
		inputs = dict["inputs"] as Array
		print("ScenarioRunner: %d input action(s) to apply." % inputs.size())

	# Optional hud_info object: passed through to renderer.load_state for C5 QA.
	var hud_info: Dictionary = {}
	if dict.has("hud_info") and dict["hud_info"] is Dictionary:
		hud_info = dict["hud_info"] as Dictionary
		print("ScenarioRunner: hud_info keys: %s" % str(hud_info.keys()))

	return {"state": state, "inputs": inputs, "hud_info": hud_info}


# ---------------------------------------------------------------------------
# Input action application
# ---------------------------------------------------------------------------

## Apply an ordered list of input actions through the Controller.
func _apply_inputs(state, inputs: Array):
	for action in inputs:
		if not action is Dictionary:
			continue
		var type: String = str(action.get("type", ""))
		match type:
			"click":
				var row: int = int(action.get("row", 0))
				var col: int = int(action.get("col", 0))
				print("ScenarioRunner: input click (%d,%d)" % [row, col])
				state = Controller.handle_tile_click(state, row, col)

			"activate":
				var power_id: String = str(action.get("power_id", ""))
				var piece = null
				if state.selected != null:
					piece = Board.piece_at(state, state.selected.row, state.selected.col)
				if piece == null:
					print("ScenarioRunner: activate skipped — no selected piece")
					continue
				var target = null
				if action.has("row") and action.has("col"):
					target = {"row": int(action.get("row", 0)), "col": int(action.get("col", 0))}
				print("ScenarioRunner: input activate %s target=%s" % [power_id, str(target)])
				var result: Dictionary = Controller.activate_power(state, piece, power_id, target)
				state = result["state"]

			"ai_turn":
				var diff: String = str(action.get("difficulty", "medium"))
				var rng := RNG.new(state.seed + state.turn)
				print("ScenarioRunner: input ai_turn difficulty=%s" % diff)
				state = Controller.ai_take_turn(state, diff, rng)

			_:
				print("ScenarioRunner: unknown input type '%s', skipping." % type)

	return state


# ---------------------------------------------------------------------------
# Artifact output
# ---------------------------------------------------------------------------

## Write .qa/frame.png (viewport) and .qa/state.json.
func _save_artifacts(state) -> void:
	var abs_qa: String = ProjectSettings.globalize_path(QA_DIR)
	var dir_err: int = DirAccess.make_dir_recursive_absolute(abs_qa)
	if dir_err != OK and dir_err != ERR_ALREADY_EXISTS:
		push_error("ScenarioRunner: could not create .qa/ dir, err=%d" % dir_err)

	var img: Image = get_viewport().get_texture().get_image()
	var png_path: String = QA_DIR + "/frame.png"
	var png_err: int = img.save_png(png_path)
	print("ScenarioRunner: frame.png saved err=%d size=%dx%d" % [
		png_err, img.get_width(), img.get_height()
	])

	var json_path: String = QA_DIR + "/state.json"
	var f2 := FileAccess.open(json_path, FileAccess.WRITE)
	if f2 == null:
		push_error("ScenarioRunner: cannot write state.json (err=%d)" % FileAccess.get_open_error())
		return
	f2.store_string(JSON.stringify(state.to_dict(), "\t"))
	f2.close()
	print("ScenarioRunner: state.json saved")
