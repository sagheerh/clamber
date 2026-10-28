class_name SimBody
extends RefCounted
## Mathematical point-body state, not a creature segment/collision shape.
## Float64 scalar coordinates avoid Vector2's build-dependent real_t precision.
## All physical properties must be supplied; no radius/head/grip defaults exist.
const TUNING = preload("res://core/tuning.tres")

var x: float
var y: float
var previous_x: float
var previous_y: float
var velocity_x: float
var velocity_y: float
var inverse_mass: float
var _configured: bool = false


func setup(initial_x: float, initial_y: float, supplied_inverse_mass: float) -> Error:
	if not is_finite(initial_x) or not is_finite(initial_y):
		return ERR_INVALID_PARAMETER
	if not is_finite(supplied_inverse_mass) or supplied_inverse_mass < TUNING.physics_zero:
		return ERR_INVALID_PARAMETER
	x = initial_x
	y = initial_y
	previous_x = initial_x
	previous_y = initial_y
	velocity_x = TUNING.physics_zero
	velocity_y = TUNING.physics_zero
	inverse_mass = supplied_inverse_mass
	_configured = true
	return OK


func is_valid() -> bool:
	return (
		_configured
		and is_finite(x)
		and is_finite(y)
		and is_finite(previous_x)
		and is_finite(previous_y)
		and is_finite(velocity_x)
		and is_finite(velocity_y)
		and is_finite(inverse_mass)
		and inverse_mass >= TUNING.physics_zero
	)


func is_within_bounds(limit: float) -> bool:
	return (
		is_valid()
		and is_finite(limit)
		and limit >= TUNING.physics_zero
		and absf(x) <= limit
		and absf(y) <= limit
	)


func snapshot() -> Dictionary:
	return {
		"x": x,
		"y": y,
		"previous_x": previous_x,
		"previous_y": previous_y,
		"velocity_x": velocity_x,
		"velocity_y": velocity_y,
		"inverse_mass": inverse_mass,
		"configured": _configured,
	}


func restore(state: Dictionary) -> Error:
	# Validate the complete candidate before mutating any member.
	var configured: Variant = state.get("configured")
	if not configured is bool or not configured:
		return ERR_INVALID_DATA
	for key in ["x", "y", "previous_x", "previous_y", "velocity_x", "velocity_y", "inverse_mass"]:
		var value: Variant = state.get(key)
		if not (value is int or value is float) or not is_finite(float(value)):
			return ERR_INVALID_DATA
	if state.inverse_mass < TUNING.physics_zero:
		return ERR_INVALID_DATA
	x = state.x
	y = state.y
	previous_x = state.previous_x
	previous_y = state.previous_y
	velocity_x = state.velocity_x
	velocity_y = state.velocity_y
	inverse_mass = state.inverse_mass
	_configured = true
	return OK
