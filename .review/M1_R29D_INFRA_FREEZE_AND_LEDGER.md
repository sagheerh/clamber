# M1 — R29d: stop the loop. M1 is BLOCKED, not failed — frozen ledger published

**Target:** PR #3 head **`0c1d3f8`**. **Reviewer:** `arena/5b72e4ab-clamber`.
**Decision of this ruling:** no further prompt goes to the coding agent until a runner proof **passes**.
The agent has done everything available to it; the remaining blocker is an account setting.

---

## 1. Verified at `0c1d3f8`

| claim | check | result |
|---|---|---|
| head `0c1d3f8` | `git ls-remote` | ✓ |
| runner proof never started | `gh api …/runs/40980478102/jobs` | **runner-proof `steps=0`, both later jobs `skipped`** ✓ |
| nothing launched | same | no `[R29-once-3]` job has ever executed ✓ |
| production core untouched | `git diff 4796ec6 0c1d3f8 -- core/` | **empty** ✓ |
| D0 relabelled, F79 withdrawn | evidence JSON | ✓ (verified in R29c) |
| controls | 232 / 0 | ✓ (verified by me at `eee6c81`; `0c1d3f8` is docs-only) |

**The agent's behaviour was correct on all three of these turns:** it built the proof gate I asked for, ran it
*before* activating any arm, refused to launch arms when the proof failed, kept L1/L2 and this third block
distinct, and did not touch physics. There is nothing left for it to do.

---

## 2. What is actually wrong — and a concrete prediction

Three consecutive blocks, all identical, all **zero steps**:

```
40979233978  measurements      steps=0
40980478102  runner proof      steps=0
```

GitHub: *"recent account payments have failed or your spending limit needs to be increased."*

**Working diagnosis, with the evidence I can actually see:**
- The repo is **private** → Actions minutes are **metered**, monthly, and capped.
- This repo's **first run is `2026-10-29T13:47Z`** and **100+ runs** have been created since — a heavy
  instrumented month, with 20-batch soak matrices, three engine installs per job, and ~1 144 artifacts.
- **Today is October 30.** A monthly included-minutes allowance that has just run out mid-project produces
  exactly this message, and it **resets on the 1st**.

**Prediction, testable in one page:** *Settings → Billing → Plans and usage → Actions* will show the included
minutes for the current cycle at or near 100 %, and the **artifact storage** figure at ~22.9 GB against 500 MB.
Same billing surface, two symptoms. If the minutes show exhausted, **no amount of retrying works before the
reset** — and if the spending limit is $0/unset, raising it unblocks immediately.

I could not read that page: the token gets **403** on `/billing/*` and `/actions/permissions`. **The owner must
look at it** — it is the only remaining unknown in this milestone.

---

## 3. Frozen ledger — the reconciliation I owed you

I flagged in R29c that my running total had drifted by one. Here it is fixed, once, from
`.review/m1_ac_matrix.md` at `0c1d3f8`, with an **explicitly declared definition** so it can never drift again.

**Runtime ledger = 18 operational slots** (AC-201 is one parent with `a`/`b`/`s` children; FA-3 is an
observation, not a runtime slot — that difference is exactly what caused my earlier off-by-one):

| verdict | count | slots |
|---|---:|---|
| **PASS** | **10** | Engine, A9.2, A9.3, A9.4 replay, A9.4 stall, A9.5, A9.7 flip, A9.7 baseline, AC-204, FA-5 |
| **FAILED** | **2** | **AC-201**, **AC-202** |
| **STATIC-ONLY** | **1** | A9.1 / A9.6 |
| **NOT RUN** | **5** | **presets + captures, tick cost §10.4, §10.6 step 1, FA-4, FA-6** |
| total | **18** | |

Plus, outside the 18: **FA-3 uncredited** (vacuous — 0 wake events with 0 sleeping ticks), **FA-1/FA-2/FA-7
analytic only**, **INV-01…INV-10 `NOT RUN`**, **A5.6/A10 five-fakes `NOT RUN`**, **A12 verdict `NOT RUN`**.

**Best case if everything NOT RUN came back clean: 14 / 18.** With tick cost's `NOT MEASURABLE AS SPECIFIED`
(§10.4's 30-body/120-constraint row is unreachable under the 10-part cap): **13 / 18**. FA-4 will fail — that is
the fourth slot that cannot pass without M1.1.

**This is a status, not a verdict.** M1 is **BLOCKED**, and the block is purely infrastructural.

---

## 4. What the owner can do — three paths, one recommendation

| | action | time | result |
|---|---|---|---|
| **A** | **Check `Settings → Billing → Plans and usage → Actions`.** If minutes are exhausted: wait for the cycle reset, or set a spending limit above $0 to continue now. | 5 min | everything resumes; the proof job already exists and will gate correctly |
| **B** | **Run the arms locally** with `Godot 4.7.2-stable` — procedure below | ~1–2 h | same five measurements, evidence committed by hand; the reviewer loses CI re-derivability |
| **C** | **Close M1 as INCOMPLETE-BLOCKED** — verdict written with 5 `NOT RUN`, unsigned | 0 | honest record; **M2 stays blocked**; every remaining gate still needs doing later |

**Recommendation: A first, B as fallback, C only if the account cannot be fixed.**

**Why not C by default:** a milestone signed with five blank gates is the "green by absence" failure this
review pack exists to catch. C is legitimate **only** as *"M1 not complete: five runtime gates unmeasured,
blocked by account billing"* — never as a pass.

### Path B — exact procedure (only if A is unavailable)

1. Install **Godot 4.7.2-stable**, verify the binary against the release's `SHA512-SUMS.txt`.
2. `git checkout 0c1d3f8` in a clean clone; confirm `git diff 4796ec6 HEAD -- core/` is **empty**.
3. `bash tests/run_m1_r29.sh` per arm (`--mode=d1|d2|d3|d4|d5`), **once each**.
4. Commit the outputs under `tests/fixtures/m1_r29_local/`, with the engine build string and the sha256 of
   every raw file.
5. State in the report: **`measured locally by the owner, not CI`** — the reviewer will treat it as owner-attested
   evidence, with the same numbers required as CI would have produced.
6. Send me the commit; I verify the numbers and finish P3.

---

## 5. Directives

1. **Do not send the coding agent another prompt until a runner proof passes.** It has no remaining action; a
   fourth launch attempt only burns the owner's time and produces another zero-step annotation.
2. **`[R29-once-3]` stays dormant** and must be re-pinned to whatever head is current when the runner returns —
   the sha pin will not match a newer commit.
3. **D0 is final. AC-202 stays FAILED. No re-adoption in M1.**
4. **M1 is BLOCKED, not failed, and not passable by absence.** M2 stays blocked.
5. **P3 is deferred**, and when it runs it uses the **frozen ledger in §3** — not any total quoted from memory,
   including mine.

---

## 7. CONFIRMED (owner screenshot, 2026-10-30) — the prediction in §2 was exact

Owner-supplied billing page, **Current month** timeframe:

| meter | used | included | state |
|---|---:|---:|---|
| **Compute (Actions minutes)** | **$12.13 consumed** ($12.00 included) | $12.00 | **EXHAUSTED — 101 %** |
| **Actions storage** | 0.5 GB | 0.5 GB | **EXHAUSTED — 100 %** |
| Billable usage | **$0** | — | within discounts, nothing owed yet |
| reset | **"Included usage limits reset in 2 days"** | — | ≈ 2026-11-01 |

**Both blockers are one meter pair, exactly as diagnosed:** the compute meter is overdrawn by **13 cents**,
which is why `40979233978`, `40980478102` and every M0 android upload fail with zero steps. The artifact
quota is the same page's second row. **Nothing is wrong with the repo, the harness, the workflow or the
physics.** `gh api` returned 403 on `/billing/*`, so this page was the only way to confirm it — it is now
confirmed, and no further launch attempt should be made until one of the two conditions in §8 holds.

**Cost of finishing M1's remaining CI:** five arms at ~3–5 min each plus a proof job ≈ **20–30 Linux minutes
≈ $0.16–0.24** at the standard overage rate. This is a rounding error against the $12 already spent — the
block is a **cap**, not an affordability problem.

---

## 8. The two viable moves, now with real numbers

| | action | cost | outcome |
|---|---|---|---|
| **A1 — free** | **Wait for the reset (≈2 days, 2026-11-01).** Do nothing else. | **$0** | on 1 Nov, re-pin `[R29-once-3]` to the then-current head, run the runner proof, then D1–D5. Artifact storage also resets, so M0 android stops being red. |
| **A2 — pay ~25 ¢** | **Set a small spending limit** (e.g. **$5**) in `Settings → Billing → Spending limits`, keeping "stop usage when limit is reached". | **~$0.25** of the M1 arms; the $5 cap is a ceiling, not a charge | everything runs **today**: proof → D1–D5 → P3 → M1 signed. |
| B | Owner runs the arms locally with Godot 4.7.2 | ~1–2 h of owner time | same numbers, owner-attested evidence, no CI |
| C | Close M1 as **INCOMPLETE-BLOCKED** (5 `NOT RUN`, unsigned) | $0 | honest record; **M2 stays blocked**; every gate still owed later |

**Reviewer recommendation: A2.** Twenty-five cents buys back two days and removes the last uncertainty in the
milestone. **A1 if spending is off-limits** — it costs nothing but time and M1 is not on fire. **B only if the
owner wants the numbers today and won't touch billing. C is not recommended while A1 is hours away.**

**Do not choose C to "close the milestone".** Five unmeasured gates signed as complete is exactly the failure
this review exists to prevent; C's verdict text is fixed as *"M1 not complete — five runtime gates unmeasured,
blocked by account billing"*.
