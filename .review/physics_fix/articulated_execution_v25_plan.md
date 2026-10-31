# V25: final-geometry constitutive operator split — COMPONENTS ONLY

V24 sourcea2a900fe2b29/run41218016181 CLOSEDFAIL:401native,600/Slug7200PASS;
Hopper227FINAL status30, TwinNOTRUN; publishera258574. No unchanged retry.
V24first complete constitutive stage passed1.5156160421302822→4.0764550485385975e-26.
Stable coordinates fix particular frames but do not solve generic endpoint
quantization/passivity. NO more coordinate variation / ULP nudge / guard waiver.

Explicit different discretization: initial UNDAMPED physical impact/support,
positions+six sweeps, then the SINGLE complete authored angular-drag/support
operator evaluated on final actual geometry. Full angular retention unchanged.2;
NO extra angular stage, damping coefficient, iteration or energy-derived branch.
The entire original local-drag plus coupled-support operator moves together, not
an extra post-hoc damper. Linear loss, one original drive, full gravity, 2passes,
6positions, caps/material/masses/axes/sleep/RNG/guards remain. Existing candidate
classes still usephase0. New subclass explicitly recordsphase1; historical
capture semantics stay immutable. This changes stage ordering, not a tuning fix.

Purpose: constitutive law should close on same final geometry as end-of-tick
constraints, not be followed by an unrelated undamped near-null projection after
nonlinear position operations. Original strict per-stage/whole actual endpoint
energy barriers remain; first physical impact also strictly passive. New formula
must prove native before any public-world registration. It is NOT guaranteed by
the earlier coordinate regressions and could still fail.

Required zero-public-clock native: original42 plus new57 controls. Twelve real
component steps across3models/all4held masks, phase counts/controller once,
actual-energy/impulse ledgers;3 invalid real-material rollback; three archived
failed FINAL frames as stress inputs with complete constitutive physical guards.
Archived inputs have old stage history: applying final constitutive operator is
ONLY a component stress check, NOT a full new tick or evidence of no-double-drag
in an old world. New real component steps prove one phase per NEW tick. No new
world, runtime-suite retry, production adoption or full validation credit here.

e7cb805/run41218469555: native57/0 assertions passed but scanner correctly
REJECTED three expected negative material controls calling the logging public
probe door. ZERO public Sim ticks; do not credit jobSUCCESS. Negative material
control now calls SAME real adapter's silent checked-outcome entry directly and
asserts byte-identical bodies. No log scanner suppression/relaxation or physics
change. Runtime/full-frame rollback is separately covered by typed contract.
Runner has new mandatory57 gate plus old401;60 failclosed double controls.
World/runtime selection points at NEW explicitly versioned subclass only, no
world or runtime selector on this proof commit. Require green exact-engine job.

## Exact-engine proof SUCCESS
adb2d9e/run41218710566: native42 + final-geometry57 PASS, strict scanner clean,
ZERO public Sim ticks. All3models/all4masks first component step, actual ledgers,
three old failing final-frame stress inputs and silent material rejection PASS.
This is NOT long-world or full input acceptance.

Next gate BEFORE spending another ordered world: NEW physics runtime contract
(first attempt on V25; NOT rerun of failed V23 recipe), expected195 checks across
three creatures, first failure STOP. Four extra fake-resource cases now require
independent actual load formula/previousN/grip predicate, fixed actual materials,
preimpact normal target and independent angular-speed bounds. No acceptance
threshold changed. Observations add actual POST-position endpoint pose per sample
so angular impulse is not reconstructed on pre-contact/before-cleanup geometry.
Typed factory/partial-frame live mutation rollback/no leaked signals and natural
input wake/release cases retained. Exact success/first failure stored as bounded
Variant evidence, source manifest and logs on same branch without upload quota.
Full runtime and long world still pending; no fullF31/FA3/determinism signoff.

## Contract factory defect found; earlier physics/input credit WITHDRAWN
V25a89bbe3/run41218837826 CLOSED84/1,24awake; same Hopper mask2 tick1; TwinNOTRUN.
No V25 long world ran. Recorder failed (job contents permission read only);
full logs unavailable through permitted hosts; do NOT pretend full failure was
captured. Existing annotations retained. No unchanged public retry.

SOURCE diagnosis: CandidateSim._configure called base Sim._configure then
_restore(snapshot()) on BASELINE initial snapshot. Although restore rebuilt the
right candidate TYPE, it overwrote its derived toe geometry with cardinal
baseline coordinates. That invalidates earlier Slug physics/input/wake coverage
as evidence for the actual candidate stance; type/atomicity controls were real
but NOT correct-geometry integration. Public ordered worlds injected the fresh
candidate directly and do not contain this harness setup defect.

Actual fix: initialize typed solver/fresh public accumulator DIRECTLY after
identity/RNG setup, NEVER restore baseline initial physics. Candidate identity
is explicitly test-only recipe; normal restore/rollback still reconstructs typed
candidate from its own valid snapshots. New setup assertion byte-compares FULL
physical snapshot against independent standalone same candidate setup, not just
get_script/type. Fix is a real observed factory defect, so new corrected contract
is authorized validation of CHANGED setup, not blind retry of failed physics.
Job gets same fixed-branch bounded evidence write permission as world publisher.
No scanner relaxation. Expected195 if3complete; first failure STOP. No world
marker until corrected native contract passes. Production untouched.

559bfe9/run41219084856 compile FAILED/ZERO public ticks: GDScript constant is
class-like, `AWAKE.resource_path` not a static member. Identity now uses explicit
versioned string. No corrected-geometry runtime measurement occurred on this
source; next is launch correction, not a retry of a failed physics measurement.
Recorder checkout is exact SHA/detached: push committed HEAD explicitly to ONLY
refs/heads/arena/f43f36ab-clamber, never a different branch or force push.

## Correct-geometry runtime CLOSEDFAIL (actual evidence now preserved)
00f33495a75c/run41219237028/publisher47e8071:88checks/1failure/26awake audits;
Slug65completed with matching fresh candidate geometry; Hopper maskBOTH tick4
(mask3/tick0 in case) fails FIRST UNDAMPED physical support; TwinNOTRUN.
Full source/logs and failure Variant saved `tests/fixtures/m1_candidate_runtime/00f33495a75c/`.
This is REAL physics failure, not the old wrong-geometry setup or launch incident.
Final constitutive stage truthfully NOTRUN (status3), not misreported PASS.
No V25 600/7200 world registered. Full requested items still INCOMPLETE.

Read-only nextgate: reconstruct exact archived before-contact raw bodies/history/
limits/terrain, run original physical BLOCK through probe (4 assertions: frame,
expected failure, all inputs atomic, active solve entered), print factor/actual
energy diagnosis. ZERO public OR private clock ticks. No unchanged runtime-suite
retry or long world. Resourcefakes/geometry observations must not be weakened to
make this case pass. Production and original acceptance thresholds unchanged.

## Targeted second blocker fix: dual-feasible normal pivots
Read-only40b26ad/run41219433113 SUCCESS/native4 ZERO creature ticks: first normal
solve succeeds, second material solve FAILS, publisher NOT reached. Independent
binary64 reconstruction of exact archive identifies sequence second:
active[0,1] lambda0=-.8527806036673949, nextnormal2 violated; adds it anyway;
active[0,1,2] lambda0=-.7516712369667986, normal3 violated; adds it ->rankfail[0,1,2,3].
Known tensile contact must have been removed FIRST. Dual-feasible ordering removes
normal0 at[0,1], then finishesactive[1,2],lambda[.6578958667967969,.8901006825767206].
This is NOT tiny-energy rejection, rank tolerance or extra iteration budget.

Change generic test candidate active solver to discard strict negative active
multipliers BEFORE adding another violated inequality. Deterministic first index,
strict signs, finite/visited-cycle/factor/publisher guards unchanged. No epsilon,
regularization, rank waiver, normal target rounding or changed constraint set.
Frozen primal-first method in diagnostic control preserves expected old failure.
New native6: real archive strict publisher/momentum/pose plus exact2D counterexample
(old adds3rows for2DOF and fails, new active[2] gives[1.1,2.2],all constraints).
ONLY component proof requested; no new runtime/world until green. All prior
458 native barriers must remain for eventual ordered world.

ba66c3e/run41219569109 SUCCESS: native42+new6/ZERO creature ticks; archived
physical rejection fixed, ORIGINAL actual energy publisher PASS and real terrain
momentum/unchanged poses; exact counterexample distinguishes old/new ordering.
Next corrected runtime contract is NEW physically changed kernel, not retry of
failed source. Independent angular law now verifies BOTH local -C*omega and
contact response -C*deltaOmega (C=I*d/(1-d)) on actual per-observation geometry,
not merely summing reported torques. Compensated fake drag/hinge pair must fail
although the old circular net ledger would close. Real positive linear-cap force
components seed uniform100WU/s (labelled test initial condition, NOT tuning) and
verify exact42 resource plus full fresh gravity and actual clamp impulses; fake
omitted clamp must fail. These components DO NOT advance any creature tick.
Expect207:69percreature, first unexpected failureSTOP; first actual full force
sample and positive clamp sample per creature persist in bounded Variant report.
Full ordered world remains NOTRUN for V25 until this gate green; no adoption.

## Corrected full registered runtime matrix PASS
93b2f1fb0cd7/run41219732497 SUCCESS/publisher67be347:207checks/0failures,
66 actual awake force audits; complete cases Slug/Hopper/TwinRoller. Positive force
and clamp Variants retained with exact source manifest.69checks per creature:
all held bits/release + actual natural input wake3masks + sleeping/awake restore,
byte identity/typed geometry, malformed restore5, live body-mutating partialframe
failure/no leaked signals/all-state rollback and candidate continuation+3cap/drop;
independent per-observation force/angular/resource/controller/contact closure,
14 bad force variants including compensated drag/hinge; actual positive linear
clamp component plus omitted-clamp negative. These force-only clamp cases have
ZERO integration ticks and are NOT motion/FA3 captures. Candidate namespace only;
no claim production Sim factories changed, crossarch determinism, phone or FA3.

Register FIRST V25 ordered world ONLY NOW, same physically proved recipe and
corrected dual-feasible kernel.63failclosed runner controlsPASS (62.462s).
All464native prerequisites required before any public tick; then original600
complete predicate (15deg/noallair/.90actualspawn/4s/F52.001anchored30), Slug7200,
Hopper7200,Twin7200, firstfailureSTOP. No thresholds/materials/masses/iterations
changed. Test-only result scope explicitly states V25 rather than historical
first-support wording. No other public world selected/rerun. Full M1/signature
and production adoption remain blocked even if this requested scoped matrix passes.

## FIRST V25 world CLOSEDFAIL — do not claim completion
9343fb06296f/run41219891289/publisherffe57e4: all464nativePASS; original600FULL
PASS (posture0,air0,penetration0,net0,sleep29/original4s), Slug7200 geometryPASS
(length2.220446049250313e-16WU,peakpenetration.012012090780530296WU,netCOM.3586042012433926WU).
Hopper285 FIRST PHYSICAL velocity_pass_0 status30; TwinNOTRUN; later arms STOP.
Final constitutive stage status3/NOTRUN, not failed or PASS. One stale scope label
claimed "complete FINAL support" despite status3; fix reporting ONLY when statusOK,
leave actual NOTRUN wording otherwise. No solver/acceptance change or new world.

207/0 full registered runtime/input/wake/force/rollback matrix remains real scoped
PASS on all3, but is NOT all7200/dynamic-state coverage or production adoption.
Independent archived arithmetic confirms saved3first-awake and3positiveclamp
samples; maxlinear2.64e-16Ns/contactangular4.16e-17NsWU/material3.47e-17NsWU,
positiveclampNs8.53e-14,velocity0.0. Sampled qualifyinggrip0 so FA3 uncredited.
Exact285 archived read-only manifold diagnostic preregistered next: same physical
kernel,history/limits/terrain/raw precontact work, original strict publisher and
active factor trace;4checks, ZERO public OR private ticks. No unchanged world or
runtime retry. Both requested items must NOT be called jointly complete.

Twofold first native7a4a1e0/run41220529564 compiled original42PASS, but new test
compile STOPPED: lowercase scalar reference after preload rename toSCALAR on
wrapped line72. ZERO creature/component ticks for that test; not physical failure.
Correct test identifier only, retain incident annotations; same preregistered10
native controls follow before any new runtime/world. No acceptance claim.

fbf629d/run41220578564: actual285 changed component DOES solve same active[0,1,2]
and original strict publisher passes (actual1.2157209960538857→.1827241817815083),
endpoint momentum/poses pass. Native10 overall FAIL1: exact long-decimal low-word
assertion. Fix that test's operand/expectation construction using exact power-of-2
division, retaining exact equality, not epsilon. No new world or adoption. Full
5test Python rational analysis retained; no ticks. Subsequent10 must all pass.
