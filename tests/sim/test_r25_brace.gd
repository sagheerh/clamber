extends SceneTree
## R25 fixed arms. No search/retuning after results; sleep remains CreatureSleep.
const TUNING = preload("res://core/tuning.tres")
var _failures := 0
var _checks := 0
var _folder := ""


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report-dir="):
			_folder = arg.trim_prefix("--report-dir=")
	assert(not _folder.is_empty())
	_controls()
	_actual_public_f52()
	# All arms registered before measurement; no outcome-dependent extra cells.
	_arm("idle-on", true, .7, 0)
	_arm("idle-off", false, .7, 0)
	_arm("lurch-off", false, .7, 60)
	_arm("lurch-on", true, .7, 60)
	_arm("gain1-short", true, 1.0, 60)
	_arm("gain07-long", true, .7, 300)
	_arm("gain1-long", true, 1.0, 300)
	print("M1 R25 controls: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _check(ok: bool, label: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		push_error("FAIL R25 component: " + label)


func _controls() -> void:
	var bodies := CreaturePresets.load_model("Slug", TUNING).create_bodies(0.0, 0.0)
	var joint := AngularJoint.new()
	_check(joint.setup(bodies[0], bodies[1], TUNING) == OK, "joint setup")
	for sign_value in [-1.0, 1.0]:
		PlanarBasis.spin(bodies[1], sign_value)
		_check(joint.update_brace(0, true) == OK and joint.brace_active, "release captures angle")
		var target := joint.brace_q
		_check(not joint.hold_velocity().is_empty(), "bilateral block completes")
		_check(absf(joint.state().omega) < 1e-12, "relative velocity blocked both signs")
		_check(joint.update_brace(0, true) == OK and joint.brace_q == target, "idempotent capture")
		for mask in [1, 2, 3]:
			_check(
				(
					joint.update_brace(mask, true) == OK
					and not joint.brace_active
					and joint.brace_q == 0.0
				),
				"ANY input instantly releases/full rearm"
			)
	# Public restore rejection/hashes include bit AND target, no metadata-only hash.
	var sim := R25Fixture.public_sim("Slug")
	sim.step(0)
	var saved := sim.snapshot()
	for bad_value in [1, "true", null]:
		var bad: Dictionary = saved.duplicate(true)
		bad.accumulator.solver.rig.physical.angular_joints[0].brace_active = bad_value
		sim.restore(bad)
		_check(sim.last_status != OK and sim.snapshot() == saved, "malformed flag atomic")
	for bad_angle in [INF, NAN, 4.0, "0", null]:
		var bad: Dictionary = saved.duplicate(true)
		bad.accumulator.solver.rig.physical.angular_joints[0].brace_q = bad_angle
		sim.restore(bad)
		_check(sim.last_status != OK and sim.snapshot() == saved, "malformed angle atomic")
	var restored := R25Fixture.public_sim("Slug")
	restored.restore(saved)
	_check(
		restored.last_status == OK and restored.state_hash() == sim.state_hash(),
		"brace hash restore"
	)
	for tick in range(60):
		var mask := 1 if tick < 30 else 0
		sim.step(mask)
		restored.step(mask)
		_check(
			(
				sim.last_status == OK
				and restored.last_status == OK
				and var_to_bytes(sim.snapshot()) == var_to_bytes(restored.snapshot())
			),
			"exact brace continuation"
		)
	# Uniform-gravity airborne pair, no world pin: actual COM trajectory unaffected.
	var model := CreaturePresets.load_model("Slug", TUNING)
	var probes: Array[ActuatedLoadProbe] = []
	for enabled in [false, true]:
		var p := ActuatedLoadProbe.new()
		p.brace_enabled = enabled
		_check(
			(
				p.setup(
					model,
					R25Fixture.floor_grid(),
					0.0,
					R25Fixture.spawn_y(model) + 2.0,
					R25Fixture.materials(model),
					R25Fixture.materials(model, true),
					TUNING
				)
				== OK
			),
			"airborne setup"
		)
		probes.append(p)
	for tick in range(12):
		var a := probes[0].advance(0)
		var b := probes[1].advance(0)
		_check(
			(
				a.status == OK
				and b.status == OK
				and a.grounded_parts.is_empty()
				and b.grounded_parts.is_empty()
			),
			"airborne no manufactured ground"
		)
		var ca := R25Fixture.center(probes[0].snapshot().bodies)
		var cb := R25Fixture.center(probes[1].snapshot().bodies)
		_check(
			absf(ca[0] - cb[0]) < 1e-12 and absf(ca[1] - cb[1]) < 1e-12,
			"brace holds shape not height; same airborne COM"
		)


func _actual_public_f52() -> void:
	var sim := R25Fixture.public_sim("Slug")
	var file := FileAccess.open(_folder + "/public-f52.jsonl", FileAccess.WRITE)
	assert(file != null)
	for tick in range(600):
		sim.step(0)
		_check(sim.last_status == OK, "public adopted idle tick")
		file.store_line(
			JSON.stringify(
				{"tick": tick, "status": sim.last_status, "state": sim.snapshot()}, "", true, true
			)
		)
	file.close()


func _arm(name: String, enabled: bool, gain: float, hold: int) -> void:
	var tuning: Tuning = TUNING.duplicate(true)
	tuning.motors_gain_default = gain  # ONLY authorised existing dial values .7/1.
	var model := CreaturePresets.load_model("Slug", tuning)
	var rig := SleepingLoadProbe.new()
	var twin := SleepingLoadProbe.new()
	for r in [rig, twin]:
		_check(
			(
				r.setup(
					model,
					R25Fixture.floor_grid(),
					0.0,
					R25Fixture.spawn_y(model),
					R25Fixture.materials(model),
					R25Fixture.materials(model, true),
					tuning,
					true,
					enabled
				)
				== OK
			),
			"arm setup"
		)
	rig._probe.collect_contact_samples = true
	var file := FileAccess.open(_folder + "/" + name + ".jsonl", FileAccess.WRITE)
	assert(file != null)
	var ticks := 5700 + hold + 240 if hold else 6000
	for tick in range(ticks):
		var mask := 1 if hold and tick >= 5700 and tick < 5700 + hold else 0
		var row := rig.step(mask)
		var other := twin.step(mask)
		if (
			row.status != OK
			or other.status != OK
			or var_to_bytes(rig.snapshot()) != var_to_bytes(twin.snapshot())
		):
			_check(false, "arm aborted/observer changed physical state at %s:%d" % [name, tick])
			break
		row.observer_on_off_physical_state_equal = true
		row.arm = name
		row.brace_enabled = enabled
		row.gain = gain
		row.hold_ticks = hold
		row.requested_ticks = ticks
		if row.has("awake_solver_trace_before_sleep_parking"):
			var raw: Dictionary = row.awake_solver_trace_before_sleep_parking
			raw.diagnostic_motor_stiffness = tuning.motors_joint_stiffness
			raw.diagnostic_motor_damping = tuning.motors_joint_damping
			raw.diagnostic_motor_max_torque = tuning.motors_max_torque
			raw.diagnostic_angular_impulse_limit_rad_s = (
				tuning.physics_max_constraint_angular_impulse_rad_s
			)
			raw.diagnostic_motor_limit_max_deg = tuning.motors_limit_max_deg
			raw.input_mask = mask
		file.store_line(JSON.stringify(row, "", true, true))
	file.close()
