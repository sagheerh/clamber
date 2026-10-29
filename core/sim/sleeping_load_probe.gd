class_name SleepingLoadProbe
extends RefCounted
## Engineering composition, NOT public Sim. Awake CoupledLoadProbe remains unchanged.
## Sleeping rows never pretend parked/stale forces are a fresh awake force budget.
const TUNING = preload("res://core/tuning.tres")
var _probe: CoupledLoadProbe = CoupledLoadProbe.new()
var _sleep := CreatureSleep.new()
var _terrain: SdfGrid
var _mass: float
var _tuning: Tuning
var _friction: Array[float] = []
var _restitution: Array[float] = []


func setup(
	model: CreatureModel,
	terrain: SdfGrid,
	x: float,
	y: float,
	friction: Array[float],
	restitution: Array[float],
	tuning: Tuning,
	actuated: bool = false,
	brace_enabled: bool = true
) -> Error:
	var probe: CoupledLoadProbe = ActuatedLoadProbe.new() if actuated else CoupledLoadProbe.new()
	var sleep := CreatureSleep.new()
	if actuated:
		(probe as ActuatedLoadProbe).brace_enabled = brace_enabled
	if (
		probe.setup(model, terrain, x, y, friction, restitution, tuning) != OK
		or sleep.configure(tuning) != OK
	):
		return ERR_INVALID_DATA
	_probe = probe
	_sleep = sleep
	_terrain = terrain
	_mass = model.total_mass()
	_tuning = tuning.duplicate(true)
	_friction = friction.duplicate()
	_restitution = restitution.duplicate()
	return OK


func snapshot() -> Dictionary:
	return {"physical": _probe.snapshot(), "sleep": _sleep.snapshot()}


func restore(state: Dictionary) -> Error:
	if (
		_tuning == null
		or not state.get("sleep") is Dictionary
		or not state.get("physical") is Dictionary
	):
		return ERR_INVALID_DATA
	var sleep := CreatureSleep.new()
	if sleep.configure(_tuning) != OK or sleep.restore(state.sleep) != OK:
		return ERR_INVALID_DATA
	var physical: Dictionary = state.physical
	if not physical.get("ticks") is int or not physical.get("bodies") is Array:
		return ERR_INVALID_DATA
	if (
		sleep.last_sleep_tick >= physical.ticks
		or sleep.last_wake_tick >= physical.ticks
		or (sleep.asleep and not _parked_velocities(physical.bodies))
		or not _origin_matches(state.sleep.dwell_start, physical.bodies)
	):
		return ERR_INVALID_DATA
	var status := _probe.restore(physical)
	if status != OK:
		return status
	_sleep = sleep
	return OK


func step(input_mask: int) -> Dictionary:
	if _tuning == null:
		return {"status": ERR_UNCONFIGURED}
	if input_mask < TUNING.motors_input_released_mask or input_mask > TUNING.motors_input_both_mask:
		return {"status": ERR_INVALID_PARAMETER}
	var before := snapshot()
	var result := _advance(before, input_mask)
	if result.status != OK:
		var rollback := restore(before)
		if rollback != OK:
			return {"status": rollback, "rollback_failed": true}
	return result


func _advance(before: Dictionary, input_mask: int) -> Dictionary:
	var tick: int = before.physical.ticks
	var wake_reason := ""
	var new_grounded: Array = []
	if input_mask != TUNING.motors_input_released_mask:
		if _sleep.asleep:
			wake_reason = "input"
		_sleep.wake(tick)
	if _sleep.asleep:
		# Existing contact resolver on DETACHED clones; no parked-body impulses/motion.
		var query := _grounded_query(before.physical.bodies)
		if query.status != OK:
			return query
		for index in range(query.grounded.size()):
			if query.grounded[index] and not before.physical.bodies[index].grounded:
				new_grounded.append(index)
		if not new_grounded.is_empty():
			_sleep.wake(tick)
			wake_reason = "new_grounded"
		else:
			var parked: Dictionary = before.physical.duplicate(true)
			parked.ticks += TUNING.physics_one
			for index in range(parked.bodies.size()):
				parked.bodies[index].grounded = query.grounded[index]
				if not query.grounded[index]:
					parked.bodies[index].gripping = false
			if _probe.restore(parked) != OK:
				return {"status": ERR_INVALID_DATA}
			_sleep.max_body_com_displacement_wu = TUNING.physics_zero
			return _row(tick, input_mask, wake_reason, new_grounded)
	var trace := (
		(_probe as ActuatedLoadProbe).advance(input_mask)
		if _probe is ActuatedLoadProbe
		else _probe.step()
	)
	if trace.status != OK:
		return trace
	var after := _probe.snapshot()
	if _sleep.observe(before.physical.bodies, after.bodies, input_mask, tick) != OK:
		return {"status": ERR_INVALID_DATA}
	if _sleep.asleep:
		for body in _probe.bodies:
			for point in [body.a, body.b]:
				point.velocity_x = TUNING.physics_zero
				point.velocity_y = TUNING.physics_zero
	var row := _row(tick, input_mask, wake_reason, new_grounded)
	# Explicitly PRE parking: do not mislabel the velocity-zeroing as contact impulse.
	row.awake_solver_trace_before_sleep_parking = trace
	return row


func _row(tick: int, input_mask: int, reason: String, new_grounded: Array) -> Dictionary:
	return {
		"status": OK,
		"tick": tick,
		"input_mask": input_mask,
		"sleep_state": "asleep" if _sleep.asleep else "awake",
		"sleep_implemented": true,
		"sleep": _sleep.snapshot(),
		"wake_reason": reason,
		"sleep_breaking_new_grounded_parts": new_grounded,
		"state": snapshot()
	}


func _grounded_query(states: Array) -> Dictionary:
	var shadows: Array[CapsuleBody] = []
	for state in states:
		var body := CapsuleBody.new()
		if body.restore(state) != OK:
			return {"status": ERR_INVALID_DATA}
		shadows.append(body)
	var status := CapsuleContact.resolve_tick(
		shadows,
		_terrain,
		_mass,
		CoupledLoadProbe.lowest_mask(shadows, _tuning),
		_friction,
		_restitution,
		_tuning
	)
	if status != OK:
		return {"status": status}
	var grounded: Array = []
	for body in shadows:
		grounded.append(body.grounded)
	return {"status": OK, "grounded": grounded}


func _parked_velocities(states: Array) -> bool:
	for body in states:
		if not body is Dictionary:
			return false
		for end in ["a", "b"]:
			if (
				not body.get(end) is Dictionary
				or body[end].get("velocity_x") != TUNING.physics_zero
				or body[end].get("velocity_y") != TUNING.physics_zero
			):
				return false
	return true


func constraint_snapshot() -> Dictionary:
	return _probe.constraint_snapshot()


func restore_constraints(state: Dictionary) -> Error:
	return _probe.restore_constraints(state)


func _origin_matches(origin: Array, bodies: Array) -> bool:
	# Same ordered creature, not another body set. No added numeric threshold.
	if origin.is_empty():
		return true
	if origin.size() != bodies.size():
		return false
	for index in range(origin.size()):
		if not bodies[index] is Dictionary:
			return false
		for key in ["kind", "mass", "radius", "length"]:
			if origin[index][key] != bodies[index].get(key):
				return false
	return true
