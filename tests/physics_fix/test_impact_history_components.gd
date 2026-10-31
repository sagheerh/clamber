# gdlint: disable=max-line-length
extends SceneTree
## Native components only. No public Sim clock, historic world replay or verdict.
const NEW = preload("res://tests/physics_fix/impact_history_mobility.gd")
const OLD = preload("res://tests/physics_fix/articulated_mobility_candidate.gd")
const TERRAIN = preload("res://tests/physics_fix/impact_history_terrain.gd")
const CANDIDATE = preload("res://tests/physics_fix/impact_history_candidate.gd")
const ENERGY = preload("res://tests/physics_fix/rigid_contact_candidate.gd")
const CONFIG = preload("res://core/tuning.tres")
var _checks := 0
var _failures := 0


func _initialize() -> void:
	var parents: Array[int] = [-1]
	var bodies := _one(-28.0 / 60.0, 0.0)
	var network := NEW.new()
	network.history = _states(_one(0.0, 0.0))
	var valid: bool = network.configure(bodies, parents) == OK
	var result: Dictionary = network.contact_velocity(bodies, 0, 0.5, 0.0, 1.0, 1.0, 0.02)
	_check(
		(
			valid
			and not result.is_empty()
			and result.normal_target == 0.0
			and bodies[0].a.velocity_y == 0.0
		),
		"gravity-supported rest is not a new restitution impact"
	)
	bodies = _one(-1.0 - 28.0 / 60.0, 0.0)
	network = NEW.new()
	network.history = _states(_one(-1.0, 0.0))
	valid = network.configure(bodies, parents) == OK
	result = network.contact_velocity(bodies, 0, 0.5, 0.0, 1.0, 1.0, 0.02)
	_check(
		(
			valid
			and not result.is_empty()
			and result.normal_target == 0.02
			and absf(bodies[0].a.velocity_y - 0.02) < 1e-12
		),
		"real incoming impact retains original restitution0.02"
	)
	bodies = _one(0.1, 0.0)
	network = NEW.new()
	network.history = _states(_one(0.0, 0.0))
	valid = network.configure(bodies, parents) == OK
	var bits := _bits(bodies)
	result = TERRAIN._constrained_contact_response(network, bodies, 0, 0.0, 0.0, 1.0, 1.0, 0.02)
	_check(
		(
			valid
			and not result.is_empty()
			and result.normal_impulse_ns == 0.0
			and bits == _bits(bodies)
		),
		"separating zero-response identity remains exact"
	)
	network = NEW.new()
	valid = network.configure(bodies, parents) == OK
	_check(
		(
			valid
			and network.contact_velocity(bodies, 0, 0.0, 0.0, 1.0, 1.0, 0.02).is_empty()
			and bits == _bits(bodies)
		),
		"missing history fails closed without publishing"
	)
	network = NEW.new()
	network.history = _states(_one(0.0, 0.0))
	valid = network.configure(bodies, parents) == OK
	network.history[0].a.velocity_y = 1.0
	_check(
		(
			valid
			and network.contact_velocity(bodies, 0, 0.0, 0.0, 1.0, 1.0, 0.02).is_empty()
			and bits == _bits(bodies)
		),
		"mutated history invalidates factor atomically"
	)
	network = NEW.new()
	network.history = _states(_one(0.0, 0.0))
	valid = network.configure(bodies, parents) == OK
	bodies[0].a.x += 0.01
	bits = _bits(bodies)
	_check(
		(
			valid
			and network.contact_velocity(bodies, 0, 0.0, 0.0, 1.0, 1.0, 0.02).is_empty()
			and bits == _bits(bodies)
		),
		"changed geometry invalidates factor, not repaired"
	)
	# This exact known reprojection must STILL fail the original strict barrier.
	var report: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(
			"res://tests/fixtures/m1_articulated_execution/797a85674f31/idle-Slug-failure.json"
		)
	)
	var full: Dictionary = bytes_to_var(Marshalls.base64_to_raw(report.full_state_variant_base64))
	bodies = _restore(full.awake_trace.work_state.bodies)
	network = NEW.new()
	var slug_parents: Array[int] = [-1, 0, 1]
	valid = network.configure(bodies, slug_parents) == OK
	bits = _bits(bodies)
	_check(
		valid and network.project_velocity(bodies).is_empty() and bits == _bits(bodies),
		"original positive-energy rejection retained; no combined allowance or ULP repair"
	)

	# The exact closed V12 finite-energy defect MUST disappear, not be waived.
	var archived: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(
			"res://tests/fixtures/m1_articulated_execution/a45a2b50eb67/idle-Slug-failure.json"
		)
	)
	var decoded: Dictionary = bytes_to_var(
		Marshalls.base64_to_raw(archived.full_state_variant_base64)
	)
	bodies = _restore(
		bytes_to_var(Marshalls.base64_to_raw(decoded.awake_trace.full_work_variant_base64))
	)
	network = NEW.new()
	network.history = decoded.candidate.bodies.duplicate(true)
	valid = network.configure(bodies, slug_parents) == OK
	var energy_before: float = _energy(bodies)
	result = network.contact_velocity(bodies, 2, 1.0, 0.0, 1.0, 0.0, 0.02)
	_check(
		valid and not result.is_empty() and _energy(bodies) < energy_before,
		"V12 archived tangential response is strictly dissipative, no allowance"
	)
	# With matching impact history this is the unchanged original law, bitwise.
	bodies = _one(-1.0, 0.0)
	var control_bodies := _one(-1.0, 0.0)
	network = NEW.new()
	network.history = _states(bodies)
	var control := OLD.new()
	var one: Array[int] = [-1]
	valid = network.configure(bodies, one) == OK and control.configure(control_bodies, one) == OK
	result = network.contact_velocity(bodies, 0, 0.5, 0.0, 1.0, 1.0, 0.02)
	var old_result: Dictionary = control.contact_velocity(
		control_bodies, 0, 0.5, 0.0, 1.0, 1.0, 0.02
	)
	_check(
		(
			valid
			and not result.is_empty()
			and not old_result.is_empty()
			and _bits(bodies) == _bits(control_bodies)
		),
		"genuine old impact preserves original response bitwise"
	)
	for name in ["Slug", "Hopper", "TwinRoller"]:
		var rig := CANDIDATE.new()
		var model := CreaturePresets.load_model(name, CONFIG)
		var setup: Error = rig.setup(
			model,
			R25Fixture.floor_grid(),
			0.0,
			R25Fixture.spawn_y(model),
			R25Fixture.materials(model),
			R25Fixture.materials(model, true),
			CONFIG
		)
		_check(setup == OK, name + " original template/mass/material setup")
		rig.collect_contact_samples = true
		var trace: Dictionary = rig.step()
		_check(trace.status == OK, name + " actual isolated coupled step")
		var honest: bool = trace.status == OK
		if honest:
			honest = trace.previous_grounded_feet == 0 and trace.contact_batches.size() == 2
			for sample in trace.contact_samples:
				honest = honest and not sample.may_grip
			for axis in ["x", "y"]:
				var impulses := 0.0
				for stage in [
					"drive_internal", "damping", "gravity", "internal", "contact_velocity", "clamp"
				]:
					impulses += trace.momentum_budget[stage + "_impulse_" + axis + "_ns"]
				honest = (
					honest
					and (
						absf(impulses - trace.momentum_budget["momentum_change_" + axis + "_ns"])
						< 1e-12
					)
				)
		_check(honest, name + " frozenN0 disabled both passes, actual momentum ledger closes")
	for side in [-1.0, 1.0]:
		_boundary(side)
	_check(_checks == 22, "complete native tally before world")
	print("Impact history components: %d checks, %d failures" % [_checks, _failures])
	print("Scope: contact constitutive COMPONENTS ONLY; ZERO public world ticks; NOT acceptance")
	quit(1 if _failures else 0)


func _boundary(side: float) -> void:
	var bodies := CreaturePresets.load_model("Slug", CONFIG).create_bodies(0.0, 0.0)
	for body in bodies:
		body.a.velocity_y = -1.0
		body.b.velocity_y = -1.0
	PlanarBasis.spin(bodies[1], side)
	var joint := AngularJoint.new()
	var valid: bool = joint.setup(bodies[0], bodies[1], CONFIG) == OK
	var q: float = joint.state().q
	var network := NEW.new()
	network.limits = [
		{
			"parent": 0,
			"child": 1,
			"rest_angle": joint.rest_angle,
			"lower": q if side < 0.0 else q - 2.0,
			"upper": q if side > 0.0 else q + 2.0
		}
	]
	network.history = _states(bodies)
	var parents: Array[int] = [-1, 0, 1]
	valid = valid and network.configure(bodies, parents) == OK
	var pose := _pose(bodies)
	var e0 := _energy(bodies)
	var result: Dictionary = network.contact_velocity(bodies, 2, 1.0, 0.0, 1.0, 0.0, 0.02)
	var relative: float = PlanarBasis.frame(bodies[1]).omega - PlanarBasis.frame(bodies[0]).omega
	_check(
		valid and not result.is_empty() and side * relative <= 1e-12,
		"active boundary and original undamped contact solve together"
	)
	_check(
		_pose(bodies) == pose and _energy(bodies) <= e0,
		"active boundary remains position-neutral and strictly passive"
	)


func _one(vy: float, omega: float) -> Array[CapsuleBody]:
	var b := CreaturePresets.load_model("Slug", CONFIG).create_bodies(0.0, 0.0)[0]
	var state := b.snapshot()
	b = CapsuleBody.new()
	state.mass = 1.0
	state.length = 2.0
	state.a.x = 0.0
	state.a.y = 0.0
	state.b.x = 2.0
	state.b.y = 0.0
	state.a.inverse_mass = 2.0
	state.b.inverse_mass = 2.0
	state.a.velocity_x = 0.0
	state.b.velocity_x = 0.0
	state.a.velocity_y = vy - omega
	state.b.velocity_y = vy + omega
	if b.restore(state) != OK:
		return []
	return [b]


func _restore(states: Array) -> Array[CapsuleBody]:
	var result: Array[CapsuleBody] = []
	for state in states:
		var b := CapsuleBody.new()
		if b.restore(state) != OK:
			return []
		result.append(b)
	return result


func _states(bodies: Array[CapsuleBody]) -> Array:
	var result: Array = []
	for body in bodies:
		result.append(body.snapshot())
	return result


func _bits(bodies: Array[CapsuleBody]) -> PackedByteArray:
	return var_to_bytes(_states(bodies))


func _pose(bodies: Array[CapsuleBody]) -> PackedByteArray:
	var states := _states(bodies)
	for state in states:
		for p in [state.a, state.b]:
			p.erase("velocity_x")
			p.erase("velocity_y")
	return var_to_bytes(states)


func _energy(bodies: Array[CapsuleBody]) -> float:
	var result := 0.0
	for b in bodies:
		result += ENERGY.kinetic_energy(b)
	return result


func _check(ok: bool, label: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		push_error("FAIL " + label)
