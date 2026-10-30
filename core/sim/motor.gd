class_name MotorDrive
extends RefCounted
## GDD3.4 spring/return, L/R held bits only; no alternate contraction/feel model.
const TUNING = preload("res://core/tuning.tres")


static func drive(
	joint: AngularJoint, input_mask: int, channel: String, gain: float, tuning: Tuning
) -> Dictionary:
	if (
		joint == null
		or tuning == null
		or not is_finite(gain)
		or gain < tuning.motors_gain_min
		or gain > tuning.motors_gain_max
		or input_mask < tuning.motors_input_released_mask
		or input_mask > tuning.motors_input_both_mask
	):
		return {}
	var value := joint.state()
	if value.is_empty():
		return {}
	var target: float = TUNING.physics_zero
	var torque: float
	if joint.child_body.kind == "motor":
		if channel not in ["L", "R"]:
			return {}
		var bit := (
			tuning.motors_input_left_mask if channel == "L" else tuning.motors_input_right_mask
		)
		if input_mask & bit:
			target = -tuning.motors_contraction_deg * PlanarBasis.TABLE.DEGREE_RADIANS * gain
		torque = clampf(
			(
				tuning.motors_joint_stiffness * (target - value.q)
				- tuning.motors_joint_damping * value.omega
			),
			-tuning.motors_max_torque * gain,
			tuning.motors_max_torque * gain
		)
	else:
		# Passive soft return uses its own prescribed stiffness, NOT invented motor damping.
		torque = -tuning.physics_passive_stiffness * value.q
	var response := joint.apply_impulse(torque / tuning.physics_tick_hz)
	if response.is_empty():
		return {}
	response.merge(
		{
			"q": value.q,
			"target": target,
			"omega": value.omega,
			"torque": torque,
			"spring_torque":
			(
				tuning.motors_joint_stiffness * (target - value.q)
				if joint.child_body.kind == "motor"
				else -tuning.physics_passive_stiffness * value.q
			),
			"damping_torque":
			(
				-tuning.motors_joint_damping * value.omega
				if joint.child_body.kind == "motor"
				else float(TUNING.physics_zero)
			),
			"kind": joint.child_body.kind,
			"channel": channel
		}
	)
	return response
