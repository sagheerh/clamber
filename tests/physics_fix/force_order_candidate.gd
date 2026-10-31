# gdlint: disable=max-line-length,max-returns
extends "res://tests/physics_fix/preintegrated_articulated_candidate.gd"
## UNADOPTED: existing angular/linear loss applies to old motion, not fresh drive.
## Same controller/material/coefficients, two velocity passes and six sweeps.


func _begin_tick() -> Error:
	# The original reset/controller door executes ONCE below, after damping.
	# No input suppression, precomputed force, hidden clock or changed motor law.
	return OK


func _apply_forces(dt: float, budget: Dictionary) -> Error:
	_stage_order.append("angular_damping")
	_force_certificate = PackedByteArray()
	var uniform := true
	for body in bodies:
		for point in [body.a, body.b]:
			uniform = (
				uniform
				and point.velocity_x == bodies[0].a.velocity_x
				and point.velocity_y == bodies[0].a.velocity_y
			)
	# D>0 publishes canonical tree/rod velocities; d0 is identity, not projection.
	var canonical: bool = _tuning.physics_angular_damping > 0.0 or uniform
	var capped := false
	angular_damping_events = []
	var damping_status := _apply_authored_angular_damping(budget)
	if damping_status != OK:
		return damping_status
	if collect_length_phases:
		length_phases = {}
		length_phase_tick = _ticks
	_stage_order.append("linear_damping")
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
			point.velocity_y = damped
	# All authored damping acts on OLD motion. The original controller samples
	# this current state and applies its full fresh impulse, just as gravity does.
	var before_drive := _hinge_velocity_key()
	var drive_x := _momentum_x()
	var drive_y := _momentum_y()
	_stage_order.append("drive")
	var driven: Error = super._begin_tick()
	if driven != OK:
		return driven
	budget.drive_internal_impulse_x_ns += _momentum_x() - drive_x
	budget.drive_internal_impulse_y_ns += _momentum_y() - drive_y
	var drive_identity: bool = before_drive == _hinge_velocity_key()
	_stage_order.append("gravity")
	for body in bodies:
		for point in [body.a, body.b]:
			var mass: float = float(TUNING.physics_one) / point.inverse_mass
			point.velocity_y += _tuning.physics_gravity_wu_s2 * dt
			budget.gravity_impulse_y_ns += mass * _tuning.physics_gravity_wu_s2 * dt
			var before_clamp: float = point.velocity_y
			var before_clamp_x: float = point.velocity_x
			if not _clamp_velocity(point):
				return ERR_INVALID_DATA
			capped = (
				capped or point.velocity_x != before_clamp_x or point.velocity_y != before_clamp
			)
			budget.clamp_impulse_y_ns += mass * (point.velocity_y - before_clamp)
			budget.clamp_impulse_x_ns += mass * (point.velocity_x - before_clamp_x)
	# Uniform scalar linear loss and common gravity preserve rigid/hinge velocity
	# compatibility. Never certify an actual point cap, a d0 nonrigid input, or an
	# angular boundary. Consumer still validates tree/masses/geometry and the full
	# exact key AFTER angular/self-contact work; any edit invalidates this witness.
	var network := _limited_network()
	if network.configure(bodies, _parents) != OK:
		return ERR_INVALID_DATA
	if (
		canonical
		and drive_identity
		and not capped
		and network._angular_inequalities(bodies, true).is_empty()
	):
		_force_certificate = _hinge_velocity_key()
	return OK


func _step(before: Dictionary) -> Dictionary:
	var result := super._step(before)
	result.force_order_scope = "existing-motion loss THEN original fresh motor and gravity; no gain/target change"
	last_step_trace = result.duplicate(true)
	return result
