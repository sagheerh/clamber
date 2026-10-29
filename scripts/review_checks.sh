#!/usr/bin/env bash
# Static evidence only; NOT a substitute for replay/soak/performance/visual review.
set -euo pipefail
cd "$(dirname "$0")/.."
echo 'CLAMBER M1 review — static/invariant subset'
python3 scripts/check_m1_matrix.py
python3 scripts/review_static.py
python3 tests/test_review_checks.py
python3 tests/test_owner_geometry_source.py
python3 tests/test_load_trace.py
python3 tests/test_contact_trace.py
python3 tests/test_r14_owner.py
python3 tests/test_static.py
python3 tests/test_android_inspection.py
echo 'PASS: review_checks.sh static checks completed.'
echo 'PENDING: formal INV-01..INV-10 semantic sweep / A10 five-fakes / A12 review.'
echo 'NOT RUN: M1 replay, falsification, baseline, soak, timing and gait captures.'
