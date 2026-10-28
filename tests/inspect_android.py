#!/usr/bin/env python3
"""Fail-closed offline inspection of an AAB and its bundletool-produced APK."""
import json
import struct
import sys
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path

ANDROID = '{http://schemas.android.com/apk/res/android}'
PAGE_SIZE = 16384


def check_elf(data):
    if len(data) < 64 or data[:6] != b'\x7fELF\x02\x01':
        raise ValueError('Expected little-endian ELF64')
    if struct.unpack_from('<H', data, 18)[0] != 183:
        raise ValueError('Expected AArch64 machine')
    phoff = struct.unpack_from('<Q', data, 32)[0]
    phentsize, phnum = struct.unpack_from('<HH', data, 54)
    if phentsize < 56 or not phnum or phoff + phentsize * phnum > len(data):
        raise ValueError('Invalid ELF program headers')
    loads = 0
    for index in range(phnum):
        kind, _, offset, address, _, _, _, alignment = struct.unpack_from(
            '<IIQQQQQQ', data, phoff + index * phentsize)
        if kind == 1:  # PT_LOAD
            loads += 1
            if alignment < PAGE_SIZE or alignment & (alignment - 1):
                raise ValueError('PT_LOAD is not at least 16 KB aligned')
            if offset % PAGE_SIZE != address % PAGE_SIZE:
                raise ValueError('PT_LOAD offset/address incongruent at 16 KB')
    if not loads:
        raise ValueError('No PT_LOAD segments')
    return loads


def check_archive(path, prefix):
    result = {}
    with zipfile.ZipFile(path) as archive:
        libraries = [name for name in archive.namelist()
                     if name.startswith(prefix) and name.endswith('.so')]
        if not libraries:
            raise ValueError('No packaged native libraries')
        for name in libraries:
            if name.split('/')[len(prefix.rstrip('/').split('/'))] != 'arm64-v8a':
                raise ValueError('Unexpected ABI: ' + name)
            result[name] = check_elf(archive.read(name))
    return result


def check_manifest(text):
    manifest = ET.fromstring(text)
    if manifest.attrib.get('package') != 'org.clamber.game':
        raise ValueError('Unexpected package')
    sdk = manifest.find('uses-sdk')
    if sdk is None or int(sdk.attrib[ANDROID + 'minSdkVersion'], 0) != 26:
        raise ValueError('minSdk must be 26')
    if int(sdk.attrib[ANDROID + 'targetSdkVersion'], 0) != 36:
        raise ValueError('targetSdk must be 36')
    orientations = [node.attrib.get(ANDROID + 'screenOrientation')
                    for node in manifest.iter('activity')]
    if 'portrait' not in orientations:
        raise ValueError('Portrait activity missing')
    permissions = [node.attrib.get(ANDROID + 'name')
                   for node in manifest.findall('uses-permission')]
    if any(name in permissions for name in [
            'android.permission.INTERNET', 'android.permission.ACCESS_NETWORK_STATE']):
        raise ValueError('Unexpected network permission')
    application = manifest.find('application')
    if application is None or application.attrib.get(ANDROID + 'debuggable') != 'true':
        raise ValueError('Expected a debug build')
    return {'package': 'org.clamber.game', 'min_sdk': 26, 'target_sdk': 36,
            'orientation': 'portrait', 'debuggable': True, 'network_permissions': False}


def inspect(aab, apk, manifest, config):
    if 'PAGE_ALIGNMENT_16K' not in config:
        raise ValueError('Bundle config does not request 16 KB APK alignment')
    return {'manifest': check_manifest(manifest),
            'aab_native_load_segments': check_archive(aab, 'base/lib/'),
            'apk_native_load_segments': check_archive(apk, 'lib/'),
            'bundle_page_alignment': '16KB',
            'device_installation': 'NOT MEASURED', 'device_frame_timing': 'NOT MEASURED'}


if __name__ == '__main__':
    try:
        report = inspect(sys.argv[1], sys.argv[2], Path(sys.argv[3]).read_text(),
                         Path(sys.argv[4]).read_text())
        print(json.dumps(report, indent=2, sort_keys=True))
    except (ValueError, KeyError, OSError, struct.error, ET.ParseError, zipfile.BadZipFile) as error:
        print('::error title=M0 Android inspection::' + str(error))
        raise SystemExit(1) from error
