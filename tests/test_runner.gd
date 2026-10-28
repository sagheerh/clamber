extends RefCounted
## Exit status is explicit (assertions alone may be disabled in export templates).
const Store = preload("res://core/data/save_store.gd")
const SafeArea = preload("res://ui/components/safe_area.gd")
const TUNING = preload("res://core/tuning.tres")
const ROOT := "user://m0_test_saves"
var _failures := 0
var _checks := 0


func run() -> int:
	_test_scripts_compile("res://core")
	_test_scripts_compile("res://platform")
	_test_scripts_compile("res://ui")
	_test_tuning()
	_test_saves()
	_test_safe_area()
	_test_platform_stubs()
	print("M0: %d checks, %d failures" % [_checks, _failures])
	return 0 if _failures == 0 else 1


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("FAIL: " + label)


func _test_scripts_compile(path: String) -> void:
	for directory in DirAccess.get_directories_at(path):
		_test_scripts_compile(path.path_join(directory))
	for file in DirAccess.get_files_at(path):
		if file.ends_with(".gd"):
			var script = load(path.path_join(file))
			_check(script != null and script.can_instantiate(), "compiles: " + path.path_join(file))


func _test_tuning() -> void:
	var count := 0
	for property in TUNING.get_property_list():
		if (
			property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE
			and property.usage & PROPERTY_USAGE_EDITOR
		):
			count += 1
			_check(TUNING.get(property.name) != null, "tuning value: " + property.name)
	_check(count >= 40, "at least 40 exported tuning constants")
	_check(TUNING.physics_tick_hz == 60, "fixed 60 Hz")
	_check(TUNING.physics_fixed_dt_s == 1.0 / 60.0, "fixed step")
	_check(TUNING.physics_gravity_wu_s2 == -28.0, "GDD gravity unchanged")
	_check(TUNING.motors_gain_default == 0.70, "default motor strength unchanged")
	_check(TUNING.economy_offline_default, "offline default")
	_check(
		(
			ProjectSettings.get_setting("physics/common/physics_ticks_per_second")
			== TUNING.physics_tick_hz
		),
		"project tick matches tuning"
	)
	_check(
		(
			ProjectSettings.get_setting("display/window/size/viewport_width")
			== TUNING.camera_viewport_width_px
		),
		"viewport width matches tuning"
	)
	_check(
		(
			ProjectSettings.get_setting("display/window/size/viewport_height")
			== TUNING.camera_viewport_height_px
		),
		"viewport height matches tuning"
	)
	_check(
		(
			ProjectSettings.get_setting("display/window/handheld/orientation")
			== DisplayServer.SCREEN_PORTRAIT
		),
		"portrait locked"
	)
	_check(
		ProjectSettings.get_setting("rendering/renderer/rendering_method") == "mobile",
		"Mobile renderer"
	)


func _test_saves() -> void:
	_cleanup()
	var store := Store.new()
	var events: Array = []
	store.recovered.connect(func(path: String, source: String): events.append([path, source]))
	var errors: Array = []
	store.write_failed.connect(func(path: String, error: Error): errors.append([path, error]))
	var path := ROOT.path_join("creatures.json")
	var defaults := {"schema": 3, "creatures": []}
	var first := {"schema": 3, "creatures": ["previous save"]}
	var second := {"schema": 3, "creatures": ["latest save"]}
	_check(store.load_data(path, defaults) == defaults, "fresh install defaults")
	_check(events.is_empty(), "fresh install is not corruption")
	_check(store.save(path, first) == OK, "first atomic save")
	_check(store.save(path, second) == OK, "second atomic save")
	_check(store.load_data(path, defaults) == second, "primary beats backup")
	_check(not FileAccess.file_exists(path + ".tmp"), "tmp consumed on rename")
	_check(store.load_data(path + ".bak", defaults) == first, "backup is previous successful save")
	_write_raw(path, "garbage")
	_check(
		store.load_data(path, defaults) == first, "garbage primary recovers backup (AC-501/T-15)"
	)
	_check(events.back() == [path, ".bak"], "backup recovery signal")
	_check(store.save(path, second) == OK, "save after corruption succeeds")
	_check(
		store.load_data(path + ".bak", defaults) == first,
		"save after corruption preserves good backup"
	)
	_write_raw(path, "garbage")
	_write_raw(path + ".bak", "also garbage")
	var loaded := store.load_data(path, defaults)
	_check(loaded == defaults, "both corrupt and no tmp -> defaults")
	_check(events.back() == [path, "defaults"], "non-fatal default recovery signal")
	loaded.creatures.append("not shared")
	_check(defaults.creatures.is_empty(), "defaults deep copied")
	_write_raw(path + ".tmp", JSON.stringify(second))
	_check(store.load_data(path, defaults) == second, "interrupted write recovers tmp")
	_check(events.back() == [path, ".tmp"], "tmp recovery signal")
	_write_raw(path + ".bak", JSON.stringify(first))
	_check(store.load_data(path, defaults) == first, "backup has priority over tmp")
	_write_raw(path, JSON.stringify(second))
	_write_raw(path + ".bak.tmp", "partial backup staging")
	_check(
		store.load_data(path, defaults) == second,
		"interrupted backup staging leaves primary intact"
	)
	# Valid JSON is not enough: reject wrong root, missing/future/fractional schema.
	for invalid in ["[]", "null", "{}", '{"schema":4}', '{"schema":3.5}', '{"schema":"3"}']:
		_write_raw(path, invalid)
		_check(store.load_data(path, defaults) == first, "invalid schema/root recovers: " + invalid)
	_check(store.save(path, {"creatures": []}) == ERR_INVALID_DATA, "invalid writes rejected")
	_check(not errors.is_empty(), "write failure signalled")
	_write_raw(ROOT.path_join("blocked"), "this is a file, not a directory")
	_check(
		store.save(ROOT.path_join("blocked/child.json"), first) != OK,
		"unwritable destination returns error"
	)
	_write_raw(path, "bad")
	_write_raw(path + ".bak", "bad")
	_write_raw(path + ".tmp", "bad")
	_check(store.load_data(path, defaults) == defaults, "all three invalid -> defaults")
	_cleanup()


func _write_raw(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	_check(file != null, "fixture file opens")
	if file != null:
		file.store_string(text)
		file.flush()
		file.close()


func _cleanup() -> void:
	if not DirAccess.dir_exists_absolute(ROOT):
		return
	for file in DirAccess.get_files_at(ROOT):
		DirAccess.remove_absolute(ROOT.path_join(file))
	if DirAccess.dir_exists_absolute(ROOT):
		DirAccess.remove_absolute(ROOT)


func _test_safe_area() -> void:
	var portrait := Rect2(0, 0, 1080, 2340)
	_check(
		SafeArea.content_margins(portrait, portrait, Transform2D.IDENTITY) == Vector4.ZERO,
		"no cutout -> no margins"
	)
	_check(
		(
			SafeArea.content_margins(portrait, Rect2(0, 80, 1080, 2220), Transform2D.IDENTITY)
			== Vector4(0, 80, 0, 40)
		),
		"portrait top/bottom insets"
	)
	var scaled := Transform2D(Vector2(2, 0), Vector2(0, 2), Vector2.ZERO)
	_check(
		(
			SafeArea.content_margins(Rect2(0, 0, 2160, 4680), Rect2(0, 160, 2160, 4440), scaled)
			== Vector4(0, 80, 0, 40)
		),
		"physical -> viewport margins"
	)
	# On short displays, the Android status area can be entirely in the letterbox.
	var letterbox := Transform2D(Vector2(1, 0), Vector2(0, 1), Vector2(100, 200))
	_check(
		(
			SafeArea.content_margins(
				Rect2(100, 200, 1080, 2340), Rect2(0, 80, 1280, 2600), letterbox
			)
			== Vector4.ZERO
		),
		"letterbox absorbs inset"
	)
	_check(
		(
			SafeArea.content_margins(
				Rect2(0, 0, 1080, 1920), Rect2(30, 60, 1020, 1800), Transform2D.IDENTITY
			)
			== Vector4(30, 60, 30, 60)
		),
		"16:9 insets"
	)
	_check(
		(
			SafeArea.content_margins(
				Rect2(0, 0, 1080, 2520), Rect2(0, 90, 1080, 2370), Transform2D.IDENTITY
			)
			== Vector4(0, 90, 0, 60)
		),
		"21:9 insets"
	)


func _test_platform_stubs() -> void:
	var share := preload("res://platform/share_plugin.gd").new()
	var billing := preload("res://platform/billing.gd").new()
	var ads := preload("res://platform/ads.gd").new()
	var haptics := preload("res://platform/haptics.gd").new()
	var callbacks: Array = []
	share.completed.connect(func(success: bool): callbacks.append(success))
	billing.purchase_completed.connect(func(_id: String, success: bool): callbacks.append(success))
	billing.restore_completed.connect(func(success: bool): callbacks.append(success))
	ads.completed.connect(func(success: bool): callbacks.append(success))
	_check(
		(
			not share.is_available()
			and not billing.is_available()
			and not ads.is_available()
			and not haptics.is_available()
		),
		"all capabilities unavailable offline"
	)
	share.share_text("CLAMBER")
	share.share_image("", "CLAMBER")
	billing.purchase("no-products-in-M0")
	billing.restore_purchases()
	ads.show_rewarded()
	haptics.play(PackedInt32Array([8]))
	_check(
		callbacks == [false, false, false, false, false], "stubs complete without granting anything"
	)
