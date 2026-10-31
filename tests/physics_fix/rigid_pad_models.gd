# gdlint: disable=max-line-length
extends RefCounted
## Owner-authorized new stance prototype, NOT rewritten historical presets.
## Root DOWN centres the head mass on its existing motor socket (no fake torque).
## Horizontal real capsule feet provide a finite actual contact baseline.
const AXES: Dictionary = {
	"Slug": {0: "DOWN", 2: "LEFT"},
	"Hopper": {0: "DOWN", 5: "RIGHT", 7: "LEFT"},
	"TwinRoller": {0: "DOWN", 4: "LEFT", 5: "LEFT"}
}


static func load_model(name: String, tuning: Tuning) -> CreatureModel:
	var original := CreaturePresets.load_model(name, tuning)
	if original == null or not AXES.has(name):
		return null
	var definition := original.definition()
	for index in AXES[name]:
		definition.parts[index].axis = AXES[name][index]
	var result := CreatureModel.new()
	return result if result.configure(definition, tuning) == OK else null
