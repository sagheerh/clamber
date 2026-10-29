# M1 — R19 review: F56 prerequisite resolved (my spec was wrong); the drift is a damping terminal velocity, not a spring leak

**Target:** PR #3 head `efe7297` (draft, OPEN), 10 files +580/−2 over `9a4380c`.
**CI:** `40821176171` — failures are exactly two: *R18 F56 literal external-contact prerequisite* (step *F56 unchanged actuated-after6000 last300 momentum identity*) and *M1 point/link unit tests* at the unchanged support gate. **Public-Sim replay job green**, invariant/static green, spring diagnostic green, convergence job green. `40821176180` M0 **516/0** + Android pass.
**Reviewer branch:** `arena/5b72e4ab-clamber` → this file. Local: **152** Python controls pass, matrix guard exit 0.

---

## 1. Verdict

**The STOP was correct, and the prerequisite failed because I wrote it wrong.** With the balance I should have specified, it closes at rounding level, and the code makes that non-negotiable rather than rhetorical.

| Item | Status |
|---|---|
| **F56** | **CLOSED on the correct form** — complete external balance; internal rows structurally zero and enforced by `STOP` |
| Literal form | **retained as the record of my mis-specification**, not deleted, not redefined |
| F55 / F57 | **CLOSED** as report-only / nit |
| **F58** | new — the drift is exactly `thrust/(damping·m)`; success for A is a **thrust** criterion, 48× |
| **F59** | new — no equilibrium exists; record it, and re-read AC-201 accordingly |
| Remedy A | **authorized to proceed**, with a zero-torque fixed-point capture (see §4) |
| Rows | **8/18 measured**, unchanged — correct, nothing was upgraded on a failed gate |

Honouring the STOP instead of substituting the complete balance, and saying so in those words, is the right instinct. Now the substitution is authorised — on evidence, not convenience.

---

## 2. F56 — my third specification error, and why the fix is not a loophole

I wrote: *"Σ COM momentum change = Σ external (ground normal + friction) impulses"*. I left out **linear damping** and **gravity**. Both are external to the constraint system in this solver — damping is applied as `−LINEAR_DAMPING·p` per tick, gravity as `m·g·dt` — so the literal identity could never hold. Measured: lateral residual `−0.24891888144391563`, which is exactly the damping impulse `−0.24891888144391586`, to `6.4e-16`.

The risk in "let the balance include more terms" is that internal leakage gets absorbed into the allowance. `tests/load_external_report.py` forecloses that, and I checked the code rather than the prose:

```python
if not close(drive, 0.) or not close(internal, 0.):
    raise ValueError('INTERNAL momentum leak; STOP')        # per tick
if not close(sums['internal_drive'],0.) or not close(sums['internal_velocity'],0.):
    raise ValueError('Window INTERNAL momentum leak; STOP') # per window
if not close(damping, -LINEAR_DAMPING*(before+drive)):
    raise ValueError('Damping book disagrees with resource-derived damping')
```

So the internal rows (`internal_drive`, `internal_velocity`) are **structural zeros that abort the run if violated**, not free parameters that close a gap. Damping is not a plug either: it is recomputed from the resource coefficient and the reconstructed momentum, and the contact sum is cross-checked against the solver's own recorded velocity impulse. The claimed residual is the remainder after all of that.

Result, per tick: max |full residual| **5.20e-17** lateral, **3.68e-16** vertical; window sums `−6.45e-16` / `3.54e-14` against the existing `1e-12`. Internal sums `−1.25e-16` and `9.92e-16` (lateral), i.e. roundoff, with `drive` and `internal` individually asserted zero every tick.

**F56 CLOSED.** Prerequisite satisfied: no internal row moves the centre of mass, exactly as I derived from `AngularJoint`, `CoincidentHinge` and `SelfContact`, and now measured.

*Bonus consistency check:* the window normal impulse implies `215.78345997892384/300 × 60 = 43.157 N` average support against `W = 43.4 N` — a **0.243 N** deficiency, inside the 0.723 N of the corrected F26 invariant. The load path is still honest in the arm that walks.

---

## 3. F58 — the drift is a terminal velocity set by `physics_linear_damping`, not by the spring's size

The two lateral sums are equal and opposite to 14 digits: friction `+0.24891888144391522`, damping `−0.24891888144391586`. That is not a coincidence, it is a **terminal-velocity regime**, and it can be solved for exactly:

```
thrust per tick   = 0.24891888144391522 / 300 = 8.297296e-04  mass·WU/s
mean thrust force = 8.297296e-04 × 60         = 0.049784 N     = 0.1147 % of W
terminal velocity = thrust_per_tick / (damping · m)
                  = 8.297296e-04 / (0.02 × 1.55)
                  = 0.0267654711 WU/s = 4.0148 px/s
reported mean_completed_com_vx = 0.02676547112300171   (agrees to 7.3e-17)
```

Three consequences that change how the remedy is judged:

1. **Nothing is accumulating and nothing is unbalanced.** The creature is held at a constant speed by `physics_linear_damping = 0.02`, exactly as an object at terminal velocity. There is no leak to find, which is why F56 closes.
2. **The drift magnitude is a damping property.** A persistent thrust of `F` yields `drift = 150·F/(0.02·1.55)`. The rectified thrust is only **0.115 % of body weight**, and it still produces 3.93 px/s because the only brake is 2 % damping. This is why I refuse to touch damping — it is feel, and it is the knob that would "fix" the symptom without changing the cause.
3. **A's success criterion is thrust, not drift.** Baseline drift `5.602e-04 WU/s` is **47.78×** smaller, so A must reduce the rectified friction impulse from `8.297e-04` to **≤ 1.74e-05 mass·WU/s per tick**. Publish that number. If A removes the offset but leaves an oscillation, thrust will fall by a few ×, not 48×, and the honest reading will be *"the offset was not the whole cause"* — not *"A failed"*, and not a reason to tune stiffness.

---

## 4. A's calibration must be a fixed point — capture with the return disabled

This is the one thing that could make a correct remedy look broken. Today `q_settled ≈ 0.8429 rad` is measured **with the spring live and targeting 0**, so it is a spring-loaded equilibrium, not a free one. Set the target to that number and the equilibrium moves: the capture was never a fixed point, and A would land at a different pose with a residual offset and a residual thrust.

Capture instead with the return **disabled** — motor target tracking `q` every tick, i.e. zero spring torque — settle, record `q_settled`, then set the target. At that pose the spring torque is zero by construction, so it is a genuine fixed point and the resting creature is genuinely unpowered.

Record in the evidence: the capture protocol, the number of settle ticks, the captured `q_settled` per joint, and the fact that it lives in solver state so it is inside `snapshot()` and `state_hash()`. The baseline will legitimately change once; regenerate it with provenance and say so, rather than bending the protocol to keep an old hash.

---

## 5. F59 — there is no equilibrium to converge to; "settled" is the wrong word for this arm

`Δp ≈ −4e-16` over 300 ticks while `vx ∈ [0.0222, 0.0431]`, **strictly positive throughout**. Net velocity change is zero, velocity is never zero. That is a **periodic limit cycle translating at constant mean speed** — a rocking walker, not a settling body. Its 6-tick recurrence is the cycle.

So for the actuated arm:

- `settled = false` was never going to flip to `true`; the system has no fixed point, and reporting `settled_mean = null` is the correct description of a cruising limit cycle.
- AC-201's "settles and sleeps within 4 s" must be read, for a live-spring creature, as **"zero input produces zero net motion"** — a design property, not a convergence property. Do not relax it; state it.
- Put F59 in the mechanism table next to F55 and F58 so that these three findings read as one story: *a 0.115 %-of-weight rectified thrust, braked only by 2 % damping, holds a periodic limit cycle at 4.01 px/s.*

---

## 6. Accepted as-is

- F55 report row: `0.15 WU/s × 150 = 22.5 px/s`, arms at 0.4 % / 15.6 % / 17.5 %. Correct framing, no claim of a leak.
- F57 wording: RNG exists, survives replay, physics does not consume it. Correct.
- 8/18 unchanged, no baseline regeneration, no AC-201 run, Phase 3 not entered. All correct.
- `remedy_authorized_by_requested_gate` correctly computed from the literal predicate and exited 1; the report keeps both definitions side by side rather than overwriting the literal one. That is the behaviour I want from every future gate.

---

## 7. What happens next

1. **Motor-stiffness sweep** — `motors_joint_stiffness` 2400 vs 0, damping untouched, drift in px/s and **rectified thrust per tick** for each. This is the falsification of my own mechanism claim; if 0 does not collapse the drift, the spring is not the source and we stop again.
2. **A**, captured with the return disabled (§4), then measured against three numbers: drift vs `0.084 px/s`, thrust vs `≤ 1.74e-05`, and `q_settled` as a fixed point (re-measure after applying A and show it does not move).
3. Then **Phase 3**: AC-201 (with F59's reading), AC-202, FA-3/FA-4/FA-5.

**Acceptance 8/18. Determinism attempt 1 stands as a same-build observation; cross-architecture attempts 0.**
