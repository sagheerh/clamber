# D09 non-adopted study — registered before measurement

Authority: user confirms delegated D09=PROPORTIONAL, D08=physical hold first,
D06=author provisional minimal fixture. Read reviewer decision source by git show
origin/arena/5b72e4ab-clamber ONLY; never copied/merged. No decision re-litigation.

Three PROPOSED triples (constraint relative-speed cap, stiffness, torque cap):
(30,10,12), (30,20,12), (30,40,12). Physical proposal values live in isolated
`tests/fixtures/d09/c*/tuning.tres`, NOT core/tuning.tres. Stiffnesses are quarter,
half, and whole of owner's EXAMPLE40; all are proposals requiring measurement.
Shared30 ceiling/12 cap are owner's EXAMPLES, not derived/adopted constants.
No subsequent bound increase is authorized. All mass/weight/geometry/gravity,
linear damping, sampling, limits40 default, gain.7 remain committed defaults.

For endpoint-mass capsules I=m*extent²/4; relative inertia
Ieff=1/(1/Ip+1/Ic)=1/weight. Linearization Ieff*qddot+c*qdot+k*q=0 gives
c_critical=2*sqrt(k*Ieff)=2*sqrt(k/weight). Evaluate at authored actual setup
endpoints, independently reconstruct from raw first-tick endpoints/masses.
FIXED candidate coefficient, not adaptive damping; report loaded effective
zeta=c*sqrt(weight_loaded)/(2*sqrt(k)) separately. This is continuous linear
critical damping, not a claim that the nonlinear 60Hz constrained plant is
critically damped. For an isolated semi-implicit critical oscillator, stability
requires (dt*sqrt(k*weight))²+4*dt*sqrt(k*weight)<4. Contacts/constraints differ;
this analytic warning is not a solver threshold or permission to change dt.
The range deliberately includes the example and lower stiffnesses before seeing
any result. No coefficient chosen as nice-looking/adopted from this study.

Each candidate:6000 awake ticks in all four R23 cells both/stop_only/drive_only/
inert, plus independent6000tick proposed lurch-response run. Lurch PROPOSAL:
released0..5699, L held5700..5759=1s, released5760..5999=4s. No synthesized loads,
no altered solverHz or formal FA4 claim from a newly invented pulse protocol.
Report actual displacement and response, not a tuned success threshold.
Full raw traces/observer on-off equality/per-tick F31/F56/damping/contact/clamp/
angular projection/binary64 limit audit required EACH run. F63 independently
reconstructs both clamps with candidate coefficients; defaults of old auditors
stay strict. Compare three zero-input alternative cells per candidate per tick.

Holding criterion from owner: max over holding window |requested_impulse|/bound
<=.5, upstream torque NOT clipped. Report actual saturation and delivered ratios.
Settled pose only if exact observed recurrence supports it; otherwise null and
explicit transient q range/residual, NEVER a fitted equilibrium/A calibration.
F52 observer on awake trace is counterfactual eligibility, not actual parking or
formal AC201. D08 .001/30*60*150=.3px/s is a necessary drift line, NOT sufficient
for per-body per-tick AND anchored dwell-net predicate to fire within4s. Preserve
strict predicate, no epsilon. Record margin .3-|drift|, don't confuse low mean
with a pass. No fallback hold during study; adoption/remeasure must come first.

D06 JSON in data/towers is provisional test geometry/layout+input PROPOSAL,
subject to B04 and NOT measured FA6/product content. One floor/ledge/non-solid
spawn marker/input script. Ten runs/6–8 target remain tuning's owner values.
Identical deterministic initial states/inputs give identical outcomes: never add
noise, alter seeds or synthesize variability just to hit6–8. No FA6 run here.
No AC202/FA5 parallel work this increment: keep8/18/FA5 untouched.

STOP AND REPORT all three candidates BEFORE adoption. Core default resource and
R23 2x2 remain OLD parameterisation/history. No baseline regeneration now.
Public Sim replay/clock MUST run on this commit and reproduce existing baseline;
first future adopted solver-changing commit must rerun/regenerate with provenance.
No M2/camera/captures/waivers/silent AC201 rewrite. D07 remains queued for phone.
