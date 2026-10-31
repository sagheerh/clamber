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
