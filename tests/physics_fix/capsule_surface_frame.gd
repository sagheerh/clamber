# gdlint: disable=max-line-length
extends RefCounted
## Contact lives on capsule SKIN, not at its centreline material sample.
const OLD = preload("res://tests/physics_fix/rigid_contact_candidate.gd")


static func frame(body: CapsuleBody, u: float, nx: float, ny: float) -> Dictionary:
	var result: Dictionary = OLD.frame(body, u, nx, ny)
	if result.is_empty():
		return {}
	result.rx -= body.radius * result.nx
	result.ry -= body.radius * result.ny
	var axes: Dictionary = PlanarBasis.frame(body)
	var normal_arm: float = result.rx * result.ny - result.ry * result.nx
	var tangent_arm: float = result.rx * result.nx + result.ry * result.ny
	result.knn = 1.0 / body.mass + normal_arm * normal_arm * axes.inverse_inertia
	result.ktt = 1.0 / body.mass + tangent_arm * tangent_arm * axes.inverse_inertia
	result.knt = normal_arm * tangent_arm * axes.inverse_inertia
	result.determinant = result.knn * result.ktt - result.knt * result.knt
	var vx: float = (body.a.velocity_x + body.b.velocity_x) / 2.0 - axes.omega * result.ry
	var vy: float = (body.a.velocity_y + body.b.velocity_y) / 2.0 + axes.omega * result.rx
	result.normal_velocity = vx * result.nx + vy * result.ny
	result.tangent_velocity = -vx * result.ny + vy * result.nx
	for key in [
		"rx", "ry", "knn", "ktt", "knt", "determinant", "normal_velocity", "tangent_velocity"
	]:
		if not is_finite(result[key]):
			return {}
	return result if result.determinant > 0.0 else {}


static func rows(
	bodies: Array[CapsuleBody], part: int, u: float, nx: float, ny: float
) -> Dictionary:
	if part < 0 or part >= bodies.size():
		return {}
	var value: Dictionary = frame(bodies[part], u, nx, ny)
	if value.is_empty():
		return {}
	var normal: Array[float] = []
	var tangent: Array[float] = []
	normal.resize(3 * bodies.size())
	tangent.resize(3 * bodies.size())
	normal.fill(0.0)
	tangent.fill(0.0)
	normal[3 * part] = value.nx
	normal[3 * part + 1] = value.ny
	normal[3 * part + 2] = value.rx * value.ny - value.ry * value.nx
	tangent[3 * part] = -value.ny
	tangent[3 * part + 1] = value.nx
	tangent[3 * part + 2] = value.rx * value.nx + value.ry * value.ny
	return {"normal": normal, "tangent": tangent}
