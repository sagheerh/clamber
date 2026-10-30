class_name CreatureModel
extends RefCounted
## Real engineering tree/derived parameters, not the builder codec or full Sim.
const TUNING = preload("res://core/tuning.tres")
var _definition: Dictionary = {}
var _parts: Array[CreaturePart] = []
var _pairs: Array = []
var _mass: float = TUNING.physics_zero


func configure(definition: Dictionary, tuning: Tuning) -> Error:
	if (
		tuning == null
		or not definition.get("parts") is Array
		or not definition.get("name") is String
	):
		return ERR_INVALID_DATA
	var source: Array = definition.parts
	if source.size() < tuning.physics_min_valid_parts or source.size() > tuning.physics_part_budget:
		return ERR_INVALID_DATA
	var parts: Array[CreaturePart] = []
	var mass: float = TUNING.physics_zero
	var motors: int = TUNING.physics_zero
	var feet: int = TUNING.physics_zero
	for index in range(source.size()):
		var part := CreaturePart.new()
		if (
			not source[index] is Dictionary
			or part.configure(source[index], tuning) != OK
			or not _valid_parent(part, index)
		):
			return ERR_INVALID_DATA
		mass += part.mass
		motors += TUNING.physics_one if part.kind == "motor" else TUNING.physics_zero
		feet += TUNING.physics_one if part.kind == "foot" else TUNING.physics_zero
		parts.append(part)
	if (
		not is_finite(mass)
		or mass <= TUNING.physics_zero
		or motors < tuning.physics_min_motors
		or feet < tuning.physics_min_feet
	):
		return ERR_INVALID_DATA
	var pairs := _validated_pairs(parts, tuning)
	if pairs.is_empty():
		return ERR_INVALID_DATA
	_definition = definition.duplicate(true)
	_parts = parts
	_pairs = pairs
	_mass = mass
	return OK


func definition() -> Dictionary:
	return _definition.duplicate(true)


func total_mass() -> float:
	return _mass


func collision_pairs() -> Array:
	# GDD layer11 feet collide with terrain/hazards, not creature parts.
	var result: Array = []
	for pair in _pairs:
		if (
			_parts[pair[TUNING.physics_zero]].kind != "foot"
			and _parts[pair[TUNING.physics_one]].kind != "foot"
		):
			result.append(pair.duplicate())
	return result


func d10_pairs() -> Array:
	# Universal geometry guard includes feet even where the response mask does not.
	return _pairs.duplicate(true)


func create_bodies(x: float, y: float) -> Array[CapsuleBody]:
	var bodies: Array[CapsuleBody] = []
	if not is_finite(x) or not is_finite(y):
		return bodies
	for part in _parts:
		var ax := x if part.parent < TUNING.physics_zero else bodies[part.parent].b.x
		var ay := y if part.parent < TUNING.physics_zero else bodies[part.parent].b.y
		var body := CapsuleBody.new()
		if body.configure(part, ax, ay) != OK:
			return []
		bodies.append(body)
	return bodies


func _validated_pairs(parts: Array[CreaturePart], tuning: Tuning) -> Array:
	var pairs: Array = []
	var clearance := (
		tuning.physics_joint_length_wu
		- tuning.physics_contact_slop_wu
		- tuning.physics_d10_bend_margin_wu
	)
	for a in range(parts.size()):
		var children: int = TUNING.physics_zero
		for part in parts:
			children += TUNING.physics_one if part.parent == a else TUNING.physics_zero
		if children > tuning.physics_max_children:
			return []
		for c in range(a + TUNING.physics_one, parts.size()):
			var distance := _tree_distance(parts, a, c)
			if (
				distance == tuning.physics_self_collision_min_levels
				and not parts[a].radius + parts[c].radius < clearance
			):
				return []
			if distance >= tuning.physics_self_collision_min_levels:
				pairs.append([a, c])
	return pairs


func _tree_distance(parts: Array[CreaturePart], a: int, c: int) -> int:
	var ancestors: Array[int] = []
	while a >= TUNING.physics_zero:
		ancestors.append(a)
		a = parts[a].parent
	var depth: int = TUNING.physics_zero
	while c not in ancestors:
		c = parts[c].parent
		depth += TUNING.physics_one
	return ancestors.find(c) + depth


func _valid_parent(part: CreaturePart, index: int) -> bool:
	return not (
		(
			index == TUNING.physics_zero
			and (part.kind != "head" or part.parent != -TUNING.physics_one)
		)
		or (
			index > TUNING.physics_zero
			and (part.kind == "head" or part.parent < TUNING.physics_zero or part.parent >= index)
		)
	)
