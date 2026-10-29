class_name CreatureTickSolver
extends PointLinkSolver
## FixedStepAccumulator's solver interface, backed by the REAL actuated creature.
## No dummy point solver is stepped. Parent primitive integration is never called.
signal tick_completed(state: Dictionary)
var _rig: SleepingLoadProbe
var _model: CreatureModel
var _tower: TowerData
var _held: int = TUNING.motors_input_released_mask


func configure(model: CreatureModel, tower: TowerData, tuning: Tuning) -> Error:
	if model == null or tower == null or tuning == null:
		return ERR_INVALID_DATA
	var spec := tower.snapshot()
	var grid := tower.terrain(tuning)
	if spec.is_empty() or grid == null:
		return ERR_INVALID_DATA
	var rig := SleepingLoadProbe.new()
	if rig.setup(model, grid, spec.x, spec.y, spec.friction, spec.restitution, tuning, true) != OK:
		return ERR_INVALID_DATA
	_model = model
	_tower = tower
	_tuning = tuning.duplicate(true)
	_rig = rig
	return OK


func fixed_step() -> float:
	return float(TUNING.physics_one) / _tuning.physics_tick_hz


func is_valid() -> bool:
	return _rig != null and _tuning != null


func tick_count() -> int:
	return _rig.snapshot().physical.ticks


func set_input(input_mask: int) -> Error:
	if input_mask < TUNING.motors_input_released_mask or input_mask > TUNING.motors_input_both_mask:
		return ERR_INVALID_PARAMETER
	_held = input_mask
	return OK


func step() -> Error:
	if not is_valid():
		return ERR_UNCONFIGURED
	var row := _rig.step(_held)
	if row.status == OK:
		tick_completed.emit(snapshot())
	return row.status


func snapshot() -> Dictionary:
	if not is_valid():
		return {}
	return {"rig": _rig.snapshot(), "constraints": _rig.constraint_snapshot(), "held": _held}


func restore(state: Dictionary) -> Error:
	if (
		not is_valid()
		or not state.get("rig") is Dictionary
		or not state.get("constraints") is Dictionary
		or not state.get("held") is int
		or state.held < TUNING.motors_input_released_mask
		or state.held > TUNING.motors_input_both_mask
	):
		return ERR_INVALID_DATA
	# Rebuild on detached bodies; failed restore never mutates the live solver.
	var candidate := CreatureTickSolver.new()
	if (
		candidate.configure(_model, _tower, _tuning) != OK
		or candidate._rig.restore(state.rig) != OK
		or candidate._rig.restore_constraints(state.constraints) != OK
	):
		return ERR_INVALID_DATA
	_rig = candidate._rig
	_held = state.held
	return OK
