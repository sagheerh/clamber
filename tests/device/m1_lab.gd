# gdlint: disable=max-line-length
extends Control
## Opt-in manual engineering lab. Never runs D0/R27/R29 acceptance protocols.
const TUNING = preload("res://core/tuning.tres")
const FIXTURE = preload("res://tests/sim/r25_fixture.gd")
const HELD_INPUT = preload("res://tests/device/held_input.gd")
const VIEW = preload("res://tests/device/m1_view.gd")
const SAFE_AREA = preload("res://ui/components/safe_area.gd")
const NAMES := ["Slug", "Hopper", "TwinRoller"]
var _held := HELD_INPUT.new()
var _sim: Sim
var _trace: FileAccess
var _session_path := ""
var _paused := true
var _failed := false
var _mask := 0
var _info: Label
var _pause_button: Button
var _left: Panel
var _right: Panel
var _view: Variant


func _ready() -> void:
	_build_controls()
	var build := Engine.get_version_info()
	if (
		build.major != 4
		or build.minor != 7
		or build.patch != 2
		or build.status != "stable"
		or not str(build.hash).begins_with("ed1daf0bf")
	):
		_stop("Exact Godot 4.7.2 stable ed1daf0bf required")
		return
	_start_session(0)


func _build_controls() -> void:
	var safe := SAFE_AREA.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(safe)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 24)
	safe.add_child(column)
	var warning := Label.new()
	warning.text = "M1 DIAGNOSTIC ONLY — BLOCKED / NOT SIGNED\nNot a game screen or acceptance run. Collision diagram: 150 px/WU."
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning.add_theme_font_size_override("font_size", 28)
	column.add_child(warning)
	var chooser := OptionButton.new()
	for name in NAMES:
		chooser.add_item(name)
	chooser.add_theme_font_size_override("font_size", 32)
	chooser.custom_minimum_size.y = 90.0
	chooser.item_selected.connect(_start_session)
	column.add_child(chooser)
	_pause_button = Button.new()
	_pause_button.add_theme_font_size_override("font_size", 32)
	_pause_button.custom_minimum_size.y = 90.0
	_pause_button.pressed.connect(_toggle_pause)
	column.add_child(_pause_button)
	_info = Label.new()
	_info.add_theme_font_size_override("font_size", 28)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_info)
	_view = VIEW.new()
	_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_view.clip_contents = true
	column.add_child(_view)
	var pads := HBoxContainer.new()
	pads.custom_minimum_size.y = 360.0
	pads.add_theme_constant_override("separation", 24)
	column.add_child(pads)
	_left = _pad(pads, "HOLD L / A or Left")
	_right = _pad(pads, "HOLD R / D or Right")


func _pad(parent: Control, caption: String) -> Panel:
	var panel := Panel.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	var label := Label.new()
	label.text = caption
	label.add_theme_font_size_override("font_size", 28)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(label)
	return panel


func _start_session(index: int) -> void:
	_close_session("preset_changed")
	_paused = true
	_failed = false
	_held.clear()
	_mask = 0
	var folder := "user://m1_lab"
	if DirAccess.make_dir_recursive_absolute(folder) != OK:
		_stop("Cannot create local evidence folder")
		return
	# Unique directory is created exclusively. Never overwrite a prior session.
	var id := str(Time.get_unix_time_from_system()).replace(".", "-")
	_session_path = folder + "/" + id + "-" + str(Time.get_ticks_usec())
	if DirAccess.make_dir_absolute(_session_path) != OK:
		_stop("Cannot create unique session directory")
		return
	_trace = FileAccess.open(_session_path + "/trace.jsonl", FileAccess.WRITE)
	if _trace == null:
		_stop("Cannot open session trace")
		return
	_sim = FIXTURE.public_sim(NAMES[index])
	if _sim == null or _sim.last_status != OK:
		_stop("Sim setup failed")
		return
	_sim.tick_completed.connect(_record_tick)
	_sim.failed.connect(_simulation_failed)
	_write_json(
		"source.json",
		{
			"evidence_kind": "owner-attested manual diagnostic, NOT CI or R29 evidence",
			"preset": NAMES[index],
			"seed": 305419896,
			"build": Engine.get_version_info(),
			"os": OS.get_name(),
			"processor": OS.get_processor_name(),
			"model": OS.get_model_name(),
			"tuning_source_sha256":
			(
				JSON
				. parse_string(
					FileAccess.get_file_as_string("res://tests/fixtures/source_manifest.json")
				)
				. tuning_sha256
			),
			"package_provenance": _package_provenance(),
			"source_manifest":
			JSON.parse_string(
				FileAccess.get_file_as_string("res://tests/fixtures/source_manifest.json")
			),
			"terrain": "R25 flatplane fixture; finite domain; no camera following",
			"warning":
			"AC-201/AC-202 FAILED; FA-3 uncredited; M1 BLOCKED; no automatic gate verdict"
		}
	)
	_write_json("spawn.json", _sim.snapshot())
	if _failed:
		_stop("Session metadata write failed")
		return
	_view.bodies = _sim.get_render_state()
	_view.queue_redraw()
	_pause_button.text = "Start / resume diagnostic"
	_info.text = "Ready (paused). Logs: " + ProjectSettings.globalize_path(_session_path)


func _package_provenance() -> Variant:
	var path := "res://tests/device/" + "package_manifest.json"
	if FileAccess.file_exists(path):
		return JSON.parse_string(FileAccess.get_file_as_string(path))
	return {"status": "EDITOR SESSION; use versioned source files, not an APK claim"}


func _process(delta: float) -> void:
	if _paused or _failed or _sim == null:
		return
	_mask = _held.mask()
	var before := _sim.snapshot()
	var outcome := _sim.advance_frame(delta, _mask)
	if outcome.status != OK:
		_write_json(
			"failure.json", {"status": outcome.status, "before": before, "after": _sim.snapshot()}
		)
		_stop("Solver failure: " + str(outcome.status))
		return
	if _failed:
		return
	_view.bodies = _sim.get_render_state()
	_view.queue_redraw()
	_info.text = (
		"Ticks: %d | held: %d | dropped seconds: %.6f\nLogs: %s"
		% [outcome.ticks, _mask, outcome.dropped, ProjectSettings.globalize_path(_session_path)]
	)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var token := "touch:" + str(event.index)
		if not event.pressed:
			_held.release(token)
		elif not _paused and not _failed:
			_held.press(token, _channel(event.position), true)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# Touch-generated mouse events must not duplicate ownership.
		if event.device == -1:
			return
		if not event.pressed:
			_held.release("mouse")
		elif not _paused and not _failed:
			_held.press("mouse", _channel(event.position))
	elif event is InputEventKey and not event.echo:
		var token := "key:" + str(event.keycode)
		if not event.pressed:
			_held.release(token)
		elif not _paused and not _failed:
			if event.keycode in [KEY_A, KEY_LEFT]:
				_held.press(token, 1)
			elif event.keycode in [KEY_D, KEY_RIGHT]:
				_held.press(token, 2)


func _channel(point: Vector2) -> int:
	if _left.get_global_rect().has_point(point):
		return 1
	if _right.get_global_rect().has_point(point):
		return 2
	return 0


func _toggle_pause() -> void:
	if _failed:
		return
	_paused = not _paused
	_held.clear()
	_pause_button.text = "Resume diagnostic" if _paused else "Pause / flush logs"
	if _paused:
		_checkpoint("paused")


func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT]:
		_paused = true
		_held.clear()
		if is_instance_valid(_pause_button):
			_pause_button.text = "Resume diagnostic"
		_checkpoint("backgrounded")


func _record_tick(state: Dictionary) -> void:
	if _trace != null:
		_trace.store_line(JSON.stringify({"input_mask": _mask, "state": state}, "", true, true))
		if _trace.get_error() != OK:
			_stop("Trace write failed; no further ticks")


func _simulation_failed(status: Error) -> void:
	_stop("Simulation status: " + str(status))


func _stop(reason: String) -> void:
	_failed = true
	_paused = true
	_held.clear()
	if is_instance_valid(_info):
		_info.text = "STOP — " + reason + "\nRetain logs; no automatic retry."
	_checkpoint(reason)


func _checkpoint(reason: String) -> void:
	if _trace != null:
		_trace.flush()
		if _trace.get_error() != OK:
			_failed = true
			_paused = true
			if is_instance_valid(_info):
				_info.text = "STOP — trace flush failed; retain session files."
	if _sim != null and not _session_path.is_empty():
		_write_json("checkpoint.json", {"reason": reason, "state": _sim.snapshot()})


func _write_json(name: String, value: Variant) -> void:
	var file := FileAccess.open(_session_path + "/" + name, FileAccess.WRITE)
	if file == null:
		_failed = true
		_paused = true
		return
	file.store_string(JSON.stringify(value, "", true, true))
	if file.get_error() != OK:
		_failed = true
		_paused = true
	file.close()


func _close_session(reason: String) -> void:
	_checkpoint(reason)
	if _trace != null:
		_trace.close()
		_trace = null
	_sim = null


func _exit_tree() -> void:
	_close_session("closed")
