## ui_shot.gd — Headless-renderable snapshot harness for title/pause UI.
##
## Accepts a user arg: "title" or "pause".
## Renders one frame of the requested UI, saves .qa/frame.png, then quits.
##
## Usage (run from inside the godot/ directory):
##   bash scripts/godot.sh --path . res://tools/ui_shot.tscn -- title
##   bash scripts/godot.sh --path . res://tools/ui_shot.tscn -- pause
##
## Note: run WITHOUT --headless so the RenderingServer is active and the
## viewport texture is populated.  The -s flag (script mode) still allows
## headless rendering via a real window.
##
## Output: .qa/frame.png  (860×560 PNG)
## Stdout: "ui_shot: frame.png saved err=0 size=860x560"
extends Node2D

const GameState   = preload("res://src/game_state.gd")
const Board       = preload("res://src/board.gd")
const Renderer    = preload("res://src/renderer.gd")
const PowerMenu   = preload("res://src/power_menu.gd")
const TitleScreen = preload("res://src/title.gd")
const PauseOverlay = preload("res://src/pause_overlay.gd")

const QA_DIR: String = "res://.qa"


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var mode: String = "title"
	for a: String in args:
		if a == "title" or a == "pause":
			mode = a
			break

	print("ui_shot: mode=%s" % mode)

	if mode == "title":
		_setup_title()
	else:
		_setup_pause()

	await RenderingServer.frame_post_draw
	_save_frame()
	get_tree().quit()


func _setup_title() -> void:
	var title: Node2D = TitleScreen.new()
	add_child(title)
	# Force one draw pass before the await.
	title.queue_redraw()


func _setup_pause() -> void:
	# Build a mid-game state so the board renders behind the overlay.
	var state = Board.create_initial_state(12345)

	var renderer: Node2D = Renderer.new()
	add_child(renderer)
	renderer.load_state(state, {
		"ai_thinking": false,
		"mode": "vsai",
		"difficulty": "medium",
	})

	var menu: Node2D = PowerMenu.new()
	add_child(menu)
	menu.update(state)

	var overlay: Node2D = PauseOverlay.new()
	add_child(overlay)
	overlay.queue_redraw()


func _save_frame() -> void:
	var abs_qa: String = ProjectSettings.globalize_path(QA_DIR)
	var dir_err: int = DirAccess.make_dir_recursive_absolute(abs_qa)
	if dir_err != OK and dir_err != ERR_ALREADY_EXISTS:
		push_error("ui_shot: could not create .qa/ dir, err=%d" % dir_err)

	var img: Image = get_viewport().get_texture().get_image()
	var png_path: String = QA_DIR + "/frame.png"
	var png_err: int = img.save_png(png_path)
	print("ui_shot: frame.png saved err=%d size=%dx%d" % [
		png_err, img.get_width(), img.get_height()
	])
