# V3 preregistration — causal audit, stage identity, authored angular damping

2026-10-31, fixed branch. NEW unadopted implementation; not an unchanged retry.
Original v1/v2/historical evidence immutable. No production/core/tuning change.

## Read-only diagnosis, eight offline audit controls

Saved14-frame sourcef7b8fd2 trace, hashes verified; ZERO new engine/world ticks.
At tick8: prior attitude13.875006095204565deg, after integration18.36637192151201,
final18.41374748886769. First15deg violation already exists at integration.
All angular position corrections and self-contact events through this crossing
are zero. Full endpoint position-ledger and x/y momentum-budget reconstruction
close within1e-12 OFFLINE UNIT arithmetic, not a gameplay tolerance. Grip changes
true->false at tick6 under the unchanged measured load threshold, not an invented
contact predicate. This does not prove grip loss is a defect or all rotation is
unphysical. Aggregated interleaved position phases cannot be treated as exact
chronological intermediate states. Report: articulated-posture-causal-audit.json.

Source audit: GDD4.2 and core/tuning.tres already prescribe angular damping0.8,
but NO core/sim script reads physics_angular_damping. This is a real implementation
omission, NOT proof that adding it will meet posture/sleep. Existing masses,
geometry, motor values, F24 load/grip, sleep and original thresholds remain fixed.

## Two explained changes, separate test-only classes

1. staged_articulated_candidate: a tick-local certificate of the EXACT binary64
   geometry, masses, inverse masses, topology and velocities is taken ONLY after
   successful constrained terrain + cap processing. In the next existing velocity
   pass, run the original angular/self-contact rows and validate the network as
   before. If and ONLY if every certified byte is unchanged, do not republish an
   already-constrained mathematical identity. A one-bit change invalidates it.
   Cold/changed/invalid states still take the original strict guarded projection.
   No epsilon, passivity relaxation, velocity rescaling, iteration or hidden
   cross-tick/snapshot state. Numerical sourcef7b8fd2 remains rejected when cold.

2. damped_staged_articulated_candidate: implement the EXISTING angular damping
   coefficient as fractional spin loss per fixed step, consistent with the
   existing linear coefficient convention: delta_omega = -damping * omega.
   This is an explicit candidate interpretation of the previously unused0.8
   setting, not measured acceptance or a claim the GDD spells out its units.
   Apply after motor drive, before existing point-linear damping/gravity/predict;
   existing point-linear retention also damps point spin, as it already did.
   Preserve COM analytically; record actual x/y momentum roundoff in damping
   budget and expose actual external angular impulse + before/after energy.
   No drag is a qualifying foot load, no positions/flags/sleep edited, no motion
   cutoff or parked/unconditional zeroing. Coefficient/resource not retuned.

Twenty native saved-component assertions precede any NEW world run. Includes
actual saved q inside limits/no self pairs; original extra rows bitwise identity;
cold guard still rejects atomically, warm no-op preserves every velocity/load;
one-bit velocity and geometry invalidation; invalid mass and NaN damping reject;
authored spin/COM/energy and no flag/load/position/clock mutation controls. Their
1e-12 numerical comparisons are UNIT scalar arithmetic ONLY, not solver cutoffs.

## Exact engine, one NEW invocation, original stopping rules

Native42 prerequisites -> import/check-only -> existing8 cap controls -> new20
component controls -> original NaN/Inf scanner controls -> Slug600.
ONLY if original15deg/no-airborne/.90WU/4s F52 + geometry criteria pass: sequential
Slug/Hopper/TwinRoller7200. Same six/two/distance budgets; no final distance repair,
controller, new collision geometry, mass/force substitution or sleep relaxation.
Original penetration violation only >.02*(1+1e-9). First solver/numerical failure
terminal; full-horizon metric failure stops later arms. Preserve full failure
state, report, source, engine and transport hashes in fresh <source12> folder.
No replay of any D0/R27/R28/R29 capture or unchanged failed candidate.

Native20 and new world outcome NOT RUN at preregistration. If this hypothesis
fails, reject/preserve/analyse, not secretly change parameters or keep retrying.
M1 remains BLOCKED/NOT SIGNED; production AC201/202 FAILED, FA3 uncredited,
M2 blocked; device/layout/feel/default-performance gates not waived.
