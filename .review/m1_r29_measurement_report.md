# R29 measurement report — head 534f5f53966be38b9cae171ba11e223403e8fbc4

D0 corrected by reviewer5ed8fca; F79 WITHDRAWN. L1 is a launch incident, zero ticks; logs retained. This report contains L2 first executions, not compile-only measurements. No P3 or adoption.

Start facts: {"tuning_sha256": "5f4d0d06564fb3a0847309d83cf5f3c87b9321ea5e2dd87e572e4bd9fe750666", "core_diff_fb890fd": "EMPTY", "controls": 226, "control_failures": 0, "M0": 516, "M0_failures": 0, "engine": "4.7.2.stable.official.ed1daf0bf", "engine_checksum": "SHA512-SUMS release manifest verified in CI"}

## D0 penetration control (reverted build)
| preset | control WU | adopted WU | adopted/control | verdict |
|---|---:|---:|---:|---|
|Slug|0.020000000000000823|0.07028201067739755|3.514100533869733|CONTROL — AT SLOP (0.02 + roundoff)|
|Hopper|0.020000000000000823|0.0933999293597247|4.669996467986043|CONTROL — AT SLOP (0.02 + roundoff)|
|TwinRoller|0.020000000000000823|0.05075245867956493|2.537622933978142|CONTROL — AT SLOP (0.02 + roundoff)|
Roundoff-aware comparison: >0.02*(1+1e-9). The reprojection multiplies penetration2.5–4.7× above designed slop; AC202as adopted is dead on evidence. No preexisting penetration defect; F79 WITHDRAWN. The control does not establish that reprojection cannot increase its maximum.

## D1 presets / captures
|preset|trace sha256|distinct?|10s COM path WU|final COM / pose|plot|
|---|---|---|---:|---|---|
Pairwise mean COM separation WU: {}
Capture bytes: None; shared seed305419896,600ticks; full pose/input/digests in committed manifest. Hash inequality binary, no numeric distinctness threshold authored.

## D2 tick cost (3.0 ms NOT applied as pass/fail)
All rows NOT MEASURABLE AS SPECIFIED; reference-device leg NOT MEASURED (owner D07). Hopper alone mandatory; SlugAggregate = ten independent real Slugs, not one coupled30body creature. Both existing entrypaths measured; frame-only optimized mode absent.
|workload / path|bodies|structural constraints|median ms|P95 ms|hardware|
|---|---:|---|---:|---:|---|
1000warmup discarded;10000samples/path/workload; nearest-rankP95. Raw CSVs and CPU/build committed;3ms is not a PASS/FAIL gate for these rows. Optional14partfixture NOT RUN/not needed.

## D3 §10.6 step 1
NOT RUN; see blocker below.
All100 hashes logged if completed; local repeatability only, NOT independent RNG/crossarchitecture determinism evidence. Steps2–3 NOT RUN/nohardware; acceptedsoak not rerun.

## D4 FA-4 | D5 FA-6
### D4/sleep — NOT RUN
```json
null
```
### D4/lurch — NOT RUN
```json
null
```
### D5 — NOT RUN
```json
null
```
1.00BL spec vs scale remains ownercall; no approximate lurch threshold/ceiling authored. FA6 variance source NONE, existing flatplane substitute for absent tutorial; no invented success predicate.

## Regression
null
Zero core/tuning changes, no preset/save/M0expectation edits. No artifactuploads/deletion. L1logs retained; any further arm failure stops later arms. No all-workflows-green claim (legacy artifactquota).

## Not measured
- D07/referencehardware; crossarchitecture/five-device legs: nohardware.
- Authored tutorial success band: chunk/goal predicate absent; ten substitute outcomes are a finding, not fabricated successes.
- Frame-only optimized transaction mode absent; optional14part fixture not run.
No P3, adoption, retune, physics/slop/solver epsilon/tolerance/iteration edits, acceptedsoak rerun, FA3credit or M1complete claim.
