class_name AngularJoint
extends RefCounted
## Parent/child angular row; no root/head-owned joint. Endpoints carry m/2 each,
## so I=m*actual_extent^2/4 (not an invented solid-rod inertia).
const TUNING = preload("res://core/tuning.tres")
var parent_body: CapsuleBody
var child_body: CapsuleBody
var rest_angle: float
var lower: float
var upper: float
var impulse: float = TUNING.physics_zero
var _tuning: Tuning


func setup(parent: CapsuleBody, child: CapsuleBody, tuning: Tuning) -> Error:
	if (
		parent == null
		or child == null
		or parent == child
		or tuning == null
		or child.kind not in ["motor", "passive"]
	):
		return ERR_INVALID_DATA
	parent_body = parent
	child_body = child
	_tuning = tuning.duplicate(true)
	var value := state()
	if value.is_empty():
		return ERR_INVALID_DATA
	rest_angle = value.angle
	lower = (
		(
			tuning.motors_limit_min_deg
			if child.kind == "motor"
			else -tuning.physics_passive_limit_deg
		)
		* PlanarBasis.TABLE.DEGREE_RADIANS
	)
	upper = (
		(tuning.motors_limit_max_deg if child.kind == "motor" else tuning.physics_passive_limit_deg)
		* PlanarBasis.TABLE.DEGREE_RADIANS
	)
	return OK


func reset_tick() -> void:
	impulse = TUNING.physics_zero


func state() -> Dictionary:
	var parent := PlanarBasis.frame(parent_body)
	var child := PlanarBasis.frame(child_body)
	if parent.is_empty() or child.is_empty():
		return {}
	var radians := PlanarBasis.angle(
		parent.x * child.x + parent.y * child.y, parent.x * child.y - parent.y * child.x
	)
	if not is_finite(radians):
		return {}
	return {
		"parent": parent,
		"child": child,
		"angle": radians,
		"q": PlanarBasis.wrap_angle(radians - rest_angle),
		"omega": child.omega - parent.omega,
		"weight": parent.inverse_inertia + child.inverse_inertia
	}


func apply_impulse(requested: float) -> Dictionary:
	var value := state()
	if value.is_empty() or not is_finite(requested):
		return {}
	var bound: float = _tuning.physics_max_constraint_angular_impulse_rad_s / value.weight
	var j := clampf(requested, -bound - impulse, bound - impulse)
	# Intersect both bodies' existing absolute angular-speed bounds.
	var limit := _tuning.physics_max_angular_velocity_rad_s
	var minimum: float = maxf(
		(value.parent.omega - limit) / value.parent.inverse_inertia,
		(-limit - value.child.omega) / value.child.inverse_inertia
	)
	var maximum: float = minf(
		(value.parent.omega + limit) / value.parent.inverse_inertia,
		(limit - value.child.omega) / value.child.inverse_inertia
	)
	if minimum <= maximum:
		j = clampf(j, minimum, maximum)
		j = clampf(j, -bound - impulse, bound - impulse)
	var before_impulse := impulse
	impulse += j
	PlanarBasis.spin(parent_body, -j * value.parent.inverse_inertia)
	PlanarBasis.spin(child_body, j * value.child.inverse_inertia)
	return {
		"impulse": j,
		# F63 observation ONLY: retain the requested and actually delivered drive.
		"requested_impulse": requested,
		"impulse_bound": bound,
		"impulse_before": before_impulse,
		"impulse_after": impulse,
		"parent_inverse_inertia": value.parent.inverse_inertia,
		"child_inverse_inertia": value.child.inverse_inertia,
		"parent_omega": value.parent.omega,
		"child_omega": value.child.omega,
		"speed_minimum_impulse": minimum,
		"speed_maximum_impulse": maximum,
		"relative_speed_change": j * value.weight,
		"tick_net_relative_speed_change": impulse * value.weight
	}


func project_position() -> Error:
	var value := state()
	if value.is_empty():
		return ERR_INVALID_DATA
	var error: float = value.q - clampf(value.q, lower, upper)
	if error == TUNING.physics_zero:
		return OK
	if PlanarBasis.turn(parent_body, error * value.parent.inverse_inertia / value.weight) != OK:
		return ERR_INVALID_DATA
	return PlanarBasis.turn(child_body, -error * value.child.inverse_inertia / value.weight)


func block_velocity() -> Error:
	var value := state()
	if value.is_empty():
		return ERR_INVALID_DATA
	if (
		(value.q <= lower and value.omega < TUNING.physics_zero)
		or (value.q >= upper and value.omega > TUNING.physics_zero)
	):
		return ERR_INVALID_DATA if apply_impulse(-value.omega / value.weight).is_empty() else OK
	return OK


func snapshot() -> Dictionary:
	return {"rest_angle": rest_angle, "lower": lower, "upper": upper, "impulse": impulse}


func valid_snapshot(data: Dictionary) -> bool:
	return (
		data.get("rest_angle") == rest_angle
		and data.get("lower") == lower
		and data.get("upper") == upper
		and (data.get("impulse") is float or data.get("impulse") is int)
		and is_finite(float(data.impulse))
	)
