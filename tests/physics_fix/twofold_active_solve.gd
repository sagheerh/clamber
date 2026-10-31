# gdlint: disable=max-line-length,max-returns
extends RefCounted
## UNADOPTED algebraic precision escalation ONLY on an ordinary rank rejection.
## No rank waiver, diagonal regularizer, epsilon, physical sweep or energy allowance.
## Twofold LDL^T solves the SAME binary64 rows/RHS/weights. Ordinary strict rank
## guard still applies to every active matrix; a rank-rejected matrix never publishes.
## Fixed twofold precision is NOT exact rational arithmetic or a universal QP solver.


static func add(a: Array, b: Array) -> Array:
	var s: float = a[0] + b[0]
	var v: float = s - a[0]
	var e: float = (a[0] - (s - v)) + (b[0] - v) + a[1] + b[1]
	var h: float = s + e
	return [h, e - (h - s)]


static func neg(a: Array) -> Array:
	return [-a[0], -a[1]]


static func mul(a: Array, b: Array) -> Array:
	var ca: float = 134217729.0 * a[0]
	var cb: float = 134217729.0 * b[0]
	var ah: float = ca - (ca - a[0])
	var bh: float = cb - (cb - b[0])
	var al: float = a[0] - ah
	var bl: float = b[0] - bh
	var p: float = a[0] * b[0]
	var e: float = ((ah * bh - p) + ah * bl + al * bh) + al * bl
	e += a[0] * b[1] + a[1] * b[0]
	e += a[1] * b[1]
	var h: float = p + e
	return [h, e - (h - p)]


static func divide(a: Array, b: Array) -> Array:
	if not valid(a) or not valid(b) or sign_of(b) == 0:
		return [NAN, NAN]
	var q: float = a[0] / b[0]
	var r := add(a, neg(mul(b, [q, 0.0])))
	var correction: float = (r[0] + r[1]) / b[0]
	return add([q, 0.0], [correction, 0.0])


static func valid(a: Array) -> bool:
	return a.size() == 2 and is_finite(a[0]) and is_finite(a[1])


static func sign_of(a: Array) -> int:
	var x: float = a[0] if a[0] != 0.0 else a[1]
	return 1 if x > 0.0 else (-1 if x < 0.0 else 0)


static func _linear(rows: Array, rhs: Array, weights: Array) -> Dictionary:
	var lower: Array = []
	var diagonal: Array = []
	for i in range(rows.size()):
		var line: Array = []
		for j in range(i + 1):
			var value: Array = [0.0, 0.0]
			for d in range(weights.size()):
				value = add(
					value, mul(mul([rows[i][d], 0.0], [weights[d], 0.0]), [rows[j][d], 0.0])
				)
			for k in range(j):
				value = add(
					value, neg(mul(mul(line[k], diagonal[k]), lower[j][k] if j < i else line[k]))
				)
			if not valid(value) or (i == j and sign_of(value) <= 0):
				return {}
			line.append(divide(value, diagonal[j]) if j < i else [1.0, 0.0])
			if i == j:
				diagonal.append(value)
		lower.append(line)
	var multipliers: Array = []
	for i in range(rows.size()):
		var value: Array = [rhs[i], 0.0]
		for j in range(i):
			value = add(value, neg(mul(lower[i][j], multipliers[j])))
		multipliers.append(value)
	for i in range(rows.size()):
		multipliers[i] = divide(multipliers[i], diagonal[i])
	for i in range(rows.size() - 1, -1, -1):
		for j in range(i + 1, rows.size()):
			multipliers[i] = add(multipliers[i], neg(mul(lower[j][i], multipliers[j])))
	var delta: Array = []
	for d in range(weights.size()):
		var value: Array = [0.0, 0.0]
		for i in range(rows.size()):
			value = add(value, mul(mul([weights[d], 0.0], [rows[i][d], 0.0]), multipliers[i]))
		delta.append(value)
	for item in delta + multipliers:
		if not valid(item):
			return {}
	return {"delta": delta, "multipliers": multipliers}


static func solve(
	kernel: RefCounted, equalities: Array, rhs: Array, inequalities: Array
) -> Dictionary:
	var pending: Array = [[]]
	var visited: Dictionary = {}
	while not pending.is_empty():
		var active: Array = pending.pop_front()
		active.sort()  # A face has one canonical key, independent of pivot order.
		var key := var_to_bytes(active).hex_encode()
		if visited.has(key):
			continue
		visited[key] = true
		var rows := equalities.duplicate()
		var values := rhs.duplicate()
		for index in active:
			rows.append(inequalities[index].row)
			values.append(float(inequalities[index].rhs))
		# Preserve original rank/finite barrier, never accept its rejected matrix.
		if not rows.is_empty() and kernel._factor_rows(rows).is_empty():
			# A violated dependent row cannot coexist with this entire active
			# face. Explore one-row exchanges, NOT a singular factor or rank
			# waiver. Every neighbor must independently meet strict primal AND
			# dual conditions before publication. Finite visited faces, no budget.
			for remove in range(active.size()):
				var neighbor := active.duplicate()
				neighbor.remove_at(remove)
				pending.append(neighbor)
			continue
		var result := _linear(rows, values, kernel._weights)
		if result.is_empty():
			return {}
		var pivot := -1
		for i in range(active.size()):
			if sign_of(result.multipliers[equalities.size() + i]) < 0:
				pivot = i
				break
		if pivot >= 0:
			active.remove_at(pivot)
			pending.push_front(active)
			continue
		for i in range(inequalities.size()):
			if i in active:
				continue
			var residual: Array = [-float(inequalities[i].rhs), 0.0]
			for d in range(kernel._weights.size()):
				residual = add(residual, mul([inequalities[i].row[d], 0.0], result.delta[d]))
			if not valid(residual):
				return {}
			if sign_of(residual) < 0:
				pivot = i
				break
		if pivot >= 0:
			active.append(pivot)
			pending.push_front(active)
			continue
		var delta: Array[float] = []
		var multipliers: Array[float] = []
		for x in result.delta:
			delta.append(x[0] + x[1])
		for x in result.multipliers:
			multipliers.append(x[0] + x[1])
		if not kernel._finite(delta) or not kernel._finite(multipliers):
			return {}
		return {
			"delta": delta,
			"multipliers": multipliers,
			"active": active,
			"algebra":
			"twofold SAME rows + finite independent face exchanges; original rank/finite/strict publisher retained"
		}
	return {}
