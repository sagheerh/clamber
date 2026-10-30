# gdlint: disable=max-line-length
# Evidence scope narrative remains a single artifact string.
extends "res://tests/sim/test_public_sim.gd"
## Actual engine frame callbacks under --fixed-fps30/144, fixed solver60.
var _sim: Sim
var _expected_fps := 0
var _frames: Array = []
var _tick_stream := PackedByteArray()
var _tick_hashes: Array = []
var _compared_stream := PackedByteArray()


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report-dir="):
			_folder = arg.trim_prefix("--report-dir=")
		if arg.begins_with("--expected-fps="):
			_expected_fps = arg.trim_prefix("--expected-fps=").to_int()
	_sim = _rig()
	_sim.tick_completed.connect(_on_tick)
	_check(_expected_fps in [30, 144], "actual fixed-fps support probe")


func _on_tick(state: Dictionary) -> void:
	if _tick_hashes.size() < TICKS:
		_compared_stream.append_array(var_to_bytes(state))
	_tick_stream.append_array(var_to_bytes(state))
	_tick_hashes.append(Sim.digest(state))


func _process(frame_seconds: float) -> bool:
	_frames.append(frame_seconds)
	# Constant recorded RELEASED input in both frame conditions. Live spring stays on.
	var response := _sim.advance_frame(frame_seconds, 0)
	_check(response.status == OK, "actual frame delivery completes")
	if response.status != OK:
		_finish()
		return true
	if response.ticks >= TICKS:
		_check(
			response.ticks == _tick_hashes.size() and _tick_hashes.size() >= TICKS,
			"equal simulated ticks: actual%d recorded%d" % [response.ticks, _tick_hashes.size()]
		)
		_finish()
		return true
	return false


func _finish() -> void:
	var file := FileAccess.open(
		_folder.path_join("delivery-%d.bin" % _expected_fps), FileAccess.WRITE
	)
	_check(file != null, "frame-condition stream opens")
	if file != null:
		file.store_buffer(_tick_stream)
	var prefix := FileAccess.open(
		_folder.path_join("delivery-%d-compared.bin" % _expected_fps), FileAccess.WRITE
	)
	_check(prefix != null, "equal-tick prefix opens; full stream including excess retained")
	if prefix != null:
		prefix.store_buffer(_compared_stream)
	var report := {
		"condition": _expected_fps,
		"frames": _frames.size(),
		"frame_seconds": _frames,
		"tick_hashes": _tick_hashes,
		"compared_ticks": TICKS,
		"actual_ticks": _tick_hashes.size(),
		"compared_tick_hashes": _tick_hashes.slice(0, TICKS),
		"final_accumulator":
		{
			"pending": _sim.snapshot().accumulator.pending,
			"dropped": _sim.snapshot().accumulator.dropped
		},
		"tick_hz": TUNING.physics_tick_hz,
		"stream_bytes": _tick_stream.size(),
		"failures": _failures,
		"checks": _checks,
		"scope":
		"actual SceneTree frame callbacks, --fixed-fps, first600 identical released-input fixed ticks; full extra ticks retained; clock outside tick hash"
	}
	var compact := report.duplicate(true)
	compact.erase("frame_seconds")
	compact.erase("tick_hashes")
	compact.erase("compared_tick_hashes")
	compact["actual_tick_count"] = _tick_hashes.size()
	compact["first_frame_seconds"] = _frames[0]
	compact["last_frame_seconds"] = _frames[-1]
	print("M1 public delivery: " + JSON.stringify(compact, "", true, true))
	var output := FileAccess.open(
		_folder.path_join("delivery-%d.json" % _expected_fps), FileAccess.WRITE
	)
	if output != null:
		output.store_string(JSON.stringify(report, "", true, true))
	quit(0 if _failures == 0 else 1)
