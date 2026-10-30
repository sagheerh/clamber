class_name TowerData
extends RefCounted
## Explicit terrain/spawn/material input to Sim; no generated/tutorial geometry.
const TUNING = preload("res://core/tuning.tres")
var _state: Dictionary = {}


func configure(
	grid: SdfGrid,
	x: float,
	y: float,
	friction: Array[float],
	restitution: Array[float],
	tuning: Tuning
) -> Error:
	if grid == null or tuning == null or not is_finite(x) or not is_finite(y):
		return ERR_INVALID_DATA
	if friction.is_empty() or friction.size() != restitution.size():
		return ERR_INVALID_DATA
	for index in range(friction.size()):
		if (
			not is_finite(friction[index])
			or friction[index] < TUNING.physics_zero
			or not is_finite(restitution[index])
			or restitution[index] < TUNING.physics_zero
			or restitution[index] > TUNING.physics_one
		):
			return ERR_INVALID_DATA
	var terrain := grid.snapshot()
	var copy := SdfGrid.new()
	if copy.configure(terrain.rows, terrain.x, terrain.y, terrain.friction, tuning) != OK:
		return ERR_INVALID_DATA
	_state = {
		"terrain": copy.snapshot(),
		"x": x,
		"y": y,
		"friction": friction.duplicate(),
		"restitution": restitution.duplicate()
	}
	return OK


func snapshot() -> Dictionary:
	return _state.duplicate(true)


func terrain(tuning: Tuning) -> SdfGrid:
	if _state.is_empty():
		return null
	var grid := SdfGrid.new()
	var data: Dictionary = _state.terrain
	if grid.configure(data.rows, data.x, data.y, data.friction, tuning) != OK:
		return null
	return grid
