class_name CapsuleContact
extends RefCounted
## Transactional sampled-capsule/SDF response, not a coupled creature solver.
const TUNING = preload("res://core/tuning.tres")


static func resolve(
	body: CapsuleBody,
	terrain: SdfGrid,
	creature_mass: float,
	lowest: bool,
	material_friction: float,
	restitution: float,
	tuning: Tuning
) -> Error:
	if body == null or not body.is_valid() or terrain == null or tuning == null:
		return ERR_INVALID_DATA
	for value in [
		creature_mass,
		material_friction,
		restitution,
		tuning.physics_gravity_wu_s2,
		tuning.physics_contact_slop_wu,
		tuning.physics_max_projection_wu_tick,
		tuning.physics_grip_normal_force_ratio,
		tuning.physics_grip_normal_force_floor,
		tuning.physics_foot_grip_bias,
		tuning.physics_static_slip_wu_s,
		tuning.physics_limb_reset_residual_wu,
		tuning.physics_max_linear_velocity_wu_s
	]:
		if not is_finite(value):
			return ERR_INVALID_DATA
	if (
		creature_mass <= TUNING.physics_zero
		or material_friction < TUNING.physics_zero
		or restitution < TUNING.physics_zero
		or restitution > TUNING.physics_one
		or tuning.physics_tick_hz != TUNING.physics_tick_hz
		or tuning.physics_grip_normal_force_ratio < TUNING.physics_zero
		or tuning.physics_grip_normal_force_floor <= TUNING.physics_zero
		or tuning.physics_contact_slop_wu < TUNING.physics_zero
		or tuning.physics_max_projection_wu_tick <= TUNING.physics_zero
		or tuning.physics_foot_grip_bias < TUNING.physics_zero
		or tuning.physics_static_slip_wu_s < TUNING.physics_zero
		or tuning.physics_limb_reset_residual_wu < TUNING.physics_zero
		or tuning.physics_max_linear_velocity_wu_s <= TUNING.physics_zero
		or tuning.physics_limb_lengths_wu.is_empty()
	):
		return ERR_INVALID_DATA
	var work := CapsuleBody.new()
	if work.restore(body.snapshot()) != OK:
		return ERR_INVALID_DATA
	var status := _response(
		work, terrain, creature_mass, lowest, material_friction, restitution, tuning
	)
	return status if status != OK else body.restore(work.snapshot())


static func _response(
	body: CapsuleBody,
	terrain: SdfGrid,
	creature_mass: float,
	lowest: bool,
	friction: float,
	restitution: float,
	tuning: Tuning
) -> Error:
	var zero := TUNING.physics_zero
	var one := TUNING.physics_one
	var dt := float(one) / tuning.physics_tick_hz
	var dx := body.b.x - body.a.x
	var dy := body.b.y - body.a.y
	var squared := dx * dx + dy * dy
	if not is_finite(squared) or squared <= zero or terrain.cell_size() <= zero:
		return ERR_INVALID_DATA
	# Bound before integer conversion; do not accept arbitrarily huge sample counts.
	var extent := sqrt(squared)
	if (
		not is_finite(body.rest_length)
		or body.rest_length > tuning.physics_limb_lengths_wu[-one]
		or extent > body.rest_length + tuning.physics_limb_reset_residual_wu
	):
		return ERR_PARAMETER_RANGE_ERROR
	var intervals := maxi(one, ceili(extent / terrain.cell_size()))
	var threshold := maxf(
		tuning.physics_grip_normal_force_floor,
		tuning.physics_grip_normal_force_ratio * creature_mass * absf(tuning.physics_gravity_wu_s2)
	)
	if not is_finite(threshold):
		return ERR_INVALID_DATA
	var may_grip := body.kind == "foot" and lowest and body.normal_force_last_tick >= threshold
	body.grounded = false
	body.gripping = false
	var positional: float = zero
	var impulse: float = zero
	var original_a := [body.a.x, body.a.y]
	var original_b := [body.b.x, body.b.y]
	for index in range(intervals + one):
		var u := float(index) / intervals
		var v := one - u
		var sample := _swept_sample(
			terrain,
			body.a.x * v + body.b.x * u,
			body.a.y * v + body.b.y * u,
			body.a.previous_x * v + body.b.previous_x * u,
			body.a.previous_y * v + body.b.previous_y * u,
			body.radius,
			tuning
		)
		if sample.is_empty():
			return ERR_INVALID_DATA
		if sample.distance > body.radius + tuning.physics_contact_slop_wu:
			continue
		body.grounded = true
		var nx: float = sample.nx
		var ny: float = sample.ny
		var denominator := v * v * body.a.inverse_mass + u * u * body.b.inverse_mass
		if not is_finite(denominator) or denominator <= zero:
			return ERR_INVALID_DATA
		var correction: float = (
			maxf(zero, body.radius - tuning.physics_contact_slop_wu - sample.distance) / denominator
		)
		positional += correction / (dt * dt)
		body.a.x += body.a.inverse_mass * v * nx * correction
		body.a.y += body.a.inverse_mass * v * ny * correction
		body.b.x += body.b.inverse_mass * u * nx * correction
		body.b.y += body.b.inverse_mass * u * ny * correction
		var vx := body.a.velocity_x * v + body.b.velocity_x * u
		var vy := body.a.velocity_y * v + body.b.velocity_y * u
		var normal := vx * nx + vy * ny
		var bounce := -(one + restitution) * minf(zero, normal) / denominator
		impulse += bounce / dt
		var tangent := -vx * ny + vy * nx
		var damping: float = minf(friction, sample.friction)
		if may_grip:
			damping *= tuning.physics_foot_grip_bias
		body.gripping = body.gripping or may_grip
		var retained := tangent * (one - minf(float(one), damping))
		if absf(tangent) < tuning.physics_static_slip_wu_s:
			retained = zero
		var tangential := (retained - tangent) / denominator
		body.a.velocity_x += body.a.inverse_mass * v * (nx * bounce - ny * tangential)
		body.a.velocity_y += body.a.inverse_mass * v * (ny * bounce + nx * tangential)
		body.b.velocity_x += body.b.inverse_mass * u * (nx * bounce - ny * tangential)
		body.b.velocity_y += body.b.inverse_mass * u * (ny * bounce + nx * tangential)
	body.normal_force_last_tick = maxf(positional, impulse)
	for entry in [[body.a, original_a], [body.b, original_b]]:
		var point: SimBody = entry[zero]
		var before: Array = entry[one]
		var x: float = point.x - before[zero]
		var y: float = point.y - before[one]
		if (
			not is_finite(x * x + y * y)
			or (
				x * x + y * y
				> tuning.physics_max_projection_wu_tick * tuning.physics_max_projection_wu_tick
			)
		):
			return ERR_PARAMETER_RANGE_ERROR
	return OK if body.is_valid() else ERR_INVALID_DATA


static func _swept_sample(
	terrain: SdfGrid, x: float, y: float, px: float, py: float, radius: float, tuning: Tuning
) -> Dictionary:
	var current := terrain.sample(x, y)
	var previous := terrain.sample(px, py)
	if current.is_empty() or previous.is_empty():
		return {}
	var dx := x - px
	var dy := y - py
	var squared := dx * dx + dy * dy
	var bound := (
		tuning.physics_max_linear_velocity_wu_s / tuning.physics_tick_hz
		+ tuning.physics_max_projection_wu_tick
	)
	if not is_finite(squared) or not is_finite(bound) or squared > bound * bound:
		return {}
	var approach: float = dx * previous.nx + dy * previous.ny
	if previous.distance <= radius and approach < TUNING.physics_zero:
		# Preserve the entering-side normal, including already grounded motion.
		previous.distance += approach
		return previous
	if previous.distance > radius:
		var steps := maxi(TUNING.physics_one, ceili(sqrt(squared) / terrain.cell_size()))
		var last_distance: float = previous.distance
		var last_u: float = TUNING.physics_zero
		for index in range(TUNING.physics_one, steps + TUNING.physics_one):
			var u := float(index) / steps
			var probe := terrain.sample(px + dx * u, py + dy * u)
			if probe.is_empty():
				return {}
			if probe.distance <= radius:
				var fraction: float = (last_distance - radius) / (last_distance - probe.distance)
				var hit_u := last_u + (u - last_u) * fraction
				var hit := terrain.sample(px + dx * hit_u, py + dy * hit_u)
				if hit.is_empty():
					return {}
				hit.distance += (TUNING.physics_one - hit_u) * (dx * hit.nx + dy * hit.ny)
				return hit
			last_distance = probe.distance
			last_u = u
	return current
