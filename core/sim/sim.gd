# gdlint: disable=unused-argument
class_name Sim
extends RefCounted
## M0 interface only. No solver, gameplay, or manufactured results.
const TUNING = preload("res://core/tuning.tres")


func setup(creature: CreatureModel, tower: TowerData, seed: int, tuning: Tuning) -> void:
	pass


func step(input_mask: int) -> void:
	pass


func get_render_state() -> Array:
	return []


func snapshot() -> Dictionary:
	return {}


func restore(s: Dictionary) -> void:
	pass


func state_hash() -> int:
	return TUNING.physics_zero


func result() -> RunResult:
	return null
