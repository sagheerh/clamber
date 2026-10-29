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


R10 final implementation verification be04bbf / CI40695219730:600 rows, ledger
verified including independently reconstructed damping, all-contact literal gate
passes, check RED solely for F30. Peak scope clarified: measured9.695448846059607N
is LAST300, whereas ALL600 measured peak14.81106559439147N and applied peak
14.807263336585688N are still below17.36N. Grip never engaged. No transient clipping
or false no-toggle success. No pose branch authorized; F31/F32/F33 evidence supplied
for review without assigning an owner acceptance verdict to those minors.


## M1-D09 — R11 closure and forward measurement-only limit-cycle diagnosis

R11 owner CLOSES F31 after independent reconstruction of raw endpoint momentum,
resource damping, all-contact support and real clamp measurement. Conservation
F22/F23/F25/F31 is CLOSED. Preserve those checks and the two algebra-balanced but
physically fake ledger controls; components are NOT complete-creature determinism.

F35 forward MAJOR: steady nonzero velocity field with repeating positions is NOT
rest. Before any fix, record EVERY part's endpoint/COM speed, all600 momentum decay,
and measured per-endpoint displacement contributions from integration, distance
rows, hinge rows and contact position projection. Log predictor-vs-completed-v
phase offset too: end-of-tick v*dt is not the actual same-tick predictor displacement.
No changes to0.02 damping, no velocity epsilon/sleep predicate, no behavioral fix.
Run isolated diagnostic-only position-iteration samples1/2/4/6/12/24; source default6
is NOT changed/adopted. Results and mechanism attribution require actual runtime,
pending at implementation commit; do not infer which phase pumps from source alone.
The observed last300 P envelope defines a descriptive plateau-entry tick only,
never a rest tolerance; exact-constant suffix is reported separately without epsilon.

F36: synthetic lowered-motor pose must trip the shared audit now; flags become
hard production assertions in the authorized pose-decision commit, NOT before.
F37: retain existence-only boolean but ALSO print last300 grip fraction and foot
share of ALL grounded measured reaction; no new sustained-support threshold.

F30 remains the only red gate and owner pose decision is PENDING: A pose-axis rule
recommended, B pinned radius changes rejected, C sprawl/re-target requires decision.
Do not implement A/B/C or angular limits. Order is F35 instrumentation -> unchanged
baseline + diagnostic sweep -> owner pose decision -> pose+F36 assertion -> FA-5
band. FA-3/4/5/6 and all other coupled runtime gates NOT RUN; determinism attempts0.
No retune, M2, or captures. Geometry unchanged outside synthetic test bodies.


M1-D09 first measured follow-up @21a9174 / CI40699163425: all600 baseline position
and speed identities verified; first tick inside final observed P envelope66;
exact-constant final suffix absent. Per-phase ledger identifies contact projection
as the main vertical cancellation for head/motor/footB, but HINGE rows lift footA.
Prediction integrates damped previous v+gravity (downward), not completed upward v.
Six isolated iteration probes all complete: increasing1->24 changes peak norm only
.2019055601->.2019043696WU/s, leaving a nonzero floor. No new value adopted.
Y/bottom repetition is not full position stasis: measured X drift≈−7.175e-6WU/tick
at599; head bottom also changes during the initial falling transient. F35 is a
forward measured issue, not a rest/sleep pass or a behavioral fix authorization.
F37 measured grip fraction0; foot support share≈.222392538, no new threshold.


## M1-D10 — R12 nonzero equilibrium, spawn-only experiment and separate sleep decision

R12 owner CLOSES F36/F37 and accepts instrumentation. Preserve all F31 checks,
F36 two-sided real-body lowered-motor control, F37 existence-vs-sustained metrics.
Hard production pose assertions still land in the authorized pose commit.

F38 supersedes any reading of F35 as an iteration-convergence defect. The six
iteration results approach a NONZERO P_inf≈.1634223589Ns; observed envelope entry
127/77/67/66/65/64 improves while the live field remains. More iterations reach
that model equilibrium faster; they do not remove it. No adopted iteration value.
The ONLY new physical experiment is600 unchanged ticks from y=.33/.53/.73 with
configured6 iterations, same model/materials and zero initial motion. Report all
final300 P ranges plus final/mean; pending at this code commit. Do not choose a
rest attractor/sleep definition or discuss a behavioral fix before this evidence.
Finite600 data are not a mathematical proof of global attractor existence.

FA-4 "asleep" definition is an owner decision SEPARATE from F30 pose. Options:
positional stillness, an owner-authored threshold above the velocity floor, or a
model change. None is selected/implemented; no velocity epsilon or damping change.
F30 A/C decision pending, B pinned-radius changes rejected, no pose/limit branch.
Order: spawn experiment -> owner pose AND asleep answers -> authorized pose with
hard F36 assertion -> only then FA-5 band. FA-3/4/5/6 NOT RUN; determinism attempts0.

F39 is a forward SOAK finding, not an FA-3 blocker: extrapolate late baseline
|dx|=7.1751877234e-6WU/tick to600/3600/10000/18000 ticks. At reference150px/WU,
these are .004305/.025831/.071752/.129153WU or .646/3.875/10.763/19.373px.
NOT actual long runs; persistence is assumed and no bound established. Report
reviewer's Gauss-Seidel zero-mode interpretation as a hypothesis, not a proved
cause: a single endpoint's completed vx*dt is not the integrator predictor or
whole-creature COM motion. The existing raw phase/start-v ledger can establish
mass-weighted COM attribution without another experiment. No friction/order fix.

F40 at requested reference150px/WU: motor prediction .977/.939px down and contact
projection .985/1.527px up per60Hz step; net Y is float noise. Record beside FA-3
so numerical churn and possible feel buzz are not investigated twice. This is an
INTRA-STEP excursion proxy, NOT a rendered/captured 60Hz bob measurement. No render
sampling/interpolation assumption or new runtime camera scale adopted. No M2 or
captures. Original derivation/tuning/presets/contact/body/hinge unchanged.


M1-D10 measured follow-up @8463240 / CI40710677636: y=.33/.53/.73, all unchanged6
iterations/zero motion/600 ticks, give identical final300 P range
[.1634223702948058,.16342237029480586]Ns and mean.16342237029480583Ns. Final values
.16342237029480583/.16342237029480583/.16342237029480586Ns; observed envelope entry
66/70/73. Common nonzero COM vy≈.1054337872869715WU/s, max endpoint norm
.20190439092127008WU/s. This supports a shared observed equilibrium for the three
requested starts, NOT sleep acceptance or a proof over arbitrary spawn states.
No predicate/threshold/model/pose chosen; owner F30 and asleep decisions remain.

F39 causal precision: at599 baseline mass-weighted COM dx=-7.175187723425593e-6WU,
actual integration dx=-7.175187723396494e-6; distance=-2.927783044006219e-17,
hinge=+1.789698646617957e-19, contact=0. Raw retained START vx independently gives
-7.175187723393609e-6. COMPLETED vx*dt COM=-7.321620125911735e-6. The endpoint
18x comparison does not establish displacement without velocity: integration
accounts for net COM translation, while internal rows redistribute per-point
positions. Friction irrelevance/position-order injection are NOT proven. This is
analysis of the same existing trace, not an extra experiment or fix. Real creep
and all requested soak extrapolations stand; none is an executed soak gate.


## M1-D11 — R13 reviewer correction; F41/F42 read-only diagnostics

Owner R13 closes F38 and accepts F40. Keep the shared observed nonzero equilibrium
for the three starts, not a global-attractor proof, and internal phase amplitude,
not rendered buzz. No additional iteration/spawn experiment or model/rest choice.

F39 **REVIEWER CORRECTION (not an agent error)**: reviewer explicitly withdraws
its prior position-injection/friction-blindness attribution after independent
mass-weighted COM recomputation. Actual translation is integrated from retained
velocity; inverse-mass-balanced distance/hinge rows cancel in COM while moving
individual endpoints. Do not defend the withdrawn claim. Earlier soak arithmetic
is unchanged and is neither an executed soak nor a current FA-3 blocker.

F41 MAJOR: instrument actual CapsuleContact._response candidates and responses,
not a presumed single contact. Opt-in detached scalar callback only; arithmetic,
operation order, iterations, body geometry, tuning resource and clamp unchanged.
Log tick/body/pass/sample-index/u, interpolated tangent before/after and retained,
endpoint XY velocities, normal/signed tangential impulse, inverse masses, normal
and separate positional cleanup. Count actual active samples for every body/pass;
re-evaluate earlier sampled tangents using body-end velocities and report residual
body/creature COM vx. Independent parser recomputes endpoint/impulse identities,
checks sequential continuity/final physical state, sums impulse vs F31 force, and
checks raw grounded sets/transitions. Preserve the old independent F31 controls.

Authorize isolated cloned Tuning .15vs1.5 slip diagnostics, fixed600/6/.33 and
zero initial motion ONLY. Original resource stays.15. Report full-run/steady
branch activation and COM drift; never adopt the sweep value or a friction fix.
Per-tick observer-on/off full physical snapshot equality is noninterference
coverage, NOT complete-creature determinism acceptance. Pinned engine pending
at this implementation commit; local89 synthetic/static Python checks pass.

F42 MINOR: log every tick's grounded set, new-grounded/lifted transitions and
per-contact impulses. Do NOT equate persistent grounded contacts with either
sleep-breaking or sleep-eligible. That clarification belongs with the owner's
separate FA-4 asleep decision. No acceptance criterion or sleep model changes.

Order remains owner F30 pose AND asleep/F42 -> authorized pose+hard F36 assertion
-> FA-5 band. Re-run F41 after approved pose (motor-belly.095WU support becomes
foot-pad.05WU support) and compare explicitly. No angular-limit/epsilon/damping/
retune/model/sampling fix, M2 or captures. Baseline F30 remains RED until genuine
foot support path. FA-3/4/5/6/all coupled runtime gates NOT RUN; determinism0.


M1-D11 observed @de26fa3 / CI40802438116: both600-tick diagnostic cases complete,
all F31/motion and observer-on/off full physical states match. Every late tick has
actual head3/3, motor3/3, foot3/2 active samples per pass. Final-pass motor
u0->u.5->u1 all return retained0/tangent0 immediately; later samples reopen
u0/u.5 to+.0027983689378984/+.0013991844689492WU/s, leaving motor A vx
-.0027983689378984 and B0. Head likewise leaves A=-2.41613678290311e-5, B0.
This demonstrates actual overlapping sequential sample rows, not one-sample
assumption. Endpoint impulse identities verify within1.111e-16; no solver fix.

.15vs1.5 full600 active/static counts9917/9850 vs9909/9909 and max paired
COM vx difference.014493333006502587WU/s show transient sensitivity. Every last300
tick has17 active responses, ALL static in both cases (5100/5100); late paired
COM vx difference<=3.985e-17WU/s, actual mean COM dx≈-7.175187723414e-6WU/tick
and identical integrated mean dx=-7.175187723396494e-6. Resource stays.15. No
threshold/order/sampling adoption; re-measure after authorized F30 pose.

F42 late grounded sets always[0,1,2], zero new-grounded transitions but active
contacts and nonzero support impulses on all300 ticks. Raw all600 per-contact
impulses and grounded/new/lifted sets retained without classifying sleep-breaking
or sleep eligibility. Owner asleep answer must clarify persistent support contacts.
No FA-3 acceptance rewrite. Observer equivalence is not creature determinism;
byte-serialized snapshot strengthening PASS @5c1bffe / CI40802791884 on every600 ticks per case.
F30+asleep/F42 remain owner-blocked; FA-3/4/5/6/all coupled runtime gates NOT RUN.


D11 strict follow-up @5c1bffe / CI40802791884: independent active/skipped geometry,
normal/mass/cleanup and signed endpoint response identities all verify; both
threshold probes OBSERVED, baseline F30-only RED. Raw F42 transition sets in both
cases: motor/foot newly grounded at0, head at7, no lifted events across600. Final
sample normal impulses are retained per contact: nine positive in first pass,
eight zero in second pass, with signed tangential impulses in both. Persistent
support contact evidence is NOT a sleep-breaking interpretation. Thirteen new
synthetic controls,91 Python total; all34 previously accepted parser/control
methods and accepted F31 analyzer function source-identical. No tuning/physics
fix or pending owner decision is silently adopted. Runtime gates remain NOT RUN.


## M1-D12 — Owner R14 final A/A1 pose, positional sleep and transition-only contacts

Owner-authored approvals (2026-10-29), implement IN ORDER, not agent reinterpretation:
1. F41b answered before source edits: candidate intervals=ceil(current extent/cell),
   not rest length; first-pass positional cleanup changes foot extent across.25WU.
   Tick599 foot pass0 intervals2/candidates3/active3, pass1 intervals1/2/2;
   final extent.248830517515599WU. Both counts invariant to endpoint velocities
   with fixed current/previous positions+terrain; velocities indirectly affect
   future geometry through integration. No direct velocity-dependent sample count.
2. A: change ONLY foot axis to DOWN in all3 catalog JSONs. A1: preserve TwinRoller
   foot5 (parent0) explicitly as non-support stub; exemption list EXACTLY that foot.
   F36 hard catalog bottom assertion in SAME pose commit; original two-sided
   synthetic bad-pose control retained on its original horizontal-foot fixture.
   Paired pre/post Slug600 uses same.33/6/.15/zero-motion, no sleep/retune. Raw
   everytick supports and F41 samples retained, report measured grip, not "fixed".
   Hopper (feet5/7) supplies future two-foot grip branch, NOT TwinRoller stub.
3. Sleep: owner constants sleep_still_displacement_wu=.001, sleep_dwell_ticks=30.
   Maximum per-body per-tick COM displacement strictly below.001 for30 consecutive
   ticks -> park, zero all endpoint velocities, sleep_state asleep. Input fully
   re-arms, record wake tick. Snapshot all dwell/wake state; restore replay exact.
   Sleep parks the plateau, DOES NOT FIX it: play may retain endpoint speed≈.202
   WU/s (30px/s at150px/WU), feel risk for motor stage, not a fix authorization.
4. F42: sleep-breaking means body ungrounded->grounded WHILE ASLEEP. Persistent
   support impulses are not violations. No impulse threshold/second constant.
5. Then motors/angular limits/self-contact; Hopper two-foot FA-5 and all3 FA-3/4;
   public Sim wiring LAST. FA-3/4/5/6 NOT RUN until genuine gate traces exist;
   complete-creature determinism attempts0. No M2/camera/screens/captures.

R14 confirms F41 sequential overlap mechanism and closes static-slip hypothesis:
keep.15 resource,1.5 diagnostic only. Re-measure AFTER A, never tune toward smaller
creep. Identical old drift with DIFFERENT contact geometry -> STOP and re-derive;
unchanged drift/contact mechanism elsewhere -> report for later owner decision.
No damping/radius/mass/grip/gate/limit constant edits, no new epsilon/hysteresis/
decay/grace/contact fix; only TWO approved sleep tuning additions at sleep stage.
Pose measurement pending pinned engine in this commit, no physical success claim.


D12 pose evidence @126dc80 / CI40804352094: authored audit passes but dynamic
sole-foot expectation is NOT observed. Before grip0/600, after1/600 at19, late
fraction0 both. Late all3 grounded/17 responses unchanged; dx -7.175187723414263e-6
->+9.337328797577746e-6WU/tick (larger magnitude, reversed). This fourth outcome
is neither pose-artefact downgrade nor identical-drift/different-geometry trap.
Retain F41; do not tune. Root spawn remains.33, so new authored foot pad initially
at-.27WU, not a clear pad-on-floor spawn; free-hinge solver still has no angular
limits. Report raw supports and avoid claiming maintained posture from authored
axis alone. Next approved step is sleep, not a contact/pose/spawn retune.

D12 sleep commit: adds ONLY the two exact owner constants, source-commented and
inventoried. Snapshot-only positional CreatureSleep + engineering SleepingLoadProbe
composition, existing always-awake diagnostic untouched. On sleep, park and zero
all endpoint velocities; input re-arms, records actual asleep->awake tick. F42
new grounding WHILE asleep wakes with NO impulse threshold; persistent contacts
are not violations. Existing contact resolver runs on detached clones for parked
contact observation only; no mutation/qualifying-load injection into real bodies.
Restore includes dwell/sleep/wake state; component+real-probe replay tests compare
full serialized continuation from partial-dwell/asleep checkpoints. NOT full
creature determinism/FA acceptance. Engine results pending in this code commit.

Explicit owner requirement: sleep parks the plateau, it does NOT fix it. During
play max endpoint speed≈.202WU/s=30px/s at150px/WU remains a shimmer/feel risk for
motor work, not now. No epsilon/hysteresis/decay/grace/contact fix. Motors/limits/
self-contact NEXT, then FA-5 Hopper and all3 FA-3/4, public Sim last; gates NOT RUN,
complete-creature determinism attempts0, no M2/camera/screens/captures.


D12 executed sleep @e36c407 / CI40805104578:3659 checks PASS. Sleep61/210/390,
input wake180/360 across600 engineering ticks. Restoring at47(partial dwell15)
and62(asleep) gives1091 subsequent byte-identical full physical+sleep snapshots,
including identical sleep/wake ticks. F42 persistent support/nonzero prior
support impulses do not wake; ungrounded->grounded control DOES wake. No impulse
threshold. This is COMPONENT/engineering-probe evidence, not complete-creature
determinism or all-preset motor-lurch acceptance. Attempts remain0.

Only two owner sleep fields added; previous400 resource entries unchanged. Scope
next remains motors/angular limits/self-contact -> actual Hopper two-foot FA-5
and all3 FA-3/4 -> public Sim last. No pending owner decision invented, no retune,
no plateau fix claim. Sleep parks the plateau;≈.202WU/s awake shimmer risk remains.


## M1-R15 — Owner verdict/order, F43 legal clearance and F44 count confounding

Owner accepts F41b, A/A1 and sleep; no new owner decision required. Binding order
supersedes R14: motors L/R contraction/angular limits/self-contact FIRST, same
increment legal BOTH-arm rerun + required main-trace per-body/pass intervals,
candidate count and active count, then F41 rejudgment; public Sim/F45/replay;
Hopper all four FA-5 branches and all presets FA-3/4; then AC-201/202/204, A9,
§10.6, tick cost and captures. No captures/M2/camera before that ordered stage.

F30-authored CLOSED — the audit proves foot pads at -0.205 (Slug, TwinRoller 4) and -0.235 (Hopper) below the lowest non-foot body, with exactly one documented exemption.

F30-runtime BLOCKED — not by the pose but by missing actuators. The hinges rotate freely, so the foot swings up and the head and motor bellies still rest on the ground: 17 active samples and all three bodies grounded after the fix, with the foot carrying 22.24 percent of support. With no angular limit and no motor torque, the lowest-energy configuration of a limp chain is everything on the ground. The pose cannot constrain attitude.

These are the owner-supplied baseline statuses. Actuator source is not itself
closure evidence. Historical shipped-preset first grip tick19 is exactly one tick,
toggles[19,20], steady fraction0: PATH EXISTENCE ONLY.

F43: derive the root from actual authored capsule surfaces, lowest surface+.01WU
above floor. Preserve .33 explicitly as historical over-penetrating spawn. F44:
foot length=.25/cell=.25 sits on the ceil knife edge, 3→2 candidates after projection.
Do NOT fix sampling/constants. Required main600 counts are checked against every
raw candidate; report both arms side by side. Mismatching count regimes confound
pose comparisons. F41 rejudgment is pending legal/count evidence. Landing depth is
owner-disfavored, not established causation; P barely changed/F38 height insensitivity.

Implementation increment uses existing spring k2400/c55, gain/torque/limits and
per-tick relative-angular-impulse cap6. Limits follow drive, with position row and
outward velocity block sharing the same signed net impulse budget across passes.
Inverse inertia is derived from the existing two endpoint masses (m/2 at each),
not a fabricated solid-rod mass distribution. Passive k900 return/±110° and motor
−140°/+40° are relative to authored rest. No angular limit on root/head or feet.
D10 pairs come from model.collision_pairs() once at setup; center spheres have
existing part radii, existing contact slop and normal-only response (no invented
self-friction). Self impulses are separately retained, never mislabeled hinge or
terrain support; positional cleanup still never qualifies grip.

The accepted baseline has no-op composition hooks; accepted analyzer/control
sources stay unchanged. For actuated engineering reports, raw angular/self
position phases first close independently, then a disclosed lossless internal-
phase adapter permits reuse of the accepted verifier. Original raw traces stay
unmodified. No resource retune, sampling/velocity epsilon/hysteresis or global
angular damping activation. This is NOT complete-creature determinism (attempts0).
F45 will document old .05/.6 sleep fields superseded (no unauthorized deletion)
when public Sim is wired, citing F38's velocity plateau. Accepted sleep unchanged.


### R15 legal/count remeasurement @35df327 / CI40810406262 SUCCESS

Four legal600 traces completed with observer-on/off physical equality and all
required counts independently matched to raw events. Actual roots .405 before /
.6100000000000001 after, lowest capsule+.010000000000000009 both. Historical.33
actual deepest surfaces -.065/-.270 remain explicitly over-penetrating evidence.
No sampling/contact/tuning change. New mechanics921 checks PASS; old suites pass.

Baseline last300 tuples(I,C,A) identical BOTH arms: head2/3/3 both passes, motor
2/3/3 both passes, foot2/3/3 pass0 and1/2/2 pass1. Legal mean dx before
-7.1751877234127456e-6 ->+9.337328797581247e-6WU/tick, difference
1.6512516520993993e-5. Thus F41 residual persists with legal matching steady counts,
not proof illegal landing depth caused it, not a failed authored-pose fix.

Actuated last300 dx .0003903690062867916 ->.000437169361675691,
difference4.6800355388899406e-5WU/tick. Count regimes DIFFER: head2/3/1 both passes
both arms; motor pass0(2/3/1)267+(2/3/2)33 before ->250+50 after, pass1(2/3/1)300
both; foot pass0(2/3/3)300 ->(1/2/2)300, pass1(1/2/2)300 both. Larger observed drift
is recorded, but pose-causal interpretation is NOT established under F44. F41
stays OPEN, no downgrade/repair/retune. Full600 histograms/raw counts retained.
All3 bodies grounded late, steady grip0 all4 cases. Actuated support share
.3057010100863977 ->.27408929671045956; no sole-foot/sustained-grip acceptance.

R15 machinery source does not retroactively close the owner's F30-runtime status
or mark any FA gate run. Next is public Sim/F45/replay BEFORE Hopper FA-5/all-preset
FA-3/4, per owner order. Component engineering replay only; determinism attempts0.


R15 strengthened controls @548b5c8 / CI40810712083 SUCCESS:106 Python and931
mechanics checks; four legal600 summaries repeat unchanged. F43 validator now
rederives clearance from raw START endpoints/radii, rejects fake legal metadata;
actual composed D10 overlap/impulse hooks independently tested (no terrain call or
qualifying load injection). Main-count/phase falsification controls remain; old
accepted analyzer/control suites unchanged. New runner completion floor931.
No production mechanics change or retune in this control-only follow-up.


## M1-R16 — accepted mechanics components, honest RED sustained-support gate

Owner accepts motors/asymmetric limits/velocity blocking/D10/CORDIC/F43/count and
spawn falsification controls, unchanged c641990 coefficients. Current mechanics
count is931, NOT preliminary921; Python106 and M0 514/0 reproduced. Components
are not coupled runtime acceptance or complete-creature determinism (attempts0).

F47: owner acknowledges F37 requested metrics but not their use in the gate, and
R15 “M1 green” did not check the impact-only flip. This is the OWNER'S reviewer
correction, recorded from R16; do not attribute a causal/acceptance claim to tests.
Exact replacement chosen: in last300 ticks, grip fraction>0 AND at least one
SAME-TICK grounded gripping positive-reaction single foot contributes strictly
>0.50 of ALL grounded velocity-level reaction. No aggregate-feet majority or
majority at a different time/foot; no positional cleanup. No new physical constant.
This is the F30 diagnostic door, NOT FA-5. Existing CI exit remains nonzero on
failure, with no bypass or weakening of force/F31/motion checks. Current data RED.
Eight new adversarial Python controls include actual CLI impact-only exit1;
accepted40-control file unchanged. No physics/tuning change.

ORDER: F47/F51 first; F48 convergence and own zero-input drift line; F49 separate
pre-fold angular/self position and impulse maxima, F50 post-pose .610/.810 legal
spawn comparison; public Sim/F45/replay; then FA-5(all4), all3 FA-3/4,
AC201/202/204,A9,10.6,tickcost/captures. No retune/epsilon/hysteresis/damping or
sampling change/injected qualifying loads/M2/camera/captures. Only the two already
landed sleep additions are authorized. Zero input is NOT unpowered: always-on
spring return remains live. Do not interpret R15's evolving last300 as equilibrium.
F41 stays OPEN; no premature closure from F50. FA-3/4/5/6/all runtime gates NOT RUN.


R16 F48 diagnostic extension (not physics): both actuated arms6000 ticks at mask0.
Zero-input own-line drift explicitly means live spring return, not unpowered.
Report600/3000/6000 windows; exact constant/repeating last300 COM(dx,vx) with>=2
observed cycles is the deliberately strict settlement criterion, no velocity
band/epsilon. Otherwise classify monotone/oscillating TRANSIENT and leave settled
value null, without interpreting a mean as equilibrium or absence as divergence.
All raw6000 observations retained, observer equivalence and raw continuation
F31/phase/count/contact impulse identities checked. Accepted first600 math is
unchanged beyond authorized F47; accepted40-control file untouched. Actuated F41
pair interpretation DEFERRED until settled. F47 remains mandatory RED exit.


R16 F48 executed @f6b852a / CI40812720624: M1 RED only at sustained-support gate;
both6000 arms OBSERVED with full continuation identities and observer equivalence.
Before settled value null, support fraction0/max share.3138574119247297/gatefalse.
No equilibrium inferred. Check annotations capped50, hiding later windows from API;
subsequent observation moved to its own checksum-pinned CI job (original gate still
fails overall, no bypass). Raw artifacts retain ALL observations, not only notices.

R16 F49 observation-only limit-block/self-contact event logs retain actual impulse
changes and individual collision vectors so opposite impulses cannot cancel out
of max reports. Separate angular/self max absolute net per-tick phase coordinate
WU, angular drive/block event max (mass*WU^2/s), self event magnitude(N*s), and
net impulse maxima computed BEFORE folding; adapter still refuses unclosed raw
ledger and keeps source unmodified. No physical behavior/order/value change.
R16 F50 post-pose root derived+.01/.21 (about.610/.810) BOTH baseline600 and
actuated6000; original pre-pose actuated6000 retained. Same pose, only authorized
+.20 fixture lift; no tuning field/retune. Validate ACTUAL raw initial surfaces.
Nonsettled window means are facts only, settled comparison null; F41 stays OPEN.


R16 @34b0cfd / CI40813196081: independent observation job SUCCESS, all5 cases
complete, original M1 gate RED only F47. Both original actuated arms6000 remain
oscillating, settled values null: before final300 mean dx.0003903690062867022,
after.0004371693616756641WU/tick; net3.51332105658/3.93452425508px/s. Similar
window bands do not prove equilibrium; no exact recurrence is not divergence.
F49 Slug angular max phase coordinates.009223146/.008874612/.009034440WU
(before/after/raised), drive max.044444719/.044386385/.044374511, limit-block
max.000177216/.000340027/.000566626 mass*WU^2/s; self phase/impulses0 (no eligible
Slug self pair). Source mechanics unchanged, only telemetry. Per-step10-notice
cap hid later F50 summaries despite complete artifact: pack notices<=3500chars,
assert<=10, no silent result loss. Raw count-period and repeat-lag differences
are observation ONLY, not a settlement tolerance or acceptance criterion.
Every diagnostic entry point now has an own zero-input drift line, including
historical pose/slip/spawn; spring live status explicit. No equilibrium claim.


R16 complete visibility @a6c33f8 / CI40813617730: all5 cases/17 report lines
retained in9 annotations. Observation job/static128/931 mechanics PASS; overall
M1 RED ONLY F47 support door, no bypass; original40 controls/tuning unchanged.
F50 .610/.810 post-pose final-window means: actuator through6000
.0004371693616756641/.00043716936167566446WU/tick (gap3.7947076036992655e-19);
baseline through600 9.337328797581247e-6/9.337328797582121e-6 (gap8.74138e-19).
Both observed vx envelopes overlap. Baseline counts match; actuator counts have
same6-tick pattern but different per-tick phase. This+.20 spawn change shows
binary64-scale mean differences; no premature F41 closure/landing-artefact claim
or nonsettled pose interpretation. Count periods9/6/6 with repeat-lag max vx
3.92048e-16/3.60822e-16/4.54498e-16 are raw recurrence observations, NOT an added
settlement tolerance. Settled values/comparisons remain null.
ZERO INPUT still LIVE RETURN: final3003.51332105658/3.93452425508/3.93452425508px/s
for pre/post/raised actuator; baseline post.0840359591782px/s at both spawns.
Full raw19200ticks artifact12871566645 SHA256
fb50e8157cb349b27da42de1d9a460dfd91701a92ba5e22fbc46a74ad7f7273e.
Only R16 ordered steps1–3 done; public Sim/F45/replay NEXT, not a new approval
blocker and not claimed done. All coupled runtime acceptance NOT RUN; determinism0.

## R17 Phase1 — F52 dwell window, F53/F54; F48 diagnostic authorization

Read reviewer-owned completion plan and R17 review via FETCH_HEAD only; neither
artifact copied/merged. Owner supersedes R16 order: F52 per-tick AND net per-body
COM displacement from the start-of-dwell snapshot, BOTH strictly below the SAME
.001WU for 30 ticks. Any failure/input resets dwell and origin. Origin snapshots
are future state, deep-copied/restored atomically. No threshold/physics retune.
Required translated .0005WU/tick falsification: old reference sleeps at29, new
predicate must never sleep; settled .000009337328797581247 fixture still sleeps.
Sleep remains composed ONLY with free-hinge engineering rig at this increment;
actuated public Sim not yet wired, so CI cannot yet manufacture FA-4 success.
F47/F49/F50/F51 CLOSED, FA-5 unchanged; F50 retires landing-spawn confound.
F53 reports dvx_direction_reversals, not positive-vx sign changes. F54 retains
raw zero Slug self-contact maxima: path exercised ONLY by units, not at scale.
F48 sweep ONLY physics_passive_stiffness900 vs0 as DIAGNOSTIC override. Slug has
one motor joint (stiffness2400), NO passive joint. Report live spring status by
actual arm, not by passive override alone. MotorDrive decomposition observes the
same pre-drive q/omega; signed contributions before clamp, no operation-order or
physics change. Await measured evidence before mechanism/remedy question.
No runtime acceptance measured here; 0/18, complete-creature attempts0.

## M1-R17-P2 — public Sim composition, preserving M0 signatures

Owner explicitly authorizes Phase2 immediately after Phase1 question, independent
of remedy answer. No spring/geometry/physics remedy adopted. Public setup retains
(creature,tower,seed,tuning) and original void step/restore signatures; explicit
last_status and failed signal expose failures; advance_frame returns status.
CreatureTickSolver implements the existing PointLinkSolver accumulator interface
using REAL ActuatedLoadProbe+CreatureSleep. Parent primitive integration is never
called; original accumulator and math tests unchanged. FixedStepAccumulator drives
ALL public ticks at1/60, held L/R bits applied before every catch-up step. Max3,
all excess dropped. Signals publish only after frame commit; rollback errors
propagate. Snapshot identity includes immutable creature/tower/physics settings;
clock, solver bodies/endpoints, contact flags/load channels, XPBD multipliers,
contact counts, joint rest/limits/impulses, held input, F52 dwell origin and RNG
are serialized. Detached candidate reconstruction makes restore atomic.
Seed reaches ONLY the owned xoshiro128** instance. Canonical 32-bit transition
constants are algorithm identities derived from existing integer identities, not
new physical knobs/tuning. Deterministic int64 seed expansion uses low/high words
and their complements (zero state impossible); independent canonical vector test.
No random consumers/physics perturbations invented where none are required.
F45 documents legacy .05/.6 as unused and superseded, citing owner F38. No deletion
or retune. result() now reports ONLY physics observations, not fabricated score,
flags, tutorial or gameplay outcome. state_hash preserves int interface; SHA256
state_digest accompanies every replay tick. Full snapshots include delivery clock;
frame/stall comparisons use full solver+RNG streams at equal simulated ticks and
retain/report distinct pending/dropped clocks rather than hiding their difference.
Attempt1 fixture: Slug, actual legal+.01 spawn, explicit uniform diagnostic .9/.02
material (NOT a new production default), seed305419896, 600ticks. Released first60,
alternating L/R60tick blocks thereafter. Three runs compare FULL tick bytes,
SHA256 and result fields. Falsification flips ONLY LEFT bit1 at tick0 (0->1),
checks actual body motion changes AND different final digest; equality is RED.
A9.5 separate protocol: actual SceneTree callbacks under --fixed-fps30/144, same
600 RELEASED-input ticks with live spring; every delivered frame duration logged,
solver remains60. Baseline intentionally missing initially; candidate generated
ONLY from pinned CI, missing baseline makes public job RED until committed/rerun.
All feel/creature runtime gates remain NOT RUN; no acceptance upgrade before CI.

R17 Phase2 executed attempt1 @0443138 / CI40817804303: full THREE600tick public
streams byte-identical (31,131,584bytes each), integer hashes3535650661 and SHA256
d735ea5f596f9a7b9bdfea0acee9b666a4e364e670f21dba9556985b7bfd19c8.
Exactly tick0 LEFT0->1 changed ACTUAL bodies and final SHA256 to
0f0f93a619d86a62f7485f3cbfcc2e0d7d19c1a76a609ab1e8e81c5a009fcf99.
9053 engine assertions0failures incl restore/rollback, chunk/stall, live-spring
sleep reachability:600ticks, never asleep, max dwell2. Attempt1 SUCCESS as a
same-build observation, not automatic acceptance. Frame harness SEPARATELY failed:
actual Godot startup frame.025s, then fixed-fps30 frames1/30; last frame601ticks.
Correct equal-count comparison uses first600 physical+RNG ticks; retain FULL601
stream, all elapsed frames and final pending/drop clocks as evidence. No clipping
of forces/observations, no solver/frame clock modification, no changed sampling.
Both actual startup frame and post-start fixed-fps support are recorded; the
prefix is an equal-SIMULATED-tick comparison, not invented equal wall duration.
F41 now buckets last300 by full per-body/pass(I,C,A) signatures plus per-body
buckets; raw min/max/means only. No tolerance, sampling change or forced closure.

## M1-R17-P2-BASELINE

Actual generated candidate from CI40818199967 @af6a6c9, job123264184894. Source
job was RED at the delivery support check (Python1/144 versus engine modal
.006944444444444445), NOT at replay. Three31,131,584byte full streams equal;
state digest d735ea5f596f9a7b9bdfea0acee9b666a4e364e670f21dba9556985b7bfd19c8
and full raw stream SHA256
05c27f020015dab2fc15ccad5cc963e5d064a8ed3247490a54e8f8ed57de1518.
Per-tick digest table SHA256
f9b6fdce63b77143a7187cde3760d023716f066d8f0a54ab93b36dcee737483f.
Fixture/seed/input/tuning fingerprint stored alongside exact hashes. Baseline is
NOT a pass until committed and matched by another actual pinned run. CI refuses
missing/mismatching baseline; intentional hash updates require this linked
DECISIONS entry to contain the new exact hashes, not just edit a fixture.
Actual modal frame durations:30 ->.03333333333333333;144 ->.006944444444444445
(one ULP above Python1/144). Both conditions' first600 solver+RNG tick bytes
already match. Capability probe classifies nominal CLI FPS via ROUND(1/modal)
integer identity; it never rounds, clips or substitutes ANY elapsed frame sent
to Sim. All startup/transient durations, pending/drop and full extra ticks are
retained. This is report-only nominal-FPS identification, NOT a solver tolerance,
velocity epsilon, changed sampling or weakened normative acceptance condition.
A mislabeled60FPS frame fixture under expected30 remains a mandatory rejection.

## R17 Phase2 measured — eight of eighteen, not M1 completion

CI40818428101 @e1934ed: public job123264928010 SUCCESS; M0 CI40818428107 SUCCESS
516/0+Android. Overall M1 RED ONLY original required F47. Independent raw stream,
per-tick hashes/results x3 and real body-changing tick0 LEFT bit falsification
verified. Attempt1 SUCCESS as a SAME-BUILD observation; no cross-architecture,
all-preset, soak or feel acceptance implied. Full measured metadata/18row ledger:
.review/m1_r17_phase2_evidence.json; raw public artifact12873442495 SHA256
0adba3ab612a4d8e5a31c750b50a6afbabcbda2ea1e3e738a3f8b13ded7b1f9e.
Actual frame callback streams first600 identical, full extra ticks/startup clocks
retained. Public9053/0, frame30 308/0, frame144 1446/0. Source Python140; four new
matrix-scope adversarial controls make144 local, awaiting exact-head CI. Other
components931/4897/381/237/136/80, M0 516 (original514 +2 automatic script compile checks). Phase1 had131Python,0/18,attempts0;
Phase2 now8/18,attempt1. No test-family count is a gate or determinism substitute.
Owner authorizes measured row upgrades; F15 guard now permits ONLY exact
(gate, PASS(measured runtime), CI+artifact-row) triples for1/2/3/9/10/11/12/13,
plus supporting A8 baseline alias (NOT9/18). Borrowed-row citations, old real run,
unrun creature gates and generic PASS still rejected. Original tests/floor12 and
FA-3/4/5/6 NOT RUN protection unchanged. All ten remaining runtime rows explicitly
NOT RUN with reasons; no 200run/7200tick/capture/perf/repeatability fabrication.
F41 full-body and per-body/pass count buckets measured, artifact12873517463.
Main A buckets vary substantially INSIDE a single signature; all exact-constant
flags false. Baseline identical counts retain different observed pose drifts.
F41 OPEN, not sampling-artifact closure or pose-causal claim. F50 spawn confound
retired per owner; F47/F49/F50/F51 CLOSED and FA-5 untouched. Permanent pre-clamp
motor return observed, but requested passive900/0 intervention has no passive
Slug joint to change. M1-D05 motor-return direction question sent; NO remedy
adopted, no stronger diagnostic stiffness intervention invented. Phase3 settle/
lurch blocked on that owner product choice; Phase2 required no wait and is done.


R17 final count audit @7d54449 / CI40819056901 + M0 CI40819056867: public,
spring/convergence/static jobs SUCCESS; M1 RED ONLY F47, M0 **516/0**, Android
PASS. Corrected Phase2 carry-forward514 before closeout: unchanged M0 test runner
recursively adds one compile assertion per script, and CreatureTickSolver plus
Xoshiro128StarStar add TWO. Original514 preserved, not reduced/replaced. Phase1
still correctly514 (before those classes). All current phase-specific counts now
explicit. Final public summary/hashes EXACTLY equal e1934ed; source140Python and
current144Python differ ONLY by four additional scoped matrix controls. Added
actual unittest count annotation so CI exposes the current total explicitly.

## R18 — accepted Phases1/2 retained; F56 before the approved A direction

Read reviewer-owned M1_R18_PUBLIC_SIM_REVIEW.md using git show FETCH_HEAD ONLY;
no reviewer artifact copied/merged. Owner accepts Phases1/2, closes F52/F53/F54,
verifies8/18. Prior passive900/0 sweep was OWNER's wrong-knob instruction, no-op
on Slug's motor2400; not proof of causality. M1-D05 option A is OWNER-approved
DIRECTION (settled-pose motor target); B/C rejected. But F56 must FIRST pass,
then the correct motor2400/0 sweep with damping unchanged must be MEASURED before
ANY remedy/calibration. Neither new constant nor retune authorized.
F56 literal requested identity is delta COM momentum == ground normal+friction.
Existing solver ALSO has explicit external linear damping and gravity. Measure
literal sides/residual WITHOUT subtracting/relabeling those terms. Separately
publish full Newton balance and contact-attributed delta with every omitted term
visible, using the EXISTING ledger precision1e-12. An internally closing full
ledger is NOT silently substituted for a failing literal prerequisite. Non-rounding
literal residual means STOP, no A or sweep until the prerequisite is resolved.
Observation-only x momentum phase columns + drive COM totals parallel existing y
ledger, unchanged solver operation order/physical arithmetic. Snapshots/hash/
baseline unaffected; existing raw/F31/count/contact proofs still mandatory.
F55 report-only .15WU/s=22.5px/s: baseline .08403595917823123 (0.373493percent),
before3.5133210565803203 (15.614760percent), after3.9345242550809765
(17.486774percent) of that allowance. This is a COM-drift unit comparison, NOT
proof each instantaneous contact sample lies in a static branch; no defect/leak
is inferred merely from these values. No change to static slip or sampling.
F57: injected seeded stream exists and survives snapshot/restore/hash/replay;
NO physics path consumes RNG. Standalone canonical vector tests do NOT mean
physics randomness exercised. Accepted A9.3 has this precise injection scope.
Runtime8/18 and determinism attempt1 retained. AC-201 and other ten runtime
rows remain NOT RUN; no acceptance claim from this prerequisite harness.


R18 measured F56 closeout @832fa3d / CI40820719982, external job123272312328:
last300 x raw momentum change -4.163336342344337e-16 vs ground friction
.24891888144391522, literal residual -.24891888144391563 mass*WU/s. Existing
external damping -.24891888144391586 explains this difference. Full x balance
residual -6.453171330633722e-16; full y residual3.544387006115812e-14, both within
existing1e-12. Y literal residual -215.78345997892384; gravity -217 plus damping
1.2165400210761605 accounts for normal215.78345997892384. Complete ledger and
per-tick/window internal conservation close; literal predicate remains FALSE.
This is NOT evidence of an internal defect and NOT authorization to rewrite
F56 or proceed. STOP applied: motor2400/0 sweep, A calibration protocol/remedy,
after-A drift and AC-201 NOT RUN. Owner A direction remains approved conditionally;
B/C still rejected. Owner resolution of the literal equation's omitted external
forces is required before continuation. No tuning/baseline/physical changes.
Runtime remains8/18, accepted attempt1 SUCCESS; current public summary EXACTLY
matches9a/sourcee193 strict baseline. PROGRESS/evidence ledger record exact sides,
CI/artifacts/counts and failed local ZIP retrieval honestly.


## R19 — owner resolves F56; motor-source falsification FIRST (no remedy yet)

Read reviewer-owned M1_R19_MOMENTUM_IDENTITY_REVIEW.md with git show FETCH_HEAD;
no reviewer artifact copied/merged. Owner explicitly owns the omitted damping/
gravity and closes F56 on the COMPLETE external balance. Preserve original
literal definition, numbers, failed predicate and exit1 behaviour as history;
R19 complete authorization is a separate named decision, not an overwrite.
All per-tick AND window internal-zero/damping/contact/raw-endpoint guards retained.

F55/F58/F59 mechanism story: authored static-slip allowance .15WU/s=22.5px/s;
existing walking arm .0008297296048130507 mass*WU/s/tick rectified friction,
.04978377628878304N (about .115percent body weight), balanced by unchanged .02
linear damping. Mean completed COM vx .02676547112300171WU/s (4.014820668px/s)
is NOT the positional net-drift3.934524255px/s; publish both, do not conflate.
Owner interprets the observed6-tick count recurrence/positive vx as a translating
rocking limit cycle, not a stationary equilibrium. Retain measured settled=false/
settled_mean=null and raw binary64 recurrence errors; no epsilon/exact recurrence
claim invented. For live spring AC-201 requires zero-input zero-net-motion as a
design property AND the existing settle/sleep-within4s gate; no relaxation.
F57 unchanged: RNG stored/restored/hashed, NOT consumed by physics.

ORDER: diagnostic motor stiffness2400 vs0, damping untouched, both drift and
signed rectified friction thrust/tick; no sum(abs) loophole. Use owner's explicit
1.74e-05 thrust reference as a conservative continuation screen, not a new
physical threshold or invented collapse ratio. If motor0 does not reach it,
STOP/report, no A/calibration/baseline regeneration/Phase3. Report drift against
.08403595917823123 reference separately. If supported, A captures ONCE at setup
with motor target tracking actual q EVERY zero-input tick (zero spring torque),
not spring-loaded target0. Settle protocol must use justified existing criteria,
record ticks/per-joint q, snapshot/hash target; remeasure awake post-A q rather
than prove stability by parking. Compare thrust<=1.74e-05 and drift vs.084 plus
fixed-point q honestly. Offset reduction alone not whole cause, never retune.
Legitimate A baseline regeneration requires raw generated provenance/strict CI.
Then Phase3 AC-201/202 and FA-3/4/5, no other gates silently upgraded. Current8/18;
no A/Phase3 implementation before motor falsification is actually measured.


R19 measured STOP @217eda1 / CI40864407948, motor job123415407058:
motor2400 drift3.9345242550809765px/s, rectified friction
.0008297296048130507 mass*WU/s/tick; motor0 drift3.9345242550808814,
thrust.0008297296048130529. Zero/live thrust ratio1.0000000000000027. Damping
.02/55 untouched; motor0 spring torque verified0 every tick, mean total drive
changes -1260 -> -108.72746136803042. Both complete F56 balances close within
existing1e-12; normal43.15669199578477N vs43.4, deficiency.2433080042152298N
inside ALL-grounded.723 allowance. This is an ACTUAL motor intervention and NO
thrust collapse, not a passive-joint no-op or ledger leak. F58's terminal mean
velocity prediction holds in both; eliminating spring stiffness alone is NOT
supported as the mechanism/removal of thrust. No remaining cause inferred from
persistence with damping/limits/constraints/contact still active.

Per owner ORDER1 STOP: A calibration/target-tracking settle/fixed-point proof,
post-A measurements, baseline regeneration and Phase3/AC-201/202/FA-3/4/5 NOT RUN.
Conditional A direction not revoked; cannot apply it against falsified prerequisite.
No new stiffness/damping/geometry/slip/sampling values adopted; no velocity
threshold/epsilon/hysteresis/waiver. F55/F58/F59 now adjacent in PROGRESS; F59
AC-201 zero-input zero-net-motion design reading retained with original4s sleep,
not a relaxed criterion. q mean in this sweep is NOT captured q_settled. Runtime
8/18 unchanged, attempt1 same-build success retained, cross-arch0. Current158
Python controls/public full summary exact Phase2/strict baseline preserved.
Next owner review of failed motor-source premise; no unrequested diagnostic.


## R20 — F60 R19 inference WITHDRAWN; F61 record-only; A WITHDRAWN; F63 teeth

Reviewer R20 read with git show FETCH_HEAD ONLY; not copied/merged. Owner withdraws
A (F62) and the earlier interpretation of motor2400/0 as spring-source falsification.
R19 numerical observations stay, but intervention is VOID/uninformative if applied
impulses are unchanged under saturation. Removing a torque component does not
necessarily remove the delivered impulse. Keep mean_clamped_total_torque forever.
F61 record-only: nominal inverse inertia sum about134.9992, bound about.0444447
angular impulse (mass*WU^2/s), deliverable torque about2.667 vs1260 authored
(.21percent). Global6rad/s relative-speed cap/inertia controls saturated strength,
not the authored torque knobs in THAT regime; no numeric correction adopted.
F62 spring-only unsaturated residual about.001111rad/.064deg is an arithmetic
screen, not proof including damping/absolute-speed caps. Record owner's withdrawn
A; no implementation, settled-pose calibration, baseline regeneration or Phase3.

F63 standing rule: every intervention reports requested impulse/bound/actually
applied impulse plus saturated_ticks/300, with constraint and absolute-body-speed
clamps separately reconstructed from RAW PRE-DRIVE endpoints/inverse masses.
Do not use authored rest lengths where actual extents differ. Extra impulse
return fields / body ids are observation-only; original physical arithmetic/order
unchanged, full public baseline must still match. Pose interventions also publish
per-tick endpoint trajectory deltas against reference; retain full difference file.
No inference from mean torque or mean impulse alone; per-tick applied teeth needed.

ORDER: reference + historical motor0 VOID record remeasured with F63 metadata,
then gain0 with ALL other values/damping unchanged, full F56 for EVERY arm.
Assert requested0 and MEASURE applied0 (including possible absolute-speed clamp
correction); never infer zero delivery just from gain. If true zero drive does not
collapse drift to free-hinge .08403595917823123px/s, STOP BEFORE bound sweep or A.
If it does, diagnostic bound6 vs1 at original gain/stiffness, full F56, report raw
ratios without inventing an approx4x tolerance; adopt no values. Only if those two
leave the saturation claim open may the owner's optional .5deg-residual falsifier
be considered. No A remedy is authorized. Current8/18 unchanged, attempts1 same-
build success/cross-arch0, F55/56/57/58/59 preserved; FA-5 untouched.


R20 measured @8e0b907 / CI40868433005, saturation job123429003201:
reference/stiffness0 requested means -21/-1.8121243561338403, actual bounds
.04119350481568311 each, applied -.04119350481568311 each, saturation300/300
BOTH. Late applied difference max3.33e-16, no difference above existing1e-12:
R19 spring-source conclusion WITHDRAWN, late intervention VOID, not falsifying.
Do not claim identical full trajectories: per-tick/startup differences retained,
late position offset.0037990209470555314WU despite velocity difference4.44e-15.
F61 nominal472.497x overshoot confirmed from resource/preset; ACTUAL late cap
uses current extents and yields509.79x mean requested/bound. Record only, no
coefficient change, no blanket all-presets/unsaturated-regime authorability claim.

Gain0 requested/applied EXACT0 ALL6000ticks, saturation0/300, torque0. Drift
5.387448117922983px/s, thrust.0011205429121987627/tick (.06723257473192576N),
NOT collapse to.08403595917823123. Complete F56 x/y residuals1.734723475976807e-17/
3.0281332996651145e-14. Reference and stiffness0 F56 also close within1e-12.
This is a delivered-impulse intervention with teeth, not another void arm.
ORDER1 STOP applied BEFORE bound6/1 or optional.5degree residual. F62 A remains
WITHDRAWN/NOT RUN; no calibration/protocol/target/snapshot/baseline change, Phase3
NOT ENTERED. Nonzero MOTOR drive not necessary for observed motion; contact/
limit/constraint-path isolation requires new authorization, not a guessed cause.
All adopted/default physical coefficients/damping/sampling unchanged. No
velocityepsilon/hysteresis/waiver. Runtime8/18 unchanged, all remaining10 NOT RUN,
attempt1 same-build success/cross-arch0 retained. Source ledger/PROGRESS records
F63 quantitative teeth and exact CI/artifacts,167Python/full public summary exact
Phase2/strict committed baseline MATCH. No local artifact ZIP inspection claimed.


## R21 — limit-removal and bound-sign diagnostics; no remedy/feel decision

Read reviewer M1_R21_LIMIT_STOP_REVIEW.md via git show FETCH_HEAD ONLY; no reviewer
artifact copied/merged. Owner ACCEPTS gain0's real delivery removal/F56 and owns
withdrawal of R20 saturated-drive-propulsor prediction: gain0 drift5.3874 exceeds
reference3.9345, so delivered drive was a brake in that comparison. F61 remains
record-only saturated-authoring arithmetic. F66 use MEASURED current-extent bounds
(.0411935 reference/.0412489 gain0), not nominal-rest.0444447; observed requested/
bound ratios also use actual inertia (about509.79/43.99 in R20), not nominal ratios.
F62 A remains WITHDRAWN; optional.5degree residual check now OBSOLETE, DO NOT RUN.

F64 is an owner HYPOTHESIS to test, not proven from drive-time mean q: project_position
runs AFTER prediction/distance/hinge, so record q/error at each actual angular pass,
plus velocity-stop predicates even if cumulative cap yields zero delivered impulse.
F63 applied-drive teeth/complete F56 and per-tick reference trajectories retained.
Original angular phase ledger contains ENDPOINT COORDINATE DISPLACEMENT in WU,
NOT radians. Publish its summed abs net coordinate changes unchanged; separately
observe all6 angular correction passes and audit requested and observed absolute
rotation in rad plus endpoint path WU. Do not equate mean drive-time error.1444
rad with total correction per tick/iteration without measurement, or infer net COM
injection merely from a nonzero internal positional correction.
The measured arms are ZERO INPUT, target0. The -.7576rad target is held-L at gain.7,
not zero-input target; negative torque still follows positive q at target0.

Order: reference40/bound6, arm1 diagnostic upper40->90 with original drive,
then arm2 bound6->1 with upper40 restored, everything else fixed including damping.
Only process-local Tuning duplicates vary; core/tuning.tres stays40 THROUGHOUT,
SHA checked between arms. Wide process exits, next arm constructs fresh40 copy;
next commit rechecks unchanged default40. No90 adopted, no preset edit/baseline
regeneration. F65 recorded as D08 band-vs-loaded-operating-pose question: authored
q0 IS inside[-140,40]; observed gravity-loaded rocking pose beyond40 is not itself
proof authored q0 is illegal/unreachable, nor a stationary equilibrium (F59).
No feel choice among widen/pose-mass/intended-stop mechanics is adopted.
D08, D06 tutorial FA-6 fixture and D07 reference-device tickcost are queued owner
choices, NONE blocks these two diagnostics. Phase3/coupled feel gates NOT RUN;
accepted8/18/attempt1 same-build success/cross-arch0 retained. FA-5 untouched.


R21 boundary-audit followup: first source0943087 wide90 removed ALL6000 positional
and velocity stop engagement, but drift2.950043883090746; F64 necessary-stop
prediction falsified. Bound1 measurement generated, reporting STOPPED on exact
predicate mismatch; no bound1 number/prediction conclusion yet. Add binary64
q/lower/upper/omega words, compare exact decoded predicate against recorded bool
and independently reconstruct raw geometry/velocities. No comparison tolerance
replaces a relational stop decision, no new epsilon, no physics change. Nextcommit
rechecks default40/SHA unchanged. Publish Euclidean endpoint-phase magnitude in
WU as well as labelled L1 sum; neither is angular radians. Rerun both arms ordered
with complete F56 emitted into bounded annotations; no new remedy authorized.


### R21 measured closeout — two falsified predictions, no adopted remedy

Source48d54df /M140877081798, full facts `.review/m1_r21_limit_evidence.json`.
Both ordered arms complete with unchanged F56/independent drive/geometry/phase
and exact binary64 predicate audits. Wide90 ALL6000 stop/positional correction/
block impulses EXACT0 yet drift2.950043883090746: F64 necessary-stop mechanism
falsified (not.08-.5; reference3.9345242550809765). Bound1 at fresh40 delivers
.16550972149490567x reference; drift FALLS3.5208063727143637: supplied sign
prediction inverted. Do not fit a new propulsion story. Global bound changes
both drive and limit caps, so do not call it an isolated drive-only intervention.
Mean actual pre-position correction over all6 passes .07042523254053407rad/tick
reference /0wide /.23703982613933203bound1. Drive-time q/error cannot substitute
for actual per-pass q/error. Euclidean endpoint magnitude WU from original phase
ledger6.637221585009945 /0 /22.080763658493435 per last300; separately verified
rad sums21.12756976216022 /0 /71.1119478417996. Neither measure is net COM energy
injection or a feel acceptance criterion. Bound1 nonzero window momentum change
must not be equated to reference's zero-window-momentum-change translating cycle. No solver constants adopted.

Binary64 q/lower/upper/omega independently reconstructed, decoded predicate EXACT
matches engine bool. Bound1 has39 late300 /1746 all6000 decimal-vs-binary decision
differences; no epsilon/threshold replaces relational predicate. First source094
bound1 report failure was a telemetry audit issue, not determinism attempt/finding.
Default40 and original resourceSHA unchanged throughout, and rechecked in this
nextcommit;90 exists only as reproducible per-process duplicate diagnostic.
Full original F56 literal EXACT R18/false/defaultexit1 and separate authorized
complete predicate EACH arm preserved. Full public summary EXACT acceptedPhase2.
176 Python controls, original component counts, M0516(514+2auto compile)/Android
PASS; overall M1 remains red at existing F47 and two wrong diagnostic predictions.
8/18 movement0, ten NOT RUN rows/FA5 unchanged, no baseline regeneration/Phase3.
F65 ownerD08 remains open, no assertion legal authored q0 unreachable; F66 measured
bounds supersede nominal, F61 record-only, owner R20 propulsion claim withdrawn,
R19 late stiffness0 remains VOID, A WITHDRAWN/residual OBSOLETE. Queue D08/D06/D07
for owner; these decisions did not block diagnostics. No choice/remedy inferred.


## R22 — one missing factorial cell, then unconditional STOP

Read reviewer arena/5b72e4ab-clamber M1_R22_NO_SINGLE_LEVER_REVIEW via git show ONLY;
never copy/merge reviewer artifact. Owner accepts both R21 arms/withheld failed
report/binary64 re-audit and withdraws drive-is-a-brake as a mechanism (F67).
Keep numeric correlations only; non-monotone results do not isolate causal phase
ordering or a universal35x floor. Three permanent columns: drive-time violation
rad; actual per-pass/summed angular correction rad; original endpoint ledger WU.
The erroneous.1444rad-per-pass claim is OWNER/reviewer's, now withdrawn: mean
versus max and distributed versus repeated correction were both confused.

F61 strengthened by bound1,−21/.006817925509442767≈3080.1157876576485,300/300:
constraint cap sets final delivery in MEASURED nonzero late windows. Torque/gain
clamp still sets request−21; gain0 switches it off. Original124/6000 stiffness0
startup changes persist in record. Do not infer parameter irrelevance for all
inputs/startup or impossible linear regime universally; NO constants changed.

Authorize exactly gain0+upper90, fresh defaults otherwise,6000 ticks with fullF56
and binary64/raw limit audits.90 exists only in process-local Tuning duplicate;
40 resource/creature bytes checked vs74c629e before/after and nextcommit. No baseline
rerun, other arms, free-hinge regeneration or subsequent sweeps. Manual r22_only
CI mode skips other runtime jobs (not passed/waived/closed); commits use [skip ci]
so automatic push/PR cannot silently rerun historical sweeps. Static controls run
locally and in dedicated dispatch; original tests remain intact. STOP after report
regardless of result. Inertness MUST be measured, not assumed from flags: zero
requested/applied all6000 AND zero positional/velocity engagement/block impulse.
If premise fails, do not mislabel that as inert-row-without-impulse solver defect.
No invented approximate-baseline tolerance or solver epsilon.

F68 OWNER structural finding for current measured actuated fixture/defaults:
zero-input creep contradicts settle/sleep≤4s, wider90 insufficient (2.9500),
nonzero late drives saturated. Formal AC201 gate remains NOT RUN/no upgrade;
not a proof over every untested band/pose/mass. D08 owner options now include
station-keeping: widening measured insufficient; pose/mass change unmeasured
(authorability question, not bounded by wide90's3%/25% response); intended stop
requires OWNER duration/net-displacement and revised sleep design if chosen.
Reviewer recommends third option plus explicit station-keeping requirement/hold
on release, recorded ONLY for owner decision. No acceptance reinterpretation,
duration, sleep re-scope, hold, hysteresis or tuning adopted. D06 tutorial and
D07 device tickcost queued. A/residual WITHDRAWN/OBSOLETE; no baseline/Phase3;
8/18 movement0/FA5 unchanged. Only authorized next action is single missing cell.

R22 scheduling correction: GitHub integration denied manual Actions dispatch
(HTTP403 Resource not accessible by integration); NO diagnostic was started by
that request. Use one push tagged [R22-once] for the single cell instead. Legacy
runtime jobs remain manual-only, NOT passed/waived/closed; static checks stay
active. Subsequent closeout commits [skip ci], new cell requires explicit marker
or authorized manual dispatch, never auto repeats on PR or ordinary docs push.
No source/resource change or additional diagnostic arm results from this fix.


### R22 measured closeout — baseline-return branch; STOP, owner handoff

Sourceeea4e52 /M140880532917 /job123470523762 SUCCESS. EXACTLY ONE new arm:
gain0+upper90, default bound6/all else fixed. Drift.08403595917824255 vs existing
free-hinge.08403595917823123, difference1.1324274851176597e−14px/s. Thrust
.00001772186894237695 impulse/tick /.0010633121365426171N. All6000 requested/
applied drive EXACT0, all positional/velocity limit engagement0, all block
impulse0 and all angular phase endpoint/projection changes0. Drive-time error,
actual correction rad and endpoint WU columns separately0. Complete F56 passed
per-tick/window; full book in `.review/m1_r22_inert_evidence.json`, literal still
false/distinct complete authorization unchanged. Inertness measured, not assumed.
Baseline-return branch supported; no inert-row solver/plumbing defect exposed by
THIS fixture. Either active angular path separately amplified creep in prior
cells; neither individually necessary for that amplification. Jointly off returns
to baseline. No further causal ordering mechanism asserted. Historic2.95 minimum
applied to active configurations ONLY; not mere angular-row presence, since inert
row now below it. Owner F67 drive-is-brake mechanism remains WITHDRAWN.

STOP after this cell, no sweep/arm/solver investigation/retune/hold implementation
run.180 static controls +load80/0; other runtime jobs skipped, not passed/waived/
closed; prior F47/public evidence retained. Denied dispatch never created a run;
one push marker executed cell once, PR cell skipped. Nextcommit [skip ci] to
prevent any repeat. Core/GD harness byte-identical63cb024, tuning/creatures
byte-identical74c629e; default40/SHA unchanged after90 process exited and rechecked
in nextcommit. No90 default ever committed. No baseline/Phase3/A/residual change.

F68 OWNER finding for current measured fixture/defaults shifts M1 from torque/band
knob hunting to owner station-keeping decision. Original AC201 zero-net-motion AND
sleep≤4s remains normative/NOT RUN; not reinterpreted/waived. D08 owner options
widening measured insufficient, pose/mass redesign UNMEASURED (not bounded by
wide90's3%/25%), intended stop plus reviewer-recommended station-keeping and
owner-authored duration/net-displacement and sleep redesign only if owner chooses.
No duration/hold/threshold/hysteresis/damping/geometry change adopted. D06/D07
queued.8/18 movement0, ten runtime gates NOT RUN/unmoved/FA5 unchanged. Accepted
determinism attempt1 same-build observation/cross-arch0 retained, no new attempt.
NEXT single milestone ownerD08 decision/handoff only. No further experiment.

R22 closeout CI preservation: component/public regression jobs are automatic again
for future ordinary changes; they were skipped on the one-cell marker run and
are NOT rerun by this [skip ci] closeout. Historical convergence/spring/F56-reference/
R21 experiment jobs remain manual-only so STOP does not silently launch old sweeps.
Original test code/floors/F47 failure and public baseline remain intact; scheduling
is not a waiver. No additional runtime invocation/arm after the R22 result.


## R23 — investigation CLOSED; owner D09/D08 PENDING, no further work authorized

Read ONLY reviewer branch arena/5b72e4ab-clamber R23 causal-closure review and
M1_D08_OWNER_DECISION sheet through git show. Neither file copied/merged. The
sheet is a recommendation/options list, NOT answers from owner. Inert cell accepted,
no defect: .08403595917824255 vs.08403595917823123px/s, delta1.1324274851176597e−14;
ALL6000 requested/applied0, no limit engagement/projection/block, three columns0,
completeF56PASS. R22 source evidence unchanged. No arms/solver investigations remain.

F69 recorded as OWNER architectural finding for measured fixture: active drive
alone2.950043883090746, stop path alone5.387448117922983, both3.9345242550809765,
jointly off.08403595917824255. Each path independently sufficient for observed
amplification, neither individually necessary. Non-additive/partial cancellation
relative to stop-only, NOT less than both:2.95 <3.93 <5.39. No scalar-knob search
resumed. No universal mathematical proof about all possible coefficients inferred
from finite measured saturated arms; proportional D09 remains an OWNER design fork.
F70 measured late-window drive q1.563079699374753–1.5630796993747635rad≈89.558deg,
only≈.442deg headroom under90. Unpowered loaded sag≈89.6deg from authored rest.
85/89 band would exclude measured posture/invalidate inert-premise equivalence;
no such test or≈3px/s result measured. Record reviewer narrower-band prediction
as counterfactual ONLY, not evidence. No new experiment. Drive-time error, actual
correction rad, endpoint displacement WU remain permanently distinct.

OWNER/reviewer corrects R22 F58 under1percent language: identity predicts mean
completed velocity, not positional net drift. Reference completed4.014820668450256
vspositional3.9345242550809765px/s,≈2percent difference. Keep two claims distinct;
full existing contact/damping/gravity/internal books and F56 predicates untouched.

Public Sim replay/clock DID NOT RUN on d76b88e. Last measured63cb024 /40878101597
(and accepted74c629e); solver-neutral skipped jobs accepted unpassed/not waived.
FIRST SOLVER-CHANGING COMMIT MUST rerun public replay/clock, reproduce baseline or
regenerate ONLY with owner authorization/provenance. Do not carry old replay over
as new evidence. Current documentation-only closeout [skip ci], no runtime run.

WAIT for BOTH explicit answers: D09=bang-bang OR proportional; D08=hold OR
accept-creep OR other exactly as OWNER writes it. No recommended choice adopted.
Until answers: no experiments, tuning, hold, AC201 rewrite, baseline regeneration,
Phase3 or any runtime gate start.8/18 movement0/FA5 untouched. After answers:
1.D09 increment (document effective motor strength/caps vs authority OR authorized
proportional re-scale with baseline regeneration/provenance/allfour arms measured);
2.D08 increment;3.Phase3 AC201/AC202/FA3/FA4/FA5. AC202/FA5 may start in parallel
with D09 increment AFTER authorization, separate evidence/configuration/commit
provenance; not a present instruction to start. D06/D07 queued, no M0 waiver
carried forward. A/residual obsolete/withdrawn, no baseline/Phase3 changes.
NEXT single milestone WAIT for owner D09 AND D08. No additional implementation.


## Delegated owner D09/D08/D06 — accepted; proposal study, NOT adoption

User explicitly confirms owner delegation; read origin/arena/5b72e4ab-clamber
M1_D09_D08_D06_DECISIONS via git show ONLY, never copied/merged. D09 proportional
muscle/re-scaled, not bang-bang documentation. D08 physical hold first, visible
release-hold fallback ONLY after approved adoption and full4-cell remeasure still
above derived.3px/s; no freeze now. D06 author provisional minimal fixture now,
subject to B04, FA6 target6–8of10 unchanged. D07 owner phone queued/M0ONLY waiver.

Non-adopted proposals registered before measurement: cap30 for ALL (no further
raise), torque12 ALL, k10/20/40 (quarter/half/whole owner's EXAMPLE40). All numbers
are proposals, not claimed derived feel constants. Isolated tuning.tres override
resources only; core tuning SHA/defaults untouched. Damping c=2sqrt(kIeff),
Ieff=1/(inverseIp+inverseIc), evaluated actual authored endpoint geometry, raw
independently audited; publish loaded damping ratio. Continuous linear critical
coefficient need not be stable/critical in nonlinear discrete constrained plant.
Fixed60Hz unchanged. Plan `.review/m1_d09_study_plan.md`, at least3 triples,
four cells plus proposed lurch1s held L/4s release after95s awake settling each.
No formal FA4 credit for proposed pulse. Full per-arm F56/F63/limit/WU audits,
exact pose settlement or null/transient range; no residual calibration/A revival.

Owner holding criterion max |requested|/bound<=.5 AND unclipped upstream motor
request at working/settled pose. Actual saturation/holding residual/pose/drift/
lurch required; no nice first result adoption. Derived D08 line .001/30*60*150=.3
px/s is necessary, not sufficient: exact F52 body per-tick AND anchored dwell-net
must fire within4s; strict comparison unchanged. Awake observer eligibility not
actual sleep. Margin below.3 treated as feel risk if close, not comfortable pass.
STOP after study before adoption. On approval adopt, regenerate baseline with
provenance/re-measure4arms; old R23 describes OLD parameterisation, preserved.
If pose cannot hold sane residual report/return to owner, do NOT raise bound again.

D06 authored provisional proposal JSON: one floor, one ledge, one spawn marker,
one identical script/ten attempts via existing owner tuning targets. No generation/
difficulty curve/product level design or captures. Layout/success proposal NOT
measured/qualifying until Phase4; re-lay/re-run if B04 resolves differently. With
identical state/inputs deterministic solver gives identical outcomes; no invented
noise/seed variation to manufacture6–8 successes. FA6 NOT RUN. AC202/FA5 parallel
authorized but not started here, evidence would be separated. Runtime8/18 movement0.
Public replay/clock rerun on first study commit to reproduce OLD baseline, not
regenerate/adopt example. Actual first adopted solver change must rerun again with
provenance. No silent AC201 rewrite/epsilon/hold/waiver/M2/camera/captures.


### D09 study measured closeout — authorable headroom observed, station-keeping NOT achieved

Source573a1fb /M140885113085 /job123486613471 SUCCESS. Full fifteen audited
runs/90krawticks `.review/m1_d09_study_evidence.json`, non-adopted plan unchanged.
PROPOSED (cap,k,torque)=(30,10,12)/(30,20,12)/(30,40,12); cap ceiling NOT raised.
Derived c=2sqrt(kIeff) authoredactual inertia yields.5443327361211717 /
.7698027378662161 /1.0886654722423434. Fixed continuous linearization, loaded
zeta at measured mean bounds1.066/1.079/1.085, NOT globally critical discrete plant.
Working angular residuals.22316866039209582 /.08996254195334404 /.032108711886440405
rad (12.787/5.154/1.840deg); exact settled pose NULL all3, no fitted equilibrium.
Holding300 maxabs requested/bound.245244 /.240241 /.235556 (<owner.5), constraint/
upstream torque/body speed clipping0 each. Linear headroom COMPONENT observed;
formal settled-holding criterion not qualified without established settlement.

Both/drive-only drift8.550150769956836 /11.479241947750111 /12.910423565431365px/s;
stop-only5.374919874839947 all3, inert.08403595917824255 all3. Thus NOT D08 physical
station-keeping: all powered both above derived.3 and no F52 eligibility all6000
fromspawn. No candidate adopted, no nice first result selected. STOP; no more
triples/bound increase/hold until review. Better angle/residual/headroom does not
constitute an AC201 pass. Exact per-body F52 remains authoritative, not mean drift.
Proposed95sreleased/1sL/4srelease response measured held dx.14075959883633615 /
.0922175655125983 /.02659880134783954WU, postrelease first F52 eligibility82/66/64
ticks (awake observer no parking/formal sleep/FA4 credit). Full response in evidence.
All15 fullF56 pass, maxwindowabsresidual4.565792188770956e−14, oldliteral record/
default exit1 preserved, distinct R19 complete predicate. All observer on/off
physical states equal6000each; permanent rad/rad/WU limit columns retained.

Public replay/clock PUSH+PR rerun573a1fb SUCCESS, FULL summary EXACT oldcommitted
baseline; reproduced, NOT regenerated. Sourcecontrol physics/defaultsunchanged;
first future adoptedsolver change still must rerun/regeneratewithprovenance.
185Python/load80each PASS; M0516(514+2auto compile)/AndroidPASS. F47 remains RED,
legacy sweeps skipped/not waived. Sourceartifact12901654637/398343994B/SHA
3b82aac1ee32484c89e85503a7b4c86b0518a58ed72f87ddcee5ee57341443d5, compact books+
metadata inspected NOTrawZIP. Closeoutskipci no additional runtime experiment.

D06 provisional fixture AUTHORED underB04, layout/script/success proposals NOT
measured/FA6 qualification; deterministic identical initial states/inputs cannot
produce differing outcomes—do not add artificial noise to force6–8. No product
geometry/generation/difficultycurve/captures. D07 phonequeued. Ownerdecisions
remain accepted, no relitigation; waiting STUDY APPROVAL, not choice of bang-bang.
On approval adopt selected parameters, baseline provenance/full4cellremeasure then
D08margin/fallback decision perdelegatedrule, not before. R23 2x2 OLD parameterisation
retained ashistory. Core/TUNING/creaturebytes unchanged; mass/weightuntouched,
40default intact.8/18movement0/FA5untouched, AC202notrun, no Phase3/A/residual/M2.
NEXT singlemilestone ownerreviewD09study BEFORE adoption, STOP experiments now.


## R24 — accepted D09 study; one final measurement round, then package decision

Read M1_R24_D09_STUDY_REVIEW and owner-decisions addendum by git show reviewer
origin/arena/5b72e4ab-clamber ONLY; no copy/merge. Study accepted, still no adoption.
F65 CLOSED BY RE-SCALE for measured POWERED candidate configurations, attributable
to real headroom/legal pose rather than tuning accident. Core committed default
remains historical8.27deg paststop because candidates not adopted. No runtime row
credit/FA5 change. F65 all6000 zero engagement/projection/block to independently check
in C against archived raw rows and original summaries, not inferred from means.

Authorize ONLY A:c40 static-slip.15/.015/.0015 process duplicates, B:committed
default bound6/k2400/gain.7/damping55/torque1800 lurch SAME95sreleased/1sL/4srelease,
6000ticks each/fullF56. Report bodylength from actual sum of3initial capsule axes,
not an invented AABB dimension. C reads OLD15run archive12901654637, no repeat3k
measurements: COMcompleted vx ranges, per-tick driveq CSV and intertick changes,
within-tick sampled q spread reconstructed afterintegration +original phaseevents,
plus driveomega. No new physics telemetry needed/no threshold/force changes.

F71 A-B/k records empirical fit of finite3points, not validated rigid-jointlimit,
not universal proof no motor parameter works. F72 static drive-phase samples do
not prove zero motion within fixedtick; sampled phases/omega make that auditable,
no new causal model asserted. Reviewer.010impulse/5% fork40 conflicts with actual
D09 totalrequested/applied.0444354/bound.1886402≈23.56%; retain measured fulltorque
(spring+damping) not spring-only conflation. F73 tablek↑drift8.55->12.91 WORSE and
lurch.14076->.02660 smaller; wording stifferbetterdrift is sign-inverted. Both
metrics favour softer among these3; formalFA4NOTRUN and no universal tradeoff theorem.
Owner D09 physical-stationkeeping premise withdrawn, defined visiblebrace fallback
authorised but explicitly unspent until round returns. TWO packages pending:
P-A committed saturatedmotor+visiblebrace; P-Bc10linear+visiblebrace/baseline
provenance/regeneration/lurch rederive. Do not choose/adopt/implement now.
Futurebrace must be visible designed state, input release/unrelease, snapshot/
restore audited and explicit internal hold momentum sumzero in completeF56.
No external support or load fudging authorised. No such mechanic implemented here.

FA6 addendum DECIDED legitimate variance: player timing ONLY, published onsets
[0,4,8,12,16,20,24,28,32,36]ticks, before anyFA6run. One seed305419896 (existing
public fixture seed), spawn/geometry/physics fixed; no jitter/noise/seed variation.
Provisional pulse60ticks and fixed300tick horizon from original60+240 proposal
retained; released until onset, L60ticks, release to same endtick. Geometry/success
proposal still underB04/NOTmeasured; 10runs/6–8target unchanged. No FA6 executed.
No post-result list tuning. D07phone queued; M0waiver does notcarry. AC202/FA5
parallel if this last round extends, not started in this one bounded increment.
STOP afterA/B/C for owner package choice;8/18 movement0, tenNOTRUN, no Phase3/A/
residual/M2/camera/captures/tolerance/epsilon/mass/weight changes.


## R24 result — final A/B/C COMPLETE; STOP for P-A/P-B (no adoption)

Source8110688/roundjob123504891124SUCCESS, exactly3slipcells+1defaultlurch;
C oldsource573a1fb/archive12901654637 read, no newstiffness runs. Fullfacts in
`.review/m1_r24_round_report.md` and evidenceJSON. A100xthreshold reduction does
NOTreduce drift12.9104/13.2677/13.2403: proportionalhypothesisFALSIFIED, no magic
.00349targetadoption. Publishper-pointconditionalallowances as UNMEASURED and
unsupported, not a setting proposal. Bheldx.0262301617WU=.0291446241bodylengths,
actualsum.8999999999999999WU; NOTnearbodylength, noFA4PASS. F72driveq recurrence
confirmed but within-tick sampledq~.11rad/nonzeroomega~1.2rad/s contradictsfrozen
throughouttick premise. No unique contactcause demonstrated/universal no-k proof.
F65 CLOSED BY MEASURED RE-SCALE verified cold3x6000: zeroengagement/projection/
nonzeroblock in all3poweredcases; workingposeslegal. Currentdefaultnotfixed/
adopted. F71fitfinitepointsNOTmeasuredrigidlimit; F73signcorrectionstiffness↑
drift↑andlurch↓, not opposingdirections. No contact-model fix inferred from A.
FullF56each6000raw/20windowsPASS/maxpertick1.887379141862766e-15/maxwindow
6.96942503708442e-14; observerbit-equal6000each, literaldefaultfalse/exit1unchanged.
PublicFULLsummarypush+PRexactoldbaseline, reproducedNOTregenerated,190controls,
M0516+Androidpush+PRPASS. OverallM1F47RED/notwaived, rounditselfSUCCESS. Artifact
12904553635 externalraw/CSV/books, no generatedrawGit. No default/creature/core
changes.8/18movement0/tenNOTRUN. Finalroundcompleteinoneincrement, noextension.
STOPforownerEXACTLY P-Asaturated+visiblebrace or P-Bc10+visiblebrace+actualadoption
baselineprovenance/lurchrederive. No furtherphysics trials/contact sweeps; no
packagechoice/brace/adoption yet. PreregisteredFA6offsets fixed/noFA6run. Future
visiblebrace must snapshot/restore/explicit internalnetzero ledger/fullF56 and
never manufactures support/fudgesloads. AC201strictunchanged/noM2/camera/captures.

## M1-R25 — OWNER DECISION: P-B adoption + relative-joint brace

Decision source: GDD owner/user's explicit R25 instruction (DECISION, not proposal),
reviewer origin/arena/5b72e4ab-clamber at9957260, read
`.review/M1_R25_PACKAGE_DECISION.md` by git show ONLY; never copied/merged.
Adopt k10/bound30/cap12 with derived c.5443327361211717 in ONE adoption commit.
First adopted motor re-scale of this study, not another process-local candidate.
Honest cost: changed committed physics => regenerate public baseline with exact
provenance and rerun public replay/clock ON the solver-changing source commit.
If brace fails, adopted idle drift is8.550150769956836 rather than old3.9345242551.
Do not hide that risk or dependency of AC201 on a designed hold mechanic.

Derivation: equal endpoint masses m/2 => I=m*extent²/4. Actual authored Slug head
m=.35*2.2=.77, extent.35 => Ip=.02358125; motor m=.30*1.6=.48, extent.30 =>
Ic=.0108. 1/Ip+1/Ic=134.99916561141055 (use actual authored binary64 frames;
no rounded inertia substituted). Ieff=1/(1/Ip+1/Ic), c=2sqrt(k*Ieff), giving
.5443327361211717 at k10. Resource stores FULL derived value, not rounded.544333.
Cap30 replaces6, torque12 replaces1800, stiffness10 replaces2400, damping replaces55.
Gain.7/range0..1/contraction62, slip.15, sleep.001/30, masses/weight/bands unchanged.
Continuous authored critical damping is NOT a claim of loaded discrete criticality.

Reasons: k10 wins observed drift AND lurch among10/20/40; live gain dial/headroom
(maxrequest/bound.245, no holding300clipping), legal12.7866deg pose, end-release
lurch.2518BL vscommitted.1457BL. Rejected P-A has dead saturateddial/illegalpose;
k20/k40 worse on both measured metrics; morestiffness is NOT a stationkeepingfix.
A slip hypothesis falsified/nonmonotone; no extrapolated.00349target authorised.
F71 finite3point trend only/asymptoteunsupported. F72 frozenjoint WITHDRAWN byowner
as samplingerror. F73 opposite-direction tradeoff WITHDRAWN. F65 CLOSEDbyrescale.

Mechanism statement of record (owner R25): **steady treadmill**, not a frozenjoint
or between-tick oscillatory limit cycle. Late completed COMvx spreads (k10,k20,k40)
7.7e-16/3.5e-15/4.6e-15WU/s over300ticks, while sampled relativeq churn~.11rad/tick
and driveomega1.19..1.27rad/s returns to same drivephase. Contact/friction solve
rectifies this churn into steady translation. Scope measured loaded cases, not a
universal no-motor theorem/infinite-stiffness proof. R24publicjob actually DID run
on8110688 (also573a1fb); stale wording 'not since d76b88e' corrected as provenance,
but neither earlier run covers THIS adoption, so fresh adopted-source rerun required.

Brace specification: on zero input (including spawn), capture relativeq once;
replace angular row by bilateral positional error(q-releaseq) and exact velocity
block J=-omega/(Ip^-1+Ic^-1). ANY input instantly disables and fully rearms it,
including other channel; no delay/hysteresis/strength constant/cap/spring. Equal/
opposite endpoint couples on each body, zero internal net linear impulse by
construction. Raw observed roundoff is retained, not replaced by manufacturedzero;
existing1e-12 bookkeeping only. No world height/anchor/support force. Position
turns conserve eachbodyCOM; no new qualifying loads. Gravity/contact remainexternal.
Reject worldpin (airborne manufacturedsupport), velocityzeroing (silentfakeAC201),
morestiffness (measuredworsedrift). Sleep parks ONLY after ORIGINALF52 fires;
brace is idempotent across sleep and releases on input wake. No CreatureSleep edits.

State: per joint bool brace_active + necessary release-angle scalar brace_q;
flag alone cannot encode arbitrary releaseangle. Both in snapshot/statehash/atomic
restore, strict boolean/finiteangle [-PI,PI], inactive canonicalq0, no missingfield
accepted. brace_enabled is explicit diagnostic config identity for authorisedoff
arm; publicalwaysON, not tuning. Public get_brace_state exposes detachedjointflags.
VISIBLE contract: distinct planted joint cue consuming brace_active, distinguishable
from asleep; Phase4 renderer/captures deferred as owner authorised, NOT claimed
rendered in this headless increment. Never infer presentation from velocities.

Registration: `.review/m1_r25_adoption_plan.md`. IdleON/OFF, lurchOFF/ON .7/1s,
ON1.0/1s, ON.7/5s, ON1.0/5s. Same95sreleased and4srelease; hold durations fixed
BEFORE outcomes, not widened to hitgate. F74 sampled maximum only, not global
maximum over unbounded holdtime; longer motion includes passive translation.
ActualpublicSim F52/600tick trace separate from forcebudget traces. Allsleepenabled
arms publish awakepreparkingF56 plus explicitpark transitions; parkedrows NEVER
invent fresh forces. Internal brace contribution is observed SUBSET of existing
internal/drive, not double counted. LiteralF56false/default exit1 not rewritten.

STOP after registered measurements ifONdrift>.3, actualunmodifiedF52not<240ticks,
OFFdriftnotEXACT8.550150769956836, nonconserving/newknob; no retune/retry/epsilon/
threshold/slip change. Lurch weakness/F74shortfall published, no contraction/gain
range widening. Remaining alternatives require NEWowner contactmodel/specdecision.

AC202andFA5 START in parallel jobs, no needs dependency onbrace/baseline success.
AC202public3presets7200ticks each/allsegments, UNMODIFIED.05WU. FA5authoredHopper
awakebraceOFF7200ticks fixed released/L/R/both60tickblocks. Flat existingfloor,
no new stance geometry or syntheticload/flag/pose; actualhinge+gravity+self loads,
frozen priorN, thresholdmax(5,.4W/N), N0disable. Allfourbranches+twofootstance
must be observed; missingcoverage fails honestly/no geometryposthoc adjustment.
No gate credit before measuredCI; matrix8/18 retained for review this increment.
NoM2/camera/captures/waiver/mass/weight changes. D07phone/B04layout remainqueued.


## M1-R25-BASELINE — generated adopted-source replay provenance

Owner R25 authorised regeneration, source 8d73597f0ce4c118ad0602816b51770d8292611f, CI40895082337.
Final digest a30a132f739e97ce3b4f73ca1716fb7359e0ae22b460378d8396b01da773fb71; full stream SHA256 a2929a0c590f68cbe795ab03b2027cb94a9990fef69732236865f1fb30d3e557;
per-tick table SHA256 f2c680300abdc6e2937a493aa344e1404dece005397cd8a99a6c17a52bd4f239.
Generated from actual pinned4.7.2 triple streams+clock, not hand-edited expectation.
Separate public replay/clock job reruns this SAME source commit against generated
baseline; source overlay is explicit; closeout commits generated bytes/this entry.


### R25 STOP reached on adopted source8d73597 — NO PHYSICS FIXES

CI40895082337 source brace job123521869979 executed registeredsevenarms once.
IdleON12.617730602141002px/s, actualpublic F52neverfires600ticks and ONnone6000:
STOPconditionsmet. OFFexact8.550150769956836 reproduced, all7completeF56PASS/
observerequal/724controlsPASS, but ONalso weakensheldlurch. No strength/threshold/
slip/epsilon edits or secondphysicalround. Allcore/tuning frozen at8d73597.
IndependentAC202completed7200each/allsegmentmaxfoot.09437/.19992/.09966 failed;
limb-onlymax to auditarchiveddata, no new runs. FA5stopped7067/7200, countsN2,
below/above/twofootgrip observed, airborne missing; NOTPASS. Exactabortstatus
wasn'tlogged, so cannotassertcause from failedjob alone. No syntheticcoverage.
Baselinegeneratedfromactualsource/matched SAMEsourcepublicjob123522445066,
9057+308+1446PASS, no determinismfailure. Committed generatedbaseline/entry now.
SourceCIstatic failed184controls due test's shallowgit-history assumption;
fixturegoldenhash control repaired WITHOUT changing expectedresource orphysics.
Postmortem `[R25-audit]` job reads original3traceartifacts+baseline only, noGodot,
computes per-kindAC202maxima/FA5lastbounds/public-to-force-trace agreement. This
is reporting, not a new physicaltrial. Matrix8/18 unchanged; STOPforNEWowner
contactmodelreview or ownerauthoredAC201number/specdecision. No unilateralwaiver.


### R25 archived-data closeout — no new physics, core frozen at8d73597

Archiveaudit40896828176/job123528127119SUCCESS,0newphysicsruns. AC202motor/passive/
limbmax Slug.06735552288921903/Hopper.1090211629000053/Twin.07263504920267333WU,
all>.05 evenexcludingfeet. Hopperliteral limb6.09978856801616326 at13, so true
limbfailure, notfoot-onlysurrogate. FA5lastx[-11.998676101856619,-11.215033260486496],
nearfixtureleftbound-12; actualabortstatusnotlogged, probableboundaryescapeNOT
assertedascause. No extra replay/step/floor expansion. Airbornecoverage0; all
observedgripsmatchedlaw, absenceofcoverage/truncationNOTairbornefalsegrip proof.
Publicidle600physicalstatesmatchforcearm600exactly, actualF52neverfires. Committed
baselinebyteequalgeneratorfileSHA3d2f95e2187b2f90961d31a525eaa9d79ccb4296dec4fb766c6754f4043f185f.
Normalstrictpublicc169ded PUSH+PRjobs123528127573/123528164326 PASS and FULLsummary
EXACTadoption-sourcepublic.198PythoncontrolsPUSH+PRPASS aftertestonlyshallowhistory
fix. HistoricalF47stepstillRED/nonwaived. Core/data/tuning/sleepunchangedsince
8d73597; no physics adjustments afterSTOP. Matrix8/18/no newacceptancecredit.
STOPforNEWownercontactmodelreview or owner-authoredAC201number/specdecision;
F74sampledshortfall and independentAC202/FA5failuresremainvisible, no improvisation.

## M1-R26 — OWNER DECISION: brace rejection; LAST bounded diagnostics

2026-10-29. Readonly reviewer1df02f5 §10 records owner-selected Option3.
No reviewer file copied/merged. R25 adoption is accepted at byte level, but the
brace mechanic is **built, measured, REJECTED** and removed atomically (code,
state/target, snapshot/hash/restore, presentation getter/flag and brace tests).
Keep four P-B lines bound30/k10/c.5443327361211717/cap12; no old3.93px/s reversion.
ONdrift12.617730602141002 vs OFF8.550150769956836px/s (**+47.6%**);
end-release+.2249433803374048 -> -.06129663822438047WU. No new brace/lurch trial.
Historical R25 F56 brace-internal column stays: <=7.8e-16 while mechanic useless.
P-B live gain remains permanent: requested/bound worst~.245,0/300 saturated;
legal12.8° travel versus old8.5° beyond+40° stop. F74 is only a sampled ceiling
over .7/1gain×1s/5s; until creep is fixed no lurch measurement is trustworthy,
and idle translation is never input credit.

**F75 mechanism-of-record (owner):** sustained internal load is rectified by
contact/friction into translation proportional to transmitted joint load,
independent of static-slip allowance; locking relative rotation increases load
transmission/creep47.6%. Five sweeps exhausted motor/limit/slip knobs. The motion
is a steady treadmill, not a limit cycle/frozen joint. F72 withdrawn, F71
asymptote unsupported, F73 k10 wins both. This records the owner's mechanism
interpretation, NOT a newly established universal scalar proportionality law:
mean absolute MOTOR drive torque alone is not total transmitted joint load,
and the prior k sweep must not be falsely described as showing torque grows
monotonically with k. D1 locates the carrier or explicitly remains inconclusive.

Authorised scope is `.review/m1_r26_diagnostic_plan.md`, preregistered before
measurement: D1 coefficient.9/.3/1.8/3.6 process-local duplicates at P-B released
input, report drift+thrust, adopt nothing; D2 raw phase-error instrumentation and
ONE identical distance-only final traversal diagnostic duplicate,7200 ticks,
unchanged .05WU literal-limb criterion. Separate hinge/angular/self/contact
phases are necessary to test F76, not assume its attribution. Normal order and
constants remain unchanged. F77 parallel independent authored airborne/drop/
ledge/midair fixtures, unconditional termination/tick/status and independent
branch events with frozen N/40% threshold distribution; no synthetic loads.
Prior FA5 truncation was a fixture defect, not an established physics failure.

Hard fork **without further measurement**: BOTH diagnostics locate correctness-
shaped causes => one later fixed increment implements both and reruns AC201+202.
EITHER inconclusive => Option2 accepts creep, OWNER authors AC201 number, AC202
is honestly failing with measured maximum. No engineer-authored AC201 rewrite,
.05 widening, new knobs, mass/weight/epsilon changes, waiver, M2/camera/captures.
Matrix8/18; determinism attempt1 remains same-build only, cross-architecture0.

Current committed baseline before this change is P-B WITH brace (R25 generated
provenance). Removing brace changes physics AND serialization: new R26 generated
baseline requires its own provenance line, same-source strict rerun, then
committed-byte strict rerun. Generator is separately scoped to R26/old R25 hash;
normal baseline checker is unchanged. D2 nondefault diagnostic is not adopted
as a production baseline; its paired trace hashes/ordering identity are separate.
Results and generated hashes PENDING; no qualifying measurements claimed yet.


## M1-R26-BASELINE — generated P-B WITHOUT brace replay provenance

Owner R26 authorised regeneration on brace removal, source114265e0116101a897d8429a2998f4987549f86f,
CI40901902007 / generator123546155675 SUCCESS. Generated actual pinned4.7.2
triple byte-equal replay streams plus30/144Hz delivery checks, not edited expected
physics. Source overlay modifies ONLY baseline+DECISIONS provenance. SAME-source
strict public replay123546537887 SUCCESS (9053+308+1446 checks,0failures).
Final digest 4ec66a1f719135112c28f4e6678d87f4e3c04221d5236816ec02788faa0a6aaa; full stream SHA256 cf98342cf54a06180a68223fb9aa0cb217209b2adb77c544293348e896e29190;
per-tick table SHA256 ab2be178d0dee0da6d6d08e8ac8109fb3598803d2c970ffbb61235ef8c3288af.
Generated baseline bytes are committed here WITHOUT core/data/tuning edits.
Archive-only audit compares those committed bytes with original generation.
Subsequent normal public CI must match committed bytes. R25's P-B+brace baseline
remains historical; this is a separately identified P-B WITHOUT brace baseline.
D2's nondefault Hopper final-distance arm is NOT adopted or substituted here.

## M1-R26-D1 — measured fork: Option2; NO further diagnostic measurement

Source114265e / CI40901902007 / D1job123546155730 SUCCESS. Exactly four6000-tick
released process-local friction duplicates; all observed/unobserved snapshots
byte-equal, all6000 positions/contacts/F31 and20F56windows per cell independently
verified. Default resource remains.9 with four P-B values untouched.

| Friction | Drift px/s | Signed rectified thrust N |
|---|---:|---:|
| .9 | 8.550150769956836 | .10818558117092802 |
| .3 | 9.393416417530442 | .11885547303816352 |
| 1.8 | 8.482160126141556 | .10732529139197892 |
| 3.6 | 8.482160126141556 | .10732529139197892 |

No roughly proportional response; reducing coefficient3× INCREASES drift/thrust
~9.9%. Coefficients1.8/3.6 are the SAME clamped dynamic operator, not independent
carrier localization. Each last300 has900 dynamic,1800 static-override,2400
inactive candidates; .3/.9 dynamic unsaturated versus1.8/3.6 dynamic clamped.
Cannot infer a located normal-accumulation/position-projection fix from this
alone. D1 is **inconclusive for a correctness-shaped cause**; owner binding fork
therefore selects **Option2**, irrespective of D2. No more sweeps/brace/lurch/
additional measurements to seek a different outcome. No diagnostic adopted.
OWNER must author AC201's replacement number; existing settles/sleeps criterion
has NOT been silently rewritten. AC202 remains honest measured failure, .05
unchanged. D2 and repaired FA5 ARCHIVE-ONLY interpretation are being completed;
D2 diagnostic itself finished7200; baseline terminated7067/status30 at tick7067,
so no full7200baseline claim. No physics rerun to repair reporting/fixture gaps.

## M1-R26-F76-F77 — final ORIGINAL archive interpretation; Option2 binding

Source114265e physics ran ONCE; archive job123551531542 inCI40903408711 SUCCESS,
no editor/solver/physical rerun, all original rawtrace hashes checked. The two
source reporter errors are disclosed: FA5 non-foot schema has no gripping field;
D2 rejected incomplete baseline before reporting the completed diagnostic. Only
postprocessing was repaired. No raw load/geometry/threshold/constant was edited.

F76: existing final distance block restores literal limbs to1.7763568394002505e-15;
final hinge/angle/self phases reach.014927052436045196 in baseline. Hinge and
angular maxima coincide: rigid angular rotation is NOT the source of this
threshold violation. Later contact cleanup raises completed literal-limb3 to
**.05334550000967464@tick12**. Baseline completed7067 before both observed/control
returnstatus30 at tick7067, reasonstep_failure. Its exact failing callsite is
not logged; do not infer a proven boundary cause or claim7200baselinecompletion.
ONE extra-distance diagnostic completed**7200**, immediate limb error
1.7763568394002505e-15 but after-contact/completed limb3
**.051910617942553194@tick11>.05**. A final projection before contacts is not a
sufficient ordering fix. No after-contact arm, adoption, widened.05 or remeasure.
D1 alone already selectsOption2; D2 does not supply the missing sufficient fix.

Separate D2 trace provenance (NONDEFAULT diagnostic, NOT production baselines),
both source114265e/CI40901902007, seed305419896, authoredHopper/block60input:
- Normal order baseline7067 rawSHA256
  414449d35c3549a16a5221091be9f1d67bb074651b2f5d1535f29c1bd3e6b1c0.
- Added ONE final-distance traversal diagnostic7200 rawSHA256
  d4fc09e6b28e4c054a1ca6d885505c0516e844dd1b3b1835ff2a2d4f4bf30fab.
Neither trace is silently promoted to a newly generated production baseline.
The separate M1-R26-BASELINE regeneration/provenance above remains authoritative.

F77 fixture/law audit: stance600/drop600/ledge1200/midair12 all completed,
status0/control0/reasoncompleted/failingticknull; all four branches present,
N0 disabled separately. Natural ledge departuretick83. Airborne236foot/pass
observations/6episodes, at-or-above27foot/pass observations/**8per-foot episodes**,
twofoot9pair/pass observations/**3pair episodes**; below4731/11non-grip episodes;
N0disabled14/7non-grip episodes. Events collapse all candidate samples and both
passes within each tick; ticks can contain different branches across passes.
At/above durations3,2,2/3,4/3,2,2ticks; pair durations2/3/2. These are disjoint
operational episodes, not independent random trials (ledge startup repeats
stance), and NOT evidence of robust sustained grip. N2threshold18.871999999999996N
for all true-grip observations; N1threshold37.74399999999999N observed without
true grip. Full per-case N/threshold/load ranges and capsule counts retained.
Loads reconstructed from real gravity/hinge/self-contact + independently rebuilt
SDF normals; no synthetic qualifying loads, pose/velocity/support injection or
new eligibility predicate. Short12tick midair does not pretend to have a300tick
F56window. Longer fixture windows retain original complete momentum guards.

Generated brace-free baseline byteequaloriginal generator; fileSHA256
2779456f6a35338a97666bcec813608ae5bda83c612ec1d5b6560df62590f679.
Committedddefbba normal strictpublic PUSH123551532000/PR123551591430 bothSUCCESS,
9053+308+1446checks,0failures. FullPUSH/PRsummariesidentical. Source comparison
changes ONLY an obsolete human-readable brace scope label, no physical/hash/
clock metric.201PythoncontrolsCI; M0516/0+AndroidPUSH/PRSUCCESS. M1stillred only
unchangedF47/HingedSlug600, no waiver. Core/data/tuning unchanged since114265e.

F75 qualification: owner's transmitted-load rectification chain is retained as
mechanism-of-record, NOT a proven universal law relating drift to scalar motor
amplitude. Oldk10/20/40 meanabs applied angular IMPULSE actually DECREASES
.04796602541507495/.0458210036063169/.044435404255268936 while drift INCREASES
8.55015/11.47924/12.91042px/s. Do not mislabel impulse as torque or erase this
countertrend. D1's coefficient response does not establish a located upstream
correctness fix; clamp/static-override caveats are explicit in the report.

**FINAL hard stop:** Option2. OWNER authors AC201 displacement/time criterion;
engineer leaves oldcriterion unchanged. AC202 honestFAIL with measuredmaximum.
No further measurement/sweeps/brace/lurch trials or diagnostic adoption. Matrix
8/18, same-buildattempt1 remains observation, crossarchitecture0. No mass/weight,
epsilon/slip/stiffness/damping/.05 changes, waiver/M2/camera/captures. Last
publication step only persists BOTH already-derived per-tick phase-maxima files
from ORIGINAL rawbytes in the audit artifact; no new physical run.
