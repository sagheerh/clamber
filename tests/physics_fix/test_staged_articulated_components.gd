# gdlint: disable=max-line-length
extends SceneTree
## Saved-state COMPONENT controls; no clock, Sim.step, world replay or acceptance.
const CANDIDATE = preload("res://tests/physics_fix/damped_staged_articulated_candidate.gd")
const TUNING = preload("res://core/tuning.tres")
const ARCHIVE := "res://tests/fixtures/m1_articulated_execution/f7b8fd24d6b8/idle-Slug-failure.json"
var _checks := 0
var _failures := 0


func _initialize() -> void:
	var archived: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ARCHIVE))
	var decoded: Dictionary = bytes_to_var(
		Marshalls.base64_to_raw(archived.full_state_variant_base64)
	)
	var work: Dictionary = decoded.awake_trace.work_state
	var rig := CANDIDATE.new()
	var model := CreaturePresets.load_model("Slug", TUNING)
	_check(
		(
			rig.setup(
				model,
				R25Fixture.floor_grid(),
				0.0,
				0.0,
				R25Fixture.materials(model),
				R25Fixture.materials(model, true),
				TUNING
			)
			== OK
		),
		"construct component"
	)
	_check(rig.restore(work) == OK, "restore exact binary64 saved failure, no advance")
	_check(rig._pairs.is_empty(), "archived Slug has no enabled self-pair")
	var q: Dictionary = rig._joints[0].state()
	_check(
		q.q > rig._joints[0].lower and q.q < rig._joints[0].upper,
		"saved geometry is strictly inside angular limits"
	)
	var before := var_to_bytes(rig.snapshot())
	var key: PackedByteArray = rig._hinge_velocity_key()
	_check(rig._extra_velocities() == OK, "original angular/self-contact stage succeeds")
	_check(
		before == var_to_bytes(rig.snapshot()),
		"extra rows are bitwise identity at failing geometry"
	)
	_check(key == rig._hinge_velocity_key(), "no velocity/geometry dependency changed")
	var x: Array[float] = [0.0, 0.0, 0.0]
	var y: Array[float] = [0.0, 0.0, 0.0]
	var cold := PackedByteArray()
	_check(
		rig._project_changed_velocity(cold, x, y) == ERR_INVALID_DATA,
		"uncertified saved frame still hits strict unchanged energy guard"
	)
	_check(before == var_to_bytes(rig.snapshot()), "cold rejection remains atomic")
	_check(
		rig._project_changed_velocity(key, x, y) == OK,
		"certified exact identity does not republish roundoff"
	)
	_check(
		before == var_to_bytes(rig.snapshot()) and x == [0.0, 0.0, 0.0] and y == [0.0, 0.0, 0.0],
		"identity preserves all motion and adds no impulses"
	)
	var bits := PackedFloat64Array([rig.bodies[0].a.velocity_x]).to_byte_array()
	bits[0] = bits[0] ^ 1
	rig.bodies[0].a.velocity_x = bits.to_float64_array()[0]
	_check(
		key != rig._hinge_velocity_key(),
		"one-bit velocity mutation invalidates certificate exactly"
	)
	_check(rig.restore(work) == OK, "restore test control")
	rig.bodies[0].a.x += 0.01
	_check(key != rig._hinge_velocity_key(), "geometry mutation invalidates certificate exactly")
	rig.bodies[0].mass = 0.0
	_check(
		rig._project_changed_velocity(key, x, y) == ERR_INVALID_DATA,
		"invalid mass never bypasses validation"
	)

	_check(rig.restore(work) == OK, "restore before prescribed damping control")
	var original: Dictionary = rig.snapshot()
	var budget := {"damping_impulse_x_ns": 0.0, "damping_impulse_y_ns": 0.0}
	_check(
		rig._apply_authored_angular_damping(budget) == OK,
		"existing angular resource applied without advancing clock"
	)
	var physics_ok := rig._ticks == 14
	var energy_ok := true
	for i in range(rig.bodies.size()):
		var b := rig.bodies[i]
		var old: Dictionary = original.bodies[i]
		var event: Dictionary = rig.angular_damping_events[i]
		physics_ok = (
			physics_ok
			and (
				absf(
					event.omega_after - event.omega_before * (1.0 - TUNING.physics_angular_damping)
				)
				<= 1e-12
			)
		)
		for axis in ["velocity_x", "velocity_y"]:
			physics_ok = (
				physics_ok
				and absf((b.a.get(axis) + b.b.get(axis)) - (old.a[axis] + old.b[axis])) <= 1e-12
			)
		energy_ok = energy_ok and event.energy_after <= event.energy_before
	_check(
		physics_ok and energy_ok, "unit-roundoff COM/spin/energy controls; not a solver tolerance"
	)
	var after_damping := var_to_bytes(rig.snapshot())
	rig._tuning.physics_angular_damping = NAN
	_check(
		(
			rig._apply_authored_angular_damping(budget) == ERR_INVALID_DATA
			and after_damping == var_to_bytes(rig.snapshot())
		),
		"nonfinite damping rejected before any mutation"
	)
	var fields_ok := true
	for i in range(rig.bodies.size()):
		var state: Dictionary = rig.bodies[i].snapshot()
		var old: Dictionary = original.bodies[i]
		for field in [
			"grounded", "gripping", "applied_load_n", "measured_reaction_n", "positional_cleanup_n"
		]:
			fields_ok = fields_ok and state[field] == old[field]
		for endpoint in ["a", "b"]:
			fields_ok = (
				fields_ok
				and state[endpoint].x == old[endpoint].x
				and state[endpoint].y == old[endpoint].y
			)
	_check(fields_ok, "drag does not edit positions, sleep, flags or qualifying loads")
	if _checks != 20:
		_failures += 1
	print("Staged articulated components: %d checks, %d failures" % [_checks, _failures])
	print("Scope: saved component ONLY; ZERO world ticks; posture NOT FIXED/NOT MEASURED")
	quit(0 if _failures == 0 else 1)


func _check(value: bool, label: String) -> void:
	_checks += 1
	if not value:
		_failures += 1
		push_error("FAIL staged articulated component: " + label)
