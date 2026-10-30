class_name R25Fixture
extends RefCounted
## Test-only shared authored geometry; no support/load/pose injection.
const TUNING = preload("res://core/tuning.tres")


static func floor_grid(tuning: Tuning = TUNING) -> SdfGrid:
	var rows: Array = []
	for iy in range(49):
		var row := PackedFloat64Array()
		for ix in range(97):
			row.append(-4.0 + iy * tuning.physics_sdf_cell_wu)
		rows.append(row)
	var grid := SdfGrid.new()
	assert(grid.configure(rows, -12.0, -4.0, tuning.physics_grip_friction, tuning) == OK)
	return grid


static func spawn_y(model: CreatureModel) -> float:
	var bottom := INF
	for body in model.create_bodies(0.0, 0.0):
		bottom = minf(bottom, minf(body.a.y, body.b.y) - body.radius)
	return .01 - bottom


static func materials(
	model: CreatureModel, bounce: bool = false, tuning: Tuning = TUNING
) -> Array[float]:
	var values: Array[float] = []
	for part in model.definition().parts:
		values.append(tuning.physics_foot_restitution if bounce else tuning.physics_grip_friction)
	return values


static func center(states: Array) -> Array:
	var x := 0.0
	var y := 0.0
	var mass := 0.0
	for b in states:
		mass += b.mass
		x += b.mass * (b.a.x + b.b.x) / 2.0
		y += b.mass * (b.a.y + b.b.y) / 2.0
	return [x / mass, y / mass]


static func public_sim(name: String, lift: float = 0.0) -> Sim:
	var model := CreaturePresets.load_model(name, TUNING)
	var tower := TowerData.new()
	assert(
		(
			tower.configure(
				floor_grid(),
				0.0,
				spawn_y(model) + lift,
				materials(model),
				materials(model, true),
				TUNING
			)
			== OK
		)
	)
	var sim := Sim.new()
	sim.setup(model, tower, 305419896, TUNING)
	assert(sim.last_status == OK)
	return sim
