#!/usr/bin/env python3
"""Exact-arithmetic contact counterexamples/oracle; NOT Godot execution or AC evidence."""
from fractions import Fraction as F
from pathlib import Path
import json
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]


def matrix(mass, inertia, rx, ry, nx, ny):
    cn = rx * ny - ry * nx
    ct = rx * nx + ry * ny
    return 1 / mass + cn * cn / inertia, 1 / mass + ct * ct / inertia, cn * ct / inertia


def solve(knn, ktt, knt, vn, vt, retention, restitution):
    dn = -restitution * min(F(0), vn) - vn
    normal_only = max(F(0), dn / knn)
    tangent_after_normal = vt + knt * normal_only
    dt = retention * tangent_after_normal - vt
    determinant = knn * ktt - knt * knt
    jn = (dn * ktt - dt * knt) / determinant
    jt = (dt * knn - dn * knt) / determinant
    if jn < 0:
        jn = F(0)
        jt = dt / ktt
    return jn, jt


class ContactAnalysis(unittest.TestCase):
    def test_free_endpoint_cleanup_changes_bone_length(self):
        # A vertical segment: contact at A moves only A by depth.
        a, b, depth = F(0), F(1, 4), F(1, 16)
        self.assertEqual(b - (a + depth), F(3, 16))
        self.assertNotEqual(b - (a + depth), b - a)

    def test_common_translation_preserves_extent(self):
        a, b, depth = F(0), F(1, 4), F(1, 16)
        self.assertEqual((b + depth) - (a + depth), b - a)

    def test_axial_endpoint_impulse_injects_stretch_velocity(self):
        # m=2, each endpoint mass=1. Incoming vA=vB=-1, contact u=0.
        va = vb = F(-1)
        old_inverse_effective_mass = F(1)
        old_impulse = -va / old_inverse_effective_mass
        self.assertEqual(vb - (va + old_impulse), F(-1))
        knn, ktt, knt = matrix(F(2), F(1, 2), F(1, 2), F(0), F(1), F(0))
        impulse, _ = solve(knn, ktt, knt, F(-1), F(0), F(1), F(0))
        self.assertEqual(impulse, F(2))
        self.assertEqual(va + impulse / 2, F(0))
        self.assertEqual(vb + impulse / 2, F(0))

    def test_oblique_matrix_is_positive_definite(self):
        mass, inertia = F(2), F(1, 2)
        rx, ry, nx, ny = F(0), F(-1, 3), F(3, 5), F(4, 5)
        knn, ktt, knt = matrix(mass, inertia, rx, ry, nx, ny)
        self.assertGreater(knn, 0)
        self.assertGreater(knn * ktt - knt * knt, 0)
        self.assertEqual(knn * ktt - knt * knt,
                         1 / mass * (1 / mass + (rx * rx + ry * ry) / inertia))

    def test_coupled_normal_tangent_targets(self):
        knn, ktt, knt = matrix(F(2), F(1, 2), F(0), F(-1, 3), F(3, 5), F(4, 5))
        vn, vt, retention = F(-1), F(2, 5), F(1, 10)
        jn, jt = solve(knn, ktt, knt, vn, vt, retention, F(0))
        self.assertGreaterEqual(jn, 0)
        self.assertEqual(vn + knn * jn + knt * jt, F(0))
        self.assertEqual(vt + knt * jn + ktt * jt,
                         retention * (vt + knt * (-vn / knn)))

    def test_separating_frictionless_contact_does_not_pull(self):
        knn, ktt, knt = matrix(F(2), F(1, 2), F(0), F(-1, 3), F(3, 5), F(4, 5))
        jn, jt = solve(knn, ktt, knt, F(1), F(0), F(1), F(0))
        self.assertEqual((jn, jt), (F(0), F(0)))

    def test_normal_only_oblique_row_has_zero_tangent_impulse(self):
        knn, ktt, knt = F(3, 2), F(3, 2), F(1, 2)
        jn, jt = solve(knn, ktt, knt, F(-1, 10), F(-1), F(1), F(0))
        self.assertEqual(jt, F(0))
        self.assertEqual(jn, F(1, 15))

    def test_preserving_prenormal_tangent_can_inject_energy(self):
        # K=[[3/2,1/2],[1/2,3/2]]: a valid endpoint rigid-body mass matrix.
        # K^-1=[[3/4,-1/4],[-1/4,3/4]]. Incorrectly holding vt=-1 fixed
        # while removing incoming vn=-.1 raises contact-mode kinetic energy.
        vn, vt = F(-1, 10), F(-1)
        before = (F(3, 4) * (vn * vn + vt * vt) - F(1, 2) * vn * vt) / 2
        incorrect_after = F(3, 8)
        self.assertGreater(incorrect_after, before)

    def test_postnormal_tangent_target_removes_energy(self):
        knn, ktt, knt = F(3, 2), F(3, 2), F(1, 2)
        vn, vt = F(-1, 10), F(-1)
        for retention in [F(0), F(1, 10), F(1)]:
            jn, jt = solve(knn, ktt, knt, vn, vt, retention, F(0))
            work = jn * vn + jt * vt + (knn * jn * jn + 2 * knt * jn * jt + ktt * jt * jt) / 2
            self.assertLessEqual(work, 0)

    def test_slug_spawn_has_nonzero_gravity_moment(self):
        # Data-derived static geometry, NOT a time-domain posture prediction.
        preset = json.loads((ROOT / 'data/creatures/preset_slug.json').read_text())
        self.assertEqual([p['axis'] for p in preset['parts']], ['RIGHT', 'DOWN', 'DOWN'])
        fields = dict(re.findall(r'^(physics_\w+) = (-?[0-9.]+)$',
                                 (ROOT / 'core/tuning.tres').read_text(), re.M))
        v = lambda key: F(fields['physics_' + key])
        head = v('head_length_wu') * v('head_mass_per_wu')
        motor = v('joint_length_wu') * v('motor_mass_per_wu')
        foot = v('foot_length_wu') * v('grip_mass_per_wu')
        total = head + motor + foot
        contact_x = v('head_length_wu')
        weighted_x = head * contact_x / 2 + (motor + foot) * contact_x
        moment = (contact_x * total - weighted_x) * abs(v('gravity_wu_s2'))
        self.assertEqual(total, F(31, 20))
        self.assertEqual(moment, F(3773, 1000))
        self.assertGreater(moment, 0)

    def test_candidate_has_no_production_callsite(self):
        for p in (ROOT / 'core').rglob('*.gd'):
            self.assertNotIn('rigid_contact_candidate', p.read_text())
        source = (ROOT / 'tests/physics_fix/rigid_contact_candidate.gd').read_text()
        self.assertIn('jn = 0.0', source)
        self.assertIn('PlanarBasis.spin(shadow, spin)', source)
        self.assertIn('body.restore(shadow.snapshot())', source)

    def test_existing_sleep_and_tuning_not_replaced(self):
        sleep = (ROOT / 'core/sim/creature_sleep.gd').read_text()
        self.assertIn('net >= _tuning.sleep_still_displacement_wu', sleep)
        self.assertIn('still_ticks == _tuning.sleep_dwell_ticks', sleep)
        tuning = (ROOT / 'core/tuning.tres').read_text()
        self.assertIn('sleep_still_displacement_wu = 0.001', tuning)
        self.assertIn('sleep_dwell_ticks = 30', tuning)
        self.assertIn('physics_contact_slop_wu = 0.02', tuning)


if __name__ == '__main__': unittest.main(verbosity=2)
