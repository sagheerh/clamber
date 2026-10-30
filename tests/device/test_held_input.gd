extends SceneTree
## Input ownership unit tests only. No Sim, solver or measurement ticks.
const HELD = preload("res://tests/device/held_input.gd")
var _checks := 0
var _failures := 0


func _initialize() -> void:
	var held := HELD.new()
	_check(held.mask() == 0)
	held.press("touch:0", 1, true)
	_check(held.mask() == 1)
	held.press("touch:1", 2, true)
	_check(held.mask() == 3)
	held.press("touch:2", 1, true)
	held.release("touch:2")
	_check(held.mask() == 3)
	held.release("touch:0")
	_check(held.mask() == 2)
	held.press("touch:1", 1, true)
	_check(held.mask() == 2)
	held.clear()
	_check(held.mask() == 0)
	held.press("key:A", 1)
	held.press("key:Left", 1)
	held.release("key:A")
	_check(held.mask() == 1)
	held.release("key:Left")
	_check(held.mask() == 0)
	held.press("invalid", 4)
	held.press("outside", 0)
	_check(held.mask() == 0)
	print("M1 lab input: %d checks, %d failures; zero solver ticks" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _check(value: bool) -> void:
	_checks += 1
	if not value:
		_failures += 1
