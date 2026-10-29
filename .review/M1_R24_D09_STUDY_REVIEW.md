# M1 — R24 review: the study is clean, the re-scale works, and it proves the drift is **contact-level, not joint-level**

**Target:** PR #3 head `7d48ba0` (draft, OPEN), commits `573a1fb` + `7d48ba0` over `d76b88e`.
**CI:** study job **success** (15 runs, 90 000 raw ticks, observer on/off bit-equal every tick), public replay/clock **reproduced the committed baseline exactly, not regenerated**, M0 **516/0** + Android, existing F47 red and **not waived**. Local: **185** Python controls pass.
**Defaults:** `core/tuning.tres` and `data/creatures/` byte-identical to `d76b88e`; candidates lived only in `tests/fixtures/d09/*`, plus the provisional `data/towers/provisional_fa6.json`.
**Reviewer branch:** `arena/5b72e4ab-clamber`.

---

## 1. Verdict

**Study accepted. Nothing adopted — and that is the right call, for a better reason than the report gives.**

| Item | Status |
|---|---|
| Study integrity (15 runs, F56 ≤4.57e-14, observer equality, baseline untouched) | **accepted** |
| Headroom criterion | **met** — worst `|requested|/bound` 0.2452/0.2402/0.2356, saturation 0/300, no torque or speed clipping |
| **F65 — the sag past the stop** | **FIXED by the re-scale** — powered poses now sit at 12.8°/5.2°/1.8°, inside the +40° band, engagement 0/300 |
| Station-keeping | **not achieved** — 8.55/11.48/12.91 px/s, 28×/38×/43× the 0.3 px/s line |
| **F71 — the drift obeys `A − B/k`, A = 14.41** | new, my fit |
| **F72 — the internal pose is frozen while the creature translates** | new, from your own `q` ranges |
| **F73 — AC-201 and FA-4 pull in opposite directions** | new, lurch 6.4×/9.8×/33.8× short |
| My D09 goal, and my D08 premise | **both falsified — recorded in §6** |
| Rows | **8/18**, movement 0 |

---

## 2. What the re-scale actually achieved — and it is not nothing

Three things I asked for are now true, and they are the reason this study was worth its round:

1. **The gain dial is alive.** Worst `|requested|/bound` = **0.2356–0.2452**, saturation **0/300**, `upstream_torque_clipped_ticks` **0**, `body_speed_limited_ticks` **0**. The motor finally runs in its linear range; the clamp no longer *is* the muscle.
2. **F65 is closed.** In the powered cells `q` sits at **12.787° / 5.154° / 1.840°**, comfortably inside the authored +40° band, with `limit_engaged_ticks` **0**, projection **0**, block impulse **0** for all 6000 ticks. The 8.27°-past-the-stop sag that dominated R19–R22 is **gone**. That is a real authoring fix, not a measurement artefact.
3. **The dead band is gone** — the residual is now 0.223/0.090/0.032 rad instead of 0.84, so `motors_gain` and `motors_contraction_deg` actually shape the pose.

**So the re-scale did what it was designed to do. It just did not do what I hoped it would do for the drift, and that is the finding.**

---

## 3. F71 — the drift follows `A − B/k`, and the asymptote says the joint is not the cause

Fitting the three measured points:

```
drift(k) = A − B/k     A = 14.4083   B = 58.5818

k=10  measured  8.55015   fit  8.55015   err 0.0
k=20  measured 11.47924   fit 11.47924   err 0.0
k=40  measured 12.91042   fit 12.94379   err 3.3e-02
```

A two-parameter fit through three points is weak evidence on its own — but the *shape* is not: drift is **monotone increasing** in stiffness while the residual is **monotone decreasing** (0.223 → 0.090 → 0.032). **Less torque, more drift.** Every torque-based explanation predicts the opposite sign, which is why mine kept failing.

The asymptote is the part that matters: `A = 14.41 px/s` at `k → ∞`. **A perfectly rigid joint still drifts at ~14 px/s.** So joint compliance cannot be the cause, and no stiffness value removes it. Predicted at the two unmade points: k=80 → 13.68, k=160 → 14.04.

---

## 4. F72 — the internal pose is frozen to 1e-14 while the whole creature slides

This is the observation that settles the mechanism, and it is in your own table: `working_pose_q_rad` is `0.22316866…` with min and max differing in the **14th decimal** — the joint is *static* — and the creature nevertheless translates at 8.55–12.91 px/s. Cross-check with F58: thrust `0.16336 N` → `(0.16336/60)/(0.02×1.55) = 0.0879 WU/s = 13.2 px/s` against 12.91 measured. The drag balance still closes, so this is a **steady creep at terminal velocity**, not a rocking limit cycle.

Put together:

> A creature held in a **fixed internal pose** by a live motor, with **no stop engagement**, **no saturation**, a **0.03–0.22 rad residual**, and a joint that moves by less than 1e-14 rad, translates steadily across a flat floor.

That is not a joint phenomenon, not a stop phenomenon, and not an oscillation. It is the **contact/friction model rectifying a sustained internal load into translation**. It also explains the whole earlier 2×2 without contradiction: the free-hinge and inert arms drift at 0.084 because they carry **no internal torque at all**, and the moment a torque exists the body creeps (8.5+ even at the softest setting) — the discontinuity in §5.

---

## 5. The discontinuity that frames everything

| state | internal torque | drift | × floor |
|---|---|---:|---:|
| free hinge / inert | **none** | **0.0840** | 1.0× |
| linear motor, k=10 | 0.048 (23 % of bound) | 8.5502 | 101.7× |
| linear motor, k=40 | 0.010 (5 % of bound) | 12.9104 | 153.6× |
| saturated motor (committed) | 0.041 (100 % of bound) | 3.9345 | 46.8× |

**Zero torque ⇒ floor. Any torque ⇒ 8.5–12.9.** A 100× jump for a torque that is 5–23 % of the bound. Reducing the torque does not approach the floor; it moves *away* from it once the joint is stiff enough to transmit rather than absorb.

Consequence: a creature that must hold itself up with a live motor **cannot** reach 0.3 px/s on this contact model by any motor parameter. AC-201 as written is therefore not a motor-authority problem — which is the third time this milestone has reclassified the problem, and the first time the classification is compatible with everything measured.

---

## 6. My two errors, recorded plainly

**D09's goal is falsified.** I justified the re-scale as "remove the cause: no sag past the stop ⇒ no stop projection ⇒ linear motor ⇒ small residual ⇒ pumping gone". The stop and the sag *were* removed — measured, 0/300 engagement — and the drift went **up 2.2–3.3×**. The premise that a linear motor would park the creature was wrong.

**D08's premise goes with it.** I wrote "fix the muscle and re-measure; do not freeze the creature", on the theory that a physical fix would make the hold unnecessary. It does not. The re-scale is still the right engineering (real dial, legal pose, no saturation) but it will **not** deliver station-keeping, and I should not pretend otherwise.

What survives from D08 is exactly the pre-registered fallback, and its condition is now **met by measurement**: drift > 0.3 px/s after a full re-scale and four-arm re-measure ⇒ **the visible release-hold is authorised**. I am deliberately not spending it yet — see §8.

---

## 7. F73 — AC-201 and FA-4 pull in opposite directions

FA-4 wants a single L-hold to lurch **≈ one body length**. The Slug chain is 0.35 + 0.30 + 0.25 = **0.90 WU**:

| k | lurch (held) | body lengths | short of FA-4 |
|---:|---:|---:|---:|
| 10 | 0.14076 WU | 0.156 | **6.4×** |
| 20 | 0.09222 WU | 0.102 | 9.8× |
| 40 | 0.02660 WU | 0.030 | 33.8× |

So **stiffer is better for drift and worse for lurch, and softer is better for lurch and worse for drift** — and *neither end* satisfies its own gate. There is no `k` that passes both, which means adoption cannot be decided on these three candidates at all. Your proposed protocol is fine as an instrument, but the numbers are measured on the wrong side of a trade-off that the parameter cannot resolve.

---

## 8. The three measurements that decide adoption — one round, then I choose

I hold delegated authority for these, and I am time-boxing this: **one more measurement round, then the decision is taken** whether or not everything is perfect. M1 has spent seven rounds on this phenomenon and the remaining ten gates are still unmeasured.

**A. The rectifier itself** — at the `k=40` candidate, `physics_static_slip_wu_s` `0.15` → `0.015` → `0.0015`, diagnostic duplicate, three cells, defaults untouched.
Hypothesis: drift scales with the static-slip allowance. Observed creep is `0.086 WU/s` against a **0.15 WU/s** allowance — 57 % of it. If drift falls roughly in proportion, the "static" branch is a **velocity clamp rather than true sticking**, and that is the actual lever: to reach 0.3 px/s it would need ≈ 0.0035 WU/s. This is the single most informative number left in the milestone.

**B. The reference lurch** — run the *same* proposed protocol on the **committed** defaults (saturated motor, bound 6.0, k=2400). I have no FA-4 comparison without it, and if the committed creature already lurches near one body length, adopting any linear candidate would **destroy the one behaviour that works**.

**C. Two fields you already have** — for the three powered cells, report `last300_com_vx_range` and the per-tick `q` spread. §4 rests on `q` being frozen to 1e-14; publish the spread explicitly so the claim is auditable rather than inferred from a mean table.

**Then I decide between exactly two packages:**

| | **P-A: keep saturated, add visible brace** | **P-B: adopt linear k=10, add visible brace** |
|---|---|---|
| physics change | none | k=10, damping 0.544, bound 30, cap 12 |
| gain dial | dead | **alive** |
| pose vs +40° stop | 8.5° past it | **legal (12.8°)** |
| idle drift without brace | 3.93 | 8.55 |
| lurch | **measure in B** | 0.156 body lengths |
| cost | 1 increment | 1 increment + baseline regeneration + lurch re-derivation |

Both packages end in a **visible brace** — a designed state, not a silent freeze: the creature visibly plants itself on input release, with its own presentation, and releases on input. The brace must be audited like sleep already is: snapshot/restore, explicit ledger treatment, and the hold impulse counted as an internal term that sums to zero so the F56 identity still closes. **A brace that manufactures support or fudges loads is rejected on sight.**

---

## 9. Accepted as-is

- **Nothing adopted**, no bound raised a second time, defaults and creature bytes untouched, no hold added before approval. Correct on all four.
- `settled_pose = null` for all 15 runs, with working-window means and ranges published instead. **Exact equilibria not claimed** — right answer, and it is why your residuals stayed honest.
- Damping derivation `c = 2√(k·I_eff)`, `I_eff = 1/(1/I_p + 1/I_c)`, with the explicit caveat that it is a continuous linearisation of a nonlinear discrete plant and that "critically damped" is **not** asserted at the loaded plant (evaluated ζ 1.066/1.079/1.085). Good.
- `stop_only` = **5.37492** and `inert` = **0.08404** identical across all three candidates — the internal control that shows the drive-zero axes are genuinely independent of stiffness. That agreement is worth as much as the results.
- `both` ≡ `drive_only` **to every digit** at each candidate, exactly as predicted by zero stop engagement.
- F52 eligibility reported as a **counterfactual on an awake trace, not AC-201 and not parking**, with post-release eligibility at 82/66/64 ticks explicitly *not* claimed as sleep. Your instinct that "a low window-mean drift is not sufficient; the actual predicate must fire" is right and I want it kept as a standing rule.
- **D06 fixture** authored as provisional geometry with `status`, `subject_to: M1-B04`, unmeasured layout numbers, and the determinism caveat that identical inputs cannot produce 6–8 of 10 without artificial variance. That last note is the most valuable line in the file, and it means **FA-6 must be specified before it can be measured** — see §10.

---

## 10. FA-6 needs one owner-level statement before it can ever pass

Your fixture is honest, and honesty exposes a problem: a deterministic solver given one input script and one seed produces **one** outcome. Ten runs of that are ten copies. So FA-6's "10 runs, 6–8 successes" is only meaningful if the runs **differ**, and the difference must come from something legitimate: 10 different **starting poses** within a tolerance, 10 different **input timings** (player imperfection), or 10 different **spawn offsets**. That is a spec decision, not a code one, and it must be written down **before** the test, not chosen after seeing results.

I will settle it with the package decision above; do not invent variability before then.

---

## 11. State of M1

**8/18 measured.** Ten remain: AC-201, AC-202, AC-204, presets + captures, tick cost, §10.6, FA-3, FA-4, FA-5, FA-6.

- **AC-202 and FA-5** are independent of every open question and have still not been started. If the next round takes more than one increment, they start in parallel.
- **AC-201** is now correctly characterised: it needs either a contact-model fix (arm A) or the brace.
- **FA-4** cannot be evaluated until arm B measures the reference lurch.
- **D07** (reference-device tick cost) still needs the owner's phone.

**Acceptance 8/18. Determinism attempt 1 stands as a same-build observation; cross-architecture attempts 0.**
