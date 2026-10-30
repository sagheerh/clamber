# AC-201 / AC-202 investigation — candidate only, neither failure fixed yet

Date: 2026-10-30. Branch: `arena/f43f36ab-clamber`; investigation base `394f7e9`.
Owner now explicitly authorises carefully analysed physics fixes. Lack of
permission is **no longer the blocker**. Validation infrastructure is the blocker.
No production operator is changed/adopted in this increment.

## 1. What this game is supposed to do

Normative inputs reviewed: GDD §§1.3–1.8, 3.4, 4.1–4.7, 10.6, 13.1 and the
existing owner decisions, R26/R27/R28/R29 reports and current implementation.

CLAMBER is an offline, portrait, player-built physics creature game. Two held
L/R channels are the player's muscles; wiring and timing, not extra controls or
scripted movement, create different gaits. Releasing should allow real settling,
not leave an uncommanded treadmill. Limbs must remain bones during terrain
contact, without solving one invariant by pushing feet into terrain. Physical
falls and lurches remain part of the toy; this is not a request for an upright
vehicle controller or an automatic walking animation.

M1 supplies standalone solver/presets/harness, not the later builder/tower game.
A correct repair must retain fixed60Hz, max3/drop accumulator, injected xoshiro,
float64 scalar solver math, deterministic ordering, actual motor torque/limits,
terrain collision, finite validation and transactional restore. Cosmetics must
not affect collision. Sleep must not manufacture evidence by freezing drift.

Actual public path:

```text
Sim.advance_frame -> FixedStepAccumulator -> CreatureTickSolver
  -> SleepingLoadProbe -> ActuatedLoadProbe/CoupledLoadProbe
  -> distance / hinges / angular limits / self-contact -> CapsuleContact
  -> CreatureSleep observes actual completed positions
```

## 2. Why the failures were still present

Earlier requests constrained work to measurements/merge/ZIP access and expressly
prohibited solver changes. The later device lab added testing access, not a
physics fix. It would have been false to call M1 complete from those changes.
The new request authorises the missing correctness investigation, not a hidden
relaxation of the assertions or a retry of the rejected final-distance adoption.

Historical facts retained without rerunning the accepted jobs:

- AC-201: Slug600 zero-input ticks completed; spawn-relative attitude maximum
  35.34385590667538° exceeded15°. No sleep; original4s requirement unmet.
  Actual COM0.6460243614279206WU met the separately authored0.90WU displacement
  limit; that does not make the whole criterion pass.
- AC-202: later contact cleanup reintroduces completed length error after earlier
  distance solves. R26 Hopper literal-limb example0.05334550000967464WU >0.05.
- R28's final distance repair reduced length residuals but pushed contact geometry
  inward: Slug0.07028201067739755WU, Hopper0.0933999293597247WU,
  TwinRoller0.05075245867956493WU penetration. It was reverted and is not retried.
- D0's reverted control is0.02WU + roundoff, **not a pre-existing penetration
  defect**. F79 remains WITHDRAWN; adoption reached2.5–4.7× designed slop.

Sources remain `.review/m1_r26_diagnostic_report.md`, `m1_r27_report.md`,
`m1_r28_adoption_report.md`, `m1_r29_measurement_report.md` and their JSONs.

## 3. Located AC-202 mechanism: incompatible terminal operators

`CoupledLoadProbe._predict_and_project` does its six position iterations with
bones first, then hinge/angular/self-contact. Terrain position correction is
later, inside `_velocity_contacts`, after that whole loop.

In `CapsuleContact._response`, an active sample uses:

```text
u = sample parameter, v = 1-u
D = v² * inverse_mass_A + u² * inverse_mass_B
lambda = max(0, radius - slop - signed_distance) / D
A += inverse_mass_A * v * normal * lambda
B += inverse_mass_B * u * normal * lambda
```

These are legitimate **free-particle** contact rows. They are not an exact
rigid-capsule row: A and B generally receive different corrections. At u=0,
only A moves. Therefore the final operation is allowed to change the bone's
extent after its distance row has finished. This algebraic counterexample
matches the historically measured phase-local injection; it is not a new
whole-creature measurement.

The velocity row also addresses free endpoint DOFs. For an axial endpoint hit,
stopping just one endpoint introduces longitudinal relative velocity. The
coupled solver's earlier distance-velocity projection cannot constrain a later
contact impulse. The free-particle denominator is not intrinsically incorrect;
**using terminal free-particle rows while requiring a completed rigid bone is
the incompatibility**.

A final bone-only reprojector is not a solution because it can move the capsule
back through contact. Raising slop, adding an epsilon, adding iterations, moving
the foot, forcing a posture, or weakening the0.05 limit are not used here.

## 4. AC-201 is not yet isolated to a proven patch

The owner mechanism-of-record associates sustained internal load and
contact/friction rectification with drift. Historical friction sweeps were not a
proof of a particular scalar coefficient defect. Their inconclusive result is
not relabelled as a new diagnosis.

There is also a genuine spawn transient to distinguish from numerical creep.
The actual Slug data give head0.77, motor0.48, foot0.30 mass units; total1.55.
Its COM x is0.263064516129…WU, whereas its initially lowest foot endpoint is
x0.35WU. With gravity28, initial gravity moment about that prospective contact
has magnitude3.773 mass·WU²/s². This static calculation is derived from the
committed geometry/material values. It explains why “released input” does not
imply “initial pose is already an equilibrium.” It does **not** predict the
final angle, justify exceeding15°, locate the sustained drift callsite, or prove
that the new contact kernel solves posture/sleep.

`CreatureSleep.observe` correctly rejects both per-tick and anchored dwell net
motion beyond the existing0.001WU/30-tick rule. Making sleep trigger earlier to
hide the bad motion would not repair contact/joint dynamics. No sleep predicate,
input rearm or parking implementation is changed.

## 5. Implemented, isolated candidate — NOT selected by Sim

`tests/physics_fix/rigid_contact_candidate.gd` provides a detached rigid-row
kernel. It has **no production callsite** and is excluded from ordinary exports.

For equal endpoint masses, consistent with `AngularJoint`:

```text
inverse_mass = 1/m
inverse_inertia = 4/(m * actual_extent²)
r = (u - 1/2) * (B - A)
t = (-ny, nx)
cn = cross(r, n); ct = cross(r, t)
Knn = 1/m + cn²/I
Ktt = 1/m + ct²/I
Knt = cn*ct/I
```

- Resolve coupled normal/tangent mass, rather than applying independent endpoint
  impulses that access the bone's longitudinal mode.
- Apply the result as whole-body COM translation plus spin. Its *increment* has
  no longitudinal endpoint component; pre-existing longitudinal error from other
  rows is not silently erased or claimed solved.
- Apply friction retention to the tangent velocity **after normal response**.
  At an oblique rigid contact, keeping the pre-normal tangent fixed can invent
  a tangential impulse even when friction is zero and can add kinetic energy.
  Exact-rational tests include that counterexample.
- Enforce unilateral normal impulse; reject invalid/nonfinite inputs atomically.
  A strict no-energy-increase guard fails closed without a velocity clamp or
  physics epsilon. Coupled restitution/multiple-contact behavior remains to test.
- An isolated common-translation positional hypothesis preserves current extent
  and separates positional cleanup from actual impulse/qualifying load. It
  checks the existing projection bound for the isolated call and does not change
  radius/slop; accumulated per-tick corrections still need a composition guard.

**Limits:** this is not a finished manifold/hinge solver. Common translation does
not repair pre-existing bone stretch, enforce hinges, or guarantee that later
nonparallel surface normals won't undo an earlier contact. Multiple contacts,
curved/bilinear terrain, swept entry, angular caps, frozen prior-grounded N,
qualifying load, aggregate projection caps, F31 budgets, rollback and snapshots still require real-engine
composition tests. No claim is made that any new kernel eliminates35° posture
change or makes a complete creature sleep.

## 6. Validation and infrastructure gate

Actually run:

| Check | Result | Scope |
|---|---|---|
| `bash scripts/review_checks.sh` | 232/0 | unchanged static/invariant controls |
| `python3 tests/test_physics_fix_analysis.py` | 12/0 | exact-rational analysis/oracle + static guards, NOT GDScript execution |
| `gdlint tests/physics_fix/*.gd` | clean | grammar/lint, NOT semantic compilation |
| device package Python tests |10/0| existing packaging regression |
| ZIP provenance Python tests |10/0| core hash/paths unchanged |
| missing-GODOT runner guard | fails before execution | no primitive or creature ticks |
| candidate Godot unit script | NOT RUN | 31 planned primitive assertions, no claimed result |
| new complete-creature AC-201/202 validation | NOT RUN | production not modified/adopted |

The official4.7.2 Linux binary download through the GitHub asset API redirected
to `release-assets.githubusercontent.com`, where the sandbox SSL/network
connection fails. No older/unverified binary is substituted.

Read-only inspection of recent main CI40993179302 (source7d86dd5) showed parse
job123860148269 failed with **steps[]**, before executing any engine code. Exact
annotation:

> The job was not started because recent account payments have failed or your spending limit needs to be increased. Please check the 'Billing & plans' section in your settings

Preserved in `.review/physics_fix/recent-main-{jobs,annotations}.json`.
This is recent infrastructure evidence, **not a newly launched proof for this
candidate**. Neither alternative billing cause is independently established.
No repeated proof/job, billing operation, artifact upload/deletion or credentials
request was made. Zero new complete-creature attempts; no D0/R27/R29 rerun.

## 7. Safe next gate (desktop engine, no phone needed yet)

Make the checksum-verified pinned4.7.2 official ed1daf0bf engine available, then:

```bash
export GODOT=/absolute/path/to/checksum-verified-godot
bash tests/run_m1_contact_candidate.sh
```

This command refuses an existing result directory, verifies the unchanged core
manifest, records source/candidate hashes/build, imports and semantically checks
the candidate script, then runs **primitive-only** tests. Return the entire
`exports/contact-candidate-units/` directory, including source/import/compile/
units logs. An error stops; do not quietly rerun/overwrite or call it an arm pass.
A physical phone is not needed for this first gate.

After real primitive validation, the candidate still needs an independently
recorded coupled contact/hinge implementation and new source-pinned full-creature
validation. Before changing the solver, retain the current public regression
baseline and real rerun provenance. Any adoption must record explained trajectory
changes rather than regenerating expectations to hide failures.

Required full-creature checks include the original4s sleep deadline plus the
owner's separate600-tick stability clauses, actual wake/input behavior, full120s
bone errors together with penetration/contact constraints, and all three preset
inputs. Curved/slope/edge contacts, speed/torque caps, F24/F31 and atomic
rollback need regression coverage. Old historical evidence is never overwritten.
Only then can production contact be changed and a new verdict considered.

## Status

**AC-201 and AC-202 remain FAILED on the current production solver.** Candidate
code/analysis is saved, but neither failure has been fixed or validated yet.
M1 BLOCKED / NOT SIGNED; M2 blocked. The outstanding blocker is engine execution,
not missing permission, and the remaining composition work is explicitly open.
