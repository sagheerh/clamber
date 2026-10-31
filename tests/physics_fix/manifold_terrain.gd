# gdlint: disable=max-line-length,max-returns
extends RefCounted
## NEW unadopted terrain adapter. Existing sampling/grip policy; network response.
const NETWORK = preload("res://tests/physics_fix/surface_constitutive_kernel.gd")
const ORIGINAL = preload("res://tests/physics_fix/surface_impact_kernel.gd")
const BLOCK = preload("res://tests/physics_fix/support_manifold.gd")
const ROW = preload("res://tests/physics_fix/capsule_surface_frame.gd")
const TUNING = preload("res://core/tuning.tres")


static func resolve_tick(
	bodies: Array[CapsuleBody],
	parents: Array[int],
	terrain: SdfGrid,
	creature_mass: float,
	lowest: Array[bool],
	friction: Array[float],
	restitution: Array[float],
	tuning: Tuning,
	observer: Callable = Callable(),
	certified_velocity: PackedByteArray = PackedByteArray(),
	limits: Array = [],
	history: Array = [],
	constitutive: bool = true
) -> Dictionary:
	var kernel_script: GDScript = NETWORK if constitutive else ORIGINAL
	if (
		bodies.is_empty()
		or parents.size() != bodies.size()
		or lowest.size() != bodies.size()
		or friction.size() != bodies.size()
		or restitution.size() != bodies.size()
		or terrain == null
		or tuning == null
	):
		return {"status": ERR_INVALID_DATA, "reason": "invalid batch dimensions"}
	if (
		not is_finite(creature_mass)
		or creature_mass <= 0.0
		or tuning.physics_tick_hz != TUNING.physics_tick_hz
	):
		return {"status": ERR_INVALID_DATA, "reason": "invalid mass/fixed tick"}
	for value in [
		tuning.physics_contact_slop_wu,
		tuning.physics_grip_normal_force_ratio,
		tuning.physics_grip_normal_force_floor,
		tuning.physics_foot_grip_bias,
		tuning.physics_static_slip_wu_s,
		tuning.physics_gravity_wu_s2,
		tuning.physics_max_projection_wu_tick
	]:
		if not is_finite(value):
			return {"status": ERR_INVALID_DATA, "reason": "nonfinite resource"}
	if (
		tuning.physics_contact_slop_wu < 0.0
		or tuning.physics_grip_normal_force_ratio < 0.0
		or tuning.physics_grip_normal_force_floor <= 0.0
		or tuning.physics_foot_grip_bias < 0.0
		or tuning.physics_static_slip_wu_s < 0.0
		or tuning.physics_max_projection_wu_tick <= 0.0
	):
		return {"status": ERR_INVALID_DATA, "reason": "invalid resource"}
	var validation: RefCounted = kernel_script.new()
	validation.limits = limits
	validation.history = history
	if constitutive:
		validation.angular_retention = 1.0 - tuning.physics_angular_damping
	if validation.configure(bodies, parents) != OK:
		return {"status": ERR_INVALID_DATA, "reason": "invalid tree or aliased bodies"}
	var work: Array[CapsuleBody] = []
	var before: Array = []
	var prior_n := 0
	for i in range(bodies.size()):
		if (
			bodies[i] == null
			or not bodies[i].is_valid()
			or not is_finite(friction[i])
			or friction[i] < 0.0
			or not is_finite(restitution[i])
			or restitution[i] < 0.0
			or restitution[i] > 1.0
		):
			return {"status": ERR_INVALID_DATA, "reason": "invalid body/material"}
		before.append(bodies[i].snapshot())
		if bodies[i].kind == "foot" and bodies[i].grounded:
			prior_n += 1
		var shadow := CapsuleBody.new()
		if shadow.restore(before[i]) != OK:
			return {"status": ERR_INVALID_DATA, "reason": "shadow restore"}
		work.append(shadow)
	# Frozen previous-tick N, original formula. No extra support predicate.
	var threshold: float = tuning.physics_grip_normal_force_floor
	if prior_n > 0:
		threshold = maxf(
			threshold,
			(
				tuning.physics_grip_normal_force_ratio
				* creature_mass
				* absf(tuning.physics_gravity_wu_s2)
				/ prior_n
			)
		)
	if not is_finite(threshold):
		return {"status": ERR_INVALID_DATA, "reason": "nonfinite grip threshold"}
	var reactions: Array[float] = []
	reactions.resize(2 * (bodies.size() - 1))
	reactions.fill(0.0)
	var dt := 1.0 / tuning.physics_tick_hz
	# Position stage first: rigid-body rotations change the hinge Jacobian.
	# Rebuild for each requested displacement; never use an old pose's factors.
	for part in range(work.size()):
		var body := work[part]
		var count := _intervals(body, terrain, tuning)
		if count < 1:
			return _fail("invalid capsule extent", work)
		body.positional_cleanup_n = 0.0
		for index in range(count + 1):
			var u := float(index) / count
			var sample := _sample(body, terrain, u, tuning)
			if sample.is_empty():
				return _fail("position sweep", work)
			var depth: float = maxf(
				0.0, body.radius - tuning.physics_contact_slop_wu - sample.distance
			)
			if depth == 0.0:
				continue
			var position_network := (
				preload("res://tests/physics_fix/limited_articulated_mobility_candidate.gd").new()
			)
			position_network.limits = limits
			position_network.position_terrain = terrain
			if position_network.configure(work, parents) != OK:
				return _fail("position factor", work)
			var event := position_network.contact_position(
				work, part, u, sample.nx, sample.ny, depth, tuning
			)
			if event.is_empty():
				return _fail("network position response", work)
			body.positional_cleanup_n += event.position_multiplier_kg_wu / (dt * dt)
	# Reconcile velocities on the FINAL geometry before applying material policy.
	var network: RefCounted = kernel_script.new()
	network.limits = limits
	network.history = history
	if constitutive:
		network.angular_retention = 1.0 - tuning.physics_angular_damping
	if network.configure(work, parents) != OK:
		return _fail("velocity factor", work)
	if (
		certified_velocity.is_empty()
		or certified_velocity != _velocity_key(work, parents) + var_to_bytes(limits)
	):
		var projected: Dictionary = network.project_velocity(work)
		if projected.is_empty():
			return _fail("initial network velocity projection", work)
		_add(reactions, projected.hinge_impulses)
	var contacts: Array = []
	var observations: Array = []
	for part in range(work.size()):
		var body := work[part]
		var count := _intervals(body, terrain, tuning)
		if count < 1:
			return _fail("velocity capsule extent", work)
		var may_grip: bool = (
			prior_n > 0
			and body.kind == "foot"
			and lowest[part]
			and body.applied_load_n >= threshold
		)
		body.grounded = false
		body.gripping = false
		body.measured_reaction_n = 0.0
		for index in range(count + 1):
			var u := float(index) / count
			var sample := _sample(body, terrain, u, tuning)
			if sample.is_empty():
				return _fail("velocity sweep", work)
			var observed: Dictionary = CapsuleContact._observation(body, u, index, count, sample)
			observed.centerline_tangent_before = observed.tangent_before
			observed.tangent_before = ROW.frame(body, u, sample.nx, sample.ny).tangent_velocity
			observed.contact_scope = "simultaneous true skin support manifold; actual material point"
			observed.may_grip = may_grip
			observed.material_friction = friction[part]
			observed.sample_friction = sample.friction
			observed.part = part
			observed.active = sample.distance <= body.radius + tuning.physics_contact_slop_wu
			if not observed.active:
				observations.append(observed)
				continue
			body.grounded = true
			body.gripping = body.gripping or may_grip
			var damping: float = minf(friction[part], sample.friction)
			if may_grip:
				damping *= tuning.physics_foot_grip_bias
			contacts.append(
				{
					"part": part,
					"u": u,
					"nx": sample.nx,
					"ny": sample.ny,
					"restitution": restitution[part],
					"damping": minf(1.0, damping),
					"static_threshold": tuning.physics_static_slip_wu_s,
					"observation": observations.size()
				}
			)
			observations.append(observed)
	var result: Dictionary = BLOCK.solve(network, work, contacts)
	if result.is_empty():
		return _fail("simultaneous material support block", work)
	_add(reactions, result.hinge_impulses)
	for index in range(contacts.size()):
		var contact: Dictionary = contacts[index]
		work[contact.part].measured_reaction_n += result.contacts[index].normal / dt
		var observed: Dictionary = observations[contact.observation]
		observed.normal_impulse_ns = result.contacts[index].normal
		observed.tangential_impulse_ns = result.contacts[index].tangent
		observed.normal_target = network.normal_target(
			contact.part, contact.u, contact.nx, contact.ny, contact.restitution
		)
		observed.angular_drag_events = result.angular_drag_events.duplicate(true)
		observed.hinge_impulses_ns = result.hinge_impulses.duplicate()
		observed.manifold_shared_event = true
	for observed in observations:
		var body: CapsuleBody = work[observed.part]
		observed.avx_after = body.a.velocity_x
		observed.avy_after = body.a.velocity_y
		observed.bvx_after = body.b.velocity_x
		observed.bvy_after = body.b.velocity_y
		observed.tangent_after = (
			ROW.frame(body, observed.u, observed.nx, observed.ny).tangent_velocity
		)
		observed.gripping_after = body.gripping
		if observer.is_valid():
			observer.call(observed, int(observed.part))
	# Bound TOTAL motion of every body across all samples (including transferred
	# movement), not just each individual projection. No cap silently increased.
	var bound: float = tuning.physics_max_projection_wu_tick * tuning.physics_max_projection_wu_tick
	for i in range(work.size()):
		for name in ["a", "b"]:
			var now: Dictionary = work[i].snapshot()[name]
			var dx: float = now.x - before[i][name].x
			var dy: float = now.y - before[i][name].y
			if not is_finite(dx * dx + dy * dy) or dx * dx + dy * dy > bound:
				return _fail("aggregate projection cap", work)
	for i in range(bodies.size()):
		var status := bodies[i].restore(work[i].snapshot())
		if status != OK:
			for j in range(bodies.size()):
				var rollback := bodies[j].restore(before[j])
				if rollback != OK:
					return {"status": rollback, "reason": "batch rollback failed"}
			return {"status": status, "reason": "batch publication failed"}
	return {"status": OK, "hinge_impulses": reactions, "prior_grounded_feet": prior_n}


static func _intervals(body: CapsuleBody, terrain: SdfGrid, tuning: Tuning) -> int:
	var frame := PlanarBasis.frame(body)
	if frame.is_empty() or terrain.cell_size() <= 0.0 or tuning.physics_limb_lengths_wu.is_empty():
		return -1
	var extent: float = sqrt(frame.squared)
	if (
		not is_finite(body.rest_length)
		or body.rest_length > tuning.physics_limb_lengths_wu[-1]
		or extent > body.rest_length + tuning.physics_limb_reset_residual_wu
	):
		return -1
	return maxi(1, ceili(extent / terrain.cell_size()))


static func _sample(body: CapsuleBody, terrain: SdfGrid, u: float, tuning: Tuning) -> Dictionary:
	return CapsuleContact._swept_sample(
		terrain,
		body.a.x * (1.0 - u) + body.b.x * u,
		body.a.y * (1.0 - u) + body.b.y * u,
		body.a.previous_x * (1.0 - u) + body.b.previous_x * u,
		body.a.previous_y * (1.0 - u) + body.b.previous_y * u,
		body.radius,
		tuning
	)


static func _add(target: Array[float], values: Array) -> void:
	for i in range(target.size()):
		target[i] += values[i]


static func _fail(reason: String, work: Array[CapsuleBody]) -> Dictionary:
	var states: Array = []
	for body in work:
		states.append(body.snapshot())
	return {
		"status": ERR_INVALID_DATA,
		"reason": reason,
		"full_work_variant_base64": Marshalls.raw_to_base64(var_to_bytes(states))
	}


static func _velocity_key(bodies: Array[CapsuleBody], parents: Array[int]) -> PackedByteArray:
	var key := PackedFloat64Array()
	for i in range(bodies.size()):
		var body := bodies[i]
		key.append_array(
			PackedFloat64Array(
				[
					float(parents[i]),
					body.mass,
					body.a.inverse_mass,
					body.b.inverse_mass,
					body.a.x,
					body.a.y,
					body.b.x,
					body.b.y,
					body.a.velocity_x,
					body.a.velocity_y,
					body.b.velocity_x,
					body.b.velocity_y
				]
			)
		)
	return key.to_byte_array()
