# M1 — R22 review: both directions dead; no single factor predicts the drift; stop hunting knobs

**Target:** PR #3 head `63cb024` (draft, OPEN), commits `0943087` + `48d54df` + `63cb024` over `74c629e`.
**CI:** `40878101597` — green: F56 complete, public replay/clock, invariant/static, R17 spring, R16 convergence. Red: sustained-support gate and *R21 wide stop then bound diagnostic* (the two falsified predictions). `40878101769` M0 **516/0** + Android pass.
**Reviewer branch:** `arena/5b72e4ab-clamber`. Local: **176** Python controls pass, matrix guard exit 0. `core/tuning.tres` + `data/creatures/` diff vs `74c629e`: **empty** — defaults really were untouched, the 90° band existed only in an exited diagnostic duplicate.

---

## 1. Verdict

**Both arms are accepted; both of my predictions failed; and the four arms together destroy the frame I was using.** I have now been wrong six times in this milestone, and the useful conclusion is not a seventh hypothesis — it is that **this system has no single lever**, and continuing to hunt one is burning rounds.

| Item | Status |
|---|---|
| Arm 1 (wide 90°) | **accepted** — zero limit engagement/projection/block impulse on all 6000 ticks, drift 2.9500 |
| Arm 2 (bound 1.0) | **accepted** — drift 3.5208, my predicted sign inverted |
| My R20 claim ("saturated impulse is the propulsor") | **falsified** (gain 0 went *up*) |
| My R21 claim ("the drive is a brake") | **downgraded to false as a mechanism** — see §3 |
| My "0.1444 rad per pass" | **wrong** — you are right, 0.0704 rad/tick summed over six passes |
| F61 | **strengthened** — saturated 300/300 even at bound 1.0 (3080× over) |
| F64 | **revised** — stop engagement contributes 25 %, is not necessary |
| F65 | **stands** — the only surviving structural claim |
| **F67** | new — non-monotone response; no scalar predicts drift |
| **F68** | new — AC-201 for the actuated creature is unreachable with these constants, whatever the band |
| Rows | **8/18**, movement 0 |

---

## 2. The four arms, side by side

| arm | applied \|j\| | projection rad/tick | thrust | drift px/s | vs free-hinge |
|---|---:|---:|---:|---:|---:|
| free-hinge baseline (no angular row) | — | — | 1.68e-05 | **0.0840** | 1.0× |
| **gain 0**, stop 40° (R21) | 0 | — | 1.1205e-03 | **5.3874** | 64× |
| **bound 1.0**, stop 40° | 0.006818 | 0.23704 | 7.4280e-04 | **3.5208** | 42× |
| **reference**, stop 40°, bound 6.0 | 0.041194 | 0.07043 | 8.2973e-04 | **3.9345** | 47× |
| **stop 90°**, bound 6.0 | 0.042442 | 0.00000 | 6.2988e-04 | **2.9500** | 35× |

Every arm still obeys F58 (`drift = thrust/(damping·m)`); I re-derived the prediction column and it matches each measured value to better than 1 %. So the accounting is sound everywhere — what is missing is any *causal* ordering.

---

## 3. F67 — no single factor predicts the drift, and my "brake" story dies with the rest

The two cleanest comparisons are single-variable, and they disagree with each other:

- **Stop engagement only** (reference → wide 90°): brake strength changes by **+3.0 %**, stop engagement goes to zero, drift falls **−25.0 %**.
- **Brake strength only** (reference → bound 1.0): brake strength drops **6.0×**, stop engagement unchanged at 300/300, drift falls **−10.5 %**.

And the ordering across all four arms is **non-monotone in both variables**:

- brake `0 → 5.387`, `0.0068 → 3.521`, `0.0412 → 3.935`, `0.0424 → 2.950`
- projection `0 → 2.950`, `0.0704 → 3.935`, `0.2370 → 3.521`

A pure drag would be monotone decreasing in brake strength. A pure stop-ratchet would be monotone increasing in projection. Neither holds. A **3 % larger brake giving 25 % less drift** is not a drag coefficient, it is a **phase relationship**: the drift is the DC component of a limit cycle, and the limit cycle's phase responds to whichever coupling changed, in whichever direction.

So I withdraw "the drive is a brake" as a mechanism. What is defensible from R21 is only: *a larger applied angular impulse coincided with lower drift in two of the three comparisons.* That is a correlation in a 4-point set with a sign flip in it, and it is not a mechanism.

**The one thing that is unambiguous across all five rows: the presence of the angular row itself takes drift from 0.084 to 2.95 px/s — a 35× floor — and no configuration of that row (zero drive, zero engagement, weaker clamp) gets back below 2.95.** The row is not a propulsor in any of the four ways I tried to characterise it; it is a *coupling* that turns vertical sag into horizontal translation, and the DC component is emergent.

---

## 4. F61 strengthened, and what it means for feel

The bound-1.0 arm is the strongest evidence yet: requested impulse −21.0 against a measured bound of 0.006818 is **3080× over**, saturated **300/300**. So there is **no linear motor regime in any arm we can run**: at bound 6.0, 1.0 and gain 0.7/0, the drive is either fully clamped or exactly off. The delivered joint impulse is a *constraint* constant (`physics_max_constraint_angular_impulse_rad_s / weight`), and `motors_joint_stiffness`, `motors_joint_damping`, `motors_max_torque` and `motors_gain` never bind.

Order-of-magnitude context for the owner, **estimate not measurement**: `bound × tick_hz ≈ 2.67 N·m` of effective drive, against a gravitational demand of roughly `m_eff·g·r ≈ 2 N·m` for this 1.55 kg, 0.3 WU creature. The creature is sitting at the edge of being able to hold itself up, which is consistent with a permanent sag and with drift that responds to phase rather than to force.

---

## 5. My error, recorded

I wrote that the stop violation produces "a 0.1444 rad positional correction per tick inside each of the six iterations". Wrong twice: the 0.1444 figure was `mean|q| − upper` (a mean, not a max), and the correction is **distributed** across passes, not repeated per pass. Your measured values are the correct ones — max drive-time violation **0.1500 rad**, summed correction **0.0704 rad/tick** — and your separation of *drive-time error* from *actual correction* from *endpoint displacement in WU* is exactly the distinction I failed to make. Keep all three columns permanently.

Also good: resolving the bound-1 boundary audit with **exact binary64 predicate telemetry** (39/300 and 1746/6000 decimal-vs-binary disagreements) instead of adding an epsilon. That is the right instinct and it produced a better audit than the one I specified.

---

## 6. The one arm still worth running — and it is decisive, not exploratory

We have a 2×2 factorial of (drive impulse) × (stop engagement), and **one cell is missing**:

| | stop engaged | stop not engaged |
|---|---|---|
| **drive applied** | reference 3.9345 ✅ | wide 90° 2.9500 ✅ |
| **drive zero** | gain 0 5.3874 ✅ | **MISSING** |

**Run `motors_gain = 0` with `motors_limit_max_deg = 90`.** Prediction, and it is a strong one: **drift ≈ 0.084 px/s, equal to the free-hinge baseline.**

Reason: with the drive at zero and no band violation there is nothing left for the angular row to do. `MotorDrive.drive()` returns `torque = clamp(2400·(0−q) − 55·ω, ±1800·0) = 0` exactly, so `apply_impulse(0)` changes nothing; `project_position()` returns early on `error == 0`; `block_velocity()` cannot fire inside the band. In that configuration `AngularJoint` is provably inert, and the only active rows are the coincident hinge, the distance rows and the contacts — i.e. the free-hinge baseline.

- **If it lands at 0.084**, the frame is settled: each mechanism (applied impulse, stop projection) is *independently sufficient*, neither is necessary, and the DC drift is an interaction. Then stop experimenting and go to the owner with D08.
- **If it does not** — if an inert angular row still produces ~3 px/s — then something in the row or its plumbing moves the child without an impulse, and that is a genuine solver defect worth finding, because it would invalidate every "component accepted" claim downstream of it.

Report for that arm: drift, thrust, F56, and the same three limit columns. Nothing else.

---

## 7. Strategic pivot — stop hunting, start deciding

Four arms, three falsified hypotheses, and a 35× floor that no parameter has moved below 2.95. The productive conclusion:

1. **Do not run further single-factor sweeps without an owner direction.** The next sweep will be a fifth falsification of the same kind.
2. **F68 — AC-201 for the actuated creature is unreachable with these constants.** "Zero input ⇒ settle and sleep ≤4 s" is contradicted by every actuated arm (2.95–5.39 px/s), and it is not a matter of the band: widening the stop *reduced* the problem by only 25 % and DID NOT remove it. So the owner question is no longer "which limit band" — it is **what provides station-keeping**, because the current drive cannot: it is saturated in every arm, and its authored strength is inoperative.
3. **M1-D08 restated, with the data the owner needs.** All three original options are now measured or bounded:
   - widen the stop → **2.95 px/s, insufficient** (measured);
   - change pose/mass so the sag is legal → removes a +3 % brake difference and 25 % of the drift at best, and the drive stays saturated (measured);
   - keep the stop as an intended mechanic → then AC-201 must be re-read as "no input produces no *net* displacement over N seconds", which needs an owner-authored number, and the sleep predicate must be re-scoped for a cruising limit cycle.
4. **My recommendation to the owner:** take option 3 plus a **station-keeping requirement written down**, because the drift is a real, physical, emergent property of a sagging actuated chain and hiding it with a wider band does not work. Concretely: decide whether the awake creature is allowed to creep, and if not, spend one increment on an explicit station-keeping mechanism (a sleep-like "hold" that freezes the joint row and the stop projections when input is released) rather than on more torque knobs. That is a design change, so it is the owner's call, not mine.
5. Only after that: Phase 3 (AC-201/202, FA-3/4/5), then Phase 4 (presets, captures, FA-6, tick cost, soak), then Phase 5.

---

## 8. Accepted as-is

- Both arms with full F56 on every arm, all 18000 raw ticks and per-tick comparisons preserved.
- Defaults untouched: committed stop stays 40°, resource SHA unchanged, the 90° band confined to an exited diagnostic duplicate. Verified independently — `core/tuning.tres` and `data/creatures/` are byte-identical to `74c629e`.
- The failed bound-1 report was withheld rather than cited, then re-audited without an epsilon. Correct sequence.
- A and the 0.5° residual check remain **withdrawn/obsolete**; no baseline regeneration; Phase 3 not entered; 8/18 with zero movement.
- `limit_engaged_ticks` reported over both the last 300 **and** all 6000 (5980/6000 in reference) — F64's "every tick" is now a whole-run measurement, not a window claim.

**Acceptance 8/18. Determinism attempt 1 stands as a same-build observation; cross-architecture attempts 0.**
