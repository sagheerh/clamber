# gdlint: disable=max-line-length
extends SceneTree
## Native constitutive components ONLY. No world clock, Sim.step or historic replay.
const LEGACY = preload("res://tests/physics_fix/damped_staged_articulated_candidate.gd")
const CANDIDATE = preload("res://tests/physics_fix/assembly_damped_candidate.gd")
const DRAG = preload("res://tests/physics_fix/articulated_angular_drag.gd")
const NETWORK = preload("res://tests/physics_fix/articulated_mobility_candidate.gd")
const CONFIG = preload("res://core/tuning.tres")
var _checks := 0
var _failures := 0


func _initialize() -> void:
	var legacy := _rig("Slug")
	_check(legacy != null and legacy.bodies.size() == 3, "original preset setup")
	_rotate(legacy.bodies)
	var network := NETWORK.new()
	_check(network.configure(legacy.bodies, legacy._parents) == OK, "original constrained mobility")
	var budget := {"damping_impulse_x_ns": 0.0, "damping_impulse_y_ns": 0.0}
	_check(
		legacy._apply_authored_angular_damping(budget) == OK,
		"old independent-spin damping succeeds"
	)
	var old_projection := network.project_velocity(legacy.bodies)
	_check(
		not old_projection.is_empty(),
		"existing hinge constraints subsequently reconcile old damping"
	)
	var legacy_rate: float = PlanarBasis.frame(legacy.bodies[1]).omega
	_check(
		legacy_rate > 0.5,
		"old hinge reconciliation undoes most of the authored 80 percent spin loss"
	)
	var rig := _rig("Slug")
	_rotate(rig.bodies)
	var before := _bits(rig.bodies)
	var geometry := _geometry(rig.bodies)
	var momentum := _momentum(rig.bodies)
	var angular := _angular_momentum(rig.bodies)
	var result := DRAG.apply(rig.bodies, rig._parents, CONFIG.physics_angular_damping)
	_check(result.status == OK, "new combined articulated drag succeeds")
	var rates := true
	for body in rig.bodies:
		rates = rates and absf(PlanarBasis.frame(body).omega - 0.2) < 1e-12
	_check(rates, "authored angular fraction survives hinge compatibility; arithmetic check only")
	var after_momentum := _momentum(rig.bodies)
	_check(
		(
			absf(after_momentum[0] - momentum[0]) < 1e-12
			and absf(after_momentum[1] - momentum[1]) < 1e-12
		),
		"global COM translation momentum preserved"
	)
	var hinges := true
	for child in range(1, rig.bodies.size()):
		var p: CapsuleBody = rig.bodies[rig._parents[child]]
		var c: CapsuleBody = rig.bodies[child]
		hinges = hinges and p.b.velocity_x == c.a.velocity_x and p.b.velocity_y == c.a.velocity_y
	_check(hinges, "tree hinge velocities agree bit for bit")
	_check(
		geometry == _geometry(rig.bodies), "no positions, flags, applied load, mass or shape edit"
	)
	_check(
		result.energy_after <= result.energy_before, "strict total passivity; no energy allowance"
	)
	var force_error := 0.0
	for i in range(rig.bodies.size()):
		var x: float = (
			result.external_linear_impulse_x_ns if i == 0 else result.hinge_impulses[2 * (i - 1)]
		)
		var y: float = (
			result.external_linear_impulse_y_ns
			if i == 0
			else result.hinge_impulses[2 * (i - 1) + 1]
		)
		for c in range(i + 1, rig.bodies.size()):
			if rig._parents[c] == i:
				x -= result.hinge_impulses[2 * (c - 1)]
				y -= result.hinge_impulses[2 * (c - 1) + 1]
		force_error = maxf(force_error, absf(x - result.events[i].body_linear_impulse_x_ns))
		force_error = maxf(force_error, absf(y - result.events[i].body_linear_impulse_y_ns))
	_check(
		force_error < 1e-12,
		"every reported hinge impulse reconstructs measured body momentum change"
	)
	var torque := 0.0
	for event in result.events:
		torque += event.external_angular_impulse
	_check(
		absf(_angular_momentum(rig.bodies) - angular - torque) < 1e-12,
		"external torque ledger closes on coincident source tree"
	)
	print(
		(
			"Assembly drag diagnostic: "
			+ JSON.stringify(
				{
					"legacy_final_motor_omega": legacy_rate,
					"authored_target": 0.2,
					"new_motor_omega": PlanarBasis.frame(rig.bodies[1]).omega,
					"hinge_force_residual": force_error
				},
				"",
				true,
				true
			)
		)
	)
	for body in rig.bodies:
		for point in [body.a, body.b]:
			point.velocity_x = 0.125
			point.velocity_y = -0.25
	before = _bits(rig.bodies)
	result = DRAG.apply(rig.bodies, rig._parents, CONFIG.physics_angular_damping)
	_check(
		result.status == OK and before == _bits(rig.bodies),
		"pure global translation is exact identity, not erased"
	)
	_rotate(rig.bodies)
	before = _bits(rig.bodies)
	result = DRAG.apply(rig.bodies, rig._parents, 0.0)
	_check(result.status == OK and before == _bits(rig.bodies), "disabled damping identity")
	result = DRAG.apply(rig.bodies, rig._parents, NAN)
	_check(
		result.status != OK and before == _bits(rig.bodies), "nonfinite damping rejected atomically"
	)
	var bad_parents: Array[int] = [-1, 2, 1]
	result = DRAG.apply(rig.bodies, bad_parents, 0.8)
	_check(
		result.status != OK and before == _bits(rig.bodies), "invalid topology rejected atomically"
	)
	result = DRAG.apply(rig.bodies, rig._parents, 1.0)
	var rest: bool = result.status == OK
	for body in rig.bodies:
		rest = (
			rest
			and PlanarBasis.frame(body).omega == 0.0
			and absf(body.a.velocity_x - 0.125) < 1e-12
			and absf(body.a.velocity_y + 0.25) < 1e-12
		)
	_check(rest, "unit full damping removes angular DOFs only, leaves COM motion")
	var single: Array[CapsuleBody] = [rig.bodies[0]]
	var root: Array[int] = [-1]
	_rotate(single)
	result = DRAG.apply(single, root, 0.8)
	_check(
		result.status == OK and absf(PlanarBasis.frame(single[0]).omega - 0.2) < 1e-12,
		"single-body physical angular fraction preserved"
	)
	var templates := true
	for name in ["Hopper", "TwinRoller"]:
		var other := _rig(name)
		_rotate(other.bodies)
		result = DRAG.apply(other.bodies, other._parents, 0.8)
		templates = templates and result.status == OK
		for body in other.bodies:
			templates = templates and absf(PlanarBasis.frame(body).omega - 0.2) < 1e-12
	_check(templates, "all other original template topologies; no world ticks")
	rig = _rig("Slug")
	rig._input_mask = 1
	var driven: bool = rig._begin_tick() == OK
	result = DRAG.apply(rig.bodies, rig._parents, 0.8)
	_check(
		driven and result.status == OK and result.energy_after <= result.energy_before,
		"fresh real motor impulse plus drag is passive as a combined operator"
	)
	var composed := CANDIDATE.new()
	var model := CreaturePresets.load_model("Slug", CONFIG)
	var valid := (
		composed.setup(
			model,
			R25Fixture.floor_grid(),
			0.0,
			0.0,
			R25Fixture.materials(model),
			R25Fixture.materials(model, true),
			CONFIG
		)
		== OK
	)
	_rotate(composed.bodies)
	budget = {"damping_impulse_x_ns": 0.0, "damping_impulse_y_ns": 0.0}
	_check(
		(
			valid
			and composed._apply_authored_angular_damping(budget) == OK
			and composed._drag_hinges.size() == 4
		),
		"candidate exposes actual damping hinge impulse provenance"
	)
	before = _bits(composed.bodies)
	composed.bodies[0].mass = 0.0
	var invalid_before := _bits(composed.bodies)
	result = DRAG.apply(composed.bodies, composed._parents, 0.8)
	_check(
		result.status != OK and invalid_before == _bits(composed.bodies),
		"invalid body rejected without partial publication"
	)
	result = DRAG.apply(rig.bodies, rig._parents, 1.1)
	_check(result.status != OK, "out-of-range resource rejected, never clamped")
	const CAPTURE = preload("res://tests/physics_fix/articulated_capture_policy.gd")
	var full := {
		"status": OK,
		"tick": 3,
		"input_mask": 2,
		"momentum_budget": {"a": 1.0},
		"contact_samples": [1, 2, 3]
	}
	var full_bits := var_to_bytes(full)
	_check(
		var_to_bytes(CAPTURE.select(full, true)) == full_bits,
		"idle600 transport preserves full diagnostic trace bitwise"
	)
	var compact := CAPTURE.select(full, false)
	_check(
		(
			compact.momentum_budget == full.momentum_budget
			and compact.status == full.status
			and not compact.has("contact_samples")
			and var_to_bytes(full) == full_bits
		),
		"long geometry transport keeps budget/status without mutating full scanned trace"
	)
	print("Assembly angular drag components: %d checks, %d failures" % [_checks, _failures])
	print("Scope: constrained damping COMPONENTS ONLY; ZERO world ticks; NOT acceptance")
	quit(1 if _failures else 0)


func _rig(name: String) -> LEGACY:
	var rig := LEGACY.new()
	var model := CreaturePresets.load_model(name, CONFIG)
	var status := rig.setup(
		model,
		R25Fixture.floor_grid(),
		0.0,
		0.0,
		R25Fixture.materials(model),
		R25Fixture.materials(model, true),
		CONFIG
	)
	return rig if status == OK else null


func _rotate(bodies: Array[CapsuleBody]) -> void:
	var mass := 0.0
	var cx := 0.0
	var cy := 0.0
	for body in bodies:
		mass += body.mass
		cx += body.mass * (body.a.x + body.b.x) / 2.0
		cy += body.mass * (body.a.y + body.b.y) / 2.0
	cx /= mass
	cy /= mass
	for body in bodies:
		for point in [body.a, body.b]:
			point.velocity_x = 0.125 - (point.y - cy)
			point.velocity_y = -0.25 + (point.x - cx)


func _momentum(bodies: Array[CapsuleBody]) -> Array[float]:
	var x := 0.0
	var y := 0.0
	for body in bodies:
		x += body.mass * (body.a.velocity_x + body.b.velocity_x) / 2.0
		y += body.mass * (body.a.velocity_y + body.b.velocity_y) / 2.0
	return [x, y]


func _angular_momentum(bodies: Array[CapsuleBody]) -> float:
	var result := 0.0
	for body in bodies:
		for point in [body.a, body.b]:
			result += body.mass * (point.x * point.velocity_y - point.y * point.velocity_x) / 2.0
	return result


func _geometry(bodies: Array[CapsuleBody]) -> PackedByteArray:
	var fields: Array = []
	for body in bodies:
		fields.append(
			[
				body.a.x,
				body.a.y,
				body.b.x,
				body.b.y,
				body.mass,
				body.rest_length,
				body.applied_load_n,
				body.grounded,
				body.gripping
			]
		)
	return var_to_bytes(fields)


func _bits(bodies: Array[CapsuleBody]) -> PackedByteArray:
	var states: Array = []
	for body in bodies:
		states.append(body.snapshot())
	return var_to_bytes(states)


func _check(ok: bool, label: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		push_error("FAIL " + label)
