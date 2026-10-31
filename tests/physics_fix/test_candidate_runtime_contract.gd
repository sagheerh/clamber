# gdlint: disable=max-line-length,max-returns
extends "res://tests/physics_fix/test_articulated_execution.gd"
## NEW test-only typed-factory validation, not production Sim adoption/signoff.
const RUNTIME = preload("res://tests/physics_fix/candidate_sim.gd")
const VALIDATED_AWAKE = preload("res://tests/physics_fix/final_geometry_constitutive_candidate.gd")
var _checks := 0
var _failures := 0
var _audited_awake := 0
var _signals: Array = []
var _active_sim: RUNTIME
var _completed_cases: Array = []
var _failure_evidence: Dictionary = {}
var _force_samples: Array = []
var _clamp_samples: Array = []


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report-dir="):
			_folder = arg.trim_prefix("--report-dir=")
	for name in ["Slug", "Hopper", "TwinRoller"]:
		if not _contract(name):
			break  # Even this validation suite stops at FIRST unexpected failure.
		_completed_cases.append(name)
	print("Candidate runtime contract: %d checks, %d failures" % [_checks, _failures])
	print("Candidate runtime audited awake ticks: %d" % _audited_awake)
	print(
		"Scope: TEST-ONLY candidate factories; real public inherited frame/clock/sleep/input paths; NOT production acceptance, FA3 or cross-architecture determinism"
	)
	if not _folder.is_empty():
		DirAccess.make_dir_recursive_absolute(_folder)
		var report := {
			"checks": _checks,
			"failures": _failures,
			"awake_force_audits": _audited_awake,
			"completed_cases": _completed_cases,
			"scope": "TEST-ONLY candidate runtime contract, not production or FA3",
			"force_samples_variant_base64": Marshalls.raw_to_base64(var_to_bytes(_force_samples)),
			"clamp_samples_variant_base64": Marshalls.raw_to_base64(var_to_bytes(_clamp_samples)),
			"failure_variant_base64":
			(
				Marshalls.raw_to_base64(var_to_bytes(_failure_evidence))
				if not _failure_evidence.is_empty()
				else null
			)
		}
		var file := FileAccess.open(_folder + "/summary.json", FileAccess.WRITE)
		if file == null:
			_failures += 1
		else:
			file.store_string(JSON.stringify(report, "", true, true))
			file.close()
	quit(1 if _failures else 0)


func _new_runtime(name: String) -> RUNTIME:
	var source := _sim(name, false)
	if source == null or source.last_status != OK:
		return null
	var sim := RUNTIME.new()
	sim.setup(source._creature, source._tower, 305419896, TUNING)
	_active_sim = sim
	return sim


func _contract(name: String) -> bool:
	var sim := _new_runtime(name)
	if not _require(
		(
			sim != null
			and sim.last_status == OK
			and sim.candidate_survives()
			and _spawn_matches_standalone(sim)
		),
		name + " typed configured candidate factory"
	):
		return false
	var initial := sim.snapshot()
	_signals = []
	sim.tick_completed.connect(func(s: Dictionary): _signals.append(s))
	# Substep held state is serialized but no tick, RNG or public signal is invented.
	var frame := sim.advance_frame(0.5 / 60.0, 1)
	if not _require(
		(
			frame.status == OK
			and frame.steps == 0
			and _signals.is_empty()
			and sim.snapshot().rng == initial.rng
			and sim.snapshot().accumulator.solver.held == 1
		),
		name + " held input accumulates without premature tick or RNG"
	):
		return false
	frame = sim.advance_frame(0.5 / 60.0, 1)
	if not _require(
		(
			frame.status == OK
			and frame.steps == 1
			and _signals.size() == 1
			and _force_ok(sim.last_row().awake_solver_trace_before_sleep_parking)
		),
		name + " exact 60Hz first full impulse tick"
	):
		return false
	var actual_trace: Dictionary = sim.last_row().awake_solver_trace_before_sleep_parking
	_force_samples.append({"name": name, "trace": actual_trace.duplicate(true)})
	for mutation in [
		"gravity",
		"endpoint",
		"target",
		"delivered",
		"N",
		"clamp",
		"raw_contact",
		"raw_damping",
		"raw_material",
		"raw_load",
		"raw_grip",
		"raw_bound",
		"raw_local_drag",
		"compensated_contact_drag"
	]:
		var fake: Dictionary = actual_trace.duplicate(true)
		match mutation:
			"gravity":
				fake.momentum_budget.gravity_impulse_y_ns += 0.01
			"endpoint":
				fake.feet[0].avx += 0.01
			"target":
				fake.drive_events[0].target += 0.01
			"delivered":
				fake.drive_events[0].impulse += 0.01
			"N":
				fake.previous_grounded_feet += 1
			"clamp":
				fake.momentum_budget.clamp_impulse_x_ns += 0.01
			"raw_contact":
				fake.contact_samples[0].normal_impulse_ns += 0.01
			"raw_material":
				fake.contact_samples[0].material_friction += 0.01
			"raw_load":
				fake.contact_batches[0].parts[0].applied_load_n += 0.01
			"raw_grip":
				fake.contact_samples[0].may_grip = not fake.contact_samples[0].may_grip
			"raw_bound":
				fake.drive_events[0].speed_maximum_impulse += 0.01
			"raw_local_drag":
				fake.authored_angular_damping[0].omega_after += 0.01
			"compensated_contact_drag":
				for sample in fake.contact_samples:
					if (
						sample.has("angular_drag_events")
						and not sample.angular_drag_events.is_empty()
					):
						sample.angular_drag_events[0].angular_impulse += 0.01
						sample.angular_drag_events[0].hinge_angular_impulse -= 0.01
						break
			"raw_damping":
				for sample in fake.contact_samples:
					if (
						sample.has("angular_drag_events")
						and not sample.angular_drag_events.is_empty()
					):
						sample.angular_drag_events[0].angular_impulse += 0.01
						break
		if not _require(
			not _force_ok(fake), name + " independent force checker rejects fake " + mutation
		):
			return false
	var checkpoint := sim.snapshot()
	sim.restore(checkpoint)
	if not _require(
		(
			sim.last_status == OK
			and sim.candidate_survives()
			and var_to_bytes(checkpoint) == var_to_bytes(sim.snapshot())
		),
		name + " valid restore byte-identical and candidate survives both factories"
	):
		return false
	# Every held mask and releases are audited from live, not fabricated forces.
	for mask in [2, 3, 0, 1, 0]:
		for tick in range(3):
			sim.step(mask)
			if not _require(
				(
					(
						sim.last_status == OK
						and sim.candidate_survives()
						and not sim._solver._rig._sleep.asleep
						and sim._solver._rig._sleep.still_ticks == 0
					)
					if mask != 0
					else sim.last_status == OK
				),
				name + " held/released live mask%d tick%d" % [mask, tick]
			):
				return false
			if not _require(
				_force_ok(sim.last_row().awake_solver_trace_before_sleep_parking),
				name + " independent actual force budget mask%d tick%d" % [mask, tick]
			):
				return false
	# Invalid restore MUST retain all physics/RNG/clock/constraints and candidate.
	for kind in ["rng", "clock", "body", "constraints", "identity"]:
		var good := sim.snapshot()
		var bad: Dictionary = good.duplicate(true)
		match kind:
			"rng":
				bad.rng = []
			"clock":
				bad.accumulator.pending = NAN
			"body":
				bad.accumulator.solver.rig.physical.bodies[0].a.velocity_x = INF
			"constraints":
				bad.accumulator.solver.constraints = {}
			"identity":
				bad.identity = {}
		sim.restore(bad)
		if not _require(
			(
				sim.last_status != OK
				and sim.candidate_survives()
				and var_to_bytes(good) == var_to_bytes(sim.snapshot())
			),
			name + " malformed " + kind + " restore atomically rejects without factory loss"
		):
			return false
	# A second tick fails AFTER one real tick + injected body mutation. No public
	# partial-frame signals may escape. This is NOT a second physics measurement.
	var before := sim.snapshot()
	var emitted := _signals.size()
	sim.inject_failure(sim._solver.tick_count() + 1)
	frame = sim.advance_frame(3.0 / 60.0, 3)
	if not _require(
		(
			frame.status != OK
			and not frame.rollback_failed
			and sim.candidate_survives()
			and _signals.size() == emitted
			and var_to_bytes(before) == var_to_bytes(sim.snapshot())
		),
		name + " partial-frame mutated failure rolls back ALL state/signals and keeps candidate"
	):
		return false
	sim.inject_failure(-1)
	frame = sim.advance_frame(4.0 / 60.0, 2)
	if not _require(
		(
			frame.status == OK
			and frame.steps == 3
			and frame.dropped > 0.0
			and frame.pending == 0.0
			and _signals.size() == emitted + 3
			and sim.candidate_survives()
		),
		name + " candidate continues after rollback with capped 3-tick catchup/drop"
	):
		return false
	# Natural sleep -> each input bit, BOTH, and release. Fresh real spawn each
	# case, NO injected parking, fake grounded flags, wake thresholds or loads.
	for mask in [1, 2, 3]:
		var wake_sim := _new_runtime(name)
		var asleep := false
		for tick in range(600):
			wake_sim.step(0)
			if wake_sim.last_status != OK:
				break
			if wake_sim._solver._rig._sleep.asleep:
				asleep = true
				break
		if not _require(
			asleep and wake_sim.last_status == OK,
			name + " natural full-creature sleep before wake mask%d" % mask
		):
			return false
		var sleeping := wake_sim.snapshot()
		wake_sim.restore(sleeping)
		if not _require(
			(
				wake_sim.last_status == OK
				and wake_sim.candidate_survives()
				and var_to_bytes(sleeping) == var_to_bytes(wake_sim.snapshot())
			),
			name + " sleeping restore preserves actual anchored dwell and candidate"
		):
			return false
		wake_sim.step(mask)
		var row: Dictionary = wake_sim.last_row()
		if not _require(
			(
				wake_sim.last_status == OK
				and row.wake_reason == "input"
				and not row.sleep.asleep
				and row.sleep.still_ticks == 0
				and _force_ok(row.awake_solver_trace_before_sleep_parking)
			),
			(
				name
				+ (
					" real input wakes whole creature, rearms dwell, applies actual mask%d force"
					% mask
				)
			)
		):
			return false
		wake_sim.step(0)
		if not _require(
			(
				wake_sim.last_status == OK
				and _force_ok(wake_sim.last_row().awake_solver_trace_before_sleep_parking)
			),
			name + " release after wake uses prescribed return law"
		):
			return false
	var clamp_rig := VALIDATED_AWAKE.new()
	var model := AUTHORED_MODELS.load_model(name, TUNING)
	if (
		clamp_rig.setup(
			model,
			_grid(false),
			0.0,
			R25Fixture.spawn_y(model),
			R25Fixture.materials(model),
			R25Fixture.materials(model, true),
			TUNING
		)
		!= OK
	):
		return _require(false, name + " clamp component setup")
	for body in clamp_rig.bodies:
		body.a.velocity_x = 100.0
		body.b.velocity_x = 100.0
	var budget := {}
	for stage in ["drive_internal", "damping", "gravity", "internal", "contact_velocity", "clamp"]:
		for axis in ["x", "y"]:
			budget[stage + "_impulse_" + axis + "_ns"] = 0.0
	var status: Error = clamp_rig._begin_tick()
	if status == OK:
		status = clamp_rig._apply_forces(1.0 / 60.0, budget)
	if not _require(
		status == OK and clamp_rig.snapshot().ticks == 0 and _clamp_force_ok(clamp_rig, budget),
		(
			name
			+ " actual nonzero linear clamp follows fixed resource and full fresh gravity; force component, no integration"
		)
	):
		return false
	_clamp_samples.append(
		{"name": name, "bodies": clamp_rig.snapshot().bodies, "budget": budget.duplicate(true)}
	)
	var fake_budget: Dictionary = budget.duplicate(true)
	fake_budget.clamp_impulse_x_ns = 0.0
	if not _require(
		not _clamp_force_ok(clamp_rig, fake_budget),
		name + " real positive-clamp audit rejects omitted clamp impulse"
	):
		return false
	return true


func _force_ok(trace: Dictionary) -> bool:
	if not FULL_FORCE_AUDIT.validate(trace):
		return false
	_audited_awake += 1
	return true


func _require(ok: bool, label: String) -> bool:
	_checks += 1
	if not ok:
		_failures += 1
		if _failure_evidence.is_empty() and _active_sim != null:
			_failure_evidence = {
				"label": label,
				"snapshot": _active_sim.snapshot(),
				"physics_failure": _active_sim.last_failure.duplicate(true),
				"last_row": _active_sim.last_row().duplicate(true)
			}
		push_error("FAIL " + label)
	return ok


func _spawn_matches_standalone(sim: RUNTIME) -> bool:
	var actual := VALIDATED_AWAKE.new()
	var spec := sim._tower.snapshot()
	if (
		actual.setup(
			sim._creature,
			sim._tower.terrain(TUNING),
			spec.x,
			spec.y,
			spec.friction,
			spec.restitution,
			TUNING
		)
		!= OK
	):
		return false
	return var_to_bytes(actual.snapshot()) == var_to_bytes(sim._solver._rig._probe.snapshot())


func _clamp_force_ok(rig: RefCounted, budget: Dictionary) -> bool:
	var vx: float = 100.0 * (1.0 - TUNING.physics_linear_damping)
	var vy: float = TUNING.physics_gravity_wu_s2 / 60.0
	var scale: float = TUNING.physics_max_linear_velocity_wu_s / sqrt(vx * vx + vy * vy)
	var mass := 0.0
	for body in rig.bodies:
		mass += body.mass
		for point in [body.a, body.b]:
			if (
				absf(point.velocity_x - vx * scale) > 1e-12
				or absf(point.velocity_y - vy * scale) > 1e-12
			):
				return false
	return (
		absf(budget.clamp_impulse_x_ns - mass * (vx * scale - vx)) < 1e-12
		and absf(budget.clamp_impulse_y_ns - mass * (vy * scale - vy)) < 1e-12
		and budget.clamp_impulse_x_ns < 0.0
	)
