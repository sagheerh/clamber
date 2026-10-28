# gdlint: disable=max-returns
class_name SaveStore
extends RefCounted
## Synchronous, offline JSON store. No UI/platform dependencies.
## A non-empty, current-schema dictionary is the M0 validation boundary.

signal recovered(path: String, source: String)
signal write_failed(path: String, error: Error)

const TUNING = preload("res://core/tuning.tres")


func save(path: String, payload: Dictionary) -> Error:
	if not _valid(payload):
		return _fail(path, ERR_INVALID_DATA)
	var error := DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if error != OK:
		return _fail(path, error)
	# The original stays intact until the final replacement. Never back up garbage.
	error = _write_json(path + ".tmp", payload)
	if error != OK:
		return _fail(path, error)
	var previous := _read_valid(path)
	if not previous.is_empty():
		error = _write_json(path + ".bak.tmp", previous)
		if error != OK:
			return _fail(path, error)
		error = DirAccess.rename_absolute(path + ".bak.tmp", path + ".bak")
		if error != OK:
			return _fail(path, error)
	error = DirAccess.rename_absolute(path + ".tmp", path)
	if error != OK:
		return _fail(path, error)
	return OK


func load_data(path: String, defaults: Dictionary) -> Dictionary:
	var primary := _read_valid(path)
	if not primary.is_empty():
		return primary
	for suffix in [".bak", ".tmp"]:
		var candidate := _read_valid(path + suffix)
		if not candidate.is_empty():
			recovered.emit(path, suffix)
			return candidate
	if (
		FileAccess.file_exists(path)
		or FileAccess.file_exists(path + ".bak")
		or FileAccess.file_exists(path + ".tmp")
	):
		recovered.emit(path, "defaults")
	# Recovery is read-only: preserve evidence and do not overwrite a good backup.
	return defaults.duplicate(true)


func _valid(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	var schema: Variant = value.get("schema")
	return (schema is int or schema is float) and schema == TUNING.physics_save_schema


func _read_valid(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK or not _valid(json.data):
		return {}
	return json.data


func _write_json(path: String, payload: Dictionary) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(payload))
	file.flush()
	var error := file.get_error()
	file.close()
	return error


func _fail(path: String, error: Error) -> Error:
	write_failed.emit(path, error)
	return error
