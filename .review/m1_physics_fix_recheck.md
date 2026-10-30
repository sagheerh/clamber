# M1 recheck — real execution, rejected candidate, not complete

2026-10-30 · branch `arena/f43f36ab-clamber`

**Outcome: M1 code is still NOT complete. AC-201/AC-202 remain FAILED on the
production implementation; M1 BLOCKED / NOT SIGNED; FA3 uncredited; M2 blocked.**
This recheck fixed a real runner defect, got actual engine evidence, implemented
and executed a test-only coupled physics candidate, and rejected it on measured
failure. It did **not** finish the requested production physics repair.

## 1. Concrete bug fixed

`tests/run_m1_contact_candidate.sh` used standalone `! grep ...` under `set -e`.
Bash exempts inverted commands from errexit: a logged import/compile error with
engine exit0 could proceed, and an error plus passing unit summary could falsely
pass. Reproduced **3 failing cases out of9** before fixing it. Explicit
`if grep ...; then exit 1; fi` now stops each stage correctly.

- Primitive-runner routing: **9/0**.
- New composed-runner routing: **13/0**, including missing/short summaries,
  unexecuted arm, logged errors, nonzero exit preservation and evidence overwrite.
- These tests use a clearly labelled **TEST DOUBLE**, zero real engine ticks.
  They are shell/protocol regressions, not physics evidence.
- Before/after logs: `physics_fix/runner-before-fix.log`,
  `runner-regressions.log`, `composition-runner-regressions.log`.

Fixed in commit `6c1c4878dfbf7ed9bce9bc66a181e6b1f8af90df`.

## 2. Real pinned engine is now available in CI

The old main allocation/billing failures remain historical evidence, but are
**not the current blocker**. No billing operation, credential request, old-branch
copy or merge was used.

| Exact source | Run / job | Actual result |
|---|---|---|
| `6c1c4878dfbf7ed9bce9bc66a181e6b1f8af90df` | [41004935173](https://github.com/sagheerh/clamber/actions/runs/41004935173), job123897579940 | released SHA512 verified, exact4.7.2.stable.official.ed1daf0bf, import/check-only, **31 primitive checks / 0 failures** |
| `36313adee19458995618a860843b078a356975ed` | [41005575775](https://github.com/sagheerh/clamber/actions/runs/41005575775), primitive job123899589732 | same exact-engine primitive gates success |
| same36313ad | composition job123899667855 | semantic compile success; **600 actual Slug ticks; candidate FAILED**; evidence publication success |

Job/annotation JSON is saved under `physics_fix/`. The workflow checks exact
event source SHA and branch and uses explicit opt-in commit markers. A launch
failure would not be a measurement. This candidate did actually execute600 ticks.

## 3. What was implemented and measured

Protocol was frozen **before execution** in
[`physics_fix/coupled_candidate_plan.md`](physics_fix/coupled_candidate_plan.md).

- `tests/physics_fix/capsule_contact_composition.gd`: current-source-derived
  contact fixture, original source hash in header. Keeps original terrain sweep,
  frozen previous-foot N, lowest/load eligibility, material/grip policy,
  transactional batch and aggregate projection guard. Replaces free-endpoint
  contact correction with common translation and coupled rigid COM/angular rows.
- `tests/physics_fix/actuated_contact_composition.gd`: actual actuated rig with
  existing distance/axial-velocity rows placed after hinge/angular/self-contact
  rows **before contact**. Same six position iterations, two distance solves per
  iteration and two velocity passes. No post-contact distance repair.
- `tests/physics_fix/test_contact_composition.gd`: fresh public Sim/clock/sleep
  composition with explicitly substituted test-only awake rows. Real authored
  Slug, original flat floor/material/spawn, seed305419896, released input600.
  No sleep shortcut, epsilon, force controller, mass change or retune.
- Public identity does not encode the test substitution, so this is **not a
  production/reference/replay/restore acceptance run**. On failed public step,
  rollback reconstructs baseline rows; the harness stops immediately, never
  continuing on a secretly restored production implementation.
- Unchanged asleep terrain classification still uses original-contact shadows.

### Actual first gate: Slug, released600

| Measurement | Result | Interpretation |
|---|---:|---|
| completed ticks |600/600| full registered idle horizon, not a zero-tick incident |
| max head-to-mean-foot attitude change from spawn |39.67491255849509°| **FAIL**, original bound15° |
| first attitude violation |tick8, zero-based| early physical collapse, not late sleep bookkeeping |
| first head-grounded tick |11| actual support topology changed |
| net COM from spawn |.5006718410403428WU| within original .90WU; not a posture/sleep pass |
| all-parts-airborne ticks |0| no airborne violation |
| sleeping ticks |0| **FAIL** both original4s deadline and sleep-by600 |
| maximum F52 still count |1| never obtains required30-tick dwell |
| maximum bone error, all bodies |1.1102230246251565e−16WU| IDLE-ONLY observation; not120s AC-202 |
| native maximum penetration |.020000000000000823WU| slop+roundoff; zero violations using `>.02*(1+1e-9)` |

**Candidate REJECTED / NOT ADOPTED.** All three7200-tick length arms—Slug,
Hopper, TwinRoller—remain **NOT RUN**. The first gate failed, so the harness
stopped before them. No later arm, automatic retry or D0/R27/R29 recapture.
No two-minute length verdict is inferred from600 ticks.

### Preserved evidence and independent audit

Source36313ad; evidence-only child `9f77efdb375a9085faeffd1a1432efd344e646fd`.
Folder: `tests/fixtures/m1_contact_composition/36313adee194/`.

- Full600 raw state rows (all3 bodies/endpoints/velocities/flags/load fields,
  angular joint state, sleep/dwell state and constraints), losslessly compressed.
- Spawn/public identity, exact source/engine/code hashes, summary, import/compile/
  engine logs, exit1 and transport index. No Actions artifact-upload prerequisite.
- Raw bytes2,587,542; gzip bytes292,972.
- Raw SHA256 `61effb30f761f90c8dc7627a2034fd6aa055975bf4e961ec88dd7efc1727ed49`.
- Gzip SHA256 `779376a07699a8f11eaebe286c487534a15ca4f3a8e25ec6c7234a96c6c61171`.

Independent Python computation:

```bash
python3 tests/report_contact_composition.py
python3 tests/test_contact_composition_audit.py
```

These commands **do not run physics**. They verify sealed source/transport data,
scan every state/constraint scalar, and independently recompute posture, COM,
geometry, sleep, endpoint residuals and the STOP ledger. Audit tests **12/0**;
NaN in a head endpoint, fabricated sleep/pass, short horizon, wrong source/engine,
modified compressed data and invented7200 arm are rejected. Numerical raw peaks
remain visible: independent flat-plane penetration .020000000000000448WU versus
native interpolated-SDF .020000000000000823WU. Neither is silently rounded down.
Audit output: [`physics_fix/composition-audit-36313ad.json`](physics_fix/composition-audit-36313ad.json).

## 4. What the actual trace reveals—and what it does not

Rigid bones alone are insufficient. In this **candidate**, after contact:

- Maximum hinge endpoint separation: **.06874241313623658WU**.
- Maximum hinge relative endpoint speed: **1.7990887822518324WU/s**.
- Final head/motor hinge relative speed: **.3344416667386175WU/s**;
  motor/foot hinge: **.09601206993057251WU/s**.
- F52 anchored displacement exceeds .001WU on **50 of ticks500–599**; the
  still count never exceeds1. Sleep is correctly refusing ongoing motion.
- Foot candidate sample counts vary **2/3** around an extent/cell boundary.
  This is an observed sampling discontinuity, **not demonstrated proof that
  changing sample count alone would fix posture, hinge residuals or drift**.

Existing point-hinge rows, rigidity rows and terrain contact still do not produce
one consistent completed position/velocity constraint state. Reordering isolated
rows preserved bone extent here but did not solve their coupled compatibility.
This is stronger evidence than an unexecuted primitive, but it is **not a proven
AC-201 production patch**, nor a claim that the production solver has these exact
candidate residual magnitudes. The initial gravity moment remains a static
calculation, not a prediction or a proof that the15° requirement is impossible.

Remaining implementation work: coherent articulated hinge/contact/manifold
position AND velocity response with correct actual force budgets, within existing
iteration/cap/material/sleep policy; then actual rest/release and full-length+
penetration regression. Do not hide this behind friction tuning, extra iterations,
forced upright posture, new sleep flags, velocity cutoffs or weakened tolerances.
Any production selection needs new source provenance, explained trajectory
changes and a fresh public regression/reference baseline. Preserve old evidence.

## 5. Other fresh regressions, carefully scoped

All below used source36313ad and **unchanged production core**, not adopted
candidate rows:

- [M0 run41005575708](https://github.com/sagheerh/clamber/actions/runs/41005575708):
  headless **516/0**; normal Android AAB export, bundle validation,
  arm64/min26/target36/portrait/native16KB and APK zip alignment successful.
  Not an M1 lab APK build/install, physical-device run or frame-time measurement.
- [M1 run41005575764](https://github.com/sagheerh/clamber/actions/runs/41005575764):
  static **232/0**; existing point/link and public replay/clock jobs successful.
  Public committed baseline matched. This is regression evidence for unchanged
  production, not candidate determinism, a cross-architecture result, a new
  milestone signature, or credit for physics RNG use (it remains unused).
- [R29 run41005575710](https://github.com/sagheerh/clamber/actions/runs/41005575710):
  **parse only**, zero measurement ticks. Runner-proof/measurement jobs skipped.
  Historical R27/R28/R26 once-only arms also stayed skipped.
- Local controls232/0; exact-rational/source analysis12/0; package10/0;
  provenance10/0; runner routing9/0 +13/0; sealed-audit12/0.
  No-.git ZIP recheck:232/0 controls and12/0 sealed audit.
  All five candidate GDScripts grammar/lint clean; real semantic compilation
  separately evidenced above. No scanner or original assertion weakened.

Production `core/`, tuning, source manifest and historical capture files remain
byte-unchanged. Only this fixed branch was pushed; the prohibited older branch
was neither merged nor copied. Five outstanding runtime gates, D2 phone timing,
physical device/layout checks and FA3 are not waived. **M1 remains incomplete.**
