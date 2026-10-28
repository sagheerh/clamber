# CLAMBER — GAME DESIGN DOCUMENT
### The authoritative specification for implementation

| Field | Value |
|---|---|
| **Document** | CLAMBER — Game Design Document (GDD), single source of truth |
| **Version** | 1.0 |
| **Date** | 28 October 2026 |
| **Status** | Approved for prototype implementation (P0); P1/P2 sections are specification-complete but not yet scheduled |
| **Target platform** | Android (portrait, phones first), offline-first |
| **Engine** | Godot 4.7.x (stable line), GDScript + custom fixed-step physics |
| **Supersedes** | The CLAMBER concept report (used here as the gameplay-identity source) |

---

## 0. HOW TO READ THIS DOCUMENT

### 0.1 Source-of-truth rules

Two inputs define CLAMBER and neither may be overridden by this document:

1. **The CLAMBER concept report** is the source of truth for *gameplay identity*: build a ridiculous physics creature, drive it yourself with two thumbs, climb a procedurally generated tower, share it as a code.
2. **The supplied UI/UX mockup (`CLAMBER_UI.jpeg`)** is the source of truth for *visual direction and screen layout*. This GDD **documents the mockup; it does not redesign it.** Where the mockup is silent or ambiguous, this document makes an explicit assumption, labels it `A-xx`, and specifies the behaviour without moving a single control.

### 0.2 Scope tags

Every feature carries a tag. This is how the reader separates "the game we intend" from "the game we build first".

| Tag | Meaning | Phase |
|---|---|---|
| **[CORE]** | Required for the P0 playable prototype (validates whether the game is fun at all) | P0 |
| **[V1]** | Required for the shippable MVP / soft launch | P1 |
| **[POST]** | Documented, specified, deliberately deferred | P2+ |
| **[CUT]** | Considered and explicitly excluded from the design | — |

A screen or feature appearing in the mockup is **not** automatically `[V1]`. Section 12 maps every visible screen to a phase.

### 0.3 Assumption and decision IDs

- `A-xx` — an assumption made because the concept or mockup was silent/ambiguous. Each has a validation method.
- `D-xx` — a design decision made by this document that a future agent must not silently change.
- `AC-xxx` — a measurable acceptance criterion.
- `T-xxx` — a test scenario.
- `R-xx` — a risk.
- All numeric constants are **initial tuning targets**, not proven values. They live in one tuning resource (Section 10.9) and are expected to change during playtesting without invalidating the specification.

### 0.4 Quality bar for a future coding agent

If a behaviour is specified here, implement it as specified. If a behaviour is *not* specified, prefer the simplest implementation that satisfies the nearest acceptance criterion, then record the gap. Do not invent economy, physics-feel, or monetisation values; every such value in this document was chosen deliberately and is listed as tunable in one place.

---

## 1. GAME OVERVIEW

### 1.1 One sentence

**CLAMBER is a portrait-mode physics game where you snap together a ridiculous creature from a handful of limbs and motors, then drive it up today's procedurally generated tower with two thumbs — hold left, hold right — and share it as a code anyone can try to beat.**

### 1.2 Elevator paragraph

In most build-and-test games you build a machine and watch it run. In CLAMBER you are the nervous system. Every motor on your creature belongs to channel **L** or channel **R**; holding your left thumb contracts every L motor, holding your right contracts every R. That is the entire control scheme. Wire your two legs to opposite channels and you have a walker. Wire both to L and you have a hopping ball. Add a tail to R and you have something that gallops badly and looks hilarious doing it. Then you climb a tower that is the same for everyone today, and the thing you built becomes a 20-something-character code your friend can paste in and fail with.

### 1.3 Design pillars

These five pillars are the tie-breakers for every future design argument, in priority order.

| # | Pillar | What it means in practice | What violates it |
|---|---|---|---|
| **P1** | **You build the weird thing** | Every climb is the player's own creation. The default state of the game is "someone else's creature is not good enough". | Shipping a single fixed vehicle; selling parts that make the player's build irrelevant |
| **P2** | **Your thumbs are the muscles** | Control is 2 channels × timing. Expressiveness comes from *wiring* and *rhythm*, never from extra buttons. | Adding a jump button, a brake, a boost, gesture combos |
| **P3** | **Failure is funny and cheap** | A fall costs seconds, never progress. Restart is instant, silent, and free. The best clips are disasters. | Checkpoint loss, energy systems, retry ads, "you lost your creature" |
| **P4** | **Two minutes, one thumb per side** | A run is 30–120 s. A build-tweak-run cycle is 2–4 min. The game is playable one-handed-adjacent, standing up, in a queue. | Long unskippable intros, forced tutorials, 5-minute sessions |
| **P5** | **Everything is shareable as a code** | The creature, the run, the challenge, and the brag all serialize to text. No accounts, no servers required to participate. | Server-gated features for basic play; global leaderboards required for comparison |

### 1.4 Anti-pillars (explicit non-goals)

- **No pay-to-win.** No purchasable part, upgrade, motor strength, or extra part slot. Ever. The economy is cosmetic + convenience (`D-01`).
- **No punishment for absence.** No streaks, no decay, no "you missed yesterday's tower". Missing a day is invisible.
- **No permanent failure.** No run is ever unwinnable-by-design; the player can always restart from a checkpoint or from zero at no cost.
- **No accounts at MVP.** Identity is a local creature library plus codes.
- **No global leaderboard at MVP.** Comparison is local, asynchronous, and invite-based (Section 8.6).
- **No "watch it run" passivity.** The player drives. An auto-drive exists only as an accessibility option (`A-11`), clearly labelled, excluded from medal eligibility.

### 1.5 Target audience

| Segment | Description | Why they stay |
|---|---|---|
| **Primary — "Tinkerers"** 13–34, play Hill Climb, Poly Bridge, Besiege, Kerbal, Lego, Suika; consume physics/"AI learns to walk" short-form video | They enjoy the *combinatorial* part: a new gait is a discovery | Creature journal, gait badges, mutation/Lineage `[POST]` |
| **Secondary — "Daredevils"** 13–30, play Getting Over It, Only Up, Chained Together, Flappy-likes | They enjoy the *execution* part: the run, the record, the clutch | Daily tower, personal ghosts, medals |
| **Tertiary — "Viewers"** anyone arriving from a clip | They want to try *that exact creature* in under 20 s | Code import, curated starter creatures, preset-first tutorial |

**Explicitly not targeted:** players seeking narrative, PvP, or meta-progression grind; children under 13 (COPPA/GDPR-K policy simplicity — see 11.7).

### 1.6 Platform and session shape

| Item | Spec |
|---|---|
| Platform | Android first (phones). iOS `[POST]` |
| Orientation | Portrait locked (9:19.5 reference canvas 1080 × 2340) |
| Input | Two simultaneous touch zones; no keyboard/tilt requirements |
| Session | Typical 3–6 min; run 30–120 s; build 30–90 s |
| Network | Fully playable offline. Network only for ads, IAP, and optional crash/analytics |
| Install size target | ≤ 70 MB AAB download |
| Device floor | Android 8.0 (API 26) / arm64 / 2 GB RAM / 60 fps on a 2019 mid-range SoC |

### 1.7 The core loop

**Micro (seconds):** see obstacle → decide which thumb → hold → release → watch what the physics does → react.

**Meso (2–4 min):**
```
        ┌──────────────────────────────────────────────┐
        │  1. BUILD / TWEAK (30–90 s)                  │
        │     tap part → snap → set L/R strength       │
        └───────────────┬──────────────────────────────┘
                        ▼
        ┌──────────────────────────────────────────────┐
        │  2. CLIMB (30–120 s)                         │
        │     two thumbs, checkpoint falls, flag       │
        └───────────────┬──────────────────────────────┘
                        ▼
        ┌──────────────────────────────────────────────┐
        │  3. RESULT (time / falls / score / medal)    │
        └───────────────┬──────────────────────────────┘
                ┌───────┴────────┐
                ▼                ▼
        "one more try"     "share / save / next tower"
                │                │
                └───────► back to 1 ◄──────┘
```

**Macro (days):** daily tower (same seed for everyone) + campaign unlocks (new part families) + cosmetic progression + code exchange with friends.

### 1.8 The first 60 seconds (first-run experience, `[CORE]`)

| Time | Screen | What happens |
|---|---|---|
| 0:00–0:02 | S00 splash → S03 Climb | App opens **directly into a climb**. No menu, no logo hold. A preset creature ("The Slug", 3 parts, one motor on L) stands at the base of a short tutorial tower. |
| 0:02–0:06 | S03 | Two translucent thumb pads fade in. The left pad pulses with a downward chevron and the word **HOLD**. No text tutorial, no modal. |
| 0:06–0:18 | S03 | Player holds left → the motor contracts → the creature lurches forward one body length. Release → it settles. A second pulse on the right pad. Alternating produces a hobbling walk. |
| 0:18–0:26 | S03 | The creature reaches a 0.6 WU ledge and faceplants. **Auto-retry after 1.0 s** (no dialog). The tip "Falls return you to the last flag" appears once, in-world, as a small toast. |
| 0:26–0:45 | S03 → S04 | Player clears the ledge and reaches the first flag. Victory screen: time, falls, score, creature card, Share, Next Tower. |
| 0:45–0:58 | S04 → S02 | A single contextual prompt appears on the victory screen: **"Give it a third leg?"** Tapping opens Build (S02) with the head selected and a highlighted free socket. |
| 0:58–1:00 | S02 | One tap places a limb. The player has now driven, failed, retried, triumphed, and modified — all inside 60 seconds — without reading a paragraph of text. |

**Rule:** the first-run must never show a modal dialog, a permissions prompt, a rating prompt, or an ad before the player has reached their first flag.

---

## 2. UI/UX AUDIT — THE EXISTING MOCKUP

### 2.1 What the mockup establishes (and what this document will not change)

The mockup defines ten visual surfaces sharing one visual language. Everything below is **observed**, not proposed.

**Visual language (locked):**

| Token | Value (sampled from the mockup) | Usage |
|---|---|---|
| `--sky` | `#46B0E4` (gradient to `#C8EBFF`) | Menu and gameplay sky |
| `--navy-900` | `#00192F` | Deepest background, sheet backdrops |
| `--navy-800` | `#002643` | Primary panel / card fill (home panel, victory body) |
| `--navy-700` | `#0A3963`-ish raised row | Secondary rows, list containers |
| `--ink` | `#FFFFFF` on navy; `#0B2A45` on white | Text |
| `--accent-yellow` | `#FFD04E` | Primary CTA ("Play", "Save", "Share"), active tab, selected part family |
| `--accent-blue` | `#2A98D5` | Left motor channel; slider fill; secondary info |
| `--accent-orange` | `#EF7438` | Right motor channel; danger-adjacent accents |
| `--surface-white` | `#F8F8F6` / `#FFFFFF` | Build canvas, creature list rows, victory stat card, creature card |
| `--gold-coin` | `#F2B33D` | Currency chip icon |
| Font | Rounded geometric sans, heavy weight for titles, regular for body; all caps only for the logo | Headings, buttons, labels |
| Shape language | 24–32 px corner radius, soft outer shadow `0 8px 24px rgba(0,0,0,.25)` | All cards and buttons |
| Icon language | Single-weight rounded line icons in circles | Rail tabs, stat icons, settings chevrons |
| Creature rendering | Flat vector limbs, thick outline, googly eyes, per-part saturated colour, pastel joint caps | Everywhere a creature appears |

**Structural conventions (locked):**
- Every screen uses the same top bar: back chevron left, centred title, one right-side affordance (help `?`, gear, or currency chip).
- Primary actions are full-width yellow pills; secondary actions are full-width navy-800 pills with a thin light border.
- The currency chip (`🪙 120 ⊕`) is present on every screen where spending is possible.
- Portrait, edge-to-edge art, no bottom OS bars visible in-content (safe-area padding required).

### 2.2 Screen inventory

| ID | Screen (mockup title) | Phase | Purpose |
|---|---|---|---|
| **S00** | Splash / Logo | `[V1]` | Wordmark, tagline, creature art; doubles as icon/key-art direction |
| **S01** | Home | `[V1]` (`[CORE]` reduced) | Play entry, today's tower, Build/Creatures/Shop tiles, currency, settings |
| **S02** | Build Your Creature | `[CORE]` (`[V1]` full) | Assemble creature; part families; L/R motor strength; Reset / Save |
| **S03** | Climb (gameplay HUD) | `[CORE]` | The run: day chip, timer, pause, two thumb pads |
| **S04** | You Reached the Flag! | `[CORE]` | Result: time, falls, score, creature card + code + Copy, Share, Next Tower |
| **S05** | My Creatures | `[V1]` | Library: My Creations / Community / Favorites; rows with code + best time |
| **S06** | Creature (detail) | `[V1]` | One creature: preview, code, parts, best time, falls, Share, Edit |
| **S07** | Daily Tower | `[V1]` | Today's seeded tower, terrain label, carousel of days, Play |
| **S08** | Shop | `[V1]` | Cosmetics grid; Workshop tab (locked) |
| **S09** | Settings | `[V1]` | Sound/music, vibration, tips, offline mode, legal, version |

**Screens required by this document but absent from the mockup** (specified in Section 9, styled with the same tokens, no redesign of existing screens):

| ID | Screen | Phase | Why it is unavoidable |
|---|---|---|---|
| S10 | Pause overlay | `[CORE]` | The mockup shows a pause glyph; interrupting a physics run must not lose state |
| S11 | Fall / recovery overlay | `[CORE]` | Falls are the signature failure; needs a defined visual |
| S12 | Import Code sheet | `[V1]` | Codes are the sharing artifact; entry needs a home |
| S13 | Campaign map | `[POST]` | Part-family unlocks need a progression surface |
| S14 | Creature Card export sheet | `[V1]` | The shareable unit; needs a preview before system share |
| S15 | Rewarded-ad prompt card | `[POST]` | Monetisation surface (P2), not prototype |
| S16 | Workshop purchase sheet | `[POST]` | The locked tab in S08 needs a destination |

### 2.3 Screen-by-screen specification

Each entry: **observed layout → behavioural specification → states → deviations/assumptions.** Pixel positions are given as proportions of a 1080 × 2340 canvas, so they survive device variation.

---

#### S00 — Splash / Logo

**Observed.** Sky-blue background with soft clouds; the wordmark **CLAMBER** in heavy white rounded caps with a dark outline and drop shadow; a stylised mountain with a red flag rising out of the "A"; tagline underneath: *"Build it. Drive it. Climb it."*; a large 4-limbed creature standing on a rock ledge at bottom-right, mid-stride, eyes looking up-left.

**Behaviour.**
1. Cold start shows this art for **no longer than 900 ms** while the game loads; hard cap 1.5 s; if loading exceeds the cap, show a non-blocking spinner under the tagline.
2. The wordmark mark (mountain + flag inside the A) is the app icon motif `[V1]`.
3. Art is a single full-bleed image or a 3-layer parallax (sky / mountain / creature) that reacts ±6 px to device tilt `[POST]` if cheap; otherwise static.
4. The tagline is **locked copy**: *Build it. Drive it. Climb it.* It is used verbatim in the store listing and in the first-run.

**States.** Warm start → no splash (skip to S01 in ≤ 200 ms). Interrupted load → frozen frame, resume on return.

**Assumptions.** `A-01`: the splash is not a tappable "tap to start" gate; the game boots into content (see 1.8). A tap-to-start gate would contradict pillar P4 and is rejected.

---

#### S01 — Home

**Observed layout (top → bottom).**
- Top-left: circular **gear** button (→ S09).
- Top-right: currency chip — coin icon + `120` + green `⊕` (→ S08).
- Centre: the CLAMBER wordmark (smaller than splash) over gameplay sky/mountain art.
- Below: a **Today's Tower** card — left thumbnail of a tower on a light panel, right text block: "Today's Tower" / "Day 14 👑" (crown for the current day).
- A full-width yellow **▶ Play** pill.
- A row of three equal navy tiles with icon + label: **Build** (wrench), **Creatures** (stylised creature head), **Shop** (cart).
- Bottom: standard Android gesture bar area.

**Behaviour.**

| Control | Action | Destination | Notes |
|---|---|---|---|
| Gear | Tap | S09 Settings | Slide-up, not a full-screen replace |
| Coin chip `⊕` | Tap | S08 Shop → Cosmetics | The `⊕` means "get more coins", which in this economy means play or the rewarded ad `[POST]`. Opens the shop with the coin-acquisition sheet `A-02` |
| Today's Tower card | Tap | S07 Daily Tower | Card shows the *current* daily seed thumbnail |
| **Play** | Tap | S03 Climb, resuming the last active creature on today's tower | If no creature is active, uses the last-saved creature; if none exists, uses "The Slug" preset |
| Build | Tap | S02 with the last edited creature | |
| Creatures | Tap | S05 My Creatures | |
| Shop | Tap | S08 Shop | |

**Rules.**
- **Play is the default action from a cold start after the first run** (`D-02`): returning players land on S01 and can reach a run in one tap. First-ever launch bypasses S01 entirely (1.8).
- The Home **Play** button always resumes *today's* tower with the *active* creature. Changing either is done from S07 or S05.
- The Today's Tower card shows a small crown when the day's tower has been cleared (`A-03`: crown = cleared indicator; the mockup shows a crown with no other signal. If playtests misread it, it becomes a check-mark badge — no layout change).

**States.**
- *Fresh install:* creature = "The Slug" preset; coins = 0; no crown.
- *Cleared today:* crown on card, Play label unchanged.
- *Offline:* identical; only the coin `⊕` and any ad surfaces are inert.
- *No network and Offline Mode on (S09):* an unobtrusive "offline" glyph appears in the top bar.
- *Tower data missing/corrupt:* card shows a neutral placeholder, Play falls back to the last available tower, and an error toast fires (11.5).

**Assumptions.** `A-02`: `⊕` opens the coin-acquisition sheet rather than a second currency. `A-03`: crown = cleared. The three tiles are one-tap destinations, not tabs; they have no selected state.

---

#### S02 — Build Your Creature

**Observed layout.**
- Top bar: back chevron (←), title **Build Your Creature**, right `?` help.
- Left **vertical rail** of five icon+label tabs: **Limbs** (bold yellow when active), **Joints**, **Motors**, **Feet**, **Special**.
- Main area: a light `#F2F2F0` canvas card with rounded corners containing the creature, rendered large, centred, casting a soft shadow.
- Top-right of the canvas: **Parts 3/10** (a budget counter; the current number is rendered inside a small white pill).
- Directly under the canvas: a horizontal strip of **four quick-add tiles**, each containing a small triangular node-graph glyph in a distinct colour — blue, green, orange, purple — inside a rounded white tile with a thin coloured border. (Observed four; count is presumably scrollable.)
- Below: two labelled sliders — **Left Motor Strength 70%** (blue fill, round thumb) and **Right Motor Strength 70%**.
- Bottom row: **⟲ Reset** (navy pill) and **✓ Save** (yellow pill, wider).

**Behaviour — the build model.**

1. **Selection.** Tapping any part on the creature selects it (highlight ring + subtle scale). Tapping empty canvas deselects. Selected part determines which rail tab is contextually highlighted, but any rail tab can be opened at any time.
2. **Rail tabs are part families, not modes.** Opening **Limbs** shows the limb catalogue in a horizontal strip occupying the same strip position as the four quick-add tiles. The four coloured tiles in the mockup are read as **quick-add limb archetypes** (`A-04`, `D-03`): *Straight length*, *Angled (elbow) pair*, *Symmetric leg pair*, *Branch (three-way)*. Each tile's colour maps to the limb tint it will produce (blue / green / orange / purple), previewing the colour convention used everywhere.
3. **Placement.** With a family open, tapping a part selects it for placement; valid sockets on the creature pulse with a white ring; tapping a socket places the part and increments the Parts counter. Invalid placement is prevented (not errored).
4. **Snapping.** Length snaps to 8 buckets; angle snaps to 5°; a placement may be dragged along a socket arc and released to commit. The snap is *forgiving*: the part previews at the nearest legal snap at all times.
5. **Motor strength sliders are global channel gains** (`D-04`). The two sliders in the mockup are the only always-visible tuning controls, and they control **all** motors on channel L and channel R respectively, 0–100 % in 1 % steps, default 70 %. Per-joint tuning is *not* in the mockup and therefore is not in V1; if introduced later `[POST]`, it appears as an identical slider inside the Joints/Motors detail sheet, never as a new global control. `A-05` records this reconciliation of mockup vs. concept ("motors have one tunable parameter each").
6. **Reset** restores the creature to its last-saved state (destructive, requires confirm if ≥ 3 parts have changed). It never deletes the saved creature.
7. **Save** commits to the library, generates/refreshes the creature code, and returns to the previous screen. Save is disabled (dimmed, still tappable with an explanation) when the creature is invalid — see §4.6.
8. **Parts budget** is `Parts current/max`. `max` is a per-creature constant raised by campaign unlocks `[POST]`; V1 default 10 (`A-06` — the mockup shows `/10`; The Hopper is shown with `Parts 8`, consistent).
9. **Help `?`** opens a one-screen visual legend (channel colours, part families, budget) as a bottom sheet; it never opens a tutorial flow.

**States.**

| State | Presentation |
|---|---|
| Empty (new creature) | Head only, centred, plus a highlighted first socket; Parts `1/10` |
| Budget exhausted | Quick-add tiles dim; socket rings turn grey; tapping shows toast "All 10 parts used — remove one first" |
| Invalid (no motor) | Save is amber-outlined; banner above the buttons: "Needs at least one motor to move" |
| Unsaved changes | Back triggers a confirm sheet: "Save changes? / Save · Discard · Cancel" |
| Server-free / offline | No visual difference |
| Undo | Rail-bottom undo arrow `[V1]` (not in mockup; add as a small glyph in the top bar next to `?` — `D-05`, minimal footprint) |

**Assumptions.** `A-04` four quick-add tiles = archetypes; `A-05` global channel gains; `A-06` budget 10. `D-03`/`D-04`/`D-05` lock the interpretations. If playtesting shows players read the four tiles as *colours only* (cosmetic), the tiles are relabelled but not restructured.

---

#### S03 — Climb (gameplay HUD)

**Observed layout.**
- Top-left: day chip — dark rounded pill, small flag glyph + **Day 14**.
- Top-centre-right: timer **00:42** with a small clock glyph.
- Top-right: circular **pause** button.
- Full-bleed climbing scene: stacked blocky rock platforms with grass caps, sky gradient, a flag on the summit ahead.
- The player's creature is small in frame, mid-climb, limbs glowing at the driven joints (the mockup shows several parts lit, which the GDD formalises as the **motor-glow convention**).
- Bottom-left: large circular pad, dark navy with a **blue** inner ring and a blue **up-chevron/hand** glyph, label **Hold Left**.
- Bottom-right: matching pad with an **orange** inner ring, orange glyph, label **Hold Right**.

**Behaviour.**

| Element | Rule |
|---|---|
| **Timer** | Starts on the **first input** after spawn (not on scene load). Format `MM:SS`, no centiseconds in HUD (centiseconds shown on S04 `[V1]`). Continues during falls. Stops at flag. |
| **Day chip** | Shows the seed's day number for a daily tower; shows the tower name for campaign towers (`[POST]`). Tapping does nothing (it is a label, not a button) |
| **Pause** | Opens S10 over a frozen simulation. Pause is *never* mid-physics-ambiguity: the sim freezes at the last completed fixed step |
| **Thumb pads** | Visual affordance + touch target. The **entire lower-left 45 % × 24 %** of the screen (above the pad, below the top bar, left of centre) drives channel **L**; the mirrored region drives **R**. The pads themselves are the visual representation of those regions, not the only hit area. Multi-touch required; 2+ fingers supported |
| **Motor glow** | While a channel is held, every motor on that channel glows in the channel colour with an intensity ∝ contraction rate. This is a **pillar-P2 readability rule**, not decoration: a viewer must be able to see the inputs |
| **Creature camera** | Camera follows the creature's centre of mass with a deadzone of 18 % of screen height; zooms out to 0.75× while airborne > 0.7 s; clamps to tower bounds; never reverses direction faster than 220 px/s |

**States.**
- *Pre-input:* timer `00:00` static, pads pulsing if the player has < 3 total runs lifetime.
- *Running:* as above.
- *Falling:* pads remain live, camera zooms out; S11 overlay is **not** shown for ordinary falls (only for out-of-world/lava) — see §5.7.
- *Paused:* S10.
- *Reached flag:* immediate transition, 0 ms input lock, S04 fades in over 260 ms.
- *Backgrounded:* automatic pause + save of the run state to memory (not disk) — see §11.6.

**Assumptions.** `A-07`: pad glyphs (hand/chevron) are stylistic; the semantic is *hold to contract*, and the GDD text uses "hold" everywhere. `A-08`: the number of glowing parts in the mockup is illustrative; glow follows channel membership exactly.

---

#### S04 — You Reached the Flag!

**Observed layout.**
- Top: celebratory confetti on a dark starry navy background; a flag on a small mound, centred.
- Title: **You Reached the Flag!**
- Stat card (white text on navy-800): rows with line icons — ⏱ **Time** `01:24`, 🚩 **Falls** `2`, ★ **Score** `3,460`.
- Creature card (white): creature thumbnail left; right side "**My Creature**", code line `CL-7Q2K-9BTA`, and a small navy **Copy** pill.
- Full-width yellow **Share** pill with a share glyph.
- Full-width navy **→ Next Tower** pill.

**Behaviour.**

1. Score, time, and falls are computed at the frame the creature's head enters the flag trigger (§7.3). The numbers shown are final and immutable for that run.
2. **Copy** copies the creature **transfer code** (not merely the displayed fingerprint — see §8.2) to the clipboard and toasts "Code copied". It does not open the system share sheet.
3. **Share** opens the OS share sheet with the canonical share text plus, if available, the exported creature card image (S14). `[V1]`
4. **Next Tower** advances: for a daily, to the next day's tower *only if it is unlocked by date* — otherwise it starts today's tower again (`A-09`: the mockup implies an endless sequence; in the daily model "next" = tomorrow, so the button relabels to **Play Again** when the next day is not yet available. This is a label change on an existing button, no layout change.)
5. The "Give it a third leg?" prompt from the first-run (1.8) is *only* shown on the first ever clear.
6. Confetti respects the reduce-motion setting and flashes no more than 3×/s (§11.4).
7. A medal badge appears next to the score when a threshold is met (§7.4) `[V1]`.

**States.**
- *New best:* "New Best!" ribbon replaces "My Creature" line `[V1]`.
- *Not a new best:* shows the run's numbers and the previous best in a small caption.
- *First clear:* adds the contextual "Give it a leg?" prompt.
- *Offline:* identical; Share uses text only if card export is unavailable.
- *Ad-eligible moment* `[POST]`: no interstitial may appear on S04 within 60 s of a Share/Copy action (see §8.9).

**Assumptions.** `A-09` as above; `A-10`: the score formula in §7.3 is reverse-engineered to *exactly* reproduce the mockup's `01:24 / 2 falls / 3,460` for Day 14, so the screenshot remains a valid reference.

---

#### S05 — My Creatures

**Observed layout.**
- Top bar: back, title **My Creatures**, right `⊕` in a circle (new creature).
- Segmented pill row: **My Creations** (yellow/active) · **Community** · **Favorites**.
- A scrollable list of white rounded rows. Each row: creature thumbnail left; name (bold) + star glyph; code line in mono (`CL-3D9F-7K2P`); then a star + best time (`02:16`); right: `⋯` overflow.
- One row ("Long Boy", `CL-ST6V-2N9M`, `02:37`) is rendered at reduced opacity with grey text and no star.
- Row order in the mockup is by best time ascending (02:16, 01:48, 02:37, 03:12) — i.e. **not** sorted; it is therefore *manually ordered or last-used ordered* (`A-12`).

**Behaviour.**

| Control | Action |
|---|---|
| Back | → S01 |
| `⊕` | Creates a new creature (prompt for name via inline edit, default "Untitled") → S02 |
| Segmented tabs | Filter the list. **My Creations** = local library; **Community** = curated + imported creatures (§8.5); **Favorites** = starred creatures |
| Row tap | → S06 Creature detail |
| `⋯` | Bottom sheet: **Edit** · **Duplicate** · **Rename** · **Share** · **Favorite/Unfavorite** · **Delete** (destructive, confirm) · **Export code** |
| Long-press row | Enters multi-select mode (`[V1]`, for bulk delete/export); subtle haptic |

**States.** Empty library (illustration + "Build your first creature" CTA) · Community empty (explains codes, offers S12) · Favorites empty · List loading (skeletons, max 300 ms) · Row with no completion (greyed, `—` instead of a time).

**Assumptions.** `A-11`: the greying of "Long Boy" reads as **"not yet cleared on the highlighted tower"** (no medal, no best time for that tower), with the time shown being that creature's best on *any* tower. This is the most useful and least destructive interpretation. `A-12`: the mockup's ordering is by **last used**, with Favorites pinned. The `★` beside the name and the `★` beside the time are **two different markers** — name-star = favorited; time-star = earned a medal `A-13`; the Favorites tab filters on the former. If this proves confusing in testing, the time-star becomes a medal glyph (a rosette), a one-asset change.

---

#### S06 — Creature (detail)

**Observed layout.**
- Top bar: back, title **Creature**.
- Large light-blue preview card containing a rendered creature, with a `★` in the top-right of the card.
- Name (**The Hopper**) bold; below it the code `CL-3D9F-7K2P` in mono grey.
- A 3-column stat strip on navy: **Parts 8** · **Best Time 02:16** · **Falls 2**.
- Yellow **Share** pill.
- Navy **✏ Edit** pill.

**Behaviour.**
- Preview is a live idle render (motors breathe; eyes track the gyro `[POST]`); tapping the preview plays a 3-second idle animation of the creature.
- Stats: Parts = current part count; Best Time = best completion on the currently selected tower; Falls = falls in that best run (matching S04's `Falls 2` — consistent with the mockup).
- **Share** = same behaviour as S04 Share.
- **Edit** = opens S02 with this creature loaded; edits create a *new* save revision, and the previous best time is retained under the creature's history.
- Card `★` = favorited toggle.
- Overflow-free: rename/duplicate/delete live in S05's `⋯`; on S06 they are available via long-press on the title `[V1]`.

**States.** Never-cleared creature → Best Time `—`, Falls `—`. Deleted creature → back to S05 with toast.

---

#### S07 — Daily Tower

**Observed layout.**
- Top bar: back, title **Daily Tower**, right `?`.
- Below the top bar: `👑` + a small crown/caret control on the left, centred **★ Day 14 ★**, a `>` caret on the right (day navigation).
- Subtitle: **Mixed Terrain**.
- Large tower preview card: an illustrated tower against mountains, with three pagination dots beneath (indicating multiple preview images, not multiple towers).
- Full-width yellow **▶ Play** pill.

**Behaviour.**
- The preview card is a **swipeable gallery** of three auto-generated previews of the same tower: (1) the base, (2) the hardest obstacle section, (3) the summit. Dots reflect the active page.
- Left/right carets navigate **days**, not towers. Only days ≤ today are selectable; the right caret is disabled at today (grey chevron). Selecting a past day shows that seed read-only, marked "Past tower" `A-14`.
- **Mixed Terrain** is a terrain-mix label derived from the generator's composition (§6.3): one of `Mixed`, `Rocky`, `Icy`, `Windswept`, `Ruin` `[POST for non-Mixed]`.
- **Play** starts S03 with the active creature.
- `?` explains: same tower for everyone today, resets at local midnight, no penalty for missing a day.

**States.** Today (default) · past day selected · tomorrow locked (carets disabled, no preview) · offline with cached buffer (all days ≤ today available) · offline with no buffer (error state: "Tower data unavailable — reconnect or play a practice tower", with practice towers being the last 3 cached dailies).

**Assumptions.** `A-14`: carets = day navigation. `A-15`: the three dots paginate previews.

---

#### S08 — Shop

**Observed layout.**
- Top bar: back, title **Shop**, right coin chip `120 ⊕`.
- Segmented tabs: **Cosmetics** (active, yellow) · **Workshop 🔒** (with a padlock glyph).
- 2 × 3 grid of cosmetic pack cards. Each card: creature rendered in the pack's palette, pack name below, and a price row (`🪙 200`) for unowned packs.
- Observed packs and prices: **Classic** (selected — yellow border, ✓ badge, no price), **Forest** 200, **Desert** 200, **Neon** 300, **Ice** 300, **Space** 300.

**Behaviour.**
- Cosmetics are **creature palettes/skins**: they recolour parts and joints, never change physics, mass, friction, or motor output (`D-01`).
- Tapping an unowned pack opens a confirm sheet: preview swatch, price, **Buy**, and a "not enough coins" state with a route to earn.
- Owning a pack: card shows no price and a `✓` when applied. Applying is global (applies to all creatures by default) with a per-creature override in S02 `[V1]`.
- The **Workshop** tab is locked. Tapping shows S16: a one-time purchase that removes ads and unlocks extra palettes/eyes and unlimited journal slots `[POST]`. The padlock is *not* removed in V1 — the tab remains present but locked, exactly as mockup (`A-16`). This is honest: the tab advertises future value without shipping empty.
- Coin balance in the top bar is live and identical to S01.

**States.** Owned / applied / affordable / unaffordable / purchasing (spinner, ≤ 3 s) / purchase failed (toast + retry) / network-down (prices cached, purchase disabled) / all-owned (grid shows owned set, a "more coming" footer).

**Assumptions.** `A-16` Workshop = the one-time unlock described by the concept. Prices in the mockup (200/300) are the shipped defaults; the coin economy in §7.6 is calibrated so that a 200-coin pack is ~1–2 days of normal play.

---

#### S09 — Settings

**Observed layout.**
- Top bar: back, title **Settings**.
- Group 1 (**Sound & Music**): two sliders — a music-note icon slider, and a speaker icon slider.
- Group 2 (toggles, all default ON, yellow pills): **Vibration**, **Show Tips**, **Offline Mode**.
- Group 3 (chevron rows): **Privacy Policy** ›, **Terms of Service** ›.
- Footer: `Version 1.0.0` in dim grey.

**Behaviour.**
- **Slider 1 (music-note icon)** = music bus volume, 0–100 %, default 70 %; at 0 the music bus is muted but the slider position is remembered. **Slider 2 (speaker icon)** = SFX + UI bus, default 80 %, same rule. Haptics follow the Vibration toggle, not the sliders.
- All three toggles write immediately, persist, and take effect without a restart.
- **Offline Mode** (default ON in the mockup) is read as `A-17`: when ON, the game makes **no network requests at all** — ads never load or show, content updates are skipped, and any cloud/leaderboard features are hidden. When OFF, ads and optional telemetry become eligible. Because CLAMBER is offline-first, the *default* shipped value is **ON**, matching the mockup, and the game is fully playable in that state.
- Privacy Policy / Terms open an in-app document viewer (bundled HTML/PDF), never an external browser, so they work offline `D-06`.
- Version string is generated from the build (`major.minor.build`), never hand-typed.
- Settings changes are logged locally only.

**States.** Sliders at 0 (icon shows a strike-through) · Offline Mode on (a persistent small glyph in the top-right corner of every screen) · documents unavailable (should never happen; falls back to a plain-text summary bundled with the build).

**Assumptions.** `A-17` as above; `A-18`: "Show Tips" governs in-world contextual tips (1.8) and Build hints, not legal text.

### 2.4 Navigation graph

```
                    ┌──────────────┐
   cold start ──►   │ S00 Splash   │
                    └──────┬───────┘
                           │ first ever launch?
              yes ┌────────┴────────┐ no
                  ▼                 ▼
          ┌───────────────┐   ┌───────────┐
          │ S03 Climb     │   │ S01 Home  │◄───────────┐
          │ (tutorial run)│   └──┬─┬─┬─┬──┘            │
          └───────┬───────┘      │ │ │ │               │
                  ▼              │ │ │ │               │
          ┌───────────────┐      │ │ │ │               │
          │ S04 Victory   │      │ │ │ └──► S08 Shop ──┤
          └──┬────────┬───┘      │ │ │        (locked workshop → S16 [POST])
             │        │          │ │ │
   "add a leg"│       │ Play     │ │ └──► S05 My Creatures ──► S06 Detail ──► S02
             ▼        ▼          │ │            └──► S12 Import [V1] ──► S06
          ┌───────────────┐      │ │
          │ S02 Build     │◄─────┘ └──► S07 Daily Tower ──► S03 ──► S04 ──► S14 Share
          └───────┬───────┘                 │
                  │ Save                    └──► (day carousel)
                  ▼
              S01 / S05

   S03 ──pause──► S10 Pause ──► resume | restart | build | quit(S01)
   S03 ──fall───► S11 (auto-dismiss, 1.0 s) ──► S03
   S09 Settings reachable only from S01 (gear) and S10 (gear)
```

**Navigation invariants:**
1. No screen is more than **2 taps** from a running climb (S01 → Play → S03).
2. Every screen has exactly one back affordance, top-left, with Android back behaving identically. Back from S01 exits to the OS launcher (with a confirmation only if a run is in progress in memory).
3. Modal sheets dismiss on backdrop tap, never trap the user.
4. Any screen opened from a run (S10 → S02) returns to the *paused run* on save, not to the home screen.

---

## 3. CORE MECHANICS

### 3.1 The creature model

A creature is a **tree of rigid segments** (a kinematic chain hierarchy, not an arbitrary graph).

```
Head (root, always present, carries eyes)
 └─ Segment
     ├─ Segment
     │   └─ Foot
     └─ Segment
         └─ Foot
```

Every non-root segment has exactly one parent socket and up to **two** child sockets (`A-19`: two children max, so a 10-part budget cannot produce an unreadable bush; a branch is allowed but a split-of-a-split is not).

**Part taxonomy** (matches the five rail tabs in S02):

| Family | Part kinds | Function | Acts under a channel? |
|---|---|---|---|
| **Limbs** | `LIMB` | Rigid bone. No actuation. Structural length and reach. | No |
| **Joints** | `JOINT_PASSIVE` | Compliant hinge with an angular limit range. Dampens and absorbs. | No |
| | `JOINT_MOTOR` | Actuated hinge; the only thing a thumb controls. | **Yes** (L or R) |
| **Motors** | *(presentation of `JOINT_MOTOR` with a visible hub + glow ring; the tab is where channel assignment and motor colour live)* | — | — |
| **Feet** | `FOOT_GRIP` (default) · `FOOT_SPIKE` `[POST]` · `FOOT_STICKY` `[POST]` | Terminal pad. Sets the contact material (friction, restitution) and is the only part that can anchor the creature. | No |
| **Special** | `SPRING` `[POST]` · `SUCTION` `[POST]` · `COUNTERWEIGHT` `[POST]` | One-shot or conditional behaviours that expand build space in P2. | `SPRING` yes (fires on channel release) |

**Rules that make the taxonomy teachable:**
- A creature must have at least **one `JOINT_MOTOR`** and at least **one `FOOT_*`** to be valid (§3.5).
- Motors are assigned to channel **L** or **R** at placement time. The head is neutral.
- Each part has a **colour index** (cosmetic) drawn from the active palette; the channel colour (blue L / orange R) is always overlaid as the motor glow, so channel is never communicated by the part colour alone (accessibility, §11.4).
- Mass is derived, never authored: `mass = baseMass(kind) × length`. This keeps the physics legible and prevents invisible stat tuning.

### 3.2 Part statistics (initial tuning targets)

| Kind | Mass (per WU) | Length options (WU) | Angular limit | Compliance | Notes |
|---|---|---|---|---|---|
| `LIMB` | 1.0 | 0.40 – 1.50 | n/a | rigid (0) | 8 discrete lengths |
| `JOINT_PASSIVE` | 0.8 | 0.30 | ±110° | soft (k = 900) | absorbs landing shock |
| `JOINT_MOTOR` | 1.6 | 0.30 | −140° … +40° from rest | stiff (k = 2400) | heavier: motors cost you |
| `FOOT_GRIP` | 1.2 | 0.25 | n/a | rigid | μ = 0.90, restitution 0.02 |
| `FOOT_SPIKE` | 1.2 | 0.25 | n/a | rigid | μ = 1.15, but sinks 0.03 WU — slower on rock |
| `FOOT_STICKY` | 1.3 | 0.25 | n/a | rigid | μ = 1.40, releases after 0.25 s of tension |

Units: 1 WU = 1 metre. A typical 8-part creature is 1.6–2.4 WU tall and 2–3 WU long. The camera shows 7.2 WU of width at zoom 1.0.

### 3.3 Build rules (S02)

| Rule | Value / behaviour |
|---|---|
| Part budget | 10 `[V1]` default; `[POST]` up to 14 via campaign (one slot per tier) |
| Socket rules | One parent, ≤ 2 children per segment; root is the head |
| Placement | Tap family → tap pulsing socket; optional drag along an arc before release |
| Length snap | 8 buckets: 0.40 / 0.55 / 0.70 / 0.85 / 1.00 / 1.15 / 1.30 / 1.50 WU |
| Angle snap | 5° increments; the 4 quick-add archetypes pre-set 0°, ±45°, ±90° |
| Channel assignment | Set on placement (default: opposite channel to the parent motor; ties → L). Changeable by tapping the motor and picking L/R |
| Colour | Inherits the pack palette; per-part override `[V1]` |
| Undo | 20-step stack `[V1]`; Reset is separate |
| Autosave | Every 20 s and on background, to a `draft` slot; never overwrites the saved creature |
| Budget exceeded | Prevented at placement; no negative states exist |

### 3.4 The control model — "Two-Thumb Nervous System"

**The complete input specification.**

```
Channel L  ←  any touch inside the bottom-left input region, OR the left pad
Channel R  ←  any touch inside the bottom-right input region, OR the right pad
```

- **Hold = contract.** While a channel is held, every motor assigned to it drives toward its *contracted* target angle.
- **Release = relax.** On release, motors return to their rest angle under spring force, with damped oscillation.
- **Nothing else.** No tap actions, no swipes, no gestures, no jump, no brake, no boost `D-07`.
- Both channels may be held simultaneously (this is often a valid technique — a "both-hands crunch" to pop the creature over a ledge).
- Input is sampled at the physics tick, not the frame; the sampled state is a 2-bit mask `(L, R)`. **This is the entire input record used for ghosts and replays** (see §8.7).

**Why it works as a design (P2).** The player's signal is 2 bits of state plus timing, yet the creature can have any number of motors. The expressiveness moves into *design* (which motor is on which channel, how long, how strong) and *rhythm* (when to fire). The same body driven with a different rhythm is a different machine; a different body driven with the same rhythm is a different challenge. This is the game's entire depth budget and it must not be diluted.

**Motor model (per motor, per tick):**

```
held   = (channel == L) ? inputL : inputR

θ_target = θ_rest − A_contract · s_channel          (held)
θ_target = θ_rest                                    (released)

τ = clamp(k_joint · (θ_target − θ) − c_joint · ω,
          −τ_max · s_channel,
          +τ_max · s_channel)

ω ← ω + (τ / I) · dt
θ ← θ + ω · dt
```

with initial values: `A_contract = 62°`, `k_joint = 2400`, `c_joint = 55`, `τ_max = 1800`, `I` from the segment masses. `s_channel` is the global slider from S02 (0.00–1.00, default 0.70).

**Design consequences that must survive tuning:**
- At `s = 0` the creature is immobile but still grabbable by physics; the game must not soft-lock (timeout → restart prompt after 12 s, §5.6).
- Higher `s` reaches further but overshoots and self-topples more; lower `s` is precise but slow. The slider is a genuine trade-off, not an upgrade.
- The spring return is what makes the creature look alive on release. It may not be removed for "snappier" feel; that would break the fiction and the readability rule.

### 3.5 Validation rules (blocking vs. warning)

| Check | Severity | Message |
|---|---|---|
| No motor | **Blocking** | "Needs at least one motor to move" |
| No foot | **Blocking** | "Needs a foot to push against the ground" |
| Zero-length / detached part | **Blocking** | "A part isn't connected" |
| All motors on one channel | Warning | "Both channels are empty on one side — it will only move one way" |
| Part count 0 or 1 | **Blocking** | "Add a leg" |
| Creature taller than 3.2 WU | Warning | "Tall creatures tip easily" |
| Motor strength 0 on a channel used by motors | Warning | "That channel is at 0%" |
| Creature mass > 18 | Warning (not blocking) | "Heavy — it will be slow" |

Warnings never prevent Save; they appear as an inline amber banner above the Reset/Save row and are suppressed for 7 days after two dismissals (`Show Tips` off also suppresses them, `A-18`).

### 3.6 Build → run handoff

1. Save in S02 writes the creature, regenerates its code, records `lastEdited`.
2. Save returns to the caller (S05, S06, or a paused S10).
3. **Play** from S01/S07: the creature is serialised into the run's deterministic input (see §4.7) and the tower seed is fixed. The run begins at checkpoint 0.
4. Editing mid-run (S10 → S02 → Save) restarts the run from checkpoint 0 with the new body and **keeps the elapsed time** (`D-08`: rebuilding mid-run costs you your time, never your progress).

---

## 4. PHYSICS SPECIFICATION

### 4.1 Why custom physics

The feel *is* the product. A general-purpose engine's 2D solver (Box2D-derived, as used by both Godot and Unity) is deterministic only within an identical binary and platform, is tuned for stacking boxes rather than compliant limbs, and hides its iteration order. CLAMBER needs: (a) a small, auditable solver, (b) identical behaviour across devices for code-sharing and ghosts, (c) joint compliance that can be author-tuned to "feels like a rubber toy". Decision `D-09`: **custom fixed-step position-based dynamics (PBD/XPBD)**, ~600–900 lines, no third-party physics dependency.

This is also the single highest technical risk in the project (R-01) and the reason P0 exists.

### 4.2 Simulation parameters

| Parameter | Value | Rationale |
|---|---|---|
| Timestep | Fixed `dt = 1/60 s` | Determinism, touch-sampling parity |
| Substepping | Accumulator, max 3 catch-up steps per frame, then drop | Prevents spiral-of-death after a hitch |
| Solver | XPBD, 6 position iterations, 2 velocity passes | Enough for ≤ 30 bodies |
| Gravity | `−28 WU/s²` (≈ 2.85 g) | Game-feel gravity; real g makes toys feel floaty |
| Linear damping | 0.02 | Kills endless drift |
| Angular damping | 0.8 | Prevents perpetual spin on release |
| Velocity clamp | 42 WU/s linear, 24 rad/s angular | Anti-tunnelling backstop |
| Penetration tolerance | 0.02 WU | Contact slop |
| Sleep threshold | `|v| < 0.05` for 0.6 s and grounded | Perf + stops micro-jitter on ledges |
| Solver order | Fixed part order (index order), stable sort | Determinism |
| RNG | `xoshiro128**` seeded per-run from the tower seed; never `randf()` | Determinism |

**Deterministic math discipline:** the hot path uses only `+ − × ÷` and comparisons on `float64` (GDScript floats are doubles). `sqrt` is permitted (IEEE-754 correctly rounded, identical on ARM64/x86-64). `sin/cos/pow/exp` are **forbidden in the solver**; angles are stored as unit vectors or precomputed tables. This is the cheapest path to cross-device determinism; §10.6 defines the validation gate and the fallback.

### 4.3 Bodies and constraints

- **Spheres (2D circles) with radius per part**, mass from §3.2, and a segment shape for collision against terrain (a capsule of radius `r` between the part's two endpoints).
- **Rigid link constraint:** distance between a part's endpoints is held exactly; this makes a limb a bone rather than a rubber band.
- **Hinge constraint with limits:** between parent and child; the angular limit is enforced as a position constraint plus a velocity block.
- **Motor constraint:** an angular target driven by the spring-damper in §3.4, applied *before* the limit constraint so limits always win.
- **Feet:** a small oriented capsule with the material's μ; feet are the only parts that can create a "grip" contact (higher friction, restitution 0.02).

### 4.4 Collision handling

| Layer | Contents | Collides with |
|---|---|---|
| 0 | Terrain (static) | 10, 11 |
| 10 | Creature parts | Terrain, creature parts, hazards |
| 11 | Creature feet | Terrain, hazards |
| 20 | Hazards (lava, spikes, kill volume) | 10, 11 |
| 21 | Triggers (flags, checkpoints, coins) | 10 only (no physical response) |

**Self-collision rule** (`D-10`): parts closer than **2 levels** in the hierarchy never collide with each other. Deeper pairs collide, but only their sphere approximations, and the pair list is rebuilt once per run (not per tick). Rationale: avoiding the classic self-collision jitter that makes jointed toys look broken, while still letting a long creature's leg hit its own head for comedy.

**Anti-tunnelling:** terrain is a **signed-distance grid** (0.25 WU cells) rather than triangles, sampled at the part's current and previous positions; if a part crosses a surface within one tick, it is projected back along the surface normal. The creature is small and slow enough that this is sufficient; the velocity clamp is the backstop.

**Contact response:** positional projection + Coulomb friction approximated by tangential damping `μ_effective = min(μ_part, μ_terrain)`, with a static-friction threshold of 0.15 WU/s tangential slip. Feet get an extra "grip bias": if the foot is the lowest point of the creature and normal force exceeded a threshold last tick, tangential damping is multiplied by 1.4.

### 4.5 Stability rules

| Failure mode | Rule |
|---|---|
| Jitter on rest | Sleep threshold (§4.2) + contact slop |
| Explosive joints | Per-tick angular impulse clamp: `Δω ≤ 6 rad/s` per constraint per tick |
| Stretched limbs | Distance constraint solved twice per iteration; residual > 0.25 WU forces a hard reset of the limb to its rest length |
| Creature pushed into terrain | Outward projection, max 0.4 WU/tick; beyond that, respawn at checkpoint |
| NaN / infinity | The solver validates state each tick; any non-finite value triggers recovery (§5.5) |
| 30 s of no ground contact | Forces a fall (anti-flying exploit) |

### 4.6 Determinism contract

A run is fully defined by the tuple:

```
Run(seed, creaturePayload, inputMask[tick], tuningVersion)
```

Two devices producing the same tuple must produce the same result, defined as: **same flag-reach tick ± 0**, same fall count ± 0, same final score ± 0. The tolerance is exact, not approximate; anything else is a bug. Section 10.6 defines the test (a 60-second scripted input log replayed on 5+ devices and 2 architectures).

If the contract cannot be met, the fallback `D-11` applies: ghosts are stored as **sparse transforms at 10 Hz** (not resimulated), and result codes carry `(time, falls, score, checksum)` rather than reproducing the run. Codes for *creatures* are unaffected either way, because a code is data, not a simulation.

### 4.7 Run state and checkpointing

| Element | Spec |
|---|---|
| Checkpoints | One per tower "pitch" — every 3–5 chunks (§6.4). A checkpoint is a flag sprite and a trigger volume 3 WU wide |
| Fall definition | (a) the creature's centre of mass drops > 5 WU below the highest checkpoint reached, **or** (b) any part enters a hazard, **or** (c) no part is in contact with terrain for > 2.5 s and the creature is below the highest checkpoint |
| On fall | Fade out 180 ms → respawn at last checkpoint → fade in 180 ms → 0.35 s input grace. **Falls counter +1. Timer keeps running.** |
| Respawn pose | The pose saved at the checkpoint trigger, not the pose of the fall. Deterministic: the checkpoint stores the exact part transforms at trigger time |
| Progress loss | Only to the last checkpoint (max 3–5 chunks). Never to the start |
| Timing | The timer runs from first input to flag entry, across all falls |
| Restart | Instant, no ad, no confirm, same seed. Target ≤ 800 ms from tap to controllable |

### 4.8 Camera and framing

- Deadzone 18 % of screen height; vertical follow is weighted 1.0, horizontal 0.35 (the tower is vertical).
- Look-ahead: +25 % of screen height in the direction of travel while ascending.
- Zoom: 1.0 default; 0.72 while airborne > 0.7 s or after a fall; lerp at 3.0/s.
- Clamps: never show below the tower base plane or above the summit + 2 WU.
- Shake: **disabled by default** (`A-20`); if enabled via reduce-motion OFF, max 4 px, < 3 Hz, never during the control input.

---

## 5. FALLING, RECOVERY, AND RESTART

### 5.1 Philosophy (P3)

The fall is the content. It must be **visible, funny, cheap, and instantly recoverable**. Any mechanic that makes a player hesitate to attempt something is banned.

### 5.2 Fall taxonomy

| Type | Cause | Presentation | Counter |
|---|---|---|---|
| **Tumble** | Ragdolled off a ledge, lands lower, still on terrain | No overlay. Camera zooms out. Creature keeps control | Falls +1 only if it drops below checkpoint height |
| **Checkpoint fall** | Dropped > 5 WU below the last checkpoint | S11 faint vignette + respawn | Falls +1 |
| **Hazard** | Lava/spikes/void | Instant fade, brief red flash (≤ 1 flash/s) | Falls +1 |
| **Stuck** | 8 s with < 0.5 WU of progress and grounded | Small pulsing hint arrow pointing up; after 4 more s, "Restart" chip appears | No penalty, no auto-restart |
| **Soft-lock** | 12 s with no state change and no input | Auto-pause with "Restart run?" | None |
| **Exploit exit** | Creature leaves tower bounds | Invisible wall at ± 9 WU; hard ceiling at summit + 6 WU | None |

### 5.3 S11 — Fall / recovery overlay `[CORE]`

Not in the mockup; required. Visual: a 260 ms fade to 55 % black with a 1 px channel-coloured vignette; centred, small text `Falls  3` updating with a soft count animation; no button, no dialog, auto-dismiss. It must never require a tap.

### 5.4 Restart affordances

| Where | Action | Behaviour |
|---|---|---|
| S10 Pause | "Restart run" | Immediate, same seed, same creature, timer resets |
| S10 Pause | "Restart from checkpoint" | Only if a checkpoint exists; **timer is not reset** (no farming) |
| S04 | Play Again / Next Tower | New run / next tower |
| Build (S02) after editing | Save → Play | New run from checkpoint 0, timer preserved (`D-08`) |
| Long-press pause (1.5 s) | Emergency restart | Escape hatch for a broken creature; no confirm, with a 3-second undo toast |

### 5.5 Recovery from an invalid simulation state

If the solver detects NaN, an unrecoverable penetration, or a part transform outside a 200 WU box:
1. Freeze the tick.
2. Restore all part transforms from the last checkpoint snapshot (or the run start).
3. Zero all velocities, re-apply the resting input mask as released.
4. Log `run_state_recovered` with the tick index and the failing constraint.
5. Show no dialog. Resume after 0.4 s.
If this happens 3× in one run, the run is ended with a soft error and the tower is marked "retry", not "failed" (`AC-118`).

### 5.6 Character of the failure

- On respawn, the creature's eyes look up at where it fell from (the head's eye target lerps to the last checkpoint for 1.0 s). This is the cheapest comedy in the game and it costs one line of code.
- Falls are **never** narrated with text on S03 ("You fell!" is banned). The counter on S04 does the talking.

---

## 6. TOWER DESIGN AND GENERATION

### 6.1 Structure

A tower is a vertical stack of **chunks**. A chunk is one screen-height (7.2 WU wide × 8.0 WU tall at zoom 1.0) and contains:

- an **entry ledge** at a defined x/y contract,
- 1–4 **obstacles** from the taxonomy,
- optional **decoration** (grass, rocks, banners) that never affects collision,
- optional **triggers** (flag, checkpoint, coin).

Chunk contract: every chunk exports `entryPoint` and `exitPoint` and guarantees the exit is reachable from the entry **by a valid creature** (§6.5). Adjacent chunks are stitched by aligning exit→entry with a 0–1 WU vertical tolerance.

### 6.2 Obstacle taxonomy

| # | Obstacle | Difficulty driver | Phase |
|---|---|---|---|
| 1 | **Ledge** (step up 0.4–1.0 WU) | Step height vs. limb reach | `[CORE]` |
| 2 | **Slope** (15°/30°/45°) | Traction and momentum | `[CORE]` |
| 3 | **Gap** (0.8–2.4 WU) | Jump distance vs. run-up | `[CORE]` |
| 4 | **Stairs** (2–5 steps) | Rhythm, foot width | `[CORE]` |
| 5 | **Overhang** (must duck/curl) | Creature height, body shape | `[CORE]` |
| 6 | **Narrow chimney** | Width ≤ 1.6 WU | `[CORE]` |
| 7 | **Ice patch** | μ = 0.15 | `[POST]` |
| 8 | **Wind zone** | Constant horizontal force 0.6–1.6 g | `[POST]` |
| 9 | **Moving platform** | Deterministic sinusoid, period 3–6 s | `[POST]` |
| 10 | **Crumbling rock** | Disappears 0.6 s after first contact | `[POST]` |
| 11 | **See-saw plank** | Rigid body on a pivot | `[POST]` |
| 12 | **Conveyor** | Surface velocity 1.2 WU/s | `[POST]` |
| 13 | Hazard field (lava/spikes) | Instant fall | `[POST]` |

**Rule:** the P0 prototype ships obstacles 1–6 only. That constraint is deliberate (six authored, tuned obstacle types beat twenty untuned ones).

### 6.3 Generation algorithm

```
generateTower(seed, profile) -> Tower

  rng = xoshiro128**(seed ^ GEN_SALT[profile.genVersion])
  chunks = []
  difficulty = profile.startDifficulty        // 1..10
  pitchIndex = 0

  while totalHeight < profile.targetHeight:
      band = pickBand(difficulty, profile.terrainMix)     // weighted table
      template = weightedPick(BAND_LIBRARY[band], rng)
      chunk = instantiate(template, rng, entryPoint)
      if not validates(chunk, budget):          // §6.5
          continue                              // reroll with the same rng stream
      chunks.push(chunk)
      difficulty = clamp(difficulty + profile.difficultyStep(difficulty), 1, 10)
      if (chunks.length % profile.flagEvery) == 0: placeCheckpoint(chunk)
  placeSummitFlag(chunks.last)
  return Tower(seed, genVersion, chunks, profile)
```

**Determinism:** the generator must be version-locked. `genVersion` is an integer constant baked into the build; changing ANY generation constant increments it, which retires the old daily towers rather than silently changing them.

**Daily towers are pre-baked.** The app ships with a **90-day buffer** of daily tower data (≈ 60–120 KB), generated at build time by the same generator version. This guarantees every player gets the identical tower, allows the fairness validation (§6.5) to run offline at authoring time, and removes all on-device generation cost. On first launch, the app also caches the next 30 days locally for older installs. If a device's date exceeds the buffer, the app generates locally with a clear "unofficial tower" flag (`A-21`), so the game never blocks.

**Seed derivation:** `seed = xxhash64(f"{YYYY-MM-DD}|{genVersion}|clamber")` in **UTC**. `A-22`: the mockup's "Day 14" implies a day index; `dayNumber = floor((date − 2026-01-01)/1 day) + 1` is displayed in the chip, so the number in the mockup is reproducible. The reset is at 00:00 UTC, and the UI states "resets at midnight UTC" rather than local midnight to avoid timezone-based cheating and confusion.

### 6.4 Difficulty progression

| Metric | Definition | Bands |
|---|---|---|
| `diff` | 1–10 scale stored per chunk | 1: flat + one ledge · 3: slopes + gaps · 5: stairs + overhangs · 7: chimneys + combos · 9: 2-obstacle chains with a precision element |
| Curve (campaign) | `diff(chunk_i) = clamp(1 + 0.55·i, 1, 10)` with a **plateau** (reset to −2) after every cleared pitch | Teaches, then tests, then rewards |
| Curve (daily) | Ramps 2 → 9 across the tower with the peak at 75–85 % height | The summit should feel earned |
| Tower length (P0) | 8 chunks, 2 checkpoints, ~55 s for a first clear | |
| Tower length (V1 daily) | 14–20 chunks, 4–5 checkpoints, 90–150 s clear | Matches the mockup's 01:24 |

### 6.5 Fairness validation (the generator's acceptance gate)

A generated chunk is **rejected** unless it passes all of:

| Check | Rule | Failure handling |
|---|---|---|
| Static reachability | A 2.2 WU reach capsule can be placed from entry to exit without intersecting terrain | Reroll |
| Reference-clearable | A scripted **reference creature** (a fixed 8-part biped with a deterministic driving policy) clears the chunk within 3× its baseline time | Reroll (max 40 attempts, then fall back to the band's easiest template) |
| No soft-lock geometry | Every resting surface drains to a checkpoint; no "bowl" from which the reference creature cannot escape | Reroll |
| No cheap shortcut | Ceiling/side walls prevent bypassing an obstacle above its plane | Reroll |
| Readability | Obstacle count ≤ 4 visible at once; no obstacle occluded by decoration | Reroll |

The reference creature + policy is a *validation tool*, not shipped gameplay. It is the same harness described in §13.3 and doubles as the difficulty baseline for medals (§7.4).

### 6.6 Content variety without content volume

Depth comes from systems, not level count:
- **Build space** — 5 families × lengths × angles × channels × budgets.
- **Seeded towers** — daily + practice + campaign hand-authored set.
- **Constraints** `[POST]` — "≤ 4 parts", "no feet", "carry the egg", "one channel only".
- **Weekly themes** `[POST]` — a terrain mix with a modifier banner (Icy week, Windswept week).

### 6.7 Level data format (authoring + shipping)

```json
{
  "towerId": "daily-2026-10-28",
  "genVersion": 1,
  "seed": 1489217360511,
  "profile": "daily",
  "terrainMix": "mixed",
  "parTimeMs": 100000,
  "scoreBudget": 4600,
  "chunks": [
    { "template": "slope_ramp_30",  "entryX": 0.0, "exitX": 1.4, "diff": 2, "decor": ["rock_s"] },
    { "template": "gap_pair",       "entryX": 1.4, "exitX": 3.1, "diff": 4, "triggers": ["checkpoint"] }
  ],
  "checkpoints": [ { "chunk": 3, "x": 2.2, "y": 24.0 } ]
}
```

Authoring is template-driven; there is no visual level editor in P0 (`[POST]` if ever).

---

## 7. SCORING, PROGRESSION, ECONOMY

### 7.1 What is measured

Exactly three run statistics exist, and they are the three shown on S04:

| Stat | Definition | Display |
|---|---|---|
| **Time** | First input → head enters summit flag trigger, in ms, displayed `MM:SS` | S03 HUD, S04, S06 |
| **Falls** | Count of checkpoint-fall / hazard events (§5.2) | S04, S06 |
| **Score** | Derived formula (§7.3) | S04 |

Nothing else is invented (no combo, no style rank, no XP per jump). Extra stats are a scope trap and a pillar-P4 violation.

### 7.2 Time rules

- Clock starts on the **first input sample**, not on spawn, so a player reading a tip is not punished.
- Clock runs during falls and during respawn fades.
- Clock stops the frame the flag trigger fires; the run ends.
- Sub-second precision is stored (`ms`) and displayed as `MM:SS` on HUD/S04; S06 and share cards may show `MM:SS.cs` `[V1]`.
- Runs over 99:59 are not possible (tower timeout at 15 min forces a "run abandoned" result).

### 7.3 Score formula (reverse-engineered to the mockup)

```
Score = max(0, round( B − F·falls − K·seconds + P·coins ))

B = tower "score budget"   (per tower; V1 daily range 3000–6000)
F = fall penalty           = 150
K = per-second penalty     = 10
P = coin pickup value      = 50
```

**Worked example — the mockup's S04 (Day 14, `Time 01:24`, `Falls 2`):**

```
seconds = 84, falls = 2, coins = 0, B = 4600
Score = 4600 − (150×2) − (10×84) + 0
      = 4600 − 300 − 840
      = 3460   ✔ matches the mockup exactly
```

**Design intent of the shape:** `B` dominates, so *finishing* is worth far more than being fast (pillar P3: the game rewards completion before mastery). Falls cost a fixed 150 (≈ 15 s of climbing), so a fall is painful but never fatal. Coins are small, optional, and exist only to make a risky detour meaningful `[POST]` — V1 ships coins at 0 per tower.

**No cap on the time term below 0:** the score floors at 0; a finish always awards at least the first-clear coin reward (§7.6) even if the score is 0.

### 7.4 Medals

Medals are **per tower**, computed from the reference-creature baseline (§6.5), never from other players (no leaderboard dependency):

| Medal | Threshold |
|---|---|
| 🥇 Gold | `time ≤ 1.00 × refTime` and `falls ≤ 1` |
| 🥈 Silver | `time ≤ 1.25 × refTime` and `falls ≤ 3` |
| 🥉 Bronze | `time ≤ 1.60 × refTime` or (any time with ≥ 1 fall) |
| — | Slower than bronze: "Cleared" |

`refTime` is shipped inside each tower's data (computed at bake time). This makes medals deterministic, offline, and identical for everyone.

### 7.5 Progression model

**There is no XP, no level, no battle pass** `D-12`. Progression is four parallel, non-exclusive tracks:

| Track | Advances by | Reward | Phase |
|---|---|---|---|
| **A. Part families** | Clearing campaign towers (hand-authored, teaching one obstacle each) | New family or part kind (Special tab fills in) | `[POST]` |
| **B. Budget** | Clearing a tier's final tower | +1 part slot, max 14 | `[POST]` |
| **C. Cosmetics** | Coins | Palettes, eyes | `[V1]` |
| **D. Mastery badges** | Behavioural firsts detected by the sim ("first roll", "first inchworm", "first 3-limb hop", "cleared with 4 parts") | A badge + a creature-journal entry | `[POST]` |

`A-23`: the mockup shows a "Workshop" unlock and cosmetic prices but no campaign map; the campaign is therefore a **post-MVP surface** (S13) and V1 progression is cosmetics + mastery badges only. The game is complete without it.

### 7.6 Coin economy

| Source | Amount | Cap |
|---|---|---|
| First clear of today's daily | 50 | 1/day |
| Repeat clear of today's daily | 10 | 5/day |
| Medal earned (gold/silver/bronze) | 40 / 25 / 15 | per medal, per tower, once |
| Personal best improvement | 15 | 3/day |
| Sharing a creature card | 5 | 1/day |
| Rewarded ad (optional) | 20 | 3/day `[POST]` |

| Sink | Price (mockup) | Equivalent play |
|---|---|---|
| Forest palette | 200 | ~1.5 normal days |
| Desert palette | 200 | ~1.5 days |
| Neon palette | 300 | ~2 days |
| Ice palette | 300 | ~2 days |
| Space palette | 300 | ~2 days |
| Classic palette | 0 (owned) | — |

Calibration check against the mockup: a player who has just cleared Day 14 with a best time and a bronze medal would plausibly hold `120` coins (50 first clear + 15 medal + 15 PB + 40 over three days). The mockup's `120` is therefore *consistent*, and the starting balance on a fresh install is **0**, with the first cosmetic reachable in two days `D-13`.

**Coin rules:** coins are never purchasable with real money (`D-01`). No coin doubler, no timer booster, no "watch ad for coins" in V1.

### 7.7 Cosmetic system

- A **palette** is a set of 6 part colours + joint-cap colours + an eye style. It recolours rendering only.
- Palettes are applied globally by default; a creature may pin its own palette (which then travels inside the creature code — see §8.3, 3 bits).
- **Classic is always free and always the default**, so a shared code never depends on the recipient owning a purchase.
- Unowned palette on an imported creature → the creature renders in Classic with a lock glyph and a one-tap "Unlock in Shop" route. **It must render and climb identically.**

### 7.8 Shop rules (S08)

1. Cosmetics only. No gameplay item is ever listed.
2. Prices are static (no A/B, no time-limited discounts, no "was 400 now 200") `D-14`.
3. Purchase is one tap → OS billing sheet → grant. Offline purchase is impossible; the button shows "Offline" instead of a price.
4. Ownership is local-first: an owned flag is written locally the moment entitlement is confirmed, and re-verified on next launch.
5. Restore/refund: entitlement is re-read from Play Billing on launch and after a reinstall `[V1]`.

---

## 8. CREATURE DATA, CODES, SHARING, COMMUNITY

### 8.1 Why text is the whole social layer

There is **no backend at MVP** (`D-15`). Every social feature is therefore a serialisation problem. This is a feature, not a constraint to apologise for: text codes work in group chats, in video captions, in comments, on paper, and they survive a server outage.

### 8.2 Two identifiers per creature

| Identifier | Form | Bits | Purpose | Matches mockup? |
|---|---|---|---|---|
| **Display code** (fingerprint) | `CL-XXXX-XXXX` (8 Crockford Base32 symbols) | 40 | Human-legible identity in lists, UI, speech, video captions | **Yes — exactly the mockup's format** |
| **Transfer code** (payload) | `CL-` + 32–44 Crockford Base32 symbols in 4-symbol groups | 160–220 | The actual reconstruction data; what **Copy** and **Share** emit | Extends the mockup's format, same typography |

**Decision `CD-01`:** the mockup shows an 8-symbol code as the visible label. 40 bits cannot hold a 10-part creature (a single 10-part creature needs ≈ 214 bits at the specified quantisation). Therefore the visible string is the **fingerprint** (a stable 40-bit hash of the canonical payload) and the **Copy** action copies the full transfer code. The UI does not change: the same monospace caps, the same `CL-` prefix, the same 4-symbol groups, the same single Copy pill. The only microcopy addition is the toast **"Full code copied"** so the player is not surprised by clipboard length. A receiver may paste either form; a fingerprint alone resolves from the local library or returns "That code isn't in your library — ask for the full code."

**Honesty note for future maintainers:** the concept report's estimate of "~20 characters" is optimistic. At V1 quantisation the realistic transfer code is 32–44 symbols. This should be reflected in any marketing copy ("a short code", not "a 20-character code").

### 8.3 Transfer-code bit layout (normative)

All fields are little-endian bit-packed into a byte stream, then Base32-encoded with **Crockford's alphabet** (`0123456789ABCDEFGHJKMNPQRSTVWXYZ`, case-insensitive, `I/L→1`, `O→0` on decode).

**Header — 24 bits**

| Field | Bits | Notes |
|---|---|---|
| `version` | 3 | 1 for V1 |
| `partCount` | 4 | 1–14 |
| `rootId` | 4 | always 0 (head); reserved |
| `lGain` | 5 | 0–31 → strength 0.00–1.00 in 1/31 steps |
| `rGain` | 5 | as above |
| `eyeStyle` | 2 | 4 eye variants |
| `reserved` | 1 | must be 0 |

**Part record — 19 bits × partCount** (index 0 = head, kind forced)

| Field | Bits | Encoding |
|---|---|---|
| `kind` | 4 | 0 empty · 1 limb · 2 passive joint · 3 motor · 4 foot-grip · 5 foot-spike · 6 foot-sticky · 7 spring · 8 suction · 9 counterweight |
| `parent` | 4 | index of parent, must be < own index |
| `length` | 3 | 8 buckets (§3.3) |
| `angle` | 4 | 16 buckets of 22.5° signed offset from parent |
| `channel` | 1 | 0 = L, 1 = R |
| `colour` | 3 | 8 palette slots |

**Trailer — 8 bits:** `crc8` over all preceding bytes (poly 0x07, init 0x00).

**Size:** `24 + 19·n + 8` bits, rounded up to a Base32 symbol (5 bits).
- 8 parts → 184 bits → **37 symbols**
- 10 parts → 222 bits → **45 symbols**
- Headline figure to quote: **"about 40 characters"**.

**Decoder rules:**
1. Strip whitespace, dashes, and the `CL` prefix; uppercase; apply Crockford substitutions.
2. If the symbol count matches a fingerprint (8) → resolve locally.
3. Verify CRC. On failure → error UI "That code looks damaged" + a photograph/paste retry.
4. Verify `version ≤ current`. On a newer version → "Made with a newer version of CLAMBER — update to open".
5. Verify structure (parent indices, ≤ 2 children, budget ≤ current max). On violation → "That code isn't a valid creature".
6. On success → **preview before save** (`[V1]`, S12 shows the assembled creature, its part count, and "Save to My Creatures").

**Test vectors** must be committed with the encoder (`/tests/codes/`): for each of ≥ 12 creatures (1-part, 10-part, all-kinds, branch, one-channel, zero-gain, corrupted CRC, future version), the exact canonical code string. Round-trip `encode(decode(x)) == x` for all.

### 8.4 Creature schema (local storage)

```json
{
  "schema": 3,
  "id": "c_01J9F3K2",
  "name": "The Hopper",
  "code": "CL-3D9F-7K2P",
  "transfer": "CL-XXXX-XXXX-...",
  "createdAt": "2026-10-12T09:14:00Z",
  "updatedAt": "2026-10-27T18:02:11Z",
  "palette": "classic",
  "favorite": true,
  "archived": false,
  "parts": [
    { "i":0, "kind":1, "parent":null, "len":3, "ang":0, "ch":0, "col":0 },
    { "i":1, "kind":3, "parent":0,    "len":2, "ang":5, "ch":0, "col":2 }
  ],
  "gains": { "l": 0.70, "r": 0.70 },
  "stats": {
    "bestByTower": { "daily-2026-10-14": { "timeMs": 136000, "falls": 2, "score": 3460, "medal": "bronze" } },
    "totalRuns": 9
  }
}
```

- `len`/`ang`/`ch`/`col` store the **quantised indices**, not floats. This guarantees that what is stored is exactly what is encoded, and eliminates an entire class of "the code doesn't reproduce my creature" bugs.
- `stats.bestByTower` is pruned to the last 30 towers.
- Creature library cap: `[V1]` 30 saved creatures (enough; the Workshop unlock raises it). On hitting the cap, the game prompts to delete or export rather than silently failing.

### 8.5 Community tab (S05)

No server exists, so "Community" means:

1. **Curated starter set** — 12 creatures shipped with the build (2 per palette), authored to span the build space (inchworm, biped, quadruped, tall wobbler, tiny roller, absurd 10-part spider). Always present, never deletable, marked with a small "CLAMBER" glyph.
2. **Imported creatures** — anything the player pasted from someone else, grouped with a subtle "from a code" tag.
3. **Featured of the day** `[POST]` — if a static JSON on a CDN is ever added; omitted at V1 because it breaks the offline promise.

Empty state explains the concept in one line: "Add creatures from codes your friends send you."

### 8.6 Sharing artifacts

**Share text (canonical):**

```
CLAMBER — The Hopper
CL-3D9F-7K2P
Best 02:16 · Day 14 · 2 falls

Full code:
CL-7Q2K-MXR9-4BTA-...
```

**S14 creature card (image)** `[V1]`: 1080×1350 PNG exported from a dedicated render target:
- top: creature on a transparent-then-sky background, rendered at 3× scale;
- middle: name, fingerprint, best time, medal;
- bottom: the full transfer code in 2 lines, monospace, plus a small "Clamber" wordmark.

Export uses `Viewport.get_texture().get_image().save_png()` into a cache dir, then the Android share intent via a small platform plugin. If image export fails, fall back to text-only share (`AC-310`).

**Deep link** `[POST]`: `https://clamber.game/c/CL-XXXX-XXXX` serving a static card page with an install link. Out of scope for V1 (needs hosting), but the share text already contains everything needed, so nothing is lost.

### 8.7 Ghost replays (personal only)

`[V1]` — cheap because determinism is already required.

- A ghost is the `inputMask[tick]` stream (2 bits/tick) plus the run's seed and creature id.
- Storage: 120 s × 60 ticks × 2 bits ≈ 1.8 KB before compression; RLE-compressed typically < 400 B.
- Rendering: a translucent silhouette of the player's **best** run for that tower, played back by resimulating (deterministic) or, under fallback `D-11`, by interpolating sparse transforms.
- Toggleable in Settings `[V1]` addition — **but the settings list in the mockup has no ghost toggle**, so it lives in the S10 pause sheet instead (`A-24`), keeping S09 exactly as designed.
- A ghost never affects physics (it is a visual layer only).

### 8.8 Result codes (friend comparison without a server)

`[POST]`. Format: `R-<fingerprint>-<timeMs-base32>-<falls>-<crc>`. Pasting one shows "Ali beat you by 0:12 with a 6-part creature" and offers to load that creature. This is the entire "leaderboard" replacement and it costs one more serialiser.

### 8.9 Ads and the share loop

Calling this out explicitly because it is a design constraint, not a monetisation detail:

- No ad may appear on S04 within 60 s of a Copy or Share action.
- No ad may appear after a fall.
- No ad before the player's first flag.
- No ad may interrupt a run.
- With **Offline Mode ON** (the shipped default, `A-17`), no ad loads at all.

Consequence: V1 (which ships with ads off entirely) has zero conflict with the loop; P2 must respect these rules even at the cost of revenue.

---

## 9. REMAINING SCREENS AND GLOBAL UI BEHAVIOUR

### 9.1 S10 — Pause overlay `[CORE]`

Not in the mockup (only the pause glyph is). Styled with the same tokens: full-screen 65 % navy scrim, a centred card of navy-800 with 32 px radius.

| Element | Behaviour |
|---|---|
| Title | `Paused` + the day chip repeated |
| **Resume** (yellow pill) | Unpauses; 3-2-1 none — instant, no countdown (P4) |
| **Restart run** (navy pill) | Confirms only if the run is over 60 s |
| **Build** (navy pill) | Opens S02 with the current creature; on save, returns to a *paused, restarted* run at checkpoint 0 (`D-08`) |
| **Ghost toggle** `[V1]` | On/off for this tower |
| **Settings** (gear, top-right) | Opens S09 as a sheet; returns to pause |
| **Quit** (text button) | Returns to S01; run state is discarded (with confirm) |

Pause rules: sim time freezes exactly; audio ducks to 20 %; the timer does not advance; backgrounding the app auto-pauses.

### 9.2 S12 — Import code sheet `[V1]`

- Reached from S05 (`⊕` long-press or a dedicated "Add from code" row in the Community tab) `A-25`.
- Fields: a single large text input (auto-uppercase, auto-hyphenate every 4 chars), a **Paste** button, and a **Camera** button `[POST]` (clipboard is enough).
- On submit: decode → preview (name auto-assigned "Imported #n") → **Save**.
- Error states are exhaustive (§11.5): damaged, wrong version, invalid structure, own creature (offers "that's yours"), duplicate (offers "already in your library").

### 9.3 S14 — Share sheet (internal) `[V1]`

Pre-share preview: the generated card image, a toggle for "include full code" (default **on**), and the standard Share button invoking the OS sheet. Share failure (no share targets) → copy to clipboard + toast.

### 9.4 Global components

| Component | Spec |
|---|---|
| **Toast** | Bottom, above the safe area, 40 px tall pill, 2.2 s, max 1 queued, never blocks input |
| **Confirm sheet** | Bottom sheet with a question, a destructive action (red-ish orange), and Cancel; used only for Destroy/Save-changes |
| **Loading** | Skeletons only for lists; spinners only for billing and share card export; nothing spins longer than 3 s before an error appears |
| **Currency chip** | Always live, animates on gain (+n floats up 600 ms) |
| **Empty states** | Every list has one; each contains exactly one actionable button |
| **Error banner** | Inline amber row under the top bar; dismissible; never a modal for a non-blocking problem |
| **Rate prompt** | Never before the 5th completed run and never after a fall; once per install `[V1]` |
| **Interruptions** | Phone call / notification / screen lock during a run → auto-pause; on return, resume is a single tap |

### 9.5 Motion and feedback rules

- Every control gives feedback within **80 ms** (scale 0.96 + colour shift).
- Screen transitions: 260 ms ease-out; no transition may delay input readiness.
- The thumb pads pulse only while the player has fewer than 3 lifetime runs (`Show Tips` governs).
- All motion respects the Reduce Motion system setting (§11.4).

---

## 10. TECHNICAL SPECIFICATION

### 10.1 Engine and language (chosen, justified)

**Godot 4.7.x stable, GDScript, custom PBD physics.**

| Option | Verdict | Reason |
|---|---|---|
| **Godot 4.7** | **Chosen** | MIT licence (no royalty, no licence churn), best-in-class 2D, very small APK, fastest iteration loop for a solo dev, mature Android export, GDScript is fast enough for ≤ 30 bodies |
| Unity | Rejected | Licence churn, larger binaries, and its 2D physics would still be replaced by the custom solver — no benefit |
| Native Kotlin + custom renderer | Rejected | Weeks lost to tooling for a game whose hard part is design iteration |
| LÖVE / Defold | Rejected | Android integration and store tooling weaker; no advantage for this project |

Version pinning `D-16`: target **4.7.2-stable** (latest stable maintenance release at time of writing, 18 Aug 2026; 4.7 released 18 Jun 2026, with 4.8 still in beta). Do not adopt 4.8 before release-candidate quality; the project must build with an explicit engine version recorded in `project.godot` and in CI. Reference: https://godotengine.org/download/archive/ and https://docs.godotengine.org/en/stable/about/release_policy.html

**Why custom physics:** §4.1. Godot's built-in 2D physics (and Jolt in 3D) is not cross-device deterministic and is not tuned for compliant limbs. We still use Godot's `CharacterBody2D`-free, purely mathematical solver driven from `_physics_process` with a manual accumulator.

### 10.2 Store compliance (verified, current as of this writing)

| Requirement | Specification | Source |
|---|---|---|
| **Target API level** | New apps and every update must target **API 36 (Android 16)** since **31 Aug 2026**; the 4.7.x export template defaults to targetSdk 36 | https://support.google.com/googleplay/android-developer/answer/11926878 |
| **minSdk** | 26 (`A-26`: Godot 4.7 templates ship 24; we raise to 26 to drop legacy input/rendering paths, covering ~98 %+ of active devices) | — |
| **16 KB page size** | Native libs must be 16 KB-aligned; Godot ≥ 4.5 supports this and 4.7.2 templates pass alignment checks | https://developer.android.com/guide/practices/page-sizes |
| **Play Billing** | Must use **Billing Library 8+** for new apps/updates since 31 Aug 2026; use 9.x if the plugin supports it, giving headroom to Aug 2027 | https://developer.android.com/google/play/billing/deprecation-faq |
| **Data safety form** | Declare: no data collected beyond an optional, opt-out analytics SDK; no location; no contacts; ads identifiers only if P2 ads ship | — |
| **Ads declaration** | `[V1]` declares "no ads". P2 must update the declaration before enabling ads | — |
| **Content rating** | IARC questionnaire; expect "Everyone" / PEGI 3 | — |
| **Families policy** | Not enrolled in Designed for Families; app must not target children under 13 in store listing | — |

`R-02`: each of these has a moving deadline. Re-verify all five at every release candidate; treat the run-up to 31 August each year as a mandatory compliance milestone.

### 10.3 Project structure

```
res://
  core/
    sim/               # deterministic solver: solver.gd, body.gd, constraint.gd, motor.gd
    run/               # run_controller.gd, checkpoint.gd, fall_detector.gd, input_recorder.gd
    creature/          # creature_model.gd, part.gd, validator.gd, serializer.gd, codec.gd
    tower/             # generator.gd, chunk_library.gd, validator.gd, reference_creature.gd
    econ/              # wallet.gd, medals.gd, score.gd
    data/              # save_store.gd (atomic), schema_migrations.gd, settings_store.gd
  ui/
    screens/           # s00_splash.tscn ... s16_workshop.tscn
    components/        # toast.tscn, confirm_sheet.tscn, creature_card.tscn, currency_chip.tscn
    theme/             # clamber_theme.tres, tokens.gd (colour/spacing constants)
  art/  audio/  data/ (towers/*.json, creatures/starter_*.json)
  platform/            # android/ share_plugin.gd, billing.gd, ads.gd, haptics.gd (all with no-op stubs)
  tests/               # headless determinism + codec + generator tests
```

**Architecture rules:**
- `core/` has **zero** UI or platform dependencies and is unit-testable headless.
- Every platform capability is behind a stub interface so the game runs in a desktop editor with no Android plugins.
- No autoload singletons for game state; one `App` autoload for services, everything else injected.
- Signals over polling; no `get_node("../../..")` chains.

### 10.4 Rendering and performance budgets

| Budget | Target | Measured on |
|---|---|---|
| Frame time (P95) | ≤ 16.6 ms | Snapdragon 660-class device, 1080p |
| Physics tick | ≤ 3.0 ms for 30 bodies / 120 constraints | Same |
| Draw calls | ≤ 45 | Any scene |
| Texture memory | ≤ 96 MB | — |
| APK download | ≤ 70 MB | Play Console |
| Cold start → controllable | ≤ 3.0 s | Mid-range |
| Warm resume | ≤ 250 ms | — |
| Battery | ≤ 8 % per 10 min gameplay | — |
| Memory ceiling | ≤ 320 MB RSS | — |

**Rendering decisions:** single `CanvasItem` layer per scene; creature parts drawn as batched `Polygon2D`/`Line2D` from a shared atlas, not per-part materials; the tower is a procedurally built `TileMapLayer` (Godot 4.5+ merges placed cell shapes); no 3D; Mobile renderer; `rendering/2d/snap/snap_2d_transforms_to_pixel = true` to avoid shimmer; MSAA off; screen at native resolution with a 0.85 `content_scale` floor for low-end devices.

**Resolution handling:** base viewport 1080×2340, `canvas_items` stretch mode with `keep` aspect; safe-area insets read from Android and applied as margins to the top bar and thumb-pad regions; ultra-tall (21:9) and short (16:9) devices are both supported by the same anchors.

### 10.5 Save data and persistence

| File | Contents | Write policy |
|---|---|---|
`user://settings.json` | volumes, toggles, reduce motion, locale | Every change, debounced 250 ms
`user://profile.json` | coins, owned cosmetics, applied palette, selected creature, tower progress, badges | Debounced 1 s + on lifecycle pause
`user://creatures.json` | creature library (§8.4) | On save/delete + on pause
`user://runs/<towerId>.json` | per-tower bests, ghost streams, medal | On run end
`user://drafts/` | build autosave slots | Every 20 s

**Atomic write protocol:** write to `<file>.tmp` → `flush()` → rename over the original → keep one `.bak`. On any read failure: try `.bak`, then the `.tmp`, then initialise defaults and raise a non-fatal error toast (`AC-402`). Every file carries `schema`; migrations are pure functions in `schema_migrations.gd` with tests from v1→v2→v3 fixtures.

**No cloud saves at V1** `D-17`. Reinstalling loses the library; the app mitigates by encouraging code export, and the store listing says so plainly. Play Games Saved Games is a `[POST]` option.

### 10.6 Determinism validation plan

| Step | Method | Pass criterion |
|---|---|---|
| 1 | Unit: solver on a fixed scenario, 10 000 ticks, hash of final state | Identical across 100 local runs |
| 2 | Cross-architecture: replay a 60 s recorded input log on arm64-v8a, arm64 device, x86_64 emulator, desktop | Final `(tick, position, falls)` bit-identical |
| 3 | Cross-device: 5 physical devices (2 low-end, 2 mid, 1 flagship) | Same as step 2 |
| 4 | Long-run soak: 200 consecutive runs | No drift, no NaN |

Fail → apply `D-11` fallback (sparse ghosts, cheat-tolerant results) and record why in the risk register. **The game is still shippable without determinism; it just loses ghost fidelity and honest result comparison — so this is a quality gate, not a launch blocker.**

### 10.7 Third-party dependencies

| Need | Choice | Phase | Notes |
|---|---|---|---|
| Ads | Google AdMob (via a maintained Godot plugin) | `[POST]` | Must not delay launch; the game is complete without ads |
| IAP | Google Play Billing 8/9 via the official Godot integration | `[V1]` if Workshop ships, else `[POST]` | If V1 ships no IAP, the Workshop tab remains locked and nothing is sold |
| Analytics | Privacy-light event log → local file, uploaded only if opted in | `[V1]` | See §14.1 |
| Crash | Google Play Console (Android vitals) + a local last-error file | `[V1]` | No extra SDK required |
| Share | Small Android `Intent.ACTION_SEND` plugin | `[V1]` | ~80 lines of Kotlin |
| Fonts | One open-licence rounded sans (e.g. a SIL OFL face) with the licence bundled | `[CORE]` | Verify commercial-use licence before shipping |

`R-03`: Godot's Android plugin ecosystem moves; every native plugin must be pinned and must have a pure-GDScript no-op fallback so a plugin failure never blocks play.

### 10.8 Error handling matrix

| Condition | Detection | User-visible behaviour | Log |
|---|---|---|---|
| Corrupt save | JSON parse/CRC fail | Toast "Couldn't load your creatures — recovered a backup"; library restored from `.bak` | `err_save_corrupt` |
| Save write fails (no space) | `FileAccess` open/write error | Blocking sheet: "Storage full", with "Free space / Continue without saving" | `err_save_write` |
| Invalid code | CRC/structure checks | Inline field error, keeps input editable | `err_code_invalid` |
| Code from newer version | `version` field | "Made with a newer version" | `err_code_version` |
| Tower data missing | Loader null | Falls back to last cached tower + banner | `err_tower_missing` |
| Sim invalid state | NaN/bounds check | Silent recovery (§5.5) | `err_sim_recovered` |
| Billing unavailable | `BillingResponseCode` | "Store unavailable — try later"; no coin loss | `err_billing` |
| Purchase succeeded, grant failed | Entitlement write error | Retry 3×, then "Restore purchases" CTA | `err_grant` |
| Ad failed to load | Timeout 8 s | Silently skip; the reward is never "lost" because it was never promised | `err_ad` |
| No network with Offline Mode off | Connectivity check | Features degrade, nothing blocks | `err_offline` |
| Clipboard unavailable | Platform return | Share text via OS sheet instead | `err_clipboard` |
| Share has no targets | Intent exception | Copy to clipboard + toast | `err_share` |
| OOM / process death mid-run | Android lifecycle | Run is discarded; no state corruption; next launch is clean | `err_proc_death` |

### 10.9 Single tuning resource

Every magic number in this document lives in `res://core/tuning.tres` (a Godot `Resource`), grouped by system: `Physics`, `Motors`, `Camera`, `Fall`, `Score`, `Economy`, `Generator`. Changing a value must not require a code change, and the tuning hash is included in telemetry so that playtest data can be attributed to a build configuration.

### 10.10 Accessibility and input (technical hooks)

- Remappable left/right (left-handed mode mirrors the input regions and pad colours).
- Touch targets ≥ 48 dp; thumb regions extend to the screen edges.
- No gesture ambiguity: the pads accept any finger; 3+ fingers are ignored beyond the two channels.
- Motion reduce: kills confetti, shake, camera zoom easing, and the fall vignette.
- Text scale 100–130 % via theme scaling; layouts use containers so text never clips.

---

## 11. AUDIO, HAPTICS, SETTINGS, OFFLINE

### 11.1 Audio direction

Playful, tactile, low-fidelity: rubbery thuds, springy squeaks, a light percussion loop that implies momentum. Music must never carry the tension of a run — the tension is the player's own thumbs.

| Event | Sound | Notes |
|---|---|---|
| Motor engage | Short squeak, pitch +2 semitones per 10 % contraction rate | The most frequent sound in the game; must not fatigue |
| Motor release | Soft breath inhale | Contrast is what sells the mechanism |
| Foot contact | Thud, volume/pitch by impact impulse | Velocity-scaled, 4 variants round-robin |
| Fall | Comedic descending slide (0.6 s) | Never harsh |
| Checkpoint | Two-note chime | |
| Flag reach | 1.5 s fanfare, the only "big" sound | |
| UI tap | Woodblock | |
| Purchase | Coin shimmer | |

Music: 3 loops (Home, Climb, Result) at 90–110 BPM, ≤ 1.2 MB each, Ogg Vorbis. Adaptive layering `[POST]`: percussion stems in on climb start. All music and SFX must be licensed for commercial use; an `ATTRIBUTION.md` ships in the repository and in the app's legal screen.

### 11.2 Audio implementation

- 3 buses: `Music`, `SFX`, `UI`, each driven by the S09 sliders (music slider → `Music`; speaker slider → `SFX` + `UI`).
- Voice pool: 12 `AudioStreamPlayer` nodes, round-robin, max 4 simultaneous instance of the same SFX.
- Limiter on the master bus; ducking of music by −6 dB during the fall/flag.
- Audio pauses exactly with the sim; no sound continues on the pause screen except a looped quiet bed at 20 %.

### 11.3 Haptics

| Event | Pattern | Setting |
|---|---|---|
| Thumb press | 8 ms light tick | Vibration toggle |
| Thumb release | none (absence is the feedback) | — |
| Foot landing with impulse > threshold | 12 ms medium | Vibration toggle |
| Fall | 40 ms heavy, then 20 ms | Vibration toggle |
| Flag reach | 3 × 25 ms ramp | Vibration toggle |
| Medal earned | 2 × 15 ms | Vibration toggle |

Haptics are disabled entirely in the first run and enabled after the first flag (never before it, to avoid a "broken phone" first impression on devices without a vibrator).

### 11.4 Accessibility requirements (`AC-5xx`)

| Requirement | Spec |
|---|---|
| **Channel identification never by colour alone** | L is blue **and** carries a circular/chevron glyph **and** the word "Left"; R is orange **and** carries a square/hand glyph **and** "Right". Motor glow uses the same glyph overlay at 40 % opacity |
| Colour-blind safe | Blue/orange is deuteranopia-safe; a third palette (`high-contrast`, with distinct luminance) ships for the joints and terrain |
| **Motor-assist mode** `[V1]` | Two global assists, individually toggleable: (a) *Grip assist* +35 % friction on feet; (b) *Slow-mo* global timescale 0.85. Both disable medals for that run and are shown with a small icon on the result screen |
| **Auto-drive** `[POST]` | An optional rhythm-pulse autopilot so players who cannot operate two thumbs can still watch and progress. Always labelled; never eligible for medals/bests |
| Reduce motion | System setting respected: no confetti, no shake, no zoom easing, instant transitions |
| Photosensitivity | ≤ 3 flashes/s anywhere; the fall flash is a ≤ 1 Hz vignette |
| Text scale | 100–130 %; all screens must survive 130 % without clipping (`AC-503`) |
| No timing gates in UI | No countdowns in menus; the tutorial has no fail state |
| Audio-only information | No information exists only in audio (every cue has a visual) |

### 11.5 Offline behaviour

`A-17` defines the shipped default: **Offline Mode is ON**, and the game must be fully playable.

| Feature | Offline behaviour |
|---|---|
| Build, climb, score, medals | Fully available |
| Daily tower | Available from the pre-baked 90-day buffer; if the date exceeds the buffer, generate locally and mark "unofficial" |
| Creature save/codes/import | Fully available |
| Cosmetics | Owned cosmetics usable; shop shows cached prices, purchasing disabled |
| Ads | Never load |
| Analytics | Buffered locally, uploaded only if opt-in and network present |
| Workshop purchase | Disabled with an explanatory state |

### 11.6 Lifecycle

- `NOTIFICATION_APPLICATION_PAUSED` → auto-pause the run, flush saves, stop audio.
- Process death mid-run → the run is lost, nothing else is (the save protocol is atomic).
- Returning within 10 minutes → resume to the pause screen, not directly into play.
- Screen rotation → ignored (portrait lock).
- Headphone connect/disconnect → do not change volume, just re-route.

### 11.7 Privacy

- No accounts, no PII, no contact or location access.
- Analytics `[V1]` is: local JSON of gameplay events, uploaded only with explicit opt-in from a first-run sheet shown *after* the first flag.
- No ad SDK in V1, so no advertising ID access in V1.
- Privacy Policy and Terms bundled in-app and reachable offline (`D-06`).
- COPPA/GDPR-K: the store listing targets 13+; no child-directed features.

---

## 12. SCOPE — PROTOTYPE vs. PRODUCTION

### 12.1 The three phases

| Phase | Purpose | Duration (solo, full-time) | Exit criterion |
|---|---|---|---|
| **P0 — Playable core prototype** | Answer one question: *is two-thumb driving of a jointed creature fun for ten minutes?* | 2–4 weeks | Experiment B gate (§13.4) |
| **P1 — Vertical slice / MVP** | The complete game as the mockup describes it, minus monetisation and campaign | 10–18 weeks | Soft launch in 2–3 markets |
| **P2 — Production features** | Campaign, Workshop IAP, ads, ghosts+, community, weekly themes | 8–16 weeks | Global launch readiness |

### 12.2 Screen-by-phase matrix

| Screen | P0 | P1 | P2 |
|---|---|---|---|
| S00 Splash | placeholder | full art | — |
| S01 Home | reduced: one **Play** button + gear | full (tower card, 3 tiles, currency) | crown states |
| S02 Build | reduced: tap-to-add from a fixed palette, 4 archetypes, 2 sliders, Reset/Save | full rails (5 families), undo, warnings, palettes | per-joint tuning, specials |
| S03 Climb | full HUD, both pads, timer, pause | + ghost, medals in HUD | — |
| S04 Victory | time/falls/score + Share (text) | + creature card, Copy, medal, New Best | + ad-safe "bonus" slot |
| S05 My Creatures | — | full (3 tabs, list, ⋯ menu) | multi-select |
| S06 Creature detail | — | full | — |
| S07 Daily Tower | — (P0 uses a single hand-authored tower) | full (carousel, previews) | terrain-mix variants |
| S08 Shop | — | Cosmetics grid, coin purchases | Workshop tab live (IAP) |
| S09 Settings | audio mute + vibration only | full (as mockup) | — |
| S10 Pause | full | + ghost toggle, build-and-return | — |
| S11 Fall overlay | full | full | — |
| S12 Import code | — | full | camera capture |
| S13 Campaign map | — | — | full |
| S14 Share sheet | — | full | deep-link page |
| S15 Rewarded ad | — | — | full |
| S16 Workshop | — | locked tab only | full |

### 12.3 Systems-by-phase

| System | P0 | P1 | P2 |
|---|---|---|---|
| Custom physics | ✅ 6 iterations, 60 Hz | ✅ hardening + determinism gate | ✅ optimised |
| Two-thumb control | ✅ | ✅ | + auto-drive assist |
| Parts | 4 kinds (limb, motor, passive joint, grip foot) | + colour palettes | + spike/sticky/spring/suction/counterweight |
| Tower | 1 hand-authored, 8 chunks, obstacles 1–6 | generator + 90-day daily buffer | + obstacles 7–13, themes |
| Scoring/medals | time + falls only | + score, medals, coins | + collectibles |
| Creature library | 3 presets, save 1 draft | 30 slots, full CRUD | 14-slot budget unlocks |
| Codes | encode/decode (headless, tested) | Copy/Share/Import UI | result codes |
| Ghosts | — | ✅ | sparse fallback |
| Economy | none | coins + cosmetics | Workshop IAP, rewarded ads |
| Analytics | local FPS + event log | opt-in upload | full funnel |

### 12.4 Explicitly excluded from P0 (and why)

- **No shop, no coins, no ads, no IAP.** Monetisation cannot be validated before the core is fun, and any of them would add a week of integration risk to a 3-week prototype.
- **No creature library or codes in the UI.** The codec exists and is unit-tested headless, because it constrains the data model; but no screen touches it yet.
- **No procedurally generated towers.** One hand-authored tower is a better test of feel than a mediocre generator, and it removes the largest scheduling risk from the prototype.
- **No palettes, no specials, no badges, no campaign, no ghosts.** All of these multiply the build space before we know whether the build space is interesting.

### 12.5 Definition of done — P0

The prototype is done when, on a mid-range Android device:

1. It boots into a climb in < 3 s.
2. Both thumb pads drive the creature with < 50 ms perceived latency.
3. Three preset creatures produce three visibly different gaits.
4. A player can fall and be climbing again in under 1.5 s.
5. The 8-chunk tower can be cleared by a new player in 3–12 attempts.
6. The build screen can add/remove parts and change both gains, and the effect is felt on the next run.
7. A 60-second recorded input log replays bit-identically on at least two devices.
8. It does not crash in a 30-minute session, including backgrounding 10 times.
9. Five external testers each voluntarily play > 10 minutes without prompting.

---

## 13. TEST PLAN AND ACCEPTANCE CRITERIA

### 13.1 Acceptance criteria (measurable, testable)

**Control & feel**

| ID | Criterion | Method | Phase |
|---|---|---|---|
| AC-101 | Input-to-visual latency ≤ 50 ms on a mid-range device | High-speed capture of tap and first frame of motion | P0 |
| AC-102 | Two simultaneous touches always register as L+R; a third touch never steals a channel | Automated multi-touch test | P0 |
| AC-103 | A released channel returns the motor to rest within 260 ms ± 40 ms at gain 0.7 | Solver trace assertion | P0 |
| AC-104 | The pad's visual hit region covers 100 % of the designated screen region | Region-bounds test on 5 aspect ratios | P0 |
| AC-105 | No creature can be made immobile-by-design while a motor and a foot exist | 200 random creatures × 3 seeds, all reach ≥ 1 WU in 20 s | P1 |

**Physics**

| ID | Criterion | Method | Phase |
|---|---|---|---|
| AC-201 | With no input, a creature settles and sleeps within 4 s | Trace test | P0 |
| AC-202 | No limb stretches more than 0.05 WU from its rest length during a 2-minute run | Assertion in debug build | P0 |
| AC-203 | No part passes through terrain at ≤ 42 WU/s | 500 randomised impact tests | P1 |
| AC-204 | Zero NaN/∞ events in a 200-run soak | Soak log | P0 |
| AC-205 | Frame budget §10.4 met on the reference low-end device | Profiler | P0 |
| AC-206 | 60 s scripted run is bit-identical on 5 devices | §10.6 | P0 |

**Build**

| ID | Criterion | Method | Phase |
|---|---|---|---|
| AC-301 | Placing a part at the budget limit is impossible (never produces 11/10) | Fuzz the placement UI | P1 |
| AC-302 | Save is blocked with a correct message for each of the 4 blocking validations | Manual matrix | P1 |
| AC-303 | A part can be placed on any valid socket in ≤ 3 taps from a cold build screen | Task-based usability test, 5 users | P1 |
| AC-304 | Autosave restores a draft after a process kill within 20 s of the change | Kill-and-relaunch test | P1 |

**Codes**

| ID | Criterion | Method | Phase |
|---|---|---|---|
| AC-310 | 12 test-vector creatures round-trip encode→decode identically | Unit | P0 |
| AC-311 | Every corruption of up to 3 symbols is detected (CRC) | Property test over 10 000 mutations | P1 |
| AC-312 | A future-version code produces the specific error state, not a crash | Unit + UI | P1 |
| AC-313 | A creature imported by code renders and climbs identically to the original (same seed, same inputs) | Determinism harness | P1 |

**Tower & fairness**

| ID | Criterion | Method | Phase |
|---|---|---|---|
| AC-401 | 100 % of a 90-day baked tower set passes the §6.5 fairness gate | Batch validation script in CI | P1 |
| AC-402 | The reference creature clears every chunk within 3× baseline | Batch script | P1 |
| AC-403 | Every tower has a checkpoint at least every 5 chunks | Data assertion | P1 |

**Data & resilience**

| ID | Criterion | Method | Phase |
|---|---|---|---|
| AC-501 | A corrupted `creatures.json` recovers from `.bak` with zero data loss for the previous save | File corruption test | P1 |
| AC-502 | Killing the app at 30 random moments mid-run never corrupts a save | Monkey test | P1 |
| AC-503 | All screens render without clipping at 130 % text scale, on 16:9 and 21:9 | Screenshot diff | P1 |

**Accessibility**

| ID | Criterion | Method | Phase |
|---|---|---|---|
| AC-601 | Channel identity is distinguishable in a grayscale screenshot | Grayscale capture check | P1 |
| AC-602 | Reduce-motion removes all confetti/shake/zoom and keeps the game fully playable | Manual | P1 |
| AC-603 | Every SFX has a visual counterpart in the same frame | Design review checklist | P1 |

**Experience (the only criteria that matter)**

| ID | Criterion | Method | Phase |
|---|---|---|---|
| AC-701 | ≥ 4 of 5 untutored testers state the goal correctly after 20 s of watching | Experiment A | P0 |
| AC-702 | Median first-flag time ≤ 60 s for a new player | Instrumented | P0 |
| AC-703 | ≥ 60 % of testers attempt a second run voluntarily after a failure | Instrumented | P0 |
| AC-704 | ≥ 3 of 5 testers build/alter a creature within the first session without being asked | Observation | P1 |
| AC-705 | Median voluntary session ≥ 8 min in a closed test | Instrumented | P1 |

### 13.2 Functional test scenarios

| ID | Scenario | Steps | Expected |
|---|---|---|---|
| T-01 | First launch | Install, open | Boots into S03 with "The Slug", ≤ 3 s; L pad pulses; reaches first flag; S04; "add a leg?" prompt appears once only |
| T-02 | Fall and retry | Fall from height | 180 ms fade, respawn at checkpoint, falls = 1, timer continues, no dialog, controllable ≤ 0.8 s |
| T-03 | Pause mid-air | Pause while airborne | Sim freezes exactly; resume continues the same trajectory; no time drift |
| T-04 | Build new creature | S02 → add 2 limbs + motor + foot → Save | Part counter correct, code regenerated, creature appears in S05, playable |
| T-05 | Budget limit | Add parts to 10 | 11th placement impossible; tiles dim; toast correct |
| T-06 | Invalid creature | Remove all motors → Save | Blocked with the specific message; Reset/Save still usable |
| T-07 | Share & import | Save, Share → copy text → Import in the same device | Imported creature identical (part count, gains, code match) |
| T-08 | Corrupt code | Import `CL-0000-0000` and a truncated real code | Distinct, correct error messages; input remains editable |
| T-09 | Offline daily | Airplane mode ON, open S07 | Today's tower available, Playable, no ads, no errors |
| T-10 | Date rollover | Change device date to tomorrow mid-session | New daily loads after returning to S01; no data loss; a warning if time moved backwards |
| T-11 | Shop purchase | Buy Forest with insufficient coins | Confirm sheet shows shortfall, Buy disabled, "how to earn" route |
| T-12 | Settings persistence | Change both volumes, toggles, kill app, relaunch | All values restored |
| T-13 | Background during run | Home button mid-run, wait 60 s, return | Auto-paused, resume works, timer unchanged |
| T-14 | Process death | Kill the process mid-run, relaunch | Clean boot, library intact, no partial run |
| T-15 | Corrupt save | Replace `creatures.json` with garbage, launch | `.bak` recovery or default library + toast; no crash |
| T-16 | Extreme creature | 10 parts, all one channel, gain 0 | No crash; immobile-but-grabbable; 12 s soft-lock prompt appears |
| T-17 | 3+ touches | Press L, R, and a third finger | Third finger ignored; channels stable |
| T-18 | Text scale 130 % | Set system text scale, open every screen | No clipping; all CTAs reachable |
| T-19 | Medal thresholds | Clear a tower at exactly refTime | Gold awarded; falls=2 at refTime → Silver |
| T-20 | Share from S06 vs S04 | Share from both | Identical payload; no double coin award |

### 13.3 Automated harnesses (must exist before P1)

1. **Headless simulator** — runs the solver with no rendering at 10× speed for soak and determinism tests.
2. **Reference creature bot** — deterministic policy used for fairness validation and medal baselines.
3. **Tower batch validator** — CI job over the 90-day buffer; fails the build if any tower fails §6.5.
4. **Codec property tests** — round-trip + corruption fuzzing.
5. **Save migration fixtures** — v1/v2/v3 sample files that must load after any schema change.

### 13.4 Experiment gates (from the concept's validation plan, restated as engineering gates)

| Gate | Measure | Pass | If it fails |
|---|---|---|---|
| **B — driving is fun** | 5 testers, P0 build, no prompting: voluntary play > 10 min each, ≥ 60 % do a second run after a failure | Proceed to P1 | Iterate control twice (see below), then pivot |
| **C — building is wanted** | Closed test, 50–200 testers: builds in most sessions; D1 return not collapsing | Proceed to soft launch | Reduce build friction; lean on presets |
| **D — distribution** | 12–20 clips across 4 formats: any single format producing unprompted "what is this" comments and non-zero code redemptions | Soft launch | Stop; do not invest further |

**The two control iterations if B fails** (decided in advance so the team cannot rationalise forever):
1. **Momentum-preserving release:** add a 120 ms post-release assist that preserves limb momentum (making the creature feel more like a vehicle).
2. **Tap-rhythm alternative:** a third input mode where a *tap* (not a hold) fires a single full contraction, making the game more like a rhythm toy. Same creature, same physics; only the input mapping changes.

If B fails after both, the concept pivots to the Lineage/breeder mode or the contraption alternative — not a fourth control variant.

---

## 14. METRICS AND SUCCESS CRITERIA

### 14.1 Events (local-first; uploaded only with opt-in)

| Event | Key properties |
|---|---|
| `app_open` | build, cold/warm, device tier, offline |
| `run_start` | towerId, creatureId, partCount, gains, isPreset |
| `run_end` | result (flag/quit/timeout/abandon), timeMs, falls, score, medal, attemptIndex |
| `fall` | type, heightLost, tick |
| `build_open` / `build_save` | source, partsAdded, partsRemoved, gainChanges, durationMs |
| `code_copy` / `code_share` / `code_import` | source screen, outcome |
| `shop_view` / `shop_buy` | itemId, price, balanceAfter, outcome |
| `settings_change` | key, value |
| `error` | code, context (never PII) |
| `perf` | P95 frame ms, sim ms, dropped frames per session |

### 14.2 Success metrics (targets to *evaluate against*, not promises)

| Metric | Target for soft launch | Kill signal |
|---|---|---|
| First-flag completion in first session | ≥ 70 % | < 40 % → tutorial/control broken |
| Median first-flag time | ≤ 90 s | > 3 min → tower too hard early |
| Voluntary retry after failure | ≥ 60 % | < 35 % → failure is punishing or unclear |
| Builds created per active user in week 1 | ≥ 2 | ≈ 0 → build is too fiddly |
| Share or copy per session | ≥ 1 % | ≈ 0 → the loop does not exist |
| Code redemptions per 100 installs | ≥ 5 | 0 → sharing has no recipient |
| D1 / D7 | 25 % / 8 % (directional) | D1 < 15 % → first session is not landing |
| Crash-free sessions | ≥ 99.5 % | < 98 % → stop shipping features |
| Median session length | ≥ 6 min | < 3 min → the loop is too thin |

**Honesty clause for future readers:** none of the above has been measured. These are the thresholds at which the *design* would be considered validated; they are not evidence that it works. Any document claiming CLAMBER's mechanics are proven fun or viral is wrong.

### 14.3 What would count as disconfirming evidence

- Testers stop voluntarily in under 5 minutes after two control iterations.
- Players build one creature and never build again.
- Fewer than 1 in 200 sessions produces a share, and no clip format produces unprompted interest.
- Players describe the game as "a ragdoll toy" with no goal when shown a 15-second clip.

Each of these is a reason to change the design or stop, and each is measured by an experiment listed in §13.4.

---

## 15. RISKS, ASSUMPTIONS, OPEN DECISIONS

### 15.1 Risk register

| ID | Risk | P | Impact | Mitigation | Validation |
|---|---|---|---|---|---|
| R-01 | **Physics feel + determinism** are harder than estimated (the signature asset is the riskiest build) | High | High | Custom solver written early and standalone; feel tuned before any UI; determinism gate at P0 with a documented fallback | AC-206, AC-202 |
| R-02 | Store policy deadlines move (API level, billing version, page size) | Med | Med | Compliance checklist reviewed at every RC; Billing 9.x chosen for headroom | §10.2 |
| R-03 | Android plugin ecosystem breakage (ads/IAP/share) | Med | Med | Pin versions; every plugin behind a stub with a no-op fallback | AC at RC |
| R-04 | **Build UI is fiddly on a phone** (the classic failure of this genre) | High | High | Presets + archetype quick-add + snap; players can play the daily forever without building | AC-303, AC-704 |
| R-05 | Tower generator produces unfair or boring towers | Med | High | Fairness gate with a reference creature; pre-baked dailies; six tuned obstacles before twenty | AC-401/402 |
| R-06 | Driving is not fun (concept-level risk) | Med | Fatal | P0 exists solely for this; two pre-agreed iterations; pivot plan | Experiment B |
| R-07 | No organic distribution; store discoverability is poor | High | High | Validate clips before investing; keep burn near zero; code share is the growth channel | Experiment D |
| R-08 | Fast clone if successful | Med | Med | Ship the brand-defining surfaces (card format, codes, daily) at launch; competitive advantage is feel + tuning, which is genuinely hard to copy | — |
| R-09 | Performance on low-end devices | Low | Med | ≤ 30 bodies; budget table; reference device under test | AC-205 |
| R-10 | Save corruption / data loss | Low | High | Atomic writes + backup + migration tests | AC-501 |
| R-11 | Ad integration damaging the share loop | Med (P2) | Med | Hard placement rules (§8.9); ads off by default (Offline Mode) | Design review |
| R-12 | Scope creep into campaign/community before core is proven | High | High | This document's phase tags; P0 definition of done is narrow and enforced | — |

### 15.2 Assumption register

| ID | Assumption | Why it exists | How to validate |
|---|---|---|---|
| A-01 | Splash is not a tap-to-start gate | Mockup shows no button | Observe first-run behaviour |
| A-02 | Coin `⊕` opens a coin-acquisition sheet | Iconography is ambiguous | Usability test on S01 |
| A-03 | Home crown = tower cleared today | No legend in mockup | Test comprehension |
| A-04 | The four coloured tiles in S02 are quick-add limb archetypes | No labels given | Test comprehension; relabel if read as colours |
| A-05 | Motor strength sliders are **global channel gains**, not per-part | Mockup shows exactly two sliders | Test whether players expect per-part tuning |
| A-06 | Part budget default 10 | Mockup `3/10` and `Parts 8` | Tune with playtests |
| A-07 | Pad glyphs are stylistic; semantics are "hold" | Glyphs could imply tap | Test with new players |
| A-08 | Glowing parts illustrate channel membership | Visual inference | — |
| A-09 | "Next Tower" = next day where available, else repeat | No next-day affordance in mockup | — |
| A-10 | Score formula reproduces `3,460` exactly | Mockup is the reference | Automated unit test |
| A-11 | Greyed list row = not yet cleared on the highlighted tower | Best available reading | Test with users |
| A-12 | List order = last used, favourites pinned | Mockup order is neither alphabetical nor by time | — |
| A-13 | `★` by name = favourite; `★` by time = medal earned | Two stars in one row | Consider a rosette glyph |
| A-14 | Carets navigate days, not towers | Copy says "Daily Tower" | — |
| A-15 | Three dots = preview pagination | Visual inference | — |
| A-16 | Locked "Workshop" tab = one-time unlock | Matches the concept's model | — |
| A-17 | Offline Mode default ON and means "no network at all" | Toggle shown ON | — |
| A-18 | "Show Tips" = in-world tips/hints only | — | — |
| A-19 | Max two children per segment | Keeps builds readable | Playtest readability |
| A-20 | Camera shake off by default | Accessibility-first | — |
| A-21 | Beyond the baked buffer, generate locally and mark "unofficial" | Avoids a hard date cliff | — |
| A-22 | Day number computed from a fixed epoch; daily resets 00:00 UTC | Mockup shows "Day 14" | — |
| A-23 | Campaign/progression map is post-MVP | Not in mockup | — |
| A-24 | Ghost toggle lives in pause, not settings | Settings list is fixed by the mockup | — |
| A-25 | Import lives in S05 Community | No import affordance in mockup | — |
| A-26 | minSdk 26 | Coverage vs. simplicity trade | Device analytics after launch |

### 15.3 Open decisions (owner: design lead)

| ID | Question | Options | Needed by |
|---|---|---|---|
| OD-01 | Is the transfer code acceptable at ~40 characters? | (a) accept, (b) introduce a link-based short code needing a host, (c) reduce quantisation | P1 start |
| OD-02 | Do per-joint motor settings justify their UI cost? | ship / defer | P1 mid |
| OD-03 | Does the game ship with ads at all? | yes at P2 / never | P2 planning |
| OD-04 | iOS after Android? | yes / no | Post-launch |

---

## 16. DELIVERY

### 16.1 Milestones

| M | Milestone | Duration | Deliverable | Gate |
|---|---|---|---|---|
| M0 | Project skeleton, tuning resource, CI, Android export on device | 1 wk | APK that boots | — |
| M1 | Standalone solver + 3 preset creatures + headless harness | 1–2 wk | Determinism + feel harness | AC-201/204 |
| M2 | S03 climb + S11 fall + S10 pause + one hand-authored tower | 1 wk | **P0 prototype** | Experiment B |
| M3 | Reduced S02 build + save/draft | 1 wk | P0 complete | §12.5 |
| M4 | Codec + library + S05/S06 + S12 | 2 wk | Creatures persist and travel | AC-310–313 |
| M5 | Generator + 90-day bake + fairness CI | 2–3 wk | Deterministic dailies | AC-401/402 |
| M6 | S01, S07, S08, S09, S04 final, palettes, coins | 3 wk | **P1 feature complete** | Internal |
| M7 | Polish, audio, haptics, accessibility, localisation hooks | 2 wk | RC1 | AC-5xx/6xx |
| M8 | Soft launch (2–3 markets) | 2–3 wk | Live build | Metrics §14.2 |
| M9 | P2: campaign, Workshop IAP, ads, ghosts+, themes | 8–16 wk | Global launch candidate | — |

**Total to P1 (full-time, one developer):** approximately 10–18 weeks of engineering after the prototype, i.e. **12–22 weeks** from M0 to M8, excluding marketing. Part-time, double it. This estimate excludes the tuning time, which no schedule survives: plan an explicit **3-week feel-polish buffer** before M8 and expect it to be needed.

### 16.2 Repository deliverables alongside this GDD

1. `tuning.tres` initialised with every constant in this document.
2. `data/towers/` — 90-day baked buffer.
3. `data/creatures/starter_*.json` — 12 curated creatures.
4. `tests/codes/` — 12 codec test vectors.
5. `ATTRIBUTION.md` — every font, sound, and music licence.
6. `COMPLIANCE.md` — the §10.2 table with re-verification dates.

### 16.3 Standing rules for whoever implements this

1. **Do not add a control.** No jump, no brake, no boost. If a level needs one, the level is wrong.
2. **Do not sell power.** No part, slot, or stat is ever purchasable.
3. **Do not punish absence.** No streaks, no decay, no missed-day guilt.
4. **Do not gate the first flag.** No ad, no prompt, no dialog before it.
5. **Do not break the code.** Every creature must always serialize, and every code must always decode or fail loudly.
6. **Do not change the mockup's screens** without an explicit `D-xx` entry here.
7. **Do not claim the game is fun.** Measure it (§13.4) and report what you measured.

---

## APPENDIX A — WORKED EXAMPLE: DAY 14

Everything below is consistent with the supplied mockup and can be used as an integration fixture.

| Item | Value |
|---|---|
| Tower | `daily-2026-10-14`, day number 14, terrain mix `Mixed`, 16 chunks, 4 checkpoints, `scoreBudget 4600` |
| Active creature | "The Hopper", 8 parts, code `CL-3D9F-7K2P`, gains L 0.70 / R 0.70 |
| Run | `Time 01:24` (84 000 ms), `Falls 2`, `Score 3,460` (formula verified §7.3) |
| Medal | Bronze (1.6 × refTime band, 2 falls) |
| Coins after run | 120 (50 first clear + 15 medal + 15 PB improvement + 40 carried) |
| Library shown | The Hopper 02:16 (8 parts) · Spider Walk 01:48 · Long Boy 02:37 (greyed, no medal) · Tanky 03:12 |
| Shop shown | 120 coins; Classic owned; Forest/Desert 200; Neon/Ice/Space 300; Workshop locked |

## APPENDIX B — STRING TABLE (locked copy)

| Key | English |
|---|---|
| app.tagline | Build it. Drive it. Climb it. |
| home.play | Play |
| home.todaysTower | Today's Tower |
| home.build | Build |
| home.creatures | Creatures |
| home.shop | Shop |
| build.title | Build Your Creature |
| build.tab.limbs | Limbs |
| build.tab.joints | Joints |
| build.tab.motors | Motors |
| build.tab.feet | Feet |
| build.tab.special | Special |
| build.parts | Parts %d/%d |
| build.gainLeft | Left Motor Strength |
| build.gainRight | Right Motor Strength |
| build.reset | Reset |
| build.save | Save |
| build.err.noMotor | Needs at least one motor to move |
| build.err.noFoot | Needs a foot to push against the ground |
| climb.holdLeft | Hold Left |
| climb.holdRight | Hold Right |
| result.title | You Reached the Flag! |
| result.time | Time |
| result.falls | Falls |
| result.score | Score |
| result.copy | Copy |
| result.share | Share |
| result.next | Next Tower |
| result.again | Play Again |
| result.copied | Full code copied |
| creatures.title | My Creatures |
| creatures.tab.mine | My Creations |
| creatures.tab.community | Community |
| creatures.tab.favorites | Favorites |
| creature.parts | Parts |
| creature.bestTime | Best Time |
| creature.falls | Falls |
| creature.share | Share |
| creature.edit | Edit |
| daily.title | Daily Tower |
| shop.title | Shop |
| shop.tab.cosmetics | Cosmetics |
| shop.tab.workshop | Workshop |
| settings.title | Settings |
| settings.soundMusic | Sound & Music |
| settings.vibration | Vibration |
| settings.tips | Show Tips |
| settings.offline | Offline Mode |
| settings.privacy | Privacy Policy |
| settings.terms | Terms of Service |
| err.codeDamaged | That code looks damaged |
| err.codeVersion | Made with a newer version of CLAMBER — update to open |

Strings must be externalised (CSV/`.translation`) from day one; no string literals in scenes.

## APPENDIX C — FINAL CONSISTENCY CHECKLIST

- [x] Every screen in the mockup is documented with layout, behaviour, states, and assumptions.
- [x] No mockup screen was redesigned; the only additions are new screens (S10–S16) and microcopy.
- [x] Every gameplay rule has a measurable acceptance criterion or test scenario.
- [x] Prototype (P0), MVP (P1), and production (P2) scopes are separated and justified.
- [x] Every numeric constant is labelled tunable and lives in one resource.
- [x] The physics determinism contract has a gate and a documented fallback.
- [x] The score formula reproduces the mockup's numbers exactly.
- [x] No claim is made that any untested mechanic is fun, proven, or viral.
- [x] Store compliance requirements are cited to current official documentation.
- [x] All ambiguities are labelled `A-xx` with a resolution and a validation path.

---

*End of document. Version 1.0 — 28 October 2026.*
