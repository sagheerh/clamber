# M1 — R17 review: F47/F49/F50/F51 closed; the sleep predicate would sleep a walking creature @ `5b04cb4`

**Target:** PR #3 head `5b04cb4` (draft, OPEN). Commits over R16's `5f24081`: `04e1041` (F47 gate + F51), `f6b852a` (F48 6000-tick convergence), `34b0cfd` (F49/F50), `a6c33f8`/`5b04cb4` (record windows).
**CI:** `40813964958` **fails only the F47 support gate**; `40813965034` M0 **514/0** + Android pass.
**Reviewer branch:** `arena/5b72e4ab-clamber` → this file.

---

## 1. Verdict

**The gate now means what it says, and the drift is measured properly. In doing so the run exposed a defect in the sleep predicate that I authored — it would put a creature sliding at 3.93 px/s to sleep and then report FA-4 as a pass.**

| Item | Status |
|---|---|
| F47 gate | **CLOSED** — sustained same-tick single-foot majority; M1 correctly red |
| F48 convergence | **CLOSED as measurement** — 6000 ticks, explicit classification, no epsilon, settled value left unset |
| F49 phase magnitudes | **CLOSED** — separate pre-fold maxima |
| F50 spawn sensitivity | **CLOSED** — spawn-independence to `3.79e-19`, which also retires F41's spawn confound |
| F51 count | **CLOSED** — 931 everywhere |
| Python 128 / mechanics 931 / M0 514 | **reproduced locally / CI-confirmed** |
| **F52 [BLOCKING for FA-4]** sleep fires on a steadily sliding creature | new, **my constant's derivation was incomplete** |
| **F53 [MINOR]** `vx_change_sign_reversals` counts direction changes, not sign reversals | new |
| **F54 [NOTE]** self-contact never fires on the Slug in 6000 ticks | new |
| FA-3/4/5/6, captures, determinism | `NOT RUN` / **0** |

---

## 2. F47 — closed, and the controls are the right ones

`sustained_support()` is exactly what was asked, no more and no weaker:

```python
total = fsum(measured_reaction for grounded bodies)
candidates = [(foot, foot.reaction / total) for grounded feet]
passed = fraction > 0 and bool(majority_ticks)   # majority_ticks: same-tick grounded+gripping+reaction>0 and share > .50
```

The four shapes I wanted rejected are rejected: landing-only grip (fraction 0 in the last 300), exactly-half support (`> .50` is strict), aggregate-feet support (per-foot, not summed), and grip/share on different feet or different ticks (same-tick, same-foot). The returned evidence is self-describing (`grip_fraction`, `max_single_foot_grounded_support_share`, `loaded_majority_grip_ticks`), so a future reader can see *why* it passed or failed.

CI is red for exactly this and nothing else: every arm reports `support_gate_passed: false`, with `last300_grip_fraction 0.0` and `max_single_foot_share` **0.2224** (baseline) / **0.2841** (actuated). M1 is now honest. FA-5 untouched.

---

## 3. F48 — measured correctly; the answer is "internal, not landing"

The convergence report refuses to manufacture an equilibrium, which is the point: `classification: oscillating transient`, `settled: false`, `settled_mean_dx_wu_tick: null`, `mean_label: TRANSIENT WINDOW MEAN, NOT EQUILIBRIUM`, and an explicit criterion with no velocity epsilon. Three arms at 600, 3000 and 6000 ticks all give the same mean to 12 digits (`0.0004371693616757`), so the measurement is stable even though no settlement was claimed. `spring_return_live: true` and "ZERO INPUT IS NOT UNPOWERED" are on every line. Good.

The numbers that matter, at 150 px/WU:

| arm | drift | note |
|---|---:|---|
| baseline (free hinges) | **0.084 px/s** | the number we chased for four rounds |
| actuated before-pose | **3.513 px/s** | spring live |
| actuated after-pose | **3.934 px/s** | spring live |
| actuated after-pose, raised spawn | **3.934 px/s** | identical |

And F50 makes the mechanism question answerable: the two spawns differ by **`3.7947e-19`** (actuated) and **`8.7414e-19`** (baseline) per tick. A landing artefact cannot be spawn-invariant to 19 digits. Adding motors made the lateral drift **47× worse**, and it is a property of the always-on spring, not of how the creature lands.

Supporting evidence already in this run: `angular.max_abs_limit_block_impulse = 5.67e-04` against `max_abs_drive_impulse = 4.44e-02` — the angular limits are active **1.3 %** of the drive. So the creature is not fighting its limits; something else is pushing it, and the only other torque source is the spring return.

**Mechanism hypothesis to confirm (not to adopt):** `rest_angle` is captured from the *authored* pose at setup, and the spring drives `q → 0`. Gravity sags the creature to a pose it cannot hold, so every joint sits at `q ≠ 0` and the spring applies a **permanent** restoring torque — an internal motor that never switches off. The limit cycle then rectifies it into lateral walking.

**Ask, diagnostic only, no adoption:** report per joint the mean `|q|` and the mean spring torque contribution over the last 300 ticks; and run `physics_passive_stiffness` as a diagnostic sweep (e.g. current value and 0) with drift reported for each. If drift collapses toward the 0.084 px/s baseline when the spring is off, the mechanism is proven and the fix becomes an owner decision (spring targets the settled pose, weaker spring, or no passive spring at all) — **not** something to change in code now.

---

## 4. F52 [BLOCKING for FA-4] — the sleep predicate sleeps a creature that is walking

`CreatureSleep.observe()` compares **per-tick** COM displacement to `sleep_still_displacement_wu`:

```gdscript
maximum = max over bodies of |com_after − com_before|          # ONE tick
still_ticks += 1 if maximum < 0.001 WU
asleep when still_ticks == 30
```

Against the numbers this run just produced:

| creature | per-tick COM | vs 0.001 WU (0.15 px) | net over the 30-tick dwell | vs 0.001 WU |
|---|---:|---|---:|---|
| free-hinge settled | `9.34e-06` WU (0.0014 px) | 107× below → sleeps ✅ | `2.80e-04` WU (0.042 px) | below ✅ |
| **actuated, sliding 3.93 px/s** | **`4.37e-04` WU (0.066 px)** | **2.3× below → sleeps** ❌ | **`1.31e-02` WU (1.97 px)** | **13× above** |

So a creature travelling at 3.93 px/s satisfies the stillness test on every single tick, accumulates 30 still ticks, and is declared **asleep at ~1.1 s** — at which point velocities are zeroed and it is parked mid-slide. FA-4 asks "does the Slug settle/sleep within 4 s", and this implementation would answer **yes** for a creature that never stopped moving.

This is my error, not the agent's: I proposed `0.001 WU` from the free-hinge numbers only, and wrote in the decision record that the margin was 139× because the settled drift was `7.175e-06`. I never checked the constant against a creature with a live actuator, which at the time did not exist. The constant is not wrong; **the window it is applied to is too short.**

**Fix, no new constant, no owner decision needed:** apply the *same* `0.001 WU` to the **net displacement over the dwell window** as well as per tick — i.e. hold the snapshot from the start of the dwell and require `|com(t) − com(t − 30)| < sleep_still_displacement_wu`. The table above shows it discriminates cleanly: settled creatures pass at 0.042 px, the sliding creature fails at 1.97 px. Per-tick stillness alone is what makes it unsafe.

**Required control:** add a **slow-slide falsification fixture** — a body advancing `5.0e-04 WU/tick` (below the per-tick threshold, above the net-over-dwell threshold) must **never** sleep. Right now `grep` finds no such test in `tests/sim/test_sleep.gd`; every existing case is a genuinely settling creature, which is why 3,659 passing checks did not catch this.

**Scope note:** sleep is currently composed only with the free-hinge probe, so this cannot mislead CI yet. It becomes reachable the moment public `Sim` lands with motors and a live spring — which is the next increment. Fix it before wiring, not after.

---

## 5. Smaller items

**F53 [MINOR]** — `vx_change_sign_reversals: 99` is computed over a window whose `vx` is strictly positive (`[0.0222, 0.0431]`), so it cannot be counting sign changes. It is counting reversals in the *direction of change* (`Δvx` flips). Rename to `dvx_direction_reversals` before someone reads "sign reversals" as "the creature is jittering about zero".

**F54 [NOTE]** — `self_contact.max_abs_position_delta_wu = 0.0` and `max_impulse_magnitude = 0.0` across all 6000 actuated ticks. Expected on a 3-part Slug (D-10 excludes both pairs), but it means the self-contact path is exercised **only** by its unit tests. Do not describe self-contact as validated at scale until a preset that can actually self-hit (Hopper, or a sagging multi-limb build) produces a non-zero impulse.

**F41 status, now narrowed.** F50 retires the spawn confound: two legal spawns give drift identical to `3.8e-19`. What remains between the pose pair is (a) the pose itself and (b) the count regime (`last300_per_tick_count_regimes_identical: false` for actuated, `true` for baseline). That is now a one-step question, and the trace already contains what is needed: **bucket the last-300 drift by count regime** — group ticks by their `(intervals, candidate, active)` tuple per body and report mean drift per bucket. If drift is constant within a bucket and differs across buckets, the mechanism is sampling, not pose, and F41 can be closed as a sampling artefact with evidence.

---

## 6. Where M1 stands

**Landed and verified:** infrastructure; math 381; geometry 136; presets + model; SDF + swept contact 237; force-channel split; load producer + conservation + ledger; telemetry; pose A/A1 + hard audit; positional sleep + replay; mechanics (motors, asymmetric limits, velocity blocking, D10 self-contact) 931; **F47 honest gate**.

**Blocking / open, in order:**

1. **F52** — sleep must not fire on a sliding creature (same constant, longer window, plus a slow-slide control). This is the one thing that could manufacture an FA-4 pass.
2. **F48 mechanism** — per-joint `|q|`/torque and a passive-stiffness sweep, to confirm the spring is the source of 3.93 px/s before any fix is proposed.
3. **F41** — bucket drift by count regime.
4. F53 rename, F54 caveat.
5. Public `Sim` wiring + F45 superseded sleep constants + replay.
6. Then FA-5's four branches, FA-3/FA-4 on three presets, AC-201/202/204, A9, §10.6, tick cost, captures.

**Acceptance gates passed: 0 of 21.** Analytic-only: FA-1/2/7. Complete-creature determinism attempts: **0**.
