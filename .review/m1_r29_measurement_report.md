# R29 measurement report — head fe56aadd936a167ee10487951c33f824a045fc07

## Resumption from eee6c81 — runner proof blocked, arms NOT LAUNCHED

The mandatory trivial zero-physics runner proof was attempted FIRST, source
fe56aad/[R29-runner-proof], CI40980478102/job123818988944. GitHub did not start
it: **steps[], zero runnersteps, zero engine/measurementticks**. Exact annotation:

> The job was not started because recent account payments have failed or your spending limit needs to be increased. Please check the 'Billing & plans' section in your settings

The proof therefore did not pass. **[R29-once-3] was NOT activated; the five arms
were NOT launched/re-pinned to a measurement source.** Old marker2 remains
literally closed tobb88cd1. No proof retry, alternate execution or new arm attempt.
L1 andL2 are **zero-tick launch incidents, neither measurement evidence nor arm
failures**. RP1 is a preflight allocation failure, also not an arm failure.
Check metadata/annotations committed under `m1_r29_launch_incidents/RP1-*.json`.
No D0 rerun, physics/tuning edit, AC202readoption or P3. The D0 correction and
original measurements below remain unchanged; all D1–D5 values remain NOT RUN.

Original startingfacts remain recorded:4796ec6, productioncorebyteequalfb890fd,
tuningSHA2565f4d0d06564fb3a0847309d83cf5f3c87b9321ea5e2dd87e572e4bd9fe750666,
controls226/0, M0516/0, checksumGodot4.7.2.stable.official.ed1daf0bf.
These were verified before originalD0, NOT fresh CI results from this blockedlaunch.

## D0 penetration control (reverted build)

D0was NOT rerun. Source819cefc / CI40974609556,7200ticks/preset, unchangedrawdata.

| preset | reverted max WU | adopted max WU (R28) | adopted/control | worst control tick / part/kind/u | verdict |
|---|---:|---:|---:|---|---|
|Slug|0.020000000000000823|0.07028201067739755|3.514100533869733|22 / 0/head/0|CONTROL — AT SLOP (0.02 + roundoff)|
|Hopper|0.020000000000000823|0.0933999293597247|4.669996467986043|33 / 0/head/0|CONTROL — AT SLOP (0.02 + roundoff)|
|TwinRoller|0.020000000000000823|0.05075245867956493|2.537622933978142|15 / 0/head/0|CONTROL — AT SLOP (0.02 + roundoff)|

Designed physics_contact_slop_wu=.02. Absolute excess8.22e-16WU, relative4.11e-14:
roundoff at the designed slop, **not a pre-existing penetration defect**.
Corrected report-only defect test is **>0.02*(1+1e-9)**, never bare>=.02.
No physics slop/epsilon/tolerance/tuning value was changed.

**The reprojection multiplies penetration2.5–4.7× above the designed slop;
AC-202 as adopted is dead on the evidence. F79 is WITHDRAWN.**
Keep the earlier caveat: the control does not establish that the reprojection
cannot increase its maximum. AC202remainsFAILEDforM1, no readoption; reevaluate
only insideM1.1aftercontactrectifierfix, not this session.

## D1 presets / captures

|preset|trace sha256|distinct?|10s COM path|final pose|plot|
|---|---|---|---|---|---|
|Slug|NOT RUN|NOT RUN|NOT RUN|NOT RUN|NOT RUN|
|Hopper|NOT RUN|NOT RUN|NOT RUN|NOT RUN|NOT RUN|
|TwinRoller|NOT RUN|NOT RUN|NOT RUN|NOT RUN|NOT RUN|

Required RP1proof never started, so no arms were launched: no captures/manifest/plots generated; no reference or window
substitution. Capture footprint0 is NOT a completed capture deliverable.

## D2 tick cost (3.0 ms not applied as pass/fail)

|row|actual bodies / constraints|median / P95|status|
|---|---|---|---|
|Hopper alone, mandatory real row|NOT RUN / NOT RUN|NOT RUN / NOT RUN|NOT MEASURABLE AS SPECIFIED; execution NOT RUN|
|Ten independent Slugs, labelled30capsule aggregate|NOT RUN / NOT RUN|NOT RUN / NOT RUN|NOT MEASURABLE AS SPECIFIED; execution NOT RUN|

No timing file/hardware/build measurement exists: no runner started. Planned
1000warmupdiscarded/10000samples for both existing directtick/publicframe+tick
entrypaths was not executed. Actual constraint counts must not be filled from
reference.3.0ms is NOT a PASS/FAIL predicate. **Reference-device leg NOT MEASURED
(D07).** Optional14part test-only fixture not run; no product geometry authored.

## D3 §10.6 step 1

**100/100 identical: NOT RUN | hash NOT RUN | steps2–3 NOT RUN**.
This resumption executed0repeats/0ticks; no hashlog exists. Steps2–3 lack crossarchitecture/
five-device hardware. No soak rerun or repetition-as-independent-determinism claim.

## D4 FA-4 | D5 FA-6

|measurement|value|status|
|---|---|---|
|FA4settle/sleep within4s|NOT RUN|no runner/ticks|
|FA4lurch WU / BL / px|NOT RUN / NOT RUN / NOT RUN|no runner/ticks|
|FA6ten outcomes/input execution|NOT RUN (0executed)|no runner/ticks|

D4protocol remains zero240/L60/released240; 1.00BL spec-vs-scale is the owner's
call, no new tolerance or ceiling. AcceptedAC201sleep counts are not substituted.
D5planned identicalL60/released240, seed305419896/spawn/pose identical, variance
source **NONE**. The authored tutorial chunk/goal/successpredicate is absent;
flatplane was the explicit substitute. If executed it would be insensitive by
construction: an insensitive finding is not a failure. Here no ten-run finding
was measured; all outcomes/success_count remainnull, not0or10 fabricated.

## Regression

- Local reviewcontrols **232/0**; no existing assertion/floor weakened.
- `git diff4796ec6..HEAD -- core/`: **EMPTY**. Tuning byteidentical SHA256
  `5f4d0d06564fb3a0847309d83cf5f3c87b9321ea5e2dd87e572e4bd9fe750666`.
- No presets/save/M0expectation edits. Changes are docs/tests/workflow/fixtures/
  testregistration only; no physics/adoption/retune.
- Fresh resumption M0 **NOT RUN**: runnerproof blocked before reaching arms/D7.
  Historical L2 CI40979233773 headlessjob123814811476 also had steps[]. Lastverified **516/0**, source2041793/job123808676727, is historical
  proof—not relabelled as a fresh test. CI all-green is NOT claimed.

Launchaccounting:
- **L1:** source8dfe959/CI40976842113, inherited_checked/helper collision,
  zero ticks; committed `m1_r29_raw/D[1-5]-engine.log` retained unchanged.
- Correctedhelper compile-only source2041793/CI40977382604 succeeded. This is
  compile evidence ONLY, never a measurement or validation of newHopper timings.
- **L2:** sourcebb88cd1 / CI40979233978, measurementsjob123814811746,
  **steps[], zero runnersteps, zero ticks**. Check annotation:
  > The job was not started because recent account payments have failed or your spending limit needs to be increased. Please check the 'Billing & plans' section in your settings
- No runner/engine log exists forL2. The actual check annotation/job/run metadata
  are committed under `tests/fixtures/m1_r29_launch_incidents/`.
- Both failedlaunches are distinct. L2is billing/spending-limit infrastructure,
  NOT another compiler or physics failure and NOT artifactstoragequota.
- Historical L2closeout kept marker2 closed tobb88cd1; owner now explicitly
  classifies L1/L2 as launchincidents, NOT armfailures. Resumption awaits required
  runnerproof; marker3notactivated. No artifactdeletion or alternate execution.

## Not measured

D1–D5 and fresh current-head engine/M0regression: exact RP1billing/spending-limit
annotation above; mandatory proofjob never started and no arms were launched. No captures/timings/hashes/lurch/outcomes or
hardware string fabricated. D07/crossarchitecture/five-device legs: no hardware.
Tutorialsuccesspredicate and 1BLinterpretation remain open. No frame-only optimized
transactionmode exists; no corechange authorized to create it.

No P3, AC202readoption, retune/sweep/brace, physics slop/epsilon/tolerance/iteration
edit, acceptedsoak rerun, FA3credit, penetration/creepfix, mobileperformance or
M1complete claim. **Awaiting successful runner proof; no arm failures or executions in this resumption.**
