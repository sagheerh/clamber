# M0 closeout + M1 scaffold — independent verification (R3)

**Reviewed:** 2026-10-28  
**Current session branch after sync:** `arena/5b72e4ab-clamber` fast-forwarded to `a486868` (M0 merge `c641990` + M1 scaffold).  
**Remote state:** `origin/main = c641990` (M0 merged), PR #2 head = `a486868` (draft).  
**Inputs:** pasted session report, GitHub API/PR data, commit diffs, attached `CLAMBER_REVIEW_AGENT.md`, `docs/GDD.md`.

---

## 1. Verdict

- **M0 closeout: VERIFIED.** PR #1 is merged as `c641990`, all four checks green, closeout commit `5c6cbbb` is documentation-only, M0-D07 is honest about the owner override, and evidence links are corrected.
- **M1 scaffold: VERIFIED AS SCAFFOLD ONLY — NOT APPROVED.** PR #2 is a separate draft commit after M0 landed; `.review/m1_ac_matrix.md` exists and every runtime gate is `NOT RUN`. No solver, presets, baseline, capture, or M1 test exists.
- **Overall:** the coding agent did what was asked for the closeout boundary. Before M1 implementation starts, the scaffold needs a small **review-infrastructure reconciliation** so M1 does not inherit M0's waived artifacts.

---

## 2. Evidence I ran

```text
git fetch origin
git merge --ff-only origin/arena/f08ed236-clamber   # local branch now a486868

gh pr view 1 -> MERGED, mergeCommit c641990, base main, head 5c6cbbb,
                headless + android checks SUCCESS
gh pr view 2 -> OPEN, isDraft true, head a486868, base main,
                headless SUCCESS, android SUCCESS (M0 regression only)
gh run view 40629356697 -> main merge run SUCCESS (headless + android)

git show --stat 5c6cbbb
  DECISIONS.md | 36 +--
  PROGRESS.md  | 34 +--
  README.md    | 11 +--
  docs/validation/M0.md | 81 +--
  4 files changed

git diff ba7179b 5c6cbbb -- core tests .github project.godot export_presets.cfg ui platform
  (empty)

git show --stat a486868
  .review/m1_ac_matrix.md | 76 ++++
  PROGRESS.md             | 14 ++++
  2 files changed

git rev-parse a486868^ -> c641990   # M1 scaffold is after M0 merge

python3 tests/test_static.py            -> 6 tests OK
python3 tests/test_android_inspection.py -> 7 tests OK
```

`PR #1` body records `APPROVE — HUMAN OVERRIDE`. `PR #2` body records `SCAFFOLD ONLY — M1 GATES NOT MET`. `reviewDecision` is empty on both, which is fine for an owner override / draft, but M1 signoff will need a formal PR review per A12.

---

## 3. Verified good — do not redo

- `M0-D07` correctly says: owner verbal verification, **not E4 evidence**, no screenshot/adb/device identity/lifecycle/frame-time capture, no artifact-to-device chain of custody, 60 fps/P95 **not measured**, waivers **M0 only**.
- `docs/validation/M0.md` now points to final run `40625642314`, artifact `12789073777`, digest `sha256:a45fbe...`, expiry `2026-11-04`.
- `PROGRESS.md` says `M0 — APPROVED / COMPLETE (owner override); M1 — READY` and separately logs the M1 kickoff.
- Closeout changed **no** runtime, tuning, save, test, project, export, UI, or platform code.
- M1 scaffold parent is the M0 merge commit, satisfying "only after M0 lands".
- M1 matrix already includes AC-201, AC-202, AC-204, three presets + 10 s captures, tick ≤ 3.0 ms, A9 replay ×3, 2 s stall, two frame conditions, mandatory one-bit falsification, committed baseline + CI regression, and §10.6 repeatability. All are `NOT RUN`.
- M1 matrix explicitly keeps M0-B02 zoom and M0-B03 unspecified thresholds unresolved and refuses to fabricate them.
- PR #2 CI passing is correctly treated as M0 regression, not M1 proof.

---

## 4. Gaps to fix in PR #2 before M1 implementation

These are **MAJOR for M1 readiness**, not M0 blockers. They exist because M0-D07 waived review-pack artifacts for M0 only.

### F1 — [MAJOR] `scripts/review_checks.sh` is still missing
- **Citation:** `git ls-tree -r c641990 | grep '^scripts/'` → empty; `git ls-tree -r a486868 | grep '^scripts/'` → empty. M0-D07 explicitly waived it for M0 only.
- **Violates:** `CLAMBER_REVIEW_AGENT.md:67` (A5.1), PART B M0 `:245`, and the M1 review will require it.
- **Done when:** add `scripts/review_checks.sh` that runs the invariant/static checks and exits 0; wire it into CI; paste its output in the M1 PR.

### F2 — [MAJOR] Full external PART B / A9 text is not in the checkout
- **Citation:** PR #2 body and `.review/m1_ac_matrix.md` both say the standalone review-pack text is not present and must be reconciled before signoff.
- **Why it matters:** I have the attached `CLAMBER_REVIEW_AGENT.md`; the M1 matrix captures most of it, but not all. Vendor the full file into the repo (e.g. `docs/CLAMBER_REVIEW_AGENT.md`) so the reviewer and CI share one normative copy.
- **Specific clauses to add to `scripts/review_checks.sh` + `.review/m1_ac_matrix.md`:**
  - A9.1 static scan: `core/sim`, `core/run`, `core/tower` must contain no `randf`, `randi`, `randomize`, `Time.get_ticks_*`, `Engine.get_physics_frames` used as input, `_process(delta)` stepping, or unseeded global RNG.
  - A9.2 fixed `1.0/60.0` via accumulator, never raw frame delta.
  - A9.3 RNG injected; seed is a parameter of `Sim.setup(...)`.
  - A9.4 replay ≥3 times in one session, compare hashes; repeat after a deliberate 2 s stall.
  - A9.5 two frame conditions, e.g. `--fixed-fps 30` and `--fixed-fps 144` if supported, otherwise windowed vs headless; record the exact protocol.
  - A9.6 transcendental ban: no `sin/cos/tan/pow/exp/atan2` inside solver integration/constraint functions.
  - A9.7 committed baseline + test that **fails loudly** when one documented input bit is flipped; hash must differ.
  - A8 regression: M1+ determinism replay must match the recorded baseline hash; **test count must not decrease** without a `DECISIONS.md` justification. M0 baseline = 475 engine + 6 static + 7 inspector = 488 checks.
  - Every-milestone invariant sweep INV-01…INV-10, not just INV-01.
  - A5.6 hunt for the five fakes; A12 `.review/m1_verdict.md` / `.json` + formal PR review before M1 signoff.

### F3 — [MAJOR] M1 matrix needs an explicit invariant + regression row
- **Citation:** current `.review/m1_ac_matrix.md` has an "Engine / architecture" row but no explicit INV-01…INV-10 sweep or test-count baseline.
- **Done when:** add rows for the full invariant sweep, M0 regression suite (475 checks), and test-count non-regression (488 baseline), all `NOT RUN` until M1 CI exists.

### F4 — [MINOR] CI workflow name/jobs are still M0-only
- **Citation:** `.github/workflows/m0.yml` is named `M0 headless gates`; PR #2's green checks are M0 regression only.
- **Done when:** add an M1-specific workflow/job (or rename to `CI` with separate M0 regression + M1 harness jobs) that will run replay, soak, performance, and preset captures with the pinned 4.7.2 engine. Keep the M0 job as regression.

### F5 — [NIT] `actions/upload-artifact@v4` Node.js 20 deprecation warning
- Non-blocking. Update when convenient.

---

## 5. Human decisions still open

1. **M0-B02 camera zoom:** `0.75` (GDD §2.3) vs `0.72` (§4.8). Needed before M2/camera work; M1 does not use it.
2. **M0-B03 thresholds:** grip normal-force, landing haptic impulse, generator salt/weights/heights. Do not invent; obtain from owner when those milestones are assigned.
3. **M1 reference hardware:** tick ≤ 3.0 ms and later device/frame-time gates need named hardware/method. M0-D07 cannot waive these.

---

## 6. Paste-ready message to the coding agent

```text
R3 review: M0 closeout is VERIFIED and PR #1/c641990 stays merged. M0-D07,
corrected evidence links, PROGRESS.md, and docs/validation/M0.md are accurate.
I confirmed the closeout diff changed only DECISIONS.md, PROGRESS.md, README.md,
and docs/validation/M0.md — no runtime, tuning, save, test, project, export, UI
or platform code. M1 scaffold PR #2 (a486868) is correctly separate, after the
M0 merge, and every M1 gate is NOT RUN. Good boundary; do not redo M0.

Before starting M1 implementation, make ONE small scaffold-fix commit on PR #2.
Do not implement the solver yet in that commit.

F1 [MAJOR] Add `scripts/review_checks.sh` and wire it into CI. M0-D07 waived this
script for M0 ONLY; M1 review requires it. It must run the invariant/static scans
and exit 0. Paste its output in the PR.

F2 [MAJOR] Vendor the full external review pack into the repository as
`docs/CLAMBER_REVIEW_AGENT.md` (the complete PART B / A9 / invariant text). Then
reconcile `.review/m1_ac_matrix.md` against it explicitly:
- A9.1 static scan: no randf/randi/randomize, Time.get_ticks_*,
  Engine.get_physics_frames as input, _process(delta) stepping, or unseeded
  global RNG in core/sim, core/run, core/tower.
- A9.2 fixed 1/60 accumulator, no raw frame delta.
- A9.3 injected RNG: seed is a Sim.setup parameter.
- A9.4 replay >=3 times + one 2-second stall, hashes compared at equal tick counts.
- A9.5 two frame conditions (--fixed-fps 30 / --fixed-fps 144 if supported,
  else windowed vs headless); record the exact protocol.
- A9.6 no sin/cos/tan/pow/exp/atan2 in solver step/constraint functions.
- A9.7 committed baseline + one-bit input falsification that FAILS if the hash
  is unchanged.
- A8 regression: M1+ replay matches baseline; test count must not drop below the
  M0 baseline of 488 checks without a DECISIONS.md justification.
- Full INV-01..INV-10 sweep every milestone.
- A5.6 five-fakes check and A12 .review/m1_verdict.md/.json + formal PR review
  before M1 signoff.

F3 [MAJOR] Add explicit matrix rows for the full invariant sweep, M0 regression
suite (475 engine checks), and test-count non-regression (488 baseline). Keep all
M1 runtime rows NOT RUN.

F4 [MINOR] Add an M1-specific CI workflow/job (or split the current
`M0 headless gates` workflow into M0 regression + M1 harness jobs). PR #2's
current green checks are only M0 regression; they are not M1 determinism,
soak, performance or capture evidence.

F5 [NIT] Update actions/upload-artifact@v4 when convenient.

After that scaffold-fix commit is pushed and CI is green, start M1 increment 1:
minimal mathematical body/constraint state + three preset fixtures, preserving
the public Sim interface and all tuning values. Do NOT invent M0-B03 grip/
haptic/generator thresholds. Do NOT start M2/S03/camera work; M0-B02 zoom
(0.75 vs 0.72) still needs my decision before M2.

Keep PR #2 as a draft until at least increment 1 exists. Report the new commit,
PR link, review_checks.sh output, and CI run. Do not claim any M1 gate has passed
until the real pinned-engine replay/soak/performance harness runs.
```

---

*End of R3 verification. M0 is closed by owner override; M1 is a scaffold, not a completed milestone.*
