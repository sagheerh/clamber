# gdlint: disable=max-line-length,max-returns
extends Sim
## Test-only factories. Inherited PUBLIC advance_frame, signals, accumulator,
## sleeping/awake implementation and codecs are not replaced. Base Sim's hardcoded
## restore factories otherwise silently swap candidate physics back to baseline.
const AWAKE = preload("res://tests/physics_fix/final_geometry_constitutive_candidate.gd")
var fail_at_tick := -1  # Explicit test fault; NOT serialized physical state.
var last_failure: Dictionary = {}


class CandidateSolver:
	extends CreatureTickSolver
	var fail_at_tick := -1
	var last_row: Dictionary = {}
	var last_failure: Dictionary = {}

	func configure(model: CreatureModel, tower: TowerData, tuning: Tuning) -> Error:
		if super.configure(model, tower, tuning) != OK:
			return ERR_INVALID_DATA
		var spec := tower.snapshot()
		var probe := AWAKE.new()
		if (
			probe.setup(
				model,
				tower.terrain(tuning),
				spec.x,
				spec.y,
				spec.friction,
				spec.restitution,
				tuning
			)
			!= OK
		):
			return ERR_INVALID_DATA
		probe.collect_contact_samples = true
		_rig._probe = probe
		return OK

	func restore(state: Dictionary) -> Error:
		if (
			not is_valid()
			or not state.get("rig") is Dictionary
			or not state.get("constraints") is Dictionary
			or not state.get("held") is int
			or state.held < 0
			or state.held > 3
		):
			return ERR_INVALID_DATA
		var candidate := CandidateSolver.new()
		if (
			candidate.configure(_model, _tower, _tuning) != OK
			or candidate._rig.restore(state.rig) != OK
			or candidate._rig.restore_constraints(state.constraints) != OK
		):
			return ERR_INVALID_DATA
		_rig = candidate._rig
		_held = state.held
		last_row = {}
		return OK

	func step() -> Error:
		if not is_valid():
			return ERR_UNCONFIGURED
		if tick_count() == fail_at_tick:
			# Deliberately corrupt live physics before failing: proves actual rollback,
			# not merely rejection of a bad argument before anything changes.
			_rig._probe.bodies[0].a.velocity_x += 2.0
			return ERR_INVALID_DATA
		last_row = _rig.step(_held)
		if last_row.status == OK:
			tick_completed.emit(snapshot())
		else:
			last_failure = {
				"mask": _held,
				"tick": tick_count(),
				"awake_trace": _rig._probe.last_step_trace.duplicate(true)
			}
		return last_row.status


func _configure(creature: CreatureModel, tower: TowerData, seed: int, tuning: Tuning) -> Error:
	var status := super._configure(creature, tower, seed, tuning)
	if status != OK:
		return status
	# Never restore the BASELINE initial snapshot onto a new candidate: that
	# overwrites its radius-derived toe placement with cardinal baseline geometry.
	var solver := CandidateSolver.new()
	var clock := FixedStepAccumulator.new()
	if solver.configure(_creature, _tower, _tuning) != OK or clock.setup(solver) != OK:
		return ERR_INVALID_DATA
	_solver = solver
	_clock = clock
	_identity["test_only_candidate_recipe"] = AWAKE.resource_path
	_solver.tick_completed.connect(_record_tick)
	return OK


func _restore(state: Dictionary) -> Error:
	if (
		_clock == null
		or state.get("identity") != _identity
		or not state.get("rng") is Array
		or not state.get("accumulator") is Dictionary
	):
		return ERR_INVALID_DATA
	if _solver is CandidateSolver and not (_solver as CandidateSolver).last_failure.is_empty():
		last_failure = {
			"before_frame": state.duplicate(true),
			"failed": (_solver as CandidateSolver).last_failure.duplicate(true)
		}
	var solver := CandidateSolver.new()
	solver.fail_at_tick = fail_at_tick
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


func candidate_survives() -> bool:
	return (
		_solver is CandidateSolver
		and _solver._rig._probe.get_script() == AWAKE
		and _clock._solver == _solver
	)


func last_row() -> Dictionary:
	return (_solver as CandidateSolver).last_row


func inject_failure(tick: int) -> void:
	fail_at_tick = tick
	(_solver as CandidateSolver).fail_at_tick = tick
