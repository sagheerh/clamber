# gdlint: disable=max-line-length
extends "res://tests/physics_fix/test_local_angular_components.gd"
## Authorized stance/structural connectors, isolated units only, ZERO public clock.
const MODELS = preload("res://tests/physics_fix/rigid_pad_models.gd")
const PAD = preload("res://tests/physics_fix/rigid_pad_candidate.gd")
const FINAL = preload("res://tests/physics_fix/surface_impact_kernel.gd")
const PHYSICAL = preload("res://tests/physics_fix/limited_articulated_mobility_candidate.gd")


func _initialize() -> void:
	var model := MODELS.load_model("Slug", CONFIG)
	var original := CreaturePresets.load_model("Slug", CONFIG)
	_check(
		(
			model != null
			and model.definition().parts[0].axis == "DOWN"
			and model.definition().parts[2].axis == "LEFT"
		),
		"explicit new root/pad stance, not historical capture"
	)  #1
	_check(
		(
			original.definition().parts[0].axis == "RIGHT"
			and original.definition().parts[2].axis == "DOWN"
		),
		"historical preset file untouched"
	)  #2
	var rig := PAD.new()
	var valid: bool = _setup_pad(rig, "Slug") == OK
	var old_bodies := original.create_bodies(0.0, 0.0)
	for i in range(rig.bodies.size()):
		valid = (
			valid
			and rig.bodies[i].mass == old_bodies[i].mass
			and rig.bodies[i].radius == old_bodies[i].radius
			and rig.bodies[i].rest_length == old_bodies[i].rest_length
		)
	_check(valid, "physical masses/inertia formula/radii/lengths/materials unchanged")  #3
	var kernel := FINAL.new()
	kernel.limits = rig._limit_definitions()
	kernel.history = _states(rig.bodies)
	valid = kernel.configure(rig.bodies, rig._parents) == OK
	_check(
		valid and kernel._hinges.size() == 5,
		"four pin rows plus ONE bilateral physical connector row"
	)  #4
	var external: Array[float] = kernel._zero(9)
	external[8] = 1.0
	var response: Dictionary = kernel.mobility(external)
	_check(
		not response.is_empty() and absf(response.delta[5] - response.delta[8]) < 1e-12,
		"real foot/leg angular compatibility in effective contact mobility"
	)  #5
	external.fill(0.0)
	external[2] = 1.0
	response = kernel.mobility(external)
	_check(
		not response.is_empty() and response.delta[2] != 0.0,
		"root stays genuinely free, no world upright/weld"
	)  #6
	var angular: float = 0.0
	for i in range(rig.bodies.size()):
		var body: CapsuleBody = rig.bodies[i]
		var axes: Dictionary = PlanarBasis.frame(body)
		angular += (
			response.delta[3 * i + 2] / axes.inverse_inertia
			+ (
				body.mass
				* (
					(body.a.x + body.b.x) * response.delta[3 * i + 1]
					- (body.a.y + body.b.y) * response.delta[3 * i]
				)
				/ 2.0
			)
		)
	_check(
		absf(angular - 1.0) < 1e-12,
		"connector torques internal; actual total angular impulse equals external root impulse"
	)  #7
	var bad := FINAL.new()
	bad.limits = rig._limit_definitions()
	bad.limits[-1].rigid_connector_quarters = 7
	bad.history = _states(rig.bodies)
	var bits: PackedByteArray = _bits(rig.bodies)
	_check(
		bad.configure(rig.bodies, rig._parents) != OK and bits == _bits(rig.bodies),
		"invalid connector descriptor rejected without mutation"
	)  #8
	var foot: CapsuleBody = rig.bodies[2]
	var center_x: float = 0.0
	var mass: float = 0.0
	for body in rig.bodies:
		center_x += body.mass * (body.a.x + body.b.x) / 2.0
		mass += body.mass
	_check(
		foot.a.y == foot.b.y and center_x / mass > foot.b.x and center_x / mass < foot.a.x,
		"new real horizontal capsule baseline contains actual spawn COM"
	)  #9
	var free := PHYSICAL.new()
	valid = free.configure(rig.bodies, rig._parents) == OK
	external.fill(0.0)
	external[8] = 1.0
	response = free.mobility(external)
	_check(
		valid and not response.is_empty() and absf(response.delta[5] - response.delta[8]) > 1.0,
		"old free foot negative control really permits relative spin"
	)  #10
	PlanarBasis.turn(foot, 0.01)
	var position := PHYSICAL.new()
	position.limits = rig._limit_definitions()
	valid = position.configure(rig.bodies, rig._parents) == OK
	var repaired: Dictionary = position.project_hinge_positions(rig.bodies, rig._parents, CONFIG)
	var p: Dictionary = PlanarBasis.frame(rig.bodies[1])
	var f: Dictionary = PlanarBasis.frame(foot)
	_check(
		(
			valid
			and not repaired.is_empty()
			and absf(p.x * f.x + p.y * f.y) < 1e-12
			and p.x * f.y - p.y * f.x < 0.0
		),
		"finite coordinate publication enforces authored right-angle connector, not post-contact repair"
	)  #11
	for name in ["Slug", "Hopper", "TwinRoller"]:
		rig = PAD.new()
		_check(
			_setup_pad(rig, name) == OK,
			name + " explicit stance + ordinary rigid attachments configured"
		)
		var snapshot: Dictionary = rig.snapshot()
		_check(
			rig.restore(snapshot) == OK and var_to_bytes(snapshot) == var_to_bytes(rig.snapshot()),
			name + " physical snapshot/restore byte identity"
		)
		rig.collect_contact_samples = true
		var trace: Dictionary = rig.step()
		_check(
			trace.status == OK and trace.constitutive_stage.status == OK,
			name + " isolated complete physical stage"
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
		_check(honest, name + " actual momentum and frozen previousN0 eligibility")
	_check(_checks == 23, "complete rigid-pad components tally")
	print("Rigid pad components: %d checks, %d failures" % [_checks, _failures])
	print(
		"Scope: authorized NEW stance/rigid connector components; ZERO public world ticks; NOT acceptance"
	)
	quit(1 if _failures else 0)


func _setup_pad(rig: RefCounted, name: String) -> Error:
	var model := MODELS.load_model(name, CONFIG)
	if model == null:
		return ERR_INVALID_DATA
	return rig.setup(
		model,
		_grid(),
		0.0,
		R25Fixture.spawn_y(model),
		R25Fixture.materials(model),
		R25Fixture.materials(model, true),
		CONFIG
	)
