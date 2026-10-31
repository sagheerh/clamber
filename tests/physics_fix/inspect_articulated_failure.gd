# gdlint: disable=max-line-length
extends SceneTree
## READ-ONLY archived component state. NO Sim/clock/step/advance or world run.
const NETWORK = preload("res://tests/physics_fix/articulated_mobility_candidate.gd")
const ROW = preload("res://tests/physics_fix/rigid_contact_candidate.gd")
const TUNING = preload("res://core/tuning.tres")
const ARCHIVE := "res://tests/fixtures/m1_articulated_execution/f7b8fd24d6b8/idle-Slug-failure.json"
var _checks := 0
var _failures := 0


func _initialize() -> void:
	var archived: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ARCHIVE))
	_check(archived.get("tick") == 14 and archived.get("status") == 30, "exact archived failure")
	var raw := Marshalls.base64_to_raw(archived.full_state_variant_base64)
	var decoded: Dictionary = bytes_to_var(raw)
	var trace: Dictionary = decoded.awake_trace
	_check(
		trace.phase == "pre-contact hinge velocity" and trace.velocity_pass == 1, "failure stage"
	)
	var bodies: Array[CapsuleBody] = []
	var restored := true
	for state in trace.work_state.bodies:
		var body := CapsuleBody.new()
		restored = body.restore(state) == OK and restored
		bodies.append(body)
	_check(restored and bodies.size() == 3, "restore exact work bodies, not a world")
	var before := var_to_bytes(_snapshots(bodies))
	var network := NETWORK.new()
	var parents: Array[int] = [-1, 0, 1]
	_check(network.configure(bodies, parents) == OK, "geometry and SPD factor valid")
	var velocity: Array[float] = network._velocities(bodies)
	var rhs: Array[float] = []
	var max_rhs := 0.0
	for row in network._hinges:
		var value := 0.0
		for d in range(velocity.size()):
			value += row[d] * velocity[d]
		rhs.append(-value)
		max_rhs = maxf(max_rhs, absf(value))
	var impulse: Array[float] = network._solve(rhs)
	var delta: Array[float] = []
	delta.resize(velocity.size())
	delta.fill(0.0)
	var finite := impulse.size() == 4
	for d in range(delta.size()):
		for i in range(impulse.size()):
			delta[d] += network._weights[d] * network._hinges[i][d] * impulse[i]
		finite = is_finite(delta[d]) and finite
	_check(finite and delta.size() == 9, "finite exact requested block response")
	var after: Array[CapsuleBody] = []
	var valid := true
	var max_speed := 0.0
	for i in range(bodies.size()):
		var body := bodies[i]
		var shadow := CapsuleBody.new()
		valid = shadow.restore(body.snapshot()) == OK and valid
		var axes := PlanarBasis.frame(body)
		max_speed = maxf(max_speed, absf(axes.omega))
		var vx: float = (body.a.velocity_x + body.b.velocity_x) / 2.0 + delta[3 * i]
		var vy: float = (body.a.velocity_y + body.b.velocity_y) / 2.0 + delta[3 * i + 1]
		var omega: float = axes.omega + delta[3 * i + 2]
		shadow.a.velocity_x = vx + omega * axes.y / 2.0
		shadow.a.velocity_y = vy - omega * axes.x / 2.0
		shadow.b.velocity_x = vx - omega * axes.y / 2.0
		shadow.b.velocity_y = vy + omega * axes.x / 2.0
		valid = shadow.is_valid() and valid
		after.append(shadow)
	_check(valid, "hypothetical post-state satisfies all body validity guards")
	var e0 := _energy(bodies)
	var e1 := _energy(after)
	_check(
		is_finite(e0) and is_finite(e1) and e1 > e0,
		"strict kinetic guard rejects actual binary64 result"
	)
	_check(
		network.project_velocity(bodies).is_empty(),
		"native operator rejects the archived component state"
	)
	_check(before == var_to_bytes(_snapshots(bodies)), "rejection is bitwise atomic")
	_check(
		max_speed < TUNING.physics_max_angular_velocity_rad_s and trace.work_state.ticks == 14,
		"no angular speed cap involved in this failing stage"
	)
	var report := {
		"scope": "NATIVE ARCHIVED COMPONENT INSPECTION ONLY; ZERO WORLD TICKS; NOT ACCEPTANCE",
		"archived_source": "f7b8fd24d6b89cd4644e7ca559619c20a55f26cd",
		"phase": trace.phase,
		"velocity_pass": trace.velocity_pass,
		"before_energy": e0,
		"after_energy": e1,
		"energy_change": e1 - e0,
		"energy_f64_le_hex": PackedFloat64Array([e0, e1, e1 - e0]).to_byte_array().hex_encode(),
		"max_hinge_rhs": max_rhs,
		"max_abs_omega": max_speed
	}
	print("Archived first-failure inspection: " + JSON.stringify(report, "", true, true))
	if _checks != 10:
		_failures += 1
	print("Physics-failure inspection: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _snapshots(bodies: Array[CapsuleBody]) -> Array:
	var result: Array = []
	for body in bodies:
		result.append(body.snapshot())
	return result


func _energy(bodies: Array[CapsuleBody]) -> float:
	var result := 0.0
	for body in bodies:
		result += ROW.kinetic_energy(body)
	return result


func _check(value: bool, label: String) -> void:
	_checks += 1
	if not value:
		_failures += 1
		push_error("FAIL archived inspection: " + label)
