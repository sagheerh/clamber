# gdlint: disable=max-line-length
extends "res://tests/physics_fix/damped_support_mobility.gd"
## PRIVATE constitutive trial arithmetic ONLY, not a physical publication API.
## Owner MUST compare complete drag+contact endpoint energy with its actual raw
## origin and reject/restore the entire tick before Sim can commit. Old per-contact
## publishers/classes are unchanged. Intermediate Newton responses are not states.


func _publish(bodies: Array[CapsuleBody], delta: Array, position: bool, tuning: Tuning) -> Error:
	if position:
		return super._publish(bodies, delta, position, tuning)
	if not _finite(delta) or delta.size() != _weights.size():
		return ERR_INVALID_DATA
	var shadows: Array[CapsuleBody] = []
	for i in range(bodies.size()):
		var shadow := CapsuleBody.new()
		if shadow.restore(bodies[i].snapshot()) != OK:
			return ERR_INVALID_DATA
		var axes: Dictionary = PlanarBasis.frame(bodies[i])
		var vx: float = (shadow.a.velocity_x + shadow.b.velocity_x) / 2.0 + delta[3 * i]
		var vy: float = (shadow.a.velocity_y + shadow.b.velocity_y) / 2.0 + delta[3 * i + 1]
		var omega: float = axes.omega + delta[3 * i + 2]
		shadow.a.velocity_x = vx + omega * axes.y / 2.0
		shadow.a.velocity_y = vy - omega * axes.x / 2.0
		shadow.b.velocity_x = vx - omega * axes.y / 2.0
		shadow.b.velocity_y = vy + omega * axes.x / 2.0
		if not shadow.is_valid():
			return ERR_INVALID_DATA
		shadows.append(shadow)
	for i in range(bodies.size()):
		bodies[i].a.velocity_x = shadows[i].a.velocity_x
		bodies[i].a.velocity_y = shadows[i].a.velocity_y
		bodies[i].b.velocity_x = shadows[i].b.velocity_x
		bodies[i].b.velocity_y = shadows[i].b.velocity_y
	return OK
