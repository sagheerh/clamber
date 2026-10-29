# M1 R27 — owner split, policy verdict, one post-contact arm, soak/static tests

Read readonly reviewer57ed098 `.review/M1_R27_OPTION2_DECISION.md` in full via
`git show`; never copied. Binding user directive supersedes R26 stop ONLY for
AC201a/b measurement, ONE AC202 ordering candidate/all3presets, AC204 and FA3.
Drift is CLOSED: no D1, brace, knob/sleep/slip/stiffness/damping/torque/epsilon
or tolerance changes. Physical resource bytes stay5f4d0d…; original GDD text stays.

Pre-outcome fixture/metric contract: `tests/fixtures/r27_plan.json`. AC201600tick
Slug on committed defaults, vector from head centre to foot-centroid vs spawn,
net 2D mass-weighted COM displacement from spawn (not steady drift extrapolation).
Owner1BL=.90WU/135px threshold derived before result. Report raw measured margin,
.5BL alternative,13.5px/s steady boundary, and owner85.5px reference separately.
Unmodified F52 remains named AC201s FAILED/M1.1, no suppressed failure.

FA5 owner-reviewed PASS uses original R26 archived evidence, adopted per-foot/
branch tick-episode definition,2–4tick transient coverage caveat.236 foot/pass
observations comprise96ledge+92drop+48midair; not236capsule samples allfromledge.
F76 contact positional correction is the measured length-error injector, after
the position iteration LOOP (not interleaved after EACH iteration in current
code). Landing clustering is consistent with largest impact corrections. Retain
correct arm values: baseline final-angular .0149270524 versus diagnostic
.0151407516; diagnostic contact/completed .05191061794. Prior angular hypothesis
falsified. D1 normal/position-path interpretation is owner mechanism-of-record,
not a located correctness-shaped drift fix. Thrust range.107325..118855N is
~±5.1% about its midpoint (~10.7% peak/min), not a5% total range.

AC202: MOVE existing diagnostic-only distance traversal to after BOTH contact
passes, ONCE at the end. Same rows, project code, compliance, multipliers; no
reset or iteration/velocity edit. Exactly one configuration across all3presets,
7200ticks each on preregistered±64WU TEST plane domain (known R26±12 truncation
not repeated; analytical plane/grid spacing/material/body geometry unchanged);
all articulated motor/passive/limb segments count, literal limbs
and feet/head separately. Default flag remainsfalse pending adoption; ordinary
replay must match existing brace-free baseline. No new production baseline is
invented for an unadopted candidate. Each candidate trace gets own hash/provenance.

FA3:600ticks each real preset, static zero input, actual sleep-breaking contacts
per unmodified F42, full contact trace plus sleeping opportunities. Do not call
an awake creeping body resting, or zero sleep opportunities sustained sleep.
AC204:200 independent seeded numerical runs of real public-used composition,
120s each (adjacent AC202 duration is nearest specified horizon),20batches×10.
Preregistered wider diagnostic floor bounds, no synthetic loads/pose/velocities;
no post-outcome fixture revision. All nonzero solver statuses fail the run even
if rollback leaves finite state. Log every seed/outcome, check every tick's
snapshot/constraints and returned observations for nonfinite values; no retry.

**Expectation:** M1 will reach18/18 MEASURED, not18/18 passing. FA4 lurch and
AC201s sleep depend on contact rectifier/M1.1. Do NOT call16/18 M1 complete
without this sentence, scoped follow-ups and measured verdicts for every row;
M2 remains blocked until failures resolved or owner amends GDD. No extra tasks.
