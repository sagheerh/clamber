extends RefCounted
## Production preset definitions; runtime feel plans are still unexecuted.
## Runtime observations are still unknown; no gait/sleep/success evidence implied.
const TUNING = preload("res://core/tuning.tres")


static func preset_geometry() -> Array:
	var presets: Array = []
	var tuning: Tuning = TUNING
	for name in CreaturePresets.FILES:
		var model := CreaturePresets.load_model(name, tuning)
		if model == null:
			return []
		var definition := model.definition()
		var kinds: Array = []
		var parents: Array = []
		var channels: Array = []
		for part in definition.parts:
			kinds.append(part.kind)
			parents.append(part.parent)
			channels.append(part.channel)
		presets.append({"name": name, "kinds": kinds, "parents": parents, "channels": channels})
	return presets


static func pending_runtime(tuning: Tuning) -> Array:
	var cases: Array = []
	for preset in preset_geometry():
		(
			cases
			. append(
				{
					"id": "FA-3",
					"preset": preset.name,
					"status": "NOT RUN",
					"observations": null,
					"required_ticks": tuning.feel_static_scene_ticks,
					"required_fields":
					["ticks", "sleep_breaking_contacts", "contact_trace", "seed", "tuning_hash"],
					"reason":
					(
						"Components exist; full all-preset static scene "
						+ "after motors/limits/self-contact is unexecuted"
					),
				}
			)
		)
	(
		cases
		. append(
			{
				"id": "FA-4",
				"preset": "Slug",
				"status": "NOT RUN",
				"observations": null,
				"settle_budget_seconds": tuning.physics_settle_budget_s,
				"required_fields":
				[
					"settle_tick",
					"sleep_tick",
					"velocities",
					"L_hold_ticks",
					"lurch_wu",
					"body_length_wu"
				],
				"reason":
				"Sleep component exists; full motor lurch scene unexecuted, no invented lurch tolerance",
			}
		)
	)
	(
		cases
		. append(
			{
				"id": "FA-5",
				"status": "NOT RUN",
				"observations": null,
				"ratio": tuning.physics_grip_normal_force_ratio,
				"floor": tuning.physics_grip_normal_force_floor,
				"cases":
				["below_ratio", "at_ratio", "two_foot_stance", "airborne", "floor_dominates"],
				"required_fields":
				[
					"mass_sum",
					"gravity",
					"previous_grounded_feet",
					"applied_load_n",
					"measured_reaction_n",
					"positional_cleanup_n",
					"support_sum",
					"support_error",
					"grounded",
					"grip",
					"sleep",
					"slip_trace",
					"gate_toggles"
				],
				"reason":
				"Components exist; real coupled FA-5 band (two-foot Hopper) is unexecuted",
			}
		)
	)
	(
		cases
		. append(
			{
				"id": "FA-6",
				"status": "NOT RUN",
				"observations": null,
				"required_runs": tuning.feel_tutorial_runs,
				"success_min": tuning.feel_tutorial_successes_min,
				"success_max": tuning.feel_tutorial_successes_max,
				"success_count": null,
				"required_fields":
				[
					"initial_state",
					"seed",
					"scripted_input_log",
					"tutorial_chunk",
					"per_run_outcomes"
				],
				"reason":
				"Needs contacts, motors and tutorial scenario; never randomize identical runs to force target",
			}
		)
	)
	return cases


static func readable_pixels(pixels: float, target: float) -> bool:
	# Owner F21: float-noise only, NOT legibility slack or physics tuning.
	return is_finite(pixels) and is_finite(target) and pixels + 1e-9 >= target
