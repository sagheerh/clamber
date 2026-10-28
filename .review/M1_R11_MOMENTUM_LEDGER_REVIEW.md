# M1 — R11 review: conservation closed, F30 still the only red @ `3c9f942`

**Target:** PR #3 head `3c9f942` (draft, OPEN). Commits over R10's `1f2c19f`: `bc4202a` (bottoms + momentum ledger), `ad9e5d0` (bias explanation), `be04bbf` (annotation budgeting), `3c9f942` (records).
**CI:** `40695859755` — M0 green, static-subset green, **M1 red**. I read every annotation: the red is `foot_load_path_exercised == false` (F30) and nothing else.
**Reviewer branch:** `arena/5b72e4ab-clamber` → this file.

---

## 1. Verdict

**F31 CLOSED — the +0.196 N is genuinely explained, and I re-derived it myself rather than accepting it.** The conservation criterion is now the correct one and passes. The only red is F30, and the exit expression proves the separation. Nothing was retuned, nothing was waived, and no runtime row moved.

| Item | Status |
|---|---|
| F31 — unexplained +0.196 N bias | **CLOSED**, independently reconstructed |
| All-grounded conservation (`43.4 ± 0.723`) | **passes**; applied sum equals 43.4 to `7.1e-15` |
| R9 foot-only criterion | correctly superseded, recorded as owner correction |
| F30 pose blocker | **OPEN — red check**, correctly not waived |
| Reporting honesty ("grip never engaged", all-600 peaks) | **fixed as asked** |
| Tuning / pose / radii / contact code | **untouched** (`git diff` empty) |
| **New:** resting state is a limit cycle, not a fixed point | **F35 [MAJOR forward]** |
| **New:** bottom audit prints but does not assert | **F36 [MINOR]** |
| FA-3/4/5/6, captures, determinism | still `NOT RUN` / **0** |

---

## 2. F31 — verified closed, by my own arithmetic

I reconstructed the momentum from the trace's own per-endpoint velocities at tick 599, using endpoint mass = part mass / 2:

| Body | mass | v_a | v_b | contribution |
|---|---|---|---|---|
| foot | 0.3 | 0.0929998144282119 | 0.006612313610152515 | 0.01494181920575466 |
| head | 0.77 | 0.20190438947560638 | 0.077483849085075 | 0.10756447184586235 |
| motor | 0.48 | 0.077483849085075 | 0.0929998144282119 | 0.04091607924318885 |

`Σ m·v = 0.16342237029480586` against the reported `0.16342237029480583` — agreement to **3e-17**. Then `0.02 × 0.16342237029480586 = 0.0032684474058961173`, and `× 60 = 0.19610684435376705` against the observed support bias `0.19610684435377124` — agreement to **4e-15**. And the third independent number: the **applied** load sum equals 43.4 to `7.1e-15`, while the **measured** reaction exceeds it by exactly the damping term. Three channels, one explanation, no fitting.

The anti-circularity design is the part I want to credit explicitly, because it is the discipline this project has been missing at times:

- the parser **reconstructs** `momentum_before/after` from the raw endpoint velocities, so a claimed momentum is not trusted (`test_endpoint_momentum_independently_reconstructed`);
- `damping_impulse` must equal `−0.02 × measured_before_momentum` using the tuning resource, so "damping explains it" is checked against the actual pre-tick momentum, not asserted;
- `contact_reported` must equal the sum of per-body reactions, and `contact_velocity_impulse` must equal the momentum delta across the contact step — they agree to `5.5e-16`;
- `test_synthetic_damping_bias_identity_not_physics_evidence` and `test_damping_claim_checked_against_raw_start_momentum_and_resource` both construct a ledger where **the algebra balances but the physics is fake**, and both are correctly rejected. That is the five-fakes discipline applied to the agent's own explanation.

The clamp term is also a real measurement, not a structural zero: `before_clamp` is captured, `_clamp_velocity` is called, and the delta is booked (lines 177–180). "Clamp contributes zero" is therefore evidence, not tautology.

Nothing was quietly changed to make this pass: `git diff 1f2c19f 3c9f942` over `core/tuning.*`, `data/creatures/`, `core/creature/`, `core/sim/capsule_contact.gd`, `core/sim/capsule_body.gd` is **empty**. Local Python is **63** (19 + 5 + 25 + 6 + 8), matrix guard exit 0, and the seven original parser tests are intact (the fixture was enriched, not weakened).

---

## 3. F35 [MAJOR, forward] — the accepted explanation proves the resting state is a limit cycle

The same ledger that closes F31 says something the report does not: **the creature never comes to rest.**

- `momentum_after_y_ns` ranges `[0.1634223702948058, 0.16342237029480586]` across the last 300 ticks — constant to **1e-16**, i.e. not decaying.
- At tick 599 **all six endpoints are moving upward**: foot 0.0930 / 0.0066, head 0.2019 / 0.0775, motor 0.0775 / 0.0930 WU/s.
- Net `P = 0.1634 N·s` over 1.55 kg is an average **0.105 WU/s upward**; left to integrate that is **1.05 WU in 10 s**.
- Yet every `bottom_wu` is identical at tick 0 and tick 599 (`−0.02`).

So velocities persist at ~0.1 WU/s while positions do not move, and 2 % damping dissipates `0.0033 N·s` every tick that the contact must resupply forever. That is a pump loop with a fixed point of non-zero velocity — not a rest state. Today it is invisible because `sleep_implemented = false` and `sleep_state` is a string.

Why this matters now rather than later:

1. **FA-3 requires "600 static ticks, zero sleep-breaking contacts", and FA-4 requires the Slug to settle/sleep within 4 s.** Any velocity-keyed sleep can never fire on this state. The gate would fail for a reason nobody would look for while staring at grip numbers.
2. **The +0.196 N is a permanent 0.45 % tax on the support sum.** Conservation passing at that amplitude partly measures the pump, not the load. Fine while tolerance is 1.67 %; fatal to reasoning once FA-5 wants 40 % band edges.
3. **Motors will act on a live velocity field** rather than on a settled body, so the lurch/one-body-length behaviour will be measured on top of ~0.1 WU/s of pre-existing creep.

**Do not fix this with damping.** `physics_linear_damping = 0.02` is a pinned value and the +0.196 N would simply move. What I want measured first, in the trace, with no behavioural change:

- per-body `|v|` every tick, and the decay profile from tick 0 (when did `P` stop changing?);
- the position-vs-velocity reconciliation: positions integrate `p += v·dt` and are static while `v > 0`, so something cancels roughly `0.0018–0.0034 WU` per tick. The trace cannot currently say whether that is the distance rows, the hinge rows or the contact position projection. **Report which**, per part, per tick.
- the amplitude of the velocity field as a function of `physics_position_iterations` — a *diagnostic sweep only*, reported, not adopted. If the creep shrinks as iterations rise, the pump is the projection sequence and the fix is a solver-design decision for the owner.

Framing for the record: **F31 asked "why is the sum 0.196 too big"; the answer is "because the body never stops moving". That closes the arithmetic and opens the behaviour.**

---

## 4. F36 [MINOR] — the preset-bottom audit detects the F30 defect but cannot fail on it

`tests/feel/test_owner_geometry.gd` builds the correct table (all three presets, every part, authored pose) and prints `non_foot_below_foot` with exact gaps. But the only assertion is `_check(bottoms.size() == 3, ...)` — a non-vacuity check. The flags are **printed, never asserted**, so after the pose fix a regression that reintroduces "motor 0.045 WU below the foot" would leave the geometry job green. Also, there is no synthetic bad pose proving the detector fires.

Ask:

1. add a fixture with a deliberately lowered motor and assert the audit **flags it** (proves the detector works);
2. convert the flags to a hard assertion in the commit that lands the pose decision — consistent with the probe, which stays red for exactly this defect.

For the record, the audit output reproduces my R10 arithmetic exactly: Slug `0.045`, Hopper `0.015 ×4` (both feet, both limbs), and TwinRoller `0.045`, `0.05`, `0.335`, `0.345`, `0.645`. TwinRoller's foot 5 has **five** bodies below it — it is a tail with grip eligibility.

---

## 5. F37 [MINOR] — "path exists" is one gripping tick away from green

`foot_load_path_exercised = bool(loaded_grip)`. Because grip requires `applied_load_n ≥ 17.36 N`, this is a decent operational proxy, but it means **a single gripping tick in 600 flips the whole F30 gate green** while the creature may still be standing on its motor 99 % of the time.

Ask (reporting only — no new threshold from me): also emit, for the steady window, the **fraction of ticks with grip** and the **foot's share of total support** (`foot / all grounded`). Then "the path exists" is visibly distinct from "the path carries the creature", and FA-5's band has the numbers it needs.

---

## 6. Current state, stated plainly

- Producer and conservation: **done and independently verified**. F22 / F23 / F25 / F31 closed.
- Grip on a shipped creature: **never engaged** in 600 ticks. Peak applied 14.80726 N, peak measured 14.81107 N, both below the unchanged 17.36 N gate. Red check correctly stays red.
- Cause: **F30 authored pose** — in all three presets the feet are not the lowest bodies. Owner decision pending.
- New behaviour risk: **F35** — the resting state retains 0.1 WU/s of upward velocity; FA-3 / FA-4 sleep is unreachable until that is understood.
- FA-3/4/5/6, AC-201/202/204, A9, §10.6, captures: `NOT RUN`. Complete-creature determinism attempts: **0**.
