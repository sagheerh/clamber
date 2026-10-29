extends SceneTree
## R15 mechanics units/awake engineering composition; NOT FA or creature determinism.
const TUNING = preload("res://core/tuning.tres")
var _checks := 0
var _failures := 0


func _initialize() -> void:
	_math()
	_motors()
	_limits()
	_self_collision()
	_composition()
	print("M1 R15 mechanics components: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _check(value: bool, label: String) -> void:
	_checks += 1
	if not value:
		_failures += 1
		push_error("FAIL R15 mechanics: " + label)


func _math() -> void:
	# Independent libm references are TEST ONLY; no solver transcendental call.
	for i in range(-180, 181):
		var radians := i * PI / 180.0
		var axes := PlanarBasis.basis(radians)
		_check(
			absf(axes[0] - cos(radians)) < 2e-15 and absf(axes[1] - sin(radians)) < 2e-15,
			"binary64 algebraic rotation vs independent math"
		)
		_check(
			absf(PlanarBasis.wrap_angle(PlanarBasis.angle(axes[0], axes[1]) - radians)) < 2e-15,
			"signed angle wrap roundtrip"
		)
	_check(
		is_nan(PlanarBasis.angle(0.0, 0.0)) and PlanarBasis.basis(NAN).is_empty(),
		"invalid math rejected"
	)


func _joint(kind: String = "motor") -> AngularJoint:
	var model := CreaturePresets.load_model("Hopper", TUNING)
	var bodies := model.create_bodies(0.0, 0.0)
	var joint := AngularJoint.new()
	var index := 1 if kind == "motor" else 2
	_check(joint.setup(bodies[0], bodies[index], TUNING) == OK, "real part joint setup")
	return joint


func _momentum(body: CapsuleBody) -> Array:
	return [
		(body.a.velocity_x + body.b.velocity_x) * body.mass / 2.0,
		(body.a.velocity_y + body.b.velocity_y) * body.mass / 2.0
	]


func _motors() -> void:
	for channel in ["L", "R"]:
		for mask in range(4):
			var joint := _joint()
			var value := MotorDrive.drive(joint, mask, channel, .7, TUNING)
			var held: bool = (mask & (1 if channel == "L" else 2)) != 0
			var target := -62.0 * PI / 180.0 * .7 if held else 0.0
			_check(
				absf(value.target - target) < 1e-15, "L/R masks are independent; both means both"
			)
			_check(
				absf(value.torque - clampf(2400.0 * target, -1260.0, 1260.0)) < 1e-12,
				"independent prescribed spring and gain torque clamp"
			)
			_check(
				absf(value.tick_net_relative_speed_change) <= 6.0 + 1e-14,
				"per-constraint tick angular budget"
			)
			var parent := PlanarBasis.frame(joint.parent_body)
			var child := PlanarBasis.frame(joint.child_body)
			_check(
				(
					absf(
						parent.omega / parent.inverse_inertia + child.omega / child.inverse_inertia
					)
					< 1e-12
				),
				"equal/opposite angular impulse conserves angular momentum"
			)
			_check(
				(
					_momentum(joint.parent_body) == [0.0, 0.0]
					and _momentum(joint.child_body) == [0.0, 0.0]
				),
				"torque is not a fake linear/grip load"
			)
	var released := _joint()
	_check(PlanarBasis.turn(released.child_body, -.2) == OK, "displaced joint")
	var value := MotorDrive.drive(released, 0, "L", .7, TUNING)
	_check(
		value.target == 0.0 and value.torque > 0.0, "release restores authored rest, not held pose"
	)
	var damped := _joint()
	PlanarBasis.spin(damped.child_body, 1.0)
	value = MotorDrive.drive(damped, 0, "L", .7, TUNING)
	_check(absf(value.torque + 55.0) < 1e-12, "existing c55 damper independent of spring")
	var passive := _joint("passive")
	PlanarBasis.turn(passive.child_body, .01)
	value = MotorDrive.drive(passive, 0, "", .7, TUNING)
	_check(absf(value.torque + 9.0) < 1e-11, "passive prescribed k900 return")
	var zero := _joint()
	value = MotorDrive.drive(zero, 3, "L", 0.0, TUNING)
	_check(
		value.target == 0.0 and value.torque == 0.0 and value.impulse == 0.0,
		"gain zero has no invented minimum drive"
	)
	_check(MotorDrive.drive(zero, 4, "L", .7, TUNING).is_empty(), "reject non-L/R bits")


func _limits() -> void:
	for kind in ["motor", "passive"]:
		for rotation in [-3.0, 2.0]:
			var joint := _joint(kind)
			PlanarBasis.turn(joint.child_body, rotation)
			_check(joint.project_position() == OK, "angular position constraint")
			var value := joint.state()
			_check(
				value.q >= joint.lower - 2e-15 and value.q <= joint.upper + 2e-15,
				"prescribed asymmetric motor / symmetric passive bounds"
			)
	# Deliberately OUTSIDE the boundary, no epsilon-dependent velocity predicate.
	var limit := _joint()
	PlanarBasis.turn(limit.child_body, 1.0)
	PlanarBasis.spin(limit.child_body, 1.0)
	_check(
		limit.block_velocity() == OK and absf(limit.state().omega) < 1e-12, "outward velocity block"
	)
	limit.reset_tick()
	PlanarBasis.spin(limit.child_body, -1.0)
	var before: float = limit.state().omega
	_check(
		limit.block_velocity() == OK and limit.state().omega == before,
		"inward velocity not blocked"
	)
	var fast := _joint()
	PlanarBasis.turn(fast.child_body, 1.0)
	PlanarBasis.spin(fast.child_body, 20.0)
	fast.block_velocity()
	fast.block_velocity()
	_check(
		absf(fast.impulse * fast.state().weight) <= 6.0 + 1e-14,
		"two passes cannot spend clamp twice"
	)
	var root := AngularJoint.new()
	_check(
		root.setup(fast.parent_body, fast.parent_body, TUNING) != OK, "no self/root angular joint"
	)


func _self_collision() -> void:
	var model := CreaturePresets.load_model("Hopper", TUNING)
	for pair in model.collision_pairs():
		var d := model.definition()
		_check(
			d.parts[pair[0]].kind != "foot" and d.parts[pair[1]].kind != "foot",
			"feet response mask excluded"
		)
		_check(
			d.parts[pair[1]].parent != pair[0] and d.parts[pair[0]].parent != pair[1],
			"adjacent parts excluded"
		)
	# Isolated normal-response unit, not a coupled pair-list or grip fixture.
	var bodies := model.create_bodies(0.0, 0.0)
	var a := bodies[0]
	var b := bodies[1]
	var shift_x := (a.a.x + a.b.x - b.a.x - b.b.x) / 2.0 + .1
	var shift_y := (a.a.y + a.b.y - b.a.y - b.b.y) / 2.0
	for point in [b.a, b.b]:
		point.x += shift_x
		point.y += shift_y
		point.velocity_x = -1.0
	var center_before := (a.mass * (a.a.x + a.b.x) + b.mass * (b.a.x + b.b.x)) / 2.0
	_check(SelfContact.project_position(a, b, TUNING) == OK, "self sphere normal projection")
	var geometry := SelfContact.geometry(a, b)
	_check(
		absf(geometry.distance - (a.radius + b.radius - .02)) < 1e-14,
		"existing slop, no new radius/tolerance"
	)
	_check(
		absf((a.mass * (a.a.x + a.b.x) + b.mass * (b.a.x + b.b.x)) / 2.0 - center_before) < 1e-14,
		"self position conserves mass center"
	)
	var px: float = _momentum(a)[0] + _momentum(b)[0]
	var impulse := SelfContact.project_velocity(a, b, TUNING)
	_check(
		impulse.normal_impulse > 0.0 and absf(_momentum(a)[0] + _momentum(b)[0] - px) < 1e-14,
		"self impulse physical and equal/opposite"
	)
	_check(
		not a.grounded and not b.grounded and not a.gripping and not b.gripping,
		"self cannot declare terrain support/grip"
	)


func _floor() -> SdfGrid:
	var rows: Array = []
	for iy in range(49):
		var row := PackedFloat64Array()
		for ix in range(97):
			row.append(-4.0 + iy * TUNING.physics_sdf_cell_wu)
		rows.append(row)
	var result := SdfGrid.new()
	_check(
		result.configure(rows, -12.0, -4.0, TUNING.physics_grip_friction, TUNING) == OK,
		"flat fixture"
	)
	return result


func _probe(name: String) -> ActuatedLoadProbe:
	var model := CreaturePresets.load_model(name, TUNING)
	var friction: Array[float] = []
	var bounce: Array[float] = []
	for part in model.definition().parts:
		friction.append(TUNING.physics_grip_friction)
		bounce.append(TUNING.physics_foot_restitution)
	var probe := ActuatedLoadProbe.new()
	_check(
		probe.setup(model, _floor(), 0.0, 6.0, friction, bounce, TUNING) == OK,
		"awake composition setup"
	)
	return probe


func _composition() -> void:
	var probe := _probe("Hopper")
	var restored := _probe("Hopper")
	var checkpoint := {}
	for tick in range(20):
		var row := probe.advance(3 if tick < 10 else 0)
		_check(row.status == OK, "real awake airborne steps")
		if row.status != OK:
			return
		_check(
			row.angular_joints.size() == 3 and row.drive_events.size() == 3,
			"two actual channels and passive, no head/foot invented limits"
		)
		_check(
			(
				row.contact_counts.size() == 16
				and row.contact_counts.all(
					func(c): return c.active_count == 0 and c.candidate_count == c.intervals + 1
				)
			),
			"main trace counts every body/pass, including airborne inactive"
		)
		_check(
			absf(row.momentum_budget.residual_y_ns) < 1e-12,
			"awake composition independent momentum ledger"
		)
		if tick == 9:
			checkpoint = probe.snapshot()
			_check(restored.restore(checkpoint) == OK, "actuator checkpoint restore")
		elif tick > 9:
			_check(
				(
					restored.advance(0).status == OK
					and var_to_bytes(restored.snapshot()) == var_to_bytes(probe.snapshot())
				),
				"component restored continuation exact"
			)
	var bad := checkpoint.duplicate(true)
	bad.angular_joints[0].rest_angle += .1
	var before := var_to_bytes(restored.snapshot())
	_check(
		restored.restore(bad) != OK and before == var_to_bytes(restored.snapshot()),
		"bad actuator restore atomic"
	)
	_check(
		restored.advance(4).status != OK and before == var_to_bytes(restored.snapshot()),
		"bad input leaves state unchanged"
	)
