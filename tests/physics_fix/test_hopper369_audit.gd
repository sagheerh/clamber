# gdlint: disable=max-line-length
extends "res://tests/physics_fix/test_final_manifold_audit.gd"


class V26Probe:
	extends Probe

	func _active_solve(equalities: Array, rhs: Array[float], inequalities: Array) -> Dictionary:
		var result: Dictionary = _frozen(equalities, rhs, inequalities)
		calls.append(
			{
				"equalities": equalities.size(),
				"inequalities": inequalities.size(),
				"failed": result.is_empty(),
				"active": result.get("active", [])
			}
		)
		return result

	func _frozen(equalities: Array, rhs: Array[float], inequalities: Array) -> Dictionary:
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
				# A binary64 false violation can add a dependent row. Restart SAME
				# finite algebra at twofold precision, NOT the rejected singular matrix.
				# The helper independently retains the original rank/visited guards.
				return preload("res://tests/physics_fix/twofold_v26_control.gd").solve(
					self, equalities, rhs, inequalities
				)
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


class FrameProbe:
	extends V26Probe
	var algebra: Array = []

	func _active_solve(equalities: Array, rhs: Array[float], inequalities: Array) -> Dictionary:
		var result: Dictionary = super._active_solve(equalities, rhs, inequalities)
		algebra.append(
			{
				"equalities": equalities,
				"rhs": rhs,
				"inequalities": inequalities,
				"weights": _weights.duplicate(),
				"result": result
			}
		)
		return result


func _initialize() -> void:
	var kernel := FrameProbe.new()
	var frame: Dictionary = preload("res://tests/physics_fix/manifold_archive.gd").first_frame(
		"res://tests/fixtures/m1_articulated_execution/5d6c4409a19e/length-Hopper-failure.json",
		kernel
	)
	_check(
		not frame.is_empty(),
		"exact corrected-geometry Hopper RIGHT mask2 tick369 FIRST physical pass; not a world replay"
	)
	if frame.is_empty():
		quit(1)
		return
	var original := var_to_bytes(_states(frame.bodies))
	var response: Dictionary = BLOCK.solve(kernel, frame.bodies, frame.contacts)
	_check(response.is_empty(), "exact archived unexpected physical rejection reproduced")
	_check(
		original == var_to_bytes(_states(frame.bodies)),
		"failed raw manifold solve leaves ALL original endpoints unchanged"
	)
	_check(
		not kernel.calls.is_empty(),
		"actual support algebra reached; publication/rank outcome logged without assuming cause"
	)
	print(
		(
			"Hopper369 manifold diagnostic: "
			+ JSON.stringify(
				{
					"calls": kernel.calls,
					"published": kernel.publication,
					"contacts": frame.contacts
				},
				"",
				true,
				true
			)
		)
	)
	# CI annotation messages are bounded; emit independently parseable sparse
	# row/RHS blocks instead of one silently truncated dense diagnostic.
	for index in range(kernel.algebra.size()):
		var data: Dictionary = kernel.algebra[index]
		var rows: Array = []
		for row in data.equalities:
			rows.append(_sparse(row))
		var constraints: Array = []
		for item in data.inequalities:
			constraints.append({"row": _sparse(item.row), "rhs": item.rhs})
		print(
			(
				"Hopper369 manifold rows%d: " % index
				+ JSON.stringify({"equalities": rows, "weights": data.weights}, "", true, true)
			)
		)
		print(
			(
				"Hopper369 manifold rhs%d: " % index
				+ JSON.stringify(
					{"rhs": data.rhs, "inequalities": constraints, "result": data.result},
					"",
					true,
					true
				)
			)
		)

	print("Hopper369 manifold audit: %d checks, %d failures" % [_checks, _failures])
	print(
		"Scope: EXACT archived first support pass, ZERO public OR private creature ticks; expected error component diagnosis NOT acceptance"
	)
	quit(1 if _failures else 0)


func _sparse(row: Array) -> Array:
	var result: Array = []
	for i in range(row.size()):
		if row[i] != 0.0:
			result.append([i, row[i]])
	return result
