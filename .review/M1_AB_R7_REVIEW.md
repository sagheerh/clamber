# M1 Commits A + B — R7 verification of PR #3 @ `0668d66`

**Reviewed:** 2026-10-28  
**PR #3 head:** `0668d666949fcccb02a80c0cf770dea7f8df770d` (draft)  
**A:** `0ee3548` (F16–F19) · **B:** `0668d66` (owner geometry)  
**CI:** M1 [`40672331407`](https://github.com/sagheerh/clamber/actions/runs/40672331407), M0/Android [`40672331399`](https://github.com/sagheerh/clamber/actions/runs/40672331399) — **both green**

---

## 1. Verdict

| Item | Verdict |
|---|---|
| **A / B separation** | **MET** — A touches only `accumulator.gd`, `check_m0_regression.py`, tests and records; zero geometry. B is geometry only. |
| **F16 floors** | **MET** — `ENGINE_BASELINE 476`, `COMBINED_BASELINE 489`, message now uses the constants instead of hardcoded text. |
| **F17 rollback** | **MET** — `rollback_status` checked first; 7 new integration checks (292 → 299) include the forced rollback failure. |
| **F18 record** | **MET** — snapshot policy and benchmark prerequisite recorded; both performance numbers still `NOT RUN`. |
| **F19 wording** | **MET** — matrix row now says frame *delivery*, not tick rate. |
| **B constants** | **MET** — all 14 values match my spec exactly, verified with `Decimal` in `test_owner_geometry_source.py`. |
| **D-10 guard** | **MET and stronger than asked** — all 25 kind pairs, not just the 3 I listed; strict `< limit`; both an equality-negative control and an oversized-radius negative control; per-preset sibling pairs; `checked_pairs > 0` so it cannot silently check nothing. |
| **Head rules** | **MET** — mass 2.2 × 0.35 = 0.77 pinned in Decimal; **no** head angular-limit export exists (asserted by regex). |
| **Visual isolation** | **MET** — the scanner got *stricter*: a new rule fails if any `*_visual_radius_*` is referenced in `core/`, with a narrow exemption for the declaration lines in `tuning.gd` only. |
| **Analytic-only honesty** | **MET** — FA-1/2/7 labelled `PASS (analytic only)` in annotations *and* in the JSON; FA-3/4/5/6 `NOT RUN` with `observations: null` and FA-6 `success_count: null`; `run_m1_feel.sh` asserts every one of those nulls and a ≥123 floor, so a future fabrication fails CI. |
| **GDD §3.2 untouched** | **MET** — only the two head constants were added; masses/lengths/friction/stiffness/torque unchanged. |
| **Claim guard still green** | **MET** — `review_checks.sh` exit 0; 34 Python tests (18 + 3 + 6 + 7). |

Counts I reproduced: primitive **381** = 82 + 299, geometry **123**, M0 **500**, Python **34**.

This is the best-verified increment so far. Two findings, one of them mine to own.

---

## 2. Findings

### F20 — [MAJOR] The FA gates are not inside the claim guard

The FA-1…FA-7 gates exist to make “viral vs copycat” falsifiable, but they live in
**prose and JSON only** — they are not rows in the guarded matrix table.

I proved the hole on the real tracked file:

```sh
printf '\nFA-6: PASS (8/10 successes)\n' >> .review/m1_ac_matrix.md
python3 scripts/check_m1_matrix.py
# PASS: M1 claim-freeze matrix guard; owner pack SHA-256 / 379 lines verified.
# exit=0     <-- a fabricated FA-6 success is NOT caught
```

- **Citation:** `.review/m1_ac_matrix.md` has 32 pipe rows, **zero** with an `FA-`
  gate cell; `scripts/check_m1_matrix.py` only inspects pipe-table rows.
- **Violates:** A7.1 (every criterion mapped in the matrix), A10 “ticked box”,
  and the whole purpose of building the guard in R4.
- **Done when:**
  - FA-1 … FA-7 are **rows** in the gate table.
  - The status allowlist gains exactly one scoped value,
    `PASS (analytic only)`, permitted **only** for `FA-1`, `FA-2`, `FA-7`, and only
    with a citation (CI run or the geometry report path).
  - FA-3/4/5/6 remain `NOT RUN`.
  - A negative control in the PR body shows `FA-6 | PASS (analytic only)` failing
    with exit 1 (today it passes silently), and `FA-1 | PASS (analytic only) | CI…`
    still passing.

### F21 — [MINOR] FA-1 sits exactly on its own boundary — and that is my number, not the agent's mistake

```
kind     diameter px          target   margin
limb     19.5                 15.0     +4.5
passive  25.500000000000004   15.0     +10.5   <- float noise already visible
motor    28.5                 15.0     +13.5
foot     15.0                 15.0      +0     <- exactly on the limit
head     30.0                 30.0      +0     <- exactly on the limit
```

The comparison is `>=`, so it passes today. But foot and head have **zero margin**:
a different operation order (engine build, `Vector2` path, recomputed scale) can
yield `14.999999999999998` and turn a correct build red for no reason, and the
temptation would then be to weaken the target — losing the legibility floor that
made FA-1 meaningful in the first place.

- **Done when:** the FA-1 comparison uses an explicit **float-noise epsilon**
  (`pixels + 1e-9 >= target`), documented as float-noise-only, *not* legibility
  slack — a real 0.5 px regression must still fail. Do **not** change the radii:
  they were derived from D-10 clearance and the derivation hash is pinned.

---

## 3. Where M1 stands now

Verified and closed: review infra, pack provenance, claim guard, point/link
primitives, capped clock, atomicity, owner geometry constants, D-10 guard, visual
isolation, analytic FA-1/2/7.

Still `NOT RUN`: FA-3 (600-tick static scenes), FA-4 (Slug settle/sleep + lurch),
FA-5 (grip band), FA-6 (10-run success count), AC-201/202/204, A9 replay/stall/
frame-condition/baseline/bit-flip, tick cost, §10.6, all captures.

**Nothing blocks Part 3 now.** Creature bodies, feet and contact response are
authorised. The moment contacts exist, FA-5 and FA-6 stop being plans and become
the numbers that decide whether this game is worth building.

---

## 4. Paste-ready message to the coding agent

```text
R7 verification of PR #3 @ 0668d66: Commits A and B are ACCEPTED. I verified
everything myself rather than trusting the report:

- A/B separation is clean: A touches only accumulator.gd, check_m0_regression.py,
  tests and records; zero geometry. B is geometry only.
- F16: floors are 476/489 and the error message now uses the constants.
- F17: rollback_status is checked before the tick error; the forced-failure test
  grew integration checks 292 -> 299.
- B constants match my spec exactly. I checked with Decimal, including
  2.2 * 0.35 = 0.77 and the two untouched existing values (bias 1.4, slip 0.15).
- The D-10 guard is stronger than I asked: all 25 kind pairs, strict < 0.22, an
  equality negative control, an oversized-radius negative control, per-preset
  sibling pairs, and checked_pairs > 0 so it cannot pass by checking nothing.
- No head angular limit was invented; the Python test asserts that by regex.
- The scanner got STRICTER, not weaker: a new rule bans *_visual_radius_* in core/
  with only the declaration lines in tuning.gd exempt.
- Analytic honesty is real: FA-1/2/7 are "PASS (analytic only)" in both the
  annotations and the JSON; FA-3/4/5/6 carry observations: null; FA-6 success_count
  is null; and run_m1_feel.sh fails CI if any of those nulls becomes a number or
  if the 123 floor drops. Good design - the report cannot quietly become "evidence".
- Counts reproduced: primitive 381 (82 + 299), geometry 123, M0 500, Python 34
  (18 + 3 + 6 + 7). Both CI runs green.

Two findings, both small, both to fix before Part 3's acceptance claims land.

F20 [MAJOR] The FA gates are not inside the claim guard. I appended
"FA-6: PASS (8/10 successes)" to the real tracked matrix and
scripts/check_m1_matrix.py returned exit 0. Your guard only inspects pipe-table
rows, and the matrix has 32 rows with zero FA- gate cells - so the exact "ticked
box" fake the guard exists for is still open for the seven gates I created to make
this game's feel falsifiable.

Fix:
- Add FA-1 through FA-7 as rows in the gate table.
- Extend the status allowlist with exactly one scoped value, "PASS (analytic only)",
  permitted ONLY for FA-1, FA-2 and FA-7, and only with a citation (CI run or the
  geometry report path).
- FA-3, FA-4, FA-5, FA-6 stay NOT RUN.
- Negative controls in the PR body: "FA-6 | PASS (analytic only)" must now fail with
  exit 1 (today it silently passes), and "FA-1 | PASS (analytic only) | CI..." must
  still pass.

F21 [MINOR] FA-1 sits exactly on its own boundary and the margin is my number, not
your bug: foot is 15.0 px against a 15.0 target and head is 30.0 against 30.0. Your
own output already shows float noise elsewhere (passive = 25.500000000000004), so a
different operation order can produce 14.999999999999998 and turn a correct build
red. Fix the comparison, not the radii: use pixels + 1e-9 >= target, documented as
float-noise only, not legibility slack. A real 0.5 px regression must still fail.
Do NOT change the radii - they came from the D-10 clearance derivation whose hash
is pinned.

Then proceed with Part 3 as authorised: creature bodies, feet and contact response.
Order I want:
1. Creature model + feet + contacts, with the D-10 guard re-run against the real
   preset definitions, not just the topology fixtures.
2. FA-5 grip band, because it is cheap and it tells us immediately whether the
   ratio choice works: below 40% of creature weight slips, >= 40% grips, two-foot
   stance grips, airborne never grips.
3. FA-3 static 600-tick scenes, then AC-201 settle/sleep <= 4 s.
4. AC-202 stretch <= 0.05 WU over 2 min, then AC-204 200-run soak.
5. FA-4 and FA-6 last, because they need motors and a tutorial scenario.

FA-6 is not a polish item. Report the actual 10-run count. If it lands at 10/10 the
game is too easy to be interesting; at <= 4/10 it is frustrating. If either
happens, STOP and bring me the numbers with the input log and per-run outcomes -
do not retune the constants to hit 6-8.

Still NOT RUN until actually executed: FA-3/4/5/6, AC-201/202/204, A9 replay,
stall, frame conditions, baseline, bit-flip, tick cost, §10.6, captures.
No M2, no camera, no product screens. Keep the claim guard passing.
```

---

*End of R7 review. A and B accepted; F20 (guard coverage for FA gates) and F21 (FA-1 float margin) to land before Part 3 acceptance claims.*
