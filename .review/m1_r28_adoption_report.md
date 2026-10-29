# R28 adoption report — head 446d870da5c02ecfc295a19d7f35a8436b3b7fa7

**Adoption REJECTED and REVERTED.** This header identifies the measured adoption
head, not current production. Revert: `75fd3e7ff9f1e370831386f700757f8f26cacf3d`.
Single measurement [CI40970023755](https://github.com/sagheerh/clamber/actions/runs/40970023755),
job123784170344, engine status0, all3×7200 completed. Literal measured-source pins
now close all five new jobs against future markers. No physical retry.

## Adopted change

The exact-subject physics commit `446d870` made the existing final `_links`
traversal unconditional after all contact passes/`_finish_velocities`, at
`core/sim/coupled_load_probe.gd:359–366` **in that measured commit**. Traversal,
rows/order, compliance, multipliers and `project()` maths were unchanged; no
velocity edit or runtime physics selector. Diagnostic recording remains gated.
SleepingLoadProbe `_grounded_query` uses detached CapsuleBody clones, not live
endpoints; parked queries cannot introduce a new live-position length error.
This does not claim to repair an arbitrary already-invalid incoming snapshot.

D3 failed. A full `git revert 446d870` restored production core byte-for-byte to
session start `fb890fd`. **The adoption is not retained.** No alternate pass,
clamp/slop/epsilon/tolerance/iteration change or retune was attempted.

Tuning unchanged before/adoption/after: SHA256
`5f4d0d06564fb3a0847309d83cf5f3c87b9321ea5e2dd87e572e4bd9fe750666`;
P-B defaults30/10/0.5443327361211717/12 retained. No presets/save formats changed.

## Baseline & replay

**NOT RUN on the adopted build: D3 mandatory penetration stop.** Baseline job
123785570360 and public job123785571843 skipped. No generated fixture, new
input-log/final-state digest, adoption provenance or adopted same-source replay
exists. Never hand-updated a baseline/hash. The existing fixture is unchanged:
SHA256 `2779456f6a35338a97666bcec813608ae5bda83c612ec1d5b6560df62590f679`.
It is historical R26 evidence, **not** an adoption fixture. Engine/source/seed/
tick_hz/ticks/input-log/final-state/UTC/method provenance for a new baseline is
unavailable because generation was correctly blocked, not copied from old data.
Any later public replay on the reverted build is regression only, not D2.

## Penetration (limit0.02)

Completed post-pass capsule-surface penetration, WU; all original presets7200
ticks, fixed60Hz. Strict adoption requirement **<0.02**, no epsilon. Ticks zero-based.

| Preset | Completed ticks | Max penetration WU | Max foot penetration WU | Worst all-body sample | Verdict |
|---|---:|---:|---:|---|---|
| Slug | 7200 | 0.07028201067739755 | 0.07028201067739755 | foot2, tick6,u1 | FAIL → REVERT |
| Hopper | 7200 | 0.0933999293597247 | 0.0933999293597247 | foot5, tick7,u1 | FAIL → REVERT |
| TwinRoller | 7200 | 0.05075245867956493 | 0.048174420428044054 | motor1,tick2162,u1 | FAIL → REVERT |

All three meet the owner's stop condition; the first alone was sufficient.
Report verification passed; engine status0 and completion7200 on each preset.
Worst-sample radii/centres/SDF distance/normal/part/tick survive in evidenceJSON.
No inference that a length improvement fixes the positional rectifier/drift.

## AC-202 production row (limit0.05WU)

These are **production-configuration numbers during the now-reverted adoption**,
not a flag-selected candidate or current-build PASS. Metric is articulated
motor/passive/limb length error; Slug/Twin have no literal `limb` kind. Every
preset completed7200 ticks. Length PASS cannot override penetration FAIL.

| Preset | Completed-tick articulated max WU | Worst part/kind/tick | Limit WU | Length-only verdict |
|---|---:|---|---:|---|
| Slug | 4.996003610813204e-16 | 1/motor/6092 | 0.05 | PASS; adoption REVERTED |
| Hopper | 1.8318679906315083e-15 | 6/limb/5739 | 0.05 | PASS; adoption REVERTED |
| TwinRoller | 1.7763568394002505e-15 | 3/motor/5608 | 0.05 | PASS; adoption REVERTED |

## Idle family adopted build

**Entire prescribed from-spawn zero-input600 arm NOT RUN**, job123785570864
skipped by D3. No reference substitution, different-window result, cause/fix
inference or improvement retry. Deltas cannot be computed without adopted data.

| Metric | Accepted R27/reference | Adopted | Delta | Threshold | Verdict |
|---|---|---|---|---|---|
| AC-201a peak-to-peak | 35.34385590667538°; FAIL | NOT RUN | N/A | ≤15°/600ticks | NOT RUN: D3 stop |
| 201a signed min/max; all-airborne count | archived R27; no all-airborne escape | NOT RUN | N/A | same600/all ticks | NOT RUN: D3 stop |
| AC-201b from-spawn COM net | .6460243614279206WU=96.9036542141881px=.7178048460310229BL;9.69036542141881px/s; margin1.39313631766256 | NOT RUN | N/A | ≤.90WU=135px,10s | NOT RUN: D3 stop |
| AC-201s firstF52tick; sleeping count | none;0; FAIL | NOT RUN | N/A | firsttick<600 or none; unchangedF52 | NOT RUN: D3 stop |
| Signed lateral net COM speed, last300 | R26reference8.550150769956836px/s | NOT RUN | N/A | observational, no new pass limit | NOT RUN: D3 stop |
| Mean2D COM path speed,last300 | not substituted for signed-reference definition | NOT RUN | N/A | observational | NOT RUN: D3 stop |

The85.5px/.570WU reference is **not** the R27 from-spawn net96.903654px.
Original GDD ≤4s text remains; no weakening of F52/sleep rules. Reference values
are cited accepted archives, not a new R27 run. The .5BL criterion fails on that
R27 reference; .90WU is the authorized R28b threshold, not13.5px.

## AC-201a characterisation3600ticks

**NOT RUN**: job123785570911 skipped after D3, before idle600. Attitude°/s,
90°/180° crossing times, per-tick delta sign changes and last600 max|angle|:
all NOT RUN, with no inferred/extrapolated values. Reading **undetermined due
to absent3600tick measurement**, not a measured boundedness finding. This arm
was characterization only; no change to15°/600 acceptance window.

## Regression

- Adoption source M0 job123784170381: **516 checks,0 failures**; unchanged
  command/expectations. Primitive381/0 (82+299), contact component237/0.
- Local `review_checks.sh`: **226 controls,0 failures** on adoption and reverted
  source. Initial adoption CI static stopped188 controls/failure: archived
  `git show fb890fd` assertions need history absent from default shallow checkout.
  Regression-only static checkout now fetch-depth0; no assertion relaxation.
- CI evidence-commit outcome recorded separately below when available. Do not
  mislabel an initial source-CI failure as green.
- Tuning diff versusfb890fd **empty**. Current entire productioncore diff
  **empty** after full revert. No preset/save/M0 expectation edits. Changed files
  are harness/report/plan/baseline tooling, diagnostic input-log collection,
  archival/source checks, CI routing/history access, decisions/progress/matrix/
  evidence. No runtime physics change survives.
- D8 **only** historical F47 named diagnostic step is continue-on-error:true,
  preparatorycommit8bcb481; unchanged command, raw-artifact definition and
  `::error` annotation. Expected-red until M1.1, never FA/idle acceptance.
  Before: historical job123763105825 failure/F47. After: sourcejob123784170278
  failure from **artifact quota before F47**, F47 skipped. Therefore D8's
  after-diagnostic result is **NOT RUN**, not PASS; no CI-green claim.
- Historical R27/accepted200-run soak not rerun; FA3 **vacuous/uncredited**
  (0sleep/0wake), no carried narrow PASS. Same-build determinism attempt1 only,
  cross-architecture0 unchanged; no soak-based determinism claim.

## Not measured (blocker each)

1. New adoption baseline/provenance/digests and same-source public reproduction:
   **NOT RUN — D3 mandatory stop**, dependent jobs skipped, fixture unchanged.
2. Adopted idle600 family/drift, signed extrema/airborne/sleep/COM units/margins
   and R27 deltas: **NOT RUN — D3 stop**, job123785570864 skipped.
3. Adopted characterisation3600 metrics/classification: **NOT RUN — D3 stop**,
   job123785570911 skipped. Never extrapolated600 to3600.
4. Full raw JSON artifact delivery: **UPLOAD FAILED — GitHub artifact storage
   quota hit**; usage recalculation6–12h. Original raw-file hashes and numeric
   results survive in check annotations (retained verbatim in evidenceJSON),
   but hashes/annotations are **not full raw traces**. No fabricated archive,
   historical-artifact deletion, or physical retry. Direct log download also
   returned EOF from the restricted results-receiver host.
5. CI all-jobs-green and D8 after-diagnostic outcome: **blocked by artifact
   storage quota**; log-upload steps fail before F47/owner geometry steps. No
   upload step was quarantined or acceptance assertion weakened to hide this.
6. Device performance/60fps/reference tick cost/cross-architecture determinism:
   **NOT RUN — outside authorized R28 scope**, no device/build evidence for such
   claims. M2 remains blocked by owner review/failures/amendment.

## What this session did NOT do

No retune, sweep, brace, threshold/window/iteration/slop/epsilon adjustment,
clamping workaround, accepted-soak rerun, soak-as-determinism claim, second
R28 measurement arm, M1.1 rectifier fix, P2/P3, M1-complete/deviceperf/60fps/
reference-tick-cost claim. No reviewer files copied/committed/merged/rebased.
**Adoption reverted; wait for owner.**
