# gdlint: disable=max-line-length
extends "res://tests/physics_fix/test_rigid_pad_components.gd"
const MANIFOLD_RIG = preload("res://tests/physics_fix/manifold_candidate.gd")
const BLOCK = preload("res://tests/physics_fix/support_manifold.gd")
const SKIN_ROW = preload("res://tests/physics_fix/capsule_surface_frame.gd")
const SERIAL = preload("res://tests/physics_fix/surface_impact_terrain.gd")


class ManifoldFault:
	extends "res://tests/physics_fix/manifold_candidate.gd"

	func _velocity_pass(
		before: Dictionary,
		hx: Array[float],
		hy: Array[float],
		reaction: Array[float],
		cleanup: Array[float],
		budget: Dictionary,
		positions: Array,
		samples: Array,
		pass_index: int,
		certificate: PackedByteArray
	) -> Dictionary:
		var result: Dictionary = super._velocity_pass(
			before, hx, hy, reaction, cleanup, budget, positions, samples, pass_index, certificate
		)
		if result.status == OK and pass_index == 0:
			bodies[0].a.velocity_x = 100.0
			return STAGE_GUARD.validate(_constitutive_origin, bodies)
		return result


func _initialize() -> void:
	var rig := PAD.new()
	_check(_setup_pad(rig, "Slug") == OK, "authorized rigid-pad model configuration")  #1
	for body in rig.bodies:
		for point in [body.a, body.b]:
			var x: float = point.x
			var y: float = point.y
			point.x = (99.0 * x - 20.0 * y) / 101.0
			point.y = (20.0 * x + 99.0 * y) / 101.0 + 0.01
	var history := _states(rig.bodies)
	var contacts: Array = []
	var geometric := true
	for part in [1, 2]:
		contacts.append(
			{
				"part": part,
				"u": 1.0,
				"nx": 0.0,
				"ny": 1.0,
				"restitution": 0.02,
				"damping": 0.9,
				"static_threshold": 0.15
			}
		)
		geometric = (
			geometric
			and rig.bodies[part].b.y - rig.bodies[part].radius <= CONFIG.physics_contact_slop_wu
		)
	_check(
		geometric, "both actual skin supports geometrically qualify, not synthetic contact loads"
	)  #2
	for body in rig.bodies:
		body.a.velocity_y = -28.0 / 60.0
		body.b.velocity_y = -28.0 / 60.0
	var raw := _states(rig.bodies)
	var old_bodies := _restore(raw)
	var old := FINAL.new()
	old.history = history.duplicate(true)
	old.limits = rig._limit_definitions()
	var valid: bool = old.configure(old_bodies, rig._parents) == OK
	var first: Dictionary = SERIAL._constrained_contact_response(
		old, old_bodies, 1, 1.0, 0.0, 1.0, 0.0, 0.02
	)
	var second: Dictionary = SERIAL._constrained_contact_response(
		old, old_bodies, 2, 1.0, 0.0, 1.0, 0.0, 0.02
	)
	var residual: float = SKIN_ROW.frame(old_bodies[1], 1.0, 0.0, 1.0).normal_velocity
	_check(
		(
			valid
			and not first.is_empty()
			and not second.is_empty()
			and first.normal_impulse_ns > 0.0
			and residual > 0.01
		),
		"old serial law leaves positive impulse AND separating speed: material complementarity defect"
	)  #3
	var kernel := FINAL.new()
	kernel.history = history.duplicate(true)
	kernel.limits = rig._limit_definitions()
	valid = kernel.configure(rig.bodies, rig._parents) == OK
	var result: Dictionary = BLOCK.solve(kernel, rig.bodies, contacts)
	_check(valid and not result.is_empty(), "direct simultaneous unilateral support solve")  #4
	var complementarity: bool = not result.is_empty()
	if complementarity:
		for j in range(2):
			var normal: float = SKIN_ROW.frame(rig.bodies[j + 1], 1.0, 0.0, 1.0).normal_velocity
			complementarity = complementarity and result.contacts[j].normal > 0.0 and normal == 0.0
	_check(complementarity, "both positive support reactions have exact zero normal speed")  #5
	_check(
		(
			PlanarBasis.frame(rig.bodies[1]).omega == 0.0
			and PlanarBasis.frame(rig.bodies[2]).omega == 0.0
		),
		"static two-support/tangent nullspace has exact zero rigid-cluster spin, not epsilon"
	)  #6
	_check(
		PlanarBasis.frame(rig.bodies[0]).omega != 0.0,
		"head angular DOF genuinely continues; no whole-creature park/sleep"
	)  #7
	_check(
		_energy(rig.bodies) < _energy(_restore(raw)),
		"strict actual physical endpoint energy dissipates"
	)  #8
	var balanced: bool = not result.is_empty()
	if balanced:
		for axis in ["x", "y"]:
			var measured := 0.0
			var force := 0.0
			for i in range(rig.bodies.size()):
				measured += (
					rig.bodies[i].mass
					* (
						(
							rig.bodies[i].a.get("velocity_" + axis)
							+ rig.bodies[i].b.get("velocity_" + axis)
						)
						- (raw[i].a["velocity_" + axis] + raw[i].b["velocity_" + axis])
					)
					/ 2.0
				)
			for event in result.contacts:
				force += -event.tangent if axis == "x" else event.normal
			balanced = balanced and absf(measured - force) < 1e-12
	_check(
		balanced,
		"all real terrain impulses and actual momentum close without pooled qualifying loads"
	)  #9
	var unchanged := true
	for i in range(rig.bodies.size()):
		for endpoint in ["a", "b"]:
			for axis in ["x", "y"]:
				unchanged = (
					unchanged and rig.bodies[i].get(endpoint).get(axis) == raw[i][endpoint][axis]
				)
	_check(unchanged, "contact block never changes pose/positions")  #10
	var single := _restore(raw)
	kernel = FINAL.new()
	kernel.history = history.duplicate(true)
	kernel.limits = rig._limit_definitions()
	valid = kernel.configure(single, rig._parents) == OK
	result = BLOCK.solve(kernel, single, [contacts[0]])
	old_bodies = _restore(raw)
	old = FINAL.new()
	old.history = history.duplicate(true)
	old.limits = rig._limit_definitions()
	valid = valid and old.configure(old_bodies, rig._parents) == OK
	first = SERIAL._constrained_contact_response(old, old_bodies, 1, 1.0, 0.0, 1.0, 0.0, 0.02)
	var difference: float = 0.0
	for i in range(single.size()):
		for endpoint in ["a", "b"]:
			for axis in ["velocity_x", "velocity_y"]:
				difference = maxf(
					difference,
					absf(single[i].get(endpoint).get(axis) - old_bodies[i].get(endpoint).get(axis))
				)
	_check(
		valid and not result.is_empty() and not first.is_empty() and difference < 1e-12,
		"one-contact physical negative boundary reproduces original skin response"
	)  #11
	single = _restore(history)
	for body in single:
		body.a.velocity_y = 0.5
		body.b.velocity_y = 0.5
	kernel = FINAL.new()
	kernel.history = history.duplicate(true)
	kernel.limits = rig._limit_definitions()
	valid = kernel.configure(single, rig._parents) == OK
	var bits: PackedByteArray = _bits(single)
	result = BLOCK.solve(kernel, single, contacts)
	_check(
		(
			valid
			and not result.is_empty()
			and result.contacts[0].normal == 0.0
			and result.contacts[1].normal == 0.0
			and bits == _bits(single)
		),
		"separating supports release with byte identity; no ground weld"
	)  #12
	var invalid: Array = contacts.duplicate(true)
	invalid[0].damping = NAN
	_check(
		BLOCK.solve(kernel, single, invalid).is_empty() and bits == _bits(single),
		"invalid material rejects atomically before touching state"
	)  #13
	for name in ["Slug", "Hopper", "TwinRoller"]:
		var combined := MANIFOLD_RIG.new()
		_check(_setup_pad(combined, name) == OK, name + " actual manifold adapter setup")
		combined.collect_contact_samples = true
		var trace: Dictionary = combined.step()
		_check(
			trace.status == OK and trace.constitutive_stage.status == OK,
			name + " complete strict manifold stage"
		)
		var honest: bool = trace.status == OK
		if honest:
			honest = trace.previous_grounded_feet == 0 and trace.contact_batches.size() == 2
			for sample in trace.contact_samples:
				honest = honest and not sample.may_grip
			for axis in ["x", "y"]:
				var impulse: float = 0.0
				for stage in [
					"drive_internal", "damping", "gravity", "internal", "contact_velocity", "clamp"
				]:
					impulse += trace.momentum_budget[stage + "_impulse_" + axis + "_ns"]
				honest = (
					honest
					and (
						absf(impulse - trace.momentum_budget["momentum_change_" + axis + "_ns"])
						< 1e-12
					)
				)
		_check(honest, name + " actual momentum and frozen previousN0 flags")
	var fault := ManifoldFault.new()
	var setup: Error = _setup_pad(fault, "Slug")
	bits = var_to_bytes(fault.snapshot())
	var rejected: Dictionary = fault.step()
	_check(
		setup == OK and rejected.status != OK,
		"injected finite gain rejected by same real strict outer guard"
	)
	_check(
		bits == var_to_bytes(fault.snapshot()),
		"entire manifold rig state atomically restored; never parked"
	)
	for side in [-1.0, 1.0]:
		_manifold_boundary(history, rig._limit_definitions(), contacts, side)
	_archived_final_frame()
	_check(_checks == 28, "complete native manifold tally")
	print("Support manifold components: %d checks, %d failures" % [_checks, _failures])
	print(
		"Scope: isolated two-support physical complementarity; ZERO public world ticks; NOT acceptance"
	)
	quit(1 if _failures else 0)


func _manifold_boundary(history: Array, limits: Array, contacts: Array, side: float) -> void:
	var bodies := _restore(history)
	var joint := AngularJoint.new()
	var valid: bool = joint.setup(bodies[0], bodies[1], CONFIG) == OK
	var bounds: Array = limits.duplicate(true)
	bounds[0].rest_angle = joint.rest_angle
	bounds[0].lower = 0.0
	var axes: Dictionary = PlanarBasis.frame(bodies[0])
	bodies[0].a.velocity_x = side * axes.y
	bodies[0].a.velocity_y = -side * axes.x
	for body in bodies:
		body.a.velocity_y -= 28.0 / 60.0
		body.b.velocity_y -= 28.0 / 60.0
	var parents: Array[int] = [-1, 0, 1]
	var kernel := FINAL.new()
	kernel.history = history.duplicate(true)
	kernel.limits = bounds
	valid = valid and kernel.configure(bodies, parents) == OK
	var response: Dictionary = BLOCK.solve(kernel, bodies, contacts)
	var omega: float = PlanarBasis.frame(bodies[0]).omega
	_check(
		valid and not response.is_empty() and (omega <= 1e-12 if side > 0.0 else omega < -0.1),
		"real lower-boundary support blocks outward but freely releases inward"
	)


func _archived_final_frame() -> void:
	var text := FileAccess.get_file_as_string(
		"res://tests/fixtures/m1_articulated_execution/28fa6de101e2/idle-Slug-failure.json"
	)
	var saved: Dictionary = JSON.parse_string(text)
	var full: Dictionary = bytes_to_var(Marshalls.base64_to_raw(saved.full_state_variant_base64))
	var raw: Array = bytes_to_var(
		Marshalls.base64_to_raw(full.awake_trace.full_work_variant_base64)
	)
	var bodies := _restore(raw)
	var history: Array = full.before.accumulator.solver.rig.physical.bodies
	var limits: Array = (
		[
			{
				"parent": 0,
				"child": 1,
				"rest_angle": full.awake_trace.work_state.angular_joints[0].rest_angle,
				"lower": full.awake_trace.work_state.angular_joints[0].lower,
				"upper": full.awake_trace.work_state.angular_joints[0].upper
			}
		]
		+ full.awake_trace.rigid_connectors
	)
	var parents: Array[int] = [-1, 0, 1]
	var kernel := FINAL.new()
	kernel.history = history.duplicate(true)
	kernel.limits = limits
	var valid: bool = (
		saved.tick == 13 and saved.status == 30 and kernel.configure(bodies, parents) == OK
	)
	var frame: Dictionary = SKIN_ROW.frame(bodies[1], 1.0, 0.0, 1.0)
	_check(
		valid and frame.normal_velocity > 0.0 and frame.tangent_velocity != 0.0,
		"archived exact failing frame requests friction with no new normal collision"
	)
	var before: float = _energy(bodies)
	var response: Dictionary = BLOCK.solve(
		kernel,
		bodies,
		[
			{
				"part": 1,
				"u": 1.0,
				"nx": 0.0,
				"ny": 1.0,
				"restitution": 0.02,
				"damping": 0.9,
				"static_threshold": 0.15
			}
		]
	)
	_check(
		(
			not response.is_empty()
			and response.contacts[0].tangent != 0.0
			and _energy(bodies) < before
		),
		"archived final physical response dissipates without a fake normal-impulse friction predicate"
	)
