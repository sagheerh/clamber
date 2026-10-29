# M1 completion plan — what is left, in order, and what "done" means

**Written against PR #3 head `5b04cb4`** (draft), reviewer branch `arena/5b72e4ab-clamber`.
Status source of truth: `.review/m1_ac_matrix.md` (enforced by `scripts/check_m1_matrix.py`, currently exit 0).
This document is a work order, not evidence. Nothing in it may be cited as a pass.

---

## 0. The one-sentence answer

The **components** are built and largely verified; the **acceptance harness does not exist**, because not one acceptance gate runs through the public `Sim`. `core/sim/sim.gd` is a **33-line stub**. All 18 runtime gates funnel through `Sim.setup / step / state_hash`, so the milestone is at *engineering ≈70 %, acceptance 0*.

Second sentence, and it matters more: **M1 cannot go green while the creature walks by itself.** `AC-201` asks for "settles and sleeps within 4 s with no input"; the measured zero-input drift of the actuated creature is **3.934 px/s**, and the sleep predicate as specified would *sleep* that creature rather than expose it. Both are fixable, one of them needs an owner decision.

---

## 1. Gate-by-gate state (18 runtime rows, all NOT RUN)

Non-runtime rows already on file and **not** M1 acceptance: `M0 regression` (regression only), `FA-1`/`FA-2`/`FA-7` (analytic only), `A9.1`/`A9.6` (static check only). Do not count them toward 18.

| # | Gate | Exists today | Gap | Pass condition | Evidence required |
|---|---|---|---|---|---|
| 1 | Engine / architecture (M1 runtime) | pinned 4.7.2 CI, M0 514/0, static scans | runtime scan has no `Sim` to scan | real import + M0 unchanged + headless core + scans clean over the wired Sim | CI run + annotation |
| 2 | A9.2 accumulator | `core/sim/accumulator.gd` (106 lines), unit-tested | not used by `Sim` | ≤3 catch-up steps, excess dropped, no raw delta into step math | chunk-equivalence + stall tests through `Sim` |
| 3 | A9.3 injected RNG | none in `Sim` | seed path absent | `seed` via `setup`, xoshiro128** only, same seed ⇒ same stream | same/different-seed test |
| 4 | **AC-201** | free-hinge probe: sleeps at ~1.1 s | **actuated creature slides at 3.934 px/s; sleep predicate unsound (F52)** | no-input settles **and** sleeps ≤4 s, using tuning thresholds | sleep tick + velocities, both presets' creatures |
| 5 | AC-202 | joint length projection exists | no 2-minute run through `Sim` | max abs limb-length error ≤0.05 WU over 7200 ticks | measured max + log |
| 6 | AC-204 | none | soak harness absent | 200 runs, zero non-finite, every run/seed logged, nothing healed or discarded | log artifact |
| 7 | Three presets / §16.1 | 3 preset JSONs, topology + pose verified | identical-input divergence unmeasured; **no captures** | same recorded L/R pattern ⇒ three different motions; 10 s capture each | 3 traces + 3 captures + shared seed/input references |
| 8 | Tick cost / §10.4 | none | 30-body scene + timer absent | solver tick ≤3.0 ms at 30 bodies, constraint count recorded (budget 120) | measured timing + hardware + method |
| 9 | A9.4 replay ×3 | probe-level determinism only | no `Sim` replay | 3 replays exact-matching state hashes | hash table |
| 10 | A9.4 two-second stall | accumulator logic only | no injection through `Sim` | catch-up/drop logged; equal at equal tick counts | stall log |
| 11 | A9.5 two frame conditions | none | delivery-vs-simulation separation unproven | `--fixed-fps 30` vs `144`, identical tick counts, `tick_hz` fixed 60 | protocol + comparison |
| 12 | A9.7 falsification | none | no baseline to flip against | flip exactly one documented input bit at one documented tick ⇒ **different** hash; equal = FAIL | pair of hashes |
| 13 | A9.7 baseline / CI regression | deliberately absent | needs a real hash | committed baseline with fixture identity, hash, tuning fingerprint; CI rejects unexplained change without DECISIONS.md | fixture + CI job |
| 14 | §10.6 repeatability | none | 10000×100 untested; cross-arch untested | 10000 ticks, 100 local repeats identical; 60 s cross-architecture replay; 200-run soak tracked separately | artifacts + runner identities |
| 15 | FA-3 no jitter | pair clearance partially analytic | 600-tick static scene not run | every 2-apart pair `r_A+r_C ≤ 0.22`; **zero sleep-breaking contacts in 600 static ticks** | per-pair table + transition count |
| 16 | FA-4 Slug stands | free-hinge only | actuated case fails today | no-input settle+sleep ≤4 s **and** single L-hold lurches ≈ one body length | both measurements |
| 17 | FA-5 grip band | mechanics + support gate built | 4 branches not run on Hopper | foot <40 % weight **slips**; ≥40 % **grips**; two-foot stance grips; airborne never grips | 4 labelled branches |
| 18 | FA-6 near-miss | none | **no tutorial chunk exists** (`data/towers/` is empty) | 10 identical scripted runs ⇒ **6–8 successes** | 10 run records + chunk fixture |

Supporting counts already real: math 381, contact 237, analytic 136, load 80, mechanics 931, sleep 3659 (**5424** engine checks) + **128** Python controls.

---

## 2. Phases, in order, with exit criteria

**Phase 1 — correctness blockers (small, do first).**
`F52` sleep window (per-tick **and** net-over-dwell, same `0.001 WU`, plus a `5.0e-04 WU/tick` slow-slide fixture that must never sleep) · `F53` rename · `F54` caveat · `F48` per-joint `|q|`/torque table and `physics_passive_stiffness` sweep.
**Exit:** sleep cannot fire on a moving body, proven by a failing-before/passing-after control; sweep numbers on the table; commit pushed.

**Phase 2 — `Sim` wiring (the unlock; biggest single item).**
`setup(seed, tuning)`, `step(input_mask)`, `state_hash()`, snapshot/restore over solver + accumulator + creature + contacts + sleep + motors; `F45` legacy-sleep doc; replay harness; **determinism attempt 1** (`A9.4` ×3, `A9.7` bit-flip).
**Exit:** rows 1, 2, 3, 9, 10, 11, 12, 13 become runnable; attempt count moves 0 → 1 with a real hash; a bit flip demonstrably changes it.

**Phase 3 — creature acceptance.**
`AC-201`, `AC-202`, `FA-4`, `FA-3`, `FA-5`.
**Exit:** rows 4, 5, 15, 16, 17 measured. **This phase cannot pass while the spring drives the creature sideways** — it is gated on the Phase-1 sweep plus the owner's remedy decision.

**Phase 4 — presets, captures, feel, cost.**
Three-preset identical-input divergence + 10 s captures · `FA-6` on a real tutorial chunk · tick cost at 30 bodies · `AC-204` 200-run soak.
**Exit:** rows 6, 7, 8, 18 measured with artifacts.

**Phase 5 — repeatability and closeout.**
`§10.6` 10000×100 + cross-architecture · invariant sweep INV-01..10 · `A5`/`A10` five-fakes · `A12` evidence · `.review/m1_verdict.md` · final PR review.
**Exit:** all 18 rows `PASS` with citations, matrix guard still exit 0, verdict issued, PR merged.

---

## 3. What still needs the owner (and nothing else does)

| ID | Question | Blocks | Why it cannot be decided by the agent |
|---|---|---|---|
| **M1-D05** | After the stiffness sweep: spring targets the settled pose, weaker spring, or no passive spring? | AC-201, FA-4, the 3.934 px/s feel risk, all of Phase 3 | it is a feel/product call, and the numbers are on the table |
| **M1-D06** | FA-6 needs a tutorial chunk; `data/towers/` is empty. Author a minimal chunk fixture in M1, or defer FA-6 to M1.1? | FA-6 only | chunk geometry is content scope, and chunk scale is already flagged as **M1-B04** (7.2 WU width vs 8.0 WU height, both normative) |
| **M1-D07** | Reference-device tick cost: owner runs the build on the phone and reports; M0-D07 waiver does not carry | the "reference device" half of row 8 | hardware only the owner has |

Everything else — F52, F41 bucketing, Sim wiring, replay, AC-201/202/204, FA-3/4/5, soak, §10.6, closeout — needs **no** decision. It needs execution.

---

## 4. Definition of M1 complete

1. All 18 runtime rows read `PASS` with a CI run id or committed artifact.
2. `scripts/check_m1_matrix.py` exits 0 **and** the matrix contains no `NOT RUN`.
3. A committed baseline hash exists and CI rejects an unexplained change.
4. Determinism attempts ≥1 with a recorded outcome; a bit flip demonstrably changes the hash.
5. `.review/m1_verdict.md` issued by review, PR #3 formally reviewed, M0 suite still 514/0.
6. **No waiver, no widened tolerance, no synthetic load, no velocity epsilon.** If a gate cannot pass honestly, it stays red and the reason is recorded.

M1 is **not** complete when the tests are numerous or the CI is green in places. It is complete when the creature stands up by itself, the numbers survive replay, and the feel gates were measured rather than asserted.
