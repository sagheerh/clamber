# gdlint: disable=max-line-length
extends "res://tests/physics_fix/test_runtime_manifold_audit.gd"


func _initialize() -> void:
	var kernel := Probe.new()
	var frame: Dictionary = preload("res://tests/physics_fix/manifold_archive.gd").first_frame(
		"res://tests/fixtures/m1_articulated_execution/9343fb06296f/length-Hopper-failure.json",
		kernel
	)
	_check(not frame.is_empty(), "exact archived Hopper released285 first physical support frame")
	var before := _states(frame.bodies)
	var energy := _energy(frame.bodies)
	var response: Dictionary = BLOCK.solve(kernel, frame.bodies, frame.contacts)
	_check(
		not response.is_empty() and _energy(frame.bodies) <= energy,
		"twofold rank-trap precision solves real archive and passes ORIGINAL strict physical publisher"
	)
	var real := not response.is_empty()
	if real:
		for axis in ["x", "y"]:
			var actual := 0.0
			var impulse := 0.0
			for i in range(frame.bodies.size()):
				var body: CapsuleBody = frame.bodies[i]
				actual += (
					body.mass
					* (
						body.a.get("velocity_" + axis)
						+ body.b.get("velocity_" + axis)
						- before[i].a["velocity_" + axis]
						- before[i].b["velocity_" + axis]
					)
					/ 2.0
				)
			for i in range(frame.contacts.size()):
				var c: Dictionary = frame.contacts[i]
				impulse += (
					response.contacts[i].normal * c["n" + axis]
					+ response.contacts[i].tangent * (-c.ny if axis == "x" else c.nx)
				)
			real = real and absf(actual - impulse) < 1e-12
	_check(real, "archived real terrain impulse closes actual endpoint momentum")
	var poses := true
	for i in range(frame.bodies.size()):
		for endpoint in ["a", "b"]:
			for axis in ["x", "y"]:
				poses = (
					poses and frame.bodies[i].get(endpoint).get(axis) == before[i][endpoint][axis]
				)
	_check(poses, "no pose manipulation, synthesized loads or input rewrite")
	var SCALAR = preload("res://tests/physics_fix/twofold_active_solve.gd")
	_check(
		SCALAR.add(SCALAR.add([1e16, 0.0], [1.0, 0.0]), [-1e16, 0.0]) == [1.0, 0.0],
		"twofold cancellation retains exact unit; no epsilon"
	)
	# Construct dyadic values by exact power-of-two division, not a decimal
	# parser's long-literal conversion. Equality remains exact, no tolerance.
	var dyadic := 1.0 / 134217728.0
	var small: Array = SCALAR.mul([1.0 + dyadic, 0.0], [1.0 - dyadic, 0.0])
	_check(
		small[0] == 1.0 and small[1] == -dyadic * dyadic,
		"Dekker product retains exact low component"
	)

	var bad := Probe.new()
	bad._weights = [1.0, 1.0]
	_check(
		SCALAR.solve(bad, [[1.0, 0.0], [1.0, 0.0]], [0.0, 0.0], []).is_empty(),
		"genuine rank deficiency still rejected; no diagonal regularizer"
	)
	_check(
		(
			SCALAR
			. solve(
				bad, [], [], [{"row": [1.0, 0.0], "rhs": 1.0}, {"row": [-1.0, 0.0], "rhs": 0.0}]
			)
			. is_empty()
		),
		"inconsistent unilateral system still failclosed"
	)
	_check(
		not SCALAR.valid(SCALAR.mul([1e308, 0.0], [1e308, 0.0])),
		"arithmetic overflow rejected, not sanitized"
	)
	_check(
		(
			kernel.publication.get("status", ERR_INVALID_DATA) == OK
			and kernel.calls[-1].active == [0, 1, 2]
		),
		"same archived independent active set, ORIGINAL strict publisher actually called"
	)

	print("Twofold active components: %d checks, %d failures" % [_checks, _failures])
	print(
		(
			"Twofold archive diagnostic: "
			+ JSON.stringify(
				{"calls": kernel.calls, "published": kernel.publication}, "", true, true
			)
		)
	)
	print(
		"Scope: one exact archived support solve and arithmetic/rank controls; ZERO creature ticks; not acceptance"
	)
	quit(1 if _failures else 0)
