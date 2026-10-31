# gdlint: disable=max-line-length
extends "res://tests/physics_fix/coplanar_pad_candidate.gd"
## V25 explicit operator split: initial physical impact, positions, then ONE
## complete authored angular resistance/support stage at final actual geometry.
## Not extra drag, velocity scaling, energy repair, cutoff or budget. All old
## candidate classes retain phase0, and every publisher/complete guard stays.


func _constitutive_velocity_pass() -> int:
	return 1


func _begin_tick() -> Error:
	_constitutive_report = {
		"status": ERR_UNCONFIGURED, "scope": "final-geometry constitutive stage NOTRUN"
	}
	return super._begin_tick()


func _step(before: Dictionary) -> Dictionary:
	var result := super._step(before)
	if (
		result.get("constitutive_stage", {}).get("status") == OK
		and result.constitutive_stage.has("scope")
	):
		result.constitutive_stage.scope = "V25 complete angular drag plus FINAL support; actual endpoint energy, no allowance"
	result.constitutive_phase_scope = "V25: ONE full authored angular/support constitutive stage AFTER positions, not V24 first-pass recipe"
	last_step_trace = result.duplicate(true)
	return result
