# M1 — P2/D2 ruling: time ten Slugs (30 capsules), label it, and do not call it a gate pass

**Question put to the reviewer (2026-10-30):** §10.4 asks for a solver tick at **30 bodies / 120
constraints**, but no legal production creature has 30 parts. Which workload should be timed?

**Verified in the repo before ruling:**

| preset | parts |
|---|---:|
| `preset_slug.json` | **3** (head, motor, foot) |
| `preset_twinroller.json` | **6** |
| `preset_hopper.json` | **8** |

GDD caps a creature at **10 parts** ("All 10 parts used — remove one first", §5 build budget; `10 parts → 222
bits`; T-16 "10 parts"). So the agent's claim is correct, and the situation is sharper than stated:

> **No legal creature can reach 120 constraints either.** A 10-part creature is ≈9 distance links plus angular
> joints — on the order of ≤ 40 constraints. **§10.4's 30-body / 120-constraint row is unreachable in
> production at any creature size the GDD allows.**

And a 10-part creature **does not exist** — the largest preset is 8. Authoring one would be new preset
geometry, which the reviewer may not do and the agent may not invent.

## Ruling: Option 1 — "30 real capsules: ten Slugs" — adopted with four labels

1. **Primary row = the largest *real* workload that exists:** the **Hopper, 8 parts**, measured alone, median
   and P95. That is the shipping performance number and it needs no proxy.
2. **Budget row = ten independent Slug solvers, 30 capsules**, reported as an **AGGREGATE of ten solvers**,
   never as "one 30-body creature". Report per-solver median/P95 as well as the aggregate, so one slow
   solver cannot hide inside the sum.
3. **Report the actual constraint count** for both rows. Expect the aggregate to carry ~2–3 dozen
   constraints, **not 120** — say so in the row.
4. **The row is ONE-SIDED and must be labelled as such:** fewer constraints than the budget means an
   aggregate *pass* does **not** establish the 30/120 budget (more constraints cost more), while an
   aggregate *fail* would establish that the budget is missed. Write that sentence next to the number.

**Verdict for the matrix row:** `MEASURED ON A DECLARED PROXY — gate not established` plus the owner
question below. **Not** `PASS`, **not** `NOT RUN`.

## Rejected, with reasons

- **Option 2 (30-point / 120-link `PointLinkSolver` fixture)** — rejected. `PointLinkSolver` is documented in
  the repo as *"Independent scalar point/link integrator, NOT the creature Sim or a replay"*. Timing it would
  be a number from a non-production integrator presented beside production rows — the "stub that passes"
  pattern. It also matches the constraint count only by leaving the creature code entirely.
- **Option 3 (mark `NOT RUN`)** — rejected as the *only* action. A labelled proxy number is more useful to the
  owner than a blank row, and the label makes it non-launderable. `NOT RUN` remains correct for the
  **reference-device leg** (D07), which genuinely cannot be measured here.
- **Building a 10-part creature to chase the budget** — **not authorised.** New preset geometry is an owner
  decision, and it would still not reach 120 constraints.

## Owner question opened by this ruling (4th open item)

> §10.4's "30 bodies / 120 constraints" cannot occur in production: the GDD caps creatures at 10 parts
> (≤ ~40 constraints) and the largest shipped preset is 8 parts. **Is that budget (a) headroom to be
> demonstrated by an aggregate proxy, or (b) a hard scenario that needs an authorised test-only creature?**
> Until the owner rules, M1's tick-cost row reads *measured on a declared proxy; gate not established*, and
> the reference-device leg stays `NOT MEASURED (D07)`.

Record it beside the existing owner items: AC-202/M1.1 scope, D07 reference-device cost, FA-4's 1.00 BL.

---

## Verified constants (read from `core/tuning.tres` at `4796ec6`)

```
physics_contact_slop_wu     = 0.02
physics_part_budget         = 10
physics_post_part_budget    = 14
```

Presets: Slug **3**, TwinRoller **6**, Hopper **8** parts. So the largest creature the tuning permits is
**14** (post-budget) and the largest *shipped* one is **8** — the §10.4 row's **30 bodies / 120 constraints**
is unreachable by a factor of **2.1× in bodies** and roughly **3× in constraints** at the absolute cap. This
is a **spec-vs-scale defect in the gate text**, not a measurement failure by the agent.

## Execution instruction (paste-ready)

> Take **Option 1** — ten Slugs, 30 capsules — with these constraints:
>
> 1. **Mandatory real row:** measure **Hopper (8 parts)** alone through the production `Sim.step` path.
>    That is the largest shipped creature and the honest production number.
> 2. **Budget proxy row:** ten **independent** production Slug solvers in one frame = 30 capsules. Report
>    **per-solver median/P95 and the aggregate**, plus the **actual constraint count** (expect ~2–3 dozen,
>    not 120). Label it "AGGREGATE OF TEN SOLVERS — not one 30-body creature".
> 3. **Optional, clearly labelled test-only:** a 14-part creature built inside the model's legal limits
>    (`physics_post_part_budget`), timed the same way, **not** committed as a preset. This is the closest
>    legal approach to the budget and must be marked test-only.
> 4. Protocol for all rows: warm-up discarded, ≥10 000 ticks, **median + P95**, hardware string, build,
>    constraint count. `physics_tick_hz` fixed at 60; never time the outer frame as if it were a tick.
> 5. **Do NOT apply the 3.0 ms threshold as a pass/fail on any proxy.** Report the numbers beside it as
>    context. The matrix row reads **`NOT MEASURABLE AS SPECIFIED`** with the owner question attached, and
>    the reference-device leg stays `NOT MEASURED (D07)`.
> 6. **Do not** time `PointLinkSolver` — it is documented as not the creature Sim, and a number from it would
>    be a non-production integrator sitting in a production row.

## Postscript — D0 has landed, and it kills my own hypothesis (18th error, owned)

Control arm on the **reverted** build, 3 × 7200 ticks (CI `40974615538`, evidence at `a3c7cc0`):

| preset | control max WU | R28 adopted max WU | ratio | worst part / tick |
|---|---:|---:|---:|---|
| Slug | **0.020000000000000823** | 0.07028201067739755 | 0.285 | head / 22 |
| Hopper | **0.020000000000000823** | 0.0933999293597247 | 0.214 | head / 33 |
| TwinRoller | **0.020000000000000823** | 0.05075245867956493 | 0.394 | head / 15 |

**The control sits exactly on `physics_contact_slop_wu` and never exceeds it** — the production resolver's
steady state is the slop allowance, and all three presets hit the same 0.020000000000000823 ceiling across
7200 ticks. The adopted build then exceeded it by **2.5×–4.7×**.

Therefore, on my own attribution table: **the reprojection causes the excess penetration.** AC-202 as adopted
is **dead on the evidence**, not merely "unadopted". And **F79 was not pre-existing** — I read the tick-6/7
peaks as spawn-settling and said the shape "argues against the obvious reading". The control arm has the
identical spawn window and shows no such peak, so my reading was wrong: those peaks were the projection
acting on a settling creature. **The control arm is what exposed my error, which is exactly why it was
mandatory.**

**Owner disposition unchanged:** AC-202 stays FAILED for M1; it is revisited in M1.1 after the rectifier fix,
where the question becomes whether a post-contact projection is still needed at all. **Do not re-adopt now.**
