# NEW articulated assembly — frozen before execution

Native prerequisite: sourcebc800ca1ac6520ebac3fac961723e4e80bb7ae9d,
run41149770549/job124383257583: official4.7.2.ed1daf0bf, SHA512-verified,
semantic compile +42 component assertions, zero failures. This is component
validation, not M1 acceptance. The previous local-contact candidate remains
rejected; it is not rerun or modified.

## Algorithm change, no tuning sweep

New test-only `articulated_terrain_candidate.gd` +
`actuated_articulated_candidate.gd`. Actual tree-wide hinge mobility, not old
free-point hinge rows or isolated-body contact effective mass. Six existing
position iterations, two existing distance solves per iteration, two existing
velocity passes, unchanged resource values/materials/body hierarchy/geometry.

Within each existing position iteration: distance, angular/self-contact, rigid
hinge Newton block. Terrain corrections use the same constrained mobility and
rigid pose turns, not an after-contact distance repair. Position and velocity
stages are separated: pose changes invalidate factors, so rebuild before the
velocity block. No velocity impulses or qualifying load from positional cleanup.

Both x/y hinge reactions from all network projections/contact responses are
recorded and accumulated as actual equal/opposite internal impulses for the
existing applied-load calculation on the next velocity pass. Original prior-foot
N is reconstructed from the prior committed flags each pass; original lowest,
max(5,.40W/N), N=0 disable, material/static-slip/grip-bias policy retained.
No raw terrain reaction substituted for applied normal load; no artificial
support, velocity epsilon, sleep edit, upright controller or mass change.

Original absolute angular cap remains. One block reconciliation follows it; if
cap/hinge bounds conflict, fail rather than silently scale all motion, increase
iterations or continue with broken constraints. Strict finite/passivity/projection
barriers from the42-unit component remain; an edge rejection is a failure, never
hidden by a new epsilon. New position rotations are linearized: nonlinear hinge
residual/convergence is measured, not assumed.

## One invocation, exact new source; same gate order, not old captures

Fresh public Sim/clock and existing sleep composition with explicitly substituted
NEW awake rig. Snapshot identity does not encode this test-only substitution;
therefore this is not production adoption, reference generation or determinism.
A public rollback reconstructs baseline rows: ANY step failure is terminal.

1. Both labelled nonphysical NaN/Inf scanner controls must be detected.
2. Original Slug flat floor/spawn/material, seed305419896, released600 ticks.
   Measure from spawn: max head-to-mean-foot attitude≤15°, no all-body-airborne
   ticks, actual COM net≤.90WU, unmodified F52 sleep by original4s. All bodies,
   input/channels/joints, flags, loads, sleep, positions and awake force/phase/
   contact trace retained per tick. No slop or sleep manufactured to pass.
3. ONLY if idle and geometry criteria satisfy bounds: fresh Slug, Hopper,
   TwinRoller sequential7200 each on original wide flat grid, input masks
   released/L/R/both in60-tick blocks. All capsule length errors≤.05WU; penetration
   violation ONLY `>.02*(1+1e-9)`, not bare>=.02. No 120s claim from600.
4. Any numerical/solver/query/write failure stops immediately. Full-horizon
   criterion failure stops later arms; they are explicitly NOT RUN. No automatic
   retry or old R27/R28/R29/D0 execution.
5. Preserve success OR first failure, full trace/variant failure state, source,
   engine/candidate hashes, exit status and raw/gzip hashes in NEW folder
   `tests/fixtures/m1_articulated_execution/<source12>/` on this SAME branch.
   No artifact-upload prerequisite or deletion of any old evidence.

Even satisfying these candidate metrics does not sign M1, credit FA3, waive
phone/layout/performance gates or unlock M2. Actual adoption must carry explained
new production provenance/public baseline and independent budget/restore coverage.
