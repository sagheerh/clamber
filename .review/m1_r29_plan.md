# R29 premeasurement plan

Launch routing restored FIRST: separate push-only workflow r29.yml, immutable
event SHA + [R29-once], no workflow_dispatch or artifact-upload dependencies.
No historical workflow arm is unpinned. One sequential worker, one process per
D0,D1,D2,D3,D4,D5 arm in that order; regressions D7 last. Six start facts must
pass before D0. Measurement source SHA is recorded, then closed literally.
Evidence will be committed to the same fixed session branch with [skip ci],
with compressed annotation backup if repository write fails. No artifact deletion.
No product/core edits; no new acceptance threshold. Missing scenario/threshold
is NOT RUN, never manufactured. All generated captures under5MB.
