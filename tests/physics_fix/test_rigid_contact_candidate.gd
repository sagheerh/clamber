extends SceneTree
## Primitive-only candidate tests. No assembled-creature/AC/D0/R27/R29 run.
const ROW = preload("res://tests/physics_fix/rigid_contact_candidate.gd")
const TUNING = preload("res://core/tuning.tres")
var _checks := 0
var _failures := 0


func _initialize() -> void:
	_axial_contact()
	_oblique_contact()
	_oblique_without_friction()
	_separating_contact()
	_common_translation()
	_atomic_rejection()
	print("Unadopted rigid contact units: %d checks, %d failures" % [_checks, _failures])
	print("Scope: primitive rows ONLY; AC-201/AC-202 NOT MEASURED")
	quit(0 if _failures == 0 else 1)


func _body() -> CapsuleBody:
	var model := CreaturePresets.load_model("Slug", TUNING)
	return model.create_bodies(0.0, 0.0)[1]


func _check(value: bool, label: String) -> void:
	_checks += 1
	if not value:
		_failures += 1
		push_error("FAIL candidate: " + label)


func _near(a: float, b: float) -> bool:
	# Scalar unit-test roundoff allowance, NOT a physics/contact/sleep tolerance.
	return absf(a - b) <= 1e-12


func _axial_contact() -> void:
	var body := _body()
	body.a.velocity_y = -1.0
	body.b.velocity_y = -1.0
	var value := ROW.frame(body, 1.0, 0.0, 1.0)
	_check(_near(value.knn, 1.0 / body.mass), "axial rigid effective inverse mass")
	var event := ROW.velocity_response(body, 1.0, 0.0, 1.0, 1.0, 0.0)
	_check(not event.is_empty(), "normal row succeeds")
	_check(_near(body.a.velocity_y, 0.0), "normal stops first endpoint")
	_check(_near(body.b.velocity_y, 0.0), "normal stops second endpoint")
	_check(_near(event.normal_impulse_ns, body.mass), "actual total momentum impulse")
	_check(_near(PlanarBasis.frame(body).omega, 0.0), "no invented spin under axial hit")


func _oblique_contact() -> void:
	var body := _body()
	body.a.velocity_x = 0.7
	body.b.velocity_x = 0.7
	body.a.velocity_y = -1.0
	body.b.velocity_y = -1.0
	var nx := 0.6
	var ny := 0.8
	var old := ROW.frame(body, 0.9, nx, ny)
	var event := ROW.velocity_response(body, 0.9, nx, ny, 0.1, 0.0)
	_check(not event.is_empty(), "coupled oblique row succeeds")
	var after := ROW.frame(body, 0.9, nx, ny)
	_check(_near(after.normal_velocity, event.normal_target), "friction does not undo normal row")
	var normal_only: float = -old.normal_velocity / old.knn
	var post_normal_tangent: float = old.tangent_velocity + old.knt * normal_only
	_check(
		_near(after.tangent_velocity, post_normal_tangent * 0.1), "post-normal tangent retention"
	)
	_check(event.normal_impulse_ns >= 0.0, "normal impulse nonnegative")
	_check(
		_near((body.a.velocity_x + body.b.velocity_x) / 2.0, 0.7 + event.x / body.mass),
		"COM impulse x"
	)
	_check(
		_near((body.a.velocity_y + body.b.velocity_y) / 2.0, -1.0 + event.y / body.mass),
		"COM impulse y"
	)
	var dx := body.b.x - body.a.x
	var dy := body.b.y - body.a.y
	_check(
		_near(
			(
				(body.b.velocity_x - body.a.velocity_x) * dx
				+ (body.b.velocity_y - body.a.velocity_y) * dy
			),
			0.0
		),
		"no new axial stretch velocity"
	)


func _oblique_without_friction() -> void:
	var body := _body()
	body.a.velocity_y = -1.0
	body.b.velocity_y = -1.0
	var event := ROW.velocity_response(body, 1.0, 0.6, 0.8, 1.0, 0.0)
	_check(not event.is_empty(), "frictionless oblique row succeeds")
	_check(_near(event.tangential_impulse_ns, 0.0), "zero friction means zero tangent impulse")
	_check(event.energy_after <= event.energy_before, "contact cannot add kinetic energy")


func _separating_contact() -> void:
	var body := _body()
	body.a.velocity_y = 1.0
	body.b.velocity_y = 1.0
	var before := body.snapshot()
	var event := ROW.velocity_response(body, 1.0, 0.0, 1.0, 1.0, 0.0)
	_check(event.normal_impulse_ns == 0.0, "separating normal never pulls")
	_check(body.snapshot() == before, "no impulse for separating frictionless row")


func _common_translation() -> void:
	var body := _body()
	var before := body.snapshot()
	var extent := body.b.y - body.a.y
	_check(ROW.translate_outward(body, 0.0, 1.0, 0.125, TUNING) == OK, "outward translation")
	_check(_near(body.b.y - body.a.y, extent), "extent unchanged by contact cleanup")
	_check(
		body.a.x == before.a.x and body.b.x == before.b.x,
		"flat normal has no lateral position edit"
	)
	_check(
		body.a.velocity_y == before.a.velocity_y and body.b.velocity_y == before.b.velocity_y,
		"cleanup not velocity or support impulse"
	)
	_check(body.applied_load_n == before.applied_load_n, "no invented qualifying load")


func _atomic_rejection() -> void:
	var body := _body()
	var before := body.snapshot()
	_check(
		ROW.velocity_response(body, 1.0, NAN, 1.0, 1.0, 0.0).is_empty(), "nonfinite normal rejected"
	)
	_check(body.snapshot() == before, "normal failure atomic")
	_check(
		ROW.velocity_response(body, 2.0, 0.0, 1.0, 1.0, 0.0).is_empty(),
		"sample outside segment rejected"
	)
	_check(
		ROW.velocity_response(body, 1.0, 0.0, 1.0, -0.1, 0.0).is_empty(), "bad retention rejected"
	)
	_check(
		(
			ROW.translate_outward(
				body, 0.0, 1.0, TUNING.physics_max_projection_wu_tick * 2.0, TUNING
			)
			!= OK
		),
		"existing projection cap retained"
	)
	_check(body.snapshot() == before, "all rejected operations atomic")
	body.a.inverse_mass *= 2.0
	var malformed := body.snapshot()
	_check(ROW.frame(body, 1.0, 0.0, 1.0).is_empty(), "unequal endpoint mass rejected")
	_check(
		(
			ROW.velocity_response(body, 1.0, 0.0, 1.0, 1.0, 0.0).is_empty()
			and body.snapshot() == malformed
		),
		"malformed mass response atomic"
	)
