# M1 foundations — R4 review of PR #3 (`f51ecd4`)

**Reviewed:** 2026-10-28  
**PR #3:** `arena/4cd0a587-clamber` @ `f51ecd480ce5e5476428740755f2dd33a87a5e79` → `main`, **draft**.  
**Checks:** 8/8 SUCCESS (`headless` ×2, `android` ×2, `M1 invariant/static subset` ×2, `M1 point/link unit tests` ×2).  
**Reviewer branch (pack carrier only):** `arena/5b72e4ab-clamber` @ `9a9350c`.

---

## 1. Verdict

**Independent foundations: ACCEPTED as foundations. M1: still INCOMPLETE / NOT APPROVABLE.**

The point-body + XPBD distance-link increment is honest, well-tested and correctly scoped. It does not invent radii, head properties, grip thresholds, or a gait, and it does not claim determinism. That part is good work and does not need redoing.

Two review-infrastructure items from R3 are still open (**F7**, **F8**), and the increment introduced one **false record about the owner** that must be corrected before anything else is written on top of it (**F12**).

**Verified items — do not redo**

| Claim | Verification |
|---|---|
| `M1 math foundations: 81 checks, 0 failures` on pinned 4.7.2 | CI annotations on both `M1 point/link unit tests` check-runs (`122631071347`, `122631056383`) |
| `M1 acceptance: NOT RUN ...` printed by the harness itself | Same annotations; `test_math_state.gd` prints it before `quit()` |
| M0 regression unchanged: 475 engine checks | `headless` annotation `M0: 475 checks, 0 failures`; `check_m0_regression.py` enforces 475 / 13 / 488 |
| Android packaging still green | `android` annotations unchanged |
| `scripts/review_checks.sh` exit 0, 21 Python tests | Ran it on the PR tree: 8 `test_review_checks` + 6 static + 7 inspector = 21, exit 0 |
| Tuning/save/M0 tests unchanged | `git diff c641990 f51ecd4 -- core/tuning.gd core/tuning.tres docs/TUNING.md` → **empty**; `-- tests/test_static.py tests/test_android_inspection.py tests/test_runner.gd tests/run_tests.sh` → **empty** |
| Public `Sim` interface untouched | `core/sim/sim.gd` not in the diff; stub bodies intact |
| No invented contact values | `body.gd` requires caller-supplied `inverse_mass`; zero inverse mass documented as a mathematical pin, not a head default; no radius/head/grip field exists |

**Code quality notes on the increment (all positive)**

- Float64 scalar `x/y/previous/velocity` instead of `Vector2` avoids `real_t` build-dependence — correct reasoning for a determinism-critical primitive.
- `restore()` validates every field **before** mutating any member, and the test proves the failure is atomic by comparing `snapshot()` before/after.
- `project()` returns `ERR_INVALID_DATA` on coincident endpoints rather than fabricating an axis or a hidden epsilon; rejects `ERR_UNAVAILABLE` when both ends are pinned; checks `squared_length` overflow from `1e300` fixtures and leaves state unchanged.
- XPBD math is textbook-correct: `alpha = compliance / dt²`, `denominator = Σw + alpha`, `lambda` accumulated and reset at tick boundary, `sqrt` only (no banned transcendental).
- The 81 checks are **real assertions with exact expected values** (`a.x == 0.5 and b.x == 1.5`, `multiplier == -0.5`, `expected = -1.0 / (2.0 + compliance/(dt*dt))`, mass-weighted `0.25 / 1.25`). 57 literal `_check(` sites plus loop expansion — not a hollow print-only test.
- `docs/validation/M1.md` is honest: every AC row NOT RUN, 0 complete determinism attempts, two-attempt stop budget explicitly unconsumed, D-11 not fabricated.

---

## 2. Findings

### F7 — [BLOCKER] Full review pack still absent, and the reason given is now false
- **Citation:** `docs/CLAMBER_REVIEW_AGENT.md` on `f51ecd4` is **46 lines**, header “The full external review pack has NOT been provided or vendored.” `.github/workflows/m1.yml` notice still prints `Full external pack absent.`
- **Fact:** the complete pack **is** supplied and present in this repository at `origin/arena/5b72e4ab-clamber:docs/CLAMBER_REVIEW_AGENT.md` — **379 lines**, **23451 bytes**, `sha256 e3bd06654e0f92aaca55d0cc85e79f6d589a45aa6d9ddab5f4f068db22edb9a1`, containing PART A (A1–A13 incl. A9 seven-point determinism and A10 five fakes), PART B (INV-01…INV-10 + M0–M7), PART C, PART D, PART E.
- **Violates:** A5.5 / A7.1 traceability, A12.1 verdict artifacts, `DECISIONS.md` M1-B02.
- **Done when:** `sha256sum docs/CLAMBER_REVIEW_AGENT.md` = `e3bd0665…9a1` and `wc -l` = `379`; the “PARTIAL SOURCE ONLY / NOT provided” header replaced by a provenance line; the CI notice no longer says “absent”.

### F8 — [MAJOR] Matrix is still not tick-proof
- **Citation:** `scripts/review_checks.sh` is unchanged at 12 lines / 570 bytes; it never reads `.review/m1_ac_matrix.md`.
- **Risk:** A10 “ticked box”. Any future commit can write `| AC-201 | … | PASS | None |` and CI stays green.
- **Done when:** `review_checks.sh` fails when (a) any M1 runtime row (`AC-201/202/204`, presets, tick cost, A9.2/A9.3/A9.4/A9.5/A9.7, §10.6, A12, A5.6) contains `Met|PASS|PASSED|VERIFIED`; (b) any pass token appears with an empty or `None` evidence cell; (c) fewer than 12 rows contain `NOT RUN`. The two legitimate regression rows (`PASS (regression only)`, `PASS (count floor only)`) must be allowed **only** when the status text contains `regression`/`count floor` **and** the evidence cell cites a run or commit. Include a negative-control transcript in the PR body: force one AC row to `PASS | None` → exit 1, revert → exit 0.

### F12 — [MAJOR] Owner decision misattributed in the record
- **Citation:** `DECISIONS.md` **M1-D01**: *“The owner also selected use of the supplied review requirements for now.”* Repeated in `docs/validation/M1.md` (“The owner also selected using the supplied review excerpts for now”) and in `.review/m1_ac_matrix.md`.
- **Fact:** the owner said the opposite — that the excerpts were **not enough** to vendor the document faithfully, and supplied the complete pack instead. The owner never chose to proceed on partial requirements.
- **Why it matters:** a decision log that puts a choice in the owner’s mouth is exactly the kind of unverifiable claim A4 forbids, and it is now the stated reason for leaving F7 open.
- **Done when:** M1-D01/M1-B02 and `docs/validation/M1.md` state that the owner supplied the full pack on 2026-10-28 (sha256 above), that M1-B02 is **resolved**, and that no “use excerpts” owner decision exists.

### F13 — [MINOR] `DistanceConstraint.project()` mixes the global resource with the passed parameter
- **Citation:** `core/sim/constraint.gd` — `var fixed_step := float(TUNING.physics_one) / float(tuning.physics_tick_hz)`; `physics_one` is read from the global `TUNING` while the tick rate comes from the argument.
- **Risk:** a future test that injects alternate tuning silently half-applies it, and the primitive would fail open a “tuning is injected, not global” check (A9.3 spirit).
- **Done when:** both factors come from the `tuning` argument, and a unit test proves the parameter is honoured — e.g. `TUNING.duplicate()`, set `physics_tick_hz = 120`, and assert a different `multiplier` than at 60 Hz. That is a synthetic test resource, not a tuning change.

### F14 — [MINOR] Branch bookkeeping
- PR #3 is on `arena/4cd0a587-clamber`; `docs/validation/M1.md` calls that “the active session branch”. The session’s active branch is `arena/5b72e4ab-clamber`, which holds only the pack carrier commit `9a9350c`.
- **Action:** keep PR #3 as the one canonical M1 PR, do **not** open a second draft PR from `5b72e4ab`, and word M1.md as “M1 working branch for PR #3”. One PR, one source of truth.

---

## 3. Owner inputs still blocking real M1 work

- **M1-B01:** per-part collision radii (including head), head mass/length treatment, foot normal-force grip threshold — with units. Until then: no contact, no gait, no AC-201/202/204, no tick measurement that means anything for feel.
- **M0-B02:** camera zoom `0.75` (§2.3) vs `0.72` (§4.8) — M2 only, but it must be decided before camera work starts.
- M0-B03 haptic/generator values remain out of scope for M1.

---

## 4. Paste-ready message to the coding agent

```text
R4 review of PR #3 @ f51ecd4: the independent foundations are ACCEPTED as
foundations. I verified the CI annotations myself: "M1 math foundations: 81
checks, 0 failures" and "M1 acceptance: NOT RUN" on both point/link jobs, M0 at
475 checks / 0 failures, Android packaging green, and review_checks.sh exit 0 with
21 Python tests (8 + 6 + 7). I read body.gd, constraint.gd, test_math_state.gd and
M1.md, and confirmed the tuning/save/M0-test diffs against main are empty and
public Sim is untouched. The XPBD math, atomic restore, coincident/overflow
rejection and exact-value assertions are good — do not redo any of it.

M1 remains INCOMPLETE. Do not mark any runtime gate passed.

Three things to fix now, in one small commit (docs + scripts + one primitive test;
no contacts, no presets, no gait work).

F7 [BLOCKER] The full review pack is supplied. Stop saying it is absent — it is
already in this repository on the reviewer branch. Extract that one file only:

  git fetch origin arena/5b72e4ab-clamber
  git show origin/arena/5b72e4ab-clamber:docs/CLAMBER_REVIEW_AGENT.md \
    > docs/CLAMBER_REVIEW_AGENT.md
  sha256sum docs/CLAMBER_REVIEW_AGENT.md
  # must be e3bd06654e0f92aaca55d0cc85e79f6d589a45aa6d9ddab5f4f068db22edb9a1
  wc -l docs/CLAMBER_REVIEW_AGENT.md
  # must be 379

Fallback if that ref is inconvenient:
  curl -fsSL \
    https://raw.githubusercontent.com/sagheerh/clamber/arena/5b72e4ab-clamber/docs/CLAMBER_REVIEW_AGENT.md \
    -o docs/CLAMBER_REVIEW_AGENT.md

It must be byte-identical and unmodified: PART A (A1-A13, including the A9
seven-point determinism check and A10 five fakes), PART B (INV-01..INV-10 and the
M0-M7 checklists), PART C, PART D, PART E. Replace the "PARTIAL SOURCE ONLY /
NOT provided" header with a provenance line: owner-supplied 2026-10-28,
byte-identical, sha256 e3bd0665..., unmodified. Update the m1.yml notice that
currently prints "Full external pack absent."

F12 [MAJOR] Correct a false record about me. DECISIONS.md M1-D01 says "the owner
also selected use of the supplied review requirements for now", and M1.md and the
matrix repeat it. I did not select that. I said the excerpts were not enough to
vendor the document faithfully and gave you the complete pack. Remove that
attributed decision everywhere, state that the owner supplied the full pack on
2026-10-28 with the sha256 above, and mark M1-B02 RESOLVED (vendored), not waived.
Do not put words in the owner's mouth again; if a decision is unclear, ask.

F8 [MAJOR] Make the matrix tick-proof. Extend scripts/review_checks.sh so it
fails when:
 (a) any M1 runtime row (AC-201/202/204, presets, tick cost, A9.2, A9.3, A9.4,
     A9.5, A9.7, §10.6, A12, A5.6) contains Met/PASS/PASSED/VERIFIED;
 (b) any pass token appears with an empty or "None" evidence cell;
 (c) fewer than 12 rows contain NOT RUN.
Allow your two legitimate rows "PASS (regression only)" and "PASS (count floor
only)" only when the status text says regression/count floor AND the evidence cell
cites a run or commit. Paste the negative-control transcript in the PR body:
force AC-201 to "PASS | None" -> exit 1, revert -> exit 0.

F13 [MINOR] In constraint.gd, project() takes a tuning argument but reads
physics_one from the global TUNING. Use the passed tuning for both factors, and
add one unit test that proves injection is honoured: duplicate the resource, set
physics_tick_hz = 120, and assert the multiplier differs from the 60 Hz run. That
is a synthetic test resource, not a tuning change.

F14 [MINOR] PR #3 is the one canonical M1 PR on arena/4cd0a587-clamber. Do not open
a second PR from arena/5b72e4ab-clamber (it exists only to carry the review pack),
and make M1.md say "M1 working branch for PR #3" instead of claiming another
branch is the active session branch.

After those are pushed and green, the next increment is integration + the fixed
1/60 accumulator over bodies and links with tuning gravity and deterministic
ordering — still no contacts, no radii, no gaits, no presets, no baseline, no
AC-201/202/204 claims. M1-B01 (radii, head mass/length, grip threshold with units)
is still mine to supply; do not fill it. Do not start M2 or camera work.
```

---

*End of R4 review. Foundations accepted; M1 not approvable; F7/F8/F12 must land before any further M1 increment.*
