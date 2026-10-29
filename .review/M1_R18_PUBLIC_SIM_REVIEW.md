# M1 — R18 review: Phase 1 + Phase 2 accepted, 8/18 measured; my F48 sweep asked the wrong knob

**Target:** PR #3 head `9a4380c` (draft, OPEN), 35 files +2858/−44 over `5b04cb4`.
**CI:** `40819475508` M1 — the only failing job is *M1 point/link unit tests* at step *Hinged Slug600 load diagnostic* (the sustained-support gate); **the public-Sim job passes**. `40819475501` M0 **516/0** + Android pass. `40816607995` Phase 1, `40818428101` first public-Sim job.
**Reviewer branch:** `arena/5b72e4ab-clamber` → this file.

---

## 1. Verdict

**Phase 1 and Phase 2 are accepted. 8 of 18 runtime rows are now genuinely measured, and the milestone is red for the right reason.** Two of my own instructions were wrong and the agent caught one of them; the other has now to be fixed before any remedy is applied.

| Item | Status |
|---|---|
| F52 sleep window | **CLOSED** — both fixtures behave, and it composes with a live spring without parking it |
| F53 / F54 | **CLOSED** |
| F48 "sweep" | **VACUOUS — my error.** `physics_passive_stiffness` 900 vs 0 is a no-op on the Slug |
| F48 mechanism | **magnitude proven by arithmetic**, causality not yet measured |
| Phase 2 public Sim | **ACCEPTED** — attempt 1 real, baseline committed, bit flip physical |
| 8/18 rows | **verified row-by-row** against the matrix |
| **F55** drift inside the static-slip allowance | new (explains why no solver bug is needed) |
| **F56** COM momentum identity | new — **must run before the remedy** |
| F57 RNG carried but not consumed | nit |
| Remaining 10 rows | `NOT RUN`, correctly |

---

## 2. Phase 1 — verified

**F52.** The predicate now requires both:

```gdscript
if input_mask != released or maximum >= sleep_still_displacement_wu or net >= sleep_still_displacement_wu:
    still_ticks = 0; _dwell_start = []
```

with `_dwell_start` captured at `still_ticks == 0` and carried through snapshot/restore, corrupt origins rejected atomically. Fixtures behave exactly as required:

| fixture | per-tick | net/30 | old | new |
|---|---:|---:|---:|---|
| settled (`9.337e-06`) | 0.0000093 | 0.0002801 | sleeps 29 | **sleeps 29** (no regression) |
| slow slide (`5.0e-04`) | 0.0005 | 0.015 | slept 29 | **never in 600** |

The real free-hinge replay still sleeps (ticks 61/210/390), and — the part that matters most — **the live-spring creature stays awake for all 600 ticks with max dwell 2** (`_zero_input_live_sleep`). The fix is doing its job in composition, not just in a fixture.

*Sensitivity to record, not a defect:* the dwell test now rejects any steady creep above ~`3.3e-05` WU/tick (≈0.005 px/s), and the settled creature sits at `9.34e-06` — a **3.6× margin**, down from 107×. If a future authored creature legitimately creeps at 0.003 px/s it will never sleep and AC-201 will fail honestly. That is the price of measuring 0.5 s of real stillness instead of 1/60 s of it, and it is the right trade.

**F53/F54** closed as asked.

---

## 3. F48 — my ask was wrong, and your catch was correct

I asked for a `physics_passive_stiffness` sweep. `MotorDrive.drive()` shows why that could never work:

```gdscript
if joint.child_body.kind == "motor":
    target = -contraction_deg*rad*gain if input else 0
    torque = clamp(motors_joint_stiffness*(target - q) - motors_joint_damping*omega, ±max_torque*gain)
else:
    torque = -physics_passive_stiffness * q
```

The Slug's joint is a **motor** joint with `motors_joint_stiffness = 2400` and there is no passive joint, so `physics_passive_stiffness` is dead code for this creature. 900 and 0 are identical because the number never enters. **That is my error, not an evasion**, and reporting it instead of quietly presenting a no-op as proof is exactly right.

What the run *does* prove is the magnitude, by arithmetic:

`2400 × 0.8429 rad = 2022.8` = the reported `mean spring torque -2022.854605`, against `mean damping -141.25`. So at zero input the spring is **94 % of the joint torque** and it never switches off, because `q ≈ 0.84 rad` (48°) is where gravity holds the creature and the target is `q = 0`.

Causality still needs a measured arm with the **motor** stiffness at zero, not the passive one.

---

## 4. F55 — the drift is *inside* the permitted static-slip band

`physics_static_slip_wu_s = 0.15` WU/s = **22.5 px/s** at 150 px/WU. Every drift number in this milestone is far below it:

| arm | drift | share of the 22.5 px/s allowance |
|---|---:|---:|
| free-hinge baseline | 0.084 px/s | 0.4 % |
| actuated before | 3.513 px/s | 15.6 % |
| actuated after | 3.934 px/s | 17.5 % |

So the solver is **not** doing anything it was not permitted to do: the static branch holds tangential motion only up to that allowance, and any persistent internal force simply walks the creature over the floor at a fraction of it. This matters for the remedy discussion in two ways:

- No solver defect is *required* to explain 3.93 px/s. The friction model is behaving as authored, and M0-era tuning is what sets the ceiling.
- It also means "less spring" and "no spring" will not reach zero drift; they converge on the 0.084 px/s floor, which is what the sleep predicate accepts (`2.80e-04` WU net over 30 ticks against `0.001`).

Report it as a row in the mechanism table, so nobody later reads the 3.93 as a leak.

---

## 5. F56 [do this before the remedy] — prove the drift is external

I traced every internal row for COM conservation:

| row | linear momentum effect |
|---|---|
| `AngularJoint.apply_impulse` | angular only (`PlanarBasis.spin` on both bodies, no linear term) |
| `CoincidentHinge.project_position` | `parent += inv_p·x`, `child -= inv_c·x` ⇒ **ΔCOM = 0 exactly** |
| `CoincidentHinge.project_velocity` | equal and opposite, `Δp = ±(v_p−v_c)/weight` ⇒ **Δp = 0** |
| `SelfContact` (D10) | already verified conserving to `1e-14` |

So **no internal row can move the centre of mass**, and the entire 3.93 px/s must be external contact impulse. That is a claim I can derive but you must measure, because if it is false the remedy would paper over a real leak:

**Ask:** over the last 300 ticks of the actuated-after arm, assert the identity

`Σ COM momentum change = Σ external (ground normal + friction) impulses`

to the ledger's existing precision, and publish both sides plus the residual. If the residual is at rounding level, the mechanism is proven external and the spring discussion is purely a feel decision. If it is not, **stop** — that is a solver defect and the remedy changes completely.

---

## 6. Phase 2 — accepted

Verified from the committed evidence, not from prose:

- `replay_full_stream_bytes = 31131584`, `replay_streams_byte_equal = true`
- `falsification.baseline_digest = d735ea5f…` vs `changed_digest = 0f0f93a6…`, `physical_bodies_differ_at_flip = true`, `tick = 0`
- baseline committed with tuning fingerprint `3a32dd3d…`, `full_stream_sha256 05c27f02…`, matching sha256 in `tests/fixtures/public_sim_baseline.json`, provenance naming the source run **and** stating that the source job was red on the frame-protocol check — that is honest provenance, and the matching rerun is what makes it acceptance
- `live_spring_sleep`: 600 ticks, `max_dwell_ticks = 2`, never asleep
- delivery: 30 FPS → 301 frames, **601 actual ticks, 600 compared**, `tick_hz 60` throughout, startup frame 0.025 s retained and disclosed
- `snapshot()` reaches the real solver: `accumulator → _solver.snapshot() → {rig, constraints, held}` with `rig.sleep.dwell_start` inside, and `Sim._restore` rebuilds on detached objects before committing

The 601st tick is handled correctly: actual delivery is preserved, the comparison is on an equal simulated-tick prefix, and no elapsed time was altered. **Good.**

**F57 [nit]** — `_rng` is configured, snapshotted, restored and hashed, but no physics path consumes it (`_record_tick` only captures it). A9.3 is satisfied as "an injected seeded stream exists and survives replay"; do not describe randomness as *exercised*. When the first stochastic path lands, the vector test in `xoshiro128_vectors.json` becomes load-bearing.

**Matrix** — I checked all eight upgraded rows against the required evidence: Engine, A9.2, A9.3, A9.4 ×3, A9.4 stall, A9.5, A9.7 flip, A9.7 baseline. Correct, and the remaining ten still say `NOT RUN` with reasons. Guard exits 0 locally, **144** Python tests pass, and the original 514 M0 checks are untouched (516 = 514 + two new compile assertions from the recursive per-script check, which is a side effect and must not be read as M0 improving).

---

## 7. F41 — correctly still open

| bucket | ticks | mean | min | max |
|---|---:|---:|---:|---:|
| after actuated A | 250 | 4.503e-04 | 3.625e-04 | 7.048e-04 |

Within the dominant bucket the drift varies **1.94×**, so bucketing does not isolate sampling and the pose claim stays unsupported. Right call.

---

## 8. M1-D05 — the spring decision, with what is actually known

Known: spring on ⇒ 3.51/3.93 px/s. Free hinges ⇒ 0.084 px/s. Spring torque is 94 % of joint torque and permanent (`2400 × 0.843`). No internal row can move the COM (subject to F56). The static band permits up to 22.5 px/s, so the model is not misbehaving — the spring is simply using 17 % of the allowance, forever.

| option | what changes | expected drift | feel cost |
|---|---|---|---|
| **A. target the settled pose** | `target = q_settled` per joint instead of 0 | ≈ baseline (0.08 px/s) | keeps posture memory; needs one deterministic calibration rule |
| B. weaker return spring | `motors_joint_stiffness` 2400 → smaller | scales down, never zero | weakest option: it is tuning toward a number, and weakens the lurch return |
| C. no return spring | stiffness 0 at release | ≈ baseline | limp when idle; loses the GDD §3.4 return |

**I recommend A**, and it must be framed as a proposal for the owner: it is the only option that removes the permanent torque *without* weakening the return, because at rest the target and the pose coincide. It costs one documented calibration decision (which is why it is not mine to take silently):

- the settled pose is captured **once, at setup**, from a deterministic zero-input settle, stored in solver state and therefore in `snapshot()`/`state_hash()` (replay stays valid);
- the capture is a **protocol** number, not a feel number — it must be named and justified, and it must not be chosen to make a drift number look good;
- the drive target becomes `q_settled - contraction_deg*rad*gain`, so contraction magnitude and therefore lurch feel are unchanged;
- if A does not bring zero-input drift to the free-hinge baseline, come back with numbers — do not start tuning stiffness to close the gap.

**Before A is applied**, F56 must pass and the *correct* sweep (motor stiffness 2400 vs 0, damping untouched) must be measured, because that arm is the falsification of my own mechanism claim.

---

## 9. Where M1 stands

**8/18 measured.** `NOT RUN`: AC-201, AC-202, AC-204, three presets + captures, tick cost, §10.6, FA-3, FA-4, FA-5, FA-6.

Order: F56 identity → motor-stiffness sweep (2400/0) → owner decision applied → Phase 3 (AC-201/202, FA-3/4/5) → Phase 4 (presets, captures, FA-6, tick cost, soak) → Phase 5 (§10.6, invariants, verdict).

**Acceptance 8/18. Determinism attempt 1 succeeded as a same-build observation; cross-architecture attempts remain 0.**
