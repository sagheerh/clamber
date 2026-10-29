class_name ActuatedLoadProbe
extends CoupledLoadProbe
## R15 awake mechanics composition, NOT public Sim or completed runtime gates.
var _joints: Array[AngularJoint] = []
var _channels: Array[String] = []
var _pairs: Array = []
var _self_impulses: Array = []
var _drive_events: Array = []
var _limit_events: Array = []
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
		_drive_events.append(event)
	return OK


func _extra_positions(positions_ledger: Array) -> Error:
	var before := _positions()
	for joint in _joints:
		if joint.project_position() != OK:
			return ERR_INVALID_DATA
	_book_positions(before, positions_ledger, "angular")
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
	return OK


func _extra_velocities() -> Error:
	for index in range(_joints.size()):
		var joint := _joints[index]
		var before := joint.impulse
		if joint.block_velocity() != OK:
			return ERR_INVALID_DATA
		_limit_events.append(
			{
				"joint": index,
				"impulse_before": before,
				"impulse_after": joint.impulse,
				"impulse": joint.impulse - before
			}
		)
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
