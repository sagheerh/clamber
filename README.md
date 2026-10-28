# CLAMBER

M0 engineering skeleton for the offline-first, portrait Android physics game in
[`docs/GDD.md`](docs/GDD.md). There is **no gameplay, product screen, or final art**
in this milestone. Boot is a solid GDD navy (`#00192F`) surface.

## Exact toolchain

- **Godot 4.7.2-stable**, standard GDScript build (not .NET), pinned in
  `project.godot`, CI, and the test launcher. Do not silently substitute a release.
- Mobile renderer (Vulkan), 2D, 1080 × 2340, `canvas_items` / `keep`, portrait.
- Android export: matching **4.7.2-stable** templates, OpenJDK 17, Android SDK
  platform 36/build tools supported by that pinned template, minSdk 26,
  targetSdk 36, arm64-v8a only. Native libraries must pass 16 KB alignment checks.
- No plugins, downloaded art, accounts, network permissions, or SDK integrations.

## Run

Install the pinned editor from the official Godot release, then from this directory:

```sh
godot --version                      # 4.7.2.stable...
godot --headless --editor --import   # class/resource cache on a clean checkout
godot --path .
```

Boot has an empty safe-area container; future top bars and thumb regions go inside
it. Display insets are converted through the viewport screen transform so letterbox
padding is not applied twice. Desktop uses zero insets. No mockup screens are built.
Lifecycle pause emits save-flush/pause signals and mutes the master bus without
changing volume. Resume restores mute state but does **not** unpause gameplay.
SaveStore is synchronous; deferred stores/run/audio systems do not yet exist.

## Test

```sh
tests/run_tests.sh
# Or GODOT=/absolute/path/to/Godot_v4.7.2-stable_linux.x86_64 tests/run_tests.sh

# After the import above, the requested project entry point is also supported:
godot --headless --run-tests
# Equivalent user-argument spelling: godot --headless -- --run-tests

# Dependency-free static contract checks only (NOT runtime verification):
python3 tests/test_static.py
```

`--run-tests` is dispatched by the boot script, not a claim that Godot ships a
built-in test runner. Tests explicitly return a nonzero exit code on failure;
no reliance on debug-only assertions. Fixtures live in the isolated
`user://m0_test_saves` directory and are deleted afterwards.

Runtime coverage: scripts compile, tuning loads, project settings match tuning,
atomic saves, previous-save backup, garbage/invalid schema recovery,
`.bak` before `.tmp`, defaults/deep-copy, interrupted writes, write failures,
safe-area transforms on portrait/16:9/21:9/letterboxed displays, platform no-ops.
The GitHub Actions workflow runs these gates with the exact engine version and
checksum-verifies the downloaded editor. CI has been configured, **not run here**.

## Tuning and architecture

[`docs/TUNING.md`](docs/TUNING.md) maps every exported field to its GDD section.
All core numeric values are serialized explicitly in `core/tuning.tres`; there
are no numeric literals in core scripts. GDD gameplay, presentation, persistence,
replay/codec, acceptance/measurement thresholds, and build budgets are grouped in
Physics, Motors, Camera, Fall, Score, Economy, Generator. No feel/economy values
were changed. Conflicting or unspecified values are recorded in `DECISIONS.md`,
not guessed. Palette colors live in `ui/theme/tokens.gd` per §10.3.

`core/` has no UI/platform dependencies. Only SaveStore and tuning are implemented;
other core scripts are compile-only stubs. Sim/codec public signatures are reserved,
but their empty/null returns are **not implementations**. There are no autoloads.
Platform services complete immediately with failure/unavailable, never grant
entitlements or ad rewards, and never make network or OS capability calls.

### Save protocol

Every payload must be a dictionary with current `schema` (3). Save writes/flushes
`file.tmp`, stages the previous **validated** original via `file.bak.tmp`, renames
that to `file.bak`, then atomically replaces the original with `file.tmp`. The
original is never moved out of place first. A bad original cannot destroy a good
backup. Recovery reads original → `.bak` → `.tmp` → deep-copied defaults, signalling
non-fatal recovery to future UI. Reads never mutate the surviving files.
Write errors are returned and signalled. JSON/schema validation is implemented;
payload-specific validation and migrations remain stubs, not invented schemas.
`flush()` is the GDD durability boundary; this is not an OS power-loss/fsync claim.

## Android build and device gate

1. Install the exact standard export templates through the editor and configure
   Java SDK / Android SDK paths in **Editor Settings → Export → Android**.
2. Install the matching Android Gradle build template via **Project → Install
   Android Build Template**. Generated `android/` files are ignored; no plugin code
   is required. Do not upgrade its Gradle/NDK dependencies independently.
3. Run `mkdir -p exports` then:
   ```sh
   godot --headless --path . --export-debug Android exports/clamber-debug.aab
   ```
4. An AAB cannot be installed directly with `adb install`. Use official Android
   `bundletool build-apks --bundle=exports/clamber-debug.aab --output=exports/clamber.apks`
   with your **local debug signing configuration**, then
   `bundletool install-apks --apks=exports/clamber.apks` on a connected device.
   Never commit signing material. Alternatively select APK format temporarily in
   the local editor for quick debug deployment; the tracked preset remains AAB.
5. Verify generated manifest SDK/orientation/ABI settings, inspect packaged native
   library ELF alignment and APK zip alignment for 16 KB support, then record the
   device model/OS, boot result, frame-time capture, lifecycle and cutout checks.
   Use Android's `check_elf_alignment.sh` and `zipalign -c -P 16 -v 4` on the
   bundletool-produced APKs. P95 target is ≤16.6 ms on Snapdragon 660-class hardware.

**Current validation limitation:** this sandbox has no Godot, JDK, Android SDK,
`adb`, or physical device. GitHub release metadata is reachable, but editor assets
redirect to a host blocked by the network allowlist. No engine compilation,
headless execution, AAB, installation, alignment or 60 fps measurement is claimed.
M0 remains open until those gates have actual evidence.
