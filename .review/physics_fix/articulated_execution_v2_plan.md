# Articulated assembly v2 — diagnosis and preregistration

2026-10-31; fixed branch arena/f43f36ab-clamber. NOT production adoption.

## Preserved first execution, not a compile incident

Source6b48e638c368579abcef1a59289809d6b8b7a158, CI41150287513:
native42 prerequisites PASS (job124384940295), import/compile PASS, then
job124385014033 FAIL at tick index2, after exactly TWO committed Slug frames.
Official4.7.2.ed1daf0bf; source/evidence clean and immutable under
`tests/fixtures/m1_articulated_execution/6b48e638c368/`, publisheree809141.
Error: `Articulated post-cap reconciliation failure`, status30. All three7200
arms NOT RUN. Metrics over two frames are NOT600-tick posture/rest evidence.

The failing stage unconditionally reprojects hinge velocities even when the
preceding angular cap did not change ANY velocity. That extra projection is not
a cap reconciliation; contact already used constrained mobility. Its strict
passivity guard can reject a floating-point roundoff-only projection. The last
committed archived frame has head/motor/foot speeds2.4070941984621723,
.5564046657230058,-.4764001351019629rad/s vs original24rad/s cap. This is NOT a
capture of the failing intermediate frame. The original trace did not retain
that frame or the exact rejection subcondition: do not claim a proven energy
number or assert the failing intermediate cap was inactive.

## Narrow new algorithm, not an unchanged retry or threshold relaxation

An inactive cap must be the identity. Test the EXACT existing24rad/s bound;
if no body exceeds it, perform neither zero-spin calls nor another hinge solve.
Do not accumulate numerical correction impulses as a speed cap. On an actual
cap, retain the original cap, exactly one reconciliation and strict conflict
failure. Invalid/nonfinite frames must still enter the existing rejection path.
NO change to the mobility kernel, passivity guard, tuning, thresholds, iterations,
friction/grip/F24/F52/sleep, body geometry or hierarchy. No velocity epsilon,
normalization/rescaling, upright controller, gait script or forced sleep.

Seven new native adapter assertions restore only an already preserved committed
frame and verify the inactive cap is BITWISE identity, including impulse accounts.
This never advances a creature clock or regenerates any historical arm. Semantic
compile, all42 native operator checks and all7 adapter checks must pass before
any NEW world invocation. Local runner regressions17/0 use labelled doubles,
zero real engine/world ticks. Rational/source18/0 remain separate offline checks.

New failure capture includes awake failure trace with pre-contact/cap stage,
work state and cap input as applicable, preserved as Variant bytes so NaN/Inf
cannot be hidden by JSON null conversion. This is observation, not solver state.

## One invocation on the NEW committed source

Same frozen protocol as articulated_execution_plan.md: scanner controls first;
released Slug600, original15deg/.90WU/no-airborne/4s F52 and length/penetration
criteria; ONLY on success run sequential Slug/Hopper/TwinRoller7200 original
inputs. First solver/numerical failure terminal; full-horizon criteria failure
stops later arms. Fresh source12 directory, exact engine and source hashes,
raw/gzip hashes, preserve success OR first failure without upload dependency.
No retry of6b48e63/36313ad or any R27/R28/R29/D0 historical capture.

Native7 and new world outcome are NOT RUN at this preregistration. M1 remains
BLOCKED/NOT SIGNED; production AC201/202 FAILED, FA3 uncredited, M2 blocked.
