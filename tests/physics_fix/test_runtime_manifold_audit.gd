# gdlint: disable=max-line-length
extends "res://tests/physics_fix/test_final_manifold_audit.gd"


class PrimalFirstProbe:
	extends Probe

	func _active_solve(equalities: Array, rhs: Array[float], inequalities: Array) -> Dictionary:
		var result: Dictionary = _primal_first(equalities, rhs, inequalities)
		calls.append(
			{
				"equalities": equalities.size(),
				"inequalities": inequalities.size(),
				"failed": result.is_empty(),
				"active": result.get("active", [])
			}
		)
		return result

	func _primal_first(equalities: Array, rhs: Array[float], inequalities: Array) -> Dictionary:
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
			var pivot := -1
			for i in range(inequalities.size()):
				if i not in active and _dot(inequalities[i].row, delta) < inequalities[i].rhs:
					pivot = i
					break
			if pivot >= 0:
				active.append(pivot)
				continue
			for i in range(active.size()):
				if multipliers[equalities.size() + i] < 0.0:
					pivot = i
					break
			if pivot >= 0:
				active.remove_at(pivot)
				continue
			return {"delta": delta, "multipliers": multipliers, "active": active}
		return {}


func _initialize() -> void:
	var kernel := PrimalFirstProbe.new()
	var frame: Dictionary = preload("res://tests/physics_fix/manifold_archive.gd").runtime_frame(
		"res://tests/fixtures/m1_candidate_runtime/00f33495a75c/summary.json", kernel
	)
	_check(
		not frame.is_empty(),
		"exact corrected-geometry Hopper mask3 tick4 FIRST physical pass; not a world replay"
	)
	var original := var_to_bytes(_states(frame.bodies))
	var response: Dictionary = BLOCK.solve(kernel, frame.bodies, frame.contacts)
	_check(response.is_empty(), "exact archived unexpected physical rejection reproduced")
	_check(
		original == var_to_bytes(_states(frame.bodies)),
		"failed raw manifold solve leaves ALL original endpoints unchanged"
	)
	_check(not kernel.calls.is_empty(), "failure reaches real active solver")
	print(
		(
			"Runtime manifold diagnostic: "
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
	print("Runtime manifold audit: %d checks, %d failures" % [_checks, _failures])
	print(
		"Scope: EXACT archived first support pass, ZERO public OR private creature ticks; expected error component diagnosis NOT acceptance"
	)
	quit(1 if _failures else 0)
