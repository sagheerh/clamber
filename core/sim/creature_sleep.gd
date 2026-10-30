# gdlint: disable=max-returns
# Explicit malformed snapshot/observation exits preserve atomic state validation.
class_name CreatureSleep
extends RefCounted
## Owner R14 Decision2: positional dwell parks the plateau; does not repair it.
## Predicate reads ONLY explicit body snapshots; no timers, grounding/velocity epsilon.
const TUNING = preload("res://core/tuning.tres")
var asleep: bool = false
var still_ticks: int = TUNING.physics_zero
var last_sleep_tick: int = -TUNING.physics_one
var last_wake_tick: int = -TUNING.physics_one
var max_body_com_displacement_wu: float = TUNING.physics_zero
var max_body_dwell_displacement_wu: float = TUNING.physics_zero
var _dwell_start: Array = []
var _tuning: Tuning


func configure(tuning: Tuning) -> Error:
	if (
		tuning == null
		or not is_finite(tuning.sleep_still_displacement_wu)
		or tuning.sleep_still_displacement_wu <= TUNING.physics_zero
		or tuning.sleep_dwell_ticks <= TUNING.physics_zero
	):
		return ERR_INVALID_DATA
	_tuning = tuning.duplicate(true)
	return OK


func snapshot() -> Dictionary:
	return {
		"asleep": asleep,
		"still_ticks": still_ticks,
		"last_sleep_tick": last_sleep_tick,
		"last_wake_tick": last_wake_tick,
		"max_body_com_displacement_wu": max_body_com_displacement_wu,
		"max_body_dwell_displacement_wu": max_body_dwell_displacement_wu,
		"dwell_start": _dwell_start.duplicate(true),
	}


func restore(state: Dictionary) -> Error:
	if _tuning == null or not state.get("asleep") is bool:
		return ERR_INVALID_DATA
	for key in ["still_ticks", "last_sleep_tick", "last_wake_tick"]:
		if not state.get(key) is int:
			return ERR_INVALID_DATA
	var distance: Variant = state.get("max_body_com_displacement_wu")
	if (
		state.still_ticks < TUNING.physics_zero
		or state.still_ticks > _tuning.sleep_dwell_ticks
		or state.asleep != (state.still_ticks == _tuning.sleep_dwell_ticks)
		or state.last_sleep_tick < -TUNING.physics_one
		or state.last_wake_tick < -TUNING.physics_one
		or not (distance is float or distance is int)
		or not is_finite(float(distance))
		or distance < TUNING.physics_zero
	):
		return ERR_INVALID_DATA
	var start: Variant = state.get("dwell_start")
	var net: Variant = state.get("max_body_dwell_displacement_wu")
	if (
		not start is Array
		or (state.still_ticks > TUNING.physics_zero) == start.is_empty()
		or not (net is float or net is int)
		or not is_finite(float(net))
		or net < TUNING.physics_zero
		or (
			state.still_ticks > TUNING.physics_zero
			and (
				net >= _tuning.sleep_still_displacement_wu
				or distance >= _tuning.sleep_still_displacement_wu
			)
		)
	):
		return ERR_INVALID_DATA
	for body in start:
		if not body is Dictionary or _center(body).is_empty():
			return ERR_INVALID_DATA
	_dwell_start = start.duplicate(true)
	max_body_dwell_displacement_wu = net
	asleep = state.asleep
	still_ticks = state.still_ticks
	last_sleep_tick = state.last_sleep_tick
	last_wake_tick = state.last_wake_tick
	max_body_com_displacement_wu = distance
	return OK


func wake(tick: int) -> void:
	if asleep:
		last_wake_tick = tick
	asleep = false
	still_ticks = TUNING.physics_zero
	_dwell_start = []
	max_body_dwell_displacement_wu = TUNING.physics_zero


func observe(before: Array, after: Array, input_mask: int, tick: int) -> Error:
	if (
		_tuning == null
		or asleep
		or before.is_empty()
		or before.size() != after.size()
		or input_mask < TUNING.motors_input_released_mask
		or input_mask > TUNING.motors_input_both_mask
		or tick < TUNING.physics_zero
	):
		return ERR_INVALID_DATA
	var start: Array = before if still_ticks == TUNING.physics_zero else _dwell_start
	if start.size() != before.size():
		return ERR_INVALID_DATA
	var net: float = TUNING.physics_zero
	var maximum: float = TUNING.physics_zero
	for index in range(before.size()):
		if not before[index] is Dictionary or not after[index] is Dictionary:
			return ERR_INVALID_DATA
		var first := _center(before[index])
		var second := _center(after[index])
		if not start[index] is Dictionary:
			return ERR_INVALID_DATA
		var origin := _center(start[index])
		if first.is_empty() or second.is_empty() or origin.is_empty():
			return ERR_INVALID_DATA
		var x: float = second[TUNING.physics_zero] - first[TUNING.physics_zero]
		var y: float = second[TUNING.physics_one] - first[TUNING.physics_one]
		maximum = maxf(maximum, sqrt(x * x + y * y))
		x = second[TUNING.physics_zero] - origin[TUNING.physics_zero]
		y = second[TUNING.physics_one] - origin[TUNING.physics_one]
		net = maxf(net, sqrt(x * x + y * y))
	if not is_finite(maximum) or not is_finite(net):
		return ERR_INVALID_DATA
	max_body_com_displacement_wu = maximum
	max_body_dwell_displacement_wu = net
	if (
		input_mask != TUNING.motors_input_released_mask
		or maximum >= _tuning.sleep_still_displacement_wu
		or net >= _tuning.sleep_still_displacement_wu
	):
		still_ticks = TUNING.physics_zero
		_dwell_start = []
	else:
		if still_ticks == TUNING.physics_zero:
			_dwell_start = before.duplicate(true)
		still_ticks += TUNING.physics_one
	if still_ticks == _tuning.sleep_dwell_ticks:
		asleep = true
		last_sleep_tick = tick
	return OK


func _center(state: Dictionary) -> Array:
	var body := CapsuleBody.new()
	if body.restore(state) != OK:
		return []
	# CapsuleBody.restore enforces equal endpoint masses; arithmetic COM is exact form.
	var two := TUNING.physics_one + TUNING.physics_one
	return [(body.a.x + body.b.x) / two, (body.a.y + body.b.y) / two]
