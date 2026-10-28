class_name HapticsService
extends RefCounted
## No vibration, including first run. TODO(Android): gated adapter after M3.


func is_available() -> bool:
	return false


func play(_pattern_ms: PackedInt32Array) -> void:
	pass
