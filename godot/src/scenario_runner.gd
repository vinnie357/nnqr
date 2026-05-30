## ScenarioRunner — see-harness for the AI QA loop.
##
## Invoked with:
##   godot --headless --path . -- --scenario res://scenarios/<name>.json
##
## Reads the scenario JSON, builds a GameState, renders one frame,
## writes .qa/frame.png (viewport screenshot) and .qa/state.json,
## then quits.  With no --scenario flag the initial board is used.
extends Node2D

const GameState = preload("res://src/game_state.gd")
const Renderer  = preload("res://src/renderer.gd")

const QA_DIR: String = "res://.qa"

var _renderer: Node2D = null


func _ready() -> void:
	_renderer = Renderer.new()
	add_child(_renderer)

	var state = _resolve_state()
	_renderer.load_state(state)

	# Wait for one rendered frame before capturing
	await RenderingServer.frame_post_draw
	_save_artifacts(state)
	get_tree().quit()


## Parse --scenario from user CLI args; return initial state when absent.
func _resolve_state():
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
		return state

	print("ScenarioRunner: loading scenario: ", scenario_path)
	return _load_scenario(scenario_path)


## Load a JSON scenario file and build a GameState from it.
func _load_scenario(path: String):
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("ScenarioRunner: cannot open scenario file: " + path)
		var state = GameState.new()
		state.init_board()
		return state
	var text: String = f.get_as_text()
	f.close()

	var result: Variant = JSON.parse_string(text)
	if result == null:
		push_error("ScenarioRunner: invalid JSON in: " + path)
		var state = GameState.new()
		state.init_board()
		return state

	var state = GameState.new()
	state.load_dict(result as Dictionary)
	return state


## Write .qa/frame.png (viewport) and .qa/state.json.
func _save_artifacts(state) -> void:
	# Ensure output directory exists
	var abs_qa: String = ProjectSettings.globalize_path(QA_DIR)
	var dir_err: int = DirAccess.make_dir_recursive_absolute(abs_qa)
	if dir_err != OK and dir_err != ERR_ALREADY_EXISTS:
		push_error("ScenarioRunner: could not create .qa/ dir, err=%d" % dir_err)

	# Viewport screenshot
	var img: Image = get_viewport().get_texture().get_image()
	var png_path: String = QA_DIR + "/frame.png"
	var png_err: int = img.save_png(png_path)
	print("ScenarioRunner: frame.png saved err=%d size=%dx%d" % [
		png_err, img.get_width(), img.get_height()
	])

	# State JSON
	var json_path: String = QA_DIR + "/state.json"
	var f2 := FileAccess.open(json_path, FileAccess.WRITE)
	if f2 == null:
		push_error("ScenarioRunner: cannot write state.json (err=%d)" % FileAccess.get_open_error())
		return
	f2.store_string(JSON.stringify(state.to_dict(), "\t"))
	f2.close()
	print("ScenarioRunner: state.json saved")
