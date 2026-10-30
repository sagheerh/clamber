# M1 R24 — final round COMPLETE; STOP for owner package decision

Measured source `8110688`; push [40890281324](https://github.com/sagheerh/clamber/actions/runs/40890281324),
round job123504891124 SUCCESS. Exactly A3+B1,6000raw ticks each/24,000total,
observer-on/off physical states bit-equal6000each. C reprocessed OLD source573a1fb,
artifact12901654637, **no rerun of the three stiffness cells or 15-arm study**.
Full precision, all F56 vectors and provenance: `m1_r24_round_evidence.json`.

## A — static-slip intervention, NON-ADOPTED c40

Same k40/damping1.0886654722423434/bound30/cap12/gain.7 and geometry/seed/clock.

| slip WU/s | drift px/s | relative drift vs .15 | conditional inferred allowance for .3px/s (WU/s) |
|---:|---:|---:|---:|
| .15 | 12.9104235654314 | 1 | 0.00348555566530682 |
| .015 | 13.2677107688533 | 1.02767432080064 | 0.000339169286879844 |
| .0015 | 13.2403280705056 | 1.02555334481492 | 3.39870732510344e-05 |

**Proportional scaling hypothesis falsified.** Reducing allowance100× leaves
slightly MORE drift, not100×less. The final column is ONLY s*.3/abs(drift),
conditional/unmeasured through-origin extrapolation. Its incompatible values
are **not** a recommended setting, fix, adoption, or authorization for a target
trial. The originally suggested.00349WU/s is unsupported by these measurements.
All3fail.3px/s; no F52eligibility fromspawn6000ticks (awake observer only,
not formalAC201/sleep). No alternative contact mechanism isolated/proven here.

## B — committed saturated reference, SAME proposed protocol

Released0..5699; L5700..5759; released5760..5999. Bound6/k2400/damping55/
cap1800/gain.7 unchanged. Actual initial capsule-axis sum **.8999999999999999WU**
(checks nominal .35+.30+.25=.90, not AABB width).

- Held COM displacement(x,y): **(.02623016170054049,1.6653345369377348e-16)WU**.
- Held horizontal displacement **.029144624111711658 body lengths**; norm
  .02623016170054049WU. **NOT near one body length.**
- End-of-release net displacement from held start **(.1311508085026989,0)WU**;
  do not conflate this five-second motion with one-second held lurch.
- Held torque **-1260** every60ticks, all60saturated; mean request/bound509.78986.
  Thus reference does not establish a near-body-length behavior to preserve.
- Previously measured proposed c10/c20/c40 held x .1407595988/.0922175655/
  .0265988013WU = .15640/.10246/.02955 nominalbodylengths. No formalFA4PASS
  inferred from this proposed single protocol, nor an input-minus-idle effect.

## C — OLD powered traces, last300 ticks5700..5999

COM vx is mass-weighted **completed endpoint velocity**, not net positional drift.
Drive q is the pre-drive sample, not an assertion of a constant continuous pose.
CSV has one row per tick and raw per-tick sampled qspread (900CSVrows total).

| candidate | completed COMvx [min,max] WU/s | driveq [min,max] rad | between-tick qspread rad | within-tick sampled qspread [min,max] rad | mean driveomega rad/s |
|---|---|---|---:|---|---:|
| c10 | [0.058164290952111265, 0.058164290952112035] | [0.22316866039209327, 0.22316866039210037] | 7.105427357601002e-15 | [0.11155079619301267, 0.11155079619301889] | 1.18727917337618 |
| c20 | [0.07809008127719534, 0.07809008127719887] | [0.08996254195333808, 0.08996254195335229] | 1.4210854715202004e-14 | [0.11088261179678982, 0.11088261179679781] | 1.2340945681038027 |
| c40 | [0.08782601064920688, 0.08782601064921149] | [0.032108711886437824, 0.03210871188645159] | 1.3766765505351941e-14 | [0.10929299596206787, 0.10929299596207942] | 1.2692381774655277 |

Within-tick samples: drive; after-integration reconstructed from raw start+
integration endpoint deltas; original pre-angular eachpass; velocity-limit
samples; completed. Angles unwrapped around drive reference. These are sampled
ranges, **not continuous maxima**, and no net distance/hinge delta is reordered
into a fictitious chronological path. **Tiny between-tick q spread coexists with
~.11rad within-tick motion and nonzero omega.** F72 frozen-throughout-tick premise
is contradicted; drive-sample recurrence is real, not a rest/global-attractor or
unique causal proof. No new instrumentation or physical runs used for C.

F65 **CLOSED BY RE-SCALE**: archived powered workingq12.787/5.154/1.840deg legal
under+40. All6000 per candidate independently read: **0engaged,0projection-moved,
0nonzero limit-block ticks**, agrees original summary. This is candidate-scoped
closure; current defaults remain unadopted/historical and are not called fixed.
F71 fit14.4083-58.5818/k remains finite3point empirical relation, NOT a measured
infinite-stiffness result or universal impossibility proof. F73 opposite-direction
tradeoff is sign-inverted: measured stiffness↑means drift↑ (worse), lurch↓; k10
is better on both measured metrics among these3, not formalFA4qualification.

## Integrity / unchanged gates

All4 completeF56PASS on EACH of6000ticks plus20disjoint300tick windows percell,
x/y/rawcontact/resource-damping/internalzero guards. Max abs per-tick residual
**1.887379141862766e-15**, max abs window residual **6.96942503708442e-14**.
Full20books/cell in artifact `A-*/f56.json`,`B/f56.json`; literalF56false/default
exit1 unchanged (completepredicate distinct). All3A have0limitengagement6000.
A.15 EXACTLY reproduces old c40 drift; no observer effect/default mutation.

Artifact12904553635 `m1-r24-round-40890281324`,112920936bytes,
sha256 `af7e60c4d0b6e3dfffb0f526002d2af221a9ecc9ed9b592ac2cadc5f8db39d3b`,
contains four new rawtraces, fullbooks/report and3Cper-tickCSVs. OriginalCarchive
was downloaded by CI cross-run with actions:read, not replaced by new measurements.
Raw artifacts stay external, not committed.

Static190controlsPASS/gdformat+gdlint/bash/import checksPASS; load80components each.
Public replay/clock pushANDPR fullsummary EXACT oldbaseline (9053+308+1446checks),
reproduced **NOT regenerated**. M0push40890281543/PR40890293796 headless516checks
(514+2compile)/AndroidPASS. M1overallRED at historical HingedSlug600/F47 step,
not the R24job; not waived. PRroundjobSKIPPED: no duplicate round.
Core/default/creature bytes unchanged vs7d48ba0; tuningSHA3a32dd3d2d719ed28220ed531fee05c8d2a799140d3f06e3aeed4d28d6e6f60c.

## STOP / next owner decision — exactly two packages

- **P-A:** keep committed saturated motor + visible brace.
- **P-B:** adopt k10/damping.5443327361211717/bound30/cap12 + visible brace;
  regenerate baseline with provenance and rederive lurch on actual adoption.

No package selected/adopted, brace implemented, baseline regenerated, or new
experiment authorised. Fallback condition met; brace authority deliberately
unspent until owner choice. Futurebrace visibly plants onrelease/releases oninput,
snapshot/restore, explicit internal netzero hold ledger/fullF56; no fabricated
support/loads. AC201actualsleep/strictF52 unchanged; no epsilon/waiver/M2/camera/
captures/mass changes. Acceptance **8/18**, movement0, tenNOTRUN; FA5untouched,
AC202notrun. This round completed in one measurement increment; no extended sweep.

FA6 list preregistered `[0,4,8,12,16,20,24,28,32,36]`, one seed/spawn/geometry/
physics, only onset varies; original proposed60tickpulse/fixed300horizon retained.
No other variance, noFA6run,6–8/10target unchanged, B04layout provisional/D07phone
queued. Stop for owner package choice, not another diagnostic increment.
