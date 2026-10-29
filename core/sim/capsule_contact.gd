class_name CapsuleContact
extends RefCounted
## Transactional sampled-capsule/SDF response, not a coupled creature solver.
const TUNING = preload("res://core/tuning.tres")


## Fixture-only primitive: caller-supplied N/eligibility are NOT a coupled entry point.
## Coupled code MUST use resolve_tick(), which freezes N from completed snapshots.
static func resolve(
	body: CapsuleBody,
	terrain: SdfGrid,
	creature_mass: float,
	lowest: bool,
	material_friction: float,
	restitution: float,
	grounded_feet_previous: int,
	tuning: Tuning,
	observer: Callable = Callable()
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
		or grounded_feet_previous < TUNING.physics_zero
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
		work,
		terrain,
		creature_mass,
		lowest,
		material_friction,
		restitution,
		grounded_feet_previous,
		tuning,
		observer
	)
	return status if status != OK else body.restore(work.snapshot())


static func _response(
	body: CapsuleBody,
	terrain: SdfGrid,
	creature_mass: float,
	lowest: bool,
	friction: float,
	restitution: float,
	grounded_feet_previous: int,
	tuning: Tuning,
	observer: Callable = Callable()
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
	# Owner R8/F24: frozen previous-tick count, not a count during this loop.
	var threshold: float = tuning.physics_grip_normal_force_floor
	if grounded_feet_previous > zero:
		threshold = maxf(
			threshold,
			(
				tuning.physics_grip_normal_force_ratio
				* (creature_mass * absf(tuning.physics_gravity_wu_s2))
				/ grounded_feet_previous
			)
		)
	if not is_finite(threshold):
		return ERR_INVALID_DATA
	var may_grip := (
		grounded_feet_previous > zero
		and body.kind == "foot"
		and lowest
		and body.applied_load_n >= threshold
	)
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
		var observation := {}
		if observer.is_valid():
			observation = _observation(body, u, index, intervals, sample)
			observation.may_grip = may_grip
			observation.material_friction = friction
			observation.sample_friction = sample.friction
		if sample.distance > body.radius + tuning.physics_contact_slop_wu:
			if not observation.is_empty():
				observation.active = false
				observation.gripping_after = body.gripping
				observer.call(observation)
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
		if not observation.is_empty():
			observation.active = true
			observation.gripping_after = body.gripping
			observation.retained = retained
			observation.static_branch = absf(tangent) < tuning.physics_static_slip_wu_s
			observation.positional_cleanup_n = correction / (dt * dt)
			observation.normal_impulse_ns = bounce
			observation.tangential_impulse_ns = tangential
			observation.avx_after = body.a.velocity_x
			observation.avy_after = body.a.velocity_y
			observation.bvx_after = body.b.velocity_x
			observation.bvy_after = body.b.velocity_y
			observation.tangent_after = (
				-(body.a.velocity_x * v + body.b.velocity_x * u) * ny
				+ (body.a.velocity_y * v + body.b.velocity_y * u) * nx
			)
			observer.call(observation)
	body.measured_reaction_n = impulse
	body.positional_cleanup_n = positional
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


static func resolve_tick(
	bodies: Array[CapsuleBody],
	terrain: SdfGrid,
	creature_mass: float,
	lowest: Array[bool],
	friction: Array[float],
	restitution: Array[float],
	tuning: Tuning,
	observer: Callable = Callable()
) -> Error:
	# No cached N state: derive from complete previous-tick snapshots BEFORE resolving.
	if (
		bodies.is_empty()
		or lowest.size() != bodies.size()
		or friction.size() != bodies.size()
		or restitution.size() != bodies.size()
	):
		return ERR_INVALID_DATA
	var work: Array[CapsuleBody] = []
	var count: int = TUNING.physics_zero
	for body in bodies:
		if (
			body == null
			or not body.is_valid()
			or body in bodies.slice(TUNING.physics_zero, work.size())
		):
			return ERR_INVALID_DATA
		var state := body.snapshot()
		if state.kind == "foot" and state.grounded:
			count += TUNING.physics_one
		var candidate := CapsuleBody.new()
		if candidate.restore(state) != OK:
			return ERR_INVALID_DATA
		work.append(candidate)
	for index in range(work.size()):
		var recorder := Callable()
		if observer.is_valid():
			recorder = observer.bind(index)
		var status := resolve(
			work[index],
			terrain,
			creature_mass,
			lowest[index],
			friction[index],
			restitution[index],
			count,
			tuning,
			recorder
		)
		if status != OK:
			return status
	# All candidates validated; publish scalar endpoint state, retaining identities.
	for index in range(work.size()):
		var status := bodies[index].restore(work[index].snapshot())
		if status != OK:
			return status
	return OK


## Detached scalar observation only; never passed back into constraint math.
static func _observation(
	body: CapsuleBody, u: float, index: int, intervals: int, sample: Dictionary
) -> Dictionary:
	var v := TUNING.physics_one - u
	var tangent: float = (
		-(body.a.velocity_x * v + body.b.velocity_x * u) * sample.ny
		+ (body.a.velocity_y * v + body.b.velocity_y * u) * sample.nx
	)
	return {
		"inverse_mass_a": body.a.inverse_mass,
		"inverse_mass_b": body.b.inverse_mass,
		"positional_cleanup_n": float(TUNING.physics_zero),
		"sample_index": index,
		"intervals": intervals,
		"u": u,
		"nx": sample.nx,
		"ny": sample.ny,
		"distance_wu": sample.distance,
		"avx_before": body.a.velocity_x,
		"avy_before": body.a.velocity_y,
		"bvx_before": body.b.velocity_x,
		"bvy_before": body.b.velocity_y,
		"avx_after": body.a.velocity_x,
		"avy_after": body.a.velocity_y,
		"bvx_after": body.b.velocity_x,
		"bvy_after": body.b.velocity_y,
		"tangent_before": tangent,
		"tangent_after": tangent,
		"retained": null,
		"static_branch": false,
		"normal_impulse_ns": float(TUNING.physics_zero),
		"tangential_impulse_ns": float(TUNING.physics_zero),
	}
