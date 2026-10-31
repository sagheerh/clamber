#!/usr/bin/env python3
"""Saved V5 early-fall rotational ledger; ZERO new world ticks.
Explains pre-integration angular momentum, NOT a proof of pose impossibility.
"""
import gzip
import hashlib
import json
import re

from articulated_complete_trace_audit import FOLDER, RAW_SHA256, ROOT, SOURCE


def audit():
    raw = gzip.decompress((FOLDER / "idle-Slug.jsonl.gz").read_bytes())
    if hashlib.sha256(raw).hexdigest() != RAW_SHA256:
        raise ValueError("immutable trace hash mismatch")
    rows = [json.loads(line) for line in raw.splitlines()]
    spawn = json.loads((FOLDER / "idle-Slug-spawn.json").read_text())["rig"]["physical"]["bodies"]
    tuning = (ROOT / "core/tuning.tres").read_text()
    def scalar(key):
        return float(re.search(r"^" + key + r" = ([-+0-9.eE]+)$", tuning, re.M)[1])
    gravity = scalar("physics_gravity_wu_s2")
    hz = scalar("physics_tick_hz")
    drag = scalar("physics_linear_damping")
    px, py = spawn[2]["b"]["x"], spawn[2]["b"]["y"]
    mass = sum(b["mass"] for b in spawn)
    com_x = sum(b["mass"] * (b["a"]["x"] + b["b"]["x"]) / 2 for b in spawn) / mass
    result = []
    for row in rows[:15]:
        trace = row["awake_solver_trace"]
        parts = sorted(trace["feet"] + trace["other_bodies"], key=lambda p: p["part"])
        before = predicted = gravity_impulse = before_spin = after_motor_spin = 0.0
        for p in parts:
            d = p["position_delta_wu"]["integration"]
            dx, dy = p["start_bx"] - p["start_ax"], p["start_by"] - p["start_ay"]
            inertia = p["mass"] * (dx * dx + dy * dy) / 4
            omega = (dx * (p["start_bvy"] - p["start_avy"]) - dy * (p["start_bvx"] - p["start_avx"])) / (dx * dx + dy * dy)
            before_spin += inertia * omega
            after_motor_spin += inertia * trace["authored_angular_damping"][p["part"]]["omega_before"]
            for endpoint, offset in [("a", 0), ("b", 2)]:
                x, y = p[f"start_{endpoint}x"], p[f"start_{endpoint}y"]
                vx, vy = p[f"start_{endpoint}vx"], p[f"start_{endpoint}vy"]
                before += p["mass"] / 2 * ((x - px) * vy - (y - py) * vx)
                predicted += p["mass"] / 2 * ((x - px) * d[offset + 1] * hz - (y - py) * d[offset] * hz)
                gravity_impulse += p["mass"] / 2 * (x - px) * gravity / hz
        motor = after_motor_spin - before_spin
        angular = sum(e["external_angular_impulse"] for e in trace["authored_angular_damping"])
        linear = -drag * (before + motor + angular)
        result.append(dict(tick=row["tick"], angular_momentum_before=before,
                           angular_momentum_after_integration=predicted,
                           motor_internal_angular_impulse=motor,
                           gravity_angular_impulse=gravity_impulse,
                           authored_angular_drag_impulse=angular,
                           linear_drag_angular_impulse=linear,
                           residual=predicted-before-motor-angular-linear-gravity_impulse,
                           clamp_y=trace["momentum_budget"]["clamp_impulse_y_ns"],
                           clamp_x=trace["momentum_budget"]["clamp_impulse_x_ns"],
                           angular_limit_engaged=any(e["engaged"] for e in trace["angular_limit_events"]),
                           self_events=len(trace["self_contact_events"])))
    return dict(scope="OFFLINE early rotational ledger ONLY; ZERO new world ticks; NOT acceptance",
                source=SOURCE, raw_sha256=RAW_SHA256, mass=mass,
                initial_com_x=com_x, initial_toe_x=px,
                initial_gravity_torque_nm=(com_x-px)*mass*gravity,
                rows=result, max_absolute_residual=max(abs(r["residual"]) for r in result),
                limitations=["Fixed initial toe is a bookkeeping origin, NOT a persistent pin/controller.",
                             "Ledger covers start -> force integration, not unsaved chronological contact intermediate poses.",
                             "Motor orbital COM roundoff is not reconstructed individually; native measured net drive COM impulse is roundoff-scale.",
                             "Unbalanced gravity and nonzero angular momentum explain a real early fall; this is NOT proof no legal pose/contact/order repair can satisfy15deg.",
                             "No new damping/order/geometry/tuning experiment selected from this audit."])


if __name__ == "__main__":
    print(json.dumps(audit(), indent=2))
