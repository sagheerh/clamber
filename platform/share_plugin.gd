class_name ShareService
extends RefCounted
## Desktop/offline no-op. TODO(Android): ACTION_SEND behind this interface.
signal completed(success: bool)


func is_available() -> bool:
	return false


func share_text(_text: String) -> void:
	completed.emit(false)


func share_image(_path: String, _text: String) -> void:
	completed.emit(false)
