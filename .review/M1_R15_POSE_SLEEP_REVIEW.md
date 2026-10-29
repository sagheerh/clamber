# M1 — R15 review: pose + sleep landed; the "unexpected" pose result is a real finding @ `d2fe703`

**Target:** PR #3 head `d2fe703` (draft, OPEN). Commits over R14's `75df486`: `126dc80` (A/A1 axes + hard F36 audit + paired supports), `e36c407` (sleep dwell/wake/replay), `34ebc6`/`d4c260e`/`d2fe703` (records).
**CI:** `40806098142` green (M1), `40806098134` green (M0 **510/0**, Android pass).
**Reviewer branch:** `arena/5b72e4ab-clamber` → this file.

---

## 1. Verdict

**F41b answered correctly. Pose A+A1 and the sleep implementation are both accepted as landed, exactly to spec. The "unexpected" post-pose result is not a failure of either — it is two new defects in the probe's initial condition and in the contact sampling rule.**

| Item | Status |
|---|---|
| F41b explanation | **accepted**, and it exposes a knife-edge (F44) |
| Pose A + A1 | **landed exactly**: 5 axes DOWN, only 2 tuning additions, old resource sha pinned |
| Hard F36 audit + exemption | **landed**, synthetic bad-pose control retained |
| Sleep implementation | **accepted**: snapshot-only, dwell, wake, transition wake, replay |
| Sleep replay evidence | **verified** 1,091 identical states, restore at 47 and 62 |
| Python 97 / M0 510 | **reproduced locally / CI-confirmed** |
| Post-pose dynamics | **correctly not downgraded, not tuned** |
| **F43 [MAJOR]** spawn begins **0.27 WU inside the floor**; pre/post comparison is not like-for-like | new |
| **F44 [MAJOR]** foot rest length **exactly equals** the SDF cell size → sample count on a `ceil()` cliff | new |
| **F45 [MINOR]** two unused M0 velocity-keyed sleep constants now coexist with the positional pair | new |
| **F46 [NOTE]** F30 *authored* is closed; F30 *runtime* is blocked by missing actuators, not by the pose | record correction |
| FA-3/4/5/6, captures, determinism | `NOT RUN` / **0** |

---

## 2. What I verified

- **Axes exactly as approved, no collateral edits.** `data/creatures/*.json`: Slug `[head RIGHT, motor DOWN, foot DOWN]`; Hopper feet 5 and 7 `DOWN` (both now −1.000); TwinRoller foot 4 `DOWN`, foot 5 `DOWN` with `parent: 0` **retained as the exempt stub**. No parent changed anywhere.
- **Tuning additions are only the two approved fields**: `sleep_still_displacement_wu = 0.001`, `sleep_dwell_ticks = 30`. No radius, mass, damping, slip, gate or iteration value moved, and `test_r14_owner.py` pins the *original* resource by sha256 (`1da7a06b…`) so an old value cannot have been quietly edited.
- **Python 97** = 19 + **6** (new R14 owner) + 13 + 40 + 5 + 6 + 8, reproduced locally; matrix guard exit 0; M0 **510/0** confirmed from CI annotations.
- **Sleep module is clean by construction**: `observe()` reads only two snapshot arrays plus `input_mask`; there is no timer and no velocity epsilon; `restore()` rejects any state where `asleep != (still_ticks == sleep_dwell_ticks)`, which makes replay divergence impossible to hide; the sleeping probe asserts `_parked_velocities` on every sleeping row and zeros both endpoint velocities each parked tick.
- **The R14 owner tests are not self-fulfilling**: they feed a synthetic fixture through the *classifier* and include the trap case (identical drift with a changed grounded set must raise `suspicious_identical_drift_different_support`). They do not restate the agent's own numbers, and the real numbers live only in CI annotations — acceptable, worth knowing.
- **Post-pose numbers, from CI**: `grip_ticks 1` at tick 19 (`loaded_grip_ticks 1`), toggle ticks `[19, 20]`, steady grip `0`; `grounded_sets [[0,1,2]]` before **and** after; active samples per pass identical in both runs (head 3/3, motor 3/3, foot 3 then 2); foot support share `0.22239253…` → `0.22240637…`; all-terrain reaction `43.596106844` → `43.596103430`; COM `vx` `−4.3930e-04` → `+5.7167e-04`; drift `−7.17519e-06` → `+9.33733e-06`.

---

## 3. F30 status, stated precisely (replaces "pending" and prevents "the pose fix failed")

Two different claims were being carried under one label, and they now separate:

- **F30-authored: CLOSED.** The audit proves a foot pad is 0.205 WU (Slug, TwinRoller 4) and 0.235 WU (Hopper) below the lowest non-foot body, with exactly one documented exemption. That was the defect I raised in R10 and it is fixed at the definition level.
- **F30-runtime: still blocked, now by the missing actuators.** In the settled probe the foot still carries 22.24 % of support and head+motor carry the rest, because **the hinges rotate freely** and the foot swings up to lie alongside the body. Nothing in the pose can prevent that: with no angular limit and no motor torque, the lowest-energy configuration of a limp chain is everything on the ground. The authored geometry is now correct; the *attitude* is unconstrained.

So do not read the persistence of 17 samples/tick and three grounded bodies as "A did not work". It worked, and it exposed the next dependency. Step 4 (motors, angular limits, self-contact) is now the gate for every FA-5 branch, not an optional extra: "two-foot stance grips" and "airborne never grips" are literally statements about a creature that can hold an attitude.

Also record the milestone honestly: **grip engaged for the first time in a shipped preset**, once, at tick 19, for exactly one tick (`toggles [19, 20]`), with steady-window fraction 0. That is path existence, nothing more.

---

## 4. F43 [MAJOR] — the post-pose run starts 0.27 WU inside the floor

The probe still spawns at root `y = 0.33`, but the pad now hangs 0.25 WU lower than the old motor belly:

| | lowest authored bottom at spawn | penetration below the surface (floor at `y = 0`) |
|---|---:|---:|
| before A | motor `−0.065` | `0.045 WU` |
| after A | foot **`−0.270`** | **`0.270 WU`** |

`physics_max_projection_wu_tick = 0.4` means it *can* recover in one tick, so the run does not explode — but the tick-0 state is not a legal starting pose, and the two arms of the comparison do not start from equivalent states. "No silent spawn correction" was the right instinct; the missing half is that an illegal spawn makes the comparison invalid rather than conservative.

**What this does and does not explain.** It probably does **not** explain the drift reversal: F38 already showed the plateau is insensitive to landing (three spawn heights 0.20 WU apart gave `P` within `2.8e-17`), and here the plateau barely moved (`0.16342237` → `0.16341952`, Δ `2.8e-6`) while the lateral drift flipped sign and grew 30 %. If landing depth were the driver, the plateau should have moved too. So F43 is a validity defect, not the mechanism.

**Ask:** derive the spawn from the model instead of hard-coding it — root `y` such that the lowest authored capsule surface sits `+0.01 WU` above the floor — and re-run both arms at legal clearance. Report the drift delta again. Keep the 0.33 run as the historical record, labelled as an over-penetrating spawn.

---

## 5. F44 [MAJOR] — the foot's sample count sits exactly on a `ceil()` cliff, and that is why the drift flipped

`physics_foot_length_wu = 0.25` and `physics_sdf_cell_wu = 0.25`. The candidate count is `max(1, ceil(extent / cell)) + 1`, so at the foot's rest length the ratio is **exactly 1.0** — `ceil(1.0) = 1` — and any extension of a single micron pushes it to `ceil(1.000004) = 2`.

That is precisely what the trace shows, and it is the answer to F41b: `part 2 pass0: intervals=2 candidates=3`, `pass1: intervals=1 candidates=2`, `completed extent 0.248831 WU`. The foot straddles the boundary *within a single tick*.

Why this matters beyond bookkeeping:

1. **Support distribution and lateral bias are discontinuous in geometry.** The number of tangential samples decides how much endpoint velocity survives (F41: later samples recreate earlier motion), so a sample count flipping 3→2 changes the surviving velocity — and its sign. That is the most plausible explanation for COM `vx` going `−4.39e-04 → +5.72e-04` while the all-terrain reaction moved by only `3.4e-06`.
2. **The comparison "before vs after" therefore conflates a pose change with a sample-count change**, which is why neither of my predicted outcomes materialised. The honest statement is that F41's re-measure is **not yet interpretable**; it needs a legal spawn *and* a documented statement of the sample counts on both arms (which the trace already carries).
3. **It is a hidden fragility for every future change.** Any edit that stretches the foot by a fraction of a cell (a pose, a clearance, a damping tweak) flips the sample count and can flip the drift sign with no visible cause. Head (0.35/0.25 = 1.4) and motor (0.30/0.25 = 1.2) are safely inside their bins; only the foot is on the edge.

**Do not change either constant.** Options belong to the owner later: decouple sampling density from `physics_sdf_cell_wu`, or make the sampling criterion continuous, or nudge one of the two values. For now: record it, and in every trace row report `intervals` and the candidate count per body per pass (the slip trace already does; make it a required field in the main 600-tick trace too, so this can never again be invisible).

---

## 6. F45 [MINOR] — two contradictory sleep definitions now live in `TUNING`

`physics_sleep_velocity_wu_s = 0.05` and `physics_sleep_grounded_s = 0.6` (M0) are **declared and used nowhere** — I grepped the whole tree. They encode the *velocity-keyed* sleep that F38 proved can never fire on this model. The approved positional pair now sits next to them.

A future implementer wiring the public `Sim` will find both and has a 50 % chance of picking the one that cannot work. Ask: in the same commit that wires `Sim` sleep, either delete the M0 pair or mark them explicitly superseded in `docs/TUNING.md` with the F38 reason. No decision needed from the owner for a documentation-level clarification; deleting them is an owner call.

---

## 7. Sleep: accepted, with the two boundaries made explicit

- Evidence is sound: sleep ticks `61 / 210 / 390`, input wakes `180 / 360`, restores at `47` (mid-dwell) and `62` (asleep) each reproducing **1,091 subsequent full serialised states** identically, including the sleep and wake ticks. That is the strongest replay evidence in the project so far — but it is still **component** replay of an engineering probe, not complete-creature determinism.
- The transition-only wake control passes, so F42's reading is implemented as approved.
- Two things to keep visible, both already true in the report and both worth never dropping: sleep **parks** the plateau (0.202 WU/s awake endpoint speed = 30 px/s at 150 px/WU remains a feel risk), and **asleep is not FA-4**. FA-4 also wants Slug settle ≤ 4 s *and* an L-hold lurch of about one body length — the lurch needs motors.

---

## 8. Where M1 stands

**Landed and verified:** review infrastructure; math 381; owner geometry 131 → now 136 analytic; presets + creature model; SDF + swept contact 237; force-channel split; coupled load producer + conservation + ledger; telemetry F36/F37/F41/F42; **pose A/A1 with hard audit**; **positional sleep with replay**.

**Blocked by nothing but engineering now — no owner decision outstanding:**
1. **Motors** (L/R contraction), **angular limits**, **self-contact**. This is the gate for every FA-5 branch.
2. Legal-spawn probe rerun (F43) and sample-count reporting (F44) before F41 is re-judged.
3. Public `Sim` wiring (still a 33-line stub) and the superseded-sleep cleanup (F45).
4. Then FA-5 band (Hopper two-foot), FA-3 / FA-4 on all three presets.
5. Then AC-201/202/204, A9 (×5), §10.6, tick cost, captures.

**Acceptance gates passed: 0 of 21.** Analytic-only: FA-1/2/7. Complete-creature determinism attempts: **0**.
