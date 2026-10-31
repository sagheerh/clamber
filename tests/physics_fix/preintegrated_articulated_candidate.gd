# gdlint: disable=max-line-length,max-returns
extends "res://tests/physics_fix/assembly_damped_candidate.gd"
## UNADOPTED: first of the SAME two contact passes precedes position integration.
## No extra pass/iteration, altered material, position-to-load feedback or sleep rule.
var _stage_order: Array = []


func _step(before: Dictionary) -> Dictionary:
	_stage_order = []
	_drag_hinges = []
	_drag_failure = {}
	angular_damping_events = []
	var result := _step_impl(before)
	if result.status == OK:
		result.diagnostic_mechanics = "R15 awake actuated; NOT public Sim/FA"
		result.input_mask = _input_mask
		result.motor_gain = _tuning.motors_gain_default
		result.drive_events = _drive_events
		result.angular_limit_events = _limit_events
		result.angular_position_events = _position_events
		result.self_contact_events = _self_events
		result.angular_joints = []
		for joint in _joints:
			result.angular_joints.append(joint.state().merged(joint.snapshot()))
		result.self_collision_pairs = _pairs.duplicate(true)
		result.self_impulses_ns = _self_impulses.duplicate(true)
	else:
		if not result.has("work_state"):
			result.work_state = snapshot()
	result.authored_angular_damping = angular_damping_events.duplicate(true)
	result.stage_order = _stage_order.duplicate()
	if not _drag_failure.is_empty():
		result.drag_failure = _drag_failure.duplicate(true)
		result.work_state = snapshot()
	result.angular_drag_scope = "same V9 constrained angular fraction; pre-integration contact dependency candidate"
	last_step_trace = result.duplicate(true)
	return result


func _step_impl(before: Dictionary) -> Dictionary:
	if _tuning.physics_velocity_passes != 2 or _tuning.physics_position_iterations != 6:
		return {"status": ERR_INVALID_DATA, "reason": "registered two/six budget required"}
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
		"momentum_before_x_ns": _momentum_x(),
		"drive_internal_impulse_x_ns": float(TUNING.physics_zero),
		"drive_internal_impulse_y_ns": float(TUNING.physics_zero),
		"damping_impulse_x_ns": float(TUNING.physics_zero),
		"gravity_impulse_x_ns": float(TUNING.physics_zero),
		"clamp_impulse_x_ns": float(TUNING.physics_zero),
		"internal_impulse_x_ns": float(TUNING.physics_zero),
		"contact_velocity_impulse_x_ns": float(TUNING.physics_zero),
		"damping_impulse_y_ns": float(TUNING.physics_zero),
		"gravity_impulse_y_ns": float(TUNING.physics_zero),
		"clamp_impulse_y_ns": float(TUNING.physics_zero),
		"internal_impulse_y_ns": float(TUNING.physics_zero),
		"contact_velocity_impulse_y_ns": float(TUNING.physics_zero),
	}
	_contact_counts = []
	_contact_batches = []
	var started := _begin_tick()
	if started != OK:
		return {"status": started}
	# R18 observation only: read COM change from the existing pre-integration drive.
	budget.drive_internal_impulse_x_ns = _momentum_x() - budget.momentum_before_x_ns
	budget.drive_internal_impulse_y_ns = _momentum_y() - budget.momentum_before_y_ns
	var positions: Array = []
	for body in bodies:
		var phases := {}
		for phase in position_phases():
			phases[phase] = [
				float(TUNING.physics_zero),
				float(TUNING.physics_zero),
				float(TUNING.physics_zero),
				float(TUNING.physics_zero)
			]
		positions.append(phases)
	var forced := _apply_forces(dt, budget)
	if forced != OK:
		return {"status": forced, "phase": "forces"}
	_accumulate_hinges(_drag_hinges, hinge_x, hinge_y)
	_drag_hinges = []
	var contact_samples: Array = []
	var response := _velocity_pass(
		before,
		hinge_x,
		hinge_y,
		reaction,
		cleanup,
		budget,
		positions,
		contact_samples,
		0,
		PackedByteArray()
	)
	if response.status != OK:
		return response
	var projected := _integrate_and_project(dt, positions)
	if projected != OK:
		return {"status": projected, "phase": "position"}
	response = _velocity_pass(
		before,
		hinge_x,
		hinge_y,
		reaction,
		cleanup,
		budget,
		positions,
		contact_samples,
		1,
		response.certified
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


func _apply_forces(dt: float, budget: Dictionary) -> Error:
	_stage_order.append("forces")
	angular_damping_events = []
	var damping_status := _apply_authored_angular_damping(budget)
	if damping_status != OK:
		return damping_status
	if collect_length_phases:
		length_phases = {}
		length_phase_tick = _ticks
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
	return OK


func _integrate_and_project(dt: float, positions: Array) -> Error:
	_stage_order.append("integration")
	var before_integration := _positions()
	for body in bodies:
		for point in [body.a, body.b]:
			point.x += point.velocity_x * dt
			point.y += point.velocity_y * dt
	_book_positions(before_integration, positions, "integration")
	_record_length_phase("after_integration")
	for link in _links:
		link.reset_multiplier()
	for iteration in range(_tuning.physics_position_iterations):
		_stage_order.append("position_sweep_%d" % iteration)
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


func _velocity_pass(
	before: Dictionary,
	hinge_x: Array[float],
	hinge_y: Array[float],
	reaction: Array[float],
	cleanup: Array[float],
	budget: Dictionary,
	positions: Array,
	contact_samples: Array,
	velocity_pass: int,
	certified_velocity: PackedByteArray
) -> Dictionary:
	var dt := float(TUNING.physics_one) / _tuning.physics_tick_hz
	_stage_order.append("velocity_pass_%d" % velocity_pass)
	var lowest: Array[bool] = []
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
	return {"status": OK, "lowest": lowest, "certified": certified_velocity}
