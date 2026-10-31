# gdlint: disable=max-line-length
extends "res://tests/physics_fix/test_coplanar_pad_components.gd"
## Read exact failure only. Never creates Sim, calls step, or advances any clock.


class Probe:
	extends "res://tests/physics_fix/surface_impact_kernel.gd"
	var calls: Array = []
	var publication: Dictionary = {}

	func _active_solve(equalities: Array, rhs: Array[float], inequalities: Array) -> Dictionary:
		var result: Dictionary = super._active_solve(equalities, rhs, inequalities)
		calls.append(
			{
				"equalities": equalities.size(),
				"inequalities": inequalities.size(),
				"failed": result.is_empty(),
				"active": result.get("active", [])
			}
		)
		return result

	func _publish(
		bodies: Array[CapsuleBody], delta: Array, position: bool, tuning: Tuning
	) -> Error:
		var before_energy := 0.0
		var proposed_energy := 0.0
		for i in range(bodies.size()):
			var body: CapsuleBody = bodies[i]
			var axes: Dictionary = PlanarBasis.frame(body)
			var shadow := CapsuleBody.new()
			if shadow.restore(body.snapshot()) != OK:
				return ERR_INVALID_DATA
			var vx: float = (body.a.velocity_x + body.b.velocity_x) / 2.0 + delta[3 * i]
			var vy: float = (body.a.velocity_y + body.b.velocity_y) / 2.0 + delta[3 * i + 1]
			var omega: float = axes.omega + delta[3 * i + 2]
			shadow.a.velocity_x = vx + omega * axes.y / 2.0
			shadow.a.velocity_y = vy - omega * axes.x / 2.0
			shadow.b.velocity_x = vx - omega * axes.y / 2.0
			shadow.b.velocity_y = vy + omega * axes.x / 2.0
			before_energy += CONTACT_ROW.kinetic_energy(body)
			proposed_energy += CONTACT_ROW.kinetic_energy(shadow)
		var status: Error = super._publish(bodies, delta, position, tuning)
		publication = {
			"status": status,
			"actual_before": before_energy,
			"actual_proposed": proposed_energy,
			"gain": proposed_energy - before_energy
		}
		return status


func _initialize() -> void:
	var saved: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(
			"res://tests/fixtures/m1_articulated_execution/c49fcc66ee9f/length-Hopper-failure.json"
		)
	)
	var full: Dictionary = bytes_to_var(Marshalls.base64_to_raw(saved.full_state_variant_base64))
	var raw: Array = bytes_to_var(
		Marshalls.base64_to_raw(full.awake_trace.full_work_variant_base64)
	)
	var bodies := _restore(raw)
	var history: Array = full.before.accumulator.solver.rig.physical.bodies
	var parts: Array = full.before.identity.creature.parts
	var parents: Array[int] = []
	var limits: Array = []
	var joint_index := 0
	for child in range(parts.size()):
		parents.append(int(parts[child].parent))
		if parts[child].kind in ["motor", "passive"]:
			var source: Dictionary = full.awake_trace.work_state.angular_joints[joint_index]
			limits.append(
				{
					"parent": int(parts[child].parent),
					"child": child,
					"rest_angle": source.rest_angle,
					"lower": source.lower,
					"upper": source.upper
				}
			)
			joint_index += 1
	limits.append_array(full.awake_trace.rigid_connectors)
	var kernel := Probe.new()
	kernel.history = history.duplicate(true)
	kernel.limits = limits
	var terrain: Dictionary = full.before.identity.tower.terrain
	var grid := SdfGrid.new()
	var valid: bool = (
		saved.tick == 256
		and saved.status == 30
		and full.awake_trace.stage_order[-1] == "velocity_pass_1"
		and grid.configure(terrain.rows, terrain.x, terrain.y, terrain.friction, CONFIG) == OK
		and kernel.configure(bodies, parents) == OK
	)
	_check(valid, "exact archived final physical pass, not first constitutive stage")
	var contacts: Array = []
	for part in range(bodies.size()):
		var count: int = COPLANAR_ADAPTER._intervals(bodies[part], grid, CONFIG)
		for index in range(count + 1):
			var u := float(index) / count
			var sample: Dictionary = COPLANAR_ADAPTER._sample(bodies[part], grid, u, CONFIG)
			if sample.distance <= bodies[part].radius + CONFIG.physics_contact_slop_wu:
				contacts.append(
					{
						"part": part,
						"u": u,
						"nx": sample.nx,
						"ny": sample.ny,
						"restitution": 0.02,
						"damping": 0.9,
						"static_threshold": 0.15
					}
				)
	var bits := _bits(bodies)
	var response: Dictionary = BLOCK.solve(kernel, bodies, contacts)
	_check(response.is_empty(), "exact failed response reproduced without advancing clock")
	_check(bits == _bits(bodies), "failed response leaves input bytes intact")
	_check(
		(
			not kernel.calls.is_empty()
			and (kernel.calls[-1].failed or kernel.publication.get("status", OK) != OK)
		),
		"identify rejecting factor or actual strict publisher"
	)
	print(
		(
			"Final manifold audit data: "
			+ JSON.stringify(
				{"contacts": contacts, "solves": kernel.calls, "publication": kernel.publication},
				"",
				true,
				true
			)
		)
	)
	print("Final manifold archive audit: %d checks, %d failures" % [_checks, _failures])
	print(
		"Scope: archived Hopper256 read-only reproduction; ZERO public ticks; expected failure is NOT candidate acceptance"
	)
	quit(1 if _failures else 0)
