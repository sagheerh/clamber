# gdlint: disable=max-line-length,max-returns
extends "res://tests/physics_fix/preintegrated_articulated_candidate.gd"
## V14: ONE atomic drag+support constitutive stage; final pass remains original W.
## No upright target, tuning change, extra iteration, sleep edit or energy repair.
const TRIAL_CONTACT = preload("res://tests/physics_fix/constitutive_trial_terrain.gd")
const STAGE_GUARD = preload("res://tests/physics_fix/constitutive_stage_guard.gd")
const SUPPORT_CONTACT = preload("res://tests/physics_fix/impact_history_terrain.gd")
var _constitutive_origin: Array = []
var _constitutive_report: Dictionary = {}


# Defer the existing drag into the coupled stage. Uniform scalar linear damping
# and common gravity commute with it. Controller still executes once before it.
func _apply_authored_angular_damping(_budget: Dictionary) -> Error:
	_drag_hinges = []
	_drag_hinges.resize(2 * (bodies.size() - 1))
	_drag_hinges.fill(0.0)
	_drag_failure = {}
	angular_damping_events = []
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
	if velocity_pass == 0:
		budget.internal_impulse_y_ns += _momentum_y() - before_internal
		budget.internal_impulse_x_ns += _momentum_x() - before_internal_x
		_constitutive_origin = []
		_constitutive_report = {}
		for body in bodies:
			_constitutive_origin.append(body.snapshot())
		var drag: Dictionary = ASSEMBLY_DRAG.apply(
			bodies, _parents, _tuning.physics_angular_damping
		)
		if drag.status != OK:
			return drag
		angular_damping_events = drag.events
		_accumulate_hinges(drag.hinge_impulses, hinge_x, hinge_y)
		budget.damping_impulse_x_ns += drag.external_linear_impulse_x_ns
		budget.damping_impulse_y_ns += drag.external_linear_impulse_y_ns
		var network := _limited_network()
		if network.configure(bodies, _parents) != OK:
			return {"status": ERR_INVALID_DATA}
		certified_velocity = PackedByteArray()
		if (
			_tuning.physics_angular_damping > 0.0
			and network._angular_inequalities(bodies, true).is_empty()
		):
			certified_velocity = _hinge_velocity_key()
	if velocity_pass == 0:
		before_internal = _momentum_y()
		before_internal_x = _momentum_x()
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
	var contact: GDScript = TRIAL_CONTACT if velocity_pass == 0 else SUPPORT_CONTACT
	var status: Dictionary = contact.resolve_tick(
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
		_limit_definitions(),
		before.bodies
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
	if velocity_pass == 0:
		_constitutive_report = STAGE_GUARD.validate(_constitutive_origin, bodies)
		if _constitutive_report.status != OK:
			return _constitutive_report.merged(
				{"phase": "complete drag and support", "work_state": snapshot()}
			)
	# Certify ONLY after successful network terrain response and any real cap
	# reconciliation. This ticket lives for this tick only, never in snapshots.
	certified_velocity = _hinge_velocity_key()
	budget.clamp_impulse_y_ns += _momentum_y() - before_clamp
	budget.clamp_impulse_x_ns += _momentum_x() - before_clamp_x
	for index in range(bodies.size()):
		reaction[index] += bodies[index].measured_reaction_n
		cleanup[index] += bodies[index].positional_cleanup_n
	return {"status": OK, "lowest": lowest, "certified": certified_velocity}


func _step(before: Dictionary) -> Dictionary:
	_constitutive_origin = []
	_constitutive_report = {}
	var result := super._step(before)
	result.support_scope = "single complete dissipative constitutive stage; original strict final contact"
	result.constitutive_stage = _constitutive_report.duplicate(true)
	last_step_trace = result.duplicate(true)
	return result
