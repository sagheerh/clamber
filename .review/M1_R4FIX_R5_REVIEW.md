# M1 R4 fix — R5 verification of PR #3 @ `0ec87d0`

**Reviewed:** 2026-10-28  
**PR #3 (canonical draft):** `arena/4cd0a587-clamber` @ `0ec87d0ba2664ef9ad23920ced91e4b2761a17e5`  
**CI at that exact commit:** M1 run [`40636758741`](https://github.com/sagheerh/clamber/actions/runs/40636758741) and M0/Android run [`40636758718`](https://github.com/sagheerh/clamber/actions/runs/40636758718) — **green**.

---

## 1. Verdict

| Item | Verdict | Independent evidence |
|---|---|---|
| **F7** pack vendored | **MET** | `sha256sum docs/CLAMBER_REVIEW_AGENT.md` → `e3bd06654e0f92aaca55d0cc85e79f6d589a45aa6d9ddab5f4f068db22edb9a1`; `wc -l` → **379**; file has the original `# CLAMBER — REVIEW / GATEKEEPER AGENT` header and all of `PART A…PART E`, i.e. genuinely byte-identical, not retyped. |
| **F12** false attribution | **MET** | `DECISIONS.md` M1-D01 now says the attribution “was incorrect and is withdrawn”; M1-B02 reads **“RESOLVED (vendored), not waived”**; `docs/validation/M1.md` and the matrix repeat the correction. Grep for `excerpt`/`partial`/`absent` across tracked docs/scripts → no stale claim left. |
| **F8** tick-proof guard | **PARTIALLY MET** — see F15 | `scripts/check_m1_matrix.py` runs first in `review_checks.sh`; I reproduced the `PASS | None` failure myself (exit 1, three errors) and the pack-tamper failure (`+1 newline` → SHA + 379-line error). But an allowlist bypass exists. |
| **F13** injected tuning | **MET** | `constraint.gd`: `float(tuning.physics_one) / float(tuning.physics_tick_hz)`; new `_injected_tick_rate()` duplicates the resource, injects 120 Hz, asserts the compliant multiplier differs from 60 Hz; primitive count 81 → **82** in CI. |
| **F14** branch bookkeeping | **MET** | M1.md: “M1 working branch for PR #3 … PR #3 is the sole canonical M1 draft. The reviewer branch is only the document carrier.” |
| **No scope creep** | **MET** | `git diff f51ecd4 0ec87d0 -- core/tuning.gd core/tuning.tres docs/TUNING.md core/data/ tests/test_static.py tests/test_android_inspection.py tests/test_runner.gd tests/run_tests.sh core/sim/sim.gd project.godot` → **empty**. Only `core/sim/constraint.gd` changed, one line. |
| **Test count** | **VERIFIED** | 15 guard tests + 6 static + 7 inspector = **28**, exactly as reported; engine 475 unchanged; primitive 82. |

The pack provenance is handled the right way: the immutable file keeps its exact bytes and a **sibling** `docs/CLAMBER_REVIEW_AGENT.provenance.md` records source commit `9a9350c`, hash, length and scope. That is better than editing the pack.

---

## 2. One remaining finding

### F15 — [MAJOR] The claim guard is a blocklist; six synonyms still pass
- **Citation:** `scripts/check_m1_matrix.py` → `SUCCESS = re.compile(r'\b(?:met|pass|passed|verified)\b', re.I)`.
- **Reproduced by me** on the real tracked matrix (each mutation reverted afterwards):

  | Mutated `AC-201` status | Evidence | Guard exit |
  |---|---|---|
  | `PASS` | `None` | **1** (correct) |
  | `PASS` | `CI40636758741` | **1** (correct) |
  | `COMPLETE` | `CI40636758741` | **0** ← bypass |
  | `DONE` | `CI40636758741` | **0** ← bypass |
  | `GREEN` | `CI40636758741` | **0** ← bypass |
  | `ACCEPTED` | `CI40636758741` | **0** ← bypass |
  | `MEASURED (4 s)` | `CI40636758741` | **0** ← bypass |
  | `SOLVED` | `CI40636758741` | **0** ← bypass |
  | pack + one newline | — | **1** (correct) |

- **Why it matters:** A10's “ticked box” is the exact fake this guard is meant to stop, and `COMPLETE` is the most natural word a future agent would type. The guard currently protects against the honest reviewer's own wording, not against a claim.
- **Done when:** the script **allowlists** the status cell instead of blocklisting tokens. Only these values may appear while the freeze is active:

  ```text
  NOT RUN
  NOT RUN for M1
  STATIC CHECK ONLY
  PASS (regression only)      # + run/commit citation, gate = M0 regression
  PASS (count floor only)     # + run/commit citation, gate = A8 test-count floor
  ```

  Anything else — including an empty status — is an error, so `COMPLETE`, `DONE`, `GREEN`, `ACCEPTED`, `SOLVED`, `MEASURED`, `PASSED`, `VERIFIED`, `met`, `~~NOT RUN~~` and new synonyms all fail closed. Also scan every `|`-row in the file, not only the first table, and keep the `NOT RUN ≥ 12` floor. Keep the existing seven tests and add one parametrised test over the six words above plus a test that an empty status fails.

---

## 3. Status of M1

- **Runtime gates: all still NOT RUN.** No contacts, no presets, no accumulator, no replay, no baseline, no soak, no captures. The agent correctly claims none of them.
- **M1-B01 remains open** (radii incl. head, head mass/length treatment, grip threshold with units). This is the owner's to supply.
- **M1-B02 resolved** by vendoring; executing the INV sweep, A10 five fakes and A12 verdict is still outstanding and belongs to the review process, not to the coding agent marking rows green.
- `M0-B02` (0.75 vs 0.72 zoom) is still an M2 decision.

---

## 4. Paste-ready message to the coding agent

```text
R5 verification of PR #3 @ 0ec87d0: F7, F12, F13 and F14 are MET, and F8 is
mostly done. I re-verified everything myself rather than trusting the report:

- docs/CLAMBER_REVIEW_AGENT.md is byte-identical: sha256 e3bd06654e0f92aaca55d0cc85e79f6d589a45aa6d9ddab5f4f068db22edb9a1, 379 lines, original header, PART A through PART E intact. Recording provenance in the sibling .provenance.md instead of editing the file was the right call.
- M1-D01's false attribution is withdrawn everywhere; M1-B02 reads RESOLVED
  (vendored), not waived; M1.md branch wording is correct; no stale "pack absent"
  text remains in docs, scripts or workflows.
- constraint.gd now derives both factors from the passed tuning, and the synthetic
  120 Hz assertion is genuine (primitive count 81 -> 82 in CI annotations).
- CI at 0ec87d0 is green: M1 40636758741 (82 primitive checks, 0 failures;
  "M1 acceptance: NOT RUN") and M0/Android 40636758718 (475 engine checks).
- 15 guard + 6 static + 7 inspector = 28 Python tests, exactly as reported.
- git diff f51ecd4 0ec87d0 over tuning, TUNING.md, save code, M0 tests, sim.gd and
  project.godot is empty; only one line of constraint.gd changed. No scope creep.

One finding remains before F8 can be called done.

F15 [MAJOR] The claim guard is a blocklist, so six synonyms still slip through.
I mutated the real tracked AC-201 row and ran the guard: PASS|None -> exit 1
(correct), PASS|CI40636758741 -> exit 1 (correct), but COMPLETE, DONE, GREEN,
ACCEPTED, SOLVED and MEASURED (4 s) all returned exit 0 with a CI citation.
"COMPLETE" is exactly the word a future agent would type, so this guards the
honest reviewer's vocabulary, not the fake.

Fix: allowlist the status cell instead of blocklisting tokens. While the freeze is
active, the only permitted values are:
  NOT RUN
  NOT RUN for M1
  STATIC CHECK ONLY
  PASS (regression only)    -> only for gate "M0 regression", with a run/commit citation
  PASS (count floor only)   -> only for gate "A8 test-count floor", with a run/commit citation
Anything else, including an empty status, must fail closed. Scan every |-row in the
file, not just the first table, and keep the NOT RUN >= 12 floor. Keep your seven
existing guard tests, add a parametrised test over the six bypass words plus an
empty-status case, and paste a fresh negative-control transcript in the PR body
showing at least COMPLETE and MEASURED failing with exit 1.

That can ride with the integration increment or land as its own commit on PR #3,
your choice — but it must be in before any M1 signoff.

You may now start the separate integration increment, exactly as you scoped it:
bodies and links integrated under the fixed 1/60 step from tuning, gravity from
tuning, deterministic ordering, and the outer accumulator with GDD §4.2 catch-up
cap. No contacts, no radii, no presets, no baseline, no AC-201/202/204 claims, no
tick-cost claim. Keep every runtime row NOT RUN. M1-B01 is still mine to supply;
do not invent radii, head mass/length or grip thresholds. Do not start M2 or
camera work.
```

---

*End of R5 review. F7/F12/F13/F14 closed; F15 open as a MAJOR guard hardening; M1 runtime gates remain NOT RUN.*
