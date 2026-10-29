# M1 — R14 review: F41 confirmed on evidence, F42 answered by data @ `75df486`

**Target:** PR #3 head `75df486` (draft, OPEN). Commits over R13's `d36c89f`: `de26fa3` (contact-sample observer + slip sweep), `5c1bffe` (multi-sample evidence), `75df486` (byte-level non-interference + raw grounding).
**CI:** `40803064849` — M0 green, **M1 red for F30 only**; both slip cases `OBSERVED`, baseline load probe fails as expected.
**Reviewer branch:** `arena/5b72e4ab-clamber` → this file.

---

## 1. Verdict

**F41 is answered, and the answer is the one I hypothesised — now on evidence rather than inference. F42 is answered by measurement too: under the transition-only reading there are zero violations in the steady window, so the criterion does not need a new constant.**

| Item | Status |
|---|---|
| Observer is genuinely read-only | **verified** — 600/600 identical snapshots with observer on/off |
| Python suites | **91 = 19+13+40+5+6+8**, reproduced locally |
| F41 mechanism | **confirmed**: `retained = 0` while endpoint velocity survives; later samples move earlier ones off zero |
| Static slip is *not* the mechanism | **confirmed**: 1.5 vs 0.15 changes transients by 0.0145 WU/s, late drift by **3.98e-17** |
| F42 | **answered**: steady `new_grounded_transition_count = 0`, `grounded_sets = [[0,1,2]]` |
| Physics / pose / radii / data | **untouched** (`capsule_contact.gd` change is an optional `Callable` observer, default invalid) |
| **F41b [new]** active sample count changes between passes (foot 3 → 2) | new, needs one answer |
| F30 pose, asleep definition | still the only blockers |

---

## 2. What I verified

- `capsule_contact.gd` diff is an **optional `observer: Callable = Callable()`** threaded through `resolve` → `resolve_tick` → `_response`, with a detached `_observation()` that reads state and returns a Dictionary. Nothing is fed back: the call site only assigns to `observation.*` and calls `observer.call(...)`.
- Non-interference is proven the right way: `observer_on_off_equal_ticks: 600` in both cases, i.e. serialised physical snapshots are byte-identical with the observer enabled and disabled. That is stronger than "we only added prints".
- F41 evidence, per body at tick 599 (baseline, `static_slip = 0.15`):

| body | `zero_retained_with_surviving_endpoint_count` | `earlier_static_sample_changed_by_later_samples_count` | max `tangent_at_body_end` after static response |
|---|---:|---:|---:|
| head | 1800 | 1200 | 0.000590 WU/s |
| motor | 1800 | 1200 | 0.002798 WU/s |
| foot | 1369 | 600 | 0.003544 WU/s |

  The mechanism is now demonstrated sample by sample. For the motor's final pass: sample `u=0` zeroes its own tangent, then sample `u=0.5` writes `avx −0.00279837 / bvx +0.00279837`, and sample `u=2` leaves `avx` at exactly that value. **Each sample reaches its own zero target; the set of overlapping samples does not jointly reach zero.** That is the residual, and 1800/1800 endpoint survivals per body is not a rounding effect.
- The threshold sweep settles the question I asked: `max_abs_com_vx_difference_last300 = 3.98e-17` between `0.15` and `1.5`, while `max_abs_com_vx_difference_all600 = 0.0145`. So `physics_static_slip_wu_s` changes the transient and provably not the steady drift. **Static slip is eliminated as the cause**, and no value was adopted.
- COM bookkeeping still closes: `steady_mean_com_dx_wu_tick = −7.175187723414263e-06` against `steady_mean_integration_com_dx_wu_tick = −7.175187723396494e-06` — 1.8e-17.
- F42: `grounded_transition_ticks = [{tick 0, new [1,2]}, {tick 7, new [0]}]`, `steady_new_grounded_transition_count = 0`, `steady_grounded_sets = [[0,1,2]]`, `steady_ticks_with_any_active_sample = 300`. Reported without adopting an interpretation.

---

## 3. F41b [MINOR, but ask before the pose change] — the contact set is not pass-stable

The foot shows `active_counts [2, 3]` with `per_pass {0: 3, 1: 2}` — the *number of active samples changes between velocity passes within the same tick*. Head and motor hold at 3/3. Sample counts are therefore not a pure function of geometry, or something in the pass sequence perturbs them.

Why it matters, and why now: if the active sample count is velocity-dependent, the system has a **feedback path** — more motion produces more samples, more samples recreate more motion — which is one candidate explanation for a drift that stays constant to `1e-16` instead of decaying. I am not asserting that; I am saying it should be settled **before** the pose change, because the pose change alters contact geometry from a 0.095 WU motor belly to a 0.050 WU foot pad and will perturb exactly this quantity.

Ask: explain why `candidate_counts` differs between passes for the foot, and whether the count is invariant to endpoint velocity. One paragraph plus one trace line is enough.

---

## 4. What this changes about F41's future

Do not fix it now, and this is the substantive point: after F30 lands, the geometry inverts. Today **three bodies** are grounded and produce 17 samples per tick (motor belly 0.095 WU, head 0.095 WU, foot pad). After the pose fix the creature rests on a **0.050 WU foot pad** with the motor and head above the ground, so the sample set collapses to the foot's ~2 samples and the whole 17-sample overlap vanishes.

So there are two informative outcomes and one uninformative one:

- post-pose drift **smaller** → the overlap was the pump, as suspected, and F41 is downgraded to "pose artefact";
- post-pose drift **equal to `1e-16`** → the mechanism moved with the contact, and the residual is a genuine sampling limitation that needs an owner decision later;
- post-pose drift **identical to `−7.1752e-06`** with a completely different contact geometry → suspicious, stop and re-derive.

Report whichever it is; do not tune toward the first.

---

## 5. M1 remaining, in the terms the owner asked for

**Done and verified:** review infrastructure; math foundations (381); owner geometry D04 (131); production presets + creature model; SDF + swept contact (237); force-channel split; coupled load producer + conservation + momentum ledger (F22/F23/F25/F31/F38/F40/F41/F42 measured); telemetry (F36/F37).

**Blocked on the owner — two decisions, nothing else on the critical path:** F30 pose (with the TwinRoller foot-5 exception) and the definition of "asleep" (with FA-3's sleep-breaking wording).

**Then, still to build:** pose commit + hard F36 assertion; sleep implementation; **motors**; angular limits; self-contact; public `Sim` (still a 33-line stub); F41 re-measure.

**Then, still to evidence:** FA-3 / FA-4 / FA-5 / FA-6, AC-201/202/204, A9 (replay ×3, baseline, bit-flip, soak, two-frame, two-second), §10.6, tick cost, captures.

**Acceptance gates passed: 0 of 21.** Analytic-only passes: FA-1/2/7. Complete-creature determinism attempts: **0**.

---

## 6. Boundary

91 Python tests, 381 math, 237 contact, 131 analytic and 80 load-path checks are **components**. They are not determinism, not stance, not acceptance. Every runtime gate stays `NOT RUN` until the traces exist.
