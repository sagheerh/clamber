# M1 — R34 review: the articulated candidate is a **spawn-induced spin**, not creep — and the energy guard is unsatisfiable as written

**Branch reviewed:** `arena/f43f36ab-clamber` @ **`d3a07ae`** (2026-10-31). Candidate source `f7b8fd2`, CI `41150933157`.
**Reviewer:** `arena/5b72e4ab-clamber`. **Verdict: candidate correctly rejected. One new defect class found, one
unsatisfiable guard identified, one governance failure repeated. M1 still BLOCKED / NOT SIGNED.**

---

## 1. Verified myself

| claim | check | result |
|---|---|---|
| production core untouched | `git diff 7d86dd5 d3a07ae -- core/` | **empty** ✓ |
| real pinned engine | `components.log` + CI annotations | `4.7.2.stable.official.ed1daf0bf` ✓ |
| 42 mobility checks | CI job annotation | **“M1 articulated mobility units: 42 checks, 0 failures”** ✓ |
| 8 cap-identity checks | committed `components.log` | **“Articulated cap identity: 8 checks, 0 failures”** ✓ |
| 232 controls | I ran `scripts/review_checks.sh` at `d3a07ae` | **232 ran, 0 failures** ✓ |
| 2-ULP energy rise | I recomputed: `math.ulp(1.1674e-4) = 1.355e-20`, delta `2.7105e-20` | **exactly 2.000 ULP** ✓ — the agent's arithmetic is right |
| guard not weakened | no epsilon/tolerance introduced | ✓ |
| later arms not run | `not_run_arms: [length-Slug, length-Hopper, length-TwinRoller]` | ✓ |
| M0 | 516 + android job | ✓ |

**Three credits, and they are real:**

1. **Penetration is below the slop for the first time in the milestone.** `max_penetration_wu = 0.01999830891325001`
   < `0.02`. Every previous build sat **on** the slop (production) or **2.5–4.7× above** it (R28).
2. **Bone length at roundoff**: `1.665e-16` WU over 14 ticks.
3. **The strict passivity guard was not weakened** when it fired. That is the correct instinct — and it is
   precisely why §4 below matters.

---

## 2. F81 — this is a **spin at spawn**, not the slow topple. Categorically different.

I decoded the committed trace tick by tick (`idle-Slug.jsonl.gz`, 14 rows, `attitude_deg` per row):

| tick | attitude ° | **Δ per tick** | length peak | pen peak |
|---:|---:|---:|---:|---:|
| 0 | 0.0000 | — | 0 | 0.000000 |
| 1 | **0.3161** | **+0.3161** | 5.6e-17 | 0.005884 |
| 2 | 1.0427 | +0.7266 | 0 | 0.014116 |
| 3 | 2.3095 | +1.2668 | 5.6e-17 | 0.019998 |
| 4 | 4.2769 | +1.9674 | 5.6e-17 | 0.019939 |
| 5 | 6.8657 | +2.5889 | 5.6e-17 | 0.019908 |
| 6 | 10.0617 | +3.1960 | 1.1e-16 | 0.019906 |
| 7 | 13.8750 | +3.8133 | 1.1e-16 | 0.019910 |
| **8** | **18.4137** | +4.5387 | 5.6e-17 | 0.019918 |
| 9 | 23.8861 | +5.4724 | 5.6e-17 | 0.019929 |
| 10 | 30.6033 | +6.7171 | 5.6e-17 | 0.019941 |
| **11** | **38.9799** | **+8.3767** | 1.7e-16 | 0.019954 |
| 12 | 37.7808 | **−1.1992** | 5.6e-17 | 0.019962 |
| 13 | 36.1396 | −1.6412 | 1.1e-16 | 0.019982 |
| 14 | *solver stops* | — | — | — |

Three facts fall out, none of which “38.98° vs 35.34°” conveys:

1. **There is angular velocity at tick 1 with zero input.** From rest, one tick of gravity alone can produce
   ≈0.002° of rotation on a creature this size (½·α·t², α≈16 rad/s²); we observe **0.316°** — roughly **140×
   more**. So the first contact pass **delivers a spin**, it does not merely fail to prevent one.
2. **The rate accelerates monotonically**: 0.32 → 0.73 → 1.27 → 1.97 → 2.59 → 3.20 → 3.81 → 4.54 → 5.47 → 6.72
   → **8.38 °/tick**. Production averages **0.0589 °/tick**. The candidate's peak is **142× the production
   rate** — this is an instability, not the rectifier's slow creep.
3. **It only stops when something hits the ground** (Δ flips negative at tick 12), and the solver then aborts
   at 14.

So the previous framing — “posture limit broken at tick 8” — understates it. **The creature is thrown into a
~19 °/s spin by its own first contact and tips over in 0.18 s.**

---

## 3. F80 extended — **contact is not the posture lever.** Three candidates, same posture.

| build | max attitude | net COM | penetration | bone |
|---|---:|---:|---:|---:|
| production | 35.34386° | 0.6460244 WU | on slop (0.0200) | 0.10553 (ac202 mode) |
| R32 composition candidate | 39.67491° | 0.5006718 WU | on slop (0.0200) | 1.11e-16 |
| R34 articulated candidate | **38.98°** (11 ticks) | — (aborted) | **0.0199983 — under slop** | 1.67e-16 |

Three different contact treatments now span 35.3° → 39.7° → 39.0°. **The posture number has not improved once**,
while penetration and bone length both improved substantially. The two channels are decoupled exactly as F80
predicted, and the evidence now says something sharper:

> **The topple lives in the angular/hinge channel, and no contact-pass variant will move it.** Three attempts
> at the contact/impulse family have left posture at 35–40°. Continuing there is the definition of a blind
> retry.

The next experiment must be **angular**: measure where the spin comes from at ticks 0–2, before any posture
failure exists.

---

## 4. I am authorising one fix to the *guard* — because the guard, as written, is unsatisfiable

The passivity guard rejected a projection whose numbers are:

```
max hinge RHS                     1.22514845490862e-17
max requested velocity increment  5.0187308831723105e-17
kinetic energy change             2.7105e-20  =  exactly 2 binary64 ULPs
```

**A strict “energy must never increase” test cannot be satisfied by binary64 arithmetic at these magnitudes.**
Re-projecting rows whose residual is already ~1e-17 will sometimes round upward by an ULP or two. That is not
the solver misbehaving; it is the arithmetic. As written, **the guard will eventually reject any candidate at
random**, and the temptation will be to “just weaken it” — which is exactly what must not happen.

**Authorised (this is a solver-internal no-op test, not an acceptance threshold):**

> When the residual of a constraint row is below **1e-15** (relative to its own scale), **skip the projection
> entirely** — perform no work rather than work that cannot change the physical answer. Log the skip count per
> tick. Keep the passivity guard exactly as strict as it is for every row that *is* projected.

Conditions on that authorisation:

1. **Declared constant, owner-visible**, recorded in `DECISIONS.md` with its derivation: 1e-15 WU is **13 orders
   of magnitude below** the 0.02 WU slop and **11 below** the 0.05 WU limb gate, so a row skipped at that scale
   cannot affect any measured gate.
2. **Logged, not silent**: `skipped_rows` per tick must appear in the trace, and the run must report the maximum
   residual among skipped rows. If that maximum ever exceeds 1e-15, the run is invalid.
3. **The guard is never relaxed by more than this**: no epsilon in the passivity comparison itself, no
   `>=` for `>`.
4. If the candidate then completes 600 ticks, report **all five** numbers (attitude, sleep, COM, penetration,
   bone) — a completed run is not a passing run.

If the agent believes the projection should not be running at all on already-satisfied rows, that is the same
fix and is preferable: **remove the work, do not tolerate the error.**

---

## 5. Governance failure, repeated — 122 controls are now unwired

I directed in R32: *“Wire the 56 orphaned controls into `review_checks.sh` before the next candidate. An unwired
test is not a control.”* It was not done, and the pile grew:

```
review_checks.sh at d3a07ae  →  232 controls (unchanged)
unwired test files, run by hand just now:
  test_contact_candidate_runner.py          9   OK
  test_contact_composition_audit.py        12   OK
  test_contact_composition_runner.py       13   OK
  test_m1_device_package.py                10   OK
  test_physics_fix_analysis.py             12   OK
  test_articulated_execution_runner.py     17   OK
  test_articulated_first_failure_audit.py  19   OK
  test_articulated_mobility_analysis.py    18   OK
  test_articulated_units_runner.py         12   OK
                                     total 122  OK (0 failures)
```

**Effective coverage is 354; the reported number is 232.** Every one of those 122 could regress silently and both
the local suite and CI would stay green. This is the “ticked box” pattern, and it is now **blocking**: the next
candidate submission is not reviewable until `review_checks.sh` runs them and the count reads **354**.

---

## 6. Mandatory invariant for the next candidate — angular momentum, not just linear

The R33 invariants covered linear momentum, energy, R19 identity and determinism order. **They were not enough**,
and F81 shows why: a chain-distributed impulse can conserve linear momentum while injecting **angular**
momentum.

For internal impulses this is exact and cheap: a hinge impulse acts as an equal-and-opposite pair **at a common
point**, so it contributes **zero net torque** — about any point, including the COM. Therefore:

> **Assert, at every contact pass:** `‖Σ m·Δv‖ ≤ 1e-12 · ‖Σ m·|v|‖` **and**
> `‖Σ Δ(r × m·v) about COM‖ ≤ 1e-12 · ‖Σ |r × m·v|‖`. Both must hold **without** gravity in the sum (gravity is
> external and is applied outside the contact solve).

If either fails, **the operator is not internal** and no posture number from that build means anything. This
single assertion would have predicted F81 before the 600-tick arm was ever spent.

**Combined with the R33 four, the next candidate's test file must contain five invariants**, and the first tick
(0 → 1) must be reported with `Δv`, `ΔL` and `ΔKE` explicitly — the spin appears there, not at tick 8.

---

## 7. Ruling

1. **Candidate correctly rejected**; stop honoured; later arms not run; guard not weakened; production untouched.
2. **Credited**: penetration below slop for the first time, bone at roundoff, cap-identity fix (8/8), 42/42
   mobility on the real pinned engine.
3. **F81 recorded**: spawn-induced angular velocity and a monotonically accelerating tilt, 142× the production
   rate. This is a different defect class from the creep, and it must be described as such in every future report.
4. **F80 extended**: contact is not the posture lever — stop varying the contact pass.
5. **Authorised**: the declared 1e-15 no-op skip (§4), with logging and no other relaxation.
6. **Blocking**: wire the 122 controls; `review_checks.sh` must read **354** before the next candidate is reviewed.
7. **Next work item is angular**, not contact: find the source of the tick-1 spin.

**Accept rule unchanged, all at once on one build:** attitude ≤ 15° · sleep fires · net COM ≤ 0.90 WU ·
penetration ≤ slop × (1+1e-9) · bone ≤ 0.05 WU · **plus** the five invariants (linear **and** angular momentum,
energy, R19 identity, determinism order).

**M1: BLOCKED / NOT SIGNED. M2 blocked.**
