# M1 R26 — LAST bounded diagnostic increment (pre-measurement)

Authority: owner-selected Option3, readonly reviewer `1df02f5`,
`.review/M1_R26_BRACE_REJECTION_REVIEW.md` §10. Reviewer files are NOT copied.
This plan is authored before results; no outcome-dependent fixture/knob revisions.
Matrix remains **8/18**. No M2, waiver, camera, captures, mass/weight change,
epsilon, .05 widening, new slip/stiffness/damping values, brace rerun or lurch trial.

## Atomic rejection / retained adoption

One source commit removes brace implementation, state/target, snapshots/restore,
hash/presentation getter and its runtime/Python forgery tests. Original non-brace
restore/rollback/math guards remain. Historical R25 reports/F56 brace-internal
column remain unchanged. Delete obsolete brace CI job, not historical evidence.
Four P-B resource lines stay EXACT (resource SHA256
`5f4d0d06564fb3a0847309d83cf5f3c87b9321ea5e2dd87e572e4bd9fe750666`):
bound30, k10, damping.5443327361211717, cap12. Default friction stays.9.
Normal physics ordering stays unchanged. Diagnostic switch defaults false and
is never set by public/product code. Phase/contact observations are detached;
baseline observer-on/off physical states must be byte-identical.

## D1 — four process-local duplicates, once each

Authored Slug, old legal .01WU floor clearance, same uniform diagnostic material,
P-B and released input for 6000 ticks. Coefficients in registered execution order
**.9, .3, 1.8, 3.6**, changing `physics_grip_friction` in a resource duplicate;
both material and terrain read that duplicate (otherwise `min()` masks the arm).
No production resource save. Fresh observed/unobserved pair in each cell.
Keep raw endpoints, position/momentum ledgers, contact candidates/counts/flags,
real drive requests/bounds/applied, frozen N, resource damping and F56 guards.
Report positional drift and signed net friction impulse/thrust over last300;
all6000 raw rows validated; no idle translation counted as commanded movement.
Exact .9 reference drift must reproduce **8.550150769956836px/s**.

**Interpretability registered in advance:** current friction is capped tangent
retention, not an unbounded Coulomb coefficient. Static branch forces zero
retention; gripping .9 and both1.8/3.6 can hit the dynamic clamp. Independently
audit material/terrain coefficients, actual `may_grip`, retained tangent, actual
endpoint response and branch counts. Publish drift/thrust/coefficient ratios;
do not invent a proportionality threshold or mistake equivalent clamped
interventions for evidence of an upstream cause. Values are diagnostic ONLY.

## D2 / F76 — one baseline and ONE diagnostic duplicate, 7200 ticks each

Use **Hopper**, including its literal limb6 failure, not a foot-only proxy.
Public Sim, authored geometry/clearance, seed305419896, repeating released/L/R/
both 60-tick blocks identical to independent AC202 script. Raw per-tick body
endpoints/rest lengths and every distance row at:

1. after integration;
2. last existing distance block (before hinge/angular/self-contact);
3. after final hinge;
4. **after final angular**;
5. after final self-contact;
6. **after added final distance** (diagnostic arm ONLY);
7. after each subsequent velocity/contact-cleanup pass;
8. completed public tick (independently measured).

Iteration hooks overwrite observations, so only the final iteration is retained.
ONE added traversal uses **the same `_links`, `project(_tuning)`, compliance,
multipliers, constants**, no multiplier reset, no velocity edit. Location:
after the full position loop, BEFORE velocity/contact cleanup. Ledger records
this in existing distance column. No unregistered after-contact repair.
Report raw-recomputed worst all-part AND **literal-limb** errors per tick/phase,
and7200-tick maxima/tick/part/kind. Parked ticks are explicitly distinguished
from nonexistent awake projection observations. Baseline observer-off twin
checks snapshot equality every tick. Diagnostic is not adopted or relabeled a
passing production AC202 run. Criterion remains **.05WU at completed tick**.
Angular rigid-body rotation itself preserves body extent algebraically;
therefore F76's suspected angular attribution remains a hypothesis. Separate
hinge/self/contact observations prevent false phase attribution.

## F77 — independent parallel FA5 fixture repair

Predeclared `tests/fixtures/r26_fa5.json`: unchanged two-foot Hopper stance600,
+2WU drop onto feet600, natural authored ledge departure1200, +4WU midair12.
Stance reproduces the known natural above/below/two-foot startup; lifted cases
supply initially clear geometry rather than hoping an ordinary walk becomes
airborne. Preflight checks actual SDF clearance BEFORE lifted cases step;
first completed tick must actually have neither foot grounded/gripping.
The ledge is a test-only exact primitive SDF, not a product geometry change:
upper quadrant x>=0,y<=0 union lower plane y<=-2.5. Start x.1; no imposed velocity,
pose edits, synthetic support flags, or qualifying load injection. A completed
ledge departure must be observed after real support, both feet left of edge,
airborne and above lower floor; otherwise report fixture shortfall, no retune.

Every case emits unconditional reason, failing tick (null iff completion),
status and observer status, plus initial geometry and last pre-step geometry on
failure. Wrapper records import/engine failures even before initialization.
Independent checker reconstructs frozen previous N, global lowest geometry,
bilinear SDF normal, gravity+real hinge/self-contact load, 40%/N threshold,
actual per-candidate eligibility and resulting grip flags, completed flags,
and momentum guards. Report capsule sample counts separately from foot/pass
counts. **Events** are maximal consecutive TICKS per foot/branch, collapsing
samples and both passes; two-foot pair gets its own episode key. Report episode
count/duration, true-grip count (zero for non-grip branches), and N/threshold/load
distribution. One brief landing episode must not be sold as robust sustained grip.
Coverage needs below, at/above, two-foot, airborne (N0 disabled separately).
Missing branch/fixture or noncompletion is NOT PASS; no automatic matrix credit.

## Baselines / no second measurement fork

Brace removal changes public physics and serialization. Explicit R26 generator
accepts only the old R25 stream `a2929a0c…`, requires successful byte-equal triple
replays and clock checks, and records source/run/final/stream/tick hashes under
**M1-R26-BASELINE**. Normal checker is NOT relaxed. Same-source public job applies
ONLY generated baseline/provenance overlay and reruns strict replay/clock gates;
then generated bytes are committed without solver changes and normal CI reruns.
D2 is an isolated nondefault Hopper diagnostic, NOT a replacement production
baseline; each paired raw trace gets separate source/ordering/hash provenance.
No D2 public baseline is silently adopted. Any later authorised production fix
would require its OWN separately identified regeneration/provenance.

After these results, **NO more measurement/sweep/brace/lurch trial**:
BOTH D1+D2 located correctness-shaped causes => one subsequently fixed increment
implements both then reruns AC201+202. EITHER inconclusive => **Option2**;
owner authors AC201 number; AC202 keeps honest measured failure. Engineer does
not author that number, rewrite AC201, or pre-claim that either cause is found.
