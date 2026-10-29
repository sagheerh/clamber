# M1 — R21 review: my saturation prediction is falsified; the joint is 8.27° past its own stop every tick

**Target:** PR #3 head `74c629e` (draft, OPEN), commits `8e0b907` + `74c629e` over `979563f`.
**CI:** `40869475224` — RED for the sustained-support gate and the gain-0 no-collapse gate; **five other jobs succeed**, including public replay/clock. `40869475223` M0 **516/0** + Android pass.
**Reviewer branch:** `arena/5b72e4ab-clamber`. Local: **167** Python controls pass, matrix guard exit 0. `core/tuning.tres` and `data/creatures/` diff vs `979563f`: **empty**.

---

## 1. Verdict

**The arm is real, my prediction was wrong, and the mechanism is now visible in numbers you already published.**

| Item | Status |
|---|---|
| gain-0 arm | **ACCEPTED as a real intervention** — requested and applied impulse exactly 0 for 6000 ticks, F56 complete on all arms |
| My R20 prediction ("drift collapses to 0.084 with no drive") | **FALSIFIED** — drift rose to 5.3874 px/s, thrust 1.1205e-3 (×1.35) |
| R20 causal claim ("the saturated impulse is the propulsor") | **withdrawn by me**, not merely by you |
| F61 (authored motor strength inoperative) | **stands, record-only** — the 472× overshoot is unaffected by this result |
| **F64 [MAJOR]** the joint sits **8.27° past its +40° stop every tick** | new, derived from your own spring-torque and bound numbers |
| **F65 [MAJOR]** the Slug's authored standing pose is **unreachable** | new, owner-relevant, independent of drift |
| F66 | bound 0.04119 measured, my 0.04444 nominal — yours wins |
| Rows | **8/18**, movement 0 |

---

## 2. What gain-0 proved, and what it killed

Your table is decisive:

| arm | requested | applied | saturated | drift | thrust |
|---|---:|---:|---:|---:|---:|
| reference | −21.000 | −0.0411935 | 300/300 | 3.9345 | 8.297e-4 |
| stiffness 0 | −1.8121 | −0.0411935 | 300/300 | 3.9345 | 8.297e-4 |
| **gain 0** | **0** | **0** | **0/300** | **5.3874** | **1.1205e-3** |

Zero drive, and the creature walks **faster**. So the drive is not the propulsor; it is a **brake**. My ORDER-1 prediction said the opposite. That is my fifth wrong call in this milestone, and the second one your measurement corrected.

Consequence I want on the record: **the R19 stiffness sweep was void, and my R20 causal inference was also void.** Two layers of my own reasoning gone. What survives from R20 is only F61 — the arithmetic showing that `motors_max_torque`/`stiffness`/`gain` cannot matter while the clamp delivers 2.667 N·m against 1260 authored — and even that is now *record-only*, because nothing about the motor turns out to be causal for the drift.

---

## 3. F64 — the mechanism, from your own numbers

`mean_spring_torque = −2022.0813` is `2400·(target − q)` with `target = 0`, so the sampled joint angle is

```
q = +2022.0813 / 2400 = +0.842534 rad = +48.274°
```

and `angular_joint.setup()` sets, for a motor joint,

```
lower = motors_limit_min_deg · DEGREE_RADIANS = −140° = −2.44346 rad
upper = motors_limit_max_deg · DEGREE_RADIANS =  +40° = +0.69813 rad
```

**`q` exceeds `upper` by 0.144402 rad = 8.274°**, every tick, at drive time. Everything else follows:

- `project_position()` computes `error = q − clamp(q, lower, upper) = +0.1444` and rotates both bodies to remove it — a **0.1444 rad positional correction per tick**, applied inside each of the six position iterations.
- `block_velocity()` sees `q >= upper and omega > 0` and fires; your `max_abs_limit_block_impulse = 5.67e-4` is that firing.
- Position projection is PBD positional correction: it moves bodies without a corresponding momentum change, so the contact solver immediately rectifies the resulting foot motion — with friction, that rectification is translation. **A stop that is re-violated every tick is a per-tick engine.**
- The drive is a brake because `target = −62°·0.7 = −0.7576 rad` pulls `q` *negative*, i.e. off the +40° stop. With `gain = 0` the clamp is `±max_torque·0 = 0`, so `torque = 0` exactly and nothing pulls it off the stop. Hence 5.39 > 3.93.
- The free-hinge arms have **no angular row at all** — `coupled_load_probe` builds `CoincidentHinge` for the baseline path — so there is no stop to lean on. Hence 0.084.

So the ordering `free-hinge 0.084 < drive 3.93 < no drive 5.39` is exactly what a limit-leaning ratchet predicts, and it is why the two stiffness arms were identical: in both, the applied impulse was the clamp bound, which is a property of the constraint, not the motor.

**Why the limit is violated at all** is the second half of the finding, and it is not a solver question: `rest_angle` is captured from the authored pose at setup, so `q = 0` is authored-correct; gravity then sags the joint to `q = +48.27°`, and the author's `motors_limit_max_deg = 40` forbids it. **The creature cannot reach its own rest pose.** That is F65, and it is a preset-versus-limit authoring conflict, not a tune.

---

## 4. F66 — your bound measurement supersedes my arithmetic

I derived `bound = 6/134.9992 = 0.044444`. You measure `0.0411935` over the last 300, and `0.041248933` in the gain-0 arm. Since `weight = inv_I(parent) + inv_I(child)` is computed from the **actual endpoint extents** (`PlanarBasis.frame`), not from the `part.length` I used, your number is the real one and mine was a nominal approximation. The ratio conclusions (472.5× and 40.8× the bound) are unaffected — both are so far past saturation that a 7 % difference in the denominator changes nothing. From here, quote the measured bound.

---

## 5. The decisive test, and what falsifies me again

**Arm 1 — widen the stop, change nothing else.** `motors_limit_max_deg` 40 → 90 (diagnostic, not adopted), reference drive (`motors_gain_default`), everything else fixed.

- **Prediction (mine, falsifiable):** with `q ≈ +48.3°` inside a +90° band, nothing is violated, `project_position()` returns `OK` on `error == 0`, `block_velocity()` never fires, `limit_block_impulse ≡ 0`, and drift collapses toward the free-hinge **0.084 px/s** (I expect 0.08–0.5 px/s; the remaining difference is because a wide-limit joint still has its row).
- **If drift stays ≈3.9 px/s with `limit_block_impulse ≡ 0`, my mechanism is wrong for the fifth time** and the propulsor is in the distance/coincident-hinge/contact path instead. Say so plainly; do not hunt for a story that fits.

**Arm 2 — bound sweep with the reference drive.** `physics_max_constraint_angular_impulse_rad_s` 6.0 → 1.0, limit unchanged.

- **Prediction:** the drive is a brake, so weakening it should let drift **rise** from 3.93 toward the 5.39 gain-0 value (not reach it — bound 1.0 still delivers `1/6` of the angular impulse). Monotone ordering: `bound 6 → 3.93 < bound 1 → <5.39`.
- **If drift falls with the smaller bound, my sign is inverted** and the drive is a propulsor after all.

**Both arms: report the F63 teeth table** — requested, measured bound, applied, saturated ticks — plus, new: `limit_engaged_ticks/300`, `max|q − clamp(q, lower, upper)|`, and the summed positional projection magnitude for the `angular` phase (the "angular" row of your phase ledger). That last number is the one that makes or breaks F64: today it must be ≈ 0.1444 rad/tick; in a wide band it must be 0.

---

## 6. What the owner will need after that

**M1-D08 — the limit band versus the authored pose.** Whichever way the drift test lands, `+48.27°` of gravity sag against a `+40°` stop is a design conflict: the creature is permanently sitting on its end-stop at rest. The options are all feel decisions, so they are not mine:

- widen `motors_limit_max_deg` so the standing pose is legal (changes what a "crouch" means);
- change the authored pose/mass so the sag stays inside the band (changes silhouette and feel);
- keep the stop and make leaning on it an intended mechanic (then the drift is a design feature and must be tuned deliberately, not accidentally).

I am not picking one. The diagnostic above tells us whether the stop is *the* cause; D08 decides what to do about it.

Also still open from the plan: **D06** (FA-6 tutorial chunk) and **D07** (reference-device tick cost). All three are Phase-3/4 blockers, none blocks the two arms above.

---

## 7. Accepted as-is

- F60 rewritten as "late-window intervention void", with the **124/6000 startup-tick delivery difference retained** rather than smoothed away — that is the honest version and I want it kept.
- F63 retrofit: requested, bound, both clamps and delivered impulse audited per tick from raw pre-drive endpoints. That is what made this diagnosis possible in one round.
- F62: A withdrawn, not labelled failed.
- No tuning adopted, no baseline regeneration, no Phase 3, rows unmoved.
- Gain-0's momentum change **not** called the same terminal cycle as the reference — correct, since thrust differs by 35 %.

**Acceptance 8/18. Determinism attempt 1 stands as a same-build observation; cross-architecture attempts 0.**
