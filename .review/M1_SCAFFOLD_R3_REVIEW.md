# M1 scaffold — R3 review of PR #3 + full review-pack handoff

**Reviewed:** 2026-10-28  
**PR #3:** `arena/4cd0a587-clamber` @ `2358c8364ac84566918b77093ee2afa1c18f28fe` → `main`, **draft**, all six checks SUCCESS.  
**Reviewer session branch:** `arena/5b72e4ab-clamber` @ `9a9350c` (independent scaffold implementation + byte-identical full review pack; CI green: `review-scaffold`, `headless` pass, `android` running at time of writing).  
**Prior state:** M0 merged as `c641990`, owner override `M0-D07`; PR #2 is the stale scaffold from the merged branch.

---

## 1. Verdict on the scaffold fix

| Item | Verdict | Evidence |
|---|---|---|
| **F1** `scripts/review_checks.sh` | **DONE** | `scripts/review_checks.sh` (executable, `set -euo pipefail`) runs `review_static.py`, `test_review_checks.py`, `test_static.py`, `test_android_inspection.py`; I ran it on the PR tree → **exit 0**. Wired into a dedicated CI job. |
| **F2** full external pack vendored | **STILL OPEN — now unblocked** | `docs/CLAMBER_REVIEW_AGENT.md` on PR #3 is **46 lines** and its header states the full pack was *not* provided. The complete pack is now supplied (see §2). |
| **F3** matrix reconciliation | **DONE** | `.review/m1_ac_matrix.md` (96 lines) adds full INV-01…INV-10 row, A5.6/A10 five-fakes, A12 verdict row, A9.1–A9.7 rows including both frame conditions, 475 engine + 488 combined floors, and every runtime row is `NOT RUN`. |
| **F4** M1 CI separate from M0 regression | **DONE** | New `.github/workflows/m1.yml` named *“M1 review scaffold (not runtime acceptance)”*, job *“M1 invariant/static subset (NOT replay or soak)”*, plus M0 workflow renamed to **M0 regression gates**. |
| **F5** `upload-artifact@v4` warning | **DONE** | Bumped to `@v5`; tag verified via API: `refs/tags/v5` → `330a01c490aca151604b8cf639adc76d48f6c5d4`. |

Additional good work I verified:

- `scripts/check_m0_regression.py` enforces `engine >= 475` **and** `engine + python >= 488` **and** `python >= 13`, rejects multiple/missing completion markers, and runs only after a successful headless step. `tests/test_review_checks.py` proves the floors are falsifiable (`M0: 474` with 100 python tests still fails).
- `scripts/review_static.py` scans `core/`, `ui/`, `platform/`, `tests/` recursively, checks `.tscn` node types as well as `.gd`, strips strings/comments (including triple-quoted) before matching, bans `randf/randfn/randi/randomize/seed/randf_range/randi_range`, `RandomNumberGenerator`, `Time.get_ticks_*`, `Engine.get_physics_frames`, `_process`/`_physics_process`/`delta`, and the transcendental set; also checks the 4.7.2 pin and the single-Autoload rule.
- PR #3 CI: `headless` ×2, `android` ×2, `M1 invariant/static subset` ×2 → all **SUCCESS**. Correctly described as M0 regression + static subset, not M1 runtime evidence.
- No solver, preset, tuning, save or M0-test change is in the scaffold commit. `M1-D01` honestly refuses to invent radii, head mass/length, or grip threshold.

---

## 2. Full review pack — supplied, byte-identical

The complete attached pack is committed verbatim on the reviewer branch:

```text
branch:  arena/5b72e4ab-clamber
path:    docs/CLAMBER_REVIEW_AGENT.md
lines:   379
bytes:   23451
sha256:  e3bd06654e0f92aaca55d0cc85e79f6d589a45aa6d9ddab5f4f068db22edb9a1
```

Structure it actually contains (not an excerpt):

- **PART A** — A1 Role, A2 Authority, A3 Inputs, A4 Verification doctrine (E1–E4), A5 the six mandatory review steps, A6 severity/pass rule, A7 review order (incl. A7.1 AC matrix mandatory), A8 regression gate, **A9 determinism deep-check (7 points)**, **A10 the five fakes** (hollow test, ticked box, weakened gate, stub that passes, borrowed artifact), A11 round protocol R1–R4, A12 output format (`m<N>_verdict.md` / `.json` + PR review + ESCALATE), A13 tone.
- **PART B** — invariant sweep **INV-01…INV-10** with evidence class and severity, then M0…M7 checklists. M1 checklist: AC-201, AC-202, AC-204 + soak log, full A9 incl. bit-flip, three presets with 10 s captures, tick ≤ 3.0 ms at 30 bodies, no Godot physics nodes.
- **PART C** first prompt for the reviewer, **PART D** GitHub wiring, **PART E** the three failure modes.

The review does **not** need the pack re-transcribed into the matrix; it needs the pack present so citations like `A9.5`, `A10`, `INV-07`, `A12.1` resolve to shared text.

---

## 3. Remaining findings for PR #3

### F7 — [BLOCKER for M1 readiness] The vendored pack is still the 46-line partial file
- **Citation:** `git show origin/arena/4cd0a587-clamber:docs/CLAMBER_REVIEW_AGENT.md` → 46 lines, header “The full external review pack has NOT been provided or vendored.”
- **Violates:** `docs/CLAMBER_REVIEW_AGENT.md` A5.5/A7.1 traceability and A12.1 verdict artifacts (they must cite a shared normative source); `DECISIONS.md` M1-B02.
- **Done when:** `sha256sum docs/CLAMBER_REVIEW_AGENT.md` prints `e3bd06654e0f92aaca55d0cc85e79f6d589a45aa6d9ddab5f4f068db22edb9a1` and the file is 379 lines, with the “PARTIAL SOURCE ONLY” header replaced by a provenance line (source: owner-supplied pack, 2026-10-28, byte-identical, unmodified).

### F8 — [MAJOR] Review checks cannot catch a ticked gate
- **Citation:** `scripts/review_static.py` validates code invariants only; `scripts/check_m0_regression.py` validates log counts. Neither reads `.review/m1_ac_matrix.md`.
- **Risk:** A10 “ticked box” — a future commit can mark `AC-201 … | PASS |` in the matrix with no evidence and CI stays green.
- **Done when:** `review_checks.sh` fails if a gate row contains `Met/PASS/PASSED/VERIFIED` while its evidence column is empty or `None`, and if fewer than 12 rows remain `NOT RUN` during the scaffold phase. Prove it with a negative-control run in the PR body (temporarily set one row to `Met`, show exit 1, revert). Reference implementation: `scripts/review_checks.sh` on `arena/5b72e4ab-clamber` (it does this and I verified the failure mode locally).

### F9 — [MINOR] Post-vendoring text must not keep saying “pack absent”
- **Citation:** `DECISIONS.md` **M1-D01** (“`docs/CLAMBER_REVIEW_AGENT.md` is explicitly a partial transcription”), **M1-B02** (“supply full external review pack”), and matrix rows `PARTIAL / full mapping BLOCKED`, `BLOCKED / NOT RUN` for five fakes.
- **Done when:** those statements become “pack vendored at sha256 e3bd0665…; INV/five-fakes/A12 now resolvable”, `M1-B02` is marked resolved, and the matrix keeps the runtime gates `NOT RUN`. Do not convert a supplied document into a passed gate.

### F10 — [MINOR] M0 check names still show the old workflow title on PR #3
- **Citation:** PR #3 `statusCheckRollup` lists `workflowName: M0 headless gates` for the two M0 runs; the rename to `M0 regression gates` lands on the next push.
- Non-blocking; it resolves itself with the next commit.

### F11 — [NIT] Pin the artifact action by SHA
- `actions/upload-artifact@v5` is a moving major tag. Optional: pin `330a01c490aca151604b8cf639adc76d48f6c5d4`.

---

## 4. What is still NOT done (unchanged)

- No solver, no presets, no baseline hash, no replay/bit-flip/stall/frame-condition run, no soak, no tick measurement, no captures. All M1 runtime rows remain `NOT RUN`, correctly.
- `M1-B01` (per-part radii incl. head, head mass/length treatment, foot normal-force grip threshold) is still an owner-supplied-inputs blocker. Do not invent them.
- `M0-B02` camera zoom stays an M2 question.
- M0 is closed by owner override only; nothing here reopens or re-approves M0.

---

## 5. Paste-ready message to the coding agent

```text
R3 review of PR #3 (2358c83): scaffold fix is DONE for F1, F3, F4 and F5. I
verified all six checks SUCCESS, ran scripts/review_checks.sh on your tree (exit
0), read review_static.py / check_m0_regression.py / test_review_checks.py, and
confirmed the 475 engine + 13 python = 488 floors are falsifiable (M0: 474 with
100 python tests still fails). Upload-artifact v5 exists; tag
330a01c490aca151604b8cf639adc76d48f6c5d4 confirmed. Do not redo any of that.

F2 is the only blocker left, and it is now unblocked: the complete external review
pack is supplied. Copy it byte-identically from the reviewer branch instead of
retyping it:

  git fetch origin arena/5b72e4ab-clamber
  git show origin/arena/5b72e4ab-clamber:docs/CLAMBER_REVIEW_AGENT.md \
    > docs/CLAMBER_REVIEW_AGENT.md
  sha256sum docs/CLAMBER_REVIEW_AGENT.md
  # must print e3bd06654e0f92aaca55d0cc85e79f6d589a45aa6d9ddab5f4f068db22edb9a1
  wc -l docs/CLAMBER_REVIEW_AGENT.md   # must print 379

Do not summarise, reorder or "improve" it. It must stay verbatim so citations such
as A9.5, A10, INV-07 and A12.1 resolve to shared text.

Same scaffold-fix commit (docs + scripts only, no solver, no presets, no tuning,
no save changes, every runtime gate still NOT RUN):

F7 [BLOCKER] Replace the 46-line partial file with the verbatim 379-line pack.
Change its header from "PARTIAL SOURCE ONLY / NOT provided" to a provenance line:
owner-supplied 2026-10-28, byte-identical, sha256 e3bd0665..., unmodified.

F8 [MAJOR] Make the matrix tick-proof. Extend scripts/review_checks.sh so it fails
if any gate row contains Met/PASS/PASSED/VERIFIED while its evidence column is
empty or None, or if fewer than 12 rows are NOT RUN during the scaffold phase.
Include a negative-control run in the PR body: temporarily set one row to Met,
show exit 1, revert, show exit 0. Reference implementation already exists in
scripts/review_checks.sh on arena/5b72e4ab-clamber — port the logic, keep your
better structure.

F9 [MINOR] After vendoring, update DECISIONS.md M1-D01 and M1-B02 and the matrix
rows that say "partial / pack absent / BLOCKED" so they read "pack vendored at
sha256 e3bd0665...; INV and A10 five-fakes and A12 now resolvable". Resolve M1-B02.
Keep every runtime gate NOT RUN; a supplied document is not a passed gate.

F10 [MINOR] The M0 check names on PR #3 still show "M0 headless gates"; they will
update on the next push after your rename. No action needed beyond confirming it.

F11 [NIT] Optional: pin actions/upload-artifact to
330a01c490aca151604b8cf639adc76d48f6c5d4 instead of the v5 tag.

Then: re-run scripts/review_checks.sh, paste the full output in the PR body, push,
and get all CI green. Only after that start M1 increment 1 (mathematical
body/link/constraint state + three preset fixtures), and keep M1-B01 unresolved
until I supply radii, head mass/length and the grip threshold. Do not start M2 or
camera work; M0-B02 zoom stays mine to decide.

Report: new commit SHA, sha256/wc of the vendored pack, review_checks.sh output,
the F8 negative-control transcript, and CI run link. Do not claim any M1 runtime
gate has passed.
```

---

*End of R3 scaffold review. M0 stays closed by owner override; M1 stays scaffold-only until F7–F9 land and increment 1 exists.*
