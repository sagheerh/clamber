# M1 — R16 review: motors/limits/self-contact accepted as components; the blocking gate flipped green @ `5f24081`

**Target:** PR #3 head `5f24081` (draft, OPEN). Commits over R15's `d2fe703`: `3b6e180` (actuated composition + legal paired probes), `0cf1215`/`35df327` (compile fixes), `548b5c8` (independent spawn/self-contact checks), `5f24081` (records).
**CI:** `40810927730` M1 **success**, `40810927619` M0 **514/0 + Android pass**.
**Reviewer branch:** `arena/5b72e4ab-clamber` → this file.

---

## 1. Verdict

**The mechanics work is real, honest and builds on the existing constants — accepted as components. But M1 is now green for the wrong reason, and I missed its first flip two rounds ago.**

| Item | Status |
|---|---|
| Motors / angular limits / self-contact | **accepted as components**; every coefficient pre-dates at `c641990`, no new tuning |
| Falsification controls | **good** — outward blocked / inward not blocked, no root joint, feet+adjacent excluded from self-contact |
| F43 legal spawns | **closed** — `.405` / `.6100000000000001`, `lowest_initial_surface_wu = 0.01` in all four arms |
| F44 count reporting | **closed** — forged interval/candidate/active rejected independently |
| F41 | **correctly left open**, not downgraded |
| Python 106 / mechanics 931 / M0 514 | **reproduced locally / CI-confirmed** |
| **F47 [MAJOR]** M1 green on 1–5 transient grip ticks; the blocker no longer blocks | new, and partly **my miss** |
| **F48 [MAJOR]** zero-input actuated drift is **47×** the free-hinge creep and the window is not steady | new |
| **F49 [MINOR]** phase folding hides `angular`/`self_contact` magnitudes | new |
| **F50 [MINOR]** the F41 pair still confounds pose with spawn | new |
| **F51 [NIT]** "921" vs "931" mechanics checks in the same message | new |
| FA-3/4/5/6, captures, determinism | `NOT RUN` / **0** |

---

## 2. F47 [MAJOR] — the check that was kept red to block advancement is now green

The gate is unchanged since `bc4202a`:

```python
'foot_load_path_exercised': bool(loaded_grip)      # any tick where a foot grips with reaction > 0
...
raise SystemExit(0 if good and momentum_ledger_verified and position_ledger and foot_load_path_exercised else 1)
```

and CI runs that script with `exit "$status"` — **no `continue-on-error`, no bypass**. So M1 green means this condition passed. It passed on:

| arm | grip ticks | first grip | toggles | last-300 grip fraction | foot support share | grounded late |
|---|---:|---:|---|---:|---:|---|
| legal baseline-after | **5 / 600** | tick 4 | `[4, 9]` | **0.0** | 22.24 % | `[[0,1,2]]` |
| historical 0.33 after | **1 / 600** | tick 19 | `[19, 20]` | **0.0** | 22.24 % | `[[0,1,2]]` |

So the blocker was satisfied by **landing impact** — the foot loads hard for a few ticks as the creature settles, grips, and then never grips again for 99 % of the run, while the head and motor bellies carry 77 % of the support and 17 contact samples per tick remain.

Two things follow, and both are on me as much as on the agent:

1. **This is exactly the risk I raised as F37 in R11** ("a single gripping tick in 600 flips the whole F30 gate green while the creature may still be standing on its motor 99 % of the time"). I asked for the fraction and share metrics and did **not** ask for the gate to use them. The metrics were added; the pass condition was not. That is now the single most misleading signal in the project.
2. **I reported "M1 green" in R15 without checking why it had gone green.** It flipped at `d2fe703` (grip at tick 19), one round before this one, and I let it pass. That is a review miss and I am recording it here rather than letting it stand.

**Ask**, small and mechanical: make the gate require *sustained* support, not existence. The numbers already in the trace make this a one-line change with no new constant, for example:

```
foot_load_path_exercised  ->  foot_support_demonstrated
= (last-300 grip fraction > 0) AND (max single-foot share of grounded support in the last 300 > 0.50)
```

Both quantities are already computed (`steady_grip_fraction`, `steady_foot_support_share_mean`). Under today's data that keeps M1 **red**, which is the honest state: the foot carries 22 % and grip never persists. Choose the exact form and say so in the commit message; do not let the existence boolean remain the gate. FA-5's real pass/fail stays where it is.

---

## 3. F48 [MAJOR] — with zero input, the articulated creature slides 47× faster than the limp one

The actuated arms call `advance(0)` — input mask **0**, so no contraction, only the always-on spring return (`torque = stiffness·(0 − q) − damping·ω`, clamped). Even so:

| arm | COM Δx / tick | COM speed | at 150 px/WU | travel in 10 s |
|---|---:|---:|---:|---:|
| baseline before | −7.175e-06 | −0.065 px/s | 0.065 px/s | 0.6 px |
| baseline after | +9.337e-06 | +0.084 px/s | 0.084 px/s | 0.8 px |
| **actuated before** | +3.904e-04 | +0.0234 WU/s | **3.5 px/s** | 35 px |
| **actuated after** | +4.372e-04 | +0.0262 WU/s | **3.9 px/s** | 39 px |

`Σm·|g|` is 43.4 N and the creature weighs 1.55 kg, so this is a creature **walking sideways at ~3.5–4 px/s with nobody touching it**. The free-hinge creep I chased for four rounds is 0.08 px/s; adding the parts that make it a creature made the number **47× worse**. That is the number to watch from now on, and it should be reported on every subsequent run as its own line.

Second, sharper problem: **the actuated window is not steady.** `last300_com_vx_range` is `[0.0222, 0.0431]` WU/s — a 2× spread — whereas the free-hinge arms hold `vx` constant to `5e-17`. So `last300_com_dx_wu_tick` is a mean over a still-evolving transient, and the `before` vs `after` comparison (`0.000390` vs `0.000437`) is two transients being compared as if they were equilibria.

**Ask:** report convergence explicitly (is `|vx|` monotone, oscillating, or settled by tick 600?), and if it is not settled, run the actuated arms longer (3000–6000 ticks) and report both the transient and the settled value. Do not start interpreting actuated drift until the window is steady. Also state plainly in the record that zero input ≠ unpowered: the spring return is active, so "awake zero-input" still contains a live actuator.

---

## 4. F49 [MINOR] — the phase adapter is lossless, but it also makes two mechanisms invisible

`accepted_view()` folds `angular` and `self_contact` into `hinge` for the actuated arms, and it does so **properly**: it first requires all six phase keys, re-closes the raw ledger per endpoint (`|net − Σ phases| ≤ 1e-12`) and raises if not, then folds. `test_lossless_phase_adapter_keeps_source_raw` proves the source rows are untouched. That is the right way to adapt.

The cost: after folding, a self-contact explosion or an angular-limit fight becomes indistinguishable from a hinge correction, and the per-phase maxima report no longer shows them. Since self-contact and angular rows are brand new and unmeasured at scale, that is the wrong thing to hide.

**Ask:** in the trace summary, report `max |Δposition|` and `max impulse` for `angular` and `self_contact` **separately**, before folding. One extra block, no behaviour change.

---

## 5. F50 [MINOR] — the F41 pair still confounds pose with spawn

The four legal arms are `(baseline, actuated) × (before-pose, after-pose)`, and the derived spawns are `0.405` for before and `0.6100000000000001` for after. Each is legal — but the two arms of the pair differ in **both** pose and start height, so "pose-causal" cannot be concluded from them, which the agent correctly refuses to claim.

F38 already showed the momentum plateau is insensitive to spawn; the **drift** was not tested that way. The same infrastructure answers it cheaply: run the post-pose arm at `0.610` **and** at `0.610 + 0.20` (both legal). If drift is unchanged across the two, the spawn difference cannot explain the pose pair, and the pose claim becomes defensible; if drift moves, F41 is a landing artefact and should be treated as such. Report it; do not use it to close anything prematurely.

---

## 6. F51 [NIT] — two different numbers for the same suite

The message says "**921** mechanics checks" and the session report says "**931 checks PASS**". CI's annotation says `M1 R15 mechanics components: 931 checks, 0 failures`, and `tests/run_m1_mechanics.sh` gates on the printed count. The 921 is a typo in prose. Worth fixing before someone quotes it: a suite count that disagrees with itself is exactly the kind of small incoherence that makes bigger claims harder to trust.

---

## 7. What is genuinely good in this increment

- **No new physics constants.** Every coefficient used (`motors_*` stiffness/damping/torque/contraction/limits/gain, `physics_passive_stiffness`, `physics_passive_limit_deg`) is `c641990`-era; `git diff d2fe703 5f24081 -- core/tuning.tres` is **empty**. The only numbers added to the repo this round are the CORDIC mathematical table.
- **The controls are adversarial, not decorative.** Outward velocity blocked *and* inward deliberately not blocked; two passes cannot spend the clamp twice; `setup(parent, parent)` rejected so there is no root/self joint; self-contact excludes feet and adjacent pairs by construction and asserts that it can never set `grounded`/`gripping`.
- **Self-contact conserves** both mass centre (position) and momentum (velocity) to `1e-14`, uses the existing `contact_slop` rather than a new radius, and adds no invented self-friction.
- **CORDIC replaces runtime trig** with a fixed binary64 table, which removes a genuine cross-platform determinism risk before it could bite.
- **Count evidence is independently validated** — forged `interval/candidate/active` tuples are rejected, duplicate rows rejected, and a missing raw event cannot be silently read as a smaller regime.
- **Spawn is derived, not hard-coded**, and validated against the actual start endpoints: `spawn_y + authored_bottom − 0.01 ≤ 1e-15` in all four arms.

---

## 8. Where M1 stands

**Landed and verified:** infrastructure; math 381; geometry 136; presets + model; SDF + swept contact 237; force-channel split; load producer + conservation + ledger; telemetry; pose A/A1 with hard audit; positional sleep with replay; **mechanics: motors, asymmetric limits, velocity blocking, D10 self-contact (931 checks)**.

**Open, in priority order:**

1. **F47** — make the M1 gate require sustained foot support so red means red (this is the only thing that can silently misreport progress).
2. **F48** — quantify the zero-input actuated drift properly, with a converged window; 3.5–3.9 px/s is a feel-level defect and it is 47× the number we spent four rounds on.
3. **F49** — expose angular/self-contact phase magnitudes.
4. **F50** — one extra legal spawn to break the pose/spawn confound for F41.
5. Public `Sim` wiring (still a 33-line stub) + F45 superseded sleep constants.
6. Then FA-5's four branches, FA-3/FA-4 on three presets, AC-201/202/204, A9, §10.6, tick cost, captures.

**Acceptance gates passed: 0 of 21.** Analytic-only: FA-1/2/7. Complete-creature determinism attempts: **0**.
