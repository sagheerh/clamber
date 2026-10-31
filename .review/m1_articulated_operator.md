# Remaining M1 coupling work — implementation increment, not completion

2026-10-30 · `arena/f43f36ab-clamber`

**M1 is NOT complete; production AC-201/AC-202 remain FAILED.** This increment
implements the missing *network-level* hinge/contact inverse-mass operator. It is
not selected by production or the previously rejected candidate. Native semantic
compilation, assembled integration, posture/sleep,7200 length+penetration and
physical-device/performance gates are still open. No signature, FA3 credit or M2.

## Why a different operator is needed

The previous candidate kept bones rigid but contact moved one body independently
of its hinged neighbours. Its600-row trace has hinge relative endpoint speed up
to1.7990887822518324WU/s. Replacing endpoint contact with a local COM/spin response
alone cannot preserve inter-body hinge constraints. Increasing friction, sleep
thresholds or iteration counts would not repair that missing coupling.

`tests/physics_fix/articulated_mobility_candidate.gd` implements:

```
W  = diagonal inverse mass / actual-extent inertia, 3 DOFs per capsule
H  = both x/y endpoint coincidence rows for EVERY parent-child hinge
A  = H W H^T
Wc = W - W H^T A^-1 H W
```

A valid rooted tree makes `A` positive definite; a strict Cholesky factorization
solves the hinge block directly. This is not an additional solver iteration, an
invented compliance, diagonal regularizer, mass change or acceptance epsilon.

- Tree-wide impulse mobility: a foot impulse reaches its motor/head while
  `H delta_velocity = 0`, rather than reopening the hinge after terrain contact.
- Initial hinge velocity projection and normal/tangent contact response are
  prepared and committed in ONE shadow transaction across all bodies.
- The2x2 contact-space matrix uses `Wc`; post-normal tangent retention and a
  unilateral normal impulse follow the earlier candidate's policy inputs.
- All actual internal hinge impulses are returned separately for future force
  budgeting. The kernel **does not overwrite qualifying load or choose grip**.
  A later adapter must account for these real internal reactions, gravity and
  motor impulses without substituting raw terrain reaction for F24 applied load.
- Axial endpoint velocity is projected out structurally while preserving COM
  velocity and spin, with no velocity cutoff, motion parking or sleep predicate.
- Rigid pose Newton steps and a contact-position increment use the same hinge
  mobility. Finite rotations preserve capsule extent. Position multipliers have
  kg·WU units and are NOT velocity impulses, normal loads or grip credit.
- Position contact preserves hinges only **to first order**; finite-angle residual
  and multi-contact convergence are NOT claimed solved. Factors must be rebuilt
  after position or mass changes; stale factors are rejected before mutation.
- Existing projection cap guards both requested linear Newton displacement and
  actual endpoint motion. A bounded scalar remainder precedes CORDIC rotation,
  preventing huge finite angles from hanging the iterative angle-wrap routine.
- Finite validation, alias/cycle/topology rejection, aggregate shadow commit/
  rollback and strict energy non-increase checks remain. Roundoff-edge strict
  passivity rejection is still possible and needs native testing; no epsilon
  or quiet rescale has been added to conceal it.

## Actual validation in this reply

| Check | Result | Meaning |
|---|---:|---|
| `tests/test_articulated_mobility_analysis.py` |18/0| independent Fraction/Gaussian oracle and source controls; NOT native code execution |
| `tests/test_articulated_units_runner.py` |12/0| labelled TEST DOUBLE routing and source provenance, zero engine/world ticks |
| new GDScript grammar/format/lint |clean| NOT semantic compile |
| original contact analytical controls |12/0| no change to old candidate |
| sealed prior failure audit |12/0| old trace/evidence untouched, no replay |
| provenance controls |10/0| production tree/manifest unchanged |
| no-.git ZIP review controls |232/0| original assertions unchanged; no old engine arms |
| **new Godot component suite** |**42 planned, NOT RUN**| includes chain-wide contact, hinge velocity closure, momentum/energy, rigid pose and atomic rejection |
| new complete-creature acceptance |**NOT RUN**| no prototype world measurement or production adoption |

The rational oracle also reads the **last frame** of the sealed prior failed
trace (hash verified) and shows that the new linear hinge block removes its
hinge-velocity residual without increasing kinetic energy. It explicitly retains
its nonzero position gap: this is offline frame algebra, not600 ticks rerun,
not a nonlinear rest result and not an AC pass. A branched tree, one-body limit,
linear/angular momentum, mobility symmetry/positivity, projection idempotence,
normal/tangent targets and contact increments in the hinge nullspace are covered.

Logs: `.review/physics_fix/articulated-*.log`. Candidate/source inventory:
`.review/physics_fix/articulated-candidate-source.json`.

## Previous environment snapshot (GitHub now reconnected)

This restored checkout is on the correct active branch, with HEAD7d86dd5 and
prior session files present as working-tree changes. Earlier published commit/run
identities remain historical records; they are not claimed as this checkout's
new source. The new runner records a dirty checkout's HEAD separately and leaves
`source_commit` null, rather than presenting old HEAD as the new implementation.

No local Godot executable is installed. Official binary fetch failed with a TLS
connection error. `gh auth status` reports an invalid GitHub connection. **Reconnect
GitHub in Arena** to permit source-pinned native CI; never send credentials in chat.
That previous continuation made no push/dispatch/engine attempt. Owner has now
reconnected GitHub; authentication and same-branch fetch succeed. The local
release-asset redirect still fails. Proceed with source-pinned native CI.
No billing operation or artifact deletion was attempted.

The opt-in `articulated-primitives` job is ready in
`.github/workflows/m1-physics-fix.yml`. It requires the exact branch/event SHA and
`[M1-articulated-units]` commit marker, installs SHA512-verified official4.7.2,
then imports, check-only compiles and runs just the new42 component assertions.
It **does not select or rerun** the rejected composition or historical arms, and
has no Actions artifact-upload prerequisite. Local equivalent:

```bash
export GODOT=/absolute/path/to/checksum-verified-official-godot4.7.2
bash tests/run_m1_articulated_units.sh
```

The runner refuses existing evidence, propagates nonzero exits and logged errors,
requires all42 assertions, and records exact code hashes plus checkout dirtiness.
Passing it is a prerequisite to—not a replacement for—assembly and acceptance.

## Still needed, without pretending the task is done

1. Native semantic compile/component execution of this operator. Diagnose any
   failed primitive before attempting another world candidate.
2. A **new** articulated terrain adapter must combine real sweep/manifold samples,
   original frozen-N/lowest/grip policy, actual returned hinge/motor force budgets,
   angular/self-contact constraints and existing caps. This adapter is **not yet
   implemented or selected**. Do not feed the new mobility into the old local
   denominator or continue a failed public step after rollback.
3. Registered source-pinned full-creature posture/rest/release and length+
   penetration tests; preserve first failure and don't infer120s from idle600.
4. Only validated production selection with new explained source provenance and
   public baseline/regressions, then outstanding device/layout/FA/performance gates.

The implementation is progress on the demonstrated coupling defect, **not a claim
that posture15°, sleep4s or the whole M1 implementation is now complete**.
