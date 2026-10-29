# M1 — owner decisions D09 / D08 / D06, taken under delegated authority

**Authority:** the owner delegated these three choices explicitly ("in mai sy best option select kro… full authority"). The reviewer therefore records them as **owner decisions taken on delegation**, not as reviewer preferences. Recorded here, in this order, before any code changes.

**Decided:** D09 = **proportional muscle, re-scaled** · D08 = **physical hold first, freeze only as a fallback** · D06 = **author the minimal chunk fixture now**.

Reasoning for each is below, and every acceptance number is **derived from a constant that already exists** — none of them is a new feel value invented by me.

---

## D09 — proportional muscle, re-scaled so the motor can actually hold the creature

**Why this and not "document what exists".** The product is a climbing game whose entire personality is the *gait*: a lurch on L, a lurch on R, and a silhouette at rest that reads as a creature. Today:

- the drive is clamp-limited in **every** arm — 472× over at bound 6.0, 3080× over at bound 1.0, saturated 300/300 — so `motors_gain`, the one dial a designer would reach for, **does nothing**;
- the creature hangs **8.5° past its own authored +40° stop** (48.07–48.59° measured), and **89.6°** with nothing holding it, so the authored pose is not the pose on screen;
- the stop, not the muscle, is what holds the body up.

That is not a tuning problem, it is an architecture that cannot be tuned — and a game you cannot tune the feel of cannot become viral, it can only be copied. Documenting "the motor is bang-bang" would make the numbers honest and the product unworkable. So: **re-scale.**

**The criterion, derived not invented.** The motor must operate in its linear range at the working pose:

> `requested_impulse ≤ 0.5 × bound` for the **holding** torque at the settled pose, on every actuated arm.

The holding torque is measurable — today the clamp is what balances gravity at `q = 0.84 rad`, so the gravitational demand at that pose is ≈ the 2.67 N·m the clamp delivers. A proportional motor must therefore be able to supply ~3 N·m **without** clamping, and enough headroom above it that the lurch is still a lurch.

**Example triple to investigate, explicitly NOT adopted.** Presented so the agent has a starting point to *test*, not to apply:

| constant | now | example | reason |
|---|---:|---:|---|
| `physics_max_constraint_angular_impulse_rad_s` | 6.0 | **30** | `30/135 × 60 = 13.3 N·m` deliverable, ~4× the gravitational demand |
| `motors_joint_stiffness` | 2400 | **40** | `40 × 0.08 rad = 3.2 N·m` at a 4.6° residual — linear, not clamped |
| `motors_max_torque` | 1800 | **12** | real cap above the holding torque, so the cap finally binds instead of the bound |
| `motors_joint_damping` | 55 | **re-derive** | must be **critically damped for the new stiffness**; leaving 55 with stiffness 40 would be wildly over-damped. Derive, report the formula, do not guess |

**Required order inside this increment:** parametric study of **at least three** candidate triples → report settled pose, holding residual, drift (all four arms), and lurch response for each → **stop and report before adopting**, because a 1000× stiffness change is a physics re-scale and I will not accept the first triple that looks nice. Then: adopt, regenerate the baseline **with provenance**, re-measure the four arms, and record that the R23 2×2 describes the **old** parameterisation and is retained as history.

**Total mass and weight are untouched.** If the pose still cannot be held at a sane residual, that is evidence the *pose or the mass* is wrong (D08-c territory), and we come back — not a signal to raise the bound again.

---

## D08 — physical hold first; a freeze only if the physics cannot hold

`AC-201` needs a number, and it already has one, hidden in the sleep predicate we shipped in R15/R17:

> `sleep_still_displacement_wu = 0.001` per tick **and** net over `sleep_dwell_ticks = 30`.
> `0.001 / 30 = 3.333e-5` WU/tick = `0.005` px/tick = **0.3 px/s**.

So **AC-201 passes iff the F52 sleep predicate fires within 4 s**, and that requires zero-input drift **≤ 0.3 px/s**. No new value is introduced; the gate becomes quantitative using a constant the owner already approved.

Against that line:

| configuration | drift | vs the 0.3 px/s line |
|---|---:|---:|
| free-hinge floor | 0.084 | **passes** (3.6× margin) |
| drive only | 2.95 | 9.8× over |
| stop only | 5.39 | 18.0× over |
| both (today) | 3.93 | 13.1× over |

**Decision: fix the muscle and re-measure; do not freeze the creature.** A "hold" that freezes the joint row on release is a pause dressed as physics — for a climbing game it would read as the creature going rigid, and it would hide the sag rather than fix it. D09 should remove the *cause*: no sag past the stop means no stop projection, and a linear motor at its target means a small residual impulse instead of a permanently saturated one.

**The fallback is defined, so we do not relitigate it later:** if, after the D09 re-scale and a full four-arm re-measure, zero-input drift is **still above 0.3 px/s**, then and only then add the release-hold — and it must be a **visible mechanical state** (the creature visibly clamps, with its own input-released presentation), not a silent freeze, because a silent freeze would make AC-201 true by lying.

**If drift lands between 0.084 and 0.3** (passed, but only just), record the margin explicitly and treat it as a feel risk for FA-4, not as a pass to be celebrated.

---

## D06 — author the minimal chunk fixture now

`FA-6` is the only gate in the entire milestone that measures whether the game is **fun**: 10 identical scripted runs on the tutorial chunk, **6–8 successes**; 10/10 is a copycat, ≤4/10 is frustrating. Deferring it means M1 closes at 17/18 with every number measured **except the one that decides whether the product is worth building**. That is the wrong thing to leave out.

So: author a **minimal FA-6 fixture** — a floor, one ledge, one spawn pad, one scripted input, ten runs — and record it as **provisional test geometry, not product content**, explicitly subject to M1-B04 (7.2 WU width vs 8.0 WU height). FA-6's *number* (6–8/10) is the owner's and does not change; only the fixture layout is provisional, and if B04 resolves differently the fixture is re-laid and FA-6 re-run.

**Not** in scope: chunk generation, difficulty curve, level design. One fixture, ten runs, one number.

---

## D07 — unchanged, and it is the one thing the delegation cannot cover

Reference-device tick cost needs the phone. It stays queued until the owner runs the build; M0-D07's waiver does not carry into M1.

---

## What this unblocks, in order

1. **D09 increment** — parametric study → report → adopt → baseline regeneration with provenance → all four arms re-measured. *(This is the only step that can change physics numbers, and it stops for review mid-way.)*
2. **D08 check** — re-measure against the **0.3 px/s** line. Pass ⇒ no hold. Fail ⇒ visible release-hold, then re-measure.
3. **Phase 3** — AC-201, AC-202, FA-3, FA-4, FA-5. *(AC-202 and FA-5 were already independent of these decisions and may run in parallel from step 1, with separate evidence.)*
4. **Phase 4** — three presets + captures, FA-6 on the D06 fixture, tick cost, AC-204 soak.
5. **Phase 5** — §10.6, invariants, A5/A10/A12, `m1_verdict`, merge.

**Standing prohibitions unchanged:** no velocity epsilon, no widened tolerance, no synthetic qualifying loads, no silent AC-201 rewrite, no waiver, no M2, no camera, no captures before Phase 4. Every number above that is not derived from an existing constant is marked as a proposal requiring measurement.
