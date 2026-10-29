# M1 — R26 review: P-B adopted correctly; the brace is REJECTED (it made the creep 48 % worse); two new structural findings

**Target:** PR #3 head `ae7c3ee` (draft, OPEN), commits `8d73597` (adoption) → `c169ded` (baseline) → `ae7c3ee` (closeout) over `fc33aaa`.
**CI:** `40896828176` / `40895082337` — M1 red **only** at the historical Slug600/F47 step; the *original-archive reporting*, *public replay/clock* and *invariant/static* jobs all **green**; the historical sweeps correctly **skipped, not waived**. M0 **516/0** + Android.
**Adopted physics** (verified byte-level): `physics_max_constraint_angular_impulse_rad_s` 6.0 → **30.0**, `motors_joint_stiffness` 2400 → **10.0**, `motors_joint_damping` 55 → **0.5443327361211717**, `motors_max_torque` 1800 → **12.0**. Exactly as ordered.
**Reviewer branch:** `arena/5b72e4ab-clamber`.

---

## 1. Verdict

**The adoption was executed correctly and the stop was honoured perfectly. The brace failed, and it failed in the most informative possible way: it made the creep 48 % worse and reversed the lurch. I reject it and direct that it be reverted, keeping the P-B physics.**

| item | status |
|---|---|
| P-B adoption (k=10, damping, bound 30, cap 12) | **accepted, keep** |
| Brace-off reproduction of 8.550150769956836 | **exact — accepted** |
| Brace impulse conservation (`internal` ≤7.8e-16) | **accepted** |
| **Brace as a mechanic** | **REJECTED — revert** |
| AC-201 | **FAIL, correctly recorded** |
| **F75** the creep is proportional to transmitted torque | new, and the brace *confirms* it |
| **F76** limb-length error is injected by phase ordering | new, cheap to test |
| **F77** FA-5's airborne branch was never constructed | new, a fixture gap not a physics failure |
| F74 | **accepted as a sampled ceiling**; FA-4 is 4× out of reach |
| Rows | **8/18**, movement 0 |

---

## 2. Why the brace is rejected — three measurements, one direction

| | drift | vs brace-off |
|---|---:|---:|
| brace off | 8.55015 px/s | — |
| **brace on** | **12.61773 px/s** | **+47.6 %** |

| gain 0.7, 1 s hold | held | end-of-release |
|---|---:|---:|
| brace off | 0.140760 WU | **+0.224943 WU** (+0.2499 BL) |
| **brace on** | 0.140096 WU | **−0.061297 WU (−0.0681 BL)** |

So the brace: (a) does not slow the idler by one pixel — it speeds it up by half; (b) leaves the lurch during the hold essentially unchanged; and (c) **makes the creature travel backwards over the release window**. A mechanism that increases the thing it was built to remove and inverts the one behaviour it was supposed to preserve has no reading on which it is worth keeping.

**And it explains itself, which is the valuable part.** The brace locks *relative rotation*. Under gravity that rotation is what the joint was using to absorb the sag; locking it forces the whole gravitational load to be transmitted through the constraint into the two bodies and thence into the floor. More transmitted torque → more creep. That is exactly the direction F71/F73 already measured (torque up ⇒ creep up: 8.55 → 11.48 → 12.91) and the brace is the most extreme version of it. **The brace did not fail to engage; it engaged perfectly and thereby made the defect worse.** That is the cleanest possible confirmation of F75, and it is worth more than a success would have been.

**Directive: revert the brace — code, state bit, snapshot field, presentation flag, and its tests — in one commit, and record in `DECISIONS.md` that it was built, measured, and rejected on measurement, with these three numbers.** Keep the F56 brace-internal column in the report as the record that it conserved momentum (≤7.8e-16) while being useless — a mechanism can be correct and still be wrong.

**Keep the P-B physics.** Its two product wins are independent of the brace and permanent: `motors_gain` is alive (worst `|requested|/bound` 0.245, saturation 0/300) and the pose is legal at 12.8° instead of 8.5° *past* the +40° stop. Reverting to the saturated motor would buy 3.93 px/s instead of 8.55 at the cost of a dead feel dial and an illegal pose — a bad trade for a game whose feel is the lurch.

---

## 3. F75 — the complete causal chain, now with its last link

Everything measured across R19–R26 is consistent with exactly one mechanism:

> **A sustained internal load is rectified into translation by the contact/friction solve, at a rate proportional to the load transmitted through the joint, and independent of the static-slip allowance.**

Supporting measurements, all in the record: creep is proportional to applied torque (8.55 → 11.48 → 12.91 as k rises); it is **flat** when the slip allowance is cut 100× (12.9104 / 13.2677 / 13.2403, R25-A); it is a **steady treadmill**, not an oscillation (`vx` spread ≤4.6e-15 over 300 ticks, 0.11 rad of within-tick churn at ~1.2 rad/s, R25-C); it needs **no drive** (gain 0 alone gives 5.39 with the stop engaged); it vanishes **only** when there is no internal torque at all (free hinge / inert: 0.0840); and now **locking the joint harder makes it worse (+47.6 %)**.

That is not a joint problem, not a stop problem, not a motor-authority problem. It is the friction solve turning a static load into a per-tick tangential impulse. **AC-201 cannot pass until that is fixed or AC-201's specification changes**, and no further knob on the motor, the limit or the slip threshold will move it — five independent sweeps have now shown that.

---

## 4. F76 — a new, cheap, structural hypothesis for AC-202

AC-202 fails on **limb segments themselves**, not just feet: Slug motor **0.06736**, Hopper **0.10902**, TwinRoller motor **0.07264** WU against the unchanged **0.05** limit. Even the strict limb-only reading fails, which is why "excluding feet" did not rescue it. And the failures cluster at **landing ticks** — 6, 9, 13, 28, 65, 81 — with a few later.

There is a concrete structural suspect, and it is in the loop order, not in a constant. In `coupled_load_probe._predict_and_project()`, each position iteration runs:

```
distance rows  →  hinge rows  →  _extra_positions()   # angular, then self-contact
```

The angular row's `project_position()` rotates both bodies to correct the joint angle — and **that rotation changes the limb endpoints' positions, i.e. it injects length error** — and it runs **last in the iteration**, so nothing re-converges the distance rows afterwards. Whatever length error the angular projection introduces survives to the end of the tick. At impact the angular row does its largest correction, which is exactly where the AC-202 maxima sit.

**The test (one arm, diagnostic, no tuning):**

1. Report, per tick, the length error of every distance row **after the final angular projection** versus **after the final distance pass**. If the difference is the AC-202 failure, F76 is proven.
2. In the same arm, add a **distance-only final pass** (no constant changes, no tolerance change — one extra projection of the same rows with the same code) and report whether the maximum collapses below 0.05.

If (2) collapses the error, the fix is an ordering change, which is a physics change needing its own decision — but it is a **correctness** change, not a tuning one. If it does not, AC-202 is a structural solver limitation and the gate needs an owner-level conversation about impact transients, which I will not relax unilaterally.

---

## 5. F77 — FA-5 was never given an airborne case, and that is a fixture gap

FA-5 is reported as *incomplete* — correct, and the numbers explain why:

| branch | observed |
|---|---:|
| below threshold (slips) | 15 317 |
| at/above threshold (grips) | 7 |
| two-foot gripping stance | 2 |
| **airborne (never grips)** | **0** |
| N0 no-grip | 4 |

Termination: **7 067 of 7 200** ticks, `termination_reason` **not logged**, last endpoints at `x ≈ −11.998…−11.215` against a fixture bound of `x ∈ [−12, 12]`. The creature **walked to the edge of the fixture** — plausibly into the boundary — and the harness broke on a bad status without recording which one. Two separate defects, and neither is a physics failure:

1. **The airborne branch cannot appear on a creature resting on the floor.** It needs a fixture that drops the creature from a height, or launches it — a *designed test case*, not a lucky observation. Author it explicitly: three cases (drop onto a foot, launch from the ledge, and a mid-air sample) so `airborne > 0` is guaranteed by construction, and the gate is a **pass** only when all four branches have coverage.
2. **`termination_reason` must be logged**, always, with the failing tick and status. An unlogged exit from a gate harness is an unmeasured gate; this is the second time this milestone has been unable to say *why* a run ended (R24's bound-1 audit had the same shape, but there it was caught before reporting).

Also: `at_or_above` = 7 samples is thin for a "grips" branch. Report the distribution of `N` against the 40 % threshold and state how many independent *grip events* (not samples) each branch contains, so a 7-sample branch is not mistaken for a demonstrated behaviour.

---

## 6. F74 — accepted as a sampled ceiling; FA-4 is out of reach and I will not force it

Best tested held displacement **0.26910 BL** (gain 0.7, 5 s hold); best end-of-release **0.13690 BL** (gain 1.0, 5 s). Against FA-4's **1.00 BL**, the honest reading is: *within the current dial ranges and hold durations, a single L-hold produces at most ~27 % of one body length.*

Your scoping is correct and I am adopting it as the record: this is a **sampled ceiling over 0.7/1.0 gain and 1 s/5 s holds, not a global maximum over unlimited hold time**. And your warning that idle translation must not be relabelled as input effect is exactly right — at a 12.6 px/s idle creep, a 5 s "hold" accumulates 0.42 BL of *drift*, which would swamp a real lurch. **Until the creep is fixed, no lurch measurement is trustworthy**, which is a further reason F75 is now the critical path.

---

## 7. Baseline and provenance — accepted

- Regenerated **on the adoption commit** under an explicit baseline/provenance-only overlay, with the strict replay/clock rerun passing against it on that same commit, then matching the committed baseline in both push and PR checks. That is the correct order.
- Physics has not changed since `8d73597` — I verified `core/tuning.tres` is identical between `8d73597` and `ae7c3ee`, and that the only `core/` delta from `fc33aaa` is the adopted four lines plus the brace implementation.
- The shallow-checkout static-test fix is legitimate: it changed no physics and no expected resource bytes.

**One consequence to state in the closeout:** the committed baseline is now the **P-B** baseline. If the brace revert and the F76 ordering test change physics, the baseline changes again, and each regeneration must carry its own provenance line. Baselines are cheap; unexplained baselines are not.

---

## 8. The owner decision this now requires — and it is the one I pre-registered

R25 pre-registered this stop: *if drift with the brace is above 0.3 px/s, the remaining choices are a contact-model review (larger scope, new owner decision) or accepting the creep with an owner-authored AC-201 number.* The condition has been met by measurement, so I will not decide it alone. The fork:

**Option 1 — fix the rectifier (≈2 increments).** One bounded diagnostic (friction-coefficient sweep 0.9 → 0.3/1.8/3.6 at fixed torque, plus the F76 ordering test), then the actual fix in the friction/contact solve. Risk: it touches the most feel-sensitive code in the game; every preset's landing, walking and grip behaviour depends on it; and AC-202/F76 needs work in the same area anyway.

**Option 2 — accept the creep, author AC-201 (≈1 increment).** Keep 8.55 px/s (or revert to 3.93 by also reverting P-B), replace AC-201's "settles and sleeps within 4 s" with an owner-authored "no net displacement over N seconds" number, and re-scope sleep for a cruising body. Cheaper, ships sooner, and the creep is *invisible* to a player who is holding input most of the time — but an idle creature slides 128 px in 10 s at 150 px/WU, which is roughly one screen width per 20 s.

**Option 3 — bounded then decided (my recommendation).** Spend **one** increment on the two cheap diagnostics only (friction proportionality + F76 ordering), with a hard rule: if neither exposes a fixable cause, take Option 2 immediately. This buys information without an open-ended commitment, and it is the last time this phenomenon gets an increment.

Either way, **AC-202 and FA-5's fixture gaps (F77) are independent of this choice and should proceed in parallel** — FA-5's airborne fixture in particular is pure test authoring with no physics risk.

---

## 9. What I am directing right now, without waiting

1. **Revert the brace** (code + state bit + snapshot field + presentation flag + its tests) in one commit; keep the four tuning lines; record the rejection with the three numbers above.
2. **Author FA-5's airborne fixture** (F77) and log `termination_reason` unconditionally. Re-run FA-5 only after the fixture guarantees all four branches.
3. **Run the F76 ordering test** — the after-angular vs after-distance length error, plus one extra distance-only final pass as a diagnostic duplicate.
4. **Do not** re-run the brace, touch the motor/limit/slip values, or widen anything. Matrix stays **8/18**.

**Acceptance 8/18. Determinism attempt 1 stands as a same-build observation; cross-architecture attempts 0.**

---

## 10. Owner decision taken (post-review): **Option 3 — bounded diagnostic, then decide**

The owner selected the bounded path. Recorded here as the binding instruction, so the scope cannot drift.

**This is the last increment this phenomenon receives.** Two diagnostics, both cheap, both pre-registered; then a decision is taken *whatever the result*, on the evidence in hand.

**D1 — friction proportionality (diagnostic duplicates, defaults untouched).** At the adopted P-B physics, idle zero-input, sweep the floor friction coefficient `physics_grip_friction` `0.9 → 0.3 / 0.9 / 1.8 / 3.6`. Report drift and thrust for each.
- If drift scales roughly with the coefficient, the tangential impulse is being produced *by the friction solve itself* — F75 confirmed at the mechanism level, and the fix has a location.
- If drift is flat in the coefficient, friction magnitude is not the carrier and the rectifier is upstream (normal impulse accumulation or the position-projection path), which is a different and larger fix.
- Do **not** adopt any value. The committed 0.9 stays.

**D2 — F76 phase ordering.** Per tick, report the worst distance-row length error measured (a) after the final angular projection and (b) after the final distance pass; then one diagnostic arm with a **distance-only final pass** added (same code, same tolerance, no constant changed) and report whether the 7200-tick maximum falls below 0.05 WU.
- If (a) ≫ (b) and the extra pass collapses the error, AC-202's failure is an **ordering defect** with a correctness fix.
- If the error is unchanged, AC-202 is a structural solver limitation and joins AC-201 in the owner conversation.

**Then the decision, with no further measurement:**
- If D1 **and** D2 both show a located, correctness-shaped cause → one fixed increment to implement both, then AC-201 + AC-202 re-run.
- If **either** is inconclusive → take Option 2: accept the creep, the owner authors AC-201's number, and AC-202 is reported honestly as failing with its measured maximum.
- Under no circumstances: no further knob sweeps, no re-running the brace, no widening 0.05, no new slip/stiffness/damping values, no epsilon.

**In parallel, unconditionally:** revert the brace; author FA-5's airborne fixture and log `termination_reason`; keep the matrix at 8/18 until a gate actually passes.
