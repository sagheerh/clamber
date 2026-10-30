# M1 manual-device diagnostic increment — not M1 completion

2026-10-30; active branch `arena/f43f36ab-clamber`; base merged main `7d86dd5`.
Owner intends to perform physical-device tests after implementation.

## Code delivered

- `tests/device/m1_lab.tscn` / `m1_lab.gd`: opt-in engineering session using real
  production presets, the unchanged R25 flatplane fixture, and public Sim.
- `held_input.gd`: event-driven per-touch ownership, L/R/both, no reassignment by
  an extra touch; desktop held keys/mouse; pause/background clears inputs.
- `m1_view.gd`: fixed150px/WU collision diagram, no camera or art/physics mixing.
- Unique user-data session directories, committed tick states/input masks, spawn,
  checkpoints, error state, source/build/hardware metadata and flushed logs.
- `scripts/build_m1_device.py`: hash-verified isolated staging with source
  inventory; exact-engine guarded debug APK export with its own package ID.
  Committed normal boot/preset/workflow files are untouched. Historical R27/R29
  runners are not included in that staged package or executed by the lab.
- `test_held_input.gd`: ten input-only checks supplied for real engine execution.
- `test_m1_device_package.py`: ten executed packaging/static contracts.
- `M1_DEVICE_TEST.md`: desktop F6 / CLI, APK build/install, owner test/extraction.

## Validation actually performed

| Check | Result | Limits |
|---|---|---|
| `bash scripts/review_checks.sh` in Git checkout | 232/0 | static/invariant controls only |
| Same command in newly extracted no-`.git` ZIP | 232/0 | no engine/physics ticks |
| `python3 tests/test_m1_device_package.py` | 10/0 in Git and ZIP | staging, hashes, guards, static wiring; no Android build |
| `python3 tests/test_zip_provenance.py` | 10/0 | provenance checks, not simulation |
| `gdlint tests/device/*.gd` | clean | grammar/lint, not Godot semantic compile |
| `python3 scripts/review_static.py` | 77 scripts/scenes, clean | known static subset only |
| `python3 scripts/build_m1_device.py --prepare-only` | stage created in Git and ZIP | no engine calls, no APK |
| Godot semantic compilation / input unit execution | NOT RUN | pinned executable unavailable |
| APK export, install, touch/background behavior | NOT RUN | engine/templates/SDK/device unavailable |
| New M0 engine regression | NOT RUN | historical516/0 not relabelled fresh |

Initial Git-present suite failed at missing `fb890fd` because this clone starts
from a squashed main. Read-only fetch of the original pinned source restored
history without switching/creating branches:

```text
git fetch --no-tags origin 4796ec632637053214b1463f44120eb54cd17d72
# fetched original commit/history into FETCH_HEAD; no tracked ref changed
```

The existing historical assertions then passed unchanged. No source expectations
or literal workflow pins were edited to hide the missing-object error.

## Invariance

```text
git diff --exit-code 7d86dd5 -- core/ data/ ui/ project.godot export_presets.cfg .github/ tests/sim/ tests/fixtures/
# no output, exit0
python3 tests/source_provenance.py
# core_tree_sha256: 557524202efe109074f692a56240ca6b50fcd422db4ed38888aed1b4476704df
# tuning_sha256: 5f4d0d06564fb3a0847309d83cf5f3c87b9321ea5e2dd87e572e4bd9fe750666
```

No D0, R27 or R29 measurement executed; no solver/adoption/retune, thresholds,
iterations, preset/save expectations, normal boot/export, CI measurement marker,
artifact deletion, billing operation or product-screen/camera work.

## Remaining work — cannot honestly call M1 complete

AC-201/AC-202 known failures remain; rejected AC-202 adoption stays reverted;
FA-3 remains uncredited. Five runtime gates remain NOT RUN, including D2's
reference-phone leg (D07). No tutorial success predicate is invented. Interactive
logging is deliberately not the tick-cost benchmark. Existing prohibitions on
physics/adoption changes were not silently lifted by adding diagnostic access.

M1 stays BLOCKED / NOT SIGNED; M2 blocked. The owner has a new manual test path,
not a validated APK or proof that the existing solver meets acceptance criteria.
