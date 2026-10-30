# M1 — merge-to-main and local-run prompt (owner will download a ZIP and run it on their machine)

**Prepared by the reviewer, 2026-10-30.** Ready to paste to the coding agent as one session.
**Two warnings first — both verified by me, both would cost the owner a wasted download.**

---

## WARNING 1 — merge **only** the agent branch. Do **not** merge the reviewer branch.

| | |
|---|---|
| `origin/main` | `c641990` |
| `origin/arena/4cd0a587-clamber` | `0c1d3f8` |
| merge-base | **`c641990`** → main is a **direct ancestor** ⇒ **fast-forward, zero conflicts, zero content change** |

The reviewer branch `arena/5b72e4ab-clamber` is **older** than the agent branch and **does not contain**:

```
.github/workflows/m1.yml          (1420 lines, exists only on the agent branch)
.github/workflows/r29.yml
.review/m1_r17_phase1_evidence.json … .review/m1_r29_measurement_evidence.json  (15+ evidence files)
tests/…  (the whole R28/R29 harness)
```

Merging it into main **would delete the measurement workflow and the evidence** — 248 paths differ between
the two branches. My review documents are **not** needed to run the game or the arms; they live on the
reviewer branch and stay there.

---

## WARNING 2 — a ZIP has **no `.git`**, and the local runner depends on git

Verified in the agent branch at `0c1d3f8`:

| file | git dependency | effect on a ZIP |
|---|---|---|
| `tests/run_m1_r29.sh` | `git rev-parse HEAD`, `git diff 4796ec6 -- core/` | **fails immediately** |
| `tests/test_r29.py` | `git diff 4796ec6 -- core/` | control fails |
| `tests/run_m1_r28.sh`, `run_m1_r24.sh`, `run_m1_inert.sh` | `git diff` guards | fail |
| `tests/r29_publish.py` | `git config`, commits | fails |

So **"download ZIP → run arms" does not work today**, and that is a real, fixable gap. Either the agent adds a
ZIP-safe local mode (below), or the owner does `git clone` instead of downloading a ZIP — a clone behaves
identically and needs no changes.

---

# PROMPT — paste to the coding agent

> **Task: merge the agent branch to `main` and make the repo runnable from a plain ZIP on the owner's
> machine. No physics changes. M1 is NOT being signed by this merge.**
>
> ### 1. Merge (fast-forward only)
> - Confirm `git merge-base origin/main origin/arena/4cd0a587-clamber` is `c641990` — main is a direct
>   ancestor, so this must be a **fast-forward**.
> - Merge `arena/4cd0a587-clamber` into `main`. If git ever reports a **conflict** or a non-FF merge,
>   **stop and report** — that changes the picture and needs review.
> - **Proof of no content change:** after the merge,
>   `git diff 0c1d3f8 origin/main --stat` must be **empty**, and
>   `git ls-tree -r 0c1d3f8` must equal `git ls-tree -r origin/main`.
>   Record both commands and their (empty) output in the commit body.
> - Merge commit message: `merge: M1 solver foundations and measured gates (M1 BLOCKED, not signed)`.
> - **Do NOT merge `arena/5b72e4ab-clamber`.** It predates the M1 workflow and the R28/R29 evidence; merging
>   it would delete `.github/workflows/m1.yml`, `.github/workflows/r29.yml` and 15+ `.review/*evidence.json`
>   files. State in the report that you did not merge it and why.
> - Tag the result for reproducible downloads: **`m1-blocked-2026-10-30`** (annotated) pointing at `main`.
>   Do not move or reuse any existing tag.
>
> ### 2. Record what the merge is and is not
> In `PROGRESS.md` and `DECISIONS.md`, one short block:
> - `main` now carries the M1 code **for local execution**.
> - **M1 is BLOCKED and NOT SIGNED**: `AC-201` FAILED, `AC-202` FAILED (adoption reverted; control sits at
>   `physics_contact_slop_wu = 0.02`, adoption reached 2.5–4.7× it), `FA-3` uncredited, and **five runtime
>   gates NOT RUN** (presets+captures, tick cost §10.4, §10.6 step 1, FA-4, FA-6) because CI is blocked by
>   account billing (compute $12.13/$12.00, storage 0.5/0.5 GB, resets in 2 days).
> - **M2 remains blocked.** A merge is not a verdict and must never be cited as one.
>
> ### 3. Make the measurement path work without `.git` (ZIP-safe)
> Add a **local mode** that changes **no physics, no thresholds, no assertions**:
> - `tests/run_m1_r29.sh` and the other `run_m1_r*.sh` guard scripts: when **`CLAMBER_LOCAL=1`** is set,
>   skip the `git rev-parse` / `git diff` provenance checks and instead verify provenance from a **committed
>   manifest** — add `tests/fixtures/source_manifest.json` containing at least:
>   `{source_commit: "0c1d3f8…", tuning_sha256: "5f4d0d06…", core_tree_sha256: "<sha256 over a sorted
>   core file list + contents>"}`. The local mode recomputes `core_tree_sha256` and `tuning_sha256` and
>   **fails if either differs** — so a ZIP run still proves it is measuring the right code.
> - `tests/test_r29.py`: replace `git diff 4796ec6 -- core/` with the same manifest comparison when
>   `.git` is absent, and keep the git path when it is present.
> - CI behaviour must be **unchanged** (`CLAMBER_LOCAL` unset ⇒ identical checks to today).
> - Prove it: run the whole suite **twice** in a scratch copy of a ZIP-style export (no `.git`) and show
>   the controls pass and the arms reach the point of starting.
>
> ### 4. `LOCAL_RUN.md` at the repo root — the owner's checklist
> Must contain, copy-pasteable, with no assumed knowledge:
> 1. Install **Godot 4.7.2-stable** (exact build string `4.7.2.stable.official.ed1daf0bf`); verify against
>    the release's `SHA512-SUMS.txt`.
> 2. Unzip the `m1-blocked-2026-10-30` archive anywhere; `cd` into it.
> 3. `export GODOT=/path/to/Godot_v4.7.2-stable_linux.x86_64` (and the Windows equivalent).
> 4. `export CLAMBER_LOCAL=1`.
> 5. `bash scripts/review_checks.sh` → expect **232 controls, 0 failures**.
> 6. `bash tests/run_m1_r29.sh D1` … `D5`, **once each, in order**; each writes under
>    `tests/fixtures/m1_r29_execution/`.
> 7. What to send back: the whole `tests/fixtures/m1_r29_execution/` folder **plus** `import.log`,
>    `compile.log` and the engine build string.
> 8. Troubleshooting: the `_checked` parse error is fixed (helper is `_checked_step`); if the engine refuses
>    to import, delete `.godot/` and retry; if a script reports a missing `git`, `CLAMBER_LOCAL=1` was not set.
> 9. A one-line honest warning: **the local run is owner-attested evidence, not CI evidence**, and D2's
>    reference-device leg still requires the physical device (D07).
>
> ### 5. Do not
> - Do not rerun D0. Do not adopt or retry AC-202. Do not change tuning, slop, tolerances, iterations.
> - Do not start P3 or write any M1 verdict.
> - Do not delete artifacts or touch billing.
> - Do not present `CLAMBER_LOCAL` as a weakening of CI: if the manifest check cannot be made equivalent to
>   the git check, **stop and report** rather than shipping a looser local path.

---

## What the owner gets after this

- `main` at the merge commit, tagged `m1-blocked-2026-10-30`, downloadable as a ZIP that **runs**.
- Five measurement arms executable on the owner's own machine with no GitHub minutes.
- The record still says **M1 BLOCKED, not signed** — which is the truth today, and stays true until the five
  gates produce numbers.
