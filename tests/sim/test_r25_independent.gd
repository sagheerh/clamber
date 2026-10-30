# gdlint: disable=max-line-length
# Full evidence scope strings remain single artifact labels.
extends SceneTree
## Separate AC202 / FA5 jobs; neither depends on brace acceptance or baseline job.
const TUNING = preload("res://core/tuning.tres")
var _folder := ""
var _mode := ""


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report-dir="):
			_folder = arg.trim_prefix("--report-dir=")
		if arg.begins_with("--mode="):
			_mode = arg.trim_prefix("--mode=")
	assert(not _folder.is_empty())
	if _mode == "ac202":
		_ac202()
	elif _mode == "fa5":
		_fa5()
	else:
		quit(1)


func _mask(tick: int) -> int:
	# One fixed repeating released/L/R/both script, published before outcomes.
	return (tick / 60) % 4


func _ac202() -> void:
	var summary := {}
	var failed := false
	for name in ["Slug", "Hopper", "TwinRoller"]:
		var sim := R25Fixture.public_sim(name)
		var file := FileAccess.open(_folder + "/" + name + ".jsonl", FileAccess.WRITE)
		assert(file != null)
		var maximum := 0.0
		var where := {}
		var count := 0
		for tick in range(7200):
			sim.step(_mask(tick))
			if sim.last_status != OK:
				failed = true
				break
			var errors: Array = []
			var states := sim.get_render_state()
			for index in range(states.size()):
				var b: Dictionary = states[index]
				var x: float = b.b.x - b.a.x
				var y: float = b.b.y - b.a.y
				var error: float = absf(sqrt(x * x + y * y) - b.length)
				if not is_finite(error):
					failed = true
				errors.append(error)
				if error > maximum:
					maximum = error
					where = {"tick": tick, "part": index, "kind": b.kind}
			file.store_line(
				JSON.stringify(
					{
						"tick": tick,
						"input_mask": _mask(tick),
						"errors_wu": errors,
						"bodies": states
					},
					"",
					true,
					true
				)
			)
			count += 1
		file.close()
		var passed := count == 7200 and maximum <= .05
		failed = failed or not passed
		summary[name] = {
			"ticks": count,
			"max_absolute_length_error_wu": maximum,
			"maximum_at": where,
			"passed": passed,
			"scope": "all segments, stronger than limbs only; publicSim60Hz120s"
		}
	var report := FileAccess.open(_folder + "/ac202-engine.json", FileAccess.WRITE)
	report.store_string(JSON.stringify(summary, "", true, true))
	report.close()
	print("M1 R25 AC202 engine: " + JSON.stringify(summary, "", true, true))
	quit(1 if failed else 0)


func _fa5() -> void:
	var model := CreaturePresets.load_model("Hopper", TUNING)
	var probe := ActuatedLoadProbe.new()
	var twin := ActuatedLoadProbe.new()
	for p in [probe, twin]:
		assert(
			(
				p.setup(
					model,
					R25Fixture.floor_grid(),
					0.0,
					R25Fixture.spawn_y(model),
					R25Fixture.materials(model),
					R25Fixture.materials(model, true),
					TUNING
				)
				== OK
			)
		)
	probe.collect_contact_samples = true
	var file := FileAccess.open(_folder + "/Hopper.jsonl", FileAccess.WRITE)
	assert(file != null)
	var count := 0
	for tick in range(7200):
		var row := probe.advance(_mask(tick))
		var other := twin.advance(_mask(tick))
		if (
			row.status != OK
			or other.status != OK
			or var_to_bytes(probe.snapshot()) != var_to_bytes(twin.snapshot())
		):
			break
		row.observer_on_off_physical_state_equal = true
		row.input_mask = _mask(tick)
		row.fixture = "authored Hopper/legal .01 clearance/uniform diagnostic floor; no pose/load injection"
		file.store_line(JSON.stringify(row, "", true, true))
		count += 1
	file.close()
	print(
		(
			"M1 R25 FA5 raw: %d ticks, actual two-foot authoredHopper, observerequal; branches independently verified next"
			% count
		)
	)
	quit(0 if count == 7200 else 1)
