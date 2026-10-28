# CLAMBER progress

## Current milestone: M0 — APPROVED / COMPLETE (owner override); M1 — IN PROGRESS / production definitions and contact components, coupled gates NOT RUN

Session date: 2026-10-28. Normative inputs: `docs/GDD.md` and
`docs/ui/CLAMBER_UI.jpeg`. M0 is accepted by the GDD owner under M0-D07, dated 2026-10-28. Verdict:
**APPROVE — HUMAN OVERRIDE**. Missing device evidence and measured FPS/P95 are
waived for M0 only, not represented as measured. Land M0 before the separate M1
scaffold/PR; no M1 implementation or gate completion is claimed by this closeout.

### Exists

- Pinned Godot4.7.2-stable project: Mobile renderer, 1080×2340, portrait,
  canvas_items/keep, 60 Hz, pixel snapping, MSAA off, ETC2/ASTC import enabled.
- Engineering-only navy boot surface with safe-area container and lifecycle hooks.
- `core/tuning.gd` / `.tres`: **400 exported fields** (376 original +24 owner M1-D04), seven original groups,
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
