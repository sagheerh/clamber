#!/usr/bin/env python3
"""Packaging/static lab contracts only: not Android or physics evidence."""
import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('device_build', ROOT / 'scripts/build_m1_device.py')
builder = importlib.util.module_from_spec(spec)
spec.loader.exec_module(builder)


class DevicePackageTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.stage = Path(self.temp.name) / 'project'

    def test_isolated_main_and_apk_package(self):
        before = (ROOT / 'project.godot').read_bytes()
        builder.prepare(self.stage)
        self.assertIn('res://tests/device/m1_lab.tscn', (self.stage / 'project.godot').read_text())
        self.assertEqual((ROOT / 'project.godot').read_bytes(), before)
        preset = (self.stage / 'export_presets.cfg').read_text()
        self.assertIn('org.clamber.m1lab', preset)
        self.assertIn('gradle_build/export_format=0', preset)
        self.assertIn('permissions/internet=false', preset)
        self.assertNotIn('tests/*', preset)

    def test_exact_core_and_fixture_bytes(self):
        builder.prepare(self.stage)
        for p in (ROOT / 'core').rglob('*'):
            if p.is_file() and not p.name.endswith('.uid'):
                self.assertEqual(p.read_bytes(), (self.stage / p.relative_to(ROOT)).read_bytes())
        self.assertEqual((self.stage / 'tests/sim/r25_fixture.gd').read_bytes(),
                         (ROOT / 'tests/sim/r25_fixture.gd').read_bytes())

    def test_no_acceptance_runners_in_staging(self):
        builder.prepare(self.stage)
        self.assertFalse((self.stage / 'tests/sim/test_r29.gd').exists())
        self.assertFalse((self.stage / '.git').exists())
        self.assertFalse((self.stage / '.review').exists())

    def test_inventory_hashes_actual_staged_sources(self):
        result = builder.prepare(self.stage)
        for name, expected in result['staged_files_sha256'].items():
            self.assertEqual(hashlib.sha256((self.stage / name).read_bytes()).hexdigest(), expected)
        self.assertIn('tests/fixtures/source_manifest.json', result['staged_files_sha256'])
        self.assertIn('tests/device/m1_lab.gd', result['staged_files_sha256'])

    def test_existing_destination_never_overwritten(self):
        self.stage.mkdir()
        with self.assertRaises(FileExistsError): builder.prepare(self.stage)

    def test_failed_provenance_prevents_staging(self):
        with patch.object(builder, 'verify', side_effect=ValueError('manifest mismatch')):
            with self.assertRaises(ValueError): builder.prepare(self.stage)
        self.assertFalse(self.stage.exists())

    def test_wrong_engine_rejected_before_build(self):
        with patch.object(builder.subprocess, 'check_output', return_value='wrong'), \
             patch.object(builder.subprocess, 'call') as engine:
            with self.assertRaises(ValueError):
                builder.build(self.stage, Path(self.temp.name) / 'lab.apk', 'not-a-real-engine')
            engine.assert_not_called()

    def test_normal_export_still_excludes_tests(self):
        self.assertIn('tests/*', (ROOT / 'export_presets.cfg').read_text())
        self.assertIn('res://ui/boot.tscn', (ROOT / 'project.godot').read_text())

    def test_view_is_fixed_collision_diagram(self):
        source = (ROOT / 'tests/device/m1_view.gd').read_text()
        self.assertIn('PIXELS_PER_WU := 150.0', source)
        self.assertIn('body.radius', source)
        self.assertNotIn('Camera2D.new', source)
        self.assertNotIn('art_', source)

    def test_input_is_held_and_release_cleared_on_pause(self):
        source = (ROOT / 'tests/device/m1_lab.gd').read_text()
        self.assertIn('_sim.advance_frame(delta, _mask)', source)
        self.assertIn('_sim.tick_completed.connect(_record_tick)', source)
        self.assertIn('NOTIFICATION_APPLICATION_FOCUS_OUT', source)
        self.assertNotIn('Input.is_', source)


if __name__ == '__main__': unittest.main(verbosity=2)
