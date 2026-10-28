# M1 acceptance matrix — scaffold, NOT approval evidence

**Status: READY FOR IMPLEMENTATION; all M1 runtime gates NOT RUN.**

M0 was landed separately in PR [#1](https://github.com/sagheerh/clamber/pull/1),
merge commit `c641990be2d77c57c223bc7cbc54d0097c3d8816`. Its closeout is approved
by owner override (M0-D07). **No M0 evidence/performance waiver applies to M1.**
The full external review pack is now vendored at `docs/CLAMBER_REVIEW_AGENT.md`.
`scripts/review_checks.sh` and the M1 scaffold CI job enforce the static guards
below; they are **not** M1 runtime evidence. No baseline hash is fabricated here.

## Normative inputs and boundaries

- Owner M1 packet dated 2026-10-28 and the complete `docs/CLAMBER_REVIEW_AGENT.md`
  (PART B M1 checklist, A9 determinism deep-check, invariant sweep, A5/A8/A10/A12).
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
  values; no tolerance/constant changes to manufacture a gate result.

## Required gates and evidence

| Gate / source | Required acceptance evidence | Status | Evidence reference |
|---|---|---|---|
| Engine / architecture | Real Godot 4.7.2 import, M0 regression suite unchanged, core remains headless; static scans enforce RNG/math/node/input restrictions | NOT RUN | None; M0-only results are not M1 proof |
| AC-201 | No-input trace shows settling AND sleep within ≤4 s; record sleep tick and velocities using tuning thresholds | NOT RUN | None |
| AC-202 | Maximum absolute limb-length error ≤0.05 WU over a two-minute run; assert and log measured maximum | NOT RUN | None |
| AC-204 | 200-run soak; zero NaN/∞, log all runs/seeds and failures; do not silently heal/discard non-finite events to obtain a green result | NOT RUN | None |
| Three presets / §16.1 | Three authored presets, identical recorded L/R pattern, three different motions; 10 s capture for EACH, plus shared input/seed and trace references | NOT RUN | No presets or captures implemented |
| Tick cost / §10.4 | Measured solver tick ≤3.0 ms at 30 bodies; record actual constraint count (GDD budget:120), hardware/build and timing method | NOT RUN | No timing measurement; CI timing alone is not reference-device evidence |
| A9.1 static scan | `core/sim`, `core/run`, `core/tower` contain no `randf`, `randi`, `randomize`, `Time.get_ticks_*`, `Engine.get_physics_frames` used as input, `_process(delta)` stepping, or unseeded global RNG | NOT RUN | Static guard exists in `scripts/review_checks.sh`; real M1 code not yet scanned against implementation |
| A9 replay ×3 | Same initial state/seed/tuning and tick-indexed input log replayed three times; exact matching state hashes and result fields | NOT RUN | No M1 baseline/hash |
| A9 two-second stall | Inject a two-second frame stall into the accumulator; log catch-up/drop behavior and compare at equal simulated tick counts with identical tick-indexed inputs | NOT RUN | None |
| A9.5 two frame conditions | Run `--fixed-fps 30` and `--fixed-fps 144` if supported, otherwise windowed vs headless; record exact protocol and compare identical simulated tick counts/input stream, not equal wall duration after dropped steps | NOT RUN | Conditions/protocol must be recorded before execution |
| A9 mandatory falsification | Flip exactly one documented input bit at one documented tick; demonstrate a DIFFERENT hash from the unmodified baseline; fail if equal | NOT RUN | None |
| Baseline / CI regression | Generate baseline with real engine, commit fixture identity/hash/tuning fingerprint; CI must reject unexplained hash changes and require a linked DECISIONS.md explanation for an intentional change | NOT RUN | Baseline deliberately absent, not zero or invented |
| §10.6 repeatability | Fixed scenario 10000 ticks, 100 local repeats; recorded 60 s cross-architecture/device replay and 200-run soak tracked separately | NOT RUN | No device/architecture evidence; no M0 waiver carries forward |
| Invariant sweep INV-01..INV-10 | Every milestone re-check: no Godot physics nodes; one 2-bit input path; no global RNG; no transcendentals in solver; fixed 1/60 accumulator; tuning-only constants; no extra screens/monetised gameplay; first flag unblocked; offline no-ops; cosmetics cannot alter physics | NOT RUN | `scripts/review_checks.sh` covers static subset; full runtime sweep needs M1 build |
| M0 regression suite | Re-run M0 real-engine suite (475 checks, 0 failures) plus 6 static + 7 inspector tests as regression | NOT RUN | M0 CI evidence exists; M1 CI must re-run it |
| Test-count non-regression | Total checks must not drop below M0 baseline **488** without a written DECISIONS.md justification | NOT RUN | Baseline recorded here; M1 harness not implemented |
| A5 / A10 / A12 review gate | Run `scripts/review_checks.sh`, full test suite, prior-milestone regression, read diff, check this matrix, hunt five fakes; produce `.review/m1_verdict.md` / `.json` and a formal PR review before signoff | NOT RUN | No M1 review verdict artifacts yet |

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

- M0-B02: 0.75 vs 0.72 camera zoom remains for M2; no camera work in M1.
- M0-B03: grip normal-force threshold, haptic impulse threshold and generator
  parameters remain unspecified. Do not create numeric defaults. Before any
  dependent grip behavior, obtain the owner's value; proceed only on independent
  solver work meanwhile. Haptics/generation are outside this packet.
- `docs/CLAMBER_REVIEW_AGENT.md` is now the vendored full external review pack.
  The scaffold-fix reconciliation above covers its PART B M1, A9.1–A9.7,
  INV-01..INV-10, A5, A8, A10 and A12 requirements. Any future change to that
  pack requires updating this matrix and `scripts/review_checks.sh`.
- No preset geometry, captures, performance measurement or real-engine M1 test
  run exists yet. No baseline may be approved from `Sim.state_hash()`'s M0 stub.
- Reference-device performance and cross-device/architecture evidence still need
  actual hardware. M0-D07 cannot be used to waive those later gates.

**Current verdict: M1 SCAFFOLD ONLY — NOT REVIEWABLE AS A COMPLETED MILESTONE.**
