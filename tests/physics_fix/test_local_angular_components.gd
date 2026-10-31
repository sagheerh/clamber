# gdlint: disable=max-line-length
extends "res://tests/physics_fix/test_constitutive_stage_components.gd"
## Direct components ONLY, never public Sim/world/clock.
const LOCAL = preload("res://tests/physics_fix/local_angular_drag.gd")
const LOCAL_KERNEL = preload("res://tests/physics_fix/local_angular_constitutive_kernel.gd")
const LOCAL_RIG = preload("res://tests/physics_fix/local_angular_constitutive_candidate.gd")


func _initialize() -> void:
	var one: Array[int] = [-1]
	var bodies := _one(-1.0, -1.0)
	var bits: PackedByteArray = _bits(bodies)
	_check(
		LOCAL.apply(bodies, one, NAN).status != OK and bits == _bits(bodies),
		"invalid local resistance rejects atomically"
	)  # 1
	_check(
		LOCAL.apply(bodies, one, 0.0).status == OK and bits == _bits(bodies),
		"zero coefficient is exact original identity"
	)  # 2
	bodies = _one(-1.0, 0.0)
	bits = _bits(bodies)
	_check(
		LOCAL.apply(bodies, one, 0.8).status == OK and bits == _bits(bodies),
		"uniform translation exact identity, no linear drag invented"
	)  # 3
	bodies = _one(-1.0, -1.0)
	var origin := _states(bodies)
	var local: Dictionary = LOCAL.apply(bodies, one, 0.8)
	_check(
		local.status == OK and absf(PlanarBasis.frame(bodies[0]).omega + 0.2) < 1e-12,
		"isolated body SAME authored angular fraction"
	)  # 4
	var parents: Array[int] = [-1, 0, 1]
	bodies = CreaturePresets.load_model("Slug", CONFIG).create_bodies(0.0, 0.0)
	# Compatible mixed angular motion: only head spins, others translate with pin.
	for i in range(bodies.size()):
		var axes: Dictionary = PlanarBasis.frame(bodies[i])
		var w: float = 1.0 if i == 0 else 0.0
		bodies[i].a.velocity_x = 0.0 if i == 0 else bodies[parents[i]].b.velocity_x
		bodies[i].a.velocity_y = 0.0 if i == 0 else bodies[parents[i]].b.velocity_y
		bodies[i].b.velocity_x = bodies[i].a.velocity_x - w * axes.y
		bodies[i].b.velocity_y = bodies[i].a.velocity_y + w * axes.x
	origin = _states(bodies)
	var old_bodies := _restore(origin)
	local = LOCAL.apply(bodies, parents, 0.8)
	_check(
		local.status == OK and GUARD.validate(origin, bodies).status == OK,
		"local constrained angular resolvent is physically passive"
	)  # 5
	_check(
		(
			absf(local.external_linear_impulse_x_ns) < 1e-12
			and absf(local.external_linear_impulse_y_ns) < 1e-12
		),
		"local drag never invents global linear force"
	)  # 6
	var law: bool = true
	for i in range(bodies.size()):
		var axes: Dictionary = PlanarBasis.frame(bodies[i])
		law = (
			law
			and (
				absf(
					(
						local.events[i].external_angular_impulse
						+ 4.0 * axes.omega / axes.inverse_inertia
					)
				)
				< 1e-12
			)
		)
	_check(law, "EACH actual per-body drag torque equals -C_i omega_i, not all-shape resistance")  # 7
	var kernel := LOCAL_KERNEL.new()
	kernel.history = origin.duplicate(true)
	_check(
		(
			kernel.configure(bodies, parents) == OK
			and not kernel.mobility([0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]).is_empty()
		),
		"modified angular Jacobian / original physical mass validates"
	)  # 8
	bodies = _one(-1.0, -1.0)
	origin = _states(bodies)
	local = LOCAL.apply(bodies, one, 0.8)
	kernel = LOCAL_KERNEL.new()
	kernel.history = origin.duplicate(true)
	var valid: bool = kernel.configure(bodies, one) == OK
	var result: Dictionary = kernel.contact_velocity(bodies, 0, 0.0, 0.0, 1.0, 1.0, 0.02)
	_check(
		valid and not result.is_empty() and GUARD.validate(origin, bodies).status == OK,
		"complete local angular/support scalar remains strictly passive"
	)  # 9
	var axes: Dictionary = PlanarBasis.frame(bodies[0])
	_check(
		(
			absf(
				(
					local.events[0].external_angular_impulse
					+ result.angular_drag_events[0].angular_impulse
					+ 4.0 * axes.omega / axes.inverse_inertia
				)
			)
			< 1e-12
		),
		"contact feedback closes SAME actual local constitutive torque law"
	)  # 10
	var shape: Dictionary = DRAG.apply(old_bodies, parents, 0.8)
	var nonlocal_gap: float = 0.0
	for i in range(old_bodies.size()):
		var old_axes: Dictionary = PlanarBasis.frame(old_bodies[i])
		nonlocal_gap = maxf(
			nonlocal_gap,
			absf(
				(
					shape.events[i].external_angular_impulse
					+ 4.0 * old_axes.omega / old_axes.inverse_inertia
				)
			)
		)
	_check(
		shape.status == OK and nonlocal_gap > 1e-6,
		"old global shape operator is NOT a local per-body angular material law"
	)  # 11
	bodies = _one(1.0, 0.0)
	origin = _states(bodies)
	bodies[0].a.velocity_y = 1.0000000000000002
	bodies[0].b.velocity_y = 1.0000000000000002
	_check(
		GUARD.validate(origin, bodies).status != OK,
		"strict positive ULP rejection still applies to new physical stage"
	)  # 12
	for name in ["Slug", "Hopper", "TwinRoller"]:
		var rig := LOCAL_RIG.new()
		var setup: Error = _setup(rig, name)
		_check(setup == OK, name + " unchanged model/material/spawn")
		rig.collect_contact_samples = true
		var trace: Dictionary = rig.step()
		_check(
			trace.status == OK and trace.constitutive_stage.status == OK,
			name + " local complete stage physical guard"
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
		_check(honest, name + " frozen N0 both passes, real momentum ledger")
	for side in [-1.0, 1.0]:
		_local_boundary(side)
	_check(_checks == 25, "complete local constitutive native tally")
	print("Local angular components: %d checks, %d failures" % [_checks, _failures])
	print(
		"Scope: isolated LOCAL constitutive components only; ZERO public world ticks, NOT acceptance"
	)
	quit(1 if _failures else 0)


func _local_boundary(side: float) -> void:
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
	var kernel := LOCAL_KERNEL.new()
	kernel.history = origin.duplicate(true)
	kernel.limits = limits
	valid = valid and local.status == OK and kernel.configure(bodies, parents) == OK
	var result: Dictionary = kernel.contact_velocity(bodies, 2, 1.0, 0.0, 1.0, 0.0, 0.02)
	var relative: float = PlanarBasis.frame(bodies[1]).omega - PlanarBasis.frame(bodies[0]).omega
	_check(
		valid and not result.is_empty() and side * relative <= 1e-12,
		"local angular/contact boundary holds"
	)
	_check(
		GUARD.validate(origin, bodies).status == OK,
		"local boundary actual energy and exact geometry remain valid"
	)
