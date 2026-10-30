extends RefCounted
## UNADOPTED contact-row candidate. Not called by production Sim or R29.
## Two equal endpoint masses imply I=m*extent^2/4, as in AngularJoint.
## This tests a rigidity-preserving contact formulation, NOT a whole-creature fix.
const TUNING = preload("res://core/tuning.tres")


static func frame(body: CapsuleBody, u: float, nx: float, ny: float) -> Dictionary:
	if body == null or not body.is_valid() or not is_finite(u) or u < 0.0 or u > 1.0:
		return {}
	var endpoint_inverse := 2.0 / body.mass
	if (
		not is_finite(endpoint_inverse)
		or body.a.inverse_mass != endpoint_inverse
		or body.b.inverse_mass != endpoint_inverse
	):
		return {}
	var axes := PlanarBasis.frame(body)
	var normal_squared := nx * nx + ny * ny
	if axes.is_empty() or not is_finite(normal_squared) or normal_squared <= 0.0:
		return {}
	var normal_length := sqrt(normal_squared)
	nx /= normal_length
	ny /= normal_length
	var rx: float = (u - 0.5) * axes.x
	var ry: float = (u - 0.5) * axes.y
	var normal_arm := rx * ny - ry * nx
	var tangent_arm := rx * nx + ry * ny
	var inverse_mass := 1.0 / body.mass
	var knn: float = inverse_mass + normal_arm * normal_arm * axes.inverse_inertia
	var ktt: float = inverse_mass + tangent_arm * tangent_arm * axes.inverse_inertia
	var knt: float = normal_arm * tangent_arm * axes.inverse_inertia
	var determinant: float = knn * ktt - knt * knt
	var vx: float = (body.a.velocity_x + body.b.velocity_x) / 2.0 - axes.omega * ry
	var vy: float = (body.a.velocity_y + body.b.velocity_y) / 2.0 + axes.omega * rx
	var vn := vx * nx + vy * ny
	var vt := -vx * ny + vy * nx
	for value in [rx, ry, knn, ktt, knt, determinant, vx, vy, vn, vt]:
		if not is_finite(value):
			return {}
	if determinant <= 0.0:
		return {}
	return {
		"nx": nx,
		"ny": ny,
		"rx": rx,
		"ry": ry,
		"knn": knn,
		"ktt": ktt,
		"knt": knt,
		"determinant": determinant,
		"normal_velocity": vn,
		"tangent_velocity": vt,
		"inverse_inertia": axes.inverse_inertia
	}


static func velocity_response(
	body: CapsuleBody, u: float, nx: float, ny: float, retention: float, restitution: float
) -> Dictionary:
	# Policy inputs must come from the unchanged material/grip/static-slip policy.
	# This kernel does not choose grip, frozen N, support, friction or sleep.
	if (
		not is_finite(retention)
		or retention < 0.0
		or retention > 1.0
		or not is_finite(restitution)
		or restitution < 0.0
		or restitution > 1.0
	):
		return {}
	var value := frame(body, u, nx, ny)
	if value.is_empty():
		return {}
	var normal_target: float = -restitution * minf(0.0, value.normal_velocity)
	# Friction acts on the velocity AFTER the normal-only impulse. For a rigid
	# body normal response can change tangential speed through rotation. Holding
	# the original tangent fixed would create a spurious impulse even at mu=0.
	var normal_only: float = maxf(0.0, (normal_target - value.normal_velocity) / value.knn)
	var tangent_after_normal: float = value.tangent_velocity + value.knt * normal_only
	var tangent_target: float = tangent_after_normal * retention
	var dn: float = normal_target - value.normal_velocity
	var dt: float = tangent_target - value.tangent_velocity
	# Solve the coupled 2x2 contact-space mass matrix. Independent scalar normal
	# then tangent rows can reintroduce normal approach at an oblique lever arm.
	var jn: float = (dn * value.ktt - dt * value.knt) / value.determinant
	var jt: float = (dt * value.knn - dn * value.knt) / value.determinant
	if jn < 0.0:
		# Unilateral normal: never pull a capsule into terrain to hit the target.
		jn = 0.0
		jt = dt / value.ktt
	var ix: float = value.nx * jn - value.ny * jt
	var iy: float = value.ny * jn + value.nx * jt
	var spin: float = (value.rx * iy - value.ry * ix) * value.inverse_inertia
	for number in [jn, jt, ix, iy, spin]:
		if not is_finite(number):
			return {}
	var energy_before := kinetic_energy(body)
	if not is_finite(energy_before):
		return {}
	var shadow := CapsuleBody.new()
	if shadow.restore(body.snapshot()) != OK:
		return {}
	# Whole rigid-body translation + spin; no longitudinal endpoint impulse.
	for point in [shadow.a, shadow.b]:
		point.velocity_x += ix / body.mass
		point.velocity_y += iy / body.mass
	PlanarBasis.spin(shadow, spin)
	var energy_after := kinetic_energy(shadow)
	# Strict fail-closed guard for the unadopted kernel, not a new acceptance
	# tolerance or a quiet velocity clamp. Coupled restitution still needs tests.
	if not is_finite(energy_after) or energy_after > energy_before:
		return {}
	if not shadow.is_valid() or body.restore(shadow.snapshot()) != OK:
		return {}
	return {
		"normal_impulse_ns": jn,
		"tangential_impulse_ns": jt,
		"x": ix,
		"y": iy,
		"spin_change": spin,
		"energy_before": energy_before,
		"energy_after": energy_after,
		"normal_target": normal_target,
		"tangent_target": tangent_target
	}


static func kinetic_energy(body: CapsuleBody) -> float:
	return (
		body.mass
		* (
			body.a.velocity_x * body.a.velocity_x
			+ body.a.velocity_y * body.a.velocity_y
			+ body.b.velocity_x * body.b.velocity_x
			+ body.b.velocity_y * body.b.velocity_y
		)
		/ 4.0
	)


static func translate_outward(
	body: CapsuleBody, nx: float, ny: float, depth: float, tuning: Tuning
) -> Error:
	# ISOLATED positional hypothesis: a common translation preserves extent.
	# A curved SDF / multiple contacts / hinge coupling still needs validation.
	# This is not a license to append distance repair after production contacts.
	if (
		body == null
		or not body.is_valid()
		or tuning == null
		or not is_finite(depth)
		or depth < 0.0
		or not is_finite(tuning.physics_max_projection_wu_tick)
		or tuning.physics_max_projection_wu_tick <= 0.0
	):
		return ERR_INVALID_DATA
	var squared := nx * nx + ny * ny
	if not is_finite(squared) or squared <= 0.0:
		return ERR_INVALID_DATA
	if depth > tuning.physics_max_projection_wu_tick:
		return ERR_PARAMETER_RANGE_ERROR
	var shadow := CapsuleBody.new()
	if shadow.restore(body.snapshot()) != OK:
		return ERR_INVALID_DATA
	var length := sqrt(squared)
	var dx := depth * nx / length
	var dy := depth * ny / length
	for point in [shadow.a, shadow.b]:
		point.x += dx
		point.y += dy
	if not shadow.is_valid():
		return ERR_INVALID_DATA
	return body.restore(shadow.snapshot())
