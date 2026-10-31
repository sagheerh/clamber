# gdlint: disable=max-line-length,max-returns
extends "res://tests/physics_fix/manifold_candidate.gd"
## Owner-authorized derived stance: real toe skin and motor end skin coplanar
## with vertical leg. No arbitrary angle, collider offset, extra torque or park.
const COPLANAR_KERNEL = preload("res://tests/physics_fix/limited_articulated_mobility_candidate.gd")


func setup(
	model: CreatureModel,
	terrain: SdfGrid,
	x: float,
	y: float,
	friction: Array[float],
	restitution: Array[float],
	tuning: Tuning
) -> Error:
	var status: Error = super.setup(model, terrain, x, y, friction, restitution, tuning)
	if status != OK:
		return status
	for connector in _rigid_connectors:
		var child: int = connector.child
		if bodies[child].kind != "foot":
			continue
		var parent: int = connector.parent
		# Original capsule radii/lengths determine the ONE slope; no angle knob.
		var drop: float = bodies[parent].radius - bodies[child].radius
		var ratio: float = drop / bodies[child].rest_length
		if ratio < 0.0 or ratio >= 1.0 or connector.rigid_connector_quarters not in [-1, 1]:
			return ERR_INVALID_DATA
		connector.rigid_connector_inset_ratio = ratio
		connector.rest_angle = PlanarBasis.angle(
			ratio, connector.rigid_connector_quarters * sqrt(1.0 - ratio * ratio)
		)
		var kernel := COPLANAR_KERNEL.new()
		kernel.limits = _limit_definitions()
		var direction: Array[float] = kernel.rigid_axis(bodies, child)
		if direction.size() != 2:
			return ERR_INVALID_DATA
		var toe: SimBody = bodies[child].b
		toe.x = bodies[child].a.x + direction[0]
		toe.y = bodies[child].a.y + direction[1]
		toe.previous_x = toe.x
		toe.previous_y = toe.y
	return OK


func _step(before: Dictionary) -> Dictionary:
	var result := super._step(before)
	result.physical_model_scope = "NEW radius-derived coplanar toe/parent skin stance; actual capsules; NOT V17/V18 or historical geometry"
	last_step_trace = result.duplicate(true)
	return result
