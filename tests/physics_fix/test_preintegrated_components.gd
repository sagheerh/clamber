# gdlint: disable=max-line-length
extends SceneTree
## Isolated native stage/load components. No public Sim/world capture or old replay.
const CANDIDATE = preload("res://tests/physics_fix/preintegrated_articulated_candidate.gd")
const CONFIG = preload("res://core/tuning.tres")
var _checks := 0
var _failures := 0


func _initialize() -> void:
	var expected := ["forces", "velocity_pass_0", "integration"]
	for i in range(6):
		expected.append("position_sweep_%d" % i)
	expected.append("velocity_pass_1")
	for name in ["Slug", "Hopper", "TwinRoller"]:
		var rig := _rig(name)
		_check(rig != null, name + " original geometry/material setup")
		if rig == null:
			continue
		rig.collect_contact_samples = true
		var result: Dictionary = rig.step()
		_check(result.status == OK, name + " component step")
		if result.status != OK:
			print("Preintegrated component failure: " + JSON.stringify(result, "", true, true))
			continue
		_check(
			(
				result.stage_order == expected
				and rig._tuning.physics_velocity_passes == 2
				and rig._tuning.physics_position_iterations == 6
			),
			name + " actual two passes bracket integration and six unchanged sweeps"
		)
		var geometry := true
		for body in rig.bodies:
			var dx: float = body.b.x - body.a.x
			var dy: float = body.b.y - body.a.y
			geometry = geometry and absf(sqrt(dx * dx + dy * dy) - body.rest_length) < 1e-12
			geometry = (
				geometry
				and (
					minf(body.a.y, body.b.y) - body.radius
					>= -CONFIG.physics_contact_slop_wu * (1.0 + 1e-9)
				)
			)
		_check(geometry, name + " original length and penetration bounds")
		var ledger := true
		for axis in ["x", "y"]:
			var sum_impulses := 0.0
			for stage in [
				"drive_internal", "damping", "gravity", "internal", "contact_velocity", "clamp"
			]:
				sum_impulses += result.momentum_budget[stage + "_impulse_" + axis + "_ns"]
			ledger = (
				ledger
				and (
					absf(sum_impulses - result.momentum_budget["momentum_change_" + axis + "_ns"])
					< 1e-12
				)
			)
		_check(ledger, name + " actual momentum/load ledger closes; arithmetic test only")
		var frozen: bool = result.previous_grounded_feet == 0 and result.contact_batches.size() == 2
		var preintegration_reaction := false
		for sample in result.contact_samples:
			frozen = frozen and not sample.may_grip
			preintegration_reaction = (
				preintegration_reaction
				or (sample.velocity_pass == 0 and sample.normal_impulse_ns > 0.0)
			)
		_check(
			frozen and preintegration_reaction,
			name + " fresh physical support before integration; N0 stays disabled in BOTH passes"
		)
	var invalid := _rig("Slug")
	invalid._tuning.physics_velocity_passes = 3
	var before := var_to_bytes(invalid.snapshot())
	var rejected: Dictionary = invalid.step()
	_check(
		rejected.status != OK and before == var_to_bytes(invalid.snapshot()),
		"unsupported budget rejected atomically; no hidden additional sweep"
	)
	var empty := CANDIDATE.new()
	var empty_result: Dictionary = empty.step()
	_check(empty_result.status == ERR_UNCONFIGURED, "unconfigured path retains original contract")
	print("Preintegrated components: %d checks, %d failures" % [_checks, _failures])
	print("Scope: stage/load COMPONENTS ONLY; ZERO public world ticks; NOT acceptance")
	quit(1 if _failures else 0)


func _rig(name: String) -> CANDIDATE:
	var model := CreaturePresets.load_model(name, CONFIG)
	var rig := CANDIDATE.new()
	var status := rig.setup(
		model,
		R25Fixture.floor_grid(),
		0.0,
		R25Fixture.spawn_y(model),
		R25Fixture.materials(model),
		R25Fixture.materials(model, true),
		CONFIG
	)
	return rig if status == OK else null


func _check(ok: bool, label: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		push_error("FAIL " + label)
