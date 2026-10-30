# M1 diagnostic lab — desktop and Android

This opt-in lab lets the owner inspect the **existing M1 solver code** on a real
phone. It is not the game UI, an M1 sign-off, or a replacement for R29 evidence.
M1 is still **BLOCKED / NOT SIGNED**: AC-201 and AC-202 remain failed, FA-3 is
uncredited, and phone/performance/feel acceptance is not established.

## What is implemented here

- Slug, Hopper and TwinRoller use production `CreaturePresets` and public `Sim`.
- The existing authored R25 flatplane/spawn/material fixture is reused unchanged.
  This is a **new manual diagnostic session**, not a rerun of a historical gate.
- Touch L/R, hold both fingers, or use A/Left and D/Right on desktop. Each touch
  owns its original channel until release; a third touch cannot steal it.
- Pause/resume, preset selection, and safe-area-aware layout. Backgrounding or
  focus loss clears held input and pauses; resuming requires an explicit tap.
- The public fixed-step accumulator controls 60 Hz ticking, max-three catch-up
  and dropping excess time. The lab never directly edits physics state.
- A fixed **collision-geometry diagram**, 150 px/WU; no camera tracking, artwork,
  eye physics or camera acceptance claim. Green indicates actual grip, coral
  grounded, gold head. A moving creature can leave the diagram or finite terrain;
  this is reported, not silently reset or teleported.
- Per-tick input and actual committed simulation state, spawn, checkpoints,
  failure state, engine/hardware and package provenance in unique session folders.
  Background/pause flushes the trace. Errors stop execution, not auto-retry.

Interactive logging/snapshots are intentionally expensive and **must not be used
as D2's benchmark**. No tutorial goal/success predicate, FA-6 success count,
AC-201/202 pass, reference-phone result or cross-device determinism is invented.

## Desktop (Godot editor)

Install the checksum-verified exact **Godot 4.7.2-stable, official ed1daf0bf**
build and import this source project. See `LOCAL_RUN.md` for checksum steps.
Open `tests/device/m1_lab.tscn` and press **F6 (Run Current Scene)**, not F5.
Alternatively:

```bash
export GODOT=/absolute/path/to/godot
"$GODOT" --editor --path . --import
"$GODOT" --path . res://tests/device/m1_lab.tscn
```

The normal F5 boot scene is intentionally unchanged. Start paused, choose a
preset, then press Start. Each preset selection creates a fresh uniquely named
manual session and retains previous logs. Pause before copying logs.

Input-only unit checks (no solver/physics ticks):

```bash
"$GODOT" --headless --path . --script res://tests/device/test_held_input.gd
# Expected: 10 checks, 0 failures; requires a real engine run to establish this.
```

## Build a separate debug APK

Prerequisites: Python 3.10+, the exact Godot editor **and matching export
templates**, JDK17, Android SDK36 (including build tools/adb), and your normal
Godot Android export configuration. The script configures that editor's SDK/JDK
paths from the two environment variables below. It does not touch billing,
credentials, signing keys, the normal project scene or the committed export preset.

```bash
export GODOT=/absolute/path/to/godot
export JAVA_HOME=/absolute/path/to/jdk17
export ANDROID_HOME=/absolute/path/to/android-sdk

# Optional: inspect isolated staging only; no engine or physics execution.
python3 scripts/build_m1_device.py --prepare-only

# Real build (requires the editor + SDK + export templates on your machine).
python3 scripts/build_m1_device.py
adb install -r exports/m1-lab.apk
```

The builder stages into a NEW `.tools/m1-device-*/project/` directory and exports
`exports/m1-lab.apk`, separate package **`org.clamber.m1lab`**. It includes only the
lab and its shared fixture, not the historical R27/R29 runners. No automatic gate
or device run happens during staging/export. The production package remains
`org.clamber.game`. To prevent accidental evidence replacement, an existing APK
is not overwritten; use `--output exports/m1-lab-session2.apk` for another build.
This command is a build path, not a claim that an APK has been built here.

Outputs to retain: APK, `.sha256`, `.source.json`, `.engine.txt`, `.import.log`,
`.export.log`, and the exact source commit/ZIP. The source sidecar hashes staged
core/presets/lab/fixture files; its embedded copy is also recorded in sessions.

## Owner test and return evidence

1. Open **CLAMBER M1 Diagnostic**, choose Slug and Start. Try idle, held L, held R,
   both, release; check that release does not stick. Repeat manually for Hopper
   and TwinRoller. This is exploratory testing, not a prescribed acceptance run.
2. While holding a pad, background and return: simulation should remain paused
   with released input until explicitly resumed. Try two touches then a third;
   the third must not reassign either existing channel.
3. Pause, record your phone model/Android version and observations or video.
   No timing or feel threshold is being authored here.
4. Retain the **whole** `user://m1_lab/` folder shown in the diagnostic label.
   On a debug Android install, an example extraction is:

   ```bash
   adb exec-out run-as org.clamber.m1lab tar -cf - files > m1-lab-device-logs.tar
   ```

   `run-as` requires the debug package and device support. If it fails, retain
   the error and use the displayed data path / Android Studio Device Explorer;
   do not send an empty archive as evidence. Desktop user-data paths are shown
   in the lab; copy `m1_lab/` after pausing or closing it.
5. Send the logs, video/notes, and APK provenance sidecars together. Keep failure
   files and previous sessions; do not remove them or call a failed session PASS.

## Validation status of this increment

Python package/static tests and GDScript grammar/lint were run here. A real Godot
binary, Android SDK/templates and phone are not installed here. **Engine semantic
compilation, interactive input tests, APK export/install and device behavior are
NOT RUN**, not passing results. The input unit script is supplied for owner use.
No D0/R27/R29 physical measurement was run. Existing 232 controls can be checked
in a no-`.git` ZIP export. A squashed/limited-history Git checkout may lack the
historical objects required by the unchanged assertions. This session restored
them read-only with:

```bash
git fetch --no-tags origin 4796ec632637053214b1463f44120eb54cd17d72
bash scripts/review_checks.sh
```

Git-present controls and no-`.git` ZIP controls both passed 232/0 after that;
no historical assertions were weakened. If fetching history is unavailable, use
the ZIP path, not edited expectations or a fake `.git` directory.

M1's existing physics failures are not fixed by this diagnostic tooling. Changing
the solver or retrying the reverted AC-202 adoption remains outside the prior
no-physics authorisation. Physical-device testing can provide observations, but
cannot turn those known failures into “code complete / M1 passed” by itself.
