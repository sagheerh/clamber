# M1 — owner decision sheet: two forks, and M1 cannot advance past them

**Status:** PR #3 head `d76b88e`, 8/18 runtime rows measured, investigation closed (R19–R23).
**Answer format:** one line per decision, e.g. `D09 = proportional, D08 = hold`. Nothing else is blocked on you.

---

## Why this is now a decision and not a test

Five rounds of measurement produced one causal statement (`.review/M1_R23_CAUSAL_CLOSURE_REVIEW.md` §3):

> The Slug drifts at zero input because of **two mechanisms, each sufficient, neither necessary**: a saturated angular joint impulse, and per-tick stop projection from a gravity sag that sits past the authored 40° limit. Removing both restores the free-hinge floor **exactly** (0.08404 px/s, Δ1.1e-14). Removing either alone leaves 35–64× that floor. Together they **interfere partially**: the full ordering is **2.95 < 3.93 < 5.39**, so the combined case is 27 % below stop-only but 33 % **above** drive-only. It is not below both.

No torque coefficient moves that. There is no seventh experiment worth running. The remaining choices are **what the creature should be**, which is yours.

---

## D09 — motor authority *(decide first; it sets the numbers for D08)*

**Measured.** The drive is clamped by `physics_max_constraint_angular_impulse_rad_s / weight` in **every** arm: requested −21.0 against a bound of 0.0412 is **472×** over at bound 6.0, and **3080×** over at bound 1.0. Saturated **300/300** everywhere. So:

- effective motor strength = `bound × 60 ≈ 2.67 N·m`, a **global solver constant** shared by every creature and every joint;
- `motors_joint_stiffness` (2400), `motors_joint_damping` (55), `motors_max_torque` (1800) and `motors_gain` (0.7) **never bind** — gain is a dead dial except at exactly 0, where it removes the actuator entirely;
- the resting sag demands `2400 × 0.84 ≈ 2022 N·m`, which no plausible bound supplies.

Two coherent designs follow. Both are legitimate; they feel different.

| | **D09-a — bang-bang muscle (accept what exists)** | **D09-b — proportional muscle (re-scale)** |
|---|---|---|
| what changes | nothing physical. Document that the motor is a fixed-strength bang-bang actuator; derive/name the one effective number (`≈2.67 N·m`) from tuning and retire the misleading 1800/2400 as "cap, not strength" | lower `motors_max_torque` and `motors_joint_stiffness` until the request sits **inside** the bound (roughly `max_torque·gain < 2.67 N·m` and `stiffness < 2.1 N·m/rad`), so `gain` and `contraction` become real feel dials |
| feel | one strength, on/off; gain useless; contraction still shapes the target pose | gain becomes a smooth strength dial; contraction shapes both pose and effort; the lurch becomes authorable |
| cost | **≈0** — documentation only | **1 increment** + baseline regeneration + re-measure the four arms; all drift numbers change |
| risk | every creature has identical motor strength; tuning knobs lie to future work | a 1000× stiffness change is a physics re-scale and needs its own review |
| effect on drift | none — numbers stay as measured | unknown; must be re-measured before D08's numbers are frozen |

**My recommendation: D09-b.** The product goal is a viral game whose feel is *tuned*, and right now the strongest feel dial in the game (gain) does nothing. That is a bigger problem than the drift.

---

## D08 — station-keeping, stop band, and what AC-201 means

**Measured, all four configurations** (last-300 drift at 150 px/WU):

| | stop engaged | stop not engaged |
|---|---:|---:|
| drive applied | 3.9345 | 2.9500 |
| drive zero | 5.3874 | **0.08404** (= floor) |

AC-201 asks: *no input ⇒ settles and sleeps within 4 s*. At 3.9 px/s that is **15.7 px of travel per 4 s window**, and the creature never sleeps (max dwell 2 ticks). The options:

| | **D08-a — explicit release-hold** | **D08-b — widen the stop** | **D08-c — reshape pose/mass** | **D08-d — accept the creep** |
|---|---|---|---|---|
| what it does | on input release, freeze the joint row and stop projection (a designed "hold" state) so the creature parks | `motors_limit_max_deg` 40 → ~100 | change authored pose or mass so the sag is legal | keep physics; **you** author AC-201's number |
| measured outcome | drift → 0 by construction; sleep works again | **2.95 px/s measured — still 35× the floor**, AC-201 still fails | removes at most **25 %** (the stop-vs-band difference); drive stays saturated | AC-201 becomes "no net displacement over *N* seconds", N your number |
| cost | 1 increment + a design mechanic + sleep re-scope | ~0 code, but **does not work** | 1 increment, feel/preset change, still fails | ~0 code; AC-201 text amended **by you**, plus sleep predicate re-scoped for a cruising limit cycle |
| risk | a "hold" is a game mechanic, not a physics fix — it must be visible to the player, or it is a lie | wasted increment; the 90° run also had only **0.44° of headroom**, so a real fix would need ~100° | large feel change for a 25 % gain | idle creatures crawl; AFK parking becomes impossible |

**My recommendation: D08-a, with D08-d's number written down as well.** A designed hold is the only option that makes AC-201 true *and* keeps the authored 40° limit, which is the pose the whole silhouette was built around. Accept the creep only if you decide idling drift is part of the game's character.

**Whichever you pick, I will not accept:** a widened tolerance, a velocity epsilon, a silent rewrite of AC-201, or a "hold" that is really the sleep predicate in disguise. If AC-201's text changes, it changes in `DECISIONS.md` under your name with the number and the reason.

---

## Still queued, unchanged, and not blocking the two above

- **D06 — FA-6 tutorial chunk.** `data/towers/` is empty. Author a minimal chunk fixture in M1, or defer FA-6 to M1.1. (Chunk scale is also flagged as M1-B04: 7.2 WU width vs 8.0 WU height, both normative.)
- **D07 — reference-device tick cost.** Only you have the phone. M0-D07's waiver does not carry into M1.

---

## What happens after your two answers

| phase | what runs | rows that can move |
|---|---|---|
| **D09 increment** | re-scale (b) or document (a), regenerate baseline with provenance, re-measure the four arms | none — protects the numbers everything else depends on |
| **D08 increment** | hold mechanic or amended AC-201 + sleep re-scope | **AC-201**, and unblocks **FA-4** |
| **Phase 3** | AC-201, AC-202 (≤0.05 WU stretch, 7200 ticks), FA-3 (600 static ticks, zero sleep-breaking contacts), FA-4 (settle + one-body-length lurch), FA-5 (four grip branches on Hopper) | **+5 rows** → 13/18 |
| **Phase 4** | three-preset divergence + 10 s captures, FA-6 (10 runs, 6–8 successes), tick cost at 30 bodies, AC-204 200-run soak | **+4 rows** → 17/18 |
| **Phase 5** | §10.6 (10000 ticks × 100 repeats + cross-architecture), INV-01..10 sweep, A5/A10 five-fakes, A12 evidence, `m1_verdict`, final PR review | **+1 row** → **18/18**, M1 complete |

Two of the ten remaining rows — **AC-202 and FA-5** — do not depend on either decision and can be built the moment you say go, in parallel with the D09 increment.

**Determinism:** attempt 1 is a same-build observation, accepted. Cross-architecture attempts remain **0** and come with §10.6 in Phase 5. Components are not determinism.
