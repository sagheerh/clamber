# Read-only static support diagnosis — NOT a 600-tick impossibility verdict

Pinned NEW V16 source253102b4750d42cbe8780fc72c61f4b1749ad83d/
CI41169768318, immutable publisher523c181. No new world/replay. Fraction5 controls
read actual spawn, including source free-foot joint taxonomy and .25WU grid.

Actual bodies: head mass.77/length.35; motor.48/.30; foot.30/.25; M1.55.
Only motor/passive kinds get angular joints. Foot has an ideal positional pin,
NOT a motor/passive angular spring or rigid parent attachment. GDD§3.1 calls it
a terminal pad; §3.2 says rigid/n/a, which alone does not authorize a new parent
weld or different collision shape. Resolve physical intent before inventing one.

Within +/-15deg relative original RIGHT/DOWN/DOWN pose, head and motor cannot
contact the floor, even allowing full .02WU penetration/slop. Foot upper endpoint
and any midpoint are above its contact band. .25WU foot on .25WU grid has only
ends (or ends+midpoint under extent roundoff), so only lower endpoint B qualifies.
This is a single support point, not the silhouette interval Bx+/-radius. Normal
force at actual skin and centreline share the same horizontal line of action.

At genuine static equilibrium all external horizontal forces sum to zero:
terrain tangent force T=0. Vertical force N=M*g. Take foot moments about its
unactuated pin A: g*Lf*(M-mf/2)*sin(delta_foot)=0. Coefficient=9.8N*m, so within
+/-15deg its axis MUST be vertical. There is no static drag torque at zero speed.
With vertical foot, whole COM relative contact B obeys

    COMx-Bx = -[.13475*cos(delta_head)+.303*sin(delta_motor)]/1.55

For |delta|<=15deg, conservative exact enclosures cos15>.96, sin15<.26 give
COMx-Bx < -.03263225806451613WU. Hence uncompensated whole-creature gravity
moment exceeds1.41624N*m. Internal motor torque cannot cancel whole angular
momentum. No static, single-support equilibrium exists in that pose box under
these assumptions. This is stronger than an initial-COM silhouette observation:
it also enforces the free foot's own moment balance.

IMPORTANT LIMITS: this is a STATIC equilibrium obstruction, NOT a rigorous
finite-time bound for the anchored.001WU/30 sleep implementation or a proof that
600 ticks cannot satisfy every discrete metric. It does not waive any gate, prove
all numerical defects repaired, authorize retuning, or justify forced sleep,
new foot welds or a posture controller. Resting after tipping into head/motor
contact is outside the pose box and does not contradict the derivation.
V16 actually reaches such a tipped multibody-support state, with continuous
motion and no qualifying sleep: max38.504759454769165deg, first failure43.

Engineering implication: stop treating verified friction/hinge corrections as
proof of an upright-rest fix. A documented owner decision about foot support /
attachment and authored stance is needed before changes to those locked physical
definitions. Preserve all 15deg/4s/F52/.90WU, original geometry evidence, and
strict force/rollback/math controls. No new proposal/world selected here.
