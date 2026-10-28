class_name FixedStepAccumulator
extends RefCounted
## Outer primitive clock only. No callbacks, engine clocks or creature replay.
const TUNING = preload("res://core/tuning.tres")

var _solver: PointLinkSolver
var _pending: float = TUNING.physics_zero
var _dropped: float = TUNING.physics_zero
var _last_steps: int = TUNING.physics_zero


func setup(solver: PointLinkSolver) -> Error:
	if solver == null or not solver.is_valid():
		return ERR_INVALID_PARAMETER
	_solver = solver
	_pending = TUNING.physics_zero
	_dropped = TUNING.physics_zero
	_last_steps = TUNING.physics_zero
	return OK


func advance(frame_seconds: float) -> Error:
	if not is_valid() or not is_finite(frame_seconds) or frame_seconds < TUNING.physics_zero:
		return ERR_INVALID_DATA
	var total := _pending + frame_seconds
	if not is_finite(total):
		return ERR_INVALID_DATA
	var steps: int = TUNING.physics_zero
	var cap := _solver.max_catch_up_steps()
	var dt := _solver.fixed_step()
	while steps < cap and total >= float(steps + TUNING.physics_one) * dt:
		steps += TUNING.physics_one
	var remaining := total - float(steps) * dt
	var dropped := _dropped
	if steps == cap:
		dropped += remaining
		remaining = TUNING.physics_zero
	if not is_finite(dropped):
		return ERR_INVALID_DATA
	var before := _solver.snapshot()
	for index in range(steps):
		var status := _solver.step()
		if status != OK:
			# The outer call is atomic even if an earlier tick in this frame succeeded.
			_solver.restore(before)
			return status
	_pending = remaining
	_dropped = dropped
	_last_steps = steps
	return OK


func is_valid() -> bool:
	return (
		_solver != null
		and _solver.is_valid()
		and is_finite(_pending)
		and _pending >= TUNING.physics_zero
		and _pending < _solver.fixed_step()
		and is_finite(_dropped)
		and _dropped >= TUNING.physics_zero
		and _last_steps >= TUNING.physics_zero
		and _last_steps <= _solver.max_catch_up_steps()
	)


func snapshot() -> Dictionary:
	if _solver == null:
		return {}
	return {
		"solver": _solver.snapshot(),
		"pending": _pending,
		"dropped": _dropped,
		"last_steps": _last_steps,
	}


func restore(state: Dictionary) -> Error:
	if _solver == null or not state.get("solver") is Dictionary:
		return ERR_INVALID_DATA
	if not _valid_clock_fields(state):
		return ERR_INVALID_DATA
	var status := _solver.restore(state.solver)
	if status != OK:
		return status
	_pending = state.pending
	_dropped = state.dropped
	_last_steps = state.last_steps
	return OK


func _valid_clock_fields(state: Dictionary) -> bool:
	for key in ["pending", "dropped"]:
		var value: Variant = state.get(key)
		if not (value is int or value is float) or not is_finite(float(value)):
			return false
	if state.pending < TUNING.physics_zero or state.pending >= _solver.fixed_step():
		return false
	if state.dropped < TUNING.physics_zero:
		return false
	var steps: Variant = state.get("last_steps")
	if not steps is int or steps < TUNING.physics_zero or steps > _solver.max_catch_up_steps():
		return false
	if steps == _solver.max_catch_up_steps() and state.pending != TUNING.physics_zero:
		return false
	return true
