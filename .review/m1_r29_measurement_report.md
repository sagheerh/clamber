# R29 measurement report — head 8dfe959fe3587cd4f1cbf978c9c28f7186352689

D0 measured on **819cefc4ce9b66e6f8725d1ed24694e85e8f5154**;
D1–D5 attempted on header head but **NONE EXECUTED: harness compile error**.
[Control CI40974609556](https://github.com/sagheerh/clamber/actions/runs/40974609556)
SUCCESS; [remaining CI40976842113](https://github.com/sagheerh/clamber/actions/runs/40976842113)
FAILURE. No arm retried. This is measurement accounting, **not P3's verdict**.

All six starting facts VERIFIED before D0:

| Fact | Verified value |
|---|---|
| Session-start head |4796ec632637053214b1463f44120eb54cd17d72|
| Tuning SHA256 |5f4d0d06564fb3a0847309d83cf5f3c87b9321ea5e2dd87e572e4bd9fe750666|
| Production core |byte-identical tofb890fd; AC202adoption reverted|
| Controls |226/0 fresh preflight scripts/review_checks.sh|
| M0 |516/0 fresh preflight, unchanged suite/expectations|
| Engine |Godot4.7.2.stable.official.ed1daf0bf, release SHA512checksum verified|

## D0 penetration control (reverted build)

Same inherited R28 sampler, three presets,7200ticks each; same input
`(tick//60)%4`, seed305419896, materials/geometry, registered±64WU uniformplane.
Production diagnostic projection remains OFF. Per-tick worstsample plus all
bodyendpoints/radii/kinds committed as gzipJSONL;21600rows independently audited.
Unrounded maxima below; **no epsilon** applied at the0.02boundary.

| preset | reverted max WU | adopted max WU (R28) | worst tick reverted | limit | attribution |
|---|---:|---:|---:|---:|---|
|Slug|0.020000000000000823|0.07028201067739755|22|0.02|PRE-EXISTING; ratio0.2845678404364825|
|Hopper|0.020000000000000823|0.0933999293597247|33|0.02|PRE-EXISTING; ratio0.2141329242656268|
|TwinRoller|0.020000000000000823|0.05075245867956493|15|0.02|PRE-EXISTING; ratio0.3940695785060293|

Worst control samples: **part0/head/u0.0 on all three**, normal[0,1], radius.1WU,
SDF distance.07999999999999918WU. Adopted worstticks6/7/2162 are accepted R28
references, not rerun/re-derived. Control maxima all violate the strict limit.

**Owner attribution rule, unchanged:**

| Control result | Mandatory conclusion |
|---|---|
|≥0.02 at similar magnitude|penetration is PRE-EXISTING; the reprojection is not demonstrated to cause it; F79 stands as its own defect|
|≤0.005|the reprojection causes it; AC-202 as adopted is dead|
|in between|partially causative; report both numbers, conclude nothing stronger|

All controls≥.02; comparison is .02 versus .05075–.09340WU, with exact ratios
reported, not a newly authored similarity cutoff. This demonstrates penetration
already exists without the reprojection. It **does not establish that the
reprojection cannot increase the maximum**. Ownerdisposition unchanged:
**AC202FAILEDforM1, no readoption; reevaluate insideM1.1 after rectifier fix**.
D0 informs that work only; no fix/clamp/slop/retune followed it.

## D1 presets / captures

| preset | trace sha256 | distinct? | 10 s COM path | final pose | plot |
|---|---|---|---|---|---|
|Slug|NOT RUN|NOT RUN|NOT RUN|NOT RUN|NOT RUN|
|Hopper|NOT RUN|NOT RUN|NOT RUN|NOT RUN|NOT RUN|
|TwinRoller|NOT RUN|NOT RUN|NOT RUN|NOT RUN|NOT RUN|

Exact blocker: test script did not load. Godot reported
`Parse Error: Member "_checked" is not a function` at
`res://tests/sim/test_r29.gd:111`. The new helper collided with inherited R27
integer member `_checked`. **Zero ticks, no captures/plots/manifest produced**.
This was an agent-authored harness defect, **not artifact quota or physics**.
No trace hashes, motion-divergence values or final poses were fabricated.
Planned same seed305419896/input600t was not executed. No distinctness threshold
was authored. Capturefile footprint0bytes is NOT a completed deliverable.

## D2 tick cost (limit 3.0 ms)

**NOT RUN — same compile blocker, zero timed ticks.**

- Bodies: planned30, actual NOT RUN.
- Constraints: actual NOT RUN; no reference count substituted.
- Median / P95: NOT RUN / NOT RUN; no raw timing file exists.
- Hardware/build for timing: NOT RUN; no timing hardware string fabricated.
- Method planned: owner-selected ten independent productionSlugs/30capsules,
  aggregate not one coupled30body creature;1000warmupdiscarded then10000samples
  each for directtransactional tick and publicframe-plus-tick entrypaths;
  structural objects/scalarrows/contactworkload separately recorded.
- **Reference-device leg: NOT MEASURED (owner D07).** A future GitHubrunner
  result would be x86-64sharedcloud, not Snapdragon660. No mobile budget claim.
- Frame-only optimized transaction configuration: NOT RUN, not implemented;
  implementing it would violate zero-core-change scope.

## D3 §10.6 step 1

**100/100 identical: NOT RUN | hash: NOT RUN | steps2–3: NOT RUN**

Step1 blocker: same harness compilation failure;0 of100repeats executed,
no100hashlog exists. Steps2–3 blocker: no crossarchitecture/five-device hardware.
No local repeatability or independent RNG-driven determinism result is claimed.
F78unchanged; accepted200/200soak was NOT rerun or relabelled as determinism.

## D4 FA-4 | D5 FA-6

| Measurement | Value | Threshold / interpretation | Verdict |
|---|---|---|---|
|FA4 settle/sleep tick and count|NOT RUN|within4s; unchangedF52|NOT RUN: compilation|
|FA4 L-hold lurch WU / BL / px|NOT RUN / NOT RUN / NOT RUN|approx1BL, interpretation OPEN|NOT RUN: compilation|
|FA6 ten outcomes|NOT RUN (0executed)|target6–8, stop10or≤4|NOT RUN: compilation + absent tutorial predicate|

FA4 proposed protocol: zero0..239, L240..299 (60tickhold), released300..539.
It was **not executed**; acceptedAC201s0sleep is NOT substituted as FA4data.
**Is1.00BL a spec value or scale value? OPEN owner question.** No interpretation,
approximate tolerance, working-window ceiling or replacement settling metric chosen.

FA6 proposed substitute: existing uniformplane because authored tutorialchunk/
goal/successpredicate do not exist in M1; same pose/seed305419896, L0..59,
released60..299, identical absolute input on allten. **Variance source NONE**;
physics does not consume RNG (F78). Such a setup is insensitive by construction,
not an observed ten-run result here. No success count0or10 invented; countnull.
Historicalvarying-onset list was not silently substituted. Success-band/early-stop
rules cannot be evaluated without the tutorial success predicate. No product
chunk/scene was built to fill this gap.

## Regression

| Check | Result | Committed proof |
|---|---|---|
|Controls after attempted arms|232/0|tests/fixtures/m1_r29_raw/D7-static.log|
|M0 after attempted arms|516/0|tests/fixtures/m1_r29_raw/D7-m0.log|
|Tuning SHA256|5f4d0d06564fb3a0847309d83cf5f3c87b9321ea5e2dd87e572e4bd9fe750666|byteequalstart|
|git diff4796ec6..HEAD -- core/|EMPTY|no productphysicschange|
|Preset/save/M0expectation edits|NONE|unchanged|

Changedfiles: documentation/evidence, tests/harnesses/reports/fixtures, dedicated
workflow and testregistration `scripts/review_checks.sh` only. M0 count remains
514+2compilechecks=516. M0/editorimport/gdlint passing **did not validate** the
measurement script's inherited-member binding; they are not a runtime PASS.

D6launchpath restored FIRST incommitdafd3c1. Two push-only immutable-source CI
runs: D0oneinvocation; D1–D5oneinvocationeach in the secondworker. Sourcepins now
closed literally to819cefc4ce9b66e6f8725d1ed24694e85e8f5154 and
8dfe959fe3587cd4f1cbf978c9c28f7186352689. NO dispatch, NO artifactdelete attempt,
NO artifactuploadstep. Both workers committed their existing evidence directly
to the same branch with [skipci], so logs/data survived quota. Historical
marker-pinned R1x–R28measurement jobs remain pinned/unrun; routine regression
jobs are not those arms. LegacyM1uploadquota failures remain infrastructure
exceptions; **R29remainingworkerRED is a harness error, not that exception**.
No all-CI-green claim. Reporter also failed on null missingpayload after D7;
this report now records missing measurements explicitly instead of claiming data.

Helper renamed to `_checked_step` for future use, with a separate Godot
**--check-only** validation (no initialization/no measurementticks). No R29arm
was retried after correction. Compile-only outcome is recorded in evidence when
available; it cannot retroactively turn D1–D5 into measured results.

## Not measured

1. D1captures/plots/manifest/hashdistinctness/COMdivergence/finalposes: harness
   parse error at `_checked`,0ticks; no retry, no reference substitution.
2. D2median/P95/actualconstraintcount/hardware/rawtimings: same error,0samples.
3. D3all100hashes/10000tick repeats: same error,0repeats.
4. D4settle/sleep/lurch numbers: same error,0ticks;1BLmeaning additionally OPEN.
5. D5tenoutcomes/inputexecution/successband: same error,0runs; additionally
   missing tutorialchunk/successpredicate. VarianceNONE was planned, not measured.
6. D07referenceperformance and §10.6steps2–3: no reference/crossarchitecture/
   five-device hardware. Frame-onlyoptimized transactionmode: absent; no coreedits.

No P3verdict, adoption, retune, slop/epsilon/tolerance/iteration change, accepted
soak rerun, FA3credit, creep/penetrationfix, mobileperformance or M1complete claim.
