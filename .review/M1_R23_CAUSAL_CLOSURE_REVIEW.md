# M1 — R23 review: the 2×2 is complete and the investigation is closed

**Target:** PR #3 head `d76b88e` (draft, OPEN), commits `dff8018` + `d76b88e` over `63cb024`.
**CI:** `40880532917` — the single authorised cell **PASS** (plus 6000 observer-equivalence checks); invariant/static **PASS**; the six historical jobs **skipped**, not waived. Local: **180** Python controls pass, matrix guard exit 0.
**Diff:** 9 files, +615/−3, and **nothing under `core/` or `data/`** — the solver, tuning resource, creature presets and the committed 40° stop are byte-identical to `63cb024`. The 90° band lived only in a process-local duplicate, exactly as ordered.
**Reviewer branch:** `arena/5b72e4ab-clamber`.

---

## 1. Verdict

**The missing cell returned the free-hinge baseline to 1.1e-14 px/s, the 2×2 is now complete, and the causal question is answered.** There is no inert-row solver defect. The drift requires *either* an applied joint impulse *or* stop projection; **each alone is sufficient, neither is necessary**, and together they **interfere partially** — the combined case sits *between* the two, not below both.

| Item | Status |
|---|---|
| Inert cell (gain 0 + 90°) | **ACCEPTED** — 0.08403595917824 vs baseline 0.08403595917823, Δ **1.13e-14 px/s** |
| All 6000 ticks requested/applied = 0, no engagement/projection/block | **verified in the evidence** |
| Three-column separation (drive-time / correction / endpoint WU) | **verified, all 0** |
| F56 complete on this arm | **PASS**, y residual 3.88e-14 |
| Investigation | **CLOSED** — no further arms |
| F69 | new — the causal statement (each sufficient, neither necessary, interacting) |
| F70 | new caveat — the inert result has only **0.44°** of band headroom |
| My R22 "matches to better than 1 %" | **corrected to 2 %** — see §5 |
| Rows | **8/18**, movement 0 |

---

## 2. The completed 2×2

Last-300 drift, 150 px/WU. Free-hinge floor (no angular row at all): **0.084036**.

| | stop **engaged** (+40° stop) | stop **not engaged** (+90° band) |
|---|---|---|
| **drive applied** | **3.9345** (reference) | **2.9500** |
| **drive zero** | **5.3874** (gain 0) | **0.08404** (inert) |

Read as a causal table:

| configuration | drift | × baseline | what it isolates |
|---|---:|---:|---|
| neither mechanism | **0.08404** | 1.0× | the floor: hinge + distance + contact only |
| drive only | 2.9500 | 35.1× | a saturated joint impulse is sufficient on its own |
| stop only | 5.3874 | 64.1× | per-tick stop projection is sufficient on its own |
| both | 3.9345 | 46.8× | **between the two**: 27 % below stop-only, 33 % above drive-only — partial interference, not cancellation of both |

The last row is the surprising one and it is why every single-factor prediction I made failed. The ordering is **2.95 < 3.93 < 5.39**: adding the stop to the drive *raises* drift by 33 %, while adding the drive to the stop *lowers* it by 27 %. The two mechanisms do not add, and they do **not** simply cancel either — they **interfere**, and the interaction has a sign that depends on which one you start from. A 3 % brake difference produced 25 % drift change (R22) because the response is set by the limit cycle's phase, not by any coefficient.

**And critically: with both mechanisms provably off, the actuated creature reproduces the free-hinge baseline to 1.1e-14 px/s.** That is the result that matters most for trust in the solver: an `AngularJoint` that applies no impulse and projects nothing is **exactly** a coincident hinge. No hidden coupling, no plumbing leak. The baseline-return branch is supported; the inert-row defect branch is dead.

---

## 3. F69 — the causal statement, in one paragraph

*The Slug's zero-input drift is produced by two independent sufficient mechanisms — the saturated angular joint impulse, and per-tick stop projection from a sag that sits past the authored +40° limit — and by neither of them necessarily. Removing either alone leaves 35–64× the free-hinge floor; removing both restores it exactly. The combined case is 27 % lower than the stop-only case, so the mechanisms interact, and no scalar (applied impulse, saturation, engagement, projection magnitude) orders the four arms monotonically. Therefore no torque coefficient can be tuned to reach the floor: the choice is architectural, not parametric.*

That statement is the deliverable of R19–R23. It is why I withdraw, in order: the spring-as-source premise (R19 void), the saturated-impulse-is-the-propulsor claim (R20, falsified by gain 0), the drive-is-a-brake mechanism (R21/R22, withdrawn), and the necessary-stop mechanism (F64, falsified by the 90° arm).

---

## 4. F70 — the inert cell has 0.44° of headroom, and that is worth recording

`drive_q_rad_range` in the inert arm is `[1.563079699374753, 1.5630796993747635]` — **89.558°**, i.e. **0.442°** inside the 90° band, for the whole window. Compare the other arms' drive-time `q`:

| arm | `q` range (deg) | note |
|---|---|---|
| reference (stop 40°) | 48.07 – 48.59 | held ~8.5° past the stop by the clamp |
| bound 1.0 (stop 40°) | 49.75 – 49.76 | |
| wide 90°, drive on | 51.92 – 54.05 | free pose with the drive pulling |
| **inert (drive 0, band 90°)** | **89.558** | sags to the very edge of the band |

Two consequences. First, the "no engagement" result was obtained at the edge of validity: a 91° band would have passed, an 89° band would have engaged and the arm would have measured ~3 px/s instead of 0.084. Record the headroom with the result so nobody later re-runs it at 85° and gets a contradictory answer. Second, it quantifies the sag: **with nothing to lean on, the joint hangs at 89.6°— nearly a right angle — from the authored rest pose.** That is the physical fact behind F65, and it is a design input, not a solver artefact.

---

## 5. Correction to my own R22 text

I wrote that F58's identity matched every arm "to better than 1 %". That was wrong on the strict reading. The identity predicts **mean completed velocity**; the reported **positional drift** sits about **2.0 %** below it in every arm (reference: 4.0148 predicted vs 3.9345 measured; inert: 0.08575 vs 0.08404). So: identity → mean velocity, agreement <1 %; mean velocity → positional drift, gap ≈2 % (the cycle's phase). Both numbers are fine and the accounting still closes, but I should not have compressed them into one claim. Recording it because I have been asking you to be precise about exactly this kind of thing.

---

## 6. The skipped-job protocol is acceptable, with one condition

You used a dedicated manual run so the historical sweeps did not replay, and marked the skipped jobs **unpassed, not waived**. That is correct — with the condition that the head really is solver-neutral, which I verified independently: no `core/` and no `data/` changes, tuning and creature bytes identical, the only additions being a report script, a runner and evidence.

The one consequence to state plainly: **the public-Sim replay/clock job did not run on `d76b88e`.** It passed on `63cb024` and on `74c629e`, and nothing in this head can affect it, but the last measured replay is one commit behind head. When the next solver-changing commit lands, those jobs must run again — and the committed baseline must then be reproduced or regenerated with provenance.

---

## 7. Where M1 actually stands

**8/18 runtime rows. Ten remain: AC-201, AC-202, AC-204, three presets + captures, tick cost, §10.6, FA-3, FA-4, FA-5, FA-6.**

Everything remaining now sits behind two owner decisions (next document: `.review/M1_D08_OWNER_DECISION.md`), because:

- **AC-201 cannot pass with the current constants** — measured, in four configurations, and it is not a band problem.
- **FA-4's lurch** would be measuring the constraint clamp, not the motor (F61: 472–3080× saturated in every arm).
- **FA-3's "zero sleep-breaking contacts"** is evaluated on a creature that never sleeps while awake (F59/F68).
- **FA-5 (grip band)** and **AC-202 (stretch)** are the only two of the ten that are genuinely independent of this decision, and they can be built now.
- **FA-6** needs a chunk that does not exist (D06); **tick cost** needs the owner's device (D07); **§10.6** needs a second architecture.

So the honest sequence is: two decisions → one architectural increment → then ten measured rows across Phases 3–5. The investigation was not wasted; it produced the number the decisions need.
