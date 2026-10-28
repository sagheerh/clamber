# M1 acceptance matrix — scaffold, NOT approval evidence

**Status: READY FOR IMPLEMENTATION; all M1 runtime gates NOT RUN.**

M0 was landed separately in PR [#1](https://github.com/sagheerh/clamber/pull/1),
merge commit `c641990be2d77c57c223bc7cbc54d0097c3d8816`. Its closeout is approved
by owner override (M0-D07). **No M0 evidence/performance waiver applies to M1.**
This matrix is the separate M1 PR scaffold, not a solver implementation or a claim
that the M0 headless suite validates M1. No baseline hash is fabricated here.

## Normative inputs and boundaries

- Owner M1 packet dated 2026-10-28 and its supplied PART B / A9 requirements.
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

Reconciled with the supplied R3 PART B/A9 checklist in
`docs/CLAMBER_REVIEW_AGENT.md` (explicitly partial; full pack absent).

| Gate / source | Required acceptance evidence | Status | Evidence reference |
|---|---|---|---|
| Full INV-01..INV-10 sweep | Static subset via scripts/review_checks.sh plus full manual/semantic sweep using the original pack; do not invent INV IDs | PARTIAL / full mapping BLOCKED | Original pack not supplied |
| M0 regression | Preserve original 475 engine checks and all existing tests; separate M0 regression workflow | NOT RUN on this branch | Historical M0 results are not M1 gates |
| A8 test-count floor | At least 475 engine +13 original Python checks =488; no count reduction without a reviewed DECISIONS.md explanation | ENFORCED by log checker; real CI pending | scripts/check_m0_regression.py |
| A8 replay baseline | M1+ replay matches a genuinely generated committed baseline; unexplained changes fail CI | NOT RUN | No M1 baseline exists |
| A5.6 five-fakes | Run original pack five-fakes procedure; preserve evidence | BLOCKED / NOT RUN | Full definitions not supplied |
| A12 verdict/review | Produce .review/m1_verdict.md and .json plus formal PR review before signoff | NOT RUN | No verdict or approval claimed |
| Engine / architecture | Real Godot4.7.2 import, M0 regression suite unchanged, core remains headless; static scans enforce RNG/math/node/input restrictions | NOT RUN for M1 | None; M0-only results are not M1 proof |
| A9.1 / A9.6 static restrictions | Recursive core/sim, core/run, core/tower scans for RNG/clock/frame sources, raw delta callbacks and solver transcendentals; scan scripts AND scene node types | STATIC CHECK ONLY | scripts/review_checks.sh; no runtime proof |
| A9.2 accumulator | Fixed 1/60, outer accumulator, no raw frame delta in solver, catch-up/drop as GDD §4.2 | NOT RUN | No accumulator implemented |
| A9.3 injected RNG | Preserve seed parameter in Sim.setup and explicitly inject seeded xoshiro128**; stub signature alone is insufficient | NOT RUN | Sim remains a stub |
| AC-201 | No-input trace shows settling AND sleep within ≤4 s; record sleep tick and velocities using tuning thresholds | NOT RUN | None |
| AC-202 | Maximum absolute limb-length error ≤0.05 WU over a two-minute run; assert and log measured maximum | NOT RUN | None |
| AC-204 | 200-run soak; zero NaN/∞, log all runs/seeds and failures; do not silently heal/discard non-finite events to pass | NOT RUN | None |
| Three presets / §16.1 | Three authored presets, identical recorded L/R pattern, three different motions; 10 s capture for EACH, plus shared input/seed and trace references | NOT RUN | No presets or captures implemented |
| Tick cost / §10.4 | Measured solver tick ≤3.0 ms at 30 bodies; record actual constraint count (GDD budget:120), hardware/build and timing method | NOT RUN | No timing measurement; CI timing alone is not reference-device evidence |
| A9.4 replay ×3 | Same initial state/seed/tuning and tick-indexed input log replayed three times; exact matching state hashes and result fields | NOT RUN | No M1 baseline/hash |
| A9.4 two-second stall | Inject a two-second frame stall into the accumulator; log catch-up/drop behavior and compare at equal simulated tick counts with identical tick-indexed inputs | NOT RUN | None |
| A9.5 two frame conditions | Use --fixed-fps 30 and --fixed-fps 144 if supported, otherwise windowed vs headless; record exact commands and support probe; compare identical simulated tick counts/input stream, not equal wall duration after dropped steps | NOT RUN | Conditions/protocol must be recorded before execution |
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
- The standalone review-pack PART B / full A9 document is not present in the
  checkout. The supplied owner-message requirements are captured above; reconcile
  any additional external protocol detail before signing off A9, not by guessing.
- No preset geometry, captures, performance measurement or real-engine M1 test
  run exists yet. No baseline may be approved from `Sim.state_hash()`'s M0 stub.
- Reference-device performance and cross-device/architecture evidence still need
  actual hardware. M0-D07 cannot be used to waive those later gates.

**Current verdict: M1 SCAFFOLD ONLY — NOT REVIEWABLE AS A COMPLETED MILESTONE.**

## Owner clarifications — current independent-work boundary

On 2026-10-28 the owner selected independent work only, not invented contact
values: per-part radii (including head), head mass/length and grip normal-force
threshold are missing. Collision, creature simulation and gait gates remain
blocked on those inputs. Mathematical body/constraint state can proceed without
choosing them. Full external pack vendoring remains explicitly incomplete.

## Independent increment 1 (M1-D02)

Scaffold commit2358c83 CI was green before this code increment. The new point-body
state and XPBD distance-link primitive have their own synthetic real-engine unit
job. They do not implement creature integration/contact, presets or a Sim replay.
All AC-201/202/204, A9 runtime, performance, gait and cross-architecture acceptance
rows remain NOT RUN. The public Sim functions still have their M0 stub bodies.
No arbitrary point-fixture values may be promoted to gameplay tuning defaults.
