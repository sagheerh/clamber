#!/usr/bin/env python3
"""Synthetic inspector tests; never presented as validation of an actual Android build."""
import struct
import tempfile
import unittest
import zipfile
from pathlib import Path

from inspect_android import check_elf, check_manifest, inspect

MANIFEST = '''<manifest xmlns:android="http://schemas.android.com/apk/res/android"
package="org.clamber.game"><uses-sdk android:minSdkVersion="26" android:targetSdkVersion="36"/>
<application android:debuggable="true"><activity android:screenOrientation="portrait"/>
</application></manifest>'''


def elf(alignment=16384, address=0, machine=183):
    data = bytearray(120)
    data[:6] = b'\x7fELF\x02\x01'
    struct.pack_into('<H', data, 18, machine)
    struct.pack_into('<Q', data, 32, 64)
    struct.pack_into('<HH', data, 54, 56, 1)
    struct.pack_into('<IIQQQQQQ', data, 64, 1, 0, 0, address, 0, 0, 0, alignment)
    return data


class AndroidInspectorTests(unittest.TestCase):
    def test_valid_elf(self):
        self.assertEqual(check_elf(elf()), 1)

    def test_under_aligned_elf(self):
        with self.assertRaises(ValueError):
            check_elf(elf(alignment=4096))

    def test_incongruent_elf(self):
        with self.assertRaises(ValueError):
            check_elf(elf(address=4096))

    def test_wrong_machine(self):
        with self.assertRaises(ValueError):
            check_elf(elf(machine=62))

    def test_truncated_elf(self):
        with self.assertRaises(ValueError):
            check_elf(elf()[:80])

    def test_manifest(self):
        self.assertEqual(check_manifest(MANIFEST)['target_sdk'], 36)
        for invalid in [MANIFEST.replace('"26"', '"24"'),
                        MANIFEST.replace('"36"', '"35"'),
                        MANIFEST.replace('portrait', 'landscape'),
                        MANIFEST.replace('debuggable="true"', 'debuggable="false"'),
                        MANIFEST.replace('<application', '<uses-permission android:name="android.permission.INTERNET"/><application')]:
            with self.subTest(invalid=invalid), self.assertRaises(ValueError):
                check_manifest(invalid)

    def test_archives_and_bundle_config(self):
        with tempfile.TemporaryDirectory() as folder:
            aab, apk = Path(folder) / 'test.aab', Path(folder) / 'test.apk'
            for path, prefix in [(aab, 'base/lib/'), (apk, 'lib/')]:
                with zipfile.ZipFile(path, 'w') as archive:
                    archive.writestr(prefix + 'arm64-v8a/libgodot.so', elf())
            result = inspect(aab, apk, MANIFEST, 'PAGE_ALIGNMENT_16K')
            self.assertEqual(result['device_frame_timing'], 'NOT MEASURED')
            with self.assertRaises(ValueError):
                inspect(aab, apk, MANIFEST, 'PAGE_ALIGNMENT_4K')
            with zipfile.ZipFile(apk, 'a') as archive:
                archive.writestr('lib/x86_64/unexpected.so', elf())
            with self.assertRaises(ValueError):
                inspect(aab, apk, MANIFEST, 'PAGE_ALIGNMENT_16K')


if __name__ == '__main__':
    unittest.main(verbosity=2)
