#!/usr/bin/env python3
"""Packaging-only tests, separate from the 232 historical review controls."""
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import source_provenance as provenance


class ZipProvenance(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        (self.root / 'core').mkdir()
        (self.root / 'core/tuning.tres').write_bytes(b'tuning')
        (self.root / 'core/code.gd').write_bytes(b'code')
        self.manifest = self.root / 'source_manifest.json'
        self.manifest.write_text(json.dumps(dict(source_commit='pinned',
            tuning_sha256=provenance.hashlib.sha256(b'tuning').hexdigest(),
            core_tree_sha256=provenance.tree_sha256(self.root))))
        self.root_patch = patch.object(provenance, 'ROOT', self.root)
        self.manifest_patch = patch.object(provenance, 'MANIFEST', self.manifest)
        self.root_patch.start()
        self.manifest_patch.start()
        self.addCleanup(self.root_patch.stop)
        self.addCleanup(self.manifest_patch.stop)
        # The function's default root was bound at definition; select scratch root.
        original = provenance.tree_sha256
        tree_patch = patch.object(provenance, 'tree_sha256', lambda: original(self.root))
        tree_patch.start()
        self.addCleanup(tree_patch.stop)

    def test_clean(self):
        self.assertEqual(provenance.verify()['source_commit'], 'pinned')

    def test_edit(self):
        (self.root / 'core/code.gd').write_bytes(b'changed')
        with self.assertRaises(ValueError): provenance.verify()

    def test_add(self):
        (self.root / 'core/extra.gd').write_bytes(b'extra')
        with self.assertRaises(ValueError): provenance.verify()

    def test_delete(self):
        (self.root / 'core/code.gd').unlink()
        with self.assertRaises(ValueError): provenance.verify()

    def test_rename(self):
        (self.root / 'core/code.gd').rename(self.root / 'core/renamed.gd')
        with self.assertRaises(ValueError): provenance.verify()

    def test_symlink(self):
        (self.root / 'core/link').symlink_to('code.gd')
        with self.assertRaises(ValueError): provenance.verify()

    def test_tuning_field_independently_verified(self):
        manifest = json.loads(self.manifest.read_text())
        manifest['tuning_sha256'] = 'wrong'
        self.manifest.write_text(json.dumps(manifest))
        with self.assertRaises(ValueError): provenance.verify()

    def test_editor_uid_sidecar_is_not_source(self):
        (self.root / 'core/code.gd.uid').write_text('uid://generated')
        self.assertEqual(provenance.verify()['source_commit'], 'pinned')

    def test_orphan_uid_is_rejected(self):
        (self.root / 'core/orphan.gd.uid').write_text('uid://orphan')
        with self.assertRaises(ValueError): provenance.verify()

    def test_missing_manifest(self):
        self.manifest.unlink()
        with self.assertRaises(FileNotFoundError): provenance.verify()


if __name__ == '__main__':
    unittest.main(verbosity=2)
