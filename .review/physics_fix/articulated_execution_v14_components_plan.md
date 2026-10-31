# V14 components preregistration: entire physical constitutive stage

NO public world source/measurement selected by this commit. Native COMPONENTS
ONLY marker, NOT articulated-execution. Original historical runs not repeated.

V13 history-only source069ad4b/native237 fails posture then tick25solver; CLOSED.
V12's SPD derivative is not an independently physical impulse map after free
angular drag. Native exact finite defect is not roundoff. V12 publisher/fixtures
remain unchanged and still reject it. No scalar energy budget/epsilon/repair or
claim that V12 passes. No production/tuning/acceptance change.

New physical operator proposed for independent validation: ONE complete implicit
angular drag plus first support stage. Original raw endpoints at the actual start
are preserved, not a caller-supplied energy allowance. Private derivative trials
may NOT be committed as physical states. Complete endpoint energy MUST be <=
actual raw origin, strictly, even a single positive ULP rejects; exact mass/shape/
position/previous-position identity also mandatory. Failure uses existing whole
creature atomic rollback. Old individual strict project/contact publishers remain
UNCHANGED; original V12 finite defect is still rejected by its old physical API.
This explicitly changes operator boundary, not silently weakening old tests.
Prior instruction to avoid an ad-hoc pre-drag allowance remains: no accumulated
credit, external work credit, tolerance, extra damping or energy scaling exists.

Reason: the same d=.8 linear constitutive resistance responds to TOTAL motion
in that stage, not just to precontact motion. Constitutive derivatives are not
separate physical impulses; comparing each derivative with an already damped
intermediate misidentifies the mathematical operator. Complete implicit response
has v = D(v_free+W*J), where D=r*P_H+(1-r)*T, K=r*W_H+(1-r)*T. For a single
zero-target dissipative contact, (M+C)v=M*v_free+J with C PSD on shape modes gives
E(v)<=E(v_free). For multiple sequential contacts no blanket proof is claimed;
actual complete endpoint guard remains mandatory and may STOP. This is NOT
sufficient proof of final posture or no-airborne600.

Drag is placed immediately inside first contact stage AFTER original precontact
angular/self constraints, not a force-order sweep. Baseline controller still runs
once as V10, unchanged authored impulse/targets/gain. Uniform existing linear
damping and common gravity commute with the linear free D; full dt/gravity remain.
Same two velocity passes, same integration/six position sweeps, SAME authored
angular fraction ONCE. Final post-position pass remains ORIGINAL UNDAMPED W with
history-correct restitution and unchanged strict individual passivity. No second
implicit angular application. Damping/actual reaction/hinge budgets all retained.
Position stage cannot change geometry under a constitutive certificate; such a
change FAILS CLOSED rather than being counted as dissipative angular work.

Before ANY new public world: native30 components selected here, including scalar
complete analytic rod, inclined exact counterexample with raw omega10 ->2 and
real full energy reduction, rejection when that exact output is compared with
already-damped origin, original V12 rejection unchanged, missing origin/NaN/pose/
positiveULP faults, exact identity, allthree real isolated template step + frozenN0
and actual momentum, injected finite-gain full creature rollback, and BOTH angular
boundaries with exact geometry/strict complete energy. Old components42 also run.
No claims from source grammar alone. Any component failure means ZERO public ticks.
A future world preregistration must separately select exact source and retain all
old237 +new30 prerequisites and original600 -> sequentialthree7200 gates.

First component source688bf9d/run41168647122 is FAILED despite printing30/0:
scanner catches FOUR native out-of-bounds errors. ZERO public ticks. Original
step_impl unconditionally consumes an edge-sized force-drag hinge vector after
forces; deferred identity door returned empty instead of exact zero edge vector.
Supply correctly sized zeros for the no-op (no physical impulse fabricated) and
reset complete-stage diagnostics before every step. Add full stack context to CI
annotations, rather than accepting summary30 in presence of script errors.
