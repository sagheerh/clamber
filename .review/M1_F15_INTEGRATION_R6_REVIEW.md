# M1 F15 + integration increment — R6 verification of PR #3 @ `cb4a0d9`

**Reviewed:** 2026-10-28  
**PR #3 head:** `cb4a0d95d5b1378d6cf675be9b7c7bdc8417918d` (draft) — commits `201644e` (F15), `f6b3756` (integration), `cb4a0d9` (evidence + floors)  
**CI at that head:** M1 [`40639408102`](https://github.com/sagheerh/clamber/actions/runs/40639408102), M0/Android [`40639408109`](https://github.com/sagheerh/clamber/actions/runs/40639408109) — **green**

---

## 1. Verdict

| Item | Verdict | Independent evidence |
|---|---|---|
| **F15** allowlist guard | **MET** | I mutated the tracked matrix myself: `COMPLETE`, `MEASURED (4 s)`, `DONE`, `GREEN`, empty status and bare `PASS` on a runtime row all return **exit 1**; `NOT RUN | None` returns **exit 0**; untouched matrix returns **exit 0**. Header rows and *all* pipe tables are now scanned, and the `NOT RUN ≥ 12` floor reads the status cell only. |
| **Integration increment** | **ACCEPTED as independent primitives** | Real code + 292 real assertions; CI annotation `M1 primitive total: 374 checks, 0 failures (82 point/link + 292 integration/clock)`. |
| **Scope discipline** | **MET** | `git diff 0ec87d0 cb4a0d9 -- scripts/review_static.py tests/test_static.py tests/test_android_inspection.py tests/test_runner.gd core/tuning.gd core/tuning.tres` → **empty**. No scanner relaxation, no tuning change, no M0 test edit. |
| **No contacts / presets / baseline** | **MET** | `grep -rn 'contact\|collision\|radius' core/sim/*.gd` → only doc comments. No preset files, no baseline hash, no captures. |
| **Runtime claims** | **NONE** | Every runtime row in the matrix is `NOT RUN` / `NOT RUN for M1` / `STATIC CHECK ONLY`; only the two scoped regression rows cite a run. |
| **Full M1** | **STILL INCOMPLETE** | Correctly stated by the agent. |

**Primitive floors are now pinned**: `tests/run_m1_math.sh` requires `M1 math foundations ≥ 82`, `M1 integration primitives ≥ 292`, exactly one match each, plus zero script errors. Their parser negative fixture (291 rejected, 292 accepted) is the right way to prove the pin can fail.

---

## 2. What the 292 checks actually assert (I read them)

- **Catch-up cap** (`_catch_up_cap`): after a fractional frame plus `(cap+2)·dt + dt/4`, exactly `cap` ticks run, `pending == 0`, and `dropped == accumulated − cap·dt` — derived from tuning, not a magic number. A follow-up `advance(0)` proves the dropped backlog never runs later.
- **Chunk equivalence** (`_frame_chunks`): six 2-tick frames vs twenty-four half-tick frames → identical tick count, **identical solver snapshot**, identical pending, zero dropped.
- **Analytic gravity** (`_gravity`): damping forced to 0 in a duplicated resource, expected `y` uses `g·dt²·n(n+1)/2` to `1e-12`, horizontal drift exact, tick count exact; also proves a caller mutating the tuning resource after setup cannot retune a running solver (it holds a duplicate).
- **Damping / clamp / pinning** (`_damping_clamp_and_pinning`): per-tick retention `(1 − damping)` exact; `1e4` input velocity clamped to `physics_max_linear_velocity_wu_s`; pinned (`inverse_mass == 0`) points ignore gravity and drift.
- **Deterministic ordering** (`_ordering`): four fresh builds of the same chain, with the caller's `bodies` reversed and `links` cleared *after* setup, still produce identical snapshots, part 0 stays the anchor, and link count is unchanged — i.e. setup really copied the arrays and preserved index order.
- **Atomicity** (`_frame_rollback`): a synthetic exact-coincidence fixture makes tick 1 succeed and tick 2 fail; the solver snapshot after the failure equals the tick-1 snapshot, and `clock.advance(2·dt)` rolls the **whole frame** back to the pre-frame snapshot. That is the hard case, and it is genuinely tested.
- **Snapshot → restore → step** (`_restore_and_step`): checkpoint with dropped-time history *and* a fractional remainder, restore, re-advance → byte-identical complete snapshot; same at the solver level.
- **Invalid input/state** (`_invalid_state_and_input`): non-finite frames, overflow, invalid restores rejected without partial mutation.

The implementation itself is sound: `accumulator.advance(frame_seconds)` has no engine callback and no clock read; the solver's `step()` takes no elapsed time; tuning is duplicated at setup and validated (`tick_hz`, gravity finite, damping in `[0,1]`, speed limit finite and squared-finite); `_settings()` and `_topology` are part of snapshot identity, so a mismatched restore is rejected rather than silently applied.

`M0: 476 checks` is legitimate: the M0 recursive compile test acquires one extra script, and no M0 test file changed. Historical `docs/validation/M0.md` still correctly records 475 for the M0 era.

---

## 3. New findings (all small; none block this increment)

### F16 — [MINOR] M0 engine floor was not raised with the count
- **Citation:** `scripts/check_m0_regression.py` → `ENGINE_BASELINE = 475`, `COMBINED_BASELINE = 488`, while the real count is now **476 / 489**.
- **Risk:** deleting `core/sim/accumulator.gd` (or shrinking the recursive compile set) restores 475 and still passes — a silent regression window.
- **Done when:** pin `476` and `489` (or keep 475/488 with a written reason), and make the failure message quote the pinned numbers.

### F17 — [MINOR] Frame rollback ignores its own failure
- **Citation:** `core/sim/accumulator.gd`, `advance()`: `_solver.restore(before)` is called and its `Error` is discarded before `return status`.
- **Risk:** if the rollback itself fails, the caller gets the *tick* error while the solver stays mutated — the exact silent-heal the pack forbids.
- **Done when:** check the restore result and return `ERR_INVALID_DATA` (or a distinct error) when rollback fails, with a test that forces it.

### F18 — [MINOR] Per-tick deep snapshots will distort the ≤3.0 ms tick-cost gate
- **Citation:** `PointLinkSolver.step()` takes a full `snapshot()` of every body and link before each tick, and `FixedStepAccumulator.advance()` takes another before the loop.
- **Why now:** atomicity is correctly tested, but when the §10.4 tick-cost gate is measured at 30 bodies / 120 constraints, three deep copies per frame will dominate the number and the agent will be tempted to either loosen the gate or "optimise" the atomicity tests.
- **Done when:** before the tick-cost gate is claimed, record whether the snapshot is needed per tick or only per frame, measure both, and state which configuration the measured number refers to. Do not change the atomicity guarantees to make the number look better.

### F19 — [NIT] Two primitives disagree on who may change the tick rate
- `PointLinkSolver._valid_tuning()` requires the shipped `physics_tick_hz` (60), while `DistanceConstraint.project(tuning)` accepts any rate (the 120 Hz test relies on this).
- **Consequence for the plan:** A9.5's "two frame conditions" must vary **frame delivery** (`--fixed-fps 30/144`, windowed vs headless), not `tick_hz`. Write that in the matrix row now so a future run does not try to inject a different tick rate and get `ERR_INVALID_PARAMETER`.

---

## 4. Where M1 now stands

Done: review infra, pack provenance, claim guard, point/link primitives, capped fixed-step clock, atomicity, ordering, snapshots.

Still `NOT RUN` and blocked on **M1-B01**: creature bodies with radii, head mass/length, feet, contacts, contact friction, then AC-201 (settle/sleep), AC-202 (stretch), three presets, A9 replay/stall/frame conditions/bit-flip baseline, soak, tick cost, captures, §10.6 cross-machine.

**M1-B01 is now the only thing standing between the project and its real gate.** Integration and accumulator work has no further honest scope without contact geometry.

---

## 5. Paste-ready message to the coding agent

```text
R6 verification of PR #3 @ cb4a0d9: F15 is MET and the integration increment is
ACCEPTED as independent primitives. M1 remains INCOMPLETE.

Verified myself, do not redo:
- F15: I mutated the tracked matrix. COMPLETE, MEASURED (4 s), DONE, GREEN, an
  empty status and a bare PASS on a runtime row all return exit 1; NOT RUN|None and
  the untouched matrix return exit 0. All pipe tables are covered and the NOT RUN
  floor reads the status cell only.
- Integration: CI annotation "M1 primitive total: 374 checks, 0 failures
  (82 point/link + 292 integration/clock)". I read test_integration.gd: the cap
  test derives dropped time from tuning, chunk equivalence compares full solver
  snapshots, gravity is analytic to 1e-12, ordering survives the caller reversing
  bodies and clearing links post-setup, and the rollback test genuinely has tick 1
  succeed and tick 2 fail before the whole frame is reverted. The 82/292 floors and
  the 291-rejected parser fixture are the right way to pin them.
- Scope: diff over review_static.py, the M0 tests, test_runner.gd, tuning.gd and
  tuning.tres is empty. No contacts, radii, presets, baseline or captures exist.
  Every runtime row is still NOT RUN.
- M0 at 476 is legitimate: the recursive compile test picked up one new script and
  no M0 test file changed.

Four small items before the next increment:

F16 [MINOR] Raise the M0 floors to match reality: ENGINE_BASELINE 476 and
COMBINED_BASELINE 489 in scripts/check_m0_regression.py, or keep 475/488 with a
written reason. Right now deleting core/sim/accumulator.gd silently returns to 475
and passes.

F17 [MINOR] In accumulator.advance() you discard the Error from
_solver.restore(before) on rollback. If the rollback itself fails, the caller sees
the tick error while the solver stays mutated - that is silent healing. Return a
failure when the rollback fails, and add a test that forces it.

F18 [MINOR] solver.step() takes a full snapshot every tick and advance() takes
another per frame. That is correct for atomicity but it will dominate the §10.4
<=3.0 ms tick-cost measurement at 30 bodies / 120 constraints. Before you claim
that gate, record whether the snapshot is needed per tick or only per frame,
measure both, and say which configuration the number refers to. Do not weaken the
atomicity tests to improve the number.

F19 [NIT] PointLinkSolver requires the shipped 60 Hz tick rate while
DistanceConstraint accepts any rate. Write in the A9.5 matrix row that the two
frame conditions vary frame DELIVERY (--fixed-fps 30/144, windowed vs headless),
not tick_hz, so a future run does not try to inject a different rate and get
rejected.

Then STOP feature work and wait for me. M1-B01 (per-part radii, head mass/length,
foot grip normal-force threshold, with units) is the only remaining input that
unblocks anything real. Do not invent those values, do not start contacts on
guessed geometry, do not start M2 or camera work. While waiting you may only land
F16-F19 and keep CI green.
```

---

*End of R6 review. F15 closed; integration primitives accepted; M1 blocked on owner-supplied contact geometry (M1-B01), with F16–F19 as small cleanups.*
