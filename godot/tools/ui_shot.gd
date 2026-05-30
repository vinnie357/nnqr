## ui_shot.gd — Headless-renderable snapshot harness for title/pause UI.
##
## A standalone SceneTree script (runnable directly via --script — no scene
## wrapper). Accepts a user arg: "title" or "pause". Builds one frame of the
## requested UI under the root window, saves .qa/frame.png, then quits.
##
## Usage (run from inside the godot/ directory):
##   bash scripts/godot.sh --path . --script res://tools/ui_shot.gd -- title
##   bash scripts/godot.sh --path . --script res://tools/ui_shot.gd -- pause
##
## Note: run WITHOUT --headless so the RenderingServer is active and the
## root viewport texture is populated.
##
## Output: .qa/frame.png  (860×560 PNG)
## Stdout: "ui_shot: frame.png saved err=0 size=860x560"
extends SceneTree

const Board        = preload("res://src/board.gd")
const Renderer     = preload("res://src/renderer.gd")
const PowerMenu    = preload("res://src/power_menu.gd")
const TitleScreen  = preload("res://src/title.gd")
const PauseOverlay = preload("res://src/pause_overlay.gd")

const QA_DIR: String = "res://.qa"


func _initialize() -> void:
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

	# Let the freshly-added nodes enter the tree and draw before capturing.
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	_save_frame()
	quit()


func _setup_title() -> void:
	var title: Node2D = TitleScreen.new()
	root.add_child(title)
	title.queue_redraw()


func _setup_pause() -> void:
	# Build a mid-game state so the board renders behind the overlay.
	var state = Board.create_initial_state(12345)

	var renderer: Node2D = Renderer.new()
	root.add_child(renderer)
	renderer.load_state(state, {
		"ai_thinking": false,
		"mode": "vsai",
		"difficulty": "medium",
	})

	var menu: Node2D = PowerMenu.new()
	root.add_child(menu)
	menu.update(state)

	var overlay: Node2D = PauseOverlay.new()
	root.add_child(overlay)
	overlay.queue_redraw()


func _save_frame() -> void:
	var abs_qa: String = ProjectSettings.globalize_path(QA_DIR)
	var dir_err: int = DirAccess.make_dir_recursive_absolute(abs_qa)
	if dir_err != OK and dir_err != ERR_ALREADY_EXISTS:
		push_error("ui_shot: could not create .qa/ dir, err=%d" % dir_err)

	var img: Image = root.get_texture().get_image()
	var png_path: String = QA_DIR + "/frame.png"
	var png_err: int = img.save_png(png_path)
	print("ui_shot: frame.png saved err=%d size=%dx%d" % [
		png_err, img.get_width(), img.get_height()
	])
