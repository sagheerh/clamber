# gdlint: disable=max-line-length,max-returns
extends RefCounted
## Exact constrained resolvent of per-body angular drag. No linear shape drag.
const KERNEL = preload("res://tests/physics_fix/local_angular_constitutive_kernel.gd")
const GUARD = preload("res://tests/physics_fix/constitutive_stage_guard.gd")
const ENERGY = preload("res://tests/physics_fix/rigid_contact_candidate.gd")


static func apply(
	bodies: Array[CapsuleBody], parents: Array[int], damping: float, limits: Array = []
) -> Dictionary:
	if not is_finite(damping) or damping < 0.0 or damping > 1.0:
		return {"status": ERR_INVALID_DATA, "reason": "invalid local angular coefficient"}
	var kernel := KERNEL.new()
	kernel.angular_retention = 1.0 - damping
	kernel.limits = limits
	if kernel.configure(bodies, parents) != OK:
		return {"status": ERR_INVALID_DATA, "reason": "invalid angular resolvent"}
	var uniform: bool = true
	for body in bodies:
		for point in [body.a, body.b]:
			uniform = (
				uniform
				and point.velocity_x == bodies[0].a.velocity_x
				and point.velocity_y == bodies[0].a.velocity_y
			)
	if damping == 0.0 or uniform:
		return _identity(bodies)
	var origin: Array = []
	var work: Array[CapsuleBody] = []
	var raw: Array[float] = kernel._velocities(bodies)
	for i in range(bodies.size()):
		origin.append(bodies[i].snapshot())
		var body := CapsuleBody.new()
		if body.restore(origin[i]) != OK:
			return {"status": ERR_INVALID_DATA}
		var axes: Dictionary = PlanarBasis.frame(body)
		var omega: float = (1.0 - damping) * raw[3 * i + 2]
		body.a.velocity_x = raw[3 * i] + omega * axes.y / 2.0
		body.a.velocity_y = raw[3 * i + 1] - omega * axes.x / 2.0
		body.b.velocity_x = raw[3 * i] - omega * axes.y / 2.0
		body.b.velocity_y = raw[3 * i + 1] + omega * axes.x / 2.0
		work.append(body)
	var incoming: Array[float] = kernel._velocities(work)
	var rhs: Array[float] = kernel._zero(kernel._hinges.size())
	for i in range(rhs.size()):
		rhs[i] = -kernel._dot(kernel._hinges[i], incoming)
	var inequalities: Array = kernel._angular_inequalities(work, true)
	for inequality in inequalities:
		inequality.rhs = -kernel._dot(inequality.row, incoming)
	var solved: Dictionary = kernel._active_solve(kernel._hinges, rhs, inequalities)
	if solved.is_empty() or kernel._publish(work, solved.delta, false, null) != OK:
		return {"status": ERR_INVALID_DATA, "reason": "angular constrained free solve"}
	var checked: Dictionary = GUARD.validate(origin, work)
	if checked.status != OK:
		return checked
	var impulses: Array = []
	for i in range(bodies.size()):
		impulses.append(
			{
				"x":
				(
					bodies[i].mass
					* (
						(work[i].a.velocity_x + work[i].b.velocity_x)
						- (bodies[i].a.velocity_x + bodies[i].b.velocity_x)
					)
					/ 2.0
				),
				"y":
				(
					bodies[i].mass
					* (
						(work[i].a.velocity_y + work[i].b.velocity_y)
						- (bodies[i].a.velocity_y + bodies[i].b.velocity_y)
					)
					/ 2.0
				)
			}
		)
	var subtree: Array = impulses.duplicate(true)
	for i in range(work.size() - 1, 0, -1):
		subtree[parents[i]].x += subtree[i].x
		subtree[parents[i]].y += subtree[i].y
	var hinges: Array[float] = []
	var events: Array = []
	for i in range(work.size()):
		var axes: Dictionary = PlanarBasis.frame(bodies[i])
		var after: Dictionary = PlanarBasis.frame(work[i])
		var internal: float = 0.0
		if i > 0:
			hinges.append_array([subtree[i].x, subtree[i].y])
			internal += (-axes.x * subtree[i].y + axes.y * subtree[i].x) / 2.0
		for child in range(i + 1, work.size()):
			if parents[child] == i:
				internal += (-axes.x * subtree[child].y + axes.y * subtree[child].x) / 2.0
		var stop: float = 0.0
		for j in range(solved.active.size()):
			stop += (
				inequalities[solved.active[j]].row[3 * i + 2]
				* solved.multipliers[kernel._hinges.size() + j]
			)
		var connector := 0.0
		for row in range(2 * (bodies.size() - 1), kernel._hinges.size()):
			connector += kernel._hinges[row][3 * i + 2] * solved.multipliers[row]
		var actual_drag: float = (
			(after.omega - axes.omega) / axes.inverse_inertia - internal - stop - connector
		)
		events.append(
			{
				"part": i,
				"omega_before": axes.omega,
				"omega_projected": raw[3 * i + 2],
				"requested_delta_omega": -damping * raw[3 * i + 2],
				"omega_after": after.omega,
				"external_angular_impulse": actual_drag,
				"hinge_angular_impulse": internal,
				"limit_angular_impulse": stop,
				"connector_angular_impulse": connector,
				"body_linear_impulse_x_ns": impulses[i].x,
				"body_linear_impulse_y_ns": impulses[i].y,
				"energy_before": ENERGY.kinetic_energy(bodies[i]),
				"energy_after": ENERGY.kinetic_energy(work[i]),
				"scope": "local angular resistance on actual final spin; no linear shape drag"
			}
		)
	for i in range(work.size()):
		bodies[i].a.velocity_x = work[i].a.velocity_x
		bodies[i].a.velocity_y = work[i].a.velocity_y
		bodies[i].b.velocity_x = work[i].b.velocity_x
		bodies[i].b.velocity_y = work[i].b.velocity_y
	return {
		"status": OK,
		"events": events,
		"hinge_impulses": hinges,
		"external_linear_impulse_x_ns": subtree[0].x,
		"external_linear_impulse_y_ns": subtree[0].y
	}


static func _identity(bodies: Array[CapsuleBody]) -> Dictionary:
	var hinges: Array[float] = []
	hinges.resize(2 * (bodies.size() - 1))
	hinges.fill(0.0)
	var events: Array = []
	for i in range(bodies.size()):
		var axes: Dictionary = PlanarBasis.frame(bodies[i])
		events.append(
			{
				"part": i,
				"omega_before": axes.omega,
				"omega_projected": axes.omega,
				"requested_delta_omega": 0.0,
				"omega_after": axes.omega,
				"external_angular_impulse": 0.0,
				"hinge_angular_impulse": 0.0,
				"limit_angular_impulse": 0.0,
				"body_linear_impulse_x_ns": 0.0,
				"body_linear_impulse_y_ns": 0.0,
				"energy_before": ENERGY.kinetic_energy(bodies[i]),
				"energy_after": ENERGY.kinetic_energy(bodies[i])
			}
		)
	return {
		"status": OK,
		"events": events,
		"hinge_impulses": hinges,
		"external_linear_impulse_x_ns": 0.0,
		"external_linear_impulse_y_ns": 0.0
	}
