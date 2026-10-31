# Articulated v2 — actual failure, not M1 completion

2026-10-31, fixed arena/f43f36ab-clamber. Production/core/tuning/manifest unchanged.

## Exact execution and immutable evidence

Sourcef7b8fd24d6b89cd4644e7ca559619c20a55f26cd,
CI41150933157: native42/0 PASS; native cap identity8/0 PASS; import/semantic
compile PASS. Whole-creature job124387079507 FAIL. Publisherc6eae50 preserves
`tests/fixtures/m1_articulated_execution/f7b8fd24d6b8/` including raw/gzip hashes,
14 committed frame rows, full failure Variant and source/engine/candidate hashes.
Exact official4.7.2.ed1daf0bf. No upload dependency and no unchanged replay.

| Observation | Actual value / limitation |
|---|---|
| Committed Slug ticks |14 of600; failure at index14, status30 |
| First metric violation |tick8, attitude18.41374748886769deg >15deg |
| Peak attitude before abort |38.97992391219688deg; original15deg FAIL |
| Peak capsule length error |1.6653345369377348e-16WU over14 ticks ONLY |
| Peak penetration |.01999830891325001WU over14 ticks ONLY; use `>.02*(1+1e-9)` |
| All-airborne ticks |0 over14 ticks ONLY |
| First sleep tick |−1; no4s/600 rest result |
| Failure phase |pre-contact hinge velocity, velocity pass1 (second existing pass) |
| Later arms |Slug/Hopper/TwinRoller7200 all NOT RUN |

This does NOT pass AC201/202 or establish120s stability/determinism. The
inactive-cap identity correction removed an unnecessary stage and passed its
bitwise component regression, but DID NOT repair the posture failure. Candidate
REJECTED/NOT ADOPTED. Do not change thresholds or ship it because length stayed
small in a partial run.

## Isolating the numerical rejection without another world run

The enhanced Variant trace now includes the actual failing work bodies. An
offline scalar arithmetic mirror of the existing projection on those saved bodies
reports kinetic energy .00011674319666560506 -> .00011674319666560508, a positive
2.710505431213761e-20 (2 binary64 ULPs); max hinge RHS1.22514845490862e-17,
max requested velocity increment5.0187308831723105e-17. This is an OFFLINE MIRROR,
initially not native subcondition proof. Subsequent native inspection confirms
these EXACT values and strict passivity rejection of a
roundoff-scale already-constrained re-projection. Max work-state angular speed
.057997757374956584rad/s, far below the original24 cap.

A new READ-ONLY native inspector is preregistered: load this EXACT immutable
Variant, reconstruct only component bodies, verify finite/SPD/valid post-states,
compute the hypothetical projection energy and call the unchanged native operator
on a clone; require rejection and BITWISE atomicity. Ten assertions, no Sim,
clock, step, advance or new creature ticks. Exact-engine42 operator checks first.
Opt-in markers `[M1-articulated-units] [M1-articulated-inspect]`, never the
world-execution marker. Emit native report to CI annotations, save those after
execution. Inspection native10 was NOT RUN at preregistration; actual result follows below.

No strict guard/energy epsilon/rescaling/velocity cutoff introduced. Even a
correct numerical repair would NOT erase the independently measured posture
violation at tick8. A different, explained whole-assembly fix is still needed;
no claim that the initial gravity moment proves15deg impossible, no fabricated
physical equilibrium/controller/normal load or tuning permission.

## Remaining work, not waived

Posture≤15deg, original4s F52 rest and Slug600; full three7200 length+penetration;
held L/R/both/release/wake and independent force/rollback/restore/default-performance
coverage of the actual new implementation. Only then explained production
selection/provenance/public baseline and outstanding physical layout/device/FA
and performance gates. M1 BLOCKED/NOT SIGNED; production AC201/202 FAILED,
FA3 uncredited; M2 blocked. Native50 component assertions are not those gates.

## Native diagnosis completed — no new world ticks

Source730b2b29c1c7378c0a4a408ecd611a008d1feb98,
CI41151408137/job124388545483 SUCCESS. Exact pinned official engine, native42/0
re-PASS, then **10/0 read-only saved-frame inspection assertions PASS**.
World-execution and both historical-contact jobs SKIPPED. No new world ticks.
Saved jobs/annotations: `.review/physics_fix/articulated-inspection-41151408137-*`.

Native output EXACTLY confirms e0=.00011674319666560506,
e1=.00011674319666560508, delta=2.710505431213761e-20 (2 binary64 ULPs),
max hinge RHS1.22514845490862e-17, max abs omega.057997757374956584.
Energy triple little-endian f64 hex:
`9b50cad8809a1e3f9d50cad8809a1e3f000000000000e03b`.
Geometry/SPD/finite response and hypothetical body validity all pass; the unchanged
STRICT energy comparison rejects and leaves component bodies BITWISE unchanged.
This identifies the numerical subcondition, not a cap conflict. The guard is not
weakened or bypassed. A sound next integration must avoid unnecessary/inconsistent
projection publication, not add an epsilon or quietly erase motion. That alone
still cannot cure the independent measured posture failure at tick8.

Offline immutable-evidence audit now19/0 (v1+v2+native exact-energy linkage),
labelled runner routing17/0, independent rational/source18/0 PASS. They generate
no physical captures. M1 remains incomplete, no production adoption/signature.

Regression confirmation on inspection source730b2b2: M0 run41151408189 SUCCESS,
516/0 headless + debug Android arm64/min26/target36/portrait/16KB + APK alignment;
independent M1 foundations41151408079 SUCCESS; R2941151408199 SUCCESS,
compile-only/no physical measurement. Job/annotation records saved. These are
engineering regressions, NOT physical-device/performance or M1 runtime acceptance.
