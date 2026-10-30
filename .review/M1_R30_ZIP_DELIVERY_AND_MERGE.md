# M1 — R30: ZIP delivery verified, equality-proof conflict resolved, main advanced

**Reviewer:** `arena/5b72e4ab-clamber`. **Verified head:** agent branch **`0bf73c9`**. **Date:** 2026-10-30.

---

## 1. I reproduced the agent's ZIP claim myself, in a no-`.git` export

```
git archive origin/arena/4cd0a587-clamber | tar -x -C /tmp/zip1     # no .git directory
CLAMBER_LOCAL=1 bash scripts/review_checks.sh
→ 232 controls, 0 failures, exit 0
```

Then a **tamper test**, which is the only thing that proves the manifest path is not a loophole:

```
printf '\n# tamper\n' >> core/sim/solver.gd
CLAMBER_LOCAL=1 bash scripts/review_checks.sh
→ exit 1, provenance verifier fails (tests/source_provenance.py:40)
```

**The ZIP path is hash-pinned, not merely git-free.** One appended line in one core file is caught. The
manifest is `{source_commit: 0c1d3f8…, tuning_sha256: 5f4d0d06…, core_tree_sha256: 55752020…}`, verified
**before** any engine invocation or evidence write.

Also verified in that export:

| check | result |
|---|---|
| `git diff 4796ec6 0bf73c9 -- core/` | **empty** |
| `core/tuning.tres` sha256 | `5f4d0d06…0666` — unchanged |
| arms are once-only and ordered | `r29_local.py` refuses a repeated arm, a skipped arm, and any arm after `stopped` |
| lock prevents two terminals | exclusive `.local-run.lock`, never auto-recovered |
| engine build is exact | `4.7.2.stable.official.ed1daf0bf` or it refuses |
| local evidence cannot inherit CI identity | `GITHUB_RUN_ID` **popped** from env |
| failure semantics | records the arm **before** import, so a crash cannot be silently retried |
| no shipped test double | the double the agent used was an external stub binary; **nothing in the repo** can fabricate an arm |

**One blocker the agent reported is not a defect in its work:** it could not download Godot
(`objects.githubusercontent.com` blocked in its sandbox, same as mine). So the arms remain `NOT RUN` for a
reason that is external, and the agent correctly labelled the routing proof as routing only.

---

## 2. The "content-proof conflict" — resolved, and the agent was right to flag it

I wrote a proof that is impossible as literally worded: *"after the merge, `git diff 0c1d3f8 origin/main` must
be empty"* **and** *"add ZIP packaging"*. Both cannot hold — packaging changes the tree.

**Corrected proof, split into the two facts that actually matter:**

1. **Fast-forward integrity** — `main` (`c641990`) is a direct ancestor of `0c1d3f8`, so advancing main to
   `0c1d3f8` is a **content-free** move. This is what "no content change" was meant to capture.
2. **Declared delta** — `0bf73c9` vs `0c1d3f8` differs **only** in packaging: `LOCAL_RUN.md`,
   `tests/r29_local.py`, `tests/source_provenance.py`, `tests/test_zip_provenance.py`,
   `tests/fixtures/source_manifest.json`, docs. Verified: **`core/` empty, tuning sha identical.**
3. **What the merge does not touch** — no physics, no threshold, no preset, no save format, no baseline
   expectation, no workflow pin.

So the merge is accepted on that basis, and my original wording is withdrawn as badly specified — **my 20th
error, and it cost the agent a round trip.**

---

## 3. Merge executed

The agent could only write to its own branch and I am scoped to the reviewer branch, but the merge is a
**PR operation** on the owner's account, and the owner asked for it directly:

- PR **#3** → marked **ready for review** → **merged into `main`** with a merge commit.
- Resulting `main` tree is content-identical to `0bf73c9`.
- Annotated tag **`m1-blocked-2026-10-30`** published, so the ZIP download is reproducible.
- `arena/5b72e4ab-clamber` was **not** merged (it predates `m1.yml`, `r29.yml` and 15+ evidence files).

**What the merge means:** the M1 code is on `main` and downloadable.
**What it does not mean:** M1 is **not signed**. `AC-201` FAILED, `AC-202` FAILED, `FA-3` uncredited, and five
runtime gates remain `NOT RUN` until the owner's local run produces numbers. **M2 stays blocked.**

---

## 4. What the owner now does — the short version

1. Download the ZIP of tag **`m1-blocked-2026-10-30`** (or of `main`).
2. Follow **`LOCAL_RUN.md`** — it is written for someone who has never used Godot: verify the engine against
   `SHA512-SUMS.txt`, exact build `4.7.2.stable.official.ed1daf0bf`, `export GODOT=…`, `export CLAMBER_LOCAL=1`.
3. `bash scripts/review_checks.sh` → expect **232 / 0**.
4. `bash tests/run_m1_r29.sh D1`, then D2, D3, D4, D5 — **once each, in order**. The runner enforces it.
5. Send back `tests/fixtures/m1_r29_execution/` (including `import.log`, `compile.log`, `engine-build.txt`).

Then I verify the numbers and finish **P3**: the 18-row verdict from the frozen ledger in
`.review/M1_R29D_INFRA_FREEZE_AND_LEDGER.md` §3 — **10 PASS, 2 FAILED, 1 STATIC, 5 pending.**
