# M1-B01 — contact geometry derived from the viral-game thesis

**Purpose:** replace my earlier flat-number proposal with values *derived* from what
makes CLAMBER a viral game rather than another Play-Store physics clone, and expose
the two traps the first proposal would have walked into.

---

## 1. The thesis the numbers must serve

GDD line 654: “*The feel is the product.*” The viral loop in GDD §1 is not level
content, it is: **a ridiculous creature + near-miss failure + a 10-second clip + a
code anyone can try to beat.**

A copycat physics game optimises for *competence*: reliable walking, forgiving
collisions, stable bodies. That reads as generic and generates no clips.

CLAMBER's differentiators, and therefore the real tuning targets:

| # | Differentiator | Physics requirement |
|---|---|---|
| D-A | **Readability at thumb size** — the creature must be instantly funny in a 2-second clip | Every part legible at 150 px/WU; head is the largest silhouette element |
| D-B | **Near-miss, not near-impossible** — failure must be funny, not punishing | 60–80 % success on repeated identical inputs; retry ≤ 1 s |
| D-C | **Every player-made creature feels alive** — the share loop depends on it | Grip/inertia must scale with the creature, not with its absolute mass |
| D-D | **Comedy comes from the head** — it carries the eyes and the mascot | Head is proportionally heavy and visually dominant |
| D-E | **No “broken toy” jitter** — jitter is the #1 tell of an amateur physics game | Radii must satisfy D-10 self-collision geometry with margin |

---

## 2. Two traps in my earlier proposal (both fatal, both caught)

### Trap 1 — the grip threshold must not be an absolute force

I first proposed `grip_normal_force_threshold = 40.0`. That silently breaks the
tutorial.

**The Slug is head + motor + foot, one foot only** (GDD line 138). With the mass
model `mass = per_wu × length`:

```
head   2.2 × 0.35 = 0.77
motor  1.6 × 0.30 = 0.48
foot   1.2 × 0.25 = 0.30
total              = 1.55 mass      weight = 1.55 × 28 = 43.4
```

A single-foot stand transmits **100 % of 43.4 ≈ 43** normal force. A threshold of
40 would grip by a margin of 3 — and any lean, any damping, any contact-slop
transient drops it below 40 and the Slug **never grips**. Tutorial dead on frame one.

Worse, the *same* absolute threshold on an 8-part creature (mass 5.63, weight 158)
is 25 % of body weight — always exceeded, so heavy creatures get free stickiness.
One constant, two opposite failures: exactly the “inconsistent player-made physics”
that makes copycat games feel cheap.

**Fix:** make it dimensionless — a **fraction of the creature's own weight**:

```
grip if  normal_force_last_tick >= physics_grip_normal_force_ratio × (Σ m_i × |g|)
```

- standing on one foot → ratio 1.00 → grips (Slug survives)
- standing on two feet → ratio 0.50 → grips
- stride transition, light foot → < 0.40 → slips → **the hobble**
- airborne → 0.00 → no grip
- heavy or light creature → identical *feel*, by construction

`0.40` sits deliberately in the middle of the useful band (0.25–0.55). Success is
testable, not vibes: see FA-5/FA-6 below.

### Trap 2 — visual radius and collision radius cannot be the same number

D-10 (GDD line 694): parts **2 levels apart do collide**, by sphere approximation.
The shortest segment between such a pair is a joint: `physics_joint_length_wu = 0.30`.

For a chain `A — joint B — C`, A and C sit roughly one joint length apart and will
touch when

```
r_A + r_C  >=  L_joint − contact_slop − bend margin
           >=  0.30 − 0.02 − 0.06 = 0.22
```

My first proposal had `head 0.14 + motor 0.11 = 0.25 > 0.22`. That is **permanent
overlap on a joint that is bent**, which is precisely the “jointed toy looks broken”
jitter D-10 exists to prevent. It would have shipped as the one bug that makes the
game read as amateur.

**Fix:** collision radius is the *physics* number; art may draw up to ~1.35× larger.
This is standard practice (art offset) and keeps the cute silhouette while the
solver sees a smaller, jitter-free sphere.

---

## 3. Derivation basis

`1 WU = 1 m` (GDD 569). Portrait canvas 1080 × 2340 (GDD 99). Camera width 7.2 WU.

```
px per WU (width) = 1080 / 7.2 = 150
```

Legibility targets at 150 px/WU:

| Element | Target on screen | WU |
|---|---|---|
| minimum part diameter | ≥ 15 px | ≥ 0.10 |
| comfortable limb diameter | 18–22 px | 0.12–0.147 |
| head diameter (two eyes readable) | ≥ 36 px | ≥ 0.24 |

Limb aspect ratio across the 8 shipped lengths (0.40–1.50) with 0.13 diameter:
3.1:1 → 11.5:1. Below 3:1 reads as a blob and loses “limb”; above ~12:1 reads as a
stick insect and loses “cute toy”. The shipped set lands inside that band — long
limbs are deliberately *spindly*, which is the QWOP-style comedy, but still legible.

---

## 4. Final numbers (owner-supplied, provisional until feel gates pass)

### 4a. Collision radius (physics) and visual radius (art)

| Kind | `*_collision_radius_wu` | px Ø | visual Ø (art) | px Ø |
|---|---|---|---|---|
| `LIMB` | **0.065** | 19.5 | 0.065 (no offset — a bone is a bone) | 19.5 |
| `JOINT_PASSIVE` | **0.085** | 25.5 | 0.105 | 31.5 |
| `JOINT_MOTOR` | **0.095** | 28.5 | 0.120 | 36.0 |
| `FOOT_GRIP` | **0.050** | 15.0 | 0.065 | 19.5 |
| `HEAD` | **0.100** | 30.0 | 0.135 | 40.5 |

D-10 safety check (`< 0.22` required): head+motor 0.195 ✓, head+passive 0.185 ✓,
head+limb 0.165 ✓, motor+motor 0.190 ✓.

### 4b. Head (root)

| Field | Value | Basis |
|---|---|---|
| `physics_head_mass_per_wu` | **2.2** | mass 0.77 at length 0.35 → 50 % of The Slug, 14 % of an 8-part creature: heavy enough to faceplant on purpose (GDD 141), light enough that motors (torque 1800, k 2400) can lift it |
| `physics_head_length_wu` | **0.35** | slightly longer than a joint (0.30); 8-part total stays inside GDD's 1.6–2.4 WU tall |
| angular limit | **none** | head is the root (GDD 531) — no parent hinge exists; do not invent one |
| collides | **yes**, terrain + parts ≥ 2 levels deeper | faceplant is the core comedy beat; D-10 governs the rest |
| eye lag / look-at | cosmetic only, 1.0 s lerp (GDD 788) | must not touch physics (INV-10) |

### 4c. Foot grip

| Field | Value | Basis |
|---|---|---|
| `physics_grip_normal_force_ratio` | **0.40** | dimensionless share of creature weight; band 0.25–0.55, tune only with gait evidence |
| `physics_grip_normal_force_floor` | **5.0** | absolute minimum so a near-massless prototype cannot grip on numerical noise |
| `physics_foot_grip_bias` | **1.4** (existing) | unchanged |
| `physics_static_slip_wu_s` | **0.15** (existing) | unchanged |

Resulting thresholds: The Slug 17.4, an 8-part creature 63.1 — the *ratio* is
constant, which is the whole point (D-C).

---

## 5. Feel assertions — the numbers are wrong if these fail

These turn “viral vs generic” into pass/fail, and belong in the M1 harness next to
AC-201/202/204.

- **FA-1 Readability** — every collision diameter ≥ 15 px and head ≥ 30 px at
  150 px/WU. Fails → increase radii, do not shrink the UI.
- **FA-2 Silhouette** — every shipped limb length yields aspect ratio within
  3:1…12:1.
- **FA-3 No jitter** — for every 2-level-apart pair in all three presets,
  `r_A + r_C ≤ 0.22`; a 600-tick static scene produces zero sleep-breaking contacts.
- **FA-4 The Slug stands** — no input, settles and sleeps within 4 s (this is the
  precondition for AC-201), and a single L-hold lurches it ≈ one body length
  (GDD 140).
- **FA-5 Grip band** — a foot loaded < 40 % of weight slips; ≥ 40 % grips; a
  two-foot stance grips; airborne grips never.
- **FA-6 Near-miss** — 10 runs of the identical scripted input on the tutorial
  chunk: **6–8 successes**. 10/10 = too easy = copycat feel; ≤ 4/10 = frustrating.
- **FA-7 Mascot** — the head is the largest silhouette element in every preset.

FA-6 is the single number that separates “viral” from “Play-Store filler”; treat a
failure there as a tuning blocker, not a polish item.

---

## 6. Spec conflict found while deriving (needs owner decision)

GDD line 569: camera shows **7.2 WU of width**.
GDD line 797: a chunk is one screen-height, **7.2 WU wide × 8.0 WU tall**.

But the canvas is **1080 × 2340** (aspect 0.462). Width-based scale gives
`1080 / 7.2 = 150 px/WU`; height-based gives `2340 / 8.0 = 292.5 px/WU`. Both
cannot hold.

Consequence: on-screen part sizes differ by ~2× depending on which line is
normative — a direct readability problem for FA-1.

Mitigation: all values above are **robust to both readings** (at 292.5 px/WU the
limb is 38 px Ø and the head 79 px Ø — still valid, just chunkier). But the owner
should resolve which line is correct before any camera or chunk work in M2. Logged
as **M1-B04**, not invented here.

---

## 7. Paste-ready message to the coding agent

```text
Owner decision: M1-B01 / M1-B04. Contact geometry is supplied, derived from the
viral-feel thesis rather than copied defaults. Record as DECISIONS.md M1-D04.

Read .review/M1_B01_CONTACT_GEOMETRY_DERIVATION.md on the reviewer branch
(arena/5b72e4ab-clamber) for the full derivation, and implement exactly these:

Collision radius (physics sphere/capsule radius, WU):
  limb    0.065
  passive 0.085
  motor   0.095
  foot    0.050
  head    0.100

Visual radius (art only, may exceed collision; never fed to the solver):
  limb    0.065
  passive 0.105
  motor   0.120
  foot    0.065
  head    0.135

Head (root):
  mass per WU 2.2, length 0.35  -> mass 0.77
  angular limit: NONE (root has no parent hinge; do not invent one)
  collides: terrain yes, parts at >= 2 hierarchy levels per D-10; eye look-at is
  cosmetic only and must not touch physics (INV-10)

Foot grip (replace any absolute threshold idea):
  physics_grip_normal_force_ratio = 0.40   (fraction of the creature's own weight)
  physics_grip_normal_force_floor = 5.0    (absolute minimum, anti-numerical-noise)
  grip test: normal_force_last_tick >= max(floor, ratio * sum(m_i) * abs(g))
  physics_foot_grip_bias 1.4 and physics_static_slip_wu_s 0.15 already exist - do
  not change them.

Why the ratio, not a force: The Slug is head+motor+foot (mass 1.55, weight 43.4) on
one foot, so an absolute threshold near 40 would mean it can never grip and the
tutorial breaks; the same absolute value would be free stickiness on an 8-part
creature (weight 158). A ratio makes every player-made creature feel the same,
which is the share loop.

Hard constraints to enforce with real tests:
1. For every pair 2 levels apart: r_A + r_C <= physics_joint_length_wu - contact
   slop - 0.06. Worst pairs: head+motor 0.195, head+passive 0.185, motor+motor
   0.190, all under the 0.22 limit. Add a test over all three presets that fails
   if any pair reaches the limit. This is the D-10 jitter guard.
2. Collision radius must exceed physics_contact_slop_wu (0.02) for every kind.
3. Visual radius is never read by core physics code: assert core does not reference
   any *_visual_radius_* constant.

Feel assertions to add to the M1 harness alongside AC-201/202/204:
  FA-1 every collision diameter >= 15 px and head >= 30 px at 150 px/WU
  FA-2 every shipped limb length gives aspect ratio within 3:1..12:1
  FA-3 a 600-tick static scene for each preset produces zero sleep-breaking contacts
  FA-4 The Slug with no input settles and sleeps within 4 s, and one L-hold lurches
       it approximately one body length
  FA-5 a foot loaded < 40% of creature weight slips; >= 40% grips; two-foot stance
       grips; airborne never grips
  FA-6 ten runs of the identical scripted input on the tutorial chunk yield 6-8
       successes. 10/10 means too easy; <=4/10 means frustrating. Report the actual
       count.
  FA-7 the head is the largest silhouette element in every preset

Rules:
- All new values go through core/tuning.gd + core/tuning.tres + docs/TUNING.md with
  source "owner M1-D04". No literals in core; the existing static checks must pass.
- These are provisional design inputs, not measured evidence. If a value must
  change to pass FA-1..FA-7 or AC-201/202/204, STOP and ask me with the measured
  numbers; do not tune silently, and never widen an assertion to make it pass.
- Do not change GDD §3.2 values (masses, lengths, friction, stiffness, torque).
- M1-B04: flag only. GDD line 569 says the camera shows 7.2 WU of width (=150
  px/WU) while line 797 says a chunk is 7.2 WU wide x 8.0 WU tall on a 1080x2340
  canvas (=292.5 px/WU). Do not pick one and do not start camera work; record the
  conflict in DECISIONS.md and continue using the width-based 150 px/WU only for
  the FA-1 readability check.

After this lands: creature bodies + feet + contact response, then AC-201, AC-202,
AC-204, three presets with 10 s captures. A9 replay/baseline/bit-flip and tick cost
stay NOT RUN until they actually run. No M2, no camera, no screens.
```
