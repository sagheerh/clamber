extends SceneTree
## Synthetic points/links only; no creature replay, soak, baseline or AC evidence.
const Body = preload("res://core/sim/body.gd")
const Link = preload("res://core/sim/constraint.gd")
const Solver = preload("res://core/sim/solver.gd")
const Clock = preload("res://core/sim/accumulator.gd")
const TUNING = preload("res://core/tuning.tres")
var _checks := 0
var _failures := 0


class RollbackFailureSolver:
	extends PointLinkSolver
	var restore_calls := 0

	func step() -> Error:
		var status := super.step()
		return ERR_BUSY if status == OK else status

	func restore(_state: Dictionary) -> Error:
		restore_calls += 1
		return ERR_CANT_CREATE


func _initialize() -> void:
	_setup_guards()
	_gravity()
	_damping_clamp_and_pinning()
	_ordering()
	_catch_up_cap()
	_frame_chunks()
	_invalid_state_and_input()
	_frame_rollback()
	_rollback_failure_is_reported()
	_restore_and_step()
	print("M1 integration primitives: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("FAIL M1 integration: " + label)


func _point(x: float, y: float, weight: float) -> SimBody:
	var body := Body.new()
	_check(body.setup(x, y, weight) == OK, "explicit synthetic point")
	return body


func _free(tuning: Tuning) -> Dictionary:
	var body := _point(0.0, 0.0, 1.0)
	var solver := Solver.new()
	_check(solver.setup([body], [], tuning) == OK, "free point solver setup")
	var clock := Clock.new()
	_check(clock.setup(solver) == OK, "outer clock setup")
	return {"solver": solver, "clock": clock, "body": body}


func _chain() -> Dictionary:
	var a := _point(0.0, 3.0, 0.0)
	var b := _point(1.2, 3.0, 1.0)
	var c := _point(2.5, 3.5, 0.5)
	var ab := Link.new()
	var bc := Link.new()
	_check(ab.setup(a, b, 1.0, 1.0 / TUNING.physics_passive_stiffness) == OK, "compliant AB")
	_check(bc.setup(b, c, 1.1, TUNING.physics_rigid_compliance) == OK, "rigid BC")
	var bodies: Array[SimBody] = [a, b, c]
	var links: Array[DistanceConstraint] = [ab, bc]
	var solver := Solver.new()
	_check(solver.setup(bodies, links, TUNING) == OK, "index-ordered chain setup")
	var clock := Clock.new()
	_check(clock.setup(solver) == OK, "chain clock setup")
	return {"solver": solver, "clock": clock, "bodies": bodies, "links": links}


func _setup_guards() -> void:
	var solver := Solver.new()
	var clock := Clock.new()
	_check(solver.step() != OK and clock.advance(0.0) != OK, "unconfigured calls rejected")
	_check(clock.setup(null) != OK, "null clock target rejected")
	var a := _point(0.0, 0.0, 1.0)
	var b := _point(1.0, 0.0, 1.0)
	var link := Link.new()
	_check(link.setup(a, b, 1.0, 0.0) == OK, "setup fixture link")
	_check(solver.setup([a, b], [link], TUNING) == OK, "valid mathematical graph")
	var before := solver.snapshot()
	for bodies in [[], [a, a], [a]]:
		var typed_bodies: Array[SimBody] = []
		typed_bodies.assign(bodies)
		_check(
			solver.setup(typed_bodies, [link], TUNING) != OK,
			"empty/duplicate/foreign graph rejected"
		)
		_check(solver.snapshot() == before, "failed setup is atomic")
	_check(solver.setup([a, b], [link, link], TUNING) != OK, "duplicate constraint rejected")
	_check(solver.setup([a, b], [link], null) != OK, "null tuning rejected")
	for bad in [NAN, INF, -INF]:
		var tuning: Tuning = TUNING.duplicate(true)
		tuning.physics_gravity_wu_s2 = bad
		_check(solver.setup([a, b], [link], tuning) != OK, "non-finite tuning rejected")
	_check(solver.snapshot() == before, "all invalid setup attempts preserve state")


func _gravity() -> void:
	for factor in [1.0, 0.5]:
		var tuning: Tuning = TUNING.duplicate(true)
		tuning.physics_linear_damping = 0.0  # Synthetic analytic fixture, not shipped tuning.
		tuning.physics_gravity_wu_s2 = TUNING.physics_gravity_wu_s2 * factor
		var f := _free(tuning)
		var solver: PointLinkSolver = f.solver
		var body: SimBody = f.body
		body.x = 3.0
		body.y = 5.0
		body.velocity_x = 2.0
		var dt := float(tuning.physics_one) / tuning.physics_tick_hz
		var count := 7
		for tick in range(count):
			_check(solver.step() == OK, "analytic gravity fixed tick")
		var expected := 5.0 + tuning.physics_gravity_wu_s2 * dt * dt * count * (count + 1) / 2.0
		_check(absf(body.y - expected) <= 1e-12, "semi-implicit gravity position after N ticks")
		_check(absf(body.x - (3.0 + 2.0 * dt * count)) <= 1e-12, "fixed horizontal drift")
		_check(solver.tick_count() == count, "exact fixed tick count")
		# Setup owns a resource copy; caller edits cannot retune a running solver.
		tuning.physics_gravity_wu_s2 = NAN
		_check(solver.step() == OK, "caller tuning mutation cannot change frozen configuration")


func _damping_clamp_and_pinning() -> void:
	var tuning: Tuning = TUNING.duplicate(true)
	tuning.physics_gravity_wu_s2 = 0.0
	var f := _free(tuning)
	var body: SimBody = f.body
	body.velocity_x = 2.0
	var dt: float = f.solver.fixed_step()
	_check(f.solver.step() == OK, "damped step")
	var expected := 2.0 * (tuning.physics_one - tuning.physics_linear_damping)
	_check(absf(body.x - expected * dt) <= 1e-12, "tuning-owned per-tick linear damping")
	body.velocity_x = 1e4
	var previous := body.x
	_check(f.solver.step() == OK, "speed clamp step")
	_check(
		absf(body.x - previous - tuning.physics_max_linear_velocity_wu_s * dt) <= 1e-12,
		"pre-drift clamp uses tuning speed, not an invented bound"
	)
	_check(
		absf(body.velocity_x - tuning.physics_max_linear_velocity_wu_s) <= 1e-12, "post-solve clamp"
	)
	var pinned := _point(2.0, 3.0, 0.0)
	pinned.velocity_x = 7.0
	pinned.velocity_y = -9.0
	var solver := Solver.new()
	_check(solver.setup([pinned], [], TUNING) == OK and solver.step() == OK, "pinned tick")
	_check(pinned.x == 2.0 and pinned.y == 3.0, "pinned point ignores gravity/drift")
	_check(pinned.velocity_x == 0.0 and pinned.velocity_y == 0.0, "pinned velocity zero")


func _ordering() -> void:
	var reference: Dictionary = {}
	for run in range(4):
		var f := _chain()
		# Mutating the caller arrays must not change the solver's copied index order.
		f.bodies.reverse()
		f.links.clear()
		for tick in range(12):
			_check(f.solver.step() == OK, "ordered chain fixed tick")
		var state: Dictionary = f.solver.snapshot()
		_check(
			state.bodies[0].x == 0.0 and state.bodies[0].y == 3.0, "part index zero remains anchor"
		)
		_check(state.links.size() == 2, "caller array mutation cannot remove constraints")
		if run == 0:
			reference = state
		else:
			_check(state == reference, "fresh ordered body/link set gives identical snapshot")


func _catch_up_cap() -> void:
	var f := _chain()
	var dt: float = f.solver.fixed_step()
	var cap: int = TUNING.physics_max_catch_up_steps
	_check(f.clock.advance(dt / 2.0) == OK, "fractional frame retained")
	var frame_seconds := float(cap + 2) * dt + dt / 4.0
	var accumulated := dt / 2.0 + frame_seconds
	_check(f.clock.advance(frame_seconds) == OK, "oversized frame accepted at cap")
	var state: Dictionary = f.clock.snapshot()
	_check(
		f.solver.tick_count() == cap and state.last_steps == cap,
		"at most tuning catch-up cap ticks"
	)
	_check(state.pending == 0.0, "all excess including fractional remainder dropped at cap")
	_check(
		state.dropped == accumulated - float(cap) * dt, "exact dropped amount derived from tuning"
	)
	_check(
		f.clock.advance(0.0) == OK and f.solver.tick_count() == cap,
		"dropped backlog never runs later"
	)
	_check(f.clock.snapshot().dropped == state.dropped, "dropped seconds retained for diagnostics")


func _frame_chunks() -> void:
	var a := _chain()
	var b := _chain()
	var dt: float = a.solver.fixed_step()
	for cycle in range(6):
		_check(a.clock.advance(dt * 2.0) == OK, "two-tick frame")
		for chunk in range(4):
			_check(b.clock.advance(dt / 2.0) == OK, "half-tick frame")
	_check(
		a.solver.tick_count() == 12 and b.solver.tick_count() == 12,
		"same total time, same tick count"
	)
	_check(
		a.solver.snapshot() == b.solver.snapshot(),
		"different frame chunks, identical simulated state"
	)
	_check(a.clock.snapshot().pending == b.clock.snapshot().pending, "equal fractional remainder")
	_check(
		a.clock.snapshot().dropped == 0.0 and b.clock.snapshot().dropped == 0.0,
		"no cap drop in equivalence fixture"
	)


func _invalid_state_and_input() -> void:
	var f := _chain()
	var dt: float = f.solver.fixed_step()
	_check(f.clock.advance(dt / 2.0) == OK, "nonzero clock remainder for atomicity tests")
	var valid: Dictionary = f.clock.snapshot()
	for value in [NAN, INF, -INF, -dt]:
		_check(f.clock.advance(value) != OK, "non-finite/negative frame rejected")
		_check(f.clock.snapshot() == valid, "bad elapsed input mutates nothing")
	for value in [NAN, INF, -INF, 1e308]:
		f.bodies[1].velocity_x = value
		var corrupted := var_to_bytes(f.clock.snapshot())
		_check(f.clock.advance(dt) != OK, "non-finite/overflow state rejected")
		_check(
			var_to_bytes(f.clock.snapshot()) == corrupted,
			"rejected state retained byte-for-byte, not healed"
		)
		_check(f.clock.restore(valid) == OK, "explicit validated restore recovers fixture")
	f.links[1].multiplier = INF
	var corrupted := var_to_bytes(f.clock.snapshot())
	_check(f.solver.step() != OK, "non-finite link multiplier rejected")
	_check(var_to_bytes(f.clock.snapshot()) == corrupted, "link error mutates no body/clock")
	_check(f.clock.restore(valid) == OK, "explicit link recovery")
	# Finite inverse masses whose sum overflows must roll back earlier integration.
	var a := _point(0.0, 0.0, 1e308)
	var b := _point(1.0, 0.0, 1e308)
	var link := Link.new()
	_check(link.setup(a, b, 1.0, 0.0) == OK, "finite denominator-overflow fixture")
	link.multiplier = 7.0
	var solver := Solver.new()
	_check(solver.setup([a, b], [link], TUNING) == OK, "overflow graph setup")
	var before := solver.snapshot()
	_check(
		solver.step() != OK and solver.snapshot() == before,
		"late projection overflow rolls back all points/lambda/tick"
	)
	var huge := _free(TUNING)
	_check(
		huge.clock.advance(1e308) == OK,
		"huge finite frame is bounded by cap, not converted to integer tick count"
	)
	before = huge.clock.snapshot()
	_check(huge.clock.advance(1e308) != OK, "cumulative dropped-time overflow rejected")
	_check(huge.clock.snapshot() == before, "dropped-time overflow is atomic")


func _collision_fixture() -> Dictionary:
	# Exact synthetic coincidence on tick two; no actual contacts are implemented.
	var tuning: Tuning = TUNING.duplicate(true)
	tuning.physics_gravity_wu_s2 = 0.0
	tuning.physics_linear_damping = 0.0
	var dt := float(tuning.physics_one) / tuning.physics_tick_hz
	var travel := tuning.physics_max_linear_velocity_wu_s * dt
	var a := _point(0.0, 0.0, 0.0)
	var b := _point(travel * 2.0, 0.0, 1.0)
	b.velocity_x = -tuning.physics_max_linear_velocity_wu_s
	var link := Link.new()
	_check(link.setup(a, b, travel, 0.0) == OK, "coincidence rejection fixture")
	var solver := Solver.new()
	_check(solver.setup([a, b], [link], tuning) == OK, "coincidence graph setup")
	var clock := Clock.new()
	_check(clock.setup(solver) == OK, "coincidence clock setup")
	return {"solver": solver, "clock": clock}


func _frame_rollback() -> void:
	var probe := _collision_fixture()
	_check(probe.solver.step() == OK, "tick one genuinely succeeds before late frame failure")
	var tick_one: Dictionary = probe.solver.snapshot()
	_check(
		probe.solver.step() != OK and probe.solver.snapshot() == tick_one,
		"tick two fails atomically"
	)
	var f := _collision_fixture()
	var before: Dictionary = f.clock.snapshot()
	_check(
		f.clock.advance(f.solver.fixed_step() * 2.0) != OK, "second tick failure reported by frame"
	)
	_check(f.clock.snapshot() == before, "entire frame rolled back including successful first tick")


func _restore_and_step() -> void:
	var f := _chain()
	var dt: float = f.solver.fixed_step()
	_check(
		f.clock.advance(float(TUNING.physics_max_catch_up_steps + 2) * dt) == OK,
		"checkpoint has dropped-time history"
	)
	_check(f.clock.advance(dt / 2.0) == OK, "checkpoint has fractional future time")
	var saved: Dictionary = f.clock.snapshot()
	_check(f.clock.advance(dt * 1.5) == OK, "advance from checkpoint")
	var expected: Dictionary = f.clock.snapshot()
	_check(
		f.clock.restore(saved) == OK and f.clock.snapshot() == saved,
		"exact outer plus solver restore"
	)
	_check(f.clock.advance(dt * 1.5) == OK, "re-step same fixed ticks after restore")
	_check(
		f.clock.snapshot() == expected,
		"snapshot restore advance reproduces identical complete snapshot"
	)
	var solver_saved: Dictionary = f.solver.snapshot()
	_check(f.solver.step() == OK, "direct step before restore")
	expected = f.solver.snapshot()
	_check(
		f.solver.restore(solver_saved) == OK and f.solver.step() == OK, "direct restore then step"
	)
	_check(f.solver.snapshot() == expected, "direct snapshot restore step identity")
	var before: Dictionary = f.clock.snapshot()
	var candidates: Array = []
	var bad := before.duplicate(true)
	bad.pending = INF
	candidates.append(bad)
	bad = before.duplicate(true)
	bad.last_steps = -1
	candidates.append(bad)
	bad = before.duplicate(true)
	bad.solver.bodies[2].velocity_y = NAN
	candidates.append(bad)
	bad = before.duplicate(true)
	bad.solver.links[1].multiplier = INF
	candidates.append(bad)
	bad = before.duplicate(true)
	bad.solver.settings.gravity = 0.0
	candidates.append(bad)
	bad = before.duplicate(true)
	bad.solver.topology[0][0] = 1
	candidates.append(bad)
	for candidate in candidates:
		_check(
			f.clock.restore(candidate) != OK,
			"invalid clock/body/link/config/graph candidate rejected"
		)
		_check(
			f.clock.snapshot() == before,
			"restore validates entire candidate before any publication"
		)
	var detached := before.duplicate(true)
	detached.solver.bodies[0].x = 999.0
	_check(f.clock.snapshot() == before, "returned nested snapshots do not alias live state")


func _rollback_failure_is_reported() -> void:
	var body := _point(0.0, 0.0, 1.0)
	var solver := RollbackFailureSolver.new()
	_check(solver.setup([body], [], TUNING) == OK, "rollback-failure graph setup")
	var clock := Clock.new()
	_check(clock.setup(solver) == OK, "rollback-failure clock setup")
	var before := solver.snapshot()
	_check(
		clock.advance(solver.fixed_step()) == ERR_CANT_CREATE,
		"rollback failure supersedes tick error"
	)
	_check(solver.restore_calls == 1, "failed frame actually attempted rollback")
	_check(
		solver.snapshot() != before and solver.tick_count() == 1,
		"forced rollback failure exposes changed solver, not silent recovery"
	)
	_check(
		clock.snapshot().last_steps == 0, "failed call does not publish successful clock progress"
	)
