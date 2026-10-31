extends RefCounted
## Idle600 retains the entire awake diagnostic trace. Long geometry arms retain
## full physical state/constraints in each outer row, plus this awake summary.
## The caller MUST scan the FULL trace before selecting transport verbosity.
## Failures retain the original full before/after/work Variant, never this subset.


static func select(trace: Dictionary, idle: bool) -> Dictionary:
	if idle:
		return trace
	var result := {
		"scope": "long geometry capture; full state/constraints in row; iteration debug omitted"
	}
	for key in ["status", "tick", "input_mask", "previous_grounded_feet", "momentum_budget"]:
		if trace.has(key):
			result[key] = trace[key]
	return result
