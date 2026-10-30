# M1 — R29b ruling: D0's label is wrong (it sits ON the slop), and a parse error is not a measurement

**Target:** PR #3 head **`534f5f5`**. **Reviewer:** `arena/5b72e4ab-clamber`.
**Scope:** two corrections to the record, one authorisation, and exactly what to run next.

---

## 1. Verified myself

| claim | check | result |
|---|---|---|
| head `534f5f5` | `git ls-remote` | ✓ |
| production core untouched | `git diff 4796ec6 534f5f5 -- core/` | **empty** ✓ |
| tuning byte-identical | sha256 | `5f4d0d06…0666` ✓ |
| controls **232/0** | **I ran `scripts/review_checks.sh` at `534f5f5`** | **232 ran, 0 failures** ✓ |
| D1–D5 failed to load | `tests/fixtures/m1_r29_raw/D{1..5}-engine.log` | `Parse Error: Member "_checked" is not a function` at `test_r29.gd:111` ✓ — **zero ticks** |
| fix is a rename | `git show 2041793 -- tests/sim/test_r29.gd` | `_checked` → `_checked_step`, 4 call sites, **no logic change** ✓ |
| D0 evidence survives without artifacts | `git ls-tree 534f5f5 tests/fixtures/m1_r29_raw/` | three `.jsonl.gz` + logs **committed to the repo** ✓ |
| D2 implementation matches the ruling | `test_r29.gd:188-208` | `bodies: 30`, "ten independent real production Slugs … not one coupled 30 body creature" ✓ |
| FA-6 handles the absent tutorial chunk honestly | `test_r29.gd:337` | success counts `NOT RUN`, "never invented" ✓ |

This session behaved correctly on the two things that matter most: **it did not rerun a closed arm**, and **it
did not invent a number for a gate it could not run**. Both refusals were the right instinct. One of them now
needs an exception (§3).

---

## 2. Correction — D0 is **AT** the slop, not "PRE-EXISTING". My rule was defective; the label must change.

My attribution table said *"≥ 0.02 → PRE-EXISTING"*, and the control measured:

```
0.020000000000000823   vs   slop 0.02
excess      8.23e-16 absolute
            4.12e-14 relative      ← floating-point noise at the slop boundary
```

**That is not penetration above the allowance. That is the solver resting exactly on
`physics_contact_slop_wu` and reporting the roundoff of `radius − distance`.** The agent's evidence JSON
records it as `verdict: FAIL` with `attribution: penetration is PRE-EXISTING … F79 stands as its own defect`.
Both are wrong, and they are wrong in the one direction that matters: **a "FAIL / PRE-EXISTING" stamp on the
control is exactly the sentence a future reader could use to say "production already fails penetration, so the
projection was never the cause".**

The correct reading:

| preset | control | adopted | **adopted ÷ control** | excess over slop |
|---|---:|---:|---:|---:|
| Slug | 0.020000000000000823 | 0.07028201067739755 | **3.514×** | 2.51 × slop |
| Hopper | 0.020000000000000823 | 0.0933999293597247 | **4.670×** | 3.67 × slop |
| TwinRoller | 0.020000000000000823 | 0.05075245867956493 | **2.538×** | 1.54 × slop |

**Mandatory relabel:**
- D0 rows: `verdict: CONTROL — AT SLOP (0.02 + 4.1e-14 relative)`, **not** `FAIL`.
- `attribution:` → **`"the reprojection multiplies penetration 2.5–4.7× above the designed slop; AC-202 as
  adopted is dead on the evidence"`**.
- **Delete "F79 stands as its own defect"** — **F79 is WITHDRAWN** (I withdrew it in the previous ruling;
  there is no pre-existing penetration defect to stand).
- Fix the rule text: compare against the slop **with a roundoff band** (`> 0.02 × (1 + 1e-9)`), never a bare `≥`.

**Credit where due:** the agent's own caveat sentence — *"Pre-existing penetration is demonstrated; this does
not establish that reprojection cannot increase its maximum"* — was the substantively correct conclusion. The
label contradicted it. Keep the sentence, kill the label.

**My error, 19th:** I wrote a comparison rule against a floating-point boundary with no roundoff band, and it
produced a label that inverts the finding.

---

## 3. Ruling — **"one invocation per arm" governs executed measurements, not launch failures**

The agent declined to rerun D1–D5 because of the one-shot rule. **That reading is too strict and it would cost
the milestone.**

The rule exists to stop a *number* being regenerated until it looks better. A script that **fails to parse and
executes zero ticks produces no number** — there is nothing to p-hack, nothing to cherry-pick, and no
measurement to distort. `NOT RUN` is the correct record **for that launch**; it is not a reason to abandon five
gates over a variable name.

**Authorised: one execution of the corrected D1–D5 arms**, because:
1. zero ticks were executed in the failed launch — this is a **launch failure**, not a result;
2. the fix is a pure rename, verified as such, with no logic change;
3. no number from these arms has ever been observed by anyone.

**Conditions (all mandatory):**
- Record the failed launch as **`L1 — launch incident (zero ticks)`** with its logs; keep them committed.
- Launch under a **new** marker `[R29-once-2]` pinned to the **corrected** head, one execution per arm.
- The compile-only validation must **not** be presented as evidence of anything except compile success.
- **If any arm fails again, record `NOT RUN` and stop** — a second failure is a real signal, not bad luck.

---

## 4. Exactly what to run (values already ruled; nothing new to decide)

| arm | what | must report |
|---|---|---|
| **D1** | 3 presets × 600 ticks, one documented L/R log, one seed; per-tick capture + script-rendered plot + manifest, **committed ≤ 5 MB** | pairwise trace-hash inequality **and** mean pairwise COM separation in WU + final poses. If distinctness needs a number, **report it, do not author a threshold** |
| **D2** | **Hopper alone (8 parts) — mandatory real row**; **ten independent production Slugs = 30 capsules** as a labelled aggregate; optional 14-part test-only creature (legal per `physics_post_part_budget`) | bodies, **actual constraint count**, median + P95, hardware string, per-solver and aggregate. `physics_tick_hz` fixed 60. **Do not apply 3.0 ms as pass/fail on any proxy**; row = `NOT MEASURABLE AS SPECIFIED` + owner question. Reference-device leg = `NOT MEASURED (D07)` |
| **D3** | 10 000 ticks × 100 repeats, all 100 hashes logged | identical yes/no; steps 2–3 stay `NOT RUN`; **do not re-run or re-present the soak as determinism** |
| **D4** | Slug, zero input: settle+sleep ≤ 4 s; one L-hold lurch | numbers in **WU, BL and px**; sleep expected to fail — record it; **1.00 BL spec-vs-scale stays owner's** |
| **D5** | 10 identical runs on a flat plane, tutorial chunk absent | ten outcomes; **variance source = NONE** stated plainly; if the gate is insensitive by construction, say so — that is a finding, not a failure |

---

## 5. State of play after this ruling

- **D0: closed.** Control at slop; adoption multiplied penetration 2.5–4.7×; **AC-202 FAILED, dead, not to be
  re-adopted**; revisited only inside M1.1 after the rectifier fix.
- **D1–D5: authorised for one execution.** These are the last runtime gates.
- **D7: 232/0 controls, M0 516/0, core diff empty** — verified by me, not taken on trust.
- **M0 android still red on the artifact quota.** The owner's storage clear has not taken effect
  (recalculation is 6–12 h). This is infrastructure, not code, and must not be reported as a gate failure.
- After D1–D5 land, **P3**: the 18-row verdict, INV closure, five-fakes, PR ready. **No P3 work before then.**

**Current honest ceiling: 13/18 passing (16/18 carrying a measured verdict), with AC-201, AC-202 and FA-4
failing on one named cause, FA-3 uncredited, and tick cost `NOT MEASURABLE AS SPECIFIED`.**
