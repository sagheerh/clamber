class_name CoupledLoadProbe
extends RefCounted
## Engineering load-path probe, NOT public Sim, angular-limit/motor/self-contact solver.
## Awake integration throughout: sleep optimization is explicitly not implemented.
const TUNING = preload("res://core/tuning.tres")
var bodies: Array[CapsuleBody] = []
var _links: Array[DistanceConstraint] = []
var _hinges: Array[CoincidentHinge] = []
var _parents: Array[int] = []
var _mass: float
var _terrain: SdfGrid
var _tuning: Tuning
var _friction: Array[float] = []
var _restitution: Array[float] = []
var _ticks: int = TUNING.physics_zero


func setup(
	model: CreatureModel,
	terrain: SdfGrid,
	x: float,
	y: float,
	friction: Array[float],
	restitution: Array[float],
	tuning: Tuning
) -> Error:
	if (
		model == null
		or terrain == null
		or tuning == null
		or tuning.physics_tick_hz != TUNING.physics_tick_hz
		or tuning.physics_velocity_passes <= TUNING.physics_zero
		or tuning.physics_position_iterations <= TUNING.physics_zero
		or tuning.physics_distance_solves_per_iteration <= TUNING.physics_zero
		or tuning.physics_linear_damping < TUNING.physics_zero
		or tuning.physics_linear_damping > TUNING.physics_one
		or tuning.physics_max_linear_velocity_wu_s <= TUNING.physics_zero
	):
		return ERR_INVALID_DATA
	for value in [
		tuning.physics_gravity_wu_s2,
		tuning.physics_linear_damping,
		tuning.physics_max_linear_velocity_wu_s
	]:
		if not is_finite(value):
			return ERR_INVALID_DATA
	var candidates := model.create_bodies(x, y)
	if (
		candidates.is_empty()
		or candidates.size() != friction.size()
		or candidates.size() != restitution.size()
	):
		return ERR_INVALID_DATA
	var links: Array[DistanceConstraint] = []
	var hinges: Array[CoincidentHinge] = []
	var parents: Array[int] = []
	var definition := model.definition()
	for index in range(candidates.size()):
		var body := candidates[index]
		var link := DistanceConstraint.new()
		if link.setup(body.a, body.b, body.rest_length, tuning.physics_rigid_compliance) != OK:
			return ERR_INVALID_DATA
		links.append(link)
		var parent: int = definition.parts[index].parent
		parents.append(parent)
		if parent >= TUNING.physics_zero:
			var hinge := CoincidentHinge.new()
			if hinge.setup(candidates[parent].b, body.a) != OK:
				return ERR_INVALID_DATA
			hinges.append(hinge)
	bodies = candidates
	_links = links
	_hinges = hinges
	_parents = parents
	_mass = model.total_mass()
	_terrain = terrain
	_tuning = tuning.duplicate(true)
	_friction = friction.duplicate()
	_restitution = restitution.duplicate()
	_ticks = TUNING.physics_zero
	return OK


func snapshot() -> Dictionary:
	var states: Array = []
	for body in bodies:
		states.append(body.snapshot())
	return {"bodies": states, "ticks": _ticks}


func restore(state: Dictionary) -> Error:
	if (
		not state.get("ticks") is int
		or state.ticks < TUNING.physics_zero
		or not state.get("bodies") is Array
		or state.bodies.size() != bodies.size()
	):
		return ERR_INVALID_DATA
	for index in range(bodies.size()):
		var probe := CapsuleBody.new()
		if (
			not state.bodies[index] is Dictionary
			or probe.restore(bodies[index].snapshot()) != OK
			or probe.restore(state.bodies[index]) != OK
		):
			return ERR_INVALID_DATA
	for index in range(bodies.size()):
		var status := bodies[index].restore(state.bodies[index])
		if status != OK:
			return status
	_ticks = state.ticks
	return OK


func step() -> Dictionary:
	if _tuning == null or bodies.is_empty():
		return {"status": ERR_UNCONFIGURED}
	var before := snapshot()
	var result := _step(before)
	if result.status != OK:
		var rollback := restore(before)
		if rollback != OK:
			return {"status": rollback, "rollback_failed": true}
	return result


func _step(before: Dictionary) -> Dictionary:
	var dt := float(TUNING.physics_one) / _tuning.physics_tick_hz
	var previous_count: int = TUNING.physics_zero
	var hinge_x: Array[float] = []
	var hinge_y: Array[float] = []
	var reaction: Array[float] = []
	var cleanup: Array[float] = []
	for body in bodies:
		if body.kind == "foot" and body.grounded:
			previous_count += TUNING.physics_one
		hinge_x.append(TUNING.physics_zero)
		hinge_y.append(TUNING.physics_zero)
		reaction.append(TUNING.physics_zero)
		cleanup.append(TUNING.physics_zero)
	var projected := _predict_and_project(dt)
	if projected != OK:
		return {"status": projected}
	var response := _velocity_contacts(before, dt, hinge_x, hinge_y, reaction, cleanup)
	if response.status != OK:
		return response
	for index in range(bodies.size()):
		bodies[index].measured_reaction_n = reaction[index]
		bodies[index].positional_cleanup_n = cleanup[index]
	_ticks += TUNING.physics_one
	return _trace(previous_count, response.lowest, hinge_y)


func _predict_and_project(dt: float) -> Error:
	var retention := TUNING.physics_one - _tuning.physics_linear_damping
	for body in bodies:
		for point in [body.a, body.b]:
			point.previous_x = point.x
			point.previous_y = point.y
			# Damping acts on existing motion; gravity is a full external impulse.
			point.velocity_x *= retention
			point.velocity_y = point.velocity_y * retention + _tuning.physics_gravity_wu_s2 * dt
			if not _clamp_velocity(point):
				return ERR_INVALID_DATA
			point.x += point.velocity_x * dt
			point.y += point.velocity_y * dt
	for link in _links:
		link.reset_multiplier()
	for iteration in range(_tuning.physics_position_iterations):
		for link in _links:
			for repetition in range(_tuning.physics_distance_solves_per_iteration):
				if link.project(_tuning) != OK:
					return ERR_INVALID_DATA
		for hinge in _hinges:
			if hinge.project_position() != OK:
				return ERR_INVALID_DATA
	return OK


func _velocity_contacts(
	before: Dictionary,
	dt: float,
	hinge_x: Array[float],
	hinge_y: Array[float],
	reaction: Array[float],
	cleanup: Array[float]
) -> Dictionary:
	var lowest: Array[bool] = []
	# Position corrections do NOT become velocity impulses or qualifying loads.
	for velocity_pass in range(_tuning.physics_velocity_passes):
		for link in _links:
			if not _rigid_velocity(link):
				return {"status": ERR_INVALID_DATA}
		var hinge_index: int = TUNING.physics_zero
		for index in range(bodies.size()):
			var parent := _parents[index]
			if parent < TUNING.physics_zero:
				continue
			var impulse := _hinges[hinge_index].project_velocity()
			hinge_index += TUNING.physics_one
			if impulse.is_empty():
				return {"status": ERR_INVALID_DATA}
			hinge_x[index] += impulse.x
			hinge_y[index] += impulse.y
			hinge_x[parent] -= impulse.x
			hinge_y[parent] -= impulse.y
		for index in range(bodies.size()):
			var body := bodies[index]
			# Reconstruct ONLY previous post-resolve flags for each internal pass.
			# Thus batch is the sole coupled door and cannot see partially updated N.
			var state := body.snapshot()
			state.grounded = before.bodies[index].grounded
			if body.restore(state) != OK:
				return {"status": ERR_INVALID_DATA}
			var normal := _terrain.sample(body.a.x, body.a.y)
			if normal.is_empty():
				return {"status": ERR_INVALID_DATA}
			var external_x: float = hinge_x[index]
			var external_y: float = body.mass * _tuning.physics_gravity_wu_s2 * dt + hinge_y[index]
			body.applied_load_n = maxf(
				TUNING.physics_zero, -(external_x * normal.nx + external_y * normal.ny) / dt
			)
		lowest = lowest_mask(bodies, _tuning)
		var status := CapsuleContact.resolve_tick(
			bodies, _terrain, _mass, lowest, _friction, _restitution, _tuning
		)
		if status != OK:
			return {"status": status}
		for index in range(bodies.size()):
			reaction[index] += bodies[index].measured_reaction_n
			cleanup[index] += bodies[index].positional_cleanup_n
	return {"status": OK, "lowest": lowest}


func _rigid_velocity(link: DistanceConstraint) -> bool:
	var dx := link.body_b.x - link.body_a.x
	var dy := link.body_b.y - link.body_a.y
	var squared := dx * dx + dy * dy
	if not is_finite(squared) or squared <= TUNING.physics_zero:
		return false
	var length := sqrt(squared)
	var nx := dx / length
	var ny := dy / length
	var relative := (
		(link.body_b.velocity_x - link.body_a.velocity_x) * nx
		+ (link.body_b.velocity_y - link.body_a.velocity_y) * ny
	)
	var impulse := -relative / (link.body_a.inverse_mass + link.body_b.inverse_mass)
	if not is_finite(impulse):
		return false
	link.body_a.velocity_x -= link.body_a.inverse_mass * nx * impulse
	link.body_a.velocity_y -= link.body_a.inverse_mass * ny * impulse
	link.body_b.velocity_x += link.body_b.inverse_mass * nx * impulse
	link.body_b.velocity_y += link.body_b.inverse_mass * ny * impulse
	return true


func _clamp_velocity(point: SimBody) -> bool:
	var squared := point.velocity_x * point.velocity_x + point.velocity_y * point.velocity_y
	if not is_finite(squared):
		return false
	if (
		squared
		> _tuning.physics_max_linear_velocity_wu_s * _tuning.physics_max_linear_velocity_wu_s
	):
		var scale := _tuning.physics_max_linear_velocity_wu_s / sqrt(squared)
		point.velocity_x *= scale
		point.velocity_y *= scale
	return true


static func lowest_mask(parts: Array[CapsuleBody], tuning: Tuning) -> Array[bool]:
	# Co-lowest potential capsule surface, Y up. Slop groups equal-height pads.
	# This is eligibility geometry ONLY: grounded is still exclusively resolve's flag.
	var bottom: float = INF
	for part in parts:
		bottom = minf(bottom, minf(part.a.y, part.b.y) - part.radius)
	var result: Array[bool] = []
	for part in parts:
		result.append(
			minf(part.a.y, part.b.y) - part.radius <= bottom + tuning.physics_contact_slop_wu
		)
	return result


func _trace(previous_count: int, lowest: Array, hinge_y: Array[float]) -> Dictionary:
	var feet: Array = []
	var applied: float = TUNING.physics_zero
	var measured: float = TUNING.physics_zero
	var positional: float = TUNING.physics_zero
	var other: float = TUNING.physics_zero
	for index in range(bodies.size()):
		var body := bodies[index]
		if body.kind != "foot":
			other += body.measured_reaction_n
			continue
		var penetration: float = -INF
		var extent := body.rest_length
		var intervals := maxi(TUNING.physics_one, ceili(extent / _terrain.cell_size()))
		for sample_index in range(intervals + TUNING.physics_one):
			var u := float(sample_index) / intervals
			var sample := _terrain.sample(
				body.a.x * (TUNING.physics_one - u) + body.b.x * u,
				body.a.y * (TUNING.physics_one - u) + body.b.y * u
			)
			if sample.is_empty():
				return {"status": ERR_INVALID_DATA}
			penetration = maxf(penetration, body.radius - sample.distance)
		feet.append(
			{
				"part": index,
				"hinge_impulse_y_ns": hinge_y[index],
				"gravity_impulse_y_ns":
				body.mass * _tuning.physics_gravity_wu_s2 / _tuning.physics_tick_hz,
				"applied_load_n": body.applied_load_n,
				"measured_reaction_n": body.measured_reaction_n,
				"positional_cleanup_n": body.positional_cleanup_n,
				"penetration_wu": penetration,
				"grounded": body.grounded,
				"gripping": body.gripping,
				"lowest": lowest[index]
			}
		)
		applied += body.applied_load_n
		measured += body.measured_reaction_n
		positional += body.positional_cleanup_n
	var weight := _mass * absf(_tuning.physics_gravity_wu_s2)
	return {
		"status": OK,
		"tick": _ticks - TUNING.physics_one,
		"previous_grounded_feet": previous_count,
		"feet": feet,
		"sum_applied_load_n": applied,
		"sum_measured_reaction_n": measured,
		"sum_positional_cleanup_n": positional,
		"other_body_reaction_n": other,
		"weight_n": weight,
		"applied_error_n": applied - weight,
		"measured_error_n": measured - weight,
		"cross_error_n": applied - measured,
		"sleep_state": "awake",
		"sleep_implemented": false
	}
