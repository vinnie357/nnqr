## rng_test.gd — Tests for rng.gd (mulberry32 seeded RNG).
## Run: godot/scripts/godot.sh --headless --path . -s res://tests/rng_test.gd
extends SceneTree

const Rng = preload("res://src/rng.gd")

func _assert(cond: bool, msg: String, fails: Array) -> void:
	if not cond:
		printerr("  FAIL: " + msg)
		fails[0] += 1


func _init() -> void:
	var fails := [0]

	# --- Determinism: same seed produces same sequence ---
	var rng1 = Rng.new(42)
	var rng2 = Rng.new(42)
	var a1 = rng1.next()
	var a2 = rng2.next()
	_assert(a1 == a2, "same seed same first value (got %f vs %f)" % [a1, a2], fails)
	var b1 = rng1.next()
	var b2 = rng2.next()
	_assert(b1 == b2, "same seed same second value (got %f vs %f)" % [b1, b2], fails)

	# --- Different seeds produce different first values ---
	var rng3 = Rng.new(1)
	var rng4 = Rng.new(2)
	_assert(rng3.next() != rng4.next(), "different seeds -> different values", fails)

	# --- next() range [0,1) ---
	var rng5 = Rng.new(99)
	for i in range(200):
		var v = rng5.next()
		_assert(v >= 0.0 and v < 1.0, "next() in [0,1): got %f at step %d" % [v, i], fails)

	# --- int(min,max) range inclusive ---
	var rng6 = Rng.new(7)
	var saw_min := false
	var saw_max := false
	for i in range(300):
		var v = rng6.int(3, 7)
		_assert(v >= 3 and v <= 7, "int(3,7) in [3..7]: got %d at step %d" % [v, i], fails)
		if v == 3: saw_min = true
		if v == 7: saw_max = true
	_assert(saw_min, "int(3,7) produced min=3 in 300 draws", fails)
	_assert(saw_max, "int(3,7) produced max=7 in 300 draws", fails)

	# --- int(n,n) always returns n ---
	var rng7 = Rng.new(5)
	for i in range(10):
		_assert(rng7.int(5, 5) == 5, "int(5,5)==5 at step %d" % i, fails)

	# --- pick() returns element from array ---
	var rng8 = Rng.new(13)
	var arr = [10, 20, 30]
	for i in range(50):
		var v = rng8.pick(arr)
		_assert(v == 10 or v == 20 or v == 30, "pick returns element from array at step %d" % i, fails)

	# --- pick() on empty array returns null ---
	var rng9 = Rng.new(1)
	var result = rng9.pick([])
	_assert(result == null, "pick([]) returns null", fails)

	# --- Seed 0 works (edge case) ---
	var rng10 = Rng.new(0)
	var v0 = rng10.next()
	_assert(v0 >= 0.0 and v0 < 1.0, "seed 0 produces valid value: %f" % v0, fails)

	# --- Sequence is not all zeros ---
	var rng11 = Rng.new(1)
	var all_zero := true
	for i in range(10):
		if rng11.next() != 0.0:
			all_zero = false
	_assert(not all_zero, "sequence not all zeros", fails)

	# --- pick() distributes across elements (all 3 appear in 100 draws) ---
	var rng12 = Rng.new(55)
	var counts := {10: 0, 20: 0, 30: 0}
	for i in range(100):
		var v = rng12.pick([10, 20, 30])
		counts[v] = counts[v] + 1
	_assert(counts[10] > 0 and counts[20] > 0 and counts[30] > 0,
		"pick distributes: %s" % str(counts), fails)

	if fails[0] == 0:
		print("OK rng")
	else:
		printerr("FAIL rng: %d" % fails[0])
	quit(fails[0])
