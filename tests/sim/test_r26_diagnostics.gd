# gdlint: disable=max-line-length,max-returns
# Compact artifact labels and explicit fail-path termination data.
extends SceneTree
## R26 LAST bounded D1/D2, and independent F77 fixtures; no automatic retry.
const TUNING = preload("res://core/tuning.tres")
var _folder := ""
var _mode := ""
var _engine := {}


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report-dir="):
			_folder = arg.trim_prefix("--report-dir=")
		if arg.begins_with("--mode="):
			_mode = arg.trim_prefix("--mode=")
	var passed := false
	if not _folder.is_empty():
		if _mode == "d1":
			passed = _d1()
		elif _mode == "d2":
			passed = _d2()
		elif _mode == "fa5":
			passed = _fa5()
		var report := FileAccess.open(_folder + "/engine.json", FileAccess.WRITE)
		if report != null:
			report.store_string(JSON.stringify(_engine, "", true, true))
			report.close()
	print("M1 R26 engine: " + JSON.stringify(_engine, "", true, true))
	quit(0 if passed else 1)


func _probe(
	name: String, tuning: Tuning, grid: SdfGrid, x: float, lift: float
) -> ActuatedLoadProbe:
	var model := CreaturePresets.load_model(name, tuning)
	var p := ActuatedLoadProbe.new()
	if (
		p.setup(
			model,
			grid,
			x,
			R25Fixture.spawn_y(model) + lift,
			R25Fixture.materials(model, false, tuning),
			R25Fixture.materials(model, true, tuning),
			tuning
		)
		!= OK
	):
		return null
	return p


func _termination(target: int) -> Dictionary:
	return {
		"target_ticks": target,
		"ticks": 0,
		"termination_reason": "completed",
		"failing_tick": null,
		"status": OK,
		"observer_status": OK
	}


func _d1() -> bool:
	var passed := true
	for mu in [0.9, 0.3, 1.8, 3.6]:
		var tuning: Tuning = TUNING.duplicate(true)
		tuning.physics_grip_friction = mu
		var p := _probe("Slug", tuning, R25Fixture.floor_grid(tuning), 0.0, 0.0)
		var twin := _probe("Slug", tuning, R25Fixture.floor_grid(tuning), 0.0, 0.0)
		var id := "mu_%s" % str(mu)
		var end := _termination(6000)
		_engine[id] = end
		if p == null or twin == null:
			end.merge(
				{
					"termination_reason": "setup_failure",
					"status": ERR_INVALID_DATA,
					"failing_tick": 0
				},
				true
			)
			passed = false
			continue
		p.collect_contact_samples = true
		var file := FileAccess.open(_folder + "/" + id + ".jsonl", FileAccess.WRITE)
		if file == null:
			end.merge(
				{
					"termination_reason": "file_open_failure",
					"status": ERR_FILE_CANT_WRITE,
					"failing_tick": 0
				},
				true
			)
			passed = false
			continue
		var model := CreaturePresets.load_model("Slug", tuning)
		var spawn := R25Fixture.spawn_y(model)
		for tick in range(6000):
			var row := p.advance(0)
			var other := twin.advance(0)
			if row.status != OK or other.status != OK:
				end.merge(
					{
						"termination_reason": "step_failure",
						"status": row.status,
						"observer_status": other.status,
						"failing_tick": tick
					},
					true
				)
				passed = false
				break
			if var_to_bytes(p.snapshot()) != var_to_bytes(twin.snapshot()):
				end.merge(
					{
						"termination_reason": "observer_state_mismatch",
						"status": ERR_INVALID_DATA,
						"failing_tick": tick
					},
					true
				)
				passed = false
				break
			row.observer_on_off_physical_state_equal = true
			row.diagnostic_actuated = true
			row.diagnostic_spring_return_live = true
			row.diagnostic_spawn_y_wu = spawn
			row.diagnostic_spawn_lift_wu = 0.0
			row.diagnostic_authored_bottom_wu = .01 - spawn
			row.diagnostic_lowest_initial_surface_wu = .01
			row.diagnostic_friction = mu
			row.diagnostic_motor_stiffness = tuning.motors_joint_stiffness
			row.diagnostic_motor_damping = tuning.motors_joint_damping
			row.diagnostic_passive_stiffness = tuning.physics_passive_stiffness
			row.diagnostic_angular_impulse_limit_rad_s = (
				tuning.physics_max_constraint_angular_impulse_rad_s
			)
			file.store_line(JSON.stringify(row, "", true, true))
			end.ticks += 1
		file.close()
	return passed


func _d2() -> bool:
	var passed := true
	for arm in ["baseline", "final_distance"]:
		var sim := R25Fixture.public_sim("Hopper")
		var p: ActuatedLoadProbe = sim._solver._rig._probe as ActuatedLoadProbe
		p.collect_length_phases = true
		p.diagnostic_final_distance_pass = arm == "final_distance"
		var control: Sim = R25Fixture.public_sim("Hopper") if arm == "baseline" else null
		var end := _termination(7200)
		_engine[arm] = end
		var file := FileAccess.open(_folder + "/" + arm + ".jsonl", FileAccess.WRITE)
		if file == null:
			end.merge(
				{
					"termination_reason": "file_open_failure",
					"status": ERR_FILE_CANT_WRITE,
					"failing_tick": 0
				},
				true
			)
			passed = false
			continue
		for tick in range(7200):
			var mask: int = (tick / 60) % 4
			sim.step(mask)
			if control != null:
				control.step(mask)
			if sim.last_status != OK or (control != null and control.last_status != OK):
				end.merge(
					{
						"termination_reason": "step_failure",
						"status": sim.last_status,
						"observer_status": control.last_status if control != null else OK,
						"failing_tick": tick
					},
					true
				)
				passed = false
				break
			if control != null and var_to_bytes(sim.snapshot()) != var_to_bytes(control.snapshot()):
				end.merge(
					{
						"termination_reason": "observer_state_mismatch",
						"status": ERR_INVALID_DATA,
						"failing_tick": tick
					},
					true
				)
				passed = false
				break
			var row := {
				"tick": tick,
				"input_mask": mask,
				"bodies": sim.get_render_state(),
				"phases": p.length_phases if p.length_phase_tick == tick else {},
				"sleep": sim.snapshot().accumulator.solver.rig.sleep,
				"observer_equal": true if control != null else null,
				"diagnostic_final_distance_pass": arm == "final_distance"
			}
			file.store_line(JSON.stringify(row, "", true, true))
			end.ticks += 1
		file.close()
	return passed


func _ledge() -> SdfGrid:
	var rows: Array = []
	for iy in range(49):
		var y := -4.0 + iy * TUNING.physics_sdf_cell_wu
		var row := PackedFloat64Array()
		for ix in range(97):
			var x := -12.0 + ix * TUNING.physics_sdf_cell_wu
			var qx := -x
			var qy := y
			var dx := maxf(qx, 0.0)
			var dy := maxf(qy, 0.0)
			var corner := sqrt(dx * dx + dy * dy) + minf(maxf(qx, qy), 0.0)
			row.append(minf(corner, y + 2.5))
		rows.append(row)
	var grid := SdfGrid.new()
	if grid.configure(rows, -12.0, -4.0, TUNING.physics_grip_friction, TUNING) != OK:
		return null
	return grid


func _fa5() -> bool:
	var plan: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://tests/fixtures/r26_fa5.json")
	)
	var passed := true
	for spec in plan.cases:
		var grid := _ledge() if spec.terrain == "ledge" else R25Fixture.floor_grid()
		var p := _probe("Hopper", TUNING, grid, spec.x, spec.lift)
		var twin := _probe("Hopper", TUNING, grid, spec.x, spec.lift)
		var end := _termination(spec.ticks)
		_engine[spec.id] = end
		if p == null or twin == null:
			end.merge(
				{
					"termination_reason": "setup_failure",
					"status": ERR_INVALID_DATA,
					"failing_tick": 0
				},
				true
			)
			passed = false
			continue
		var initial := p.snapshot()
		end.initial_bodies = initial.bodies
		# Explicit airborne preflight BEFORE stepping, based on actual geometry/SDF.
		var clearance := INF
		for body in p.bodies:
			for point in [body.a, body.b]:
				var sample := grid.sample(point.x, point.y)
				if sample.is_empty():
					clearance = -INF
					break
				clearance = minf(clearance, sample.distance - body.radius)
		end.initial_min_clearance_wu = clearance
		if spec.lift > 0.0 and clearance <= TUNING.physics_contact_slop_wu:
			end.merge(
				{
					"termination_reason": "airborne_preflight_failure",
					"status": ERR_INVALID_DATA,
					"failing_tick": 0
				},
				true
			)
			passed = false
			continue
		p.collect_contact_samples = true
		var file := FileAccess.open(_folder + "/" + spec.id + ".jsonl", FileAccess.WRITE)
		if file == null:
			end.merge(
				{
					"termination_reason": "file_open_failure",
					"status": ERR_FILE_CANT_WRITE,
					"failing_tick": 0
				},
				true
			)
			passed = false
			continue
		for tick in range(spec.ticks):
			var mask: int = (tick / 60) % 4 if spec.input == "blocks60" else 0
			var row := p.advance(mask)
			var other := twin.advance(mask)
			if row.status != OK or other.status != OK:
				end.merge(
					{
						"termination_reason": "step_failure",
						"status": row.status,
						"observer_status": other.status,
						"failing_tick": tick,
						"failed_pre_step_bodies": p.snapshot().bodies
					},
					true
				)
				passed = false
				break
			if var_to_bytes(p.snapshot()) != var_to_bytes(twin.snapshot()):
				end.merge(
					{
						"termination_reason": "observer_state_mismatch",
						"status": ERR_INVALID_DATA,
						"failing_tick": tick
					},
					true
				)
				passed = false
				break
			row.observer_on_off_physical_state_equal = true
			row.fixture = spec.id
			row.input_mask = mask
			file.store_line(JSON.stringify(row, "", true, true))
			end.ticks += 1
		file.close()
	return passed
