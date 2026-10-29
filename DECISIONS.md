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
