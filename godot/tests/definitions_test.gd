extends SceneTree

const Definitions = preload("res://src/powers/definitions.gd")

func _init() -> void:
	var fails := 0
	var VALID_DURATIONS := ["permanent", "single_use"]
	var VALID_TARGETINGS := [
		"self", "self_row", "self_column", "area_3x3",
		"adjacent", "adjacent_enemy", "adjacent_empty", "adjacent_destroyed",
		"global", "special"
	]
	var REQUIRED_KEYS := ["id", "name", "category", "duration", "description", "targeting", "blocking"]

	# assert exactly 82 entries
	var count := Definitions.count()
	if count != 82:
		printerr("FAIL: expected 82 powers, got %d" % count)
		fails += 1

	for id in Definitions.all_ids():
		var entry: Dictionary = Definitions.get_def(id)

		# every entry has all 7 required keys
		for key in REQUIRED_KEYS:
			if not entry.has(key):
				printerr("FAIL: power '%s' missing key '%s'" % [id, key])
				fails += 1

		# every key == its entry's "id"
		if entry.get("id", "") != id:
			printerr("FAIL: key '%s' has mismatched id '%s'" % [id, entry.get("id", "")])
			fails += 1

		# duration in valid set
		var dur: String = entry.get("duration", "")
		if dur not in VALID_DURATIONS:
			printerr("FAIL: power '%s' has invalid duration '%s'" % [id, dur])
			fails += 1

		# targeting in valid set
		var tgt: String = entry.get("targeting", "")
		if tgt not in VALID_TARGETINGS:
			printerr("FAIL: power '%s' has invalid targeting '%s'" % [id, tgt])
			fails += 1

		# name non-empty string
		var nm: String = entry.get("name", "")
		if nm == "":
			printerr("FAIL: power '%s' has empty name" % id)
			fails += 1

		# description non-empty string
		var desc: String = entry.get("description", "")
		if desc == "":
			printerr("FAIL: power '%s' has empty description" % id)
			fails += 1

		# blocking is a bool
		var blk = entry.get("blocking", null)
		if typeof(blk) != TYPE_BOOL:
			printerr("FAIL: power '%s' blocking is not a bool (got %s)" % [id, str(blk)])
			fails += 1

	if fails == 0:
		print("OK definitions")
	else:
		printerr("FAIL definitions: %d" % fails)
	quit(fails)
