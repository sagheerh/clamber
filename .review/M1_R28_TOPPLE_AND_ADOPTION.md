# M1 — R28 review: 201a caught a real topple; AC-202 adopted; FA-3 is vacuous and cannot be credited

**Target:** PR #3 head `fb890fd` (draft, OPEN), commits `2cf2c93` → `93c17d6` → `fb890fd` over `0c2fc2a`.
**CI:** `40963830891` / `40963825251` — the only failure is the historical Slug600/F47 step; *public replay/clock*, *invariant/static* green; all R27 physical jobs correctly **skipped** on the publication head (pinned to the measured source `2cf2c93`, one invocation per mode). M0 `40963830921` / `40963825268` **516/0** + Android.
**Verified by me:** `core/tuning.tres` is byte-identical to `0c2fc2a` — the four P-B values are untouched. Local: **218** controls pass.
**Reviewer branch:** `arena/5b72e4ab-clamber`.

---

## 1. Verdict

| item | measured | my ruling |
|---|---|---|
| **AC-201a** | attitude change **35.344°** vs 15° | **FAILED — upheld.** And it is the round's most valuable result: the creature **rotates monotonically at 3.53°/s while idling** |
| **AC-201b** | 96.904 px vs 135 px, 1.393× | **PASS.** My 1.58× reference was an invalid extrapolation — corrected in §3 |
| **AC-201s** | zero sleeping ticks | **FAILED — upheld**, M1.1 carry-over |
| **AC-202** | completed-tick limb **5.0e-16** WU vs 0.05 | **ADOPT**, with three conditions (§4) |
| **AC-204** | 200/200 runs, 1.44 M ticks, zero nonfinite | **PASS**, with **F78** (seed diversity is nominal) |
| **FA-3** | zero sleep-breaking contacts, **zero sleeping ticks** | **NOT CREDITED — vacuous** (§5). Differs from your ledger |
| **FA-5** | four branches, 236 airborne samples | **PASS** retained with the 2–4 tick caveat |
| rows | — | **10 credited now, 11 with AC-202 adopted** |

---

## 2. AC-201a — the failure is real, and my threshold was the weak part

The measurement is unambiguous: `max_attitude_change = peak_to_peak = 35.344°`, with `min(angles) ≈ 0`. That equality is the tell — the signed angle starts at zero and grows in **one direction**. The creature is not rocking; it is **rotating at a constant 3.534°/s while translating at 9.69 px/s**.

| threshold | time to reach it |
|---|---|
| 15° (mine) | **4.24 s** |
| 90° | 25.5 s |
| 180° (on its back) | **50.9 s** |

**I have to own two errors here.** A 15° number with a 10 s window was doubly underived: I gave a derivation for 201b and none for 201a, and the same creature would have **passed** at 14.1° if I had written the window as 4 s instead of 10 s. A gate whose verdict flips on an arbitrary window length is exactly the kind of accident I have spent this milestone refusing.

But the finding does not depend on my number: **monotone rotation at 3.5°/s is a defect at any threshold**, and it is the thing 201b could not see. A creature "parked" in displacement while slowly toppling onto its back in 51 s is not parked. The split earned its keep in its first run.

**I am not changing 15°, and neither should you.** Required instead — characterisation, from the harness you already have:

1. Report the **rate** in °/s and the **time-to-90°**, not just the 10 s excursion, so the future owner decision has a physical quantity instead of a magic number.
2. Extend one arm to **3600 ticks (60 s)** and report whether the rotation is **monotone** (toppling) or **bounded** (settling into a tipped pose). This is the difference between "the creature falls over" and "the creature rests slightly tilted", and it cannot be inferred from a 10 s window.
3. Record that 201a and 201s are **the same defect** — the contact rectifier that produces the linear creep also produces this rotation. Both move to M1.1 together.

---

## 3. AC-201b — pass accepted, and my reference number was wrong

Measured **0.646024 WU = 96.904 px = 0.7178 body lengths**, limit 0.90 WU, margin **1.393×**. Passing.

My published reference of **85.5 px / 1.58×** was an invalid extrapolation: I multiplied the R26 *last-300 steady* creep (8.55 px/s) by 10 s, but the gate measures **from spawn**, and the spawn window contains a startup transient that the steady mean excludes. The measured effective rate from spawn is **9.69 px/s**. Your field saying the steady reference "is not a substitute for measured from-spawn displacement" is exactly right, and I am the one who needed it said.

Two things the record should carry: the 1.393× margin is **thin**, and the gate flips at a creep of **13.5 px/s** — only 1.58× the current 8.55. If M1.1's contact work reduces the creep this becomes comfortable; if any future change increases it, AC-201b fails. Do not report it as a comfortable pass.

---

## 4. AC-202 — ADOPT, with three conditions

The candidate is not a marginal improvement, it is a categorical one:

| preset | completed-tick articulated-limb max | vs 0.05 limit |
|---|---:|---:|
| Slug | **4.996e-16** | 10¹⁴× below |
| Hopper | **1.832e-15** | 10¹³× below |
| TwinRoller | **1.776e-15** | 10¹³× below |

And the phase table proves the mechanism I asked you to test: `after_contact_pass_0` **0.10553** → `after_diagnostic_final_distance` **4.996e-16**. The contact position pass injects ~0.1 WU of length error and the post-contact reprojection removes all of it. **F76 is confirmed and closed**: the injector was the contact position correction, not the angular ordering I first suspected.

**Adoption is approved.** As a physics change it needs, in one commit:

1. **Baseline regeneration with provenance**, and the public replay/clock job re-run **on the adoption commit**, reproducing the new baseline exactly.
2. **A penetration check.** The appended pass moves bodies to restore link lengths, and moving a body can push a foot into the floor. Report `max penetration depth` after the appended pass over the same 7200 ticks, against `physics_contact_slop_wu = 0.02`. If reprojection trades a length defect for a penetration defect, the adoption is **rejected** — report and stop, do not tune the slop.
3. **Re-measure the idle family on the adopted build** — AC-201a/b/s and the idle drift arm — because physics changed. **Not because I hope it fixes the creep.** It may well: the reprojection partially undoes the positional correction the contact solve injected, and that correction is where the translated displacement comes from. But the measurement is required by the change, not by hope, and a result *either way* is fine — if drift improves, record it; if it does not, record it. Do not tune toward it.

---

## 5. FA-3 — a gate that cannot fail is not a measurement. Not credited.

`sleeping_ticks: 0` in all three presets, `sleep_breaking_contacts: 0`. The criterion is *"zero sleep-breaking contacts in a 600-tick static scene"*, and a sleep-breaking contact is by definition a contact that breaks **sleep**. With the creature never asleep, there is nothing to break, so the count is zero **by construction**. Your own note already says it: *"zero wake events with zero sleep opportunities is not rest/sustained sleep/grip."*

I am converting that flag into a **non-credit**. This is where my ledger differs from yours (11 production / 12 including the candidate): FA-3 is **UNMEASURABLE AS SPECIFIED — blocked by AC-201s**, and it does not count toward either total.

What would make it non-vacuous, for M1.1: either (a) measure it on a creature that actually sleeps, once 201s passes; or (b) count **would-be** sleep-breaking transitions against a counterfactual asleep state — i.e. as if the creature were asleep at tick N, would this new grounded contact have woken it? Option (b) is legitimate only if it is written down as a counterfactual with the same discipline you applied to the F52 eligibility traces, and never labelled as sleep. Neither is authorised now; the row stays uncredited.

---

## 6. AC-204 — PASS, with F78 recorded

**200/200 runs, 1 440 000 ticks, zero failed runs, zero recorded non-finite events, 20 verified batches, 200 unique run IDs, seeds checked as `seed_base + run_id`.** The aggregation discipline — only whole batches counted, in-flight runs never guessed — is exactly right, and `determinism_attempt: false` on every batch is correctly *not* claimed as determinism.

**F78, record it:** since R17, `F57` has established that **physics does not consume the RNG**. Two hundred distinct seeds therefore produce **identical trajectories**, and the soak's evidential diversity is **nominal, not realised**. The gate's text is met literally (200 logged runs, zero nonfinite, all verified) and I am crediting it on that basis — but the soak currently proves *one* trajectory is stable, repeated 200 times, not that 200 different states are.

Two consequences: when physics first consumes the RNG, AC-204 **must be re-run**; and if you want real diversity before then, vary something the physics does read — spawn offset, pose, or the tick-indexed input. Note this is the same structural issue I pre-registered for FA-6's ten runs, and you handled FA-6 correctly by making the variance source explicit; AC-204 should get the same treatment.

---

## 7. Where M1 actually stands

**10 credited.** After the AC-202 adoption: **11.**

| state | rows |
|---|---|
| **PASS (11 after adoption)** | Engine, A9.2, A9.3, A9.4 replay, A9.4 stall, A9.5, A9.7 flip, A9.7 baseline, AC-202, AC-204, FA-5 |
| **FAILED (1)** | **AC-201** — a: topple 3.53°/s; s: never sleeps |
| **NOT CREDITED (1)** | **FA-3** — vacuous under AC-201s |
| **UNMEASURED (5)** | presets + captures, tick cost, §10.6, FA-4, FA-6 |

**Realistic close for M1:** 16 of 18 passing (AC-202, presets/captures, FA-6, §10.6, tick cost all plausible), **AC-201 and FA-4 failing with named causes**, FA-3 blocked-by-201s. That is the honest ceiling while the contact rectifier is unfixed, and it is a good milestone: every gate measured, every failure a number with a mechanism.

**One caution on the two unmeasured gates with no blocker:** *presets + captures* needs capture tooling that has never existed in this repo, and it is the only remaining gate that is *visible output* — everything else is a number. Start it early; it is the one most likely to surprise us.

---

## 8. Directives

1. **Adopt AC-202** per §4, with the penetration check and the post-adoption idle re-measure.
2. **Characterise AC-201a** per §2 — rate, time-to-90°, and monotone-vs-bounded over 3600 ticks. Do not change 15° or the window.
3. **Keep FA-3 uncredited** and record it as blocked-by-AC-201s.
4. **Start presets + captures** and **FA-6's ten-run batch** — neither has a blocker and both are the last unmeasured work that does not depend on M1.1's contact fix.
5. **Nothing else.** The drift phenomenon stays closed; no brace, no sweeps, no tolerance or epsilon changes, no `motors_*` or slip values touched.

**Acceptance 11/18 after the adoption. Determinism attempt 1 stands as a same-build observation; cross-architecture attempts 0.**
