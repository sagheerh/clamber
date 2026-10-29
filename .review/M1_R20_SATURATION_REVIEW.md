# M1 — R20 review: the sweep was void, not a falsification — both arms are hard-saturated by the constraint impulse bound

**Target:** PR #3 head `979563f` (draft, OPEN), commits `217eda1` + `979563f` over `efe7297`.
**CI:** `40865358974` — failures are exactly *R19 motor2400 vs0 source falsification* (step *Motor2400 vs0 unchanged damping, drift AND rectified thrust*) and the unchanged support gate. **F56 job now SUCCESS on the complete form**, public replay/clock green, invariant/static green, convergence green. `40865359049` M0 **516/0** + Android pass.
**Reviewer branch:** `arena/5b72e4ab-clamber`. Local: **158** Python controls pass, matrix guard exit 0.

---

## 1. Verdict

**Stopping was right; the conclusion drawn from the arm is not.** The zero-stiffness arm did not remove the drive, it only removed one term of it, and the remaining term is **40.8× larger than the impulse the solver can deliver**. Both arms therefore apply the *same saturated impulse* every tick, which is why the two runs agree to `1e-16`. This is not evidence about the spring at all — it is evidence about `physics_max_constraint_angular_impulse_rad_s`.

| Item | Status |
|---|---|
| Intervention honesty (`mean_spring_torque = 0.0`, torque −1260 → −108.7) | **verified real** |
| "Falsifies the spring-as-source premise" | **WITHDRAWN** — the arm is void, not falsifying |
| **F60 [MAJOR]** both arms saturated → identical applied impulse | new, arithmetic + observed |
| **F61 [MAJOR]** the effective motor strength is the constraint bound, not the authored torque | new, 472× |
| **F62** A's dead band is **0.064°**; A is predicted to fail at stiffness 2400 | new — **my A recommendation is withdrawn** |
| **F63** every future arm must report `|j|` vs `bound` | new gate rule |
| F56 / F55 / F58 / F59 / F57 | **CLOSED**, unchanged |
| Rows | **8/18**, movement 0 — correct |

---

## 2. The arm is void — here is the arithmetic

`apply_impulse()` caps the **cumulative** per-tick impulse at

```gdscript
var bound: float = _tuning.physics_max_constraint_angular_impulse_rad_s / value.weight
var j := clampf(requested, -bound - impulse, bound - impulse)
```

with `weight = inverse_inertia(parent) + inverse_inertia(child)` and `inverse_inertia = 4/(mass·length²)` from `PlanarBasis.frame`. For the Slug's joint 0 (head → motor), from the committed tuning and preset:

| body | length WU | density | mass | `inverse_inertia` |
|---|---:|---:|---:|---:|
| head | 0.35 | 2.2 | 0.770 | 42.4066 |
| motor | 0.30 | 1.6 | 0.480 | 92.5926 |
| foot | 0.25 | 1.2 | 0.300 | 213.333 |

`weight = 134.9992`, therefore **`bound = 6.0 / 134.9992 = 0.0444447`** relative-rad/s per tick — i.e. the drive may change relative angular velocity by at most **6 rad/s per tick**, and no more.

Now the two arms, whose requested impulses your report already contains:

| arm | mean applied torque | requested impulse/tick = torque/60 | × bound | saturates? |
|---|---:|---:|---:|---|
| stiffness 2400 | −1260.0 (saturated at `max_torque·gain`) | **−21.000** | **472.5×** | yes |
| stiffness 0 | −108.727 | **−1.812** | **40.8×** | **yes** |

Both clamp to the same `±bound`, so the applied impulse is **identical every tick** in both arms — which is exactly what your own report shows, and what I should have insisted on measuring before drawing a conclusion:

- `mean_abs_q` differs by **1.2e-16**
- `mean_damping_torque` differs by **1e-14**
- drift differs by **9.5e-14 relative**, thrust by **2e-15 relative**
- `mean_normal_support_n` identical to all printed digits (43.15669199578477)

An 11.6× smaller torque and a 19.5× smaller angular impulse producing a 1e-16 identical trajectory is not a physical result; it is the signature of a clamp that swallowed both inputs. **This arm did not test the spring, so it cannot falsify it.** Correct label: *uninformative intervention*, recorded as F60.

Credit where due: reporting `mean_clamped_total_torque` (−1260 → −108.7) is what made this diagnosable. Keep that field forever.

---

## 3. F61 — the motor's authored strength is inoperative

The deliverable torque is

```
bound × tick_hz = 0.0444447 × 60 = 2.667 N·m
```

against `motors_max_torque × motors_gain_default = 1800 × 0.7 = 1260 N·m`.

**The motor delivers 0.21 % of its authored strength; the ratio is 472×.** Consequences:

1. `motors_joint_stiffness`, `motors_joint_damping`, `motors_max_torque` and `motors_gain` are all **inoperative** anywhere the required torque exceeds 2.667 N·m — which is everywhere, since the resting error alone (0.8425 rad × 2400) demands 2022 N·m.
2. The **actual motor strength** is `physics_max_constraint_angular_impulse_rad_s / weight`, a *global solver* constant that applies identically to every joint of every creature. Motor strength is currently not authorable.
3. For the product this matters more than the drift: "too easy / too hard" tuning for the lurch is done through a coefficient that has no effect, because the clamp is the muscle. When FA-4's "single L-hold lurches ≈ one body length" is measured, it will be measuring the clamp, not the authored motor.

Do not change any of these numbers. Record F61 and carry it into the remedy discussion.

---

## 4. F62 — I withdraw A, on arithmetic

A set `target = q_settled`. For the drive to leave saturation, the residual must satisfy

```
stiffness · |q − target| / tick_hz < bound
|q − target| < bound · tick_hz / stiffness = 2.667 / 2400 = 1.111e-03 rad = 0.064°
```

The joint currently swings with `|q| ≈ 0.84 rad` and `last300_vx_range` spanning 2× (`0.0222–0.0431` WU/s). Requiring the residual to stay inside **0.064°** for 300 ticks is not a calibration problem, it is a different machine: even a 0.1° residual re-saturates the drive and the thrust returns at the same 0.0498 N.

Equivalently, for the motor to be *linear* at that pose, stiffness would have to fall to `2.667 / 0.8425 = 3.17 N·m/rad` — **756× below the authored 2400**.

So: **A as I specified it is predicted to fail, and I withdraw the recommendation.** Had it run, it would have produced a residual offset, re-saturated, and either been misreported as "A failed" or quietly followed by stiffness tuning — the exact trap I have been warning about. This is my fourth specification error in this milestone and the third one you caught by measuring instead of agreeing.

The prediction is falsifiable in one cheap run, and it should be run before any remedy anyway: **A with a deliberately 0.5° residual.** Under my claim, thrust returns to ≈ 0.0498 N. If it does not, my saturation argument is wrong and A survives.

---

## 5. What to measure next, in this order

1. **Zero-drive arm (F63 arm 1)** — `motors_gain = 0`. This is the only arm where the drive is *provably* zero: `target = −62°·rad·0 = 0` and the clamp `±max_torque·0 = 0`, so `torque = 0` exactly, requested impulse 0, no saturation. Report drift and thrust.
   - **Prediction:** drift collapses to the free-hinge baseline 0.084 px/s. If it does, the saturated joint impulse is the propulsor and the spring-stiffness question becomes "how often is the drive saturated", not "how stiff is it".
   - If drift does **not** collapse, then the source is in the contact/limit path and every torque hypothesis is dead — stop and report.
2. **Bound sweep (F63 arm 2)** — `physics_max_constraint_angular_impulse_rad_s` 6.0 → 1.0, everything else fixed. **Prediction:** thrust falls roughly in proportion (≈ 4×), because with saturation the applied impulse *is* the bound. This is the direct causal test of F60/F61 and it is diagnostic only.
3. **A-with-residual (F62 check)** — optional, only if 1 and 2 did not already settle it.

For all three: damping untouched, stiffness untouched unless it is the arm's variable, and the F56 complete balance re-run on every arm.

---

## 6. F63 — a new standing rule for every intervention

I have now had three sweeps that changed nothing physical (passive stiffness on a motor joint, motor stiffness under saturation, and the two spawns that were fine only because they *were* identical). The rule from here:

> **Every sweep must publish the strength of its own intervention** — for a drive, the requested impulse, the bound, the applied impulse, and the saturated-tick fraction; for a pose, the per-tick trajectory difference against the reference arm.

If the intervention does not move the applied quantity, the arm is **void**, not a falsification. Report `saturated_ticks / 300` for each arm in the next report. A sweep that cannot show its own teeth is not evidence.

---

## 7. Accepted as-is

- F56 complete-form job SUCCESS with the literal record, failed predicate and exit 1 all retained.
- Public replay/clock unchanged and still matching the committed baseline (`d735ea5f…`, three identical public hashes).
- 8/18, rows moved 0, no A, no baseline regeneration, Phase 3 not entered.
- F55/F58/F59 recorded together: 22.5 px/s allowance, 0.115 %-of-weight thrust, 4.01482 px/s terminal prediction vs 3.93452 px/s positional drift, positive-velocity rocking with 6-tick recurrence, AC-201 read as zero-input/zero-net-motion **plus** sleep ≤4 s, no gate relaxation.
- F57 wording still precise.

**Acceptance 8/18. Determinism attempt 1 stands as a same-build observation; cross-architecture attempts 0.**
