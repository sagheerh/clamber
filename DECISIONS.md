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

The owner also selected use of the supplied review requirements for now. The file
`docs/CLAMBER_REVIEW_AGENT.md` is explicitly a partial transcription, not the full
external pack. Original INV mapping/five-fakes definitions and A12 details still
need the original source before signoff. F2 remains partially blocked, not done.

## M1 blockers — needs human answer before dependent implementation

- M1-B01: supply body radii, head mass/length treatment and M0-B03 grip threshold
  with units. No moving-creature acceptance until the dependent physics exists.
- M1-B02: supply full external review pack. Partial R3 text is tracked honestly;
  it cannot establish full INV-01..INV-10/five-fakes/A12 review compliance.
- M0-B02 remains a camera/M2 question; haptic/generator values remain out of scope.
