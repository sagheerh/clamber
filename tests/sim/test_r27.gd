# gdlint: disable=max-line-length,max-returns
# Artifact rows retain complete provenance and unconditional failure reporting.
extends SceneTree
const TUNING = preload("res://core/tuning.tres")
var _folder := ""
var _mode := ""
var _batch := -1
var _engine := {}
var _checked := 0
var _bad: Array = []


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report-dir="):
			_folder = arg.trim_prefix("--report-dir=")
		if arg.begins_with("--mode="):
			_mode = arg.trim_prefix("--mode=")
		if arg.begins_with("--batch="):
			_batch = int(arg.trim_prefix("--batch="))
	if _folder.is_empty():
		quit(1)
		return
	var ok := false
	if _mode in ["ac201", "ac202", "fa3"]:
		ok = _scenes()
	elif _mode == "soak" and _batch >= 0 and _batch < 20:
		ok = _soak()
	var file := FileAccess.open(_folder + "/engine.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(_engine, "", true, true))
		file.close()
	print("M1 R27 engine: " + JSON.stringify(_engine, "", true, true))
	quit(0 if ok else 1)


func _end(target: int) -> Dictionary:
	return {
		"target_ticks": target,
		"ticks": 0,
		"termination_reason": "completed",
		"status": OK,
		"failing_tick": null
	}


func _scenes() -> bool:
	var passed := true
	var names: Array = ["Slug"] if _mode == "ac201" else ["Slug", "Hopper", "TwinRoller"]
	for name in names:
		var sim: Sim = null if _mode == "fa3" else _sim(name, _mode == "ac202")
		var rig: SleepingLoadProbe = null
		if _mode == "fa3":
			rig = _rig(name, false)
		elif sim != null and sim.last_status == OK:
			rig = sim._solver._rig
		var end := _end(7200 if _mode == "ac202" else 600)
		_engine[name] = end
		if rig == null:
			end.merge(
				{
					"termination_reason": "setup_failure",
					"status": ERR_INVALID_DATA,
					"failing_tick": 0
				},
				true
			)
			passed = false
			continue
		var p := rig._probe as ActuatedLoadProbe
		p.diagnostic_final_distance_pass = _mode == "ac202"
		p.collect_length_phases = _mode == "ac202"
		p.collect_contact_samples = _mode == "fa3"
		var file := FileAccess.open(_folder + "/" + name + ".jsonl", FileAccess.WRITE)
		if file == null:
			end.merge(
				{
					"termination_reason": "file_open_failure",
					"status": ERR_FILE_CANT_WRITE,
					"failing_tick": 0
				},
				true
			)
			passed = false
			continue
		var initial := rig.snapshot()
		var initial_file := FileAccess.open(_folder + "/" + name + "-spawn.json", FileAccess.WRITE)
		if initial_file == null:
			end.merge(
				{
					"termination_reason": "spawn_file_failure",
					"status": ERR_FILE_CANT_WRITE,
					"failing_tick": 0
				},
				true
			)
			file.close()
			passed = false
			continue
		initial_file.store_string(JSON.stringify(initial, "", true, true))
		initial_file.close()
		for tick in range(end.target_ticks):
			var mask: int = (tick / 60) % 4 if _mode == "ac202" else 0
			var before := rig.snapshot()
			var observation := {}
			var status: int
			if sim == null:
				observation = rig.step(mask)
				status = observation.status
			else:
				sim.step(mask)
				status = sim.last_status
			if status != OK:
				end.merge(
					{
						"termination_reason": "step_failure",
						"status": status,
						"failing_tick": tick,
						"last_pre_step": before
					},
					true
				)
				passed = false
				break
			var row := {
				"tick": tick,
				"input_mask": mask,
				"state": rig.snapshot(),
				"candidate_enabled": _mode == "ac202",
				"phases": p.length_phases if p.length_phase_tick == tick else {},
				"observation": observation
			}
			file.store_line(JSON.stringify(row, "", true, true))
			end.ticks += 1
		file.close()
	return passed


func _sim(name: String, wide: bool) -> Sim:
	if not wide:
		return R25Fixture.public_sim(name)
	var model := CreaturePresets.load_model(name, TUNING)
	var tower := TowerData.new()
	if (
		tower.configure(
			_grid(true),
			0.0,
			R25Fixture.spawn_y(model),
			R25Fixture.materials(model),
			R25Fixture.materials(model, true),
			TUNING
		)
		!= OK
	):
		return null
	var sim := Sim.new()
	sim.setup(model, tower, 305419896, TUNING)
	return sim


func _grid(wide: bool) -> SdfGrid:
	if not wide:
		return R25Fixture.floor_grid()
	var rows: Array = []
	for iy in range(49):
		var row := PackedFloat64Array()
		for ix in range(513):
			row.append(-4.0 + iy * TUNING.physics_sdf_cell_wu)
		rows.append(row)
	var grid := SdfGrid.new()
	if grid.configure(rows, -64.0, -4.0, TUNING.physics_grip_friction, TUNING) != OK:
		return null
	return grid


func _rig(name: String, wide: bool) -> SleepingLoadProbe:
	var model := CreaturePresets.load_model(name, TUNING)
	var rig := SleepingLoadProbe.new()
	if (
		rig.setup(
			model,
			_grid(wide),
			0.0,
			R25Fixture.spawn_y(model),
			R25Fixture.materials(model),
			R25Fixture.materials(model, true),
			TUNING,
			true
		)
		!= OK
	):
		return null
	return rig


func _finite(value: Variant, path: String) -> void:
	if value is float:
		_checked += 1
		if not is_finite(value):
			_bad.append({"path": path, "value_as_text": str(value)})
	elif value is Dictionary:
		for key in value:
			_finite(value[key], path + "/" + str(key))
	elif value is Array or value is PackedFloat64Array or value is PackedFloat32Array:
		for i in range(value.size()):
			_finite(value[i], path + "/" + str(i))


func _soak() -> bool:
	# Non-physical positive control: the scanner must not turn NaN/Inf into a pass.
	_finite({"control": [NAN, INF]}, "control")
	if _bad.size() != 2:
		_engine.scanner_control = "FAILED"
		return false
	_engine.scanner_control = "detected BOTH injected non-physical NaN/Inf control scalars; never qualifying run data"
	var file := FileAccess.open(_folder + "/runs.jsonl", FileAccess.WRITE)
	if file == null:
		_engine.file_failure = _end(7200)
		_engine.file_failure.merge(
			{
				"termination_reason": "file_open_failure",
				"status": ERR_FILE_CANT_WRITE,
				"failing_tick": 0
			},
			true
		)
		return false
	var all_ok := true
	for id in range(_batch * 10, (_batch + 1) * 10):
		var name: String = ["Slug", "Hopper", "TwinRoller"][id % 3]
		var seed := 1388320512 + id
		var rng := Xoshiro128StarStar.new()
		rng.configure(seed)
		var rig := _rig(name, true)
		var end := _end(7200)
		end.merge({"run_id": id, "preset": name, "seed": seed, "candidate_enabled": false})
		_checked = 0
		_bad = []
		var hash := HashingContext.new()
		hash.start(HashingContext.HASH_SHA256)
		var inputs := HashingContext.new()
		inputs.start(HashingContext.HASH_SHA256)
		var mask := 0
		if rig == null:
			end.merge(
				{
					"termination_reason": "setup_failure",
					"status": ERR_INVALID_DATA,
					"failing_tick": 0
				},
				true
			)
		else:
			_finite(rig.snapshot(), "spawn")
			for tick in range(7200):
				if tick % 60 == 0:
					mask = rng.next_u32() & 3
				var row := rig.step(mask)
				_finite(row, "observation")
				var after := rig.snapshot()
				_finite(after, "state")
				_finite(rig.constraint_snapshot(), "constraints")
				if row.status != OK or not _bad.is_empty():
					end.merge(
						{
							"termination_reason":
							"step_failure" if row.status != OK else "nonfinite",
							"status": row.status,
							"failing_tick": tick,
							"offending_observation": row
						},
						true
					)
					break
				hash.update(var_to_bytes(after))
				inputs.update(PackedByteArray([mask]))
				end.ticks += 1
			end.final_state = rig.snapshot()
		end.finite_float_checks = _checked
		end.nonfinite_events = _bad
		end.state_stream_sha256 = hash.finish().hex_encode()
		end.input_stream_sha256 = inputs.finish().hex_encode()
		end.completed = (
			end.ticks == 7200
			and end.termination_reason == "completed"
			and end.status == OK
			and _bad.is_empty()
		)
		all_ok = all_ok and end.completed
		file.store_line(JSON.stringify(end, "", true, true))
	file.close()
	_engine.batch = _batch
	_engine.runs_logged = 10
	_engine.all_runs_completed = all_ok
	return all_ok
