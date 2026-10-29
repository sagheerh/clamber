# M1 — R30: D0 answers the causality question, and D2 is a spec defect, not a workload choice

**Measured source:** `819cefc4ce9b66e6f8725d1ed24694e85e8f5154`, CI run **`40974609556`** (job `measurements`, success).
**Evidence committed at `a3c7cc0`:** `.review/m1_r29_measurement_evidence.json` + `tests/fixtures/m1_r29_raw/*.jsonl.gz`.
**Session-start head:** `4796ec6`. Start facts confirmed by the agent **and checked by me**: tuning
`5f4d0d06…0666`, `core/` diff vs `fb890fd` **EMPTY**, controls **226/0**, M0 **516/0**, engine `4.7.2.stable.official.ed1daf0bf`.

---

## 1. D0 verdict — the reprojection causes the excess. Cleanly.

| preset | **control (production/reverted)** | adopted (R28) | ratio | control worst part | control tick |
|---|---:|---:|---:|---|---:|
| Slug | **0.020000000000000823** | 0.07028201067739755 | 0.285 | head, u=0.00, r=0.1 | 22 |
| Hopper | **0.020000000000000823** | 0.0933999293597247 | 0.214 | head, u=0.00, r=0.1 | 33 |
| TwinRoller | **0.020000000000000823** | 0.05075245867956493 | 0.394 | head, u=0.00, r=0.1 | 15 |

Three independent creatures, three different part layouts, a 7 200-tick run each, and the maximum is
**the same number to eight digits past the slop**: `0.02 + 8.16e-16`. That is not a coincidence and it is not
a clamp in the measurement — I read `tests/sim/test_r29.gd`; `maximum` is a running max of
`max(0, radius − distance)` over every sampled point, with no ceiling.

`0.02 + 1 ulp` is `physics_contact_slop_wu` in float64. **Production penetration is slop-bounded by
construction**: the contact position-correction pass allows exactly the slop and no more. That is a healthy
solver operating at its declared tolerance.

Therefore:

> **Attribution: the appended distance reprojection causes the penetration.** It moves bodies to satisfy
> link lengths *after* the contact pass has finished, and nothing reprojects them back out of the terrain,
> so whatever correction it applies becomes penetration. Production never exceeds its slop; the adopted
> build exceeds it by **2.5× / 4.7× / 3.5×**.

AC-202 as adopted is **dead in its current form**. The owner disposition recorded earlier stands and is now
backed by a mechanism rather than a number: **FAILED for M1, no re-adoption, re-evaluate inside M1.1.**

---

## 2. Two of my own errors, and one finding withdrawn

**My 18th error — I misread the timing.** I argued that worst ticks 6 and 7 (before any input) pointed to a
spawn-settling artefact. The control's worst ticks are **15/22/33** — also the first tenth of a second. Early
ticks are simply where a creature first loads its ground contacts, so *every* build peaks there. **The
discriminator was magnitude, not timing**, and I reached for the wrong one because the timing pattern
supported a story I found plausible.

**My 19th error — my own adoption condition was mis-specified.** I wrote the penetration condition as
"max ≤ 0.02". Production *equals* 0.02 by design, so **the condition as written would have failed the healthy
build too**. A correct condition is *slop-relative* — compare against the control's `0.02 + 1 ulp`, or state
the ratio to control. Two of my three numeric stop conditions in this milestone (this one, and the ≤ 0.005 /
≥ 0.02 attribution bands) were absolute numbers against a quantity that is itself a tolerance. **Where a
solver's residual is defined by a tolerance, gates must be expressed relative to that tolerance, not as
absolute ceilings.**

**F79 is WITHDRAWN as a production defect.** I wrote last round that feet under the floor were "a defect, not
slop tolerance" — that was measured on the **adopted** build only. The control shows production's worst part
is the **head at slop**; no foot ever goes below the floor in production. F79 is therefore **not an
independent defect**; it is the reprojection's signature, and it dies with it. One cause, not two.

---

## 3. What M1.1 needs to know (specification input, no thresholds authored)

The trade is now measured on both sides:

| | length residual | penetration |
|---|---|---|
| production today | **0.1055 / 0.1536 / 0.0618 WU** (AC-202 FAILS) | **0.0200 (slop)** |
| appended reprojection | **~1e-15 WU** (AC-202 passes) | **0.0703 / 0.0934 / 0.0508** |

A post-contact projection can only move the error, never remove it, because the two constraint families are
satisfied at different moments in the tick. M1.1 therefore needs **distance and contact solved together** —
the contact pass inside the same iteration loop as the distance pass, iterating until *both* residuals are
inside their tolerances — not a correction appended after the loop. Recorded as a direction, not a design
mandate: the owner decides M1.1's scope, and no epsilon, iteration count or slop value is authorised here.

---

## 4. **D2 — the ruling: `NOT RUN`, blocked by a spec defect. Do not substitute a workload.**

I verified the agent's structural claim rather than accepting it:

```
core/tuning.tres:  physics_min_valid_parts = 2
                   physics_part_budget    = 10      ← enforced in creature_model.gd:19
                   physics_post_part_budget = 14
presets:           Slug 3, TwinRoller 6, Hopper 8
```

A legal single creature **cannot exceed 10 parts**, and even the post-build cap is **14**. The §10.4 budget
demands **30 bodies / 120 constraints**. **No legal production creature that size can exist**, so the gate
cannot be measured as specified — in M1 or in any later milestone with these caps.

**Verdict for the matrix: `NOT RUN — NOT MEASURABLE AS SPECIFIED`**, blocker: *§10.4 asks for a 30-body
creature; `physics_part_budget` caps production creatures at 10 (14 post-build). Either the budget is
re-expressed at the achievable maximum, or it is a declared headroom target.*

**Neither option you offered is a substitute, and neither is the gate:**

- **Ten Slugs (30 capsules)** measures 10 independent solvers, not one coupled 30-body creature. Constraint
  sharing, ordering and contact counts are all different. It is the **best proxy** because it runs the real
  production path — report it, labelled.
- **30-point / 120-link `PointLinkSolver` fixture** matches the budget's literal shape but is not a creature
  at all. It is the **best primitive** measurement — report it, labelled.

**Do all three, labelled, none as the gate:**

1. **Ten Slugs per sample** — per-solver mean, and the aggregate (≈10×). Report total capsule bodies,
   total structural constraints, total contact constraints actually resolved per tick.
2. **30-point / 120-link `PointLinkSolver`** — direct transactional tick, plus the outer
   frame+accumulator+tick path. Report the exact graph shape.
3. **The real worst case the design permits** — a legal creature at the **maximum part budget (10)**, and if
   the model permits a legal 14-part creature, that too. **This is the number that should drive the owner's
   re-scaling**, because it is the largest thing the game will ever actually simulate.

**Do not apply the 3.0 ms threshold to any of them.** Report the numbers *beside* the threshold as context
and keep the row `NOT RUN`. Converting a proxy into a pass or a fail is exactly the substitution this
session is forbidden from making. Hardware labels stay honest: GitHub runner = x86-64 shared cloud, and the
reference-device leg is **owner D07**, still open.

---

## 5. Ledger after D0 and D2

| | count |
|---|---:|
| 18 runtime slots | 18 |
| **production-operational PASS** | **10** |
| measured but FAILED | **3** — AC-201, AC-202, FA-4 (FA-4 pending its P2 arm) |
| uncredited | **1** — FA-3 (vacuous) |
| **blocked / NOT RUN** | **1** — tick cost §10.4 (spec defect) |
| still to measure in P2 | 3 — presets/captures, §10.6, FA-6 |

**Honest ceiling for M1: 13 / 18 passing, 17 / 18 carrying a measured verdict, 1 blocked by a spec defect
that no measurement can fix.** Down from the 14 I published last round — because tick cost is now blocked
rather than pending, and that is a fact about the spec, not about the work.

---

## 6. Directives

1. **AC-202 stays FAILED and reverted.** D0 closes the causality question; nothing here reopens adoption.
2. **D2 = `NOT RUN`, blocked.** Run the three labelled proxies, gate stays `NOT RUN`, no threshold applied.
3. **F79 withdrawn**; do not carry it as a production defect into the verdict.
4. **Continue P2** with D1 (presets/captures), D3 (§10.6 step 1), D4 (FA-4), D5 (FA-6), D7 (regression).
5. **Evidence storage:** the base64-annotation + committed `.jsonl.gz` route worked and I accept it. Keep raw
   captures **gzipped** and under the 5 MB budget; if a capture would exceed it, commit the decimated copy
   plus the sha256 of the full file, as the P2 prompt already requires.
6. **New owner question, added to the sheet:** is §10.4's "30 bodies / 120 constraints" a *headroom target*
   or should it be re-expressed at the achievable maximum (10 parts / 14 post-build)? Same category as
   FA-4's "1.00 BL — spec or scale", and it needs the same kind of answer.

**M1 is not complete. M2 remains blocked.**
