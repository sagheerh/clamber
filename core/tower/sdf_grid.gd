class_name SdfGrid
extends RefCounted
## Explicit signed-distance samples, bilinear normals; no outside-grid fallback.
const TUNING = preload("res://core/tuning.tres")
var _rows: Array = []
var _x: float
var _y: float
var _cell: float
var _friction: float


func configure(rows: Array, x: float, y: float, friction: float, tuning: Tuning) -> Error:
	if (
		tuning == null
		or not is_finite(x)
		or not is_finite(y)
		or not is_finite(friction)
		or friction < TUNING.physics_zero
	):
		return ERR_INVALID_DATA
	if (
		not is_finite(tuning.physics_sdf_cell_wu)
		or tuning.physics_sdf_cell_wu != TUNING.physics_sdf_cell_wu
		or rows.size() < TUNING.physics_one + TUNING.physics_one
	):
		return ERR_INVALID_DATA
	var width: int = TUNING.physics_zero
	var candidate: Array = []
	for row in rows:
		if not row is PackedFloat64Array or row.size() < TUNING.physics_one + TUNING.physics_one:
			return ERR_INVALID_DATA
		if width != TUNING.physics_zero and row.size() != width:
			return ERR_INVALID_DATA
		for value in row:
			if not is_finite(value):
				return ERR_INVALID_DATA
		width = row.size()
		candidate.append(row.duplicate())
	_rows = candidate
	_x = x
	_y = y
	_cell = tuning.physics_sdf_cell_wu
	_friction = friction
	return OK


func cell_size() -> float:
	return _cell


func sample(x: float, y: float) -> Dictionary:
	if _rows.is_empty() or not is_finite(x) or not is_finite(y):
		return {}
	var gx := (x - _x) / _cell
	var gy := (y - _y) / _cell
	var zero := TUNING.physics_zero
	var one := TUNING.physics_one
	if (
		not is_finite(gx)
		or not is_finite(gy)
		or gx < zero
		or gy < zero
		or gx > _rows[zero].size() - one
		or gy > _rows.size() - one
	):
		return {}
	var ix: int = mini(floori(gx), _rows[zero].size() - one - one)
	var iy: int = mini(floori(gy), _rows.size() - one - one)
	var tx := gx - ix
	var ty := gy - iy
	var lo: float = _rows[iy][ix] * (one - tx) + _rows[iy][ix + one] * tx
	var hi: float = _rows[iy + one][ix] * (one - tx) + _rows[iy + one][ix + one] * tx
	var dx: float = (
		(
			(_rows[iy][ix + one] - _rows[iy][ix]) * (one - ty)
			+ (_rows[iy + one][ix + one] - _rows[iy + one][ix]) * ty
		)
		/ _cell
	)
	var dy := (hi - lo) / _cell
	var squared := dx * dx + dy * dy
	var distance := lo * (one - ty) + hi * ty
	if not is_finite(squared) or squared <= zero or not is_finite(distance):
		return {}
	var length := sqrt(squared)
	return {"distance": distance, "nx": dx / length, "ny": dy / length, "friction": _friction}


func snapshot() -> Dictionary:
	return {"rows": _rows.duplicate(true), "x": _x, "y": _y, "cell": _cell, "friction": _friction}
