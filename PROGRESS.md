# CLAMBER progress

## Current milestone: M0 — APPROVED / COMPLETE (owner override); M1 — IN PROGRESS / production definitions and contact components, coupled gates NOT RUN

Session date: 2026-10-29. Normative inputs: `docs/GDD.md` and
`docs/ui/CLAMBER_UI.jpeg`. M0 is accepted by the GDD owner under M0-D07, dated 2026-10-28. Verdict:
**APPROVE — HUMAN OVERRIDE**. Missing device evidence and measured FPS/P95 are
waived for M0 only, not represented as measured. Land M0 before the separate M1
scaffold/PR; no M1 implementation or gate completion is claimed by this closeout.

### Current R16 — components accepted; M1 sustained-support gate RED

- Mechanics **931** checks, Python106 and M0 **514/0** are the accepted R15
  component counts. The preliminary921 subset is historical, NOT the current
  mechanics total (F51 correction). Components are not coupled acceptance.
- F47 gate replaced: last300 grip fraction>0 AND a grounded, gripping foot with
  positive velocity-level reaction must provide strictly>50% of ALL grounded
  reaction on the SAME tick. Aggregate feet, another foot/tick's share, landing
  impact alone, zero reaction and positional cleanup cannot pass. FA-5 untouched.
  Existing force/momentum/position checks and CI nonzero exit remain mandatory;
  no bypass/continue-on-error. Current real data must keep M1 RED.
- Owner acknowledges F37 previously requested fraction/share metrics, not a gate
  using them, and R15 “M1 green” missed the landing-impact cause; attribution is
  OWNER REVIEWER correction, not a claim of sustained support by the mechanics.
- Binding order now F47/F51 -> F48 convergence/zero-input drift -> F49 separate
  angular/self magnitudes + F50 post-pose .610/.810 -> public Sim/F45/replay ->
  FA-5 four branches, all3 FA-3/4, AC201/202/204,A9,10.6,tickcost/captures.
- Awake zero input is NOT unpowered: spring return is LIVE. R15 actuated last300
  is a transient, NOT an equilibrium; drift interpretation suspended until
  convergence evidence. F41 stays OPEN. No physics/tuning/damping/sampling/
  velocity epsilon/hysteresis/load injection/M2/camera/captures authorized.
- Public Sim still stub. FA-3/4/5/6/all coupled runtime gates NOT RUN;
  complete-creature determinism attempts0. F48 source/controls ready; pinned-engine6000 measurement pending.

### R16 F48 executed @f6b852a / CI40812720624 — M1 correctly RED

- Gate step FAILS as intended; all original math/contact/geometry/load components,
  sleep3659/mechanics931 and static controls pass. BOTH actuated6000 arms complete
  with full raw F31/position/count/contact checks and observer equivalence.
  Final before support fraction0, max single-foot share .3138574119247297, gatefalse.
- Exact settlement was NOT established in the available before-arm summary:
  settled value null, not a fabricated equilibrium. Full6000 artifacts retained.
  GitHub check annotation cap50 hid later own-line windows from this job's API;
  move subsequent measurement to a separate pinned observation job, preserving
  the original failing gate and raw artifacts. No gate bypass.
- F49 adds observation-only raw limit-block and individual self impulse events,
  before/net snapshots retained, no force/order/value changes. Summary separately
  reports angular/self max absolute per-tick phase coordinate and event impulse
  maxima BEFORE the accepted lossless phase adapter; cancellations stay visible.
- F50 repeats post-pose .6100000000000001 and .81 (legal+.01/+.21) for BOTH baseline
  600 and actuated6000, alongside the original pre-pose actuated6000. Derived from
  authored geometry plus explicitly requested fixture lift. No tuning addition.
- Current follow-up pending engine. Step4 public Sim/F45/replay is NEXT only after
  these measurements; all coupled runtime gates NOT RUN, determinism0.

### R16 F48 measurement increment (pending pinned engine)

- Extend ONLY diagnostic duration to6000; held input remains0 and live spring
  return explicitly labelled. Both legal actuated arms run6000 with EVERY raw
  tick/contact/count and observer-on/off physical equality, original600 prefix
  accepted verifier and independent full6000 momentum/position/contact checks.
- Convergence reported at600/3000/6000: monotone transient, oscillating transient,
  or exact constant/repeating last300 COM(dx,vx) pattern (at least2 cycles).
  NO velocity epsilon/band. If no exact observed settlement by6000, settled value
  stays null; a bounded last300 mean is NOT promoted to equilibrium. Tiny float
  fluctuations remain visible; lack of exact pattern is not proof of divergence.
- New own-line zero-input drift includes WU/tick, WU/s and150px/WU px/s plus raw
  speed/drift ranges. Actuated F41 pair interpretation DEFERRED unless both
  windows settle. Existing R15 component diagnostic prints the same line too.
- This always-run measurement retains evidence AFTER the RED support gate; the
  failed gate still makes CI RED, never continue-on-error or a status bypass.
- F49/F50 and public Sim/F45 remain subsequent ordered increments, not claimed.

### Historical R15 — component success, NOT M1 sustained-support acceptance

R16 supersedes “GREEN” below: component execution succeeded, but the old gate
passed on landing impact. Current M1 gate is RED until sustained majority support.

### R15 / actuator engineering increment measured (historical order)

- Binding order: motors L/R contraction + angular limits + self-contact FIRST;
  same increment derived legal BOTH-arm600 + required main-trace per-body/pass
  intervals/candidate/active counts, then F41 comparison. Public Sim/F45/replay
  NEXT, then Hopper four-branch FA-5/all-preset FA-3/4; finally AC-201/202/204,
  A9/§10.6/tick cost/captures. No M2/camera/captures now, no retune or sampling fix.
- F30-authored CLOSED — the audit proves foot pads at -0.205 (Slug, TwinRoller 4) and -0.235 (Hopper) below the lowest non-foot body, with exactly one documented exemption.
- F30-runtime BLOCKED — not by the pose but by missing actuators. The hinges rotate freely, so the foot swings up and the head and motor bellies still rest on the ground: 17 active samples and all three bodies grounded after the fix, with the foot carrying 22.24 percent of support. With no angular limit and no motor torque, the lowest-energy configuration of a limp chain is everything on the ground. The pose cannot constrain attitude.
- Above is the owner's R15 baseline verdict, NOT a claim new actuator traces pass.
  First shipped-preset grip: tick19, exactly one tick, toggles[19,20], steady
  fraction0: path existence only.
- New source: algebraic binary64 CORDIC table, spring/return motor, asymmetric
  motor/symmetric passive angular rows, D10 filtered center-sphere self response,
  separate awake ActuatedLoadProbe. Historical free-hinge trajectory retained.
  No foot/root angular limits invented. No new damping, epsilon, load injection,
  resource-value or accepted math/analyzer/control changes. Existing endpoint
  linear damping remains; existing motor c55 is used as specified. Unused global
  angular damping is not silently activated/reinterpreted by this increment.
- New fixture derives root from actual authored capsule minimum +.01WU. All four
  legal cases (old/new pose × baseline/actuated) retain required MAIN counts and
  raw candidate observations. Historical .33 pair explicitly over-penetrating.
  F43/F44 legal/count plumbing executed: see measured evidence below. F41 remains
  OPEN: legal baseline still drifts; actuated pose-causal comparison is confounded
  by differing counts. NOT a failed pose fix or landing-depth causal explanation.
- Public Sim remains stub; F45 documentation/replay is the next ordered stage,
  not an approval blocker. All coupled runtime acceptance remains NOT RUN;
  complete-creature determinism attempts0. Accepted sleep remains unchanged.

### R15 measured engineering evidence (35df327; strengthened548b5c8 also GREEN)

- Pinned Godot4.7.2 M1 CI40810406262 SUCCESS:105 Python controls,381 math,
  237 contact,136 analytic,80 load,3659 sleep,921 new mechanics checks. Initial
  engine compiler failures (global wrap-name collision/test Variant inference)
  were corrected in0cf1215/35df327, not hidden as unavailable or passing runs.
- All FOUR legal main600 traces OBSERVED, EVERY tick observer-on/off serialized
  physical state equal; required counts independently agree with all raw samples;
  F31/motion/contact verifiers pass. Actuated raw angular/self position phases
  retained, independently closed, then explicitly folded only for legacy verifier.
- Actual authored minimum before=-.395, after=-.6000000000000001WU, derived roots
  .405/.6100000000000001: BOTH initial lowest surfaces=.010000000000000009WU.
  Historical root.33 remains over-penetrating: actual deepest surfaces -.065/-.270,
  not a new legal fixture. No physical resource/sampling/threshold changed.
- Legal baseline last300 mean COM dx before=-7.1751877234127456e-6,
  after=+9.337328797581247e-6WU/tick; difference=1.6512516520993993e-5.
  Count tuple=(intervals,candidates,active), passes0/1: BOTH arms head(2,3,3)/
  (2,3,3), motor(2,3,3)/(2,3,3), foot(2,3,3)/(1,2,2), all300 ticks. Thus legal
  steady baseline counts match and residual drift persists, essentially the same
  late results as historical.33. No landing-depth causal claim.
- Legal actuated last300 mean dx before=.0003903690062867916,
  after=.000437169361675691WU/tick; difference=4.6800355388899406e-5. These are
  observed larger drifts, NOT a causal pose verdict: last300 count regimes DIFFER.
  Side by side (before -> after), tuple=(intervals,candidates,active):
  - Head passes0/1: (2,3,1)×300/(2,3,1)×300 -> same.
  - Motor pass0: (2,3,1)×267+(2,3,2)×33 -> (2,3,1)×250+(2,3,2)×50.
  - Motor pass1: (2,3,1)×300 -> same.
  - Foot pass0: (2,3,3)×300 -> (1,2,2)×300.
  - Foot pass1: (1,2,2)×300 -> same.
  Raw per-tick counts plus ALL600/last300 histograms retained in artifact; no
  candidate-regime repair, rounding, epsilon, hysteresis or sampling retune.
- All3 bodies still grounded late in all four cases. Baseline foot support share
  .2223925379546886 ->.22240637932820798; actuated .3057010100863977 ->
  .27408929671045956. Late grip fraction0 everywhere. Legal baseline after has5
  grip ticks/toggles[4,9]; legal actuated after4/toggles[4,7,10,11]; both before0.
  These separate fixture results do NOT replace the historical shipped-preset
  milestone tick19/exactly1tick/toggles[19,20], which remains path existence only.
- Artifact12869408995 (8,025,846 bytes), SHA256
  eec39d97e8ced394b44d8c152c6f88c5edf923f694d79e66abd192aa82390f43,
  contains full four raw600 traces/components/import/observer reports. This is
  awake engineering evidence, NOT public Sim/FA/complete-creature determinism.
- Follow-up548b5c8 / CI40810712083 SUCCESS:106 Python /931 mechanics checks.
  New F43 fake-legal-metadata control verifies actual START endpoints/radii,
  not merely reported clearance. Composed D10 overlap control invokes the actual
  pair-list hooks and independently conserves momentum; self response cannot
  pretend terrain support/grip. All four legal600 results repeat exactly.
  Artifact12870690195 SHA256
  589532d5add86e978cbd90273a4966b04534af19e7c46850a40bb96d18999ddd.
- Next ordered M1 stage is public Sim + explicit F45 superseded legacy-sleep
  documentation + replay; no approval blocker. Then Hopper FA-5 all4 branches /
  all-preset FA-3/4; final acceptance/tick cost/captures still NOT RUN. Attempts0.

### Historical R14 / superseded interpretation and order (preserved evidence)

R15 supersedes the F41 causal interpretation and public-Sim-LAST ordering below.
The .33 runs are historical **over-penetrating spawn** evidence only.


- F41b answered BEFORE source edits: foot current extent ceil crosses cell.25
  after first-pass positional cleanup; candidate/active count3->2, velocity-
  invariant at fixed current/previous positions+terrain. Indirect geometry path
  through integration remains. No sampling/contact fix or new epsilon.
- Owner A/A1 implemented126dc80: five foot axes ->DOWN only; hard F36 authored
  audit passes, exact retained exemption TwinRoller foot5 parent0 non-support stub.
  Original bad-pose synthetic control remains. Hopper two-foot grip proof belongs
  to future FA-5, NOT TwinRoller stub or the authored-bottom assertion.
- Unexpected measured dynamic result: before0 grip ticks, after1(at19), late
  fraction0 both. All3 bodies STILL grounded with17 active responses/tick; mean
  COM dx reverses/grows -7.175187723414263e-6 ->+9.337328797577746e-6WU/tick.
  F41 retained, not pose-artefact downgrade. Unchanged .33 spawn now starts new
  pad at-.27WU; sole-foot support prediction NOT observed. No silent spawn fix.
- Sleep sourcee36c407 / CI40805104578:3659 component checks PASS;600 engineering
  ticks, sleeps[61,210,390], input wakes[180,360]. Restore at47(partial dwell)
  and62(asleep):1091 full serialized-state continuation comparisons identical.
  Every asleep endpoint zero; persistent/new-grounding F42 controls pass. This
  is NOT complete-creature determinism or an all-preset FA-3/4 pass.
- EXACTLY two tuning additions, owner R14 Decision2: .001WU/30ticks. All previous
  tuning-resource bytes unchanged. Sleep parks plateau, does NOT fix it; awake
  max endpoint speed≈.202WU/s≈30px/s at150px/WU remains a motor-stage feel risk.
- Next M1 STEP4: motors/angular limits/self-contact. Then STEP5 Hopper two-foot
  FA-5 and all3 FA-3/4. STEP6 public Sim wiring LAST, currently untouched. No owner
  approval blocker, no retune/M2/camera/screens/captures. FA-3/4/5/6/all complete
  runtime gates remain NOT RUN; complete-creature determinism attempts0.

### Exists

- Pinned Godot4.7.2-stable project: Mobile renderer, 1080×2340, portrait,
  canvas_items/keep, 60 Hz, pixel snapping, MSAA off, ETC2/ASTC import enabled.
- Engineering-only navy boot surface with safe-area container and lifecycle hooks.
- `core/tuning.gd` / `.tres`: **402 exported fields** (376 original +24 owner M1-D04 +2 owner R14 Decision2), seven original groups,
  `docs/TUNING.md` source map. No core numeric literals; no feel/economy changes.
- Atomic JSON SaveStore: flushed tmp, previous validated backup, atomic replacement;
  primary → backup → tmp → defaults recovery; checked errors and recovery signals.
- Share/billing/ads/haptics unavailable/no-op interfaces, no SDKs/network calls.
- Architecture/shared-component stubs and reserved Sim/CreatureCodec signatures.
- Test launcher rejects wrong engine versions, script errors, failed assertions and
  missing completion markers. Six static tests, seven inspector unit tests, and
  real-engine persistence/tuning/safe-area/stub tests.
- CI headless and Android jobs with checksum-verified exact engine/templates;
  Android debug AAB export and bundletool-derived signed debug APK generation.
- Actual manifest/ABI checks, native ELF 16 KB and APK ZIP alignment checks;
  seven-day Actions artifact retention. Generated binaries/keys remain outside Git.
- README, decisions, and `docs/validation/M0.md` with reproducible evidence and
  remaining hardware checklist.

### Explicit stubs / not built

Full coupled creature solver, general builder validation/codec, run/fall/checkpoint systems, generator,
wallet/medals/score, schema migrations, settings/debounces, lifecycle run/audio
consumers, all S00–S16 screens and native plugins. Stub null/empty returns are
nonfunctional and unused. No autoload, gameplay, art, audio, production signing,
purchase, advertising or network feature. Android Gradle files/artifacts are
transient CI outputs, not tracked source.

### Validation evidence

Validated code: `ba7179b4d6d7fee26522853590578135973fd7bc`.
[Successful CI run 40625642314](https://github.com/sagheerh/clamber/actions/runs/40625642314).
Exact commands, jobs, versions and artifact digest: `docs/validation/M0.md`.

- `python3 tests/test_static.py`: **6 PASS** locally and in CI.
- `python3 tests/test_android_inspection.py`: **7 PASS** locally and in CI
  (synthetic inspector fixtures, separate from actual artifact checks).
- `gdlint core ui platform tests` (local gdtoolkit): **PASS**.
- `bash -n tests/run_tests.sh tests/build_android.sh`: **PASS**.
- `godot --headless --editor --import` on pinned CI engine: **PASS**.
- `godot --headless --run-tests` on pinned CI engine: **475 checks, 0 failures**,
  exit0, including garbage→backup and both-corrupt→defaults recovery.
- Debug Android AAB export: **PASS** on equipped CI runner, JDK17/SDK36,
  build-tools36.1.0/NDK29.0.14206865, matching4.7.2 templates.
- Bundletool validation/APK generation; actual manifest/ABI/native16KB/ZIP16KB:
  **PASS**. Debug artifact is downloadable from the successful run for seven days.
- Physical install and solid navy/no-UI/no-gameplay boot: **OWNER VERBAL
  VERIFICATION**, 2026-10-28; not E4 evidence. No screenshot/adb log, device
  identity, lifecycle/safe-area record or frame-time capture was attached.
- Measured 60 fps/P95 and remaining device artifacts: **WAIVED FOR M0 ONLY** by
  M0-D07, not measured. The 60 fps engine cap is not measurement evidence.
- Local engine/Android execution remains unavailable; CI results above are real
  runner executions, not local execution or hardware measurements.

### Definition of Done

| Criterion | State | Evidence |
|---|---|---|
| `godot --headless --run-tests` exits0 | **Met** | Pinned CI engine, 475 checks/0 failures |
| Save garbage → backup → defaults test passes | **Met** | Real-engine save test suite passes |
| Android debug install/boot and measured 60 fps/P95 | **Accepted by owner override** | Verbal boot verification; missing artifacts and measured performance waived for M0 only (M0-D07) |
| ≥40 named tunables; no core hardcoded numbers | **Met** | 376 fields; static/resource checks PASS |

### Decisions / next

M0-D01–D07 are in `DECISIONS.md`; M0-B01 is closed by the owner-only waiver.
M0 review-pack script/matrix artifacts were explicitly waived for M0 (M0-D07).
M0-B02 (camera zoom) remains for M2; M0-B03's unspecified grip/haptic/generator
thresholds remain unresolved and must not be invented. No later gate is waived.

**Next milestone: M1 — standalone custom solver + three presets + headless
determinism/feel harness.** M1 is ready, not complete. Excludes S03 climb,
pause/fall/build screens. Real-engine M1 CI evidence and baseline are not yet
available; the M0 CI suite is not evidence of M1 determinism/performance.

### M1 PR #3 kickoff / R3 scaffold fixes

M1 working branch for PR #3: `arena/4cd0a587-clamber`, not the earlier PR #2 branch.
M0 approval/closeout is untouched. The earlier M1 matrix is restored and reconciled
with supplied A9.1–A9.7, A8 475-engine/488-total regression floors, full invariant
sweep, five-fakes and A12 evidence requirements. A separate M1 static CI job and
`scripts/review_checks.sh` are added; their green status is NOT runtime evidence.
Full review pack is now vendored unchanged (owner-supplied 2026-10-28);
`docs/CLAMBER_REVIEW_AGENT.provenance.md` records the exact source/hash.
M1-B02 is RESOLVED (vendored), not waived; protocol execution is not signoff.
Owner selected independent work while missing radii/head properties/grip threshold
are unresolved (M1-D01). M1 solver, presets, captures and runtime gates NOT RUN.

### M1 independent increment 1 — real-engine primitive unit tests PASS

- Scaffold-only commit `2358c83` passed CI before mathematical implementation:
  M1 static run40631318799 and M0 regression/Android run40631318609.
- Draft PR: https://github.com/sagheerh/clamber/pull/3 (sole canonical M1 draft);
  prior scaffold PR#2 is left unchanged on its earlier branch.
- `core/sim/body.gd`: explicit float64 point state, finite/bounds validation,
  non-aliasing snapshot, checked atomic restore; no collision radii/default mass.
- `core/sim/constraint.gd`: independent XPBD distance-link projection, explicit
  compliance and tick-boundary multiplier reset; no creature integration/contact.
- `tests/sim/test_math_state.gd` + `tests/run_m1_math.sh`: synthetic unit fixtures,
  pinned real-engine CI job; these are NOT creature/replay/soak acceptance.
- Original M0 tests, public Sim interface, tuning values and boot scene unchanged.
- Presets/model/contact/debug view and M1 runtime gates remain blocked/not run;
  no head properties/radii/grip threshold or baseline hash has been invented.

### M1 measured status / next

- Mathematical commit3bbb8fa passed pinned-engine CI40631790195: **81 primitive
  unit checks, zero failures**. M0 regression/Android CI40631790078 also passed;
  original 475 engine +13 Python =488 floor is enforced with no test reduction.
- `scripts/review_checks.sh` exits0 (42 script/scene files scanned, 21 Python
  tests) at accepted head f51ecd4; the output is pasted in PR#3. These scans do
  not certify the full invariant sweep or any M1 runtime gate.
- Detailed source/run evidence and limits: `docs/validation/M1.md`.
- AC-201/202/204, distinct gaits/captures, 3600-tick/100×/two-machine replay,
  bit-flip, baseline, soak and performance: **NOT RUN / NOT MET**. No complete
  creature determinism attempt has run; the two-failed-attempt budget is unused.
- **Next: M1** — owner review of the independent integration/clock increment
  and owner input M1-B01 before any dependent creature implementation. No contacts/radii/gaits/presets/
  baseline/runtime claims. M1-B01 radii/head mass/length/grip threshold with units
  still requires owner input before dependent work. M1-B02 is resolved, not waived.
  Do not move to M2.

### M1 R4 mechanical fix increment (no integration)

- Full owner-supplied pack vendored byte-identically, SHA-256 verified, 379 lines;
  provenance outside the immutable file. Incorrect owner attribution withdrawn;
  M1-B02 RESOLVED (vendored), not waived. PR #3 remains the sole canonical draft.
- Matrix now maps the original PART B INV-01–10 and A5.6/A10 five-fakes. Full
  semantic sweep/five-fakes/A12 review and every runtime gate remain NOT RUN.
- `scripts/review_checks.sh`: exit0; 42 script/scene files and **28 Python tests**
  (15 review/guard +6 original static +7 original inspector). Guard enforces the
  claim freeze, evidence cells, ≥12 NOT RUN rows and immutable pack identity.
- Actual AC-201 working-file mutation to `PASS | None`: exit1; exact restore:
  exit0. Full transcript is in the PR #3 body, not just a unit-test claim.
- F13 uses injected `tuning.physics_one` for the fixed step (and therefore both
  factors of its square); one new synthetic 120 Hz versus 60 Hz primitive test.
  Local lint/shell/diff checks passed. Pinned-engine/M0/Android results for this
  fix commit are tracked in PR #3; no new engine result is claimed here yet.
- No integration, accumulator, contacts, presets or baseline added. Accepted M0
  tests/tuning/save and public Sim interface are unchanged. Determinism attempts:0.

### M1 R5 F15 — status allowlist (before integration)

- R5 owner accepted F7/F12/F13/F14 at0ec87d0 and independently verified its CI.
- F15 replaces permissive status handling with an exact allowlist over every
  pipe-table row, not only the first table. Scoped exceptions and NOT RUN≥12
  remain enforced. Scanner restrictions are unchanged.
- Seven existing guard tests retained; one parameterised test adds the six
  reported bypass statuses, empty status and later/headerless table cases.
- `scripts/review_checks.sh`: exit0, **29 Python tests** (16+6+7).
- Actual AC-201 COMPLETE and MEASURED (4 s) mutations with CI evidence each exit1;
  restored matrix exits0. Full fresh transcript is in PR #3's body.
- Integration is the next separate increment; runtime acceptance remains NOT RUN.

### M1 independent increment 2 — point/link integration and outer accumulator

- F15 commit201644e is green: M1 CI40638310619 and M0/Android CI40638310666.
  Original82 primitive checks and 475 M0 engine checks retained.
- `core/sim/solver.gd`: tuned fixed-step scalar integration, gravity, linear
  damping/clamp, fixed index-order link projections and tick-boundary lambda reset.
- `core/sim/accumulator.gd`: callback-free outer clock with frame_seconds input;
  tuned catch-up cap, exact dropped-time accounting and retained sub-cap remainder.
  No elapsed-time argument to the solver. Placement/naming/math: M1-D03.
- Candidate restore validates the entire graph/state; tick and whole-frame failures
  roll back atomically. No silent repair of non-finite events.
- `tests/sim/test_integration.gd` + extended `tests/run_m1_math.sh`: actual assertions
  for all six R5 evidence categories, plus pinned points, damping/clamp, invalid
  graph/configuration and late-frame rollback. Existing82 checks remain intact.
- Local review checks exit0: **44 script/scene files, 29 Python tests**. Lint,
  shell syntax and diff checks passed. New pinned-engine counts/results are recorded
  in PR #3 after execution; local Godot remains unavailable.
- Still stubs/missing: public creature Sim, model, contacts, hinges/motors/feet/SDF,
  sleep/recovery, presets, diagnostic scene and all creature-runtime acceptance.
  No tuning values, M0 tests, accepted point/link math or scanner restrictions changed.
- Next: **M1** owner review/input before dependent work. M1-B01 remains owner-supplied;
  no radius/head mass-length/grip value invented. No M2/camera. All runtime NOT RUN.

### M1 integration measured evidence — synthetic primitives only

- Source `f6b3756f36f683ea5ce6c0fa21b5c167c4598fc8`: exact Godot4.7.2
  [M1 CI40639068153](https://github.com/sagheerh/clamber/actions/runs/40639068153)
  reports **374 checks, 0 failures: 82 point/link +292 integration/clock**.
  All six R5 primitive evidence categories execute; no skipped/invented baseline.
- [M0/Android CI40639067949](https://github.com/sagheerh/clamber/actions/runs/40639067949)
  is green. Actual unchanged M0 suite now reports **476 engine checks, 0 failures**:
  its recursive per-script compile assertion picks up the new accumulator script
  (`tests/test_runner.gd:31–37`). With original13 Python checks this is489;
  the original475-engine/488-combined floors and all M0 tests remain unchanged.
- New integration completion/count floor is pinned to the measured292 checks;
  original82 point/link floor remains. This prevents a later primitive count drop.
- This is NOT M1 acceptance: contacts/presets/AC-201/202/204, A9.4/.5/.7,
  §10.6, tick cost and captures remain NOT RUN. Determinism attempts:0.
- Next: **M1** owner review of this independent increment and owner M1-B01 input
  before dependent creature work. No M2/camera or invented physical values.

### Commit A — F16–F19 only (no contact geometry)

- M0 regression floors raised to476/489; original13 Python floor preserved. Added
  a negative fixture for the old475-check run, including surplus-Python masking.
- Accumulator now returns a failed rollback's Error; a fault-injected solver forces
  a changed state and failed restore. Existing atomicity assertions remain intact.
- F18 records current tick+frame snapshot policy and a mandatory two-configuration
  benchmark protocol before any tick-cost claim. Measurements remain NOT RUN.
- A9.5 explicitly varies frame delivery, not fixed60 tick_hz.
- Next M1: only after Commit A is pushed/green, verify owner derivation hash and
  prepare the separate constants/geometry-tests/feel-scaffold Commit B.

### Commit B — M1-D04 constants, geometry guards and feel scaffolding

- Commit A0ee3548 passed pinned M1 CI40670975708 (381 checks, zero failures) and
  M0/Android CI40670975949 before geometry work. Its M0 floors are476/489.
- Owner derivation imported as the single immutable281-line file with verified
  SHA-2566453508be7cb808f643544ec3f3fdbd6560840876fc070511f4b5f50065dbc5e.
- M1-D04 records supplied collision/art radii, derived head mass, ratio/floor grip,
  no root hinge, cosmetic-only eyes and provisional/no-silent-retune requirements.
  M1-B01 is RESOLVED (inputs supplied); M1-B04 is unresolved FLAG ONLY, no camera.
- Added24 named exports/resource values/inventory entries sourced owner M1-D04.
  All376 pre-existing fields/values, GDD§3.2 and foot bias/slip remain unchanged.
- Real analytic harness: all25 kind-pair D-10 bounds, distance-two pairs in
  Slug3/Hopper8/TwinRoller6 topology fixtures, strict slop clearance and FA-1/2/7
  checks. Topology-only fixtures are NOT runtime presets or captured gaits.
- Static visual-radius isolation forbids direct/dynamic references by core except
  schema declarations; source tests pin exact owner constants and derivation hash.
- Runtime feel plans list required measurements without observations/successes.
  FA-3/4/5/6, contacts, AC-201/202/204, A9, baseline, timing and captures NOT RUN.
- Local script review:34 Python tests; lint/shell/diff checks pass. Real geometry
  counts/artifact and source-pinned CI evidence will be in PR #3 after execution.
- **Next: M1** — after B green, creature bodies/feet/contact response, then actual
  acceptance traces. Feature stop is lifted. No M2/camera/screens or silent tuning.

### R7 F20/F21 corrections (before Part3 claims)

- A/B accepted by owner at0668d66; no redo of accepted constants/foundations.
- Seven FA gate rows now mandatory. Analytic status scoped strictly toFA-1/2/7
  with run/report citation; runtimeFA-3..6 stay NOT RUN; prose/checkbox escapes fail.
- Real tracked FA-6 analytic-status mutation exits1; restored FA-1 analytic row
  exits0; original out-of-table prose bypass exits1. Full transcript in PR #3 body.
- FA-1 adds owner-authorized1e-9px float-noise allowance only. Four assertions cover
  boundary noise, half-pixel regression, beyond-allowance loss and non-finite input.
  Geometry count floor rises123→127. No tuning/radius/derivation change.
- Local review checks35 Python tests; pinned-engine results tracked in PR #3.
- Next M1: actual creature definitions/body/contact primitives, D-10 against real
  definitions, then FA-5 before static scenes/AC traces. All runtime NOT RUN.


### Part3a — production models and capsule/SDF contact components

- R7 fixes9a45f6d are all green: M1 run40674737989 has381 mathematical checks
  (82+299) and127 analytic geometry checks, zero failures; M0/Android
  run40674737947 also passed. F20 controls remain in PR body.
- Actual engineering presets now live in `data/creatures/preset_*.json` (3/8/6
  parts). Cardinal rest directions/shortest limb slot are engineering initial
  definitions, NOT approved gaits/tutorial inputs. CreatureModel derives physical
  parameters from unchanged tuning, validates rooted trees/channels/basic budgets,
  sums mass and caches hierarchy pairs. General builder/codec is still a stub.
- CapsuleBody creates float64 endpoints with half segment mass each; snapshots
  preserve contact history and restore/contact publication preserve endpoint
  identity. SdfGrid copies explicit distance samples/material at0.25WU, bilinearly
  samples and rejects undefined normals/outside queries. CapsuleContact performs
  sampled positional/velocity response, current/previous temporal crossing checks,
  explicit min-material friction, static slip and owner ratio/floor/bias foot gate.
  Projection/non-finite errors reject atomically; no pretend public Sim recovery.
- Universal D-10 includes feet/siblings in real definitions. Layer11 feet are
  excluded from the actual creature self-response mask. Geometry harness now reads
  the production catalog, fails if any preset is absent; its floor is128.
- Added `tests/sim/test_contacts.gd` and pinned `tests/run_m1_contacts.sh`, CI unit
  step and unit-log artifact. Tests change real projections/velocities, trace four
  controlled cached-load responses, two separately controlled half-weight contacts,
  airborne/stale-cache and not-lowest exclusion, swept closed-slab crossing,
  snapshots/endpoint identity and atomic rejection. **Not coupled stance/FA-5.**
- Local static review35 Python tests, GDScript formatter/linter, shell syntax,
  diff checks pass. New engine suite/128 geometry checks await pinned CI at this
  increment; no runtime result is asserted before it runs. New unit count floor208
  is separate from the unchanged accepted381 mathematical baseline.
- Tuning/derivation/GDD values unchanged; derivation SHA verified exactly.
- Still unbuilt: coupled rigid links/parent hinges, motors/angular limits,
  self-contact response, sleep/recovery/public Sim. FA-3/4/5/6, AC-201/202/204,
  A9/full deterministic replay/stall/baseline/bitflip/tick cost/captures NOT RUN.
  Complete-creature determinism attempts remain0. No M2/camera/screens.
- **Next — M1:** pin component CI, then couple rigid bodies/hinges and contacts to
  obtain real foot-load/stance traces for FA-5. Only after FA-5: FA-3/static600,
  AC-201 settle+sleep≤4s, AC-202 stretch, AC-204 soak, and motors/tutorial FA-4/6.
  FA-6 actual10-run count10/10 or≤4/10 => STOP/report logs/outcomes; never retune.


- Part3a CI40676292165: accepted381 math checks passed; new component script
  correctly FAILED before execution on nonexistent `ERR_OUT_OF_RANGE` enum.
  Replaced with Godot's `ERR_PARAMETER_RANGE_ERROR`; no physical value/assertion
  changed. Geometry step skipped in that run, not passed. Unit failure is not a
  complete-creature determinism attempt. Re-run pending.

- The companion M0 compile sweep on81d0840 also caught a typed-inference error
  in capsule restore (`state.mass` is a Variant); inverse mass is now explicitly
  float. Old M0 result504 checks/2 compile failures is not regression evidence.
  Runs969ef16 are superseded; only5bb9132 and later include both compile fixes.

- Pinned5bb9132 run40676484751 executed208 contact checks and found2 assertions
  failing at the exact40% cached-load boundary;381 math checks still pass. Actual
  trace: prior17.36, threshold display17.36, vx0.1, gripfalse; below8.68 also slips,
  above21.7/43.4 grips with vx0.0; each measured next reaction18.36. Root cause:
  `(ratio*mass)*abs(g)` rounds17.360000000000003 vs ratio of already-computed
  creature weight17.36. Grouped `ratio*(mass*abs(g))` per the weight-band definition,
  without force epsilon, changed constants, or weakened assertions. Tests now log
  cached load/threshold/vx at17 decimals. These are controlled unit traces, NOT FA-5.
- M0 at5bb9132 run40676485104 headless passed504 checks/0 failures; Android still
  pending when recorded. New geometry step skipped on failed component run.
  Complete-creature determinism attempts remain0; no owner tuning change needed.


### Part3a executed component evidence @e702232

- All four checks green: M1 run40676727247 / M0Android run40676727258.
 381 accepted math checks (82+299),208 new production/contact component checks,
 128 real-definition analytic geometry checks,504 M0 checks, all zero failures.
- Exact controlled traces (not coupled FA-5): prior8.68 =>vx≈0.1/gripfalse;
 prior17.36,21.7,43.4 =>vx0/griptrue. Each fixture measures new reaction18.36.
 No force epsilon/physical tuning or assertion relaxation. Earlier compile/unit
 failures above are retained, not counted as complete-creature determinism runs.
- Contact UNIT artifact12811047142 (762 bytes) digest
 sha256:527433c59c7079906ce3e538b0a792a33fbb5555477ce47730117973b9682c02;
 geometry artifact12810024839 (1148 bytes) digest
 sha256:f983971a93166c35e06a68bcdc047a98804a18be135bc91d6717a8f232ea3260.
 Metadata retrieved via API; ZIPs not downloaded/inspected locally.
- Production non-resource JSON now explicitly included in Android exports;
 existing package inspector verifies exact bytes in both AAB/APK, with missing/
 modified synthetic controls. This packaging addition awaits its own CI run.
 Local review now37 Python tests; original native/manifest/alignment checks intact.
- R7 order/gates unchanged: coupled FA-5 still NOT RUN; next is M1 body/hinge/
 contact coupling and measured foot-load traces, NOT static scenes or motors yet.

- Packaging check correctly failed ata8f071a (run40677420055): inspector assumed
  production assets live under`base/assets/` in the AAB. Pinned Godot4.7.2 source
  `platform/android/export/export_plugin.cpp` uses the install-time asset-pack
  module;`platform/android/java/app/assetPackInstallTime/build.gradle` fixes its
  name to`assetPackInstallTime`. Corrected AAB path to that module's`assets/`;
  APK path remains`assets/`. Exact-byte/all-three-file guards and negative cases
  stay intact. Runtime/M0headless/static jobs passed; no Android pass claimed for
  that failed run. Followup CI pending. No physics/test tolerance changes.


### Part3a final implementation CI @5ff93bf — ALL GREEN

- M1 run40677962012 (check122781079671):381 mathematical checks (82+299),
 208 contact-component checks and128 production-definition analytic checks,
 all zero failures. Static review37 Python tests passes. FA-1/2/7 analytically
 checked only; no rendered/device/feel result is inferred.
- M0/Android run40677961953:504 headless checks/0 failures and Android PASS.
 The package-inspection step passed exact source-byte checks for all three JSON
 presets in AAB`assetPackInstallTime/assets/` and universal APK`assets/`, alongside
 unchanged manifest/ABI/native16KB/ZIP-alignment checks. Earlier failed packaging
 assumption is superseded, not waived. No installation/performance claim.
- Canonical draft PR#3 records controls, failures/fixes, actual controlled response
 traces, source-pinned runs and unit-vs-runtime scope. All implementation pushed.
- **M1 not complete:** FA-3/4/5/6, AC-201/202/204, complete-creature A9/replay/
 stall/frame/baseline/bitflip/timing/§10.6/captures remain NOT RUN; attempts0.
 General codec/builder, coupled links/hinges, motors/limits, self response and
 sleep/checkpoint recovery remain unbuilt. No M2/camera/screens.
- **Next single milestone — M1:** couple rigid bodies/hinges and contacts, obtain
 measured FA-5 load-band/two-foot/airborne traces before static600/AC-201, then
 AC-202→AC-204→FA-4/6 last. Preserve FA-6 stop/report rule and unchanged tuning.


### R8 / owner F24 — force-channel first increment (coupling NOT built)

- Owner accepts prior Part3a as COMPONENTS; F20/F21 closed.208 component checks
  are NOT determinism; complete-creature determinism attempts remain0.
- Applied-load input and measured impulse-reaction output are split; positional
  cleanup is a third diagnostic, never load. The response cannot clobber input.
- Frozen previous completed tick's post-resolve grounded count is computed once
  by batch resolve, no stored N or alternate grounding predicate. N0 disables
  first-contact grip; expected-share band and5N floor recorded with rejected
  alternatives, FA-5 row and owner-attributed append-only derivation addendum.
- Added actual snapshot restore-and-continue and reverse-order component tests,
  zero-to-two touchdown, two-to-one lift-off, immutable-input and positional-only
  false-grip controls. These are controlled components, NOT a coupled stance.
- F22/F25 load producer/conservation and Slug600 trace remain NOT IMPLEMENTED;
  FA-3/4/5/6 and all coupled AC/A9 runtime claims remain NOT RUN. No sleep result
  is fabricated. The0.723N last300/600 criterion is recorded, not relaxed.
- Next M1: implement real gravity/hinges/contact load transfer for one Slug,
  record every required tick, then FA-5 band and only then two-foot presets.

- First R8 pinned component execution e26a1d6 / CI40686657656:233 component
  checks,381 math,128 analytic, all zero failures. Strengthened N0 fixture to a
  qualifying100N input; added actual1->2 touchdown-next-tick step to accompany
  2->1 lift-off and byte-equal restore/continue. New component floor237; original
  accepted208 checks retained with corrected split-field semantics. These remain
  COMPONENT tests, not FA-5 acceptance, not a Slug600 trace and not determinism.


### R9 — real gravity/hinge load bridge; raw diagnostic pending execution

- R9 accepts step1. Added shared-endpoint translational hinges and a coupled
 engineering load probe: gravity + measured equal/opposite hinge impulse supplies
 applied_load_n. Contact impulse output is independent; position cleanup is never
 a source. No prescribed whole-weight share or injected qualifying production load.
- Coupled entry uses batch only; frozen previous flags survive both velocity
 passes. resolve is fixture-only. Co-lowest capsule surface uses existing slop;
 unequal-height/reversed-order read-only fixture added before any stance claim.
- Independent isolated-foot gravity test expects8.4N, not2x. Added600-row JSONL
 diagnostic and independently falsified parser; BOTH force sums and their cross
 difference must satisfy fixed0.723 for last300. Failure is a nonzero CI result,
 not masked. Full raw rows and summary are uploaded even on failure.
- This probe has free rotational hinges; angular limits, motors, self-contact and
 sleep optimization remain unbuilt. All rows explicitly awake/sleep_implemented
 false. No fake sleep observation or accepted stance; no Hopper/TwinRoller run.
- Local review45 Python tests/lint/format/shell/diff pass; new Godot execution is
 pending. Existing237 component/381 math/128 analytic floors are unchanged.
 Tuning/derivation and exact AAB/APK preset guards are unchanged.
- F22/F25/F26 remain OPEN until actual execution and force balance; all runtime
 FA-3/4/5/6/AC/A9 gates stay NOT RUN. Complete-creature attempts0. No M2/camera/
 captures/retuning. Next M1: inspect every raw Slug tick and report findings before
 any FA-5 band or two-foot stance work.


### R9 first executed600-row finding @206d205

- Pinned M1 CI40689842649 ran381 math,237 contact,128 analytic and78 load-path
 components, all zero component failures. Isolated0.30-mass foot's independent
 two-endpoint reaction=8.40000000000000036N, with no divide-by-two correction.
- ALL600 coupled Slug rows were generated. Fixed last300 force acceptance FAILED:
 max|applied-43.4|=33.7224813369873N;
 max|reaction-43.4|=33.70455115394039N;
 max|applied-reaction|=0.017930183046905412N. No grip toggles recorded.
- CI is RED on that actual force criterion, not on a compile/unit failure. The
 closely agreeing channels do NOT establish that the foot carries the full body.
 Added non-foot post-resolve flags/reactions and first/last/range annotations to
 investigate support elsewhere, without changing physics or tolerance. No stance
 claim, no FA-5 band, no Hopper/TwinRoller advance. Sleep remains unimplemented.
- M0/Android run40689842574 passed506 checks/0 failures and Android inspection.
 Existing exact preset bytes, radii, owner values and derivation are unchanged.
- Full600-row diagnostic artifact12816646171 (45670 bytes), SHA256
 2df54e2e4025a3808bf35724b10dc11fd825be6800de314dde6ff58fe13b18c2.
 API metadata retrieved; local ZIP download blocked by artifact-host access.
 Do not claim local inspection of that ZIP. Independent parser processed all rows
 in CI and its annotations were retrieved. Raw artifact remains on GitHub.
- Unequal-height fixture strengthened to two actually post-resolve grounded feet
 on separate elevations, then read-only/reversed eligibility. Load-path component
 floor78->80. Next M1: inspect raw support routing finding; no gate/tuning changes.


### R9 support routing isolated @d5ef49a (CI40690630151)

- All600 rows completed again;80 load-path unit checks passed,381 math/237 contact/
 128 analytic checks passed; static45 Python tests passed. Force criterion remains
 RED, intentionally unwaived. Isolated reaction8.40000000000000036N; no2x defect.
- Last300 applied range[9.6775186630127,9.677518663012702]N;
 reaction[9.695448846059604,9.695448846059607]N;
 positional cleanup[4.134452379266757,4.134452379267277] force-equivalent N, NOT load.
 Max cross discrepancy0.017930183046905412N passes0.723; both foot sums miss43.4
 by about33.7N, so the overall criterion FAILS. No averaging/window clipping.
- Tick599: previousN1, foot grounded=true,lowest=true,gripping=false;
 hinge impulseY=-0.021291977716878335Ns, gravity impulseY=-0.14Ns.
 The HEAD and MOTOR are ALSO grounded, measured reactions19.98947352225558N and
 13.911184476038581N. All-terrain reaction is43.59610684435376..43.59610684435377N.
 Thus the independent channels agree on the foot's underload: other capsules
 carry the rest. It is not evidence that the foot supports the creature.
- Tick0 previousN0, no grip; no grip toggles anywhere. Every row awake with
 sleep_implemented=false. No false settled/sleep/stance or FA-5 acceptance claim.
- Preserved the prototype's original free rotational hinges/axes/radii/materials
 instead of changing pose/ratio or hiding other contacts to force a stand. Full
 angular/attachment constraints remain to be implemented under existing GDD
 values; the current limited probe cannot be treated as a finished creature Sim.
- Matrix evidence now acknowledges this FAILED preflight while FA-3/4/5/6 remain
 exactly NOT RUN. Next M1: complete missing angular/attachment constraints and
 rerun this unchanged Slug diagnostic before any band or two-foot stance.
 Complete-creature determinism attempts remain0; no retune/M2/camera/captures.


### R10 — diagnostic-only implementation, pinned execution pending

- Supersedes R9 interpretation, NOT accepted force code: all-grounded invariant
  restored; producer/conservation F22/F23/F25 CLOSED, F27/28/29 accepted. F30 is an
  authored-pose blocker, not a missing angular-limit fix. No pose/radius/limits
  changes, no setting changes, original derivation and addendum remain byte-equal.
- Every tick now exports all bodies' start/completed endpoint positions/bottoms,
  velocities/inverse masses and applied/reaction/cleanup channels; start state
  exposes authored spacing even when projection masks it by completed tick0.
- Analytic CI prints each preset/part bottom and flags non-foot below any foot,
  BEFORE600. New analytic check floor129 (was128). It diagnoses, does not pick A.
- Discrete momentum budget measures existing damping, gravity, clamp, internal
  rows, independent across-batch contact velocity deltas and before/after P_y.
  Python reconstructs P_y from endpoints and verifies reaction*dt independently.
  Bias equation includes measured dP/damping/clamp/internal; no force correction.
  Hypothesized damping contribution remains UNVERIFIED until actual pinned run.
- Original seven parser falsifications retained;13 more added (20 total), including
  shared support correctly passing force conservation while never-gripping is
  BLOCKED; airborne load excluded; literal ceiling; body geometry and ledger
  falsifications. Synthetic rows are parser controls ONLY, not physical evidence.
- Local static/review58 Python tests pass. Formatter/linter/shell/diff checks and
  pinned-engine execution status will be recorded after verification. All old
  math/contact/load component floors unchanged. No component count is determinism.
- Full diagnostic stays red for no actual grip/foot load path independently of
  all-grounded force pass; report says "grip never engaged". F30 owner pending;
  FA-3/4/5/6/all AC/A9/runtime gates NOT RUN, complete-creature attempts0.


### R10 first pinned measurements @bc4202a

- M1 push run40694232799: static58 Python tests passed;381 math/237 contact/
  129 analytic/80 load-path checks passed,600 raw diagnostic rows completed.
  Overall M1 RED for missing foot path, not force conservation or unit compilation.
  M0/Android push run40694232735 passed; duplicate PR runs40694241017/40694240944
  also have M1 diagnostic red and M0/Android green. Numeric annotations retrieved
  through GitHub API; not a claim of locally downloading the raw ZIP.
- All-grounded max applied-vs-weight7.105427357601002e-15N;
  reaction-vs-weight0.19610684435377124N; cross0.19610684435376413N.
  All satisfy literal0.723N on EVERY tick300..599. No foot-only weight test is
  substituted; no clipping/normalizing/subtracting the measured bias.
- MEASURED last300 budget: P_before/P_after=0.1634223702948058..
  0.16342237029480586Ns UPWARD; dP=-2.7755575615628914e-17..
  +2.7755575615628914e-17Ns; J_gravity=-0.7233333333333334Ns;
  J_damping=-0.0032684474058961143..-0.003268447405896114Ns;
  J_clamp=0; J_internal=-2.7755575615628914e-17..1.1102230246251565e-16Ns;
  J_contact=0.7266017807392293..0.7266017807392295Ns.
- Therefore R-W=(dP-J_damping-J_clamp-J_internal)/dt predicts
  +0.19610684435375852..0.19610684435376852N, matching observed
  +0.19610684435376413..0.19610684435377124N. Damping removes2percent of positive
  carried endpoint momentum each tick; terrain support replaces this downward
  drag as well as gravity. This is a measured discrete balance, not a waiver.
- Over ALL600, independent Python raw-momentum residual max1.1102230246251565e-15Ns;
  batch velocity-delta vs reported reaction*dt max5.551115123125783e-16Ns;
  bias identity discrepancy max5.861977570020827e-14N. No gravity-free generalization
  or2x sampling normalization. All-terrain43.59610684435376..43.59610684435377N and
  per-foot force ranges are byte-value unchanged from R9.
- Authored root(0,0) audit reproduces Slug motor-.395/foot-.350 (gap.045WU);
  Hopper limbs-.765/feet-.750 (gap.015WU); TwinRoller motor-.695/feet-.650 and-.050
  (gaps.045/.645WU). All3/8/6 parts printed, with non-foot-below-foot flags.
  Tick0 START motor bottom-.065 vs foot-.020; completed both≈-.020, confirming
  why completed positions alone conceal the authored gap. No pose changed.
- Follow-up parser explicitly checks measured drag against resource damping times
  independently reconstructed raw start momentum; significant internal-row drift
  fails bookkeeping. Additional falsifications reject fabricated drag and a grip
  flag without measured foot reaction.24 parser controls plus1 annotation test/63 Python total pass
  locally; original seven controls retained. These remain synthetic parser tests,
  NOT physical load evidence. Grouped annotation avoids GitHub's per-step cap
  hiding engagement, peaks or the completed tick599 behind earlier evidence.
- Owner F30 decision remains pending; no axes/radii/angular limits or tuning changed.
  All runtime acceptance remains NOT RUN; complete-creature attempts0.

- Reporting follow-up: @ad9e5d0's first grouped annotation accidentally included
  raw tick lines and hit GitHub's4096-character message cap. Corrected selection
  excludes raw ticks from annotations ONLY (all600 stay in artifacts), packs
  <=3500-character messages, and tests the ACTUAL embedded workflow Python with
  600 mock raw lines plus first/last/ledger/engagement/F30 evidence. No raw data or
  transients dropped from the diagnostic. No physics or acceptance change.
- Formatter scope: targeted changed-GDScript format check passes. Whole-tree
  formatter check flags pre-existing core/tuning.gd; byte-equal1f2c19f copy also
  fails that formatter check. Protected tuning source is intentionally unchanged;
  linter/static checks pass. This is not a new formatting pass claim for the tree.


### R10 final implementation verification @be04bbf

- Exact implementation SHA be04bbf3fcdb106718a81f47c6adb4340982d2a2.
  M1 CI40695219730 static PASS63 Python;381 math/237 contact/129 analytic/80 load
  components PASS,600 raw rows processed; momentum ledger VERIFIED true over all
  600, including independent damping-vs-raw-start-momentum/resource identity and
  internal cancellation checks. M1 diagnostic RED solely for F30/no genuine foot
  load path. M0 headless506/0 and Android PASS in CI40695219716.
- Corrected annotations now expose COMPLETE first0/last599, engagement, peaks,
  ledger verification and F30 blocker within per-message/count limits. Retrieved
  annotations via API and parsed both row JSONs independently; raw ZIP not locally
  downloaded. Full artifact12818438383,435766bytes, SHA256
  d65c97a9845bda4f484fe34a9133efddf3f05c6023d17f717d2c7588e9733d90,
  https://github.com/sagheerh/clamber/actions/runs/40695219730/artifacts/12818438383.
- IMPORTANT peak scope:9.695448846059607N is the measured peak over ticks300..599,
  NOT all600. Actual all600 measured peak14.81106559439147N; actual applied peak
  14.807263336585688N, below unchanged N1 grip gate17.36N. Grip NEVER engaged on
  ANY tick. Empty toggle list is not a success; no smoothing/clipping hides the
  transient peak. All-gravity/support conservation and measured damping bias are
  unchanged. Global internal-row residual max8.881784197001252e-16Ns.
- Local scripts/review_checks.sh PASS63 tests; changed-GD formatter PASS, full
  linter PASS, shell syntax/diff checks PASS. AST/source-text comparison confirms
  all seven original parser test methods are unchanged; cases were not weakened.
  Protected accepted foundations/tuning/presets/derivation/contact/hinge/export
  byte guards PASS against1f2c19f. Whole-tree formatter baseline exception above
  remains explicitly reported; no protected source changed to tidy it.
- F22/F23/F25 stay owner-CLOSED; measured F31 explanation and F32/F33 diagnostics
  supplied for review, not self-awarded owner acceptance. F30 owner pose decision
  PENDING. No pose/radius/angular-limit branch, no retune/M2/camera/captures.
  FA-3/4/5/6/all coupled AC/A9/§10.6/runtime timing NOT RUN; determinism attempts0.
  Next single milestone M1: await owner's F30 decision, then authorized foot-path
  proof before FA-5 load-band/two-foot work. No angular-limit next-fix inference.


### R11 instrumentation before pinned execution

- F31 owner-CLOSED; accepted conservation verification unchanged. F35 measured
  displacement ledger surrounds existing integration/distance/hinge/contact calls
  without changing call order/arithmetic or writing physical state. Per-body
  endpoint norms/COM norm and all600 profile added. No rest/sleep epsilon; first
  plateau entry is described relative to the OBSERVED last300 P range, not a gate.
- Iteration samples1/2/4/6/12/24 use fresh diagnostic-only tuning clones. Source
  resource remains6; each600 trace/profile is preserved separately. No value is
  selected/adopted and no force data normalized for the sweep. Engine/partial
  failures remain explicit NOT COMPLETED, never zero-amplitude observations.
- F36 now tests a real synthetic body-pose motor lowered from a clear pose through
  the SAME bottom calculation/flagger as production. Production flags remain
  findings until owner pose commit; that commit MUST hard-assert the chosen rule.
- F37 reports last300 gripping count/fraction and per-tick measured grounded foot
  support / ALL grounded support, with range/mean; zero denominator undefined.
  Existing any-loaded-grip boolean is labeled existence-only, NOT sustained stance.
- Local static72 Python/changed-GD format/linter/shell/diff checks passed.
  Measurements below supersede initial runtime-pending status. No behavioral
  corrections, no tuning/preset/contact changes.


### R11 first executed observations @21a9174 / M1 CI40699163425

- Static72 Python tests;381 math/237 contact/131 analytic/80 load checks pass.
  Baseline600 motion/speed/position identities and accepted F31 ledger VERIFIED.
  Six fresh600 sweeps1/2/4/6/12/24 all OBSERVED, ledgers verified; sweep step PASS.
  Baseline load step remains RED only for F30/no gripping path. No rest claim.
- P_y transient is NOT monotonic: ticks0/1/2=-.41174373333333336/
  -.736673289905942/-1.0039825972757102Ns, tick5=-1.6166856921413673Ns,
  tick30=.17897176428114156Ns, tick60=.16342237029481205Ns. From tick66,
  all remaining values lie in observed final range.1634223702948058..
  .16342237029480586Ns. No exact-constant suffix of≥2 ending599; ulp-scale
  fluctuations persist. Descriptive envelope, NOT new rest/velocity epsilon.
- Actual same-tick prediction integrates damped PREVIOUS velocity plus gravity,
  not the COMPLETED velocity. At599 it moves endpoints DOWN.0044800..
  .0076698WU. Position projection cancels these measured displacements, while
  the independent velocity passes finish with upward velocities again. Do not
  pretend dt*v_completed was the downward predictor or directly cancelled.
- Per-endpoint Y ledger at599 (integration, distance, hinge, contact), WU:
  head A=(-.00448000608301,+.00000010103090,0,+.00447990505211);
  head B=(-.00651220824272,-.00000010103090,+.00003404447646,+.00647826479716);
  motor A=(-.00651220824272,-.00000059016495,-.00005461301432,+.00656741142199);
  motor B=(-.00625878080878,+.00000059016495,-.00392010260583,+.01017829324966);
  foot A=(-.00625878080878,-.00001338336054,+.00627216416932,0);
  foot B=(-.00766977665548,+.00001338336054,0,+.00765639329494).
  Net Y is floating noise. Contact projection dominates head/motor/footB;
  footA is lifted by HINGE rows, not contact position projection. Distance rows
  are small but explicitly accounted for. Max position ledger residual over600
  1.5612511283791264e-17WU. All per-part/per-tick vectors remain in raw/profile.
- Precision correction to "positions static": last300 Y/bottoms repeat, but all
  bodies drift X≈−7.1751877234e-6WU/tick at599 (≈.004305WU/600 ticks if sustained).
  Also HEAD tick0 bottom+.2222222222 is NOT tick599−.020; initial transient exists.
  Forward F35 concern remains valid; report measured positions, not a fixed pose.
- Steady max endpoint norm vs iterations1/2/4/6/12/24:
  .201905560144957/.2019046404620631/.2019044236543067/.20190439092127008/
  .20190437249764873/.2019043696109208WU/s. More position iterations do NOT
  remove the nonzero velocity plateau; do not recommend adopting24 as a fix.
  Follow-up also emits per-case X/Y net displacement to separate geometric creep
  sensitivity from persistent velocity amplitude. Source default remains6.
- F37: last300 grip0/300 (fraction0); foot/all-grounded measured support
  .22239253795468855...22239253795468863 (mean.2223925379546886≈22.2393percent).
  Existence is not sustained support; no new threshold. F36 synthetic actual
  lowered-motor control passed; production assertion still awaits pose commit.
- No F35 fix or acceptance claimed. F30 owner decision pending; no A/B/C branch,
  no damping/velocity epsilon/new iteration default. FA-3/4/5/6 NOT RUN; attempts0.


### R11 verified follow-up @4697137 / CI40699727411

- Baseline600 and all6 independent600 sweeps completed; motion/position identities
  and accepted F31 momentum checks verified. M1 static72 Python;381 math/237 contact/
  131 analytic/80 baseline load checks, all zero component failures. F30 is still
  the sole failing gate; diagnostic sweep step succeeds as observations ONLY.
  M0 headless506/0 and Android green in CI40699727445. No device/timing inference.
- X drift magnitude does NOT shrink with more iterations: headA per tick at
  1/2/4/6/12/24 is−7.14510179693e-6/−7.16869662992e-6/−7.17437319565e-6/
  −7.17518772340e-6/−7.17563168037e-6/−7.17570091621e-6WU. Peak speed barely
  changes and stays nonzero. Both observations argue against adopting more
  position iterations as a fix. No value adopted; no behavioral correction.
- Full baseline artifact12820897682 (791211bytes), SHA256
  f0c0c98c8b0c18f0ec05505ef19a9999d2657a5ba7fdcb267f9a4b54b9f8c441;
  full sweep artifact12819933805 (3468821bytes), SHA256
  8ab96a2f68e0b8189b63d4bbd96386f3784cf23927b795ea5795265247b084b0.
  Each raw600/profile/summary retained; no tick discarded, smoothing or clipping.
  GitHub API annotations/metadata inspected, NOT a locally downloaded raw ZIP.
- Original seven parser tests and BOTH algebra-balanced/fake-physics rejection
  methods source-text compared with3c9f942, unchanged. Protected tuning/data/
  creature/contact/hinge/derivation diff against3c9f942 is empty. Math foundations
  untouched; no acceptance threshold weakened. Norm comparison tolerance is only
  existing arithmetic identity checking, NEVER a velocity-zero/rest/sleep epsilon.
- F31 is owner-CLOSED. F35 observation complete but FORWARD ISSUE UNFIXED, no
  self-awarded closure/rest claim. F36 negative control done; production assertion
  explicitly deferred to pose commit. F37 metrics emitted without threshold.
  F30 owner pose decision pending; all runtime gates NOT RUN; determinism0.
  Next single milestone M1: await owner decision, then authorized pose+F36
  hard assertion before FA-5 band; no retune/M2/captures.


### R12 implementation before pinned execution

- Reconciled rehydrated local Git metadata to existing pushed c3b7b01 ONLY after
  comparing EVERY source file with that commit byte-for-byte; no source discarded.
  Branch remains arena/4cd0a587-clamber. No branch switching or source reset.
- Added test-only --spawn-y=.33/.53/.73, default unchanged.33; raw metadata records
  requested height. Same real model/materials/seedless diagnostic/fixed60Hz/zero
  initial motion; no iterations override for R12. Core physics files untouched.
- New three-spawn observer validates all600 rows/case, actual raw initial root,
  zero initial velocities, constant height metadata, configured6 iterations,
  existing F31+motion identities, final300 P range/mean/final and COM vertical
  speed. No equality tolerance/rest threshold introduced. Missing or aborted
  data stays NOT COMPLETED, not an equilibrium estimate. Runtime PENDING.
- Accepted R11 iteration experiment remains manually reproducible via workflow
  dispatch/scripts; routine CI now runs ONLY requested R12 spawn experiment in
  its place. Baseline F30 red is retained; no acceptance test is skipped/weakened.
- Local review78 Python tests (19/5/40/6/8), changed-GD formatter, full linter,
  shell/diff checks pass. Original72 tests retained. New synthetic controls check
  metadata, initial motion, iterations, incomplete cases and no sleep adoption;
  they are NOT physical evidence. No new feel constants, no source retune.


### R12 executed spawn sensitivity @8463240 / CI40710677636

- 78 Python tests pass;381 math/237 contact/131 analytic/80 baseline load checks
  pass. All3 requested fresh600-tick spawn probes complete with unchanged6
  iterations, same model/materials and initial zero motion; F31 and motion
  identities verified. Spawn observer step succeeds. Baseline remains RED for
  F30 only, NOT for conservation, instrumentation, or a chosen sleep predicate.
  M0 headless506/0 + Android green in CI40710677582. No device/timing claim.
- Heights.33/.53/.73 ALL produce final300 P range
  [.1634223702948058,.16342237029480586]Ns and identical mean
  .16342237029480583Ns. Final P=.16342237029480583/.16342237029480583/
  .16342237029480586Ns (spread2.7755575615628914e-17Ns). Envelope entry66/70/73.
  Final mass-weighted COM vy=.1054337872869715..0.10543378728697152WU/s.
  Max endpoint norm.20190439092127008WU/s for all3; grip fraction0 and foot
  share.2223925379546886. Shared observed NONZERO equilibrium for these starts;
  no global-attractor proof, rest acceptance or asleep predicate adopted.
- F39 attribution qualification from EXISTING telemetry, not a fourth experiment:
  mass-weighted baseline COM dx=-7.175187723425593e-6WU at599; integration
  contributes-7.175187723396494e-6; distance rows-2.927783044006219e-17;
  hinge rows+1.789698646617957e-19; contact projection0. Raw start vx*0.98*dt
  independently predicts-7.175187723393609e-6WU. Completed-velocity COM vx*dt
  is-7.321620125911735e-6WU. Thus net COM drift IS accounted for by integration
  of the retained horizontal field; per-endpoint position rows redistribute it.
  Comparing headA alone with its completed velocity does NOT establish net
  position injection, friction irrelevance, or the proposed position-order cause.
  Drift is real and soak projections remain unchanged; no causal fix selected.
- F39 horizon and F40 reference-scale churn are recorded beside FA-3. Horizon
  numbers are analytic rate extrapolations, NOT3600/10000/18000-tick executions.
  Motor churn is intra-step .94..1.53 reference px, NOT captured visible bob.
- Raw spawn artifact12825803242,1693399bytes, SHA256
  6ec8d96cfcb8ed7d6e0ee5078de7ac6ff330a32de16fe50b512ab204c9e5ee78;
  baseline artifact12826381798,791602bytes, SHA256
  8321a585c6a832e3dafb25556e557e785dc3b726e8ed2e3c8f3985205e9ff4c8.
  All raw600/profile/summary/logs retained per case. API annotations/metadata
  inspected and all3 row payloads parsed; raw ZIP NOT locally downloaded.
- All34 accepted parser/control methods source-text unchanged fromc3b7b01;
  original72 checks retained, plus6 R12 controls. Source core/data/creature/
  contact/body/hinge/tuning/derivation/export diff is EMPTY. Full linter, targeted
  formatter, shell syntax, matrix guard and diff checks pass. No thresholds
  widened; no smoothing, clipping, prescribed loads, or adopted constants.
- Owner F36/F37 CLOSED. F38 shared-equilibrium observation supplied without
  self-awarded closure; F39 remains forward SOAK finding with corrected attribution.
  F30 pose AND FA-4 asleep definition remain SEPARATE pending owner decisions.
  Next M1: await both answers, then authorized pose+hard F36 assertion, only then
  FA-5 band. FA-3/4/5/6/all coupled runtime gates NOT RUN; determinism attempts0.
  No retune, velocity epsilon, damping change, M2, or captures.


### R13 measured sample responses @de26fa3 / CI40802438116

- Pinned engine381 math/237 contact/131 analytic/80 load components PASS;
  both600-tick threshold probes OBSERVED, all F31/motion identities verify.
  Observer on/off full physical snapshots equal at every tick for each case.
  Byte-serialized snapshot comparison is added in the follow-up for stricter
  diagnostic evidence (not creature determinism). Baseline F30 ONLY remains RED.
- Crucial actual last300 sample counts PER PASS (all candidates active):
  head3/3, motor3/3, foot3/2. Total17 active responses/tick, NOT one contact/body
  and NOT two foot samples in both passes. Candidate count uses current extent,
  not an assumption from rest length. Counts stable for every last300 tick.
- At599 final pass, all8 active samples take static branch and retain0 tangent.
  Motor u0: A vx .0000483227356581 ->0, B vx .00559673787580 survives.
  u.5: A/B become[-.0027983689378984,+.0027983689378984], sampled tangent0.
  u1: B becomes0, A stays-.0027983689378984; earlier u0/u.5 tangents become
  +.0027983689378984/+.0013991844689492. Head similarly ends A vx
  -.0000241613678290311, B0; earlier tangents+.0000241613678290311/
  +.0000120806839145155. Foot final pass has independent u0/1 and ends vx0
  at599 (last300 body COM range only +/-8.67e-19 float noise).
- Thus zeroing EACH interpolated sample does not simultaneously stop endpoints:
  later overlapping rows measurably reintroduce earlier sample tangent. This is
  observed in actual multi-sample responses, not a single-sample assumption.
  Body-end COM vx final pass: head≈-1.20806839145e-5, motor≈-.0013991844689492,
  foot≈0. First-pass COM vx: head+.000295201730920, motor-.000504600195549,
  foot+.001771830516589WU/s. No change to sampling/order/friction proposed.
- Completed creature COM vx final300 baseline range
  [-.0004392972075547341,-.00043929720755467625]WU/s;1.5 case
  [-.0004392972075547327,-.0004392972075546731]. Maximum paired late difference
  3.984442983884229e-17WU/s. Mean actual COM dx baseline=-7.175187723414263e-6
  vs1.5=-7.175187723414633e-6WU/tick; integrated contribution BOTH
  -7.175187723396494e-6. Steady drift insensitive in this diagnostic, NOT a
  blanket threshold-inactivity claim or a friction fix authorization.
- Transients DO differ: full600 active/static branch counts .15=9917/9850
  (67 non-static),1.5=9909/9909 (0 non-static), total candidates10151/10150.
  Max paired completed COM vx difference over600=.014493333006502587WU/s.
  Last300 BOTH5100/5100 active responses use static branch, so increasing its
  threshold cannot change that observed branch selection. Max endpoint impulse
  identity error1.1102230246251565e-16; sampled target error<=4.164e-17WU/s.
- F42 BOTH cases: grounded sets[0,1,2] for every last300 tick, active contacts
  on all300 ticks, zero newly-grounded transitions in that window. Support
  normal impulse sum≈.726601780739229Ns/tick remains nonzero, not position
  cleanup. Raw per-contact signed impulses and all600 sets/transitions are
  retained as contact-events.jsonl / grounding-events.jsonl per case. This is
  NOT a sleep-breaking/sleep-eligible classification or a changed FA-3 criterion.
- Source-pinned artifacts: R13=12866817056,3405462bytes,SHA256
  7c19029879a62c732cbb9e01871705674a95fc57818afbc37f1a4f593c38a502;
  baseline=12865849732,2482879bytes,SHA256
  baaa4c558b290612142ec20eaa76b7cb9850ec3672be2ad534ba51a0b7901dd7.
  API annotations and metadata inspected; raw ZIP not locally downloaded.
- F38 owner-CLOSED; F40 accepted; F39 REVIEWER CORRECTION (not agent error).
  F41/F42 are measurement/clarification findings, not closed by self-award.
  Owner F30 AND asleep/F42 still pending -> authorized pose+hard F36 assertion
  -> FA-5 band. Re-measure F41 after pose and compare. No resource edit, retune,
  epsilon, damping, iterations adoption, geometry/limits, M2/captures. FA-3/4/5/6
  and all coupled runtime gates NOT RUN; creature determinism attempts0.


### R13 strict-observer follow-up @5c1bffe / CI40802791884

- Strict var_to_bytes full physical snapshot equality passes EVERY600 ticks per
  threshold case (and baseline). It compares serialized state, not approximate
  float equality. This is observer noninterference ONLY, not a determinism gate.
- All91 Python checks pass (19/5/40/13/6/8), targeted formatter/full GDScript
  linter/shell syntax/diff checks pass. Pinned381/237/131/80 components pass;
  both threshold cases OBSERVED with the exact same measured ranges/counts as
  above. Baseline remains RED solely for F30; observer step succeeds. F31 analyzer
  function unchanged and all34 accepted parser/control methods source-identical.
- New independent checks reconstruct active-vs-skipped from sampled distance,
  normal length, endpoint inverse masses, per-sample positional cleanup and all
  impulse responses/continuity. F31/motion verification failure is rejected,
  never silently converted into an OBSERVED diagnostic case. No resource edits.
- Full600 grounded transitions, BOTH cases: tick0 new[1,2] (motor,foot), tick7
  new[0] (head), no lifted transitions. Last300 grounded[0,1,2], no new/lifted,
  yet17 active sample responses/tick. At599 normal impulses per sample for pass0:
  head[.105563333819726,.15133106814863925,.07626349006922774],
  motor[.0956523645662548,.0901259481497068,.046074761884681424],
  foot[.05752437215064493,.06907111040760779,.034995331542740704]Ns.
  Pass1 all8 normal impulses0 but signed tangential impulses persist. Raw signed
  per-contact impulses (both passes), flags and all600 sets remain in artifacts;
  no sleep-breaking/eligibility filter chosen or criterion rewritten.
- Updated artifact12866996647,3407167bytes,SHA256
  48b3687555a2351eaecb7e4add55062ebcb3606a406710c782548b805a72346e;
  baseline12866274067,2483260bytes,SHA256
  aacd23d958f06e19b3772dde30352017cd6fad2c69fbb65816f080062463907a.
  API annotations/metadata inspected; raw ZIP not downloaded locally. M0 run
  40802791874 headless506/0 PASS; Android result recorded in final CI/PR status.
- R11 iteration and R12 spawn drivers/controls retained, workflow_dispatch runs
  them; routine CI now runs the requested R13 observer comparison. No runtime
  acceptance upgrade: owner pose+asleep/F42 still precede authorized pose+F36
  assertion and FA-5 band, F41 must be re-measured after pose. FA-3/4/5/6 and all
  coupled runtime gates NOT RUN; complete-creature determinism attempts0.


### R14 pose measured @126dc80 / CI40804352094 — prediction NOT observed

- Hard authored F36 audit PASS, exact exemption TwinRoller foot5 parent0 retained;
  original horizontal-foot two-sided synthetic bad-pose control still fires.
  JSON diff ONLY five foot axis fields (Slug2,Hopper5/7,TwinRoller4/5 ->DOWN).
- Paired unchanged Slug600/.33/6/.15/zero-motion, sleep DISABLED, real physics:
  before grip0/600; after1/600 (tick19), loaded grip1 tick; last300 grip0 BOTH.
  After last300 foot share.22240637932820798 vs before.2223925379546886.
  Path existence now demonstrated once, NOT sustained support or FA-5 acceptance.
- Before all-grounded reaction43.59610684435376..377N, after
  43.596103429635704..571N; literal43.4+/-.723 every last300 passes BOTH.
  Foot applied before[9.6775186630127,9.677518663012702], after
  [9.678122826771673,9.678122826771675]N; foot measured before
  [9.695448846059604,9.695448846059607], after
  [9.696051516603347,9.69605151660335]N. Both F31/motion independent identities
  verify; everytick raw supports retained, no clipping or supplied load.
- F41 unexpected FOURTH outcome: last300 still grounded[0,1,2] with same active
  counts head3/3,motor3/3,foot3/2 =17/tick. No predicted collapse to sole foot.
  Mean actual COM dx changes -7.175187723414263e-6 ->+9.337328797577746e-6
  WU/tick: reverses direction and grows, NOT smaller, NOT identical old drift with
  different geometry. Retain F41; no pose-artefact downgrade or sampling fix.
  Post completed COM vx range[.0005716731916895578,.0005716731916896102]WU/s.
- This is the CURRENT free-hinge solver with UNCHANGED root spawn.33: after A,
  authored pad starts at-.27WU (previously-.02), not placed on a clear foot-only
  stance. No silent spawn correction. Authored bottoms do not prove dynamically
  maintained pose; angular limits/motors/self-contact are still absent. Do not
  claim why all transient/contact differences occur without further evidence.
- Pose CI now green on original existence criterion, not a strengthened stance
  acceptance:381 math/237 contact/136 analytic/80 load components PASS, all600
  both cases OBSERVED. FA-3/4/5/6/all full runtime gates NOT RUN; determinism0.

### R14 sleep component implementation — pinned engine pending

- EXACTLY two owner R14 Decision2 additions: sleep_still_displacement_wu=.001,
  sleep_dwell_ticks=30. Every previous tuning-resource byte unchanged after
  removing these two lines; source-lock tests cover this and axis-only catalogs.
- CreatureSleep reads only supplied physical snapshots, maximum per-body COM
  displacement strictly below.001 for30 consecutive fixed ticks. No grounding or
  velocity epsilon predicate, no hysteresis/decay/grace/impulse threshold.
- SleepingLoadProbe composes the existing awake probe; diagnostic600 stays awake
  and unchanged. Sleep zeroes EVERY endpoint velocity and parks physical state.
  Any input fully re-arms; asleep ungrounded->grounded wakes (F42), persistent
  support does not. Contact query runs EXISTING resolver on detached clones,
  never injecting loads or moving/impulsing parked production bodies.
- Snapshot contains physical endpoints/tick plus sleep flag/dwell/displacement/
  last sleep/wake ticks. Atomic restore;600-step real engineering Slug tests
  partial-dwell and asleep checkpoints, exact byte-state continuation and wake
  ticks, boundary/reset controls, persistent/new-contact controls and zeroing.
  Engine pending: no fabricated tick/success counts; this is NOT creature
  determinism, all-presets FA-3 or motor-lurch FA-4. Public Sim remains untouched.
- SLEEP PARKS THE PLATEAU, DOES NOT FIX IT. Awake endpoint speed remains about
  .202WU/s (30px/s at150px/WU); feel shimmer risk for motor stage, not addressed now.
- Next M1 after sleep evidence: motors/angular limits/self-contact, then Hopper
  two-foot FA-5 and all3 FA-3/4, public Sim LAST. No tuning changes beyond the two
  owner constants, no retune/M2/screens/camera/captures. Determinism attempts0.


### R14 sleep executed @e36c407 / CI40805104578

- Static96 Python=19/5/40/13/5(new R14)/6/8 PASS. Source locks prove ALL previous
  tuning-resource bytes unchanged (only.001/30 additions) and non-axis preset
  content/parents unchanged. Original34 accepted parser/control methods retained.
- Pinned381 math/237 contact/136 analytic/80 load +3659 sleep component checks
  PASS. Full M1 CI green; unchanged paired pose600 repeats exact measured results
  above. No sustained-support/feel/runtime acceptance implication from green CI.
- Sleep ticks61/210/390, wake ticks180/360,600 original state rows; first sleep
  after62 completed fixed ticks (~1.033s), not a fabricated plateau-entry estimate.
  Restore checkpoints47 (15 accumulated still ticks) and62 (asleep) compare
  553+538=1091 subsequent physical+dwell/sleep/wake states byte-identically.
- Strict boundary/reset/max-per-body tests, all-endpoint velocity zeroing,
  persistent-support NOT waking and actual false->true grounded wake controls
  pass. Bad controller/wrapper restore atomic; invalid dwell rejected. Input
  re-arms fully, prevents accumulating dwell while held. New contact wake uses
  existing resolver on detached clones, no impulse threshold or force injection.
- Awake F41 probe stays awake by construction; wrapper records a separate
  awake_solver_trace_before_sleep_parking and never presents stale/parked force
  fields as a fresh conservation trace. Snapshot predicate reads physical body
  snapshots only; no wall-clock/frame-time or hidden temporal cache.
- Sleep artifact12868315418,5667bytes,SHA256
  0b06ae9a38fb1135a7b62c1c759fff911cc9e329a79471fe948bcf460560a207;
  paired pose12867413739,3985484bytes,SHA256
  f673165d7a2ec938d998607ceb0ededebb391cdaea8024c2b1125ae187b928d0.
  API annotations/metadata inspected, raw ZIP not downloaded locally. All600
  per-body support channels/contact samples retained separately from sleep rows.
- Steps4–6 NOT implemented in this increment. Motors/limits/self-contact next,
  then actual Hopper two-foot band and all3 FA-3/4, public Sim last. F41 persists;
  larger/reversed drift with SAME support set is not the owner's identical-old-
  drift/DIFFERENT-geometry trap. No new approval inferred for a friction fix.
  All full runtime gates NOT RUN; complete-creature determinism attempts0.


R14 provenance follow-up: accepted F31 analyzer function and old controls remain
verbatim; CLI diagnostic_summary updates only runtime owner-decision/limitation
metadata so published reports no longer claim pose/asleep decisions are pending
or that the separate sleep component is absent. Awake diagnostic behavior is
unchanged. New source/provenance control brings Python total97. Pending feel plans
retain NOT RUN, with reasons updated to acknowledge existing components.


### R14 final code validation @d4c260e

- M1 CI40805642120 GREEN:97 Python,381 math/237 contact/136 analytic/80 load,
  plus3659 sleep components pass. Pre/post600 result repeats exactly;1091 restored
  continuations identical with sleep[61,210,390]/wake[180,360]. All40 original/R12
  load-control file bytes and accepted F31 analyze function remain unchanged.
- M0 CI40805642118 GREEN:510 headless checks/0 failures and Android export/
  alignment PASS. No performance/device or full-M1 waiver/gate inference.
- Final pose artifact12868411026,3985484bytes,SHA256
  d32688683bbbe33a71ea61ba0074be0f3881bb7e91540646b0d71df3b3199477;
  sleep12868520505,5667bytes,SHA256
  23d0b2c0d05cd0ed40182481cb7105d59e80b761f636e65d7178fd83e6425312.
  API annotations/metadata inspected, raw ZIP not locally downloaded.
- Active matrix evidence now reflects approved A/A1 rather than a pending owner
  pose choice; FA-4 scope explicitly all3 presets per R14. All full runtime gate
  statuses stay NOT RUN. Steps1–3 implemented; steps4–6 remain next, not complete.
