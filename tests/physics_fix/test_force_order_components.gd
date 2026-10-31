# gdlint: disable=max-line-length
extends SceneTree
const CANDIDATE = preload("res://tests/physics_fix/force_order_candidate.gd")
const OLD = preload("res://tests/physics_fix/preintegrated_articulated_candidate.gd")
const CONFIG = preload("res://core/tuning.tres")
var _checks := 0
var _failures := 0


func _initialize() -> void:
	var expected := [
		"angular_damping", "linear_damping", "drive", "gravity", "velocity_pass_0", "integration"
	]
	for i in range(6):
		expected.append("position_sweep_%d" % i)
	expected.append("velocity_pass_1")
	for name in ["Slug", "Hopper", "TwinRoller"]:
		var rig := _rig(name)
		_check(rig != null, name + " original setup")
		if rig == null:
			continue
		var result: Dictionary = rig.step()
		_check(
			(
				result.status == OK
				and result.stage_order == expected
				and result.drive_events.size() == rig._joints.size()
			),
			name + " real force order; controller runs once; two/six unchanged"
		)
		var valid: bool = result.status == OK
		if valid:
			for axis in ["x", "y"]:
				var impulses := 0.0
				for stage in [
					"drive_internal", "damping", "gravity", "internal", "contact_velocity", "clamp"
				]:
					impulses += result.momentum_budget[stage + "_impulse_" + axis + "_ns"]
				valid = (
					valid
					and (
						absf(impulses - result.momentum_budget["momentum_change_" + axis + "_ns"])
						< 1e-12
					)
				)
			for body in rig.bodies:
				var dx: float = body.b.x - body.a.x
				var dy: float = body.b.y - body.a.y
				valid = valid and absf(sqrt(dx * dx + dy * dy) - body.rest_length) < 1e-12
		_check(valid, name + " actual force ledger and unchanged lengths")
	var fresh := _rig("Slug")
	fresh._input_mask = 1
	var before := var_to_bytes(fresh.snapshot())
	_check(
		fresh._begin_tick() == OK and before == var_to_bytes(fresh.snapshot()),
		"deferred door does not apply a motor impulse before damping"
	)
	var status: Error = fresh._apply_forces(1.0 / CONFIG.physics_tick_hz, _budget())
	var event: Dictionary = fresh._drive_events[0]
	var expected_omega: float = event.child_omega + event.impulse * event.child_inverse_inertia
	var actual: float = PlanarBasis.frame(fresh.bodies[1]).omega
	_check(
		status == OK and absf(actual - expected_omega) < 1e-12 and event.impulse != 0.0,
		"full actual fresh motor impulse survives authored angular loss; arithmetic check only"
	)
	var quiet := true
	for loss in fresh.angular_damping_events:
		quiet = (
			quiet
			and loss.omega_before == 0.0
			and loss.energy_before == 0.0
			and loss.energy_after == 0.0
		)
	_check(quiet, "damping saw only original zero motion, not the newly applied motor")
	var old := OLD.new()
	var model := CreaturePresets.load_model("Slug", CONFIG)
	var old_setup: Error = old.setup(
		model,
		R25Fixture.floor_grid(),
		0.0,
		R25Fixture.spawn_y(model),
		R25Fixture.materials(model),
		R25Fixture.materials(model, true),
		CONFIG
	)
	old._input_mask = 1
	var old_ready: bool = (
		old_setup == OK
		and old._begin_tick() == OK
		and old._apply_forces(1.0 / CONFIG.physics_tick_hz, _budget()) == OK
	)
	var old_omega: float = PlanarBasis.frame(old.bodies[1]).omega
	_check(
		old_ready and absf(actual) > absf(old_omega),
		"old force-through-loss counterfactual is observably attenuated"
	)
	_check(
		fresh._force_certificate.is_empty(),
		"a real new motor impulse invalidates the old canonical witness"
	)
	print("Force-order components: %d checks, %d failures" % [_checks, _failures])
	print(
		(
			"Force-order diagnostic: "
			+ JSON.stringify(
				{
					"new_motor_omega": actual,
					"old_motor_omega": old_omega,
					"requested_full_omega": expected_omega
				},
				"",
				true,
				true
			)
		)
	)
	print("Scope: force COMPONENTS ONLY; ZERO public world ticks; NOT acceptance")
	quit(1 if _failures else 0)


func _rig(name: String) -> CANDIDATE:
	var model := CreaturePresets.load_model(name, CONFIG)
	var rig := CANDIDATE.new()
	var status: Error = rig.setup(
		model,
		R25Fixture.floor_grid(),
		0.0,
		R25Fixture.spawn_y(model),
		R25Fixture.materials(model),
		R25Fixture.materials(model, true),
		CONFIG
	)
	return rig if status == OK else null


func _budget() -> Dictionary:
	return {
		"drive_internal_impulse_x_ns": 0.0,
		"drive_internal_impulse_y_ns": 0.0,
		"damping_impulse_x_ns": 0.0,
		"damping_impulse_y_ns": 0.0,
		"gravity_impulse_x_ns": 0.0,
		"gravity_impulse_y_ns": 0.0,
		"clamp_impulse_x_ns": 0.0,
		"clamp_impulse_y_ns": 0.0
	}


func _check(ok: bool, label: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		push_error("FAIL " + label)
