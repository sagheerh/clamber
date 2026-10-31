"""Independent exact-rational constitutive evidence. NOT native or world proof."""
import unittest

from test_articulated_mobility_analysis import F, dot, energy, frame, project, slug


def momentum(bodies, velocity):
    return [sum(m * velocity[3*i+d] for i, (_, _, m) in enumerate(bodies)) for d in [0, 1]]


def constitutive(bodies, parents, velocity, damping):
    if damping == 0:
        return velocity[:]
    weights, rows, gram = frame(bodies, parents)
    constrained = project(weights, rows, gram, velocity)
    mass = sum(m for _, _, m in bodies)
    com = [p/mass for p in momentum(bodies, velocity)]
    return [(com[d % 3] if d % 3 != 2 else F(0)) + (1-damping) * (v-(com[d % 3] if d % 3 != 2 else 0)) for d, v in enumerate(constrained)]


class AssemblyDragAnalysis(unittest.TestCase):
    def setUp(self):
        self.b = slug()
        self.w, self.h, self.g = frame(self.b, [-1, 0, 1])
        m = sum(m for _, _, m in self.b)
        cx, cy = [sum(m*(a[d]+z[d])/2 for a, z, m in self.b)/m for d in [0, 1]]
        self.v = []
        for a, z, _ in self.b:
            self.v += [F(1,8)-((a[1]+z[1])/2-cy), -F(1,4)+((a[0]+z[0])/2-cx), F(1)]

    def test_old_independent_spin_target_is_undone_by_hinges(self):
        free = [v if i % 3 != 2 else F(1,5) for i, v in enumerate(self.v)]
        old = project(self.w, self.h, self.g, free)
        self.assertGreater(old[5], F(3,4))
        self.assertNotEqual(old[5], F(1,5))

    def test_new_fraction_is_retained_on_all_angular_dofs(self):
        result = constitutive(self.b, [-1,0,1], self.v, F(4,5))
        self.assertEqual(result[2::3], [F(1,5)]*3)
        self.assertEqual([dot(h, result) for h in self.h], [0]*4)

    def test_com_momentum_is_not_damped_or_erased(self):
        result = constitutive(self.b, [-1,0,1], self.v, F(4,5))
        self.assertEqual(momentum(self.b, self.v), momentum(self.b, result))

    def test_full_composite_projection_and_drag_are_passive(self):
        for velocity in [self.v, [F(i-4,13) for i in range(9)], [F((-1)**i,7) for i in range(9)]]:
            result = constitutive(self.b, [-1,0,1], velocity, F(4,5))
            self.assertLessEqual(energy(self.w, result), energy(self.w, velocity))
            self.assertEqual([dot(h, result) for h in self.h], [0]*4)

    def test_pure_translation_and_disabled_drag_are_identity(self):
        v = [F(1,8), -F(1,4), F(0)]*3
        self.assertEqual(constitutive(self.b, [-1,0,1], v, F(4,5)), v)
        self.assertEqual(constitutive(self.b, [-1,0,1], self.v, F(0)), self.v)

    def test_full_angular_damping_leaves_global_translation(self):
        result = constitutive(self.b, [-1,0,1], self.v, F(1))
        self.assertEqual(result, [F(1,8), -F(1,4), F(0)]*3)


if __name__ == '__main__':
    unittest.main(verbosity=2)
