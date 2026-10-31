# V6 preregistration — angular inequalities in the same hinge/contact block

Prior V5 source813e3ef/run41157323700 is CLOSED: 600 ticks, solver OK,
first posture violation14/max51.5092822123154deg; sleep FAIL. All7200 NOT RUN.
No unchanged replay. Production AC201/202 remain FAILED; M1 BLOCKED/NOT SIGNED.

Saved100 shows finalq .7578008772383322 > upper .6981317007977316; original
last angular pass reached the upper bound. Later hinge/contact corrections reopen
it. 554 frames violate from46 onward. This is a LATE defect, not an explanation
of first posture failure14. No claim fixing this defect alone achieves posture/rest.

NEW test-only limited kernel inherits the unchanged strict energy/atomic/motion
publication guards. Adds authored parent/child relative-angle inequalities to H
in a direct mass-metric active-set solve. Contact normal is a unilateral row in
the SAME position solve, not angular correction after contact. At active angular
stops, project velocity/contact with the corresponding unilateral angular row;
allow inward release and separate angular torques from actual hinge force impulses.
No upright/world-angle target, extra motor, damping/order change, tuning/mass/slop,
energy epsilon, pose/PBD iteration or sleep/grip rule change. Active-set pivots
are algebraic factorizations, not extra world/PBD sweeps; repeated active sets
fail closed, never add a regularizer. Geometry AND bound metadata bind factors.
New tick-local certificates include authored bound metadata as well as exact state.

Separate copies of adapter/composition preserve all older candidates and evidence.
Original six position/two velocity sweeps and angular damping interpretation kept.
The new position solve may change contact's finite-precision trajectory, so no
V5 partial metric is carried forward. No production/core/manifest changes.

New24 native component assertions use a hash-pinned JSON pose derived from saved
V5tick100 (not a binary Variant and not an exact unsaved intermediate phase).
First use original AngularJoint correction, then reproduce original contact
reopening. New block must preserve that angle while respecting rigid lengths,
linear hinge rows, true normal multiplier, velocity/position separation, stale
factor and metadata atomic rejection, outward stops/inward release, contact velocity
and mirrored lower-stop sign. Unit comparisons at1e-12 are arithmetic verification,
NEVER solver/energy/rest allowances. No clocks/Sim.step/world ticks in components.

Native prerequisites42+8+20+12+24 -> original scanner controls -> ONE new600.
If original15deg/4s rest/geometry gates fail, stop all later7200 arms and preserve
first failure/source. Only full600 PASS permits sequential Slug/Hopper/Twin7200.
No new acceptance/determinism/adoption/FA3 credit from component success. Physical
layout/device/performance and production adoption/provenance gates remain.

Local gdlint/gdformat PASS; routing doubles24/24 PASS (ZERO actual engine ticks).
Native24 and new world NOT RUN at this preregistration. CI check-only/timeout60s/
quit-after1/error scanning/exact24 tally must stop BEFORE world on any component
failure. M1 remains BLOCKED/NOT SIGNED regardless of push/merge/tooling.

Component incident sourcefe1cf864e80b/run41159649791: prior42+8+20+12 PASS;
new scripts/check-only compile PASS. New component test then accessed runtime
CapsuleBody.length (snapshot name) instead of rest_length (runtime field), at the
rigidity assertion. No preceding assertion FAIL logged. New24 NOT complete;
ZERO world ticks, no posture/physics-run credit. Publisherf61eef2 preserves logs.
Fix test field only; no kernel/resource change or failed-world replay.
