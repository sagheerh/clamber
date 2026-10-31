# gdlint: disable=max-line-length
extends SceneTree
## Exact saved-state component controls; NO world clocks or historical replay.
const NETWORK = preload("res://tests/physics_fix/articulated_mobility_candidate.gd")
const CONTACT = preload("res://tests/physics_fix/staged_terrain_candidate.gd")
const ARCHIVE := "res://tests/fixtures/m1_articulated_execution/9e980ef9dfee/idle-Slug-failure.json"
var _checks := 0
var _failures := 0


func _initialize() -> void:
	var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ARCHIVE))
	var decoded: Dictionary = bytes_to_var(
		Marshalls.base64_to_raw(report.full_state_variant_base64)
	)
	var states: Array = bytes_to_var(
		Marshalls.base64_to_raw(decoded.awake_trace.full_work_variant_base64)
	)
	var bodies: Array[CapsuleBody] = []
	var valid := states.size() == 3
	for state in states:
		var body := CapsuleBody.new()
		valid = body.restore(state) == OK and valid
		bodies.append(body)
	_check(valid, "exact saved batch work bodies")
	var network := NETWORK.new()
	var parents: Array[int] = [-1, 0, 1]
	_check(network.configure(bodies, parents) == OK, "valid final geometry/SPD factor")
	var before := _bits(bodies)
	_check(
		network.contact_velocity(bodies, 2, 1.0, 0.0, 1.0, 0.0, 0.02).is_empty(),
		"original API reproduces saved contact rejection"
	)
	_check(before == _bits(bodies), "original strict rejection remains atomic")
	var response := CONTACT._constrained_contact_response(
		network, bodies, 2, 1.0, 0.0, 1.0, 0.0, 0.02
	)
	_check(
		(
			not response.is_empty()
			and response.normal_impulse_ns == 0.0
			and response.tangential_impulse_ns == 0.0
		),
		"exact zero physical response"
	)
	_check(before == _bits(bodies), "zero impulse preserves every velocity/pose/flag bit")
	_check(
		(
			CONTACT
			. _constrained_contact_response(network, bodies, 2, 1.0, 0.0, 1.0, 0.0, NAN)
			. is_empty()
		),
		"nonfinite material never bypasses guard"
	)
	bodies[0].a.x += 0.01
	_check(
		(
			CONTACT
			. _constrained_contact_response(network, bodies, 2, 1.0, 0.0, 1.0, 0.0, 0.02)
			. is_empty()
		),
		"stale geometry cannot reuse identity"
	)
	if _checks != 8:
		_failures += 1
	print("Staged contact identity: %d checks, %d failures" % [_checks, _failures])
	print("Scope: saved contact component ONLY; ZERO world ticks; NOT acceptance")
	quit(0 if _failures == 0 else 1)


func _bits(bodies: Array[CapsuleBody]) -> PackedByteArray:
	var snapshots: Array = []
	for body in bodies:
		snapshots.append(body.snapshot())
	return var_to_bytes(snapshots)


func _check(value: bool, label: String) -> void:
	_checks += 1
	if not value:
		_failures += 1
		push_error("FAIL contact identity: " + label)
