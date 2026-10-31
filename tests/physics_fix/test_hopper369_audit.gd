# gdlint: disable=max-line-length
extends "res://tests/physics_fix/test_final_manifold_audit.gd"


class FrameProbe:
	extends Probe
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
					"contacts": frame.contacts,
					"algebra": kernel.algebra
				},
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
