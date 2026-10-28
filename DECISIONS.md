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

## M0-D06 — Build evidence is not physical-device evidence

The user selected **No device available** during follow-up validation. Keep M0 open
on its installation/display/performance criterion; do not substitute an emulator,
CI success, or the 60 fps cap for measured hardware results. CI produces a debug
AAB and disposable-key APKs for later installation, with automated manifest/ABI/
16 KB checks. Generated binaries, native build files and signing keys stay out of
Git; only test tooling and evidence references are committed.

## Blocked — needs human answer

- **M0-B01 (remaining M0 gate):** a real Android phone is still required for
  AAB-derived installation, navy-screen, safe-area/lifecycle and measured 60 fps /
  frame-time evidence. The user confirmed none is currently available. Engine and
  Android build validation can be completed in CI, but hardware acceptance cannot.
- **M0-B02 (before camera implementation):** §2.3 S03 specifies airborne zoom 0.75,
  §4.8 specifies 0.72. Both are preserved under section-specific tuning names;
  neither is selected or used in M0. Which is normative?
- **M0-B03 (before contact/haptics/generator implementation):** §4.4 foot normal-force
  grip threshold, §11.3 landing haptic impulse threshold, and §6.3 generation salt,
  profile weights/heights are named but have no supplied numeric values. They are
  intentionally not fabricated as zero-valued tunables. Supply values when those
  milestones are assigned. No M0 feature depends on them.
