# gdlint: disable=max-line-length
extends "res://tests/physics_fix/limited_actuated_candidate.gd"
## UNADOPTED angular DOF damping; same existing stage/order, six/two sweeps.
const ASSEMBLY_DRAG = preload("res://tests/physics_fix/articulated_angular_drag.gd")
var _drag_hinges: Array = []
var _drag_failure: Dictionary = {}


func _apply_authored_angular_damping(budget: Dictionary) -> Error:
	_drag_hinges = []
	_drag_failure = {}
	var result := ASSEMBLY_DRAG.apply(bodies, _parents, _tuning.physics_angular_damping)
	if result.status != OK:
		_drag_failure = result
		return result.status
	angular_damping_events = result.events
	_drag_hinges = result.hinge_impulses
	budget.damping_impulse_x_ns += result.external_linear_impulse_x_ns
	budget.damping_impulse_y_ns += result.external_linear_impulse_y_ns
	return OK


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
	# Actual damping-induced internal forces, not an invented support producer.
	# Accumulate once; the inherited door still freezes original previous-tick N.
	if not _drag_hinges.is_empty():
		_accumulate_hinges(_drag_hinges, hinge_x, hinge_y)
	_drag_hinges = []
	return super._velocity_contacts(
		before, dt, hinge_x, hinge_y, reaction, cleanup, budget, positions, contact_samples
	)


func _step(before: Dictionary) -> Dictionary:
	var result := super._step(before)
	if not _drag_failure.is_empty():
		result.drag_failure = _drag_failure.duplicate(true)
		result.work_state = snapshot()
	result.angular_drag_scope = "authored angular fraction on constrained assembly DOFs; not a world-angle controller"
	last_step_trace = result.duplicate(true)
	return result
