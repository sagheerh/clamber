# M1 — R33: the work is not on the remote, the environment blocker is workspace-local, and the chain approach has four hard invariants

**Reviewer:** `arena/5b72e4ab-clamber`. **Date:** 2026-10-30.
**Verdict: nothing to review — but nothing was claimed either, and that is correct. M1 stays BLOCKED.**

---

## 1. I looked for the work. It is not on the remote.

```
remote heads, right now:
  arena/4cd0a587-clamber   0bf73c9   (already merged into main as 7d86dd5)
  arena/f43f36ab-clamber   9618b06   (2026-10-30 05:07)  ← unchanged, still the rejected candidate
  arena/f08ed236-clamber   a486868   (2026-10-28 03:55)  ← stale, see §5
  arena/5b72e4ab-clamber   fdc200a   (this review branch)
  main                     7d86dd5
```

**No new commit exists anywhere** for the hinge-chain operator, the 18 math/source checks, the 12 runner
checks, or the 42 Godot checks. So I cannot verify any of them, and I am **not** treating them as progress
toward a fix. The agent said the same thing itself: *"koi naya push ya CI run claim nahi kar raha."* That
restraint is exactly right — an unpushed, unrun check is a claim about a local file system.

---

## 2. The environment blocker is real but **workspace-local** — the repository is fully operational

I re-tested everything from my side after the owner made the repo public:

| surface | state |
|---|---|
| GitHub auth (mine) | **valid** — pushed `fdc200a` successfully |
| Actions minutes | **free** (public repo); jobs execute, no billing message |
| **artifact storage** | **WORKING** — android job step 8 `Run actions/upload-artifact@v4` = **success** |
| full green run | **`41070829387`** on `fdc200a`: `review-scaffold` ✅ `headless` ✅ `android` ✅ |

**This closes the third blocker.** Until now I had to assume uploads would fail; they no longer do — storage is
unmetered on a public repo too. **All three blockers from R29 are gone: minutes, storage, runner.**

So `"GitHub authentication invalid"` describes **that workspace's session**, not the repository or the token.
The owner reconnect fixes it; nothing about M1's record depends on it.

**And the practical consequence is large:** the moment that workspace can push, the **42 Godot checks run on a
real pinned engine for free** in CI. There is no reason for the candidate to sit unvalidated for want of a
local engine.

---

## 3. Design preflight — four invariants this operator must satisfy, or it is invalid however it measures

The change described — *"contact impulse distributed across the whole hinge-linked chain, not just the
contacted body"* — is a legitimate idea (it is what a mass-matrix / constraint-coupled contact solve does), but
it introduces four failure modes that **posture and sleep numbers alone will not catch**. These are cheap to
assert and must be in the candidate's own test file, not discovered later by me:

1. **Impulse redistribution must be conservation, not amplification.**
   Sum over the chain of `Δ(mass·velocity)` must equal the original contact impulse to roundoff. If the chain
   sum exceeds the single-body impulse, the operator is injecting momentum. *Assert: `‖Σ chain impulse −
   original impulse‖ ≤ 1e-12 × ‖original‖`.*
2. **No net energy gain across the contact pass.**
   A distributed impulse can do positive work through hinge coupling even while conserving momentum.
   *Assert: total kinetic energy after the contact pass ≤ before + roundoff.* Report the delta.
3. **The R19/F56 signed-thrust identity must still hold.**
   Per-body impulse bookkeeping changes when an impulse is spread. If the momentum ledger no longer closes,
   every earlier momentum result is invalidated. *Assert: the existing R19 identity check still passes on the
   candidate build.*
4. **Determinism order.**
   If the distribution walks the chain, the walk must use a **fixed constraint-index order**, never a
   discovery/BFS order that depends on floating-point coincidence. §10.6 requires bit-identical repeats, and a
   traversal-order dependency breaks that silently. *Assert: 100 identical repeats, identical hash.*

**Two predicted interactions, so they are not surprises:**

- **Sleep will get harder, not easier.** Any non-zero impulse delivered to a chain body that was nearly at rest
  resets the stillness window. Expect `AC-201s` to stay failed or worsen; that is not a reason to reject, but it
  must be reported, not hidden.
- **F80 says the channels are separable.** The previous candidate reduced creep 22.5 % while worsening posture
  12.3 %. A chain-distributed impulse plausibly moves **posture** more than drift. Report both columns every
  time, never one.

---

## 4. What counts as evidence for this candidate

| artefact | status |
|---|---|
| 18 math/source checks | **NOT engine evidence** — they run without the engine |
| 12 runner checks | **NOT engine evidence** — routing only |
| **42 Godot component checks** | **NOT RUN** ⇒ this candidate currently has **zero engine evidence** |
| full-creature posture/sleep | **NOT RUN** |

The agent's own framing — *"yeh engine run nahi hai"* — is correct and I am holding it to that. Nothing here may
be described as *progress toward the fix* in any verdict; it is a **hypothesis with unit-level support**.

**Accept rule unchanged, all at once on one build:** attitude ≤ 15° · sleep fires · net COM ≤ 0.90 WU ·
penetration ≤ slop × (1+1e-9) · bone ≤ 0.05 WU · plus the four invariants in §3.

---

## 5. Branch hygiene — one trap and one recommendation

**Trap:** `arena/f08ed236-clamber` is **two days stale** (2026-10-28 03:55) and predates the entire solver. If
anyone merges it, `core/` loses **3 648 lines** across 26 files — including `capsule_contact.gd`,
`coupled_load_probe.gd`, `creature_solver.gd` and `tuning.tres`. **Do not merge it, do not "consolidate" onto
it, and consider deleting it** so a tired merge cannot destroy the milestone.

**Recommendation:** M1.1's contact/hinge work is now split across `f43f36ab` (candidate) and whatever branch the
new engine-less workspace will produce. **Consolidate onto one branch** for the fix work. Four arena branches
with evidence in three places is how a record becomes unauditable — and the contact work is precisely the part
that must be traceable from hypothesis → candidate → measurement → verdict.

---

## 6. Ruling

1. **Nothing to review this round**; nothing was falsely claimed. Credit for the discipline.
2. **Reconnect GitHub in Arena** (owner action) — then **push and let free CI run the 42 Godot checks.** Do not
   wait for a local engine; the engine is available for free in this repo now.
3. **Add the four invariants from §3** to the candidate's test file *before* the first full-creature run. A
   candidate that fixes posture while breaking momentum conservation or determinism is not a fix.
4. **Report posture and drift side by side**, per F80, plus sleeping ticks, penetration and bone error.
5. **Do not merge `arena/f08ed236-clamber`.** Consolidate M1.1 work onto one branch.
6. **M1 remains BLOCKED / NOT SIGNED. M2 blocked.** A green CI run of the *candidate* would still not be a
   verdict — the verdict is mine, and it needs the five M1 arms as well.
