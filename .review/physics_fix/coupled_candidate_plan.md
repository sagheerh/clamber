# Fresh coupled contact candidate — protocol before execution

This is NEW code, not R27/R28 readoption or a D0/R29 recapture. No historical source,
evidence, thresholds or tuning is changed. No production `core/` callsite changes.
Primitive run 41004935173/source6c1c4878dfbf7ed9bce9bc66a181e6b1f8af90df
compiled and ran 31 checks, zero failures on official4.7.2.ed1daf0bf.

## Single implementation, no sweep

- `capsule_contact_composition.gd` is an explicitly copied/hashed **current-source**
  fixture. Original terrain sweep, prior-N/lowest/load eligibility, constants,
  transactional per-body AND batch publication, and aggregate contact projection
  guard remain. Only the endpoint response is replaced: common translation out
  of terrain and coupled COM/angular normal/tangent impulse using actual inertia.
- `actuated_contact_composition.gd` inherits the real actuated rig. Two source-
  derived methods reorder the existing distance/axial-velocity rows after the
  existing hinge/angular/self-contact rows, BEFORE contact. Six position iterations,
  two distance solves per iteration and two velocity passes remain untouched.
  No distance projection follows contact: that rejected R28 operation is absent.
- No upright controller, force multiplier, mass/weight/grip rule change, sleep
  shortcut, velocity epsilon, extra iteration, friction knob or new input.
- This is **test-only awake-row substitution** in a fresh real public Sim/clock
  and existing SleepingLoadProbe, with real authored preset/materials/terrain and
  seed305419896. Public snapshot identity does not encode the substitution;
  provenance records the actual candidate code hashes. Thus this is NOT production
  acceptance, a reference baseline, or a determinism/restore attempt. Existing
  asleep terrain classification still runs on detached original-contact shadows.
- A failed public step restores the production implementation. The harness MUST
  terminate immediately on ANY step failure; never continue on baseline rows.

## Registered gate order / honest stopping

1. Explicit nonphysical NaN AND Inf scanner controls must BOTH be detected.
2. Slug released600 ticks on the original flat-floor fixture, measured from spawn:
   max head-to-mean-foot attitude change≤15°, no all-parts-airborne ticks,
   net actual COM≤.90WU, **unmodified F52 sleep by original4s**. Record first sleep
   and every complete state (all bodies, channels/joints, flags, velocities,
   positions, sleep state and constraint state). Do not invent sleep on failure.
3. Only if gate2 AND length/penetration observations satisfy their bounds: fresh
   Slug, Hopper, TwinRoller, sequential7200 ticks each on the original wide flat
   grid, masksreleased/L/R/both in60-tick blocks. All body length errors≤.05WU;
   report penetration violations ONLY at `>.02*(1+1e-9)`. Roundoff reporting band
   is not solver slop. Record actual peaks with no normalization.
4. Any step/nonfinite/query/write failure stops immediately and preserves the
   first failure. Criterion failure is decided after that arm's registered full
   horizon for characterisation; no later arm runs. Later arms explicitly NOT RUN.
   A two-minute length PASS is NEVER inferred from600 idle ticks.
5. Store complete per-tick raw JSONL losslessly gzip-compressed plus raw/gzip
   SHA256s, source/engine/code identity, spawn state, summary and engine logs on
   this same branch in a separate new fixture directory. No historical artifacts
   removed, no Actions artifact-upload prerequisite. One candidate invocation;
   no automatic retry after failure. Publication failure is NOT accepted evidence.

Passing these candidate metrics would only permit considering production adoption
with fresh source provenance and public reference/regressions. It does not sign
M1, credit FA3, clear device/layout/performance gates or unlock M2.
