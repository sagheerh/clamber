# gdlint: disable=max-line-length
extends "res://tests/physics_fix/test_final_manifold_audit.gd"


func _initialize() -> void:
	var frame: Dictionary = preload("res://tests/physics_fix/manifold_archive.gd").final_frame(
		"res://tests/fixtures/m1_articulated_execution/67b167a30543/length-Hopper-failure.json"
	)
	var kernel := Probe.new()
	kernel.history = frame.kernel.history
	kernel.limits = frame.kernel.limits
	_check(
		kernel.configure(frame.bodies, frame.kernel._tree_parents) == OK,
		"exact V23 Hopper263 FINAL frame configured without clock"
	)
	var original := var_to_bytes(_states(frame.bodies))
	var response: Dictionary = (
		preload("res://tests/physics_fix/support_manifold_v23_control.gd")
		. solve(kernel, frame.bodies, frame.contacts)
	)
	_check(
		response.is_empty() and kernel.publication.status == ERR_INVALID_DATA,
		"strict original publisher rejects exact archived proposal"
	)
	_check(
		original == var_to_bytes(_states(frame.bodies)),
		"failed proposal leaves all original endpoints unchanged"
	)
	_check(
		(
			kernel.calls.size() == 2
			and not kernel.calls[0].failed
			and not kernel.calls[1].failed
			and kernel.publication.actual_proposed > kernel.publication.actual_before
		),
		"both solves succeed; actual final endpoint energy rises"
	)
	print(
		(
			"Hopper263 diagnostic: "
			+ JSON.stringify(
				{"solves": kernel.calls, "published": kernel.publication}, "", true, true
			)
		)
	)
	print("Hopper263 audit: %d checks, %d failures" % [_checks, _failures])
	print("Scope: exact archived final pass ONLY; ZERO public world ticks; not acceptance")
	quit(1 if _failures else 0)
