class_name RunResult
extends RefCounted
## Physics observation only. Scoring, flags and completed-run acceptance not authored.
var _state: Dictionary = {}


func configure(state: Dictionary) -> void:
	_state = state.duplicate(true)


func snapshot() -> Dictionary:
	return _state.duplicate(true)
