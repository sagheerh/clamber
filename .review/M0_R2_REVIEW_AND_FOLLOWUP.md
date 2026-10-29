# M0 R2 review — engine/build gates VERIFIED, milestone still REJECT

**Reviewed:** 2026-10-28  
**CI-tested branch:** `arena/f08ed236-clamber` at `ba7179b4d6d7fee26522853590578135973fd7bc`  
**This review session's checkout:** `arena/5b72e4ab-clamber` at `0a821da` — M0 code is **not** on this branch; I fetched the other branch read-only.  
**PRs:** none (`gh pr list --state all` empty).  
**Gates:** `docs/GDD.md` §10.1, §10.5, §10.9, §16.1; `CLAMBER_REVIEW_AGENT.md` A4, A5, A7.1, A10, PART B M0.

---

## 1. What I independently verified (not just trusted from the report)

### GitHub API / run evidence I ran
```text
gh api repos/sagheerh/clamber/actions/runs/40625642314
  -> conclusion success, head_sha ba7179b..., branch arena/f08ed236-clamber

gh api .../actions/jobs/122609759675  -> headless: all steps success
gh api .../actions/jobs/122609759367  -> android: all steps success

gh api .../check-runs/122609759675/annotations
  -> notice: "M0: 475 checks, 0 failures"

gh api .../check-runs/122609759367/annotations
  -> notice: "Debug AAB exported; bundle validated; arm64/minSdk26/targetSdk36/
     portrait/native 16KB and APK zip alignment checked. Physical installation
     and frame timing NOT measured."

gh api .../actions/artifacts/12789073777
  -> name m0-android-debug, size 57,346,374 bytes,
     digest sha256:a45fbe10178a99087123f6b87079bd97bad7609f17b44676a255c52bc4557c26,
     expires 2026-11-04T03:18:21Z
```

Earlier runs `40624709321`, `40624858826`, `40624934903`, `40625022532` are **failure** with concrete annotations (`FAIL: garbage primary recovers backup`, `FAIL: fixed step`, `Portrait activity missing`, etc.). So the gate is falsifiable: it has gone red and then green. This addresses A10's "hollow test" concern.

### Local checks I ran on the extracted `ba7179b` tree
```text
python3 tests/test_static.py            -> Ran 6 tests ... OK
python3 tests/test_android_inspection.py -> Ran 7 tests ... OK
bash -n tests/run_tests.sh tests/build_android.sh -> OK
tests/run_tests.sh (no local Godot)     -> exit 127, as expected in this sandbox
```

I also read the code:
- `core/tuning.gd` / `.tres`: **376 exported fields**, 376 values, all seven required groups, every name referenced in `docs/TUNING.md`. Conflicting camera values are both kept: `camera_airborne_zoom_section_4_8 = 0.72` and `camera_airborne_zoom_section_2_3 = 0.75`.
- `core/sim/*.gd` are compile-only stubs; `ui/screens/` has no `.tscn`; no gameplay implementation. No `RigidBody2D`/`Joint2D`/RNG/transcendental/numeric-literal hits in `core/` from my own scan.
- `core/data/save_store.gd` implements primary → `.bak` → `.tmp` → defaults with flushed `.tmp`, `.bak.tmp` staging, non-mutating reads, and write-failure signals. `git log -- core/data/save_store.gd` and `-- core/tuning.tres` show both were introduced once in `8ca7e2f` and never modified afterwards.
- `d15df1a` (the "test assumption" fix) changed **only** `tests/test_runner.gd` and `tests/run_tests.sh`; it did not touch save logic or tuning. JSON-domain comparison and a 4-ULP float64 text-parser tolerance are narrow and documented in M0-D05. This is not a widened gameplay tolerance.
- `tests/run_tests.sh` uses `set -euo pipefail`, checks `godot --version` starts with `4.7.2.stable`, rejects script/parse errors, and requires the exact `^M0: [0-9]+ checks, 0 failures$` marker. `ui/boot.gd` returns `runner.run()` as the process exit code.
- `tests/inspect_android.py` fails closed on package, minSdk 26, targetSdk 36, portrait, debuggable, network permissions, non-arm64 ABIs, non-16 KB ELF PT_LOAD alignment, 4K bundle config, and missing native libs. It explicitly reports `device_installation`/`device_frame_timing` as `NOT MEASURED`.

### What I could NOT verify locally
- Godot 4.7.2 executable, CI logs, and the Actions artifact zip are blocked by this sandbox's network allowlist (`gh run download` → EOF to `productionresultssa9.blob.core.windows.net`; `gh run view --log` → EOF to `results-receiver.actions.githubusercontent.com`).
- `gh run rerun 40625642314` → "cannot be rerun; its workflow file may be broken"; `gh workflow run m0.yml` → HTTP 403 "Resource not accessible by integration". So I could not trigger a fresh run from this reviewer context.
- No physical Android device, `adb`, or frame trace exists here.

---

## 2. Verdict

**R2: engine and Android-build gates are VERIFIED. M0 as a milestone is still REJECT / INCOMPLETE.**

The coding agent's new report is accurate on the big points: 475 real-engine checks, save-corruption recovery, 376 tunables, exact 4.7.2 pin, debug AAB/bundletool/manifest/ABI/16 KB checks. Those were previously unverified and now have E1/E2/E3/E4 evidence.

But the M0 DoD item "Android AAB installs and shows the palette" remains unmet. Per `CLAMBER_REVIEW_AGENT.md:63`, an unverified DoD item is a BLOCKER. The review pack also requires `scripts/review_checks.sh`, an AC matrix, and a PR review; those artifacts are still missing.

Do **not** mark M0 approved, do **not** start M1, and do **not** claim 60 fps.

---

## 3. Remaining findings

### F1 — [BLOCKER] Physical-device acceptance is still open
- **Citation:** `docs/validation/M0.md` "Remaining physical-device gate — NOT RUN"; CI annotation says "Physical installation and frame timing NOT measured"; no `adb`/screenshot/frame-trace artifact exists.
- **Violates:** `CLAMBER_REVIEW_AGENT.md:249` (M0 AAB installs + palette screenshot), GDD §16.1 / `docs/GDD.md:1763`, A4/E4.
- **Finding:** Build validation is not installation. Navy screen, portrait lock, safe-area/cutout, home/resume/lock lifecycle, and measured 60 fps / P95 ≤ 16.6 ms on reference-class hardware are all unmeasured.
- **Done when:** A real device record is attached: hardware model/Android build/API/GPU/refresh/ABI, `adb install` output with artifact hash, AAB-derived APK launch, navy screenshot with commit SHA or device date, lifecycle/safe-area checks, and a frame-time capture with measured P95. Until then this stays open. **Human decision required:** supply a device, or explicitly waive/split this DoD item as a GDD-owner decision. The reviewer cannot waive it.

### F2 — [BLOCKER, review-pack compliance] Mandatory review artifacts are missing
- **Citation:** `git ls-tree` on `ba7179b` shows no `scripts/` directory and no `.review/` directory; `gh pr list --state all` is empty.
- **Violates:** `CLAMBER_REVIEW_AGENT.md:67` (run `scripts/review_checks.sh`), `:89-99` (`.review/m0_ac_matrix.md` is mandatory; missing = blocker), A5.5, A12 (PR review).
- **Finding:** `tests/test_static.py` is a good structural check, but the review pack names a specific entrypoint. Without the AC matrix and PR, I cannot issue the formal verdict artifacts or post a PR review.
- **Done when:** add `scripts/review_checks.sh` (it may wrap the existing static/inspector/contract checks) and paste its exit-0 output; commit `.review/m0_ac_matrix.md` mapping every M0 AC to evidence; open a PR from `arena/f08ed236-clamber` to `main` (or into this session's `arena/5b72e4ab-clamber` if this session should own the work).

### F3 — [MAJOR] Evidence doc points to the earlier run/artifact, not the final one
- **Citation:** `docs/validation/M0.md` says run `40625278718`, commit `12cbe20`, artifact `12788419971`, digest `sha256:8cdad33c...`. The report cites final run `40625642314` on `ba7179b` with artifact `12789073777`; GitHub API gives digest `sha256:a45fbe1017...`.
- **Violates:** A4 traceability; GDD §10.1 requirement that evidence be reproducible.
- **Finding:** Both runs are green and `ba7179b` is docs-only, but the durable record is stale. Two different artifact IDs/digests are in play.
- **Done when:** `docs/validation/M0.md` records both runs, marks `12cbe20` as the validated source commit and `ba7179b` as the evidence commit, and lists the final artifact `12789073777` with digest `sha256:a45fbe...` and expiry `2026-11-04T03:18:21Z`. Push that docs-only fix so CI produces a fresh green run on the corrected commit.

### F4 — [MINOR] Artifact/log evidence is not durable or reviewer-inspectable here
- **Citation:** `gh run download` and `gh run view --log` both fail with EOF to blocked hosts; artifact expires 2026-11-04.
- **Violates:** A4/E4 durability; A5.1 (reviewer must paste check output).
- **Finding:** The AAB/APK and inspection reports exist only inside a 7-day Actions artifact. I can verify metadata/annotations but cannot read `android-inspection.txt`, `AndroidManifest.xml`, `bundle-config.txt`, `zipalign.txt`, or `aab-sha256.txt`.
- **Done when:** commit the small text reports into `docs/validation/M0_android_reports/` (or append them to `docs/validation/M0.md`), including the AAB SHA256 and a short build-log excerpt. Do **not** commit the 57 MB binaries or signing keys. Attach the AAB/APK to a longer-lived GitHub Release or keep a rerunnable CI link. Rerun CI after 4 Nov if the artifact expires before device testing.

### F5 — [NIT] `actions/upload-artifact@v4` Node.js 20 deprecation warning
- **Citation:** check-run annotation on `122609759367`.
- **Finding:** Non-blocking CI hygiene warning. Update when convenient; it does not affect M0 evidence.

---

## 4. Verified items — do not redo these

| M0 item | Status | Evidence |
|---|---|---|
| `godot --headless --run-tests` exits 0 | **MET** | Run `40625642314`, headless job success, annotation `M0: 475 checks, 0 failures`; `tests/run_tests.sh` enforces marker + version + parse errors. |
| Save garbage → `.bak` → defaults recovery | **MET** | `tests/test_runner.gd` real assertions; earlier red runs prove falsifiability; `d15df1a` did not touch `save_store.gd`. |
| ≥40 tunables, no core numeric literals | **MET** | 376 fields, seven groups, `docs/TUNING.md` source map; my local static scan + `test_static.py` pass. |
| No gameplay code in M0 | **MET** | `core/sim/*` stubs, `ui/screens/` empty, no solver/RNG/physics nodes. |
| Exact Godot 4.7.2 pin | **MET** | `project.godot`, CI workflow, `tests/run_tests.sh`, SHA512-checked editor/template download. |
| Android debug AAB + bundletool + manifest/ABI + 16 KB alignment | **MET** | Android job success + annotation + `tests/inspect_android.py` fail-closed logic. |
| Physical install / navy screen / lifecycle / 60 fps | **NOT MET** | No device evidence; explicitly not claimed. |

Test-count baseline for future regression: **475 engine checks + 6 static + 7 inspector = 488 assertions/checks**. No prior milestone exists, so there is no drop.

---

## 5. Human decisions still needed

1. **Device gate:** either provide a physical Android device for F1, or issue an explicit GDD-owner waiver/split (e.g. approve "M0-engineering" and track "M0-device" separately). The review pack does not allow the reviewer to approve with this DoD item unverified.
2. **Camera zoom conflict:** `0.75` (`docs/GDD.md:327`) vs `0.72` (`docs/GDD.md:739`). Keep both in tuning; choose the normative value before M2. Do not let the agent pick in M0.
3. **Review reruns:** this reviewer context cannot rerun/dispatch Actions (403 / cannot-rerun). If you want a fresh independent run, have the agent push the F3 docs fix; that triggers `on: push`.

---

## 6. Paste-ready message to the coding agent

```text
R2 review result: engine and Android-build gates are VERIFIED, but M0 is still
REJECT / INCOMPLETE. Do not start M1, do not mark M0 approved, and do not claim
60 fps. I independently checked GitHub API run 40625642314 on ba7179b: both jobs
success, headless annotation "M0: 475 checks, 0 failures", Android annotation and
artifact 12789073777 (digest sha256:a45fbe... ) present. I also ran the 6 static +
7 inspector tests locally, read the save/tuning/stub/test code, and confirmed the
earlier red CI runs prove the gate can fail. Good work on those items; do not redo
them.

Remaining fix list for R3 (scope: only these items):

F1 [BLOCKER] Physical-device acceptance is still open. Keep M0 status REJECT until
I provide a device or an explicit GDD-owner waiver. When a device is available,
record hardware identity, `adb install` output + artifact hash, AAB-derived APK
launch, navy screenshot with commit SHA/device date, portrait/safe-area/lifecycle
checks, and a real frame-time capture with measured P95 <= 16.6 ms. No emulator,
no FPS cap, no "CI green" substitute.

F2 [BLOCKER - review pack compliance] Add `scripts/review_checks.sh` (it can wrap
the existing static/inspector/contract checks) and paste its exit-0 output. Commit
`.review/m0_ac_matrix.md` mapping every M0 acceptance criterion to its evidence.
Open a PR from `arena/f08ed236-clamber` to `main` (or into this session's
`arena/5b72e4ab-clamber` if this session should own the work). No PR and no AC
matrix means I cannot issue a formal verdict.

F3 [MAJOR] Update `docs/validation/M0.md`: it currently points to run 40625278718 /
commit 12cbe20 / artifact 12788419971 / digest 8cdad33c... . Record BOTH runs,
state that 12cbe20 is the validated source commit and ba7179b is the evidence
commit, and list final run 40625642314 / artifact 12789073777 / digest
sha256:a45fbe10178a99087123f6b87079bd97bad7609f17b44676a255c52bc4557c26 /
expiry 2026-11-04T03:18:21Z. Push this docs-only fix so CI produces a fresh green
run on the corrected commit.

F4 [MINOR] Make the Android inspection evidence durable. Commit the small text
reports (android-inspection.txt, AndroidManifest.xml, bundle-config.txt,
zipalign.txt, aab-sha256.txt, short build-log excerpt) under
docs/validation/M0_android_reports/ or append them to docs/validation/M0.md.
Do NOT commit the 57 MB binaries or signing keys. Attach the AAB/APK to a
longer-lived GitHub Release or keep a rerunnable CI link; the Actions artifact
expires Nov 4 and this reviewer sandbox cannot download Actions binary/log
redirects.

F5 [NIT] Update actions/upload-artifact@v4 when convenient; Node.js 20
deprecation warning is non-blocking.

Keep the good decisions: exact 4.7.2 pin, no gameplay/mockup screens, no invented
tuning values, both camera zoom values (0.75 §2.3 / 0.72 §4.8) left for me to
resolve. Do not change save logic, tuning, or tests to close the device gate.

After F2-F4 are pushed, I will re-review only those fixes plus the fresh CI run.
F1 stays open until device evidence or an explicit human waiver exists.
```

---

*End of R2 review. Formal `.review/m0_verdict.md` / `.json` and PR review remain deferred until F2 creates the PR and AC matrix.*
