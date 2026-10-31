# gdlint: disable=max-line-length,max-returns
extends "res://tests/physics_fix/impact_history_mobility.gd"
## Same physical operator, corrected actual capsule-surface contact rows.
const SURFACE = preload("res://tests/physics_fix/capsule_surface_frame.gd")


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
	var rows: Dictionary = SURFACE.rows(bodies, part, u, nx, ny)
	if rows.is_empty():
		return {}
	var normal: Array[float] = rows.normal
	var tangent: Array[float] = rows.tangent
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
