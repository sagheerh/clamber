# gdlint: disable=max-line-length
extends "res://tests/physics_fix/test_support_manifold_components.gd"
const COPLANAR_CONSTITUTIVE = preload("res://tests/physics_fix/surface_constitutive_kernel.gd")
const COPLANAR_ADAPTER = preload("res://tests/physics_fix/manifold_terrain.gd")
const COPLANAR = preload("res://tests/physics_fix/coplanar_pad_candidate.gd")


class CoplanarFault:
	extends "res://tests/physics_fix/coplanar_pad_candidate.gd"

	func _velocity_pass(
		before: Dictionary,
		hx: Array[float],
		hy: Array[float],
		reaction: Array[float],
		cleanup: Array[float],
		budget: Dictionary,
		positions: Array,
		samples: Array,
		pass_index: int,
		certificate: PackedByteArray
	) -> Dictionary:
		var result: Dictionary = super._velocity_pass(
			before, hx, hy, reaction, cleanup, budget, positions, samples, pass_index, certificate
		)
		if result.status == OK and pass_index == 0:
			bodies[0].a.velocity_x = 100.0
			return STAGE_GUARD.validate(_constitutive_origin, bodies)
		return result


func _initialize() -> void:
	for name in ["Slug", "Hopper", "TwinRoller"]:
		var rig := COPLANAR.new()
		var valid: bool = _setup_pad(rig, name) == OK
		var original := CreaturePresets.load_model(name, CONFIG)
		var old_bodies := original.create_bodies(0.0, 0.0)
		var shape := valid
		for i in range(rig.bodies.size()):
			shape = (
				shape
				and rig.bodies[i].mass == old_bodies[i].mass
				and rig.bodies[i].radius == old_bodies[i].radius
				and rig.bodies[i].rest_length == old_bodies[i].rest_length
			)
			if rig.bodies[i].kind == "foot":
				var parent: int = rig._parents[i]
				shape = (
					shape
					and (
						absf(
							(
								(rig.bodies[i].b.y - rig.bodies[i].radius)
								- (rig.bodies[parent].b.y - rig.bodies[parent].radius)
							)
						)
						< 1e-12
					)
				)
		_check(
			shape,
			(
				name
				+ " real toe and parent skins coplanar from unchanged radii/length/mass, no angle knob"
			)
		)
		rig.collect_contact_samples = true
		var result: Dictionary = rig.step()
		_check(
			(
				result.status == OK
				and result.constitutive_stage.status == OK
				and result.previous_grounded_feet == 0
			),
			name + " actual strict coupled gravity/contact stage; original frozen N0"
		)
		if name == "Slug":
			_check(
				(
					result.status == OK
					and _energy(rig.bodies) == 0.0
					and PlanarBasis.frame(rig.bodies[0]).x == 0.0
				),
				"neutral exact static modal moment stays zero; no artificial head momentum"
			)
		var material: bool = result.status == OK
		if material:
			for observed in result.contact_samples:
				material = material and not observed.may_grip
			for axis in ["x", "y"]:
				var impulse := 0.0
				for stage in [
					"drive_internal", "damping", "gravity", "internal", "contact_velocity", "clamp"
				]:
					impulse += result.momentum_budget[stage + "_impulse_" + axis + "_ns"]
				material = (
					material
					and (
						absf(impulse - result.momentum_budget["momentum_change_" + axis + "_ns"])
						< 1e-12
					)
				)
		_check(material, name + " genuine complete momentum and no manufactured grip/load")
		var kernel := FINAL.new()
		kernel.limits = rig._limit_definitions()
		kernel.history = _states(rig.bodies)
		valid = kernel.configure(rig.bodies, rig._parents) == OK
		var torque: Array[float] = kernel._zero(3 * rig.bodies.size())
		torque[2] = 1.0
		var response: Dictionary = kernel.mobility(torque)
		_check(
			valid and not response.is_empty() and response.delta[2] != 0.0,
			name + " actual root angular DOF free, not world fixed/upright"
		)
	var rig := COPLANAR.new()
	var valid: bool = _setup_pad(rig, "Slug") == OK
	var bits := _bits(rig.bodies)
	var kernel := FINAL.new()
	kernel.limits = rig._limit_definitions()
	kernel.limits[-1].rigid_connector_inset_ratio = 1.0
	kernel.history = _states(rig.bodies)
	_check(
		valid and kernel.configure(rig.bodies, rig._parents) != OK and bits == _bits(rig.bodies),
		"degenerate derived connector fails closed without body edits"
	)
	var driven: Dictionary = rig.advance(CONFIG.motors_input_left_mask)
	_check(
		driven.status == OK and _energy(rig.bodies) > 0.0,
		"actual held input produces physical motion; not an equilibrium park"
	)
	var fault := CoplanarFault.new()
	valid = _setup_pad(fault, "Slug") == OK
	var saved: PackedByteArray = var_to_bytes(fault.snapshot())
	var failure: Dictionary = fault.step()
	_check(
		valid and failure.status == ERR_INVALID_DATA,
		"actual finite energy gain rejected in derived model"
	)
	_check(
		saved == var_to_bytes(fault.snapshot()),
		"entire derived model snapshot atomically restored after injected gain"
	)
	_archived_shared_pin_normals()
	_archived_restitution_chord()
	_archived_hopper_affine_patch()
	_moving_pin_projection()
	_check(_checks == 28, "complete native derived geometry tally")
	print("Coplanar pad components: %d checks, %d failures" % [_checks, _failures])
	print("Scope: new radius-derived real capsule stance units; ZERO public clock; NOT acceptance")
	quit(1 if _failures else 0)


func _archived_shared_pin_normals() -> void:
	var text := FileAccess.get_file_as_string(
		"res://tests/fixtures/m1_articulated_execution/f101721f17cf/length-Slug-failure.json"
	)
	var saved: Dictionary = JSON.parse_string(text)
	var full: Dictionary = bytes_to_var(Marshalls.base64_to_raw(saved.full_state_variant_base64))
	var raw: Array = bytes_to_var(
		Marshalls.base64_to_raw(full.awake_trace.full_work_variant_base64)
	)
	var bodies := _restore(raw)
	var history: Array = full.before.accumulator.solver.rig.physical.bodies
	var kernel := COPLANAR_CONSTITUTIVE.new()
	kernel.history = history.duplicate(true)
	kernel.angular_retention = 1.0 - CONFIG.physics_angular_damping
	kernel.limits = (
		[
			{
				"parent": 0,
				"child": 1,
				"rest_angle": full.awake_trace.work_state.angular_joints[0].rest_angle,
				"lower": full.awake_trace.work_state.angular_joints[0].lower,
				"upper": full.awake_trace.work_state.angular_joints[0].upper
			}
		]
		+ full.awake_trace.rigid_connectors
	)
	var parents: Array[int] = [-1, 0, 1]
	var valid: bool = (
		saved.tick == 214 and saved.status == 30 and kernel.configure(bodies, parents) == OK
	)
	var contacts: Array = []
	for pair in [[0, 1.0], [1, 0.5], [1, 1.0]]:
		contacts.append(
			{
				"part": int(pair[0]),
				"u": pair[1],
				"nx": 0.0,
				"ny": 1.0,
				"restitution": 0.02,
				"damping": 0.9,
				"static_threshold": 0.15
			}
		)
	var response: Dictionary = BLOCK.solve(kernel, bodies, contacts)
	_check(
		valid and not response.is_empty(),
		"archived actual long-run214 shared-pin redundant normal patch factors without a pivot epsilon"
	)
	var admissible := not response.is_empty()
	if admissible:
		for c in contacts:
			admissible = (
				admissible
				and absf(SKIN_ROW.frame(bodies[c.part], c.u, c.nx, c.ny).normal_velocity) < 1e-12
			)
	_check(
		admissible and _energy(bodies) < _energy(_restore(raw)),
		"archived three actual normal constraints honored with strict actual dissipation and real head tangent"
	)
	# Original static branch overrides even zero dynamic material coefficient.
	bodies = _restore(history)
	for body in bodies:
		body.a.velocity_x = 0.1
		body.b.velocity_x = 0.1
		body.a.velocity_y = 0.5
		body.b.velocity_y = 0.5
	var physical := FINAL.new()
	physical.history = history.duplicate(true)
	physical.limits = kernel.limits
	valid = physical.configure(bodies, parents) == OK
	var contact: Dictionary = contacts[2].duplicate(true)
	contact.damping = 0.0
	response = BLOCK.solve(physical, bodies, [contact])
	_check(
		valid and not response.is_empty() and response.contacts[0].tangent != 0.0,
		"zero dynamic material does NOT bypass the existing static-slip branch"
	)


func _archived_restitution_chord() -> void:
	var saved: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(
			"res://tests/fixtures/m1_articulated_execution/8496abfa354a/length-Slug-failure.json"
		)
	)
	var full: Dictionary = bytes_to_var(Marshalls.base64_to_raw(saved.full_state_variant_base64))
	var raw: Array = bytes_to_var(
		Marshalls.base64_to_raw(full.awake_trace.full_work_variant_base64)
	)
	var history: Array = full.before.accumulator.solver.rig.physical.bodies
	var bodies := _restore(raw)
	var kernel := COPLANAR_CONSTITUTIVE.new()
	kernel.angular_retention = 1.0 - CONFIG.physics_angular_damping
	kernel.history = history.duplicate(true)
	kernel.limits = (
		[
			{
				"parent": 0,
				"child": 1,
				"rest_angle": full.awake_trace.work_state.angular_joints[0].rest_angle,
				"lower": full.awake_trace.work_state.angular_joints[0].lower,
				"upper": full.awake_trace.work_state.angular_joints[0].upper
			}
		]
		+ full.awake_trace.rigid_connectors
	)
	var parents: Array[int] = [-1, 0, 1]
	var valid: bool = saved.tick == 247 and kernel.configure(bodies, parents) == OK
	var contacts: Array = []
	for pair in [[0, 1.0], [1, 0.5], [1, 1.0]]:
		contacts.append(
			{
				"part": int(pair[0]),
				"u": pair[1],
				"nx": 0.0,
				"ny": 1.0,
				"restitution": 0.02,
				"damping": 0.9,
				"static_threshold": 0.15
			}
		)
	var target: float = kernel.normal_target(0, 1.0, 0.0, 1.0, 0.02)
	_check(
		valid and target > 0.0,
		"archived247 has genuine small positive history target; never rounded/waived to zero"
	)
	var response: Dictionary = BLOCK.solve(kernel, bodies, contacts)
	_check(
		not response.is_empty() and _energy(bodies) < _energy(_restore(raw)),
		"archived247 affine target chord avoids singular interior normal with strict actual dissipation"
	)
	for reverse in [false, true]:
		bodies = _restore(history)
		var previous := _states(bodies)
		for b in bodies:
			b.a.velocity_y = -1.0
			b.b.velocity_y = -1.0
		for b in previous:
			b.a.velocity_y = -1.0
			b.b.velocity_y = -1.0
		var physical := FINAL.new()
		physical.history = previous
		physical.limits = kernel.limits
		valid = physical.configure(bodies, parents) == OK
		var first: Dictionary = contacts[2].duplicate(true)
		first.restitution = 0.02
		var second: Dictionary = first.duplicate(true)
		second.restitution = 0.1
		var pair: Array = [second, first] if reverse else [first, second]
		response = BLOCK.solve(physical, bodies, pair)
		_check(
			(
				valid
				and not response.is_empty()
				and absf(SKIN_ROW.frame(bodies[1], 1.0, 0.0, 1.0).normal_velocity - 0.1) < 1e-12
			),
			"coincident stronger normal history target survives either input order"
		)


func _archived_hopper_affine_patch() -> void:
	var saved: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(
			"res://tests/fixtures/m1_articulated_execution/bccae29d24ad/length-Hopper-failure.json"
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
	var kernel := COPLANAR_CONSTITUTIVE.new()
	kernel.history = history.duplicate(true)
	kernel.angular_retention = 1.0 - CONFIG.physics_angular_damping
	kernel.limits = limits
	var terrain: Dictionary = full.before.identity.tower.terrain
	var grid := SdfGrid.new()
	var valid: bool = (
		saved.tick == 5
		and saved.status == 30
		and grid.configure(terrain.rows, terrain.x, terrain.y, terrain.friction, CONFIG) == OK
		and kernel.configure(bodies, parents) == OK
	)
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
	var response: Dictionary = BLOCK.solve(kernel, bodies, contacts)
	_check(
		valid and kernel.normal_target(7, 1.0, 0.0, 1.0, 0.02) > 0.0 and not response.is_empty(),
		"exact Hopper5 affine normal patch uses one material DOF without rounding real positive target"
	)
	var balanced := not response.is_empty()
	if balanced:
		for axis in ["x", "y"]:
			var dp := 0.0
			var external := 0.0
			for part in range(bodies.size()):
				var b: CapsuleBody = bodies[part]
				dp += (
					b.mass
					* (
						b.a.get("velocity_" + axis)
						+ b.b.get("velocity_" + axis)
						- raw[part].a["velocity_" + axis]
						- raw[part].b["velocity_" + axis]
					)
					/ 2.0
				)
			for i in range(contacts.size()):
				external += (
					response.contacts[i].normal * contacts[i]["n" + axis]
					+ (
						response.contacts[i].tangent
						* (-contacts[i].ny if axis == "x" else contacts[i].nx)
					)
				)
			balanced = balanced and absf(dp - external) < 1e-12
	_check(
		balanced and _energy(bodies) < _energy(_restore(raw)),
		"actual eight-body Hopper archived response dissipates and terrain impulses close total momentum"
	)


func _moving_pin_projection() -> void:
	var frame: Dictionary = preload("res://tests/physics_fix/manifold_archive.gd").final_frame(
		"res://tests/fixtures/m1_articulated_execution/c49fcc66ee9f/length-Hopper-failure.json"
	)
	var before: float = _energy(frame.bodies)
	var states := _states(frame.bodies)
	var response: Dictionary = BLOCK.solve(frame.kernel, frame.bodies, frame.contacts)
	_check(
		not response.is_empty() and _energy(frame.bodies) <= before,
		"exact Hopper256 final physical projection passes ORIGINAL strict actual energy comparison"
	)
	var honest := not response.is_empty()
	if honest:
		for axis in ["x", "y"]:
			var momentum := 0.0
			var impulse := 0.0
			for i in range(frame.bodies.size()):
				var body: CapsuleBody = frame.bodies[i]
				momentum += (
					body.mass
					* (
						body.a.get("velocity_" + axis)
						+ body.b.get("velocity_" + axis)
						- states[i].a["velocity_" + axis]
						- states[i].b["velocity_" + axis]
					)
					/ 2.0
				)
			for i in range(frame.contacts.size()):
				var c: Dictionary = frame.contacts[i]
				impulse += (
					response.contacts[i].normal * c["n" + axis]
					+ response.contacts[i].tangent * (-c.ny if axis == "x" else c.nx)
				)
			honest = honest and absf(momentum - impulse) < 1e-12
		for i in range(frame.bodies.size()):
			for endpoint in ["a", "b"]:
				for axis in ["x", "y"]:
					honest = (
						honest
						and frame.bodies[i].get(endpoint).get(axis) == states[i][endpoint][axis]
					)
	_check(honest, "moving-pin response preserves real terrain momentum and all original positions")
