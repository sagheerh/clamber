# gdlint: disable=max-line-length,max-returns
extends "res://tests/physics_fix/test_articulated_execution.gd"
## NEW test-only typed-factory validation, not production Sim adoption/signoff.
const RUNTIME = preload("res://tests/physics_fix/candidate_sim.gd")
var _checks := 0
var _failures := 0
var _audited_awake := 0
var _signals: Array = []
var _active_sim: RUNTIME
var _completed_cases: Array = []
var _failure_evidence: Dictionary = {}


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
		sim != null and sim.last_status == OK and sim.candidate_survives(),
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
	for mutation in [
		"gravity", "endpoint", "target", "delivered", "N", "clamp", "raw_contact", "raw_damping"
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
	return true


func _force_ok(trace: Dictionary) -> bool:
	if trace.get("status") != OK:
		return false
	var budget: Dictionary = trace.momentum_budget
	var bodies: Array = trace.feet + trace.other_bodies
	var mass := 0.0
	var prev_feet := 0
	for body in bodies:
		mass += body.mass
		if trace.feet.has(body) and body.grounded_previous:
			prev_feet += 1
	if (
		prev_feet != trace.previous_grounded_feet
		or absf(budget.gravity_impulse_y_ns - mass * TUNING.physics_gravity_wu_s2 / 60.0) > 1e-12
	):
		return false
	for axis in ["x", "y"]:
		var actual := 0.0
		for body in bodies:
			actual += (
				body.mass
				* (
					body["av" + axis]
					+ body["bv" + axis]
					- body["start_av" + axis]
					- body["start_bv" + axis]
				)
				/ 2.0
			)
		var reported := 0.0
		for stage in [
			"drive_internal", "damping", "gravity", "internal", "contact_velocity", "clamp"
		]:
			reported += budget[stage + "_impulse_" + axis + "_ns"]
		if (
			absf(actual - reported) > 1e-12
			or absf(actual - budget["momentum_change_" + axis + "_ns"]) > 1e-12
		):
			return false
	for event in trace.drive_events:
		var target := 0.0
		var torque: float
		if event.kind == "motor":
			var bit := 1 if event.channel == "L" else 2
			if trace.input_mask & bit:
				target = (
					-TUNING.motors_contraction_deg
					* PlanarBasis.TABLE.DEGREE_RADIANS
					* TUNING.motors_gain_default
				)
			torque = clampf(
				(
					TUNING.motors_joint_stiffness * (target - event.q)
					- TUNING.motors_joint_damping * event.omega
				),
				-TUNING.motors_max_torque * TUNING.motors_gain_default,
				TUNING.motors_max_torque * TUNING.motors_gain_default
			)
		else:
			torque = -TUNING.physics_passive_stiffness * event.q
		var bound: float = (
			TUNING.physics_max_constraint_angular_impulse_rad_s
			/ (event.parent_inverse_inertia + event.child_inverse_inertia)
		)
		var delivered := clampf(
			torque / 60.0, -bound - event.impulse_before, bound - event.impulse_before
		)
		if event.speed_minimum_impulse <= event.speed_maximum_impulse:
			delivered = clampf(delivered, event.speed_minimum_impulse, event.speed_maximum_impulse)
			delivered = clampf(
				delivered, -bound - event.impulse_before, bound - event.impulse_before
			)
		if (
			event.target != target
			or absf(event.torque - torque) > 1e-12
			or absf(event.requested_impulse - torque / 60.0) > 1e-12
			or absf(event.impulse - delivered) > 1e-12
		):
			return false
	if not _contact_ok(trace, bodies):
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


func _contact_ok(trace: Dictionary, bodies: Array) -> bool:
	# Actual endpoint deltas, per-observation pose, true skin lever arms, shared
	# hinge/drag/limit/connector event counted ONCE per full articulated batch.
	var by_part := {}
	for body in bodies:
		by_part[body.part] = body
	for batch in trace.contact_batches:
		var events := {}
		var terrain := {}
		var shared: Dictionary = {}
		for sample in trace.contact_samples:
			if sample.velocity_pass != batch.velocity_pass:
				continue
			if not events.has(sample.part):
				events[sample.part] = sample
				terrain[sample.part] = {"x": 0.0, "y": 0.0, "torque": 0.0}
			if sample.get("manifold_shared_event", false) and shared.is_empty():
				shared = sample
			var jx: float = (
				sample.normal_impulse_ns * sample.nx - sample.tangential_impulse_ns * sample.ny
			)
			var jy: float = (
				sample.normal_impulse_ns * sample.ny + sample.tangential_impulse_ns * sample.nx
			)
			var pose: Dictionary = batch.parts[sample.part]
			var rx: float = (
				(sample.u - 0.5) * (pose.b[0] - pose.a[0])
				- by_part[sample.part].radius_wu * sample.nx
			)
			var ry: float = (
				(sample.u - 0.5) * (pose.b[1] - pose.a[1])
				- by_part[sample.part].radius_wu * sample.ny
			)
			terrain[sample.part].x += jx
			terrain[sample.part].y += jy
			terrain[sample.part].torque += rx * jy - ry * jx
		if events.size() != bodies.size():
			return false
		var actual_x := 0.0
		var actual_y := 0.0
		var reported_x := 0.0
		var reported_y := 0.0
		for part in events:
			var sample: Dictionary = events[part]
			var body: Dictionary = by_part[part]
			actual_x += (
				body.mass
				* (sample.avx_after + sample.bvx_after - sample.avx_before - sample.bvx_before)
				/ 2.0
			)
			actual_y += (
				body.mass
				* (sample.avy_after + sample.bvy_after - sample.avy_before - sample.bvy_before)
				/ 2.0
			)
			reported_x += terrain[part].x
			reported_y += terrain[part].y
			var pose: Dictionary = batch.parts[part]
			var dx: float = pose.b[0] - pose.a[0]
			var dy: float = pose.b[1] - pose.a[1]
			var actual_angular: float = (
				body.mass
				* (
					(
						dx
						* (
							sample.bvy_after
							- sample.avy_after
							- sample.bvy_before
							+ sample.avy_before
						)
					)
					- (
						dy
						* (
							sample.bvx_after
							- sample.avx_after
							- sample.bvx_before
							+ sample.avx_before
						)
					)
				)
				/ 4.0
			)
			var reported_angular: float = terrain[part].torque
			if not shared.is_empty():
				for event in shared.angular_drag_events:
					if event.part == part:
						reported_angular += (
							event.angular_impulse
							+ event.connector_angular_impulse
							+ event.limit_angular_impulse
							+ event.hinge_angular_impulse
						)
			if absf(actual_angular - reported_angular) > 1e-12:
				return false
		if absf(actual_x - reported_x) > 1e-12 or absf(actual_y - reported_y) > 1e-12:
			return false
	return true
