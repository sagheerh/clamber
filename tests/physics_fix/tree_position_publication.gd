# gdlint: disable=max-line-length,max-returns
extends RefCounted
## Finite configuration-space publication INSIDE a position block, never another
## PBD sweep/final repair. Relative rotations are chosen by the coupled block;
## exact tree coordinates eliminate linearized hinge gaps. The remaining global
## translation is solved against ALL sampled terrain halfspaces at once.
## Position corrections are never converted into normal velocity/grip impulses.
const SAMPLE = preload("res://tests/physics_fix/staged_terrain_candidate.gd")


static func clear(bodies: Array[CapsuleBody], terrain: SdfGrid, tuning: Tuning) -> bool:
	for body in bodies:
		var count := SAMPLE._intervals(body, terrain, tuning)
		if count < 1:
			return false
		for index in range(count + 1):
			var sample := SAMPLE._sample(body, terrain, float(index) / count, tuning)
			if sample.is_empty() or sample.distance < body.radius - tuning.physics_contact_slop_wu:
				return false
	return true


static func publish(
	network: RefCounted,
	bodies: Array[CapsuleBody],
	parents: Array[int],
	delta: Array,
	terrain: SdfGrid,
	tuning: Tuning
) -> Dictionary:
	var work: Array[CapsuleBody] = []
	for body in bodies:
		var copy := CapsuleBody.new()
		if copy.restore(body.snapshot()) != OK:
			return {}
		work.append(copy)
	# Inherit EVERY original finite, linear/requested and actual-motion guard.
	if network._publish(work, delta, true, tuning) != OK:
		return {}
	var total_mass := 0.0
	var target_x := 0.0
	var target_y := 0.0
	for body in work:
		total_mass += body.mass
		target_x += body.mass * (body.a.x + body.b.x) / 2.0
		target_y += body.mass * (body.a.y + body.b.y) / 2.0
	# Coordinate construction, not a new force or a post-contact hinge iteration.
	for child in range(1, work.size()):
		var body := work[child]
		var parent := work[parents[child]]
		var x := body.b.x - body.a.x
		var y := body.b.y - body.a.y
		body.a.x = parent.b.x
		body.a.y = parent.b.y
		body.b.x = body.a.x + x
		body.b.y = body.a.y + y
	var actual_x := 0.0
	var actual_y := 0.0
	for body in work:
		actual_x += body.mass * (body.a.x + body.b.x) / 2.0
		actual_y += body.mass * (body.a.y + body.b.y) / 2.0
	var cx := (target_x - actual_x) / total_mass
	var cy := (target_y - actual_y) / total_mass
	_translate(work, cx, cy)
	var planes: Array = []
	for body in work:
		var count := SAMPLE._intervals(body, terrain, tuning)
		if count < 1:
			return {}
		for index in range(count + 1):
			var sample := SAMPLE._sample(body, terrain, float(index) / count, tuning)
			if sample.is_empty():
				return {}
			var rhs: float = body.radius - tuning.physics_contact_slop_wu - sample.distance
			var merged := false
			for plane in planes:
				if plane.x == sample.nx and plane.y == sample.ny:
					plane.rhs = maxf(plane.rhs, rhs)
					merged = true
					break
			if not merged:
				planes.append({"x": sample.nx, "y": sample.ny, "rhs": rhs})
	var translation := closest_translation(planes)
	if translation.is_empty():
		return {}
	_translate(work, translation[0], translation[1])
	var bound: float = tuning.physics_max_projection_wu_tick * tuning.physics_max_projection_wu_tick
	for i in range(work.size()):
		if not work[i].is_valid():
			return {}
		for endpoint in ["a", "b"]:
			var dx: float = work[i].get(endpoint).x - bodies[i].get(endpoint).x
			var dy: float = work[i].get(endpoint).y - bodies[i].get(endpoint).y
			if not is_finite(dx * dx + dy * dy) or dx * dx + dy * dy > bound:
				return {}
	# Publish once, atomically, after the whole finite configuration is feasible.
	for i in range(bodies.size()):
		bodies[i].a.x = work[i].a.x
		bodies[i].a.y = work[i].a.y
		bodies[i].b.x = work[i].b.x
		bodies[i].b.y = work[i].b.y
	return {"coordinate_com_translation": [cx, cy], "terrain_translation": translation}


static func closest_translation(planes: Array) -> Array:
	for plane in planes:
		if (
			not is_finite(plane.x)
			or not is_finite(plane.y)
			or not is_finite(plane.rhs)
			or plane.x * plane.x + plane.y * plane.y <= 0.0
		):
			return []
	if _feasible(planes, 0.0, 0.0, -1, -1):
		return [0.0, 0.0]
	var best: Array = []
	var best_squared := INF
	# In 2D the minimum-norm point is on one plane or the intersection of two.
	# Exact finite active-set enumeration; no convergence tolerance/iteration knob.
	for i in range(planes.size()):
		var a: Dictionary = planes[i]
		var scale: float = a.rhs / (a.x * a.x + a.y * a.y)
		var x: float = a.x * scale
		var y: float = a.y * scale
		if _feasible(planes, x, y, i, -1) and x * x + y * y < best_squared:
			best = [x, y]
			best_squared = x * x + y * y
		for j in range(i):
			var b: Dictionary = planes[j]
			var determinant: float = a.x * b.y - a.y * b.x
			if determinant == 0.0 or not is_finite(determinant):
				continue
			x = (a.rhs * b.y - a.y * b.rhs) / determinant
			y = (a.x * b.rhs - a.rhs * b.x) / determinant
			if _feasible(planes, x, y, i, j) and x * x + y * y < best_squared:
				best = [x, y]
				best_squared = x * x + y * y
	return best


static func _feasible(planes: Array, x: float, y: float, active_a: int, active_b: int) -> bool:
	if not is_finite(x) or not is_finite(y) or not is_finite(x * x + y * y):
		return false
	for i in range(planes.size()):
		if i not in [active_a, active_b] and planes[i].x * x + planes[i].y * y < planes[i].rhs:
			return false
	return true


static func _translate(bodies: Array[CapsuleBody], x: float, y: float) -> void:
	for body in bodies:
		for point in [body.a, body.b]:
			point.x += x
			point.y += y
