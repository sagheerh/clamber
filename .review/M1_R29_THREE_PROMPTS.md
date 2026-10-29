# M1 — R29: the three-prompt closeout plan (owner directive: finish M1 in ≤3 agent inputs)

**Recorded:** 2026-10-30. Owner directive: M1 has consumed too long; the remaining work is split into
**exactly three agent sessions, in order, each finished inside that session.**

**Authorisation this plan rests on**
- **AC-202 adoption is APPROVED** by the owner for this plan, under the three conditions in §P1-D3
  (provenance + replay on the adoption commit, penetration check, post-adoption idle re-measure).
- **No gate is relaxed, no threshold is changed, no metric is redefined, no number is re-authored.**
  AC-201a stays 15° / 10 s and stays FAILED at 35.344°.
- **M1 closes at 18/18 MEASURED**, not 18/18 passing. AC-201 and FA-4 fail with named causes;
  FA-3 is uncredited (vacuous without sleep); tick cost's reference-device leg is owner-blocked (D07).
- M1.1 (contact rectifier) is **out of scope** for all three parts. Nothing here may attempt to fix it.

---

## Session contract — read this before each of the three prompts

1. **One part per session. Finish it in that session.** Do not carry work forward into the next part
   unless this file says so, and do not start the next part early.
2. **When something cannot be measured, record `NOT RUN` + the exact blocker and move on.** Never
   fabricate, never extrapolate a reference value (my 1.58× was exactly that mistake), never substitute
   a different window for the specified one.
3. **No new physics except P1-D1.** No retuning of `physics_*`, `motors_*`, slop, epsilon or tolerances.
   No sweeps. No brace. No "quick try" to see if the creep improves.
4. **One CI invocation per arm.** Historical jobs are pinned `github.sha == '<sha>' && [Rn-once]`; update
   the pin to the head you are measuring and keep one invocation per mode. Doc-only commits use `[skip ci]`.
5. **Report in the same shape every time:** what was measured, the exact number, the gate verdict,
   what was not measured and why, and the artifact paths.

---

# PROMPT 1 — ADOPT AC-202 and re-measure everything the physics change touches

**Goal:** land the one authorised physics change, prove it did not break the baseline or the floor, and
re-measure the idle family on the adopted build. Ends with a green CI run on the adoption commit.

### D1 — Adoption (the only physics change in M1)
Make the R27 candidate the **production** path: the identical final link-projection traversal that you
already wrote and measured (`coupled_load_probe.gd`, the `diagnostic_final_distance_pass` block — same
rows, same compliance, same multipliers, same `project()` implementation, no velocity edit) runs **after
all contacts, always**, in the production tick path used by the public Sim. Remove the diagnostic flag
from the production path; the probe may keep its parameter only as a comparison arm.
**No algorithm change, no parameter change, no reordering of anything else.**

Commit message must name it: `M1: adopt AC-202 post-contact distance reprojection (physics change)`.
Add a `DECISIONS.md` entry: what changed, why, the R27 evidence reference, and the before/after numbers.

### D2 — Baseline with provenance + replay on the adoption commit
Regenerate `tests/fixtures/public_sim_baseline.json` **on this commit**, recording: engine `4.7.2-stable`,
tuning sha256, source commit sha, seed, fixed 60 Hz, tick count, and the full hash. Then run the
`public-sim-runtime` job **on this commit** and show the replay reproducing the committed baseline exactly.
Do not hand-edit the fixture; generate it.

### D3 — Penetration check (adoption condition #2)
Reprojection moves bodies; moving a body can push a foot into the floor. For all three presets, over
**7200 ticks each**, record **max penetration depth after the appended pass** and compare against
`physics_contact_slop_wu` (**0.02**). Report the number per preset.
**If any preset exceeds 0.02: STOP, report, do not adopt, do not touch the slop.** Do not tune around it.

### D4 — AC-202 re-verified as the production path
Same three 7200-tick runs must show completed-tick articulated-limb max ≤ 0.05 WU (expect roundoff,
as measured: 5.0e-16 / 1.8e-15 / 1.8e-15). Record that these are now **production** numbers with no
`candidate_enabled` column, because there is no longer a candidate.

### D5 — Idle-family re-measure on the adopted build (required by the change, not by hope)
Unchanged metrics, unchanged thresholds, from spawn:

| row | metric | threshold |
|---|---|---|
| AC-201a | peak-to-peak attitude change over 600 ticks, zero input | ≤ 15° |
| AC-201b | net COM displacement over 600 ticks | ≤ 0.90 WU = 135 px = 1.0 BL |
| AC-201s | first F52 sleep tick, unmodified policy | must fire within 10 s |
| drift arm | mean COM speed, last 300 ticks, idle | report (R26 reference 8.55 px/s) |

**A better or worse result is both acceptable — record it.** If the creep improves, log the delta; if it
gets worse, log the delta. Do not tune toward improvement, and do not re-run hoping for a different number.

### D6 — AC-201a characterisation (one extra arm, harness already exists)
Add **one** 3600-tick (60 s) zero-input arm reporting: attitude change per second, time to 90°, and whether
the rotation is **monotone (toppling)** or **bounded (settling into a tipped pose)** — e.g. sign changes of
the per-tick attitude delta, and the max |angle| in the last 600 ticks. This is characterisation for the
M1.1 handoff, not a new gate. **Do not change 15°, the 10 s window, or the 201a verdict.**

### D7 — Regression
Local Python controls: **≥218**, all passing. M0 headless suite unchanged (516/0). `core/tuning.tres`
diff shows **only** what D2's provenance requires — the four P-B values must read
30.0 / 10.0 / 0.5443327361211717 / 12.0 before and after. Run the static guard.

### Done means
Adoption committed and pushed; baseline regenerated and replay green **on the adoption commit**;
penetration reported and under 0.02; AC-202 production numbers logged; D5 four numbers logged;
D6 three numbers logged; D7 green. `.review/m1_r28_adoption_evidence.json` + a short report committed.

### Stop and report instead of continuing if
Penetration ≥ 0.02 → revert the adoption commit, report, wait. Any non-finite state in D4/D5 → report the
first tick and the trace, do not heal it. Any temptation to change a threshold → stop and ask.

---

# PROMPT 2 — Measure the five remaining gates on the adopted build

**Goal:** every unmeasured row gets a number. Nothing here changes physics; all five rows go from
`NOT RUN` to a verdict with an artifact. This is the heaviest session — budget for it and do not
start P3 in it.

### D1 — Three presets + 10 s captures (E4 artifacts)
For each of the three presets, with **one identical documented L/R input log** and identical seed:
- a **600-tick capture committed as `.json`** (per-tick COM, part positions/angles, contact/grounding
  flags, input mask, seed, tick index) — this is the E4 "capture";
- a data-rendered **PNG/SVG plot** generated from that JSON (no camera, no scene, no product screens);
- a shared trace manifest: same input digest, same seed, three preset ids.
Then prove "three different motions" **objectively, without inventing a threshold**: per-tick trace
hashes must differ pairwise (hash inequality is binary, not a threshold), and report the quantitative
divergence (e.g. mean pairwise COM separation in WU, and final poses) as numbers for the owner.
If the gate needs a numeric distinctness threshold, **report the numbers and flag it; do not author one.**

### D2 — Tick cost §10.4
Measure solver tick time at **30 bodies / ≤120 constraints** and record the actual constraint count.
Protocol: warm-up discarded, ≥10 000 ticks, report **median and P95**, plus the hardware string and the
build. Threshold ≤ 3.0 ms. **Label the hardware honestly:** a GitHub runner is x86-64 shared cloud, not a
Snapdragon 660 — so this row reads *measured on CI hardware, reference-device leg NOT MEASURED (owner
D07)*. Do not claim a mobile pass. Attach the raw timing file.

### D3 — §10.6 step 1 only
Fixed scenario, **10 000 ticks, 100 local repeats, final-state hash identical across all 100**. Log all
100 hashes. Steps 2–3 (cross-architecture, 5 devices) stay **NOT RUN** — no hardware, and a CI runner is
not an architecture matrix. Step 4 already has its 200-run soak result; **do not re-run it and do not
present it as determinism** (F78: physics does not consume the RNG, so the soak's seed diversity is
nominal).

### D4 — FA-4
The Slug, zero input: settle + sleep within 4 s, and one L-hold lurch ≈ one body length. Measure both on
the adopted build and **report the actual numbers**; sleep is expected to fail (AC-201s). Also report the
lurch against the owner's open question — is 1.00 BL a **spec** value or a **scale** value? Present the
measured distance in WU, BL and px; **do not pick the interpretation**. Do not convert the working-window
mean into a new ceiling.

### D5 — FA-6
Ten runs of the **identical** scripted input, reporting all ten outcomes and the input log. Target band
6–8 successes; stop on 10 or at ≤4. **State the variance source explicitly** (this is what F78 demands):
if physics does not consume the RNG, identical runs cannot diverge — so either name the real non-RNG
variance source you vary (spawn offset / pose / tick-indexed input), or report honestly that the ten runs
are identical by construction and the gate is currently **insensitive**. If the scenario needs a tutorial
chunk that does not exist in M1, record the substitution explicitly.

### Done means
Five rows carry measured verdicts; artifacts committed (`tests/fixtures/m1_captures/*.json`,
`*.png`, timing log, 100-hash log, FA-4/FA-6 tables); `.review/m1_r29_measurement_evidence.json`
with one entry per row containing `{gate, metric, value, threshold, verdict, artifact, not_measured}`.
CI green on the measurement commit.

### Stop and report instead of continuing if
Any gate needs a new threshold or a redefined metric → stop, report, ask. Any measurement needs a
tutorial chunk or product screen that does not exist → record the substitution, do not build product code.

---

# PROMPT 3 — Assemble the M1 verdict and hand back

**Goal:** zero new physics, zero new metrics. Turn the measured record into a signable M1 closeout.

### D1 — 18-row matrix, final
Fill `.review/m1_ac_matrix.md`: every row `PASS`, `FAILED`, `NOT CREDITED`, or `NOT RUN` with the exact
number, artifact path, and for every non-pass a **named, scoped follow-up**. Row count stays 18; no row is
deleted, merged or renamed to change the denominator.

### D2 — Verdict artifacts
`.review/m1_verdict.md` + `.review/m1_verdict.json` with: the 18 rows, the credited total, the runtime
ledger (18 slots / measured / production-operational), the determinism attempts (same-build 1,
cross-architecture 0), every open owner decision, and an explicit list of **failures with causes**:
AC-201a (monotone topple 3.53 °/s), AC-201s (never sleeps), FA-4 (sleep-dependent), FA-3 (vacuous —
uncredited, not "passing"), tick cost (reference-device leg owner-blocked).

### D3 — Owner decision sheet (short, 4 items max)
1. AC-202 adoption is landed — confirm.
2. **D07** reference-device tick cost — needs the phone.
3. **FA-4's 1.00 BL** — spec or scale.
4. **M1.1 scope** sign-off: the contact position-correction rectifier (F75 mechanism of record), which is
   the single named cause of AC-201a, AC-201s and FA-4.

### D4 — Record hygiene
Update `PROGRESS.md` (M1 = measured-complete, M2 blocked), the test-count non-regression line
(**≥218** Python controls, M0 suite unchanged), and state in one sentence that no gate was relaxed and no
threshold changed during M1.

### D5 — Five-fakes self-audit (A12)
Write the short honest version of the five traps against our own artifacts: borrowed artifact (nothing
reused from M0), cherry-picked run (report the failing arms beside the passing ones), unit confusion
(WU vs BL vs px stated per number), determinism claimed from repetition (F78 named), and green-by-absence
(FA-3 named as uncredited, not as a pass).

### D6 — PR ready for review
Mark PR #3 **ready for review** (not merged), with the verdict summary at the top and links to every
evidence file. Do not merge, do not tag, do not start M2.

### Done means
Matrix complete, verdict files committed, decision sheet in the PR body, PROGRESS updated, CI green on the
closeout commit, PR ready-for-review.

### Stop and report instead of continuing if
Any row still has no number → say so plainly at the top of the verdict and keep M1 **not signed**.
Do not fill a gap with a claim.

---

## Why this split (one line each)

- **P1 is physics then measurement** — everything downstream must be measured on the adopted build, so the
  change cannot come later.
- **P2 is pure measurement** — five rows, no design decisions, the only session with real CI volume.
- **P3 is writing and signoff** — no code, so it cannot drift, and it is the part that must never be rushed.

**Expected close:** **16 of 18 passing** (11 now + presets/captures + §10.6 + FA-6 + tick cost on CI
hardware), **AC-201 and FA-4 failing with named causes**, **FA-3 uncredited**, **D07 open on the owner's
phone**. That is a complete, honest M1.
