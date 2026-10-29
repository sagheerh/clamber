# gdlint: disable=max-line-length
# Long evidence labels remain single strings in the artifact.
extends SceneTree
## M1 complete-creature same-build attempt1. No feel/settlement acceptance claims.
const TUNING = preload("res://core/tuning.tres")
const TICKS = 600
const RUN_SEED = 305419896
var _checks := 0
var _failures := 0
var _folder := ""
var _baseline: Array = []
var _baseline_bytes: Array = []
var _streams: Array = []
var _baseline_int_hashes: Array = []
var _report: Dictionary = {"determinism_attempt": 1, "runtime_gates": {}, "attempt_started": false}


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report-dir="):
			_folder = arg.trim_prefix("--report-dir=")
	_check(not _folder.is_empty(), "explicit artifact directory required")
	_rng_controls()
	if _failures == 0:
		_replays()
	if _failures == 0:
		_clock_controls()
		_restore_controls()
		_zero_input_live_sleep()
	_report["checks"] = _checks
	_report["failures"] = _failures
	_report["engine"] = Engine.get_version_info().string
	_report["fixed_tick_hz"] = TUNING.physics_tick_hz
	_report["tuning_sha256"] = FileAccess.get_sha256("res://core/tuning.tres")
	_report["fixture"] = {
		"name": "Slug public Sim legal floor",
		"ticks": TICKS,
		"seed": RUN_SEED,
		"input": "0..59 released; alternating L/R per60 ticks thereafter",
		"spawn": "actual authored lowest surface at +.01WU; uniform diagnostic material"
	}
	var file := FileAccess.open(_folder.path_join("public-sim-report.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(_report, "", true, true))
	else:
		_check(false, "report opens")
	print("M1 public Sim: " + JSON.stringify(_report, "", true, true))
	print("M1 public Sim checks: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("FAIL M1 public Sim: " + label)


func _rig(run_seed: int = RUN_SEED) -> Sim:
	var model := CreaturePresets.load_model("Slug", TUNING)
	var rows: Array = []
	for iy in range(49):
		var row := PackedFloat64Array()
		for ix in range(97):
			row.append(-4.0 + iy * TUNING.physics_sdf_cell_wu)
		rows.append(row)
	var grid := SdfGrid.new()
	_check(grid.configure(rows, -12.0, -4.0, TUNING.physics_grip_friction, TUNING) == OK, "floor")
	var bottom := INF
	for body in model.create_bodies(0.0, 0.0):
		bottom = minf(bottom, minf(body.a.y, body.b.y) - body.radius)
	var tower := TowerData.new()
	var friction: Array[float] = [0.9, 0.9, 0.9]
	var bounce: Array[float] = [0.02, 0.02, 0.02]
	_check(
		tower.configure(grid, 0.0, .01 - bottom, friction, bounce, TUNING) == OK, "explicit tower"
	)
	var sim := Sim.new()
	sim.setup(model, tower, run_seed, TUNING)
	_check(sim.last_status == OK, "public setup succeeds with real motors and live spring")
	return sim


func _input(tick: int) -> int:
	if tick < 60:
		return 0
	return 1 if (tick / 60) % 2 == 1 else 2


func _rng_controls() -> void:
	var vectors: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://tests/fixtures/xoshiro128_vectors.json")
	)
	var rng := Xoshiro128StarStar.new()
	var state: Array = []
	for word in vectors.state:
		state.append(int(word))
	_check(rng.restore(state) == OK, "xoshiro known state")
	for output in vectors.outputs:
		_check(rng.next_u32() == int(output), "canonical independent xoshiro128** vector")
	var a := Xoshiro128StarStar.new()
	var b := Xoshiro128StarStar.new()
	var c := Xoshiro128StarStar.new()
	a.configure(RUN_SEED)
	b.configure(RUN_SEED)
	c.configure(RUN_SEED + 1)
	var different := false
	for index in range(100):
		var output := a.next_u32()
		_check(output == b.next_u32(), "same seed exact stream")
		var other := c.next_u32()
		different = different or output != other
	_check(different, "different seed different stream")
	var first := _rig()
	var second := _rig()
	var third := _rig(RUN_SEED + 1)
	_check(first.snapshot().rng == second.snapshot().rng, "seed reaches only injected instance")
	_check(first.snapshot().rng != third.snapshot().rng, "different seed propagated through Sim")
	var saved := rng.snapshot()
	_check(
		rng.restore([0, 0, 0, 0]) != OK and rng.snapshot() == saved,
		"all-zero RNG restore rejected atomically"
	)
	_report.runtime_gates["3"] = "MEASURED same/different-seed injection + canonical stream vectors; no random physics perturbation"


func _replays() -> void:
	_report.attempt_started = true
	var digest_tables: Array = []
	var finals: Array = []
	var results: Array = []
	var public_hashes: Array = []
	for run_index in range(3):
		var sim := _rig()
		var hashes: Array = []
		var stream := PackedByteArray()
		for tick in range(TICKS):
			sim.step(_input(tick))
			_check(sim.last_status == OK, "attempt1 replay tick completes")
			if sim.last_status != OK:
				return
			var state := sim.snapshot()
			var bytes := var_to_bytes(state)
			stream.append_array(bytes)
			hashes.append(sim.state_digest())
			if run_index == 0:
				_baseline_int_hashes.append(sim.state_hash())
				_baseline.append(state)
				_baseline_bytes.append(bytes)
			else:
				_check(sim.state_hash() == _baseline_int_hashes[tick], "public state_hash exact x3")
				_check(
					bytes == _baseline_bytes[tick],
					"full tick stream byte-identical replay%d tick%d" % [run_index, tick]
				)
		_check(sim.result() != null, "physics result exists, no manufactured gameplay score")
		results.append(sim.result().snapshot())
		finals.append(sim.state_digest())
		public_hashes.append(sim.state_hash())
		digest_tables.append(hashes)
		_streams.append(stream)
		var file := FileAccess.open(
			_folder.path_join("replay-%d.bin" % run_index), FileAccess.WRITE
		)
		_check(file != null, "raw full stream opens")
		if file != null:
			file.store_buffer(stream)
	_check(results[0] == results[1] and results[0] == results[2], "result fields exact x3")
	_check(
		_streams[0] == _streams[1] and _streams[0] == _streams[2],
		"ENTIRE tick streams byte equal x3"
	)
	_report["replay_final_digests"] = finals
	_report["replay_final_public_state_hashes"] = public_hashes
	_report["replay_result"] = results[0]
	_report["per_tick_digests"] = digest_tables[0]
	_report["replay_full_stream_bytes"] = _streams[0].size()
	_report["replay_streams_byte_equal"] = _streams[0] == _streams[1] and _streams[0] == _streams[2]
	_report.runtime_gates["9"] = "MEASURED x3 complete Slug, full tick bytes/hashes/results"
	var changed := _rig()
	var first_physical_differed := false
	for tick in range(TICKS):
		# Exactly ONE input bit at ONE tick: tick0 released0 XOR left1 =>1.
		changed.step(_input(tick) ^ (1 if tick == 0 else 0))
		_check(changed.last_status == OK, "falsification completes")
		if tick == 0:
			first_physical_differed = (
				changed.get_render_state() != _baseline[0].accumulator.solver.rig.physical.bodies
			)
	var digest := changed.state_digest()
	_check(changed.state_hash() != public_hashes[0], "public state_hash falsification differs too")
	_check(first_physical_differed, "bitflip changes actual bodies, not just held-input metadata")
	_check(digest != finals[0], "MANDATORY falsification different final hash; equal FAILS")
	_report["falsification"] = {
		"tick": 0,
		"bit": 1,
		"before_input": 0,
		"after_input": 1,
		"baseline_digest": finals[0],
		"changed_digest": digest,
		"physical_bodies_differ_at_flip": first_physical_differed
	}
	_report.runtime_gates["12"] = "MEASURED single left-bit tick0 flip, actual bodies AND final hash differ"


func _clock_controls() -> void:
	var one := _rig()
	var chunks := _rig()
	# Held-input boundaries align with chunks. No callback or raw elapsed math in solver.
	for frame in range(200):
		var input_mask := _input(frame * 3)
		for index in range(3):
			one.step(input_mask)
			_check(one.last_status == OK, "one-step delivery")
		var response := chunks.advance_frame(3.0 / 60.0, input_mask)
		_check(response.status == OK and response.steps == 3, "three fixed steps per chunk")
		_check(
			(
				Sim.digest(one.snapshot().accumulator.solver)
				== Sim.digest(chunks.snapshot().accumulator.solver)
			),
			"chunk equality at same tick"
		)
	var stall := _rig()
	var ordinary := _rig()
	var report := stall.advance_frame(2.0, 0)
	for index in range(3):
		ordinary.step(0)
	_check(report.status == OK and report.steps == 3 and report.pending == 0.0, "stall caps at3")
	_check(report.dropped == 2.0 - 3.0 / 60.0, "stall drops ALL excess exactly")
	_check(
		stall.snapshot().accumulator.solver == ordinary.snapshot().accumulator.solver,
		"stall same full solver bytes at equal ticks"
	)
	_report["stall"] = {
		"elapsed_s": 2.0,
		"steps": report.steps,
		"dropped_s": report.dropped,
		"pending_s": report.pending,
		"solver_equal_at_tick3":
		stall.snapshot().accumulator.solver == ordinary.snapshot().accumulator.solver,
		"clock_hash_scope":
		"whole-Sim hashes include delivery clock; compare full solver+RNG at equal ticks, clock differences explicitly retained"
	}
	_report.runtime_gates["2"] = "MEASURED held chunks vs fixed ticks + three-step stall/drop, actual accumulator"
	_report.runtime_gates["10"] = "MEASURED two-second stall; exact solver equality at tick3, delivery-clock difference retained"
	# Outer remainder is genuinely state, not a clock counter disconnected from simulation.
	var partial := _rig()
	var half := partial.advance_frame(1.0 / 120.0, 0)
	_check(half.status == OK and half.steps == 0, "half tick does not simulate")
	var saved := partial.snapshot()
	var resumed := _rig()
	resumed.restore(saved)
	_check(resumed.last_status == OK, "restore fractional pending")
	partial.advance_frame(1.0 / 120.0, 0)
	resumed.advance_frame(1.0 / 120.0, 0)
	_check(
		partial.state_digest() == resumed.state_digest(),
		"fractional clock + solver restored exactly"
	)


func _restore_controls() -> void:
	for tick in [0, 14, 59, 120, 359]:
		var sim := _rig()
		sim.restore(_baseline[tick])
		_check(sim.last_status == OK, "restore public solver+clock+contacts+motors+sleep+RNG")
		for next_tick in range(tick + 1, TICKS):
			sim.step(_input(next_tick))
			_check(
				(
					sim.last_status == OK
					and var_to_bytes(sim.snapshot()) == _baseline_bytes[next_tick]
				),
				"public restored continuation exact"
			)
	var sim := _rig()
	for field in ["rng", "clock", "body", "motor", "sleep", "constraint", "identity"]:
		var before := sim.snapshot()
		var bad := before.duplicate(true)
		match field:
			"rng":
				bad.rng = [0, 0, 0, 0]
			"clock":
				bad.accumulator.pending = -1.0
			"body":
				bad.accumulator.solver.rig.physical.bodies[0].a.x = NAN
			"motor":
				bad.accumulator.solver.rig.physical.angular_joints[0].rest_angle += .1
			"sleep":
				bad.accumulator.solver.rig.sleep.dwell_start = [{}]
			"constraint":
				bad.accumulator.solver.constraints.links[0].multiplier = INF
			"identity":
				bad.identity.tower.x += 1.0
		sim.restore(bad)
		_check(
			sim.last_status != OK and sim.snapshot() == before,
			"malformed %s restore atomic" % field
		)
	var before := sim.snapshot()
	sim.step(4)
	_check(
		sim.last_status != OK and sim.snapshot() == before,
		"invalid input returns explicit failure; no physical mutation"
	)
	var returned := sim.snapshot()
	returned.accumulator.solver.rig.physical.bodies[0].a.x += 100.0
	_check(sim.snapshot() == before, "snapshots detached, no mutable alias")


func _zero_input_live_sleep() -> void:
	var sim := _rig()
	var any_sleep := false
	var max_dwell := 0
	for tick in range(600):
		sim.step(0)
		_check(sim.last_status == OK, "live spring zero-input public tick")
		var sleep: Dictionary = sim.snapshot().accumulator.solver.rig.sleep
		any_sleep = any_sleep or sleep.asleep
		max_dwell = maxi(max_dwell, sleep.still_ticks)
	_check(not any_sleep, "F52 reachable motors+spring do NOT park walking Slug")
	_report["live_spring_sleep"] = {
		"ticks": 600,
		"any_sleep": any_sleep,
		"max_dwell_ticks": max_dwell,
		"scope":
		"F52 reachability observation, NOT AC-201/FA-4 acceptance; drift remedy pending owner"
	}
