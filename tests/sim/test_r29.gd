# gdlint: disable=max-line-length,max-returns
# R29 test-only observations. Never enables the rejected distance projection.
extends "res://tests/sim/test_r28.gd"


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report-dir="):
			_folder = arg.trim_prefix("--report-dir=")
		if arg.begins_with("--mode="):
			_mode = arg.trim_prefix("--mode=")
	if _folder.is_empty():
		quit(1)
		return
	var ok := false
	match _mode:
		"D0":
			ok = _control()
		"D1":
			ok = _capture()
		"D2":
			ok = _benchmark()
		"D3":
			ok = _repeatability()
		"D4":
			ok = _feel_four()
		"D5":
			ok = _feel_six()
	quit(0 if ok else 1)


func _write(path: String, value: Variant) -> void:
	var f := FileAccess.open(_folder + "/" + path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(value, "", true, true))
		f.close()


func _control() -> bool:
	var results := {}
	for name in ["Slug", "Hopper", "TwinRoller"]:
		var sim := _sim(name, true)
		if sim == null or sim.last_status != OK:
			_write("D0-failure.json", {"preset": name, "tick": 0, "reason": "setup"})
			return false
		var rig: SleepingLoadProbe = sim._solver._rig
		var probe := rig._probe as ActuatedLoadProbe
		# Observer flags remain false. Exact R28 terrain/sampling/input/seed.
		var file := FileAccess.open(_folder + "/D0-" + name + ".jsonl", FileAccess.WRITE)
		var maximum := {"penetration_wu": -1.0}
		for tick in range(7200):
			var before := rig.snapshot()
			var mask: int = (tick / 60) % 4
			sim.step(mask)
			var state := rig.snapshot()
			_bad = []
			_finite(state, "state")
			_finite(rig.constraint_snapshot(), "constraints")
			if sim.last_status != OK or not _bad.is_empty():
				_write(
					"D0-failure.json",
					{
						"preset": name,
						"tick": tick,
						"status": sim.last_status,
						"nonfinite": _bad,
						"before": before,
						"after": state
					}
				)
				file.close()
				return false
			var penetration := _penetration(probe)
			if penetration.status != OK:
				_write(
					"D0-failure.json",
					{"preset": name, "tick": tick, "reason": "terrain query", "state": state}
				)
				file.close()
				return false
			var peak := {"penetration_wu": -1.0}
			for sample in penetration.samples:
				if sample.penetration_wu > peak.penetration_wu:
					peak = sample.duplicate(true)
			peak.tick = tick
			if peak.penetration_wu > maximum.penetration_wu:
				maximum = peak.duplicate(true)
			var pose: Array = []
			for b in probe.bodies:
				pose.append([b.a.x, b.a.y, b.b.x, b.b.y, b.radius, b.kind])
			file.store_line(
				JSON.stringify(
					{"tick": tick, "input_mask": mask, "peak": peak, "pose": pose}, "", true, true
				)
			)
		file.close()
		results[name] = {
			"ticks": 7200,
			"max_penetration_wu": maximum.penetration_wu,
			"worst": maximum,
			"limit": 0.02
		}
	_write("D0.json", results)
	return true


func _mask(tick: int) -> int:
	return 0 if tick < 60 else 1 if (tick / 60) % 2 == 1 else 2


func _checked_step(sim: Sim, tick: int, mask: int, file: FileAccess = null) -> Dictionary:
	var rig: SleepingLoadProbe = sim._solver._rig
	var before := rig.snapshot()
	sim.step(mask)
	var state := rig.snapshot()
	_bad = []
	_finite(state, "state")
	_finite(rig.constraint_snapshot(), "constraints")
	if file != null:
		file.store_line(
			JSON.stringify({"tick": tick, "input_mask": mask, "state": state}, "", true, true)
		)
	if sim.last_status != OK or not _bad.is_empty():
		_write(
			_mode + "-failure.json",
			{
				"tick": tick,
				"status": sim.last_status,
				"nonfinite": _bad,
				"before": before,
				"after": state
			}
		)
		return {}
	return state


func _capture() -> bool:
	for name in ["Slug", "Hopper", "TwinRoller"]:
		var sim := _sim(name, true)
		if sim == null:
			return false
		var rig: SleepingLoadProbe = sim._solver._rig
		var f := FileAccess.open(_folder + "/D1-" + name + ".jsonl", FileAccess.WRITE)
		_write("D1-" + name + "-spawn.json", rig.snapshot())
		for tick in range(600):
			var state := _checked_step(sim, tick, _mask(tick))
			if state.is_empty():
				f.close()
				return false
			var parts: Array = []
			for i in range(state.physical.bodies.size()):
				var b: Dictionary = state.physical.bodies[i]
				var active := false
				for c in rig._probe._contact_counts:
					if c.part == i and c.active_count > 0:
						active = true
				parts.append(
					{
						"part": i,
						"kind": b.kind,
						"a": [b.a.x, b.a.y],
						"b": [b.b.x, b.b.y],
						"position": [(b.a.x + b.b.x) / 2.0, (b.a.y + b.b.y) / 2.0],
						"angle_rad": atan2(b.b.y - b.a.y, b.b.x - b.a.x),
						"contact": active,
						"grounded": b.grounded,
						"gripping": b.gripping
					}
				)
			f.store_line(
				JSON.stringify(
					{
						"tick": tick,
						"input_mask": _mask(tick),
						"COM": R25Fixture.center(state.physical.bodies),
						"parts": parts
					},
					"",
					true,
					true
				)
			)
		f.close()
	return true


func _benchmark() -> bool:
	var metadata := {
		"warmup": 1000,
		"samples": 10000,
		"batch": 10,
		"bodies": 30,
		"structural": {},
		"max_contact_candidates_per_pass": 0,
		"max_active_contact_samples_per_pass": 0,
		"max_self_pairs": 0,
		"method":
		"ten independent real production Slugs; direct transactional CreatureTickSolver.step and public Sim.step (nested outer+tick transactions); not one coupled30body creature; no frame-only optimized mode"
	}
	var f := FileAccess.open(_folder + "/D2-timings.csv", FileAccess.WRITE)
	f.store_line(
		"mode,sample,elapsed_us,active_contact_samples_max_pass,candidate_samples_max_pass"
	)
	for mode in ["direct_tick", "public_frame_plus_tick"]:
		var sims: Array[Sim] = []
		for i in range(10):
			var sim := _sim("Slug", true)
			if sim == null:
				return false
			sims.append(sim)
		var probe := sims[0]._solver._rig._probe as ActuatedLoadProbe
		metadata.structural = {
			"distance_objects": probe._links.size() * 10,
			"coincident_hinge_objects": probe._hinges.size() * 10,
			"angular_objects": probe._joints.size() * 10,
			"structural_objects":
			(probe._links.size() + probe._hinges.size() + probe._joints.size()) * 10,
			"scalar_structural_rows":
			(probe._links.size() + 2 * probe._hinges.size() + probe._joints.size()) * 10,
			"self_pair_candidates": probe._pairs.size() * 10
		}
		for tick in range(11000):
			var mask := _mask(tick)
			var start := Time.get_ticks_usec()
			for sim in sims:
				if mode == "direct_tick":
					if sim._solver.set_input(mask) != OK or sim._solver.step() != OK:
						f.close()
						return false
				else:
					sim.step(mask)
					if sim.last_status != OK:
						f.close()
						return false
			var elapsed := Time.get_ticks_usec() - start
			var active := [0, 0]
			var candidates := [0, 0]
			for sim in sims:
				var rig: SleepingLoadProbe = sim._solver._rig
				_bad = []
				_finite(rig.snapshot(), "state")
				_finite(rig.constraint_snapshot(), "constraints")
				if not _bad.is_empty():
					_write(
						"D2-failure.json",
						{"mode": mode, "tick": tick, "nonfinite": _bad, "state": rig.snapshot()}
					)
					f.close()
					return false
				for c in rig._probe._contact_counts:
					active[c.velocity_pass] += c.active_count
					candidates[c.velocity_pass] += c.candidate_count
				# Clear diagnostic delivery queue outside timed region, no physical state edits.
				sim._frame_ticks = []
			var a: int = maxi(active[0], active[1])
			var c: int = maxi(candidates[0], candidates[1])
			metadata.max_active_contact_samples_per_pass = maxi(
				metadata.max_active_contact_samples_per_pass, a
			)
			metadata.max_contact_candidates_per_pass = maxi(
				metadata.max_contact_candidates_per_pass, c
			)
			if tick >= 1000:
				f.store_line("%s,%d,%d,%d,%d" % [mode, tick - 1000, elapsed, a, c])
		f.flush()
	f.close()
	_write("D2.json", metadata)
	return true


func _repeatability() -> bool:
	var f := FileAccess.open(_folder + "/D3-hashes.csv", FileAccess.WRITE)
	f.store_line("run,ticks,sha256")
	for run in range(100):
		var sim := _sim("Slug", true)
		if sim == null:
			return false
		var trace := FileAccess.open(_folder + "/D3-current.jsonl", FileAccess.WRITE)
		for tick in range(10000):
			if _checked_step(sim, tick, _mask(tick), trace).is_empty():
				f.close()
				trace.close()
				return false
		trace.close()
		DirAccess.remove_absolute(_folder + "/D3-current.jsonl")
		var digest := JSON.stringify(sim.snapshot(), "", true, true).sha256_text()
		f.store_line("%d,10000,%s" % [run, digest])
		f.flush()
	return true


func _feel_four() -> bool:
	var sim := _sim("Slug", true)
	if sim == null:
		return false
	_write("D4-spawn.json", sim._solver._rig.snapshot())
	var f := FileAccess.open(_folder + "/D4.jsonl", FileAccess.WRITE)
	for tick in range(540):
		var mask := 1 if tick >= 240 and tick < 300 else 0
		if _checked_step(sim, tick, mask, f).is_empty():
			f.close()
			return false
	f.close()
	return true


func _feel_six() -> bool:
	var outcomes: Array = []
	for run in range(10):
		var sim := _sim("Slug", true)
		if sim == null:
			return false
		var f := FileAccess.open(_folder + "/D5-run-%02d.jsonl" % run, FileAccess.WRITE)
		for tick in range(300):
			var mask := 1 if tick < 60 else 0
			if _checked_step(sim, tick, mask, f).is_empty():
				f.close()
				return false
		f.close()
		outcomes.append(
			{
				"run": run,
				"ticks": 300,
				"final_state_sha256": JSON.stringify(sim.snapshot(), "", true, true).sha256_text(),
				"COM": R25Fixture.center(sim._solver._rig.snapshot().physical.bodies),
				"success": null
			}
		)
	_write(
		"D5.json",
		{
			"outcomes": outcomes,
			"variance_source":
			"none: identical absolute tick-indexed input, seed, spawn and pose; F78 physics does not consume RNG; identical by construction",
			"substitution":
			"uniform legal plane for nonexistent authored tutorial chunk; no tutorial success predicate; success counts NOT RUN, never invented"
		}
	)
	return true
