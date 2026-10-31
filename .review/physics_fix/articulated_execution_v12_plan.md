# V12 preregistration BEFORE native components / world execution

User priority: first fix <=15deg posture and no all-airborne tick. NO upright
controller, altered geometry/spawn, resource/tolerance/iteration or sleep waiver.
M1 still BLOCKED/NOTSIGNED; failed candidates not adopted or rerun unchanged.

## Evidence and hypothesis
Latest closed V11 source30a2205/run41164232428: full600 finite/solver0 but first
posture16/max49.1818408224deg, airborne18, no sleep. Native185 is NOT acceptance.
RawSHA14c57e6a8ed4b5bc1b7d5289c595a0d07ed83b1a2921a4a00a891cd12c306e5e.
At0: gravity creates closing foot vy=-.4666667, native restitution returns+.0092836.
At17 bottom=.019961902120223474, at18=.021134711502983586 > original+.02 contact
window, losing grounding. No capture repeated. This implicates restitution of
fresh support acceleration, not proof it is the sole airborne/posture cause.

Existing angular operator retains r=.2 in hinge nullspace, but terrain reaction
still uses undamped W_H. Independent exact rod controls (already6PASS) show support
regenerates rotation: split omega-.6 vs simultaneous-1/3, r0 split regenerates-.5.
New exact network8 controls verify Kd symmetry/nonnegative form, H nullspace,
common-translation momentum, contact2x2SPD, original zero/full limits and impact
vs supported rest. These are NOT normative/creature/native proof.

## One contact constitutive correction
New test-only damped_support_mobility: Kd = r*W_H+(1-r)*T, same authored r=1-.8;
T is inverse total mass common translation. SAME inverse mass/inertia, constraints,
normal/friction law, active angular inequalities and finite positional publication.
Position mobility stays original; no rotation/position repair or extra PBD/velocity
sweep. New contact feedback uses the same damping law as free articulated motion,
not an undamped support kick. Actual body deltaP minus actual terrain J gives tree
hinge Ns; measured body spin delta minus terrain/hinge/angular-limit torque gives
constitutive angular torque. These actual impulses enter existing load channel,
not undamped factor multipliers mislabeled as physical force. Residual global
linear impulse is reported, never invented/zeroed. Per-contact strict actual
kinetic energy barrier is INHERITED UNCHANGED; no combined allowance/repair/epsilon.
If this stronger barrier rejects, STOP and inspect; do not loosen it for metrics.

Impact target uses same e=.02 times PRE-FORCE incoming material-point closing
velocity. Common gravity support of an already resting body has target0, whereas
real incoming impact retains e=.02. No velocity epsilon, grounded hysteresis,
extra grip predicate or synthetic support force. Old-motion history is immutable
and per tick, not persistent model state, and is checked against original mass /
shape plus stale-factor key. Missing/mutated history/nonfinite inputs fail closed.

Candidate extends V10b preintegrated step, NOT the failed V11 full-force bypass:
original motor -> free angular drag -> existing linear drag/full gravity -> first
contact -> integrate / SAME6 position sweeps -> second contact. This is a coupled
implicit constitutive interpretation, NOT a new force-order sweep or motor retune;
all original MotorDrive numbers/targets/bounds stay. V11 bypass was not acceptance
and is inappropriate when response mobility itself is now damped. No production
core/tuning/manifest edits. Original kernels/classes and all pinned fixtures intact.

## Barriers / single new measurement
Prior native185 MUST PASS, then NEW29 (28 functional+complete tally): exact rod
support, energy/geometry, real torque ledger, zero/full damping, resting gravity vs
real impact, separating identity, missing/mutated history, invalid coefficient /
stale geometry, unchanged strict positive-energy rejection; all3 preset setup/step/
frozenN0bothpasses/actual momentum; upper AND lower active-contact boundaries.
No public Sim/clock or old full-world replay in this suite.

Then ONE NEW original600, full all-body state/channels/flags/N/sleep/position/bottom
capture. Existing scanner and guard barriers unchanged. Solver failure stops at
first failing tick. Metric-only failure still completes600, then blocks later arms.
Only complete original600 PASS permits existing sequentialthree7200. No threshold,
4s/F52 .001anchored30, displacement, penetration or no-airborne relaxation. No
adoption, physical-device/feel/performance/FA3/M1 signature from components.

Local gdlint/gdformat, exact8 and runner36 PASS are not native; native/world
outcomes NOT RUN at preregistration. Source pin generated before CI execution.

V12 first source28e96bc / run41167017247: original42 native PASS, world harness
check-only dependency compile stops on Variant-inferred `terrain` scalar in new
observer torque reconstruction. Explicit float annotation corrects this semantic
compile defect. New29 and ALL new public ticks NOT RUN. Publisher preserves exact
incident; this is not a physical attempt, posture result or an unchanged retry.

Source383c937/run41167078697: all prior185 native PASS, new29 starts but UNIT rod
fixture tries to change immutable mass/shape via restore on an already configured
capsule, correctly rejected by original contract. Fixture now restores its test
state into a FRESH CapsuleBody. No resource/core guard change; add immediate stop
on missing fixture to avoid secondary dictionary access errors. ZERO public world
ticks; this is component setup correction, not a world posture/support outcome.

## Closed measured source / read-only diagnostic registration
Source a45a2b50eb67bd0f6ca0ee4940553965bdfddafb / run41167162511 / publisher32d7e4f:
ALL native214=185+29 PASS. ONE public attempt commits37/600 ticks (0..36), then
status30 at37 in second velocity/contact pass. Max posture3.5962402248733243deg,
no airborne in ONLY the37 committed ticks. No complete600, no qualifying sleep,
all7200 NOTRUN, not adopted. Partial prefix MUST NOT be compared as a full600 PASS.

Offline exact archived work analysis: static tangential slip, separating normal
vn=.008157907402260967, vt=.0024927788320336097, Jn0, Jt=-.0014274575037939953.
Endpoint kinetic energy .06146263064834831 -> .061705010156499936, real positive
gain .00024237950815162584, NOT a roundoff/identity repair. SPD Kd and no-slip do
NOT prove incremental M-energy passivity on already damped velocities. The strict
barrier correctly stops this candidate. DO NOT add an energy allowance or bypass.

Stronger independent exact rational counterexample: unit mass, endpoints(+/-1,
+/-1), I=2, COM(vx,vy)=(-3/2,3), omega2, r1/5; at endpointa normal+y/tangent-x,
vn1/vt-1/2. Free normal remains separating, Jn0/Jt5/11 cancels slip but vx=-43/22,
omega43/22 makes E grow by EXACT293/484. Original r1 response is passive instead.
Thus V12 has a constitutive, not merely floating-point, defect. Preserve evidence.

Next registered operation is ONLY native archived single-contact inspection on
checksum4.7.2. No Sim clock/step or new world. Probe duplicates endpoint arithmetic
for observation then calls inherited publication unchanged: prove exact failure,
finite gain, atomic rejection, undamped-component negative control, independent
inclined-rod counterexample/atomic rejection. New12 controls plus original old10
inspector. Marker ONLY articulated-units+articulated-inspect, NOT execution. If
inspection fails, report failure and do not launch a creature. This diagnoses the
closed source; it does not select an alternative force order/model or adopt one.
