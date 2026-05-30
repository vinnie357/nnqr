## height_test.gd — Tests for height.gd (terrain height rules).
## Run: godot/scripts/godot.sh --headless --path . -s res://tests/height_test.gd
extends SceneTree

const Height = preload("res://src/height.gd")

func _assert(cond: bool, msg: String, fails: Array) -> void:
	if not cond:
		printerr("  FAIL: " + msg)
		fails[0] += 1


func _init() -> void:
	var fails := [0]

	# --- create_height_map returns correct dimensions ---
	var hm = Height.create_height_map(8, 10, 0)
	_assert(hm.size() == 8, "height_map has 8 rows", fails)
	_assert(hm[0].size() == 10, "height_map has 10 cols", fails)

	# --- create_height_map fills with given value ---
	var hm2 = Height.create_height_map(3, 3, 2)
	for r in range(3):
		for c in range(3):
			_assert(hm2[r][c] == 2, "fill value 2 at [%d][%d]" % [r, c], fails)

	# --- get_height uses 1-indexed row/col ---
	var hm3 = Height.create_height_map(4, 4, 0)
	hm3[0][0] = 3   # row=1,col=1
	hm3[1][2] = 4   # row=2,col=3
	_assert(Height.get_height(hm3, 1, 1) == 3, "get_height(1,1)==3", fails)
	_assert(Height.get_height(hm3, 2, 3) == 4, "get_height(2,3)==4", fails)

	# --- get_height returns 0 for out-of-bounds ---
	var hm4 = Height.create_height_map(2, 2, 1)
	_assert(Height.get_height(hm4, 0, 1) == 0, "get_height row 0 (oob) -> 0", fails)
	_assert(Height.get_height(hm4, 3, 1) == 0, "get_height row 3 (oob) -> 0", fails)

	# --- can_climb: drop any number of levels is allowed ---
	_assert(Height.can_climb(4, 0), "can drop from 4 to 0", fails)
	_assert(Height.can_climb(3, 0), "can drop from 3 to 0", fails)
	_assert(Height.can_climb(2, 1), "can drop from 2 to 1", fails)
	_assert(Height.can_climb(1, 0), "can drop from 1 to 0", fails)

	# --- can_climb: same height is allowed ---
	_assert(Height.can_climb(0, 0), "can stay at 0", fails)
	_assert(Height.can_climb(2, 2), "can stay at 2", fails)
	_assert(Height.can_climb(4, 4), "can stay at 4", fails)

	# --- can_climb: climb 1 level is allowed ---
	_assert(Height.can_climb(0, 1), "can climb 0->1", fails)
	_assert(Height.can_climb(1, 2), "can climb 1->2", fails)
	_assert(Height.can_climb(3, 4), "can climb 3->4", fails)

	# --- can_climb: climb 2+ levels is NOT allowed ---
	_assert(not Height.can_climb(0, 2), "cannot climb 0->2", fails)
	_assert(not Height.can_climb(0, 3), "cannot climb 0->3", fails)
	_assert(not Height.can_climb(1, 3), "cannot climb 1->3", fails)
	_assert(not Height.can_climb(2, 4), "cannot climb 2->4", fails)

	# --- Constants are correct ---
	_assert(Height.MIN_HEIGHT == 0, "MIN_HEIGHT==0", fails)
	_assert(Height.MAX_HEIGHT == 4, "MAX_HEIGHT==4", fails)
	_assert(Height.MAX_CLIMB == 1, "MAX_CLIMB==1", fails)

	if fails[0] == 0:
		print("OK height")
	else:
		printerr("FAIL height: %d" % fails[0])
	quit(fails[0])
