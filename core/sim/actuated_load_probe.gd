class_name ActuatedLoadProbe
extends CoupledLoadProbe
## R15 awake mechanics composition, NOT public Sim or completed runtime gates.
var _joints: Array[AngularJoint] = []
var _channels: Array[String] = []
var _pairs: Array = []
var _self_impulses: Array = []
var _drive_events: Array = []
var _limit_events: Array = []
var _position_events: Array = []
var _self_events: Array = []
var _input_mask: int = TUNING.physics_zero


func setup(
	model: CreatureModel,
	terrain: SdfGrid,
	x: float,
	y: float,
	friction: Array[float],
	restitution: Array[float],
	tuning: Tuning
) -> Error:
	var status := super.setup(model, terrain, x, y, friction, restitution, tuning)
	if status != OK:
		return status
	_joints = []
	_channels = []
	var definition := model.definition()
	for index in range(bodies.size()):
		if bodies[index].kind not in ["motor", "passive"]:
			continue
		var joint := AngularJoint.new()
		if joint.setup(bodies[_parents[index]], bodies[index], tuning) != OK:
			return ERR_INVALID_DATA
		_joints.append(joint)
		_channels.append(definition.parts[index].channel)
	_pairs = model.collision_pairs()
	return OK


func advance(input_mask: int) -> Dictionary:
	if input_mask < TUNING.motors_input_released_mask or input_mask > TUNING.motors_input_both_mask:
		return {"status": ERR_INVALID_PARAMETER}
	_input_mask = input_mask
	var response := step()
	_input_mask = TUNING.motors_input_released_mask
	return response


func snapshot() -> Dictionary:
	var result := super.snapshot()
	result.angular_joints = []
	for joint in _joints:
		result.angular_joints.append(joint.snapshot())
	return result


func restore(state: Dictionary) -> Error:
	if not state.get("angular_joints") is Array or state.angular_joints.size() != _joints.size():
		return ERR_INVALID_DATA
	for index in range(_joints.size()):
		if (
			not state.angular_joints[index] is Dictionary
			or not _joints[index].valid_snapshot(state.angular_joints[index])
		):
			return ERR_INVALID_DATA
	var status := super.restore(state)
	if status != OK:
		return status
	for index in range(_joints.size()):
		_joints[index].impulse = state.angular_joints[index].impulse
	return OK


func position_phases() -> Array:
	return super.position_phases() + ["angular", "self_contact"]


func _begin_tick() -> Error:
	_drive_events = []
	_limit_events = []
	_position_events = []
	_self_events = []
	_self_impulses = []
	for body in bodies:
		_self_impulses.append({"x": float(TUNING.physics_zero), "y": float(TUNING.physics_zero)})
	for joint in _joints:
		joint.reset_tick()
	for index in range(_joints.size()):
		var event := MotorDrive.drive(
			_joints[index], _input_mask, _channels[index], _tuning.motors_gain_default, _tuning
		)
		if event.is_empty():
			return ERR_INVALID_DATA
		event["parent_part"] = bodies.find(_joints[index].parent_body)
		event["child_part"] = bodies.find(_joints[index].child_body)
		_drive_events.append(event)
	return OK


func _extra_positions(positions_ledger: Array) -> Error:
	var before := _positions()
	for index in range(_joints.size()):
		var joint := _joints[index]
		# R21 observation only; project_position's physical operations stay unchanged.
		var value := joint.state()
		if value.is_empty():
			return ERR_INVALID_DATA
		var event := {
			"joint": index,
			"sequence": _position_events.size(),
			"parent_part": bodies.find(joint.parent_body),
			"child_part": bodies.find(joint.child_body),
			"q_rad": value.q,
			"lower_rad": joint.lower,
			"upper_rad": joint.upper,
			"error_rad": value.q - clampf(value.q, joint.lower, joint.upper),
			"parent_before": _point_positions(joint.parent_body),
			"child_before": _point_positions(joint.child_body),
		}
		if joint.project_position() != OK:
			return ERR_INVALID_DATA
		event["parent_after"] = _point_positions(joint.parent_body)
		event["child_after"] = _point_positions(joint.child_body)
		_position_events.append(event)
	_book_positions(before, positions_ledger, "angular")
	_record_length_phase("after_final_angular")
	before = _positions()
	for pair in _pairs:
		if (
			SelfContact.project_position(
				bodies[pair[TUNING.physics_zero]], bodies[pair[TUNING.physics_one]], _tuning
			)
			!= OK
		):
			return ERR_INVALID_DATA
	_book_positions(before, positions_ledger, "self_contact")
	_record_length_phase("after_final_self_contact")
	return OK


func _extra_velocities() -> Error:
	for index in range(_joints.size()):
		var joint := _joints[index]
		var before := joint.impulse
		var value := joint.state()
		if value.is_empty():
			return ERR_INVALID_DATA
		var engaged: bool = (
			(value.q <= joint.lower and value.omega < TUNING.physics_zero)
			or (value.q >= joint.upper and value.omega > TUNING.physics_zero)
		)
		var event := {
			"joint": index,
			"sequence": _limit_events.size(),
			"parent_part": bodies.find(joint.parent_body),
			"child_part": bodies.find(joint.child_body),
			"q_rad": value.q,
			"omega_rad_s": value.omega,
			"lower_rad": joint.lower,
			"upper_rad": joint.upper,
			"engaged": engaged,
			# Preserve exact boundary decisions if decimal JSON rounds a value.
			"predicate_f64_le_hex":
			(
				PackedFloat64Array([value.q, joint.lower, joint.upper, value.omega])
				. to_byte_array()
				. hex_encode()
			),
			"impulse_before": before,
			"parent_positions": _point_positions(joint.parent_body),
			"child_positions": _point_positions(joint.child_body),
			"parent_velocities": _point_velocities(joint.parent_body),
			"child_velocities": _point_velocities(joint.child_body),
		}
		if joint.block_velocity() != OK:
			return ERR_INVALID_DATA
		event["impulse_after"] = joint.impulse
		event["impulse"] = joint.impulse - before
		_limit_events.append(event)
	for pair in _pairs:
		var first: int = pair[TUNING.physics_zero]
		var second: int = pair[TUNING.physics_one]
		var event := SelfContact.project_velocity(bodies[first], bodies[second], _tuning)
		if event.is_empty():
			return ERR_INVALID_DATA
		_self_events.append(event.merged({"first": first, "second": second}))
		_self_impulses[first].x -= event.x
		_self_impulses[first].y -= event.y
		_self_impulses[second].x += event.x
		_self_impulses[second].y += event.y
	return OK


func _body_impulse(index: int) -> Dictionary:
	return _self_impulses[index]


func _step(before: Dictionary) -> Dictionary:
	var result := super._step(before)
	if result.status != OK:
		return result
	result.diagnostic_mechanics = "R15 awake actuated; NOT public Sim/FA"
	result.input_mask = _input_mask
	result.motor_gain = _tuning.motors_gain_default
	result.drive_events = _drive_events
	result.angular_limit_events = _limit_events
	result.angular_position_events = _position_events
	result.self_contact_events = _self_events
	result.angular_joints = []
	for joint in _joints:
		result.angular_joints.append(joint.state().merged(joint.snapshot()))
	result.self_collision_pairs = _pairs.duplicate(true)
	result.self_impulses_ns = _self_impulses.duplicate(true)
	return result


func _finish_velocities() -> Error:
	for body in bodies:
		var frame := PlanarBasis.frame(body)
		if frame.is_empty():
			return ERR_INVALID_DATA
		var capped := clampf(
			frame.omega,
			-_tuning.physics_max_angular_velocity_rad_s,
			_tuning.physics_max_angular_velocity_rad_s
		)
		PlanarBasis.spin(body, capped - frame.omega)
	return OK


func _point_positions(body: CapsuleBody) -> Array:
	return [body.a.x, body.a.y, body.b.x, body.b.y]


func _point_velocities(body: CapsuleBody) -> Array:
	return [body.a.velocity_x, body.a.velocity_y, body.b.velocity_x, body.b.velocity_y]
