# M1 — R25 review and PACKAGE DECISION: adopt **P-B at k = 10**, with a joint-hold brace

**Target:** PR #3 head `fc33aaa` (draft, OPEN), commits `8110688` + `fc33aaa` over `7d48ba0`.
**CI:** `40890281324` / `40890293594` — M1 red **only** at the historical Slug600/F47 step, not waived; M0 `40890281543` / `40890293796` **516/0** + Android. Local: **190** Python controls pass.
**Diff:** 14 files, and **no `core/` changes at all** — the only `data/` change is the provisional FA-6 fixture. Physics, tuning and creature bytes untouched; every candidate lived in a process-local duplicate. Verified independently.
**Reviewer branch:** `arena/5b72e4ab-clamber`.

---

## 1. Verdict of round A/B/C

**All four runs accepted. Two of my hypotheses die, one of my claims was stopped by your measurement before it could mislead anyone, and the round produced the fact that decides the package.**

| item | my claim | outcome |
|---|---|---|
| **A** static-slip is the lever | predicted drift would scale with the allowance | **FALSIFIED** — 100× reduction: 12.9104 → 13.2677 → 13.2403 |
| **B** committed creature lurches ~1 body length | feared it was "the one behaviour that works" | **FALSIFIED** — held **0.0291 BL**, end-of-release **0.1457 BL** |
| **C** joint frozen during the tick (F72) | offered as the mechanism | **WITHDRAWN** — 0.11 rad of within-tick motion at 1.19–1.27 rad/s |
| **F71** `A − B/k` asymptote | "a rigid joint still drifts at 14 px/s" | **DOWNGRADED** to a 3-point empirical trend; asymptote unsupported |
| **F73** "stiffer is better for drift, worse for lurch" | framed as a trade-off | **WRONG — there is no trade-off**: k=10 wins *both* |

Details worth keeping:

**A.** Three cells, only the allowance changed: `0.15 → 12.9104`, `0.015 → 13.2677`, `0.0015 → 13.2403`. A 100× reduction did nothing; the second and third agree to 0.2 %, so the response is flat, not merely slow. The conditional allowances you published for 0.3 px/s (`0.003486 / 0.0003392 / 0.00003399 WU/s`) are correctly labelled **unsupported extrapolations** — do not use them, and note that the mapping is not even monotone, which is exactly why extrapolating was a mistake.

**B.** Held `0.02623 WU` on a 0.90 WU chain = **0.0291 body lengths**; end-of-release `0.13115 WU` = **0.1457**. The committed creature does **not** lurch one body length either, so my reason for fearing P-B — "it would destroy the one behaviour that works" — is void. Nothing works yet; that is a cleaner position than I thought.

**C.** This one matters most. `last300_com_vx_range` gives a spread of **4.6e-15 / 7.7e-16 / 3.5e-15 WU/s** across three candidates — the velocity is constant to machine precision over 300 ticks — while the drive-time `q` repeats to 1e-14 and the **within-tick sampled `q` moves 0.1093–0.1116 rad at 1.19–1.27 rad/s**. So this is not a limit cycle and not a frozen joint: it is a **steady treadmill**, the joint churning ~0.11 rad inside every tick and landing back on the same phase, with the contact/friction solve turning that churn into constant translation. My F72 was a sampling error and I withdraw it.

**F73 corrected.** Drift rises with stiffness (8.55 → 11.48 → 12.91) and lurch *falls* with stiffness (0.156 → 0.103 → 0.030 BL). **k = 10 is best on both axes.** There is no trade-off to arbitrate — the softest candidate dominates, which removes the only reason I gave for hesitating between candidates.

---

## 2. THE DECISION: P-B, at k = 10, with a joint-hold brace

I hold delegated authority for this and I am spending it now. **P-B**, with the softest candidate, plus a brace. Reasons, in order of weight:

1. **k = 10 dominates** (above) — no trade-off means no reason to take a stiffer value.
2. **P-B is the only package where the gain dial is alive.** Worst `|requested|/bound` 0.245, saturation 0/300, zero torque and speed clipping. A climbing game's entire feel is the lurch, and in P-A that dial is inert. This is the product argument and it is decisive.
3. **P-B fixes the pose.** 12.79° vs the committed 8.5° *past* its own stop. The authored silhouette is the thing players recognise; a creature permanently 8.5° over its limit is a bug wearing a tuning hat.
4. **P-B's lurch is 1.7× the committed one** (0.2518 vs 0.1457 BL end-of-release) — nearer FA-4, not further.
5. Its one disadvantage — idle drift 8.55 vs 3.93 px/s — **is removed by the brace**, which we must build in either package.

**The honest cost:** P-B changes committed physics for the first time in this milestone, so it needs a DECISIONS entry, a regenerated baseline with provenance, and a re-run of the public replay/clock job on the solver-changing commit. If the brace does **not** deliver, P-B leaves us at 8.55 px/s instead of 3.93 — that is the risk, and it is why the brace has its own stop condition below.

---

## 3. The brace: a joint hold, not a world pin

The measured cause is churn *inside the joint*, so the brace must act there. **On input release, the angular row becomes a two-sided constraint that holds the joint's relative rotation at its release angle.**

Why this form and not the alternatives:

- **Not a world-space pin.** Pinning the body would manufacture support out of nothing when airborne — rejected outright.
- **Not velocity zeroing.** That is the sleep predicate, and sleep already exists; re-using it would make AC-201 true by lying.
- **Not more stiffness.** Measured: stiffness ↑ ⇒ drift ↑ (8.55 → 12.91), so a stiff lock is the *worst* available brace.
- **A relative-rotation hold is momentum-conserving by construction**: equal-and-opposite impulses on parent and child, so its contribution to `internal_*` in the F56 ledger is exactly zero and the complete balance must keep closing. It holds the creature's **shape**, not its height, so airborne behaviour is unaffected and it cannot hold the creature up against gravity.

Implementation requirements:

- **No new tuning constant.** It is a constraint state (+1 bit in the solver state), not a feel value, so it never becomes a knob someone tunes to pass a gate.
- **Tuning-free hold strength**: the row blocks relative rotation exactly, like `block_velocity` does at a limit, rather than adding a spring.
- **Full re-arm on any input**, instant release, no hysteresis, and it must not interact with sleep (a sleeping creature is already velocity-zeroed; the hold must be idempotent with it).
- **Inside `snapshot()` / `state_hash()` / `restore()`**, with the same malformed-state rejection the sleep predicate already has.
- **Visible**: a documented state flag plus a distinct presentation in Phase 4 captures, so a player can see the creature has planted itself. If it is invisible, it is a silent freeze with extra steps and I will reject it.

---

## 4. Acceptance and stop conditions for the adoption increment

**Adopt** into `core/tuning.tres`: `physics_max_constraint_angular_impulse_rad_s` 6.0 → **30**, `motors_joint_stiffness` 2400 → **10**, `motors_joint_damping` 55 → **0.544333** (the derived value, with the formula in the DECISIONS entry), `motors_max_torque` 1800 → **12**. With a `DECISIONS.md` entry naming me as the decision source, the derivation, and the rejected alternatives.

Then measure, in one increment:

1. **Brace on, zero input, from spawn.** Acceptance is **the unmodified F52 predicate firing within 4 s** — not a window mean, not a counterfactual. The gate is AC-201's own text; the 0.3 px/s line is a diagnostic, not the criterion.
2. **Brace off, zero input** — must reproduce **8.55015 px/s** exactly. If it does not, the adoption changed something it should not have.
3. **Brace on, L-hold** — the hold must not weaken the lurch. Report held and end-of-release displacement.
4. **F56 complete on every arm**, with the brace's `internal_*` sums still zero.
5. **Baseline regeneration** with provenance, then the public replay/clock job **on this commit** (it has not run since `d76b88e`), reproducing the new baseline exactly.
6. **Matrix stays 8/18.** AC-201 is not `PASS` until the predicate fires in CI on the adopted defaults. A dependency on a designed hold mechanic must be written into the DECISIONS entry, not hidden.

**Stop and report — do not improvise — if:**

- drift with the brace is **> 0.3 px/s**, or the F52 predicate does not fire within 4 s. Then the remaining choices are a contact-model review (a much larger scope, and a new owner decision) or accepting the creep with an owner-authored AC-201 number. **Do not** raise the hold strength, widen the sleep threshold, add an epsilon, or touch the slip allowance.
- brace-off does not reproduce 8.55015 exactly.
- the brace requires a new tuning constant, or cannot be made to conserve momentum.

---

## 5. F74 — FA-4 is 4–7× out of reach in *both* packages, and I will not let it be forced

| configuration | held | end-of-release |
|---|---:|---:|
| committed (P-A) | 0.0291 BL | 0.1457 BL |
| k = 20 | 0.1025 BL | 0.1897 BL |
| k = 40 | 0.0296 BL | 0.1123 BL |
| **k = 10 (chosen)** | **0.1564 BL** | **0.2518 BL** |
| **FA-4 target** | **1.00 BL** | **1.00 BL** |

The best measured configuration is **4× short**. Since FA-4's number is the owner's and I will not relax it, the increment must also answer, **within the existing dial ranges only**: what is the maximum achievable lurch at `motors_gain = 1.0` (versus the default 0.7), and does a longer hold help? If the ceiling is still well short of one body length, **stop and report** — widening `motors_contraction_deg` or the gain range to reach a gate is precisely the tuning-to-pass that this milestone forbids. It may well be that the GDD's "one body length" was written for a different body scale; if so, that is a specification question for the owner, not a number for me to bend.

---

## 6. What runs in parallel, starting now

**AC-202** (≤0.05 WU limb-length error over 7200 ticks) and **FA-5** (four grip branches on Hopper) have been independent of every open question for three rounds and are still at `NOT RUN`. They start **now**, in parallel, with separate evidence, and are reported separately so a brace failure cannot contaminate them.

---

## 7. Row status

**8/18 measured, movement 0.** After the adoption increment the expectation is **9/18** (AC-201) and **11/18** with AC-202 + FA-5. FA-4, FA-3, AC-204, presets/captures, tick cost, §10.6, FA-6 stay `NOT RUN` until their own phases.

M1 has spent eight rounds on one phenomenon. That was justified — it produced a correct mechanism statement and a live dial — and it stops here: after this increment the milestone moves forward on gates, not on this question.
