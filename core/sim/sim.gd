class_name Sim
extends RefCounted
## Public headless creature composition. Existing M0 method signatures preserved.
## Checked outcomes: last_status + failed signal; advance_frame returns explicit status.
signal tick_completed(state: Dictionary)
signal failed(status: Error)
const TUNING = preload("res://core/tuning.tres")
var last_status: Error = ERR_UNCONFIGURED
var _solver: CreatureTickSolver
var _clock: FixedStepAccumulator
var _rng: Xoshiro128StarStar
var _creature: CreatureModel
var _tower: TowerData
var _tuning: Tuning
var _identity: Dictionary = {}
var _frame_ticks: Array = []


func setup(creature: CreatureModel, tower: TowerData, seed: int, tuning: Tuning) -> void:
	last_status = _configure(creature, tower, seed, tuning)
	if last_status != OK:
		failed.emit(last_status)


func _configure(creature: CreatureModel, tower: TowerData, seed: int, tuning: Tuning) -> Error:
	if creature == null or tower == null or tuning == null:
		return ERR_INVALID_DATA
	var model := CreatureModel.new()
	if model.configure(creature.definition(), tuning) != OK:
		return ERR_INVALID_DATA
	var data := tower.snapshot()
	var grid := tower.terrain(tuning)
	var copy := TowerData.new()
	if data.is_empty() or grid == null:
		return ERR_INVALID_DATA
	if copy.configure(grid, data.x, data.y, data.friction, data.restitution, tuning) != OK:
		return ERR_INVALID_DATA
	var solver := CreatureTickSolver.new()
	var clock := FixedStepAccumulator.new()
	if solver.configure(model, copy, tuning) != OK or clock.setup(solver) != OK:
		return ERR_INVALID_DATA
	var rng := Xoshiro128StarStar.new()
	rng.configure(seed)
	_creature = model
	_tower = copy
	_tuning = tuning.duplicate(true)
	_solver = solver
	_clock = clock
	_rng = rng
	_identity = {"creature": model.definition(), "tower": copy.snapshot(), "tuning": _settings()}
	_solver.tick_completed.connect(_record_tick)
	return OK


func step(input_mask: int) -> void:
	if _solver == null:
		last_status = ERR_UNCONFIGURED
		failed.emit(last_status)
		return
	advance_frame(_solver.fixed_step(), input_mask)


func advance_frame(frame_seconds: float, input_mask: int) -> Dictionary:
	if _solver == null:
		last_status = ERR_UNCONFIGURED
		failed.emit(last_status)
		return {"status": last_status}
	var before := snapshot()
	last_status = _solver.set_input(input_mask)
	if last_status == OK:
		_frame_ticks = []
		last_status = _clock.advance(frame_seconds)
	if last_status != OK:
		var original := last_status
		var rollback := _restore(before)
		last_status = original if rollback == OK else rollback
		_frame_ticks = []
		failed.emit(last_status)
		return {"status": last_status, "rollback_failed": rollback != OK}
	# Publish only after frame commit. No partial-frame signals escape a rollback.
	for state in _frame_ticks:
		tick_completed.emit(state.duplicate(true))
	var clock_state := _clock.snapshot()
	return {
		"status": OK,
		"steps": clock_state.last_steps,
		"pending": clock_state.pending,
		"dropped": clock_state.dropped,
		"ticks": _solver.tick_count()
	}


func _record_tick(state: Dictionary) -> void:
	_frame_ticks.append({"solver": state.duplicate(true), "rng": _rng.snapshot()})


func get_render_state() -> Array:
	return _solver.snapshot().rig.physical.bodies if _solver != null else []


func get_brace_state() -> Array:
	# Phase4 presentation: distinct planted joint cue; never inferred from sleep.
	return _solver.snapshot().rig.physical.angular_joints if _solver != null else []


func snapshot() -> Dictionary:
	if _clock == null:
		return {}
	return {
		"identity": _identity.duplicate(true),
		"accumulator": _clock.snapshot(),
		"rng": _rng.snapshot()
	}


func restore(s: Dictionary) -> void:
	last_status = _restore(s)
	if last_status != OK:
		failed.emit(last_status)


func _restore(state: Dictionary) -> Error:
	if (
		_clock == null
		or state.get("identity") != _identity
		or not state.get("rng") is Array
		or not state.get("accumulator") is Dictionary
	):
		return ERR_INVALID_DATA
	var solver := CreatureTickSolver.new()
	var clock := FixedStepAccumulator.new()
	var rng := Xoshiro128StarStar.new()
	if (
		solver.configure(_creature, _tower, _tuning) != OK
		or clock.setup(solver) != OK
		or clock.restore(state.accumulator) != OK
		or rng.restore(state.rng) != OK
	):
		return ERR_INVALID_DATA
	_solver = solver
	_clock = clock
	_rng = rng
	_solver.tick_completed.connect(_record_tick)
	return OK


func state_hash() -> int:
	return hash(var_to_bytes(snapshot()))


func state_digest() -> String:
	return digest(snapshot())


static func digest(state: Dictionary) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(var_to_bytes(state))
	return context.finish().hex_encode()


func result() -> RunResult:
	if _solver == null:
		return null
	var value := RunResult.new()
	var state := _solver.snapshot()
	value.configure(
		{
			"ticks": state.rig.physical.ticks,
			"sleep": state.rig.sleep,
			"physics_digest": digest(state),
			"scope": "physics only; score/flags not implemented"
		}
	)
	return value


func _settings() -> Dictionary:
	var settings := {}
	for property in _tuning.get_property_list():
		var key: String = property.name
		if key.begins_with("physics_") or key.begins_with("motors_") or key.begins_with("sleep_"):
			settings[key] = _tuning.get(key)
	return settings
