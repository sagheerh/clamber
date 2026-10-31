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
	# Saved first failure is a COMPONENT fixture, never a world replay.
	var failure_text := FileAccess.get_file_as_string(
		"res://tests/fixtures/m1_articulated_execution/797a85674f31/idle-Slug-failure.json"
	)
	var failed: Dictionary = JSON.parse_string(failure_text)
	var full: Dictionary = bytes_to_var(Marshalls.base64_to_raw(failed.full_state_variant_base64))
	_check(
		(
			(
				failure_text.sha256_text()
				== "c41be0285b624d70d00d84e1bedf8b1e935b07beaa7aebd3b1e0d39736365289"
			)
			and failed.tick == 5
			and full.awake_trace.phase == "pre-contact hinge velocity"
		),
		"exact immutable first-failure fixture; no new clock"
	)
	var probe := _rig("Slug")
	var restored: bool = probe.restore(full.awake_trace.work_state) == OK
	var old_network := probe._limited_network()
	restored = restored and old_network.configure(probe.bodies, probe._parents) == OK
	var old_bits := var_to_bytes(probe.snapshot())
	var energies := _projection_energies(old_network, probe.bodies)
	var old_projection: Dictionary = old_network.project_velocity(probe.bodies)
	_check(
		(
			restored
			and old_projection.is_empty()
			and old_bits == var_to_bytes(probe.snapshot())
			and energies.after > energies.before
		),
		"redundant re-solve of canonical velocities rejects strict roundoff energy gain atomically"
	)
	print("Preintegrated exact identity control: " + JSON.stringify(energies, "", true, true))
	var producer := _rig("Slug")
	var produced: bool = producer.restore(full.candidate) == OK and producer._begin_tick() == OK
	var force_budget := _force_budget()
	produced = produced and producer._apply_forces(1.0 / CONFIG.physics_tick_hz, force_budget) == OK
	_check(
		(
			produced
			and var_to_bytes(producer.snapshot()) == old_bits
			and not producer._force_certificate.is_empty()
		),
		"successful actual constitutive producer plus common forces exactly reconstructs failing work and issues a tick-local witness"
	)
	var xs: Array[float] = [0.0, 0.0, 0.0]
	var ys: Array[float] = [0.0, 0.0, 0.0]
	var unchanged: Error = producer._project_changed_velocity(producer._force_certificate, xs, ys)
	_check(
		unchanged == OK and var_to_bytes(producer.snapshot()) == old_bits,
		"known projection identity remains BITWISE identity; no ULP velocity repair"
	)
	producer.bodies[0].a.velocity_x += 0.125
	var changed_bits := var_to_bytes(producer.snapshot())
	var changed: Error = producer._project_changed_velocity(producer._force_certificate, xs, ys)
	_check(
		changed == OK and var_to_bytes(producer.snapshot()) != changed_bits,
		"changed velocity invalidates witness and executes real constraint projection"
	)
	var capped := _rig("Slug")
	for body in capped.bodies:
		for point in [body.a, body.b]:
			point.velocity_x = 2.0 * CONFIG.physics_max_linear_velocity_wu_s
	force_budget = _force_budget()
	var cap_status: Error = capped._apply_forces(1.0 / CONFIG.physics_tick_hz, force_budget)
	_check(
		(
			cap_status == OK
			and capped._force_certificate.is_empty()
			and force_budget.clamp_impulse_x_ns != 0.0
		),
		"actual point speed cap cannot issue a canonical producer witness"
	)
	var zero := _rig("Slug")
	var zero_restored: bool = zero.restore(full.candidate) == OK
	zero._tuning.physics_angular_damping = 0.0
	force_budget = _force_budget()
	var zero_status: Error = zero._apply_forces(1.0 / CONFIG.physics_tick_hz, force_budget)
	_check(
		zero_restored and zero_status == OK and zero._force_certificate.is_empty(),
		"d0 nonuniform identity is NOT falsely certified as a hinge projection"
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


func _force_budget() -> Dictionary:
	return {
		"damping_impulse_x_ns": 0.0,
		"damping_impulse_y_ns": 0.0,
		"gravity_impulse_x_ns": 0.0,
		"gravity_impulse_y_ns": 0.0,
		"clamp_impulse_x_ns": 0.0,
		"clamp_impulse_y_ns": 0.0
	}


func _projection_energies(network: RefCounted, bodies: Array[CapsuleBody]) -> Dictionary:
	# Same native publication arithmetic, on detached bodies; no allowance/repair.
	const ENERGY = preload("res://tests/physics_fix/rigid_contact_candidate.gd")
	var velocity: Array = network._velocities(bodies)
	var rhs: Array[float] = []
	for row in network._hinges:
		rhs.append(-network._dot(row, velocity))
	var impulse: Array = network._solve(rhs)
	var delta: Array[float] = []
	for d in range(velocity.size()):
		var value := 0.0
		for i in range(impulse.size()):
			value += network._weights[d] * network._hinges[i][d] * impulse[i]
		delta.append(value)
	var before := 0.0
	var after := 0.0
	for i in range(bodies.size()):
		var body := bodies[i]
		var shadow := CapsuleBody.new()
		if shadow.restore(body.snapshot()) != OK:
			return {"before": NAN, "after": NAN}
		var axes := PlanarBasis.frame(body)
		var vx: float = (body.a.velocity_x + body.b.velocity_x) / 2.0 + delta[3 * i]
		var vy: float = (body.a.velocity_y + body.b.velocity_y) / 2.0 + delta[3 * i + 1]
		var omega: float = axes.omega + delta[3 * i + 2]
		shadow.a.velocity_x = vx + omega * axes.y / 2.0
		shadow.a.velocity_y = vy - omega * axes.x / 2.0
		shadow.b.velocity_x = vx - omega * axes.y / 2.0
		shadow.b.velocity_y = vy + omega * axes.x / 2.0
		before += ENERGY.kinetic_energy(body)
		after += ENERGY.kinetic_energy(shadow)
	return {"before": before, "after": after, "gain": after - before}
