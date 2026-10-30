#!/usr/bin/env python3
"""Stage an isolated opt-in M1 lab APK; never change the normal game export.

--prepare-only performs no engine calls or physical ticks. Requires no .git.
The real build requires exact installed export templates, JDK17 and Android SDK36.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tests'))
from source_provenance import verify  # noqa: E402


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def prepare(destination):
    manifest = verify()
    destination = Path(destination).resolve()
    # Only create a NEW destination. Never overwrite or remove an existing tree.
    destination.mkdir(parents=True, exist_ok=False)
    for name in ('core', 'data'):
        shutil.copytree(ROOT / name, destination / name,
                        ignore=shutil.ignore_patterns('*.uid', '__pycache__'))
    for name in ('tests/device',):
        shutil.copytree(ROOT / name, destination / name,
                        ignore=shutil.ignore_patterns('*.uid', '__pycache__'))
    for name in ('tests/sim/r25_fixture.gd', 'ui/components/safe_area.gd',
                 'tests/fixtures/source_manifest.json'):
        target = destination / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / name, target)
    project = (ROOT / 'project.godot').read_text()
    project = project.replace('res://ui/boot.tscn', 'res://tests/device/m1_lab.tscn')
    project = project.replace('config/name="CLAMBER"', 'config/name="CLAMBER M1 Diagnostic"')
    project = project.replace('M0 engineering boot surface; no gameplay or final screens.',
                              'Opt-in manual M1 diagnostic; BLOCKED, NOT SIGNED.')
    (destination / 'project.godot').write_text(project)
    preset = (ROOT / 'export_presets.cfg').read_text()
    preset = preset.replace('gradle_build/export_format=1', 'gradle_build/export_format=0')
    preset = preset.replace('exports/clamber-debug.aab', 'exports/m1-lab.apk')
    preset = preset.replace('org.clamber.game', 'org.clamber.m1lab')
    preset = preset.replace('package/name="CLAMBER"', 'package/name="CLAMBER M1 Diagnostic"')
    preset = preset.replace('include_filter="data/creatures/preset_*.json"',
                            'include_filter="data/creatures/preset_*.json,tests/fixtures/source_manifest.json,tests/device/package_manifest.json"')
    preset = preset.replace('exclude_filter="docs/*,tests/*,.github/*,.tools/*"',
                            'exclude_filter="docs/*,.github/*,.tools/*"')
    (destination / 'export_presets.cfg').write_text(preset)
    inventory = {p.relative_to(destination).as_posix(): sha(p)
                 for p in sorted(destination.rglob('*')) if p.is_file()}
    provenance = dict(evidence_kind='manual diagnostic, NOT acceptance/CI evidence',
                      source_manifest=manifest, staged_files_sha256=inventory)
    (destination / 'device-package.json').write_text(json.dumps(provenance, indent=2) + '\n')
    (destination / 'tests/device/package_manifest.json').write_text(json.dumps(provenance, indent=2) + '\n')
    return provenance


def android_settings():
    if sys.platform == 'darwin':
        config = Path.home() / 'Library/Application Support/Godot'
    elif os.name == 'nt':
        config = Path(os.environ['APPDATA']) / 'Godot'
    else:
        config = Path(os.environ.get('XDG_CONFIG_HOME', str(Path.home() / '.config'))) / 'godot'
    settings = config / 'editor_settings-4.7.tres'
    if not settings.exists():
        raise RuntimeError(f'Pinned editor settings not found: {settings}; configure Android paths in Godot 4.7.2 first')
    text = settings.read_text()
    for key, name in [('export/android/android_sdk_path', 'ANDROID_HOME'),
                      ('export/android/java_sdk_path', 'JAVA_HOME')]:
        value = Path(os.environ[name]).resolve()
        if not value.is_dir():
            raise ValueError(f'{name} is not a directory: {value}')
        line = key + ' = ' + json.dumps(str(value))
        pattern = r'^' + re.escape(key) + r' = .*?$'
        text = re.sub(pattern, lambda _: line, text, flags=re.M) if re.search(pattern, text, re.M) else text + '\n' + line + '\n'
    settings.write_text(text)


def build(stage, output, godot):
    version = subprocess.check_output([godot, '--version'], text=True).strip()
    if version != '4.7.2.stable.official.ed1daf0bf':
        raise ValueError(f'Expected exact pinned Godot, got {version}')
    if output.exists():
        raise ValueError(f'Refusing to overwrite existing APK: {output}')
    output.parent.mkdir(parents=True, exist_ok=True)
    for name, args in [('import', ['--import']), ('export', [
            '--verbose', '--install-android-build-template', '--export-debug', 'Android', str(output)])]:
        if name == 'export':
            android_settings()
        with output.with_suffix(f'.{name}.log').open('w') as log:
            code = subprocess.call([godot, '--headless', '--editor', '--path', str(stage), *args],
                                   stdout=log, stderr=subprocess.STDOUT)
        text = output.with_suffix(f'.{name}.log').read_text()
        if code or re.search(r'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script', text):
            raise RuntimeError(f'{name} failed; retain {output.with_suffix(f".{name}.log")}')
    if not output.is_file() or not output.stat().st_size:
        raise RuntimeError('Export returned without an APK')
    output.with_suffix('.sha256').write_text(sha(output) + '  ' + output.name + '\n')
    shutil.copy2(stage / 'device-package.json', output.with_suffix('.source.json'))
    output.with_suffix('.engine.txt').write_text(version + '\n')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--prepare-only', action='store_true')
    parser.add_argument('--output', type=Path, default=ROOT / 'exports/m1-lab.apk')
    args = parser.parse_args()
    parent = ROOT / '.tools'
    parent.mkdir(exist_ok=True)
    # mkdtemp creates a reserved outer directory; stage itself must be new.
    stage = Path(tempfile.mkdtemp(prefix='m1-device-', dir=parent)) / 'project'
    prepare(stage)
    print(f'Isolated diagnostic project: {stage}', flush=True)
    if not args.prepare_only:
        build(stage, args.output.resolve(), os.environ['GODOT'])
        print(f'APK: {args.output.resolve()} (not installed; no device test performed)')


if __name__ == '__main__':
    try:
        main()
    except Exception as exc:
        sys.exit(str(exc))
