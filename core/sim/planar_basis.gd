class_name PlanarBasis
extends RefCounted
## Precomputed binary64 micro-rotation table; runtime only scalar arithmetic/sqrt.
## No solver transcendental calls, epsilon, tunable resolution or engine Vector2.
const TUNING = preload("res://core/tuning.tres")
const TABLE = preload("res://data/math/cordic_table.gd")


static func wrap_angle(angle: float) -> float:
	if not is_finite(angle):
		return NAN
	while angle > PI:
		angle -= TAU
	while angle < -PI:
		angle += TAU
	return angle


static func angle(x: float, y: float) -> float:
	if not is_finite(x) or not is_finite(y) or x * x + y * y <= TUNING.physics_zero:
		return NAN
	var offset: float = TUNING.physics_zero
	if x < TUNING.physics_zero:
		offset = PI if y >= TUNING.physics_zero else -PI
		x = -x
		y = -y
	var result: float = TUNING.physics_zero
	for index in range(TABLE.ANGLES.size()):
		if y == TUNING.physics_zero:
			break
		var direction := float(
			TUNING.physics_one if y > TUNING.physics_zero else -TUNING.physics_one
		)
		var old_x := x
		x += direction * y * TABLE.FACTORS[index]
		y -= direction * old_x * TABLE.FACTORS[index]
		result += direction * TABLE.ANGLES[index]
	return PlanarBasis.wrap_angle(offset + result)


static func basis(radians: float) -> Array:
	var remaining := PlanarBasis.wrap_angle(radians)
	if not is_finite(remaining):
		return []
	var sign: float = TUNING.physics_one
	var half_pi := PI / (TUNING.physics_one + TUNING.physics_one)
	if remaining > half_pi:
		remaining -= PI
		sign = -sign
	elif remaining < -half_pi:
		remaining += PI
		sign = -sign
	var x: float = TABLE.GAIN_INVERSE
	var y: float = TUNING.physics_zero
	for index in range(TABLE.ANGLES.size()):
		var direction := float(
			TUNING.physics_one if remaining >= TUNING.physics_zero else -TUNING.physics_one
		)
		var old_x := x
		x -= direction * y * TABLE.FACTORS[index]
		y += direction * old_x * TABLE.FACTORS[index]
		remaining -= direction * TABLE.ANGLES[index]
	var length := sqrt(x * x + y * y)
	return [sign * x / length, sign * y / length]


static func frame(body: CapsuleBody) -> Dictionary:
	if body == null or not body.is_valid():
		return {}
	var x := body.b.x - body.a.x
	var y := body.b.y - body.a.y
	var squared := x * x + y * y
	if not is_finite(squared) or squared <= TUNING.physics_zero:
		return {}
	return {
		"x": x,
		"y": y,
		"squared": squared,
		"inverse_inertia": (body.a.inverse_mass + body.b.inverse_mass) / squared,
		"omega":
		(
			(
				x * (body.b.velocity_y - body.a.velocity_y)
				- y * (body.b.velocity_x - body.a.velocity_x)
			)
			/ squared
		)
	}


static func spin(body: CapsuleBody, change: float) -> void:
	var two := TUNING.physics_one + TUNING.physics_one
	var x := (body.b.x - body.a.x) * change / two
	var y := (body.b.y - body.a.y) * change / two
	body.a.velocity_x += y
	body.a.velocity_y -= x
	body.b.velocity_x -= y
	body.b.velocity_y += x


static func turn(body: CapsuleBody, radians: float) -> Error:
	var axes := basis(radians)
	if axes.is_empty():
		return ERR_INVALID_DATA
	var two := TUNING.physics_one + TUNING.physics_one
	var cx := (body.a.x + body.b.x) / two
	var cy := (body.a.y + body.b.y) / two
	var x := (body.b.x - body.a.x) / two
	var y := (body.b.y - body.a.y) / two
	var rx: float = axes[TUNING.physics_zero] * x - axes[TUNING.physics_one] * y
	var ry: float = axes[TUNING.physics_one] * x + axes[TUNING.physics_zero] * y
	body.a.x = cx - rx
	body.a.y = cy - ry
	body.b.x = cx + rx
	body.b.y = cy + ry
	return OK if body.is_valid() else ERR_INVALID_DATA
