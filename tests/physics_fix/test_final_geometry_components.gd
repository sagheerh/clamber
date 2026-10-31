# gdlint: disable=max-line-length
extends SceneTree
const CANDIDATE = preload("res://tests/physics_fix/final_geometry_constitutive_candidate.gd")
const MODELS = preload("res://tests/physics_fix/rigid_pad_models.gd")
const CONFIG = preload("res://core/tuning.tres")
const ARCHIVE = preload("res://tests/physics_fix/manifold_archive.gd")
var _checks := 0
var _failures := 0


func _initialize() -> void:
	for name in ["Slug", "Hopper", "TwinRoller"]:
		for mask in [0, 1, 2, 3]:
			var model := MODELS.load_model(name, CONFIG)
			var rig := CANDIDATE.new()
			_check(
				(
					rig.setup(
						model,
						R25Fixture.floor_grid(),
						0.0,
						R25Fixture.spawn_y(model),
						R25Fixture.materials(model),
						R25Fixture.materials(model, true),
						CONFIG
					)
					== OK
				),
				name + " setup mask%d" % mask
			)
			rig.collect_contact_samples = true
			var result: Dictionary = rig.advance(mask)
			_check(result.status == OK, name + " real component step mask%d" % mask)
			var phase_ok: bool = result.status == OK
			if phase_ok:
				phase_ok = (
					result.constitutive_velocity_pass == 1
					and result.stage_order.count("velocity_pass_0") == 1
					and result.stage_order.count("velocity_pass_1") == 1
					and result.constitutive_stage.status == OK
					and result.constitutive_stage.after <= result.constitutive_stage.before
					and result.drive_events.size() == rig._joints.size()
				)
			_check(
				phase_ok,
				(
					name
					+ " single final-geometry constitutive stage and original actual-energy comparison"
				)
			)
			var ledger_ok: bool = result.status == OK
			if ledger_ok:
				for axis in ["x", "y"]:
					var expected := 0.0
					for stage in [
						"drive_internal",
						"damping",
						"gravity",
						"internal",
						"contact_velocity",
						"clamp"
					]:
						expected += result.momentum_budget[stage + "_impulse_" + axis + "_ns"]
					ledger_ok = (
						ledger_ok
						and (
							absf(
								expected - result.momentum_budget["momentum_change_" + axis + "_ns"]
							)
							< 1e-12
						)
					)
			_check(ledger_ok, name + " full physical tick impulse ledger mask%d" % mask)
		var bad := CANDIDATE.new()
		var model := MODELS.load_model(name, CONFIG)
		bad.setup(
			model,
			R25Fixture.floor_grid(),
			0.0,
			R25Fixture.spawn_y(model),
			R25Fixture.materials(model),
			R25Fixture.materials(model, true),
			CONFIG
		)
		var before := var_to_bytes(bad.snapshot())
		bad._friction[0] = INF
		_check(
			(
				(
					(
						preload("res://tests/physics_fix/manifold_final_terrain.gd")
						. resolve_tick(
							bad.bodies,
							bad._parents,
							bad._terrain,
							bad._mass,
							CoupledLoadProbe.lowest_mask(bad.bodies, CONFIG),
							bad._friction,
							bad._restitution,
							CONFIG,
							Callable(),
							PackedByteArray(),
							bad._limit_definitions(),
							bad.snapshot().bodies
						)
						. status
					)
					!= OK
				)
				and var_to_bytes(bad.snapshot()) == before
			),
			name + " invalid actual material adapter rejects without mutating input"
		)
	for source in ["c49fcc66ee9f", "67b167a30543", "a2a900fe2b29"]:
		var frame: Dictionary = ARCHIVE.final_frame(
			(
				"res://tests/fixtures/m1_articulated_execution/"
				+ source
				+ "/length-Hopper-failure.json"
			)
		)
		var before_energy := 0.0
		for body in frame.bodies:
			before_energy += (
				preload("res://tests/physics_fix/rigid_contact_candidate.gd").kinetic_energy(body)
			)
		var rig := CANDIDATE.new()
		var model := MODELS.load_model("Hopper", CONFIG)
		rig.setup(
			model,
			frame.terrain,
			0.0,
			R25Fixture.spawn_y(model),
			R25Fixture.materials(model),
			R25Fixture.materials(model, true),
			CONFIG
		)
		var kernel := preload("res://tests/physics_fix/surface_constitutive_kernel.gd").new()
		kernel.history = frame.kernel.history
		kernel.limits = frame.kernel.limits
		kernel.angular_retention = 1.0 - CONFIG.physics_angular_damping
		var physical_origin: Array = []
		for body in frame.bodies:
			physical_origin.append(body.snapshot())
		var drag: Dictionary = preload("res://tests/physics_fix/local_angular_drag.gd").apply(
			frame.bodies, frame.kernel._tree_parents, CONFIG.physics_angular_damping, kernel.limits
		)
		var configured: bool = (
			drag.status == OK and kernel.configure(frame.bodies, frame.kernel._tree_parents) == OK
		)
		var response: Dictionary = (
			preload("res://tests/physics_fix/support_manifold.gd").solve(
				kernel, frame.bodies, frame.contacts
			)
			if configured
			else {}
		)
		_check(
			not response.is_empty(),
			(
				source
				+ " archived FINAL stress frame supports one complete constitutive operator (not a world replay)"
			)
		)
		var guard: Dictionary = (
			preload("res://tests/physics_fix/constitutive_stage_guard.gd")
			. validate(physical_origin, frame.bodies)
		)
		_check(
			guard.status == OK and guard.before == before_energy,
			source + " complete ACTUAL endpoint energy guards frozen stress frame"
		)
	print("Final geometry components: %d checks, %d failures" % [_checks, _failures])
	print(
		"Scope: private component steps and archived final-frame stress inputs; ZERO public Sim world ticks; not 7200 or acceptance"
	)
	quit(1 if _failures else 0)


func _check(ok: bool, label: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		push_error("FAIL " + label)
