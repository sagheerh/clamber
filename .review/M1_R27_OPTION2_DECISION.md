# M1 — R27 review + DECISION: Option 2 applied, AC-201 authored, the AC-202 injector identified

**Target:** PR #3 head `0c2fc2a` (draft, OPEN), commits `ddefbba` → `559e929` → `0c2fc2a` over `ae7c3ee`.
**Verified by me:** the brace is **gone** (no `brace` symbol anywhere in `core/`), and `core/tuning.tres` is **byte-identical** to `ae7c3ee` — the four P-B values survive: bound **30.0**, stiffness **10.0**, damping **0.5443327361211717**, max_torque **12.0**. Brace-free baseline regenerated on the same source; strict replay passes.
**Reviewer branch:** `arena/5b72e4ab-clamber`. Local: **202** Python controls pass.

---

## 1. Verdict

The bounded increment did exactly what it was bounded to do: **it eliminated the last two hypotheses and, in doing so, identified the real AC-202 injector and closed FA-5's coverage gap.** Option 2 is applied below, with authored numbers.

| item | outcome |
|---|---|
| Brace removal | **accepted** — atomic, physics untouched |
| **D1** friction proportionality | **not proportional** — and the response is inverted at low μ; no located cause |
| **D2** ordering hypothesis (F76) | **falsified** — but the phase trace **locates the injector: the contact position pass** |
| **F76 revised** | new statement with per-phase numbers |
| **FA-5** | **PASS** — all four branches covered on natural authored Hopper, no injection |
| **AC-201** | **amended and authored** under Option 2 (§3) — measurable, sleep clause named and deferred |
| **AC-202** | **one correctness arm authorised** (§4) — a located fix, not a sweep |
| Rows | **8/18 now; 10/18 expected** after the next increment |

---

## 2. The measurements, read closely

### D1 — friction does not scale the thrust, and low μ makes it worse

| μ | drift px/s | thrust N | % of weight | support N |
|---:|---:|---:|---:|---:|
| 0.3 | **9.39342** | 0.118855 | 0.2739 % | 43.2417 |
| 0.9 (committed) | 8.55015 | 0.108186 | 0.2493 % | 43.2299 |
| 1.8 | 8.48216 | 0.107325 | 0.2473 % | 43.2293 |
| 3.6 | 8.48216 | 0.107325 | 0.2473 % | 43.2293 |

Three things follow, and your "effective tangent retention" instinct is what makes them readable:

1. **1.8 and 3.6 are identical to every digit** — the tangential solve hits a clamp that is not μ-dependent, so above 1.8 the coefficient is inert. Same signature as the motor's saturation in R20: an invisible ceiling, not a physical response.
2. **Lowering μ from 0.9 to 0.3 *increases* drift by 9.9 %.** A friction-driven rectifier would fall with μ. This one rises. So the thrust is not "friction holding harder"; it is the contact solve emitting a tangential impulse whose *magnitude grows* as the coefficient shrinks relative to the demand.
3. Across the whole 12× μ range the thrust moves only **±5 %** (0.1073 → 0.1189 N) while the coefficient moves 12×. **The rectifier is inside the normal-impulse / position-correction path, not in the friction coefficient.** That is why no friction number will ever fix it, and it is the same conclusion F75 reached from the other side.

D1 is **inconclusive for a located correctness-shaped cause**, as you say. Recorded.

### D2 — my ordering hypothesis is dead; the contact pass is the injector

Per-phase limb-length error, `final_distance` arm (7200 ticks, completed):

| phase | limb error WU |
|---|---:|
| after integration | 0.084447 |
| after the iteration's distance block | **0.000000** |
| after final hinge / angular / self-contact | **0.014927** |
| after a diagnostic distance pass appended before contact cleanup | **0.000000** |
| **after contact position pass 0** | **0.051911** ← injects |
| completed tick | **0.051911** |

So: the projections converge beautifully (0.0149), the appended distance pass takes it to **zero**, and then the **contact position correction moves the bodies and re-injects 0.052** — after which nothing reprojects. The baseline arm shows the identical pattern (0.014927 → **0.053346**).

**F76 revised:** *AC-202's failures are injected by the contact position-correction pass, which runs after every projection iteration and after the appended distance pass, and are never reprojected.* My angular-ordering hypothesis was wrong; the trace refutes it and replaces it with something better, because this one has a one-line-shaped fix.

That also explains the landing clustering you saw in R26 (ticks 6, 9, 13, 28): impacts are when contact position correction is largest.

### FA-5 — all four branches, on natural authored geometry

| branch | samples | coverage |
|---|---:|---|
| below threshold (slips) | 4 731 | ✅ |
| at/above threshold (grips) | 27 | ✅ |
| two-foot stance grips | 9 | ✅ |
| **airborne (never grips)** | **236** | ✅ |
| ineligible / not lowest | 4 640 | control |
| N0 no-grip | 14 | control |

`missing_coverage: []`, `passed: true`, no pose, velocity or qualifying-load injection, and the airborne branch arose naturally (ledge departure at tick 83) rather than from a manufactured drop. Your event definition — maximal consecutive ticks per foot/branch, both velocity passes and all capsule samples collapsed into one tick — is the right unit and I am adopting it as the standing definition.

**Caveat to carry, not a defect:** episodes last 2–4 ticks, so this is **policy coverage, not sustained-grip characterisation**. FA-5 asks whether the policy grips when loaded; it does. Sustained grip belongs to FA-3 and to the feel work.

---

## 3. DECISION — AC-201 amended (Option 2), with authored numbers

The GDD's *"no-input trace shows settling AND sleep within ≤4 s"* is **not met and cannot be met** with these constants: sleep requires ≤0.3 px/s and the creature creeps at 8.55. Rather than delete the clause, it is **split into three named parts**, one of which stays failed and visible.

**AC-201a — Stability (new, measurable now).** Over **10 s** of zero input from spawn: no tick in which every part is airborne, and the head-to-foot attitude vector changes by **≤ 15°**.

**AC-201b — Parked (new, measurable now).** Over the same 10 s, net centre-of-mass displacement **≤ 1.0 body length = 0.90 WU = 135 px** at 150 px/WU.
*Derivation, fixed before looking at the result:* one body length is the largest displacement that still reads as a creature settling rather than travelling — beyond it, an idle creature has visibly relocated by more than its own footprint on a 7.2 WU chunk. Measured for the record: 8.55015 px/s × 10 s = **85.5 px = 0.570 WU = 0.633 body lengths**, i.e. **passes with a 1.58× margin**. Disclosed plainly: at a 0.5 body-length limit this would have failed, and the criterion would begin failing if creep rose above **13.5 px/s**. The number is near enough to the boundary to be worth stating rather than celebrating.

**AC-201s — Sleep (named, deferred, still failing).** The unmodified F52 predicate must fire within 10 s. It does not, and it will not until the contact rectifier is fixed. This clause moves to **M1.1** with the contact-model work, is recorded as **FAILED** in the matrix rather than removed, and the GDD text is preserved with a pointer to this decision.

**Net effect:** AC-201 becomes a measurable gate that the current build can honestly pass on a/b, while the sleep failure stays visible as a named carry-over instead of disappearing. Nothing is widened, no tolerance moves, no epsilon is added.

---

## 4. AC-202 — one correctness arm authorised (not a sweep)

I said the *drift* gets no more measurement. AC-202 is a different gate, and its injector is now located by your own trace, so it gets exactly **one** arm:

> Add the distance projection **after** the contact position-correction pass (same rows, same code, same tolerance — the same appended pass you already built, moved to the end), then report the **completed-tick** limb maximum over 7200 ticks for all three presets.

- If the completed-tick limb error falls to ≈0.015 (the pre-contact value), **AC-202 passes** and the fix is an ordering defect with a correctness patch — report it for adoption.
- If it stays above 0.05, AC-202 is reported **FAILING** with the measured number and joins AC-201s as M1.1 carry-over.

No other change, no iteration-count increase, no tolerance change, no re-run of D1.

---

## 5. What this means for finishing M1

**Now:** 8/18. **After the next increment, honest expectation: 10/18** — AC-201 (a/b measured, s deferred) and FA-5.

Remaining after that, and I want the distinction to be explicit from here on:

| row | state | what it needs |
|---|---|---|
| AC-202 | red, one arm from a fix | the post-contact reprojection arm |
| AC-204 | not built | 200-run soak harness — **no blockers, pure test authoring** |
| presets + captures | not built | capture tooling does not exist anywhere in the repo |
| tick cost | not built | 30-body scene + **your phone (D07)** |
| §10.6 | not started | 10000×100 + a second architecture |
| FA-3 | not run | 600-tick static scene, zero sleep-breaking contacts — **no blockers** |
| FA-4 | **failing** | 0.269 BL measured vs 1.00 target, and the lurch measurement is contaminated by creep until AC-201s is fixed |
| FA-6 | fixture staged | needs the 10-run batch on the pre-registered timing list |

**A hard expectation to set now:** M1 will reach **18/18 measured**, and it will not reach **18/18 passing** in this milestone. `FA-4` (lurch) and `AC-201s` (sleep) both depend on the contact rectifier, which is an M1.1 conversation. That is not a failure of M1 — it is M1 doing its job: every gate measured, every failure named with numbers, nothing laundered.

**If you want M1 to close as "complete", the definition I will sign is:** all 18 rows carry a measured verdict with evidence, every failing row has a named, scoped follow-up, and no gate was passed by relaxing it. Under that definition M1 closes at **16/18 passing, 2/18 failing-with-cause** — and M2 stays blocked until those two are resolved or the GDD is amended by you.

---

## 6. Directives now

1. **Measure AC-201a/b** on the committed defaults and **record the sleep clause as FAILED** under the new split.
2. **Run the one AC-202 arm** (§4) and report the completed-tick limb maximum for all three presets.
3. **Upgrade FA-5** to PASS with the transient-coverage caveat and the adopted event definition.
4. **Start AC-204's soak harness and FA-3's static scene** — neither has a blocker, both are test authoring, and they have been `NOT RUN` since the scaffold.
5. **Nothing else.** No knob sweeps, no brace, no drift experiments, no tolerance or epsilon changes, no `motors_*` or slip values touched.

**Acceptance 8/18 until each row is measured. Determinism attempt 1 stands as a same-build observation; cross-architecture attempts 0.**
