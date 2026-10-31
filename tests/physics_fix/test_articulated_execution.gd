# gdlint: disable=max-line-length,max-returns
extends "res://tests/sim/test_r28.gd"
## Fresh NEW unadopted articulated candidate, NOT a historical R27/R29 run or M1 verdict.
const CANDIDATE = preload("res://tests/physics_fix/actuated_articulated_candidate.gd")
var _results: Dictionary = {
	"scope": "NEW unadopted articulated candidate",
	"arms": {},
	"not_run_arms": ["idle-Slug", "length-Slug", "length-Hopper", "length-TwinRoller"],
	"status": "NOT RUN"
}


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report-dir="):
			_folder = arg.trim_prefix("--report-dir=")
	if _folder.is_empty():
		quit(1)
		return
	_bad = []
	_finite({"NON_PHYSICAL_SCANNER_CONTROL": [NAN, INF]}, "control")
	if _bad.size() != 2:
		_results.status = "scanner positive control FAILED; zero creature ticks"
		_store_candidate("summary.json", _results)
		quit(1)
		return
	_results.scanner_control = "detected both nonphysical NaN/Inf; not qualifying data"
	_bad = []
	var ok := _candidate_run("Slug", 600, true)
	if ok:
		for name in ["Slug", "Hopper", "TwinRoller"]:
			if not _candidate_run(name, 7200, false):
				ok = false
				break
	_results.status = (
		"CANDIDATE METRICS SATISFIED; NOT ADOPTED"
		if ok
		else "STOP; inspect first failure; NOT ADOPTED"
	)
	if not _store_candidate("summary.json", _results):
		ok = false
	print("M1 articulated execution: " + JSON.stringify(_results, "", true, true))
	quit(0 if ok else 1)


func _candidate_run(name: String, target: int, idle: bool) -> bool:
	var arm := "idle-Slug" if idle else "length-" + name
	var result := {
		"ticks": 0,
		"target_ticks": target,
		"max_length_wu": 0.0,
		"max_penetration_wu": 0.0,
		"max_attitude_deg": 0.0,
		"airborne_ticks": 0,
		"first_sleep_tick": -1,
		"first_metric_violation_tick": -1,
		"termination": "NOT RUN"
	}
	_results.arms[arm] = result
	_results.not_run_arms.erase(arm)
	var sim := _sim(name, not idle)
	if sim == null or sim.last_status != OK:
		result.termination = "setup failed"
		return false
	var model := CreaturePresets.load_model(name, TUNING)
	var candidate := CANDIDATE.new()
	if (
		candidate.setup(
			model,
			_grid(not idle),
			0.0,
			R25Fixture.spawn_y(model),
			R25Fixture.materials(model),
			R25Fixture.materials(model, true),
			TUNING
		)
		!= OK
	):
		result.termination = "candidate setup failed"
		return false
	# Same public clock/solver/sleep composition, substituted test-only awake rows.
	# On any failed step Sim's rollback recreates the original implementation;
	# therefore failure is terminal: NEVER continue after rollback on baseline rows.
	var rig: SleepingLoadProbe = sim._solver._rig
	rig._probe = candidate
	candidate.collect_contact_samples = true
	var initial := rig.snapshot()
	var initial_vector := _candidate_attitude(initial.physical.bodies)
	var initial_com := R25Fixture.center(initial.physical.bodies)
	if not _store_candidate(
		arm + "-spawn.json",
		{"state": sim.snapshot(), "rig": initial, "constraints": rig.constraint_snapshot()}
	):
		result.termination = "spawn write failed"
		return false
	var file := FileAccess.open(_folder + "/" + arm + ".jsonl", FileAccess.WRITE)
	if file == null:
		result.termination = "trace open failed"
		return false
	for tick in range(target):
		var mask: int = 0 if idle else (tick / 60) % 4
		var before := sim.snapshot()
		sim.step(mask)
		var state := sim._solver._rig.snapshot()
		var constraints: Dictionary = sim._solver._rig.constraint_snapshot()
		_bad = []
		_finite(state, "state")
		_finite(constraints, "constraints")
		_finite(candidate.last_step_trace, "awake_trace")
		if sim.last_status != OK or not _bad.is_empty():
			result.termination = "step/nonfinite failure"
			result.failing_tick = tick
			result.solver_status = sim.last_status
			_store_candidate(
				arm + "-failure.json",
				{
					"tick": tick,
					"status": sim.last_status,
					"nonfinite": _bad,
					"full_state_variant_base64":
					Marshalls.raw_to_base64(
						var_to_bytes(
							{
								"before": before,
								"after": sim.snapshot(),
								"candidate": candidate.snapshot(),
								"awake_trace": candidate.last_step_trace,
								"constraints": constraints
							}
						)
					)
				}
			)
			file.close()
			return false
		var penetration := _penetration(candidate)
		if penetration.status != OK:
			result.termination = "terrain query failure"
			result.failing_tick = tick
			file.close()
			return false
		var peak := 0.0
		for sample in penetration.samples:
			peak = maxf(peak, sample.penetration_wu)
		result.max_penetration_wu = maxf(result.max_penetration_wu, peak)
		var parts: Array = state.physical.bodies
		var length_peak := 0.0
		for part in parts:
			var x: float = part.b.x - part.a.x
			var y: float = part.b.y - part.a.y
			length_peak = maxf(length_peak, absf(sqrt(x * x + y * y) - part.length))
		result.max_length_wu = maxf(result.max_length_wu, length_peak)
		var angle := 0.0
		if idle:
			var vector := _candidate_attitude(parts)
			angle = absf(
				(
					atan2(
						initial_vector[0] * vector[1] - initial_vector[1] * vector[0],
						initial_vector[0] * vector[0] + initial_vector[1] * vector[1]
					)
					* 180.0
					/ PI
				)
			)
			result.max_attitude_deg = maxf(result.max_attitude_deg, angle)
			if not parts.any(func(part): return part.grounded):
				result.airborne_ticks += 1
			if state.sleep.asleep and result.first_sleep_tick < 0:
				result.first_sleep_tick = tick
		var violation: bool = (
			length_peak > 0.05
			or peak > TUNING.physics_contact_slop_wu * (1.0 + 1e-9)
			or (idle and angle > 15.0)
		)
		if violation and result.first_metric_violation_tick < 0:
			result.first_metric_violation_tick = tick
		file.store_line(
			JSON.stringify(
				{
					"tick": tick,
					"input_mask": mask,
					"state": state,
					"constraints": constraints,
					"awake_solver_trace": candidate.last_step_trace,
					"length_peak_wu": length_peak,
					"penetration_peak_wu": peak,
					"attitude_deg": angle
				},
				"",
				true,
				true
			)
		)
		if file.get_error() != OK:
			result.termination = "trace write failed"
			file.close()
			return false
		result.ticks += 1
	file.close()
	var final := sim._solver._rig.snapshot()
	var final_com := R25Fixture.center(final.physical.bodies)
	result.net_com_wu = sqrt(
		(
			(final_com[0] - initial_com[0]) * (final_com[0] - initial_com[0])
			+ (final_com[1] - initial_com[1]) * (final_com[1] - initial_com[1])
		)
	)
	var passed: bool = (
		result.max_length_wu <= 0.05
		and result.max_penetration_wu <= TUNING.physics_contact_slop_wu * (1.0 + 1e-9)
	)
	if idle:
		result.sleep_by_original_4s = result.first_sleep_tick >= 0 and result.first_sleep_tick < 240
		passed = (
			passed
			and result.max_attitude_deg <= 15.0
			and result.airborne_ticks == 0
			and result.net_com_wu <= 0.90
			and result.sleep_by_original_4s
		)
	result.termination = (
		"completed; candidate metrics satisfied"
		if passed
		else "completed; candidate metrics FAILED; stop later arms"
	)
	var saved := _store_candidate(arm + "-summary.json", result)
	return saved and passed


func _candidate_attitude(parts: Array) -> Array:
	var head := [0.0, 0.0]
	var feet := [0.0, 0.0]
	var count := 0
	for part in parts:
		var center := [(part.a.x + part.b.x) / 2.0, (part.a.y + part.b.y) / 2.0]
		if part.kind == "head":
			head = center
		elif part.kind == "foot":
			feet[0] += center[0]
			feet[1] += center[1]
			count += 1
	return [feet[0] / count - head[0], feet[1] / count - head[1]]


func _store_candidate(name: String, value: Variant) -> bool:
	var file := FileAccess.open(_folder + "/" + name, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(value, "", true, true))
	var ok := file.get_error() == OK
	file.close()
	return ok
