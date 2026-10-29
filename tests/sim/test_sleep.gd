extends SceneTree
## R14 component + engineering restore replay ONLY. NOT complete creature determinism/FA.
const TUNING = preload("res://core/tuning.tres")
var _checks := 0
var _failures := 0
var _report := {
	"scope": "sleep component/engineering replay, NOT FA or complete-creature determinism",
	"rows": []
}


func _initialize() -> void:
	_predicate()
	_replay()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report="):
			var file := FileAccess.open(arg.trim_prefix("--report="), FileAccess.WRITE)
			_check(file != null, "sleep evidence file opens")
			if file != null:
				file.store_string(JSON.stringify(_report, "", true, true))
	print("M1 sleep components: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("FAIL R14 sleep: " + label)


func _bodies() -> Array:
	var result := []
	for body in CreaturePresets.load_model("Slug", TUNING).create_bodies(0.0, 0.0):
		result.append(body.snapshot())
	return result


func _predicate() -> void:
	var rule := CreatureSleep.new()
	_check(rule.configure(TUNING) == OK, "owner sleep configuration")
	var before := _bodies()
	# Endpoint velocity plateau DOES NOT prevent positional sleep.
	for body in before:
		body.a.velocity_x = .202
		body.b.velocity_y = .202
	for tick in range(29):
		_check(rule.observe(before, before, 0, tick) == OK and not rule.asleep, "no early sleep")
	var midway := rule.snapshot()
	_check(
		rule.observe(before, before, 0, 29) == OK and rule.asleep,
		"sleep exactly at30 consecutive ticks"
	)
	_check(rule.last_sleep_tick == 29, "sleep event tick recorded")
	rule.wake(30)
	_check(
		not rule.asleep and rule.still_ticks == 0 and rule.last_wake_tick == 30,
		"wake fully re-arms"
	)
	_check(rule.restore(midway) == OK, "restore partial dwell")
	var shifted := before.duplicate(true)
	# Exact boundary with center=0: equality is NOT strictly below.001.
	for end in ["a", "b"]:
		before[0][end].x = 0.0
		shifted[0][end].x = TUNING.sleep_still_displacement_wu
	_check(
		rule.observe(before, shifted, 0, 30) == OK and rule.still_ticks == 0,
		"exact displacement boundary resets dwell; no epsilon"
	)
	var cancelled := before.duplicate(true)
	for end in ["a", "b"]:
		cancelled[0][end].x += .002
		cancelled[1][end].x -= .002 * before[0].mass / before[1].mass
	_check(
		rule.observe(before, cancelled, 0, 31) == OK and rule.still_ticks == 0,
		"maximum per-BODY movement, not aggregate creature COM cancellation"
	)
	_check(
		rule.observe(before, before, 1, 32) == OK and rule.still_ticks == 0,
		"held input resets dwell"
	)
	var stable := var_to_bytes(rule.snapshot())
	var invalid := rule.snapshot()
	invalid.still_ticks = 31
	_check(
		rule.restore(invalid) != OK and var_to_bytes(rule.snapshot()) == stable,
		"bad sleep restore atomic"
	)
	var tuning: Tuning = TUNING.duplicate(true)
	tuning.sleep_dwell_ticks = 0
	_check(CreatureSleep.new().configure(tuning) != OK, "invalid dwell rejected, no fallback")


func _floor() -> SdfGrid:
	var rows: Array = []
	for iy in range(49):
		var row := PackedFloat64Array()
		for ix in range(97):
			row.append(-4.0 + iy * TUNING.physics_sdf_cell_wu)
		rows.append(row)
	var grid := SdfGrid.new()
	_check(
		grid.configure(rows, -12.0, -4.0, TUNING.physics_grip_friction, TUNING) == OK, "sleep floor"
	)
	return grid


func _rig() -> SleepingLoadProbe:
	var rig := SleepingLoadProbe.new()
	var material: Array[float] = [
		TUNING.physics_grip_friction, TUNING.physics_grip_friction, TUNING.physics_grip_friction
	]
	var bounce: Array[float] = [
		TUNING.physics_foot_restitution,
		TUNING.physics_foot_restitution,
		TUNING.physics_foot_restitution
	]
	_check(
		(
			rig.setup(
				CreaturePresets.load_model("Slug", TUNING),
				_floor(),
				0.0,
				.33,
				material,
				bounce,
				TUNING
			)
			== OK
		),
		"sleeping engineering Slug setup"
	)
	return rig


func _input(tick: int) -> int:
	return 1 if tick == 180 else (2 if tick == 360 else 0)


func _replay() -> void:
	var rig := _rig()
	var snapshots: Array = []
	var checkpoints: Array = []
	var sleeps: Array = []
	var wakes: Array = []
	var captured_dwell := false
	var captured_asleep := false
	for tick in range(600):
		var before := rig.snapshot()
		if not captured_dwell and before.sleep.still_ticks == 15:
			checkpoints.append(before)
			captured_dwell = true
		if not captured_asleep and before.sleep.asleep:
			checkpoints.append(before)
			captured_asleep = true
		var row := rig.step(_input(tick))
		_check(row.status == OK, "real sleep probe tick%d completes" % tick)
		if row.status != OK:
			return
		var state := rig.snapshot()
		snapshots.append(var_to_bytes(state))
		if row.sleep.last_sleep_tick == tick:
			sleeps.append(tick)
		if row.sleep.last_wake_tick == tick:
			wakes.append(tick)
		if row.sleep_state == "asleep":
			for body in state.physical.bodies:
				_check(
					(
						body.a.velocity_x == 0.0
						and body.a.velocity_y == 0.0
						and body.b.velocity_x == 0.0
						and body.b.velocity_y == 0.0
					),
					"sleep zeros EVERY endpoint velocity"
				)
		if before.sleep.asleep and _input(tick) == 0:
			_check(
				row.sleep_state == "asleep" and row.wake_reason == "",
				"persistent support does not wake"
			)
		_report.rows.append(
			{
				"tick": tick,
				"input_mask": _input(tick),
				"sleep": state.sleep,
				"sleep_state": row.sleep_state,
				"wake_reason": row.wake_reason,
				"sleep_breaking_new_grounded_parts": row.sleep_breaking_new_grounded_parts
			}
		)
	_check(
		captured_dwell and captured_asleep and not sleeps.is_empty(),
		"nonvacuous partial-dwell and asleep checkpoints"
	)
	_check(wakes == [180, 360], "only actual input transitions wake at exact ticks")
	var comparisons := 0
	for checkpoint in checkpoints:
		var restored := _rig()
		_check(restored.restore(checkpoint) == OK, "restore complete physical+dwell state")
		for tick in range(checkpoint.physical.ticks, 600):
			comparisons += 1
			_check(
				(
					restored.step(_input(tick)).status == OK
					and var_to_bytes(restored.snapshot()) == snapshots[tick]
				),
				"restored continuation identical at%d (including sleep/wake ticks)" % tick
			)
	# F42 countercontrol: prior flag false, current real terrain overlap true WHILE asleep.
	if captured_asleep:
		var contact := _rig()
		var checkpoint: Dictionary = checkpoints[-1].duplicate(true)
		checkpoint.physical.bodies[2].grounded = false
		_check(contact.restore(checkpoint) == OK, "new-contact asleep fixture restores")
		var row := contact.step(0)
		_check(
			(
				row.status == OK
				and row.wake_reason == "new_grounded"
				and row.sleep_breaking_new_grounded_parts == [2]
			),
			"F42 transition wakes without impulse threshold"
		)
		var stable := var_to_bytes(contact.snapshot())
		var invalid := contact.snapshot()
		invalid.sleep.still_ticks = 31
		_check(
			contact.restore(invalid) != OK and var_to_bytes(contact.snapshot()) == stable,
			"bad wrapper restore atomic"
		)
	_report["restore_continuation_tick_comparisons"] = comparisons
	_report["sleep_ticks"] = sleeps
	_report["wake_ticks"] = wakes
	_report["checkpoint_ticks"] = checkpoints.map(func(s): return s.physical.ticks)
	_report["complete_creature_determinism_attempts"] = 0
	print(
		(
			"M1 sleep replay: "
			+ JSON.stringify(
				{
					"rows": 600,
					"sleep_ticks": sleeps,
					"wake_ticks": wakes,
					"restore_checkpoint_ticks": _report.checkpoint_ticks,
					"scope": "engineering component ONLY; complete-creature determinism0"
				},
				"",
				true,
				true
			)
		)
	)
