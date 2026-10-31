# gdlint: disable=max-line-length
extends "res://tests/physics_fix/test_local_angular_components.gd"
## Isolated physical skin-contact components; NO Sim/world ticks.
const SURFACE = preload("res://tests/physics_fix/capsule_surface_frame.gd")
const SKIN = preload("res://tests/physics_fix/surface_constitutive_kernel.gd")
const SKIN_FINAL = preload("res://tests/physics_fix/surface_impact_kernel.gd")
const SKIN_TERRAIN = preload("res://tests/physics_fix/surface_impact_terrain.gd")
const SKIN_RIG = preload("res://tests/physics_fix/surface_constitutive_candidate.gd")
const CENTERLINE = preload("res://tests/physics_fix/impact_history_terrain.gd")


func _initialize() -> void:
	var one: Array[int] = [-1]
	var bodies := _one(0.0, 1.0)
	var value: Dictionary = SURFACE.frame(bodies[0], 0.5, 0.0, 1.0)
	var old_frame: Dictionary = ENERGY.frame(bodies[0], 0.5, 0.0, 1.0)
	_check(
		value.ry == -bodies[0].radius and value.rx == 0.0,
		"capsule skin arm uses SAME actual collision radius"
	)  #1
	_check(
		value.knn == old_frame.knn and value.normal_velocity == old_frame.normal_velocity,
		"radius has zero normal moment; normal geometry unchanged"
	)  #2
	var rows: Dictionary = SURFACE.rows(bodies, 0, 0.5, 0.0, 1.0)
	_check(
		rows.tangent[2] == -bodies[0].radius and rows.normal[2] == 0.0,
		"physical tangent impulse has radius moment, not centreline moment"
	)  #3
	_check(
		old_frame.tangent_velocity == 0.0 and value.tangent_velocity == -bodies[0].radius,
		"old centreline misses real pure-spin surface slip"
	)  #4
	var origin := _states(bodies)
	var kernel := SKIN_FINAL.new()
	kernel.history = origin.duplicate(true)
	var valid: bool = kernel.configure(bodies, one) == OK
	var e0: float = _energy(bodies)
	var result: Dictionary = kernel.contact_velocity(bodies, 0, 0.5, 0.0, 1.0, 0.0, 0.0)
	_check(
		(
			valid
			and not result.is_empty()
			and result.tangential_impulse_ns > 0.0
			and _energy(bodies) < e0
			and PlanarBasis.frame(bodies[0]).omega < 1.0
		),
		"strict physical skin friction slows actual slip/spin and dissipates"
	)  #5
	bodies = _one(0.0, 1.0)
	bodies[0].a.velocity_x = -bodies[0].radius
	bodies[0].b.velocity_x = -bodies[0].radius
	origin = _states(bodies)
	var bits: PackedByteArray = _bits(bodies)
	kernel = SKIN_FINAL.new()
	kernel.history = origin.duplicate(true)
	valid = kernel.configure(bodies, one) == OK
	result = SKIN_TERRAIN._constrained_contact_response(kernel, bodies, 0, 0.5, 0.0, 1.0, 0.0, 0.0)
	_check(
		(
			valid
			and not result.is_empty()
			and result.tangential_impulse_ns == 0.0
			and bits == _bits(bodies)
		),
		"exact no-slip rolling is physical zero-response identity"
	)  #6
	var old_bodies := _restore(origin)
	var old := preload("res://tests/physics_fix/impact_history_mobility.gd").new()
	old.history = origin.duplicate(true)
	valid = old.configure(old_bodies, one) == OK
	result = CENTERLINE._constrained_contact_response(old, old_bodies, 0, 0.5, 0.0, 1.0, 0.0, 0.0)
	_check(
		valid and not result.is_empty() and result.tangential_impulse_ns != 0.0,
		"old centreline law brakes a truly no-slip roll; located defect"
	)  #7
	bodies = _one(0.0, 1.0)
	origin = _states(bodies)
	var drag: Dictionary = LOCAL.apply(bodies, one, 0.8)
	var coupled := SKIN.new()
	coupled.history = origin.duplicate(true)
	valid = drag.status == OK and coupled.configure(bodies, one) == OK
	result = coupled.contact_velocity(bodies, 0, 0.5, 0.0, 1.0, 0.0, 0.0)
	_check(
		valid and not result.is_empty() and GUARD.validate(origin, bodies).status == OK,
		"complete local angular+skin contact obeys strict actual energy"
	)  #8
	var axes: Dictionary = PlanarBasis.frame(bodies[0])
	_check(
		(
			absf(
				(
					drag.events[0].external_angular_impulse
					+ result.angular_drag_events[0].angular_impulse
					+ 4.0 * axes.omega / axes.inverse_inertia
				)
			)
			< 1e-12
		),
		"skin torque includes -radius*Jt; measured local torque ledger closes"
	)  #9
	_check(
		(
			SURFACE.frame(bodies[0], NAN, 0.0, 1.0).is_empty()
			and SURFACE.frame(bodies[0], 0.5, 0.0, 0.0).is_empty()
		),
		"invalid contact geometry is never published"
	)  #10
	for name in ["Slug", "Hopper", "TwinRoller"]:
		var rig := SKIN_RIG.new()
		var setup: Error = _setup(rig, name)
		_check(setup == OK, name + " original shape/radius/mass/material/spawn")
		rig.collect_contact_samples = true
		var trace: Dictionary = rig.step()
		_check(
			trace.status == OK and trace.constitutive_stage.status == OK,
			name + " complete skin constitutive stage"
		)
		var honest: bool = trace.status == OK
		if honest:
			honest = trace.previous_grounded_feet == 0 and trace.contact_batches.size() == 2
			for sample in trace.contact_samples:
				honest = honest and not sample.may_grip
			for axis in ["x", "y"]:
				var impulses: float = 0.0
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
		_check(honest, name + " frozen previousN0 eligibility/real momentum unchanged")
	for side in [-1.0, 1.0]:
		_skin_boundary(side)
	_check(_checks == 23, "complete skin contact native tally")
	print("Capsule surface components: %d checks, %d failures" % [_checks, _failures])
	print("Scope: isolated actual skin-contact components, ZERO public world ticks; NOT acceptance")
	quit(1 if _failures else 0)


func _skin_boundary(side: float) -> void:
	var bodies := CreaturePresets.load_model("Slug", CONFIG).create_bodies(0.0, 0.0)
	for body in bodies:
		body.a.velocity_y = -1.0
		body.b.velocity_y = -1.0
	PlanarBasis.spin(bodies[1], side)
	var joint := AngularJoint.new()
	var valid: bool = joint.setup(bodies[0], bodies[1], CONFIG) == OK
	var q: float = joint.state().q
	var origin := _states(bodies)
	var parents: Array[int] = [-1, 0, 1]
	var limits: Array = [
		{
			"parent": 0,
			"child": 1,
			"rest_angle": joint.rest_angle,
			"lower": q if side < 0.0 else q - 2.0,
			"upper": q if side > 0.0 else q + 2.0
		}
	]
	var local: Dictionary = LOCAL.apply(bodies, parents, 0.8, limits)
	var kernel := SKIN.new()
	kernel.history = origin.duplicate(true)
	kernel.limits = limits
	valid = valid and local.status == OK and kernel.configure(bodies, parents) == OK
	var result: Dictionary = kernel.contact_velocity(bodies, 2, 1.0, 0.0, 1.0, 0.0, 0.02)
	var relative: float = PlanarBasis.frame(bodies[1]).omega - PlanarBasis.frame(bodies[0]).omega
	_check(
		valid and not result.is_empty() and side * relative <= 1e-12,
		"skin tangent/normal response respects real angular boundary"
	)
	_check(
		GUARD.validate(origin, bodies).status == OK,
		"skin boundary preserves geometry and complete actual energy"
	)
