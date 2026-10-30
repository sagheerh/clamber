# M1 — R31b: runner proven on the public repo. Prompt: re-pin, prove, measure, then reach the fix loop

**Reviewer:** `arena/5b72e4ab-clamber`. **Owner action:** repo made public (2026-10-30).

---

## 1. The runner works — verified with a real push, not a promise

My docs push `e744dd9` produced run **`41004321981`**:

| job | steps executed | result |
|---|---:|---|
| `review-scaffold` | **6** | **success** |
| `headless` | **6** | **success** — annotation: *"M0: 475 checks, 0 failures"* (the reviewer branch's older M0 workflow; `main` runs 516) |
| `android` | 9 | still running (template install is slow) |

Compare with every run since `02:41Z`, which had **`steps=0`**. **The billing block is gone.** Public repo ⇒
standard `ubuntu-latest` runners are **free and unmetered**.

**Not yet proven:** artifact uploads. The storage meter (0.5 GB / 0.5 GB) is a separate line and may still
refuse uploads. **Assume it fails** and keep committing evidence into the repo, as the R29 tooling already does.

---

## 2. Why the arms still will not run, even now

| blocker | detail |
|---|---|
| **dead pins** | `r29.yml` jobs require `github.sha == github.event.after && contains(msg, '[R29-once-2]')` **and** literally `github.sha == 'bb88cd1…'`. A new push cannot satisfy a literal sha that no longer exists in the branch tip. |
| **dead proof pin** | the runner-proof job is pinned to `fe56aad` / `[R29-runner-proof]`. |
| **no local fix loop** | `tests/run_m1_r28.sh` — the arm that validates a **physics candidate** (limb error + penetration) — still calls `git rev-parse` / `git diff` and has **no `CLAMBER_LOCAL` path**. Only `run_m1_r29.sh` got the manifest treatment. |

---

# PROMPT — paste to the coding agent

> **Repo is now public: Actions minutes are free and unmetered. The runner is proven (`41004321981`,
> `headless` 0 failures). Do this in one session. No physics changes. M1 stays BLOCKED / NOT SIGNED.**
>
> ### 1. Re-pin and prove (workflow-only, no measurement)
> - Re-pin the R29 measurement jobs to **the head you are about to measure**, under a **new marker
>   `[R29-once-3]`**, keeping `github.sha == github.event.after` so only that exact push can fire them.
> - Keep **one execution per arm**. Leave every historical `[R1x–R28-*]` pin untouched and un-run.
> - Keep a **zero-physics proof job** in the same workflow, and state in the report whether it passed before
>   the arms started.
>
> ### 2. Give the fix-validation arm a `CLAMBER_LOCAL` path (this is the real gap)
> - `tests/run_m1_r28.sh` must work **without `.git`**, exactly like `run_m1_r29.sh`: when
>   **`CLAMBER_LOCAL=1`**, verify provenance from `tests/fixtures/source_manifest.json`
>   (`source_commit`, `tuning_sha256`, `core_tree_sha256`) instead of `git rev-parse` / `git diff`, and **fail
>   if either hash differs**.
> - Reuse `tests/source_provenance.py`; do **not** fork a second verifier.
> - CI behaviour unchanged when `CLAMBER_LOCAL` is unset.
> - Prove it: a no-`.git` export runs the arm's provenance check and reaches the launch boundary; a tampered
>   `core/` file is rejected. Same discipline as `0bf73c9`.
>
> ### 3. Run the five M1 arms, once each, in order
> `D1` … `D5` via `tests/run_m1_r29.sh`, exactly as ruled: D1 captures + plots + manifest committed ≤ 5 MB and
> distinctness by **pairwise trace hash and numbers** (no authored threshold) · D2 **Hopper alone as the real
> row**, ten independent Slugs as a labelled 30-capsule aggregate, optional 14-part test-only creature,
> **actual constraint count**, median + P95, `3.0 ms` **never** applied as pass/fail on a proxy,
> reference-device leg `NOT MEASURED (D07)` · D3 10 000 × 100 with all hashes logged, soak **not** re-presented
> as determinism · D4 settle/sleep/lurch in **WU, BL, px**, 1.00 BL left to the owner · D5 ten outcomes with
> **variance source NONE** stated plainly.
> - If an artifact upload fails, **commit the evidence**; never re-run an arm to regenerate it.
> - If an arm fails after executing ticks, record `NOT RUN` and stop.
>
> ### 4. Do not
> - No tuning, slop, tolerance, iteration or geometry change. `core/` diff must stay empty; tuning sha256 stays
>   `5f4d0d06…0666`.
> - No D0 rerun, no AC-202 adoption.
> - No P3 verdict, no "M1 complete", no claim that a green runner is a pass.
> - Report numbers, not narrative. A failing arm with a real number is a success for this session.

---

## 3. After the five arms succeed — the thing the owner actually wants next

The five arms close **M1's measurement record**; they do **not** fix the physics. The fix work is **M1.1**, and
it needs step 2 above to exist so candidates can be measured from a ZIP or from CI equally.

**M1.1 protocol (three candidates, one at a time)** — I will publish the full prompt once the arms land, but the
binding rules are already fixed:

1. **The defect**: `core/sim/capsule_contact.gd:158-165` moves each capsule **endpoint independently**, breaking
   link lengths (F76) and rectifying spring load into translation/rotation (F75). One cause behind AC-201a,
   AC-201s, AC-202 and FA-4.
2. **Reject rule, fixed in advance**: penetration after the candidate must stay **≤ `physics_contact_slop_wu`
   × (1 + 1e-9)**. **Any** excess ⇒ candidate rejected, no clamping, no slop change, no "bounded" workaround.
   This is the rule the first candidate failed (2.5–4.7×).
3. **Accept rule**: limb error ≤ 0.05 WU **and** penetration at slop **and** AC-201a ≤ 15° **and** AC-201s
   sleeps within 10 s — all four, on the same build, or it does not count.
4. **One candidate per round**, measured once, numbers published whichever way they fall.
5. If two candidates fail, **stop and report** — the honest conclusion would then be that this needs a solver
   change (contact + distance solved together), which is an owner decision, not an agent one.

---

## 4. Owner housekeeping

- **Flip the repo back to private** once the M1 arms and the M1.1 candidates are measured — public exposure of
  the game, history and every log is the price of free minutes.
- Still open: **D07** reference-device tick cost, **FA-4's 1.00 BL** spec-vs-scale, **§10.4's 30/120**
  spec-vs-scale, **M1.1 scope** sign-off.
