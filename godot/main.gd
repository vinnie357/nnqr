extends Node2D

# Probe: render a 10x8 board with pieces, screenshot the viewport to a PNG,
# dump a state JSON, then quit. Verifies whether the AI can SEE Godot output
# (Read-on-PNG) in this environment.

const TILE := 56
const MARGIN := 40
const COLS := 10
const ROWS := 8

func _ready() -> void:
	for r in range(ROWS):
		for c in range(COLS):
			var t := ColorRect.new()
			t.position = Vector2(MARGIN + c * TILE, MARGIN + r * TILE)
			t.size = Vector2(TILE - 2, TILE - 2)
			t.color = Color(0.2, 0.22, 0.29) if (r + c) % 2 == 0 else Color(0.16, 0.18, 0.24)
			add_child(t)
			if r < 2 or r >= ROWS - 2:
				var p := ColorRect.new()
				p.position = Vector2(MARGIN + c * TILE + 10, MARGIN + r * TILE + 10)
				p.size = Vector2(TILE - 22, TILE - 22)
				p.color = Color(0.29, 0.55, 0.94) if r < 2 else Color(0.94, 0.35, 0.35)
				add_child(p)

	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png("res://probe.png")
	var f := FileAccess.open("res://probe-state.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"board": "10x8", "save_png_err": err}))
		f.close()
	print("PROBE: save_png err=", err)
	get_tree().quit()
