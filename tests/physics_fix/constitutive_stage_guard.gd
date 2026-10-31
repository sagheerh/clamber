# gdlint: disable=max-line-length
extends RefCounted
## Complete physical operator, not an energy allowance. No scalar budget accepted.
## Actual endpoint origin, exact geometry/mass identity and strict actual energy.
const ENERGY = preload("res://tests/physics_fix/rigid_contact_candidate.gd")


static func validate(origin: Array, bodies: Array[CapsuleBody]) -> Dictionary:
	if origin.is_empty() or origin.size() != bodies.size():
		return {"status": ERR_INVALID_DATA, "reason": "missing complete constitutive origin"}
	var before: float = 0.0
	var after: float = 0.0
	for i in range(bodies.size()):
		var old := CapsuleBody.new()
		if not origin[i] is Dictionary or old.restore(origin[i]) != OK or not bodies[i].is_valid():
			return {"status": ERR_INVALID_DATA, "reason": "invalid constitutive states"}
		var shape_before: Dictionary = old.snapshot()
		var shape_after: Dictionary = bodies[i].snapshot()
		# Only velocities + contact/load flags/channels may differ. A pose/mass/
		# endpoint previous-position change is NOT covered by this physical model.
		for key in [
			"grounded", "gripping", "applied_load_n", "measured_reaction_n", "positional_cleanup_n"
		]:
			shape_before.erase(key)
			shape_after.erase(key)
		for key in ["a", "b"]:
			shape_before[key].erase("velocity_x")
			shape_before[key].erase("velocity_y")
			shape_after[key].erase("velocity_x")
			shape_after[key].erase("velocity_y")
		if var_to_bytes(shape_before) != var_to_bytes(shape_after):
			return {"status": ERR_INVALID_DATA, "reason": "constitutive geometry changed"}
		before += ENERGY.kinetic_energy(old)
		after += ENERGY.kinetic_energy(bodies[i])
	if not is_finite(before) or not is_finite(after) or after > before:
		return {
			"status": ERR_INVALID_DATA,
			"reason": "strict complete constitutive energy",
			"before": before,
			"after": after
		}
	return {
		"status": OK,
		"before": before,
		"after": after,
		"scope": "complete angular drag plus first support; actual endpoint energy, no allowance"
	}
