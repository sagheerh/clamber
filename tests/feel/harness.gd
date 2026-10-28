extends RefCounted
## Commit B scaffolding: topology-only fixtures and unexecuted runtime plans.
## No poses, contacts, motors, successes or sleep observations are fabricated.


static func preset_geometry() -> Array:
	return [
		{
			"name": "Slug",
			"kinds": ["head", "motor", "foot"],
			"parents": [-1, 0, 1],
			"channels": ["", "L", ""],
		},
		{
			"name": "Hopper",
			"kinds": ["head", "motor", "passive", "limb", "motor", "foot", "limb", "foot"],
			"parents": [-1, 0, 0, 1, 2, 3, 4, 6],
			"channels": ["", "L", "", "", "R", "", "", ""],
		},
		{
			"name": "TwinRoller",
			"kinds": ["head", "motor", "passive", "motor", "foot", "foot"],
			"parents": [-1, 0, 1, 2, 3, 0],
			"channels": ["", "L", "", "L", "", ""],
		},
	]


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
					"reason": "No static creature/contact/sleep scene implemented",
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
				"Needs real creature contacts, sleep and motors; no invented approximate-lurch tolerance",
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
				["mass_sum", "gravity", "normal_force_last_tick", "grounded", "grip", "slip_trace"],
				"reason":
				"No foot/contact response implemented; formula alone is not slip/grip evidence",
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
