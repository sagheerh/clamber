#!/usr/bin/env python3
"""Offline audit of the immutable V5 600-tick FAILURE, not a new capture.
No engine invocation, Sim calls, parameter selection, or acceptance substitution.
"""
import gzip
import hashlib
import json
import math
from pathlib import Path

from articulated_posture_audit import attitude, vector

ROOT = Path(__file__).resolve().parents[1]
SOURCE = "813e3ef6e6d34ba76911f2f26b1dcc340e4b0702"
FOLDER = ROOT / "tests/fixtures/m1_articulated_execution" / SOURCE[:12]
RAW_SHA256 = "5811c86f17ffcbdcf579557a1f6fc0220b4c7ec65c3ca2a58026f0843c54e024"
GZIP_SHA256 = "98eb92414021d2d5e32b87d634289d32461b338f74e520fe57975a68bd528b3f"


def audit():
    packed = (FOLDER / "idle-Slug.jsonl.gz").read_bytes()
    raw = gzip.decompress(packed)
    if (hashlib.sha256(packed).hexdigest() != GZIP_SHA256
            or hashlib.sha256(raw).hexdigest() != RAW_SHA256):
        raise ValueError("immutable600 trace hash mismatch")
    index = json.loads((FOLDER / "transport-index.json").read_text())
    if index["source_commit"] != SOURCE:
        raise ValueError("wrong source")
    rows = [json.loads(line) for line in raw.splitlines()]
    spawn = json.loads((FOLDER / "idle-Slug-spawn.json").read_text())["rig"]["physical"]["bodies"]
    initial = vector([dict(kind=b["kind"], a=[b["a"]["x"], b["a"]["y"]],
                           b=[b["b"]["x"], b["b"]["y"]]) for b in spawn])
    derived = []
    for row in rows:
        trace = row["awake_solver_trace"]
        parts = sorted(trace["feet"] + trace["other_bodies"], key=lambda p: p["part"])
        predicted = []
        for p in parts:
            d = p["position_delta_wu"]["integration"]
            predicted.append(dict(kind="foot" if p["part"] == 2 else p["kind"],
                                  a=[p["start_ax"] + d[0], p["start_ay"] + d[1]],
                                  b=[p["start_bx"] + d[2], p["start_by"] + d[3]]))
        joint = trace["angular_joints"][0]
        last = trace["angular_position_events"][-1]
        pa, pb, pc, pd = last["parent_after"]
        ca, cb, cc, cd = last["child_after"]
        # Independent atan2 reconstruction of recorded last angular-pass poses;
        # not an invented chronological contact/hinge intermediate state.
        q = math.atan2(cd-cb, cc-ca) - math.atan2(pd-pb, pc-pa) - joint["rest_angle"]
        q = (q + math.pi) % (2 * math.pi) - math.pi
        derived.append(dict(tick=row["tick"], status=trace["status"],
                            integration_deg=attitude(initial, vector(predicted)),
                            final_deg=row["attitude_deg"], final_q_native_rad=joint["q"],
                            last_angular_q_reconstructed_rad=q,
                            lower_rad=joint["lower"], upper_rad=joint["upper"],
                            still_ticks=row["state"]["sleep"]["still_ticks"],
                            asleep=row["state"]["sleep"]["asleep"],
                            foot_applied_n=parts[2]["applied_load_n"],
                            gripping=parts[2]["gripping"],
                            foot_b_final_vx=row["state"]["physical"]["bodies"][2]["b"]["velocity_x"],
                            foot_b_step_dx=parts[2]["b"][0]-parts[2]["start_bx"],
                            foot_b_phase_dx={k: v[2] for k, v in parts[2]["position_delta_wu"].items()}))
    violations = [r for r in derived if r["final_q_native_rad"] > r["upper_rad"]
                  or r["final_q_native_rad"] < r["lower_rad"]]
    return dict(scope="OFFLINE saved600 FAILURE; ZERO new world ticks; NOT acceptance",
                source=SOURCE, raw_sha256=RAW_SHA256, gzip_sha256=GZIP_SHA256,
                summary=json.loads((FOLDER / "summary.json").read_text()),
                tick_count=len(rows), all_solver_status_ok=all(r["status"] == 0 for r in derived),
                first_integration_violation=next(r["tick"] for r in derived if r["integration_deg"] > 15),
                first_final_violation=next(r["tick"] for r in derived if r["final_deg"] > 15),
                first_native_angular_limit_violation=violations[0]["tick"],
                native_angular_limit_violation_ticks=len(violations),
                max_native_upper_excess_rad=max(r["final_q_native_rad"]-r["upper_rad"] for r in derived),
                max_still_ticks=max(r["still_ticks"] for r in derived),
                any_sleep=any(r["asleep"] for r in derived),
                samples=[r for r in derived if r["tick"] in [0, 8, 14, 30, 46, 60, 100, 239, 599]],
                limitations=["Posture first fails BEFORE angular-limit reopening; the late defect does not explain the first crossing.",
                             "Last angular pass versus final pose isolates later aggregate operations, not an exact individual contact substep.",
                             "Angular drag units/order remain an unadopted interpretation; no damping-order candidate or new world run selected."])


if __name__ == "__main__":
    print(json.dumps(audit(), indent=2))
