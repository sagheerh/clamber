class_name DistanceConstraint
extends RefCounted
## Independent XPBD scalar distance projection; no collision/contact or actuation.
## The caller supplies rest length and compliance; lambda resets at tick boundary.
const TUNING = preload("res://core/tuning.tres")

var body_a: SimBody
var body_b: SimBody
var rest_length: float
var compliance: float
var multiplier: float
var _configured: bool = false


func setup(a: SimBody, b: SimBody, length: float, supplied_compliance: float) -> Error:
	if a == null or b == null or a == b or not a.is_valid() or not b.is_valid():
		return ERR_INVALID_PARAMETER
	if not is_finite(length) or length <= TUNING.physics_zero:
		return ERR_INVALID_PARAMETER
	if not is_finite(supplied_compliance) or supplied_compliance < TUNING.physics_zero:
		return ERR_INVALID_PARAMETER
	body_a = a
	body_b = b
	rest_length = length
	compliance = supplied_compliance
	reset_multiplier()
	_configured = true
	return OK


func reset_multiplier() -> void:
	multiplier = TUNING.physics_zero


func is_valid() -> bool:
	return (
		_configured
		and body_a != null
		and body_b != null
		and body_a != body_b
		and body_a.is_valid()
		and body_b.is_valid()
		and is_finite(rest_length)
		and rest_length > TUNING.physics_zero
		and is_finite(compliance)
		and compliance >= TUNING.physics_zero
		and is_finite(multiplier)
	)


func project(tuning: Tuning) -> Error:
	if not is_valid() or tuning == null or tuning.physics_tick_hz <= TUNING.physics_zero:
		return ERR_INVALID_DATA
	# No raw frame elapsed time is accepted here. The tick rate is resource-owned.
	var fixed_step := float(TUNING.physics_one) / float(tuning.physics_tick_hz)
	var dx := body_b.x - body_a.x
	var dy := body_b.y - body_a.y
	var squared_length := dx * dx + dy * dy
	if not is_finite(squared_length) or squared_length <= TUNING.physics_zero:
		# Undefined direction: refuse rather than fabricate an axis or hide a NaN.
		return ERR_INVALID_DATA
	var length := sqrt(squared_length)
	var alpha := compliance / (fixed_step * fixed_step)
	var denominator := body_a.inverse_mass + body_b.inverse_mass + alpha
	if not is_finite(denominator) or denominator <= TUNING.physics_zero:
		return ERR_UNAVAILABLE
	var change := (-(length - rest_length) - alpha * multiplier) / denominator
	var nx := dx / length
	var ny := dy / length
	var ax := body_a.x - body_a.inverse_mass * nx * change
	var ay := body_a.y - body_a.inverse_mass * ny * change
	var bx := body_b.x + body_b.inverse_mass * nx * change
	var by := body_b.y + body_b.inverse_mass * ny * change
	var next_multiplier := multiplier + change
	for value in [ax, ay, bx, by, next_multiplier]:
		if not is_finite(value):
			return ERR_INVALID_DATA
	body_a.x = ax
	body_a.y = ay
	body_b.x = bx
	body_b.y = by
	multiplier = next_multiplier
	return OK


func snapshot() -> Dictionary:
	# Body snapshots are separate: no shared object references are serialized.
	return {"rest_length": rest_length, "compliance": compliance, "multiplier": multiplier}


func restore(state: Dictionary) -> Error:
	if not _configured:
		return ERR_UNCONFIGURED
	for key in ["rest_length", "compliance", "multiplier"]:
		var value: Variant = state.get(key)
		if not (value is int or value is float) or not is_finite(float(value)):
			return ERR_INVALID_DATA
	if state.rest_length <= TUNING.physics_zero or state.compliance < TUNING.physics_zero:
		return ERR_INVALID_DATA
	rest_length = state.rest_length
	compliance = state.compliance
	multiplier = state.multiplier
	return OK
