# Remaining M1 coupling work — implementation increment, not completion

2026-10-31 update · `arena/f43f36ab-clamber`

**M1 is NOT complete; production AC201/202 remain FAILED.** Native42/0 now
PASS in official4.7.2.ed1daf0bf CI (41149770549 and41150287513). A new full
terrain/hinge-force adapter is implemented, unadopted. Source6b48e63 compiled but
FAILED at tick index2 after TWO committed Slug frames, post-cap reconciliation.
First failure is immutable in `tests/fixtures/m1_articulated_execution/6b48e638c368/`;
all7200 arms NOT RUN. See [v2 diagnosis/protocol](physics_fix/articulated_execution_v2_plan.md).
The new inactive-cap identity correction does not modify the kernel or its strict
passivity guard. Native8 archived-frame checks now PASS. The new v2 world invocation failed
posture at tick8, max38.98deg, and solver at tick14; all7200 arms NOT RUN.
See [actual result](physics_fix/articulated_execution_v2_result.md).
Read-only native first-failure inspection10/0 now PASS (41151408137),
ZERO new world ticks, confirming the strict2-ULP energy rejection; local labelled runner17/0 and rational18/0 PASS, not world evidence.
GitHub works; local binary unavailable. No signature, FA3 credit, M2 or device waiver.

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
| **new Godot component suite** |**42/0 PASS, pinned CI**| includes chain-wide contact, hinge velocity closure, momentum/energy, rigid pose and atomic rejection |
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

1. Validate the narrow inactive-cap identity correction with8 native archived-frame
   component checks; preserve all original rejection/physics bounds.
2. NEW registered full-creature execution: posture/rest then7200 per creature
   length+penetration. The implemented adapter accounts for real hinge impulses
   with original frozen-N/grip policy. First candidate failed, not adopted.
3. Held inputs/release/wake, independent budgets/default performance and atomic
   restore/rollback coverage of the actual new assembly; no historical replay.
4. Only after physical correctness: explained production selection/provenance and
   public baseline/regressions, then remaining physical device/layout/FA/performance.

Historical environment notes above are dated snapshots; authentication now works
and native42 execution PASSED. Local binary availability is not a CI blocker.
