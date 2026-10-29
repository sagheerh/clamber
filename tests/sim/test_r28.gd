# gdlint: disable=max-line-length,max-returns
# R28 reuses the registered R27 geometry helpers, NEVER its pinned runners.
extends "res://tests/sim/test_r27.gd"


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report-dir="):
			_folder = arg.trim_prefix("--report-dir=")
		if arg.begins_with("--mode="):
			_mode = arg.trim_prefix("--mode=")
	if (
		_folder.is_empty()
		or _mode not in ["adoption-measure", "idle-family", "ac201a-characterisation"]
	):
		quit(1)
		return
	var names: Array = ["Slug", "Hopper", "TwinRoller"] if _mode == "adoption-measure" else ["Slug"]
	var target := 7200 if _mode == "adoption-measure" else 600 if _mode == "idle-family" else 3600
	var ok := true
	for name in names:
		var sim := _sim(name, _mode == "adoption-measure")
		var end := _end(target)
		_engine[name] = end
		if sim == null or sim.last_status != OK:
			end.merge(
				{
					"termination_reason": "setup_failure",
					"status": ERR_INVALID_DATA,
					"failing_tick": 0
				},
				true
			)
			ok = false
			break
		var rig: SleepingLoadProbe = sim._solver._rig
		var probe := rig._probe as ActuatedLoadProbe
		# Recording ONLY; no switch controls the production distance traversal.
		probe.collect_length_phases = _mode == "adoption-measure"
		probe.collect_contact_samples = _mode == "adoption-measure"
		var file := FileAccess.open(_folder + "/" + name + ".jsonl", FileAccess.WRITE)
		var spawn := FileAccess.open(_folder + "/" + name + "-spawn.json", FileAccess.WRITE)
		if file == null or spawn == null:
			end.merge(
				{
					"termination_reason": "file_open_failure",
					"status": ERR_FILE_CANT_WRITE,
					"failing_tick": 0
				},
				true
			)
			ok = false
			break
		spawn.store_string(JSON.stringify(rig.snapshot(), "", true, true))
		spawn.close()
		for tick in range(target):
			var mask: int = (tick / 60) % 4 if _mode == "adoption-measure" else 0
			var before := rig.snapshot()
			sim.step(mask)
			var state := rig.snapshot()
			_bad = []
			_finite(state, "state")
			_finite(rig.constraint_snapshot(), "constraints")
			var row := {
				"tick": tick,
				"input_mask": mask,
				"state": state,
				"status": sim.last_status,
				"nonfinite": _bad.duplicate(true)
			}
			if sim.last_status != OK or not _bad.is_empty():
				row.last_pre_step = before
				file.store_line(JSON.stringify(row, "", true, true))
				end.merge(
					{
						"termination_reason":
						"step_failure" if sim.last_status != OK else "nonfinite",
						"status": sim.last_status,
						"failing_tick": tick
					},
					true
				)
				ok = false
				break
			if _mode == "adoption-measure":
				row.phases = probe.length_phases if probe.length_phase_tick == tick else {}
				row.contact_batches = probe._contact_batches
				row.penetration = _penetration(probe)
				if row.penetration.status != OK:
					end.merge(
						{
							"termination_reason": "terrain_query_failure",
							"status": row.penetration.status,
							"failing_tick": tick
						},
						true
					)
					file.store_line(JSON.stringify(row, "", true, true))
					ok = false
					break
			file.store_line(JSON.stringify(row, "", true, true))
			end.ticks += 1
		file.close()
		if not ok:
			break
	var engine := FileAccess.open(_folder + "/engine.json", FileAccess.WRITE)
	if engine != null:
		engine.store_string(JSON.stringify(_engine, "", true, true))
		engine.close()
	print("M1 R28 engine: " + JSON.stringify(_engine, "", true, true))
	quit(0 if ok else 1)


func _penetration(probe: ActuatedLoadProbe) -> Dictionary:
	var samples: Array = []
	for part in range(probe.bodies.size()):
		var body := probe.bodies[part]
		var dx := body.b.x - body.a.x
		var dy := body.b.y - body.a.y
		var intervals := maxi(1, ceili(sqrt(dx * dx + dy * dy) / probe._terrain.cell_size()))
		for index in range(intervals + 1):
			var u := float(index) / intervals
			var x := body.a.x * (1.0 - u) + body.b.x * u
			var y := body.a.y * (1.0 - u) + body.b.y * u
			var s := probe._terrain.sample(x, y)
			if s.is_empty():
				return {"status": ERR_INVALID_DATA}
			samples.append(
				{
					"part": part,
					"kind": body.kind,
					"u": u,
					"center": [x, y],
					"normal": [s.nx, s.ny],
					"distance_wu": s.distance,
					"radius_wu": body.radius,
					"penetration_wu": maxf(0.0, body.radius - s.distance),
					"surface": [x - s.nx * body.radius, y - s.ny * body.radius]
				}
			)
	return {"status": OK, "samples": samples}
