# M1 — R13 review: spawn equilibrium confirmed, and one of my own claims retracted @ `d36c89f`

**Target:** PR #3 head `d36c89f` (draft, OPEN). Commits over R12's `c3b7b01`: `8463240` (spawn sensitivity), `0d9f2e4` (equilibrium + attribution records), `d36c89f` (F40 wording).
**CI:** `40711579496` — M0 green, **M1 red for F30 only**; the spawn step passes on its own terms (`status: OBSERVED`, exit 0 unless a case is missing/mismatched).
**Reviewer branch:** `arena/5b72e4ab-clamber` → this file.

---

## 1. Verdict

**The spawn experiment is the strongest single result in M1 so far, and the agent has caught a real error in my R12 review.** I checked their correction and it holds: my F39 attribution was wrong and I withdraw it.

| Item | Status |
|---|---|
| F38 spawn sensitivity | **CLOSED — shared fixed point confirmed** |
| Agent's correction to F39 attribution | **CORRECT — my claim retracted in §3** |
| F40 pixel excursion, correctly scoped | **accepted** |
| 78 Python tests, 40 of them load-trace | **verified locally** |
| Tuning / pose / radii / model / solver | **untouched** (`git diff c3b7b01 d36c89f -- core/ data/` empty) |
| **F41 [MAJOR]** — constant residual COM tangential velocity vs a 341× larger static-slip threshold | new |
| **F42 [MINOR]** — FA-3's "zero sleep-breaking contacts" is unsatisfiable as worded | new |
| F30 pose / FA-4 "asleep" | still owner decisions; only red |
| FA-3/4/5/6, captures, determinism | `NOT RUN` / **0** |

---

## 2. F38 — closed, and stronger than reported

The three spawns converge to the same `P_y` with a **spread of `2.7755575615628914e-17`** (one double-precision step at this magnitude) despite different transient lengths — envelope entry at ticks 66 / 70 / 73:

| Spawn Y | `P_y` final (N·s) | last-300 range | entry tick |
|---:|---|---:|---:|
| 0.33 | 0.16342237029480583 | `[0.1634223702948058, 0.16342237029480586]` | 66 |
| 0.53 | 0.16342237029480583 | identical | 70 |
| 0.73 | 0.16342237029480586 | identical | 73 |

Falling from 0.20 WU higher changes the impact energy substantially and changes *nothing* about the converged value. That is not "a plateau observed three times"; it is evidence that the discrete map has a **fixed point independent of initial condition**. Combined with R12's iteration sweep (converging to a non-zero limit, not to the initial transient), F38 is answered: the 0.105 WU/s COM rise is a property of the model, and no amount of iterations, spawn placement or run length will remove it. The agent's phrasing — "shared observed nonzero equilibrium for these starts… not a global-attractor proof" — is exactly the right amount of claim.

The report also refuses to be a rubber stamp: it rejects a case on `position_iterations != 6`, on missing/mixed spawn metadata, on a raw root that does not match the requested spawn, and on any initial motion. A report that could not fail would have been worthless here.

---

## 3. F39 — I was wrong; the agent's correction is verified

My R12 claim was that the lateral creep is "displacement without velocity", because a single endpoint's net Δx (`−7.175e-06` WU) was ~18× its own `vx·dt` (`−4.03e-07` WU). **That comparison is invalid**, and the agent said so. Distance and hinge rows apply equal/opposite corrections weighted by inverse mass, so their contribution to the mass-weighted COM is *identically* zero, while they freely move individual endpoints in opposite directions. A per-endpoint mismatch therefore says nothing about COM injection.

I recomputed COM X from the trace's own integration phases:

```
0.77·(−3.946356745415658e-07 + 0)/2 = −1.5193e-07
0.48·(−4.5706692652358605e-05 + 0)/2 = −1.0970e-05
0.30·(0.0 + 0.0)/2                    =  0
                                 sum  = −1.1117e-05  ÷1.55 = −7.175187723396496e-06
```

against the reported `net_com_x_wu = −7.175187723421744e-06` — agreement to 11 digits. Their phase ledger says the same independently: `integration −7.175187723396494e-06`, `distance −3.6e-17`, `hinge +1.1e-17`, `contact 0.0`, plus `predictor_from_raw_start_vx_wu = −7.175187723393486e-06` reconstructed from raw start velocities rather than from the completed ones.

**So: the drift is integrated from velocity, it is not position-level injection, and friction is not structurally blind to it.** My F39 as written was wrong on both counts. The soak exposure numbers (0.65 px / 3.9 px / 10.8 px / 19.4 px) stand as arithmetic; the attribution does not.

This is the second time in this project the agent has corrected me with a computation instead of deferring, and it is the behaviour I most want to keep. Note it in DECISIONS as a reviewer correction, not as an agent error.

---

## 4. F41 [MAJOR] — the residual is velocity that a 341× larger threshold fails to remove

The corrected picture leaves a sharper question than my original one.

- COM X displacement per tick: `−7.175187723421744e-06` WU → COM `vx ≈ −4.31e-04 WU/s`.
- The completed-velocity check gives `−7.32e-06` WU/tick, so the velocity at the end of the tick is still of that order (`−4.39e-04 WU/s`).
- `physics_static_slip_wu_s = 0.15` WU/s is **341× larger** than that. By the written rule, `absf(tangent) < 0.15` should set `retained = 0` and erase the tangential velocity at every contact, every tick.
- It does not. The drift is **constant to `1e-16` across 300 ticks** (`steady_net_delta_ranges_wu` X: `[−7.175187723473808e-06, −7.175187723362786e-06]`), i.e. something re-creates exactly that velocity each tick, and nothing integrates it away.

The most likely mechanism, and the one to confirm rather than assume: the contact solves **one sample per body**, and `retained = 0` zeroes the *sampled point's* interpolated tangential velocity `v·a.vx + u·b.vx`, not the body's rigid velocity. With a single sample, only one linear combination is constrained; the rest of the tangential velocity survives in the endpoints, and its COM average is the residual. That is consistent with the observed per-endpoint X velocities (`head a −2.4e-05`, `motor a −2.8e-03`, `motor b 0`, `foot 0`, `foot b 0`) — none of which is the COM value, and none of which is zero after contact.

What I want measured, no behaviour change:

1. per contact sample per tick: `u`, the interpolated tangent **before** and **after** the response, `retained`, and each endpoint's `vx` before/after. If endpoint `vx` survives while the sample tangent is zeroed, the one-sample explanation is confirmed on evidence;
2. whether the residual COM `vx` changes when a body has more than one contact sample (head and motor bellies are long and may already produce two, the foot may not) — that also tells us whether a contact sampling change, rather than a friction change, is the lever;
3. the residual's sensitivity to `physics_static_slip_wu_s` as a **diagnostic sweep only** (e.g. 0.15 vs 1.5), reported, never adopted — if a 10× threshold does not change the drift, static slip is provably not the mechanism and the single-sample story is the only candidate left.

**Do not fix it, and do not raise or lower `static_slip`.** Two reasons: it is 0.65 px over FA-3's window, so it is not today's blocker; and **it will change materially when F30 is fixed**, because the contact will be a 0.05 WU foot pad instead of a 0.095 WU motor belly — different sample geometry entirely. Re-measure after the pose commit and compare; a number that moves then is diagnostic, a number that stays identical is suspicious.

---

## 5. F42 [MINOR, but it will bite FA-3] — "zero sleep-breaking contacts" cannot be satisfied as written

The steady state has **a contact every tick, forever** — that is precisely what makes the plateau what it is (contact resupplies the 0.003268 N·s that damping removes). FA-3 as recorded reads "600 static ticks, **zero sleep-breaking contacts**". Read literally, no settled creature can ever pass, because a settled creature is in permanent contact.

This needs one clarifying sentence from the owner, and it belongs in the same sitting as the "asleep" decision:

- if "sleep-breaking contact" means **a new or impacting** contact (a contact that changes the sleep eligibility, e.g. a body that was not grounded becoming grounded, or an impact above some impulse), then the present state is not automatically a failure — it is just unmeasured; or
- if it means **any contact at all** while asleep, FA-3 is unsatisfiable and the criterion itself needs rewriting.

While waiting, log per tick: the set of grounded bodies, new-grounded transitions, and per-contact impulse — the three quantities any of those readings would need. That is cheap, and it makes the eventual definition a one-line filter rather than a new run.

---

## 6. Bounds that did not move

- `core/`, `data/`, pose, radii, `tuning.tres`, damping, contact code: **no change** in this window.
- 78 Python tests reproduce locally (19 + 5 + 40 + 6 + 8), all pass; 72 previously accepted tests retained.
- M1 red **only** for `foot_load_path_exercised` (F30). Grip never engaged; all-600 peak applied 14.80726 N against the 17.36 N gate.
- FA-3 / FA-4 / FA-5 / FA-6, AC-201/202/204, A9, §10.6, captures: `NOT RUN`. Complete-creature determinism attempts: **0**.

---

## 7. Two owner decisions still gate everything

1. **F30 pose** — (A) feet become their subtree's lowest contact, (B) radius change (rejected: owner-pinned, FA-1/FA-7 derive from them), (C) accept the sprawl and re-target the static criterion.
2. **"Asleep"** — positional stillness (Y positions already settle to `1e-16`, bottoms repeat), a velocity threshold above the 0.105 WU/s floor (a new owner-authored constant), or a model change (F38 proves no iteration/spawn/length choice removes the floor). F42's clarification rides with this.

Nothing else on the critical path can move until those two are answered.
