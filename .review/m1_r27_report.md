# M1 R27 — measured results, including the unexpected stability failure

**R27’s bounded work is measured. M1 is not complete; M2 remains blocked.**

Source: `2cf2c9376556feca5698ba176c63514f37284bed`,
[CI40960697692](https://github.com/sagheerh/clamber/actions/runs/40960697692).
Machine-readable reports, job IDs and artifact SHA-256 digests are in
[`m1_r27_evidence.json`](m1_r27_evidence.json). The owner’s reviewer commit
`57ed0986999aba69f6e6296d7c131db3d894d307` was read readonly, never copied.
The pre-outcome contract is [`m1_r27_plan.md`](m1_r27_plan.md) and
`tests/fixtures/r27_plan.json`; neither was revised after outcomes.

## AC-201 — committed defaults, 600 zero-input ticks from spawn

| Clause | Measurement | Owner limit | Verdict |
|---|---|---|---|
| 201a: airborne conjunct | Zero all-parts-airborne ticks | Zero | This conjunct passes |
| 201a: attitude conjunct | Maximum spawn-relative head-to-foot change **35.34385590667538°**; peak-to-peak span identical | ≤15° | **FAIL** |
| 201b: parked | Net COM displacement **0.6460243614279206 WU = 96.9036542141881 px = 0.7178048460310229 BL** | ≤0.90 WU / 135 px / 1 BL | **PASS**, margin **1.39313631766256×** |
| 201s: unmodified F52 | Never fired; **zero sleeping ticks** | Within 10 s | **FAILED**, named M1.1 carry-over |

All 600 ticks completed, status0, no failing tick. Initial head-centre → mean
foot-centre vector was `[0.175, -0.425]` WU. Every completed tick was tested:
no endpoint-only test, startup exclusion, post-outcome vector redefinition or
threshold change. **The expected 201a/b pass was falsified.** Passing b does
not make the a+b operational composite pass. Name a’s follow-up **M1.1 posture
investigation / owner review**; its cause has not been isolated here.

Actual COM delta was `[0.5523594135041676, -0.3350321684132505]` WU. Thus the
96.904 px Euclidean displacement includes approximately 82.854 px horizontal
translation and 50.255 px vertical settling. The owner’s **85.5 px / 0.570 WU /
0.633 BL / 1.58×** is the steady-creep × 10 s **reference**, not this from-spawn
measurement. A 0.5 BL bound fails the actual result too. **13.5 px/s** is the
disclosed horizontal steady-extrapolation flip boundary; the actual gate uses
the 2D net displacement. Neither disclosure changes the authored 135 px limit.

The original GDD **“settles and sleeps within 4 s”** text remains, with a
pointer to the owner decision. It is not met, removed, relabelled or waived.

## AC-202 — one post-contact correctness arm, reported for adoption

The **same** distance traversal now runs **once after both contact passes**.
Rows, projection implementation, compliance, multipliers, iterations, tuning
and velocities are unchanged. Its diagnostic flag is **false by default**.

| Preset | Completed ticks / status | Articulated motor/passive/limb maximum WU | Literal-kind limb maximum WU | Head maximum WU | Foot maximum WU |
|---|---|---|---|---|---|
| Slug |7200 / 0|4.996003610813204e-16|Absent, null—not zero|4.440892098500626e-16|4.440892098500626e-16|
| Hopper |7200 / 0|1.8318679906315083e-15|1.8318679906315083e-15|8.881784197001252e-16|1.8041124150158794e-15|
| TwinRoller |7200 / 0|1.7763568394002505e-15|Absent, null—not zero|1.4432899320127035e-15|1.7763568394002505e-15|

**All three meet ≤0.05 WU at completed tick.** Hopper’s literal-limb maximum
is part6 at tick5739. Empty literal-limb sets were not used for vacuous passes.
The reporter checks that post-distance coordinates equal completed positions
exactly. Within this candidate, pre-final-distance contact **all-part** maxima
were 0.105532356588497 / 0.15358859650392775 / 0.061753624398069196 WU;
these are not literal-limb maxima or archived R26 values.

The wider ±64 WU **test** domain was preregistered before execution to avoid
the known ±12 WU truncation. The analytical plane, .25 WU cell spacing,
materials and creature geometry stayed unchanged. This is not a bitwise paired
R26 trajectory comparison, nor a drift experiment.

**Report the ordering correctness patch FOR ADOPTION.** It has not been
silently enabled or credited as a production-default AC-202 pass. No new
production baseline was generated. Adoption needs an explicit owner decision,
public rerun and separately recorded baseline provenance. No second arm or
retune was performed.

### F76 and D1 remain distinct

The archived R26 angular-last hypothesis was falsified: distance projection
restores roundoff, then **contact position correction** reinjects the completed
length error. Contacts run after the whole position loop, not after each
iteration. Preserve arm identities: baseline angular0.014927052436045196;
R26 diagnostic angular0.015140751632692628, appended distance roundoff, then
contact/completed literal-limb0.051910617942553194. Landing clustering is
consistent with the largest impact corrections.

D1 is **closed**. Owner mechanism-of-record places creep rectification in the
normal-impulse / position-correction class, not the friction coefficient; **no
correctness-shaped drift cause was located**. Nothing here claims a creep or
lurch fix. No D1, brace, knob, slip, stiffness, damping, torque, tolerance or
epsilon experiment was added.

## FA-3 and FA-5 — coverage, not sustained rest

**FA-3: PASS for the authored static wake-policy criterion only.** Each real
preset completed 600 zero-input ticks with status0 and full contact traces.
All three recorded **zero actual F42 sleep-breaking contacts**. Ordinary newly
grounded part counts were Slug3 / Hopper8 / TwinRoller6. Sleeping ticks were
**zero for all three**: no sleeping opportunities. This does not establish
rest, sustained sleep or sustained grip, and awake creep is not resting.
No synthetic parking or qualifying-load injection was used.

**FA-5: owner-reviewed PASS from the ORIGINAL R26 archive**,
CI40904855466/job123556709209. All four fixtures / 2412 ticks completed,
`missing_coverage: []`; no new physical run. Standing event definition:
maximal consecutive ticks per foot/branch, collapsing both velocity passes
and all capsule samples. Pair episodes have their own key. Natural ledge
departure was tick83. The 236 airborne foot/pass observations comprise
96 ledge + 92 drop + 48 midair—not 236 ledge capsule samples. Episodes last
**2–4 ticks**, establishing policy coverage, not sustained grip. The latter
belongs to FA-3 / feel work and remains uncharacterised here.

## AC-204 — PASS: all 200 runs, not merely a harness

**200/200 runs completed; 1,440,000/1,440,000 ticks; 20/20 batches; zero failed
runs and zero recorded nonfinite events.** The aggregate verifies all 200
unique run IDs. No failed seed was discarded or retried.

- Actual public-used SleepingLoadProbe + ActuatedLoadProbe composition.
- 7200 ticks / 120 s per run, selected before outcomes from adjacent AC-202’s
  two-minute duration because AC-204 leaves duration unspecified.
- Seeds `1388320512 + run_id`, IDs0..199; round-robin 67 Slug / 67 Hopper /
  66 TwinRoller. Test-owned injected xoshiro128** masks held for 60 ticks.
- Preregistered ±64 WU flat test plane, unchanged .25 WU cells and materials.
  Candidate flag **OFF** throughout the soak.
- Every tick scans returned observations, snapshots and constraints. Any
  nonzero solver status fails its run, even if rollback is finite. The scanner
  must detect both nonphysical NaN/Inf controls; controls never qualify a run.
- Each original artifact retains seeds, input/state hashes, finite-check
  counts, final state and explicit termination. No determinism claim.

Aggregate artifact **12937240162**,
`sha256:01f0f3223b07c8420a027c01785277efb4d4d4246eb9d333da6aaa28d893a7c6`.
The evidence JSON references all 20 original batch artifacts and their digests.
Local artifact redirects are network-blocked; GitHub CI original artifacts
and numeric check annotations are authoritative, not a fabricated local copy.

## Regression and deviations

- `bash scripts/review_checks.sh` → **218 controls PASS** after evidence updates;
  source CI ran **213 controls PASS** before those evidence-only additions.
- GDScript lint/format, Python compilation, bash syntax, workflow YAML and
  `git diff --check` pass.
- Ordinary public replay ran **before** the R27 fixtures: **9053 + 308 + 1446
  checks, zero failures**. Push and PR full summaries exactly match the final
  tested R26 summary, job123556709294. Tuning SHA5f4d0d… and committed baseline
  SHA2779456… unchanged.
- Same-source M0 push40960697714 / PR40960709730: headless **516/0** and Android
  success. The 516 count includes 514 engine assertions plus two compile/build
  checks; no invented extra physical assertions.
- First79c9ce2 had an invalid workflow dependency;823d1a5 encountered GitHub’s
  skipped-ancestor propagation. Both launched **zero R27 engines**. Routing
  fixes made2cf2c93 the first and only physical source. R26 studies all skipped.
  Future R27 physical-job guards are pinned to that completed source; studies
  are closed, not silently rerun by another marker.
- Overall M1 remains red: the mandatory historical F47 diagnostic and the
  newly measured 201a failure remain visible. No test was muted or waived.

## DoD and next decision

The scoped ledger has **13/18 qualified measured slots**: 12 measured passing
slots **include the unadopted AC-202 candidate**; only 11 are credited to the
production-operational track. AC-201 a+b is one failed parent slot, not two
extra successes; 201s remains separately visible without inflating18. FA-3’s
wake-policy scope is explicit. The old contaminated FA-4 ceiling is not a new
qualified lurch measurement. Five slots still lack qualified measurements:
presets/captures, tick cost, §10.6, FA-4 and FA-6.

**Expectation: M1 will reach 18/18 MEASURED, not 18/18 passing.** It has not
reached that now. FA-4 lurch and AC-201s sleep depend on contact rectifier /
M1.1 work; AC-201a stability now also fails its authored bound. The owner’s
16/18 projection is not asserted as a measured closure result. M2 stays blocked
until failures are resolved or the owner amends the GDD. Same-build determinism
attempt1 stands; cross-architecture attempts remain0.

**Next, M1 only:** owner review of the reported AC-202 adoption candidate and
the newly failed AC-201a clause. No new physical studies, camera, captures,
feel work or M2 changes were undertaken in R27.
