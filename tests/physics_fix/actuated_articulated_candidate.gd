# gdlint: disable=max-line-length,max-returns
# NEW UNADOPTED articulated block composition; prior failed candidate untouched.
# Original SHA256: fa0c73872d5eb146602a4d085678da1cf88800318752807f0d15c63ef906555b
# Same six/two iteration budgets; rigidity last BEFORE contact; never a final repair.
extends "res://core/sim/actuated_load_probe.gd"
const CONTACT = preload("res://tests/physics_fix/articulated_terrain_candidate.gd")
const NETWORK = preload("res://tests/physics_fix/articulated_mobility_candidate.gd")
var last_step_trace: Dictionary = {}


func _predict_and_project(dt: float, budget: Dictionary, positions: Array) -> Error:
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
		var network := NETWORK.new()
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
	# Position corrections do NOT become velocity impulses or qualifying loads.
	for velocity_pass in range(_tuning.physics_velocity_passes):
		var before_internal := _momentum_y()
		var before_internal_x := _momentum_x()
		if _extra_velocities() != OK:
			return {"status": ERR_INVALID_DATA}
		var network := NETWORK.new()
		if network.configure(bodies, _parents) != OK:
			return {"status": ERR_INVALID_DATA}
		var projected := network.project_velocity(bodies)
		if projected.is_empty():
			push_error("Articulated pre-contact velocity block failure")
			return {"status": ERR_INVALID_DATA}
		_accumulate_hinges(projected.hinge_impulses, hinge_x, hinge_y)
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
		var status := CONTACT.resolve_tick(
			bodies, _parents, _terrain, _mass, lowest, _friction, _restitution, _tuning, recorder
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
		if _finish_velocities() != OK:
			return {"status": ERR_INVALID_DATA}
		# Existing speed cap is still enforced, but an independent endpoint cap
		# must not silently reopen hinge velocity constraints. Reconcile once;
		# if bounds conflict, FAIL rather than add iterations or scale motion.
		if network.configure(bodies, _parents) != OK:
			return {"status": ERR_INVALID_DATA}
		var reconciled := network.project_velocity(bodies)
		if reconciled.is_empty():
			push_error("Articulated post-cap reconciliation failure")
			return {"status": ERR_INVALID_DATA}
		_accumulate_hinges(reconciled.hinge_impulses, hinge_x, hinge_y)
		for body in bodies:
			var axes := PlanarBasis.frame(body)
			if absf(axes.omega) > _tuning.physics_max_angular_velocity_rad_s:
				push_error("Articulated cap/hinge conflict")
				return {"status": ERR_PARAMETER_RANGE_ERROR}
		budget.clamp_impulse_y_ns += _momentum_y() - before_clamp
		budget.clamp_impulse_x_ns += _momentum_x() - before_clamp_x
		for index in range(bodies.size()):
			reaction[index] += bodies[index].measured_reaction_n
			cleanup[index] += bodies[index].positional_cleanup_n
	return {"status": OK, "lowest": lowest}


func _accumulate_hinges(values: Array, x: Array[float], y: Array[float]) -> void:
	for child in range(1, bodies.size()):
		var parent := _parents[child]
		var index := 2 * (child - 1)
		x[child] += values[index]
		y[child] += values[index + 1]
		x[parent] -= values[index]
		y[parent] -= values[index + 1]


func _step(before: Dictionary) -> Dictionary:
	var result := super._step(before)
	last_step_trace = result.duplicate(true)
	return result
