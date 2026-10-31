# gdlint: disable=max-line-length
extends RefCounted
const COMMON = preload("res://tests/physics_fix/manifold_terrain.gd")


static func resolve_tick(
	bodies: Array[CapsuleBody],
	parents: Array[int],
	terrain: SdfGrid,
	creature_mass: float,
	lowest: Array[bool],
	friction: Array[float],
	restitution: Array[float],
	tuning: Tuning,
	observer: Callable = Callable(),
	certified_velocity: PackedByteArray = PackedByteArray(),
	limits: Array = [],
	history: Array = []
) -> Dictionary:
	return COMMON.resolve_tick(
		bodies,
		parents,
		terrain,
		creature_mass,
		lowest,
		friction,
		restitution,
		tuning,
		observer,
		certified_velocity,
		limits,
		history,
		false
	)
