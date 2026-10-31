# gdlint: disable=max-line-length
extends SceneTree
## COMPONENT arithmetic/atomicity controls; no Sim, clocks, world replay or tuning.
const OLD = preload("res://tests/physics_fix/articulated_mobility_candidate.gd")
const NEW = preload("res://tests/physics_fix/limited_articulated_mobility_candidate.gd")
const CONFIG = preload("res://core/tuning.tres")
const ARCHIVE = "res://tests/fixtures/m1_limited_components/source813e3ef_tick100.json"
var _checks := 0
var _failures := 0
var _parents: Array[int] = [-1, 0, 1]


func _initialize() -> void:
	_check(
		(
			FileAccess.get_sha256(ARCHIVE)
			== "568640d3611128448384fce706672aaf817ff1599bacd4dce50a672be22c138c"
		),
		"immutable derived input hash"
	)
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ARCHIVE))
	_check(
		saved.source_commit == "813e3ef6e6d34ba76911f2f26b1dcc340e4b0702" and saved.tick == 100,
		"saved source; zero clock calls"
	)
	var bodies := _restore(saved.physical.bodies)
	_check(bodies.size() == 3, "restore saved JSON component bodies")
	var joint := AngularJoint.new()
	_check(joint.setup(bodies[0], bodies[1], CONFIG) == OK, "original authored joint setup")
	var snapshot: Dictionary = saved.physical.angular_joints[0]
	joint.rest_angle = snapshot.rest_angle
	_check(
		absf(joint.state().q - saved.native_joint.q) < 1e-12,
		"JSON geometry reconstructs native q; offline comparison only"
	)
	_check(joint.project_position() == OK, "original angular correction")
	var limits: Array = [
		{
			"parent": 0,
			"child": 1,
			"rest_angle": joint.rest_angle,
			"lower": joint.lower,
			"upper": joint.upper
		}
	]
	var input: Array = []
	for body in bodies:
		input.append(body.snapshot())
	var depth: float = bodies[0].radius - CONFIG.physics_contact_slop_wu - bodies[0].a.y
	_check(depth > 0.0, "angular correction exposes real floor penetration")
	var old_bodies := _restore(input)
	var old := OLD.new()
	_check(old.configure(old_bodies, _parents) == OK, "original hinge mobility factor")
	var rejected := old.contact_position(old_bodies, 0, 0.0, 0.0, 1.0, depth, CONFIG)
	var old_q := _q(old_bodies, joint.rest_angle)
	_check(
		not rejected.is_empty() and old_q - joint.upper > 0.001,
		"reproduce angular reopening in original contact block"
	)
	var network := NEW.new()
	network.limits = limits.duplicate(true)
	_check(
		network.configure(bodies, _parents) == OK,
		"coupled factor validates original authored limits"
	)
	var coupled := network.contact_position(bodies, 0, 0.0, 0.0, 1.0, depth, CONFIG)
	_check(not coupled.is_empty(), "coupled contact/hinge/angular block succeeds")
	var q := _q(bodies, joint.rest_angle)
	_check(
		q <= joint.upper + 1e-12 and q >= joint.lower - 1e-12,
		"no material angular reopening; arithmetic verification only"
	)
	var unchanged_velocity := true
	var rigid := true
	for i in range(bodies.size()):
		for endpoint in ["a", "b"]:
			unchanged_velocity = (
				unchanged_velocity
				and bodies[i].get(endpoint).velocity_x == input[i][endpoint].velocity_x
				and bodies[i].get(endpoint).velocity_y == input[i][endpoint].velocity_y
			)
		var dx: float = bodies[i].b.x - bodies[i].a.x
		var dy: float = bodies[i].b.y - bodies[i].a.y
		rigid = rigid and absf(sqrt(dx * dx + dy * dy) - bodies[i].rest_length) < 1e-12
	_check(unchanged_velocity, "position multiplier never becomes a velocity/load")
	_check(rigid, "all capsule extents remain rigid")
	var residual := 0.0
	for row in network._hinges:
		residual = maxf(residual, absf(NEW._dot(row, coupled.delta)))
	_check(
		residual < 1e-12 and coupled.position_multiplier_kg_wu >= 0.0,
		"same solve preserves linear hinge rows and unilateral normal"
	)
	print(
		(
			"Angular limited diagnostic: "
			+ JSON.stringify(
				{
					"old_q": old_q,
					"new_q": q,
					"upper": joint.upper,
					"hinge_linear_residual": residual
				},
				"",
				true,
				true
			)
		)
	)
	var bits := _bits(bodies)
	_check(
		(
			network.contact_position(bodies, 0, 0.0, 0.0, 1.0, depth, CONFIG).is_empty()
			and bits == _bits(bodies)
		),
		"stale geometry rejected atomically"
	)
	var invalid := NEW.new()
	invalid.limits = limits.duplicate(true)
	invalid.limits[0].upper = NAN
	_check(invalid.configure(bodies, _parents) != OK, "nonfinite bounds fail closed")
	# Set the UNIT boundary to the current measured angle to exercise both
	# unilateral directions exactly. This never changes a production resource.
	var velocity_bodies := _restore(input)
	var velocity_limits := limits.duplicate(true)
	velocity_limits[0].upper = _q(velocity_bodies, joint.rest_angle)
	_clear_velocities(velocity_bodies)
	PlanarBasis.spin(velocity_bodies[1], 1.0)
	var velocity_network := NEW.new()
	velocity_network.limits = velocity_limits
	var valid := velocity_network.configure(velocity_bodies, _parents) == OK
	var projected := velocity_network.project_velocity(velocity_bodies)
	_check(
		valid and not projected.is_empty() and _omega(velocity_bodies) <= 1e-12,
		"outward angular velocity constrained WITH hinges"
	)
	velocity_bodies = _restore(input)
	_clear_velocities(velocity_bodies)
	PlanarBasis.spin(velocity_bodies[1], -1.0)
	velocity_network = NEW.new()
	velocity_network.limits = velocity_limits.duplicate(true)
	valid = velocity_network.configure(velocity_bodies, _parents) == OK
	projected = velocity_network.project_velocity(velocity_bodies)
	_check(
		(
			valid
			and not projected.is_empty()
			and _omega(velocity_bodies) < 0.0
			and projected.angular_impulses.is_empty()
		),
		"inward motion releases unilateral upper stop"
	)
	bits = _bits(velocity_bodies)
	velocity_network.limits[0].upper += 0.1
	_check(
		(
			velocity_network.project_velocity(velocity_bodies).is_empty()
			and bits == _bits(velocity_bodies)
		),
		"mutated limit metadata invalidates factor"
	)
	_contact_control(input, velocity_limits, false)
	_contact_control(input, velocity_limits, true)
	var lower_network := NEW.new()
	velocity_bodies = _restore(input)
	_clear_velocities(velocity_bodies)
	PlanarBasis.spin(velocity_bodies[1], -1.0)
	lower_network.limits = limits.duplicate(true)
	lower_network.limits[0].lower = _q(velocity_bodies, joint.rest_angle)
	lower_network.limits[0].upper = lower_network.limits[0].lower + 1.0
	valid = lower_network.configure(velocity_bodies, _parents) == OK
	projected = lower_network.project_velocity(velocity_bodies)
	_check(
		valid and not projected.is_empty() and _omega(velocity_bodies) >= -1e-12,
		"lower stop has mirrored unilateral sign"
	)
	print("Angular limited components: %d checks, %d failures" % [_checks, _failures])
	print("Scope: saved/constructed component states ONLY; ZERO world ticks; NOT acceptance")
	quit(1 if _failures else 0)


func _contact_control(input: Array, limits: Array, invalid: bool) -> void:
	var bodies := _restore(input)
	_clear_velocities(bodies)
	for body in bodies:
		body.a.velocity_y = -1.0
		body.b.velocity_y = -1.0
	var network := NEW.new()
	network.limits = limits.duplicate(true)
	var valid := network.configure(bodies, _parents) == OK
	var bits := _bits(bodies)
	var result := network.contact_velocity(bodies, 0, 0.0, 0.0, 1.0, NAN if invalid else 0.0, 0.0)
	if invalid:
		_check(
			valid and result.is_empty() and bits == _bits(bodies),
			"invalid contact material rejects atomically"
		)
	else:
		_check(
			valid and not result.is_empty() and _omega(bodies) <= 1e-12,
			"contact cannot reopen upper-stop angular velocity"
		)
		_check(
			(
				not result.is_empty()
				and result.hinge_impulses.size() == 4
				and result.normal_impulse_ns >= 0.0
			),
			"force provenance separates hinge forces and angular torques"
		)


func _q(bodies: Array[CapsuleBody], rest: float) -> float:
	var p := PlanarBasis.frame(bodies[0])
	var c := PlanarBasis.frame(bodies[1])
	return PlanarBasis.wrap_angle(
		PlanarBasis.angle(p.x * c.x + p.y * c.y, p.x * c.y - p.y * c.x) - rest
	)


func _omega(bodies: Array[CapsuleBody]) -> float:
	return PlanarBasis.frame(bodies[1]).omega - PlanarBasis.frame(bodies[0]).omega


func _clear_velocities(bodies: Array[CapsuleBody]) -> void:
	for body in bodies:
		for point in [body.a, body.b]:
			point.velocity_x = 0.0
			point.velocity_y = 0.0


func _restore(states: Array) -> Array[CapsuleBody]:
	var bodies: Array[CapsuleBody] = []
	for state in states:
		var body := CapsuleBody.new()
		if body.restore(state) != OK:
			return []
		bodies.append(body)
	return bodies


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
