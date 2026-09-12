extends RefCounted

const SAVE_NAME := "astra-save.json"
const SESSION_NAME := "astra-diagnostics.json"
const REPORTS_NAME := "reports"
const MAX_ACTIONS := 200

var _initial_state: Dictionary = {}
var _actions: Array[Dictionary] = []
var _metadata: Dictionary = {}


func start(state: Dictionary) -> void:
	_initial_state = state.duplicate(true)
	_actions.clear()
	_metadata = {
		"format_version": 1,
		"build": _build_id(),
		"engine": Engine.get_version_info().get("string", "unknown"),
		"platform": OS.get_name(),
		"seed": state.get("seed", 0),
		"started_at": Time.get_datetime_string_from_system(true, true),
	}
	_write_json(_data_path(SESSION_NAME), _session_data())


func record(action: Dictionary, result: Dictionary) -> void:
	var result_summary := result.duplicate(true)
	var state_value: Variant = result_summary.get("state", {})
	result_summary.erase("state")
	var entry: Dictionary = {
		"time": Time.get_datetime_string_from_system(true, true),
		"action": action.duplicate(true),
		"result": result_summary,
	}
	if bool(result.get("ok", false)) and state_value is Dictionary:
		entry["checkpoint_state"] = state_value.duplicate(true)
	_actions.append(entry)
	if _actions.size() > MAX_ACTIONS:
		var removed: Dictionary = _actions.pop_front()
		var checkpoint: Variant = removed.get("checkpoint_state", {})
		if checkpoint is Dictionary and not checkpoint.is_empty():
			_initial_state = checkpoint.duplicate(true)
	_write_json(_data_path(SESSION_NAME), _session_data())


func save(state: Dictionary) -> void:
	var payload := {
		"format_version": 1,
		"saved_at": Time.get_datetime_string_from_system(true, true),
		"state": state.duplicate(true),
		"diagnostics": _session_data(),
	}
	_write_json(_data_path(SAVE_NAME), payload)


func load_save() -> Dictionary:
	var payload := _read_json(_data_path(SAVE_NAME))
	if payload.is_empty() or int(payload.get("format_version", 0)) != 1:
		return {}
	var state_value: Variant = payload.get("state", {})
	var restored: Variant = _restore_json_types(state_value)
	if not restored is Dictionary or not _valid_state(restored):
		return {}
	var diagnostics_value: Variant = payload.get("diagnostics", {})
	if diagnostics_value is Dictionary:
		_restore_session(diagnostics_value)
	return restored


func report(state: Dictionary, feedback: String, viewport: Viewport) -> String:
	var filename := "astra-report-%s.zip" % str(int(Time.get_unix_time_from_system()))
	var report_path := report_directory().path_join(filename)
	DirAccess.make_dir_recursive_absolute(report_directory())
	var zipper := ZIPPacker.new()
	var open_error := zipper.open(report_path)
	if open_error != OK:
		return "error: could not create report (%s)" % error_string(open_error)
	_add_text(zipper, "feedback.txt", feedback)
	_add_text(zipper, "state.json", JSON.stringify(state, "  "))
	_add_text(zipper, "replay.json", JSON.stringify(_replay_data(), "  "))
	_add_text(zipper, "diagnostics.log", _diagnostic_log())
	if viewport != null:
		var image := viewport.get_texture().get_image()
		if image != null and not image.is_empty():
			_add_bytes(zipper, "screenshot.png", image.save_png_to_buffer())
	zipper.close()
	if OS.has_feature("web"):
		var bytes := FileAccess.get_file_as_bytes(report_path)
		JavaScriptBridge.download_buffer(bytes, filename, "application/zip")
		return "downloaded:%s" % filename
	return report_path


func report_directory() -> String:
	return _data_path(REPORTS_NAME)


func _data_path(filename: String) -> String:
	var override := OS.get_environment("ASTRA_DATA_DIR")
	var root := override if not override.is_empty() else ProjectSettings.globalize_path("user://")
	return root.path_join(filename)


func _session_data() -> Dictionary:
	return {
		"metadata": _metadata.duplicate(true),
		"initial_state": _initial_state.duplicate(true),
		"actions": _actions.duplicate(true),
	}


func _replay_data() -> Dictionary:
	var public_actions: Array[Dictionary] = []
	for stored: Dictionary in _actions:
		var action_record := stored.duplicate(true)
		action_record.erase("checkpoint_state")
		public_actions.append(action_record)
	return {
		"metadata": _metadata.duplicate(true),
		"initial_state": _initial_state.duplicate(true),
		"actions": public_actions,
	}


func _restore_session(value: Dictionary) -> void:
	var initial_value: Variant = value.get("initial_state", {})
	if initial_value is Dictionary:
		_initial_state = initial_value.duplicate(true)
	_actions.clear()
	var action_value: Variant = value.get("actions", [])
	if action_value is Array:
		for item: Variant in action_value:
			if item is Dictionary:
				_actions.append(item.duplicate(true))
	var metadata_value: Variant = value.get("metadata", {})
	if metadata_value is Dictionary:
		_metadata = metadata_value.duplicate(true)


func _diagnostic_log() -> String:
	var lines: Array[String] = [
		"build=%s" % _metadata.get("build", _build_id()),
		"engine=%s" % _metadata.get("engine", Engine.get_version_info().get("string", "unknown")),
		"platform=%s" % _metadata.get("platform", OS.get_name()),
		"seed=%s" % _metadata.get("seed", 0),
	]
	var candidates: Array[String] = []
	var configured_log := OS.get_environment("ASTRA_LOG_FILE")
	if not configured_log.is_empty():
		candidates.append(configured_log)
	for fallback: String in ["user://logs/astra.log", "user://logs/godot.log"]:
		var expanded := ProjectSettings.globalize_path(fallback)
		if expanded not in candidates:
			candidates.append(expanded)
	for candidate: String in candidates:
		if FileAccess.file_exists(candidate):
			lines.append("\n--- %s ---" % candidate)
			lines.append(FileAccess.get_file_as_string(candidate))
	return "\n".join(lines)


func _build_id() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "development"))


func _valid_state(state: Dictionary) -> bool:
	for field: String in ["version", "active", "turn", "rng", "seed", "next_id", "passes", "winner"]:
		if not state.get(field, null) is int:
			return false
	if int(state.version) != 1 or int(state.active) not in [1, 2]:
		return false
	if int(state.turn) < 0 or int(state.next_id) < 1 or int(state.passes) < 0:
		return false
	if not state.get("status", null) is String or str(state.status) not in ["playing", "won", "draw"]:
		return false
	if int(state.winner) not in [0, 1, 2]:
		return false
	var tiles_value: Variant = state.get("tiles", null)
	if not tiles_value is Array or tiles_value.size() != 80:
		return false
	for tile_value: Variant in tiles_value:
		if not tile_value is Dictionary:
			return false
		var tile: Dictionary = tile_value
		if not tile.get("height", null) is int or int(tile.height) < -4 or int(tile.height) > 4:
			return false
		if not tile.get("destroyed", null) is bool or not tile.get("orb", null) is String or not tile.get("marks", null) is Dictionary:
			return false
	var pieces_value: Variant = state.get("pieces", null)
	if not pieces_value is Array:
		return false
	var ids: Dictionary = {}
	var occupied: Dictionary = {}
	var greatest_id := 0
	for piece_value: Variant in pieces_value:
		if not piece_value is Dictionary:
			return false
		var piece: Dictionary = piece_value
		for field: String in ["id", "owner", "row", "col"]:
			if not piece.get(field, null) is int:
				return false
		var id := int(piece.id)
		var row := int(piece.row)
		var col := int(piece.col)
		if id < 1 or ids.has(id) or int(piece.owner) not in [1, 2]:
			return false
		if row < 0 or row >= 8 or col < 0 or col >= 10:
			return false
		var cell := row * 10 + col
		if occupied.has(cell):
			return false
		if not piece.get("inventory", null) is Dictionary or not piece.get("flags", null) is Dictionary:
			return false
		ids[id] = true
		occupied[cell] = true
		greatest_id = maxi(greatest_id, id)
	return int(state.next_id) > greatest_id


func _restore_json_types(value: Variant) -> Variant:
	if value is float and is_equal_approx(value, round(value)):
		return int(value)
	if value is Array:
		var restored_array: Array = []
		for item: Variant in value:
			restored_array.append(_restore_json_types(item))
		return restored_array
	if value is Dictionary:
		var restored_dictionary: Dictionary = {}
		for key: Variant in value:
			restored_dictionary[key] = _restore_json_types(value[key])
		return restored_dictionary
	return value


func _write_json(path: String, value: Dictionary) -> bool:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var temporary_path := path + ".tmp"
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not write %s: %s" % [temporary_path, error_string(FileAccess.get_open_error())])
		return false
	file.store_string(JSON.stringify(value, "  "))
	file.flush()
	file = null
	var rename_error := DirAccess.rename_absolute(temporary_path, path)
	if rename_error != OK:
		push_error("Could not replace %s: %s" % [path, error_string(rename_error)])
		DirAccess.remove_absolute(temporary_path)
		return false
	return true


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _add_text(zipper: ZIPPacker, path: String, content: String) -> void:
	_add_bytes(zipper, path, content.to_utf8_buffer())


func _add_bytes(zipper: ZIPPacker, path: String, content: PackedByteArray) -> void:
	var start_error := zipper.start_file(path)
	if start_error != OK:
		push_error("Could not add %s to report: %s" % [path, error_string(start_error)])
		return
	zipper.write_file(content)
	zipper.close_file()
