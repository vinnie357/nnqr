extends RefCounted

const Diagnostics = preload("res://src/services/diagnostics.gd")
const Rules = preload("res://src/core/rules.gd")


static func run() -> Array[String]:
	var failures: Array[String] = []
	var data_dir := OS.get_environment("ASTRA_DATA_DIR")
	_expect(not data_dir.is_empty(), "test runner provides isolated ASTRA_DATA_DIR", failures)
	var diagnostics := Diagnostics.new()
	var initial: Dictionary = Rules.new_game(731)
	var action := _shuttle_action(initial)
	var result: Dictionary = Rules.apply_action(initial, action)
	_expect(bool(result.ok), "fixture action is legal", failures)
	var current: Dictionary = result.state
	diagnostics.start(initial)
	diagnostics.record(action, result)
	var failed_action := {"type": "move", "piece_id": 999, "row": 0, "col": 0}
	diagnostics.record(failed_action, Rules.apply_action(current, failed_action))
	diagnostics.save(current)
	var loaded: Dictionary = diagnostics.load_save()
	_expect(loaded == current, "save roundtrip preserves complete state", failures)
	_expect(FileAccess.file_exists(data_dir.path_join("astra-diagnostics.json")), "session evidence is persisted incrementally", failures)
	_expect(not FileAccess.file_exists(data_dir.path_join("astra-save.json.tmp")), "atomic save leaves no temporary file", failures)
	_expect(diagnostics.report_directory() == data_dir.path_join("reports"), "report directory uses configured storage", failures)

	var save_path := data_dir.path_join("astra-save.json")
	var interrupted := FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	interrupted.store_string("truncated")
	interrupted = null
	_expect(diagnostics.load_save() == current, "interrupted temporary write preserves prior save", failures)
	DirAccess.remove_absolute(save_path + ".tmp")
	_test_invalid_saves(save_path, diagnostics, failures)
	diagnostics.save(current)

	var path := diagnostics.report(current, "The second turn felt unclear.", null)
	_expect(not path.begins_with("error:"), "native report is created", failures)
	if not path.begins_with("error:"):
		_check_report(path, 2, 0, current, failures)

	var bounded := Diagnostics.new()
	bounded.start(initial)
	var bounded_state := initial
	for turn: int in range(1, 206):
		var next_action := _shuttle_action(bounded_state)
		var next_result: Dictionary = Rules.apply_action(bounded_state, next_action)
		_expect(bool(next_result.ok), "bounded replay action %d is legal" % turn, failures)
		if not bool(next_result.ok):
			break
		bounded.record(next_action, next_result)
		bounded_state = next_result.state
	var bounded_path := bounded.report(bounded_state, "bounded replay", null)
	_expect(not bounded_path.begins_with("error:"), "bounded report is created", failures)
	if not bounded_path.begins_with("error:"):
		_check_report(bounded_path, 200, 5, bounded_state, failures)
	return failures


static func _shuttle_action(state: Dictionary) -> Dictionary:
	var piece_id := 11 if int(state.active) == 1 else 21
	var piece: Dictionary = Rules.piece_by_id(state, piece_id)
	var target_row: int
	if piece_id == 11:
		target_row = 2 if int(piece.row) == 1 else 1
	else:
		target_row = 5 if int(piece.row) == 6 else 6
	return {"type": "move", "piece_id": piece_id, "row": target_row, "col": 0}


static func _test_invalid_saves(path: String, diagnostics: RefCounted, failures: Array[String]) -> void:
	var invalid_states: Array = [
		{"version": 1, "pieces": [], "tiles": []},
		Rules.new_game(2),
		Rules.new_game(3),
	]
	invalid_states[1].tiles = []
	invalid_states[2].pieces[1].id = invalid_states[2].pieces[0].id
	for index: int in range(invalid_states.size()):
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string(JSON.stringify({"format_version": 1, "state": invalid_states[index]}))
		file = null
		_expect(diagnostics.load_save().is_empty(), "malformed save %d is rejected" % index, failures)


static func _check_report(path: String, action_count: int, baseline_turn: int, expected_state: Dictionary, failures: Array[String]) -> void:
	var reader := ZIPReader.new()
	var open_error := reader.open(path)
	_expect(open_error == OK, "report is a readable ZIP", failures)
	if open_error != OK:
		return
	var names := reader.get_files()
	for required: String in ["feedback.txt", "state.json", "replay.json", "diagnostics.log"]:
		_expect(required in names, "report contains %s" % required, failures)
	var selected_log := OS.get_environment("ASTRA_LOG_FILE")
	if not selected_log.is_empty():
		var bundled_log := reader.read_file("diagnostics.log").get_string_from_utf8()
		_expect(selected_log in bundled_log, "report identifies the launcher-selected log", failures)
	var replay_value: Variant = JSON.parse_string(reader.read_file("replay.json").get_string_from_utf8())
	if replay_value is Dictionary:
		var replay: Dictionary = replay_value
		_expect(int(replay.get("metadata", {}).get("seed", 0)) == 731, "replay records seed", failures)
		var actions: Array = replay.get("actions", [])
		_expect(actions.size() == action_count, "replay has %d actions" % action_count, failures)
		var replay_state: Dictionary = replay.get("initial_state", {})
		_expect(int(replay_state.get("turn", -1)) == baseline_turn, "replay baseline advances to turn %d" % baseline_turn, failures)
		for record_value: Variant in actions:
			var record: Dictionary = record_value
			_expect(not record.has("checkpoint_state"), "report omits private checkpoint snapshots", failures)
			var replay_result: Dictionary = Rules.apply_action(replay_state, record.get("action", {}))
			if bool(replay_result.ok):
				replay_state = replay_result.state
		_expect(_normalize_numbers(replay_state) == _normalize_numbers(expected_state), "report actions reconstruct current state", failures)
	else:
		failures.append("replay JSON is valid")
	reader.close()
	DirAccess.remove_absolute(path)


static func _normalize_numbers(value: Variant) -> Variant:
	if value is float and is_equal_approx(value, round(value)):
		return int(value)
	if value is Array:
		var normalized_array: Array = []
		for item: Variant in value:
			normalized_array.append(_normalize_numbers(item))
		return normalized_array
	if value is Dictionary:
		var normalized_dictionary: Dictionary = {}
		for key: Variant in value:
			normalized_dictionary[key] = _normalize_numbers(value[key])
		return normalized_dictionary
	return value


static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
