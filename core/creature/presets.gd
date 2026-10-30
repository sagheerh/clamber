class_name CreaturePresets
extends RefCounted
## Production engineering definitions. No test fixture is used by core.
const FILES = {
	"Slug": "res://data/creatures/preset_slug.json",
	"Hopper": "res://data/creatures/preset_hopper.json",
	"TwinRoller": "res://data/creatures/preset_twinroller.json",
}


static func load_model(name: String, tuning: Tuning) -> CreatureModel:
	if name not in FILES:
		return null
	var file := FileAccess.open(FILES[name], FileAccess.READ)
	if file == null:
		return null
	var data: Variant = JSON.parse_string(file.get_as_text())
	if not data is Dictionary:
		return null
	# JSON integers arrive as doubles; validate integral values before conversion.
	for part in data.get("parts", []):
		if not part is Dictionary:
			return null
		for key in ["parent", "length_index"]:
			var value: Variant = part.get(key)
			if (
				not (value is int or value is float)
				or not is_finite(float(value))
				or value != floor(value)
			):
				return null
			part[key] = int(value)
	var model := CreatureModel.new()
	return model if model.configure(data, tuning) == OK else null
