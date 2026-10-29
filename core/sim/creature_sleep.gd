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
	var maximum: float = TUNING.physics_zero
	for index in range(before.size()):
		if not before[index] is Dictionary or not after[index] is Dictionary:
			return ERR_INVALID_DATA
		var first := _center(before[index])
		var second := _center(after[index])
		if first.is_empty() or second.is_empty():
			return ERR_INVALID_DATA
		var x: float = second[TUNING.physics_zero] - first[TUNING.physics_zero]
		var y: float = second[TUNING.physics_one] - first[TUNING.physics_one]
		maximum = maxf(maximum, sqrt(x * x + y * y))
	if not is_finite(maximum):
		return ERR_INVALID_DATA
	max_body_com_displacement_wu = maximum
	if (
		input_mask != TUNING.motors_input_released_mask
		or maximum >= _tuning.sleep_still_displacement_wu
	):
		still_ticks = TUNING.physics_zero
	else:
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
