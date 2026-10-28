# CLAMBER decisions

The GDD's existing D-01–D-17, CD-01, and A-xx decisions remain normative.
New implementation decisions use M0-Dxx to avoid colliding with those IDs.

## M0-D01 — Empty engineering boot, not a new game screen

The packet excludes every mockup screen. `ui/boot.tscn` is only the requested solid
navy engineering surface. `ui/screens/` stays empty except `.gitkeep`; core system
and shared component stubs compile/parse without implementing future milestones.
No autoload is needed until services have consumers. Public Sim/codec signatures
are reserved with explicitly nonfunctional bodies.

## M0-D02 — Safe atomic backup staging and recovery signals

§10.5 does not prescribe how to keep `.bak` without a window where the primary is
missing. Flush `file.tmp`; if the original is valid, flush `file.bak.tmp` and rename
it to `.bak`; finally rename `.tmp` over the original. Ignore `.bak.tmp` on reads.
Do not overwrite a valid backup with an invalid primary. Reads are non-mutating and
emit recovery source (`.bak`, `.tmp`, `defaults`) for later UI, instead of putting
a toast dependency in core. First install is not reported as corruption. Writes
are synchronous, return errors, and emit write-failure signals.

## M0-D03 — Validate schema without inventing migrations

Use schema 3 from §8.4 as the current generic store schema; require a dictionary
with a numeric integral schema equal to that version. Unknown/missing schemas fall
through recovery. The GDD does not provide v1/v2 save layouts; migrations/settings
remain explicit stubs. Do not fabricate historic fixtures or silently migrate.
Constants such as schema/input identities and operational budgets live in tuning
too, to satisfy the packet's stricter no-numeric-literals-in-core requirement.
Build-required numbers are mirrored in configuration (Godot cannot read its
project/export settings from a custom Resource before boot).

## M0-D04 — Pinned toolchain, honest unavailable validation

Keep 4.7.2-stable; do not substitute an older executable. The release is listed,
but download redirects to `release-assets.githubusercontent.com`, outside this
sandbox's network allowlist. No Godot/JDK/Android SDK/adb or device is installed.
The local static/grammar checks are not substitutes for engine/device tests.
Follow-up: branch push successfully ran the pinned engine on GitHub's runner;
CI now also builds and inspects Android artifacts. See `docs/validation/M0.md`.
Manual workflow dispatch returns integration HTTP 403, so validation is triggered
by pushes to the existing session branch; no credentials or permission changes
were requested. AAB delivery needs bundletool-generated APKs to install; direct
AAB installation is not an Android operation. Device evidence remains a gate.

## M0-D05 — Validate JSON semantics and float64 representation correctly

Real engine runs showed that JSON-loaded numeric values do not have the same
GDScript Variant types as the in-memory integer fixtures. Save round trips are
therefore compared after JSON normalization on both sides; no save behavior or
payload values were changed. The `.tres` parser loads the declared 1/60 decimal
as `0.01666666666666665950`, versus GDScript division's
`0.01666666666666666644`. The resource assertion permits only four float64 relative
ULPs, not gameplay tolerance. The original tuning remains unchanged. This is a
resource representation check, not a waiver of M1's exact determinism gate.

## M0-D06 — Build evidence is not physical-device evidence (historical; M0 status superseded by M0-D07)

The user selected **No device available** during follow-up validation. Keep M0 open
on its installation/display/performance criterion; do not substitute an emulator,
CI success, or the 60 fps cap for measured hardware results. CI produces a debug
AAB and disposable-key APKs for later installation, with automated manifest/ABI/
16 KB checks. Generated binaries, native build files and signing keys stay out of
Git; only test tooling and evidence references are committed.

## M0-D07 — APPROVE — HUMAN OVERRIDE; M0-only acceptance waiver

Owner decision dated **2026-10-28**: the GDD owner reports installing and opening
an M0 debug build on a physical Android device, observing the expected solid navy
screen and no UI/gameplay. The owner explicitly approves M0 as **COMPLETE** under
GDD §16.1's “APK that boots” deliverable. Verdict: **APPROVE — HUMAN OVERRIDE**.

This is **owner verbal verification, not an E4 artifact**. No screenshot, adb log,
device identity, lifecycle/safe-area record or frame-time capture was attached.
The owner did not independently identify a binary hash in that statement; do not
infer an artifact-to-device chain of custody from the linked CI artifact metadata.

For **M0 only**, the owner waives the remaining device-evidence artifacts and the
measured **60 fps / P95 ≤16.6 ms** criterion. Neither FPS nor P95 was measured.
`Engine.max_fps = 60` is only a cap, not a measurement. Also explicitly waived for
M0 only are the review-pack artifacts `scripts/review_checks.sh` and
`.review/m0_ac_matrix.md`; they are not represented as having been produced.
M0-B01 is closed by this explicit acceptance/waiver, not by fabricated test evidence.

The M0 waiver **does not apply to M1 or any later milestone**, including solver
performance, determinism, soak evidence or later device gates. M0-D06 remains the
historical record of the earlier blocker. M0 closeout is mechanical: no runtime,
feature, tuning, save or test changes. Land/close the M0 PR first; M1 scaffolding
and implementation belong in a separate commit and PR after that boundary.

## Resolved by owner override

- **M0-B01:** closed for M0 by M0-D07; owner-reported install/boot, missing E4
  device records and unmeasured frame timing explicitly waived, not measured.

## Blocked — needs human answer

- **M0-B02 (before camera implementation):** §2.3 S03 specifies airborne zoom 0.75,
  §4.8 specifies 0.72. Both are preserved under section-specific tuning names;
  neither is selected or used in M0. Which is normative?
- **M0-B03:** grip-input portion resolved by M1-D04; §11.3 landing haptic
  impulse threshold and §6.3 generation salt,
  profile weights/heights are named but have no supplied numeric values. They are
  intentionally not fabricated as zero-valued tunables. Supply values when those
  milestones are assigned. No M0 feature depends on them.

## M1-D01 — Independent mathematical work; no invented contact values

2026-10-28 owner clarification: proceed only with independent work while per-part
collision radii (including head), head mass/length treatment and foot normal-force
grip threshold remain unspecified. Implementing a moving/colliding creature would
require feel-affecting choices; do not infer these from limb lengths or use zero
as a hidden default. Mathematical body/link state and review infrastructure may
proceed. No contact, gait, performance or determinism acceptance is claimed.

R4 correction: the earlier attribution of an owner decision about excerpts was
incorrect and is withdrawn. The owner supplied the complete review pack on
2026-10-28. It is now vendored byte-identically and unmodified; provenance and
SHA-256 are in `docs/CLAMBER_REVIEW_AGENT.provenance.md`. Vendoring does not
constitute execution of its invariant sweep, five-fakes or A12 review.

## M1 blockers — needs human answer before dependent implementation

- M1-B01: **RESOLVED (owner inputs supplied)** by M1-D04. No contact/feel
  acceptance follows from receiving provisional constants.
- M1-B02: **RESOLVED (vendored), not waived**. Full owner-supplied review pack
  imported unchanged on 2026-10-28; see provenance for its exact hash. Full
  INV-01..INV-10/five-fakes/A12 execution remains outstanding.
- M0-B02 remains a camera/M2 question; haptic/generator values remain out of scope.

## M1-D02 — Scalar point/link foundations are not a creature solver

Independent increment 1 uses float64 GDScript scalar x/y, previous position,
velocity and explicitly supplied inverse mass. It introduces no radius, head
property, gravity/integration, sleep, contact, hinge or actuation tuning. Zero
inverse mass represents a mathematical pinned point; it is not a head default.
DistanceConstraint implements the standard XPBD distance projection with caller-
supplied rest length/compliance and fixed step derived from tuning tick rate.
Its multiplier must be reset by the future tick owner, not silently per iteration.

Coincident endpoints have no defined gradient; reject them rather than fabricate
an axis/epsilon. Unsolvable pinned pairs and non-finite/overflow candidates return
errors without partial mutation. Snapshot restoration validates all fields before
mutation. Synthetic fixture values in tests are mathematical examples, not
approved creature/preset tuning. Unit projection/restoration tests are NOT the M1
3600-tick replay, baseline, bit-flip falsification, contact soak or gait captures.
No complete creature determinism attempt has run; the two-attempt stop budget has
not been consumed and D-11 is not being proposed on infrastructure blockers.

## M1-D03 — Independent point/link integration and outer clock (R5)

R5 explicitly authorizes only mathematical bodies/links, fixed-step integration,
gravity from tuning, deterministic ordering and the capped outer accumulator.
`core/sim/solver.gd` is a RefCounted PointLinkSolver, not the public creature Sim.
`core/sim/accumulator.gd` is a separate RefCounted outer clock. Its entry point is
`advance(frame_seconds)`; neither class contains engine callbacks or reads clocks.
A future §10.1 driver may supply elapsed time, but this increment adds no UI/driver.
No raw frame time reaches `step()`. The scanner is unchanged (including its ban
on raw-time callback identifiers).

The fixed step is `physics_one / physics_tick_hz`, shipped at exactly 1/60,
consistent with accepted DistanceConstraint. `physics_fixed_dt_s` remains the
unchanged serialized mirror; M0-D05 records its decimal parsing difference.
The solver freezes a duplicate of supplied tuning at setup, requires the shipped
60 Hz contract, and uses supplied gravity, position iterations, distance repeats,
linear damping and velocity clamp. Semi-implicit Euler applies gravity, then
per-tick linear retention (one minus damping), clamps speed, then drifts positions.
After index-ordered distance projections, velocities are reconstructed and
clamped. Pinned mathematical points remain fixed. No angular/velocity-constraint
passes, contact, sleep, hard-reset/recovery, creature or feel acceptance is implied.
No tuning constant/value is added or changed.

Body order is caller-supplied part-index order; link order is caller-supplied
constraint-index order. Setup copies the arrays, rejects duplicates/foreign link
endpoints and preserves this order; it never sorts by object IDs or dictionaries.
The fixed graph/configuration is included in snapshot identity. Restore validates
all candidate bodies/links before publishing; a failed step rolls back the whole
tick, and a failed frame rolls back all ticks in that frame. Non-finite input/state
is reported as an error, never silently healed. Snapshots include velocities,
previous positions, multipliers, tick count and all outer-clock future state.

The clock retains fractional time below the catch-up cap. On reaching the supplied
cap (3), it drops the entire remaining time, including any fractional remainder,
and records the exact dropped seconds. It computes remaining time as accumulated
seconds minus executed steps times the fixed step. Chunk-equivalence tests avoid
cap-triggered dropping and compare equal simulated ticks; dropped wall time is not
replayed. Chunk comparisons cover solver snapshots and clock pending/dropped
seconds; last_steps is a frame-local diagnostic, not a trajectory input. This is
a primitive clock contract, not A9.4/A9.5 replay evidence.
M1-B01 and all creature-runtime acceptance gates remain unchanged/NOT RUN.

## M1 cleanup record — F16–F19 (no geometry)

F16 raises A8's M0 floors to the measured476 engine /489 combined (13 original
Python) atcb4a0d9. Removing the accumulator's compile assertion must now fail;
no M0 tests are removed or weakened. Historical475/488 records remain historical.
F17 propagates a failed frame rollback's Error instead of the original tick Error;
a test double forces a changed solver plus failing restore and checks that exact
failure reaches the caller. This is not a successful recovery or an atomicity pass.
F18 retains both per-tick and per-frame snapshots for the current public APIs:
standalone step is transactional; advance is transactional across multiple ticks.
No performance optimization/measurement is claimed. Before §10.4 signoff, measure
both current mode and any frame-only candidate on30 bodies/120 constraints, with
identical atomicity assertions, and label each result's configuration. Frame-only
is NOT implemented or measured; neither mode currently has tick-cost evidence.
F19: A9.5 varies outer frame delivery, not the shipped fixed60 Hz simulation or
DistanceConstraint's independently injectable mathematical test rate.

## M1-D04 — Owner contact geometry / grip inputs (provisional)

Owner decision supplied2026-10-28. Full derivation imported byte-identically from
`arena/5b72e4ab-clamber` at `ad9fbbcb57e1f9cdfcb720cfe616d13221991480`, ONLY
`.review/M1_B01_CONTACT_GEOMETRY_DERIVATION.md`:281 lines, SHA-256
`6453508be7cb808f643544ec3f3fdbd6560840876fc070511f4b5f50065dbc5e`.
Hash verified before reading/using the file. Commit A0ee3548 was pushed and green
(M1 CI40670975708, M0/Android CI40670975949) before this geometry work.

Collision radii in WU: limb0.065, passive0.085, motor0.095, foot0.050, head0.100.
Art-only visual radii in WU: limb0.065, passive0.105, motor0.120, foot0.065,
head0.135. Visual fields are declared in Tuning but MUST NOT be referenced by
other core scripts, including dynamic property-name lookups. Tests enforce this.
No physics state gets a visual radius or eye-look-at input (INV-10).

Root head: mass per WU2.2, length0.35, derived mass0.77. No parent hinge or angular
limit. It collides with terrain and with parts at hierarchy distance≥2 per D-10.
Foot grip uses normal_force_last_tick >= max(5.0, 0.40 * sum(m_i) * abs(g)),
conditioned on an actual ground contact; airborne never grips. The 0.40 ratio and
5.0 floor replace any earlier absolute-threshold idea. Existing foot bias1.4,
static slip0.15, GDD§3.2 masses/lengths/friction/stiffness/torque are unchanged.
M1-B01 is RESOLVED (owner inputs supplied), not a claim of implemented contact.
M0-B03's grip-input portion is resolved; haptic/generator inputs remain open.

All additions are named exports/resource values/inventory entries sourced
"owner M1-D04", including D-10 bend margin0.06 and the owner feel-check constants.
D-10 requires each distance-two pair's radius sum STRICTLY below
joint_length - contact_slop - bend_margin =0.22; reaching the bound fails.
Every collision radius must strictly exceed contact slop. Tests cover all25 kind
pairs and three topology-only preset fixtures (Slug3/Hopper8/TwinRoller6), including
sibling distance-two pairs. These fixtures choose no rest pose/gait and are NOT
runtime presets/captures; future authored runtime presets must run the same guard.

FA-1 uses width-derived150px/WU only for analytic readability, not camera setup.
FA-2 checks all eight limb lengths. FA-7 checks visual HEAD dominance in all three
fixtures. FA-3 static600-tick scenes, FA-4 settle/sleep and approximate one-length
lurch, FA-5 grip band, FA-6 ten-run success count remain NOT RUN until actual
contacts/motors/scenarios exist. Harness plans/evidence slots must not default to
successful observations. FA-4's approximate lurch is recorded as distance/body
length, not an invented numeric acceptance band. FA-6 must report actual counts;
do not inject random variations into identical deterministic runs to force6–8.
These are provisional design inputs, NOT measured feel evidence. If an owner value
must change to satisfy any FA/AC, STOP, report measurements and ask; no silent
retuning, tolerance widening or weakened assertions.

**M1-B04 — FLAG ONLY, unresolved camera/chunk scale:** GDD line569 width7.2WU
at1080px implies150px/WU; line797 height8.0WU at2340px implies292.5px/WU.
Neither is chosen for runtime/camera. No camera, M2 or product-screen work.

The owner explicitly lifted the earlier feature-work stop. After Commit B is
pushed/green, creature bodies/feet/contact response are authorized as the next
separate M1 increment, followed by actual AC traces/captures. No new permission
for M2/camera is implied. M1-B04 is flag-only, not a blocker to M1 contacts.

## R7 — F20/F21 gate and float-noise corrections

Owner accepted A/B@0668d66. F20 adds FA-1..7 to the guarded gate table. Only exact
FA-1/2/7 may use PASS (analytic only), citing a CI run or owner-geometry JSON path;
FA-3..6 stay NOT RUN. Out-of-table FA claims are rejected, including the original
prose/checkbox bypass. No runtime claim follows from analytical evidence.
F21 authorizes pixels+1e-9 >= target, test-harness-only float noise allowance, not
legibility slack or new physics tuning. Real0.5px loss and errors larger than the
specified allowance still fail. Collision radii and derivation bytes are unchanged.

## M1-D05 — Part3a production definitions and contact primitives

The first Part3 increment promotes the accepted3/8/6-part topologies into actual
engineering preset JSON definitions in data/creatures/, with cardinal rest axes
(quantised0/90-degree directions) and the shortest existing limb slot. These are
authored engineering rest poses, not approved gaits or a tutorial scenario.
CreatureModel derives masses/lengths/radii from unchanged tuning and precomputes
D-10 hierarchy-distance≥2 candidates, including feet for the universal geometry
guard; the actual self-response mask excludes layer11 feet per GDD4.4. Geometry harness reads these real definitions,
not a separate test topology. Codec/general builder validation remains deferred.

Capsule bodies own two float64 endpoints of half the derived segment mass each.
A signed-distance grid uses the existing0.25WU cell size and explicit caller-owned
terrain samples/material. The capsule contact primitive projects sampled points
along the segment and sweeps between previous/current points at grid spacing,
retaining the entering-side normal when projecting a crossing (including a closed
slab whose start/end positions are both clear),
and applies normal/restitution and tangential response in stable sample order.
Only actual FOOT_GRIP parts may get the bias, only when lowest/grounded and prior
measured normal force reaches max(floor,ratio*creature_mass*abs(g)). No default
non-foot friction or terrain material is invented: material inputs are explicit.
Contact rejection (undefined/out-of-grid normals, non-finite state, excessive
projection) leaves the live body untouched. Projection-limit errors are reported,
not silently respawned; public Sim recovery is not implemented by this primitive.

These kernels are not yet a coupled creature/contact/hinge solver. Tests exercise
real contact projections and velocity changes with controlled foot load fixtures;
that is NOT FA-5 whole-creature stance evidence. FA-5 remains NOT RUN until coupled
foot-load traces, before FA-3/static scenes or AC claims. Motors/limits, self-contact
response, sleep/recovery and full Sim replay are still outstanding. No owner value
is retuned and no new force/slip tolerance is invented.


M1-D05 export plumbing: production preset JSON is non-resource data, so the
Android preset explicitly includes data/creatures/preset_*.json. The existing
AAB/APK inspector now checks exact packaged preset bytes, with missing/modified
negative fixtures. This is packaging for M1 definitions, not M2/product UI or a
redo/extension of the M0 device waiver. Native/manifest/alignment checks remain.

The exact-load component test exposed floating-operation grouping at40%: compute
creature weight before applying the ratio. This changes no physical constant or
tolerance; no force epsilon was added and the exact-boundary assertion is intact.


## M1-D06 — Owner R8/F24 approval; force-channel first increment

The owner APPROVED per-foot expected share, not creature-level summed eligibility
or capping builds/feet. Both alternatives are rejected: summed eligibility can
lend an underloaded foot another foot's force; a cap conflicts with the third-leg
reward. T=max(5,0.40*W/N), with N frozen from feet's post-resolve grounded flags
at END of the previous tick; N0 disables all grip. Grounded is ONLY the existing
post-resolve sample-inside-radius+slop flag. No persistent N field, proximity
predicate, hysteresis, grace, decay or gate damping is added. Touchdown/lift-off
must expose the next-tick step. Slug N1 remains17.36N; the unchanged5N floor binds
for Slug-mass arithmetic at N>=4 (5/10.85 approximately0.46).

The owner explicitly requires an addendum in the derivation file in the SAME
commit as code/FA-5 row. Original281 lines/SHA6453508... remain byte-identical;
append-only attributed addendum is independently hash-pinned. This authorized
append is not a retune or a rewrite of the pinned original.

First increment separates caller-owned applied_load_n from measured_reaction_n
(velocity contact impulse/dt) and positional_cleanup_n (position correction/dt²,
NOT physical support). Contact response never assigns a measured/cleanup value to
applied_load_n. Frozen-N batch response stages all bodies before publication;
component tests actually restore completed flags and continue, including reversed
order and lift-off. The old max(position,impulse) support estimate is removed.

IMPORTANT: no producer of coupled applied load is claimed by this increment.
F22 remains OPEN until real gravity/hinge load transfer and Slug's600-tick trace.
The owner's same-tick steady support tolerance is0.723N for every last300 ticks,
not0.723333...; report all raw transient imbalance/toggling. A quiet contact's
zero impulse output is not a gravity-support estimate. No synthetic qualifying
loads may migrate from the component tests into the production coupling path.


## M1-D07 — R9 coupled engineering load producer and unfiltered diagnostic

R9 accepts step1 only; F22/F25 remain open pending real force balance. The new
CoupledLoadProbe is an engineering bridge on production-model CapsuleBody's SAME
SimBody endpoints, not the public Sim. It integrates gravity, rigid distance rows
and two translational rows per parent/child hinge. Rotational freedom is genuine:
angular limits, motor torques, self response and sleep optimization are NOT built.
There is no root parent hinge. All rows remain physically awake; logs explicitly
say sleep_implemented=false. No stance/sleep/determinism acceptance follows.

Velocity constraint impulse is measured BEFORE mutating endpoints, applied equal
and opposite, accumulated per segment. Applied compressive load is the positive
projection of that segment's actual gravity impulse plus its signed inter-segment
hinge impulse onto the terrain normal, divided by dt. Bone-internal impulses cancel
in a segment's total. No whole-creature weight shares or contact position corrections
enter this producer. Contact reaction remains independently computed by the accepted
capsule contact velocity response. Impulses from both velocity passes are summed,
not averaged or divided by an observed factor. Positional cleanup is separate.

The new bridge damps existing velocity before adding the full external gravity
impulse (v*=1-damping; v+=g*dt). This is documented integration ordering, not a
change of any tuning value. The accepted independent PointLinkSolver is untouched.
Rigid/hinge positional correction is deliberately NOT converted into applied-load
velocity impulse. Six position iterations/two rigid solves and two velocity passes
remain the resource values. No extra iterations or convergence epsilon is invented.

F27: resolve() is documented fixture-only. The coupled path calls ONLY batch
resolve_tick. For each internal velocity pass it restores the tick-start grounded
flags before that batch snapshots them. N remains the same previous-completed-tick
count throughout; it is not cached as new persistent state. Trace prints that N.

F28 lowest geometry: Y is up. Candidate capsule contact height is
min(endpointA.y,endpointB.y)-collision_radius. A part is co-lowest when its height
is within existing contact_slop of the minimum across the creature. This ONLY
computes eligibility, never grounded; actual grounded is still the one post-resolve
sample predicate. An unequal-height/order-reversed fixture proves exclusion and
that the query never mutates grounded. CapsuleContact alone owns contact flags.

Diagnostic conditions: unchanged Slug JSON/rest axes, spawn(0,0.33) (foot at
radius-slop before prediction), zero initial motion, explicit flat SDF. The test
passes uniform foot-material friction/restitution as diagnostic materials for all
parts; this is NOT a new default non-foot production material. No pose, mass,
radius, stiffness, force gate or tolerance is retuned to obtain a passing stand.
A free-hinge model may topple or rest on non-foot capsules; other-body reaction is
therefore printed too. Findings are not silently fixed by a different rest pose.

F26 independent unit integrates an isolated0.30-mass foot under-28 gravity and
checks the two-endpoint reaction converges to8.4N, not16.8N. The earlier no-gravity
slop fixture's zero impulse is not generalized to a gravity-loaded contact.
The raw Slug600 trace prints EVERY tick, all three per-foot sums, hinge/gravity
impulses, penetration, previous N, eligibility, grounded/grip and actual awake
state. Python independently re-sums channels and requires BOTH force sums vs43.4
AND their difference <=0.723 throughout ticks300..599. Positional never compensates
for missing reaction. Findings exit nonzero and remain in CI artifacts; no
continue-on-error, smoothing, tolerance widening or hidden transient clipping.
Complete-creature determinism attempts remain0. FA-3/4/5/6 remain NOT RUN.


## M1-D08 — R10 correction, accepted producer; authored pose decision pending

R10 owner review CLOSES F22/F23/F25: actual gravity plus signed hinge impulse is
accepted as the qualifying load producer; isolated reaction8.4N and independent
all-terrain support validate conservation. Preserve the implementation/tests.
R10 explicitly corrects the OWNER'S R9 wording: compare weight with the sum over
ALL grounded contacts, not just feet. Foot-only43.4N is required only if the foot
is the sole support. R9's foot-only force-failure diagnosis and proposed angular
constraints as the next fix are superseded.43.59610684435376N passes the literal
43.4±0.723N ceiling; foot-only underload is not a force-channel defect. F27/28/29
remain accepted; F24/frozen previous grounded N and intentional lag are unchanged.

F30 is MAJOR pending the owner's pose decision. R10 recommends A (author foot
axes so pads are lower than their own subtree); this recommendation is NOT an
approval. B radius changes are rejected in review (pinned FA-1/7 radii). C sprawl
is only partially defensible for Slug, not the two-foot demonstration. No A/B/C
branch, angular limits, mass/radius/axis/force-gate/D10 or solver-setting changes
are authorized by this diagnostic work. Limits cannot fix authored geometry or
supply a restoring torque. The cheap root(0,0) analytic audit prints every part's
bottom=min(endpointY)-radius and flags every non-foot below any foot. It does not
silently change the authored model or promote analytic FA checks to runtime.

F32 telemetry now includes START and completed endpoints/bottom for EVERY body;
start tick0 retains the authored gap before terrain projection masks it. Endpoint
velocities/inverse masses allow an independent Python reconstruction of total
momentum. F31's +0.19610684435376N all-contact bias is NOT waived: a diagnostic-only
ledger measures gravity, damping, clamp, internal-row and contact momentum changes
without feeding them into physics. The flat-SDF identity is
  dP_y = J_gravity + J_damping + J_clamp + J_internal + J_contact
  R-W = (dP_y-J_damping-J_clamp-J_internal)/dt.
Contact momentum change is measured independently across each real batch and
compared with summed reported reaction*dt. Internal rows should cancel; keep their
measured floating-point residual, do not assume exact cancellation. Nothing is
subtracted from the acceptance force. Bookkeeping identity tolerance1e-12 is only
float64 arithmetic/serialization checking; the literal force ceiling gets NO epsilon.
Actual numeric explanation requires pinned-engine measurements, pending at this
commit; damping is a hypothesis until then. No restitution/damping retune.

F33 reports "grip never engaged", not an empty toggle-list success. The report
separates correct all-grounded force acceptance from actual foot/grip engagement;
CI stays RED without a genuine foot load path even if conservation passes.
No qualifying production load is injected; synthetic parser falsification is NOT
physics evidence. FA-3/4/5/6 and all coupled AC/A9/replay/soak/timing/§10.6/captures
remain NOT RUN, determinism attempts0. Next M1: read measured budget/geometry,
await owner pose decision; no band/two-foot advance or M2.


M1-D08 measured follow-up @bc4202a / pinned CI40694232799: last300 end/start
P_y=+0.1634223702948058..0.16342237029480586Ns. Measured J_damping=
-0.0032684474058961143..-0.003268447405896114Ns, J_clamp=0, |dP|<=2.78e-17Ns,
|J_internal|<=1.12e-16Ns. Thus replacing the damping drag requires
-J_damping/(1/60)=+0.196106844353767N support in addition to43.4N gravity.
Predicted bias0.19610684435375852..0.19610684435376852N matches observed
0.19610684435376413..0.19610684435377124N; global ledger residual<=1.12e-15Ns
and independent batch-velocity/contact-reaction discrepancy<=5.56e-16Ns over600.
F31 is now quantitatively explained by measured terms, not assumed/waived. This
supersedes the earlier pending hypothesis in this decision's initial entry.
Further parser checks verify damping=-resource_damping*raw_start_P_y and internal
cancellation; do not correct force channels. Geometry matches R10's authored gap
calculations. Pose decision STILL PENDING; no angular-limit or pose branch.
