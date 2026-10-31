# V9 preregistration — authored angular fraction on articulated angular DOFs

V8 d0af122/run41160503517 is CLOSED:600 ticks solverOK, length/penetration inside
original bounds, posture fails14/max36.8245deg, no4s/600 sleep, maxstill4. No old
capture replay, no adoption, no M1 signature. Core/tuning/manifest unchanged.

Causal component hypothesis: free-body spin subtraction and subsequent hinge
reconciliation do not implement the declared fractional angular-rate loss on an
articulated assembly. Independent exact-rational Slug rotating-tree control:
old free spin rates .2 then original H projection returns motor .787001777100787
(and head .4678111587982833), not .2. Those corrections also regenerate body COM
relative motion before integration. Same0.8-per-step interpretation as the earlier
unadopted candidate, now applied to CONSTRAINED angular DOFs. GDD damping units
are not newly proven normative by a component; interpretation remains unadopted.

NEW constitutive map: P_H is the mass-metric tree hinge velocity projection.
For COM velocity V and retained r=1-d, D(v)=V+r*(P_H(v)-V). Compute projected angular
rates, construct compatible tree endpoint velocities at r*omega, and solve root
velocity from actual total COM momentum. Never target an angle, upright direction,
rest flag or particular speed. Pure global translation and d=0 are exact identities.
No arbitrary solution rescaling/inward rounding as an energy repair: r is ONLY
the original authored angular damping fraction. All motion may not be erased;
COM translation remains, with the original independent linear damping unchanged.

The projection is INTERNAL to one detached physical drag operator, like the old
combined hinge/contact response, never a separately published intermediate tick.
Strict before/after total energy barrier; any actual increase rejects atomically,
no epsilon/compensated allowance/repair. Original contact/H energy guards remain
unchanged. Direct factorization inside constitutive evaluation is not another
PBD/material-contact sweep; original6 position/2 velocity sweeps and phase order
remain unchanged (drive -> angular drag -> linear drag/full gravity/integration).
No tuning, mass, max speed/impulse, pose, slop, sleep or grip threshold change.

Actual measured per-body COM impulse differences decompose into tree internal
hinge impulses by subtree force balance; sum is measured global drag COM residual.
Derive external angular impulses from actual spin change minus hinge torque.
Record both, do not call total per-body spin loss an external torque. Carry true
hinge impulses once into original F24 applied-load bookkeeping; freeze previous N
and preserve original lowest/grounded/threshold policy. These are physical velocity
impulses, NOT finite-position cleanup or synthetic support. Pending impulse buffers
are tick-local and reset/consumed; no hidden cross-tick state/snapshot change.

Native NEW24 prerequisites: original preset/cold H setup; reproduce old damping
undo; constrained rates/COM/hinge agreement; strict energy; unchanged geometry/
flags/loads; per-body impulse and external torque ledgers; pure translation/d=0/
full-d unit identities; invalid coefficient/tree/body atomicity; all three topology
components; actual fresh motor impulse composition; candidate true-impulse wiring.
No clock/Sim/world replay in components. 1e-12 tests are offline arithmetic checks,
NEVER runtime velocity/sleep/energy/hinge allowances. Constitutive exact-rational6
and routing-double27 PASS locally; native24 NOT RUN at registration. No local Godot.

Original native42+8+20+12+36+NEW24 -> scanner controls -> ONE new Slug600.
Only full original15deg/4s rest/geometry PASS allows sequential three7200 length/
penetration arms. First gate failure stops later arms and preserves first failure,
exact source and Variant evidence. No partial posture/rest/determinism/FA3 credit.
Then, if those succeed, input/release/wake/rollback/force, adoption/provenance and
physical layout/device/default-performance gates still required. Phone owner data
cannot be fabricated or waived. M1 BLOCKED/NOT SIGNED, production AC201/202 FAILED,
M2 blocked until actual gates pass. No change to historical once-only captures.

Workspace recovery before edits: fresh sandbox Git metadata was at7d86dd5 while
persisted worktree matched every remote5edfb80 blob. Fetched fixed branch, verified
all remote-tracked file hashes, then mixed-reset metadata to that SAME branch tip
without changing any worktree file. Native engine/tool environments were absent;
local grammar/rational/double checks are not engine evidence.
