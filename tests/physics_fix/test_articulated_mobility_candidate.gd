# gdlint: disable=max-line-length
extends SceneTree
## Component checks only: no world ticks, historic captures or M1/AC verdict.
const NETWORK = preload("res://tests/physics_fix/articulated_mobility_candidate.gd")
const ROW = preload("res://tests/physics_fix/rigid_contact_candidate.gd")
const TUNING = preload("res://core/tuning.tres")
const EXPECTED_CHECKS := 42
var _checks := 0
var _failures := 0


func _initialize() -> void:
	_mobility_is_coupled()
	_contact_preserves_hinges()
	_projection_is_rigid()
	_position_is_transactional()
	_reject_bad_frames()
	if _checks != EXPECTED_CHECKS:
		_failures += 1
		push_error("FAIL articulated mobility: incomplete component suite")
	print("M1 articulated mobility units: %d checks, %d failures" % [_checks, _failures])
	print("Scope: component algebra ONLY; assembled AC-201/202 NOT MEASURED")
	quit(0 if _failures == 0 else 1)


func _fixture() -> Array[CapsuleBody]:
	return CreaturePresets.load_model("Slug", TUNING).create_bodies(0.0, 0.0)


func _parents() -> Array[int]:
	return [-1, 0, 1]


func _check(value: bool, label: String) -> void:
	_checks += 1
	if not value:
		_failures += 1
		push_error("FAIL articulated mobility: " + label)


func _near(a: float, b: float) -> bool:
	# Unit scalar roundoff only. Not solver, contact, sleep or gameplay tolerance.
	return absf(a - b) <= 1e-12


func _snapshots(bodies: Array[CapsuleBody]) -> Array:
	var result: Array = []
	for body in bodies:
		result.append(body.snapshot())
	return result


func _energy(bodies: Array[CapsuleBody]) -> float:
	var result := 0.0
	for body in bodies:
		result += ROW.kinetic_energy(body)
	return result


func _momentum(bodies: Array[CapsuleBody]) -> Array:
	var x := 0.0
	var y := 0.0
	var spin := 0.0
	for body in bodies:
		for point in [body.a, body.b]:
			var m := body.mass / 2.0
			x += m * point.velocity_x
			y += m * point.velocity_y
			spin += m * (point.x * point.velocity_y - point.y * point.velocity_x)
	return [x, y, spin]


func _hinges_closed(bodies: Array[CapsuleBody]) -> bool:
	for child in range(1, bodies.size()):
		var p := bodies[child - 1].b
		var c := bodies[child].a
		if not _near(p.velocity_x, c.velocity_x) or not _near(p.velocity_y, c.velocity_y):
			return false
	return true


func _rigid(bodies: Array[CapsuleBody]) -> bool:
	for body in bodies:
		var axes := PlanarBasis.frame(body)
		var axial: float = (
			axes.x * (body.b.velocity_x - body.a.velocity_x)
			+ axes.y * (body.b.velocity_y - body.a.velocity_y)
		)
		if not _near(axial, 0.0):
			return false
	return true


func _gap(bodies: Array[CapsuleBody]) -> float:
	var result := 0.0
	for i in range(1, bodies.size()):
		var dx := bodies[i].a.x - bodies[i - 1].b.x
		var dy := bodies[i].a.y - bodies[i - 1].b.y
		result = maxf(result, sqrt(dx * dx + dy * dy))
	return result


func _mobility_is_coupled() -> void:
	var bodies := _fixture()
	var network := NETWORK.new()
	_check(network.configure(bodies, _parents()) == OK, "tree factorizes")
	var before := _snapshots(bodies)
	var impulse: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0]
	var response := network.mobility(impulse)
	_check(not response.is_empty(), "finite constrained mobility")
	if response.is_empty():
		return
	_check(response.hinge_impulses.size() == 4, "both hinge reactions retained")
	_check(response.delta[1] != 0.0, "foot impulse reaches head, not isolated body")
	_check(_snapshots(bodies) == before, "mobility query has no mutation")
	var single: Array[CapsuleBody] = [bodies[1]]
	var root: Array[int] = [-1]
	var isolated := NETWORK.new()
	_check(isolated.configure(single, root) == OK, "single body has no fabricated hinge")
	var force: Array[float] = [1.0, 0.0, 0.0]
	var free := isolated.mobility(force)
	_check(
		not free.is_empty() and _near(free.delta[0], 1.0 / single[0].mass),
		"single body reduces to inverse mass"
	)


func _contact_preserves_hinges() -> void:
	var bodies := _fixture()
	for body in bodies:
		body.a.velocity_y = -1.0
		body.b.velocity_y = -1.0
	var network := NETWORK.new()
	_check(network.configure(bodies, _parents()) == OK, "contact frame configured")
	var momentum := _momentum(bodies)
	var energy := _energy(bodies)
	var before := _snapshots(bodies)
	var event := network.contact_velocity(bodies, 2, 1.0, 0.0, 1.0, 1.0, 0.0)
	_check(not event.is_empty(), "coupled normal contact publishes")
	if event.is_empty():
		return
	_check(
		event.normal_impulse_ns > 0.0 and _near(event.tangential_impulse_ns, 0.0),
		"unilateral frictionless response"
	)
	_check(_near(bodies[2].b.velocity_y, 0.0), "contact target attained")
	_check(_hinges_closed(bodies), "contact does NOT reopen either hinge")
	_check(_rigid(bodies), "contact does NOT create axial endpoint velocity")
	var after := _momentum(bodies)
	_check(_near(after[0], momentum[0]), "no invented lateral impulse")
	_check(
		_near(after[1] - momentum[1], event.normal_impulse_ns),
		"total external impulse equals reported contact"
	)
	_check(
		_near(after[2] - momentum[2], bodies[2].b.x * event.normal_impulse_ns),
		"external torque about origin conserved"
	)
	_check(_energy(bodies) <= energy, "dissipative rigid contact")
	_check(
		bodies[0].a.x == before[0].a.x and bodies[2].b.y == before[2].b.y,
		"velocity solve never edits geometry"
	)
	_check(
		bodies[2].applied_load_n == before[2].applied_load_n, "kernel never invents qualifying load"
	)


func _projection_is_rigid() -> void:
	var bodies := _fixture()
	bodies[0].a.velocity_x = -1.0
	bodies[0].b.velocity_x = 1.0
	bodies[1].a.velocity_x = 0.25
	bodies[1].b.velocity_x = 0.25
	var network := NETWORK.new()
	_check(network.configure(bodies, _parents()) == OK, "projection frame configured")
	var momentum := _momentum(bodies)
	var energy := _energy(bodies)
	var result := network.project_velocity(bodies)
	_check(not result.is_empty(), "rigid hinge projection publishes")
	_check(
		_hinges_closed(bodies) and _rigid(bodies), "both hinge and axial modes projected together"
	)
	var after := _momentum(bodies)
	_check(
		_near(after[0], momentum[0]) and _near(after[1], momentum[1]),
		"projection preserves total linear momentum"
	)
	_check(_near(after[2], momentum[2]), "coincident internal rows preserve angular momentum")
	_check(_energy(bodies) <= energy, "projection removes only incompatible kinetic energy")


func _position_is_transactional() -> void:
	var bodies := _fixture()
	for point in [bodies[2].a, bodies[2].b]:
		point.x += 0.001
	var before := _snapshots(bodies)
	var gap := _gap(bodies)
	var network := NETWORK.new()
	_check(network.configure(bodies, _parents()) == OK, "offset position frame configured")
	_check(
		not network.project_hinge_positions(bodies, _parents(), TUNING).is_empty(),
		"rigid position Newton step publishes"
	)
	_check(_gap(bodies) < gap, "Newton step reduces small hinge residual")
	var lengths_preserved := true
	var velocities_preserved := true
	for i in range(bodies.size()):
		var axes := PlanarBasis.frame(bodies[i])
		var dx: float = before[i].b.x - before[i].a.x
		var dy: float = before[i].b.y - before[i].a.y
		lengths_preserved = lengths_preserved and _near(axes.squared, dx * dx + dy * dy)
		velocities_preserved = (
			velocities_preserved
			and bodies[i].a.velocity_x == before[i].a.velocity_x
			and bodies[i].b.velocity_y == before[i].b.velocity_y
		)
	_check(lengths_preserved, "position correction preserves every rigid extent")
	_check(velocities_preserved, "position multiplier is not a velocity impulse")
	var fresh := _fixture()
	_check(network.configure(fresh, _parents()) == OK, "fresh position factor")
	var unchanged := _snapshots(fresh)
	_check(
		network.contact_position(fresh, 2, 1.0, 0.0, 1.0, 1000000.0, TUNING).is_empty(),
		"existing projection cap enforced"
	)
	_check(_snapshots(fresh) == unchanged, "projection cap failure atomic for ALL bodies")


func _reject_bad_frames() -> void:
	var bodies := _fixture()
	var network := NETWORK.new()
	var invalid: Array[int] = [-1, 2, 1]
	_check(network.configure(bodies, invalid) != OK, "cycle/forward parent rejected")
	var aliases: Array[CapsuleBody] = [bodies[0], bodies[0]]
	var pair: Array[int] = [-1, 0]
	_check(network.configure(aliases, pair) != OK, "aliased body rejected")
	_check(network.configure(bodies, _parents()) == OK, "valid frame after rejection")
	var before := _snapshots(bodies)
	_check(
		network.contact_velocity(bodies, 2, 1.0, NAN, 1.0, 1.0, 0.0).is_empty(),
		"nonfinite normal rejected"
	)
	_check(
		network.contact_velocity(bodies, 2, 1.0, 0.0, 1.0, -1.0, 0.0).is_empty(),
		"invalid material retention rejected"
	)
	_check(
		network.contact_velocity(bodies, 2, 2.0, 0.0, 1.0, 1.0, 0.0).is_empty(),
		"invalid sample rejected"
	)
	_check(_snapshots(bodies) == before, "all invalid contacts atomic")
	bodies[0].a.x += 0.001
	var moved := _snapshots(bodies)
	_check(
		network.contact_velocity(bodies, 2, 1.0, 0.0, 1.0, 1.0, 0.0).is_empty(),
		"stale geometry factor rejected"
	)
	_check(_snapshots(bodies) == moved, "stale factor rejection atomic")
