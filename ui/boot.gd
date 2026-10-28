extends Control
## Engineering-only boot surface, NOT a new product screen or S00 implementation.
signal pause_requested
signal flush_saves_requested
signal resume_to_pause_requested

const TUNING = preload("res://core/tuning.tres")
const TOKENS = preload("res://ui/theme/tokens.gd")
var _master_was_muted := false


func _ready() -> void:
	if OS.get_cmdline_args().has("--run-tests") or OS.get_cmdline_user_args().has("--run-tests"):
		var runner = load("res://tests/test_runner.gd").new()
		get_tree().quit(runner.run())
		return
	RenderingServer.set_default_clear_color(TOKENS.NAVY_900)
	Engine.max_fps = TUNING.camera_target_fps


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		pause_requested.emit()
		# SaveStore writes synchronously; future debounced stores subscribe here.
		flush_saves_requested.emit()
		get_tree().paused = true
		_master_was_muted = AudioServer.is_bus_mute(0)
		AudioServer.set_bus_mute(0, true)
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		AudioServer.set_bus_mute(0, _master_was_muted)
		# Do not resume gameplay automatically. No run/pause screen exists in M0.
		resume_to_pause_requested.emit()
