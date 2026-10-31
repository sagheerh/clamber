# gdlint: disable=max-line-length,max-returns
extends "res://tests/physics_fix/damped_staged_articulated_candidate.gd"
## NEW UNADOPTED coupled angular/hinge/contact inequality composition.
## Original six/two sweeps, loads, sleep and authored damping interpretation.
const LIMITED_NETWORK = preload("res://tests/physics_fix/limited_articulated_mobility_candidate.gd")
const LIMITED_CONTACT = preload("res://tests/physics_fix/limited_terrain_candidate.gd")


func _limit_definitions() -> Array:
	var result: Array = []
	for joint in _joints:
		result.append(
			{
				"parent": bodies.find(joint.parent_body),
				"child": bodies.find(joint.child_body),
				"rest_angle": joint.rest_angle,
				"lower": joint.lower,
				"upper": joint.upper
			}
		)
	return result


func _limited_network() -> LIMITED_NETWORK:
	var network := LIMITED_NETWORK.new()
	network.limits = _limit_definitions()
	return network


func _hinge_velocity_key() -> PackedByteArray:
	return super._hinge_velocity_key() + var_to_bytes(_limit_definitions())


func _predict_and_project(dt: float, budget: Dictionary, positions: Array) -> Error:
	angular_damping_events = []
	var damping_status := _apply_authored_angular_damping(budget)
	if damping_status != OK:
		return damping_status
	if collect_length_phases:
		length_phases = {}
		length_phase_tick = _ticks
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
			var before_damping_x: float = point.velocity_x
			point.velocity_x *= retention
			budget.damping_impulse_x_ns += mass * (point.velocity_x - before_damping_x)
			point.velocity_y = damped + _tuning.physics_gravity_wu_s2 * dt
			budget.gravity_impulse_y_ns += mass * _tuning.physics_gravity_wu_s2 * dt
			var before_clamp: float = point.velocity_y
			var before_clamp_x: float = point.velocity_x
			if not _clamp_velocity(point):
				return ERR_INVALID_DATA
			budget.clamp_impulse_y_ns += mass * (point.velocity_y - before_clamp)
			budget.clamp_impulse_x_ns += mass * (point.velocity_x - before_clamp_x)
			point.x += point.velocity_x * dt
			point.y += point.velocity_y * dt
	_book_positions(before_integration, positions, "integration")
	_record_length_phase("after_integration")
	for link in _links:
		link.reset_multiplier()
	for iteration in range(_tuning.physics_position_iterations):
		var before_distance := _positions()
		for link in _links:
			for repetition in range(_tuning.physics_distance_solves_per_iteration):
				if link.project(_tuning) != OK:
					return ERR_INVALID_DATA
		_book_positions(before_distance, positions, "distance")
		_record_length_phase("after_iteration_distance")
		var extra := _extra_positions(positions)
		if extra != OK:
			return extra
		var before_hinge := _positions()
		var network := _limited_network()
		if (
			network.configure(bodies, _parents) != OK
			or network.project_hinge_positions(bodies, _parents, _tuning).is_empty()
		):
			push_error("Articulated position block failure")
			return ERR_INVALID_DATA
		_book_positions(before_hinge, positions, "hinge")
		_record_length_phase("after_final_hinge")
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
	var certified_velocity := PackedByteArray()
	# Position corrections do NOT become velocity impulses or qualifying loads.
	for velocity_pass in range(_tuning.physics_velocity_passes):
		var before_internal := _momentum_y()
		var before_internal_x := _momentum_x()
		if _extra_velocities() != OK:
			return {"status": ERR_INVALID_DATA}
		var projection := _project_changed_velocity(certified_velocity, hinge_x, hinge_y)
		if projection != OK:
			return {
				"status": projection,
				"phase": "pre-contact hinge velocity",
				"velocity_pass": velocity_pass,
				"work_state": snapshot()
			}
		budget.internal_impulse_y_ns += _momentum_y() - before_internal
		budget.internal_impulse_x_ns += _momentum_x() - before_internal_x
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
			var extra := _body_impulse(index)
			var external_x: float = hinge_x[index] + extra.x
			var external_y: float = (
				body.mass * _tuning.physics_gravity_wu_s2 * dt + hinge_y[index] + extra.y
			)
			body.applied_load_n = maxf(
				TUNING.physics_zero, -(external_x * normal.nx + external_y * normal.ny) / dt
			)
		lowest = lowest_mask(bodies, _tuning)
		# Detached observation ONLY; no values fed into physics. FA5 independently
		# reconstructs frozen N, geometry eligibility and real hinge/load provenance.
		if collect_contact_samples:
			var parts: Array = []
			for index in range(bodies.size()):
				var body := bodies[index]
				parts.append(
					{
						"part": index,
						"bottom_wu": minf(body.a.y, body.b.y) - body.radius,
						"a": [body.a.x, body.a.y],
						"b": [body.b.x, body.b.y],
						"normal": _terrain.sample(body.a.x, body.a.y),
						"applied_load_n": body.applied_load_n,
						"hinge_x_ns": hinge_x[index],
						"hinge_y_ns": hinge_y[index],
						"extra": _body_impulse(index).duplicate(true),
						"lowest": lowest[index]
					}
				)
			_contact_batches.append({"velocity_pass": velocity_pass, "parts": parts})
		var before_contact := _momentum_y()
		var before_contact_x := _momentum_x()
		var before_contact_positions := _positions()
		var recorder := _record_contact.bind(velocity_pass, contact_samples)
		var status := LIMITED_CONTACT.resolve_tick(
			bodies,
			_parents,
			_terrain,
			_mass,
			lowest,
			_friction,
			_restitution,
			_tuning,
			recorder,
			_hinge_velocity_key(),
			_limit_definitions()
		)
		if status.status != OK:
			push_error("Articulated contact failure: " + JSON.stringify(status, "", true, true))
			return status
		_accumulate_hinges(status.hinge_impulses, hinge_x, hinge_y)
		_book_positions(before_contact_positions, positions, "contact")
		_record_length_phase("after_contact_pass_%d" % velocity_pass)
		budget.contact_velocity_impulse_y_ns += _momentum_y() - before_contact
		budget.contact_velocity_impulse_x_ns += _momentum_x() - before_contact_x
		var before_clamp := _momentum_y()
		var before_clamp_x := _momentum_x()
		var cap_input: Dictionary = snapshot() if collect_contact_samples else {}
		var cap_status := _finish_network_caps(hinge_x, hinge_y)
		if cap_status != OK:
			return {
				"status": cap_status,
				"phase": "active-cap reconciliation",
				"velocity_pass": velocity_pass,
				"cap_input": cap_input,
				"work_state": snapshot()
			}
		# Certify ONLY after successful network terrain response and any real cap
		# reconciliation. This ticket lives for this tick only, never in snapshots.
		certified_velocity = _hinge_velocity_key()
		budget.clamp_impulse_y_ns += _momentum_y() - before_clamp
		budget.clamp_impulse_x_ns += _momentum_x() - before_clamp_x
		for index in range(bodies.size()):
			reaction[index] += bodies[index].measured_reaction_n
			cleanup[index] += bodies[index].positional_cleanup_n
	return {"status": OK, "lowest": lowest}


func _project_changed_velocity(
	certified: PackedByteArray, hinge_x: Array[float], hinge_y: Array[float]
) -> Error:
	# Never bypass tree, alias, geometry, mass or finite-state validation.
	var network := _limited_network()
	if network.configure(bodies, _parents) != OK:
		return ERR_INVALID_DATA
	# A successful constrained contact/cap stage already published this EXACT
	# geometry+velocity. If angular/self-contact rows did nothing, a second
	# projection is mathematically identity, not a new physical impulse.
	if not certified.is_empty() and certified == _hinge_velocity_key():
		return OK
	var projected := network.project_velocity(bodies)
	if projected.is_empty():
		return ERR_INVALID_DATA
	_accumulate_hinges(projected.hinge_impulses, hinge_x, hinge_y)
	return OK


func _finish_network_caps(hinge_x: Array[float], hinge_y: Array[float]) -> Error:
	# With no active cap this stage is the identity, NOT another hinge solve.
	# Contact already used constrained mobility. Do not repeatedly project its
	# roundoff residual, or attribute those numerical impulses to a speed cap.
	if not _angular_cap_required():
		return OK
	if _finish_velocities() != OK:
		return ERR_INVALID_DATA
	# An ACTUAL independent angular cap can reopen hinge velocity constraints.
	# Reconcile once; retain all original strict guards and fail on conflict.
	var network := _limited_network()
	if network.configure(bodies, _parents) != OK:
		return ERR_INVALID_DATA
	var reconciled := network.project_velocity(bodies)
	if reconciled.is_empty():
		push_error("Articulated post-cap reconciliation failure")
		return ERR_INVALID_DATA
	_accumulate_hinges(reconciled.hinge_impulses, hinge_x, hinge_y)
	if _angular_cap_required():
		push_error("Articulated cap/hinge conflict")
		return ERR_PARAMETER_RANGE_ERROR
	return OK
