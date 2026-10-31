# gdlint: disable=max-line-length,max-returns
extends "res://tests/physics_fix/articulated_mobility_candidate.gd"
## UNADOPTED finite active-set block. Authored angular inequalities join H in the
## SAME solve. Active-set pivots are algebraic factorization, not extra PBD ticks
## or position/velocity sweeps. Original strict publication guards are inherited.
const FINITE_POSITION = preload("res://tests/physics_fix/tree_position_publication.gd")
var position_terrain: SdfGrid
var limits: Array = []
var _tree_parents: Array[int] = []
var _limits_key := PackedByteArray()


func configure(bodies: Array[CapsuleBody], parents: Array[int]) -> Error:
	var seen: Array[int] = []
	for limit in limits:
		if not limit is Dictionary:
			return ERR_INVALID_DATA
		for key in ["parent", "child", "rest_angle", "lower", "upper"]:
			if not limit.has(key) or typeof(limit[key]) not in [TYPE_INT, TYPE_FLOAT]:
				return ERR_INVALID_DATA
			if not is_finite(float(limit[key])):
				return ERR_INVALID_DATA
		var p := int(limit.parent)
		var c := int(limit.child)
		if (
			p != limit.parent
			or c != limit.child
			or c <= 0
			or c >= parents.size()
			or p != parents[c]
			or c in seen
			or limit.lower >= limit.upper
			or limit.rest_angle < -PI
			or limit.rest_angle > PI
			or limit.lower < -PI
			or limit.upper > PI
		):
			return ERR_INVALID_DATA
		if limit.has("rigid_connector_quarters"):
			var quarters = limit.rigid_connector_quarters
			if (
				typeof(quarters) != TYPE_INT
				or quarters < -2
				or quarters > 1
				or bodies[c].kind not in ["foot", "limb"]
			):
				return ERR_INVALID_DATA
		if limit.has("rigid_connector_inset_ratio"):
			var ratio = limit.rigid_connector_inset_ratio
			if (
				not limit.has("rigid_connector_quarters")
				or limit.rigid_connector_quarters not in [-1, 1]
				or typeof(ratio) not in [TYPE_INT, TYPE_FLOAT]
				or not is_finite(float(ratio))
				or ratio < 0.0
				or ratio >= 1.0
				or bodies[c].kind != "foot"
			):
				return ERR_INVALID_DATA
		seen.append(c)
	var status := super.configure(bodies, parents)
	if status == OK:
		_limits_key = var_to_bytes(limits)
		_tree_parents = parents.duplicate()
		var appended := false
		for limit in limits:
			if limit.has("rigid_connector_quarters"):
				var row := _zero(_weights.size())
				row[3 * int(limit.parent) + 2] = -1.0
				row[3 * int(limit.child) + 2] = 1.0
				_hinges.append(row)
				appended = true
		if appended:
			var factor := _factor_rows(_hinges)
			if factor.is_empty():
				_configured = false
				return ERR_INVALID_DATA
			_factor = factor
	return status


func _matches(bodies: Array[CapsuleBody]) -> bool:
	return super._matches(bodies) and var_to_bytes(limits) == _limits_key


func project_hinge_positions(
	bodies: Array[CapsuleBody], parents: Array[int], tuning: Tuning
) -> Dictionary:
	if not _matches(bodies) or parents.size() != bodies.size():
		return {}
	var free := _copies(bodies)
	var trial := super.project_hinge_positions(free, parents, tuning)
	if trial.is_empty():
		return {}
	if (
		_angles_feasible(free)
		and (position_terrain == null or FINITE_POSITION.clear(free, position_terrain, tuning))
	):
		_copy_positions(free, bodies)
		return trial
	var rhs := _zero(_hinges.size())
	for c in range(1, bodies.size()):
		var p := parents[c]
		if p < 0 or p >= c or _hinges[2 * (c - 1)][3 * p] != -1.0:
			return {}
		rhs[2 * (c - 1)] = bodies[p].b.x - bodies[c].a.x
		rhs[2 * (c - 1) + 1] = bodies[p].b.y - bodies[c].a.y
	return _position_block(bodies, rhs, [], 0.0, tuning)


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
	if row.is_empty():
		return {}
	var free := _copies(bodies)
	var trial := super.contact_position(free, part, u, nx, ny, depth, tuning)
	if trial.is_empty():
		return {}
	if (
		_angles_feasible(free)
		and (position_terrain == null or FINITE_POSITION.clear(free, position_terrain, tuning))
	):
		_copy_positions(free, bodies)
		return trial
	return _position_block(bodies, _zero(_hinges.size()), row, depth, tuning)


func _position_block(
	bodies: Array[CapsuleBody], rhs: Array[float], contact: Array, depth: float, tuning: Tuning
) -> Dictionary:
	var inequalities := _angular_inequalities(bodies, false)
	if inequalities.size() != 2 * limits.size():
		return {}
	if not contact.is_empty():
		inequalities.append({"row": contact, "rhs": depth})
	var solved := _active_solve(_hinges, rhs, inequalities)
	if solved.is_empty():
		return {}
	var finite_publication: Dictionary = {}
	if position_terrain == null and _hinges.size() == 2 * (bodies.size() - 1):
		if _publish(bodies, solved.delta, true, tuning) != OK:
			return {}
	else:
		finite_publication = FINITE_POSITION.publish(
			self, bodies, _tree_parents, solved.delta, position_terrain, tuning
		)
		if finite_publication.is_empty():
			return {}
	var normal_multiplier := 0.0
	if not contact.is_empty():
		var index: int = solved.active.find(inequalities.size() - 1)
		if index >= 0:
			normal_multiplier = solved.multipliers[_hinges.size() + index]
	return {
		"delta": solved.delta,
		"position_multipliers_kg_wu": solved.multipliers,
		"position_multiplier_kg_wu": normal_multiplier,
		"active_angular_rows": solved.active,
		"finite_position_publication": finite_publication
	}


func project_velocity(bodies: Array[CapsuleBody]) -> Dictionary:
	if not _matches(bodies):
		return {}
	if _angular_inequalities(bodies, true).is_empty():
		return super.project_velocity(bodies)
	var incoming := _velocities(bodies)
	var rhs := _zero(_hinges.size())
	for i in range(rhs.size()):
		rhs[i] = -_dot(_hinges[i], incoming)
	var inequalities := _angular_inequalities(bodies, true)
	for inequality in inequalities:
		inequality.rhs = -_dot(inequality.row, incoming)
	var solved := _active_solve(_hinges, rhs, inequalities)
	if solved.is_empty() or _publish(bodies, solved.delta, false, null) != OK:
		return {}
	return {
		"delta": solved.delta,
		"hinge_impulses": solved.multipliers.slice(0, _hinges.size()),
		"angular_impulses": solved.multipliers.slice(_hinges.size())
	}


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
		return super.contact_velocity(bodies, part, u, nx, ny, retention, restitution)
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
		var result := super.contact_velocity(work, part, u, nx, ny, retention, restitution)
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
		result.angular_impulses = result.hinge_impulses.slice(original_rows.size())
		result.hinge_impulses = result.hinge_impulses.slice(0, original_rows.size())
		return result
	return {}


func _angular_inequalities(bodies: Array[CapsuleBody], velocity: bool) -> Array:
	var result: Array = []
	for limit in limits:
		var p := PlanarBasis.frame(bodies[int(limit.parent)])
		var c := PlanarBasis.frame(bodies[int(limit.child)])
		if p.is_empty() or c.is_empty():
			return []
		var q := PlanarBasis.wrap_angle(
			PlanarBasis.angle(p.x * c.x + p.y * c.y, p.x * c.y - p.y * c.x) - limit.rest_angle
		)
		for side in [1.0, -1.0]:
			if velocity and not (q <= limit.lower if side == 1.0 else q >= limit.upper):
				continue
			var row := _zero(_weights.size())
			row[3 * int(limit.parent) + 2] = -side
			row[3 * int(limit.child) + 2] = side
			var bound: float = limit.lower if side == 1.0 else limit.upper
			result.append({"row": row, "rhs": side * (bound - q)})
	return result


func _active_solve(equalities: Array, rhs: Array[float], inequalities: Array) -> Dictionary:
	var active: Array[int] = []
	var visited: Dictionary = {}
	while true:
		var key := var_to_bytes(active).hex_encode()
		if visited.has(key):
			return {}  # Degenerate/cycling active sets fail closed, never regularize.
		visited[key] = true
		var rows := equalities.duplicate()
		var values := rhs.duplicate()
		for index in active:
			rows.append(inequalities[index].row)
			values.append(float(inequalities[index].rhs))
		var factor := _factor_rows(rows)
		if factor.is_empty() and not rows.is_empty():
			return {}
		var saved := _factor
		_factor = factor
		var multipliers := _solve(values)
		_factor = saved
		if multipliers.size() != rows.size():
			return {}
		var delta := _zero(_weights.size())
		for d in range(delta.size()):
			for i in range(rows.size()):
				delta[d] += _weights[d] * rows[i][d] * multipliers[i]
		if not _finite(delta):
			return {}
		# A negative active normal multiplier is a tensile contact, hence not
		# dual-feasible. Remove it BEFORE adding another violated constraint;
		# otherwise a known-invalid contact can create a singular supersystem.
		# Strict signs/order/visited-set failclosed policy remain unchanged.
		var pivot := -1
		for i in range(active.size()):
			if multipliers[equalities.size() + i] < 0.0:
				pivot = i
				break
		if pivot >= 0:
			active.remove_at(pivot)
			continue
		for i in range(inequalities.size()):
			if i not in active and _dot(inequalities[i].row, delta) < inequalities[i].rhs:
				pivot = i
				break
		if pivot >= 0:
			active.append(pivot)
			continue
		return {"delta": delta, "multipliers": multipliers, "active": active}
	return {}


func _factor_rows(rows: Array) -> Array:
	var factor: Array = []
	for i in range(rows.size()):
		var row := _zero(rows.size())
		for j in range(i + 1):
			var value := 0.0
			for d in range(_weights.size()):
				value += rows[i][d] * _weights[d] * rows[j][d]
			for k in range(j):
				value -= row[k] * factor[j][k] if i != j else row[k] * row[k]
			if not is_finite(value) or (i == j and value <= 0.0):
				return []
			row[j] = sqrt(value) if i == j else value / factor[j][j]
		factor.append(row)
	return factor


func _angles_feasible(bodies: Array[CapsuleBody]) -> bool:
	for child in range(1, bodies.size()):
		var axis := rigid_axis(bodies, child)
		if not axis.is_empty():
			if (
				bodies[child].b.x != bodies[child].a.x + axis[0]
				or bodies[child].b.y != bodies[child].a.y + axis[1]
			):
				return false
	for inequality in _angular_inequalities(bodies, false):
		if inequality.rhs > 0.0:
			return false
	return true


func _copies(bodies: Array[CapsuleBody]) -> Array[CapsuleBody]:
	var work: Array[CapsuleBody] = []
	for body in bodies:
		var copy := CapsuleBody.new()
		if copy.restore(body.snapshot()) != OK:
			return []
		work.append(copy)
	return work


func _copy_positions(source: Array[CapsuleBody], target: Array[CapsuleBody]) -> void:
	for i in range(source.size()):
		target[i].a.x = source[i].a.x
		target[i].a.y = source[i].a.y
		target[i].b.x = source[i].b.x
		target[i].b.y = source[i].b.y


## Authored rigid attachment, never a world/upright target or stiffness knob.
func rigid_axis(bodies: Array[CapsuleBody], child: int) -> Array[float]:
	for limit in limits:
		if limit.child != child or not limit.has("rigid_connector_quarters"):
			continue
		var parent := PlanarBasis.frame(bodies[int(limit.parent)])
		if parent.is_empty():
			return []
		var scale: float = bodies[child].rest_length / sqrt(parent.squared)
		var x: float = parent.x * scale
		var y: float = parent.y * scale
		if limit.has("rigid_connector_inset_ratio"):
			var longitudinal: float = limit.rigid_connector_inset_ratio
			var transverse: float = (
				limit.rigid_connector_quarters * sqrt(1.0 - longitudinal * longitudinal)
			)
			return [x * longitudinal - y * transverse, y * longitudinal + x * transverse]
		match int(limit.rigid_connector_quarters):
			-2:
				return [-x, -y]
			-1:
				return [y, -x]
			0:
				return [x, y]
			1:
				return [-y, x]
	return []
