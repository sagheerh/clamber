# M1 acceptance matrix — scaffold, NOT approval evidence

**Status: independent math unit tests PASS; all M1 creature runtime acceptance gates NOT RUN.**

M0 was landed separately in PR [#1](https://github.com/sagheerh/clamber/pull/1),
merge commit `c641990be2d77c57c223bc7cbc54d0097c3d8816`. Its closeout is approved
by owner override (M0-D07). **No M0 evidence/performance waiver applies to M1.**
This matrix is the separate M1 PR scaffold, not a solver implementation or a claim
that the M0 headless suite validates M1. No baseline hash is fabricated here.

## Normative inputs and boundaries

- Owner M1 packet and full review pack supplied 2026-10-28: PART A A1–A13,
  A9 seven points, A10 five fakes, PART B INV-01–10 / M1, PARTS C/D/E.
- GDD §3.2–3.4, §4.1–4.6, §10.3/§10.4/§10.6, §13.1 and §16.1.
- Scope: standalone custom PBD/XPBD solver, three preset creatures, headless
  determinism/feel harness and evidence. Preserve the public Sim interface.
- Not in scope: S03 climb, pause/fall/build screens, camera, tower generator,
  economy, platform integrations, codec implementation, autonomous gameplay.
- Godot 4.7.2-stable only. Offline/headless core, no UI/platform dependencies.
- L/R held states are the only inputs. Seed is injected through `Sim.setup`;
  explicitly seeded xoshiro128** only, never global RNG calls.
- Fixed 1/60 steps from tuning; an outer accumulator handles frame cadence,
  at most three catch-up steps then drops excess per §4.2. No raw frame delta
  enters `Sim.step` or integration/constraint math.
- No sin/cos/tan/pow/exp/atan2 in step/constraint paths; sqrt is permitted.
  No RigidBody2D/Joint2D/PinJoint2D/DampedSpringJoint2D anywhere in the build.
- All runtime tuning from `core/tuning.tres`. Preserve M0 tests and existing
  values; no tolerance/constant changes to manufacture a pass.

## Required gates and evidence

Reconciled with the full, owner-supplied 2026-10-28 review pack in
`docs/CLAMBER_REVIEW_AGENT.md`, byte-identical and unmodified, 379 lines. SHA-256:
`e3bd06654e0f92aaca55d0cc85e79f6d589a45aa6d9ddab5f4f068db22edb9a1`.
Provenance: `docs/CLAMBER_REVIEW_AGENT.provenance.md`. **M1-B02 RESOLVED
(vendored), not waived.** All pending sweep/protocol executions remain pending.

| Gate / source | Required acceptance evidence | Status | Evidence reference |
|---|---|---|---|
| Full PART B INV-01..INV-10 sweep | Complete the ten checks below with original pack E1/E2/E4 evidence; static subset alone is insufficient | NOT RUN | Full pack vendored; full semantic/manual sweep outstanding |
| INV-01 | No engine physics nodes in core; E1 scanner plus E2 code review | NOT RUN | scripts/review_static.py subset only; full review outstanding |
| INV-02 | Only two-bit gameplay mask; E2 router read and InputEvent grep outside ui | NOT RUN | Gameplay router not implemented |
| INV-03 | No global/unseeded RNG in sim/run/tower; E1 | NOT RUN | scripts/review_static.py subset only; full implementation review outstanding |
| INV-04 | No solver transcendentals; E1 | NOT RUN | scripts/review_static.py subset only; full implementation review outstanding |
| INV-05 / A9.2 | Fixed 1/60 via accumulator, no raw frame delta; E2 | NOT RUN | Point/link clock primitive only; tests/sim/test_integration.gd; full Sim runtime review not executed |
| INV-06 | Tuning resource owns all core numbers; E1 plus spot-read | NOT RUN | scripts/review_static.py subset only; full implementation review outstanding |
| INV-07 | No screens beyond S00–S16 or monetised gameplay; E1/E2 | NOT RUN | Full M1 scope review outstanding |
| INV-08 | Nothing blocks first flag; E2/manual run | NOT RUN | First-flag loop not implemented |
| INV-09 | Offline game, platform stubs; E1/E4 airplane-mode run | NOT RUN | No M1 runtime/device evidence |
| INV-10 | Cosmetics cannot alter physics; E2 diff of both paths | NOT RUN | Full M1 code-path review outstanding |
| M0 regression | Preserve original 475 engine checks and all existing tests; separate M0 regression workflow | PASS (regression only) | CI40639067949: 476 engine +13 Python; original475 checks preserved; floor now476 (F16) |
| A8 test-count floor | At least 476 engine +13 original Python checks =489; no count reduction without a reviewed DECISIONS.md explanation | PASS (count floor only) | CI40639067949; scripts/check_m0_regression.py; F16 raises floors to476/489 |
| A8 replay baseline | M1+ replay matches a genuinely generated committed baseline; unexplained changes fail CI | NOT RUN | No M1 baseline exists |
| A5.6 / A10 five-fakes | Hunt all five: hollow test, ticked box, weakened gate, stub that passes, borrowed artifact; cite locations/evidence for each | NOT RUN | Full definitions vendored; procedure not yet executed |
| A12 verdict/review | Produce .review/m1_verdict.md and .json plus formal PR review before signoff | NOT RUN | No verdict or approval claimed |
| Engine / architecture | Real Godot4.7.2 import, M0 regression suite unchanged, core remains headless; static scans enforce RNG/math/node/input restrictions | NOT RUN for M1 | None; M0-only results are not M1 proof |
| A9.1 / A9.6 static restrictions | Recursive core/sim, core/run, core/tower scans for RNG/clock/frame sources, raw delta callbacks and solver transcendentals; scan scripts AND scene node types | STATIC CHECK ONLY | scripts/review_checks.sh; no runtime proof |
| A9.2 accumulator | Fixed 1/60, outer accumulator, no raw frame delta in solver, catch-up/drop as GDD §4.2 | NOT RUN | Point/link clock primitive only; tests/sim/test_integration.gd; full Sim runtime review not executed |
| A9.3 injected RNG | Preserve seed parameter in Sim.setup and explicitly inject seeded xoshiro128**; stub signature alone is insufficient | NOT RUN | Sim remains a stub |
| AC-201 | No-input trace shows settling AND sleep within ≤4 s; record sleep tick and velocities using tuning thresholds | NOT RUN | None |
| AC-202 | Maximum absolute limb-length error ≤0.05 WU over a two-minute run; assert and log measured maximum | NOT RUN | None |
| AC-204 | 200-run soak; zero NaN/∞, log all runs/seeds and failures; do not silently heal/discard non-finite events from the record | NOT RUN | None |
| Three presets / §16.1 | Three authored presets, identical recorded L/R pattern, three different motions; 10 s capture for EACH, plus shared input/seed and trace references | NOT RUN | No presets or captures implemented |
| Tick cost / §10.4 | Measured solver tick ≤3.0 ms at 30 bodies; record actual constraint count (GDD budget:120), hardware/build and timing method; measure/report per-tick+per-frame snapshot mode versus any frame-only candidate without weakening atomicity | NOT RUN | No timing measurement; CI timing alone is not reference-device evidence |
| A9.4 replay ×3 | Same initial state/seed/tuning and tick-indexed input log replayed three times; exact matching state hashes and result fields | NOT RUN | No M1 baseline/hash |
| A9.4 two-second stall | Inject a two-second frame stall into the accumulator; log catch-up/drop behavior and compare at equal simulated tick counts with identical tick-indexed inputs | NOT RUN | None |
| A9.5 two frame conditions | Vary frame DELIVERY with --fixed-fps 30/144 if supported, otherwise windowed vs headless, never solver tick_hz (fixed60); record exact commands and support probe; compare identical simulated tick counts/input stream, not equal wall duration after dropped steps | NOT RUN | Conditions/protocol must be recorded before execution |
| A9.7 mandatory falsification | Flip exactly one documented input bit at one documented tick; demonstrate a DIFFERENT hash from the unmodified baseline; fail if equal | NOT RUN | None |
| A9.7 baseline / CI regression | Generate baseline with real engine, commit fixture identity/hash/tuning fingerprint; CI must reject unexplained hash changes and require a linked DECISIONS.md explanation for an intentional change | NOT RUN | Baseline deliberately absent, not zero or invented |
| §10.6 repeatability | Fixed scenario 10000 ticks, 100 local repeats; recorded 60 s cross-architecture/device replay and 200-run soak tracked separately | NOT RUN | No device/architecture evidence; no M0 waiver carries forward |

## Implementation increments (not completed)

1. Define the minimal mathematical creature/body/constraint state and the three
   preset fixtures from the GDD, recording any permitted implementation decisions.
   Keep model constants centralized; do not invent feel values or thresholds.
2. Implement the fixed-step solver with stable part/constraint ordering, injected
   RNG, motor/limit rules, and exact snapshot/restore/hash coverage of future state.
3. Add the outer accumulator and deterministic tick-indexed input replay harness;
   include stall/frame-condition tests and mandatory one-bit falsification.
4. Run settle/stretch/soak/performance traces and 10 s captures for each preset.
5. Run the real pinned-engine harness in CI, commit its genuine baseline, expose
   failure logs/artifacts, and fill this matrix with measured results and links.
   Do not mark M1 complete or advance to M2 until the M1 packet gates are met.

## Unresolved owner inputs / evidence risks

- M0-B02: 0.75 vs0.72 camera zoom remains for M2; no camera work in M1.
- M0-B03: grip normal-force threshold, haptic impulse threshold and generator
  parameters remain unspecified. Do not create numeric defaults. Before any
  dependent grip behavior, obtain the owner's value; proceed only on independent
  solver work meanwhile. Haptics/generation are outside this packet.
- Full review pack is vendored unchanged; M1-B02 is resolved, not waived.
  Execute the original protocol before signoff; file presence is not review evidence.
- No preset geometry, captures, performance measurement or complete creature-runtime
  M1 test run exists yet. No baseline may be approved from `Sim.state_hash()`'s M0 stub.
- Reference-device performance and cross-device/architecture evidence still need
  actual hardware. M0-D07 cannot be used to waive those later gates.

**Current verdict: M1 INDEPENDENT FOUNDATIONS ONLY — NOT A COMPLETED MILESTONE.**

## Owner clarifications — current independent-work boundary

On 2026-10-28 the owner selected independent work only, not invented contact
values: per-part radii (including head), head mass/length and grip normal-force
threshold are missing. Collision, creature simulation and gait gates remain
blocked on those inputs. Mathematical body/constraint state can proceed without
choosing them. Full external pack vendoring is complete (M1-B02 resolved, not
waived); the full review protocol has not been executed.

## Independent increment 1 (M1-D02)

Scaffold commit2358c83 CI was green before this code increment. The new point-body
state and XPBD distance-link primitive have their own synthetic real-engine unit
job. They do not implement creature integration/contact, presets or a Sim replay.
All AC-201/202/204, A9 runtime, performance, gait and cross-architecture acceptance
rows remain NOT RUN. The public Sim functions still have their M0 stub bodies.
No arbitrary point-fixture values may be promoted to gameplay tuning defaults.

### Real-engine foundation evidence (not acceptance)

Commit3bbb8fa: pinned Godot4.7.2 CI40631790195 passed **81 point/link unit checks**.
M0 regression/Android CI40631790078 passed with the unchanged 488 baseline floor.
See docs/validation/M1.md for links, tested behavior and exclusions. Sim remains
unimplemented; no baseline, gait, contact, full replay or soak evidence exists.
Complete creature determinism attempts:0; the two-failed-attempt limit is unused.

## R4 claim-freeze guard (not runtime evidence)

`scripts/review_checks.sh` enforces this table: no runtime acceptance row may
claim Met/PASS/PASSED/VERIFIED; no success token may have empty/None evidence;
at least 12 rows must contain NOT RUN. The two regression/count-floor rows
require explicit scoped status and a CI run or commit reference. Negative
fixtures exercise those rules; the actual AC-201 mutation/revert transcript is
in the canonical PR #3 body. This guard does not execute or approve runtime gates.

### R5 F15 — fail-closed status allowlist

Every pipe-table row in this file is checked, including later/headerless tables.
Only `NOT RUN`, `NOT RUN for M1`, `STATIC CHECK ONLY`, and the two exact scoped
regression/count-floor statuses above are allowed. Scoped statuses require their
exact gate and a run/commit citation. Unknown/empty statuses fail closed; the
NOT RUN status-row floor remains12. The original seven guard tests are retained;
a parameterised eighth covers all six reported synonyms, empty status and later
tables. Fresh COMPLETE/MEASURED working-file negative controls are in PR #3.

## Independent increment 2 — point/link integration and clock (M1-D03)

`core/sim/solver.gd` integrates explicit mathematical points/links at the tuned
fixed 1/60; `core/sim/accumulator.gd` takes frame_seconds outside the fixed-step
math. `tests/sim/test_integration.gd` covers the capped clock, exact dropped time,
chunk equivalence at equal ticks, tuned gravity, repeated index ordering,
non-finite/overflow rejection, atomic tick/frame/restore and exact checkpoint
continuation. These are synthetic primitive fixtures, not A9 runtime acceptance.
The public Sim stays a stub. All runtime rows above remain NOT RUN; no contacts,
radii, head/grip values, presets, baseline, bit-flip, tick timing or captures.

Integration source f6b3756: pinned Godot4.7.2 CI40639068153 records374 primitive
checks (82+292), zero failures. M0/Android CI40639067949 records476 engine checks
and13 original Python; the unchanged per-script compile check adds one for the
accumulator file. Original475/488 floors are unchanged. These are unit/regression
results only; all runtime acceptance rows remain NOT RUN.
