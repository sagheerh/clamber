# CLAMBER progress

## Latest V25 — runtime207 PASS; long-run Hopper285 STOP (2026-10-31)

Correct fresh geometry native runtime source93b2f1fb0cd7/run41219732497:
**207checks/0failures/66awake force audits**, all Slug/Hopper/TwinRoller cases.
L/R/BOTH/release, natural sleep/input wake, typed restore, mutated partial-frame
rollback/no leaked signals, independent angular/contact/controller/material laws,
compensated fakes and actual force-only nonzero clamp controls pass in that scope.
Offline saved3first-awake/3clamp arithmetic:6testsPASS; not all66 saved traces,
not gameplay clamp coverage, FA3 or production adoption.

Ordered source9343fb06296f/run41219891289/publisherffe57e4 CLOSEDFAIL:
**464native PASS; original600 PASS; Slug7200 PASS; Hopper285 FAIL; TwinNOTRUN.**
Original posture0deg/air0/net0/sleep29/original4sTRUE. Slug length2.22e-16WU,
penetration.012012090780530296WU, netCOM.3586042012433926WU. Hopper first physical
velocity_pass_0 support fails, not final constitutive (status3 NOTRUN).
Read-only exact285 native dc008dfa/run41220291795:42+4PASS/ZERO ticks; first
normal block18eq/4ineq succeeds with3active; second material block20eq/4ineq
rejects before publisher. Independent rational diagnosis: binary64 falsely
violates fourth normal by -2.609e-15 while exact SAME-input residual+9.595e-17;
adding it makes a truly singular system. Neither an energy allowance nor the
earlier negative-multiplier ordering fix addresses this roundoff rank trap.

Changed narrowly scoped unadopted algebraic fix: precision escalation only upon rank
rejection; twofold LDL solve of SAME rows/RHS/weights, original rank/visited/finite
and strict actual energy publisher kept. Native10 components now PASS source28b5430/run41220650456 (ZERO ticks),
exact285 actual energy1.2157209960538857→.1827241817815083; no pose change.
Fresh runtime matrix and any separately preregistered changed-source ordered world remain pending.
Shared independent force arithmetic now registered for EVERY fresh awake long-run
tick, asleep solves explicitly NOTRUN. Runner474 native prereqs/66mocktestsPASS.
No unchanged-world retry, material/mass/tuning/threshold/physical iteration change.
**Both requested items are not jointly complete. M1BLOCKED/NOTSIGNED; production
AC201/202FAILED, FA3uncredited, five runtime gates NOTRUN, M2blocked.**


## Historical V16 — complete numerical Slug600, original posture/rest still FAIL (2026-10-31)

Source **253102b4750d42cbe8780fc72c61f4b1749ad83d**, CI **41169768318**,
publisher **523c181**; immutable34 files `tests/fixtures/m1_articulated_execution/253102b4750d/`.
**317 native prerequisites PASS; 600/600 solverOK; airborne0; penetration0;
length1.6653345369377348e-16WU; actualspawnCOMnet.3322757068994543WU.**
Original posture firstfails43, maximum **38.504759454769165deg** (>15); no sleep
by original4s or600. All three7200 **NOT RUN**; no adoption/AC202/FA3/signature.

V16 corrects a proven skin-contact defect: lever = centreline(u)-radius*n,
physical skin slip = centreline slip-omega*radius; actual terrain torque includes
-radius*Jt. BOTH existing contact passes and material/static/identity decisions
use that same physical point. Radius, silhouette, masses, material, thresholds,
iterations and previousN unchanged. Fraction6 / native24 pure-spin, true rolling,
old-law negative, torque, momentum, boundary and template controls PASS. First
4477bb2 native compile incident preserved; corrected82649c9/run41169679309 clean.
Local runner48 PASS (26 script invocations), plus independent analyses; no local
Godot/device claim. Exact world-source M0/foundations/R29 companions SUCCESS.

V13/V14/V15 remain CLOSED failed / no adoption, immutable evidence retained;
V15 local angular law independently proved but did not fix posture. V16 completes
600 without their final-contact stoppage, not an acceptance cure. A separate
Fraction5 STATIC free-foot support diagnosis identifies no single-support static
equilibrium in the original +/-15deg pose box; explicitly NOT a 600-tick or F52
impossibility proof, nor authority to weld, retune or alter fixed geometry.
See `.review/physics_fix/slug-static-support-analysis.md` before selecting changes.

**M1 BLOCKED/NOT SIGNED; M2 blocked.** Production input/release/wake/rollback,
adoption, five runtime gates, determinism/replay, phone/performance/layout and
final review remain uncredited. No new world proposal selected after failedV16.


## Current milestone: M0 — APPROVED / COMPLETE (owner override); M1 — BLOCKED / NOT SIGNED; M2 blocked

Session date: 2026-10-31. Normative inputs: `docs/GDD.md` and
`docs/ui/CLAMBER_UI.jpeg`. M0 is accepted by the GDD owner under M0-D07, dated 2026-10-28. Verdict:
**APPROVE — HUMAN OVERRIDE**. Missing device evidence and measured FPS/P95 are
waived for M0 only, not represented as measured. Land M0 before the separate M1
scaffold/PR; no M1 implementation or gate completion is claimed by this closeout.

## Latest physics repair V12 — CLOSED after37 ticks; main fix NOT complete (2026-10-31)

Source **a45a2b5**, CI **41167162511**, publisher **32d7e4f**: native214PASS,
then37/600 committed ticks. Prefix posturemax **3.5962402248733243deg**, airborne0;
**tick37/status30 STOP**. A short prefix is NOT a completed600 posture/grounding
PASS. No sleep (maxstill1), allthree7200 NOTRUN. Candidate NOT ADOPTED.

Root cause is now independently confirmed: damped support's static tangential
response injects actual kinetic energy **.00024237950815162584**, not an ULP error.
The unchanged strict barrier correctly rejects it atomically. Read-only native
inspection **9a294d0 /41167509873**:42 + archived10 + new12 diagnostics PASS,
execution SKIPPED/ZERO new world ticks. Exact inclined-rod counterexample gains
293/484 despite SPD/hinge-compatible response; new rational9 includes this trap.
Do not relax the guard, rerun unchanged or claim restitution alone fixes posture.
No next candidate selected. Full closure/source hashes/incident distinctions:
`.review/physics_fix/articulated_execution_v12_closure.md`, audit10PASS and native
annotations retained. Original<=15deg/no-airborne600/4s/F52 gates unchanged;
M1BLOCKED/NOTSIGNED, productionAC201/202FAILED, M2blocked. Core/tuning untouched.

### Earlier V8 summary (historical, not latest result)

## Active causal repair — coupled constraint correction verified; posture/rest STILL FAIL (2026-10-31)

Latest executed source **d0af122528f4fadcb85584c75beb85119aec1c3c**, CI
**41160503517**, immutable publisher **051e4b7**. Native prerequisites
**42+8+20+12+36 PASS**. NEW unadopted Slug completes600/600 ticks, every solver
statusOK. Bone-length max2.220446049250313e-16WU; penetration max
**.02000000000000071WU**, inside ORIGINAL **.02*(1+1e-9)** reporting bound.
No material angular limit violation; actual V8 never reaches the upper stop.
Native36 separately exercises active upper/lower angular stops, contact coupling,
finite all-floor feasibility, exact hinge coordinates, motion bounds and atomicity.
Do not credit inactive whole-world upper-stop coverage or three7200 from this.

Implemented test-only coupled angular/hinge/contact block; inactive free operator
preserved bitwise. Finite position publication constructs tree coordinates BEFORE
solving all sampled terrain halfspaces for global translation. No rotation/hinge
repair after terrain, extra PBD sweep, upright target, motion erasure, manufactured
normal/grip load or core/tuning/manifest change. Position-only translations remain
unqualified; original strict velocity energy and displacement guards unchanged.
Free old proposal is retained where feasible; not ALL world hinges are bitwise
coincident (maxgap.0004663574476392047WU before finite path; terminal gap0).

**Original acceptance STILL FAILS**: first posture violation14, maximum
**36.82450412336463deg** (>15), no original4s sleep and none by600. Maximum still
streak4/30; continuing motion is real, not improved rest. COM net.3189581467166967WU.
All three7200 arms NOT RUN. This is NOT adoption, production AC202, determinism,
FA3 or an M1 signature. Physical input/release/wake/rollback/force, adoption,
provenance and layout/device/default-performance gates remain.

Closed attempts: V6source6fffadd native24 PASS, 7 ticks then strict contact response
rejection; V7source8368e14 native27 PASS/600 completed, material angular reopening
removed but penetration regression .02006846411770838 starts47. Preserve both;
no unchanged replay. V8 addresses finite nonlinear hinge/contact geometry, and
removes that penetration regression on Slug600 without changing the reporting bound.
No production adoption. See v6/v8 preregistration and immutable source folders.

Offline capture comparison10/0 (ZERO new ticks) pins V5/V7/V8. Physical states
first differ from V5 at46 forV7,20 forV8: early14 posture failure is NOT fixed by
these later corrections. Separate saved early rotational audit8/0 closes the
force-integration angular ledger to roundoff: initial COMx.2630645161290322 vs toe
x.35, gravity torque3.773N*m, motor pair net angular impulse roundoff-scale. This
is real early angular momentum, NOT proof the authored pose is impossible or
permission for an upright controller, tuning change or speculative order sweep.
Reports: `.review/physics_fix/articulated-{constraint-fix,rotation}-audit.json`.

M0run41160503567, foundations41160503549, R2941160503520 SUCCESS for exactd0af122.
Local routing doubles24 PASS (ZERO engine ticks). New candidate is unadopted;
**M1 BLOCKED/NOT SIGNED**, production AC201/202 FAILED, FA3 uncredited; M2 blocked.
No next candidate or new world attempt registered after this failed600 gate.

## Historical V5 — numerical run complete, posture/rest FAIL (2026-10-31)

Latest executed source **813e3ef6e6d34ba76911f2f26b1dcc340e4b0702**, CI
**41157323700**, immutable publisher **f3da173**. Native prerequisites **42+8+20+12
PASS**. NEW unadopted Slug completes **600/600 ticks with solver status OK**.
Original acceptance FAILS: first posture violation **tick14**, max
**51.5092822123154deg** (>15); no sleep by original4s or at all through600;
maximum qualifying still streak14 (<30). COM net .3568142297851864WU;
length max5.551115123125783e-16WU; penetration max.019999982972719904WU.
All three7200 arms **NOT RUN**, as required after the600 gate failure.
This is NOT production AC202, adoption, determinism, sleep or M1 acceptance.

Implemented numerical remedies: exact unchanged-state projection certificates
across caller/terrain, and exact endpoint-zero contact identity. No energy epsilon,
new iteration or motion erasure; cold/changed-state guards still strict. Candidate
angular damping0.8 interpretation remains unadopted, not a proven posture fix.
Earlier V3/V4 stopped after5/9 ticks; V5 fixes those specific numerical stoppages.
Preserved fixture/compile incidents (ZERO world ticks), including source5d5806e's
undeclared test argument; corrected by813e3ef before the native12/world run.

Read-only hash-pinned600 audit **9/0**, ZERO new ticks:
`tests/articulated_complete_trace_audit.py`, report
`.review/physics_fix/articulated-complete-trace-audit.json`. First15deg crossing is
already present at tick14 integration, not first caused by angular-limit cleanup.
A SEPARATE later defect: native final joint q exceeds upper40deg from tick46 on
554 frames. At tick100, recorded last angular pass reconstructs q=.6981317007977315
(upper=.6981317007977316), but final native q=.7578008772383322. Later aggregate
hinge/contact operations reopen the corrected angular constraint. This is not
roundoff; max upper excess .060670178674278374rad. Do NOT misattribute the earlier
posture crossing to this late defect or assert fixing it alone will pass M1.

Next physics work must prove simultaneous angular/hinge/contact feasibility on
saved component states and separately explain the early fall and sustained rest
motion; no blind damping/order tuning, upright controller or unchanged world replay.
No next candidate/world capture registered yet. Original600 -> three7200 ->
input/release/wake/rollback/force coverage -> adoption/provenance/device gates remain.
M0/foundations/R29 for source813e3ef all SUCCESS (IDs in saved regression JSON).
Production/core/tuning/manifest unchanged; **M1 BLOCKED/NOT SIGNED**, production
AC201/202 remain FAILED, FA3 uncredited; M2 blocked and phone/layout gates unwaived.

## Historical pre-V3 continuation — native network PASS, assembled failure isolated (2026-10-31)

Whole-tree articulated mobility passed **42/0 native checks**, official pinned
Godot4.7.2.ed1daf0bf, sourcebc800ca/run41149770549/job124383257583;
repeated42/0 on source6b48e63/run41150287513/job124384940295. GitHub is connected;
CI runs correctly. No local pinned binary; that is not a current CI blocker.

A NEW terrain/force-budget adapter and public-Sim candidate were implemented,
without changing production/core/tuning/manifest. Source6b48e63 compiled, then
**FAILED at Slug tick index2 after TWO committed frames**: unconditional post-cap
hinge reconciliation. First failure is preserved byee809141 under
`tests/fixtures/m1_articulated_execution/6b48e638c368/`. Three7200 arms NOT RUN.
No600/7200 stability claim; no adoption. M0, independent M1 foundations and R29
compile-only CI on this source succeeded, not acceptance/performance credit.

Inactive-cap identity correction passed8/0 native archived-frame checks after a
zero-tick JSON fixture-schema incident (source3007e64, preserved byabbdcaf).
Sourcef7b8fd2/run41150933157 repeated native42/0, compiled and actually executed
v2: **14 committed Slug ticks; posture first FAIL tick8, max38.97992391219688deg;
solver FAIL index14**, pre-contact hinge projection in second velocity pass.
All three7200 arms NOT RUN. Immutable evidence saved byc6eae50. Candidate
REJECTED/NOT ADOPTED. Partial geometry does not establish AC202/120s stability.

Read-only native inspection of the EXACT saved failing component frame now
PASSED10/0 (source730b2b2/run41151408137/job124388545483), ZERO new world
ticks; native42 re-PASS, all world jobs skipped. It confirms the2-ULP kinetic
energy increase triggers the unchanged strict guard, with valid finite/SPD
geometry and bitwise atomic rejection. No epsilon or guard relaxation. Posture already independently failed. See
`.review/physics_fix/articulated_execution_v2_result.md`. Local routing17/0,
immutable first-failure audit19/0, rational18/0 and grammar/lint PASS.

Source730b2b2 regressions also PASS: M0 run41151408189 (516/0 plus Android
arm64/min26/target36/portrait/16KB alignment export checks); independent M1
foundations41151408079 PASS; R2941151408199 compile-only PASS. No phone install,
frame timing or actual M1 acceptance inferred. Saved job/annotation records.

Actual posture/sleep,7200 length+penetration, held inputs/release/rollback,
validated production adoption/provenance, physical layout/device/performance/FA
remain open. **M1 BLOCKED/NOT SIGNED; AC201/202 production failures remain;
FA3 uncredited; M2 blocked.** No tuning, sleep or acceptance relaxation.

## Active physics-fix investigation — owner authorisation granted (2026-10-30)

Owner now explicitly requests AC-201/AC-202 fixes after project/game analysis.
Permission is no longer the blocker. Reviewed game pillars/held two-channel
control, solver/contact/sleep implementation and actual R26–R29 failure records.
No forced upright controller, scripted gait, changed sleep/threshold, or blind
re-adoption of the rejected final-distance repair.

Located the AC-202 terminal-operator incompatibility: contact cleanup moves free
endpoints after completed bone solves. Fresh recheck fixed a real test-runner
false-pass defect: standalone inverted `grep` did not stop `set -e`. Reproduced
three failures before the fix; explicit exits now pass9 routing regressions.

**CI is now available; the old allocation blocker is historical, not current.**
Current-branch source6c1c487/run41004935173 checksum-verified official Godot
4.7.2.ed1daf0bf, compiled the kernel and ran **31 primitive checks / 0 failures**.
Source36313ad/run41005575775 repeated primitives successfully, then compiled and
executed ONE new, test-only assembled rigid-contact candidate. It kept original
eligibility/load/sleep/tuning/iteration budgets; reordered existing rigidity rows
before contact; no rejected post-contact distance repair.

**Candidate REJECTED / NOT ADOPTED.** Slug released600 completed ticks:
max attitude39.67491255849509°>15°, no sleep (original4s and600 both fail),
COM .5006718410403428WU≤.90, airborne0; bone error1.1102230246251565e−16WU,
penetration .020000000000000823WU (slop+roundoff; no report violation at
`>.02*(1+1e-9)`). The last two observations are IDLE-ONLY, **not AC-202 PASS**.
All three7200-tick length arms stayed **NOT RUN** after the failed first gate.
Full600-row trace, source hashes, logs and raw/gzip hashes preserved in
`tests/fixtures/m1_contact_composition/36313adee194/` (evidence child9f77efd).
Independent offline audit12/0; composed-runner routing13/0, zero new physics ticks.

Trace audit locates remaining *coupled* incompatibility: despite rigid bones,
post-contact hinge position gaps peak .06874241313623658WU and relative endpoint
velocity gaps peak1.7990887822518324WU/s. F52 still-count never exceeds1;
50 of ticks500–599 exceed its anchored .001WU window. Foot sample count toggles
2/3 at a cell boundary. These are observations, not a proven posture/root-cause
patch or licence to change friction, sampling thresholds, iterations or sleep.

Current-source standard regression CI also succeeded (not candidate acceptance):
M0 run41005575708 headless516/0 + normal Android export/alignment; M1
run41005575764 static232/0, point/link and existing public replay/clock/baseline
jobs success. No M1 lab APK/phone execution, cross-architecture proof or D2 phone
benchmark. Historical R27/R28 arms and R29 measurements skipped; R29 parse only.

Local recheck: controls232/0, analytical12/0, package10/0, provenance10/0,
no-.git ZIP controls232/0 + sealed audit12/0; all five candidate GDScripts grammar/lint clean. Production core/tuning/manifest
unchanged; historical evidence preserved. **Neither production failure is fixed.**
M1 BLOCKED / NOT SIGNED, FA3 uncredited, M2 blocked. No automatic retry after the
candidate failure. See `.review/m1_physics_fix_recheck.md` for actual results,
remaining rigid-hinge/manifold work and exact source/job/evidence links.

## Active continuation — opt-in M1 device diagnostic (2026-10-30)

Branch `arena/f43f36ab-clamber` starts from merged main `7d86dd5`. The earlier
"main not advanced" notes below describe the previous session, not current main.
Owner wants executable code before doing their physical-device testing.

Added a separate `tests/device/m1_lab.tscn`: production presets + public Sim,
held L/R touch/keyboard, explicit pause/resume, background input clear, fixed
collision diagram (150px/WU, no camera work), and actual committed tick/session
logs. No product screen/default boot change. New isolated APK staging/build script
uses package `org.clamber.m1lab`; normal exports remain unchanged and exclude tests.
`M1_DEVICE_TEST.md` documents install, manual testing and whole-log extraction.

This closes a manual testing-access gap, NOT the physics failures. AC-201/AC-202
remain FAILED, adoption stays reverted, FA-3 uncredited, M1 BLOCKED / NOT SIGNED,
M2 blocked. No D0, accepted R27/R29 runs, tuning/core/threshold changes or P3.
Python package contracts and GDScript grammar/static checks are tested; engine
semantic compilation, input execution, APK build/install and device testing are
NOT RUN without the pinned engine/SDK/phone. Do not describe this as all M1 code
complete or phone-ready validated. Source manifest still matches unchanged core.

The squashed checkout initially lacked 4796ec6/fb890fd history and correctly
failed closed. Fetching the original pinned 4796ec6 object/history restored the
unchanged Git checks (no assertion edits): 232/0 in Git and 232/0 in no-.git ZIP.
Device package tests10/0, provenance10/0; GDScript grammar/lint clean. No real
engine/phone result implied. See `.review/m1_device_increment.md` for scope.

## Historical ZIP delivery preparation — not a merge or an M1 verdict (2026-10-30)

The intended main integration carries the M1 code for local execution, **not an
M1 sign-off**. Main has NOT been advanced by this session: branch-only write
permissions prevent updating main or publishing its tag. The agent branch has
ZIP-safe tooling and `LOCAL_RUN.md`; fast-forward/tag handoff is pending.

**M1 BLOCKED and NOT SIGNED.** AC-201 FAILED. AC-202 FAILED: adoption reverted;
the control is at `physics_contact_slop_wu = 0.02` plus roundoff, and adoption
reached 2.5–4.7× the designed slop. F79 WITHDRAWN. FA-3 is uncredited. Five runtime
gates remain NOT RUN: presets+captures, tick cost §10.4, §10.6 step 1, FA-4,
and FA-6. CI is blocked by account billing/allocation (GitHub's exact annotation
allows failed payments OR spending-limit exhaustion; neither cause independently
established). M2 remains blocked. **A merge is not a verdict.**

ZIP controls passed twice without `.git`: 232/0 each. Separate packaging tests
verify hash failures, including edits/additions/deletions/renames. Launch-routing
checks used a labelled test double, zero real engine ticks: NOT import/compile
or runtime evidence. Real Godot proof remains unavailable because the pinned
asset download redirects to a blocked host. No D0 or D1–D5 measurement was run.
Historical M0 516/0 remains historical, not a fresh result.

Manifest pins core/tuning to 0c1d3f8 (byte-identical to 4796ec6); packaging changes
necessarily differ from the full 0c1d3f8 tree. Existing CI markers and historical
R1x–R29 pins are untouched. No physics, assertions, thresholds, tuning/slop/
iterations, preset/save/M0 expectations or billing/artifacts were changed.
`arena/5b72e4ab-clamber` was NOT merged: the owner identifies it as predating the
M1 workflow and R28/R29 evidence, risking loss of workflows and evidence files.
Details and exact merge-proof limitations: `.review/m1_zip_delivery_report.md`.

## R29 resumed from eee6c81 — required proof blocked, no arms launched

Proofsourcefe56aad/CI40980478102/job123818988944steps[]: GitHubreported account
paymentfailure OR spendinglimitneedsincrease; exactannotation/metadata committed.
Zero engine/measurementticks. Marker[R29-once-3] NOTactivated, no measurement
sourcepin/armexecution created. L1/L2 are zero-ticklaunchincidents, NOT measurement
evidence or armfailures. RP1is preflightallocationfailure, not armfailure. Await
workingrunnerproof; no D0rerun/corechange/adoption/P3. D0CONTROLATSLOP/F79WITHDRAWN
unchanged. Localcontrols232/0; no freshengineM0run, previous516/0notfreshproof.

### Previous R29 — reviewer correction applied; L2blocked; STOP/no P3

D0unchangedrawdata: .020000000000000823WUeach on designed .02slop. Verdict
CONTROL AT SLOP(0.02+roundoff), notFAIL; relativeexcess4.1e-14. Defectcomparison
>.02*(1+1e-9), REPORTONLY/no tuningedit. F79WITHDRAWN/no preexistingdefect.
Adopted/controlSlug3.514/Hopper4.670/Twin2.538: reprojectionmultiplies penetration
above designedslop, AC202as adopteddead/no-readoption. Caveatretained.

L1source8dfe959/CI40976842113 is zero-tick compilerlaunchincident, logsretained.
Ownerauthorized correctedfirst D1–D5 executions under[R29-once-2]. L2source
bb88cd1/CI40979233978job123814811746 NEVERSTARTED, steps[], zero ticks:
GitHubrecentpaymentsfailed OR spendinglimitneedsincrease (exactannotation in
fixtures/m1_r29_launch_incidents). Per second-failure instruction STOP, no further
launch/localworkaround. D1–D5NOTRUN with exactbillingblocker. Hoppermandatory
D2row+labelled10Slugaggregate planned, timings/countsNOTRUN; no3msPASS/FAIL.

Localcontrols232/0, core/startdiffEMPTY, tuning5f4d..666byteidentical. FreshM0
currentheadNOTRUN/billing; lastverified516/0 source2041793 is historicalproof.
Compile-only2041793success is NOT measurement. No P3/adoption/physicschange/
thresholdretune/soakrerun/FA3credit/M1complete. Sourcebb88literalclosed; L1logs,
D0gzip and L2checkannotations preserved. Report/evidence in.review/m1_r29_*.

### Historical R28 — adoption attempted, FAILED penetration, REVERTED

Measured446d870/CI40970023755:7200ticks/all3 complete; maxpenetrationWU
Slug.07028201067739755, Hopper.0933999293597247,Twin.05075245867956493.
All >=.02; hardstop, full adoption commit reverted75fd3e7. Current production
core/tuning byteequalfb890fd. Completedlimb errors roundoff do not authorise
adoption. Baseline-generation/replay, idle600 and characterisation3600 NOT RUN:
penetration stop, no substitution/referenceextrapolation. Await owner, no P2/P3.
FA3VACUOUS/UNCREDITED per owner, supersedes old policy-only creditedcount below.
GitHub artifactquota blocks rawuploads; numeric reports/rawfilehashes in check
annotations preserved. SourceCIstatic188thenfails shallow archivalgitobject;
regression-only fullhistory checkout preserves allassertions. M0source516/0.
F47only quarantined unchangedcommand/error/artifact; sourcejobREDfromquotabefore
F47, not diagnosticPASS or CIgreen. No tuning/slop/epsilon/iteration/retune/sweep/
brace change; no R27/soak rerun; no M1complete/device/determinism claim.
See `.review/m1_r28_adoption_report.md` and evidenceJSON for exactstop/blockers.

### Historical R27 measured record — stability FAIL, parked PASS, candidate for adoption

Source `2cf2c9376556feca5698ba176c63514f37284bed`, CI40960697692. Readonly
owner reviewer57ed098 read, NEVER copied. Full outputs/artifact digests:
`.review/m1_r27_evidence.json`, `.review/m1_r27_report.md`.

- AC201a **FAIL**35.34385590667538deg>15deg fromspawn; zero all-airborne ticks.
  Expected a/b stability pass was FALSIFIED, no endpoint/startup exclusion/retune.
- AC201b **PASS**actualnetCOM.6460243614279206WU=96.9036542141881px≤135px,
  .7178048460BL,1.393136xmargin. Owner85.5px/1.58x was steadyreference, NOTactual.
  .5BL fails;13.5px/s is disclosed steady extrapolation boundary, not a newknob.
- AC201s **FAILED**F52 neverfired,0sleepingticks; M1.1contact-model carry-over.
  Original GDDsettleANDsleep≤4s preserved, not met. a-failure needs M1.1posture
  investigation/ownerreview, cause not isolated; not another drift diagnosis.
- AC202 **PASS candidate ONLY**,7200ticks/all3/status0. ArticulatedlimbmaxWU:
  Slug4.996003610813204e-16,Hopper1.8318679906315083e-15,Twin1.7763568394002505e-15.
  Hopperliteral-limbmax1.8318679906315083e-15; no literal-kindlimbs inSlug/Twin.
  DefaultflagOFF; report correctnesspatch FORADOPTION, no productionbaseline change.
- FA3 **PASS staticwake-policy ONLY**,600ticks/all3,0sleep-breaking contacts;
  sleepingopportunities0all3. Not resting/sustainedsleep/grip acceptance.
- FA5 **PASS owner-reviewed original R26 archive**, no newphysicalrun,2–4tick
  transientpolicycoverage caveat and standing per-foot/branch tick-event definition.
- **AC204 PASS:** all200/200 runs,1,440,000/1,440,000ticks,20/20batches, no failed/nonfinite run, aggregateuniqueIDs verified.

Ledger at this snapshot: 13/18 qualifiedmeasuredslots;
12 measuredpassslots INCLUDE the unadoptedcandidate;
11 production-operational passes excludeit. AC201a+b parentisFAILED;
passingb alone adds no extra18-slot credit. Sleep failure separatelyvisible.
Historical8passes plusFA5/FA3, not the expectedAC201a+b+FA5 route. No acceptance
credit from harness existence, pendingsoak, absent literal-limbset or vacuousrest.

**Expectation: M1 will reach18/18 MEASURED, not18/18passing.** Not reached now.
FA4lurch/AC201ssleep depend oncontactrectifier/M1.1; actual201astability nowalso
FAILED. Owner16/18prediction is NOT claimed as a measuredclosing result. M2blocked.
D1/drift CLOSED, no brace/sweeps/knobs/slip/stiffness/damping/torque/epsilon/tolerance.
Ordinary public9053+308+1446/0 and FULLsummaryEXACT finalR26; tuning and baseline
bytes unchanged. Initial workflow key/skip-propagation fixes launched ZERO R27
engines on79c9ce2/823d1a5; first and ONLY physicalsource2cf2c93. R26closedstudies
allSKIPPED. No M2/camera/feel/lurch/crossarchitecture work; attempt1samebuild stands.

### Historical R26 — COMPLETE / BRACE REMOVED / OPTION2 / 8of18

Source114265e / CI40901902007: atomic brace removal, four P-B defaults retained.
D1 four6000-tick friction duplicates.9/.3/1.8/3.6: drift8.55015/9.39342/8.48216/
8.48216px/s; thrust.108186/.118855/.107325/.107325N. NOT proportional; dynamic
clamp/static override recorded, no located correctness-shaped cause => **Option2**.
D2 diagnostic7200, completed literal-limb max**.051910617942553194WU>.05**;
normal baseline7067observed, max**.05334550000967464WU>.05**, then tick7067
step_failure/status30/control30. No full7200baseline claim. Final distance restores
length to roundoff BEFORE contact; contact cleanup reintroduces failure; angular
phase equals prior hinge maximum. Diagnostic NOTadopted, no extra after-contact arm.
FA5 F77 original fourfixtures2412ticks completed, all4branches/law reconstructed;
airborne236foot/pass observations,6episodes; at/above27foot/pass,8episodes;
twofoot9pair/pass,3episodes; episodes brief2–4ticks, NOTsustained grip evidence.
Ledge departure83, no syntheticloads. Termination alwayslogged. Source reporter
schema/incomplete-baseline bugs repaired **ARCHIVEONLY**, job123551531542 SUCCESS,
0newphysicalruns/rawhashesmatched. No diagnostic rerun after source.
Generated P-BWITHOUTbrace baseline committedddefbba, ownDECISIONSprovenance;
fileSHA2779456f6a35338a97666bcec813608ae5bda83c612ec1d5b6560df62590f679
byteequaloriginalgeneration. SAMEsource publicPASS, committedpush+PR strictpublic
PASS9053+308+1446, fullpush/PRsummaryidentical.201PythoncontrolsCI, M0516/0+
Androidpush+PRSUCCESS; overallM1stillRED onlyunchangedF47/nonwaived.
Report `.review/m1_r26_diagnostic_report.md`; fullprecision/evidenceJSON adjacent.
No moremeasurement/sweep/brace/lurch, no new friction/slip/stiffness/damping,
no epsilon/.05 widening/mass/weight/waiver/M2/camera/captures. Core/dataunchanged
since114265e. Owner authors AC201 displacement/time number; originalcriterion
NOTrewritten, AC202honestFAIL. Nextsinglemilestone M1ownerOption2acceptancedecision.
HistoricalbraceF56columnretained/unchanged; matrix8/18, crossarchattempts0.
Final publication559e929 push40904855466/PR40904864867:202controls/publicSUCCESS;
originalarchive123556709209SUCCESS/0newphysical, BOTH per-tickphase reports
persisted in artifact12910322894; evidence EXACT firstaudit. M0push40904855470/
PR40904864938 headless516/0+AndroidSUCCESS; onlyunchangedF47 remainsred.

### Historical R25 — P-B ADOPTED / BRACE ACCEPTANCE FAILED / STOP / 8of18

Adoption8d73597 sourceCI40895082337, ownerR25decision (readreview9957260only).
BraceONdrift12.617730602141002px/s and ACTUALF52nosleep600public/6000idlerows:
STOPconditionsmet, NOretune. OFFexact8.550150769956836 reproduced. ONheldlurch
.140096WU vsOFF.140760WU, ONend-release-.061297WU: also weakenslurch/backslides.
F74 ONgains.7/1 x1s/5s allshort; bestONheld.26910BL/end.13690BL, sampledceiling
NOTglobalunlimitedholdbound. No contraction/gainrange widening.42,480rawticks,
42,322awakeF56verified/158explicitparkedrows, all7F56PASS/observerequal,724controls.
MaxpertickF56residual1.5543e-15/braceinternal7.7716e-16; measuredroundoffretained,
no fakezeros/addedtolerance. Baselinegenerated/provenance and strictpublicrerun
ONSAMEadoptioncommit9057+308+1446PASS, generatedbytescommittedfollow-up/no coreedit.
IndependentAC2027200ticksall3/allsegmentfootmax.09437/.19992/.09966>.05FAILED;
limb/motor/passivemax.06736/.10902/.07264>.05 too; actualAC202FAIL. FA5Hopper7067/7200/below+above+twofootobserved,
airbornecoverage0=>NOTPASS, abortcauseNOTLOGGED. Separatejobs/no bracedependency.
SourceCIstaticFAIL184(shallowgit-history assumption); goldenhash test-onlyfix,
local198PASS. HistoricalF47red/notwaived, M0516+Androidpush+PRPASS. Evidence/report
`.review/m1_r25_adoption_evidence.json`/`m1_r25_adoption_report.md`. Archive-only
auditSUCCESS123528127119,0newphysics; c169ded normalpublicpush+PRnewbaselineMATCHED/198controlsPASS.
Matrix8/18movement0 retained/no gatecredit; STOPforNEWownercontactmodelreview
or owner-authoredAC201number/specdecision. Bracedesignedstateflag/anglehashed/
restored, Phase4distinctpresentationdeferred/notrendered. No syntheticloads,
slip/sleep/mass/weight/tolerance changes/waiver/M2/camera/captures. D07/B04queued.

### Historical R24 — final round COMPLETE / STOP FOR OWNER P-A/P-B / 8of18

Source8110688 /push40890281324 /round123504891124 SUCCESS; exactlyA3+B1/24krawticks.
COLDarchive12901654637 read only (no3k/15armrepeat). Fullprecision/report:
`.review/m1_r24_round_evidence.json`, `.review/m1_r24_round_report.md`.
A slip.15/.015/.0015 drift12.9104235654/13.2677107689/13.2403280705px/s:
100xlessslip did NOT reduce creep. ProportionalhypothesisFALSIFIED; conditional
.00348556/.000339169/.0000339871WU/s targets UNMEASURED/unsupported/notadopted.
Bcommittedsameproposedlurch heldCOMx.02623016170054049WU=.029144624111711658bodylengths
(actualsumaxes.8999999999999999WU), NOTnear1; noformalFA4qualification.
Cold3driveqspreads7.105e-15/1.421e-14/1.377e-14rad butwithin-tick sampledqspread
~.11155/.11088/.10929rad, omega~1.187/1.234/1.269rad/s. F72frozen-throughout-tick
premisecontradicted; drivephase recurrence real, no uniquecontactcauseisolated.
F65CLOSED BY RE-SCALE: oldpowered all6000each0engaged/0projection/0block,
legalworkingpose, notdefaultfixed/adopted. F71empiricalfitnotrigidlimit. F73sign
corrected:k↑drift↑ andlurch↓, notopposingmetrics/no universalnomotor theorem.
FullF56all4/6000each/20windows eachPASS,maxpertick1.8874e-15/maxwindow6.9694e-14,
observer6000equal each; literalF56false/defaultexit1 unchanged. Raw/CSV/books
artifact12904553635 external.190Python/load80each/M0516+Androidpush+PRPASS.
PublicFULLsummaryEXACToldbaselinepush+PR, reproducedNOTregenerated; M1F47red/notwaived.
No core/default/creature change.8/18movement0/tenNOTRUN/FA5untouched/AC202notrun.
STOP: ownerchoosesP-Asaturated+visiblebrace OR P-Bc10+visiblebrace+baseline/lurch
provenance. Neitherchosen/adopted/implemented; braceauthorisedbutdeferred. No more
measurements/targettrials, noAC201rewrite/epsilon/waiver/M2/camera/captures.
FA6onsetsfixed0,4,..36 onlyvariance/one seedspawngeometryphysics/noFA6run;
provisional60pulse/fixed300horizon,B04layout/D07phonequeued. One boundedrounddone.

### Historical D09 — three proposals measured; STOP BEFORE ADOPTION

Delegated decisions ACCEPTED, not re-litigated: D09 proportional muscle, D08
physical hold first/fallback after adoption+remeasure, D06 provisional fixture now.
Source573a1fb /[study CI40885113085](https://github.com/sagheerh/clamber/actions/runs/40885113085),
job123486613471 SUCCESS, NOT an adoption/feel pass. Full evidence including ALL15
compact per-arm books `.review/m1_d09_study_evidence.json`.90000 raw awake ticks
preserved (15x6000); observer on/off snapshots bit-equal every tick. Plan registered
before results `.review/m1_d09_study_plan.md`. No new search after these3 triples.

| PROPOSAL (cap,k,maxTorque) | (30,10,12) | (30,20,12) | (30,40,12) |
|---|---:|---:|---:|
| Derived authored critical c |.5443327361211717|.7698027378662161|1.0886654722423434|
| Working q/residual mean rad, both |.22316866039209582|.08996254195334404|.032108711886440405|
| Same degrees |12.78662236005547|5.1544739681952185|1.839693676694575|
| Settled pose |null|null|null|
| Requested /applied mean impulse, both |−.04796602541507495|−.0458210036063169|−.044435404255268936|
| Measured bound mean, both |.19558495337204906|.19072949096919847|.18864020539110127|
| MAX abs requested/bound over holding300 |.24524394432241023|.24024079010266033|.23555638186010233|
| Constraint /upstream torque /body-speed clip ticks, holding300 |0/0/0|0/0/0|0/0/0|
| Both drift px/s |8.550150769956836|11.479241947750111|12.910423565431365|
| Stop-only drift px/s |5.374919874839947|5.374919874839947|5.374919874839947|
| Drive-only drift px/s |8.550150769956836|11.479241947750111|12.910423565431365|
| Inert drift px/s |.08403595917824255|.08403595917824255|.08403595917824255|
| .3−abs(drift) margin, both px/s |−8.250150769956836|−11.179241947750111|−12.610423565431365|
| First F52 eligible from spawn, both |NONE/all6000|NONE/all6000|NONE/all6000|

Headroom COMPONENT observed on all300 both/drive-only samples (<=.5), no motor
or constraint clipping. NOT a qualified settled-holding pass: exact settled pose
not established; null is honest, late q ranges in evidence, no fitted equilibrium
or tolerance. F52 is counterfactual observer on AWAKE trace, not parking/AC201.
Improved angular residual/linear headroom did NOT yield station-keeping. All both
runs exceed derived.3px/s and never eligible F52, so no D08 pass/comfortable margin.
No choice among these proposals adopted. Do NOT raise bound beyond proposed30.

Damping derived, not guessed: I=m*extent²/4 for endpoint-mass capsules;
Ieff=1/(inverseIp+inverseIc); ccrit=2sqrt(kIeff)=2sqrt(k/weight). Evaluated authored
actual geometry, independently checked from first raw endpoints/masses; FIXED
coefficient, not adaptive. Loaded zeta evaluated at mean measured bound is
1.0659267588569554/1.0794093119953925/1.0853703537887764, not exactly1. Continuous
linear critical damping does not guarantee nonlinear/discrete critical response.
Fixed60Hz, all mass/weight/gravity/damping/sampling/geometry defaults untouched.

Proposed lurch protocol, NOT FA4:95s released,1s held L,4s released. Per candidate
held COM displacement(dx,dy) WU (.14075959883633615,−.03773132734892369),
(.0922175655125983,−.027562900329371712),(.02659880134783954,−.02425724510597177).
By end of release net dx.226660160625884 /.17072013762592775 /.10107116872395494WU.
Peak abs q while held1.3206488294384926 /1.1023759695753468 /.9638602332030473rad.
Mixed pulse/release300 torque cap clipping3/7/9ticks, constraint clip0 each;
mean_clamped_total_torque retained in each raw summary joints. First post-release
F52 eligibility after82/66/64 ticks (awake observer ONLY, not actual sleep/pass).
No new pulse success threshold/bodylength pass invented. Script is a PROPOSAL.

Full F56 EACH of15 runs PASS; all per-tick/window internal/damping/contact/clamp
raw guards preserved at1e−12. Largest abs window residual4.565792188770956e−14.
Complete vector sums per arm in evidence with explicit column order, full books/
per-tick reference comparisons in artifact. Literal F56 NOT redefined; original
R18 false/default exit1 record and distinct R19 complete authorization preserved.
Three permanent limit columns: both/drive-only/inert late300 all0 drive-time
violation rad /actual correction rad /angular-phase endpoint WU; stop-only each
has max drive violation.15296479246883943rad /sum correction52.738773834409294rad /
endpoint magnitude16.485775953383605WU, engaged300/300. Different units retained.

PUBLIC replay/clock RERUN on573a1fb, push and PR SUCCESS:FULL summary EXACT old
committed Phase2 baseline,9053+308+1446 checks. Baseline REPRODUCED, NOT regenerated;
first future adopted solver change must rerun and regenerate with provenance.
185 Python PASS, load80/0 eachrun; M0push40885113136/PR40885121681 headless+Android
SUCCESS516(514+2auto compile). Existing F47 component job remains FAIL; historical
sweeps skipped/not waived. D09 artifact12901654637 /398343994B/SHA
3b82aac1ee32484c89e85503a7b4c86b0518a58ed72f87ddcee5ee57341443d5. All compact
annotations/axis books/API metadata inspected, NOT raw ZIP. Closeout [skip ci]
prevents any repeat; source results authoritative, not claimed remeasured at head.

Core default SHA3a32dd3d2d719ed28220ed531fee05c8d2a799140d3f06e3aeed4d28d6e6f60c
unchanged; core/creatures byte-identicald582a30. Candidate tuning.tres resources
are diagnostic proposals applied only to process-local copies;90 exits per wide
arm, default40 remains. Old R23 2x2 retained as OLD parameterisation/history.
D06 authored data/towers/provisional_fa6.json: floor/oneledge/spawnmarker/script,
PROVISIONAL layout/success proposal underB04, NOT product content/FA6 run. Existing
10run/6–8 targets unchanged. Exact identical state/input deterministic runs yield
identical outcomes; no invented noise/seed variation to manufacture6–8. Phase4
execution contract must respect that, no fake qualification. D07 phone queued.
No hold/freeze now: approval/adoption/provenance+fullremeasure precedes defined
fallback. No AC202/FA5 parallel run here;8/18 movement0, ten gates NOT RUN/FA5
untouched, A/residual obsolete, Phase3 not entered, no M2/camera/captures/waiver.
NEXT single milestone: owner review of measured D09 proposals BEFORE adoption.

### Historical R23 — causal investigation CLOSED; WAIT for owner D09 AND D08

R23 review ofd76b88e and owner decision sheet read ONLY with git show from
arena/5b72e4ab-clamber; neither copied/merged into this tree. The decision sheet
contains OPTIONS/RECOMMENDATIONS, NOT owner answers. No choice inferred.

Inert cell ACCEPTED: .08403595917824255px/s vs free-hinge.08403595917823123,
difference1.1324274851176597e−14px/s; all6000 requested/applied drive EXACT0,
no engagement/projection/block impulse, three separate columns0, completeF56PASS.
Source facts remain `.review/m1_r22_inert_evidence.json`; no measurement rerun.
No inert-row defect; baseline-return branch supported. Investigation CLOSED.

F69 OWNER finding: two mechanisms, each independently sufficient for amplification
above the free-hinge floor in the measured fixture, neither individually necessary:
drive-only2.950043883090746, stop-only5.387448117922983, both3.9345242550809765.
Non-additive interaction/partial cancellation relative to STOP-ONLY; arithmetic is
2.95 <3.93 <5.39, NOT combined less than both single-mechanism cases. Architectural
choice, not further coefficient hunting. Owner's no-torque-knob conclusion recorded
for these measured saturated configurations; not a proof over every untested
coefficient/pose/mass, nor a preselected D09 or D08 answer.

F70 permanent caveat: inert drive-time q range1.563079699374753–1.5630796993747635
rad ≈89.558degrees, only≈.442degrees inside upper90 (late300 window). Released,
unpowered loaded sag≈89.6degrees from authored rest in THIS fixture. Narrowing
to85/89 excludes that measured posture, changes engagement/inertness premise, and
is NOT an equivalent repeat. Exact drift at those untested bands is UNMEASURED;
reviewer's≈3px/s counterfactual is not cited as a run. No narrower-band test.
Drive-time error rad / actual angular correction rad / endpoint displacement WU
remain permanent separate columns. F58 correction attributed to OWNER/reviewer:
identity predicts mean COMPLETED velocity (<1% agreement in review), not positional
drift. Reference4.014820668450256px/s completed versus3.9345242550809765 positional,
about2% gap; two claims, not one. Existing accounting/raw books unchanged.

Public-Sim replay/clock job DID NOT RUN on d76b88e (nor on this documentation-only
closeout). Last measured public replay is63cb024 /CI40878101597, also accepted on
74c629e. Skipped jobs unpassed, not waived. FIRST SOLVER-CHANGING COMMIT MUST rerun
public-Sim replay AND clock jobs: reproduce committed baseline or, only when owner
has authorized changed physics, regenerate with provenance. No skip-ci solver
change, no unsupported up-to-date replay claim. This closeout docs ONLY [skip ci]
prevents any further arms. Solver/tuning/creature bytes unchanged; default40.

WAIT for BOTH explicit owner answers: D09=bang-bang OR proportional;
D08=hold OR accept-creep OR other AS OWNER WRITES IT. Until then no experiments,
tuning, hold implementation, AC201 reinterpretation, baseline regeneration or
runtime gates, including no AC202/FA5 start now. After answers ONLY: (1)D09 increment
(document effective motor authority/retire misleading strength labels, OR owner-
authorized proportional re-scale inside measured bound with baseline provenance/
regeneration and allfour arms remeasured); (2)D08 increment; (3)Phase3 AC201/202,
FA3/4/5. AC202/FA5 MAY run in parallel WITH the authorized D09 increment after
answers, with evidence separated by workstream/commit/configuration, never mixed.
No instruction in the reviewer recommendation substitutes for owner authorization.
D06/D07 queued; A/residual withdrawn/obsolete; no Phase3/baseline changes.
8/18 movement0, ten NOT RUN/unmoved, FA5 untouched; attempt1 same-build observation/
cross-arch0 retained. NEXT single milestone: WAIT for owner D09 AND D08 answers.

### Historical R22 — missing cell returns to baseline; experiments STOPPED

Source **eea4e52**, [M140880532917](https://github.com/sagheerh/clamber/actions/runs/40880532917),
job123470523762 SUCCESS. Reviewer source read via git show ONLY, never copied/
merged. Exactly ONE new arm: gain0+upper90/default bound6, all6000 raw ticks,
late300 ticks5700–5999. Full facts `.review/m1_r22_inert_evidence.json`.

| Single gain0 + wide90 arm | Measured |
|---|---:|
| Drift px/s |.08403595917824255|
| Existing free-hinge baseline px/s (NOT rerun/regenerated) |.08403595917823123|
| Difference px/s |1.1324274851176597e−14|
| Rectified friction impulse/tick |.00001772186894237695|
| Mean thrust N |.0010633121365426171|
| Drive-time max band violation rad |0|
| Actual summed angular correction rad, last300 |0|
| Angular-phase endpoint displacement WU, last300 |0|
| Limit engaged last300 / all6000 |0 /0|
| Requested / applied drive ALL6000 |EXACT0 /EXACT0|
| Limit-block impulse ALL6000 |EXACT0|
| Measured bound / applied mean / sat ticks |.04442255333602155 /0 /0of300|
| mean_clamped_total_torque |0|

Three columns stay permanently separate: drive-time error rad, actual per-pass
correction rad, original endpoint-phase displacement WU. Also audited all6000:
no positional or velocity engagement, all projection endpoints unchanged, exact
binary64 predicates agree,0 decimal disagreements. Inertness verified rather
than inferred from flags. Observer on/off physical snapshots equal every tick.
Baseline-return branch supported; no inert-row solver/plumbing defect exposed
in this fixture. Operationally either angular path alone amplified creep in prior
cells; jointly off returns to baseline. Do NOT restore a scalar brake mechanism
or a universal35x floor: inert row's mere presence does NOT impose that floor.
No fitted replacement source, new causal ordering claim or further experiment.

Complete F56 PASS; per-tick/window raw contact/damping/clamp/internal guards
unchanged1e−12. Window sums mass*WU/s:

| Axis | Δp | Contact | Damping | Gravity | Complete residual |
|---|---:|---:|---:|---:|---:|
|x|−7.697835424647081e−18|.005316560682713085|−.005316560682713103|0|1.6263032587282567e−18|
|y|0|217.98051714817854|−.9805171481785386|−217.00000000000003|3.880229471064922e−14|

Clamp/internal_drive0 in both axes; internal_velocity x8.023096076392733e−18,
y−6.827871601444713e−15 (unchanged bookkeeping tolerance, NOT exact zero claim).
Literal contact-only F56 for THIS cell still false x−.005316560682713093 /
y−217.98051714817854, not silently redefined. Original R18 record/default exit1
unchanged; distinct R19 complete authorization applies, not a remedy waiver.

180 Python controls PASS locally/CI; load80 checks0fail in one cell. Manual
Actions dispatch was deniedHTTP403 BEFORE any run, so one explicit push marker
triggered this cell. PR cell SKIPPED, legacy runtime jobs manual-only/SKIPPED:
no old arms rerun; not passed/waived/closed. Prior public/complete-F56/F47 evidence
retained, no new determinism attempt or acceptance claim. Raw artifact12900316209,
21060464B/SHAcbad831725ce1a51c0bcbaf22650a14a3ca31c17e5175219c514ffe30358de2c;
complete compact annotations/API metadata inspected, NOT raw ZIP.

40 resourceSHA3a32dd3d2d719ed28220ed531fee05c8d2a799140d3f06e3aeed4d28d6e6f60c
unchanged throughout/nextcommit;90 ONLY exited process-local duplicate. Resource/
creature bytes identical74c629e; core +GD harness identical63cb024. No tuning,
solver/telemetry changes, baseline regeneration, A/residual, Phase3 or new arms.
F67 drive-is-brake mechanism withdrawn by OWNER, measurements retained. F61
nonzero late drives constrained incl3080x bound1; gain0 switches off, upstream
request clamp still acts, no universal claim about untested linear regimes.

F68 recorded as OWNER structural finding for current measured fixture/defaults:
creep contradicts settle/sleep≤4s, not just a band defect. AC201 ORIGINAL predicate
unchanged/formal gate NOT RUN; no proof over all poses/masses/bands. D08 now owner
station-keeping/design decision: widen measured insufficient; pose/mass change
UNMEASURED (wide90's3%/25% is not an upper bound on arbitrary redesign); intended
stop/re-scoped sleep/net-displacement interval needs OWNER-authored numbers.
Reviewer recommends intended stop plus explicit station-keeping/hold requirement,
recorded only for OWNER decision. No recommendation or acceptance rewrite adopted.
D06 tutorial/D07 device queued.8/18 movement0/ten rows NOT RUN, FA5 untouched,
attempt1 same-build success/cross-arch0; RNG not consumed. STOP NOW; next single
milestone OWNER D08 decision/handoff only, no further sweep or implementation.

### Historical R21 — BOTH predictions falsified; no remedy, runtime8/18 unchanged

Measured source **48d54df**, [M140877081798](https://github.com/sagheerh/clamber/actions/runs/40877081798),
limit job123458547461. Reviewer read via git show ONLY. Full evidence/complete
F56 books: `.review/m1_r21_limit_evidence.json`. All6000 per arm preserved, last300
5700–5999 reported; no baseline regeneration, retune, A/residual or Phase3.

| Late300 quantity | reference40 / bound6 | wide90 / bound6 | restored40 / bound1 |
|---|---:|---:|---:|
| Drift px/s |3.9345242550809765|2.950043883090746|3.5208063727143637|
| Requested mean angular impulse |−21|−21|−21|
| Measured bound / abs applied mean |.04119350481568311|.0424424871905789|.006817925509442767|
| Saturated ticks/300 |300|300|300|
| Positional / velocity limit ticks/300 |300 /300|0 /0|300 /300|
| Max drive-time band error rad |.1500058532205718|0|.1703507114114703|
| Max actual pre-projection error rad |.06331083047340813|0|.18088463121580023|
| Sum requested abs angular correction rad |21.12756976216022|0|71.1119478417996|
| Same rad per tick, all6 passes summed |.07042523254053407|0|.23703982613933203|
| Observed abs angular rotation rad |21.127569762160093|0|71.11194784179956|
| Angular-phase net endpoint magnitude sum WU (Euclidean/end) |6.637221585009945|0|22.080763658493435|
| Angular-phase net L1 endpoint-coordinate sum WU |8.83565758768492|0|29.13103935554537|
| Max abs limit-block impulse |.00010279054374075919|0|.000621232531100805|
| mean_clamped_total_torque |−1260|−1260|−1260|
| Complete F56 residual x |−6.453171330633722e−16|2.636779683484747e−16|1.1622647289044608e−16|
| Complete F56 residual y |3.544387006115812e−14|3.1009916856561404e−14|4.0023540037736893e−14|

**F64 necessary-stop prediction FALSIFIED:** wide90 eliminates ALL6000 positional
and velocity limit engagement, all block impulse EXACT0, all angular phase endpoint
changes and corrections EXACT0; drift remains2.9500, not owner.08–.5/free-hinge
.08403595917823123. Limits affect result, but are NOT necessary for this motion.
Do not infer a replacement source from these two separate removals. Drive-time
q/error is not each iteration's error: reference actual pre-projection max.06331
rad and summed correction.0704252rad/tick, not.1444rad per pass. WU ledger is NOT
radians. All endpoint projection deltas independently agree with that ledger.

**Bound-sign prediction INVERTED:** weakening bound lowers drift3.9345->3.5208,
not toward gain0's5.3874. Delivered mean ratio.16550972149490567, not assumed1/6;
wide90 ratio1.0303198861200147 because actual extents differ. All three saturated
300/300/body-speed-limited0/300. Mean requested/bound509.7898575451301 /
494.78875517194655 /3080.1157876576485. This global cap also caps limit rows;
report comparison, not an invented drive-only causal isolation or fitted story.
Raw per-tick differences: wide5978/6000 (first22), bound15998/6000 (first2) applied
changes>existing1e−12 precision; late300/300 each. Late max endpoint position/
velocity deltas vsreference .6584274093417979WU/.5239526882687735WU/s wide and
.2893301216031765WU/.4970773351685527WU/s bound1. Not fulltrace identity.

First source0943087 produced both traces but rejected bound1 reporting on a
boundary-predicate mismatch. Rerun48d54df records exact IEEE754 binary64 q/limits/
omega:39 late300 and1746 all6000 decimal-vs-binary predicate disagreements in
bound1, zero in reference/wide. Exact decoded predicate matches actual bool;
independent raw geometry/velocity audits retained, no epsilon/physics change.
Complete F56 EACH arm passed, per-tick/window internals within unchanged1e−12,
resource damping/raw-contact/clamp guards retained. Full books emitted in compact
annotations. Original F56 literal FULL record EXACT R18, still false/defaultexit1;
separate R19 complete authorization NOT redefinition. Bound1 window Δp_x is
.00009481202500825903, nonzero; don't impose reference F59 on it.

Default40/SHA3a32dd3d2d719ed28220ed531fee05c8d2a799140d3f06e3aeed4d28d6e6f60c
unchanged THROUGHOUT and rechecked nextcommit. Wide90 only process-local duplicate
exited; bound1 fresh40. No tuning adopted. F65/D08 is band-versus-loaded-pose/
authoring question; authored q0 legal, observed loaded rocking q>40 not proof
q0 unreachable or stationary equilibrium. Target0 for released input, not held
−62degrees×.7. F66 actual measured bounds supersede nominal arithmetic. F61 stays
record-only; owner R20 propulsion claim withdrawn; R19 late stiffness0 VOID.
A WITHDRAWN/residual OBSOLETE; no Phase3/baseline regeneration.

Source regression:176 Python PASS;931 mechanics/4897 sleep/381 math/237 contact/
136 analytic/80 load; public9053+308+1446 PASS and FULL summary EXACT accepted
Phase2. M040877081778 SUCCESS516(514+2auto compile)/Android. M1five SUCCESS,
unchanged F47 components FAIL plus R21 both owner predictions FAIL honestly.
Raw artifact12898288698 /119472146B/SHA779908f38d1546178d32e137ab004b5848b0a7b0cf0965a433ee9fa86ba71d28;
API metadata/complete annotations inspected, NOT raw ZIP. Eight accepted rows
unchanged; ten NOT RUN/unmoved: AC201/202/204, presets/captures, tickcost,§10.6,
FA3/4/5/6. Attempt1 same-build success/cross-arch0; RNG not consumed. INV/five-fakes/
A12 pending, FA5 unchanged/F41 count buckets open. D08/D06/D07 queued, never blocked
these completed diagnostics. NEXT single milestone: owner R21 evidence review /
D08 direction before an adopted remedy or further experiments; no inferred choice.

### Historical R20 — exact zero drive still walks; inference withdrawn by owner R21

Measured source **8e0b907**, [M1 CI40868433005](https://github.com/sagheerh/clamber/actions/runs/40868433005),
saturation job123429003201. Reviewer R20 read via git show ONLY; no reviewer
artifact copied/merged. F60: prior R19 spring-source conclusion WITHDRAWN; the
late-window motor-stiffness intervention is VOID/uninformative, not falsifying.
F62: owner WITHDRAWS A, not a conditional setup-remedy authorization.

**F63 teeth, last300 ticks5700–5999 of6000/arm**. Impulse is angular
mass*WU^2/s; bound×inverse-inertia-sum is relative angular-speed increment rad/s.
Original damping .02/55, stiffness2400 (except historical stiffness0 record),
materials/geometry/sampling unchanged; gain0 changes ONLY duplicate diagnostic
gain. Requested/bound/applied independently reconstructed from raw PRE-DRIVE
endpoint positions/velocities/inverse masses. Both cumulative constraint bound
and absolute-body-speed clamp audited on EVERY tick. All6000 observer-on/off
physical snapshots identical in every arm. Keep mean_clamped_total_torque.

| last300 measurement | reference2400/gain.7 | historical stiffness0/gain.7 | gain0 |
|---|---:|---:|---:|
| drift px/s@150 | 3.9345242550809765 | 3.9345242550808814 | 5.387448117922983 |
| rectified friction impulse/tick mass*WU/s | .0008297296048130507 | .0008297296048130529 | .0011205429121987627 |
| mean thrust force N | .04978377628878304 | .04978377628878317 | .06723257473192576 |
| mean requested angular impulse | -21 | -1.8121243561338403 | 0 |
| mean actual bound | .04119350481568311 | .04119350481568311 | .04124893340210059 |
| mean applied angular impulse | -.04119350481568311 | -.04119350481568311 | 0 |
| mean clamped total drive torque | -1260 | -108.72746136803042 | 0 |
| saturated ticks/300 | 300/300 | 300/300 | 0/300 |
| body-speed-limited ticks/300 | 0/300 | 0/300 | 0/300 |
| complete F56 residual x | -6.453171330633722e-16 | -2.914335439641036e-16 | 1.734723475976807e-17 |
| complete F56 residual y | 3.544387006115812e-14 | 3.1780134079895106e-14 | 3.0281332996651145e-14 |

**Gain0 requested AND applied impulses exactly0 on ALL6000 ticks**, not inferred
from a torque term or mean. This intervention removes actual drive, changes
applied impulse on300/300 late ticks, and changes trajectories. Drift INCREASES
to5.387448117922983 instead of collapsing toward free-hinge.08403595917823123.
**STOP per ORDER1.** Bound6/1 and optional.5degree-residual diagnostic NOT RUN;
A withdrawn/NOT RUN, no calibration/target/snapshot/baseline change or Phase3.
Nonzero MOTOR drive is not necessary for motion in this arm. Remaining contact/
limit/constraint paths are candidates, not a newly proven attribution to a row.
Do not tune damping or repair F61 based on this observation.

F60 actual late requested/bound ratios: reference509.7898575451301 mean,
stiffness0 43.98614805264008 mean; both300/300 at constraint bound. Applied
pair differences max3.3306690738754696e-16, none above existing1e-12 precision.
VOID for the late-window spring-source inference, NOT literal identical full
trajectories: late endpoint position difference.0037990209470555314WU and
velocity difference4.440892098500626e-15WU/s are published, full startup/each-tick
differences retained. Gain0 late applied difference mean_abs.04119350481568311,
endpoint position difference max.9682391801293719WU, velocity.32983720436516883.

**F61 record-only, separate nominal vs actual geometry.** Committed preset/resource:
head mass.77,length.35,inverse-inertia42.40657301881792; motor.48,.30,
92.59259259259261. Sum134.99916561141055; nominal-rest bound.044444719141974176,
deliverable torque2.666683148518451 vs authored1260 =.21164151972368656percent,
overshoot472.4970796399368. Late ACTUAL bound is smaller(.04119) because actual
endpoint extent, not authored rest length, drives inertia. Torque knobs are
masked in this saturated regime; global cap/current inertia controls delivery.
No claim of equal angular impulse on all joints/presets or all operating regimes.
No tuning changed. F62 nominal spring-only residual.0011111179785493544rad
(about.064degrees) recorded as owner's arithmetic, not an implemented dead band
or a fixed-point proof including damping. A is WITHDRAWN, not labelled failed.

F55/F58/F59 original reference story preserved together in R19 evidence below:
22.5px/s allowance; .1147percent-weight rectified thrust balanced by2percent
damping; completed4.01482 vs positional3.93452px/s; positive-velocity6-count
rocking cycle, settled=false/null; AC-201 zero-input zero-net-motion AND sleep
within4s, no relaxation. Do not silently assume the new gain0 arm is the SAME
stationary-momentum cycle. F57 RNG injection/snapshot/restore/hash NOT physics use.

Regression @8e0b907: static167Python; public9053/0 plus frame30 308/0/frame144
1446/0. Full summary EXACTLY equals accepted Phase2/sourcee193 including strict
baseline MATCH, triple31,131,584-byte streams/hashes/bitflip/stall/startup601 vs600.
Accepted attempt1 same-build SUCCESS retained; cross-architecture0. Components
931mechanics/4897sleep/381math/237contact/136analytic/80load. M1 RED existing F47
plus gain0 no-collapse gate; other FIVE jobs SUCCESS, corrected F56 included.
[M0 CI40868432785](https://github.com/sagheerh/clamber/actions/runs/40868432785)
PASS516/0+Android export/alignment; original514 plus two automatic script compile
checks, not expanded M0 functional coverage; no device timing measured.

Raw saturation artifact12894668288,84,981,954B,
`sha256:62ab6598d022df12dd85679ca541ecb21bd6034176fd73d9fa670a16f6c7332b`.
Full three6000 traces, report, requested/applied books and per-tick reference
trajectory files retained in CI. Complete compact annotations/metadata retrieved;
no local ZIP inspection claimed. `.review/m1_r20_saturation_evidence.json` records
source/arms/F61 arithmetic/counts/public summary/artifacts/STOP.

**Runtime8/18, movement0.** Remaining10 unchanged/NOT RUN: AC-201/202/204,
presets/captures,tickcost,§10.6,FA-3/4/5/6. FA-5 untouched; no acceptance-table
upgrades. Original F56 literal record/predicate/default exit1 retained EXACTLY,
complete form re-run on EVERY diagnostic arm within existing1e-12. Full per-arm
F56 ledgers exported, not hidden by terminal-velocity approximations.
**Next single milestone M1:** owner review of zero-drive persistence before any
authorized contact/limit isolation diagnostic; no further arm/remedy run now.

### Historical R19 — motor0 thrust unchanged; inference WITHDRAWN by R20

Source **217eda1**, [M1 CI40864407948](https://github.com/sagheerh/clamber/actions/runs/40864407948),
motor falsification job123415407058. Read reviewer R19 using git show ONLY; no
reviewer artifact copied/merged. Owner closes F56 on complete external balance
and owns omitted gravity/damping. Explicit `--r19-complete` authorizes THAT form;
original literal definition/numbers/failed predicate/default exit1 retained,
not overwritten. Full F56 job123415406812 now SUCCESS, literal identity EXACTLY
equals prior R18 record, per-tick/window internal-zero/damping/contact guards kept.

**Ordered motor-source falsification:** unchanged actuated legal after-pose,
6000 ticks/arm; actual last300 ticks5700–5999. Resource/default stiffness2400,
duplicate diagnostic tuning0 ONLY. Linear damping.02, motor damping55, passive
stiffness900, geometry/material/solver sampling unchanged. Observer on/off
physical snapshots identical for all6000/arm; all raw F31 checks retained.

| measured last300 | motor2400 | motor0 |
|---|---:|---:|
| net positional drift px/s@150 | 3.9345242550809765 | 3.9345242550808814 |
| signed rectified friction impulse/tick mass*WU/s | .0008297296048130507 | .0008297296048130529 |
| mean completed COM vx WU/s | .02676547112300171 | .02676547112300171 |
| mean completed COM vx px/s | 4.014820668450256 | 4.014820668450256 |
| mean spring torque (before clamp) | -2022.0812958538024 | 0 |
| mean damping torque (before clamp) | -108.72746136803043 | -108.72746136803042 |
| mean clamped total drive torque | -1260 | -108.72746136803042 |
| mean abs(q) rad, NOT captured q_settled | .8425338732724178 | .8425338732724177 |
| full window momentum residual x | -6.453171330633722e-16 | -2.914335439641036e-16 |
| full window momentum residual y | 3.544387006115812e-14 | 3.1780134079895106e-14 |

**Motor0/live absolute thrust ratio1.0000000000000027; NO COLLAPSE.** Spring
torque is verified zero on EVERY motor0 tick, not just its average; intervention
is real (total drive torque changes), unlike the earlier passive no-op. Thrust
is about47.7 times owner's1.74e-05 reference in BOTH arms. STOP does not depend
on an arbitrary collapse ratio/boundary: removing spring stiffness changes
neither measured thrust nor drift beyond roundoff. Spring stiffness alone is
not the source/removal mechanism supported by this experiment. Remaining damping,
angular constraints/contact dynamics stay active; no unmeasured cause assigned.
No A calibration, fixed-point capture, snapshot/hash/baseline change or Phase3.

**F55/F58/F59 mechanism story together:**
- F55: .15WU/s ×150 =22.5px/s allowance. Free-hinge .08403595917823123px/s
  (.373493percent); actuated before3.5133210565803203 (15.614760percent), after
  3.9345242550809765 (17.486774percent). Drift magnitude alone is NOT a leak.
- F58: signed thrust .0008297296048130507/tick ×60 =.04978377628878304N,
  .11470916195572128percent of43.4N. Divide by .02×1.55 to predict completed
  COM vx .026765471123001636WU/s, error -7.28583859910259e-17. Motor0 preserves
  that force-balance story but falsifies removal of spring stiffness as the
  proposed way to collapse it. Damping is UNCHANGED. Completed velocity4.01482
  px/s differs from net positional drift3.93452px/s: publish both, not interchangeable.
  Normal support43.15669199578477N, deficiency.2433080042152298N < original.723N
  ALL-grounded allowance; no foot-only generalization/gate change.
- F59: observed positive-vx rocking walker, not stationary equilibrium. Both
  have6-tick count recurrence; binary64 repeat differences retained, not called
  exactly repeating physical states. Keep measured settled=false/settled_mean=null.
  For a live spring AC-201 is zero-input zero-net-motion as a design property,
  AND original settle/sleep-within4s; do not relax it or wait for a convergence
  classifier to turn a translating cycle into rest.
F57 unchanged: RNG injected/snapshot/restored/hashed, NOT consumed by physics.

Regression @217eda1: static158Python; public9053/0, frame30 308/0 and frame144
1446/0. FULL public summary EXACTLY equals accepted Phase2 ledger/sourcee193:
three31,131,584-byte streams, all hashes/bit flip/stall/startup601 vs600 retained,
strict committed baseline MATCH. Attempt1 same-build SUCCESS retained;
cross-architecture attempts0. Components931mechanics/4897sleep/381math/237contact/
136analytic/80load. M1 RED: existing mandatory F47 plus new motor-source
falsification; other FIVE jobs succeed (including corrected F56).
[M0 CI40864408031](https://github.com/sagheerh/clamber/actions/runs/40864408031)
PASS516/0 + Android export/alignment; original514 plus two automatic script
compile checks, not improved M0 functional coverage. No device timing measured.

Raw motor artifact12892823108,54,619,368B,
`sha256:d156dc87d03abbd65cd19fb2c1ca5f196715a4f785104e5700e493e01b464fee`.
Full raw two-arm traces/logs/report retained in CI. Complete compact annotations
and artifact metadata retrieved; no local ZIP inspection claimed. Source/full
numbers/public summary/artifacts: `.review/m1_r19_motor_evidence.json`.

**Runtime8/18, movement0.** Remaining10 unchanged/NOT RUN: AC-201/202/204,
presets/captures, tickcost, §10.6, FA-3/4/5/6. FA-5 untouched, accepted F52/53/54
not reopened. A target-tracking/zero-spring capture direction retained
conditionally, but calibration ticks/q_settled/awake fixed-point proof/after-A
drift/thrust and AC-201 sleep tick **NOT RUN**, not invented from motor0 q mean.
No baseline regeneration. **Next single milestone M1:** owner review of failed
motor-source falsification before authorizing any revised diagnostic/remedy.

### Historical R18 — F56 literal prerequisite FAIL; STOP before sweep/A/Phase3

Measured source **832fa3d**, [M1 CI40820719982](https://github.com/sagheerh/clamber/actions/runs/40820719982).
F56 job123272312328 reconstructs raw endpoint momentum/contact events from the
last300 ticks (5700–5999) of the unchanged actuated-after6000 arm. All6000 raw
rows first pass existing F31/full-ledger checks. Existing precision1e-12;
impulse units mass*WU/s. Literal residual is LEFT minus RIGHT, no force omitted
by relabeling the left-hand side.

| last300 sum | lateral x | vertical y |
|---|---:|---:|
| raw COM momentum change | -4.163336342344337e-16 | 1.4432899320127035e-15 |
| ground normal | 0 | 215.78345997892384 |
| ground friction | .24891888144391522 | 0 |
| literal contact-only residual | -.24891888144391563 | -215.78345997892384 |
| existing linear damping | -.24891888144391586 | 1.2165400210761605 |
| gravity | 0 | -217.00000000000003 |
| clamp | 0 | 0 |
| internal drive | -1.249000902703301e-16 | -1.942890293094024e-16 |
| internal velocity constraints | 9.922618282587337e-16 | -9.825473767932635e-15 |
| full residual reconstructed from summed sides | -6.453171330633722e-16 | 3.544387006115812e-14 |

**Literal F56 FAILS, exit1, STOP honored.** The complete balance closes within
1e-12, with internal terms at roundoff. This is evidence of omitted external
forces in the literal equation, NOT measured evidence of an internal momentum
leak. The complete balance is NOT substituted for the requested prerequisite.
Reporter additionally rejects cumulative internal leaks (even sub-precision
per-tick leaks accumulating above precision), with a negative control.

F55 report-only: .15WU/s ×150px/WU = **22.5px/s** authored static-slip allowance.

| measured drift | px/s | percent of22.5 |
|---|---:|---:|
| free-hinge after | .08403595917823123 | .373493 |
| actuated before | 3.5133210565803203 | 15.614760 |
| actuated after | 3.9345242550809765 | 17.486774 |

A COM-unit comparison, not proof of every contact's instantaneous static branch;
3.934px/s alone is NOT an internal-leak finding. Correct motor2400/0 sweep with
damping untouched: **NOT RUN**. A calibration protocol/rule/justification:
**NOT SELECTED/APPLIED** because prerequisite failed. Owner A direction retained;
B/C remain rejected. After-A drift and AC-201 sleep tick: **NOT RUN**, no numbers
invented, no baseline/tuning/snapshot change. Phase3 not entered.
F57: RNG is injected/snapshotted/restored/hashed, but physics does NOT consume it.

Regression @832fa3d: public9053/0 + frame30 308/0 + frame144 1446/0, complete
summary EXACTLY equals accepted9a/sourcee193 including all stream hashes and
strict committed baseline MATCH. Accepted attempt1 same-build success retained;
no new failed determinism attempt. Static152Python; mechanics931/sleep4897/
math381/contact237/analytic136/load80 pass. M1 RED for existing F47 plus literal
F56 (other four jobs succeed). [M0 CI40820720016](https://github.com/sagheerh/clamber/actions/runs/40820720016)
PASS516/0 + Android export/alignment; original514 plus TWO automatic script
compile assertions, not added M0 functional coverage. No physical device timing.

Raw F56 artifact12874039236,27,349,952B,
`sha256:d243bd5083b07d5ef56bcdec07a990f7e03767fd895fba861e4f3e616ded62ac`.
Raw/report/logs retained in CI; complete compact annotations retrieved. Local
ZIP fetch failed at artifact host (EOF); no local ZIP inspection claimed.
Source/values/statuses: `.review/m1_r18_external_evidence.json`.
**Runtime8/18, movement0.** Other10 rows unchanged/NOT RUN: AC-201/202/204,
presets/captures, tickcost, §10.6 cross-arch, FA-3/4/5/6. Components do not
upgrade those rows; FA-5 unchanged, accepted F52/F53/F54 not reopened.

**Next single milestone M1:** obtain owner resolution of F56's external-force
identity before the motor2400/0 diagnostic; no remedy pending that resolution.

### Historical accepted R17 — Phases1/2 measured; 8/18 runtime rows, M1 still RED

Reviewer branch completion plan/read-only R17 review were read with git show;
neither reviewer artifact was copied, committed, merged or rebased. Work order
is NOT evidence. F47/F49/F50/F51 remain CLOSED; FA-5 unchanged; F50 retires the
landing/spawn confound. No physics/tuning/damping/sampling/remedy change.

**Phase1** commit2ddfe25 / CI40816607995 / M0 CI40816607997:
0/18 runtime rows, complete-creature attempts0. F52 BOTH per-tick AND net per-body
COM from the saved start-of-dwell snapshot must remain strictly below SAME.001WU
for30 ticks. Any failure/input resets origin+count; origin deep snapshot/restored.

| F52 translated fixture | per-tick WU | net30 WU | old sleep tick | fixed sleep tick |
|---|---|---|---|---|
| settled | 9.337328797581247e-6 | .0002801198639274374 | 29 | 29 |
| slow slide | .0005 | .015 | 29 | none in600 |

Ticks are zero-based. Actual free-hinge sleep events remain61/210/390, wakes180/360;
partial-dwell/asleep restore continuations still exact. At Phase1 ONLY free-hinge
composition used sleep; Phase2 makes F52 reachable with motors/live spring.
Phase1 counts131Python/931mechanics/4897sleep/381math/237contact/136analytic/80load;
M0 514/0+Android. Source evidence `.review/m1_r17_phase1_evidence.json`.
F53 renamed dvx_direction_reversals (NOT positive-vx sign changes). F54 preserves
zero self-contact maxima and explicitly calls them UNIT-ONLY, not scale validation.

**F48 diagnostic** last300 of6000, per-joint pre-drive signed contributions BEFORE
net torque clamp; torque unit mass*WU^2/s^2. Slug has exactly one L MOTOR joint.

| pose / passive stiffness | drift px/s@150 | mean abs(q) rad | spring mean | damping mean |
|---|---|---|---|---|
| before /900 | 3.5133210565803203 | .8428560852916004 | -2022.854604699841 | -141.2507297496081 |
| before /0 | 3.5133210565803203 | .8428560852916004 | -2022.854604699841 | -141.2507297496081 |
| after /900 | 3.9345242550809765 | .8425338732724178 | -2022.0812958538024 | -108.72746136803043 |
| after /0 | 3.9345242550809765 | .8425338732724178 | -2022.0812958538024 | -108.72746136803043 |
| free-hinge after | .08403595917823123 | n/a | n/a | n/a |

Both actuated arms STILL have spring_return_live=true: passive stiffness900->0
changes NO Slug joint (there are zero passive joints); motor return uses2400.
Mean clamped drive torque is -1260 in all four actuated arms. Sweep does NOT prove
passive spring causality or remove the motor return. Equilibrium remains unset.
M1-D05 QUESTION SENT with numbers: settled-pose motor return, weaker return, or
no zero-input motor return? NO remedy selected/adopted; Phase2 independent and
explicitly authorized immediately after question. Phase3 settle/lurch awaits owner.

**Phase2** runtime source commit e1934ed / CI40818428101, public job123264928010
SUCCESS; same-head M0 CI40818428107 SUCCESS516/0+Android. Overall M1 RED ONLY F47.
Public Sim now composes actual actuated solver + F52 sleep, original accumulator
(max3, dropped excess, fixed1/60), one injected xoshiro128**, explicit terrain/
materials. Original public M0 signatures retained; failure signal/status, no
silent healing. Complete clock/creature/contacts/constraints/motors/sleep origin/
RNG snapshots and atomic detached restore. F45 .05/.6 legacy fields documented
UNUSED/SUPERSEDED, not deleted or retuned. No UI/platform/engine clock dependency.

Determinism **attempt1 SUCCESS**, same-build complete Slug (NOT all presets or
cross-architecture acceptance): three600tick full streams31,131,584bytes EACH,
byte-identical at every tick, public integer final hash3535650661 x3, SHA256
`d735ea5f596f9a7b9bdfea0acee9b666a4e364e670f21dba9556985b7bfd19c8`.
Tick0 ONLY LEFT bit1 flipped0->1 changes actual bodies and final SHA256 to
`0f0f93a619d86a62f7485f3cbfcc2e0d7d19c1a76a609ab1e8e81c5a009fcf99`.
No nondeterminism failure recorded; earlier frame support/endpoint protocol errors
are retained, NOT hidden or relabelled creature-replay failures. Public assertions
9053/0, actual30FPS308/0 and144FPS1446/0. Baseline generated from pinned CI,
committed, then STRICTLY matched; linked DECISIONS hashes required for any update.

Two-second stall:3 steps,1.95s dropped,0 pending; same complete solver at tick3.
Actual --fixed-fps30/144 callbacks, physics stays60:301/1439 frames,601/600 actual
ticks; compare SAME first600 physical+RNG tick bytes, retain601st tick/full clock.
Actual startup/transient frames retained, never overwritten by nominal dt.
Modal seconds .03333333333333333/.006944444444444445; nominal FPS identity uses
rounded reciprocal only for capability REPORT, never modifies delivered duration.
Complete-Sim hash includes delivery clock, so frame/stall comparisons explicitly
compare full solver+RNG streams and separately retain distinct pending/drop clocks.
F52 public live-spring zero-input600 stays awake, max dwell2 (not an FA-4 run).

**Runtime status8/18** (source ledger `.review/m1_r17_phase2_evidence.json`):
rows1 engine/architecture,2 accumulator,3 RNG,9 replayx3,10 stall,11 frame delivery,
12 physical single-bit falsification,13 baseline regression measured. Other10
NOT RUN: AC-201/202/204; all-preset divergence/captures; tickcost; cross-architecture
repeatability; FA-3/4/5/6. Full INV/five-fakes/A12 still pending. Source Python140;
FOUR new exact-scope matrix controls make144 locally; final-head CI must repeat.
Component counts unchanged931/4897/381/237/136/80 and M0 516/0 (original514 +2 automatic core-script compile checks). Guard extends F15
ONLY exact measured gate/status/CI+row citations; original controls and NOT RUN
floor12 remain. Supporting A8 baseline alias is NOT a ninth runtime row.

**F41 count buckets** last300, with full per-body/pass(I,C,A) signatures retained
in the ledger/raw artifact. In actuated A/B, head both passes(2,3,1), motor pass1
(2,3,1); motor pass0 A=(2,3,1), B=(2,3,2). Foot before:pass0(2,3,3),pass1(1,2,2);
foot after:both passes(1,2,2). Baselines have identical complete count signatures
(head/motor both(2,3,3), foot pass0(2,3,3),pass1(1,2,2)).

| pose / bucket | ticks | mean COMdx WU/tick | mean px/s |
|---|---|---|---|
| before actuated A |267| .0003942677977332723 |3.5484101795994505|
| before actuated B |33| .00035882423912808966 |3.229418152152807|
| after actuated A |250| .0004503289211869022 |4.05296029068212|
| after actuated B |50| .0003713715641194736 |3.3423440770752624|
| before baseline |300| -7.1751877234127456e-6 |-.06457668951071471|
| after baseline |300| 9.337328797581247e-6 |.08403595917823123|

Dominant A bucket is NOT constant: before dx range[.000335495161399483,
.0006785071366395335], after[.0003625309958852366,.0007047542330999346].
All exactly_constant_within_bucket flags false. F41 stays OPEN; count buckets do
not isolate sampling as sole mechanism; no forced pose-causal claim. Spawn confound
remains retired, not reopened. Per-body buckets remain in spring-report.json.

Artifacts CI40818428101: public12873442495 (8,523,538bytes), full spring+bucket raw
12873517463 (109,653,804bytes); checksums/metadata in committed Phase2 ledger.
No raw/binary artifacts in Git. No captures/M2/camera/waivers or tuning changes.
Next SINGLE milestone: Phase3 creature acceptance after owner motor-return choice.

### Historical R16 — superseded by current R17 status above

- Mechanics **931** checks, Python106 and M0 **514/0** are the accepted R15
  component counts. The preliminary921 subset is historical, NOT the current
  mechanics total (F51 correction). Components are not coupled acceptance.
- F47 gate replaced: last300 grip fraction>0 AND a grounded, gripping foot with
  positive velocity-level reaction must provide strictly>50% of ALL grounded
  reaction on the SAME tick. Aggregate feet, another foot/tick's share, landing
  impact alone, zero reaction and positional cleanup cannot pass. FA-5 untouched.
  Existing force/momentum/position checks and CI nonzero exit remain mandatory;
  no bypass/continue-on-error. Current real data must keep M1 RED.
- Owner acknowledges F37 previously requested fraction/share metrics, not a gate
  using them, and R15 “M1 green” missed the landing-impact cause; attribution is
  OWNER REVIEWER correction, not a claim of sustained support by the mechanics.
- Binding order now F47/F51 -> F48 convergence/zero-input drift -> F49 separate
  angular/self magnitudes + F50 post-pose .610/.810 -> public Sim/F45/replay ->
  FA-5 four branches, all3 FA-3/4, AC201/202/204,A9,10.6,tickcost/captures.
- Awake zero input is NOT unpowered: spring return is LIVE. R15 actuated last300
  is a transient, NOT an equilibrium; drift interpretation suspended until
  convergence evidence. F41 stays OPEN. No physics/tuning/damping/sampling/
  velocity epsilon/hysteresis/load injection/M2/camera/captures authorized.
- Public Sim still stub. FA-3/4/5/6/all coupled runtime gates NOT RUN;
  complete-creature determinism attempts0. R16 steps1–3 implemented/measured; public Sim/F45/replay NEXT.

### R16 F48 executed @f6b852a / CI40812720624 — M1 correctly RED

- Gate step FAILS as intended; all original math/contact/geometry/load components,
  sleep3659/mechanics931 and static controls pass. BOTH actuated6000 arms complete
  with full raw F31/position/count/contact checks and observer equivalence.
  Final before support fraction0, max single-foot share .3138574119247297, gatefalse.
- Exact settlement was NOT established in the available before-arm summary:
  settled value null, not a fabricated equilibrium. Full6000 artifacts retained.
  GitHub check annotation cap50 hid later own-line windows from this job's API;
  move subsequent measurement to a separate pinned observation job, preserving
  the original failing gate and raw artifacts. No gate bypass.
- F49 adds observation-only raw limit-block and individual self impulse events,
  before/net snapshots retained, no force/order/value changes. Summary separately
  reports angular/self max absolute per-tick phase coordinate and event impulse
  maxima BEFORE the accepted lossless phase adapter; cancellations stay visible.
- F50 repeats post-pose .6100000000000001 and .81 (legal+.01/+.21) for BOTH baseline
  600 and actuated6000, alongside the original pre-pose actuated6000. Derived from
  authored geometry plus explicitly requested fixture lift. No tuning addition.
- Follow-up measured below. Step4 public Sim/F45/replay is NEXT after
  these measurements; all coupled runtime gates NOT RUN, determinism0.

### R16 F48 measurement design (executed; results below)

- Extend ONLY diagnostic duration to6000; held input remains0 and live spring
  return explicitly labelled. Both legal actuated arms run6000 with EVERY raw
  tick/contact/count and observer-on/off physical equality, original600 prefix
  accepted verifier and independent full6000 momentum/position/contact checks.
- Convergence reported at600/3000/6000: monotone transient, oscillating transient,
  or exact constant/repeating last300 COM(dx,vx) pattern (at least2 cycles).
  NO velocity epsilon/band. If no exact observed settlement by6000, settled value
  stays null; a bounded last300 mean is NOT promoted to equilibrium. Tiny float
  fluctuations remain visible; lack of exact pattern is not proof of divergence.
- New own-line zero-input drift includes WU/tick, WU/s and150px/WU px/s plus raw
  speed/drift ranges. Actuated F41 pair interpretation DEFERRED unless both
  windows settle. Existing R15 component diagnostic prints the same line too.
- This always-run measurement retains evidence AFTER the RED support gate; the
  failed gate still makes CI RED, never continue-on-error or a status bypass.
- F49/F50 and public Sim/F45 remain subsequent ordered increments, not claimed.

### Historical R15 — component success, NOT M1 sustained-support acceptance

R16 supersedes “GREEN” below: component execution succeeded, but the old gate
passed on landing impact. Current M1 gate is RED until sustained majority support.

### R15 / actuator engineering increment measured (historical order)

- Binding order: motors L/R contraction + angular limits + self-contact FIRST;
  same increment derived legal BOTH-arm600 + required main-trace per-body/pass
  intervals/candidate/active counts, then F41 comparison. Public Sim/F45/replay
  NEXT, then Hopper four-branch FA-5/all-preset FA-3/4; finally AC-201/202/204,
  A9/§10.6/tick cost/captures. No M2/camera/captures now, no retune or sampling fix.
- F30-authored CLOSED — the audit proves foot pads at -0.205 (Slug, TwinRoller 4) and -0.235 (Hopper) below the lowest non-foot body, with exactly one documented exemption.
- F30-runtime BLOCKED — not by the pose but by missing actuators. The hinges rotate freely, so the foot swings up and the head and motor bellies still rest on the ground: 17 active samples and all three bodies grounded after the fix, with the foot carrying 22.24 percent of support. With no angular limit and no motor torque, the lowest-energy configuration of a limp chain is everything on the ground. The pose cannot constrain attitude.
- Above is the owner's R15 baseline verdict, NOT a claim new actuator traces pass.
  First shipped-preset grip: tick19, exactly one tick, toggles[19,20], steady
  fraction0: path existence only.
- New source: algebraic binary64 CORDIC table, spring/return motor, asymmetric
  motor/symmetric passive angular rows, D10 filtered center-sphere self response,
  separate awake ActuatedLoadProbe. Historical free-hinge trajectory retained.
  No foot/root angular limits invented. No new damping, epsilon, load injection,
  resource-value or accepted math/analyzer/control changes. Existing endpoint
  linear damping remains; existing motor c55 is used as specified. Unused global
  angular damping is not silently activated/reinterpreted by this increment.
- New fixture derives root from actual authored capsule minimum +.01WU. All four
  legal cases (old/new pose × baseline/actuated) retain required MAIN counts and
  raw candidate observations. Historical .33 pair explicitly over-penetrating.
  F43/F44 legal/count plumbing executed: see measured evidence below. F41 remains
  OPEN: legal baseline still drifts; actuated pose-causal comparison is confounded
  by differing counts. NOT a failed pose fix or landing-depth causal explanation.
- Public Sim remains stub; F45 documentation/replay is the next ordered stage,
  not an approval blocker. All coupled runtime acceptance remains NOT RUN;
  complete-creature determinism attempts0. Accepted sleep remains unchanged.

### R15 measured engineering evidence (35df327; strengthened548b5c8 also GREEN)

- Pinned Godot4.7.2 M1 CI40810406262 SUCCESS:105 Python controls,381 math,
  237 contact,136 analytic,80 load,3659 sleep,921 new mechanics checks. Initial
  engine compiler failures (global wrap-name collision/test Variant inference)
  were corrected in0cf1215/35df327, not hidden as unavailable or passing runs.
- All FOUR legal main600 traces OBSERVED, EVERY tick observer-on/off serialized
  physical state equal; required counts independently agree with all raw samples;
  F31/motion/contact verifiers pass. Actuated raw angular/self position phases
  retained, independently closed, then explicitly folded only for legacy verifier.
- Actual authored minimum before=-.395, after=-.6000000000000001WU, derived roots
  .405/.6100000000000001: BOTH initial lowest surfaces=.010000000000000009WU.
  Historical root.33 remains over-penetrating: actual deepest surfaces -.065/-.270,
  not a new legal fixture. No physical resource/sampling/threshold changed.
- Legal baseline last300 mean COM dx before=-7.1751877234127456e-6,
  after=+9.337328797581247e-6WU/tick; difference=1.6512516520993993e-5.
  Count tuple=(intervals,candidates,active), passes0/1: BOTH arms head(2,3,3)/
  (2,3,3), motor(2,3,3)/(2,3,3), foot(2,3,3)/(1,2,2), all300 ticks. Thus legal
  steady baseline counts match and residual drift persists, essentially the same
  late results as historical.33. No landing-depth causal claim.
- Legal actuated last300 mean dx before=.0003903690062867916,
  after=.000437169361675691WU/tick; difference=4.6800355388899406e-5. These are
  observed larger drifts, NOT a causal pose verdict: last300 count regimes DIFFER.
  Side by side (before -> after), tuple=(intervals,candidates,active):
  - Head passes0/1: (2,3,1)×300/(2,3,1)×300 -> same.
  - Motor pass0: (2,3,1)×267+(2,3,2)×33 -> (2,3,1)×250+(2,3,2)×50.
  - Motor pass1: (2,3,1)×300 -> same.
  - Foot pass0: (2,3,3)×300 -> (1,2,2)×300.
  - Foot pass1: (1,2,2)×300 -> same.
  Raw per-tick counts plus ALL600/last300 histograms retained in artifact; no
  candidate-regime repair, rounding, epsilon, hysteresis or sampling retune.
- All3 bodies still grounded late in all four cases. Baseline foot support share
  .2223925379546886 ->.22240637932820798; actuated .3057010100863977 ->
  .27408929671045956. Late grip fraction0 everywhere. Legal baseline after has5
  grip ticks/toggles[4,9]; legal actuated after4/toggles[4,7,10,11]; both before0.
  These separate fixture results do NOT replace the historical shipped-preset
  milestone tick19/exactly1tick/toggles[19,20], which remains path existence only.
- Artifact12869408995 (8,025,846 bytes), SHA256
  eec39d97e8ced394b44d8c152c6f88c5edf923f694d79e66abd192aa82390f43,
  contains full four raw600 traces/components/import/observer reports. This is
  awake engineering evidence, NOT public Sim/FA/complete-creature determinism.
- Follow-up548b5c8 / CI40810712083 SUCCESS:106 Python /931 mechanics checks.
  New F43 fake-legal-metadata control verifies actual START endpoints/radii,
  not merely reported clearance. Composed D10 overlap control invokes the actual
  pair-list hooks and independently conserves momentum; self response cannot
  pretend terrain support/grip. All four legal600 results repeat exactly.
  Artifact12870690195 SHA256
  589532d5add86e978cbd90273a4966b04534af19e7c46850a40bb96d18999ddd.
- Next ordered M1 stage is public Sim + explicit F45 superseded legacy-sleep
  documentation + replay; no approval blocker. Then Hopper FA-5 all4 branches /
  all-preset FA-3/4; final acceptance/tick cost/captures still NOT RUN. Attempts0.

### Historical R14 / superseded interpretation and order (preserved evidence)

R15 supersedes the F41 causal interpretation and public-Sim-LAST ordering below.
The .33 runs are historical **over-penetrating spawn** evidence only.


- F41b answered BEFORE source edits: foot current extent ceil crosses cell.25
  after first-pass positional cleanup; candidate/active count3->2, velocity-
  invariant at fixed current/previous positions+terrain. Indirect geometry path
  through integration remains. No sampling/contact fix or new epsilon.
- Owner A/A1 implemented126dc80: five foot axes ->DOWN only; hard F36 authored
  audit passes, exact retained exemption TwinRoller foot5 parent0 non-support stub.
  Original bad-pose synthetic control remains. Hopper two-foot grip proof belongs
  to future FA-5, NOT TwinRoller stub or the authored-bottom assertion.
- Unexpected measured dynamic result: before0 grip ticks, after1(at19), late
  fraction0 both. All3 bodies STILL grounded with17 active responses/tick; mean
  COM dx reverses/grows -7.175187723414263e-6 ->+9.337328797577746e-6WU/tick.
  F41 retained, not pose-artefact downgrade. Unchanged .33 spawn now starts new
  pad at-.27WU; sole-foot support prediction NOT observed. No silent spawn fix.
- Sleep sourcee36c407 / CI40805104578:3659 component checks PASS;600 engineering
  ticks, sleeps[61,210,390], input wakes[180,360]. Restore at47(partial dwell)
  and62(asleep):1091 full serialized-state continuation comparisons identical.
  Every asleep endpoint zero; persistent/new-grounding F42 controls pass. This
  is NOT complete-creature determinism or an all-preset FA-3/4 pass.
- EXACTLY two tuning additions, owner R14 Decision2: .001WU/30ticks. All previous
  tuning-resource bytes unchanged. Sleep parks plateau, does NOT fix it; awake
  max endpoint speed≈.202WU/s≈30px/s at150px/WU remains a motor-stage feel risk.
- Next M1 STEP4: motors/angular limits/self-contact. Then STEP5 Hopper two-foot
  FA-5 and all3 FA-3/4. STEP6 public Sim wiring LAST, currently untouched. No owner
  approval blocker, no retune/M2/camera/screens/captures. FA-3/4/5/6/all complete
  runtime gates remain NOT RUN; complete-creature determinism attempts0.

### Exists

- Pinned Godot4.7.2-stable project: Mobile renderer, 1080×2340, portrait,
  canvas_items/keep, 60 Hz, pixel snapping, MSAA off, ETC2/ASTC import enabled.
- Engineering-only navy boot surface with safe-area container and lifecycle hooks.
- `core/tuning.gd` / `.tres`: **402 exported fields** (376 original +24 owner M1-D04 +2 owner R14 Decision2), seven original groups,
  `docs/TUNING.md` source map. No core numeric literals; no feel/economy changes.
- Atomic JSON SaveStore: flushed tmp, previous validated backup, atomic replacement;
  primary → backup → tmp → defaults recovery; checked errors and recovery signals.
- Share/billing/ads/haptics unavailable/no-op interfaces, no SDKs/network calls.
- Architecture/shared-component stubs and reserved Sim/CreatureCodec signatures.
- Test launcher rejects wrong engine versions, script errors, failed assertions and
  missing completion markers. Six static tests, seven inspector unit tests, and
  real-engine persistence/tuning/safe-area/stub tests.
- CI headless and Android jobs with checksum-verified exact engine/templates;
  Android debug AAB export and bundletool-derived signed debug APK generation.
- Actual manifest/ABI checks, native ELF 16 KB and APK ZIP alignment checks;
  seven-day Actions artifact retention. Generated binaries/keys remain outside Git.
- README, decisions, and `docs/validation/M0.md` with reproducible evidence and
  remaining hardware checklist.

### Explicit stubs / not built

Full coupled creature solver, general builder validation/codec, run/fall/checkpoint systems, generator,
wallet/medals/score, schema migrations, settings/debounces, lifecycle run/audio
consumers, all S00–S16 screens and native plugins. Stub null/empty returns are
nonfunctional and unused. No autoload, gameplay, art, audio, production signing,
purchase, advertising or network feature. Android Gradle files/artifacts are
transient CI outputs, not tracked source.

### Validation evidence

Validated code: `ba7179b4d6d7fee26522853590578135973fd7bc`.
[Successful CI run 40625642314](https://github.com/sagheerh/clamber/actions/runs/40625642314).
Exact commands, jobs, versions and artifact digest: `docs/validation/M0.md`.

- `python3 tests/test_static.py`: **6 PASS** locally and in CI.
- `python3 tests/test_android_inspection.py`: **7 PASS** locally and in CI
  (synthetic inspector fixtures, separate from actual artifact checks).
- `gdlint core ui platform tests` (local gdtoolkit): **PASS**.
- `bash -n tests/run_tests.sh tests/build_android.sh`: **PASS**.
- `godot --headless --editor --import` on pinned CI engine: **PASS**.
- `godot --headless --run-tests` on pinned CI engine: **475 checks, 0 failures**,
  exit0, including garbage→backup and both-corrupt→defaults recovery.
- Debug Android AAB export: **PASS** on equipped CI runner, JDK17/SDK36,
  build-tools36.1.0/NDK29.0.14206865, matching4.7.2 templates.
- Bundletool validation/APK generation; actual manifest/ABI/native16KB/ZIP16KB:
  **PASS**. Debug artifact is downloadable from the successful run for seven days.
- Physical install and solid navy/no-UI/no-gameplay boot: **OWNER VERBAL
  VERIFICATION**, 2026-10-28; not E4 evidence. No screenshot/adb log, device
  identity, lifecycle/safe-area record or frame-time capture was attached.
- Measured 60 fps/P95 and remaining device artifacts: **WAIVED FOR M0 ONLY** by
  M0-D07, not measured. The 60 fps engine cap is not measurement evidence.
- Local engine/Android execution remains unavailable; CI results above are real
  runner executions, not local execution or hardware measurements.

### Definition of Done

| Criterion | State | Evidence |
|---|---|---|
| `godot --headless --run-tests` exits0 | **Met** | Pinned CI engine, 475 checks/0 failures |
| Save garbage → backup → defaults test passes | **Met** | Real-engine save test suite passes |
| Android debug install/boot and measured 60 fps/P95 | **Accepted by owner override** | Verbal boot verification; missing artifacts and measured performance waived for M0 only (M0-D07) |
| ≥40 named tunables; no core hardcoded numbers | **Met** | 376 fields; static/resource checks PASS |

### Decisions / next

M0-D01–D07 are in `DECISIONS.md`; M0-B01 is closed by the owner-only waiver.
M0 review-pack script/matrix artifacts were explicitly waived for M0 (M0-D07).
M0-B02 (camera zoom) remains for M2; M0-B03's unspecified grip/haptic/generator
thresholds remain unresolved and must not be invented. No later gate is waived.

**Next milestone: M1 — standalone custom solver + three presets + headless
determinism/feel harness.** M1 is ready, not complete. Excludes S03 climb,
pause/fall/build screens. Real-engine M1 CI evidence and baseline are not yet
available; the M0 CI suite is not evidence of M1 determinism/performance.

### M1 PR #3 kickoff / R3 scaffold fixes

M1 working branch for PR #3: `arena/4cd0a587-clamber`, not the earlier PR #2 branch.
M0 approval/closeout is untouched. The earlier M1 matrix is restored and reconciled
with supplied A9.1–A9.7, A8 475-engine/488-total regression floors, full invariant
sweep, five-fakes and A12 evidence requirements. A separate M1 static CI job and
`scripts/review_checks.sh` are added; their green status is NOT runtime evidence.
Full review pack is now vendored unchanged (owner-supplied 2026-10-28);
`docs/CLAMBER_REVIEW_AGENT.provenance.md` records the exact source/hash.
M1-B02 is RESOLVED (vendored), not waived; protocol execution is not signoff.
Owner selected independent work while missing radii/head properties/grip threshold
are unresolved (M1-D01). M1 solver, presets, captures and runtime gates NOT RUN.

### M1 independent increment 1 — real-engine primitive unit tests PASS

- Scaffold-only commit `2358c83` passed CI before mathematical implementation:
  M1 static run40631318799 and M0 regression/Android run40631318609.
- Draft PR: https://github.com/sagheerh/clamber/pull/3 (sole canonical M1 draft);
  prior scaffold PR#2 is left unchanged on its earlier branch.
- `core/sim/body.gd`: explicit float64 point state, finite/bounds validation,
  non-aliasing snapshot, checked atomic restore; no collision radii/default mass.
- `core/sim/constraint.gd`: independent XPBD distance-link projection, explicit
  compliance and tick-boundary multiplier reset; no creature integration/contact.
- `tests/sim/test_math_state.gd` + `tests/run_m1_math.sh`: synthetic unit fixtures,
  pinned real-engine CI job; these are NOT creature/replay/soak acceptance.
- Original M0 tests, public Sim interface, tuning values and boot scene unchanged.
- Presets/model/contact/debug view and M1 runtime gates remain blocked/not run;
  no head properties/radii/grip threshold or baseline hash has been invented.

### M1 measured status / next

- Mathematical commit3bbb8fa passed pinned-engine CI40631790195: **81 primitive
  unit checks, zero failures**. M0 regression/Android CI40631790078 also passed;
  original 475 engine +13 Python =488 floor is enforced with no test reduction.
- `scripts/review_checks.sh` exits0 (42 script/scene files scanned, 21 Python
  tests) at accepted head f51ecd4; the output is pasted in PR#3. These scans do
  not certify the full invariant sweep or any M1 runtime gate.
- Detailed source/run evidence and limits: `docs/validation/M1.md`.
- AC-201/202/204, distinct gaits/captures, 3600-tick/100×/two-machine replay,
  bit-flip, baseline, soak and performance: **NOT RUN / NOT MET**. No complete
  creature determinism attempt has run; the two-failed-attempt budget is unused.
- **Next: M1** — owner review of the independent integration/clock increment
  and owner input M1-B01 before any dependent creature implementation. No contacts/radii/gaits/presets/
  baseline/runtime claims. M1-B01 radii/head mass/length/grip threshold with units
  still requires owner input before dependent work. M1-B02 is resolved, not waived.
  Do not move to M2.

### M1 R4 mechanical fix increment (no integration)

- Full owner-supplied pack vendored byte-identically, SHA-256 verified, 379 lines;
  provenance outside the immutable file. Incorrect owner attribution withdrawn;
  M1-B02 RESOLVED (vendored), not waived. PR #3 remains the sole canonical draft.
- Matrix now maps the original PART B INV-01–10 and A5.6/A10 five-fakes. Full
  semantic sweep/five-fakes/A12 review and every runtime gate remain NOT RUN.
- `scripts/review_checks.sh`: exit0; 42 script/scene files and **28 Python tests**
  (15 review/guard +6 original static +7 original inspector). Guard enforces the
  claim freeze, evidence cells, ≥12 NOT RUN rows and immutable pack identity.
- Actual AC-201 working-file mutation to `PASS | None`: exit1; exact restore:
  exit0. Full transcript is in the PR #3 body, not just a unit-test claim.
- F13 uses injected `tuning.physics_one` for the fixed step (and therefore both
  factors of its square); one new synthetic 120 Hz versus 60 Hz primitive test.
  Local lint/shell/diff checks passed. Pinned-engine/M0/Android results for this
  fix commit are tracked in PR #3; no new engine result is claimed here yet.
- No integration, accumulator, contacts, presets or baseline added. Accepted M0
  tests/tuning/save and public Sim interface are unchanged. Determinism attempts:0.

### M1 R5 F15 — status allowlist (before integration)

- R5 owner accepted F7/F12/F13/F14 at0ec87d0 and independently verified its CI.
- F15 replaces permissive status handling with an exact allowlist over every
  pipe-table row, not only the first table. Scoped exceptions and NOT RUN≥12
  remain enforced. Scanner restrictions are unchanged.
- Seven existing guard tests retained; one parameterised test adds the six
  reported bypass statuses, empty status and later/headerless table cases.
- `scripts/review_checks.sh`: exit0, **29 Python tests** (16+6+7).
- Actual AC-201 COMPLETE and MEASURED (4 s) mutations with CI evidence each exit1;
  restored matrix exits0. Full fresh transcript is in PR #3's body.
- Integration is the next separate increment; runtime acceptance remains NOT RUN.

### M1 independent increment 2 — point/link integration and outer accumulator

- F15 commit201644e is green: M1 CI40638310619 and M0/Android CI40638310666.
  Original82 primitive checks and 475 M0 engine checks retained.
- `core/sim/solver.gd`: tuned fixed-step scalar integration, gravity, linear
  damping/clamp, fixed index-order link projections and tick-boundary lambda reset.
- `core/sim/accumulator.gd`: callback-free outer clock with frame_seconds input;
  tuned catch-up cap, exact dropped-time accounting and retained sub-cap remainder.
  No elapsed-time argument to the solver. Placement/naming/math: M1-D03.
- Candidate restore validates the entire graph/state; tick and whole-frame failures
  roll back atomically. No silent repair of non-finite events.
- `tests/sim/test_integration.gd` + extended `tests/run_m1_math.sh`: actual assertions
  for all six R5 evidence categories, plus pinned points, damping/clamp, invalid
  graph/configuration and late-frame rollback. Existing82 checks remain intact.
- Local review checks exit0: **44 script/scene files, 29 Python tests**. Lint,
  shell syntax and diff checks passed. New pinned-engine counts/results are recorded
  in PR #3 after execution; local Godot remains unavailable.
- Still stubs/missing: public creature Sim, model, contacts, hinges/motors/feet/SDF,
  sleep/recovery, presets, diagnostic scene and all creature-runtime acceptance.
  No tuning values, M0 tests, accepted point/link math or scanner restrictions changed.
- Next: **M1** owner review/input before dependent work. M1-B01 remains owner-supplied;
  no radius/head mass-length/grip value invented. No M2/camera. All runtime NOT RUN.

### M1 integration measured evidence — synthetic primitives only

- Source `f6b3756f36f683ea5ce6c0fa21b5c167c4598fc8`: exact Godot4.7.2
  [M1 CI40639068153](https://github.com/sagheerh/clamber/actions/runs/40639068153)
  reports **374 checks, 0 failures: 82 point/link +292 integration/clock**.
  All six R5 primitive evidence categories execute; no skipped/invented baseline.
- [M0/Android CI40639067949](https://github.com/sagheerh/clamber/actions/runs/40639067949)
  is green. Actual unchanged M0 suite now reports **476 engine checks, 0 failures**:
  its recursive per-script compile assertion picks up the new accumulator script
  (`tests/test_runner.gd:31–37`). With original13 Python checks this is489;
  the original475-engine/488-combined floors and all M0 tests remain unchanged.
- New integration completion/count floor is pinned to the measured292 checks;
  original82 point/link floor remains. This prevents a later primitive count drop.
- This is NOT M1 acceptance: contacts/presets/AC-201/202/204, A9.4/.5/.7,
  §10.6, tick cost and captures remain NOT RUN. Determinism attempts:0.
- Next: **M1** owner review of this independent increment and owner M1-B01 input
  before dependent creature work. No M2/camera or invented physical values.

### Commit A — F16–F19 only (no contact geometry)

- M0 regression floors raised to476/489; original13 Python floor preserved. Added
  a negative fixture for the old475-check run, including surplus-Python masking.
- Accumulator now returns a failed rollback's Error; a fault-injected solver forces
  a changed state and failed restore. Existing atomicity assertions remain intact.
- F18 records current tick+frame snapshot policy and a mandatory two-configuration
  benchmark protocol before any tick-cost claim. Measurements remain NOT RUN.
- A9.5 explicitly varies frame delivery, not fixed60 tick_hz.
- Next M1: only after Commit A is pushed/green, verify owner derivation hash and
  prepare the separate constants/geometry-tests/feel-scaffold Commit B.

### Commit B — M1-D04 constants, geometry guards and feel scaffolding

- Commit A0ee3548 passed pinned M1 CI40670975708 (381 checks, zero failures) and
  M0/Android CI40670975949 before geometry work. Its M0 floors are476/489.
- Owner derivation imported as the single immutable281-line file with verified
  SHA-2566453508be7cb808f643544ec3f3fdbd6560840876fc070511f4b5f50065dbc5e.
- M1-D04 records supplied collision/art radii, derived head mass, ratio/floor grip,
  no root hinge, cosmetic-only eyes and provisional/no-silent-retune requirements.
  M1-B01 is RESOLVED (inputs supplied); M1-B04 is unresolved FLAG ONLY, no camera.
- Added24 named exports/resource values/inventory entries sourced owner M1-D04.
  All376 pre-existing fields/values, GDD§3.2 and foot bias/slip remain unchanged.
- Real analytic harness: all25 kind-pair D-10 bounds, distance-two pairs in
  Slug3/Hopper8/TwinRoller6 topology fixtures, strict slop clearance and FA-1/2/7
  checks. Topology-only fixtures are NOT runtime presets or captured gaits.
- Static visual-radius isolation forbids direct/dynamic references by core except
  schema declarations; source tests pin exact owner constants and derivation hash.
- Runtime feel plans list required measurements without observations/successes.
  FA-3/4/5/6, contacts, AC-201/202/204, A9, baseline, timing and captures NOT RUN.
- Local script review:34 Python tests; lint/shell/diff checks pass. Real geometry
  counts/artifact and source-pinned CI evidence will be in PR #3 after execution.
- **Next: M1** — after B green, creature bodies/feet/contact response, then actual
  acceptance traces. Feature stop is lifted. No M2/camera/screens or silent tuning.

### R7 F20/F21 corrections (before Part3 claims)

- A/B accepted by owner at0668d66; no redo of accepted constants/foundations.
- Seven FA gate rows now mandatory. Analytic status scoped strictly toFA-1/2/7
  with run/report citation; runtimeFA-3..6 stay NOT RUN; prose/checkbox escapes fail.
- Real tracked FA-6 analytic-status mutation exits1; restored FA-1 analytic row
  exits0; original out-of-table prose bypass exits1. Full transcript in PR #3 body.
- FA-1 adds owner-authorized1e-9px float-noise allowance only. Four assertions cover
  boundary noise, half-pixel regression, beyond-allowance loss and non-finite input.
  Geometry count floor rises123→127. No tuning/radius/derivation change.
- Local review checks35 Python tests; pinned-engine results tracked in PR #3.
- Next M1: actual creature definitions/body/contact primitives, D-10 against real
  definitions, then FA-5 before static scenes/AC traces. All runtime NOT RUN.


### Part3a — production models and capsule/SDF contact components

- R7 fixes9a45f6d are all green: M1 run40674737989 has381 mathematical checks
  (82+299) and127 analytic geometry checks, zero failures; M0/Android
  run40674737947 also passed. F20 controls remain in PR body.
- Actual engineering presets now live in `data/creatures/preset_*.json` (3/8/6
  parts). Cardinal rest directions/shortest limb slot are engineering initial
  definitions, NOT approved gaits/tutorial inputs. CreatureModel derives physical
  parameters from unchanged tuning, validates rooted trees/channels/basic budgets,
  sums mass and caches hierarchy pairs. General builder/codec is still a stub.
- CapsuleBody creates float64 endpoints with half segment mass each; snapshots
  preserve contact history and restore/contact publication preserve endpoint
  identity. SdfGrid copies explicit distance samples/material at0.25WU, bilinearly
  samples and rejects undefined normals/outside queries. CapsuleContact performs
  sampled positional/velocity response, current/previous temporal crossing checks,
  explicit min-material friction, static slip and owner ratio/floor/bias foot gate.
  Projection/non-finite errors reject atomically; no pretend public Sim recovery.
- Universal D-10 includes feet/siblings in real definitions. Layer11 feet are
  excluded from the actual creature self-response mask. Geometry harness now reads
  the production catalog, fails if any preset is absent; its floor is128.
- Added `tests/sim/test_contacts.gd` and pinned `tests/run_m1_contacts.sh`, CI unit
  step and unit-log artifact. Tests change real projections/velocities, trace four
  controlled cached-load responses, two separately controlled half-weight contacts,
  airborne/stale-cache and not-lowest exclusion, swept closed-slab crossing,
  snapshots/endpoint identity and atomic rejection. **Not coupled stance/FA-5.**
- Local static review35 Python tests, GDScript formatter/linter, shell syntax,
  diff checks pass. New engine suite/128 geometry checks await pinned CI at this
  increment; no runtime result is asserted before it runs. New unit count floor208
  is separate from the unchanged accepted381 mathematical baseline.
- Tuning/derivation/GDD values unchanged; derivation SHA verified exactly.
- Still unbuilt: coupled rigid links/parent hinges, motors/angular limits,
  self-contact response, sleep/recovery/public Sim. FA-3/4/5/6, AC-201/202/204,
  A9/full deterministic replay/stall/baseline/bitflip/tick cost/captures NOT RUN.
  Complete-creature determinism attempts remain0. No M2/camera/screens.
- **Next — M1:** pin component CI, then couple rigid bodies/hinges and contacts to
  obtain real foot-load/stance traces for FA-5. Only after FA-5: FA-3/static600,
  AC-201 settle+sleep≤4s, AC-202 stretch, AC-204 soak, and motors/tutorial FA-4/6.
  FA-6 actual10-run count10/10 or≤4/10 => STOP/report logs/outcomes; never retune.


- Part3a CI40676292165: accepted381 math checks passed; new component script
  correctly FAILED before execution on nonexistent `ERR_OUT_OF_RANGE` enum.
  Replaced with Godot's `ERR_PARAMETER_RANGE_ERROR`; no physical value/assertion
  changed. Geometry step skipped in that run, not passed. Unit failure is not a
  complete-creature determinism attempt. Re-run pending.

- The companion M0 compile sweep on81d0840 also caught a typed-inference error
  in capsule restore (`state.mass` is a Variant); inverse mass is now explicitly
  float. Old M0 result504 checks/2 compile failures is not regression evidence.
  Runs969ef16 are superseded; only5bb9132 and later include both compile fixes.

- Pinned5bb9132 run40676484751 executed208 contact checks and found2 assertions
  failing at the exact40% cached-load boundary;381 math checks still pass. Actual
  trace: prior17.36, threshold display17.36, vx0.1, gripfalse; below8.68 also slips,
  above21.7/43.4 grips with vx0.0; each measured next reaction18.36. Root cause:
  `(ratio*mass)*abs(g)` rounds17.360000000000003 vs ratio of already-computed
  creature weight17.36. Grouped `ratio*(mass*abs(g))` per the weight-band definition,
  without force epsilon, changed constants, or weakened assertions. Tests now log
  cached load/threshold/vx at17 decimals. These are controlled unit traces, NOT FA-5.
- M0 at5bb9132 run40676485104 headless passed504 checks/0 failures; Android still
  pending when recorded. New geometry step skipped on failed component run.
  Complete-creature determinism attempts remain0; no owner tuning change needed.


### Part3a executed component evidence @e702232

- All four checks green: M1 run40676727247 / M0Android run40676727258.
 381 accepted math checks (82+299),208 new production/contact component checks,
 128 real-definition analytic geometry checks,504 M0 checks, all zero failures.
- Exact controlled traces (not coupled FA-5): prior8.68 =>vx≈0.1/gripfalse;
 prior17.36,21.7,43.4 =>vx0/griptrue. Each fixture measures new reaction18.36.
 No force epsilon/physical tuning or assertion relaxation. Earlier compile/unit
 failures above are retained, not counted as complete-creature determinism runs.
- Contact UNIT artifact12811047142 (762 bytes) digest
 sha256:527433c59c7079906ce3e538b0a792a33fbb5555477ce47730117973b9682c02;
 geometry artifact12810024839 (1148 bytes) digest
 sha256:f983971a93166c35e06a68bcdc047a98804a18be135bc91d6717a8f232ea3260.
 Metadata retrieved via API; ZIPs not downloaded/inspected locally.
- Production non-resource JSON now explicitly included in Android exports;
 existing package inspector verifies exact bytes in both AAB/APK, with missing/
 modified synthetic controls. This packaging addition awaits its own CI run.
 Local review now37 Python tests; original native/manifest/alignment checks intact.
- R7 order/gates unchanged: coupled FA-5 still NOT RUN; next is M1 body/hinge/
 contact coupling and measured foot-load traces, NOT static scenes or motors yet.

- Packaging check correctly failed ata8f071a (run40677420055): inspector assumed
  production assets live under`base/assets/` in the AAB. Pinned Godot4.7.2 source
  `platform/android/export/export_plugin.cpp` uses the install-time asset-pack
  module;`platform/android/java/app/assetPackInstallTime/build.gradle` fixes its
  name to`assetPackInstallTime`. Corrected AAB path to that module's`assets/`;
  APK path remains`assets/`. Exact-byte/all-three-file guards and negative cases
  stay intact. Runtime/M0headless/static jobs passed; no Android pass claimed for
  that failed run. Followup CI pending. No physics/test tolerance changes.


### Part3a final implementation CI @5ff93bf — ALL GREEN

- M1 run40677962012 (check122781079671):381 mathematical checks (82+299),
 208 contact-component checks and128 production-definition analytic checks,
 all zero failures. Static review37 Python tests passes. FA-1/2/7 analytically
 checked only; no rendered/device/feel result is inferred.
- M0/Android run40677961953:504 headless checks/0 failures and Android PASS.
 The package-inspection step passed exact source-byte checks for all three JSON
 presets in AAB`assetPackInstallTime/assets/` and universal APK`assets/`, alongside
 unchanged manifest/ABI/native16KB/ZIP-alignment checks. Earlier failed packaging
 assumption is superseded, not waived. No installation/performance claim.
- Canonical draft PR#3 records controls, failures/fixes, actual controlled response
 traces, source-pinned runs and unit-vs-runtime scope. All implementation pushed.
- **M1 not complete:** FA-3/4/5/6, AC-201/202/204, complete-creature A9/replay/
 stall/frame/baseline/bitflip/timing/§10.6/captures remain NOT RUN; attempts0.
 General codec/builder, coupled links/hinges, motors/limits, self response and
 sleep/checkpoint recovery remain unbuilt. No M2/camera/screens.
- **Next single milestone — M1:** couple rigid bodies/hinges and contacts, obtain
 measured FA-5 load-band/two-foot/airborne traces before static600/AC-201, then
 AC-202→AC-204→FA-4/6 last. Preserve FA-6 stop/report rule and unchanged tuning.


### R8 / owner F24 — force-channel first increment (coupling NOT built)

- Owner accepts prior Part3a as COMPONENTS; F20/F21 closed.208 component checks
  are NOT determinism; complete-creature determinism attempts remain0.
- Applied-load input and measured impulse-reaction output are split; positional
  cleanup is a third diagnostic, never load. The response cannot clobber input.
- Frozen previous completed tick's post-resolve grounded count is computed once
  by batch resolve, no stored N or alternate grounding predicate. N0 disables
  first-contact grip; expected-share band and5N floor recorded with rejected
  alternatives, FA-5 row and owner-attributed append-only derivation addendum.
- Added actual snapshot restore-and-continue and reverse-order component tests,
  zero-to-two touchdown, two-to-one lift-off, immutable-input and positional-only
  false-grip controls. These are controlled components, NOT a coupled stance.
- F22/F25 load producer/conservation and Slug600 trace remain NOT IMPLEMENTED;
  FA-3/4/5/6 and all coupled AC/A9 runtime claims remain NOT RUN. No sleep result
  is fabricated. The0.723N last300/600 criterion is recorded, not relaxed.
- Next M1: implement real gravity/hinges/contact load transfer for one Slug,
  record every required tick, then FA-5 band and only then two-foot presets.

- First R8 pinned component execution e26a1d6 / CI40686657656:233 component
  checks,381 math,128 analytic, all zero failures. Strengthened N0 fixture to a
  qualifying100N input; added actual1->2 touchdown-next-tick step to accompany
  2->1 lift-off and byte-equal restore/continue. New component floor237; original
  accepted208 checks retained with corrected split-field semantics. These remain
  COMPONENT tests, not FA-5 acceptance, not a Slug600 trace and not determinism.


### R9 — real gravity/hinge load bridge; raw diagnostic pending execution

- R9 accepts step1. Added shared-endpoint translational hinges and a coupled
 engineering load probe: gravity + measured equal/opposite hinge impulse supplies
 applied_load_n. Contact impulse output is independent; position cleanup is never
 a source. No prescribed whole-weight share or injected qualifying production load.
- Coupled entry uses batch only; frozen previous flags survive both velocity
 passes. resolve is fixture-only. Co-lowest capsule surface uses existing slop;
 unequal-height/reversed-order read-only fixture added before any stance claim.
- Independent isolated-foot gravity test expects8.4N, not2x. Added600-row JSONL
 diagnostic and independently falsified parser; BOTH force sums and their cross
 difference must satisfy fixed0.723 for last300. Failure is a nonzero CI result,
 not masked. Full raw rows and summary are uploaded even on failure.
- This probe has free rotational hinges; angular limits, motors, self-contact and
 sleep optimization remain unbuilt. All rows explicitly awake/sleep_implemented
 false. No fake sleep observation or accepted stance; no Hopper/TwinRoller run.
- Local review45 Python tests/lint/format/shell/diff pass; new Godot execution is
 pending. Existing237 component/381 math/128 analytic floors are unchanged.
 Tuning/derivation and exact AAB/APK preset guards are unchanged.
- F22/F25/F26 remain OPEN until actual execution and force balance; all runtime
 FA-3/4/5/6/AC/A9 gates stay NOT RUN. Complete-creature attempts0. No M2/camera/
 captures/retuning. Next M1: inspect every raw Slug tick and report findings before
 any FA-5 band or two-foot stance work.


### R9 first executed600-row finding @206d205

- Pinned M1 CI40689842649 ran381 math,237 contact,128 analytic and78 load-path
 components, all zero component failures. Isolated0.30-mass foot's independent
 two-endpoint reaction=8.40000000000000036N, with no divide-by-two correction.
- ALL600 coupled Slug rows were generated. Fixed last300 force acceptance FAILED:
 max|applied-43.4|=33.7224813369873N;
 max|reaction-43.4|=33.70455115394039N;
 max|applied-reaction|=0.017930183046905412N. No grip toggles recorded.
- CI is RED on that actual force criterion, not on a compile/unit failure. The
 closely agreeing channels do NOT establish that the foot carries the full body.
 Added non-foot post-resolve flags/reactions and first/last/range annotations to
 investigate support elsewhere, without changing physics or tolerance. No stance
 claim, no FA-5 band, no Hopper/TwinRoller advance. Sleep remains unimplemented.
- M0/Android run40689842574 passed506 checks/0 failures and Android inspection.
 Existing exact preset bytes, radii, owner values and derivation are unchanged.
- Full600-row diagnostic artifact12816646171 (45670 bytes), SHA256
 2df54e2e4025a3808bf35724b10dc11fd825be6800de314dde6ff58fe13b18c2.
 API metadata retrieved; local ZIP download blocked by artifact-host access.
 Do not claim local inspection of that ZIP. Independent parser processed all rows
 in CI and its annotations were retrieved. Raw artifact remains on GitHub.
- Unequal-height fixture strengthened to two actually post-resolve grounded feet
 on separate elevations, then read-only/reversed eligibility. Load-path component
 floor78->80. Next M1: inspect raw support routing finding; no gate/tuning changes.


### R9 support routing isolated @d5ef49a (CI40690630151)

- All600 rows completed again;80 load-path unit checks passed,381 math/237 contact/
 128 analytic checks passed; static45 Python tests passed. Force criterion remains
 RED, intentionally unwaived. Isolated reaction8.40000000000000036N; no2x defect.
- Last300 applied range[9.6775186630127,9.677518663012702]N;
 reaction[9.695448846059604,9.695448846059607]N;
 positional cleanup[4.134452379266757,4.134452379267277] force-equivalent N, NOT load.
 Max cross discrepancy0.017930183046905412N passes0.723; both foot sums miss43.4
 by about33.7N, so the overall criterion FAILS. No averaging/window clipping.
- Tick599: previousN1, foot grounded=true,lowest=true,gripping=false;
 hinge impulseY=-0.021291977716878335Ns, gravity impulseY=-0.14Ns.
 The HEAD and MOTOR are ALSO grounded, measured reactions19.98947352225558N and
 13.911184476038581N. All-terrain reaction is43.59610684435376..43.59610684435377N.
 Thus the independent channels agree on the foot's underload: other capsules
 carry the rest. It is not evidence that the foot supports the creature.
- Tick0 previousN0, no grip; no grip toggles anywhere. Every row awake with
 sleep_implemented=false. No false settled/sleep/stance or FA-5 acceptance claim.
- Preserved the prototype's original free rotational hinges/axes/radii/materials
 instead of changing pose/ratio or hiding other contacts to force a stand. Full
 angular/attachment constraints remain to be implemented under existing GDD
 values; the current limited probe cannot be treated as a finished creature Sim.
- Matrix evidence now acknowledges this FAILED preflight while FA-3/4/5/6 remain
 exactly NOT RUN. Next M1: complete missing angular/attachment constraints and
 rerun this unchanged Slug diagnostic before any band or two-foot stance.
 Complete-creature determinism attempts remain0; no retune/M2/camera/captures.


### R10 — diagnostic-only implementation, pinned execution pending

- Supersedes R9 interpretation, NOT accepted force code: all-grounded invariant
  restored; producer/conservation F22/F23/F25 CLOSED, F27/28/29 accepted. F30 is an
  authored-pose blocker, not a missing angular-limit fix. No pose/radius/limits
  changes, no setting changes, original derivation and addendum remain byte-equal.
- Every tick now exports all bodies' start/completed endpoint positions/bottoms,
  velocities/inverse masses and applied/reaction/cleanup channels; start state
  exposes authored spacing even when projection masks it by completed tick0.
- Analytic CI prints each preset/part bottom and flags non-foot below any foot,
  BEFORE600. New analytic check floor129 (was128). It diagnoses, does not pick A.
- Discrete momentum budget measures existing damping, gravity, clamp, internal
  rows, independent across-batch contact velocity deltas and before/after P_y.
  Python reconstructs P_y from endpoints and verifies reaction*dt independently.
  Bias equation includes measured dP/damping/clamp/internal; no force correction.
  Hypothesized damping contribution remains UNVERIFIED until actual pinned run.
- Original seven parser falsifications retained;13 more added (20 total), including
  shared support correctly passing force conservation while never-gripping is
  BLOCKED; airborne load excluded; literal ceiling; body geometry and ledger
  falsifications. Synthetic rows are parser controls ONLY, not physical evidence.
- Local static/review58 Python tests pass. Formatter/linter/shell/diff checks and
  pinned-engine execution status will be recorded after verification. All old
  math/contact/load component floors unchanged. No component count is determinism.
- Full diagnostic stays red for no actual grip/foot load path independently of
  all-grounded force pass; report says "grip never engaged". F30 owner pending;
  FA-3/4/5/6/all AC/A9/runtime gates NOT RUN, complete-creature attempts0.


### R10 first pinned measurements @bc4202a

- M1 push run40694232799: static58 Python tests passed;381 math/237 contact/
  129 analytic/80 load-path checks passed,600 raw diagnostic rows completed.
  Overall M1 RED for missing foot path, not force conservation or unit compilation.
  M0/Android push run40694232735 passed; duplicate PR runs40694241017/40694240944
  also have M1 diagnostic red and M0/Android green. Numeric annotations retrieved
  through GitHub API; not a claim of locally downloading the raw ZIP.
- All-grounded max applied-vs-weight7.105427357601002e-15N;
  reaction-vs-weight0.19610684435377124N; cross0.19610684435376413N.
  All satisfy literal0.723N on EVERY tick300..599. No foot-only weight test is
  substituted; no clipping/normalizing/subtracting the measured bias.
- MEASURED last300 budget: P_before/P_after=0.1634223702948058..
  0.16342237029480586Ns UPWARD; dP=-2.7755575615628914e-17..
  +2.7755575615628914e-17Ns; J_gravity=-0.7233333333333334Ns;
  J_damping=-0.0032684474058961143..-0.003268447405896114Ns;
  J_clamp=0; J_internal=-2.7755575615628914e-17..1.1102230246251565e-16Ns;
  J_contact=0.7266017807392293..0.7266017807392295Ns.
- Therefore R-W=(dP-J_damping-J_clamp-J_internal)/dt predicts
  +0.19610684435375852..0.19610684435376852N, matching observed
  +0.19610684435376413..0.19610684435377124N. Damping removes2percent of positive
  carried endpoint momentum each tick; terrain support replaces this downward
  drag as well as gravity. This is a measured discrete balance, not a waiver.
- Over ALL600, independent Python raw-momentum residual max1.1102230246251565e-15Ns;
  batch velocity-delta vs reported reaction*dt max5.551115123125783e-16Ns;
  bias identity discrepancy max5.861977570020827e-14N. No gravity-free generalization
  or2x sampling normalization. All-terrain43.59610684435376..43.59610684435377N and
  per-foot force ranges are byte-value unchanged from R9.
- Authored root(0,0) audit reproduces Slug motor-.395/foot-.350 (gap.045WU);
  Hopper limbs-.765/feet-.750 (gap.015WU); TwinRoller motor-.695/feet-.650 and-.050
  (gaps.045/.645WU). All3/8/6 parts printed, with non-foot-below-foot flags.
  Tick0 START motor bottom-.065 vs foot-.020; completed both≈-.020, confirming
  why completed positions alone conceal the authored gap. No pose changed.
- Follow-up parser explicitly checks measured drag against resource damping times
  independently reconstructed raw start momentum; significant internal-row drift
  fails bookkeeping. Additional falsifications reject fabricated drag and a grip
  flag without measured foot reaction.24 parser controls plus1 annotation test/63 Python total pass
  locally; original seven controls retained. These remain synthetic parser tests,
  NOT physical load evidence. Grouped annotation avoids GitHub's per-step cap
  hiding engagement, peaks or the completed tick599 behind earlier evidence.
- Owner F30 decision remains pending; no axes/radii/angular limits or tuning changed.
  All runtime acceptance remains NOT RUN; complete-creature attempts0.

- Reporting follow-up: @ad9e5d0's first grouped annotation accidentally included
  raw tick lines and hit GitHub's4096-character message cap. Corrected selection
  excludes raw ticks from annotations ONLY (all600 stay in artifacts), packs
  <=3500-character messages, and tests the ACTUAL embedded workflow Python with
  600 mock raw lines plus first/last/ledger/engagement/F30 evidence. No raw data or
  transients dropped from the diagnostic. No physics or acceptance change.
- Formatter scope: targeted changed-GDScript format check passes. Whole-tree
  formatter check flags pre-existing core/tuning.gd; byte-equal1f2c19f copy also
  fails that formatter check. Protected tuning source is intentionally unchanged;
  linter/static checks pass. This is not a new formatting pass claim for the tree.


### R10 final implementation verification @be04bbf

- Exact implementation SHA be04bbf3fcdb106718a81f47c6adb4340982d2a2.
  M1 CI40695219730 static PASS63 Python;381 math/237 contact/129 analytic/80 load
  components PASS,600 raw rows processed; momentum ledger VERIFIED true over all
  600, including independent damping-vs-raw-start-momentum/resource identity and
  internal cancellation checks. M1 diagnostic RED solely for F30/no genuine foot
  load path. M0 headless506/0 and Android PASS in CI40695219716.
- Corrected annotations now expose COMPLETE first0/last599, engagement, peaks,
  ledger verification and F30 blocker within per-message/count limits. Retrieved
  annotations via API and parsed both row JSONs independently; raw ZIP not locally
  downloaded. Full artifact12818438383,435766bytes, SHA256
  d65c97a9845bda4f484fe34a9133efddf3f05c6023d17f717d2c7588e9733d90,
  https://github.com/sagheerh/clamber/actions/runs/40695219730/artifacts/12818438383.
- IMPORTANT peak scope:9.695448846059607N is the measured peak over ticks300..599,
  NOT all600. Actual all600 measured peak14.81106559439147N; actual applied peak
  14.807263336585688N, below unchanged N1 grip gate17.36N. Grip NEVER engaged on
  ANY tick. Empty toggle list is not a success; no smoothing/clipping hides the
  transient peak. All-gravity/support conservation and measured damping bias are
  unchanged. Global internal-row residual max8.881784197001252e-16Ns.
- Local scripts/review_checks.sh PASS63 tests; changed-GD formatter PASS, full
  linter PASS, shell syntax/diff checks PASS. AST/source-text comparison confirms
  all seven original parser test methods are unchanged; cases were not weakened.
  Protected accepted foundations/tuning/presets/derivation/contact/hinge/export
  byte guards PASS against1f2c19f. Whole-tree formatter baseline exception above
  remains explicitly reported; no protected source changed to tidy it.
- F22/F23/F25 stay owner-CLOSED; measured F31 explanation and F32/F33 diagnostics
  supplied for review, not self-awarded owner acceptance. F30 owner pose decision
  PENDING. No pose/radius/angular-limit branch, no retune/M2/camera/captures.
  FA-3/4/5/6/all coupled AC/A9/§10.6/runtime timing NOT RUN; determinism attempts0.
  Next single milestone M1: await owner's F30 decision, then authorized foot-path
  proof before FA-5 load-band/two-foot work. No angular-limit next-fix inference.


### R11 instrumentation before pinned execution

- F31 owner-CLOSED; accepted conservation verification unchanged. F35 measured
  displacement ledger surrounds existing integration/distance/hinge/contact calls
  without changing call order/arithmetic or writing physical state. Per-body
  endpoint norms/COM norm and all600 profile added. No rest/sleep epsilon; first
  plateau entry is described relative to the OBSERVED last300 P range, not a gate.
- Iteration samples1/2/4/6/12/24 use fresh diagnostic-only tuning clones. Source
  resource remains6; each600 trace/profile is preserved separately. No value is
  selected/adopted and no force data normalized for the sweep. Engine/partial
  failures remain explicit NOT COMPLETED, never zero-amplitude observations.
- F36 now tests a real synthetic body-pose motor lowered from a clear pose through
  the SAME bottom calculation/flagger as production. Production flags remain
  findings until owner pose commit; that commit MUST hard-assert the chosen rule.
- F37 reports last300 gripping count/fraction and per-tick measured grounded foot
  support / ALL grounded support, with range/mean; zero denominator undefined.
  Existing any-loaded-grip boolean is labeled existence-only, NOT sustained stance.
- Local static72 Python/changed-GD format/linter/shell/diff checks passed.
  Measurements below supersede initial runtime-pending status. No behavioral
  corrections, no tuning/preset/contact changes.


### R11 first executed observations @21a9174 / M1 CI40699163425

- Static72 Python tests;381 math/237 contact/131 analytic/80 load checks pass.
  Baseline600 motion/speed/position identities and accepted F31 ledger VERIFIED.
  Six fresh600 sweeps1/2/4/6/12/24 all OBSERVED, ledgers verified; sweep step PASS.
  Baseline load step remains RED only for F30/no gripping path. No rest claim.
- P_y transient is NOT monotonic: ticks0/1/2=-.41174373333333336/
  -.736673289905942/-1.0039825972757102Ns, tick5=-1.6166856921413673Ns,
  tick30=.17897176428114156Ns, tick60=.16342237029481205Ns. From tick66,
  all remaining values lie in observed final range.1634223702948058..
  .16342237029480586Ns. No exact-constant suffix of≥2 ending599; ulp-scale
  fluctuations persist. Descriptive envelope, NOT new rest/velocity epsilon.
- Actual same-tick prediction integrates damped PREVIOUS velocity plus gravity,
  not the COMPLETED velocity. At599 it moves endpoints DOWN.0044800..
  .0076698WU. Position projection cancels these measured displacements, while
  the independent velocity passes finish with upward velocities again. Do not
  pretend dt*v_completed was the downward predictor or directly cancelled.
- Per-endpoint Y ledger at599 (integration, distance, hinge, contact), WU:
  head A=(-.00448000608301,+.00000010103090,0,+.00447990505211);
  head B=(-.00651220824272,-.00000010103090,+.00003404447646,+.00647826479716);
  motor A=(-.00651220824272,-.00000059016495,-.00005461301432,+.00656741142199);
  motor B=(-.00625878080878,+.00000059016495,-.00392010260583,+.01017829324966);
  foot A=(-.00625878080878,-.00001338336054,+.00627216416932,0);
  foot B=(-.00766977665548,+.00001338336054,0,+.00765639329494).
  Net Y is floating noise. Contact projection dominates head/motor/footB;
  footA is lifted by HINGE rows, not contact position projection. Distance rows
  are small but explicitly accounted for. Max position ledger residual over600
  1.5612511283791264e-17WU. All per-part/per-tick vectors remain in raw/profile.
- Precision correction to "positions static": last300 Y/bottoms repeat, but all
  bodies drift X≈−7.1751877234e-6WU/tick at599 (≈.004305WU/600 ticks if sustained).
  Also HEAD tick0 bottom+.2222222222 is NOT tick599−.020; initial transient exists.
  Forward F35 concern remains valid; report measured positions, not a fixed pose.
- Steady max endpoint norm vs iterations1/2/4/6/12/24:
  .201905560144957/.2019046404620631/.2019044236543067/.20190439092127008/
  .20190437249764873/.2019043696109208WU/s. More position iterations do NOT
  remove the nonzero velocity plateau; do not recommend adopting24 as a fix.
  Follow-up also emits per-case X/Y net displacement to separate geometric creep
  sensitivity from persistent velocity amplitude. Source default remains6.
- F37: last300 grip0/300 (fraction0); foot/all-grounded measured support
  .22239253795468855...22239253795468863 (mean.2223925379546886≈22.2393percent).
  Existence is not sustained support; no new threshold. F36 synthetic actual
  lowered-motor control passed; production assertion still awaits pose commit.
- No F35 fix or acceptance claimed. F30 owner decision pending; no A/B/C branch,
  no damping/velocity epsilon/new iteration default. FA-3/4/5/6 NOT RUN; attempts0.


### R11 verified follow-up @4697137 / CI40699727411

- Baseline600 and all6 independent600 sweeps completed; motion/position identities
  and accepted F31 momentum checks verified. M1 static72 Python;381 math/237 contact/
  131 analytic/80 baseline load checks, all zero component failures. F30 is still
  the sole failing gate; diagnostic sweep step succeeds as observations ONLY.
  M0 headless506/0 and Android green in CI40699727445. No device/timing inference.
- X drift magnitude does NOT shrink with more iterations: headA per tick at
  1/2/4/6/12/24 is−7.14510179693e-6/−7.16869662992e-6/−7.17437319565e-6/
  −7.17518772340e-6/−7.17563168037e-6/−7.17570091621e-6WU. Peak speed barely
  changes and stays nonzero. Both observations argue against adopting more
  position iterations as a fix. No value adopted; no behavioral correction.
- Full baseline artifact12820897682 (791211bytes), SHA256
  f0c0c98c8b0c18f0ec05505ef19a9999d2657a5ba7fdcb267f9a4b54b9f8c441;
  full sweep artifact12819933805 (3468821bytes), SHA256
  8ab96a2f68e0b8189b63d4bbd96386f3784cf23927b795ea5795265247b084b0.
  Each raw600/profile/summary retained; no tick discarded, smoothing or clipping.
  GitHub API annotations/metadata inspected, NOT a locally downloaded raw ZIP.
- Original seven parser tests and BOTH algebra-balanced/fake-physics rejection
  methods source-text compared with3c9f942, unchanged. Protected tuning/data/
  creature/contact/hinge/derivation diff against3c9f942 is empty. Math foundations
  untouched; no acceptance threshold weakened. Norm comparison tolerance is only
  existing arithmetic identity checking, NEVER a velocity-zero/rest/sleep epsilon.
- F31 is owner-CLOSED. F35 observation complete but FORWARD ISSUE UNFIXED, no
  self-awarded closure/rest claim. F36 negative control done; production assertion
  explicitly deferred to pose commit. F37 metrics emitted without threshold.
  F30 owner pose decision pending; all runtime gates NOT RUN; determinism0.
  Next single milestone M1: await owner decision, then authorized pose+F36
  hard assertion before FA-5 band; no retune/M2/captures.


### R12 implementation before pinned execution

- Reconciled rehydrated local Git metadata to existing pushed c3b7b01 ONLY after
  comparing EVERY source file with that commit byte-for-byte; no source discarded.
  Branch remains arena/4cd0a587-clamber. No branch switching or source reset.
- Added test-only --spawn-y=.33/.53/.73, default unchanged.33; raw metadata records
  requested height. Same real model/materials/seedless diagnostic/fixed60Hz/zero
  initial motion; no iterations override for R12. Core physics files untouched.
- New three-spawn observer validates all600 rows/case, actual raw initial root,
  zero initial velocities, constant height metadata, configured6 iterations,
  existing F31+motion identities, final300 P range/mean/final and COM vertical
  speed. No equality tolerance/rest threshold introduced. Missing or aborted
  data stays NOT COMPLETED, not an equilibrium estimate. Runtime PENDING.
- Accepted R11 iteration experiment remains manually reproducible via workflow
  dispatch/scripts; routine CI now runs ONLY requested R12 spawn experiment in
  its place. Baseline F30 red is retained; no acceptance test is skipped/weakened.
- Local review78 Python tests (19/5/40/6/8), changed-GD formatter, full linter,
  shell/diff checks pass. Original72 tests retained. New synthetic controls check
  metadata, initial motion, iterations, incomplete cases and no sleep adoption;
  they are NOT physical evidence. No new feel constants, no source retune.


### R12 executed spawn sensitivity @8463240 / CI40710677636

- 78 Python tests pass;381 math/237 contact/131 analytic/80 baseline load checks
  pass. All3 requested fresh600-tick spawn probes complete with unchanged6
  iterations, same model/materials and initial zero motion; F31 and motion
  identities verified. Spawn observer step succeeds. Baseline remains RED for
  F30 only, NOT for conservation, instrumentation, or a chosen sleep predicate.
  M0 headless506/0 + Android green in CI40710677582. No device/timing claim.
- Heights.33/.53/.73 ALL produce final300 P range
  [.1634223702948058,.16342237029480586]Ns and identical mean
  .16342237029480583Ns. Final P=.16342237029480583/.16342237029480583/
  .16342237029480586Ns (spread2.7755575615628914e-17Ns). Envelope entry66/70/73.
  Final mass-weighted COM vy=.1054337872869715..0.10543378728697152WU/s.
  Max endpoint norm.20190439092127008WU/s for all3; grip fraction0 and foot
  share.2223925379546886. Shared observed NONZERO equilibrium for these starts;
  no global-attractor proof, rest acceptance or asleep predicate adopted.
- F39 attribution qualification from EXISTING telemetry, not a fourth experiment:
  mass-weighted baseline COM dx=-7.175187723425593e-6WU at599; integration
  contributes-7.175187723396494e-6; distance rows-2.927783044006219e-17;
  hinge rows+1.789698646617957e-19; contact projection0. Raw start vx*0.98*dt
  independently predicts-7.175187723393609e-6WU. Completed-velocity COM vx*dt
  is-7.321620125911735e-6WU. Thus net COM drift IS accounted for by integration
  of the retained horizontal field; per-endpoint position rows redistribute it.
  Comparing headA alone with its completed velocity does NOT establish net
  position injection, friction irrelevance, or the proposed position-order cause.
  Drift is real and soak projections remain unchanged; no causal fix selected.
- F39 horizon and F40 reference-scale churn are recorded beside FA-3. Horizon
  numbers are analytic rate extrapolations, NOT3600/10000/18000-tick executions.
  Motor churn is intra-step .94..1.53 reference px, NOT captured visible bob.
- Raw spawn artifact12825803242,1693399bytes, SHA256
  6ec8d96cfcb8ed7d6e0ee5078de7ac6ff330a32de16fe50b512ab204c9e5ee78;
  baseline artifact12826381798,791602bytes, SHA256
  8321a585c6a832e3dafb25556e557e785dc3b726e8ed2e3c8f3985205e9ff4c8.
  All raw600/profile/summary/logs retained per case. API annotations/metadata
  inspected and all3 row payloads parsed; raw ZIP NOT locally downloaded.
- All34 accepted parser/control methods source-text unchanged fromc3b7b01;
  original72 checks retained, plus6 R12 controls. Source core/data/creature/
  contact/body/hinge/tuning/derivation/export diff is EMPTY. Full linter, targeted
  formatter, shell syntax, matrix guard and diff checks pass. No thresholds
  widened; no smoothing, clipping, prescribed loads, or adopted constants.
- Owner F36/F37 CLOSED. F38 shared-equilibrium observation supplied without
  self-awarded closure; F39 remains forward SOAK finding with corrected attribution.
  F30 pose AND FA-4 asleep definition remain SEPARATE pending owner decisions.
  Next M1: await both answers, then authorized pose+hard F36 assertion, only then
  FA-5 band. FA-3/4/5/6/all coupled runtime gates NOT RUN; determinism attempts0.
  No retune, velocity epsilon, damping change, M2, or captures.


### R13 measured sample responses @de26fa3 / CI40802438116

- Pinned engine381 math/237 contact/131 analytic/80 load components PASS;
  both600-tick threshold probes OBSERVED, all F31/motion identities verify.
  Observer on/off full physical snapshots equal at every tick for each case.
  Byte-serialized snapshot comparison is added in the follow-up for stricter
  diagnostic evidence (not creature determinism). Baseline F30 ONLY remains RED.
- Crucial actual last300 sample counts PER PASS (all candidates active):
  head3/3, motor3/3, foot3/2. Total17 active responses/tick, NOT one contact/body
  and NOT two foot samples in both passes. Candidate count uses current extent,
  not an assumption from rest length. Counts stable for every last300 tick.
- At599 final pass, all8 active samples take static branch and retain0 tangent.
  Motor u0: A vx .0000483227356581 ->0, B vx .00559673787580 survives.
  u.5: A/B become[-.0027983689378984,+.0027983689378984], sampled tangent0.
  u1: B becomes0, A stays-.0027983689378984; earlier u0/u.5 tangents become
  +.0027983689378984/+.0013991844689492. Head similarly ends A vx
  -.0000241613678290311, B0; earlier tangents+.0000241613678290311/
  +.0000120806839145155. Foot final pass has independent u0/1 and ends vx0
  at599 (last300 body COM range only +/-8.67e-19 float noise).
- Thus zeroing EACH interpolated sample does not simultaneously stop endpoints:
  later overlapping rows measurably reintroduce earlier sample tangent. This is
  observed in actual multi-sample responses, not a single-sample assumption.
  Body-end COM vx final pass: head≈-1.20806839145e-5, motor≈-.0013991844689492,
  foot≈0. First-pass COM vx: head+.000295201730920, motor-.000504600195549,
  foot+.001771830516589WU/s. No change to sampling/order/friction proposed.
- Completed creature COM vx final300 baseline range
  [-.0004392972075547341,-.00043929720755467625]WU/s;1.5 case
  [-.0004392972075547327,-.0004392972075546731]. Maximum paired late difference
  3.984442983884229e-17WU/s. Mean actual COM dx baseline=-7.175187723414263e-6
  vs1.5=-7.175187723414633e-6WU/tick; integrated contribution BOTH
  -7.175187723396494e-6. Steady drift insensitive in this diagnostic, NOT a
  blanket threshold-inactivity claim or a friction fix authorization.
- Transients DO differ: full600 active/static branch counts .15=9917/9850
  (67 non-static),1.5=9909/9909 (0 non-static), total candidates10151/10150.
  Max paired completed COM vx difference over600=.014493333006502587WU/s.
  Last300 BOTH5100/5100 active responses use static branch, so increasing its
  threshold cannot change that observed branch selection. Max endpoint impulse
  identity error1.1102230246251565e-16; sampled target error<=4.164e-17WU/s.
- F42 BOTH cases: grounded sets[0,1,2] for every last300 tick, active contacts
  on all300 ticks, zero newly-grounded transitions in that window. Support
  normal impulse sum≈.726601780739229Ns/tick remains nonzero, not position
  cleanup. Raw per-contact signed impulses and all600 sets/transitions are
  retained as contact-events.jsonl / grounding-events.jsonl per case. This is
  NOT a sleep-breaking/sleep-eligible classification or a changed FA-3 criterion.
- Source-pinned artifacts: R13=12866817056,3405462bytes,SHA256
  7c19029879a62c732cbb9e01871705674a95fc57818afbc37f1a4f593c38a502;
  baseline=12865849732,2482879bytes,SHA256
  baaa4c558b290612142ec20eaa76b7cb9850ec3672be2ad534ba51a0b7901dd7.
  API annotations and metadata inspected; raw ZIP not locally downloaded.
- F38 owner-CLOSED; F40 accepted; F39 REVIEWER CORRECTION (not agent error).
  F41/F42 are measurement/clarification findings, not closed by self-award.
  Owner F30 AND asleep/F42 still pending -> authorized pose+hard F36 assertion
  -> FA-5 band. Re-measure F41 after pose and compare. No resource edit, retune,
  epsilon, damping, iterations adoption, geometry/limits, M2/captures. FA-3/4/5/6
  and all coupled runtime gates NOT RUN; creature determinism attempts0.


### R13 strict-observer follow-up @5c1bffe / CI40802791884

- Strict var_to_bytes full physical snapshot equality passes EVERY600 ticks per
  threshold case (and baseline). It compares serialized state, not approximate
  float equality. This is observer noninterference ONLY, not a determinism gate.
- All91 Python checks pass (19/5/40/13/6/8), targeted formatter/full GDScript
  linter/shell syntax/diff checks pass. Pinned381/237/131/80 components pass;
  both threshold cases OBSERVED with the exact same measured ranges/counts as
  above. Baseline remains RED solely for F30; observer step succeeds. F31 analyzer
  function unchanged and all34 accepted parser/control methods source-identical.
- New independent checks reconstruct active-vs-skipped from sampled distance,
  normal length, endpoint inverse masses, per-sample positional cleanup and all
  impulse responses/continuity. F31/motion verification failure is rejected,
  never silently converted into an OBSERVED diagnostic case. No resource edits.
- Full600 grounded transitions, BOTH cases: tick0 new[1,2] (motor,foot), tick7
  new[0] (head), no lifted transitions. Last300 grounded[0,1,2], no new/lifted,
  yet17 active sample responses/tick. At599 normal impulses per sample for pass0:
  head[.105563333819726,.15133106814863925,.07626349006922774],
  motor[.0956523645662548,.0901259481497068,.046074761884681424],
  foot[.05752437215064493,.06907111040760779,.034995331542740704]Ns.
  Pass1 all8 normal impulses0 but signed tangential impulses persist. Raw signed
  per-contact impulses (both passes), flags and all600 sets remain in artifacts;
  no sleep-breaking/eligibility filter chosen or criterion rewritten.
- Updated artifact12866996647,3407167bytes,SHA256
  48b3687555a2351eaecb7e4add55062ebcb3606a406710c782548b805a72346e;
  baseline12866274067,2483260bytes,SHA256
  aacd23d958f06e19b3772dde30352017cd6fad2c69fbb65816f080062463907a.
  API annotations/metadata inspected; raw ZIP not downloaded locally. M0 run
  40802791874 headless506/0 PASS; Android result recorded in final CI/PR status.
- R11 iteration and R12 spawn drivers/controls retained, workflow_dispatch runs
  them; routine CI now runs the requested R13 observer comparison. No runtime
  acceptance upgrade: owner pose+asleep/F42 still precede authorized pose+F36
  assertion and FA-5 band, F41 must be re-measured after pose. FA-3/4/5/6 and all
  coupled runtime gates NOT RUN; complete-creature determinism attempts0.


### R14 pose measured @126dc80 / CI40804352094 — prediction NOT observed

- Hard authored F36 audit PASS, exact exemption TwinRoller foot5 parent0 retained;
  original horizontal-foot two-sided synthetic bad-pose control still fires.
  JSON diff ONLY five foot axis fields (Slug2,Hopper5/7,TwinRoller4/5 ->DOWN).
- Paired unchanged Slug600/.33/6/.15/zero-motion, sleep DISABLED, real physics:
  before grip0/600; after1/600 (tick19), loaded grip1 tick; last300 grip0 BOTH.
  After last300 foot share.22240637932820798 vs before.2223925379546886.
  Path existence now demonstrated once, NOT sustained support or FA-5 acceptance.
- Before all-grounded reaction43.59610684435376..377N, after
  43.596103429635704..571N; literal43.4+/-.723 every last300 passes BOTH.
  Foot applied before[9.6775186630127,9.677518663012702], after
  [9.678122826771673,9.678122826771675]N; foot measured before
  [9.695448846059604,9.695448846059607], after
  [9.696051516603347,9.69605151660335]N. Both F31/motion independent identities
  verify; everytick raw supports retained, no clipping or supplied load.
- F41 unexpected FOURTH outcome: last300 still grounded[0,1,2] with same active
  counts head3/3,motor3/3,foot3/2 =17/tick. No predicted collapse to sole foot.
  Mean actual COM dx changes -7.175187723414263e-6 ->+9.337328797577746e-6
  WU/tick: reverses direction and grows, NOT smaller, NOT identical old drift with
  different geometry. Retain F41; no pose-artefact downgrade or sampling fix.
  Post completed COM vx range[.0005716731916895578,.0005716731916896102]WU/s.
- This is the CURRENT free-hinge solver with UNCHANGED root spawn.33: after A,
  authored pad starts at-.27WU (previously-.02), not placed on a clear foot-only
  stance. No silent spawn correction. Authored bottoms do not prove dynamically
  maintained pose; angular limits/motors/self-contact are still absent. Do not
  claim why all transient/contact differences occur without further evidence.
- Pose CI now green on original existence criterion, not a strengthened stance
  acceptance:381 math/237 contact/136 analytic/80 load components PASS, all600
  both cases OBSERVED. FA-3/4/5/6/all full runtime gates NOT RUN; determinism0.

### R14 sleep component implementation — pinned engine pending

- EXACTLY two owner R14 Decision2 additions: sleep_still_displacement_wu=.001,
  sleep_dwell_ticks=30. Every previous tuning-resource byte unchanged after
  removing these two lines; source-lock tests cover this and axis-only catalogs.
- CreatureSleep reads only supplied physical snapshots, maximum per-body COM
  displacement strictly below.001 for30 consecutive fixed ticks. No grounding or
  velocity epsilon predicate, no hysteresis/decay/grace/impulse threshold.
- SleepingLoadProbe composes the existing awake probe; diagnostic600 stays awake
  and unchanged. Sleep zeroes EVERY endpoint velocity and parks physical state.
  Any input fully re-arms; asleep ungrounded->grounded wakes (F42), persistent
  support does not. Contact query runs EXISTING resolver on detached clones,
  never injecting loads or moving/impulsing parked production bodies.
- Snapshot contains physical endpoints/tick plus sleep flag/dwell/displacement/
  last sleep/wake ticks. Atomic restore;600-step real engineering Slug tests
  partial-dwell and asleep checkpoints, exact byte-state continuation and wake
  ticks, boundary/reset controls, persistent/new-contact controls and zeroing.
  Engine pending: no fabricated tick/success counts; this is NOT creature
  determinism, all-presets FA-3 or motor-lurch FA-4. Public Sim remains untouched.
- SLEEP PARKS THE PLATEAU, DOES NOT FIX IT. Awake endpoint speed remains about
  .202WU/s (30px/s at150px/WU); feel shimmer risk for motor stage, not addressed now.
- Next M1 after sleep evidence: motors/angular limits/self-contact, then Hopper
  two-foot FA-5 and all3 FA-3/4, public Sim LAST. No tuning changes beyond the two
  owner constants, no retune/M2/screens/camera/captures. Determinism attempts0.


### R14 sleep executed @e36c407 / CI40805104578

- Static96 Python=19/5/40/13/5(new R14)/6/8 PASS. Source locks prove ALL previous
  tuning-resource bytes unchanged (only.001/30 additions) and non-axis preset
  content/parents unchanged. Original34 accepted parser/control methods retained.
- Pinned381 math/237 contact/136 analytic/80 load +3659 sleep component checks
  PASS. Full M1 CI green; unchanged paired pose600 repeats exact measured results
  above. No sustained-support/feel/runtime acceptance implication from green CI.
- Sleep ticks61/210/390, wake ticks180/360,600 original state rows; first sleep
  after62 completed fixed ticks (~1.033s), not a fabricated plateau-entry estimate.
  Restore checkpoints47 (15 accumulated still ticks) and62 (asleep) compare
  553+538=1091 subsequent physical+dwell/sleep/wake states byte-identically.
- Strict boundary/reset/max-per-body tests, all-endpoint velocity zeroing,
  persistent-support NOT waking and actual false->true grounded wake controls
  pass. Bad controller/wrapper restore atomic; invalid dwell rejected. Input
  re-arms fully, prevents accumulating dwell while held. New contact wake uses
  existing resolver on detached clones, no impulse threshold or force injection.
- Awake F41 probe stays awake by construction; wrapper records a separate
  awake_solver_trace_before_sleep_parking and never presents stale/parked force
  fields as a fresh conservation trace. Snapshot predicate reads physical body
  snapshots only; no wall-clock/frame-time or hidden temporal cache.
- Sleep artifact12868315418,5667bytes,SHA256
  0b06ae9a38fb1135a7b62c1c759fff911cc9e329a79471fe948bcf460560a207;
  paired pose12867413739,3985484bytes,SHA256
  f673165d7a2ec938d998607ceb0ededebb391cdaea8024c2b1125ae187b928d0.
  API annotations/metadata inspected, raw ZIP not downloaded locally. All600
  per-body support channels/contact samples retained separately from sleep rows.
- Steps4–6 NOT implemented in this increment. Motors/limits/self-contact next,
  then actual Hopper two-foot band and all3 FA-3/4, public Sim last. F41 persists;
  larger/reversed drift with SAME support set is not the owner's identical-old-
  drift/DIFFERENT-geometry trap. No new approval inferred for a friction fix.
  All full runtime gates NOT RUN; complete-creature determinism attempts0.


R14 provenance follow-up: accepted F31 analyzer function and old controls remain
verbatim; CLI diagnostic_summary updates only runtime owner-decision/limitation
metadata so published reports no longer claim pose/asleep decisions are pending
or that the separate sleep component is absent. Awake diagnostic behavior is
unchanged. New source/provenance control brings Python total97. Pending feel plans
retain NOT RUN, with reasons updated to acknowledge existing components.


### R14 final code validation @d4c260e

- M1 CI40805642120 GREEN:97 Python,381 math/237 contact/136 analytic/80 load,
  plus3659 sleep components pass. Pre/post600 result repeats exactly;1091 restored
  continuations identical with sleep[61,210,390]/wake[180,360]. All40 original/R12
  load-control file bytes and accepted F31 analyze function remain unchanged.
- M0 CI40805642118 GREEN:510 headless checks/0 failures and Android export/
  alignment PASS. No performance/device or full-M1 waiver/gate inference.
- Final pose artifact12868411026,3985484bytes,SHA256
  d32688683bbbe33a71ea61ba0074be0f3881bb7e91540646b0d71df3b3199477;
  sleep12868520505,5667bytes,SHA256
  23d0b2c0d05cd0ed40182481cb7105d59e80b761f636e65d7178fd83e6425312.
  API annotations/metadata inspected, raw ZIP not locally downloaded.
- Active matrix evidence now reflects approved A/A1 rather than a pending owner
  pose choice; FA-4 scope explicitly all3 presets per R14. All full runtime gate
  statuses stay NOT RUN. Steps1–3 implemented; steps4–6 remain next, not complete.


### R16 measured F48/F49 @34b0cfd / CI40813196081 (component jobs PASS, M1 RED)

- Dedicated observation job123248107087 SUCCESS; all FIVE requested raw cases
  OBSERVED (3×6000 actuated, 2×600 baseline), observer equivalence/identities pass.
  Original job fails ONLY F47 load-path door, not components or a measurement.
- Live-spring zero-input before, mean COM dx at600/3000/6000 respectively:
  .0003903690062867916 / .00039180535626671774 / .0003903690062867022WU/tick.
  Post-pose+.01: .000437169361675691 / .00043716936167569775 /
  .0004371693616756641. Last6000 final300 net drift3.51332105658 /3.93452425508
  px/s at150px/WU (WU/s .0234221403772 /.0262301617005). Spring return LIVE at0.
- Both oscillating under exact observed-pattern criterion, NOT settled by6000:
  before vx[.02054052008572514,.04154125326362168], after
  [.022195775258306853,.04314821835302906]. Settled values null. Bounded bands /
  similar means are NOT proof of equilibrium, and failure of exact recurrence
  is NOT proof of divergence. Add raw count-period/lag differences (no tolerance,
  no pass criterion) so binary64-scale repeat variation is visible, not hidden.
- F49 pre-fold angular max |net tick phase coordinate| before/after/raised:
  .009223146015561803/.008874611801879255/.009034439887647586WU.
  Max drive angular impulses .044444719141974176/.04438638495109458/
  .0443745109016708 (mass*WU^2/s); max limit-block .00017721591385786578/
  .0003400274408216497/.0005666264465788995. Self-contact phase/impulse maxima
  all0 for Slug (real D10 pair list excludes its foot and adjacent head/motor).
- Annotation per-step cap10 hid later F50 results even in the separate job.
  Full reports/artifacts are complete; pack bounded notices and compact repeated
  metadata, assert<=10 rather than silently dropping evidence. Repeat measurements
  to expose both complete6000/raised/baseline F50 summaries. No physics change.
- Next single M1 stage after this evidence: public Sim/F45/replay, NOT implemented
  this increment. All coupled runtime gates NOT RUN, determinism attempts0.


### R16 final measurement @a6c33f8 / CI40813617730 — expected M1 RED

- All5 cases and ALL17 report lines visible:9 bounded annotations including runner
  warning; no silent cap loss. Observation job SUCCESS; static128 Python PASS,
  mechanics931/sleep3659/math381/contact237/analytic136/load80 PASS. The ONLY
  failing step is unchanged-force + new F47 sustained-support Slug diagnostic.
  That is the required honest RED, not “M1 green” or a bypass. FA-5 untouched.
- F50 same post-pose roots .6100000000000001/.81, actual legal+.01/+.21:
  - Actuated final300 through6000: .0004371693616756641 /
    .00043716936167566446WU/tick (difference3.7947076036992655e-19).
    vx envelopes [.022195775258306853,.04314821835302906] /
    [.022195775258306908,.04314821835302908], overlap. Per-tick count phases
    differ; histograms match (6-tick count recurrence), no pose-causal upgrade.
  - Baseline final300 through600: 9.337328797581247e-6 /
    9.337328797582121e-6WU/tick (difference8.74138001566438e-19).
    vx envelopes [.0005716731916895587,.0005716731916896063] /
    [.0005716731916895565,.0005716731916896077], overlap, count regimes identical.
  - These finite-window results show only binary64-scale mean differences with
    the requested+.20 spawn change. Reported, NOT closed as a landing artefact
    or a settled pose-causal finding. F41 stays OPEN; settled comparisons null.
- Raw recurrence diagnostics through6000: pre-pose count period9, post-pose and
  raised period6. Repeat-lag max COM-vx differences3.920475055707584e-16 /
  3.608224830031759e-16 /4.544975507059235e-16WU/s; corresponding max dx
  8.939246912142984e-16 /8.881784197001252e-16 /8.480629393181616e-16WU/tick.
  This exposes a recurrent oscillation rather than hiding it behind a range.
  NO tolerance/pass criterion inferred; exact settlement still unestablished.
- ZERO-INPUT DRIFT, LIVE SPRING RETURN: final300 actuated pre/post/raised
  3.5133210565803203 /3.9345242550809765 /3.93452425508098px/s at150px/WU,
  net WU/s .023422140377202135 /.026230161700539843 /.026230161700539868.
  Post-pose baseline .08403595917823123 /.0840359591782391px/s at the2spawns.
  Nonsettled WINDOW MEANS, NOT equilibrium; no correction/retune applied.
- New controls128 Python, original40-control file/accepted mechanics/tuning bytes
  unchanged. Runtime-only code change is angular/self telemetry, not forces.
- Full19200 raw ticks in artifact12871566645 (81,813,276B), SHA256
  fb50e8157cb349b27da42de1d9a460dfd91701a92ba5e22fbc46a74ad7f7273e.
- Completed ordered R16 steps1–3 only. Public Sim remains STUB; F45 superseded
  legacy-sleep docs and public replay NOT yet wired. No new owner decision needed.
  NEXT single milestone M1: public Sim + F45/replay, then the ordered runtime
  acceptance stage. FA-3/4/5/6/all coupled runtime gates NOT RUN, determinism0.

R22 scheduling correction: GitHub integration denied manual Actions dispatch
(HTTP403 Resource not accessible by integration); NO diagnostic was started by
that request. Use one push tagged [R22-once] for the single cell instead. Legacy
runtime jobs remain manual-only, NOT passed/waived/closed; static checks stay
active. Subsequent closeout commits [skip ci], new cell requires explicit marker
or authorized manual dispatch, never auto repeats on PR or ordinary docs push.
No source/resource change or additional diagnostic arm results from this fix.

R22 closeout CI preservation: component/public regression jobs are automatic again
for future ordinary changes; they were skipped on the one-cell marker run and
are NOT rerun by this [skip ci] closeout. Historical convergence/spring/F56-reference/
R21 experiment jobs remain manual-only so STOP does not silently launch old sweeps.
Original test code/floors/F47 failure and public baseline remain intact; scheduling
is not a waiver. No additional runtime invocation/arm after the R22 result.

### R27 publication verification — no physical rerun

Publication93c17d6: M1push40963825251 / PR40963830891 static218controlsPASS;
publicjobs123763106589 /123763125623 PASS, FULLsummaries EXACT measured2cf2c93
and finaltestedR26. M0push40963825268 / PR40963830921 headless516/0+AndroidPASS.
R26/R27 physicaljobs allSKIPPED; onlyfailedstep unchanged mandatoryF47. Source
AC201a's intentional measuredFAIL remains in evidence, not rerun or hidden.
PR3 stilldraft/open, updatedcurrentR27intro; protected59421char tail EXACT
SHA23f409294933ddd4638139254f41cc5bee6c70a35f28cea6509f9d0c199d76be.
Final follow-up records verification only; no product/code/tuning/baseline edit.


R28 final regression closure (no new R28 arm): code9784b5f, M1CI40971243040:
static123788231404success226/0; revertedpublic123788231768teststepPASS9053/0,
delivery308/0+1446/0, oldbaselineMATCHED, jobREDartifactquota only (not D2).
M0CI40971242996headless123788230935success516/0; expectationsunchanged.
Math123788231589381/0+237/0stepsPASS but jobREDquota beforeF47; diagnosticNOTRUN.
AllnewR28jobs closedliteral446d870 and skipped; historicalR27/soak not rerun.
PR3stilldraft/protectedtail59421chars SHA23f409294933ddd4638139254f41cc5bee6c70a35f28cea6509f9d0c199d76be unchanged.
No productionphysicschange remains; rawartifactdelivery and allCIgreen blocked
byquota. Stop/waitowner. Do not retryphysicalmeasurements to repair artifacts.

### New physics work — V9 closed, V10 dependency candidate preregistered

V9 sourcefb9ff2c/run41162545941: native144PASS; complete new600 but postureFAIL
(t26/max36.0588°), no original4s/600sleep/maxstill4/30. Numeric/length/penetration
within original bounds; all7200NOTRUN. Unadopted/closed, no unchanged replay.
Offline phaseaudit7PASS identifies first violation after integration14.2636° ->
final15.5751°; true endpoint ledgers, not unsaved chronology/impossibility proof.
New V10 moves first of same2 contacts before integration, same6 position sweeps;
new20 native components gate any public600. See preregistration
`.review/physics_fix/articulated_execution_v10_plan.md`. No core/tuning/manifest
change, threshold waiver, manufactured phone evidence, M1 signature or FA3 credit.

### V9–V11 physics continuation closed — no acceptance/adoption

V10 native164PASS/world5stop; V10b native171PASS/world155stop, posture18/max55.03°.
V11 source30a2205/CI41164232428/publisher65107d7: native185PASS; ONE new600
finite/solver0 and originalgeometryPASS, but posture16/max49.18184°/airborne18/
no4sor600sleep/maxstill4. Three7200NOTRUN. ExactsourceM0/foundations/R29SUCCESS.
New full-force and projection-identity component controls are NOT world acceptance.
All original thresholds/core/tuning/manifest unchanged. M1BLOCKED/NOTSIGNED,
AC201/202productionFAILED/FA3uncredited/M2blocked. No unchanged repeat/adoption.
Closure `.review/physics_fix/articulated_execution_v11_closure.md`, full pinned
captures/Variant failures preserved. Offline closure10/Variant10/routing33/rational
support6 controlsPASS, ZERO new engine ticks. Rational support composition is next
research, not a selected/validated new creature model. Real device/feel gates remain.

### Owner-authorized support redesign — real idle and Slug long-run breakthrough

D08 permission retained; original presets/core/tuning/manifest remain untouched.
V17 rigid horizontal capsule pads: native341/full600 solverOK, posture12.850817deg,
noairborne, netCOM.0776663WU; sleepFAIL. V18 simultaneous normal/material manifold
fixes serial complementarity and preserves real per-body forces/frozenN. V18b
source9dfc420/run41205937516 native370/full600 solverOK, posture9.918304deg,
noairborne/net.0617381WU; real firstsleep245 but ORIGINAL4sFAIL. No waiver/retry.

New radius-derived coplanar toe stance removes geometric .045WU motor/toe skin
mismatch using existing radii/length, not angle tuning or a fake collider. All pins,
masses, materials and thresholds preserved. Exact supported free-head modal
projection preserves actual motion under tilt/drive, not a global upright lock.
V19 first14 failed strict local drag actual ULP gain; retained, never excused.
V19b f101721 native388: ORIGINAL600 full predicatePASS (posture0/noairborne/
penetration0/netCOM0, firstsleep29 =30 actual ticks), but Slug7200 stops214.
V20 8496abf native391: same original600PASS, Slug stops247. Shared-pin normal
and affine target hull controls use exact archived work/history without replay.

V21 bccae29d24ad9e7aa13148ac2b864db5a323cc45/run41207843989/publisher16135e2:
native395PASS; ORIGINAL600 full predicatePASS AND sequential Slug7200 full geometry
PASS (maxlength2.220446049250313e-16WU, penetration0). Then Hopper5/status30;
TwinRollerNOTRUN. Long posture/airborne/sleep fields honestly null/unmeasured,
not zero-PASS. Exact source M0/foundations/R29 SUCCESS. Immutable complete states,
source/build/transport hashes and failure Variant preserved. Source-specific
original600/Slug results are NOT determinism, production adoption or M1 signoff.

Independent offline analysis98controlsPASS (including actual anchored .001/30,
source/transport/full600, posture/airborne/true-spawn, real7200 input stream,
nonvacuous sleep-to-held-input wake60). FA3/F31 NOT credited: partial actual
492batch impulse audit closes linear residual3.33e-16Ns/C-drag5.20e-17NsWU,
shared events counted ONCE; full force/resource/clamp mutation coverage absent.
See `tests/coplanar_idle_analysis.py` and `.review/physics_fix/` pinned evidence.

V22 new native27 clean source7f39bf3/run41208272288: distinguish fixed affine
normal VARIATION from actual target0. Only homogeneous facts permit zero-state
publication. Archived eight-body Hopper5 now solves/dissipates/actual momentum
closes without rounding its positive target. New sourcec49fcc6 registers original600
then sequential allthree7200 behind all397native/57failclosed runner checks.
Result must be closed separately; no result presumed here. ProductionAC201/202
remain FAILED, M1BLOCKED/NOTSIGNED/M2blocked. Full generic force/rank/replay,
five runtime gates and actual device/performance/layout/signoff remain unproven.

V22 CLOSURE: c49fcc66ee9f09a1ebb225a5de8dcc6a41cda734/run41208462933 /
publisherbe0ed65: all397nativePASS; original600 full predicatePASS; sequential
Slug7200 full geometryPASS. Hopper improves from5 to256 but FINAL support rejects
status30 after same6position sweeps; TwinNOTRUN. Failing first complete stage
strict actual energyPASS .36898995024244435 ->2.2615868935345803e-12. Underlying
final factor/target/publication failure is NOT yet diagnosed; never assume ULP.
No unchanged source retry, later arm, production adoption or signature. Full pinned
captures and annotations retained. Exact-source M0/foundations/R29 SUCCESS.
Independent offline98analysis controlsPASS including sourcec49 complete idle and
Slug7200 data, real firstwake60 and any-input sleep rearm. This is NOT full FA3,
force audit, feel, determinism or a device/performance gate. Next physics action
must inspect archived Hopper256 FINAL phase read-only before proposing a change.
