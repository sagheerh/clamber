class_name CoincidentHinge
extends RefCounted
## Two translational hinge rows, free rotation. Angular limits/motors NOT implemented.
const TUNING = preload("res://core/tuning.tres")
var parent_point: SimBody
var child_point: SimBody


func setup(parent: SimBody, child: SimBody) -> Error:
	if (
		parent == null
		or child == null
		or parent == child
		or not parent.is_valid()
		or not child.is_valid()
	):
		return ERR_INVALID_DATA
	parent_point = parent
	child_point = child
	return OK


func project_position() -> Error:
	var weight := parent_point.inverse_mass + child_point.inverse_mass
	if not is_finite(weight) or weight <= TUNING.physics_zero:
		return ERR_INVALID_DATA
	var x := (child_point.x - parent_point.x) / weight
	var y := (child_point.y - parent_point.y) / weight
	if not is_finite(x) or not is_finite(y):
		return ERR_INVALID_DATA
	parent_point.x += parent_point.inverse_mass * x
	parent_point.y += parent_point.inverse_mass * y
	child_point.x -= child_point.inverse_mass * x
	child_point.y -= child_point.inverse_mass * y
	return OK


func project_velocity() -> Dictionary:
	var weight := parent_point.inverse_mass + child_point.inverse_mass
	if not is_finite(weight) or weight <= TUNING.physics_zero:
		return {}
	# Actual equal/opposite impulse, measured BEFORE changing either endpoint.
	var x := (parent_point.velocity_x - child_point.velocity_x) / weight
	var y := (parent_point.velocity_y - child_point.velocity_y) / weight
	if not is_finite(x) or not is_finite(y):
		return {}
	parent_point.velocity_x -= parent_point.inverse_mass * x
	parent_point.velocity_y -= parent_point.inverse_mass * y
	child_point.velocity_x += child_point.inverse_mass * x
	child_point.velocity_y += child_point.inverse_mass * y
	return {"x": x, "y": y}
