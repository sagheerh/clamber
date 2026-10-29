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
	var ok := _control() if _mode == "D0" else false
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
