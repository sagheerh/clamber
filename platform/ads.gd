class_name AdsService
extends RefCounted
## Never loads ads. TODO(Android/P2): adapter; retain all first-flag/offline gates.
signal completed(reward_earned: bool)


func is_available() -> bool:
	return false


func show_rewarded() -> void:
	completed.emit(false)
