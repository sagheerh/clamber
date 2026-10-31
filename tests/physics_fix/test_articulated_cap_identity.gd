# gdlint: disable=max-line-length
extends SceneTree
## Eight adapter checks, ZERO world ticks. Reads, never regenerates, old evidence.
const CANDIDATE = preload("res://tests/physics_fix/actuated_articulated_candidate.gd")
const TUNING = preload("res://core/tuning.tres")
const ARCHIVE := "res://tests/fixtures/m1_articulated_execution/6b48e638c368/idle-Slug.jsonl.gz"
var _checks := 0
var _failures := 0


func _initialize() -> void:
	var raw := FileAccess.get_file_as_bytes(ARCHIVE).decompress_dynamic(
		8388608, FileAccess.COMPRESSION_GZIP
	)
	var lines := raw.get_string_from_utf8().strip_edges().split("\n")
	_check(lines.size() == 2, "immutable first failure has exactly two committed frames")
	var record: Dictionary = JSON.parse_string(lines[1]) if lines.size() == 2 else {}
	var candidate := CANDIDATE.new()
	var model := CreaturePresets.load_model("Slug", TUNING)
	var grid := R25Fixture.floor_grid()
	_check(grid != null, "flat component fixture")
	_check(
		(
			candidate.setup(
				model,
				grid,
				0.0,
				0.0,
				R25Fixture.materials(model),
				R25Fixture.materials(model, true),
				TUNING
			)
			== OK
		),
		"construct component, no advance"
	)
	var archived: Dictionary = record.get("state", {}).get("physical", {})
	# Godot JSON numbers are floats. Restore requires an integer clock counter.
	# Normalize ONLY this exact known fixture counter; NEVER cast coordinates or
	# accept a fractional/unknown tick. This does not advance/replay the archive.
	_check(archived.get("ticks") == 2.0, "JSON fixture has exactly two committed ticks")
	if archived.get("ticks") == 2.0:
		archived.ticks = 2
	_check(candidate.restore(archived) == OK, "restore archived committed frame, no replay")
	_check(not candidate._angular_cap_required(), "archived sub-cap motion does not activate cap")
	var before: PackedByteArray = var_to_bytes(candidate.snapshot())
	var x: Array[float] = [0.0, 0.0, 0.0]
	var y: Array[float] = [0.0, 0.0, 0.0]
	_check(
		candidate._finish_network_caps(x, y) == OK,
		"inactive cap is identity, not another projection"
	)
	_check(
		(
			before == var_to_bytes(candidate.snapshot())
			and x == [0.0, 0.0, 0.0]
			and y == [0.0, 0.0, 0.0]
		),
		"bitwise unchanged state and impulse accounts"
	)
	if _checks != 8:
		_failures += 1
	print("Articulated cap identity: %d checks, %d failures" % [_checks, _failures])
	print("Scope: archived component frame only; ZERO world ticks; NOT acceptance")
	quit(0 if _failures == 0 else 1)


func _check(value: bool, label: String) -> void:
	_checks += 1
	if not value:
		_failures += 1
		push_error("FAIL cap identity: " + label)
