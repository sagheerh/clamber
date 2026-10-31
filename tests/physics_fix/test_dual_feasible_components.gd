# gdlint: disable=max-line-length
extends "res://tests/physics_fix/test_runtime_manifold_audit.gd"


func _initialize() -> void:
	var kernel := Probe.new()
	var frame: Dictionary = preload("res://tests/physics_fix/manifold_archive.gd").runtime_frame(
		"res://tests/fixtures/m1_candidate_runtime/00f33495a75c/summary.json", kernel
	)
	_check(not frame.is_empty(), "exact archived Hopper mask3 tick4 first physical support frame")
	var before := _states(frame.bodies)
	var energy := _energy(frame.bodies)
	var response: Dictionary = BLOCK.solve(kernel, frame.bodies, frame.contacts)
	_check(
		not response.is_empty() and _energy(frame.bodies) <= energy,
		"changed pivot order solves real archive and passes ORIGINAL strict physical publisher"
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
		{"row": [1.0, 1.0], "rhs": 3.0},
		{"row": [1.0, 2.0], "rhs": 5.5}
	]
	var old := PrimalFirstProbe.new()
	old._weights = [1.0, 1.0]
	_check(
		old._active_solve([], [], inequalities).is_empty(),
		"exact two-dimensional counterexample: primal-first adds singular third row before discarding tensile first"
	)
	var changed := Probe.new()
	changed._weights = [1.0, 1.0]
	var solved: Dictionary = changed._active_solve([], [], inequalities)
	_check(
		(
			not solved.is_empty()
			and solved.active == [2]
			and absf(solved.delta[0] - 1.1) < 1e-12
			and absf(solved.delta[1] - 2.2) < 1e-12
		),
		"dual-feasible pivot retains exact strict constraints and nonnegative multiplier"
	)
	print("Dual feasible components: %d checks, %d failures" % [_checks, _failures])
	print(
		(
			"Dual feasible archive diagnostic: "
			+ JSON.stringify(
				{"calls": kernel.calls, "published": kernel.publication}, "", true, true
			)
		)
	)
	print(
		"Scope: one exact archived support solve and algebraic counterexample; ZERO creature ticks; not acceptance"
	)
	quit(1 if _failures else 0)
