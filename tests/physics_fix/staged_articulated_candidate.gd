# gdlint: disable=max-line-length,max-returns
extends "res://tests/physics_fix/actuated_articulated_candidate.gd"
## UNADOPTED stage-dependency correction. Old rejected candidate is unchanged.
## No epsilon, energy guard change, added iteration, or cross-tick hidden state.
const STAGED_CONTACT = preload("res://tests/physics_fix/staged_terrain_candidate.gd")


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
		var status := STAGED_CONTACT.resolve_tick(
			bodies,
			_parents,
			_terrain,
			_mass,
			lowest,
			_friction,
			_restitution,
			_tuning,
			recorder,
			_hinge_velocity_key()
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


func _hinge_velocity_key() -> PackedByteArray:
	var key := PackedFloat64Array()
	for i in range(bodies.size()):
		var body := bodies[i]
		key.append_array(
			PackedFloat64Array(
				[
					float(_parents[i]),
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


func _project_changed_velocity(
	certified: PackedByteArray, hinge_x: Array[float], hinge_y: Array[float]
) -> Error:
	# Never bypass tree, alias, geometry, mass or finite-state validation.
	var network := NETWORK.new()
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
