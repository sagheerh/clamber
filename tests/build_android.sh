#!/usr/bin/env bash
# Requires exact installed Godot/export templates, JDK17 and Android SDK36.
set -euo pipefail
cd "$(dirname "$0")/.."
: "${GODOT:?Set GODOT to the pinned 4.7.2-stable executable}"
: "${ANDROID_HOME:?Set ANDROID_HOME}"
: "${JAVA_HOME:?Set JAVA_HOME to JDK17}"
case "$("$GODOT" --version)" in 4.7.2.stable*) ;; *) exit 1 ;; esac
mkdir -p exports
"$GODOT" --headless --editor --import
# The clean editor import creates the version-specific EditorSettings resource.
python3 - <<'PYSETTINGS'
import json, os, re
from pathlib import Path
config = Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config"))) / "godot"
files = list(config.glob("editor_settings-*.tres"))
if len(files) != 1:
    raise SystemExit(f"Expected one clean editor settings resource, found {files}")
path = files[0]
text = path.read_text()
for key, env in [("export/android/android_sdk_path", "ANDROID_HOME"),
                 ("export/android/java_sdk_path", "JAVA_HOME")]:
    line = key + " = " + json.dumps(os.environ[env])
    pattern = r"^" + re.escape(key) + r" = .*?$"
    if re.search(pattern, text, re.M):
        text = re.sub(pattern, lambda _: line, text, flags=re.M)
    else:
        text += "\n" + line + "\n"
path.write_text(text)
PYSETTINGS
"$GODOT" --headless --verbose --editor --install-android-build-template --export-debug Android exports/clamber-debug.aab 2>&1 | tee exports/android-export.log
test -s exports/clamber-debug.aab
sha256sum exports/clamber-debug.aab | tee exports/aab-sha256.txt
