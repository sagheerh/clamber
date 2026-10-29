class_name CoupledLoadProbe
extends RefCounted
## Engineering load-path probe, NOT public Sim, angular-limit/motor/self-contact solver.
## Awake integration throughout: sleep optimization is explicitly not implemented.
const TUNING = preload("res://core/tuning.tres")
var bodies: Array[CapsuleBody] = []
## Diagnostic switch ONLY; observer-off/on physical states are compared by harness.
var collect_contact_samples: bool = false
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
	var budget := {
		"dt_s": dt,
		"momentum_before_y_ns": _momentum_y(),
		"damping_impulse_y_ns": float(TUNING.physics_zero),
		"gravity_impulse_y_ns": float(TUNING.physics_zero),
		"clamp_impulse_y_ns": float(TUNING.physics_zero),
		"internal_impulse_y_ns": float(TUNING.physics_zero),
		"contact_velocity_impulse_y_ns": float(TUNING.physics_zero),
	}
	var positions: Array = []
	for body in bodies:
		var phases := {}
		for phase in ["integration", "distance", "hinge", "contact"]:
			phases[phase] = [
				float(TUNING.physics_zero),
				float(TUNING.physics_zero),
				float(TUNING.physics_zero),
				float(TUNING.physics_zero)
			]
		positions.append(phases)
	var projected := _predict_and_project(dt, budget, positions)
	if projected != OK:
		return {"status": projected}
	var contact_samples: Array = []
	var response := _velocity_contacts(
		before, dt, hinge_x, hinge_y, reaction, cleanup, budget, positions, contact_samples
	)
	if response.status != OK:
		return response
	for index in range(bodies.size()):
		bodies[index].measured_reaction_n = reaction[index]
		bodies[index].positional_cleanup_n = cleanup[index]
	_ticks += TUNING.physics_one
	return _trace(
		previous_count, response.lowest, hinge_y, before, budget, positions, contact_samples
	)


func _predict_and_project(dt: float, budget: Dictionary, positions: Array) -> Error:
	var before_integration := _positions()
	var retention := TUNING.physics_one - _tuning.physics_linear_damping
	for body in bodies:
		for point in [body.a, body.b]:
			point.previous_x = point.x
			point.previous_y = point.y
			# Damping acts on existing motion; gravity is a full external impulse.
			var mass: float = float(TUNING.physics_one) / point.inverse_mass
			var before_damping: float = point.velocity_y
			var damped: float = point.velocity_y * retention
			budget.damping_impulse_y_ns += mass * (damped - before_damping)
			point.velocity_x *= retention
			point.velocity_y = damped + _tuning.physics_gravity_wu_s2 * dt
			budget.gravity_impulse_y_ns += mass * _tuning.physics_gravity_wu_s2 * dt
			var before_clamp: float = point.velocity_y
			if not _clamp_velocity(point):
				return ERR_INVALID_DATA
			budget.clamp_impulse_y_ns += mass * (point.velocity_y - before_clamp)
			point.x += point.velocity_x * dt
			point.y += point.velocity_y * dt
	_book_positions(before_integration, positions, "integration")
	for link in _links:
		link.reset_multiplier()
	for iteration in range(_tuning.physics_position_iterations):
		var before_distance := _positions()
		for link in _links:
			for repetition in range(_tuning.physics_distance_solves_per_iteration):
				if link.project(_tuning) != OK:
					return ERR_INVALID_DATA
		_book_positions(before_distance, positions, "distance")
		var before_hinge := _positions()
		for hinge in _hinges:
			if hinge.project_position() != OK:
				return ERR_INVALID_DATA
		_book_positions(before_hinge, positions, "hinge")
	return OK


func _velocity_contacts(
	before: Dictionary,
	dt: float,
	hinge_x: Array[float],
	hinge_y: Array[float],
	reaction: Array[float],
	cleanup: Array[float],
	budget: Dictionary,
	positions: Array,
	contact_samples: Array
) -> Dictionary:
	var lowest: Array[bool] = []
	# Position corrections do NOT become velocity impulses or qualifying loads.
	for velocity_pass in range(_tuning.physics_velocity_passes):
		var before_internal := _momentum_y()
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
		budget.internal_impulse_y_ns += _momentum_y() - before_internal
		for index in range(bodies.size()):
			var body := bodies[index]
			# Reconstruct ONLY previous post-resolve flags for each internal pass.
			# Thus batch is the sole coupled door and cannot see partially updated N.
			var state := body.snapshot()
			state.grounded = before.bodies[index].grounded
			state.gripping = before.bodies[index].gripping
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
		var before_contact := _momentum_y()
		var before_contact_positions := _positions()
		var recorder := Callable()
		if collect_contact_samples:
			recorder = _record_contact.bind(velocity_pass, contact_samples)
		var status := CapsuleContact.resolve_tick(
			bodies, _terrain, _mass, lowest, _friction, _restitution, _tuning, recorder
		)
		if status != OK:
			return {"status": status}
		_book_positions(before_contact_positions, positions, "contact")
		budget.contact_velocity_impulse_y_ns += _momentum_y() - before_contact
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


func _trace(
	previous_count: int,
	lowest: Array,
	hinge_y: Array[float],
	before: Dictionary,
	budget: Dictionary,
	positions: Array,
	contact_samples: Array
) -> Dictionary:
	var feet: Array = []
	var other_bodies: Array = []
	var applied: float = TUNING.physics_zero
	var measured: float = TUNING.physics_zero
	var positional: float = TUNING.physics_zero
	var other: float = TUNING.physics_zero
	for index in range(bodies.size()):
		var body := bodies[index]
		var geometry := _body_geometry(body, before.bodies[index])
		geometry.position_delta_wu = positions[index]
		geometry.grounded_previous = before.bodies[index].grounded
		if body.kind != "foot":
			other += body.measured_reaction_n
			other_bodies.append(
				{
					"part": index,
					"kind": body.kind,
					"applied_load_n": body.applied_load_n,
					"grounded": body.grounded,
					"measured_reaction_n": body.measured_reaction_n,
					"positional_cleanup_n": body.positional_cleanup_n
				}
			)
			other_bodies.back().merge(geometry)
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
		feet.back().merge(geometry)
		applied += body.applied_load_n
		measured += body.measured_reaction_n
		positional += body.positional_cleanup_n
	var weight := _mass * absf(_tuning.physics_gravity_wu_s2)
	budget.momentum_after_y_ns = _momentum_y()
	budget.momentum_change_y_ns = budget.momentum_after_y_ns - budget.momentum_before_y_ns
	budget.contact_reported_impulse_y_ns = (measured + other) * budget.dt_s
	budget.residual_y_ns = (
		budget.momentum_change_y_ns
		- (
			budget.gravity_impulse_y_ns
			+ budget.damping_impulse_y_ns
			+ budget.clamp_impulse_y_ns
			+ budget.internal_impulse_y_ns
			+ budget.contact_reported_impulse_y_ns
		)
	)
	budget.observed_support_bias_n = measured + other - weight
	budget.predicted_support_bias_n = (
		(
			budget.momentum_change_y_ns
			- budget.damping_impulse_y_ns
			- budget.clamp_impulse_y_ns
			- budget.internal_impulse_y_ns
		)
		/ budget.dt_s
	)
	var grounded: Array = []
	var previous_grounded: Array = []
	for index in range(bodies.size()):
		if bodies[index].grounded:
			grounded.append(index)
		if before.bodies[index].grounded:
			previous_grounded.append(index)
	return {
		"contact_samples": contact_samples,
		"grounded_parts": grounded,
		"previous_grounded_parts": previous_grounded,
		"new_grounded_parts": grounded.filter(func(part): return part not in previous_grounded),
		"lifted_parts": previous_grounded.filter(func(part): return part not in grounded),
		"diagnostic_static_slip_wu_s": _tuning.physics_static_slip_wu_s,
		"status": OK,
		"tick": _ticks - TUNING.physics_one,
		"previous_grounded_feet": previous_count,
		"feet": feet,
		"sum_applied_load_n": applied,
		"sum_measured_reaction_n": measured,
		"sum_positional_cleanup_n": positional,
		"other_body_reaction_n": other,
		"other_bodies": other_bodies,
		"momentum_budget": budget,
		"diagnostic_position_iterations": _tuning.physics_position_iterations,
		"weight_n": weight,
		"applied_error_n": applied - weight,
		"measured_error_n": measured - weight,
		"cross_error_n": applied - measured,
		"sleep_state": "awake",
		"sleep_implemented": false
	}


func _momentum_y() -> float:
	var momentum: float = TUNING.physics_zero
	for body in bodies:
		for point in [body.a, body.b]:
			momentum += point.velocity_y / point.inverse_mass
	return momentum


func _body_geometry(body: CapsuleBody, start: Dictionary) -> Dictionary:
	return {
		"mass": body.mass,
		"inverse_mass_a": body.a.inverse_mass,
		"inverse_mass_b": body.b.inverse_mass,
		"radius_wu": body.radius,
		"ax": body.a.x,
		"ay": body.a.y,
		"bx": body.b.x,
		"by": body.b.y,
		"avx": body.a.velocity_x,
		"avy": body.a.velocity_y,
		"bvx": body.b.velocity_x,
		"bvy": body.b.velocity_y,
		"bottom_wu": minf(body.a.y, body.b.y) - body.radius,
		"speed_a_wu_s":
		sqrt(body.a.velocity_x * body.a.velocity_x + body.a.velocity_y * body.a.velocity_y),
		"speed_b_wu_s":
		sqrt(body.b.velocity_x * body.b.velocity_x + body.b.velocity_y * body.b.velocity_y),
		"com_speed_wu_s":
		(
			sqrt(
				(
					(
						(body.a.velocity_x + body.b.velocity_x)
						* (body.a.velocity_x + body.b.velocity_x)
					)
					+ (
						(body.a.velocity_y + body.b.velocity_y)
						* (body.a.velocity_y + body.b.velocity_y)
					)
				)
			)
			/ (TUNING.physics_one + TUNING.physics_one)
		),
		"start_avx": start.a.velocity_x,
		"start_bvx": start.b.velocity_x,
		"start_avy": start.a.velocity_y,
		"start_bvy": start.b.velocity_y,
		"start_ax": start.a.x,
		"start_ay": start.a.y,
		"start_bx": start.b.x,
		"start_by": start.b.y,
		"bottom_start_wu": minf(start.a.y, start.b.y) - body.radius,
	}


func _positions() -> Array:
	var values: Array = []
	for body in bodies:
		values.append([body.a.x, body.a.y, body.b.x, body.b.y])
	return values


func _book_positions(before: Array, ledger: Array, phase: String) -> void:
	var after := _positions()
	for index in range(bodies.size()):
		for coordinate in range(before[index].size()):
			ledger[index][phase][coordinate] += after[index][coordinate] - before[index][coordinate]


func _record_contact(event: Dictionary, part: int, velocity_pass: int, output: Array) -> void:
	event.part = part
	event.velocity_pass = velocity_pass
	output.append(event)
