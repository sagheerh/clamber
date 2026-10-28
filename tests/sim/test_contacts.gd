extends SceneTree
## Real component response tests, NOT assembled-creature FA-5 or static-scene evidence.
const TUNING = preload("res://core/tuning.tres")
var _checks := 0
var _failures := 0


func _initialize() -> void:
	_models()
	_terrain()
	_controlled_feet()
	_swept_contact()
	_rejection_and_restore()
	print("M1 contact primitives: %d checks, %d failures" % [_checks, _failures])
	print("M1 contact scope: controlled component loads only; FA-3/4/5/6 and AC gates NOT RUN")
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("FAIL M1 contact: " + label)


func _models() -> void:
	var sizes := [3, 8, 6]
	var index := 0
	for name in CreaturePresets.FILES:
		var model := CreaturePresets.load_model(name, TUNING)
		_check(model != null, "load real preset " + name)
		if model == null:
			continue
		var bodies := model.create_bodies(0.0, 2.0)
		_check(bodies.size() == sizes[index], "actual preset creates all capsule bodies")
		_check(absf(bodies[0].mass - 0.77) <= 1e-12, "head mass derived from owner values")
		var mass := 0.0
		for body in bodies:
			_check(body.is_valid(), "body has finite endpoints and owner geometry")
			_check(body.radius > TUNING.physics_contact_slop_wu, "real preset radius above slop")
			_check(
				body.a.inverse_mass == 2.0 / body.mass and body.b.inverse_mass == 2.0 / body.mass,
				"mass is split between endpoints"
			)
			mass += body.mass
		_check(absf(mass - model.total_mass()) <= 1e-12, "creature mass sums actual parts")
		var definition := model.definition()
		var pairs := model.d10_pairs()
		_check(not pairs.is_empty(), "real self-contact list is nonempty")
		for pair in model.collision_pairs():
			_check(
				bodies[pair[0]].kind != "foot" and bodies[pair[1]].kind != "foot",
				"layer11 foot excluded from self response mask"
			)
		var distance_two := 0
		var limit: float = (
			TUNING.physics_joint_length_wu
			- TUNING.physics_contact_slop_wu
			- TUNING.physics_d10_bend_margin_wu
		)
		for pair in pairs:
			var a: int = pair[0]
			var c: int = pair[1]
			_check(
				definition.parts[c].parent != a and definition.parts[a].parent != c,
				"adjacent pair never collides"
			)
			if _distance_two(definition.parts, a, c):
				distance_two += 1
				_check(
					bodies[a].radius + bodies[c].radius < limit,
					"D-10 real preset distance-two clearance"
				)
		_check(distance_two > 0, "D-10 real preset guard cannot vacuously succeed")
		var bad := definition.duplicate(true)
		bad.parts[1].parent = 1
		_check(
			model.configure(bad, TUNING) != OK and model.definition() == definition,
			"bad tree configure is atomic"
		)
		bad = definition.duplicate(true)
		bad.parts[1].channel = "JUMP"
		_check(model.configure(bad, TUNING) != OK, "third channel rejected")
		var tuning: Tuning = TUNING.duplicate(true)
		tuning.physics_head_collision_radius_wu = limit
		_check(
			model.configure(definition, tuning) != OK and model.definition() == definition,
			"D-10 rejects actual preset with oversized head"
		)
		definition.parts[0].kind = "foot"
		pairs.clear()
		_check(
			model.definition().parts[0].kind == "head" and not model.d10_pairs().is_empty(),
			"definition/pair snapshots do not alias"
		)
		index += 1
	_check(CreaturePresets.load_model("../unknown", TUNING) == null, "unknown preset path rejected")


func _distance_two(parts: Array, a: int, c: int) -> bool:
	var pa: int = parts[a].parent
	var pc: int = parts[c].parent
	return (
		(pa >= 0 and pc == pa)
		or (pa >= 0 and parts[pa].parent == c)
		or (pc >= 0 and parts[pc].parent == a)
	)


func _floor() -> SdfGrid:
	var rows: Array = []
	for iy in range(17):
		var row := PackedFloat64Array()
		for ix in range(25):
			row.append(-1.0 + iy * TUNING.physics_sdf_cell_wu)
		rows.append(row)
	var terrain := SdfGrid.new()
	_check(
		terrain.configure(rows, -2.0, -1.0, TUNING.physics_grip_friction, TUNING) == OK,
		"explicit floor SDF/material setup"
	)
	# Caller mutation cannot change the copied grid.
	rows[0][0] = NAN
	return terrain


func _terrain() -> void:
	var grid := _floor()
	var sample := grid.sample(0.125, 0.125)
	_check(
		sample.distance == 0.125 and sample.nx == 0.0 and sample.ny == 1.0,
		"bilinear SDF distance and normal"
	)
	_check(grid.sample(-3.0, 0.0).is_empty(), "outside grid has no invented floor")
	_check(grid.sample(NAN, 0.0).is_empty(), "non-finite query rejected")
	_check(
		grid.configure([PackedFloat64Array([0.0, NAN])], 0.0, 0.0, 0.9, TUNING) != OK,
		"invalid grid rejected"
	)
	_check(grid.sample(0.125, 0.125) == sample, "grid reconfigure rejection is atomic")


func _foot() -> CapsuleBody:
	var model := CreaturePresets.load_model("Slug", TUNING)
	_check(model != null, "contact fixture uses actual Slug")
	return model.create_bodies(0.0, 2.0)[2]


func _place(body: CapsuleBody, y: float, vx: float, vy: float) -> void:
	body.a.x = 0.0
	body.b.x = body.rest_length
	for point in [body.a, body.b]:
		point.y = y
		point.previous_x = point.x
		point.previous_y = y + 0.01
		point.velocity_x = vx
		point.velocity_y = vy


func _resolve(body: CapsuleBody, grid: SdfGrid, total_mass: float, lowest: bool = true) -> Error:
	return CapsuleContact.resolve(
		body,
		grid,
		total_mass,
		lowest,
		TUNING.physics_grip_friction,
		TUNING.physics_foot_restitution,
		TUNING
	)


func _controlled_feet() -> void:
	var grid := _floor()
	var model := CreaturePresets.load_model("Slug", TUNING)
	var mass := model.total_mass()
	var weight: float = mass * absf(TUNING.physics_gravity_wu_s2)
	var threshold: float = maxf(
		TUNING.physics_grip_normal_force_floor, TUNING.physics_grip_normal_force_ratio * weight
	)
	# Explicit controlled prior-force state, NOT force measured from a whole-creature stance.
	for load in [threshold * 0.5, threshold, weight / 2.0, weight]:
		var foot := _foot()
		_place(foot, foot.radius - TUNING.physics_contact_slop_wu - 0.01, 1.0, -1.0)
		foot.normal_force_last_tick = load
		var first := foot.a
		var second := foot.b
		_check(_resolve(foot, grid, mass) == OK, "controlled foot contact resolves")
		_check(
			foot.grounded and foot.gripping == (load >= threshold),
			"actual response uses last-tick ratio/floor and grounding"
		)
		if load < threshold:
			_check(
				foot.a.velocity_x > 0.0 and foot.a.velocity_x < 1.0,
				"below-band foot really slips after damping"
			)
		else:
			_check(
				absf(foot.a.velocity_x) <= 1e-12 and absf(foot.b.velocity_x) <= 1e-12,
				"loaded contact really removes tangent speed"
			)
		_check(
			foot.a.y >= foot.radius - TUNING.physics_contact_slop_wu - 1e-12,
			"positional response projects out of floor"
		)
		_check(
			foot.normal_force_last_tick > 0.0,
			"response measures new normal force, not fabricated zero"
		)
		_check(
			foot.a == first and foot.b == second,
			"contact preserves constraint-bound endpoint identity"
		)
		print(
			(
				(
					"M1 controlled foot: prior_force=%s threshold=%s vx=%s "
					+ "grounded=%s grip=%s measured_next_force=%s"
				)
				% [
					load,
					threshold,
					foot.a.velocity_x,
					foot.grounded,
					foot.gripping,
					foot.normal_force_last_tick
				]
			)
		)
	# Two separately controlled contacts at half weight; not a coupled stance claim.
	for i in range(2):
		var foot := _foot()
		_place(foot, 0.0, 1.0, -1.0)
		foot.normal_force_last_tick = weight / 2.0
		_check(
			_resolve(foot, grid, mass) == OK and foot.gripping,
			"two controlled half-weight contacts grip"
		)
	var airborne := _foot()
	_place(airborne, 1.0, 1.0, -1.0)
	airborne.normal_force_last_tick = weight
	_check(_resolve(airborne, grid, mass) == OK, "airborne response")
	_check(
		(
			not airborne.grounded
			and not airborne.gripping
			and airborne.normal_force_last_tick == 0.0
			and airborne.a.velocity_x == 1.0
		),
		"airborne cannot grip even with stale loaded history"
	)
	var elevated := _foot()
	_place(elevated, 0.0, 1.0, -1.0)
	elevated.normal_force_last_tick = weight
	_check(
		(
			_resolve(elevated, grid, mass, false) == OK
			and not elevated.gripping
			and elevated.a.velocity_x > 0.0
		),
		"not-lowest foot cannot receive grip bias"
	)


func _rejection_and_restore() -> void:
	var grid := _floor()
	var foot := _foot()
	_place(foot, 0.0, 1.0, -1.0)
	foot.normal_force_last_tick = 100.0
	var before := foot.snapshot()
	_check(_resolve(foot, grid, 1.55) == OK, "checkpoint response")
	var expected := foot.snapshot()
	_check(
		foot.restore(before) == OK and _resolve(foot, grid, 1.55) == OK,
		"restore then contact response"
	)
	_check(foot.snapshot() == expected, "identical complete contact continuation")
	for value in [NAN, INF, -INF]:
		foot.a.velocity_x = value
		var corrupted := var_to_bytes(foot.snapshot())
		_check(_resolve(foot, grid, 1.55) != OK, "non-finite body rejected")
		_check(
			var_to_bytes(foot.snapshot()) == corrupted,
			"rejection preserves corrupted input, no silent healing"
		)
		_check(foot.restore(before) == OK, "explicit recovery only")
	before = foot.snapshot()
	_check(
		_resolve(foot, grid, NAN) != OK and foot.snapshot() == before,
		"bad force input rejected atomically"
	)
	_place(foot, -0.75, 1.0, -1.0)
	before = foot.snapshot()
	_check(
		_resolve(foot, grid, 1.55) == ERR_PARAMETER_RANGE_ERROR and foot.snapshot() == before,
		"excessive projection reported, no silent respawn"
	)
	_place(foot, 0.0, 1.0, -1.0)
	foot.a.x = -100.0
	foot.b.x = -99.75
	before = foot.snapshot()
	_check(
		_resolve(foot, grid, 1.55) != OK and foot.snapshot() == before,
		"unqueryable terrain rejection atomic"
	)
	var malformed := before.duplicate(true)
	malformed.force = INF
	_check(
		foot.restore(malformed) != OK and foot.snapshot() == before,
		"bad contact snapshot restore atomic"
	)
	var undefined := SdfGrid.new()
	_check(
		(
			undefined.configure(
				[PackedFloat64Array([0.0, 0.0]), PackedFloat64Array([0.0, 0.0])],
				0.0,
				0.0,
				0.9,
				TUNING
			)
			== OK
		),
		"finite flat-field fixture configured"
	)
	_check(undefined.sample(0.0, 0.0).is_empty(), "zero SDF gradient never invents a normal")


func _swept_contact() -> void:
	var rows: Array = []
	for iy in range(9):
		var row := PackedFloat64Array()
		for ix in range(9):
			row.append(absf(-1.0 + ix * 0.25) - 0.125)
		rows.append(row)
	var wall := SdfGrid.new()
	_check(wall.configure(rows, -1.0, -1.0, 0.9, TUNING) == OK, "closed slab SDF")
	var foot := _foot()
	foot.a.x = 0.2
	foot.b.x = 0.2
	foot.a.y = 0.0
	foot.b.y = foot.rest_length
	for point in [foot.a, foot.b]:
		point.previous_x = -0.2
		point.previous_y = point.y
		point.velocity_x = 24.0
		point.velocity_y = 0.0
	_check(
		(
			wall.sample(-0.2, 0.0).distance > foot.radius
			and wall.sample(0.2, 0.0).distance > foot.radius
		),
		"both tick endpoints clear the closed slab"
	)
	_check(_resolve(foot, wall, 1.55) == OK, "swept capsule contact resolves crossing")
	_check(
		foot.a.x < -0.125 and foot.b.x < -0.125,
		"previous-position sweep prevents through-slab tunnelling"
	)
	_check(
		foot.a.velocity_x <= 0.0 and foot.b.velocity_x <= 0.0,
		"entering-side normal reverses incoming speed"
	)
