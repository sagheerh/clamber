extends SceneTree
## Runs engineering diagnostics only; NOT FA-3/5, public Sim or determinism evidence.
const TUNING = preload("res://core/tuning.tres")
var _checks := 0
var _failures := 0


func _initialize() -> void:
	_hinge_impulse()
	_unequal_height()
	_gravity_reaction()
	print("M1 load-path components: %d checks, %d failures" % [_checks, _failures])
	if _failures > 0:
		quit(1)
		return
	_slug()


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("FAIL load-path component: " + label)


func _hinge_impulse() -> void:
	var a := SimBody.new()
	var b := SimBody.new()
	_check(a.setup(0.0, 0.0, 1.0) == OK and b.setup(0.0, 0.0, 2.0) == OK, "hinge point masses")
	a.velocity_y = -0.6
	var hinge := CoincidentHinge.new()
	_check(hinge.setup(a, b) == OK, "real shared hinge endpoints")
	var impulse := hinge.project_velocity()
	_check(absf(impulse.y + 0.2) < 1e-12, "hinge returns actual child impulse")
	_check(absf(a.velocity_y - b.velocity_y) < 1e-12, "hinge closes relative velocity")
	_check(
		absf(a.velocity_y + b.velocity_y / 2.0 + 0.6) < 1e-12,
		"equal/opposite impulse conserves momentum"
	)


func _unequal_height() -> void:
	var model := CreaturePresets.load_model("Slug", TUNING)
	var low := model.create_bodies(0.0, 0.33)[2]
	var high := model.create_bodies(2.0, 0.53)[2]
	var pair: Array[CapsuleBody] = [high, low]
	var lowest: Array[bool] = CoupledLoadProbe.lowest_mask(pair, TUNING)
	var friction: Array[float] = [TUNING.physics_grip_friction, TUNING.physics_grip_friction]
	var bounce: Array[float] = [TUNING.physics_foot_restitution, TUNING.physics_foot_restitution]
	_check(
		(
			CapsuleContact.resolve_tick(
				pair, _stepped_floor(), model.total_mass(), lowest, friction, bounce, TUNING
			)
			== OK
		),
		"unequal-height surfaces resolve"
	)
	_check(
		high.grounded and low.grounded,
		"both feet really grounded at unequal heights before eligibility query"
	)
	var before := [high.snapshot(), low.snapshot()]
	var mask := CoupledLoadProbe.lowest_mask(pair, TUNING)
	_check(mask == [false, true], "unequal-height fixture excludes higher foot")
	pair.reverse()
	_check(
		CoupledLoadProbe.lowest_mask(pair, TUNING) == [true, false],
		"lowest geometry independent of array order"
	)
	_check(before == [high.snapshot(), low.snapshot()], "lowest eligibility never writes grounded")


func _stepped_floor() -> SdfGrid:
	var rows: Array = []
	for iy in range(17):
		var row := PackedFloat64Array()
		for ix in range(25):
			var x: float = -2.0 + ix * TUNING.physics_sdf_cell_wu
			var y: float = -1.0 + iy * TUNING.physics_sdf_cell_wu
			row.append(y - (0.2 if x >= 1.5 else 0.0))
		rows.append(row)
	var grid := SdfGrid.new()
	if grid.configure(rows, -2.0, -1.0, TUNING.physics_grip_friction, TUNING) != OK:
		push_error("stepped fixture setup failed")
	return grid


func _floor() -> SdfGrid:
	var rows: Array = []
	for iy in range(49):
		var row := PackedFloat64Array()
		for ix in range(97):
			row.append(-4.0 + iy * TUNING.physics_sdf_cell_wu)
		rows.append(row)
	var grid := SdfGrid.new()
	if grid.configure(rows, -12.0, -4.0, TUNING.physics_grip_friction, TUNING) != OK:
		push_error("floor setup failed")
	return grid


func _gravity_reaction() -> void:
	var model := CreaturePresets.load_model("Slug", TUNING)
	var foot := model.create_bodies(0.0, 0.33)[2]
	var parts: Array[CapsuleBody] = [foot]
	var dt := 1.0 / TUNING.physics_tick_hz
	var grid := _floor()
	var lowest: Array[bool] = [true]
	var friction: Array[float] = [TUNING.physics_grip_friction]
	var bounce: Array[float] = [TUNING.physics_foot_restitution]
	for tick in range(30):
		for point in [foot.a, foot.b]:
			point.previous_x = point.x
			point.previous_y = point.y
			point.velocity_y += TUNING.physics_gravity_wu_s2 * dt
			point.y += point.velocity_y * dt
		var status := CapsuleContact.resolve_tick(
			parts, grid, foot.mass, lowest, friction, bounce, TUNING
		)
		_check(status == OK, "isolated gravity contact completes")
		_check(foot.applied_load_n == 0.0, "independent reaction test injects no qualifying load")
		if tick >= 20:
			_check(
				absf(foot.measured_reaction_n - 8.4) <= 1e-12,
				"two endpoint impulses sum to 8.4N, never 16.8N"
			)
	print(
		(
			"M1 isolated gravity reaction: %.17f N (expected8.4, two endpoints, no factor correction)"
			% foot.measured_reaction_n
		)
	)


func _diagnostic_config() -> Dictionary:
	# Isolated diagnostic override ONLY; no resource or adopted/default value changes.
	var tuning: Tuning = TUNING.duplicate(true)
	var spawn_y := 0.33
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--iterations="):
			var value := arg.trim_prefix("--iterations=")
			if not value.is_valid_int() or value.to_int() <= 0:
				push_error("invalid diagnostic position iterations")
				return {}
			tuning.physics_position_iterations = value.to_int()
		if arg.begins_with("--static-slip="):
			var value := arg.trim_prefix("--static-slip=")
			if not value.is_valid_float() or float(value) not in [0.15, 1.5]:
				push_error("invalid R13 diagnostic static slip")
				return {}
			tuning.physics_static_slip_wu_s = float(value)
		if arg.begins_with("--spawn-y="):
			var value := arg.trim_prefix("--spawn-y=")
			if not value.is_valid_float() or float(value) not in [0.33, 0.53, 0.73]:
				push_error("invalid R12 diagnostic spawn height")
				return {}
			spawn_y = float(value)
	return {"tuning": tuning, "spawn_y": spawn_y}


func _slug() -> void:
	var config := _diagnostic_config()
	if config.is_empty():
		quit(1)
		return
	var tuning: Tuning = config.tuning
	var spawn_y: float = config.spawn_y
	var model := CreaturePresets.load_model("Slug", tuning)
	var probe := CoupledLoadProbe.new()
	probe.collect_contact_samples = true
	# Explicit uniform diagnostic material; NOT a new non-foot production default.
	var friction: Array[float] = [
		TUNING.physics_grip_friction, TUNING.physics_grip_friction, TUNING.physics_grip_friction
	]
	var bounce: Array[float] = [
		TUNING.physics_foot_restitution,
		TUNING.physics_foot_restitution,
		TUNING.physics_foot_restitution
	]
	if probe.setup(model, _floor(), 0.0, spawn_y, friction, bounce, tuning) != OK:
		push_error("probe setup failed")
		quit(1)
		return
	var reference := CoupledLoadProbe.new()
	reference.collect_contact_samples = false
	if reference.setup(model, _floor(), 0.0, spawn_y, friction, bounce, tuning) != OK:
		push_error("observer-off reference setup failed")
		quit(1)
		return
	var trace_path := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--trace="):
			trace_path = arg.trim_prefix("--trace=")
	var file: FileAccess = null
	if not trace_path.is_empty():
		file = FileAccess.open(trace_path, FileAccess.WRITE)
		if file == null:
			push_error("cannot open requested trace")
			quit(1)
			return
	var count := 0
	for tick in range(600):
		var row := probe.step()
		if row.status != OK:
			push_error("coupled probe aborted at tick%d status%s" % [tick, row.status])
			break
		var unobserved := reference.step()
		if (
			unobserved.status != OK
			or var_to_bytes(probe.snapshot()) != var_to_bytes(reference.snapshot())
		):
			push_error("observer changed physical state at tick%d" % tick)
			quit(1)
			return
		row["observer_on_off_physical_state_equal"] = true
		row["diagnostic_spawn_y_wu"] = spawn_y
		var text := JSON.stringify(row, "", true, true)
		print("M1 Slug tick: " + text)
		if file != null:
			file.store_line(text)
		count += 1
	if file != null:
		file.close()
	print(
		(
			(
				"M1 Slug trace: %d rows; diagnostic only; "
				+ "sleep/angular limits/motors/self-contact NOT implemented"
			)
			% count
		)
	)
	print(
		(
			"M1 contact observer equivalence: %d ticks bit-identical physical snapshots (on/off)"
			% count
		)
	)
	quit(0 if count == 600 else 1)
