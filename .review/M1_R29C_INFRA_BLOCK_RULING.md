# M1 — R29c ruling: the block is infrastructure, not the harness; M1 cannot close without D1–D5

**Target:** PR #3 head **`eee6c81`**. **Reviewer:** `arena/5b72e4ab-clamber`.
**Scope:** classify L2, correct the stop rule's scope, name what M1 can and cannot be signed as, and give the
exact resume instruction — including one pinning trap that would silently prevent the resume.

---

## 1. Verified myself

| claim | check | result |
|---|---|---|
| head `eee6c81` | `git ls-remote` | ✓ |
| production core untouched | `git diff 4796ec6 eee6c81 -- core/` | **empty** ✓ |
| tuning byte-identical | sha256 | `5f4d0d06…0666` ✓ |
| **232 / 0 controls** | I ran `scripts/review_checks.sh` at `eee6c81` | **232 ran, 0 failures** ✓ |
| L2 never started | `gh api …/runs/40979233978/jobs` | **`steps=0`** on the measurement job, parse job `skipped` ✓ |
| D0 relabel applied | evidence JSON | all three rows `CONTROL — AT SLOP (0.02 + roundoff)`, attribution = *"multiplies penetration 2.5–4.7× … AC-202 as adopted is dead on the evidence"* ✓ |
| roundoff band in the rule | evidence JSON | `<=0.02*(1+1e-9)` → AT SLOP; `>0.02*(1+1e-9)`, **never bare `>=`** ✓ |
| F79 withdrawn | evidence JSON | **`"F79": "WITHDRAWN"`** ✓ |

**Every correction I asked for was applied exactly, without rerunning D0 and without softening anything.**
D0 is now correctly described: the control rests at the slop, the adopted build sat **2.5–4.7×** above it,
and AC-202 is dead on the evidence. That part of the record is final.

---

## 2. Classification: **L2 is an infrastructure block, not a second arm failure**

GitHub's message is unambiguous:

> *"The job was not started because recent account payments have failed or your spending limit needs to be
> increased."*

**Zero steps, zero ticks.** My "second failure → stop" instruction was written about **arms that run and
misbehave** — a signal that the harness or the physics is wrong. Nothing about the harness was exercised here,
so that instruction does not apply and **D1–D5 are not disqualified.** Stopping the *sequence* was right;
treating it as a verdict on the harness would not be.

**Do not record this as an arm failure, a harness defect, or evidence of any kind.** It is env-blocked.

**Root cause, stated plainly:** Actions minutes on a **private** repo are metered and the account's payment or
spending limit has lapsed. This is the same account condition family as the artifact quota that has been
reddening M0 for two days — two symptoms, one billing surface. It is not code, not physics, not the harness.

**I checked whether I could run the arms myself instead.** I cannot: fetching the pinned editor from GitHub
Releases redirects to `objects.githubusercontent.com` / `release-assets.githubusercontent.com`, which this
sandbox cannot reach (`SSL_ERROR_SYSCALL`). **There is no verified local-engine path from my side**, and I will
not claim one I have not tested. Real engine measurements need either restored Actions minutes or an
owner-run local engine.

---

## 3. What M1 can be signed as today — and what it cannot

**It cannot be signed as complete.** Five runtime gates — presets/captures, tick cost, §10.6 step 1, FA-4,
FA-6 — have **no measurement at all**. A milestone signed with five blank gates is the "green by absence"
failure the review pack exists to catch. **M2 stays blocked.**

What *is* solid and does not depend on CI:

- **D0 closed** on committed repository evidence (no artifacts needed) — control at slop, adoption 2.5–4.7×
  above it, AC-202 dead.
- **AC-201a/b/s** measured; **AC-202** FAILED; **AC-204** PASS; **FA-5** PASS with caveat; **FA-3** uncredited.
- **A9 family + Engine** measured on earlier runs.
- **232/0 controls, M0 516/0, `core/` empty, tuning byte-identical** — verified by me at this head.

**A bookkeeping warning against myself:** my own running totals have drifted by one across R27→R29 (whether
FA-3 and A9.1 are separate slots). I am **not** publishing another total from memory. **P3 must reconcile the
18-slot ledger once, directly from `.review/m1_ac_matrix.md`, and the verdict uses that single number.** Any
number I have quoted before that reconciliation should be treated as provisional.

---

## 4. Three paths, with a recommendation

| | path | cost | what it buys |
|---|---|---|---|
| **A (recommended)** | **Owner restores GitHub billing** (payment method / spending limit) | minutes in a settings page | unblocks all five gates; CI can finally go green; M0 android stops being red |
| B | **Owner runs the engine locally** (`Godot 4.7.2-stable` + `tests/run_m1_r29.sh` per arm) | ~1 h of their time, manual evidence handling | same measurements, but evidence discipline is manual and the reviewer cannot re-derive it from CI |
| C | **Close M1 with D1–D5 `NOT RUN`** | free | **not a signable M1.** The verdict would read "17-of-18-style coverage with five gates unmeasured"; that is a status report, not a milestone close |

**Recommendation: A.** Then B as fallback. **Do not take C while A is available** — it converts an
account-settings problem into a permanently weaker milestone, and every one of those five gates is cheap to
run once the runner works.

*(An owner-only option I will name but not advocate: a public repo gets free Actions minutes. That exposes the
game and its history publicly — an IP decision, not an engineering one. Not my call, and not needed if billing
is fixed.)*

---

## 5. The resume instruction — and the pinning trap

**Trap:** the `[R29-once-2]` jobs are pinned to `bb88cd1` and gated on
`github.sha == github.event.after && contains(message, '[R29-once-2]')`. **When billing is restored, a new push
will not fire them** — the sha will differ. A resume that only says "push again" would silently do nothing and
look like a third failure.

**Resume prompt (paste after billing is confirmed working):**

> **Billing is restored. Resume R29 at head `eee6c81`.**
>
> 1. The `[R29-once-2]` jobs are pinned to `bb88cd1` and cannot fire from a new head. **Re-pin the five
>    measurement jobs to the new head and use a new marker `[R29-once-3]`**, keeping one execution per arm.
>    Do not touch the historical `[R1x–R27-once]` pins.
> 2. **Before launching the arms**, run a single trivial proof-that-the-runner-works job (e.g. the static
>    subset) so a billing block cannot masquerade as an arm failure again.
> 3. Then run, exactly once each: **D1** 3 presets × 600 ticks (captures + script-rendered plots + manifest,
>    committed ≤ 5 MB, distinctness by pairwise trace hash **and** numbers, no authored threshold) · **D2**
>    **Hopper alone = the mandatory real row**, plus ten independent Slugs = 30 capsules as a labelled
>    aggregate, optional 14-part test-only creature, **actual constraint count**, median + P95, hardware
>    string, **3.0 ms never applied as pass/fail on a proxy**, reference-device leg `NOT MEASURED (D07)` ·
>    **D3** 10 000 ticks × 100 repeats, all 100 hashes logged, soak never re-presented as determinism ·
>    **D4** settle/sleep/lurch in **WU, BL, px**, 1.00 BL left to the owner · **D5** ten outcomes with
>    **variance source NONE** stated plainly.
> 4. Record `L1` and `L2` as **zero-tick launch incidents**; neither is evidence, neither is an arm failure.
> 5. Do **not** rerun D0, **do not** re-adopt AC-202, **do not** start P3.
> 6. If any arm fails again after executing ticks, record `NOT RUN` and stop — that failure *is* a signal.

---

## 6. Directives

1. **D0 final as relabelled.** No rerun, no further discussion.
2. **D1–D5 remain authorized and unrun.** They are the only thing standing between M1 and a signable close.
3. **No P3 until they land.** P3 must also reconcile the ledger (§3) before publishing any total.
4. **Do not sign M1 on absence.** If the owner chooses path C, the verdict says *"M1 not complete: five runtime
   gates unmeasured, blocked by account billing"* — and M2 stays blocked.
