# gdlint: disable=max-line-length
extends "res://tests/physics_fix/test_final_manifold_audit.gd"


func _initialize() -> void:
	var kernel := Probe.new()
	var frame: Dictionary = preload("res://tests/physics_fix/manifold_archive.gd").first_frame(
		"res://tests/fixtures/m1_articulated_execution/9343fb06296f/length-Hopper-failure.json",
		kernel
	)
	_check(
		not frame.is_empty(),
		"exact corrected-geometry Hopper released mask0 tick285 FIRST physical pass; not a world replay"
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
			"Hopper285 manifold diagnostic: "
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
	print("Hopper285 manifold audit: %d checks, %d failures" % [_checks, _failures])
	print(
		"Scope: EXACT archived first support pass, ZERO public OR private creature ticks; expected error component diagnosis NOT acceptance"
	)
	quit(1 if _failures else 0)
