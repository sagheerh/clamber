# gdlint: disable=max-line-length,max-returns
extends "res://tests/physics_fix/limited_articulated_mobility_candidate.gd"
## Same UNDAMPED contact mobility/strict energy. Restitution uses pre-force motion.
var history: Array = []
var _history_key := PackedByteArray()


func configure(bodies: Array[CapsuleBody], parents: Array[int]) -> Error:
	if not history.is_empty():
		if history.size() != bodies.size():
			return ERR_INVALID_DATA
		for i in range(history.size()):
			var old := CapsuleBody.new()
			if not history[i] is Dictionary or old.restore(history[i]) != OK or bodies[i] == null:
				return ERR_INVALID_DATA
			if (
				old.mass != bodies[i].mass
				or old.radius != bodies[i].radius
				or old.rest_length != bodies[i].rest_length
				or old.kind != bodies[i].kind
			):
				return ERR_INVALID_DATA
	var status := super.configure(bodies, parents)
	if status == OK:
		_history_key = var_to_bytes(history)
	return status


func _matches(bodies: Array[CapsuleBody]) -> bool:
	return super._matches(bodies) and _history_key == var_to_bytes(history)


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
