# CLAMBER external review requirements — PARTIAL SOURCE ONLY

**The full external review pack has NOT been provided or vendored.**
This file preserves the supplied R3 checklist, not a fabricated replacement for
PART B, INV-01..INV-10, A5.6 or A12. On 2026-10-28 the owner selected “Use the
supplied requirements for now”; full-pack vendoring/signoff remains incomplete.
Replace/complete this source record only when the original pack is supplied.

## Supplied R3 checklist (owner message, 2026-10-28)

- A9.1 static scan: no randf/randi/randomize, Time.get_ticks_*,
  Engine.get_physics_frames as input, _process(delta) stepping, or unseeded
  global RNG in core/sim, core/run, core/tower.
- A9.2 fixed 1/60 accumulator, no raw frame delta.
- A9.3 injected RNG: seed is a Sim.setup parameter.
- A9.4 replay >=3 times + one 2-second stall, hashes compared at equal tick counts.
- A9.5 two frame conditions (--fixed-fps 30 / --fixed-fps 144 if supported,
  else windowed vs headless); record the exact protocol.
- A9.6 no sin/cos/tan/pow/exp/atan2 in solver step/constraint functions.
- A9.7 committed baseline + one-bit input falsification that FAILS if the hash
  is unchanged.
- A8 regression: M1+ replay matches baseline; test count must not drop below the
  M0 baseline of 488 checks without a DECISIONS.md justification.
- Full INV-01..INV-10 sweep every milestone.
- A5.6 five-fakes check and A12 .review/m1_verdict.md/.json + formal PR review
  before M1 signoff.

## Latest M1 packet — additional required evidence

- XPBD bodies, links, limited hinges, motors, feet, signed-distance grid, contact
  response, sleeping, clamps and non-finite/bounds guards.
- Quantised tree model, derived masses and three data presets: The Slug (3),
  The Hopper (8), Twin Roller (6; both motors on one channel).
- Desktop diagnostic scene only: wireframe, contacts, motor glow, hash overlay,
  held L/R buttons, flat floor and ledges. No M2 tower/camera/product screens.
- Fixed 3600-tick input replay; 100 local repeats; at least two machines or
  architectures; AC-201/202/204 and distinct preset gaits.
- After two honest failed determinism attempts, stop and propose D-11 in
  DECISIONS.md. Infrastructure blockers are not determinism failures; do not
  invent attempts, a passing baseline, or a fallback invocation.

## Evidence policy

Static CI proves only its named checks. M0 regression is not M1 runtime evidence.
No M1 runtime gate is waived by M0-D07. Missing source text, five-fakes definitions
and the formal INV mapping remain unavailable and must not be silently invented.
