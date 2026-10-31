# gdlint: disable=max-line-length,max-returns
extends RefCounted
## UNADOPTED constitutive operator for the existing angular damping fraction.
## Project into articulated velocities, then damp ANGULAR degrees, preserving COM
## momentum. No world-angle target, position edit, energy epsilon or repair scale.
## Only the combined, detached physical operator is published, with strict energy.
const NETWORK = preload("res://tests/physics_fix/articulated_mobility_candidate.gd")
const ENERGY = preload("res://tests/physics_fix/rigid_contact_candidate.gd")


static func apply(bodies: Array[CapsuleBody], parents: Array[int], damping: float) -> Dictionary:
	if not is_finite(damping) or damping < 0.0 or damping > 1.0:
		return {"status": ERR_INVALID_DATA, "reason": "invalid angular damping"}
	var network := NETWORK.new()
	if network.configure(bodies, parents) != OK:
		return {"status": ERR_INVALID_DATA, "reason": "invalid drag tree"}
	var mass := 0.0
	var px := 0.0
	var py := 0.0
	var energy_before := 0.0
	var uniform := true
	var work: Array[CapsuleBody] = []
	for body in bodies:
		mass += body.mass
		px += body.mass * (body.a.velocity_x + body.b.velocity_x) / 2.0
		py += body.mass * (body.a.velocity_y + body.b.velocity_y) / 2.0
		energy_before += ENERGY.kinetic_energy(body)
		for point in [body.a, body.b]:
			uniform = (
				uniform
				and point.velocity_x == bodies[0].a.velocity_x
				and point.velocity_y == bodies[0].a.velocity_y
			)
		var copy := CapsuleBody.new()
		if copy.restore(body.snapshot()) != OK:
			return {"status": ERR_INVALID_DATA, "reason": "drag shadow restore"}
		work.append(copy)
	if (
		not is_finite(mass)
		or mass <= 0.0
		or not is_finite(px)
		or not is_finite(py)
		or not is_finite(energy_before)
	):
		return {"status": ERR_INVALID_DATA, "reason": "nonfinite drag mass/momentum/energy"}
	var incoming := network._velocities(bodies)
	var projected := incoming.duplicate()
	if damping != 0.0 and not uniform:
		# This is ONE composite drag operator, not a separately published hinge
		# projection whose roundoff is fed back as a physical constraint impulse.
		var rhs := NETWORK._zero(network._hinges.size())
		for i in range(rhs.size()):
			rhs[i] = -NETWORK._dot(network._hinges[i], incoming)
		var reaction := network._solve(rhs)
		if reaction.size() != rhs.size():
			return {"status": ERR_INVALID_DATA, "reason": "drag factor solve"}
		for d in range(projected.size()):
			for i in range(reaction.size()):
				projected[d] += network._weights[d] * network._hinges[i][d] * reaction[i]
		if not NETWORK._finite(projected):
			return {"status": ERR_INVALID_DATA, "reason": "nonfinite projected drag rates"}
		# Canonical tree velocities at the requested angular rates. Root velocity
		# is solved from total COM momentum, never from a stationary/upright goal.
		for i in range(work.size()):
			var axes := PlanarBasis.frame(bodies[i])
			var omega: float = (1.0 - damping) * projected[3 * i + 2]
			work[i].a.velocity_x = 0.0 if i == 0 else work[parents[i]].b.velocity_x
			work[i].a.velocity_y = 0.0 if i == 0 else work[parents[i]].b.velocity_y
			work[i].b.velocity_x = work[i].a.velocity_x - omega * axes.y
			work[i].b.velocity_y = work[i].a.velocity_y + omega * axes.x
		var provisional_x := 0.0
		var provisional_y := 0.0
		for body in work:
			provisional_x += body.mass * (body.a.velocity_x + body.b.velocity_x) / 2.0
			provisional_y += body.mass * (body.a.velocity_y + body.b.velocity_y) / 2.0
		var root_x := (px - provisional_x) / mass
		var root_y := (py - provisional_y) / mass
		for body in work:
			for point in [body.a, body.b]:
				point.velocity_x += root_x
				point.velocity_y += root_y
	var energy_after := 0.0
	var body_impulses: Array = []
	for i in range(work.size()):
		if not work[i].is_valid():
			return {"status": ERR_INVALID_DATA, "reason": "invalid final drag state"}
		energy_after += ENERGY.kinetic_energy(work[i])
		body_impulses.append(
			{
				"x":
				(
					work[i].mass
					* (
						(work[i].a.velocity_x + work[i].b.velocity_x)
						- (bodies[i].a.velocity_x + bodies[i].b.velocity_x)
					)
					/ 2.0
				),
				"y":
				(
					work[i].mass
					* (
						(work[i].a.velocity_y + work[i].b.velocity_y)
						- (bodies[i].a.velocity_y + bodies[i].b.velocity_y)
					)
					/ 2.0
				)
			}
		)
	if not is_finite(energy_after) or energy_after > energy_before:
		return {
			"status": ERR_INVALID_DATA,
			"reason": "strict composite drag passivity",
			"energy_before": energy_before,
			"energy_after": energy_after
		}
	var subtree: Array = body_impulses.duplicate(true)
	for child in range(work.size() - 1, 0, -1):
		subtree[parents[child]].x += subtree[child].x
		subtree[parents[child]].y += subtree[child].y
	var hinges: Array[float] = []
	var events: Array = []
	for i in range(work.size()):
		var axes := PlanarBasis.frame(bodies[i])
		var after := PlanarBasis.frame(work[i])
		var internal_torque := 0.0
		if i > 0:
			hinges.append_array([subtree[i].x, subtree[i].y])
			internal_torque += (-axes.x * subtree[i].y + axes.y * subtree[i].x) / 2.0
		for child in range(i + 1, work.size()):
			if parents[child] == i:
				internal_torque += (-axes.x * subtree[child].y + axes.y * subtree[child].x) / 2.0
		var angular_impulse: float = (after.omega - axes.omega) / axes.inverse_inertia
		events.append(
			{
				"part": i,
				"omega_before": axes.omega,
				"omega_projected": projected[3 * i + 2],
				"requested_delta_omega": -damping * projected[3 * i + 2],
				"omega_after": after.omega,
				"external_angular_impulse": angular_impulse - internal_torque,
				"hinge_angular_impulse": internal_torque,
				"body_linear_impulse_x_ns": body_impulses[i].x,
				"body_linear_impulse_y_ns": body_impulses[i].y,
				"energy_before": ENERGY.kinetic_energy(bodies[i]),
				"energy_after": ENERGY.kinetic_energy(work[i])
			}
		)
	# No callbacks/fallible restores after publication starts. Positions, previous
	# positions, masses, grounded/gripping flags and applied loads are untouched.
	for i in range(bodies.size()):
		bodies[i].a.velocity_x = work[i].a.velocity_x
		bodies[i].a.velocity_y = work[i].a.velocity_y
		bodies[i].b.velocity_x = work[i].b.velocity_x
		bodies[i].b.velocity_y = work[i].b.velocity_y
	return {
		"status": OK,
		"events": events,
		"hinge_impulses": hinges,
		"external_linear_impulse_x_ns": subtree[0].x,
		"external_linear_impulse_y_ns": subtree[0].y,
		"energy_before": energy_before,
		"energy_after": energy_after
	}
