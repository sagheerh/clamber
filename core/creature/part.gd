class_name CreaturePart
extends RefCounted
## Derived engineering segment parameters. No parent hinge exists on the head.
const TUNING = preload("res://core/tuning.tres")
var kind: String
var parent: int
var channel: String
var axis_x: float
var axis_y: float
var length: float
var mass: float
var radius: float


func configure(definition: Dictionary, tuning: Tuning) -> Error:
	if tuning == null:
		return ERR_INVALID_PARAMETER
	var candidate: Variant = definition.get("kind")
	if not candidate is String or candidate not in ["head", "limb", "passive", "motor", "foot"]:
		return ERR_INVALID_DATA
	var p: Variant = definition.get("parent")
	var c: Variant = definition.get("channel", "")
	var axis: Variant = definition.get("axis")
	if (
		not p is int
		or not c is String
		or axis not in ["RIGHT", "LEFT", "UP", "DOWN"]
		or (candidate == "motor" and c not in ["L", "R"])
		or (candidate != "motor" and c != "")
	):
		return ERR_INVALID_DATA
	var size: float = tuning.physics_joint_length_wu
	var density: float = (
		tuning.get("physics_" + candidate + "_mass_per_wu")
		if candidate != "foot"
		else tuning.physics_grip_mass_per_wu
	)
	if candidate == "limb":
		var slot: Variant = definition.get("length_index")
		if (
			not slot is int
			or slot < TUNING.physics_zero
			or slot >= tuning.physics_limb_lengths_wu.size()
		):
			return ERR_INVALID_DATA
		size = tuning.physics_limb_lengths_wu[slot]
	elif candidate == "head":
		size = tuning.physics_head_length_wu
	elif candidate == "foot":
		size = tuning.physics_foot_length_wu
	var collision: float = tuning.get("physics_" + candidate + "_collision_radius_wu")
	if (
		not is_finite(size * density)
		or size <= TUNING.physics_zero
		or density <= TUNING.physics_zero
		or not is_finite(collision)
		or collision <= tuning.physics_contact_slop_wu
	):
		return ERR_INVALID_DATA
	kind = candidate
	parent = p
	channel = c
	length = size
	mass = size * density
	radius = collision
	axis_x = (
		TUNING.physics_one
		if axis == "RIGHT"
		else -TUNING.physics_one if axis == "LEFT" else TUNING.physics_zero
	)
	axis_y = (
		TUNING.physics_one
		if axis == "UP"
		else -TUNING.physics_one if axis == "DOWN" else TUNING.physics_zero
	)
	return OK
