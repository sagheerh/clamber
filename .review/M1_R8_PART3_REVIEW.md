# M1 — R8 review: Part 3 (creature / capsule / contact components)

**Target:** PR #3 head `0e34a5a` (draft, OPEN), branch `arena/4cd0a587-clamber`
**Baseline for this round:** `9a45f6d` (R7 verdict) → `81d0840` → `969ef16` → `5bb9132` → `e702232` → `a8f071a` → `5ff93bf` → `0e34a5a`
**Reviewer branch:** `arena/5b72e4ab-clamber` @ `ad9fbbc` (no game code touched)
**CI:** M1 `40678480824` (green), M0/Android `40678480966` (green, **504** M0 checks), push runs `40678471118` / `40678470869` (green)

---

## 1. Verdict

| Item | Status |
|---|---|
| **F20** — matrix guard accepted fake FA passes | **FIXED — verified** (4 independent fake claims now exit 1) |
| **F21** — `readable_pixels` exact-equality tolerance | **FIXED — verified** (float-noise only, < 2e-9) |
| **Part 3 components** (presets, creature trees, capsules, SDF, swept contact, grip response) | **ACCEPTED AS COMPONENTS** — honestly scoped, no runtime claim made |
| **Grip load path** (the thing the next increment will build on) | **NOT READY — 2 blocking findings (F22, F23)** |
| **Grip gate vs. 3+ feet** (player-made creatures) | **BLOCKED — owner decision required (F24)** |
| **Runtime gates** FA-3 / FA-4 / FA-5 / FA-6, AC-201/202/204, A9, captures | **still `NOT RUN`** — correctly declared |

The work in this window is disciplined: production JSON is verified byte-exact inside the shipped AAB **and** APK, D-10 is checked against the real presets (with a non-vacuity guard), every new constant is unchanged, and every log line that touches FA-5 says "controlled component loads only". That is the right shape.

It is also, precisely, why the next step must not be taken yet. Part 3 built a **force channel that carries no load**, and the increment the agent is about to build (couple bodies + hinges + contact reactions + motors) is the increment that consumes that channel. Built as-is it will produce a creature that cannot stand, with every test green.

---

## 2. What I verified myself (vs. what I am taking from CI)

**Verified locally** (git reads, arithmetic, guard re-runs, Python suites):

- `python3 scripts/check_m1_matrix.py` → exit 0 on the real matrix; `scripts/review_static.py` → 51 files clean.
- Python suites: `test_review_checks` 19, `test_owner_geometry_source` 4, `test_static` 6, `test_android_inspection` 8 = **37**, all pass.
- F20 negative controls re-run on a clean `/tmp/pr3h` extraction, all **exit 1**: FA-6 forced to `PASS (analytic only)`; FA-5 forced to `PASS`; prose line `FA-6: PASS (8/10 successes)`; FA-2 analytic with a `None` citation. Baseline matrix **exit 0**.
- F21: `readable_pixels` accepts `14.999999999999998`, rejects `14.5`, `15.0 − 2e-9`, `NAN`.
- `git diff 9a45f6d 0e34a5a -- core/tuning.tres core/tuning.gd docs/TUNING.md` → **empty**. Every `physics_*_collision_radius_wu`, `art_*`, `physics_head_*`, `physics_grip_*`, `physics_static_slip_wu_s` value is untouched.
- All "new" physics keys used by the contact code (`contact_slop_wu`, `sdf_cell_wu`, `foot_restitution`, `grip_friction`, `limb_reset_residual_wu`, `max_projection_wu_tick`, `max_linear_velocity_wu_s`) originate at **`c641990` (M0)**, not in this PR. Only `physics_grip_normal_force_ratio/floor` are new, at `0668d66`, owner-derived.
- `0.40 / 5.0 / 1.4 / 0.15` are pinned as exact Decimals in `tests/test_owner_geometry_source.py` — a silent retune cannot pass CI.
- Grip association fix is real, not cosmetic: `(0.40*1.55)*28 = 17.360000000000003` vs `0.40*(1.55*28) = 0.40*43.4 = 17.36` (because `1.55*28` lands exactly on `43.4` while `0.4*1.55` does not). No epsilon, no constant change. The test recomputes the threshold with the *same* expression, so the old association would have failed the equality case — the regression is genuinely pinned.
- No camera / M2 / product-screen file is touched anywhere in PR #3 (`git diff --name-only origin/main...HEAD | grep -i camera|m2|screen` → empty).
- `core/sim/sim.gd` is still a 33-line stub (`pass` bodies); `core/creature/validator.gd` is a 2-line M0 stub.

**Taken from CI annotations** (no Godot 4.7.2 binary in this sandbox and `godotengine.org` is not reachable, so I cannot re-execute GDScript): `M1 contact primitives: 208 checks, 0 failures`, `M1 owner geometry: 128 checks, 0 failures`, `FA-1/2/7 PASS (analytic only)`, `FA-3/4/5/6 NOT RUN`. Counts are CI-sourced, not agent-message-sourced.

**Floors are honest.** `tests/run_m1_contacts.sh` requires exactly one `M1 contact primitives: (\d+) checks, 0 failures` line with `>= 208`, plus exactly 4 `M1 controlled foot:` traces, and greps the log for `SCRIPT ERROR|ERROR|Parse Error`. The count cannot silently drop. The header comment reads "Production definitions and contact component tests only, NOT coupled FA-5".

---

## 3. F22 [MAJOR] — the grip gate reads a load that nothing in the repo produces

`may_grip` is decided by `body.normal_force_last_tick >= threshold` (`core/sim/capsule_contact.gd:97`), and that field is written at line 152:

```gdscript
body.normal_force_last_tick = maxf(positional, impulse)
```

Both terms are properties of **this one capsule's own interaction with terrain**:

- `positional += correction / (dt*dt)` where `correction = max(0, radius − slop − distance) / denominator` and `denominator = v²·(1/m_a) + u²·(1/m_b)` — a mass-weighted **penetration**, using only this capsule's two endpoint masses.
- `impulse += bounce / dt` where `bounce = −(1+e)·min(0, v·n) / denominator` — this capsule's own momentum change.

There is no parent link, no hinge reaction, no gravity share anywhere in the expression. Consequences:

1. **At rest the value is exactly 0.** A foot settled at `distance = radius − slop` gives `correction = 0` and `v·n = 0` → `positional = 0`, `impulse = 0` → no grip → no `×1.4` bias → tangent speed retained → the creature slides on flat ground forever.
2. **The gate's number is a whole-creature share.** For the Slug, `threshold = 0.40 × 1.55 × 28 = 17.36 N`, derived from **total** mass 1.55. A single foot capsule's own contribution is its own mass `0.30 × 28 = 8.4 N` — a factor of **2.07 short**, even in the best case where the capsule registers its own weight.
3. **The one writer of a qualifying value is the test.** `tests/sim/test_contacts.gd:184` does `foot.normal_force_last_tick = load`, with the honest comment "Explicit controlled prior-force state, NOT force measured from a whole-creature stance". The assertion at 189 is therefore a mirror of the comparison, not an exercise of the load path.

This is not misconduct — the labelling is unusually careful. It is a **missing load path that the next increment is supposed to supply, and that the current primitive cannot express.** `CapsuleContact` has terrain but no gravity and no constraints; `PointLinkSolver` has gravity (`solver.gd:172`) and distance constraints but no terrain and never references `CapsuleContact` or `SdfGrid`. The two halves do not touch, so no arrangement of the shipped code can put 17.36 N into a foot on a Slug.

**Why now and not later:** the coupling increment is exactly the code that reads this field. If it is built on `positional`/`impulse`, FA-5 will fail with everything green, and the temptation will be to retune `physics_grip_normal_force_ratio` — the one thing the owner forbade. The seam must be fixed *before* motors and hinges are added, not after the failure.

---

## 4. F23 [MAJOR] — one field carries two incompatible meanings, and neither is a load

`normal_force_last_tick` is written by `_response` (a *measured reaction artefact*) and read at the top of the same function (an *applied load*). The caller's injected value is overwritten at line 152 on every tick.

The agent's own trace shows the field is not a load at all (`PROGRESS.md:311–315, 328`):

> `prior17.36 … each measured next reaction 18.36`
> `prior17.36, 21.7, 43.4 => vx0/griptrue. Each fixture measures new reaction 18.36.`

**The measured "normal force" is 18.36 N for every injected prior — 8.68, 17.36, 21.7, 43.4 alike.** A quantity that does not change when the load changes by 5× is not carrying load information; 18.36 is the arithmetic of the fixture's own 0.01 WU embed below `contact_slop_wu` (`0.0051 WU / dt² = 18.36`).

Two consequences:

- **False grips.** `18.36 > 17.36`, so a foot that carries nothing can be reported as gripping purely from a 1 cm positional embed. Under gravity the value will oscillate between 0 (penetration inside the 0.02 WU slop band) and a ~8.4 N spike — grip flips tick to tick. FA-5 needs a stable band; this produces a flicker.
- **An API that cannot express the intent.** Even a correct solver has to write the true support force *before* calling `resolve`, and `resolve` then clobbers it. The field must either become a proper input/output pair (`applied_load_n` in, `measured_reaction_n` out) or `resolve` must stop writing it.

**Ask:** rename/split the field, and add a documented contract for who writes it. Do not add a second hidden channel.

---

## 5. F24 [MAJOR] — the 0.40 ratio makes every 3-legged creature unable to stand, and the GDD's first-clear reward is "a third leg"

The gate compares `0.40 × (Σm · |g|) = 0.40 W` against a **per-foot** force. A static stand on *N* grounded feet gives each foot `W/N`:

| N grounded feet | per-foot share | vs 0.40 W | result |
|---|---|---|---|
| 1 (Slug) | 1.00 W | 2.5× over | grips |
| 2 (Hopper, TwinRoller) | 0.50 W | 1.25× over | grips |
| 3 | 0.333 W | **0.83× under** | **all feet slip** |
| 4 | 0.250 W | **0.63× under** | **all feet slip** |

`1/N ≥ 0.40` ⇔ `N ≤ 2.5` ⇔ **N ≤ 2**. The ratio silently encodes "at most two load-bearing feet".

Why this is not hypothetical:

- `CreatureModel.configure` enforces only a *minimum* foot count (`physics_min_feet = 1`); no maximum exists and `core/creature/validator.gd` is a 2-line stub. `physics_part_budget = 10` and `physics_max_bodies = 30` allow many feet.
- All three shipped presets have 1 or 2 feet — which is exactly why CI is green and why this was not caught.
- **GDD line 143 / 502 / 364:** the first-clear reward is a prompt — *"Give it a third leg?"* — opening Build with a socket highlighted. The game's own onboarding hands the player a creature that, under this gate, cannot stand still and therefore cannot sleep (breaking FA-3, its own 600-static-tick gate, and AC-105 "no creature can be made immobile-by-design").
- The derivation document only reasons about 1 and 2 feet (`M1_B01_CONTACT_GEOMETRY_DERIVATION.md:59–68`). It is internally consistent; it just does not cover N ≥ 3, and N ≥ 3 is a core product surface.

**This is an owner decision, not an agent fix.** I am not proposing a new value. The options, with what each does to FA-5's boundary:

- **(a)** Threshold per foot = `0.40 × W / N_grounded` — needs a runtime *N*, and turns "two-foot stance grips" from a boundary into a walkover (two feet would only need 0.2 W each).
- **(b)** Creature-level grip: compare `0.40 W` against the **sum** of grounded foot forces, then apply bias to all grounded feet. All N stand, but "a foot loaded < 40 % slips" stops being a per-foot statement.
- **(c)** Keep the ratio and cap the build: block or warn on N ≥ 3 (contradicts the "third leg" reward; would need the GDD changed).
- **(d)** Keep 0.40 as-is and define the ratio against the *supported* load rather than total weight, i.e. grip iff `foot_force ≥ 0.40 × (W/N)` with N from the contact set — mathematically (a), but framed as the honest reading of "share".

Nothing should be retuned until the owner picks. F22/F23 must be fixed first regardless, because every option above needs a real support-force number to compare.

---

## 6. F25 [MINOR] — gravity never reaches a capsule, so the gate's denominator has no independent consumer

`physics_gravity_wu_s2 = -28.0` is integrated **only** inside `PointLinkSolver.fixed_step` (`solver.gd:172`), which operates on `SimBody` + `DistanceConstraint` and has no terrain. `CapsuleContact` reads gravity **only** to build the threshold (`capsule_contact.gd:92`); it never applies it. So today the number `43.4` exists in exactly one place: as a divisor the contact code writes for itself.

That is the structural reason F22 was invisible: there is no second, independent computation of "the weight this foot actually carries" anywhere in the codebase to disagree with the gate. When the coupling increment lands, assert the two against each other on the same tick (Σ of per-foot support forces ≈ `Σm·|g|` within a stated tolerance) — that single invariant is worth more than any number of unit cases.

---

## 7. What is genuinely good here (keep it)

1. **`export_presets.cfg` + `tests/inspect_android.py`** — production JSON is required to be **byte-identical** to the repo copies in `assetPackInstallTime/assets/` (AAB) *and* `assets/` (APK), with a negative test for missing and modified files. That closes the F7-class "data silently absent from the shipped package" hole properly.
2. **D-10 on production definitions**, not fixtures: `test_contacts.gd:48` uses `model.d10_pairs()` from the real presets, and line 74 guards `distance_two > 0` so the check cannot pass vacuously; line 88 proves it rejects an oversized head.
3. **Every claim is scoped in the artifact itself** — `run_m1_contacts.sh` prints "controlled loads are NOT whole-creature FA-5 evidence", the CI annotation prints `M1 contact scope: controlled component loads only`, and the matrix rows for FA-3/4/5/6 still read `NOT RUN`. Nothing was dressed up.
4. **Zero tuning drift**, with the constants pinned by an exact Decimal table. That is the correct answer to "do not invent thresholds".
5. **`SdfGrid.configure` is atomic and rejects `rows.size() < 2`**, non-finite samples, ragged widths, and a tuning/cell mismatch — plus "no outside-grid fallback", which is exactly the right failure mode.
6. **F20's prose escape hatch is real**: `FA claim outside guarded gate table` catches text outside the pipe table, which was the R7 hole.

---

## 8. Guardrails for the next increment (unchanged, restated because it is now the live risk)

- Fix F22/F23 **before** motors, hinges and gait. A coupled creature on a zero-load force channel cannot stand; discovering that after coupling will look like a tuning problem and will invite a retune.
- Do not touch `physics_grip_normal_force_ratio`, `physics_grip_normal_force_floor`, `physics_foot_grip_bias`, `physics_static_slip_wu_s`, any collision radius, `physics_d10_bend_margin_wu`, or the mass table. If a number must change, stop and ask with the measured trace.
- FA-5 stays `NOT RUN` until a coupled whole-creature stance and gait actually run. A component suite that injects the load is not FA-5, no matter how many checks it has.
- FA-6 stays `NOT RUN`; do not build a tutorial scenario to chase 6–8 successes before the creature can stand.
- Still no M2, no camera, no product screens, no captures.
- The boundary sentence must survive every summary: **208 component checks ≠ creature determinism**, and **0 complete-creature determinism attempts so far**.

---

## 9. Paste-ready message for the coding agent

> **R8 verdict: F20 and F21 are closed. Part 3 is accepted as components. Two blockers before you couple anything.**
>
> Verified by me, not taken on trust: F20's guard rejects all four of my fake FA claims (FA-6 analytic, FA-5 PASS, prose `FA-6: PASS (8/10)`, FA-2 analytic without citation) and the real matrix still exits 0. F21's tolerance is float-noise only — `14.999999999999998` accepted, `14.5` / `15.0−2e-9` / `NAN` rejected. Tuning diff over the whole window is empty; `0.40/5.0/1.4/0.15` and the radii are pinned by exact Decimals. The AAB/APK byte-exact preset check and the production-preset D-10 guard with its non-vacuity assert are good work — keep both.
>
> **F22 [MAJOR] — the grip gate reads a load nothing produces.** `normal_force_last_tick` comes from `maxf(positional, impulse)` (capsule_contact.gd:152), and both terms are this one capsule's own penetration and momentum change: `correction / dt²` with `denominator = v²/m_a + u²/m_b`, plus `bounce / dt`. No parent, no hinge reaction, no gravity share. At rest (`distance = radius − slop`) the value is exactly 0, so a settled foot never grips. The gate's 17.36 N is `0.40 × 1.55 × 28`, a whole-creature share, while the foot's own mass can contribute at most `0.30 × 28 = 8.4 N` — 2.07× short. Today the only code that ever sets a qualifying value is `tests/sim/test_contacts.gd:184`. Your comment and `run_m1_contacts.sh` label that honestly, so this is not a claims problem; it is that `CapsuleContact` has terrain without gravity/constraints and `PointLinkSolver` has gravity/constraints without terrain, and the shipped code has no path between them.
>
> **F23 [MAJOR] — the field means two things, neither of them load.** Your own trace says it: prior 8.68, 17.36, 21.7, 43.4 all measure the same `18.36`. A quantity that ignores a 5× load change is the fixture's 0.01 WU embed, not force. Note `18.36 > 17.36`: that is a false grip from a positional artefact, and under gravity you will get 0 inside the 0.02 slop band and a ~8.4 N spike outside it — grip flickering tick to tick. Split the field into a documented input (`applied_load_n`) and output (`measured_reaction_n`), and stop `_response` from clobbering the input.
>
> **F24 [MAJOR] — 0.40 W per foot means N ≤ 2.** A static stand shares `W/N` per foot; 3 feet = 0.333 W < 0.40 W, 4 feet = 0.25 W. Everything slips, so a 3-legged creature can neither stand nor sleep — and GDD line 143 makes *"Give it a third leg?"* the first-clear reward. `physics_min_feet = 1`, no maximum, `validator.gd` is a 2-line stub, part budget 10. This is an owner decision, not yours: do not retune the ratio. Options on the table are per-foot share `0.40 W / N_grounded`, creature-level sum, or capping the build — say which you think fits FA-5 and wait.
>
> **F25 [MINOR]** — gravity only reaches `PointLinkSolver`; `CapsuleContact` uses `-28.0` solely to build the threshold. So nothing independently computes the load the gate assumes. When you couple, assert `Σ per-foot support ≈ Σm·|g|` on the same tick; that invariant is the real test.
>
> **Order for the next commit:** fix the force channel → couple one Slug (3 parts) to a floor with gravity and hinges → print, for 600 static ticks, per-foot support force, `Σ` vs `43.4`, grounded/gripping flags, and sleep state → only then FA-5 as a band, then Hopper/TwinRoller two-foot stance. Keep FA-3/4/5/6 `NOT RUN` in the matrix until those traces exist. No M2, no camera, no captures, no retuning.
>
> Keep saying the boundary out loud: 208 component checks ≠ determinism, complete-creature determinism attempts still 0.
