#!/usr/bin/env python3
"""Exact-rational network algebra + source controls, NOT GDScript or world execution."""
from fractions import Fraction as F
from pathlib import Path
import math
import gzip
import json
import hashlib
import unittest

ROOT = Path(__file__).resolve().parents[1]


def dot(a, b):
    return sum(x*y for x, y in zip(a, b))


def frame(bodies, parents):
    weights, rows = [], []
    for a, b, mass in bodies:
        dx, dy = b[0]-a[0], b[1]-a[1]
        weights += [1/mass, 1/mass, 4/(mass*(dx*dx+dy*dy))]
    for child in range(1, len(bodies)):
        parent = parents[child]
        a, b, _ = bodies[parent]
        c, d, _ = bodies[child]
        x, y = [F(0)]*len(weights), [F(0)]*len(weights)
        x[3*parent], x[3*child] = -F(1), F(1)
        x[3*parent+2], x[3*child+2] = (b[1]-a[1])/2, (d[1]-c[1])/2
        y[3*parent+1], y[3*child+1] = -F(1), F(1)
        y[3*parent+2], y[3*child+2] = -(b[0]-a[0])/2, -(d[0]-c[0])/2
        rows += [x, y]
    gram = [[sum(a*w*b for a, w, b in zip(x, weights, y)) for y in rows] for x in rows]
    return weights, rows, gram


def solve(matrix, rhs):
    # Independent exact Gaussian elimination, NOT the native Cholesky implementation.
    a = [r[:] + [v] for r, v in zip(matrix, rhs)]
    for j in range(len(a)):
        assert a[j][j] > 0  # SPD Schur complement, no epsilon/regularizer.
        for i in range(j+1, len(a)):
            multiplier = a[i][j]/a[j][j]
            a[i] = [x-multiplier*y for x, y in zip(a[i], a[j])]
    answer = [F(0)]*len(rhs)
    for i in reversed(range(len(a))):
        answer[i] = (a[i][-1]-sum(a[i][j]*answer[j] for j in range(i+1, len(a))))/a[i][i]
    return answer


def mobility(weights, rows, gram, impulse):
    free = [w*f for w, f in zip(weights, impulse)]
    reaction = solve(gram, [-dot(row, free) for row in rows])
    delta = [free[d]+weights[d]*sum(row[d]*j for row, j in zip(rows, reaction)) for d in range(len(free))]
    return delta, reaction


def project(weights, rows, gram, velocity):
    reaction = solve(gram, [-dot(row, velocity) for row in rows])
    return [velocity[d]+weights[d]*sum(row[d]*j for row, j in zip(rows, reaction)) for d in range(len(velocity))]


def contact_row(bodies, part, u, normal):
    a, b, _ = bodies[part]
    rx, ry = (u-F(1, 2))*(b[0]-a[0]), (u-F(1, 2))*(b[1]-a[1])
    x, y = normal
    row = [F(0)]*(3*len(bodies))
    row[3*part:3*part+3] = [x, y, rx*y-ry*x]
    return row


def energy(weights, velocity):
    return sum(v*v/w for v, w in zip(velocity, weights))/2


def slug():
    return [((F(0), F(0)), (F(7, 20), F(0)), F(77, 100)),
            ((F(7, 20), F(0)), (F(7, 20), -F(3, 10)), F(12, 25)),
            ((F(7, 20), -F(3, 10)), (F(7, 20), -F(11, 20)), F(3, 10))]


class ArticulatedMobilityAnalysis(unittest.TestCase):
    def setUp(self):
        self.bodies = slug()
        self.weights, self.rows, self.gram = frame(self.bodies, [-1, 0, 1])
        self.impulse = [F(0)]*9
        self.impulse[7] = F(1)

    def test_old_local_contact_reopens_hinge(self):
        # Local whole-body foot impulse STILL moves its parent anchor relative to
        # the untouched motor. Bone rigidity alone cannot fix this incompatibility.
        local = [F(0)]*9
        local[7] = 1/self.bodies[2][2]
        self.assertNotEqual([dot(r, local) for r in self.rows], [0]*4)

    def test_global_contact_increment_preserves_all_hinges(self):
        delta, _ = mobility(self.weights, self.rows, self.gram, self.impulse)
        self.assertEqual([dot(r, delta) for r in self.rows], [0]*4)
        self.assertNotEqual(delta[1], 0)

    def test_constrained_mobility_is_symmetric(self):
        other = [F(i-4, 7) for i in range(9)]
        first, _ = mobility(self.weights, self.rows, self.gram, self.impulse)
        second, _ = mobility(self.weights, self.rows, self.gram, other)
        self.assertEqual(dot(other, first), dot(self.impulse, second))

    def test_mobility_nonnegative_quadratic_form(self):
        for impulse in (self.impulse, [F(i-4, 7) for i in range(9)], [F(0)]*9):
            with self.subTest(impulse=impulse):
                delta, _ = mobility(self.weights, self.rows, self.gram, impulse)
                self.assertGreaterEqual(dot(impulse, delta), 0)

    def test_internal_projection_preserves_linear_momentum(self):
        velocity = [F(i-4, 7) for i in range(9)]
        projected = project(self.weights, self.rows, self.gram, velocity)
        for axis in (0, 1):
            self.assertEqual(sum(velocity[d]/self.weights[d] for d in range(axis, 9, 3)),
                             sum(projected[d]/self.weights[d] for d in range(axis, 9, 3)))

    def test_internal_projection_preserves_angular_momentum_at_coincident_anchors(self):
        velocity = [F(i-4, 7) for i in range(9)]
        projected = project(self.weights, self.rows, self.gram, velocity)
        def angular(v):
            total = F(0)
            for i, (a, b, mass) in enumerate(self.bodies):
                x, y = (a[0]+b[0])/2, (a[1]+b[1])/2
                total += mass*(x*v[3*i+1]-y*v[3*i])+v[3*i+2]/self.weights[3*i+2]
            return total
        self.assertEqual(angular(velocity), angular(projected))

    def test_projection_annihilates_all_hinge_residuals(self):
        velocity = [F(i-4, 7) for i in range(9)]
        projected = project(self.weights, self.rows, self.gram, velocity)
        self.assertEqual([dot(r, projected) for r in self.rows], [0]*4)
        self.assertLessEqual(energy(self.weights, projected), energy(self.weights, velocity))

    def test_projection_is_idempotent(self):
        once = project(self.weights, self.rows, self.gram, [F(i-4, 7) for i in range(9)])
        self.assertEqual(project(self.weights, self.rows, self.gram, once), once)

    def test_translation_is_not_silently_frozen(self):
        velocity = [F(1, 8), F(-1, 4), F(0)]*3
        self.assertEqual(project(self.weights, self.rows, self.gram, velocity), velocity)

    def test_single_body_reduces_to_original_rigid_mass(self):
        weights, rows, gram = frame([self.bodies[1]], [-1])
        delta, reaction = mobility(weights, rows, gram, [F(1), F(0), F(0)])
        self.assertEqual(delta, [1/self.bodies[1][2], 0, 0])
        self.assertEqual(reaction, [])

    def test_branched_tree_keeps_all_constraints(self):
        p = (F(7, 20), F(0))
        bodies = self.bodies[:2] + [(p, (F(3, 4), F(1, 5)), F(2, 5))]
        w, h, a = frame(bodies, [-1, 0, 0])
        delta, _ = mobility(w, h, a, [F(i-4, 7) for i in range(9)])
        self.assertEqual([dot(r, delta) for r in h], [0]*4)

    def test_contact_effective_matrix_positive_definite(self):
        n = contact_row(self.bodies, 2, F(1), (F(0), F(1)))
        t = contact_row(self.bodies, 2, F(1), (-F(1), F(0)))
        dn, _ = mobility(self.weights, self.rows, self.gram, n)
        dt, _ = mobility(self.weights, self.rows, self.gram, t)
        self.assertGreater(dot(n, dn), 0)
        self.assertGreater(dot(n, dn)*dot(t, dt)-dot(n, dt)**2, 0)

    def test_contact_targets_momentum_hinges_and_energy_together(self):
        n = contact_row(self.bodies, 2, F(1), (F(0), F(1)))
        t = contact_row(self.bodies, 2, F(1), (-F(1), F(0)))
        dn, _ = mobility(self.weights, self.rows, self.gram, n)
        dt, _ = mobility(self.weights, self.rows, self.gram, t)
        knn, ktt, knt = dot(n, dn), dot(t, dt), dot(n, dt)
        v = [F(0), -F(1), F(0)]*3
        vn, vt = dot(n, v), dot(t, v)
        for retention in (F(0), F(1, 10), F(1)):
            normal_only = max(F(0), -vn/knn)
            target_t = (vt+knt*normal_only)*retention
            normal_change, tangent_change = -vn, target_t-vt
            determinant = knn*ktt-knt*knt
            jn = (normal_change*ktt-tangent_change*knt)/determinant
            jt = (tangent_change*knn-normal_change*knt)/determinant
            self.assertGreaterEqual(jn, 0)
            after = [x+a*jn+b*jt for x, a, b in zip(v, dn, dt)]
            self.assertEqual(dot(n, after), 0)
            self.assertEqual(dot(t, after), target_t)
            self.assertEqual([dot(r, after) for r in self.rows], [0]*4)
            self.assertLessEqual(energy(self.weights, after), energy(self.weights, v))
            self.assertEqual(sum((after[d]-v[d])/self.weights[d] for d in range(1, 9, 3)), jn)

    def test_archived_failed_frame_hinge_residual_is_projected_not_hidden(self):
        # Read-only frame algebra, NOT replaying or rerunning a historical world.
        raw = gzip.decompress((ROOT/'tests/fixtures/m1_contact_composition/36313adee194/idle-Slug.jsonl.gz').read_bytes())
        self.assertEqual(hashlib.sha256(raw).hexdigest(), '61effb30f761f90c8dc7627a2034fd6aa055975bf4e961ec88dd7efc1727ed49')
        state = json.loads(raw.splitlines()[-1])['state']['physical']['bodies']
        bodies, velocity = [], []
        for p in state:
            a, b = p['a'], p['b']
            ax, ay, bx, by = map(F, [a['x'], a['y'], b['x'], b['y']])
            dx, dy = bx-ax, by-ay
            avx, avy, bvx, bvy = map(F, [a['velocity_x'], a['velocity_y'], b['velocity_x'], b['velocity_y']])
            bodies.append(((ax, ay), (bx, by), F(p['mass'])))
            velocity += [(avx+bvx)/2, (avy+bvy)/2, (dx*(bvy-avy)-dy*(bvx-avx))/(dx*dx+dy*dy)]
        w, h, gram = frame(bodies, [-1, 0, 1])
        self.assertGreater(max(abs(dot(row, velocity)) for row in h), F(1, 10))
        projected = project(w, h, gram, velocity)
        self.assertEqual([dot(row, projected) for row in h], [0]*4)
        self.assertLessEqual(energy(w, projected), energy(w, velocity))
        # The position gaps still exist: do NOT call this a completed M1 fix.
        self.assertNotEqual(bodies[0][1], bodies[1][0])

    def test_position_contact_increment_is_in_hinge_nullspace(self):
        normal = contact_row(self.bodies, 2, F(1), (F(0), F(1)))
        delta, _ = mobility(self.weights, self.rows, self.gram, normal)
        depth = F(1, 1000)
        move = [x*depth/dot(normal, delta) for x in delta]
        self.assertEqual([dot(row, move) for row in self.rows], [0]*4)
        self.assertEqual(dot(normal, move), depth)
        # This is the LINEARIZED displacement, not exact finite-angle hinge
        # closure after rotating bodies, or a nonlinear convergence guarantee.

    def test_native_cholesky_algebra_matches_independent_exact_oracle(self):
        # Python arithmetic reproduction of the chosen factorization only.
        # This explicitly does NOT execute or semantically compile GDScript.
        matrix = [[float(x) for x in row] for row in self.gram]
        rhs = [float(i+1) for i in range(4)]
        lower = []
        for i in range(4):
            row = [0.0]*4
            for j in range(i+1):
                value = matrix[i][j]-sum(row[k]*(row[k] if i == j else lower[j][k]) for k in range(j))
                row[j] = math.sqrt(value) if i == j else value/lower[j][j]
            lower.append(row)
        result = rhs[:]
        for i in range(4):
            result[i] = (result[i]-sum(lower[i][j]*result[j] for j in range(i)))/lower[i][i]
        for i in reversed(range(4)):
            result[i] = (result[i]-sum(lower[j][i]*result[j] for j in range(i+1, 4)))/lower[i][i]
        expected = solve(self.gram, [F(i+1) for i in range(4)])
        for a, b in zip(result, expected):
            self.assertAlmostEqual(a, float(b), places=12)  # Unit arithmetic only.

    def test_production_and_old_candidate_not_selected(self):
        for p in (ROOT/'core').rglob('*.gd'):
            self.assertNotIn('articulated_mobility_candidate', p.read_text())
        self.assertNotIn('articulated_mobility_candidate', (ROOT/'tests/physics_fix/test_contact_composition.gd').read_text())

    def test_source_keeps_transaction_stale_frame_and_passivity_barriers(self):
        s = (ROOT/'tests/physics_fix/articulated_mobility_candidate.gd').read_text()
        for guard in ['_geometry(bodies[i]) != _signature[i]', 'after_energy > before_energy',
                      'physics_max_projection_wu_tick', 'bodies[j].restore(before[j])',
                      'parents[index] >= index']:
            self.assertIn(guard, s)
        self.assertNotIn('velocity_epsilon', s)
        self.assertNotIn('CreatureSleep', s)
        self.assertNotIn('physics_position_iterations =', s)


if __name__ == '__main__':
    unittest.main(verbosity=2)
