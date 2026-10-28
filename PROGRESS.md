# CLAMBER progress

## Current milestone: M0 — APPROVED / COMPLETE (owner override); M1 — READY

Session date: 2026-10-28. Normative inputs: `docs/GDD.md` and
`docs/ui/CLAMBER_UI.jpeg`. M0 is accepted by the GDD owner under M0-D07, dated 2026-10-28. Verdict:
**APPROVE — HUMAN OVERRIDE**. Missing device evidence and measured FPS/P95 are
waived for M0 only, not represented as measured. Land M0 before the separate M1
scaffold/PR; no M1 implementation or gate completion is claimed by this closeout.

### Exists

- Pinned Godot4.7.2-stable project: Mobile renderer, 1080×2340, portrait,
  canvas_items/keep, 60 Hz, pixel snapping, MSAA off, ETC2/ASTC import enabled.
- Engineering-only navy boot surface with safe-area container and lifecycle hooks.
- `core/tuning.gd` / `.tres`: **376 exported fields**, seven required groups,
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

Solver, creature model/validation/codec, run/fall/checkpoint systems, generator,
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

### M1 kickoff — separate scaffold after M0 merge

- M0 PR [#1](https://github.com/sagheerh/clamber/pull/1) is **MERGED**, merge commit
  `c641990be2d77c57c223bc7cbc54d0097c3d8816`, verdict
  **APPROVE — HUMAN OVERRIDE**. Closeout record commit: `5c6cbbb`.
- M1 starts in a separate draft PR with `.review/m1_ac_matrix.md`. It records the
  standalone solver/three-preset/harness scope and every required gate as pending.
- This kickoff contains no solver, presets, baseline, captures, M1 runtime test or
  tuning/save/test changes. The M0 engine stub remains explicitly nonfunctional.
- Required next increment: mathematical state/preset fixtures and independent
  solver work, with exact public interfaces and no invented grip threshold.
- M1 gates are **NOT RUN / NOT MET** until the actual pinned-engine harness and
  evidence exist. Do not treat M0's 475 checks or owner waiver as M1 acceptance.

### M1 scaffold fix — review infrastructure (no solver)

- Vendored the full external review pack verbatim at `docs/CLAMBER_REVIEW_AGENT.md`
  so the matrix and CI share one normative copy instead of paraphrased excerpts.
- Added `scripts/review_checks.sh`: M0 static/inspector tests, shell syntax, and the
  A9/INV static guards (no global RNG, tick-derived inputs, `_process(delta)`, or
  engine physics nodes in core; no transcendentals in `core/sim`; seed is a
  `Sim.setup` parameter; 60 Hz fixed step; vendored pack present; matrix honest).
  It is a **static honesty gate**, not M1 runtime evidence.
- Reconciled `.review/m1_ac_matrix.md` with PART B M1, A9.1–A9.7, INV-01–INV-10,
  A5/A8/A10/A12, the two frame conditions, the one-bit falsification requirement,
  and the M0 regression/test-count baseline (488 checks). Every runtime row remains
  **NOT RUN**.
- Renamed the workflow to `CI` and added a `review-scaffold` job that runs
  `scripts/review_checks.sh` with `pipefail`; the headless and Android jobs are
  unchanged M0 regression. Passing these jobs is still not M1 acceptance.
- No solver, preset, baseline, threshold, tuning, save or runtime change is
  included in this scaffold fix.
