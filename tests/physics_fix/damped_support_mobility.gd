# gdlint: disable=max-line-length,max-returns
extends "res://tests/physics_fix/limited_articulated_mobility_candidate.gd"
## UNADOPTED: same angular fraction in the SUPPORT impulse mobility.
## Kd = r*W_H + (1-r)*T; T preserves common COM translation. No energy allowance.
## Restitution targets pre-force closing motion, not freshly applied gravity.
var angular_retention: float = 0.2
var history: Array = []
var _history_key := PackedByteArray()
var _retention_key: float
var _contact_mode := false
var _body_masses: Array[float] = []


func configure(bodies: Array[CapsuleBody], parents: Array[int]) -> Error:
	if not is_finite(angular_retention) or angular_retention < 0.0 or angular_retention > 1.0:
		return ERR_INVALID_DATA
	if not history.is_empty():
		if history.size() != bodies.size():
			return ERR_INVALID_DATA
		for i in range(history.size()):
			var old := CapsuleBody.new()
			if not history[i] is Dictionary or old.restore(history[i]) != OK or bodies[i] == null:
				return ERR_INVALID_DATA
			if (
				old.mass != bodies[i].mass
				or old.rest_length != bodies[i].rest_length
				or old.kind != bodies[i].kind
			):
				return ERR_INVALID_DATA
	var status := super.configure(bodies, parents)
	if status == OK:
		_history_key = var_to_bytes(history)
		_retention_key = angular_retention
		_body_masses = []
		for body in bodies:
			_body_masses.append(body.mass)
	return status


func _matches(bodies: Array[CapsuleBody]) -> bool:
	return (
		super._matches(bodies)
		and _history_key == var_to_bytes(history)
		and angular_retention == _retention_key
	)


func mobility(impulse: Array[float]) -> Dictionary:
	var result := super.mobility(impulse)
	if result.is_empty() or not _contact_mode or angular_retention == 1.0:
		return result
	var total := 0.0
	var jx := 0.0
	var jy := 0.0
	for i in range(_body_masses.size()):
		total += _body_masses[i]
		jx += impulse[3 * i]
		jy += impulse[3 * i + 1]
	for i in range(_body_masses.size()):
		result.delta[3 * i] = (
			angular_retention * result.delta[3 * i] + (1.0 - angular_retention) * jx / total
		)
		result.delta[3 * i + 1] = (
			angular_retention * result.delta[3 * i + 1] + (1.0 - angular_retention) * jy / total
		)
		result.delta[3 * i + 2] *= angular_retention
	return result


func normal_target(part: int, u: float, nx: float, ny: float, restitution: float) -> float:
	if (
		part < 0
		or part >= history.size()
		or not is_finite(u)
		or u < 0.0
		or u > 1.0
		or not is_finite(restitution)
		or restitution < 0.0
		or restitution > 1.0
	):
		return NAN
	var squared := nx * nx + ny * ny
	if not is_finite(squared) or squared <= 0.0:
		return NAN
	var length := sqrt(squared)
	nx /= length
	ny /= length
	var old: Dictionary = history[part]
	var vx: float = (1.0 - u) * old.a.velocity_x + u * old.b.velocity_x
	var vy: float = (1.0 - u) * old.a.velocity_y + u * old.b.velocity_y
	return -restitution * minf(0.0, vx * nx + vy * ny)


func contact_velocity(
	bodies: Array[CapsuleBody],
	part: int,
	u: float,
	nx: float,
	ny: float,
	retention: float,
	restitution: float
) -> Dictionary:
	if not _matches(bodies) or history.size() != bodies.size():
		return {}
	var squared := nx * nx + ny * ny
	if not is_finite(squared) or squared <= 0.0:
		return {}
	var length := sqrt(squared)
	nx /= length
	ny /= length
	var before := _copies(bodies)
	_contact_mode = true
	var result := _limited_contact(bodies, part, u, nx, ny, retention, restitution)
	_contact_mode = false
	if result.is_empty():
		return {}
	return _measured_reaction(before, bodies, part, u, nx, ny, result)


func _measured_reaction(
	before: Array[CapsuleBody],
	after: Array[CapsuleBody],
	part: int,
	u: float,
	nx: float,
	ny: float,
	result: Dictionary
) -> Dictionary:
	# Body momentum minus ACTUAL external terrain impulse gives internal tree
	# reactions. Do not label the undamped factor's multiplier as a measured load.
	var fx: float = nx * result.normal_impulse_ns - ny * result.tangential_impulse_ns
	var fy: float = ny * result.normal_impulse_ns + nx * result.tangential_impulse_ns
	var changes: Array = []
	for i in range(before.size()):
		changes.append(
			{
				"x":
				(
					(
						before[i].mass
						* (
							(after[i].a.velocity_x + after[i].b.velocity_x)
							- (before[i].a.velocity_x + before[i].b.velocity_x)
						)
						/ 2.0
					)
					- (fx if i == part else 0.0)
				),
				"y":
				(
					(
						before[i].mass
						* (
							(after[i].a.velocity_y + after[i].b.velocity_y)
							- (before[i].a.velocity_y + before[i].b.velocity_y)
						)
						/ 2.0
					)
					- (fy if i == part else 0.0)
				)
			}
		)
	var subtree: Array = changes.duplicate(true)
	for c in range(before.size() - 1, 0, -1):
		subtree[_tree_parents[c]].x += subtree[c].x
		subtree[_tree_parents[c]].y += subtree[c].y
	var hinges: Array[float] = []
	for c in range(1, before.size()):
		hinges.append_array([subtree[c].x, subtree[c].y])
	var events: Array = []
	for i in range(before.size()):
		var axes := PlanarBasis.frame(before[i])
		var internal := 0.0
		if i > 0:
			internal += (-axes.x * subtree[i].y + axes.y * subtree[i].x) / 2.0
		for c in range(i + 1, before.size()):
			if _tree_parents[c] == i:
				internal += (-axes.x * subtree[c].y + axes.y * subtree[c].x) / 2.0
		var angular_limit := 0.0
		for a in range(result.get("angular_rows", []).size()):
			angular_limit += result.angular_rows[a][3 * i + 2] * result.angular_impulses[a]
		var terrain: float = ((u - 0.5) * (axes.x * fy - axes.y * fx)) if i == part else 0.0
		var actual: float = (PlanarBasis.frame(after[i]).omega - axes.omega) / axes.inverse_inertia
		events.append(
			{
				"part": i,
				"angular_impulse": actual - internal - terrain - angular_limit,
				"hinge_angular_impulse": internal,
				"terrain_angular_impulse": terrain,
				"limit_angular_impulse": angular_limit,
				"body_internal_x_ns": changes[i].x,
				"body_internal_y_ns": changes[i].y
			}
		)
	result.hinge_impulses = hinges
	result.angular_drag_events = events
	result.external_linear_residual = subtree[0]
	return result


func _limited_contact(
	bodies: Array[CapsuleBody],
	part: int,
	u: float,
	nx: float,
	ny: float,
	retention: float,
	restitution: float
) -> Dictionary:
	if not _matches(bodies):
		return {}
	var constraints := _angular_inequalities(bodies, true)
	if constraints.is_empty():
		return _free_contact(bodies, part, u, nx, ny, retention, restitution)
	var original_rows := _hinges
	var original_factor := _factor
	var active: Array[int] = []
	var visited: Dictionary = {}
	while true:
		var key := var_to_bytes(active).hex_encode()
		if visited.has(key):
			return {}
		visited[key] = true
		var rows := original_rows.duplicate()
		for index in active:
			rows.append(constraints[index].row)
		var factor := _factor_rows(rows)
		if factor.is_empty() and not rows.is_empty():
			return {}
		_hinges = rows
		_factor = factor
		var work: Array[CapsuleBody] = []
		for body in bodies:
			var copy := CapsuleBody.new()
			if copy.restore(body.snapshot()) != OK:
				_hinges = original_rows
				_factor = original_factor
				return {}
			work.append(copy)
		var result := _free_contact(work, part, u, nx, ny, retention, restitution)
		_hinges = original_rows
		_factor = original_factor
		if result.is_empty():
			return {}
		var final_velocity := _velocities(work)
		var pivot := -1
		for i in range(constraints.size()):
			if i not in active and _dot(constraints[i].row, final_velocity) < 0.0:
				pivot = i
				break
		if pivot >= 0:
			active.append(pivot)
			continue
		for i in range(active.size()):
			if result.hinge_impulses[original_rows.size() + i] < 0.0:
				pivot = i
				break
		if pivot >= 0:
			active.remove_at(pivot)
			continue
		# super has already checked strict passivity on detached bodies. Publish
		# velocity only; no endpoint position, flags or loads are invented here.
		for i in range(bodies.size()):
			bodies[i].a.velocity_x = work[i].a.velocity_x
			bodies[i].a.velocity_y = work[i].a.velocity_y
			bodies[i].b.velocity_x = work[i].b.velocity_x
			bodies[i].b.velocity_y = work[i].b.velocity_y
		result.angular_rows = []
		for index in active:
			result.angular_rows.append(constraints[index].row)
		result.angular_impulses = result.hinge_impulses.slice(original_rows.size())
		result.hinge_impulses = result.hinge_impulses.slice(0, original_rows.size())
		return result
	return {}


func _free_contact(
	bodies: Array[CapsuleBody],
	part: int,
	u: float,
	nx: float,
	ny: float,
	retention: float,
	restitution: float
) -> Dictionary:
	if (
		not _matches(bodies)
		or not is_finite(retention)
		or retention < 0.0
		or retention > 1.0
		or not is_finite(restitution)
		or restitution < 0.0
		or restitution > 1.0
	):
		return {}
	var normal := _contact_row(bodies, part, u, nx, ny)
	var tangent := _contact_row(bodies, part, u, -ny, nx)
	if normal.is_empty() or tangent.is_empty():
		return {}
	var nr := mobility(normal)
	var tr := mobility(tangent)
	if nr.is_empty() or tr.is_empty():
		return {}
	var knn := _dot(normal, nr.delta)
	var ktt := _dot(tangent, tr.delta)
	var knt := _dot(normal, tr.delta)
	var determinant := knn * ktt - knt * knt
	if not is_finite(determinant) or knn <= 0.0 or ktt <= 0.0 or determinant <= 0.0:
		return {}
	# Include initial hinge projection in the SAME shadow transaction. Contact
	# preserves hinge velocity constraints, instead of reopening the hinge after it.
	var incoming := _velocities(bodies)
	var rhs := _zero(_hinges.size())
	for i in range(rhs.size()):
		rhs[i] = -_dot(_hinges[i], incoming)
	var hinge := _solve(rhs)
	if hinge.size() != rhs.size():
		return {}
	var base := _zero(incoming.size())
	for d in range(base.size()):
		for i in range(hinge.size()):
			base[d] += _weights[d] * _hinges[i][d] * hinge[i]
	var projected := incoming.duplicate()
	for d in range(projected.size()):
		projected[d] += base[d]
	var vn := _dot(normal, projected)
	var vt := _dot(tangent, projected)
	var target := normal_target(part, u, nx, ny, restitution)
	if not is_finite(target):
		return {}
	var normal_only := maxf(0.0, (target - vn) / knn)
	var tangent_target := (vt + knt * normal_only) * retention
	var dn := target - vn
	var dt := tangent_target - vt
	var jn := (dn * ktt - dt * knt) / determinant
	var jt := (dt * knn - dn * knt) / determinant
	if jn < 0.0:
		jn = 0.0
		jt = dt / ktt
	if angular_retention == 0.0:
		for value in hinge:
			if value != 0.0:
				return {}
	else:
		for i in range(hinge.size()):
			hinge[i] /= angular_retention
	var delta := base.duplicate()
	for d in range(delta.size()):
		delta[d] += nr.delta[d] * jn + tr.delta[d] * jt
	for i in range(hinge.size()):
		hinge[i] += nr.hinge_impulses[i] * jn + tr.hinge_impulses[i] * jt
	if not _finite(delta) or not _finite(hinge) or not is_finite(jn) or not is_finite(jt):
		return {}
	if _publish(bodies, delta, false, null) != OK:
		return {}
	return {
		"normal_impulse_ns": jn,
		"tangential_impulse_ns": jt,
		"hinge_impulses": hinge,
		"delta": delta,
		"normal_target": target,
		"tangent_target": tangent_target
	}
