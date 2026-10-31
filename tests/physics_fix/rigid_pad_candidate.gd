# gdlint: disable=max-line-length
extends "res://tests/physics_fix/surface_constitutive_candidate.gd"
## Explicitly authorized structural pad/bone connectors; same masses/material/laws.
## No root constraint or global upright target. Genuine motors/passives stay free.
const CARDINAL: Dictionary = {"RIGHT": 0, "UP": 1, "LEFT": 2, "DOWN": 3}
var _rigid_connectors: Array = []


func setup(
	model: CreatureModel,
	terrain: SdfGrid,
	x: float,
	y: float,
	friction: Array[float],
	restitution: Array[float],
	tuning: Tuning
) -> Error:
	_rigid_connectors = []
	var status: Error = super.setup(model, terrain, x, y, friction, restitution, tuning)
	if status != OK:
		return status
	var parts: Array = model.definition().parts
	for child in range(1, parts.size()):
		if parts[child].kind not in ["foot", "limb"]:
			continue
		var parent: int = parts[child].parent
		var quarters: int = (
			(int(CARDINAL[parts[child].axis]) - int(CARDINAL[parts[parent].axis]) + 6) % 4 - 2
		)
		_rigid_connectors.append(
			{
				"parent": parent,
				"child": child,
				"rest_angle": quarters * PI / 2.0,
				"lower": -PI,
				"upper": PI,
				"rigid_connector_quarters": quarters
			}
		)
	return OK


func _limit_definitions() -> Array:
	return super._limit_definitions() + _rigid_connectors.duplicate(true)


func _step(before: Dictionary) -> Dictionary:
	var result := super._step(before)
	result.rigid_connectors = _rigid_connectors.duplicate(true)
	result.physical_model_scope = "owner-authorized rigid pads/bones; authored new stance; NOT historical pose PASS"
	last_step_trace = result.duplicate(true)
	return result
