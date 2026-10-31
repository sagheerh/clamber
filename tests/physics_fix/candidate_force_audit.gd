# gdlint: disable=max-line-length,max-returns
extends RefCounted
## Same independent F31 arithmetic as native207; shared by live long-run validation.
## This is a test auditor, NOT a physical solver or production acceptance waiver.
const TUNING = preload("res://core/tuning.tres")


static func validate(trace: Dictionary) -> bool:
	if trace.get("status") != OK:
		return false
	var budget: Dictionary = trace.momentum_budget
	var bodies: Array = trace.feet + trace.other_bodies
	var mass := 0.0
	var prev_feet := 0
	for body in bodies:
		mass += body.mass
		if trace.feet.has(body) and body.grounded_previous:
			prev_feet += 1
	if (
		prev_feet != trace.previous_grounded_feet
		or absf(budget.gravity_impulse_y_ns - mass * TUNING.physics_gravity_wu_s2 / 60.0) > 1e-12
	):
		return false
	for axis in ["x", "y"]:
		var actual := 0.0
		for body in bodies:
			actual += (
				body.mass
				* (
					body["av" + axis]
					+ body["bv" + axis]
					- body["start_av" + axis]
					- body["start_bv" + axis]
				)
				/ 2.0
			)
		var reported := 0.0
		for stage in [
			"drive_internal", "damping", "gravity", "internal", "contact_velocity", "clamp"
		]:
			reported += budget[stage + "_impulse_" + axis + "_ns"]
		if (
			absf(actual - reported) > 1e-12
			or absf(actual - budget["momentum_change_" + axis + "_ns"]) > 1e-12
		):
			return false
	for event in trace.drive_events:
		var target := 0.0
		var torque: float
		if event.kind == "motor":
			var bit := 1 if event.channel == "L" else 2
			if trace.input_mask & bit:
				target = (
					-TUNING.motors_contraction_deg
					* PlanarBasis.TABLE.DEGREE_RADIANS
					* TUNING.motors_gain_default
				)
			torque = clampf(
				(
					TUNING.motors_joint_stiffness * (target - event.q)
					- TUNING.motors_joint_damping * event.omega
				),
				-TUNING.motors_max_torque * TUNING.motors_gain_default,
				TUNING.motors_max_torque * TUNING.motors_gain_default
			)
		else:
			torque = -TUNING.physics_passive_stiffness * event.q
		var speed_limit: float = TUNING.physics_max_angular_velocity_rad_s
		var lower: float = maxf(
			(event.parent_omega - speed_limit) / event.parent_inverse_inertia,
			(-speed_limit - event.child_omega) / event.child_inverse_inertia
		)
		var upper: float = minf(
			(event.parent_omega + speed_limit) / event.parent_inverse_inertia,
			(speed_limit - event.child_omega) / event.child_inverse_inertia
		)
		if (
			absf(lower - event.speed_minimum_impulse) > 1e-12
			or absf(upper - event.speed_maximum_impulse) > 1e-12
		):
			return false
		var bound: float = (
			TUNING.physics_max_constraint_angular_impulse_rad_s
			/ (event.parent_inverse_inertia + event.child_inverse_inertia)
		)
		var delivered := clampf(
			torque / 60.0, -bound - event.impulse_before, bound - event.impulse_before
		)
		if event.speed_minimum_impulse <= event.speed_maximum_impulse:
			delivered = clampf(delivered, event.speed_minimum_impulse, event.speed_maximum_impulse)
			delivered = clampf(
				delivered, -bound - event.impulse_before, bound - event.impulse_before
			)
		if (
			event.target != target
			or absf(event.torque - torque) > 1e-12
			or absf(event.requested_impulse - torque / 60.0) > 1e-12
			or absf(event.impulse - delivered) > 1e-12
		):
			return false
	if not _contact_ok(trace, bodies):
		return false
	return true


static func _contact_ok(trace: Dictionary, bodies: Array) -> bool:
	# Actual endpoint deltas, per-observation pose, true skin lever arms, shared
	# hinge/drag/limit/connector event counted ONCE per full articulated batch.
	var by_part := {}
	for body in bodies:
		by_part[body.part] = body
	var mass := 0.0
	for body in bodies:
		mass += body.mass
	var n: int = trace.previous_grounded_feet
	var threshold: float = TUNING.physics_grip_normal_force_floor
	if n > 0:
		threshold = maxf(
			threshold,
			TUNING.physics_grip_normal_force_ratio * mass * absf(TUNING.physics_gravity_wu_s2) / n
		)
	for batch in trace.contact_batches:
		for part in batch.parts:
			var load: float = maxf(
				0.0,
				(
					-(
						(
							(
								by_part[part.part].mass * TUNING.physics_gravity_wu_s2 / 60.0
								+ part.hinge_y_ns
								+ part.extra.y
							)
							* part.normal.ny
						)
						+ (part.hinge_x_ns + part.extra.x) * part.normal.nx
					)
					* 60.0
				)
			)
			if absf(load - part.applied_load_n) > 1e-12:
				return false
		if batch.velocity_pass == trace.constitutive_velocity_pass:
			for drag in trace.authored_angular_damping:
				var pose: Dictionary = batch.parts[drag.part]
				var dx: float = pose.b[0] - pose.a[0]
				var dy: float = pose.b[1] - pose.a[1]
				var c: float = (
					by_part[drag.part].mass
					* (dx * dx + dy * dy)
					/ 4.0
					* TUNING.physics_angular_damping
					/ (1.0 - TUNING.physics_angular_damping)
				)
				if absf(drag.external_angular_impulse + c * drag.omega_after) > 1e-12:
					return false
		var events := {}
		var terrain := {}
		var shared: Dictionary = {}
		for sample in trace.contact_samples:
			if sample.velocity_pass != batch.velocity_pass:
				continue
			var foot: bool = trace.feet.has(by_part[sample.part])
			var may_grip: bool = (
				n > 0 and foot and sample.lowest and sample.applied_load_n >= threshold
			)
			if (
				sample.material_friction != TUNING.physics_grip_friction
				or sample.sample_friction != TUNING.physics_grip_friction
				or sample.may_grip != may_grip
				or sample.frozen_previous_grounded_feet != n
			):
				return false
			if sample.has("normal_target"):
				var old: Dictionary = by_part[sample.part]
				var impact: float = (
					-TUNING.physics_foot_restitution
					* minf(
						0.0,
						(
							(
								((1.0 - sample.u) * old.start_avx + sample.u * old.start_bvx)
								* sample.nx
							)
							+ (
								((1.0 - sample.u) * old.start_avy + sample.u * old.start_bvy)
								* sample.ny
							)
						)
					)
				)
				if absf(sample.normal_target - impact) > 1e-12:
					return false
			if not events.has(sample.part):
				events[sample.part] = sample
				terrain[sample.part] = {"x": 0.0, "y": 0.0, "torque": 0.0}
			if sample.get("manifold_shared_event", false) and shared.is_empty():
				shared = sample
			var jx: float = (
				sample.normal_impulse_ns * sample.nx - sample.tangential_impulse_ns * sample.ny
			)
			var jy: float = (
				sample.normal_impulse_ns * sample.ny + sample.tangential_impulse_ns * sample.nx
			)
			var pose: Dictionary = {"a": sample.pose_a, "b": sample.pose_b}
			var rx: float = (
				(sample.u - 0.5) * (pose.b[0] - pose.a[0])
				- by_part[sample.part].radius_wu * sample.nx
			)
			var ry: float = (
				(sample.u - 0.5) * (pose.b[1] - pose.a[1])
				- by_part[sample.part].radius_wu * sample.ny
			)
			terrain[sample.part].x += jx
			terrain[sample.part].y += jy
			terrain[sample.part].torque += rx * jy - ry * jx
		if events.size() != bodies.size():
			return false
		var actual_x := 0.0
		var actual_y := 0.0
		var reported_x := 0.0
		var reported_y := 0.0
		for part in events:
			var sample: Dictionary = events[part]
			var body: Dictionary = by_part[part]
			actual_x += (
				body.mass
				* (sample.avx_after + sample.bvx_after - sample.avx_before - sample.bvx_before)
				/ 2.0
			)
			actual_y += (
				body.mass
				* (sample.avy_after + sample.bvy_after - sample.avy_before - sample.bvy_before)
				/ 2.0
			)
			reported_x += terrain[part].x
			reported_y += terrain[part].y
			var pose: Dictionary = {"a": sample.pose_a, "b": sample.pose_b}
			var dx: float = pose.b[0] - pose.a[0]
			var dy: float = pose.b[1] - pose.a[1]
			var actual_angular: float = (
				body.mass
				* (
					(
						dx
						* (
							sample.bvy_after
							- sample.avy_after
							- sample.bvy_before
							+ sample.avy_before
						)
					)
					- (
						dy
						* (
							sample.bvx_after
							- sample.avx_after
							- sample.bvx_before
							+ sample.avx_before
						)
					)
				)
				/ 4.0
			)
			var reported_angular: float = terrain[part].torque
			if not shared.is_empty():
				for event in shared.angular_drag_events:
					if event.part == part:
						var c: float = (
							TUNING.physics_angular_damping / (1.0 - TUNING.physics_angular_damping)
							if batch.velocity_pass == trace.constitutive_velocity_pass
							else 0.0
						)
						if absf(event.angular_impulse + c * actual_angular) > 1e-12:
							return false
						reported_angular += (
							event.angular_impulse
							+ event.connector_angular_impulse
							+ event.limit_angular_impulse
							+ event.hinge_angular_impulse
						)
			if absf(actual_angular - reported_angular) > 1e-12:
				return false
		if absf(actual_x - reported_x) > 1e-12 or absf(actual_y - reported_y) > 1e-12:
			return false
	return true
