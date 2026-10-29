# M1 — R29 review: the adoption stop was obeyed, the cause is unestablished, and storage is now the blocker

**Target:** PR #3 head **`4796ec6`** (draft, OPEN, mergeable). Tail: `fb890fd` → `8bcb481` (prep, quarantine F47)
→ `446d870` (**adoption**) → `75fd3e7` (**revert**) → `91249f9` → `9784b5f` → `4796ec6`.
**Measured source:** `446d870` / CI **`40970023755`**.
**Reviewer branch:** `arena/5b72e4ab-clamber` @ `e233bfe`.

---

## 1. What I verified myself (not taken on trust)

| claim | verification | result |
|---|---|---|
| head is `4796ec6` | `git ls-remote` | ✓ |
| adoption then full revert | `git log`, `git show --stat 75fd3e7` | ✓ revert names `446d870` |
| production core unchanged | `git diff fb890fd 4796ec6 -- core/` | **empty** |
| tuning unchanged | sha256 both ends | **`5f4d0d06…0666` both** ✓ matches reported |
| adoption is exactly the authorised change | `git show 446d870 -- core/sim/coupled_load_probe.gd` | unconditional traversal, same rows/order/compliance/multipliers, **no velocity edit**, instrumentation behind `_record_length_phase` ✓ |
| revert is byte-exact | `git diff fb890fd 75fd3e7 -- core/ tests/fixtures/public_sim_baseline.json` | **empty** ✓ |
| only F47 quarantined | `grep continue-on-error` = **1** occurrence, on that step | ✓ no assertion/threshold/command touched |
| 226 controls / 0 failures | **I ran `scripts/review_checks.sh` at `4796ec6` myself** | **226 ran, 0 failures** ✓ (218 → 226, +8 R28 controls, none hollow — they assert tuning identity, exactly one traversal, no physics flag, single quarantine, detached parked resolver, pins, strict stop, horizons, no unbounded dispatch) |
| penetration values | parsed from job `123784170344` annotation | reproduced exactly ✓ |
| runs completed | `engine_status 0`, 3 × 7200, no `step_failure`, no non-finite | ✓ |
| reverted-build replay | job steps 3–6 (`R28 baseline overlay`) **skipped** → historical baseline | agent labelled this correctly ✓ |
| PR untouched | `gh pr view 3` | draft, `MERGEABLE` ✓ |
| **artifact storage** | `gh api .../artifacts` paged | **1144 artifacts, 0 expired, 22.9 GB, private repo** ← see §5 |

**This session was honest.** Numbers published that killed its own change, stop honoured without a retry,
hashes preserved after the artifact loss, F47 called **NOT RUN** rather than PASS, no threshold touched.
That is exactly the behaviour the stop conditions were written to produce.

---

## 2. The stop was obeyed — but I wrote a stop condition that cannot attribute. That is my error.

The gate said: *if any preset exceeds 0.02, do not adopt.* It fired. The revert is correct **by the rule as
written**, and I am not undoing it.

But the rule specified an **absolute** limit and **no control arm**. Only the adopted build was measured, so
these numbers establish:

> the adopted build penetrates 0.0508–0.0934 WU

and they do **not** establish:

> the reprojection causes it.

And the shape of the data argues against the obvious reading:

| preset | worst tick | part | what it means |
|---|---:|---|---|
| Slug | **6** | foot2, `u=1.00` | 0.1 s after spawn, **zero input** |
| Hopper | **7** | foot5, `u=1.00` | 0.1 s after spawn, **zero input** |
| TwinRoller | 2162 | motor1 | mid-run — a different signature |

Two of three worst cases land in the **spawn-settling window**, before any input exists. A defect that peaks
five ticks after spawn is more likely to be the creature being dropped into the ground than a mid-run
projection artefact. TwinRoller's tick-2162 event could genuinely be the reprojection.

**My 16th error, in writing:** I authored a hard stop that measures one arm and licenses a causal verdict.
A stop condition that can fire without a control is a coin-flip dressed as a gate. It is cheap to fix and it
must be fixed before anyone says "the reprojection causes penetration".

**Decisive fix (one arm, folded into P2 so the three-session limit holds):** the **same** penetration
measurement on the **reverted production build**, same presets, same 7200 ticks, same metric. Outcome table:

| control result | reading | consequence |
|---|---|---|
| reverted ≥ 0.02 too, similar magnitude | **pre-existing**; the reprojection is exonerated on this evidence | F79 becomes a defect in its own right; AC-202 adoption is a fresh owner decision |
| reverted ≪ 0.02 (e.g. ≤ 0.005) | **the reprojection causes it** | AC-202 as adopted is **dead**; M1.1 must fix the injector without a post-contact projection |
| reverted between | **partially causative** | report both numbers; no adoption |

---

## 3. A correction R28 forced on the record: **AC-202 is FAILED in production**, and always was

The R27 matrix carried AC-202 as "PASS (candidate only; unadopted)". That is a **category error** — AC-202's
text is a **production** gate (limb-length error ≤ 0.05 WU over two minutes). Production completed-tick limb
maxima, from R27's own phase table:

| preset | production completed-tick limb max | limit | ratio |
|---|---:|---:|---:|
| Slug | **0.10553 WU** | 0.05 | 2.11× |
| Hopper | **0.15363 WU** | 0.05 | 3.07× |
| TwinRoller | **0.06175 WU** | 0.05 | 1.24× |

Production **fails AC-202 by 1.2–3.1×**. The candidate was the only build that passed it, and the candidate
is not adoptable as it stands.

**So the agent's reclassification to `FAILED` is right, and for a stronger reason than the one given.** The
matrix line should read **`FAILED — production limb error 2.1×/3.1×/1.2× the limit; the only passing candidate
fails the penetration condition`**, not "FAILED (R28 penetration)". AC-202 now joins AC-201 in M1.1, and this
is one fix (the contact position-correction pass), not two.

---

## 4. New finding **F79 — feet below the floor at spawn**

| preset | part | centre vs surface | radius | penetration | vs 0.02 slop |
|---|---|---:|---:|---:|---:|
| Slug | foot2 | **−0.0203 WU (below)** | 0.05 | 0.0703 | 3.5× |
| Hopper | foot5 | **−0.0434 WU (below)** | 0.05 | 0.0934 | 4.7× |
| TwinRoller | motor1 | +0.0442 (above) | 0.095 | 0.0508 | 2.5× |

For Slug and Hopper the foot's **centre is under the terrain**, so the whole 0.05-radius foot is submerged.
Whatever the cause, that is a defect, not slop tolerance.

**Guards, effective immediately:** do not raise `physics_contact_slop_wu`; do not clamp the projection; do not
"bound" penetration to 0.02. F79 is measured first (§2), then owned by M1.1.

---

## 5. The blocker nobody has addressed: **artifact storage is exhausted and it is now deleting coverage**

| fact | value |
|---|---|
| artifacts held | **1144**, **0 expired** |
| total size | **22.9 GB** |
| repo | **private** → free Actions storage is 500 MB |
| workflow retention | already `retention-days: 7` everywhere |

Consequences, each verified:

1. **Every red X in the repository right now is this, not code.** M0 `android` exports and validates the AAB,
   then dies on `actions/upload-artifact`. The public replay job replays, then dies on the same step. The
   static job **passes** (226/0).
2. **The failure is silently shrinking M1's coverage.** On `9784b5f` the math job fails at step 6 (an upload)
   and steps 7, 9, 11–21 are **skipped**: the F47 diagnostic, R11, R12, R13, R14-sleep and R15 mechanics
   **did not run**. Diagnostics that passed on `93c17d6` are now absent.
3. **P2 cannot deliver its evidence.** The presets/captures gate is an E4 **artifact**; AC-204-style "log
   attached" is an artifact. M1 cannot be signed green while uploads fail.
4. **D8's quarantine is unverified** — F47 is **skipped**, so its post-quarantine result is `NOT RUN`. The
   agent reported exactly that rather than claiming a pass; the quarantine remains an unproven change.

**Fix:** free the storage (delete stale artifacts) or raise it. Retention is not the problem; volume is.

**Attempted 2026-10-30, blocked:** the owner authorised a bulk delete keeping only `m1-r27*` (25 artifacts,
53 MB). The API call `DELETE /repos/…/actions/artifacts/<id>` returns **403 "Resource not accessible by
integration"** — the connected token has no artifact-delete scope, so **no deletion was performed** and this
is an **owner action in the GitHub UI**. Cheapest path: *Settings → Actions → General → Artifact and log
retention → 1 day* (existing older artifacts are then cleaned up), and/or delete the M0 runs, which alone
hold **201 artifacts / 10.9 GB**. GitHub recalculates usage every 6–12 hours, so CI may stay red for hours
after the clear.

---

## 6. Ledger — corrected, including one of my own arithmetic slips

| | R27 review | after R28 |
|---|---:|---:|
| 18 runtime slots | 18 | 18 |
| **production-operational PASS** | 10 | **10** |
| **FAILED** | AC-201 | AC-201, **AC-202** |
| uncredited / unmeasurable | FA-3 | FA-3 |
| unmeasured | 5 | 5 |

**My 17th error:** my three-prompt plan said "16 of 18 with adoption" — 11 + 4 = **15**, not 16. With the
adoption now reverted and AC-202 correctly counted as FAILED, the honest ceiling is:

> **14 / 18 passing**, 17 / 18 carrying a measured verdict, **FA-3 unmeasurable as specified**.

That is a worse number than I promised, and it is the true one. It is still a complete milestone: every row
measured, every failure a number with one named cause, nothing relaxed.

---

## 7. What remains for M1, and who owns it

| # | item | owner | where |
|---|---|---|---|
| 0 | **free artifact storage** (or raise it) | **owner** | before P2 |
| 1 | **penetration control arm** on the reverted build — decides AC-202's fate | agent | P2-D0 |
| 2 | three presets + 10 s captures (E4) | agent | P2-D1 |
| 3 | tick cost §10.4 (CI hardware; reference-device leg = D07) | agent + owner | P2-D2 |
| 4 | §10.6 step 1 (100 × 10 000 identical hashes) | agent | P2-D3 |
| 5 | FA-4 (sleep-dependent → expected FAIL) | agent | P2-D4 |
| 6 | FA-6 (10 identical runs + explicit variance source) | agent | P2-D5 |
| 7 | 18-row verdict, INV closure, five-fakes, PR ready | reviewer | P3 |
| 8 | **D07** reference-device tick cost | owner (phone) | open |
| 9 | **FA-4's 1.00 BL** — spec or scale | owner | open |
| 10 | **M1.1 scope** — contact position-correction pass (one fix for AC-201a, AC-201s, AC-202, FA-4) | owner | open |

**Operational catch for P2:** at `4796ec6` the R28 jobs are gated on `workflow_dispatch` with an
`inputs.r28_source_sha` pin — but **dispatch returns 403 in this environment**, so the current workflow
**cannot launch them**. P2 must restore the push-triggered `[R2x-once]` path (`github.sha == github.event.after`)
that worked at `446d870`, keep the literal source pin in the closing record, and keep one invocation per arm.

---

## 8. Directives

0. **OWNER DECISION (2026-10-30) — AC-202 stays FAILED for M1; no re-adoption attempt inside M1.**
   Rationale, recorded so nobody reopens it by accident: the rectifier fix (M1.1) changes the very contact
   path a post-contact projection compensates for, so adopting the workaround first would risk locking in a
   solution to a defect that is about to be removed. AC-201a, AC-201s, AC-202 and FA-4 are **one** M1.1
   cause; the projection is re-evaluated **after** that fix, not before. The D0 control arm still runs —
   its purpose is to tell M1.1 whether penetration is a second, independent defect in the same pass.
1. **Adoption stays reverted.** AC-202 is `FAILED` in production; AC-201 and AC-202 are **one** M1.1 cause.
2. **P2 runs the penetration control arm first**; no conclusion about cause is written before it lands.
3. **P2 changes no physics.** Measurement, captures, timing, determinism step 1, FA-4, FA-6 only.
4. **Storage is an owner action.** Until it is cleared, no green CI claim is permitted and E4 captures move to
   **committed repo files** with a size budget rather than artifact-only storage.
5. **F79 is recorded, not fixed**; slop, clamps and tolerances stay untouched.

**M1 is not complete. M2 remains blocked. 14/18 is the honest ceiling for this milestone.**
