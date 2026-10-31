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
	var row := preload("res://tests/physics_fix/rigid_contact_candidate.gd").frame(
		bodies[2], 1.0, 0.0, 1.0
	)
	print(
		(
			"Contact input distinction: "
			+ JSON.stringify(
				{
					"endpoint_vx": bodies[2].b.velocity_x,
					"endpoint_vy": bodies[2].b.velocity_y,
					"reconstructed_tangent": row.tangent_velocity
				},
				"",
				true,
				true
			)
		)
	)
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
	_batch_projection_control()
	if _checks != 12:
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


func _batch_projection_control() -> void:
	var archived: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(
			"res://tests/fixtures/m1_articulated_execution/6249662e170d/idle-Slug-failure.json"
		)
	)
	var decoded: Dictionary = bytes_to_var(
		Marshalls.base64_to_raw(archived.full_state_variant_base64)
	)
	var states: Array = bytes_to_var(
		Marshalls.base64_to_raw(decoded.awake_trace.full_work_variant_base64)
	)
	var bodies: Array[CapsuleBody] = []
	var valid := true
	for state in states:
		var body := CapsuleBody.new()
		valid = body.restore(state) == OK and valid
		bodies.append(body)
	_check(valid and bodies.size() == 3, "restore exact second saved batch projection failure")
	var before := _bits(bodies)
	var parents: Array[int] = [-1, 0, 1]
	var lowest: Array[bool] = [false, false, true]
	const CONFIG = preload("res://core/tuning.tres")
	var model := CreaturePresets.load_model("Slug", CONFIG)
	var friction := R25Fixture.materials(model)
	var bounce := R25Fixture.materials(model, true)
	var grid := R25Fixture.floor_grid()
	var cold := CONTACT.resolve_tick(
		bodies, parents, grid, model.total_mass(), lowest, friction, bounce, CONFIG
	)
	_check(
		cold.status != OK and before == _bits(bodies),
		"uncertified batch retains strict projection rejection atomically"
	)
	var certificate := CONTACT._velocity_key(bodies, parents)
	var warm := CONTACT.resolve_tick(
		bodies,
		parents,
		grid,
		model.total_mass(),
		lowest,
		friction,
		bounce,
		CONFIG,
		Callable(),
		certificate
	)
	_check(warm.status == OK, "certified unchanged final geometry avoids duplicate projection")
	var positions_ok := true
	for i in range(bodies.size()):
		for endpoint in ["a", "b"]:
			positions_ok = (
				positions_ok
				and bodies[i].get(endpoint).x == states[i][endpoint].x
				and bodies[i].get(endpoint).y == states[i][endpoint].y
			)
	_check(
		positions_ok and certificate != CONTACT._velocity_key(bodies, parents),
		"no pose cleanup; real nonzero material response still changes velocities"
	)
