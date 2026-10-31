#!/usr/bin/env python3
"""Hash-pinned comparison of CLOSED V5/V7/V8 captures. ZERO new engine ticks.
Component and 600-tick constraint evidence is NOT production/M1 acceptance.
"""
import gzip
import hashlib
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCES = {
    "V5": ("813e3ef6e6d34ba76911f2f26b1dcc340e4b0702", "5811c86f17ffcbdcf579557a1f6fc0220b4c7ec65c3ca2a58026f0843c54e024"),
    "V7": ("8368e14f716ffebfb64052c715d0dda3eecee9b3", "8c4af7f7ab4eefc6f6b8d4d32bd2385e80beee2d8c32d12561058f40f3e0523f"),
    "V8": ("d0af122528f4fadcb85584c75beb85119aec1c3c", "773aa49d8df56258d39821d7d67598fd9b1045dd476708141a271f50d685c97e"),
}


def audit():
    rows = {}
    results = {}
    for label, (source, expected) in SOURCES.items():
        folder = ROOT / "tests/fixtures/m1_articulated_execution" / source[:12]
        raw = gzip.decompress((folder / "idle-Slug.jsonl.gz").read_bytes())
        if hashlib.sha256(raw).hexdigest() != expected:
            raise ValueError("immutable source trace mismatch: " + label)
        if json.loads((folder / "transport-index.json").read_text())["source_commit"] != source:
            raise ValueError("wrong source")
        data = [json.loads(line) for line in raw.splitlines()]
        rows[label] = data
        summary = json.loads((folder / "summary.json").read_text())
        joints = [j for r in data for j in r["awake_solver_trace"]["angular_joints"]]
        gaps = []
        for r in data:
            bs = r["state"]["physical"]["bodies"]
            gaps.append(max(math.hypot(bs[c-1]["b"]["x"]-bs[c]["a"]["x"], bs[c-1]["b"]["y"]-bs[c]["a"]["y"]) for c in [1, 2]))
        results[label] = dict(source=source, raw_sha256=expected, count=len(data),
                             every_solver_status_ok=all(r["awake_solver_trace"]["status"] == 0 for r in data),
                             summary=summary,
                             max_positive_upper_excess_rad=max(0.0, max(j["q"]-j["upper"] for j in joints)),
                             max_positive_lower_excess_rad=max(0.0, max(j["lower"]-j["q"] for j in joints)),
                             # Offline diagnostic only, not a new runtime bound.
                             material_upper_excess_frames=sum(j["q"]-j["upper"] > 1e-12 for j in joints),
                             penetration_report_violation_frames=sum(r["penetration_peak_wu"] > .02 * (1 + 1e-9) for r in data),
                             max_still_ticks=max(r["state"]["sleep"]["still_ticks"] for r in data),
                             any_sleep=any(r["state"]["sleep"]["asleep"] for r in data),
                             max_hinge_gap_wu=max(gaps), final_hinge_gap_wu=gaps[-1])
    return dict(scope="OFFLINE immutable capture comparison; ZERO new ticks; NOT acceptance",
                results=results,
                first_state_difference_from_v5={label: next((i for i in range(600) if rows["V5"][i]["state"] != rows[label][i]["state"]), None) for label in ["V7", "V8"]},
                limitations=["V8 whole run never reaches the angular upper stop; active-limit behavior is exercised by the separate native36 component suite, not inferred from this run.",
                             "V8 removes material angular/penetration failures on this flat Slug600, NOT certification of three7200 or production AC202.",
                             "Old free proposal remains in inactive feasible cases; not every published world hinge is bitwise coincident. Exact coincidence belongs to finite-coordinate publication controls.",
                             "Posture still first fails14, sleep fails and later arms remain NOT RUN. No determinism, adoption, device, performance or FA3 credit."])


if __name__ == "__main__":
    print(json.dumps(audit(), indent=2))
