# M1 — R9 review: force-channel split and frozen-N gate @ `0304bad`

**Target:** PR #3 head `0304bad` (draft, OPEN). Commits in this window: `e26a1d6` (split + gate), `0304bad` (next-tick touchdown / continuation proofs).
**CI:** `40686840877` and `40686840785` green on `0304bad` (plus two push duplicates `40686831357` / `40686831280`).
**Reviewer branch:** `arena/5b72e4ab-clamber` @ `eb90bc6` → this file.

---

## 1. Verdict

**Step 1 is ACCEPTED, exactly as scoped.** The F24 rule is implemented as approved, the force channels are genuinely separated, and — the part that matters most — nothing in production invents a load. F22 / F25 remain correctly OPEN, FA-3/4/5/6 remain `NOT RUN`, and the agent's own summary says so.

| Claim | Status |
|---|---|
| `applied_load_n` never overwritten by the response | **verified** |
| `max(positional, impulse)` removed as a load estimate | **verified** |
| Three channels: applied load / measured impulse / positional cleanup | **verified** |
| `T = max(5.0, 0.40·W/N)`, `N = 0` disables grip | **verified** |
| N frozen before any per-body resolve, no stored field | **verified** |
| Restore-and-continue byte equality | **verified by test content** (CI-run, not by me — no Godot binary here) |
| Owner addendum + FA-5 row in the same commit, original 281 lines intact | **verified by sha256** |
| `0.723` not rounded up | **verified in code and test** |
| Tuning / radii / bias / slip unchanged | **verified** (`git diff 0e34a5a 0304bad -- core/tuning.*` empty) |
| No M2, camera, product files | **verified** |
| F22 / F25 closed | **correctly NOT claimed** — still open |

---

## 2. What I checked independently

- PR head and branch both `0304bad`; PR still **draft**; `e26a1d6` + `0304bad` are the only new commits over `0e34a5a`.
- CI annotations on `0304bad`: `M1 contact primitives: 237 checks, 0 failures`, `M1 owner geometry: 128 checks, 0 failures`, `FA-1/2/7 PASS (analytic only)`, `M1 feel runtime: FA-3/4/5/6 NOT RUN`, `M1 contact scope: controlled component loads only`, `M0: 504 checks, 0 failures`, Android line still says physical install / frame timing **NOT measured**.
- Local Python: `test_review_checks` 19, `test_owner_geometry_source` 5, `test_static` 6, `test_android_inspection` 8 = **38**, all pass. `python3 scripts/check_m1_matrix.py` exit 0. `scripts/review_static.py` clean (51 files).
- `grep -rn 'applied_load_n' core/` → **exactly one hit**, the consumer at `capsule_contact.gd:113`. There is no writer anywhere in `core/`. That is the strongest possible evidence for "no injected qualifying loads in production": the field is a hole waiting for a real producer, not a number someone filled in.
- Gate is literally the approved rule: floor first, then `ratio * (creature_mass * abs(g)) / grounded_feet_previous`, `may_grip` additionally requires `N > 0`, `kind == "foot"`, `lowest`, and an actual contact sample in the loop (so an airborne foot with a stale qualifying load still cannot grip).
- `CapsuleBody` now carries `applied_load_n` / `measured_reaction_n` / `positional_cleanup_n`; `is_valid` and `restore` validate all three as finite and `>= 0`; `restore` still type-checks `grounded`/`gripping` as `bool` and **preserves `SimBody` endpoint identity**, which is what will let distance constraints stay bound when the solver arrives.
- `resolve_tick` stages every body into a working copy, counts `kind == "foot" and grounded` from the **pre-resolve snapshots**, passes that single frozen count to every `resolve`, and only publishes if all bodies succeeded. Order independence is structural, not incidental.
- Tests are real, not mirrors: `N0` disables grip with a **qualifying** 100 N input; next tick `N2` gives 8.68 and 10 N grips; lift-off keeps the frozen `N2`; the following tick `N1` doubles the bar and 10 N stops gripping; touchdown uses the *old* `N1` for both feet regardless of order; restore-and-continue compares `var_to_bytes(...)` of full snapshots; and a pure positional embed with `applied_load_n = 0` produces `positional_cleanup_n > 0`, `measured_reaction_n == 0`, `gripping == false`.
- `tests/run_m1_contacts.sh` floor moved 208 → **237**, still requires exactly 4 controlled-foot traces, still prints "controlled loads are NOT whole-creature FA-5 evidence".
- Docs: original derivation 281 lines hash to `6453508be7cb808f643544ec3f3fdbd6560840876fc070511f4b5f50065dbc5e` **byte-identical**; the `## Owner addendum` is hash-pinned separately in the geometry test; `DECISIONS.md` M1-D06 records the owner approval, both rejected alternatives, and states in capitals that **no producer of coupled applied load is claimed by this increment**.
- The new Decimal test pins the four thresholds (`17.36`, `8.68`, `17.36/3`, `5.0`), the floor-binds-at-N≥4 arithmetic, and asserts `0.723 < 43.4/60` — i.e. it would fail if someone rounded the ceiling up.

CI's own controlled trace now reads `applied_load_n=43.39999999999999858 threshold=17.35999999999999943 grip=true measured_impulse_force=18.36`. That is the honest picture: grip came from the injected input, and 18.36 is labelled impulse, not load.

---

## 3. Findings — all forward-looking, none blocking step 1

### F26 [MAJOR for step 2] — the action/reaction cross-check exists and is currently unused

Right now the only validation of the future load producer would be the producer's own sum. That is exactly the F22 failure mode one level up. A terrain-side check *is* available and costs nothing:

At steady state a grounded foot acquires `g·dt` of downward velocity each tick and `_response` cancels it through the `bounce` term. With `measured_reaction_n = impulse / dt`, that yields **`≈ m_foot·g` per foot = 8.4 N** for a Slug foot, so **`Σ measured_reaction_n ≈ 43.4 N`** over grounded feet. It is computed from completely different code (terrain sampling + velocity) than the solver's hinge arithmetic.

Two cautions the agent must not get wrong:

- The current test "slop-rest reaction zero" is true only for a fixture with **no gravity integration**. It must not be read as "the reaction is always zero" — that reading would leave the load producer unvalidated.
- Do not expect double counting: `denominator = v²/m_a + u²/m_b` weights endpoints, so a two-endpoint contact sums to `m·|v|/dt`, not `2·m·|v|/dt`. If the log shows exactly `2×`, that is a sampling defect to report, not a factor to divide out.

**Requirement for step 3:** log `Σ applied_load_n`, `Σ measured_reaction_n` and `Σ positional_cleanup_n` separately, every tick. Acceptance needs **both** force sums within `0.723 N` of `43.4` over the last 300 ticks, and each other. If they disagree, the producer is wrong — not the tolerance.

### F27 [MINOR] — `resolve()` still takes a caller-supplied N with no cross-check

`CapsuleContact.resolve(..., grounded_feet_previous, ...)` is public and accepts any `N >= 0`. Passing `1` while three feet are grounded silently grades the foot against 17.36 N instead of 5.79 N; passing `4` when one is grounded halves the bar. Nothing rejects or documents it. Make `resolve` internal/`_`-prefixed for the coupled path, or document it as fixture-only in the docstring, so the batch entry point is the only supported door.

### F28 [MINOR] — `lowest` and material arrays are caller-supplied and unchecked

`resolve_tick` validates lengths only. Two feet flagged `lowest = true` while one is 2 WU in the air is accepted. Today that is a fixture convenience; in the coupled step `lowest` becomes a real computation, and if the solver fills it by index the grip eligibility becomes arbitrary. Require a documented rule ("height within X of the creature's lowest contact") plus one unequal-height fixture, before the coupling commit claims anything about stance.

### F29 [NOTE] — the 1-tick N lag is deliberate; make it visible, do not tune it away

A foot that landed this tick is not counted; a foot that lifted still is. That is the price of freezing, and it is the right price. Consequence during single support: with a stale `N = 2` the loaded foot is graded at `0.2 W` instead of `0.4 W`. Print `previous_grounded_feet` on every line of the 600-tick log so this is visible, and do not let an unexpected grip be "fixed" by touching `0.40`.

---

## 4. Boundary that must not move

- **Step 1 complete; steps 2–4 not started.** No coupled solver, no gravity→hinge→foot→terrain load producer, no Slug trace.
- **F22 and F25 are open.** 237 component checks are **not** determinism; complete-creature determinism attempts remain **0**.
- FA-3 / FA-4 / FA-5 / FA-6, AC-201/202/204, A9 and every capture stay `NOT RUN`.
- No retune, no hysteresis/grace/decay, no M2, no camera, no captures.
