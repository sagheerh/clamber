class_name CapsuleBody
extends RefCounted
## Two float64 endpoints sharing derived part mass; no engine physics node.
const TUNING = preload("res://core/tuning.tres")
var a: SimBody
var b: SimBody
var kind: String
var radius: float
var mass: float
var rest_length: float
var normal_force_last_tick: float = TUNING.physics_zero
var grounded: bool = false
var gripping: bool = false


func configure(part: CreaturePart, x: float, y: float) -> Error:
	if part == null or not is_finite(x) or not is_finite(y) or part.mass <= TUNING.physics_zero:
		return ERR_INVALID_DATA
	var first := SimBody.new()
	var second := SimBody.new()
	var inverse := float(TUNING.physics_one + TUNING.physics_one) / part.mass
	if (
		first.setup(x, y, inverse) != OK
		or second.setup(x + part.axis_x * part.length, y + part.axis_y * part.length, inverse) != OK
	):
		return ERR_INVALID_DATA
	a = first
	b = second
	kind = part.kind
	radius = part.radius
	mass = part.mass
	rest_length = part.length
	normal_force_last_tick = TUNING.physics_zero
	grounded = false
	gripping = false
	return OK


func is_valid() -> bool:
	return (
		a != null
		and b != null
		and a.is_valid()
		and b.is_valid()
		and is_finite(radius)
		and radius > TUNING.physics_zero
		and is_finite(mass)
		and mass > TUNING.physics_zero
		and is_finite(rest_length)
		and rest_length > TUNING.physics_zero
		and kind in ["head", "limb", "passive", "motor", "foot"]
		and is_finite(normal_force_last_tick)
		and normal_force_last_tick >= TUNING.physics_zero
	)


func snapshot() -> Dictionary:
	return {
		"a": a.snapshot(),
		"b": b.snapshot(),
		"kind": kind,
		"radius": radius,
		"mass": mass,
		"length": rest_length,
		"force": normal_force_last_tick,
		"grounded": grounded,
		"gripping": gripping,
	}


func restore(state: Dictionary) -> Error:
	for key in ["radius", "mass", "length", "force"]:
		var value: Variant = state.get(key)
		if (
			not (value is int or value is float)
			or not is_finite(float(value))
			or value < TUNING.physics_zero
		):
			return ERR_INVALID_DATA
	if (
		state.mass <= TUNING.physics_zero
		or state.radius <= TUNING.physics_zero
		or state.length <= TUNING.physics_zero
		or (
			not state.get("kind") is String
			or not state.get("grounded") is bool
			or not state.get("gripping") is bool
		)
		or not state.get("a") is Dictionary
		or not state.get("b") is Dictionary
	):
		return ERR_INVALID_DATA
	var first := SimBody.new()
	var second := SimBody.new()
	if first.restore(state.a) != OK or second.restore(state.b) != OK:
		return ERR_INVALID_DATA
	var inverse := float(TUNING.physics_one + TUNING.physics_one) / state.mass
	if not is_finite(inverse) or first.inverse_mass != inverse or second.inverse_mass != inverse:
		return ERR_INVALID_DATA
	if (
		a != null
		and (
			kind != state.kind
			or mass != state.mass
			or radius != state.radius
			or rest_length != state.length
		)
	):
		return ERR_INVALID_DATA
	if a == null:
		a = first
		b = second
	else:
		# Preserve point identity for constraints bound to these owned endpoints.
		for key in [
			"x", "y", "previous_x", "previous_y", "velocity_x", "velocity_y", "inverse_mass"
		]:
			a.set(key, first.get(key))
			b.set(key, second.get(key))
	kind = state.kind
	mass = state.mass
	radius = state.radius
	rest_length = state.length
	normal_force_last_tick = state.force
	grounded = state.grounded
	gripping = state.gripping
	return OK
