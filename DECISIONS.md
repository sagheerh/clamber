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
CI is configured to download/checksum/run the exact engine on a normal runner.
AAB delivery needs bundletool-generated APKs to install; direct AAB installation
is not an Android operation. Device evidence and 16 KB alignment remain gates.

## Blocked — needs human answer

- **M0-B01 (M0 completion):** provide a runner with the exact engine and Android
  toolchain, plus a physical Android device for AAB-derived installation, safe-area,
  lifecycle, native alignment and 60 fps/frame-time evidence. Can these be run on
  your development machine or CI/device lab? No device result is available here.
- **M0-B02 (before camera implementation):** §2.3 S03 specifies airborne zoom 0.75,
  §4.8 specifies 0.72. Both are preserved under section-specific tuning names;
  neither is selected or used in M0. Which is normative?
- **M0-B03 (before contact/haptics/generator implementation):** §4.4 foot normal-force
  grip threshold, §11.3 landing haptic impulse threshold, and §6.3 generation salt,
  profile weights/heights are named but have no supplied numeric values. They are
  intentionally not fabricated as zero-valued tunables. Supply values when those
  milestones are assigned. No M0 feature depends on them.
