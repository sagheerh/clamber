# M1 — F24 decision record (owner approval of the grip band interpretation)

**Context:** R8 review (`.review/M1_R8_PART3_REVIEW.md`) F24. Agent's reply proposes per-foot share with a **dynamic** `N_grounded` and asks for an explicit owner decision. This document freezes the decision, the exact definition, and the conditions the implementation must meet.

---

## 1. Decision

**Approved in direction: per-foot expected share. Not approved as written yet — two definitions must be fixed first (§2), because the dynamic `N` introduces an order-dependent threshold and a tick-boundary step.**

The rule:

```
N      = number of foot bodies of this creature with grounded == true
         at the END of the previous tick (frozen for the whole tick)
T_foot = max(5.0, 0.40 * sum(m_i) * |g| / N)      N >= 1
       = grip disabled for every foot              N == 0
```

- Each foot must independently satisfy `T_foot` **and** the existing grounded / lowest eligibility.
- `5.0`, `0.40`, `1.4`, `0.15` and every radius stay unchanged.
- The Slug's one-foot threshold stays `0.40 × 43.4 = 17.36 N`, unchanged.

**Rejected, and why:**

| Alternative | Why not |
|---|---|
| Creature-level sum (`Σ grounded foot forces ≥ 0.40 W`) | A barely loaded foot can be carried by another foot's load. Contradicts FA-5's per-foot sentence. |
| Build cap on foot count | Contradicts the GDD's first-clear reward ("Give it a third leg?", GDD `:143`) and currently allowed builds. |
| My earlier static `N_feet` from the definition | Weaker physics: it grades a foot against a share that assumes feet are down that are actually airborne. The agent's dynamic version is the more honest one; I am revising my own proposal. |

---

## 2. Two definitions that must be fixed before implementation

**(a) `N` is frozen, order-independent, and derivable from the snapshot.**
`CapsuleContact.resolve` is called per body, sequentially. If `N` is counted *during* the resolve loop, the first foot sees a different `N` than the last and the threshold becomes body-order dependent — a silent determinism break in the exact system M1 exists to make deterministic.

Therefore: `N` = count of feet with `grounded == true` **after the previous tick's** resolve completes. That value is already reconstructible from `CapsuleBody.snapshot()["grounded"]`, so **no new state field is needed** and restore/replay stays exact. Verify this with a restore-and-continue replay, not just by inspection.

**(b) "Grounded" is the post-resolve flag, not a proximity guess.**
`grounded` is set only by an actual sample inside `radius + contact_slop` in `_response`. Use exactly that. Do not introduce a second "is somewhere near the floor" predicate — two notions of grounded is how the next F22-class defect starts.

**Expected and acceptable consequences, which must be logged rather than smoothed:**

- **Tick 0:** `N = 0` → no grip → the Slug slips on its first contact tick. Expected, not a bug.
- **Touchdown/lift-off:** `N` changes 1→2 or 2→1, so `T_foot` halves or doubles at the *next* tick. This is a step function. If the trace shows grip toggling tick-to-tick around a touchdown, that is a finding to report — **do not add hysteresis, a decay, or a grace tick**; any such mechanism is a new invented constant and needs a fresh owner decision.
- Single-support: `N = 1` → `T_foot = 0.40 W`, and the one foot carries `≈ W` → grips with 2.5× margin. Correct.

---

## 3. Feasibility check I ran on the shipped tables (this is why the floor is safe)

Every foot contributes `physics_grip_mass_per_wu × physics_foot_length_wu × |g| = 1.2 × 0.25 × 28 = 8.4 N` to `W`. So for any build with `N` feet:

```
W/N = 8.4 + 28·(mass of non-foot parts)/N  >=  8.4 N
```

and the feasibility condition `W/N >= T_foot = max(5.0, 0.4·W/N)` holds for every N, because `8.4 > 5.0` and `0.4 < 1`. **No allowed build (≤ 10 parts, ≥ 1 motor, ≥ 1 foot) is made unable to stand by this rule.**

Slug (`W = 43.4`) for reference:

| N | `0.40·W/N` | `W/N` | floor binding |
|---|---|---|---|
| 1 | 17.360 | 43.400 | no |
| 2 | 8.680 | 21.700 | no |
| 3 | 5.787 | 14.467 | no |
| 4 | 4.340 | 10.850 | **yes — effective ratio rises to 5.0/10.85 ≈ 0.46** |
| 5 | 3.472 | 8.680 | **yes** |

So the floor is **structurally non-binding for feasibility**, but it *does* bind at N ≥ 4 for Slug-mass creatures and quietly raises the effective ratio to ~0.46. That is acceptable (margin is still 2.17×) but must be stated in the band's documentation rather than discovered later.

---

## 4. Consequences that must be recorded, not silently reinterpreted

- **FA-5 wording changes meaning**: "a foot loaded < 40 % of weight slips" becomes **"< 40 % of its expected share `W/N_grounded`"**. This is an interpretation change to an acceptance criterion, so it must be written into the FA-5 row of `.review/m1_ac_matrix.md` and an addendum to `M1_B01_CONTACT_GEOMETRY_DERIVATION.md` **in the same commit as the code**, attributed to the owner's decision, not to the agent's judgement.
- **The `Σ` invariant and its tolerance are derived, not chosen.** For the Slug, one tick of gravity impulse is `W·dt = 43.4/60 = 0.723 N` (1.67 %). A support solve that has not converged may legitimately be off by up to that per tick, so the honest steady-state acceptance is: **`|Σ per-foot support − 43.4| ≤ 0.723 N sustained over the last 300 of 600 ticks`**. Any larger or oscillating deviation is reported as a finding — never absorbed into a wider tolerance.
- Support reaction must be reported **separately from positional cleanup**. The current `maxf(positional, impulse)` mixes them; the new output must expose both terms (F23).
- Transient imbalance is exposed, not clipped: if the solver's support sum exceeds or undershoots `W`, print it.

---

## 5. Unchanged guardrails

- `normal_force_last_tick` splits into immutable input `applied_load_n` + output `measured_reaction_n`; `_response` must never overwrite the input.
- No injected qualifying loads anywhere in production paths, no prescribed weight shares in the solver.
- FA-3 / FA-4 / FA-5 / FA-6 stay `NOT RUN` until the coupled traces exist; the component suite stays labelled component-only.
- No retune of `0.40`, `5.0`, `1.4`, `0.15`, radii, `d10_bend_margin_wu`, or the mass table.
- No M2, no camera, no captures.

---

## 6. Paste-ready reply to the agent

```
F24 decision: APPROVED as per-foot expected share, with two definitions fixed first, and the two rejected alternatives noted.

Rule: N = number of this creature's feet with grounded == true at the END of the previous tick. T_foot = max(5.0, 0.40 * sum(m_i) * |g| / N) for N >= 1; grip disabled for every foot when N == 0. Each foot must independently satisfy T_foot plus the existing grounded/lowest eligibility. 5.0, 0.40, 1.4, 0.15 and all radii unchanged. Slug one-foot threshold stays 17.36 N.

Definition (a) — N must be FROZEN and ORDER-INDEPENDENT. resolve() is called per body in sequence; counting grounded feet inside that loop makes the threshold depend on body order and silently breaks determinism. Count after the previous tick's resolve. It is already reconstructible from CapsuleBody.snapshot()["grounded"], so add no new state field, and prove it with a restore-and-continue replay rather than by inspection.

Definition (b) — "grounded" means exactly the post-resolve flag set by a sample inside radius + contact_slop. Do not add a second proximity predicate.

Expected, and to be logged not smoothed: tick 0 has N = 0 so the Slug slips on first contact; N steps 1->2 at touchdown so T_foot halves on the next tick; single support gives N = 1 and 0.40 W against a foot carrying ~W. If grip chatters around a touchdown, report it as a finding — do not add hysteresis, decay or a grace tick; that is a new invented constant and needs a separate decision.

Feasibility, verified on the shipped tables: every foot contributes 1.2 * 0.25 * 28 = 8.4 N to W, so W/N >= 8.4 for any N, and W/N >= max(5.0, 0.4 W/N) always holds. No allowed build is blocked. Note the floor does bind at N >= 4 for Slug-mass creatures, raising the effective ratio to about 0.46 — document that in the band, do not let it be discovered later.

Record the reinterpretation in the same commit: FA-5's "40 % of weight" becomes "40 % of expected share W/N_grounded", in the matrix row and as an addendum to M1_B01_CONTACT_GEOMETRY_DERIVATION.md, attributed to the owner's decision.

Derived tolerance, not chosen: one tick of gravity impulse is W*dt = 43.4/60 = 0.723 N (1.67 %). Steady-state acceptance is |sum of per-foot support - 43.4| <= 0.723 N sustained over the last 300 of 600 ticks. Larger or oscillating deviation is a finding; do not widen the tolerance. Report support reaction separately from positional cleanup (F23), and print transient imbalance instead of clipping it.

Go ahead in this order: split applied_load_n / measured_reaction_n -> real gravity/constraint load path -> 600-tick Slug trace with per-foot forces, sum, error, grounded/gripping flags, sleep state -> then the FA-5 band and two-foot creatures. FA-3/4/5/6 stay NOT RUN until those traces exist. No retune, no M2, no captures.

Boundary stands: 208 component checks are not determinism; complete-creature determinism attempts remain 0.
```
