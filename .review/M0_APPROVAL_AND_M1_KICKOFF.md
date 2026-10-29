# M0 approval (human owner override) + M1 kickoff instruction

**Date:** 2026-10-28  
**Owner decision:** The GDD owner installed and opened the M0 debug build on a physical Android device and reports that it boots to the expected solid navy screen. The owner asks for M0 to be **approved / marked complete** and for **M1 to start**.

> Important: the owner's verbal verification is **not E4 evidence** under `CLAMBER_REVIEW_AGENT.md:54`. No screenshot, `adb` log, lifecycle record, safe-area note, or frame-time capture was attached. Therefore this is an **explicit human/GDD-owner override**, not an independent reviewer's evidence-based approval. Record that honestly.

---

## 1. Was M0 only up to this? — Yes.

GDD §16.1 / `docs/GDD.md:1763` defines M0 as:

> "Project skeleton, tuning resource, CI, Android export on device" → deliverable **"APK that boots"**.

The CI-tested branch `arena/f08ed236-clamber` at `ba7179b` delivers:

- pinned Godot 4.7.2 skeleton + `project.godot`;
- solid navy engineering boot surface (`#00192F`), no S00–S16 screens;
- 376 tuning fields in seven groups + `docs/TUNING.md`;
- atomic `SaveStore` with corruption recovery;
- compile-only stubs for solver/creature/run/tower/econ;
- platform no-op services, safe-area + lifecycle hooks;
- headless test suite (`475 checks, 0 failures` on exact 4.7.2);
- Android debug AAB + bundletool/manifest/ABI/16 KB checks in CI;
- physical install + launch reported by the owner.

So a dark navy screen with "nothing else" is the intended M0 result, not a crash. M0 contained no gameplay, no logo screen, no menu, and no mockup implementation.

---

## 2. Decision entry to add to `DECISIONS.md`

```markdown
## M0-D07 — Human owner override closes M0 device gate

On 2026-10-28 the GDD owner installed and launched the M0 debug build on a
physical Android device and reported the expected solid navy boot surface with
no UI or gameplay. No screenshot, adb log, safe-area/lifecycle record, or
frame-time capture was committed. The owner explicitly waives the remaining
E4 device artifacts and the measured 60 fps / P95 frame-time criterion for M0,
and marks M0 APPROVED / COMPLETE.

This waiver applies only to M0. It does not change GDD §16.1, does not waive
any M1–M9 acceptance criterion, and must not be cited as evidence that 60 fps
was measured. The camera zoom conflict M0-B02 (0.75 §2.3 / 0.72 §4.8) remains
open and must be resolved by the owner before camera implementation in M2.
M0-B03's unspecified thresholds also remain open for their milestones.
```

Also update:

- `PROGRESS.md`: change current milestone to **"M0 — APPROVED / COMPLETE (owner override); M1 — NOT STARTED / READY"**. Keep the old M0 evidence table but add the override date.
- `docs/validation/M0.md`: add an **"Owner device verification (2026-10-28)"** section. State clearly: physical install + launch + navy display reported by owner; **no frame-time artifact**; status changed to complete by M0-D07. Also fix the stale run/artifact references from R2 F3 (final run `40625642314`, commit `ba7179b`, artifact `12789073777`, digest `sha256:a45fbe...`).

---

## 3. Minimal M0 closeout before the M1 PR

These are mechanical/documentation tasks, not new M0 features:

1. Add `M0-D07` and update `PROGRESS.md` / `docs/validation/M0.md` as above.
2. Fix `docs/validation/M0.md` run/artifact/digest references (R2 F3).
3. Add `scripts/review_checks.sh` (wrap the existing static/inspector/contract checks) and `.review/m0_ac_matrix.md`, or record an explicit owner waiver for R2 F2. The review pack normally treats a missing AC matrix as a blocker; the owner override covers it, but adding the files is cheap and prevents confusion at M1 review.
4. Open/finalize the M0 PR with verdict `APPROVE — HUMAN OVERRIDE`, or merge the M0 branch if the repository workflow allows. Do not rewrite M0 history or change tuning/save logic.
5. Keep the camera zoom conflict and unspecified thresholds as open human decisions.

Do **not** retroactively claim measured 60 fps. `Engine.max_fps = 60` is a cap, not a measurement.

---

## 4. Paste-ready message to the coding agent

```text
Owner decision (2026-10-28): I installed and opened the M0 debug build on a
physical Android device. It boots to the expected solid navy screen and shows no
UI/gameplay. Since M0's deliverable was only "an APK that boots" (GDD §16.1),
M0 is hereby APPROVED and marked COMPLETE by explicit GDD-owner override.

Be honest in the record: my verbal verification is not an E4 artifact. No
screenshot, adb log, lifecycle/safe-area record, or frame-time capture was
attached. Add a new DECISIONS.md entry M0-D07 saying the remaining device
artifacts and the measured 60 fps / P95 frame-time criterion are waived for M0
only. Do not claim 60 fps was measured; Engine.max_fps = 60 is a cap, not a
measurement. This waiver does not apply to any later milestone.

M0 closeout (mechanical only; no new features, no tuning/save changes):
1. Update PROGRESS.md to "M0 — APPROVED / COMPLETE (owner override); M1 — READY".
2. Update docs/validation/M0.md with an "Owner device verification" section and
   fix the stale evidence links: final run 40625642314, commit ba7179b, artifact
   12789073777, digest sha256:a45fbe10178a99087123f6b87079bd97bad7609f17b44676a255c52bc4557c26.
3. Add scripts/review_checks.sh and .review/m0_ac_matrix.md, or explicitly note
   in M0-D07 that the owner waived those review-pack artifacts for M0.
4. Finalize the M0 PR/merge with verdict APPROVE — HUMAN OVERRIDE. Do not start
   M1 inside the M0 fix commit; land/close M0 first.

Then START M1. Per GDD §16.1 and the review pack PART B:
- Scope: standalone solver + 3 preset creatures + headless determinism/feel
  harness. This is NOT S03 climb, NOT pause/fall screens, NOT build screen.
- Use custom fixed-step PBD/XPBD at 1/60 via an accumulator. No raw frame delta
  in the sim. Inject the RNG seed as a Sim.setup parameter; no global
  randf/randi/randomize. No sin/cos/tan/pow/exp/atan2 in solver step/constraint
  functions. No RigidBody2D/Joint2D/PinJoint2D/DampedSpringJoint2D anywhere.
- Required gates: AC-201 settle/sleep <= 4 s; AC-202 no limb stretch > 0.05 WU
  over 2 min; AC-204 zero NaN in a 200-run soak with log; three presets produce
  three different motions from the same input pattern (10 s capture each);
  solver tick <= 3.0 ms for 30 bodies; full A9 determinism procedure including
  replay 3x, a 2-second stall, two frame conditions, and the mandatory bit-flip
  falsification test (flip one input bit -> different hash). Commit the baseline
  hash and make CI fail if it changes without a DECISIONS.md explanation.
- Keep the exact Godot 4.7.2 pin, no new screens beyond S00–S16, no monetised
  gameplay, no network dependency, and all tuning values from core/tuning.tres.
- Produce .review/m1_ac_matrix.md and open a separate M1 PR. Do not weaken M0
  tests or tuning to make M1 pass.

Still open for me as owner, not for you to invent:
- M0-B02: camera zoom 0.75 (§2.3) vs 0.72 (§4.8). Resolve before M2/camera work;
  M1 does not need it.
- M0-B03: unspecified grip/haptic/generator thresholds. Do not fabricate them.

Confirm when M0-D07 + PROGRESS/validation updates are committed and the M1 PR
scaffold exists. Do not claim M1 gates are met until the real-engine determinism
harness runs in CI.
```

---

## 5. Reviewer note

As the independent reviewer I cannot issue an evidence-based `APPROVE` for M0 because the E4 device artifacts and frame-time capture are missing. The above is a **human-owner override**, which is allowed only because the user explicitly asked to mark M0 complete and proceed. From M1 onward, the normal evidence rules apply again: every DoD item needs a command transcript, a real test, code citation, or artifact.
