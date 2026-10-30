class_name SelfContact
extends RefCounted
## GDD4.4 sphere approximation at each segment COM. Only model.collision_pairs(),
## never adjacent pairs/feet. Normal nonpenetration only; no invented self friction.
const TUNING = preload("res://core/tuning.tres")


static func geometry(first: CapsuleBody, second: CapsuleBody) -> Dictionary:
	if first == null or second == null or not first.is_valid() or not second.is_valid():
		return {}
	var two := TUNING.physics_one + TUNING.physics_one
	var x := (second.a.x + second.b.x - first.a.x - first.b.x) / two
	var y := (second.a.y + second.b.y - first.a.y - first.b.y) / two
	var length := sqrt(x * x + y * y)
	if not is_finite(length):
		return {}
	if length == TUNING.physics_zero:
		# Exact coincident-center tie: first indexed part's authored/current axis.
		# No velocity epsilon, random normal or physical tuning parameter.
		var frame := PlanarBasis.frame(first)
		if frame.is_empty():
			return {}
		x = frame.x / sqrt(frame.squared)
		y = frame.y / sqrt(frame.squared)
	else:
		x /= length
		y /= length
	return {
		"nx": x,
		"ny": y,
		"distance": length,
		"radius": first.radius + second.radius,
		"first_inverse_mass": TUNING.physics_one / first.mass,
		"second_inverse_mass": TUNING.physics_one / second.mass
	}


static func project_position(first: CapsuleBody, second: CapsuleBody, tuning: Tuning) -> Error:
	var value := geometry(first, second)
	if value.is_empty():
		return ERR_INVALID_DATA
	var depth: float = maxf(
		TUNING.physics_zero, value.radius - tuning.physics_contact_slop_wu - value.distance
	)
	var correction: float = depth / (value.first_inverse_mass + value.second_inverse_mass)
	for point in [first.a, first.b]:
		point.x -= value.first_inverse_mass * correction * value.nx
		point.y -= value.first_inverse_mass * correction * value.ny
	for point in [second.a, second.b]:
		point.x += value.second_inverse_mass * correction * value.nx
		point.y += value.second_inverse_mass * correction * value.ny
	return OK


static func project_velocity(first: CapsuleBody, second: CapsuleBody, tuning: Tuning) -> Dictionary:
	var value := geometry(first, second)
	if value.is_empty():
		return {}
	var j: float = TUNING.physics_zero
	if value.distance <= value.radius + tuning.physics_contact_slop_wu:
		var two := TUNING.physics_one + TUNING.physics_one
		var vx := (
			(second.a.velocity_x + second.b.velocity_x - first.a.velocity_x - first.b.velocity_x)
			/ two
		)
		var vy := (
			(second.a.velocity_y + second.b.velocity_y - first.a.velocity_y - first.b.velocity_y)
			/ two
		)
		j = (
			-minf(TUNING.physics_zero, vx * value.nx + vy * value.ny)
			/ (value.first_inverse_mass + value.second_inverse_mass)
		)
	var x: float = j * value.nx
	var y: float = j * value.ny
	for point in [first.a, first.b]:
		point.velocity_x -= value.first_inverse_mass * x
		point.velocity_y -= value.first_inverse_mass * y
	for point in [second.a, second.b]:
		point.velocity_x += value.second_inverse_mass * x
		point.velocity_y += value.second_inverse_mass * y
	return {"x": x, "y": y, "normal_impulse": j}
