extends SceneTree
const Rules=preload("res://src/core/rules.gd")
const Diagnostics=preload("res://src/services/diagnostics.gd")

func _initialize() -> void:
	var args=OS.get_cmdline_user_args()
	if args.size()!=1:
		printerr("Usage: mise run astra-replay -- /absolute/path/report.zip (or replay.json)")
		quit(2)
		return
	var path=args[0]
	var replay: Variant
	var expected: Variant=null
	if path.ends_with(".zip"):
		var zip=ZIPReader.new()
		if zip.open(path)!=OK:
			printerr("Cannot open report ZIP: "+path)
			quit(2)
			return
		replay=JSON.parse_string(zip.read_file("replay.json").get_string_from_utf8())
		expected=JSON.parse_string(zip.read_file("state.json").get_string_from_utf8())
		zip.close()
	else:
		replay=JSON.parse_string(FileAccess.get_file_as_string(path))
	if not replay is Dictionary or not replay.get("initial_state") is Dictionary or not replay.get("actions") is Array:
		printerr("Invalid replay document")
		quit(2)
		return
	var diag=Diagnostics.new()
	var current: Dictionary=diag._restore_json_types(replay.initial_state)
	var index=0
	for record in replay.actions:
		var result: Dictionary=Rules.apply_action(current,diag._restore_json_types(record.action))
		if bool(result.ok)!=bool(record.result.ok):
			printerr("Replay diverged at action %d: %s" % [index,result.error])
			quit(1)
			return
		if result.ok: current=result.state
		index+=1
	if expected is Dictionary and current!=diag._restore_json_types(expected):
		printerr("Replay final state differs from the reported state")
		quit(1)
		return
	print("Replay verified: %d actions, turn %d, seed %s" % [index,current.turn,current.seed])
	quit(0)
