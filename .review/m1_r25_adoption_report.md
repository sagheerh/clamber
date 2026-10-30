# M1 R25 — P-B adopted; joint-brace acceptance FAILED — STOP

Owner R25 decision read in place (reviewer9957260), never copied/merged. Physics
adoption **8d73597**; [source CI40895082337](https://github.com/sagheerh/clamber/actions/runs/40895082337).
Four adopted values: k10, damping.5443327361211717, bound30, cap12. Gain.7/range0..1,
contraction62, slip.15, sleep.001/30, masses/weight/geometry/bands UNCHANGED.
Derivation/rejected alternatives/owner attribution in DECISIONS M1-R25.

**Honest cost and realised risk:** first adopted motor re-scale, not another
candidate; regenerated baseline and strict public replay/clock rerun on SAME
physics-changing commit. Brace did NOT remove creep: now12.6177px/s ON,8.55015OFF
vs old committed3.93452. AC201 depends on designed hold and remains FAILED.
No automatic rollback to P-A (owner choseP-B), no strength/threshold/slip change.

## Owner STOP conditions reached

- BraceON actual zero-input drift **12.617730602141002px/s**, above.3 diagnostic.
- **Unmodified actualF52 never fires:** no sleep during600publicSimticks nor6000
  idleONticks. Not a low-window-mean substitute/counterfactual/epsilon.
- BraceOFF **8.550150769956836px/s EXACT**, reproduces accepted c10. Adoption
  did not introduce an unrelated change in brace-disabled physics.
- BraceON also **weakens held lurch** slightly and causes post-release backslide
  at defaultgain. Do NOT call the brace delivered or stationkeeping fixed.
- All registered arms executed once; no outcome-dependent added arm/parameter.
  Core/tuning remain frozen at8d73597. Subsequent work is archive reporting and
  generated-baseline/static-control bookkeeping only.

## Relative-joint implementation / visibility

Bilateral release-angle row, not a world pin: J=-omega/(Ip^-1+Ic^-1), equal/
opposite endpoint couples. No force cap/spring/new tuning constant; anyinput
instantly releases/rearms. Positional row holds relativeq at releaseq; it does
not constrain body/worldheight. Sleep unchanged; velocity parking only by F52.
State boolbrace_active + necessary releaseanglebrace_q captured in snapshots/
statehash/atomicrestore (malformedbool/angle/missing/canonicalinactive validation).
Public `get_brace_state()` exposes detached flags. **Presentation contract is
specified, NOT rendered:** distinct planted joint cue must be visible in Phase4,
as authorised deferment; no current capture/visual completion claimed.

Controls724/0, including bilateral signs/idempotence/anyinput, malformedrestore,
hash/exactcontinuation and airborne equalCOM/no manufactured ground. Public
restore/clock controls9057/0. Numeric internalroundoff below is not concealed by
forcing budget columns to zero. Mathematical netzero is by construction.

## Registered lurch / F74 — actual sleeping composition

SAME95sreleased prelude, fixed held duration then4srelease. All lengths .90WU
(sum actual authored axes); signed horizontal COM displacement, not AABB width
or input-minus-idle causal effect. Sources .7/1.0 and1s/5s registered BEFOREresults.

| arm | gain | held s | held x WU | end-release x WU | held BL | end-release BL |
|---|---:|---:|---:|---:|---:|---:|
| lurch-off | 0.7 | 1 | 0.1407595988363362 | 0.2249433803374048 | 0.1563995542625957 | 0.2499370892637831 |
| lurch-on | 0.7 | 1 | 0.1400962515426247 | -0.06129663822438047 | 0.1556625017140275 | -0.0681073758048672 |
| gain1-short | 1.0 | 1 | 0.1038474460928391 | 0.1031496824643892 | 0.1153860512142657 | 0.1146107582937657 |
| gain07-long | 0.7 | 5 | 0.242186082840508 | 0.03563734148342235 | 0.2690956476005645 | 0.0395970460926915 |
| gain1-long | 1.0 | 5 | 0.1238861981725279 | 0.1232123816230377 | 0.1376513313028088 | 0.1369026462478197 |

Gain1.0 is NOT assumed monotonic with netlurch: 1sheld.11539BL vs.7's.15566;
5sheld.13765BL vs.7's.26910. Longerhold increases helddistance at eachgain,
but these sampled results remain short of1bodylength; gain1/5s end-release
.13690BL vs.7/5s.03960BL (default1sendsbackwards). Best ON held **.26910BL**,
best ON end-release **.13690BL**. No contraction/gain-range widening authorised.
**Sampled ceiling, NOT a global maximum over unlimited holdtime.** With nonzero
idle translation and no owner-defined longerhold duration, unlimitedtime is not
a meaningful finite lurch ceiling; do not drift-to-gate. FA4NOTPASS/F74STOP.

OFFactualsleepfirstfires at5841 afterrelease; its end-release.249937BL differs
from old awakecounterfactual.251845BL because parking now really runs. HeldOFF
.14075959883633615WU exactly reproduces oldc10. Do not compare the two release
measurements without this sleep distinction. ONneverparks in these arms.

## Complete F56 / determinism / baseline

Sevenarms **42,480ticks**, observerbit-equal each; **42,322actualawake force rows**,
158parkedOFFrows explicitly carry NO freshforcebudget. Everyawake tick independently
reconstructs x/y rawcontact, resource damping/gravity, clamping, both internal
terms and bilateral row impulses;300awake-row windows (including partialtail)
also close. Parking impulse transition is explicit/excluded from awakeF56, never
falsely attributed to contact. CompleteF56PASS ALL7; maxabs per-tickfull residual
**1.5543122344752192e-15**, maxabsper-tickbraceinternal **7.771561172376096e-16**.
Whole-run measured brace subset sums ~1e-13 retained (not literalbitzero); same
existing1e-12 ledgerprecision, no new physicalepsilon. Brace column is SUBSET of
existingdrive/internal, never doublecounted. Full books/raw in externalartifact
12906214059 (95,845,021B); defaultliteralF56 gate/false/exit1 unchanged.

Baselinegenerator123521870237 accepted ONLY oldbaseline/provenance mismatch after
actualtriple+clockPASS; generated exactbytes/provenance. Existing strictpublic
job **123522445066 reran on adoption8d73597**, declared baseline+DECISIONSoverlay
ONLY, no solveredit,9057+308+1446PASS. Metadata follow-up **c169ded** commits generated bytes. Normal strictpublicjob
push40896828176/job123528127573 AND PR40896836574/job123528164326 **MATCHED**
committedbaseline, fullsummary identical to adopted-source publicrerun. Archive
bytecheck confirms committedfixture IDENTICAL generatedfile, SHA256
`3d2f95e2187b2f90961d31a525eaa9d79ccb4296dec4fb766c6754f4043f185f`.
Public600idle physicalstates equal corresponding600force-trace states; actual
F52failure and F56budget evidence are the SAMEphysics, not a proxy. OriginalsourcePR's oldbaseline
mismatch is NOT a second determinismfailure; rawreplays equal.

- Final digest `a30a132f739e97ce3b4f73ca1716fb7359e0ae22b460378d8396b01da773fb71`.
- Stream SHA256 `a2929a0c590f68cbe795ab03b2027cb94a9990fef69732236865f1fb30d3e557`.
- Tick-table SHA256 `f2c680300abdc6e2937a493aa344e1404dece005397cd8a99a6c17a52bd4f239`.
- Tuning SHA256 `5f4d0d06564fb3a0847309d83cf5f3c87b9321ea5e2dd87e572e4bd9fe750666`.

M0sourcepush40895082360/PR40895093958:516/0 (514+2compile), AndroidPASS.
Committed-baseline follow-up M0push40896828167/PR40896836545 headless+AndroidPASS too.
Local198controlsPASS; sourceCIstatic184thenFAIL from test requiring unavailable
fc33aaa in shallowcheckout. Fixed test-only goldenhash normalization retains
same pre-R25 immutablebytes and fourapproved values, no physics edit; follow-up
pushANDPR198controlsPASS. No scanner/criterion weakening or count-floor reduction. OverallM1
also retains historicalF47red/nonwaived; do not label CIgreen justbecause replaypasses.

## Independent AC202 / FA5 — started and measured separately

Neither job depends on brace/baseline success; no gate credit borrowed from brace.

**AC202** job123521870061: actualpublic3presets7200tickseach/120seach.
Archived-data audit123528127119 (NO new simulation) separates actual limbs from
feet, so the stronger all-segment failure is not mislabelled as a limb failure:

| preset | max motor/passive/limb error WU | location | max foot error WU |
|---|---:|---|---:|
| Slug | .06735552288921903 | motor1, tick81 | .09437461522175528 |
| Hopper | .1090211629000053 | motor4, tick28 | .199917694835798 |
| TwinRoller | .07263504920267333 | motor1, tick650 | .09966156857329556 |

All exceed unchanged.05WU even excludingfeet. Hopper's **literal `limb`6** also
reaches **.09978856801616326WU at tick13**, independently establishing a true
limb failure, not just foot compression. Full per-kind maxima in archiveJSON.
**AC202 measured FAIL**, not merely a stronger surrogate failure. No XPBD/iteration/
geometry/tolerance repair attempted after braceSTOP.

**FA5** job123521869700: authoredHopper awakebraceOFF/naturalgravity+hinge+self
loads, originalflatfloor/script released/L/R/both60tickblocks. **7067/7200** completed,
observerequal allrecorded; harnessbreak cause notlogged, no inventedreason.
PreviousN reaches2. Observed belowthreshold15,317 /at-or-above7 /twofootgrip2 /
N0nogrip4 batches/foot-cases. **Airborne0**, missingcoverage -> **NOTPASS**.
Thresholdmax(5,.4W/N), actual priorcompletedN/lowest/loadprovenance/groundedgrip
independently verified everyrecordedpass, no syntheticload/pose/flag. No posthoc
stance/floor/input adjustment to manufacture coverage. Archived last endpointxrange **[-11.998676101856619,-11.215033260486496]WU**,
near the floor fixture's leftbound-12; consistent with fixture escape, but exact
failed-call status was NOTlogged, so it is NOT asserted as the proven abortcause.
No newstep/replay/floor expansion to infer or conceal it. All OBSERVED grip decisions
matched unchangedlaw; failure is incomplete coverage/truncation, NOT evidence of
an airborne falsegrip. Footqualification gates unchanged.

## STOP disposition

P-B remainsadopted but acceptanceFAILED; matrix **8/18**, movement0, no new PASS.
Owner must choose NEW contact-model review (largerscope) or owner-authoredAC201
number/specdecision. FA4/F74shortfall and independent failures recorded, not forced.
No retune/epsilon/sleepthreshold/slip/mass/weight changes, waiver, M2/camera/captures.
Distinctbrace presentation stillPhase4deferred; FA6onsets0,4,..36fixed/notrun;
B04layout/D07phone remainqueued. This ends brace tuning, not opens a new sweep.


## Archive audit closeout

CI40896828176/job123528127119SUCCESS, **zero newphysics runs**, no solver edits.
Read original brace/AC202/FA5/baseline artifacts only; compact findings in
`m1_r25_archive_evidence.json`. Same-commit publicrerun alreadyPASS on8d73597;
c169ded verifies committed generatedbaseline as well. No change to8/18, no
runtime gate upgraded and no claim Phase4visibility/captures delivered.
