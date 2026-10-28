#!/usr/bin/env python3
"""Known-source invariants only. Does not invent the missing review-pack INV mapping."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PHYSICS_NODES = r'\b(?:RigidBody2D|Joint2D|PinJoint2D|DampedSpringJoint2D)\b'


def code_only(text):
    # Match triple strings first, then ordinary quoted strings/comments.
    return re.sub(r'"""[\s\S]*?"""|\'\'\'[\s\S]*?\'\'\'|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'|#[^\n]*', '', text)


def violations(text, path):
    code = code_only(text)
    problems = []
    if path.endswith('.tscn'):
        without_comments = re.sub(r'^\s*;.*$', '', text, flags=re.M)
        if re.search(r'type="(?:RigidBody2D|Joint2D|PinJoint2D|DampedSpringJoint2D)"', without_comments):
            problems.append('engine physics node')
    elif re.search(PHYSICS_NODES, code):
        problems.append('engine physics node')
    if path.startswith('core/') and path.endswith('.gd'):
        if re.search(r'res://(?:ui|platform)/', text):
            problems.append('core UI/platform dependency')
        if re.search(r'(?<![\w])(?:0[xX][\da-fA-F]+|\d+(?:\.\d*)?)', code):
            problems.append('numeric literal outside tuning')
    if path.startswith(('core/sim/', 'core/run/', 'core/tower/')) and path.endswith('.gd'):
        forbidden = {
            'global/engine RNG': r'\b(?:randf|randfn|randi|randomize|seed|randf_range|randi_range)\s*\(',
            'unseeded engine RNG': r'\bRandomNumberGenerator\b',
            'wall clock': r'\bTime\s*\.\s*get_ticks_\w*\s*\(',
            'engine frame count': r'\bEngine\s*\.\s*get_physics_frames\s*\(',
            'frame callback/raw delta': r'\b(?:_process|_physics_process|delta)\b',
            'solver transcendental': r'\b(?:sin|cos|tan|pow|exp|atan2)\s*\(',
        }
        for name, pattern in forbidden.items():
            if re.search(pattern, code):
                problems.append(name)
    return problems


def scan(root):
    findings = []
    count = 0
    for folder in ('core', 'ui', 'platform', 'tests'):
        for path in sorted((root / folder).rglob('*')):
            if path.suffix not in ('.gd', '.tscn'):
                continue
            count += 1
            relative = path.relative_to(root).as_posix()
            findings.extend(f'{relative}: {message}' for message in violations(path.read_text(), relative))
    project = (root / 'project.godot').read_text()
    if 'engine_version="4.7.2-stable"' not in project:
        findings.append('engine pin must remain 4.7.2-stable')
    autoload = re.search(r'^\[autoload\]\s*(.*?)(?=^\[|\Z)', project, re.M | re.S)
    if autoload:
        entries = re.findall(r'^\s*([^;\s=]+)\s*=', autoload[1], re.M)
        if len(entries) > 1 or (entries and entries != ['App']):
            findings.append('only one optional App autoload allowed')
    return count, findings


if __name__ == '__main__':
    files, errors = scan(ROOT)
    for error in errors:
        print('FAIL: ' + error)
    if errors:
        raise SystemExit(1)
    print(f'PASS: {files} GDScript/scene files scanned; known static invariant subset clean.')
    print('PASS: A9.1 static restrictions; A9.6 math scan; exact engine pin; tuning/core boundaries.')
    print('NOTE: passing scans of current stubs do not prove an implemented solver or injected RNG.')
