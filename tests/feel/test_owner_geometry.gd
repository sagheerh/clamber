extends SceneTree
## Real analytic geometry assertions; NOT contact/gait/sleep/soak evidence.
const TUNING = preload("res://core/tuning.tres")
const Harness = preload("res://tests/feel/harness.gd")
const KINDS = ["limb", "passive", "motor", "foot", "head"]
var _checks := 0
var _failures := 0
var _report: Dictionary = {}


func _initialize() -> void:
	var limit: float = (
		TUNING.physics_joint_length_wu
		- TUNING.physics_contact_slop_wu
		- TUNING.physics_d10_bend_margin_wu
	)
	_check(limit > 0.0, "positive owner D-10 clearance budget")
	_check(
		not _pair_allowed(limit / 2.0, limit / 2.0, limit),
		"exact equality to D-10 bound is forbidden"
	)
	_check(Harness.readable_pixels(14.999999999999998, 15.0), "F21 float-noise boundary accepted")
	_check(not Harness.readable_pixels(14.5, 15.0), "F21 real half-pixel regression rejected")
	_check(
		not Harness.readable_pixels(15.0 - 2e-9, 15.0), "F21 allowance is not wider than specified"
	)
	_check(not Harness.readable_pixels(NAN, 15.0), "F21 non-finite pixels rejected")
	var readability := true
	var min_pixels := INF
	for kind in KINDS:
		var radius := _radius(TUNING, kind)
		_check(
			_above_slop(radius, TUNING.physics_contact_slop_wu),
			kind + " collision radius strictly exceeds slop"
		)
		var pixels: float = radius * 2.0 * TUNING.feel_readability_px_per_wu
		min_pixels = minf(min_pixels, pixels)
		var target: float = TUNING.feel_min_collision_diameter_px
		if kind == "head":
			target = TUNING.feel_min_head_collision_diameter_px
		readability = readability and Harness.readable_pixels(pixels, target)
		_check(
			Harness.readable_pixels(pixels, target),
			"FA-1 " + kind + " collision diameter: %s px, target %s" % [pixels, target]
		)
		# Universal bound covers every future topology, not just current fixtures.
		for other in KINDS:
			_check(
				_pair_allowed(radius, _radius(TUNING, other), limit),
				"D-10 universal pair " + kind + "+" + other
			)
	var aspect_ok := true
	var min_aspect := INF
	var max_aspect := 0.0
	for length in TUNING.physics_limb_lengths_wu:
		var aspect: float = length / (TUNING.physics_limb_collision_radius_wu * 2.0)
		min_aspect = minf(min_aspect, aspect)
		max_aspect = maxf(max_aspect, aspect)
		var valid := (
			aspect >= TUNING.feel_limb_aspect_ratio_min
			and aspect <= TUNING.feel_limb_aspect_ratio_max
		)
		aspect_ok = aspect_ok and valid
		_check(valid, "FA-2 shipped limb length %s gives aspect %s" % [length, aspect])
	var silhouette := true
	var fixtures: Array = []
	var expected_counts := [3, 8, 6]
	var presets: Array = Harness.preset_geometry()
	for index in range(presets.size()):
		var preset: Dictionary = presets[index]
		_check(preset.kinds.size() == expected_counts[index], "named preset fixture part count")
		_check(
			preset.kinds[0] == "head" and preset.parents[0] == -1, "head is root, no parent hinge"
		)
		var checked_pairs := 0
		for a in range(preset.kinds.size()):
			if a > 0:
				_check(preset.parents[a] >= 0 and preset.parents[a] < a, "acyclic parent index")
			_check(
				preset.parents.count(a) <= TUNING.physics_max_children, "at most two child sockets"
			)
			var kind: String = preset.kinds[a]
			if kind != "head":
				var dominant := _visual(TUNING, "head") > _visual(TUNING, kind)
				silhouette = silhouette and dominant
				_check(dominant, "FA-7 " + preset.name + " head visual radius dominates " + kind)
			for c in range(a + 1, preset.kinds.size()):
				if _distance_two(preset.parents, a, c):
					checked_pairs += 1
					_check(
						_pair_allowed(
							_radius(TUNING, kind), _radius(TUNING, preset.kinds[c]), limit
						),
						"D-10 " + preset.name + " distance-two pair %d/%d" % [a, c]
					)
		_check(checked_pairs > 0, "preset guard genuinely checked distance-two pairs")
		fixtures.append(
			{
				"name": preset.name,
				"parts": preset.kinds.size(),
				"distance_two_pairs_checked": checked_pairs
			}
		)
	_check(
		presets[2].channels[1] == "L" and presets[2].channels[3] == "L",
		"TwinRoller fixture motors share input channel"
	)
	# Boundary/negative controls for geometry predicates, not runtime acceptance.
	_check(
		not _pair_allowed(limit, TUNING.physics_foot_collision_radius_wu, limit),
		"oversized radius fails guard"
	)
	_check(
		not _above_slop(TUNING.physics_contact_slop_wu, TUNING.physics_contact_slop_wu),
		"radius at slop is forbidden"
	)
	_check(_distance_two([-1, 0, 0], 1, 2), "sibling distance-two pair is not skipped")
	var pending: Array = Harness.pending_runtime(TUNING)
	_check(pending.size() == 6, "three FA-3 scenes plus FA-4/5/6 plans exist")
	for plan in pending:
		_check(
			plan.status == "NOT RUN" and plan.observations == null,
			"unexecuted plan has no fabricated observations"
		)
		if plan.id == "FA-6":
			_check(
				plan.success_count == null,
				"tutorial success count is unknown, not zero or invented"
			)
	_report = {
		"scope": "analytic geometry and topology-only preset fixtures; no runtime presets",
		"source": "owner M1-D04",
		"derivation_sha256": "6453508be7cb808f643544ec3f3fdbd6560840876fc070511f4b5f50065dbc5e",
		"d10_limit_wu": limit,
		"preset_geometry": fixtures,
		"head_mass_derived": TUNING.physics_head_mass_per_wu * TUNING.physics_head_length_wu,
		"analytic":
		{
			"FA-1":
			{
				"status": "PASS (analytic only)" if readability else "FAIL",
				"minimum_collision_diameter_px": min_pixels,
				"scale_px_per_wu": TUNING.feel_readability_px_per_wu
			},
			"FA-2":
			{
				"status": "PASS (analytic only)" if aspect_ok else "FAIL",
				"min_aspect": min_aspect,
				"max_aspect": max_aspect
			},
			"FA-7": {"status": "PASS (analytic only)" if silhouette else "FAIL"},
		},
		"runtime": pending,
	}
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--report="):
			var file := FileAccess.open(argument.trim_prefix("--report="), FileAccess.WRITE)
			_check(file != null, "geometry report opened")
			if file != null:
				_report["checks"] = _checks
				_report["failures"] = _failures
				file.store_string(JSON.stringify(_report, "\t"))
	print("M1 owner geometry: %d checks, %d failures" % [_checks, _failures])
	for id in _report.analytic:
		print("M1 geometry %s: %s" % [id, _report.analytic[id].status])
	print("M1 feel runtime: FA-3/4/5/6 NOT RUN (no contacts/motors/static-scene/tutorial evidence)")
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("FAIL M1 geometry: " + label)


func _radius(tuning: Tuning, kind: String) -> float:
	return tuning.get("physics_" + kind + "_collision_radius_wu")


func _visual(tuning: Tuning, kind: String) -> float:
	return tuning.get("art_" + kind + "_visual_radius_wu")


func _pair_allowed(a: float, c: float, limit: float) -> bool:
	return a + c < limit


func _distance_two(parents: Array, a: int, c: int) -> bool:
	var pa: int = parents[a]
	var pc: int = parents[c]
	return (
		(pa >= 0 and pc == pa) or (pa >= 0 and parents[pa] == c) or (pc >= 0 and parents[pc] == a)
	)


func _above_slop(radius: float, slop: float) -> bool:
	return radius > slop
