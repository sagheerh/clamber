"""Read-only independent arithmetic on immutable native207 evidence, not new ticks.
Only three first-awake traces and three force-only positive clamp samples persist;
all66 live awake audits/207 controls are native assertions, not66 offline captures.
"""
import base64
import hashlib
import json
import math
from pathlib import Path

from godot_capture_variant import decode

ROOT = Path(__file__).resolve().parents[1]
SOURCE = "93b2f1fb0cd703de27d58f0df1b90d8c0caefaac"
FOLDER = ROOT / "tests/fixtures/m1_candidate_runtime" / SOURCE[:12]
SUMMARY_SHA256 = "c462b32df03e5724bb90fce10b506bd55386973157141a5462cb5eed2e2edb61"
NAMES = ["Slug", "Hopper", "TwinRoller"]


def audit():
    raw = (FOLDER / "summary.json").read_bytes()
    if hashlib.sha256(raw).hexdigest() != SUMMARY_SHA256:
        raise ValueError("immutable runtime summary changed")
    summary = json.loads(raw)
    source = json.loads((FOLDER / "source.json").read_text())
    if source["source_commit"] != SOURCE or source["ci_run"] != "41219732497":
        raise ValueError("wrong native runtime source")
    if "4.7.2.stable.official.ed1daf0bf" not in (FOLDER / "units.log").read_text():
        raise ValueError("wrong engine")
    if (summary["checks"] != 207 or summary["failures"] != 0
            or summary["completed_cases"] != NAMES or summary["awake_force_audits"] != 66
            or summary["failure_variant_base64"] is not None):
        raise ValueError("native matrix incomplete")
    forces = decode(base64.b64decode(summary["force_samples_variant_base64"]))
    clamps = decode(base64.b64decode(summary["clamp_samples_variant_base64"]))
    if [s["name"] for s in forces] != NAMES or [s["name"] for s in clamps] != NAMES:
        raise ValueError("missing saved samples")
    residuals = {"linear_tick_ns": 0.0, "contact_linear_ns": 0.0,
                 "contact_angular_ns_wu": 0.0, "angular_material_ns_wu": 0.0,
                 "positive_clamp_ns": 0.0, "positive_clamp_velocity_wu_s": 0.0}
    grip_eligible = 0
    for sample in forces:
        t = sample["trace"]
        if t["status"] != 0 or t["input_mask"] != 1 or t["constitutive_velocity_pass"] != 1:
            raise ValueError("wrong actual sampled phase/input")
        bodies = {p["part"]: p for p in t["feet"] + t["other_bodies"]}
        for axis in "xy":
            actual = sum(p["mass"] * (p["av"+axis]+p["bv"+axis]
                                     -p["start_av"+axis]-p["start_bv"+axis])/2
                         for p in bodies.values())
            stages = sum(t["momentum_budget"][s+"_impulse_"+axis+"_ns"]
                         for s in ["drive_internal", "damping", "gravity", "internal",
                                   "contact_velocity", "clamp"])
            residuals["linear_tick_ns"] = max(residuals["linear_tick_ns"], abs(actual-stages))
        for batch in t["contact_batches"]:
            rows = [r for r in t["contact_samples"] if r["velocity_pass"] == batch["velocity_pass"]]
            events = {p: next(r for r in rows if r["part"] == p) for p in bodies}
            shared = next((r for r in rows if r.get("manifold_shared_event")), {})
            angular = {e["part"]: e for e in shared.get("angular_drag_events", [])}
            terrain = {p: [0.0, 0.0, 0.0] for p in bodies}
            for r in rows:
                p = r["part"]
                jx = r["normal_impulse_ns"]*r["nx"]-r["tangential_impulse_ns"]*r["ny"]
                jy = r["normal_impulse_ns"]*r["ny"]+r["tangential_impulse_ns"]*r["nx"]
                dx, dy = (r["pose_b"][i]-r["pose_a"][i] for i in range(2))
                rx = (r["u"]-.5)*dx-bodies[p]["radius_wu"]*r["nx"]
                ry = (r["u"]-.5)*dy-bodies[p]["radius_wu"]*r["ny"]
                terrain[p][0] += jx
                terrain[p][1] += jy
                terrain[p][2] += rx*jy-ry*jx
                grip_eligible += bool(r["may_grip"])
            for i, axis in enumerate("xy"):
                actual = sum(bodies[p]["mass"]*(r["av"+axis+"_after"]+r["bv"+axis+"_after"]
                                               -r["av"+axis+"_before"]-r["bv"+axis+"_before"])/2
                             for p, r in events.items())
                residuals["contact_linear_ns"] = max(residuals["contact_linear_ns"],
                                                      abs(actual-sum(v[i] for v in terrain.values())))
            for p, r in events.items():
                dx, dy = (r["pose_b"][i]-r["pose_a"][i] for i in range(2))
                actual = bodies[p]["mass"]*(dx*(r["bvy_after"]-r["avy_after"]-r["bvy_before"]+r["avy_before"])
                                            -dy*(r["bvx_after"]-r["avx_after"]-r["bvx_before"]+r["avx_before"]))/4
                e = angular.get(p, {})
                reported = terrain[p][2] + sum(e.get(k, 0) for k in ["angular_impulse",
                    "hinge_angular_impulse", "limit_angular_impulse", "connector_angular_impulse"])
                residuals["contact_angular_ns_wu"] = max(residuals["contact_angular_ns_wu"], abs(actual-reported))
                c = .8/(1-.8) if batch["velocity_pass"] == 1 else 0
                residuals["angular_material_ns_wu"] = max(residuals["angular_material_ns_wu"],
                                                          abs(e.get("angular_impulse", 0)+c*actual))
    for sample in clamps:
        parts, b = sample["bodies"], sample["budget"]
        vx, vy = 100*(1-.02), -28/60
        scale = 42/math.sqrt(vx*vx+vy*vy)
        mass = sum(p["mass"] for p in parts)
        for p in parts:
            for endpoint in ["a", "b"]:
                residuals["positive_clamp_velocity_wu_s"] = max(
                    residuals["positive_clamp_velocity_wu_s"],
                    abs(p[endpoint]["velocity_x"]-vx*scale), abs(p[endpoint]["velocity_y"]-vy*scale))
        residuals["positive_clamp_ns"] = max(residuals["positive_clamp_ns"],
            abs(b["clamp_impulse_x_ns"]-mass*(vx*scale-vx)),
            abs(b["clamp_impulse_y_ns"]-mass*(vy*scale-vy)))
        if b["clamp_impulse_x_ns"] >= 0:
            raise ValueError("positive clamp control vacuous")
    return dict(scope="OFFLINE immutable native207, ZERO new ticks; not production/FA3/determinism",
                source_commit=SOURCE, native_checks=207, native_awake_audits=66,
                saved_first_awake_samples=3, saved_positive_clamp_samples=3,
                sampled_grip_eligible_observations=grip_eligible,
                max_absolute_residuals=residuals,
                limitations=["Three saved first-awake traces are not all66 live audits.",
                             "Controlled100WU/s clamp initial condition is not a gameplay/integration run.",
                             "Native factory/input/wake controls do not adopt production factories.",
                             "No FA3, long-run verdict, cross-architecture or device claim."])


if __name__ == "__main__":
    print(json.dumps(audit(), indent=2))
