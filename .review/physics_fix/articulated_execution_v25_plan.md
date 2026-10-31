# V25: final-geometry constitutive operator split — COMPONENTS ONLY

V24 sourcea2a900fe2b29/run41218016181 CLOSEDFAIL:401native,600/Slug7200PASS;
Hopper227FINAL status30, TwinNOTRUN; publishera258574. No unchanged retry.
V24first complete constitutive stage passed1.5156160421302822→4.0764550485385975e-26.
Stable coordinates fix particular frames but do not solve generic endpoint
quantization/passivity. NO more coordinate variation / ULP nudge / guard waiver.

Explicit different discretization: initial UNDAMPED physical impact/support,
positions+six sweeps, then the SINGLE complete authored angular-drag/support
operator evaluated on final actual geometry. Full angular retention unchanged.2;
NO extra angular stage, damping coefficient, iteration or energy-derived branch.
The entire original local-drag plus coupled-support operator moves together, not
an extra post-hoc damper. Linear loss, one original drive, full gravity, 2passes,
6positions, caps/material/masses/axes/sleep/RNG/guards remain. Existing candidate
classes still usephase0. New subclass explicitly recordsphase1; historical
capture semantics stay immutable. This changes stage ordering, not a tuning fix.

Purpose: constitutive law should close on same final geometry as end-of-tick
constraints, not be followed by an unrelated undamped near-null projection after
nonlinear position operations. Original strict per-stage/whole actual endpoint
energy barriers remain; first physical impact also strictly passive. New formula
must prove native before any public-world registration. It is NOT guaranteed by
the earlier coordinate regressions and could still fail.

Required zero-public-clock native: original42 plus new57 controls. Twelve real
component steps across3models/all4held masks, phase counts/controller once,
actual-energy/impulse ledgers;3 invalid real-material rollback; three archived
failed FINAL frames as stress inputs with complete constitutive physical guards.
Archived inputs have old stage history: applying final constitutive operator is
ONLY a component stress check, NOT a full new tick or evidence of no-double-drag
in an old world. New real component steps prove one phase per NEW tick. No new
world, runtime-suite retry, production adoption or full validation credit here.
