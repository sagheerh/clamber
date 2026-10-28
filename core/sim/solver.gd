class_name PointLinkSolver
extends RefCounted
## Independent scalar point/link integrator, NOT the creature Sim or a replay.
const TUNING = preload("res://core/tuning.tres")

var _bodies: Array[SimBody] = []
var _links: Array[DistanceConstraint] = []
var _topology: Array = []
var _tuning: Tuning
var _ticks: int = TUNING.physics_zero


func setup(bodies: Array[SimBody], links: Array[DistanceConstraint], tuning: Tuning) -> Error:
	if not _valid_tuning(tuning) or bodies.is_empty() or bodies.size() > tuning.physics_max_bodies:
		return ERR_INVALID_PARAMETER
	var topology: Array = []
	var seen: Array = []
	for body in bodies:
		if body == null or not body.is_valid() or body in seen:
			return ERR_INVALID_DATA
		seen.append(body)
	seen.clear()
	for link in links:
		if link == null or not link.is_valid() or link in seen:
			return ERR_INVALID_DATA
		if link.body_a not in bodies or link.body_b not in bodies:
			return ERR_INVALID_DATA
		seen.append(link)
		topology.append([bodies.find(link.body_a), bodies.find(link.body_b)])
	_bodies = bodies.duplicate()
	_links = links.duplicate()
	_topology = topology
	_tuning = tuning.duplicate(true)
	_ticks = TUNING.physics_zero
	return OK


func fixed_step() -> float:
	if _tuning == null:
		return TUNING.physics_zero
	return float(_tuning.physics_one) / float(_tuning.physics_tick_hz)


func max_catch_up_steps() -> int:
	return _tuning.physics_max_catch_up_steps if _tuning != null else TUNING.physics_zero


func tick_count() -> int:
	return _ticks


func is_valid() -> bool:
	if not _valid_tuning(_tuning) or _bodies.is_empty() or _ticks < TUNING.physics_zero:
		return false
	if not _bindings_valid():
		return false
	for body in _bodies:
		if not body.is_valid():
			return false
	for link in _links:
		if not link.is_valid():
			return false
	return true


func _bindings_valid() -> bool:
	if _links.size() != _topology.size():
		return false
	for index in range(_links.size()):
		var link := _links[index]
		if link == null:
			return false
		if link.body_a != _bodies[_topology[index][TUNING.physics_zero]]:
			return false
		if link.body_b != _bodies[_topology[index][TUNING.physics_one]]:
			return false
	return true


func step() -> Error:
	if not is_valid() or _ticks + TUNING.physics_one < _ticks:
		return ERR_INVALID_DATA
	var before := snapshot()
	var status := _integrate_tick()
	if status != OK:
		_apply_snapshot(before)
		return status
	_ticks += TUNING.physics_one
	return OK


func snapshot() -> Dictionary:
	if _tuning == null:
		return {}
	var bodies: Array = []
	var links: Array = []
	for body in _bodies:
		bodies.append(body.snapshot())
	for link in _links:
		links.append(link.snapshot())
	return {
		"bodies": bodies,
		"links": links,
		"topology": _topology.duplicate(true),
		"settings": _settings(),
		"ticks": _ticks,
	}


func restore(state: Dictionary) -> Error:
	if (
		_tuning == null
		or not _bindings_valid()
		or state.get("settings") != _settings()
		or state.get("topology") != _topology
	):
		return ERR_INVALID_DATA
	var count: Variant = state.get("ticks")
	if not count is int or count < TUNING.physics_zero:
		return ERR_INVALID_DATA
	var bodies: Variant = state.get("bodies")
	var links: Variant = state.get("links")
	if not bodies is Array or not links is Array:
		return ERR_INVALID_DATA
	if bodies.size() != _bodies.size() or links.size() != _links.size():
		return ERR_INVALID_DATA
	if not _valid_members(bodies, links):
		return ERR_INVALID_DATA
	_apply_snapshot(state)
	return OK


func _valid_members(bodies: Array, links: Array) -> bool:
	# Validate detached candidate points and bindings before publishing any field.
	var probes: Array[SimBody] = []
	for candidate in bodies:
		var probe := SimBody.new()
		if not candidate is Dictionary or probe.restore(candidate) != OK:
			return false
		probes.append(probe)
	for index in range(links.size()):
		var candidate: Variant = links[index]
		if not candidate is Dictionary:
			return false
		for key in ["rest_length", "compliance"]:
			var value: Variant = candidate.get(key)
			if not (value is float or value is int) or not is_finite(float(value)):
				return false
		var probe := DistanceConstraint.new()
		var a := probes[_topology[index][TUNING.physics_zero]]
		var b := probes[_topology[index][TUNING.physics_one]]
		if probe.setup(a, b, candidate.rest_length, candidate.compliance) != OK:
			return false
		if probe.restore(candidate) != OK:
			return false
	return true


func _integrate_tick() -> Error:
	var dt := fixed_step()
	var retention := _tuning.physics_one - _tuning.physics_linear_damping
	for link in _links:
		link.reset_multiplier()
	for body in _bodies:
		body.previous_x = body.x
		body.previous_y = body.y
		if body.inverse_mass == TUNING.physics_zero:
			body.velocity_x = TUNING.physics_zero
			body.velocity_y = TUNING.physics_zero
			continue
		var vx := body.velocity_x * retention
		var vy := (body.velocity_y + _tuning.physics_gravity_wu_s2 * dt) * retention
		if _set_velocity(body, vx, vy) != OK:
			return ERR_INVALID_DATA
		body.x += body.velocity_x * dt
		body.y += body.velocity_y * dt
		if not body.is_valid():
			return ERR_INVALID_DATA
	for iteration in range(_tuning.physics_position_iterations):
		for link in _links:
			for repetition in range(_tuning.physics_distance_solves_per_iteration):
				var status := link.project(_tuning)
				if status != OK:
					return status
	for body in _bodies:
		if body.inverse_mass == TUNING.physics_zero:
			continue
		var vx := (body.x - body.previous_x) / dt
		var vy := (body.y - body.previous_y) / dt
		if _set_velocity(body, vx, vy) != OK:
			return ERR_INVALID_DATA
	return OK


func _set_velocity(body: SimBody, vx: float, vy: float) -> Error:
	var squared_speed := vx * vx + vy * vy
	if not is_finite(squared_speed):
		return ERR_INVALID_DATA
	var limit := _tuning.physics_max_linear_velocity_wu_s
	if squared_speed > limit * limit:
		var scale := limit / sqrt(squared_speed)
		vx *= scale
		vy *= scale
	body.velocity_x = vx
	body.velocity_y = vy
	return OK


func _apply_snapshot(state: Dictionary) -> void:
	# Only called with an entirely validated candidate or trusted pre-tick snapshot.
	for index in range(_bodies.size()):
		_bodies[index].restore(state.bodies[index])
	for index in range(_links.size()):
		_links[index].restore(state.links[index])
	_ticks = state.ticks


func _settings() -> Dictionary:
	return {
		"tick_hz": _tuning.physics_tick_hz,
		"one": _tuning.physics_one,
		"gravity": _tuning.physics_gravity_wu_s2,
		"damping": _tuning.physics_linear_damping,
		"speed_limit": _tuning.physics_max_linear_velocity_wu_s,
		"iterations": _tuning.physics_position_iterations,
		"distance_repeats": _tuning.physics_distance_solves_per_iteration,
		"catch_up_cap": _tuning.physics_max_catch_up_steps,
	}


func _valid_tuning(tuning: Tuning) -> bool:
	if tuning == null:
		return false
	return (
		tuning.physics_tick_hz == TUNING.physics_tick_hz
		and tuning.physics_one == TUNING.physics_one
		and tuning.physics_zero == TUNING.physics_zero
		and tuning.physics_max_bodies > TUNING.physics_zero
		and tuning.physics_position_iterations > TUNING.physics_zero
		and tuning.physics_distance_solves_per_iteration > TUNING.physics_zero
		and tuning.physics_max_catch_up_steps > TUNING.physics_zero
		and is_finite(tuning.physics_gravity_wu_s2)
		and is_finite(tuning.physics_linear_damping)
		and tuning.physics_linear_damping >= TUNING.physics_zero
		and tuning.physics_linear_damping <= TUNING.physics_one
		and is_finite(tuning.physics_max_linear_velocity_wu_s)
		and tuning.physics_max_linear_velocity_wu_s > TUNING.physics_zero
		and is_finite(
			tuning.physics_max_linear_velocity_wu_s * tuning.physics_max_linear_velocity_wu_s
		)
	)
