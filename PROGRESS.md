# CLAMBER progress

## Current milestone: M0 — implementation present; validation BLOCKED

Do not start M1 until M0's engine/device gates have evidence. Session date:
2026-10-28. Normative inputs: `docs/GDD.md` and `docs/ui/CLAMBER_UI.jpeg`.
Read §10.3, §10.4, §10.5, §11.6 before implementation; consulted the numerical
specifications throughout the GDD for tuning. No gameplay/art/product screens built.

### Exists

- `project.godot`: Godot 4.7.2-stable pin, Mobile renderer, portrait, 1080 × 2340,
  canvas_items/keep, 60 Hz, pixel snapping, MSAA off, GDD navy clear color.
- `ui/boot.tscn` / `.gd`: engineering boot only; 60 fps cap, lifecycle pause and
  synchronous-save flush signals, master mute/restore, no automatic gameplay resume.
- `ui/components/safe_area.gd`: Android physical insets transformed into viewport
  margins; empty container, zero desktop insets. Runtime/device checks pending.
- `core/tuning.gd` / `.tres`: **376 explicitly serialized exported fields** in the
  seven required groups. `docs/TUNING.md` gives source references. Includes part
  stats, solver/motor/fall values, camera, score, economy, generator, save/codec,
  audio/haptics/UI policies, performance budgets and evaluation thresholds. No
  feel/economy changes. No numeric literals in any core `.gd` script.
- `core/data/save_store.gd`: schema-checked JSON; flushed tmp → staged previous
  valid backup → atomic primary replacement; `.bak` → `.tmp` → defaults recovery;
  non-fatal recovery/write-failure signals. Never replaces a good backup with a
  corrupt primary. Synchronous writes, no queue to flush in M0.
- `platform/{share_plugin,billing,ads,haptics}.gd`: injectable unavailable/no-op
  interfaces, explicit completion signals where relevant, Android TODOs, no SDKs.
- Required architecture directories, compile-only core/shared component stubs,
  reserved Sim/CreatureCodec interfaces, palette tokens and empty theme.
- `tests/run_tests.sh`: exact-version check, clean import and project test dispatch.
  GDScript tests cover save corruption, defaults, precedence, interrupted writes,
  invalid schema/root, write failures, core loading, tuning, safe-area transforms,
  platform no-ops. `tests/test_static.py`: dependency-free architecture gates.
- `.github/workflows/m0.yml`: checksum-verified pinned editor + headless tests.
- `export_presets.cfg`: debug Android AAB, Gradle, minSdk 26, targetSdk 36, arm64
  only, immersive, no network permissions. Export/device gates not run.
- `README.md`: setup/test/export instructions, AAB→APKs installation procedure,
  signing/alignment reminders, limitations and architecture handoff.

### Explicit stubs / not built

Solver, creature model/validation/codec, run/fall/checkpoint systems, generator,
wallet/medals/score, schema migrations, settings/debounces, lifecycle run/audio
consumers, all S00–S16 screens, all native plugins. Stub Sim/codec null/empty returns
are deliberately nonfunctional and unused. No autoloads, art, audio, gameplay,
Android Gradle template, signed artifact, purchases, advertising, or networking.
Historical migration fixtures are unspecified and were not fabricated.

### Validation evidence (local)

- `python3 tests/test_static.py`: **6 tests PASS**. Checks exact resource/export
  correspondence and inventory coverage, named normative values, zero core numeric
  literals/UI/platform dependencies, sim guardrails, project/export pins, skeleton,
  references and reserved public signatures.
- `PYTHONPATH=.tools/python .tools/python/bin/gdlint core ui platform tests`:
  **PASS**, 36 GDScript files parsed/linted (gdtoolkit, not Godot type checking).
  Only unused arguments on verbatim stub interfaces and early-return count on the
  checked atomic-write function are explicitly suppressed.
- `bash -n tests/run_tests.sh`: **PASS**.
- `tests/run_tests.sh`: static suite passes, then **exit 127 — exact engine absent**.
- `godot --headless --run-tests`: **NOT RUN**, no executable available.
- CI: configured, **not dispatched**, no claimed green build.
- Android AAB/export/install/16 KB alignment/60 fps/safe areas/lifecycle on device:
  **NOT RUN**. No JDK/SDK/adb/device; release asset download is network-blocked.

### Definition of Done

| Criterion | State | Evidence |
|---|---|---|
| `godot --headless --run-tests` exits 0 | **Not met** | Runtime unavailable; launcher correctly fails rather than skipping |
| Save garbage → backup → defaults test passes | **Not met** | Test implemented; requires engine execution |
| Android debug AAB-derived install; navy at 60 fps | **Not met** | Preset/instructions only; no device/artifact/performance evidence |
| ≥40 named tunables; no core hardcoded numbers | **Met (static)** | 376 fields; static scan passes |

### Decisions / blockers / next

M0-D01–D04 and M0-B01–B03 are in `DECISIONS.md`. Only M0-B01 blocks M0
completion; unresolved future feel/generator values were not guessed. **Next:
finish M0 validation on an equipped runner/device, not M1 implementation.**
