# gdlint: disable=max-line-length
extends "res://tests/physics_fix/test_damped_support_components.gd"
## Components only. Private constitutive trials are never Sim/world states.
const DRAG = preload("res://tests/physics_fix/articulated_angular_drag.gd")
const TRIAL = preload("res://tests/physics_fix/constitutive_trial_kernel.gd")
const GUARD = preload("res://tests/physics_fix/constitutive_stage_guard.gd")
const RIG = preload("res://tests/physics_fix/constitutive_stage_candidate.gd")


class FaultRig:
	extends "res://tests/physics_fix/constitutive_stage_candidate.gd"

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
			# LABELLED fault only: exercise real outer atomic restore, no world run.
			bodies[0].a.velocity_x = 100.0
			return STAGE_GUARD.validate(_constitutive_origin, bodies)
		return result


func _initialize() -> void:
	var one: Array[int] = [-1]
	var bodies := _one(-1.0, -1.0)
	_check(bodies.size() == 1, "raw unit rod physical source")  # 1
	var origin := _states(bodies)
	var drag: Dictionary = DRAG.apply(bodies, one, 0.8)
	_check(drag.status == OK, "original authored angular drag on detached trial")  # 2
	var kernel := TRIAL.new()
	kernel.history = origin.duplicate(true)
	var valid: bool = kernel.configure(bodies, one) == OK
	var result: Dictionary = kernel.contact_velocity(bodies, 0, 0.0, 0.0, 1.0, 1.0, 0.02)
	var report: Dictionary = GUARD.validate(origin, bodies)
	_check(
		valid and not result.is_empty() and report.status == OK,
		"complete physical scalar operator remains strictly passive"
	)  # 3
	_check(
		(
			absf(PlanarBasis.frame(bodies[0]).omega + 1.0 / 3.0) < 1e-12
			and report.after <= report.before
		),
		"same coupled analytic rod, not split spin regeneration"
	)  # 4
	var inclined: Dictionary = origin[0].duplicate(true)
	inclined.length = sqrt(8.0)
	for key in ["a", "b"]:
		var sign_value: float = -1.0 if key == "a" else 1.0
		inclined[key].x = sign_value
		inclined[key].y = sign_value
		inclined[key].previous_x = sign_value
		inclined[key].previous_y = sign_value
		inclined[key].velocity_x = -1.5 - 10.0 * sign_value
		inclined[key].velocity_y = 3.0 + 10.0 * sign_value
	bodies = _restore([inclined])
	origin = _states(bodies)
	drag = DRAG.apply(bodies, one, 0.8)
	_check(drag.status == OK, "inclined rod complete raw origin, not fake scalar budget")  # 5
	var intermediate := _states(bodies)
	var e0: float = _energy(bodies)
	kernel = TRIAL.new()
	kernel.history = origin.duplicate(true)
	valid = kernel.configure(bodies, one) == OK
	result = kernel.contact_velocity(bodies, 0, 0.0, 0.0, 1.0, 0.0, 0.0)
	_check(
		valid and not result.is_empty() and _energy(bodies) > e0,
		"positive internal derivative is explicitly NOT independently physical"
	)  # 6
	report = GUARD.validate(origin, bodies)
	_check(
		report.status == OK and report.after < report.before,
		"complete implicit constitutive operator dissipates actual energy"
	)  # 7
	_check(
		GUARD.validate(intermediate, bodies).status != OK,
		"V12 positive physical increment still rejected, no energy allowance"
	)  # 8
	var old_bodies := _restore(intermediate)
	var old := NEW.new()
	old.history = origin.duplicate(true)
	valid = old.configure(old_bodies, one) == OK
	_check(
		valid and old.contact_velocity(old_bodies, 0, 0.0, 0.0, 1.0, 0.0, 0.0).is_empty(),
		"original V12 publisher untouched and strict"
	)  # 9
	_check(GUARD.validate([], bodies).status != OK, "missing complete origin fails closed")  # 10
	bodies = _one(1.0, 0.0)
	origin = _states(bodies)
	bodies[0].a.velocity_y = 1.0000000000000002
	bodies[0].b.velocity_y = 1.0000000000000002
	_check(
		GUARD.validate(origin, bodies).status != OK,
		"one ULP positive physical energy STILL rejected"
	)  # 11
	bodies = _restore(origin)
	bodies[0].a.x += 0.01
	_check(
		GUARD.validate(origin, bodies).status != OK,
		"geometry edits cannot masquerade as constitutive dissipation"
	)  # 12
	bodies = _restore(origin)
	bodies[0].a.velocity_x = NAN
	_check(GUARD.validate(origin, bodies).status != OK, "nonfinite final state fails closed")  # 13
	bodies = _restore(origin)
	_check(GUARD.validate(origin, bodies).status == OK, "exact identity remains legal")  # 14
	for name in ["Slug", "Hopper", "TwinRoller"]:
		var rig := RIG.new()
		var setup: Error = _setup(rig, name)
		_check(setup == OK, name + " original model/material/spawn")
		rig.collect_contact_samples = true
		var trace: Dictionary = rig.step()
		_check(
			trace.status == OK and trace.constitutive_stage.status == OK,
			name + " actual complete physical operator/strict endpoint guard"
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
		_check(honest, name + " previousN0 disables both grip passes and actual momentum closes")
	var fault := FaultRig.new()
	var setup: Error = _setup(fault, "Slug")
	var bits: PackedByteArray = var_to_bytes(fault.snapshot())
	var failed: Dictionary = fault.step()
	_check(
		setup == OK and failed.status != OK,
		"injected finite physical gain rejected before tick commitment"
	)  # 24
	_check(
		bits == var_to_bytes(fault.snapshot()),
		"entire real creature state restored atomically, not parked"
	)  # 25
	for side in [-1.0, 1.0]:
		_complete_boundary(side)
	_check(_checks == 29, "complete constitutive native tally before public world")
	print("Constitutive stage components: %d checks, %d failures" % [_checks, _failures])
	print(
		"Scope: complete physical COMPONENT operator only, ZERO public world ticks; not acceptance"
	)
	quit(1 if _failures else 0)


func _setup(rig: RefCounted, name: String) -> Error:
	var model := CreaturePresets.load_model(name, CONFIG)
	return rig.setup(
		model,
		R25Fixture.floor_grid(),
		0.0,
		R25Fixture.spawn_y(model),
		R25Fixture.materials(model),
		R25Fixture.materials(model, true),
		CONFIG
	)


func _complete_boundary(side: float) -> void:
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
	var drag: Dictionary = DRAG.apply(bodies, parents, 0.8)
	var kernel := TRIAL.new()
	kernel.history = origin.duplicate(true)
	kernel.limits = [
		{
			"parent": 0,
			"child": 1,
			"rest_angle": joint.rest_angle,
			"lower": q if side < 0.0 else q - 2.0,
			"upper": q if side > 0.0 else q + 2.0
		}
	]
	valid = valid and drag.status == OK and kernel.configure(bodies, parents) == OK
	var result: Dictionary = kernel.contact_velocity(bodies, 2, 1.0, 0.0, 1.0, 0.0, 0.02)
	var relative: float = PlanarBasis.frame(bodies[1]).omega - PlanarBasis.frame(bodies[0]).omega
	_check(
		valid and not result.is_empty() and side * relative <= 1e-12,
		"complete constitutive contact and actual angular boundary solve together"
	)
	_check(
		GUARD.validate(origin, bodies).status == OK,
		"boundary keeps exact geometry and complete actual energy passivity"
	)
