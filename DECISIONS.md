# CLAMBER decisions

The GDD's existing D-01–D-17, CD-01, and A-xx decisions remain normative.
New implementation decisions use M0-Dxx to avoid colliding with those IDs.

## M0-D01 — Empty engineering boot, not a new game screen

The packet excludes every mockup screen. `ui/boot.tscn` is only the requested solid
navy engineering surface. `ui/screens/` stays empty except `.gitkeep`; core system
and shared component stubs compile/parse without implementing future milestones.
No autoload is needed until services have consumers. Public Sim/codec signatures
are reserved with explicitly nonfunctional bodies.

## M0-D02 — Safe atomic backup staging and recovery signals

§10.5 does not prescribe how to keep `.bak` without a window where the primary is
missing. Flush `file.tmp`; if the original is valid, flush `file.bak.tmp` and rename
it to `.bak`; finally rename `.tmp` over the original. Ignore `.bak.tmp` on reads.
Do not overwrite a valid backup with an invalid primary. Reads are non-mutating and
emit recovery source (`.bak`, `.tmp`, `defaults`) for later UI, instead of putting
a toast dependency in core. First install is not reported as corruption. Writes
are synchronous, return errors, and emit write-failure signals.

## M0-D03 — Validate schema without inventing migrations

Use schema 3 from §8.4 as the current generic store schema; require a dictionary
with a numeric integral schema equal to that version. Unknown/missing schemas fall
through recovery. The GDD does not provide v1/v2 save layouts; migrations/settings
remain explicit stubs. Do not fabricate historic fixtures or silently migrate.
Constants such as schema/input identities and operational budgets live in tuning
too, to satisfy the packet's stricter no-numeric-literals-in-core requirement.
Build-required numbers are mirrored in configuration (Godot cannot read its
project/export settings from a custom Resource before boot).

## M0-D04 — Pinned toolchain, honest unavailable validation

Keep 4.7.2-stable; do not substitute an older executable. The release is listed,
but download redirects to `release-assets.githubusercontent.com`, outside this
sandbox's network allowlist. No Godot/JDK/Android SDK/adb or device is installed.
The local static/grammar checks are not substitutes for engine/device tests.
Follow-up: branch push successfully ran the pinned engine on GitHub's runner;
CI now also builds and inspects Android artifacts. See `docs/validation/M0.md`.
Manual workflow dispatch returns integration HTTP 403, so validation is triggered
by pushes to the existing session branch; no credentials or permission changes
were requested. AAB delivery needs bundletool-generated APKs to install; direct
AAB installation is not an Android operation. Device evidence remains a gate.

## M0-D05 — Validate JSON semantics and float64 representation correctly

Real engine runs showed that JSON-loaded numeric values do not have the same
GDScript Variant types as the in-memory integer fixtures. Save round trips are
therefore compared after JSON normalization on both sides; no save behavior or
payload values were changed. The `.tres` parser loads the declared 1/60 decimal
as `0.01666666666666665950`, versus GDScript division's
`0.01666666666666666644`. The resource assertion permits only four float64 relative
ULPs, not gameplay tolerance. The original tuning remains unchanged. This is a
resource representation check, not a waiver of M1's exact determinism gate.

## M0-D06 — Build evidence is not physical-device evidence (historical; M0 status superseded by M0-D07)

The user selected **No device available** during follow-up validation. Keep M0 open
on its installation/display/performance criterion; do not substitute an emulator,
CI success, or the 60 fps cap for measured hardware results. CI produces a debug
AAB and disposable-key APKs for later installation, with automated manifest/ABI/
16 KB checks. Generated binaries, native build files and signing keys stay out of
Git; only test tooling and evidence references are committed.

## M0-D07 — APPROVE — HUMAN OVERRIDE; M0-only acceptance waiver

Owner decision dated **2026-10-28**: the GDD owner reports installing and opening
an M0 debug build on a physical Android device, observing the expected solid navy
screen and no UI/gameplay. The owner explicitly approves M0 as **COMPLETE** under
GDD §16.1's “APK that boots” deliverable. Verdict: **APPROVE — HUMAN OVERRIDE**.

This is **owner verbal verification, not an E4 artifact**. No screenshot, adb log,
device identity, lifecycle/safe-area record or frame-time capture was attached.
The owner did not independently identify a binary hash in that statement; do not
infer an artifact-to-device chain of custody from the linked CI artifact metadata.

For **M0 only**, the owner waives the remaining device-evidence artifacts and the
measured **60 fps / P95 ≤16.6 ms** criterion. Neither FPS nor P95 was measured.
`Engine.max_fps = 60` is only a cap, not a measurement. Also explicitly waived for
M0 only are the review-pack artifacts `scripts/review_checks.sh` and
`.review/m0_ac_matrix.md`; they are not represented as having been produced.
M0-B01 is closed by this explicit acceptance/waiver, not by fabricated test evidence.

The M0 waiver **does not apply to M1 or any later milestone**, including solver
performance, determinism, soak evidence or later device gates. M0-D06 remains the
historical record of the earlier blocker. M0 closeout is mechanical: no runtime,
feature, tuning, save or test changes. Land/close the M0 PR first; M1 scaffolding
and implementation belong in a separate commit and PR after that boundary.

## Resolved by owner override

- **M0-B01:** closed for M0 by M0-D07; owner-reported install/boot, missing E4
  device records and unmeasured frame timing explicitly waived, not measured.

## Blocked — needs human answer

- **M0-B02 (before camera implementation):** §2.3 S03 specifies airborne zoom 0.75,
  §4.8 specifies 0.72. Both are preserved under section-specific tuning names;
  neither is selected or used in M0. Which is normative?
- **M0-B03 (before contact/haptics/generator implementation):** §4.4 foot normal-force
  grip threshold, §11.3 landing haptic impulse threshold, and §6.3 generation salt,
  profile weights/heights are named but have no supplied numeric values. They are
  intentionally not fabricated as zero-valued tunables. Supply values when those
  milestones are assigned. No M0 feature depends on them.

## M1-D01 — Independent mathematical work; no invented contact values

2026-10-28 owner clarification: proceed only with independent work while per-part
collision radii (including head), head mass/length treatment and foot normal-force
grip threshold remain unspecified. Implementing a moving/colliding creature would
require feel-affecting choices; do not infer these from limb lengths or use zero
as a hidden default. Mathematical body/link state and review infrastructure may
proceed. No contact, gait, performance or determinism acceptance is claimed.

R4 correction: the earlier attribution of an owner decision about excerpts was
incorrect and is withdrawn. The owner supplied the complete review pack on
2026-10-28. It is now vendored byte-identically and unmodified; provenance and
SHA-256 are in `docs/CLAMBER_REVIEW_AGENT.provenance.md`. Vendoring does not
constitute execution of its invariant sweep, five-fakes or A12 review.

## M1 blockers — needs human answer before dependent implementation

- M1-B01: supply body radii, head mass/length treatment and M0-B03 grip threshold
  with units. No moving-creature acceptance until the dependent physics exists.
- M1-B02: **RESOLVED (vendored), not waived**. Full owner-supplied review pack
  imported unchanged on 2026-10-28; see provenance for its exact hash. Full
  INV-01..INV-10/five-fakes/A12 execution remains outstanding.
- M0-B02 remains a camera/M2 question; haptic/generator values remain out of scope.

## M1-D02 — Scalar point/link foundations are not a creature solver

Independent increment 1 uses float64 GDScript scalar x/y, previous position,
velocity and explicitly supplied inverse mass. It introduces no radius, head
property, gravity/integration, sleep, contact, hinge or actuation tuning. Zero
inverse mass represents a mathematical pinned point; it is not a head default.
DistanceConstraint implements the standard XPBD distance projection with caller-
supplied rest length/compliance and fixed step derived from tuning tick rate.
Its multiplier must be reset by the future tick owner, not silently per iteration.

Coincident endpoints have no defined gradient; reject them rather than fabricate
an axis/epsilon. Unsolvable pinned pairs and non-finite/overflow candidates return
errors without partial mutation. Snapshot restoration validates all fields before
mutation. Synthetic fixture values in tests are mathematical examples, not
approved creature/preset tuning. Unit projection/restoration tests are NOT the M1
3600-tick replay, baseline, bit-flip falsification, contact soak or gait captures.
No complete creature determinism attempt has run; the two-attempt stop budget has
not been consumed and D-11 is not being proposed on infrastructure blockers.

## M1-D03 — Independent point/link integration and outer clock (R5)

R5 explicitly authorizes only mathematical bodies/links, fixed-step integration,
gravity from tuning, deterministic ordering and the capped outer accumulator.
`core/sim/solver.gd` is a RefCounted PointLinkSolver, not the public creature Sim.
`core/sim/accumulator.gd` is a separate RefCounted outer clock. Its entry point is
`advance(frame_seconds)`; neither class contains engine callbacks or reads clocks.
A future §10.1 driver may supply elapsed time, but this increment adds no UI/driver.
No raw frame time reaches `step()`. The scanner is unchanged (including its ban
on raw-time callback identifiers).

The fixed step is `physics_one / physics_tick_hz`, shipped at exactly 1/60,
consistent with accepted DistanceConstraint. `physics_fixed_dt_s` remains the
unchanged serialized mirror; M0-D05 records its decimal parsing difference.
The solver freezes a duplicate of supplied tuning at setup, requires the shipped
60 Hz contract, and uses supplied gravity, position iterations, distance repeats,
linear damping and velocity clamp. Semi-implicit Euler applies gravity, then
per-tick linear retention (one minus damping), clamps speed, then drifts positions.
After index-ordered distance projections, velocities are reconstructed and
clamped. Pinned mathematical points remain fixed. No angular/velocity-constraint
passes, contact, sleep, hard-reset/recovery, creature or feel acceptance is implied.
No tuning constant/value is added or changed.

Body order is caller-supplied part-index order; link order is caller-supplied
constraint-index order. Setup copies the arrays, rejects duplicates/foreign link
endpoints and preserves this order; it never sorts by object IDs or dictionaries.
The fixed graph/configuration is included in snapshot identity. Restore validates
all candidate bodies/links before publishing; a failed step rolls back the whole
tick, and a failed frame rolls back all ticks in that frame. Non-finite input/state
is reported as an error, never silently healed. Snapshots include velocities,
previous positions, multipliers, tick count and all outer-clock future state.

The clock retains fractional time below the catch-up cap. On reaching the supplied
cap (3), it drops the entire remaining time, including any fractional remainder,
and records the exact dropped seconds. It computes remaining time as accumulated
seconds minus executed steps times the fixed step. Chunk-equivalence tests avoid
cap-triggered dropping and compare equal simulated ticks; dropped wall time is not
replayed. Chunk comparisons cover solver snapshots and clock pending/dropped
seconds; last_steps is a frame-local diagnostic, not a trajectory input. This is
a primitive clock contract, not A9.4/A9.5 replay evidence.
M1-B01 and all creature-runtime acceptance gates remain unchanged/NOT RUN.
