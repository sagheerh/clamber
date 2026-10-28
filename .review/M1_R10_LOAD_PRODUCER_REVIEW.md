# M1 — R10 review: coupled load producer @ `1f2c19f` (failing force window)

**Target:** PR #3 head `1f2c19f` (draft, OPEN). New commits over R9's `0304bad`: `206d205` (coupling + diagnostics), `d5ef49a` (routing exposure), `1f2c19f` (records).
**CI:** `40691112063` — M0 green, **M1 point/link job RED by design**, static-subset job green.
**Reviewer branch:** `arena/5b72e4ab-clamber` → this file.

---

## 1. Verdict

**The failing number is real, was reported correctly, and must stay red. But it is not the failure the agent thinks it is.**

- **F22, F23, F25 are now CLOSED.** The missing load path from R8 exists, is real physics, and conserves. Three independent numbers prove it (§2).
- **The Slug foot really does carry only ~9.7 N of 43.4 N.** The agent is right to refuse to call that a pass.
- **The cause is not the force channel and not missing angular limits.** It is **rest-pose geometry, and it affects all three shipped presets** (§3, F30). The agent's stated next step ("add angular/attachment mechanics, rerun") **will not fix it** and will burn another round.

I also have to correct **my own R9 wording**: I asked for `Σ per-foot support ≈ 43.4`. That is only the right invariant when the foot is the *sole* contact. The correct invariant is `Σ over all grounded contacts ≈ 43.4` — and that number is already **43.596 N**, inside the 0.723 ceiling. The agent kept the stricter reading and reported failure rather than quietly re-scoping it, which is exactly the right instinct; the criterion, not the physics, is what needs fixing.

---

## 2. What the three independent numbers establish

| Evidence | Value | What it proves |
|---|---|---|
| Isolated foot, 30 ticks, `applied_load_n == 0` asserted | **8.40000000000000036 N** | Reaction is measured, not injected; two endpoints, no double count |
| Sum of **all** terrain reactions | **43.59610684435376 N** | Conservation holds: 43.4 N weight, +0.196 N (0.45 %) |
| Applied vs measured (last 300 ticks) | **0.01793 N** | Producer and contact response are two computations that agree |
| `core/` writers of `applied_load_n` | **1** (`coupled_load_probe.gd:221`) | No injected qualifying load, no prescribed share |

The producer itself is sound and is the honest thing R8 asked for:

```gdscript
external_y = body.mass * g * dt + hinge_y[index]
applied_load_n = maxf(0, -(external_x*nx + external_y*ny) / dt)
```

Per-body gravity impulse plus the *measured* equal/opposite hinge impulse, projected on the surface normal. Positional correction is explicitly excluded. Velocity impulses are measured before endpoints are mutated. That is the real load path, and the physics is right.

**So: F22 CLOSED** (a producer exists), **F23 CLOSED** (three channels, input untouched — verified again by the airborne/stale-load case), **F25 CLOSED** (terrain-side reaction is now an independent computation).

---

## 3. F30 [MAJOR] — in every shipped preset the feet are not the lowest bodies

This is the actual cause, and I computed it from the authored presets plus the owner-pinned collision radii, using the project's own attachment rule (`create_bodies`: a child starts at its parent's `b` endpoint, then extends along its own axis).

| Preset | Lowest body | Second | Feet | Gap |
|---|---|---|---|---|
| **Slug** | motor `−0.395` | foot `−0.350` | 1 | **motor 0.045 WU below the foot** |
| **Hopper** | limb `−0.765` ×2 | **feet `−0.750` ×2** | 2 | **limb tips 0.015 WU below both feet** |
| **TwinRoller** | motor `−0.695` | foot `−0.650` | 2 | motor 0.045 below one foot; the other foot sits at `−0.050`, **0.645 WU in the air** |

Mechanism, uniform across all three: a foot is authored with a **sideways** axis (`RIGHT`/`LEFT`) and attaches at its parent's far endpoint. Its pad therefore sits at `parent_end_y − foot_radius`, while the parent's own belly sits at `parent_end_y − parent_radius`. Since `foot_collision_radius = 0.050` is smaller than *every* other collision radius (limb 0.065, passive 0.085, motor 0.095, head 0.100), **the foot pad is always above its parent's belly.** Feet can never be the ground contact as authored.

Consequences, all of them product-level:

1. **FA-5 cannot pass for any shipped creature** — not because the gate is wrong, but because no shipped foot is on the ground. The Slug's 9.695 N is *exactly* what this geometry predicts: its own weight 8.4 N plus a 1.28 N hinge pull, i.e. the foot hangs rather than bears.
2. **Hopper's "two-foot stance" would measure limb tips.** A limb is not grip-eligible (`may_grip` requires `kind == "foot"`), so the `×1.4` grip bias never fires and the two-foot branch of FA-5 is unreachable.
3. **TwinRoller's second foot is 0.645 WU above the ground** and still counts toward `N` the moment it touches anything — a foot that is a tail.
4. **The derivation's premise is falsified in the same way for all three.** `M1_B01` line 47: "A single-foot stand transmits 100 % of 43.4 ≈ 43." That sentence assumes the foot is the lowest contact. It is not, in any preset.
5. **Angular limits will not fix it.** The motor's hinge is at its top and the foot hangs from its bottom, so with no actuator the lowest-energy pose is motor belly on the ground. Limits forbid poses; they do not supply the torque that would hold a 2.5 kg-ish body up on a 0.05 WU pad. Adding limits, then rerunning, will reproduce 9.7 N and cost a round.

**This needs an owner decision, not an agent fix** — it changes the shipped creatures, and every option touches either a product asset or a derived constant:

- **(A) Pose rule (recommended):** a foot's pad must be the lowest contact surface of its own subtree, i.e. feet hang below their parent (authored axis, not a new radius). Applying it gives: Slug foot `−0.600` vs motor `−0.395` (foot **0.205 below**, load path through the foot); analogous for Hopper/TwinRoller. Touches no radius, no mass, no gate constant, no D-10 rule. It does change the shipped Slug's silhouette, which is a product decision.
- **(B) Radius change:** make the foot radius ≥ its parent's — rejected, radii are owner-pinned and FA-1/FA-7 depend on them.
- **(C) Accept the sprawl:** the Slug is limp by design (GDD `:140`, motor contracts → lurch), so at rest it need not bear weight on the foot. This is defensible for the Slug, but it leaves Hopper/TwinRoller unable to demonstrate the two-foot grip branch, and it means the grip bias never applies to any shipped creature until motors exist.

My recommendation is **(A) for the three presets** plus **(C) for the static Slug criterion**: do not require the Slug at rest to carry weight on its foot (it cannot, and GDD does not ask it to); require conservation instead, and collect foot-load evidence during motor actuation in the next increment.

---

## 4. Smaller findings

**F31 [MINOR]** — the systematic `+0.196 N` (0.45 %) on the all-terrain sum is stable to 1e-14 across the whole window, so it is a bias, not creep. It is inside the ceiling, but a conservation check that is not zero usually means a term is counted one extra or one missing time. Explain it before the number is treated as proof of conservation.

**F32 [MINOR]** — the trace logs penetration, loads, flags and N, but **no positions or angles per body**. That is why this round needed a multi-hour detour to discover a 0.045 WU pose offset that a per-tick bottom-height column would have shown in the first row. Add `bottom_wu` (and optionally the two endpoint positions) per body per tick.

**F33 [MINOR]** — "No grip toggles occurred" is trivially true: the foot peaked at 9.695 N against a 17.36 N bar, so grip **never engaged at all**. Report it as "grip never engaged" — "no toggles" reads like stability.

**F34 [NOTE]** — the failing check is correctly not waived: `tests/load_trace_report.py` exits 1, `run_m1_load_probe.sh` has no bypass flag, and the matrix rows were re-worded rather than upgraded. That is the right behaviour and it is why this round is trustworthy.

---

## 5. What to do next

1. **Do not add angular limits yet.** They cannot fix F30 and will reproduce the failure.
2. **Get the F30/A decision** (pose rule for the three presets, or accept sprawl and re-target).
3. **Re-scope F26 in writing** to `Σ all grounded contacts ≈ 43.4`, keep the foot's own share reported separately for FA-5. Pass condition for the static Slug = conservation, not foot-carries-all.
4. Then: pose fix (if approved) → re-prove *analytically* that feet are the lowest contact of each preset before any 600-tick run (a per-part bottom table is a 10-line CI check, cheaper than a trace) → rerun the unchanged diagnostic → then motors, then FA-5's four branches.
5. FA-3/4/5/6 stay `NOT RUN`. Determinism attempts remain **0**.

---

## 6. Boundary (unchanged)

Producer exists and conserves; the creature never stood on a foot, because no shipped foot is below its own parent. 80 load-path components, 237 contact, 381 math, 128 geometry, 45 Python are **components**, not determinism. Complete-creature determinism attempts remain **0**.
