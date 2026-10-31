# V8 — finite feasible tree/contact position coordinates (preregistration)

V7 source8368e14f716ffebfb64052c715d0dda3eecee9b3/run41159963288 is CLOSED.
Native42+8+20+12+27 PASS, actual600/600 solverOK. All physical states exactly equal
V5 through tick45; first change46 (independent JSON state comparison). Targeted
angular reopening removed: max native upper excess5.551115123125783e-16rad (tick79),
ZERO material excess>1e-12 (offline comparison, not a runtime allowance). But NEW
penetration regression begins47; max.02006846411770838WU at577 exceeds ORIGINAL
.02*(1+1e-9). Posture still fails14/max50.42405874018188deg; no sleep, still streak
max17. Length6.106226635438361e-16WU; COM.3537680379848081. All7200 NOT RUN.
Publisherc400dff preserves immutable8368e14f716f, no adoption, NO M1 signature.

Cause: active angular rows fix the angle in a linear tangent solve, but finite
body rotations leave nonlinear hinge gaps; solving subsequent normals separately
can reopen an earlier floor contact. Need a finite feasible coordinate publication,
not more sweeps, a softened angle or penetration allowance, or a late repair.

NEW position operator, on detached bodies inside the SAME contact position call:
1. Retain original strict requested/actual displacement guards on block delta.
2. Construct finite tree coordinates from the block's chosen relative rotations,
   assigning each child A exactly to parent B; preserve block's mass COM by a
   common translation. This is rigidity BEFORE the terrain position stage.
3. Solve remaining global translation against ALL sampled terrain halfspaces at
   once. Minimum-norm 2D translation has at most two active planes: direct finite
   active-set enumeration, no convergence/epsilon/iteration setting. Merge equal
   plane normals; infeasible geometry fails closed. No rotation/hinge repair AFTER
   the terrain translation, which structurally preserves all tree/angle constraints.
4. Check TOTAL finite endpoint displacement against unchanged projection cap;
   publish positions only once. No velocity edit, synthetic impulse/load, sleep,
   gravity/motor/damping/tuning change. Position translations are NOT contact force
   or qualifying grip. Exact terrain eligibility/sampling/slop policies retained.

Free old proposal remains bitwise intact only when both angular and terrain
feasibility permit it. Active finite-coordinate path is bound to the same tree/
geometry; all old velocity/energy guards unchanged. Terrain planes are local
sample constraints, not a guarantee across unsampled polygon transitions; full
original geometry gates remain mandatory. No pretense of production/performance
or all-slope certification from a flat-floor component.

New native suite36 = previous27 + nine controls on hash-pinned JSON poses of V7's
actual worst penetration577: provenance, successful finite publication, every hinge
bitwise coincident, ALL bottoms within ORIGINAL slop+roundoff reporting bound,
angular limit, unchanged velocities, two-plane solve, infeasible rejection, and
unchanged total-motion cap/atomicity. No world clocks/replay. Native36 pending.
Local format/lint and routing24 PASS; no local Godot/native credit.

Original prerequisites42+8+20+12+36 -> scanner controls -> ONE NEW600. Original
posture15deg/4s rest/length/penetration gates unchanged; fail -> no later7200.
Only full600 PASS permits sequential three7200. No unchanged V7 replay; no
production/core/manifest changes; M1 BLOCKED/NOT SIGNED, AC201/202 FAILED,
FA3 uncredited, M2 blocked, device/layout/performance/adoption gates remain.
