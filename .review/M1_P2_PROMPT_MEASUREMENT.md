# PROMPT 2 of 3 — ONE CONTROL ARM + THE FIVE REMAINING GATES (M1)

> Paste this whole block as one session. Self-contained. P3 comes after; do not start it here.
> **This session changes NO physics.** It measures, captures, times and reports.

---

## 0. Session contract

1. **Finish the six deliverables (D0–D5) plus D6/D7 in this session.** Do not start P3 (the verdict).
2. **Zero physics changes.** No retune, no slop/epsilon/tolerance/iteration edits, no adoption, no
   "quick try" on the rectifier. `core/tuning.tres` must be byte-identical at the end.
3. **When something cannot be measured, write `NOT RUN` + the exact blocker and continue.** Never
   extrapolate a reference, never substitute a window, never fill a gap with a claim.
4. **One CI invocation per arm**, push-triggered (see D6), pinned to the head being measured.
5. **Numbers, not narrative.** A gate that fails with a real number is a success for this session.

---

## 1. Verify first, then trust

| fact | value |
|---|---|
| session-start head | **`4796ec6`** |
| tuning sha256 | **`5f4d0d06564fb3a0847309d83cf5f3c87b9321ea5e2dd87e572e4bd9fe750666`** |
| production core | byte-identical to `fb890fd` (the AC-202 adoption is reverted) |
| controls | **226 / 0** via `scripts/review_checks.sh` |
| M0 suite | 516 / 0 |
| engine | Godot `4.7.2-stable`, checksum-pinned |

State all six in the report. If any differs, stop and report.

---

## 2. Already accepted — do not re-run, do not re-derive

- **AC-201a** FAIL 35.34386° / 15°; **AC-201b** PASS 96.90365 px / 0.6460244 WU / 0.71780 BL, margin 1.393×;
  **AC-201s** FAILED, 0 sleeping ticks.
- **AC-202** production FAILED — completed-tick limb maxima **0.10553 / 0.15363 / 0.06175 WU** (limit 0.05).
  The candidate that removes it fails penetration and is **reverted**. Do not re-attempt adoption.
- **R28 penetration, adopted build** (CI `40970023755`): Slug **0.07028201067739755**, Hopper
  **0.0933999293597247**, TwinRoller **0.05075245867956493** WU; worst ticks **6 / 7 / 2162**.
- **AC-204** PASS 200/200; **not determinism** (physics does not consume the RNG — F78).
- **FA-3** vacuous, **uncredited**. **FA-5** PASS with the 2–4-tick caveat.
- Determinism: same-build attempt 1; cross-architecture **0**.

---

## 3. D0 — the penetration control arm (do this FIRST; it decides AC-202's fate)

The R28 stop measured only the **adopted** build. Nothing yet says the reprojection caused the penetration,
and two of three worst ticks (6 and 7) sit in the spawn window with zero input. Therefore:

Run the **same** penetration measurement, same metric, same three presets, same **7200** ticks, on the
**reverted production build** (this session's head — no physics change needed).

Report per preset: `{max_penetration_wu, worst part/kind/u, worst tick, limit 0.02}` and a direct
side-by-side against the R28 adopted numbers above.

**Attribution rule — write it into the report, do not improvise it:**

| control (reverted) result | mandatory conclusion |
|---|---|
| ≥ 0.02 at similar magnitude | penetration is **PRE-EXISTING**; the reprojection is **not** demonstrated to cause it; F79 stands as its own defect |
| ≤ 0.005 | the reprojection **causes** it; AC-202 as adopted is **dead** |
| in between | **partially causative**; report both numbers, conclude nothing stronger |

**Do not** follow this with an adoption attempt, a fix, a clamp, a slop change, or a retry for a better
number. D0 is one arm. **Owner decision (2026-10-30): AC-202 stays FAILED for M1 and is not re-adopted in
this milestone** — the projection is re-evaluated inside M1.1 *after* the contact-rectifier fix, because
that fix changes the path the projection compensates for. D0's only job is to tell M1.1 whether penetration
is a second, independent defect in the same pass.

---

## 4. D1 — three presets + 10 s captures (E4)

For each preset, **one identical documented L/R input log**, identical seed, **600 ticks**:

- a per-tick capture (`tick`, `input_mask`, COM, per-part position/angle, contact/grounded flags);
- a **file-rendered plot** (SVG/PNG generated from the data by script — no camera, no scene, no product code);
- a shared manifest: same input digest, same seed, three preset ids, tick count.

Then establish "three different motions" **objectively**: per-tick trace hashes must differ pairwise (hash
inequality is binary, not a threshold) **and** report the quantitative divergence (mean pairwise COM
separation in WU, final poses) as numbers. **If the gate needs a numeric distinctness threshold, report the
numbers and flag it — do not author one.**

**Storage discipline (quota is exhausted — see D6):** commit captures as **repo files under
`tests/fixtures/m1_captures/`**, total **≤ 5 MB**. If the full per-tick JSON exceeds that, commit a decimated
copy (COM every tick; part states every 5th tick) **plus** the sha256 of the full file, and say so in the
manifest. Never make an E4 gate depend on an artifact upload.

---

## 5. D2 — tick cost §10.4

Solver tick time at **30 bodies / ≤ 120 constraints**; record the **actual** constraint count.
Protocol: warm-up discarded, **≥ 10 000 ticks**, report **median and P95**, plus hardware string and build.
Threshold **≤ 3.0 ms**.

**Label the hardware honestly:** a GitHub runner is x86-64 shared cloud — **not** a Snapdragon 660. The row
reads *"measured on CI hardware; reference-device leg NOT MEASURED (owner D07)"*. Do not claim a mobile pass,
do not write "60 fps". Commit the raw timing file.

---

## 6. D3 — §10.6 step 1 only

Fixed scenario, **10 000 ticks, 100 local repeats**, final-state hash **identical across all 100**. Log all
100 hashes as a committed file. Steps 2–3 (cross-architecture, 5 devices) stay **NOT RUN** — no hardware.
Step 4 already has its soak; **do not re-run it and do not present it as determinism**.

---

## 7. D4 — FA-4

The Slug, zero input: (a) settle **and sleep** within 4 s, (b) one L-hold lurch ≈ one body length.
Measure both on this build and report the actual numbers. Sleep is expected to fail (AC-201s) — record the
failure with its number, do not soften it.

Also report the lurch in **WU, BL and px** against the owner's open question: is **1.00 BL** a *spec* value or
a *scale* value? **Do not pick the interpretation.** Do not turn a working-window mean into a new ceiling.

---

## 8. D5 — FA-6

Ten runs of the **identical** scripted input; report all ten outcomes and the input log. Target band 6–8
successes; stop on 10 or at ≤ 4.

**State the variance source explicitly (F78):** if physics does not consume the RNG, ten identical runs
cannot diverge. Either name the real non-RNG variance source you vary (spawn offset / pose / tick-indexed
input), or report honestly that the ten runs are **identical by construction** and the gate is currently
**insensitive**. If the tutorial chunk does not exist in M1, record the substitution explicitly.

---

## 9. D6 — launch path and CI hygiene (do this before spending CI minutes)

- **`workflow_dispatch` returns 403 in this environment.** At `4796ec6` every R28 job is dispatch-gated, so
  **it cannot run**. Restore the push-trigger path that worked at `446d870`:
  `github.event_name == 'push' && github.sha == github.event.after && contains(head_commit_message, '[R29-once]')`.
  Keep the **literal measured sha** in the closing record and in the evidence JSON.
- **One invocation per arm.** Historical `[R1x–R27-once]` jobs stay pinned and un-run.
- **Artifact quota is exhausted** (1144 artifacts, 22.9 GB, private repo, 500 MB free). Consequences you must
  not paper over: any upload failure **skips every later step in that job**, which is how R11–R15 silently
  stopped running. So: prefer **committed repo evidence**; if you upload, upload last and never place an
  upload before a measurement step.
- Do **not** delete historical artifacts yourself — that is an owner action.
- Doc-only commits `[skip ci]`.

---

## 10. D7 — regression

`scripts/review_checks.sh` **≥ 226 / 0**; M0 **516 / 0**; `core/tuning.tres` **byte-identical** to session
start; `git diff 4796ec6..HEAD -- core/` **empty**; no preset/save/M0-expectation changes. State the diff
summary (expected: docs, tests, workflows, fixtures only).

---

## 11. Definition of done

- [ ] D0 control arm on the reverted build, with the attribution table filled in.
- [ ] D1 three captures + plots + manifest committed, ≤ 5 MB, distinctness by hash **and** numbers.
- [ ] D2 median + P95 + constraint count + hardware string; D07 note present.
- [ ] D3 100 × 10 000 identical hashes, log committed.
- [ ] D4 settle/sleep/lurch numbers; 1.00 BL question surfaced, not decided.
- [ ] D5 ten outcomes + explicit variance source (or honest "insensitive" finding).
- [ ] D6 push-trigger restored; one invocation per arm; no upload before a measurement.
- [ ] D7 green; `core/` diff empty.
- [ ] `.review/m1_r29_measurement_evidence.json` + `.review/m1_r29_measurement_report.md` committed, one entry
      per gate with `{gate, metric, value, threshold, verdict, artifact, not_measured, blocker}`.

---

## 12. Stop conditions

1. A gate needs a **new threshold or a redefined metric** → stop and ask; do not author it.
2. A measurement needs **product code, a tutorial chunk or a scene that does not exist** → record the
   substitution; do not build product surfaces.
3. Any **non-finite** state → report the first tick and the trace; never heal and re-run silently.
4. Any temptation to **re-attempt the AC-202 adoption** → no. It is reverted; D0 only informs the owner.
5. **Artifact upload fails** → move that evidence into the repo; do not re-run the arm to regenerate it.

---

## 13. Report format

```markdown
# R29 measurement report — head <sha>

## D0 penetration control (reverted build)
| preset | reverted max WU | adopted max WU (R28) | worst tick reverted | limit | attribution |

## D1 presets / captures
| preset | trace sha256 | distinct? | 10 s COM path | final pose | plot |

## D2 tick cost (limit 3.0 ms)
bodies / constraints / median / P95 / hardware / method / reference-device leg: NOT MEASURED (D07)

## D3 §10.6 step 1
100/100 identical: yes/no | hash | steps 2–3: NOT RUN

## D4 FA-4 | D5 FA-6
numbers + explicit variance source

## Regression
controls / M0 / tuning sha / core diff / changed files

## Not measured
each with its blocker
```

---

## 14. Claims you may not make

- No "determinism" from repetition (**F78**). No "60 fps", no mobile/reference-device perf claim.
- No "penetration fixed", no "AC-202 working", no "creep improved".
- No "FA-3 passes" — it stays **uncredited**.
- No "M1 complete" — the verdict is P3's, and the owner signs it.
- No causal claim about penetration until D0 has a number.
