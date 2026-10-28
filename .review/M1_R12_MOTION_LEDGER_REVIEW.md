# M1 — R12 review: F35 measured, and what the sweep actually proves @ `c3b7b01`

**Target:** PR #3 head `c3b7b01` (draft, OPEN). Commits over R11's `3c9f942`: `21a9174` (velocity/position instrumentation), `4697137` (projection sequence + iteration sweep), `c3b7b01` (records).
**CI:** `40700394450` — M0 green, static-subset green, **M1 red**. I read every annotation: the only failing conditions are `foot_load_path_exercised == false` (F30) and the sweep job's exit. All six sweep rows report `all_grounded_force_window_within_literal_tolerance: true`.
**Reviewer branch:** `arena/5b72e4ab-clamber` → this file.

---

## 1. Verdict

**Instrumentation accepted. F36 CLOSED. F37 CLOSED. Nothing was adopted, nothing retuned, nothing overclaimed.**

But the iteration sweep does more than the report claims, and two of its results change the *nature* of F35:

| Item | Status |
|---|---|
| F36 synthetic bad-pose control | **CLOSED** — two-sided, exact gap |
| F37 grip fraction + support share | **CLOSED** — 0/300 and 22.2392538 %, existence vs support separated |
| F35.1 speeds / decay | **verified**, and the decay curve is more informative than reported |
| F35.3 iteration sweep | **verified — and it proves F35 is a model equilibrium, not a solver defect** |
| F35.2 mechanism attribution | **verified per phase**, residual `1.56e-17` WU |
| Tuning / pose / radii / contact / damping | **untouched** (`git diff` empty over all of them) |
| **F38 [MAJOR]** plateau converges to a **non-zero** limit as iterations rise | new |
| **F39 [MAJOR]** lateral creep is displacement **without** velocity — friction cannot remove it | new |
| **F40 [MINOR]** the vertical buzz is a 1.0–1.5 px, 60 Hz bob in feel units | new |
| FA-3/4/5/6, captures, determinism | still `NOT RUN` / **0** |

---

## 2. What I verified independently

- Local Python: `test_review_checks` 19, `test_owner_geometry_source` 5, **`test_load_trace` 34**, `test_static` 6, `test_android_inspection` 8 = **72**, all pass. `check_m1_matrix.py` exit 0.
- `git diff 3c9f942 c3b7b01` over `core/tuning.tres`, `core/tuning.gd`, `data/creatures/`, `core/creature/`, `capsule_contact.gd`, `capsule_body.gd`, `coincident_hinge.gd` → **empty**. The sweep wraps tuning clones (`--iterations=`), and the log marks `configured_resource_value: true` only for `iterations = 6`.
- **F36** is a proper two-sided control, not a one-way assertion: motor raised `+0.1` → flags empty; motor lowered `−0.1` → exactly one flag, `non_foot 1`, `foot 2`, `gap 0.045 ± 1e-12`. A detector that fires on the wrong thing would fail the first half.
- **F37**: `steady_grip_fraction 0.0`, `steady_grip_ticks 0`, `steady_undefined_support_share_ticks 0`, `steady_foot_support_share_mean 0.2223925379546886` → 22.2392538 %. `path_exists_scope` explicitly says "At least one loaded gripping tick only; NOT sustained support or a new acceptance threshold".
- **F35.2** residuals: `max_position_ledger_residual_wu = 1.561e-17`, and the motion parser recomputes each body's `net = completed − start` against the four phase sums, raising on missing/non-finite phases. It also refuses to pretend `integration == completed_velocity·dt` and reports `predictor_minus_completed_velocity_dt_wu` separately — that honesty is what makes the ledger usable.
- The matrix/DECISIONS wording is disciplined: "descriptive plateau-entry tick only, never a rest tolerance", "no new value adopted", "forward measured issue, not a rest/sleep pass".

---

## 3. F38 [MAJOR] — the sweep proves the plateau is an equilibrium of the model

The report reads the sweep as "velocity amplitude essentially unchanged, so iterations are not the lever". Correct — but the six rows contain a stronger result. Taking the converged plateau `P` at each iteration and expressing the excess over the 24-iteration run:

| iterations | `P` (N·s) | excess over iter-24 |
|---:|---|---:|
| 1 | 0.16342298155380441 | `+6.226e-07` |
| 2 | 0.16342250260079949 | `+1.436e-07` |
| 4 | 0.16342238768032116 | `+2.872e-08` |
| 6 | 0.16342237029480580 | `+1.133e-08` |
| 12 | 0.16342236049778977 | `+1.535e-09` |
| 24 | 0.16342235896246843 | `0` |

The excess shrinks roughly 4–5× per doubling and is heading to **zero excess over a non-zero limit**, i.e. `P∞ ≈ 0.1634223589 N·s ≠ 0`. Increasing iterations makes the system *approach* the plateau faster (`first_tick_inside_final_observed_momentum_envelope`: 127 → 77 → 67 → 66 → 65 → 64) but never removes it.

**Therefore F35 is not a convergence defect. It is a property of the modelled system** — gravity + 0.02 damping + 0.02 restitution + position projection + velocity solve. Presenting it as "measured but unfixed, awaiting more iterations" understates what you already have.

The decay curve shows where the value comes from:

| tick | `P_y` (N·s) | max endpoint speed |
|---:|---:|---:|
| 5 | −1.616686 | 2.579 |
| 10 | −0.406611 | 0.707 |
| 30 | +0.178972 | 0.448 |
| 60 | +0.163422 | 0.2019 |
| 120–599 | +0.163422 | 0.2019 |

The creature falls, the contact arrests it hard, momentum overshoots positive at tick 30 and then **freezes** at the overshoot's leftover. Nothing in the loop pulls it back to zero, because damping removes `0.003268 N·s` per tick and the contact resupplies exactly that (the F31 result). So the final value is inherited from the arrest transient.

**That makes one cheap experiment decisive, and it is the only thing I want added before any fix is discussed:** rerun the same 600 ticks from two or three **spawn heights** (e.g. `y = 0.33`, `0.53`, `0.73`) and report the converged `P`. If `P∞` differs per spawn, there is no rest attractor and "settles/sleeps" has no target; if `P∞` is identical, the equilibrium is well-defined and the owner is choosing whether to accept 0.105 WU/s as rest or to change the model. Either answer is actionable; guessing is not.

**Consequence the owner must decide, independent of F30:** FA-4 ("settles/sleeps within 4 s") needs a definition of *asleep*. A velocity-keyed predicate cannot fire on a 0.2 WU/s floor that the model will never remove. Options, for the record, are a **positional** stillness predicate (Y positions are already static to `1e-16`), a velocity threshold **above** the floor (a new constant, owner-authored), or a **model** change (which is a solver-design decision, not a tuning tweak). Do not pick one in code.

---

## 4. F39 [MAJOR] — the lateral creep is displacement without velocity, so friction can never touch it

Every endpoint moves by the **same** X amount each tick:

| part | `net_delta_wu` = [a.x, a.y, b.x, b.y] |
|---|---|
| head | `[−7.175187723404419e-06, 5.27e-16, −7.175187723418297e-06, −6.94e-17]` |
| motor | `[−7.175187723418297e-06, 3.33e-16, −7.175187723418297e-06, −1.80e-16]` |
| foot | `[−7.175187723418297e-06, 2.78e-17, −7.175187723529319e-06, −2.46e-16]` |

All six X values agree to 11 digits and all six Y values are `~1e-16`. That is a **rigid body translation in X with zero rotation and zero vertical net motion**, every tick.

Compare it to the velocity the same bodies report: head `a` ends the tick at `v_x·dt = −4.03e-07` WU, while the position moved `−7.175e-06` WU — **18× more displacement than its own velocity implies**. So the creep is injected by the **position-projection sequence**, not by integrated velocity.

Two consequences:

1. **Friction is structurally blind to it.** `physics_static_slip_wu_s = 0.15` zeroes tangential velocity below 0.15 WU/s; the observed X velocity is `2.4e-05`–`2.8e-03` WU/s, more than 50× under that threshold, and the contact normal is `(0,1)` so its position projection contributes exactly `0.0` to X. Nothing that acts on velocity can remove a displacement that has no velocity. This cannot be fixed by μ, by static slip, by grip, or by `foot_grip_bias`.
2. **It is unbounded, and it is also converged.** The sweep shows `−7.145e-06` at 1 iteration rising monotonically to `−7.176e-06` at 24 — so more iterations do not shrink it either; like F38 it is a property of the scheme (a Gauss-Seidel ordering bias in a chain with **no root anchor**, so X translation is a zero-energy mode).

Scale, in the units that matter:

| window | creep | at 150 px/WU |
|---|---|---|
| 600 ticks (FA-3) | 0.0043 WU | **0.65 px** |
| 3600 ticks (60 s) | 0.0258 WU | 3.87 px |
| 10000 ticks (§10.6 scenario) | 0.0718 WU | **10.76 px** |
| 18000 ticks (5 min) | 0.1292 WU | 19.37 px |

So: **not** an FA-3 blocker, **is** a §10.6/soak finding, and it is the kind of thing that shows up later as "the creature slowly slides off the tower" with nobody able to point at a cause. Record it now with these numbers.

---

## 5. F40 [MINOR] — the buzz is ~1 px at 60 Hz, which is a feel number

The phase ledger says: prediction moves the motor's endpoints down `0.006512 / 0.006259` WU, contact projection lifts them `0.006567 / 0.010178` WU, net Y `≈1e-16`. At `feel_readability_px_per_wu = 150`, that is a per-tick bob of **0.94–1.53 px at 60 Hz**.

That is why "bottoms repeat" while velocities are 0.2 WU/s — the creature is vibrating in place, not standing still. For a project whose stated product is `GDD :654` "the feel is the product", a ~1 px 60 Hz shimmer on a supposedly static scene is a feel-relevant measurement, not only a solver curiosity, and it is the same phenomenon FA-3's "zero sleep-breaking contacts" is trying to get at. Worth one line in the matrix row so the two symptoms are not investigated twice.

---

## 6. What is now settled, and what is left

**Settled and independently verified:** load producer, force conservation, momentum ledger (F22/F23/F25/F31), F36, F37. The Slug's foot carries ~9.7 N of 43.4 N because in every shipped preset the feet are not the lowest bodies (F30) — grip never engaged, peak applied 14.807 N against the 17.36 N gate.

**Open, in priority order:** F30 owner pose decision (the only red) → F38 spawn-sensitivity experiment + the owner's definition of "asleep" → F39 recorded as a soak finding with the numbers above. Then, and only then, FA-5's band.

FA-3 / FA-4 / FA-5 / FA-6, AC-201/202/204, A9, §10.6 and every capture stay `NOT RUN`. Complete-creature determinism attempts: **0**.
