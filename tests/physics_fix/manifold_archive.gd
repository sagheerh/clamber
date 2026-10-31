# gdlint: disable=max-line-length
extends RefCounted
const TUNING = preload("res://core/tuning.tres")
const ADAPTER = preload("res://tests/physics_fix/manifold_terrain.gd")


static func final_frame(path: String) -> Dictionary:
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var full: Dictionary = bytes_to_var(Marshalls.base64_to_raw(saved.full_state_variant_base64))
	var raw: Array = bytes_to_var(
		Marshalls.base64_to_raw(full.awake_trace.full_work_variant_base64)
	)
	if not (
		(saved.tick == 256 or saved.tick == 263 or saved.tick == 227)
		and saved.status == 30
		and full.awake_trace.stage_order[-1] == "velocity_pass_1"
	):
		return {}
	return _assemble(
		raw,
		full.before.accumulator.solver.rig.physical.bodies,
		full.before.identity.creature.parts,
		full.awake_trace.work_state.angular_joints,
		full.awake_trace.rigid_connectors,
		full.before.identity.tower.terrain
	)


static func first_frame(path: String, kernel: RefCounted) -> Dictionary:
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var full: Dictionary = bytes_to_var(Marshalls.base64_to_raw(saved.full_state_variant_base64))
	if (
		saved.tick not in [285, 369]
		or saved.status != 30
		or full.awake_trace.stage_order[-1] != "velocity_pass_0"
	):
		return {}
	var raw: Array = bytes_to_var(
		Marshalls.base64_to_raw(full.awake_trace.full_work_variant_base64)
	)
	return _assemble(
		raw,
		full.before.accumulator.solver.rig.physical.bodies,
		full.before.identity.creature.parts,
		full.awake_trace.work_state.angular_joints,
		full.awake_trace.rigid_connectors,
		full.before.identity.tower.terrain,
		kernel
	)


static func runtime_frame(path: String, kernel: RefCounted) -> Dictionary:
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var record: Dictionary = bytes_to_var(Marshalls.base64_to_raw(saved.failure_variant_base64))
	var failure: Dictionary = record.physics_failure.failed
	var before: Dictionary = record.physics_failure.before_frame
	var trace: Dictionary = failure.awake_trace
	if (
		saved.checks != 88
		or failure.tick != 4
		or failure.mask != 3
		or trace.stage_order[-1] != "velocity_pass_0"
	):
		return {}
	var raw: Array = bytes_to_var(Marshalls.base64_to_raw(trace.full_work_variant_base64))
	return _assemble(
		raw,
		before.accumulator.solver.rig.physical.bodies,
		before.identity.creature.parts,
		trace.work_state.angular_joints,
		trace.rigid_connectors,
		before.identity.tower.terrain,
		kernel
	)


static func _assemble(
	raw: Array,
	history: Array,
	parts: Array,
	joints: Array,
	rigid: Array,
	terrain: Dictionary,
	kernel: RefCounted = null
) -> Dictionary:
	var bodies: Array[CapsuleBody] = []
	for state in raw:
		var body := CapsuleBody.new()
		if body.restore(state) != OK:
			return {}
		bodies.append(body)
	var parents: Array[int] = []
	var limits: Array = []
	var joint_index := 0
	for child in range(parts.size()):
		parents.append(int(parts[child].parent))
		if parts[child].kind in ["motor", "passive"]:
			var source: Dictionary = joints[joint_index]
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
	limits.append_array(rigid)
	if kernel == null:
		kernel = preload("res://tests/physics_fix/surface_impact_kernel.gd").new()
	kernel.history = history.duplicate(true)
	kernel.limits = limits
	var grid := SdfGrid.new()
	var valid: bool = (
		grid.configure(terrain.rows, terrain.x, terrain.y, terrain.friction, TUNING) == OK
		and kernel.configure(bodies, parents) == OK
	)
	if not valid:
		return {}
	var contacts: Array = []
	for part in range(bodies.size()):
		var count: int = ADAPTER._intervals(bodies[part], grid, TUNING)
		for index in range(count + 1):
			var u := float(index) / count
			var sample: Dictionary = ADAPTER._sample(bodies[part], grid, u, TUNING)
			if sample.distance <= bodies[part].radius + TUNING.physics_contact_slop_wu:
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
	return {"bodies": bodies, "kernel": kernel, "contacts": contacts, "terrain": grid}
