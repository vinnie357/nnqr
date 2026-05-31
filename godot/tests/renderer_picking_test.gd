## renderer_picking_test.gd — Headless round-trip test for pixel_to_tile.
## Verifies that compute_layout_for_size + tile_iso_center + pixel_to_tile form
## a true round-trip at every board tile for three representative viewport sizes.
##
## Run: godot/scripts/godot.sh --headless --path . -s res://tests/renderer_picking_test.gd
extends SceneTree

const Renderer  = preload("res://src/renderer.gd")
const GameState = preload("res://src/game_state.gd")

func _assert(cond: bool, msg: String, fails: Array) -> void:
	if not cond:
		printerr("  FAIL: " + msg)
		fails[0] += 1


func _init() -> void:
	var fails := [0]

	# Build a flat 10×8 GameState (all heights zero, no pieces needed for layout test).
	var state = GameState.new()
	state.init_board()
	# Clear pieces — the picking test only needs the height_map (all zeros after init_board).
	state.pieces.clear()
	state.selected = null
	state.valid_moves = []
	state.orbs = []

	var r = Renderer.new()
	# Do not add to scene tree — compute_layout_for_size works without a live viewport.
	r._state = state

	var vp_sizes: Array = [
		Vector2(860.0,  560.0),
		Vector2(1280.0, 800.0),
		Vector2(1600.0, 1000.0),
	]

	# -----------------------------------------------------------------------
	# 1. Round-trip: for every tile at every viewport size, the center pixel
	#    returned by tile_iso_center must map back to the same (row, col).
	# -----------------------------------------------------------------------
	for vp in vp_sizes:
		r.compute_layout_for_size(vp)
		for row: int in range(1, 9):    # rows 1..8
			for col: int in range(1, 11):  # cols 1..10
				var center: Vector2 = r.tile_iso_center(row, col, 0)
				var t = r.pixel_to_tile(center)
				_assert(
					t != null,
					"vp=%s tile(%d,%d) center→null" % [vp, row, col],
					fails
				)
				if t != null:
					_assert(
						t.row == row,
						"vp=%s tile(%d,%d) row round-trip: got %d" % [vp, row, col, t.row],
						fails
					)
					_assert(
						t.col == col,
						"vp=%s tile(%d,%d) col round-trip: got %d" % [vp, row, col, t.col],
						fails
					)

	# -----------------------------------------------------------------------
	# 2. Off-center clicks: ±quarter-tile displacement must still land on the
	#    correct tile for a sample of interior tiles (away from boundaries).
	# -----------------------------------------------------------------------
	var sample_tiles: Array = [
		[3, 4], [3, 7], [5, 2], [5, 9], [6, 5],
	]
	for vp in vp_sizes:
		r.compute_layout_for_size(vp)
		var qw: float = r._tile_w / 4.0
		var qh: float = r._tile_h / 4.0
		for pair in sample_tiles:
			var row: int = pair[0]
			var col: int = pair[1]
			var center: Vector2 = r.tile_iso_center(row, col, 0)
			# Four off-center points (inside the diamond):
			var offsets: Array = [
				Vector2(0.0,   -qh * 0.8),   # slightly above center
				Vector2(0.0,    qh * 0.8),   # slightly below center
				Vector2(-qw * 0.8, 0.0),     # slightly left
				Vector2( qw * 0.8, 0.0),     # slightly right
			]
			for off in offsets:
				var px: Vector2 = center + off
				var t = r.pixel_to_tile(px)
				_assert(
					t != null and t.row == row and t.col == col,
					"vp=%s off-center tile(%d,%d) off=%s → %s" % [
						vp, row, col, off,
						str(t) if t != null else "null"
					],
					fails
				)

	# -----------------------------------------------------------------------
	# 3. Out-of-board pixels return null.
	# -----------------------------------------------------------------------
	r.compute_layout_for_size(Vector2(1280.0, 800.0))
	var oob_points: Array = [
		Vector2(-100.0, -100.0),
		Vector2(0.0, 0.0),
		Vector2(1500.0, 1000.0),
	]
	for px in oob_points:
		var t = r.pixel_to_tile(px)
		_assert(t == null, "OOB pixel %s should return null, got %s" % [px, str(t)], fails)

	# -----------------------------------------------------------------------
	# Report
	# -----------------------------------------------------------------------
	if fails[0] == 0:
		print("OK renderer_picking")
	else:
		printerr("FAIL renderer_picking: %d assertion(s) failed" % fails[0])

	quit(fails[0])
