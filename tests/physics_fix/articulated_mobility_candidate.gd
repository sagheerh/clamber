# gdlint: disable=max-returns,max-line-length
extends RefCounted
## UNADOPTED. Tree-wide rigid hinge/contact mobility, not independent endpoint rows.
## Wc = W - W H^T (H W H^T)^-1 H W. No compliance, epsilon or iteration knob.
## Factors are bound to exact geometry; rebuild after ANY position/mass change.
const CONTACT_ROW = preload("res://tests/physics_fix/rigid_contact_candidate.gd")
var _weights: Array[float] = []
var _hinges: Array = []
var _factor: Array = []
var _signature: Array = []
var _configured := false


func configure(bodies: Array[CapsuleBody], parents: Array[int]) -> Error:
	if bodies.is_empty() or parents.size() != bodies.size() or parents[0] != -1:
		return ERR_INVALID_DATA
	var weights: Array[float] = []
	var signature: Array = []
	for index in range(bodies.size()):
		var body := bodies[index]
		if (
			body == null
			or not body.is_valid()
			or (index > 0 and (parents[index] < 0 or parents[index] >= index))
		):
			return ERR_INVALID_DATA
		for previous in range(index):
			if (
				body == bodies[previous]
				or body.a in [bodies[previous].a, bodies[previous].b]
				or body.b in [bodies[previous].a, bodies[previous].b]
			):
				return ERR_INVALID_DATA
		var axes := PlanarBasis.frame(body)
		if (
			axes.is_empty()
			or body.a.inverse_mass != 2.0 / body.mass
			or body.b.inverse_mass != 2.0 / body.mass
		):
			return ERR_INVALID_DATA
		weights.append_array([1.0 / body.mass, 1.0 / body.mass, axes.inverse_inertia])
		signature.append(_geometry(body))
	var hinges: Array = []
	for child in range(1, bodies.size()):
		var parent := parents[child]
		var p := PlanarBasis.frame(bodies[parent])
		var c := PlanarBasis.frame(bodies[child])
		var x := _zero(weights.size())
		var y := _zero(weights.size())
		x[3 * parent] = -1.0
		x[3 * child] = 1.0
		x[3 * parent + 2] = p.y / 2.0
		x[3 * child + 2] = c.y / 2.0
		y[3 * parent + 1] = -1.0
		y[3 * child + 1] = 1.0
		y[3 * parent + 2] = -p.x / 2.0
		y[3 * child + 2] = -c.x / 2.0
		hinges.append_array([x, y])
	var factor: Array = []
	# A tree of distinct finite-mass bodies gives full-rank hinge rows and SPD HWHt.
	# Strict positive pivots only; no invented regularizer or near-zero tolerance.
	for i in range(hinges.size()):
		var row := _zero(hinges.size())
		for j in range(i + 1):
			var value := 0.0
			for d in range(weights.size()):
				value += hinges[i][d] * weights[d] * hinges[j][d]
			for k in range(j):
				value -= row[k] * factor[j][k] if i != j else row[k] * row[k]
			if not is_finite(value) or (i == j and value <= 0.0):
				return ERR_INVALID_DATA
			row[j] = sqrt(value) if i == j else value / factor[j][j]
		factor.append(row)
	for weight in weights:
		if not is_finite(weight) or weight <= 0.0:
			return ERR_INVALID_DATA
	# Publish only after every validation/factorization succeeds.
	_weights = weights
	_hinges = hinges
	_factor = factor
	_signature = signature
	_configured = true
	return OK


func mobility(impulse: Array[float]) -> Dictionary:
	if not _configured or impulse.size() != _weights.size() or not _finite(impulse):
		return {}
	var free := _zero(impulse.size())
	for d in range(free.size()):
		free[d] = _weights[d] * impulse[d]
	var rhs := _zero(_hinges.size())
	for i in range(rhs.size()):
		rhs[i] = -_dot(_hinges[i], free)
	var reaction := _solve(rhs)
	if reaction.size() != rhs.size():
		return {}
	var delta := free.duplicate()
	for d in range(delta.size()):
		for i in range(reaction.size()):
			delta[d] += _weights[d] * _hinges[i][d] * reaction[i]
	if not _finite(delta):
		return {}
	return {"delta": delta, "hinge_impulses": reaction}


func project_velocity(bodies: Array[CapsuleBody]) -> Dictionary:
	if not _matches(bodies):
		return {}
	var velocity := _velocities(bodies)
	var rhs := _zero(_hinges.size())
	for i in range(rhs.size()):
		rhs[i] = -_dot(_hinges[i], velocity)
	var impulse := _solve(rhs)
	if impulse.size() != rhs.size():
		return {}
	var change := _zero(velocity.size())
	for d in range(change.size()):
		for i in range(impulse.size()):
			change[d] += _weights[d] * _hinges[i][d] * impulse[i]
	if _publish(bodies, change, false, null) != OK:
		return {}
	return {"delta": change, "hinge_impulses": impulse}


func contact_velocity(
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
	var target := -restitution * minf(0.0, vn)
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


func project_hinge_positions(
	bodies: Array[CapsuleBody], parents: Array[int], tuning: Tuning
) -> Dictionary:
	if not _matches(bodies) or parents.size() != bodies.size() or parents[0] != -1:
		return {}
	# Parent topology is part of the configured frame, not caller-chosen state.
	var rhs := _zero(_hinges.size())
	for child in range(1, bodies.size()):
		var parent := parents[child]
		if parent < 0 or parent >= child or _hinges[2 * (child - 1)][3 * parent] != -1.0:
			return {}
		rhs[2 * (child - 1)] = bodies[parent].b.x - bodies[child].a.x
		rhs[2 * (child - 1) + 1] = bodies[parent].b.y - bodies[child].a.y
	var multiplier := _solve(rhs)
	if multiplier.size() != rhs.size():
		return {}
	var delta := _zero(_weights.size())
	for d in range(delta.size()):
		for i in range(multiplier.size()):
			delta[d] += _weights[d] * _hinges[i][d] * multiplier[i]
	if _publish(bodies, delta, true, tuning) != OK:
		return {}
	return {"position_multipliers_kg_wu": multiplier, "delta": delta}


func contact_position(
	bodies: Array[CapsuleBody],
	part: int,
	u: float,
	nx: float,
	ny: float,
	depth: float,
	tuning: Tuning
) -> Dictionary:
	if not _matches(bodies) or not is_finite(depth) or depth < 0.0:
		return {}
	var row := _contact_row(bodies, part, u, nx, ny)
	var response := mobility(row)
	if response.is_empty():
		return {}
	var weight := _dot(row, response.delta)
	if not is_finite(weight) or weight <= 0.0:
		return {}
	var scale := depth / weight
	var delta: Array = response.delta.duplicate()
	for d in range(delta.size()):
		delta[d] *= scale
	if _publish(bodies, delta, true, tuning) != OK:
		return {}
	# Position multipliers are NOT velocity impulses, normal loads or grip credit.
	return {"position_multiplier_kg_wu": scale, "delta": delta}


func _contact_row(
	bodies: Array[CapsuleBody], part: int, u: float, nx: float, ny: float
) -> Array[float]:
	if part < 0 or part >= bodies.size():
		return []
	var frame := CONTACT_ROW.frame(bodies[part], u, nx, ny)
	if frame.is_empty():
		return []
	var row := _zero(_weights.size())
	row[3 * part] = frame.nx
	row[3 * part + 1] = frame.ny
	row[3 * part + 2] = frame.rx * frame.ny - frame.ry * frame.nx
	return row


func _publish(bodies: Array[CapsuleBody], delta: Array, position: bool, tuning: Tuning) -> Error:
	if not _finite(delta) or delta.size() != _weights.size():
		return ERR_INVALID_DATA
	if (
		position
		and (
			tuning == null
			or not is_finite(tuning.physics_max_projection_wu_tick)
			or tuning.physics_max_projection_wu_tick <= 0.0
		)
	):
		return ERR_INVALID_DATA
	var before: Array = []
	var shadows: Array[CapsuleBody] = []
	var before_energy := 0.0
	var after_energy := 0.0
	for i in range(bodies.size()):
		var body := bodies[i]
		before.append(body.snapshot())
		var shadow := CapsuleBody.new()
		if shadow.restore(before[i]) != OK:
			return ERR_INVALID_DATA
		if position:
			var axes := PlanarBasis.frame(body)
			var limit_squared: float = (
				tuning.physics_max_projection_wu_tick * tuning.physics_max_projection_wu_tick
			)
			# Bound the requested LINEAR Newton displacement before evaluating a
			# rotation. Still check actual endpoint motion afterwards as well.
			for sign_value in [-1.0, 1.0]:
				var lx: float = delta[3 * i] - sign_value * axes.y * delta[3 * i + 2] / 2.0
				var ly: float = delta[3 * i + 1] + sign_value * axes.x * delta[3 * i + 2] / 2.0
				var squared: float = lx * lx + ly * ly
				if not is_finite(squared) or squared > limit_squared:
					return ERR_PARAMETER_RANGE_ERROR
			# Scalar remainder, NOT a transcendental or a new angle tolerance.
			# A huge finite angle must never enter PlanarBasis's iterative wrap.
			var rotation: float = fmod(delta[3 * i + 2], TAU)
			if rotation != 0.0 and PlanarBasis.turn(shadow, rotation) != OK:
				return ERR_INVALID_DATA
			for point in [shadow.a, shadow.b]:
				point.x += delta[3 * i]
				point.y += delta[3 * i + 1]
			for pair in [[body.a, shadow.a], [body.b, shadow.b]]:
				var dx: float = pair[1].x - pair[0].x
				var dy: float = pair[1].y - pair[0].y
				var squared: float = dx * dx + dy * dy
				if (
					not is_finite(squared)
					or (
						squared
						> (
							tuning.physics_max_projection_wu_tick
							* tuning.physics_max_projection_wu_tick
						)
					)
				):
					return ERR_PARAMETER_RANGE_ERROR
		else:
			var axes := PlanarBasis.frame(body)
			var vx: float = (body.a.velocity_x + body.b.velocity_x) / 2.0 + delta[3 * i]
			var vy: float = (body.a.velocity_y + body.b.velocity_y) / 2.0 + delta[3 * i + 1]
			var omega: float = axes.omega + delta[3 * i + 2]
			# Exact structural projection, no velocity cutoff. Preserve COM and spin;
			# discard only the non-rigid axial endpoint mode, never actual rigid motion.
			shadow.a.velocity_x = vx + omega * axes.y / 2.0
			shadow.a.velocity_y = vy - omega * axes.x / 2.0
			shadow.b.velocity_x = vx - omega * axes.y / 2.0
			shadow.b.velocity_y = vy + omega * axes.x / 2.0
			before_energy += CONTACT_ROW.kinetic_energy(body)
			after_energy += CONTACT_ROW.kinetic_energy(shadow)
		if not shadow.is_valid():
			return ERR_INVALID_DATA
		shadows.append(shadow)
	# Keep the prior candidate's STRICT passivity barrier, not a gameplay epsilon.
	if (
		not position
		and (
			not is_finite(before_energy)
			or not is_finite(after_energy)
			or after_energy > before_energy
		)
	):
		return ERR_INVALID_DATA
	for i in range(bodies.size()):
		var status := bodies[i].restore(shadows[i].snapshot())
		if status != OK:
			for j in range(bodies.size()):
				var rollback := bodies[j].restore(before[j])
				if rollback != OK:
					return rollback
			return status
	return OK


func _solve(rhs: Array[float]) -> Array[float]:
	if rhs.size() != _factor.size() or not _finite(rhs):
		return []
	var result := rhs.duplicate()
	for i in range(result.size()):
		for j in range(i):
			result[i] -= _factor[i][j] * result[j]
		result[i] /= _factor[i][i]
	for i in range(result.size() - 1, -1, -1):
		for j in range(i + 1, result.size()):
			result[i] -= _factor[j][i] * result[j]
		result[i] /= _factor[i][i]
	return result if _finite(result) else []


func _matches(bodies: Array[CapsuleBody]) -> bool:
	if not _configured or bodies.size() != _signature.size():
		return false
	for i in range(bodies.size()):
		if bodies[i] == null or not bodies[i].is_valid() or _geometry(bodies[i]) != _signature[i]:
			return false
	return true


static func _geometry(body: CapsuleBody) -> Array:
	return [
		body.a.x, body.a.y, body.b.x, body.b.y, body.mass, body.a.inverse_mass, body.b.inverse_mass
	]


static func _velocities(bodies: Array[CapsuleBody]) -> Array[float]:
	var result: Array[float] = []
	for body in bodies:
		var axes := PlanarBasis.frame(body)
		result.append_array(
			[
				(body.a.velocity_x + body.b.velocity_x) / 2.0,
				(body.a.velocity_y + body.b.velocity_y) / 2.0,
				axes.omega
			]
		)
	return result


static func _zero(count: int) -> Array[float]:
	var result: Array[float] = []
	result.resize(count)
	result.fill(0.0)
	return result


static func _dot(first: Array, second: Array) -> float:
	var result := 0.0
	for i in range(first.size()):
		result += first[i] * second[i]
	return result


static func _finite(values: Array) -> bool:
	for value in values:
		if not is_finite(value):
			return false
	return true
