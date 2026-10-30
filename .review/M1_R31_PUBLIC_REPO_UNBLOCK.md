# M1 — R31: repo is PUBLIC, billing block is gone, runner proof fires

**Date:** 2026-10-30. **Owner action:** repository made **temporarily public**.

---

## 1. Verified

```
gh api repos/sagheerh/clamber
→ { "visibility": "public", "private": false, "disabled": false, "archived": false }
```

| workflow | state |
|---|---|
| M0 regression gates | **active** |
| M1 independent foundations | **active** |
| R29 zero-physics measurements | **active** |

**Why this unblocks everything:** GitHub charges for Actions minutes **only on private repos**. On a public
repo, standard `ubuntu-latest` runners are **free and unmetered**. Every zero-step failure since
`2026-10-30T02:41Z` carried the billing message —

```
40993214694  headless/review-scaffold/android   steps=0  failure
40993179302  Parse R29 harness                  steps=0  failure
40993179179  android/headless                   steps=0  failure
```

— and **all of them are the same exhausted meter** (compute $12.13 / $12.00). That meter no longer applies to
this repo's standard runners.

**Cost of the decision, stated plainly:** the game, its history, every measurement log and every review
document are now **publicly readable**. That was the owner's IP call, made knowingly. **Make it private again
once the M1/M1.1 measurements are done** — the free-minutes benefit ends the moment it flips back, so batch the
work.

---

## 2. What must happen before any arm is launched

The arms are **still pinned to dead shas** and will not fire from a new push:

- `r29.yml` jobs are gated on `github.sha == github.event.after && contains(msg, '[R29-once-2]')` and pinned to
  `bb88cd1`.
- The runner-proof job is pinned to `fe56aad` / `[R29-runner-proof]`.
- `run_m1_r28.sh` (the **fix-validation** arm) still requires `git` and has **no `CLAMBER_LOCAL` path**, so the
  local/ZIP loop cannot validate a physics candidate until that is fixed.

So the order is: **prove the runner → re-pin → run**. A proof job first, because two days of zero-step
failures have taught us that a blocked runner is indistinguishable from a broken arm.

---

## 3. Standing rules unchanged

- **No physics change in this step.** Re-pinning and a proof job touch workflows only.
- **`core/` diff must stay empty**; `core/tuning.tres` sha256 stays `5f4d0d06…0666`.
- **M1 remains BLOCKED / NOT SIGNED.** A green runner is not a verdict.
- **Once-only arms.** One execution per arm, and the local/ZIP ledger rules stay in force.
