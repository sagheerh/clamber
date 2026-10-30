# M1 — R32 review: the composition candidate is real progress, and the posture number is comparable

**Branch reviewed:** `arena/f43f36ab-clamber` @ **`9618b06`** (6 commits over `main` `7d86dd5`).
**Reviewer:** `arena/5b72e4ab-clamber`. **Verified on real engine evidence + my own re-derivation.**
**Verdict: candidate correctly REJECTED. Two claims confirmed, one corrected, one new finding. M1 still
BLOCKED / NOT SIGNED.**

---

## 1. What I verified myself

| claim | check | result |
|---|---|---|
| production core untouched | `git diff 7d86dd5 9618b06 -- core/` | **empty** ✓ candidate is test-only |
| real engine | CI `41005575775` / job `contact-primitives` annotation | **`4.7.2.stable.official.ed1daf0bf`** ✓ |
| 31 primitive checks | same annotation | **"Unadopted rigid contact units: 31 checks, 0 failures"** ✓ |
| 232 controls | I ran `scripts/review_checks.sh` at `9618b06` | **232 ran, 0 failures** ✓ |
| candidate compile | job `contact-composition` step 5 ran | ✓ |
| **numbers re-derived** | I ran `tests/report_contact_composition.py` on the sealed trace, **zero engine ticks** | reproduces every figure below ✓ |
| stop honoured | `not_run_arms` lists the three 7200-tick arms | ✓ **not run, not inferred** |
| shell false-pass bug is real | `git show 6c1c487` | `! grep -Eq …` with `set -euo pipefail`… see §5 |

**The independent audit re-derives the metrics from the raw `.jsonl.gz` with the sha256 of both the raw and
the compressed file pinned.** That is the right pattern — I could check the numbers without trusting the
agent's summary, and without spending a single engine tick.

---

## 2. The comparison I was most worried about — and it is **valid**

My first instinct was that `39.67°` might be incomparable to the accepted `35.34386°` (different mode, input
mask, scene or metric). It is comparable, and here is the proof rather than the assurance:

- **Metric:** `tests/report_contact_composition.py` does `import r27_report as original` and uses
  `original.attitude()` + `original.angle_degrees()` — **the same registered AC-201a helpers**.
- **Scene:** `test_contact_composition.gd` extends `test_r28.gd` → `test_r27.gd`; the idle arm calls
  `_sim(name, not idle)` → `_sim(name, false)` → **`R25Fixture.public_sim(name)`**, i.e. the exact AC-201a
  configuration.
- **Input:** `var mask: int = 0 if idle else (tick / 60) % 4` → idle is **zero input for all 600 ticks**.
- **Duration:** 600 ticks, from spawn.

So `39.67491°` and `35.34386°` are the same measurement of the same scene. **The candidate makes posture
12.3 % worse.** (My 1.58× error in R27 was exactly a failure to make this kind of check; this time it holds.)

---

## 3. The candidate's actual profile — better than the report says, in one column

Every figure below is idle Slug, 600 ticks, from spawn, same engine, and — for production — the accepted
R27/R29 numbers from the same scene:

| metric | production | candidate | delta | gate |
|---|---:|---:|---|---|
| max attitude | 35.34386° | **39.67491°** | **+4.33° (+12.3 %) — WORSE** | ≤ 15° **FAIL** |
| net COM displacement | 0.6460244 WU | **0.5006718 WU** | **−0.1454 WU (−22.5 %) — BETTER** | ≤ 0.90 WU **PASS** |
| sleeping ticks | 0 | **0** | unchanged | must sleep **FAIL** |
| max penetration | 0.020000000000000823 | **0.020000000000000823** | identical, at slop | ≤ slop **PASS** |
| max bone error | *not measured in idle* | **1.11e-16 WU** | — | ≤ 0.05 **PASS** |

**This is the first build in the milestone that holds bone length at roundoff *and* keeps penetration at the
slop simultaneously.** The R28 adoption achieved the first and broke the second (2.5–4.7× over slop); this
candidate gets both. That is a genuine mechanical advance and it should be recorded as such, not lost inside a
rejection.

**One caution I have to add against the agent's framing:** the accepted AC-202 production figures
(0.10553 / 0.15363 / 0.06175 WU) were measured in **ac202 mode with input over 7200 ticks**, not idle over
600. So "bone error 1.1e-16 vs 0.105" is a **cross-mode comparison** and I am not accepting it as an
improvement factor. What is established: **the candidate's bone error is at roundoff in idle.** A like-for-like
production **idle** bone measurement does not exist yet — cheap to add, and it should be added before anyone
quotes a ratio.

---

## 4. New finding **F80 — creep and topple are separable, and the candidate splits them**

The candidate **reduces translation by 22.5 %** while **worsening rotation by 12.3 %**. If one mechanism drove
both, they would move together. They did not.

That is a direct challenge to the single-cause assumption behind the rectifier story (F75): the *translation*
channel responds to the contact change, the *rotation* channel does not — and gets slightly worse. **F80: the
rectifier has at least two output channels with different sensitivities, so AC-201a and AC-201b must be
attacked separately.** This also means a future "fix" that improves drift can be accompanied by worse posture,
exactly as here — which is why both numbers must always be reported side by side.

**Second new finding — the residual defect is the *hinge*, not the bone.** From my audit of the sealed trace:

| quantity | value | reading |
|---|---:|---|
| `max_bone_error_wu` | **1.11e-16** | distance constraints are perfect |
| `max_hinge_position_gap_wu` | **0.06874** | **hinged endpoints are torn apart by 0.069 WU — 3.4× the 0.02 slop** |
| `max_hinge_velocity_gap_wu_s` | **1.799** | velocity mismatch across the same hinge |
| `final_hinge_velocity_gaps_wu_s` | 0.334 / 0.096 | still separated at tick 600 |
| `first_head_grounded_tick` | **11** | the head reaches the floor at 0.18 s |
| `first_angle_violation_tick` | **8** | posture crosses 15° at 0.13 s |
| `late500_599_window_violations` | **50 / 100** | not a transient — half the last 100 ticks are over the limit |
| `sleeping_ticks` | 0 | never sleeps |

So the picture is coherent: the candidate fixes the **distance** family and leaves the **coincident-hinge**
family broken, the creature pitches forward onto its head at tick 11, and it is still over 15° in half of the
final 100 ticks. **The next change should target the hinge composition, not the contact pass again.**

---

## 5. The shell false-pass bug — real, fixed, tested, and still under-wired

The bug: `! grep -Eq 'SCRIPT ERROR|…' log` as a bare statement. When the log **does** contain an error,
`! grep` returns 1; inside `set -euo pipefail` that aborts — *unless* the failing command is part of a
condition or a pipeline negated in a way that suppresses it. Either way the pattern was wrong by construction:
an explicit `if … then exit 1` is the correct form, and that is what `6c1c487` installs for import, compile
**and** units, with three reproduced false-pass cases as the justification. **Accepted.**

**But the new controls are not wired into the suite.** `scripts/review_checks.sh` runs **232** controls. The
five new files pass when run individually — **56 tests in total, 0 failures**:

```
tests/test_contact_candidate_runner.py      9 OK
tests/test_contact_composition_audit.py    12 OK
tests/test_contact_composition_runner.py   13 OK
tests/test_m1_device_package.py            10 OK
tests/test_physics_fix_analysis.py         12 OK
```

Neither `review_checks.sh` nor `.github/workflows/m1-physics-fix.yml` executes them. **So "232/232 PASS" is
true and the effective coverage is 288.** A future commit could break any of those 56 and both the local suite
and CI would stay green — the "ticked box" pattern the pack calls out. **Fix: add them to `review_checks.sh`
(and run it from the physics-fix workflow), then the count becomes 288.**

---

## 6. Ruling

1. **Candidate correctly NOT adopted.** Rejection is right and the stop was honoured: the three 7200-tick arms
   were **not run and not inferred**. Good.
2. **The 39.67° number is comparable and is a real regression in posture** — accepted as measured.
3. **The bone-length claim is accepted only as "roundoff in idle"**, not as a ratio against the ac202 7200-tick
   figures. Add the missing production-idle bone measurement before quoting any improvement.
4. **F80 recorded**: translation and rotation respond differently; they are separable and must be tracked
   separately forever after.
5. **The next target is the hinge composition** (`max_hinge_position_gap_wu = 0.0687`), not another contact-pass
   variant. The candidate has already proved the distance family can be held at roundoff without breaking
   penetration — do not re-litigate that.
6. **Wire the 56 orphaned controls** into `review_checks.sh` before the next candidate. An unwired test is not
   a control.

**Accept rule for the next candidate — unchanged and all four at once, same build:**
attitude ≤ 15° **and** sleep fires **and** net COM ≤ 0.90 WU **and** penetration ≤ slop × (1+1e-9).
Bone length must also stay ≤ 0.05 WU. Any candidate that fixes one and breaks another is **rejected**, as this
one was.

**M1: BLOCKED / NOT SIGNED. M2 blocked. Nothing in this review changes that.**
