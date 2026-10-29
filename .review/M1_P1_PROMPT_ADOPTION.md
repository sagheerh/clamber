# PROMPT 1 of 3 — ADOPT AC-202, THEN RE-MEASURE THE IDLE FAMILY (M1)

> Paste this whole block to the coding agent as one session. It is self-contained: repo facts,
> the single authorised change, seven deliverables, stop conditions and the report format.
> P2 and P3 come in later sessions — do not start them here.

---

## 0. Your role and the session contract

You are the implementation agent on `sagheerh/clamber`, working branch `arena/4cd0a587-clamber`
(PR #3, currently **draft**). This session performs **one physics change** — the AC-202 adoption the
owner has approved — and then re-measures everything that change touches.

**Session contract (binding):**
1. **Finish this session's seven deliverables in this session.** Do not carry work into P2/P3, and do not
   start P2/P3 work.
2. **When something cannot be measured, record `NOT RUN` + the exact blocker and continue.** Never
   extrapolate a reference value, never substitute a different window, never fill a gap with a claim.
3. **Exactly one physics change is authorised: D1.** No retuning, no sweeps, no "quick try" to see if the
   creep improves, no tolerance/slop/epsilon edits, no iteration-count edits.
4. **One CI invocation per arm**, pinned to the head you are measuring (see §6). Doc-only commits `[skip ci]`.
5. **Report the numbers, not the story.** A worse number is a valid result. A better number is a valid
   result. Neither may be produced by tuning.

---

## 1. Repo facts you must verify first, then trust for the rest of the session

| fact | value |
|---|---|
| branch head at session start | **`fb890fd`** ("record tested publication and protected PR evidence") |
| P-B tuning (must stay byte-identical) | bound **30.0**, stiffness **10.0**, damping **0.5443327361211717**, max_torque **12.0** |
| tuning file | `core/tuning.tres` — **must diff empty against `fb890fd` at the end of this session** |
| engine | Godot `4.7.2-stable` only, pinned by checksum in CI |
| production tick path | `Sim` → `CreatureTickSolver` (`core/sim/creature_solver.gd`) → `SleepingLoadProbe` (`core/sim/sleeping_load_probe.gd`) → `ActuatedLoadProbe._step` → **`CoupledLoadProbe._step`** (`core/sim/coupled_load_probe.gd`) |
| diagnostic sibling | `CoupledLoadProbe` is also the diagnostic probe used by the R27 harness — the same `_step` body, so an unconditional edit here reaches production **and** the harness |
| baseline fixture | `tests/fixtures/public_sim_baseline.json` |
| pytest-equivalent controls | `scripts/review_checks.sh` → **≥ 218** Python controls |
| M0 suite | 516 checks / 0 failures, unchanged |

Verify the head sha and the four tuning values before you change anything; state them in the report.

---

## 2. Already measured — do not re-derive, do not re-run

These are the reviewer-accepted R27 numbers. Cite them; do not spend CI re-establishing them.

| row | accepted value |
|---|---|
| AC-201a (600 ticks, idle) | **FAIL 35.34386°** peak-to-peak vs 15°; **no airborne tick** |
| AC-201b (600 ticks, from spawn) | **PASS 96.90365 px = 0.6460244 WU = 0.71780 BL**; limit 135 px / 0.90 WU / 1.0 BL; margin **1.393×**; flip at 13.5 px/s |
| AC-201s | **FAILED** — 0 sleeping ticks in 600, F52 never fired |
| AC-202 candidate (7200 ticks ×3) | completed-tick limb max **Slug 4.996e-16 / Hopper 1.832e-15 / TwinRoller 1.776e-15 WU** |
| AC-202 mechanism | contact position pass injects it: `after_contact_pass_0` 0.10553 / 0.15363 / 0.06175 WU → post-contact reprojection **roundoff** |
| AC-204 soak | PASS 200/200 runs, 1 440 000 ticks, zero failed runs, zero non-finite; **not determinism** |
| FA-3 | **vacuous, uncredited** (0 wake events with 0 sleeping ticks) |
| determinism | same-build attempt 1 only; **cross-architecture attempts 0** |

**Do not re-run the R27 pinned jobs** (`[R27-once]`, pinned to `2cf2c93`). They are history.

---

## 3. D1 — the adoption (the only physics change in M1)

**What to change.** In `core/sim/coupled_load_probe.gd`, at the end of `_step()`, the block currently
guarded by `diagnostic_final_distance_pass` (the R27 candidate: *same final traversal, moved after all
contacts — identical rows, compliance, multipliers and `project()` implementation, no velocity edit*)
must run **unconditionally**, after `_finish_velocities()` and after every contact/velocity pass, on
every production tick.

**What must not change.** The traversal itself — same link list, same order, same `project()` calls, same
compliance, same multipliers. **No velocity edit.** Nothing else in `_step()` moves. The contact pass,
the iteration count, the angular joint order and `_finish_velocities()` stay exactly where they are.
`core/tuning.tres` is **not touched**.

**Implementation constraints.**
- The projection is **not** conditional on any runtime flag: remove the branch. If you want an A/B arm
  for evidence, put the switch in the **test harness only** (an argument the harness passes at setup,
  defaulting to *adopted*), and record in the evidence which arm produced which row.
- Phase recording (`_record_length_phase`, contact batches, per-phase limb ledger) is **instrumentation,
  not physics**: keep it behind the existing diagnostic switch so the production tick does not pay for it,
  and enable it explicitly for the measurement arms.
- **Verify** that the other production `CapsuleContact.resolve_tick` call site
  (`sleeping_load_probe.gd`, the parked/asleep path) cannot leave a length error behind — it operates on
  detached clones and must not mutate live positions. State the verification in the report; do not change
  it unless it is actually live-mutating, and if it is, stop and report.

**Commit** (single commit, message must name the change):
```
M1: adopt AC-202 post-contact distance reprojection (physics change)
```
Plus a `DECISIONS.md` entry: what changed, why, R27 evidence reference, before/after numbers, and the
explicit note that no tuning value was modified.

---

## 4. D2 — baseline with provenance + replay on the adoption commit

Regenerate `tests/fixtures/public_sim_baseline.json` **on the adoption commit** (generate, never
hand-edit) recording at minimum:

```
engine_version, tuning_sha256, source_commit_sha, seed, tick_hz: 60,
ticks, input_log_digest, final_state_hash, collected_utc, method
```

Then run the **`public-sim-runtime`** job on that commit and show it reproducing the committed baseline
exactly (9053-check shape as before is fine; the digests must be the new ones and must match the fixture).
**No baseline may be approved from a stale or invented hash.**

---

## 5. D3–D7 — measurements

### D3 — penetration check (adoption condition #2; hard stop)
Reprojection moves bodies; a moved body can push a foot into the floor. For each of the three presets,
over **7200 ticks**, record **max penetration depth after the appended pass** (body surface below terrain
surface at the contact normal) and compare to `physics_contact_slop_wu` = **0.02**.

Report per preset: `{max_penetration_wu, limit: 0.02, verdict}`.
**If any preset exceeds 0.02 → revert the adoption commit, stop, report, wait for the owner. Do not touch
the slop, do not clamp, do not "bound" the projection.**

### D4 — AC-202 as a production row
Same three 7200-tick runs, limb-length max ≤ **0.05 WU**, per preset. These are now the **production**
numbers — report them with **no `candidate_enabled` column**, because there is no candidate any more.

### D5 — idle-family re-measure on the adopted build (required by the change, not by hope)
Identical metrics, identical thresholds, **measured from spawn**, zero input, 600 ticks:

| row | metric | threshold | what to report |
|---|---|---|---|
| AC-201a | peak-to-peak attitude change | ≤ 15° | degrees, plus `min/max` signed angles, plus airborne-tick count |
| AC-201b | net COM displacement | ≤ 0.90 WU = 135 px | WU, px, BL, effective px/s, margin ratio |
| AC-201s | first F52 sleep tick | must fire < 600 | tick or `none`; count sleeping ticks |
| drift arm | mean COM speed, last 300 ticks | none (report) | px/s, beside the R26 reference **8.55 px/s** |

**Any direction of change is acceptable — record the delta against the table in §2 and stop there.**
Do not retune toward improvement; do not re-run for a different number; do not describe a decrease as a
"fix" (the rectifier is M1.1's job).

### D6 — AC-201a characterisation (one extra arm, existing harness)
Add **one** 3600-tick (60 s) zero-input arm and report:
- attitude rate in **°/s**;
- **time to 90°** (s) and time to 180° if reached;
- **monotone vs bounded**: count of sign changes of the per-tick attitude delta, and `max |angle|` over the
  last 600 ticks.
Purpose: tell M1.1 whether this is a topple or a settle-into-tilt. **This is characterisation, not a new
gate: do not change 15°, the 10 s window, or the AC-201a verdict.**

### D7 — regression
- `scripts/review_checks.sh`: **≥ 218 controls, 0 failures** (`>=` — the count only grows).
- M0 headless: **516 / 0**, unchanged.
- `core/tuning.tres` diff vs `fb890fd`: **empty**.
- `git diff fb890fd..HEAD --stat` must show **no** changes to `core/tuning.tres`, no preset data, no save
  format, no M0 test expectations. State the diff summary in the report.

---

## 6. CI hygiene (this repo's pinned one-shot pattern)

- Historical jobs are guarded `github.sha == '<sha>' && contains(head_commit_message, '[Rn-once]')`.
  **Do not un-pin, do not re-run them.**
- For this session add **new** jobs pinned to the adoption head with a new marker, e.g.
  `[R28-once]`, one invocation per arm (`adoption-measure`, `ac202-production`, `idle-family`,
  `ac201a-characterisation`, and the existing soak only if it is genuinely needed — it is not, the
  200-run soak is already accepted on this physics family and **must not be presented as determinism**).
- Upload raw logs and JSON as artifacts; annotate the console log the way the existing R27 job does.
- Doc-only commits: `[skip ci]`.

### D8 — the standing red X on the PR (assigned here because it blocks "CI green")
Every real-code push makes the **M1** workflow red, and it has been red on `2cf2c93` and `93c17d6` for the
same reason: job `math-foundations` → **step 9, "Hinged Slug600 load diagnostic (NOT FA acceptance)"**.
Every later historical job is then skipped. That step is a **historical F47 diagnostic, not an M1
acceptance gate** — but a red X on the PR is currently indistinguishable from a real gate failure.

Fix it **without weakening anything**:
1. Keep the diagnostic running and keep its raw output artifact and its `::error` annotation.
2. Mark **only that step** `continue-on-error: true`, so the job's conclusion reflects the acceptance
   steps. Do **not** touch any `review_checks.sh` assertion, any acceptance step, or any threshold.
3. Add a `DECISIONS.md` line: the F47 Slug600 load diagnostic is **expected-red until M1.1's contact
   rectifier lands**; it was never an acceptance gate; its failure is retained and visible.
4. Report the change in the session report with the before/after job conclusions, so nobody can read the
   new green as "the diagnostic passes".

If you believe quarantining it would misrepresent the record, **do not do it — say so and leave it red**;
the verdict then carries "CI: one known-red diagnostic, not a gate" and P3's done-criteria changes. Decide,
state the decision, and move on. Do not spend more than one commit on this.

---

## 7. Definition of done (self-check before you report)

- [ ] `core/tuning.tres` byte-identical to `fb890fd`; head diff contains only the adoption + harness +
      docs + evidence.
- [ ] The projection is unconditional in the production tick; no runtime flag decides physics.
- [ ] `DECISIONS.md` entry present and specific.
- [ ] Baseline regenerated with full provenance; `public-sim-runtime` green **on the adoption commit**.
- [ ] Penetration reported per preset and **< 0.02** (otherwise you reverted and stopped).
- [ ] AC-202 production limb maxima reported per preset (expect roundoff; ≤ 0.05).
- [ ] AC-201a / 201b / 201s / drift re-measured and reported with the §2 deltas.
- [ ] 3600-tick characterisation: °/s, time-to-90°, monotone-vs-bounded.
- [ ] ≥ 218 Python controls pass; M0 516/0 unchanged.
- [ ] `.review/m1_r28_adoption_evidence.json` + `.review/m1_r28_adoption_report.md` committed.
- [ ] D8 decided and recorded (quarantined with the diagnostic still visible, or left red with the reason).
- [ ] CI green on the acceptance steps of the adoption commit and of the evidence commit (D8's known-red
      diagnostic, if you left it red, named in the report as the only exception).

---

## 8. Stop conditions (stop and report — do not work around)

1. **Penetration ≥ 0.02** on any preset → revert the adoption, report, wait.
2. **Any non-finite state** (NaN/∞) in D4/D5 → report the first tick and the full trace; never heal and
   re-run silently.
3. **Any temptation to change a threshold, window, metric, tolerance, slop, iteration count or tuning
   value** → stop and ask the owner. That is not this session's authority.
4. **The traversal cannot be made unconditional without changing its order or its maths** → stop and
   report; the adoption is then not the measured candidate and cannot be adopted by reinterpretation.

---

## 9. Report format (use exactly this shape)

```markdown
# R28 adoption report — head <sha>

## Adopted change
file:line, what the traversal does, confirmation that it is unconditional, confirmation that
tuning.tres is byte-identical (sha256 <before> / <after>).

## Baseline & replay
fixture sha256, source_commit, tuning_sha256, run id, digest reproduced: yes/no.

## Penetration (limit 0.02)
| preset | max penetration WU | verdict |

## AC-202 production row (limit 0.05 WU)
| preset | completed-tick limb max WU | ticks | verdict |

## Idle family, adopted build (from spawn, 600 ticks, zero input)
| row | R27 value | adopted value | delta | threshold | verdict |
| AC-201a | 35.34386° | | | 15° |
| AC-201b | 0.6460244 WU / 96.90365 px | | | 135 px |
| AC-201s | none (0 sleeping ticks) | | | <600 |
| drift | 8.55015 px/s (last 300) | | | report |

## AC-201a characterisation (3600 ticks)
rate °/s | time to 90° | time to 180° or n/a | sign changes | max|angle| last 600
reading: toppling / bounded-tilt / undetermined — with the number that decides it.

## Regression
controls count | M0 checks | tuning diff | changed-file summary

## Not measured
explicit list + blocker per line.

## What this session did NOT do
no retune, no sweep, no brace, no threshold change, no soak-as-determinism claim, no M1.1 fix attempt.
```

---

## 10. Claims you may not make in this session

- Not "AC-201 passes" unless the measured number is under the threshold — and if it does pass, say
  **"passes on the adopted build; cause unchanged, M1.1 still open"**, not "fixed".
- Not "penetration is fine" without the number.
- Not "determinism" from any repetition of identical runs (physics does not consume the RNG — F78).
- Not "M1 complete". M1's verdict belongs to the reviewer in P3.
- Not "60 fps", not a device/perf claim, not a reference-device tick-cost claim (that is D07, owner phone).
