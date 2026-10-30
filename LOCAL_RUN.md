# Local ZIP measurements — M1 BLOCKED, NOT SIGNED

This is an engineering/headless measurement path, not a signed M1 game release.
AC-201 FAILED; AC-202 FAILED (adoption reverted); FA-3 is uncredited. M2 remains
blocked. A merge is not a verdict. Do not run D0 or any historical R24–R28 arm.

## Prerequisites

Use Bash, Python 3.10+ and the **standard (not Mono) Godot 4.7.2-stable** editor
for your OS. On Windows use Git Bash with Python and Godot on its executable
path (no Git repository is needed). On macOS/Linux use a terminal with Bash.
Install Godot from:

https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable

Download your platform's archive and that release's `SHA512-SUMS.txt`. Verify the
archive **before extracting/running it**. For example on Linux:

```bash
archive=Godot_v4.7.2-stable_linux.x86_64.zip
grep -F " $archive" SHA512-SUMS.txt | sha512sum --check --strict
unzip "$archive" -d godot
```

On macOS use `shasum -a 512 "$archive"` and compare the entire digest to the
matching filename in `SHA512-SUMS.txt`; on Windows use PowerShell
`Get-FileHash -Algorithm SHA512 <archive>` and compare likewise. Stop on a
missing entry or mismatch. The build string must be exactly
`4.7.2.stable.official.ed1daf0bf`, not merely another 4.7 editor.

## Unzip and run once, in order

The prior M1 foundations were merged to main at `7d86dd5`; this continuation is
on `arena/f43f36ab-clamber`. Download the ZIP of an exact source commit on this
branch for these instructions. The earlier requested name
`m1-blocked-2026-10-30` is not asserted here as a published tag. Do not use the old
`arena/5b72e4ab-clamber` source. For interactive desktop/phone testing instead of
headless measurements, see `M1_DEVICE_TEST.md`.

Unzip the source ZIP, enter its top-level directory, then copy/paste, replacing
only the Godot binary path. Use an absolute path, including spaces if necessary:

```bash
cd /path/to/unzipped/clamber
export GODOT=/absolute/path/to/Godot_v4.7.2-stable_linux.x86_64
export CLAMBER_LOCAL=1
"$GODOT" --version
python3 tests/source_provenance.py
bash scripts/review_checks.sh > review-controls.log 2>&1
cat review-controls.log
# Expect 232 controls total, 0 failures. Stop if any test fails.

# Run each arm once, in this order. Stop on any error; do not retry.
bash tests/run_m1_r29.sh D1 &&
bash tests/run_m1_r29.sh D2 &&
bash tests/run_m1_r29.sh D3 &&
bash tests/run_m1_r29.sh D4 &&
bash tests/run_m1_r29.sh D5
```

D1–D5 run the existing real measurement scripts with unchanged inputs,
assertions, horizons and thresholds. D2 includes Hopper alone and a labelled
aggregate of ten independent Slugs; 3.0 ms is **not** applied as a proxy pass/fail.
D3 is 100 × 10,000 ticks and can take a while; do not interrupt and restart it.
D5 also runs the existing D7 controls/M0 regression checks. D0 is historical
only and is never executed by these commands. No CI markers are activated.

The committed `tests/fixtures/source_manifest.json` identifies the pinned
**core source** (`0c1d3f8…`), not the later self-referential packaging commit.
It checks tuning separately and a canonical sorted path/content SHA256 of every
source file under `core/`, rejecting additions, removals, renames and symlinks.
Only generated `.gd.uid` sidecars beside `.gd` files are excluded, just as the
Git guard ignores those untracked editor files; they are not committed core blobs.
All pinned core files are non-executable regular blobs; ZIP permissions are not
used as source identity. Do not regenerate/edit the manifest to bypass a failure.
Historical review assertions use archived, hash-pinned original blobs when
`.git` is absent; they do not compare to invented or regenerated expectations.

## Send back the evidence

Send the **whole** `tests/fixtures/m1_r29_execution/` directory (ZIP it), including
`import.log`, `compile.log`, per-arm logs, `engine-build.txt`, `local-run.json`,
raw traces/CSVs/hashes, `captures/`, local measurement evidence/report, and any
failure state. Include `review-controls.log`, OS, CPU model, and whether Godot
was run under translation/emulation. Do not send just screenshots or summaries.
Some outputs exist only after their arm succeeds; retain partial evidence on
failure. Local evidence stays in this folder, not the historical `.review/`
record. The ledger enforces order, once-only execution, and STOP after failure;
do not delete it to rerun an arm. Even a preflight failure requires review first.

**A local run is owner-attested evidence, not CI evidence; D2's reference-device
leg still needs the phone (D07).** Local repeat equality is not cross-architecture
or independent-RNG determinism evidence. FA-6 has variance source NONE and no
authored tutorial success predicate; do not invent a success count.

## Troubleshooting

- `_checked` parse error: the fixed helper is `_checked_step`. Confirm the ZIP
  contains that name in `tests/sim/test_r29.gd`; do not use an old download.
- Import failure: retain logs and stop. Deleting the generated `.godot/` cache can
  fix stale imports, but do not retry an attempted arm without owner review.
- Missing-Git error in the runner usually means `CLAMBER_LOCAL=1` was not exported
  in this terminal. Do not set fake CI IDs or install a fake `.git` directory.
- Manifest mismatch: stop and send logs. Re-extract the correct source ZIP for
  inspection; do not alter core, tuning, tolerances, or the manifest to make it pass.
- Wrong build: install the checksum-verified pinned release. Do not substitute.
- Local hardware/CPU details may need manual supplementation on macOS/Windows;
  missing CPU identification is reported as NOT REPORTED, never as a phone result.
