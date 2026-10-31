# gdlint: disable=max-line-length
extends SceneTree
## READ ONLY exact archived contact, NOT a Sim/world run or alternative candidate.
const SUPPORT = preload("res://tests/physics_fix/damped_support_mobility.gd")
const ENERGY = preload("res://tests/physics_fix/rigid_contact_candidate.gd")
const ARCHIVE := "res://tests/fixtures/m1_articulated_execution/a45a2b50eb67/idle-Slug-failure.json"
var _checks := 0
var _failures := 0


class Probe:
	extends "res://tests/physics_fix/damped_support_mobility.gd"
	var record: Dictionary = {}

	func _publish(
		bodies: Array[CapsuleBody], delta: Array, position: bool, tuning: Tuning
	) -> Error:
		if position:
			return super._publish(bodies, delta, position, tuning)
		var before: float = 0.0
		var after: float = 0.0
		for i in range(bodies.size()):
			var body: CapsuleBody = bodies[i]
			var shadow := CapsuleBody.new()
			if shadow.restore(body.snapshot()) != OK:
				return ERR_INVALID_DATA
			var axes: Dictionary = PlanarBasis.frame(body)
			var vx: float = (body.a.velocity_x + body.b.velocity_x) / 2.0 + delta[3 * i]
			var vy: float = (body.a.velocity_y + body.b.velocity_y) / 2.0 + delta[3 * i + 1]
			var omega: float = axes.omega + delta[3 * i + 2]
			shadow.a.velocity_x = vx + omega * axes.y / 2.0
			shadow.a.velocity_y = vy - omega * axes.x / 2.0
			shadow.b.velocity_x = vx - omega * axes.y / 2.0
			shadow.b.velocity_y = vy + omega * axes.x / 2.0
			before += ENERGY.kinetic_energy(body)
			after += ENERGY.kinetic_energy(shadow)
		record = {"before": before, "after": after, "gain": after - before, "delta": delta}
		# No bypass: EXACT inherited strict publication/atomicity guard.
		return super._publish(bodies, delta, position, tuning)


func _initialize() -> void:
	var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ARCHIVE))
	_check(report.tick == 37 and report.status == 30, "source a45a2b5 exact first failure")
	var full: Dictionary = bytes_to_var(Marshalls.base64_to_raw(report.full_state_variant_base64))
	var bodies: Array[CapsuleBody] = _restore(
		bytes_to_var(Marshalls.base64_to_raw(full.awake_trace.full_work_variant_base64))
	)
	_check(bodies.size() == 3, "restore immutable native work bytes only")
	var before: PackedByteArray = var_to_bytes(_states(bodies))
	var probe := Probe.new()
	probe.angular_retention = 1.0 - 0.8
	probe.history = full.candidate.bodies.duplicate(true)
	var parents: Array[int] = [-1, 0, 1]
	_check(probe.configure(bodies, parents) == OK, "native geometry/factor and original history")
	var result: Dictionary = probe.contact_velocity(bodies, 2, 1.0, 0.0, 1.0, 0.0, 0.02)
	_check(
		result.is_empty() and not probe.record.is_empty(),
		"rejection is publication, not invalid factor"
	)
	_check(probe.record.gain > 0.0001, "real energy injection, NOT an ULP identity issue")
	_check(
		(
			absf(probe.record.before - 0.06146263064834831) < 1e-15
			and absf(probe.record.after - 0.061705010156499936) < 1e-15
		),
		"independent scalar reconstruction matches native endpoint energy"
	)
	_check(before == var_to_bytes(_states(bodies)), "rejected native contact is atomic")
	print("Support-failure inspection: archived ", JSON.stringify(probe.record))
	var control := SUPPORT.new()
	control.angular_retention = 1.0
	control.history = full.candidate.bodies.duplicate(true)
	var valid: bool = control.configure(bodies, parents) == OK
	var e0: float = _energy(bodies)
	result = control.contact_velocity(bodies, 2, 1.0, 0.0, 1.0, 0.0, 0.02)
	_check(
		valid and not result.is_empty() and _energy(bodies) <= e0,
		"original undamped contact is passive on identical input, NOT a new world trial"
	)
	var rod: Dictionary = full.candidate.bodies[0].duplicate(true)
	rod.mass = 1.0
	rod.length = sqrt(8.0)
	for key in ["a", "b"]:
		var sign_value: float = -1.0 if key == "a" else 1.0
		rod[key].x = sign_value
		rod[key].y = sign_value
		rod[key].previous_x = sign_value
		rod[key].previous_y = sign_value
		rod[key].inverse_mass = 2.0
		rod[key].velocity_x = -1.5 - 2.0 * sign_value
		rod[key].velocity_y = 3.0 + 2.0 * sign_value
	bodies = _restore([rod])
	probe = Probe.new()
	probe.history = [rod.duplicate(true)]
	var one: Array[int] = [-1]
	_check(
		bodies.size() == 1 and probe.configure(bodies, one) == OK,
		"exact inclined unit rod counterexample"
	)
	before = var_to_bytes(_states(bodies))
	result = probe.contact_velocity(bodies, 0, 0.0, 0.0, 1.0, 0.0, 0.0)
	_check(
		result.is_empty() and absf(probe.record.gain - 293.0 / 484.0) < 1e-13,
		"counterexample exact gain293/484 despite removing tangential slip"
	)
	_check(
		before == var_to_bytes(_states(bodies)), "counterexample not published; barrier retained"
	)
	print("Support-failure inspection: counterexample ", JSON.stringify(probe.record))
	_check(_checks == 11, "complete diagnostic tally, not acceptance")
	print("Support-failure inspection: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _restore(states: Array) -> Array[CapsuleBody]:
	var bodies: Array[CapsuleBody] = []
	for state in states:
		var body := CapsuleBody.new()
		if body.restore(state) != OK:
			return []
		bodies.append(body)
	return bodies


func _states(bodies: Array[CapsuleBody]) -> Array:
	var states: Array = []
	for body in bodies:
		states.append(body.snapshot())
	return states


func _energy(bodies: Array[CapsuleBody]) -> float:
	var result: float = 0.0
	for body in bodies:
		result += ENERGY.kinetic_energy(body)
	return result


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("FAIL " + label)
