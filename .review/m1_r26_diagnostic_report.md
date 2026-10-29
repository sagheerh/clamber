# M1 R26 — brace rejected; bounded diagnostics complete; Option 2

**Decision: Option 2. No further diagnostic measurements.** D1 does not locate a
correctness-shaped carrier; D2 does not repair the unchanged .05 WU literal-limb
criterion. No friction value or ordering change is adopted. The **owner must
author AC-201's replacement displacement/time number**. Until then its original
settles-and-sleeps criterion remains unchanged and unmet. AC-202 remains an
honest measured failure. Acceptance remains **8/18**, not milestone approval.

Authority: owner-selected Option3 in readonly reviewer `1df02f5`, section10.
Preregistration: `m1_r26_diagnostic_plan.md`. Source **114265e0116101a897d8429a2998f4987549f86f**;
original CI **40901902007**. No reviewer files copied, merged or adopted.
Full-precision evidence: `m1_r26_diagnostic_evidence.json` and
`m1_r26_archive_evidence.json`. All postprocessing uses ORIGINAL source artifacts;
there was no second physical diagnostic invocation or outcome-dependent retune.

## 1. Atomic brace removal; P-B stays

Source114265e removes implementation, active bit/angle target, snapshot/hash/
restore handling, presentation getter/flag, brace runtime tests, Python controls
and obsolete brace job in **one commit**. Original non-brace atomic restore,
rollback and math guards remain. Public checks drop9057→9053 only because the
four brace-malformation cases no longer describe valid state. M0 floors remain.

The four P-B defaults are unchanged: **bound30, k10, damping.5443327361211717,
cap12**. Resource SHA256 remains
`5f4d0d06564fb3a0847309d83cf5f3c87b9321ea5e2dd87e572e4bd9fe750666`.
Default friction stays.9. No reversion to old3.93px/s physics. Permanent P-B wins:
worst requested/bound≈.245;0/300 saturation; legal12.8° travel rather than old8.5°
beyond the+40° stop. Normal projection ordering is unchanged; the diagnostic
switch defaults false and no product/public path enables it.

Historical rejection evidence is retained, NOT rerun:

| Quantity | Brace OFF | Brace ON |
|---|---:|---:|
| Idle drift px/s | 8.550150769956836 | 12.617730602141002 |
| End-release displacement WU | +.2249433803374048 | −.06129663822438047 |
| Brace-internal F56 momentum residual | not applicable | ≤7.771561172376096e−16 |

The brace conserved internal momentum while increasing creep **47.6%** and
weakening/reversing the sampled release. The historical R25 F56 column remains
unchanged in its report. A conserved internal mechanism is not a useful mechanic.

## 2. F75 / D1 — carrier NOT located by coefficient proportionality

Each cell: authored Slug, P-B without brace, legal.01WU clearance, released input,
6000 awake ticks, process-local duplicated resource. BOTH diagnostic material
and terrain use that duplicate, avoiding a hidden `min(material, terrain)` cap.
Observed/unobserved physical snapshots match every tick. Source job123546155730
**SUCCESS**, exactly four cells, no value adopted.

| Friction | Positional drift px/s | Signed net friction thrust N | Mean absolute motor impulse |
|---|---:|---:|---:|
| .9 | 8.550150769956836 | .10818558117092802 | .04796602541507495 |
| .3 | 9.393416417530442 | .11885547303816352 | .04543232190900799 |
| 1.8 | 8.482160126141556 | .10732529139197892 | .04836483355058748 |
| 3.6 | 8.482160126141556 | .10732529139197892 | .04836483355058748 |

Thrust is SIGNED net friction impulse/window time, not sum of magnitudes or
commanded movement. Idle translation is never input credit. The .9 positional
drift reproduces the archived reference **exactly**. All6000 raw endpoints,
contacts/counts, six position phases and F31 are checked per cell;20 complete
F56 windows each. Worst per-tick complete residual1.5543122344752192e−15;
worst complete window residual5.240252676230739e−14. Literal contact-only lateral
and vector predicates remain **false in all four cells**, not silently redefined.

Each last300 contains900 dynamic,1800 static-override and2400 inactive candidates.
Dynamic retention is unsaturated at.3/.9 but clamped at1.8/3.6; those last two
are the SAME effective dynamic operator. Static override retains zero regardless
of coefficient. Lowering coefficient3× increases drift/thrust≈9.9%, not a roughly
proportional response. Flat clamped arms alone cannot establish an upstream
normal-accumulation/position defect. **D1 is inconclusive for a located,
correctness-shaped cause. This is sufficient to select Option2.**

F75 owner's mechanism-of-record remains: sustained internal load →
contact/friction rectification → translation associated with transmitted joint
load, independent of static-slip allowance; locking relative rotation increases
transmission/creep. This is **not an established universal scalar proportionality
law for mean motor drive**. The old k10/20/40 sweep actually has mean absolute
applied impulses .04796602541507495/.0458210036063169/.044435404255268936 while
drift increases8.55015/11.47924/12.91042px/s. Those are angular IMPULSES, not
unlabelled torques or total joint-load measurements. We retain the owner's
causal-chain interpretation without falsifying that countertrend or claiming D1
proved linear friction scaling. Five prior knob sweeps remain exhausted.
Steady treadmill, not limit cycle/frozen joint; F72 withdrawn, F71 asymptote
unsupported, F73 k10 wins both.

## 3. F76 / D2 — immediate distance repair does not survive contact cleanup

Authored Hopper, public Sim, seed305419896, repeating60-tick released/L/R/both
blocks. Baseline observer-on/off snapshots equal on every completed tick.
Exactly one added distance-only traversal in the diagnostic arm, using the SAME
rows, multipliers, compliance and `project(_tuning)` code, after the position
loop and BEFORE velocity/contact cleanup. No multiplier reset or velocity edit.

**Completeness:** baseline7067/7200, then both observed/control status30 at
failing tick7067, reason`step_failure`. Diagnostic **7200/7200**, status0,
reason`completed`, failing ticknull. No physics rerun to repair the incomplete
baseline. Its maxima below are over7067 observed ticks, NOT a full120s baseline.
The status/reason is logged; the precise failing solver callsite was not logged
and is not inferred from the last valid coordinates.

Worst absolute **literal-limb** error WU at each phase:

| Phase | Baseline:7067 observed ticks | Diagnostic:7200 ticks |
|---|---:|---:|
| Last existing distance block, before hinge | 1.7763568394002505e−15 | 1.7763568394002505e−15 |
| After final hinge | .014927052436045196 | .015140751632692628 |
| After final angular | .014927052436045196 | .015140751632692628 |
| After final self-contact | .014927052436045196 | .015140751632692628 |
| After added final distance | not present | 1.7763568394002505e−15 |
| After first contact cleanup | .05334550000967464 | .051910617942553194 |
| After second contact cleanup / completed tick | **.05334550000967464** | **.051910617942553194** |

Completed maxima are literal **limb3**, baseline tick12 and diagnostic tick11.
All-part maxima are foot5: .1476148698175428@7 versus.14264355525719857@7;
these foot values are not substituted for the limb criterion. Full raw per-row
phase endpoints/rest lengths/errors and derived per-tick worst-all/worst-limb
reports are retained in original/archived-publication artifacts.

Angular projection does not introduce the observed threshold violation: its
phase maximum equals the preceding hinge maximum, consistent with rigid-body
rotation preserving its own extent. The final-distance pass repairs immediate
length errors to roundoff, but **later contact positional cleanup reintroduces
the failing completed-tick error**. It is therefore not a sufficient ordering
fix for AC-202. The diagnostic's7200-tick limb maximum **.051910617942553194>.05**;
normal no-brace baseline already provides a counterexample **.05334550000967464**
even though its120s fixture did not complete. No.05 widening, adoption, extra
after-contact pass, new arm or further measurement.

## 4. F77 — repaired FA5 fixture/law audit

Predeclared stance600, +2WU drop600, authored ledge departure1200, +4WU midair12.
All **2412 ticks** completed with observer-equal physical snapshots. Every case:
reason`completed`, status0, observer status0, failing ticknull. Lifted geometry
was clear before stepping; airborne response actually observed on first tick.
Natural ledge departure at **tick83** after real support; no velocity/pose/load
injection. Initial minimum clearances .01/2.01/.01/4.01WU, retaining raw precision
in evidence. No synthetic qualifying force or support flag.

Source FA5 job123546155628 initially failed in the REPORTER (`KeyError gripping`
on a NON-foot record), not because the engine fixture failed. Archive-only audit
job123551531542 reinterpreted the unchanged raw bytes, reconstructing each SDF
normal, gravity+real hinge/self-contact load, frozen prior N, global lowest mask,
40%/N threshold, actual candidate eligibility, per-pass grip and completed foot
flags. No false extra load predicate. Original raw checksums matched. The short
midair case has no300-tick F56 window; do not claim one. Longer cases retain the
existing complete momentum-window guards.

| Case | At/above foot/pass counts | At/above episodes | Two-foot pair/pass counts | Pair episodes | Airborne foot/pass counts | Airborne episodes |
|---|---:|---:|---:|---:|---:|---:|
| Stance600 | 7 | 3 | 2 | 1 | 0 | 0 |
| Drop600 | 13 | 2 | 5 | 1 | 92 | 2 |
| Ledge1200 | 7 | 3 | 2 | 1 | 96 | 2 |
| Midair12 | 0 | 0 | 0 | 0 | 48 | 2 |
| **Total** | **27** | **8** | **9** | **3** | **236** | **6** |

Below-threshold4731 foot/pass observations,11 non-grip episodes; N0-disabled14
foot/pass observations,7 non-grip episodes; ineligible-not-lowest4640 separate
observations. True-grip event count in below/airborne/N0 branches is **zero**.
Capsule sample counts are separate again in JSON, never conflated with passes.

Events are maximal consecutive TICKS per foot/branch, collapsing capsule samples
and both solver passes; pair5+7 uses a distinct key. A tick containing different
branches in different passes can belong to both. These are disjoint operational
episodes, **not independent stochastic trials**; ledge startup repeats the stance
transient. At/above durations are3,2,2 /3,4 /3,2,2 ticks; pair durations2/3/2.
This demonstrates brief real grip-law branches, **not robust sustained grip**.

N/threshold distribution: N0 disables grip (threshold not active); N1 threshold
37.74399999999999N; N2 threshold18.871999999999996N. All27 at/above observations
and9 two-foot observations occur atN2. Stance at/above loads19.268961368455294..
22.303614150117895N; drop21.41757871487081..54.081691681016686N. Ledge includes
N1 airborne/below/ineligible observations but no N1 true grip. Full per-case
N/threshold/load ranges and episode durations are in archived evidence.
**All four requested branches are present; the repaired fixture/law audit passes.**
The guarded legacy table is not silently rewritten: its locked qualification
status remains as directed; evidence explicitly records this execution rather
than pretending the gate was never attempted. Milestone count remains8/18.

## 5. Separate baseline provenance; strict regressions

R25 baseline was P-B WITH brace. R26 baseline is **P-B WITHOUT brace**.
Generator123546155675 and SAME-source strict public123546537887 succeeded.
Actual generated bytes committed in **ddefbbabc557be955ce348632f027ed84527f51d**;
archive audit proves byte equality. No core/data/tuning change after114265e.

- Baseline file SHA256 `2779456f6a35338a97666bcec813608ae5bda83c612ec1d5b6560df62590f679`.
- Final digest `4ec66a1f719135112c28f4e6678d87f4e3c04221d5236816ec02788faa0a6aaa`.
- Stream SHA256 `cf98342cf54a06180a68223fb9aa0cb217209b2adb77c544293348e896e29190`.
- Tick-table SHA256 `ab2be178d0dee0da6d6d08e8ac8109fb3598803d2c970ffbb61235ef8c3288af`.

Normal committed-baseline public jobs **123551532000 push /123551591430 PR**
pass9053+308+1446 checks,0failures. Full push/PR summaries are identical;
source summary differs ONLY in correction of an obsolete human-readable brace
scope label. Physical replay/delivery hashes and all measurements are unchanged.
The normal baseline checker is unmodified/strict. D2's nondefault diagnostic is
NOT a replacement public baseline; each paired raw trace has its OWN source,
ordering identity and SHA256 in archived provenance. A later authorised physical
change would require another separately identified regeneration.

Commands/results:

- `scripts/review_checks.sh`: source200 controls; parser fix201 in push+PR;
  final report-publication hardening adds the explicit target-forgery control.
- `gdlint` / `gdformat --check` on changed GDScript, Python compile, workflow YAML
  parse, `git diff --check`: passed locally.
- `tests/run_m1_r26.sh d1`: source job123546155730 SUCCESS, exactly four cells.
- `tests/run_m1_r26.sh d2`: source job123546155690 failed due incomplete baseline
  reporter; raw diagnostic completed7200. Archive-only interpretation above.
- `tests/run_m1_r26.sh fa5`: engine completed all four; reporter schema bug;
  `tests/r26_archive_audit.py` on originals: **SUCCESS,0new physical runs**.
- `tests/run_m1_public.sh`: generated overlay and normal committed bytes both
  match, source and push/PR cited above.
- M0 source push40901902041/PR40901918052 and committed-baseline
  push40903408840/PR40903423810: headless516/0 and Android **SUCCESS**.
- Overall M1 remains **RED** at unchanged `Hinged Slug600`/F47; no bypass/waiver.
  Same-build determinism attempt1 remains an observation; cross-architecture0.

## 6. Closeout / hard stop

One bounded physical increment, no diagnostic adoption and no further measurement.
No slip/stiffness/damping changes, mass/weight change, epsilon, tolerance widening,
brace rerun, new lurch trial, camera, capture, M2 or waiver. F74 remains a sampled
ceiling over.7/1gain×1s/5s, not a global maximum. Until creep is fixed no lurch
measurement is trustworthy; idle motion never earns input-effect credit.

**Blocked on owner:** author Option2's AC-201 displacement/time criterion; resolve
AC-202's measured failure in that owner conversation. Engineer has neither
invented an acceptance number nor changed the existing criterion.

**Next single milestone: M1 — owner-authored Option2 acceptance decision.**
