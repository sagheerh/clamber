# gdlint: disable=max-line-length
extends "res://tests/physics_fix/test_hopper369_audit.gd"


func _initialize() -> void:
	var kernel := Probe.new()
	var frame: Dictionary = preload("res://tests/physics_fix/manifold_archive.gd").first_frame(
		"res://tests/fixtures/m1_articulated_execution/5d6c4409a19e/length-Hopper-failure.json",
		kernel
	)
	_check(not frame.is_empty(), "exact archived Hopper RIGHT369 first physical support frame")
	var before := _states(frame.bodies)
	var energy := _energy(frame.bodies)
	var response: Dictionary = BLOCK.solve(kernel, frame.bodies, frame.contacts)
	_check(
		not response.is_empty() and _energy(frame.bodies) <= energy,
		"rank exchange solves real archive and passes ORIGINAL strict physical publisher"
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
	var inequalities: Array = [
		{"row": [1.0, 0.0], "rhs": 1.0},
		{"row": [0.0, 1.0], "rhs": 1.0},
		{"row": [1.0, 1.0], "rhs": 3.0}
	]
	var old := V26Probe.new()
	old._weights = [1.0, 1.0]
	_check(
		old._active_solve([], [], inequalities).is_empty(),
		"independent 2D trap: all existing multipliers POSITIVE; precision alone cannot add dependent third normal"
	)
	var changed := Probe.new()
	changed._weights = [1.0, 1.0]
	var result: Dictionary = changed._active_solve([], [], inequalities)
	_check(
		not result.is_empty() and result.delta == [1.5, 1.5] and result.active == [2],
		"finite independent face exchange finds strict primal/dual optimum without rank waiver or epsilon"
	)

	print("Rank exchange components: %d checks, %d failures" % [_checks, _failures])
	print(
		(
			"Rank exchange archive diagnostic: "
			+ JSON.stringify(
				{"calls": kernel.calls, "published": kernel.publication}, "", true, true
			)
		)
	)
	print(
		"Scope: exact archived369 solve + independent rational2D rank-exchange trap; ZERO creature ticks; not acceptance"
	)
	quit(1 if _failures else 0)
