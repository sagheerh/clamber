# gdlint: disable=max-line-length,max-returns
extends RefCounted
## One direct unilateral terrain block, not more contact sweeps. Normals are
## solved together; static tangential response cannot reopen an earlier support.
const ROW = preload("res://tests/physics_fix/capsule_surface_frame.gd")


static func solve(kernel: RefCounted, bodies: Array[CapsuleBody], contacts: Array) -> Dictionary:
	if not kernel._matches(bodies):
		return {}
	var incoming: Array[float] = kernel._velocities(bodies)
	var normal: Array = []
	var groups: Array[int] = []
	for i in range(bodies.size()):
		groups.append(i)
	for limit in kernel.limits:
		if limit.has("rigid_connector_quarters"):
			groups[int(limit.child)] = groups[int(limit.parent)]
	var constraints: Array = kernel._angular_inequalities(bodies, true)
	for item in constraints:
		item.rhs = -kernel._dot(item.row, incoming)
	for index in range(contacts.size()):
		if not contacts[index] is Dictionary:
			return {}
		for key in ["part", "u", "nx", "ny", "restitution", "damping", "static_threshold"]:
			if (
				not contacts[index].has(key)
				or typeof(contacts[index][key]) not in [TYPE_INT, TYPE_FLOAT]
				or not is_finite(float(contacts[index][key]))
			):
				return {}
		if (
			typeof(contacts[index].part) != TYPE_INT
			or contacts[index].part < 0
			or contacts[index].part >= bodies.size()
			or contacts[index].damping < 0.0
			or contacts[index].damping > 1.0
			or contacts[index].static_threshold < 0.0
		):
			return {}
		var contact: Dictionary = contacts[index]
		var rows: Dictionary = ROW.rows(bodies, contact.part, contact.u, contact.nx, contact.ny)
		if rows.is_empty():
			return {}
		var target: float = kernel.normal_target(
			contact.part, contact.u, contact.nx, contact.ny, contact.restitution
		)
		if not is_finite(target):
			return {}
		var frame: Dictionary = ROW.frame(bodies[contact.part], contact.u, contact.nx, contact.ny)
		var x: float = (bodies[contact.part].a.x + bodies[contact.part].b.x) / 2.0 + frame.rx
		var y: float = (bodies[contact.part].a.y + bodies[contact.part].b.y) / 2.0 + frame.ry
		var record := {
			"row": rows.normal,
			"tangent": rows.tangent,
			"rhs": target - kernel._dot(rows.normal, incoming),
			"target": target,
			"contact": index,
			"group": groups[contact.part],
			"nx": frame.nx,
			"ny": frame.ny,
			"coordinate": x * frame.ny - y * frame.nx
		}
		# Coincident normal lines in one rigid cluster are one support constraint.
		# Keep an actual material point; no pooled body load or manufactured N.
		var duplicate := false
		for previous in normal:
			if (
				previous.group == record.group
				and previous.nx == record.nx
				and previous.ny == record.ny
				and previous.coordinate == record.coordinate
				and previous.target >= record.target
			):
				duplicate = true
				break
		if not duplicate:
			normal.append(record)
	var base: Array = kernel._hinges.duplicate()
	var rhs: Array[float] = kernel._zero(base.size())
	for i in range(base.size()):
		rhs[i] = -kernel._dot(base[i], incoming)
	var all_constraints: Array = constraints + normal
	var first: Dictionary = kernel._active_solve(base, rhs, all_constraints)
	if first.is_empty():
		return {}
	var after_normal: Array[float] = incoming.duplicate()
	for d in range(incoming.size()):
		after_normal[d] += first.delta[d]
	var chosen: Dictionary = {}
	for index in first.active:
		if index < constraints.size():
			continue
		var item: Dictionary = normal[index - constraints.size()]
		var contact: Dictionary = contacts[item.contact]
		var coefficient: float = contact.damping
		# Existing min(material), foot bias, and static threshold, not force tuning.
		if absf(kernel._dot(item.tangent, incoming)) < contact.static_threshold:
			coefficient = 1.0
		if not chosen.has(item.group) or coefficient > chosen[item.group].coefficient:
			chosen[item.group] = {"item": item, "coefficient": coefficient}
	var tangent_records: Array = []
	for group in chosen:
		var choice: Dictionary = chosen[group]
		var item: Dictionary = choice.item
		var target: float = (1.0 - choice.coefficient) * kernel._dot(item.tangent, after_normal)
		base.append(item.tangent)
		rhs.append(target - kernel._dot(item.tangent, incoming))
		tangent_records.append({"item": item, "target": target})
	var solved: Dictionary = kernel._active_solve(base, rhs, all_constraints)
	if solved.is_empty():
		return {}
	var delta: Array[float] = solved.delta
	# Exact parameterization of a fully constrained static rigid patch: two
	# distinct parallel supports at target0 plus actual static tangent target0
	# mathematically have vx=vy=omega=0. This is NOT a velocity epsilon/parking.
	for tangent in tangent_records:
		if tangent.target != 0.0 or chosen[tangent.item.group].coefficient != 1.0:
			continue
		var support: Array = []
		for j in range(solved.active.size()):
			var index: int = solved.active[j]
			if index >= constraints.size() and solved.multipliers[base.size() + j] > 0.0:
				var item: Dictionary = normal[index - constraints.size()]
				if item.group == tangent.item.group and item.target == 0.0:
					support.append(item)
		var fixed := false
		for a in support:
			for b in support:
				if a.nx == b.nx and a.ny == b.ny and a.coordinate != b.coordinate:
					fixed = true
		if fixed:
			for i in range(bodies.size()):
				if groups[i] == tangent.item.group:
					for axis in range(3):
						delta[3 * i + axis] = -incoming[3 * i + axis]
	var before: Array[CapsuleBody] = kernel._copies(bodies)
	if kernel._publish(bodies, delta, false, null) != OK:
		return {}
	var impulses: Array = []
	for _item in contacts:
		impulses.append({"normal": 0.0, "tangent": 0.0})
	var angular_rows: Array = []
	var angular_impulses: Array = []
	for j in range(solved.active.size()):
		var index: int = solved.active[j]
		var impulse: float = solved.multipliers[base.size() + j]
		if index < constraints.size():
			angular_rows.append(constraints[index].row)
			angular_impulses.append(impulse)
		else:
			impulses[normal[index - constraints.size()].contact].normal += impulse
	for j in range(tangent_records.size()):
		impulses[tangent_records[j].item.contact].tangent += solved.multipliers[
			kernel._hinges.size() + j
		]
	# Reconstruct REAL linear hinge transfers after subtracting ALL terrain
	# forces, not a fake per-primary-row load. Connector couples remain separate.
	var external: Array = []
	var changes: Array = []
	var torques: Array[float] = []
	for i in range(bodies.size()):
		external.append({"x": 0.0, "y": 0.0})
		torques.append(0.0)
	for index in range(contacts.size()):
		var contact: Dictionary = contacts[index]
		var frame: Dictionary = ROW.frame(before[contact.part], contact.u, contact.nx, contact.ny)
		var fx: float = frame.nx * impulses[index].normal - frame.ny * impulses[index].tangent
		var fy: float = frame.ny * impulses[index].normal + frame.nx * impulses[index].tangent
		external[contact.part].x += fx
		external[contact.part].y += fy
		torques[contact.part] += frame.rx * fy - frame.ry * fx
	for i in range(bodies.size()):
		changes.append(
			{
				"x":
				(
					(
						bodies[i].mass
						* (
							(bodies[i].a.velocity_x + bodies[i].b.velocity_x)
							- (before[i].a.velocity_x + before[i].b.velocity_x)
						)
						/ 2.0
					)
					- external[i].x
				),
				"y":
				(
					(
						bodies[i].mass
						* (
							(bodies[i].a.velocity_y + bodies[i].b.velocity_y)
							- (before[i].a.velocity_y + before[i].b.velocity_y)
						)
						/ 2.0
					)
					- external[i].y
				)
			}
		)
	var subtree: Array = changes.duplicate(true)
	for child in range(bodies.size() - 1, 0, -1):
		subtree[kernel._tree_parents[child]].x += subtree[child].x
		subtree[kernel._tree_parents[child]].y += subtree[child].y
	var hinges: Array[float] = []
	var events: Array = []
	for i in range(bodies.size()):
		var axes: Dictionary = PlanarBasis.frame(before[i])
		var internal := 0.0
		if i > 0:
			hinges.append_array([subtree[i].x, subtree[i].y])
			internal += (-axes.x * subtree[i].y + axes.y * subtree[i].x) / 2.0
		for child in range(i + 1, bodies.size()):
			if kernel._tree_parents[child] == i:
				internal += (-axes.x * subtree[child].y + axes.y * subtree[child].x) / 2.0
		var connector := 0.0
		for row in range(2 * (bodies.size() - 1), kernel._hinges.size()):
			connector += kernel._hinges[row][3 * i + 2] * solved.multipliers[row]
		var stop := 0.0
		for j in range(angular_rows.size()):
			stop += angular_rows[j][3 * i + 2] * angular_impulses[j]
		var actual: float = (PlanarBasis.frame(bodies[i]).omega - axes.omega) / axes.inverse_inertia
		events.append(
			{
				"part": i,
				"angular_impulse": actual - internal - connector - stop - torques[i],
				"hinge_angular_impulse": internal,
				"connector_angular_impulse": connector,
				"limit_angular_impulse": stop,
				"terrain_angular_impulse": torques[i]
			}
		)
	return {
		"status": OK,
		"hinge_impulses": hinges,
		"angular_drag_events": events,
		"contacts": impulses,
		"external_linear_residual": subtree[0]
	}
