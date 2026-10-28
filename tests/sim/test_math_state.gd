extends SceneTree
## Synthetic mathematical fixtures, NOT creature tuning, gaits or M1 acceptance.
const Body = preload("res://core/sim/body.gd")
const Link = preload("res://core/sim/constraint.gd")
const TUNING = preload("res://core/tuning.tres")
var _checks := 0
var _failures := 0


func _initialize() -> void:
	_body_state()
	_rigid_link()
	_mass_weighting()
	_compliant_link()
	_invalid_constraints()
	_snapshot_projection()
	print("M1 math foundations: %d checks, %d failures" % [_checks, _failures])
	print("M1 acceptance: NOT RUN (no creature/contact/accumulator/replay/soak implementation)")
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("FAIL M1 math: " + label)


func _point(x: float, y: float, inverse_mass: float) -> SimBody:
	var body := Body.new()
	_check(body.setup(x, y, inverse_mass) == OK, "synthetic point setup")
	return body


func _body_state() -> void:
	var body := Body.new()
	_check(not body.is_valid(), "unconfigured body is not valid")
	_check(body.setup(1.25, -2.5, 0.5) == OK, "explicit mathematical state")
	_check(body.previous_x == body.x and body.previous_y == body.y, "previous position initialized")
	_check(body.velocity_x == 0.0 and body.velocity_y == 0.0, "initial velocity zero")
	_check(body.is_within_bounds(3.0) and not body.is_within_bounds(2.0), "explicit bound check")
	_check(not body.is_within_bounds(INF), "non-finite bound rejected")
	var saved := body.snapshot()
	body.x = 99.0
	body.velocity_y = 7.0
	_check(body.restore(saved) == OK and body.snapshot() == saved, "exact scalar state restore")
	var detached := body.snapshot()
	detached.x = 10.0
	_check(body.x == 1.25, "snapshot does not alias body")
	for invalid in [NAN, INF, -INF]:
		_check(body.setup(invalid, 0.0, 1.0) != OK, "non-finite position rejected")
		_check(body.setup(0.0, invalid, 1.0) != OK, "non-finite y rejected")
		_check(body.setup(0.0, 0.0, invalid) != OK, "non-finite inverse mass rejected")
		var candidate := saved.duplicate()
		candidate.velocity_x = invalid
		_check(
			body.restore(candidate) != OK and body.snapshot() == saved, "invalid restore is atomic"
		)
	_check(
		body.setup(0.0, 0.0, -1.0) != OK and body.snapshot() == saved,
		"negative inverse mass rejected"
	)
	for candidate in [{}, {"configured": true}, {"configured": "true"}]:
		_check(
			body.restore(candidate) != OK and body.snapshot() == saved,
			"incomplete restore rejected"
		)
	body.x = NAN
	_check(not body.is_valid(), "guard observes corrupted state")
	_check(body.restore(saved) == OK, "explicit restore recovers mathematical state")


func _rigid_link() -> void:
	var a = _point(0.0, 0.0, 1.0)
	var b = _point(2.0, 0.0, 1.0)
	var link := Link.new()
	_check(link.setup(a, b, 1.0, TUNING.physics_rigid_compliance) == OK, "rigid link setup")
	_check(link.project(TUNING) == OK, "rigid XPBD projection")
	_check(a.x == 0.5 and b.x == 1.5, "equal inverse mass gives symmetric correction")
	_check(a.y == 0.0 and b.y == 0.0, "no invented perpendicular correction")
	_check(link.multiplier == -0.5, "exact rigid multiplier")
	_check(a.previous_x == 0.0 and b.previous_x == 2.0, "projection preserves pre-step positions")
	_check(
		link.project(TUNING) == OK and b.x - a.x == 1.0, "already satisfied link remains satisfied"
	)
	link.reset_multiplier()
	_check(link.multiplier == 0.0, "explicit tick-boundary multiplier reset")


func _mass_weighting() -> void:
	var a = _point(0.0, 0.0, 0.0)
	var b = _point(0.0, 2.0, 1.0)
	var link := Link.new()
	_check(link.setup(a, b, 1.0, 0.0) == OK and link.project(TUNING) == OK, "anchored projection")
	_check(a.y == 0.0 and b.y == 1.0, "zero inverse mass point is pinned")
	_check(a.setup(0.0, 0.0, 1.0) == OK and b.setup(2.0, 0.0, 3.0) == OK, "weighted fixtures")
	link.reset_multiplier()
	_check(link.project(TUNING) == OK, "weighted projection")
	_check(a.x == 0.25 and b.x == 1.25, "corrections proportional to inverse masses")


func _compliant_link() -> void:
	var a = _point(0.0, 0.0, 1.0)
	var b = _point(2.0, 0.0, 1.0)
	var link := Link.new()
	var compliance := 1.0 / float(TUNING.physics_passive_stiffness)
	_check(link.setup(a, b, 1.0, compliance) == OK, "explicit compliant fixture")
	_check(link.project(TUNING) == OK, "compliant XPBD projection")
	var dt := 1.0 / float(TUNING.physics_tick_hz)
	var expected := -1.0 / (2.0 + compliance / (dt * dt))
	_check(link.multiplier == expected, "XPBD compliance scaled by fixed step squared")
	_check(b.x - a.x > 1.0 and b.x - a.x < 2.0, "compliant correction is not rigid correction")
	var state := link.snapshot()
	link.reset_multiplier()
	_check(link.restore(state) == OK and link.snapshot() == state, "restore compliance and lambda")


func _invalid_constraints() -> void:
	var a = _point(0.0, 0.0, 0.0)
	var b = _point(2.0, 0.0, 0.0)
	var link := Link.new()
	_check(link.project(TUNING) != OK, "unconfigured constraint rejected")
	_check(link.setup(a, a, 1.0, 0.0) != OK, "self-link rejected")
	_check(link.setup(null, b, 1.0, 0.0) != OK, "null body rejected")
	for invalid in [0.0, -1.0, INF, NAN]:
		_check(link.setup(a, b, invalid, 0.0) != OK, "invalid rest length rejected")
	for invalid in [-1.0, INF, NAN]:
		_check(link.setup(a, b, 1.0, invalid) != OK, "invalid compliance rejected")
	_check(link.setup(a, b, 1.0, 0.0) == OK, "two pinned mathematical points")
	var before := [a.snapshot(), b.snapshot(), link.snapshot()]
	_check(link.project(TUNING) == ERR_UNAVAILABLE, "immovable rigid pair cannot solve")
	_check(before == [a.snapshot(), b.snapshot(), link.snapshot()], "failure is non-mutating")
	_check(a.setup(0.0, 0.0, 1.0) == OK and b.setup(0.0, 0.0, 1.0) == OK, "coincident fixture")
	_check(link.project(TUNING) == ERR_INVALID_DATA, "no fabricated normal for coincident points")
	_check(b.setup(1e300, 1e300, 1.0) == OK, "finite large fixture")
	before = [a.snapshot(), b.snapshot(), link.snapshot()]
	_check(link.project(TUNING) == ERR_INVALID_DATA, "squared-length overflow rejected")
	_check(before == [a.snapshot(), b.snapshot(), link.snapshot()], "overflow failure is atomic")
	var state := link.snapshot()
	for invalid in [{}, {"rest_length": 1.0, "compliance": 0.0, "multiplier": INF}]:
		_check(
			link.restore(invalid) != OK and link.snapshot() == state, "bad link restore rejected"
		)


func _snapshot_projection() -> void:
	var a = _point(0.0, 0.0, 1.0)
	var b = _point(3.0, 4.0, 2.0)
	var link := Link.new()
	_check(link.setup(a, b, 2.0, 0.0) == OK, "non-axis-aligned fixture")
	var initial := [a.snapshot(), b.snapshot(), link.snapshot()]
	_check(link.project(TUNING) == OK, "first projection")
	var projected := [a.snapshot(), b.snapshot(), link.snapshot()]
	_check(a.restore(initial[0]) == OK, "restore first point")
	_check(b.restore(initial[1]) == OK, "restore second point")
	_check(link.restore(initial[2]) == OK, "restore constraint")
	_check(link.project(TUNING) == OK, "projection after restore")
	_check(
		projected == [a.snapshot(), b.snapshot(), link.snapshot()],
		"bit-exact mathematical restore replay"
	)
