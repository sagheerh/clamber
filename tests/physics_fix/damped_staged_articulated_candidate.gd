# gdlint: disable=max-line-length
extends "res://tests/physics_fix/staged_articulated_candidate.gd"
## UNADOPTED: implement the existing GDD4.2 angular damping resource, not a retune.
const ENERGY = preload("res://tests/physics_fix/rigid_contact_candidate.gd")
var angular_damping_events: Array = []


func _apply_authored_angular_damping(budget: Dictionary) -> Error:
	var damping: float = _tuning.physics_angular_damping
	if not is_finite(damping) or damping < 0.0 or damping > 1.0:
		return ERR_INVALID_DATA
	for body in bodies:
		var axes := PlanarBasis.frame(body)
		if axes.is_empty() or not is_finite(axes.omega):
			return ERR_INVALID_DATA
	for i in range(bodies.size()):
		var body := bodies[i]
		var axes := PlanarBasis.frame(body)
		var before_x := body.mass * (body.a.velocity_x + body.b.velocity_x) / 2.0
		var before_y := body.mass * (body.a.velocity_y + body.b.velocity_y) / 2.0
		var e0 := ENERGY.kinetic_energy(body)
		var change: float = -damping * axes.omega
		PlanarBasis.spin(body, change)
		budget.damping_impulse_x_ns += (
			body.mass * (body.a.velocity_x + body.b.velocity_x) / 2.0 - before_x
		)
		budget.damping_impulse_y_ns += (
			body.mass * (body.a.velocity_y + body.b.velocity_y) / 2.0 - before_y
		)
		angular_damping_events.append(
			{
				"part": i,
				"omega_before": axes.omega,
				"requested_delta_omega": change,
				"omega_after": PlanarBasis.frame(body).omega,
				"external_angular_impulse": change / axes.inverse_inertia,
				"energy_before": e0,
				"energy_after": ENERGY.kinetic_energy(body)
			}
		)
	return OK


func _predict_and_project(dt: float, budget: Dictionary, positions: Array) -> Error:
	angular_damping_events = []
	var status := _apply_authored_angular_damping(budget)
	if status != OK:
		return status
	# Existing point linear damping, full gravity and position budgets unchanged.
	return super._predict_and_project(dt, budget, positions)


func _step(before: Dictionary) -> Dictionary:
	var result := super._step(before)
	result.authored_angular_damping = angular_damping_events.duplicate(true)
	last_step_trace = result.duplicate(true)
	return result
