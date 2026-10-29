# M0 device gate — blue-screen report and next evidence steps

**User report:** installed the debug app on a phone, opened it, and saw only a blue screen with nothing else.

## 1. Is that expected?

**If it is a very dark navy / almost-black blue (`#00192F`) → YES, expected for M0.**

Evidence from the CI-tested branch `arena/f08ed236-clamber` at `ba7179b`:

- `ui/boot.tscn` contains only a root `Control` plus a `SafeArea` `MarginContainer`; there is no logo, label, button, menu, or gameplay node.
- `ui/theme/tokens.gd:7` defines `NAVY_900 = Color("00192f")`.
- `ui/boot.gd:17` calls `RenderingServer.set_default_clear_color(TOKENS.NAVY_900)` in `_ready()`.
- `project.godot:31` sets `environment/defaults/default_clear_color=Color(0, 0.098039216, 0.184313725, 1)`, which is the same `#00192F`.
- `PROGRESS.md` and `DECISIONS.md M0-D01` explicitly say M0 is an engineering-only navy boot surface and that no S00–S16 screens or gameplay exist.

So "sirf dark blue screen, kuch bhi nahi" is the intended M0 result. The actual game screens arrive in later milestones.

**If it is bright sky blue (`#46B0E4`), light blue, or a blue gradient/logo → NOT expected; treat it as a bug.**  
`project.godot` does **not** set `application/boot_splash/bg_color`. Godot 4.7.2's generated default is neutral gray `Color(0.14, 0.14, 0.14)` (`main/main_builders.py:14`), but an Android window/theme or splash setting could still produce a different early color. Ask the coding agent to set:

```ini
[application]
boot_splash/bg_color = Color("00192f")
boot_splash/show_image = false
```

and re-export, then verify with a fresh screenshot. Do not accept a bright blue screen as "the palette".

## 2. The verbal report is not yet evidence

Per `CLAMBER_REVIEW_AGENT.md:54` (E4) and M0 checklist `:249`, the device gate needs an artifact. The user's message alone cannot close F1 from the R2 review. Capture and send all of the following.

### Minimum artifact set
1. **Screenshot** of the launched app with device date/time visible in the status bar (satisfies "device date visible"), showing the solid navy screen. If possible also show `Settings → Apps → CLAMBER` version `0.0.0`.
2. **Hardware identity:** phone model, Android version/API, GPU/SoC, screen refresh rate, ABI (`arm64-v8a`).
3. **Install proof:** which APK/AAB-derived artifact was installed, its SHA256, and `adb install` output if available.
4. **Launch proof:** `adb shell monkey -p org.clamber.game -c android.intent.category.LAUNCHER 1` output, or a short screen recording.
5. **Lifecycle:** home → recent apps → return; screen lock → unlock → return. Record no crash, no black screen, and that the navy surface returns.
6. **Safe area / orientation:** portrait lock, status bar/cutout/gesture bar behavior; note if the device has a notch or punch-hole.
7. **Frame timing:** a real capture, not the `Engine.max_fps = 60` cap. Record P95 frame time and whether it meets ≤ 16.6 ms on the reference-class hardware named in `docs/validation/M0.md`.

### Useful adb commands
```sh
adb devices
adb install -r clamber-debug-universal.apk
sha256sum clamber-debug-universal.apk
adb shell monkey -p org.clamber.game -c android.intent.category.LAUNCHER 1
adb shell screencap -p /sdcard/m0_boot.png
adb pull /sdcard/m0_boot.png
adb shell dumpsys package org.clamber.game | grep -E 'versionName|targetSdk|versionCode'
adb shell dumpsys display | grep -i refresh
# After ~30 seconds on the boot screen:
adb shell dumpsys gfxinfo org.clamber.game framestats > m0_gfxinfo.txt
```

## 3. What to tell the coding agent now

```text
Device update: I installed and launched the M0 debug build on a physical phone.
The app opens to a solid screen and shows no UI, logo, menu, or gameplay.

Please confirm the expected color. From the code, M0 should show dark navy #00192F
(NAVY_900), not bright sky blue #46B0E4. I am attaching a screenshot with the
device date/time visible. If the screenshot is bright blue or light blue, treat
that as a display/boot-splash bug, set application/boot_splash/bg_color to
#00192F (and show_image=false), re-export, and give me a new artifact to retest.
If it is dark navy, confirm that this is the intended M0 engineering boot surface.

I am also collecting: device model/Android API/GPU/refresh rate/ABI, APK SHA256,
adb install + launch output, lifecycle (home/resume/lock/unlock), safe-area/
portrait/cutout observations, and a gfxinfo/Perfetto frame-time capture with
measured P95. I will send those next.

Until that evidence is recorded in docs/validation/M0.md, keep M0 status
REJECT / INCOMPLETE. Do not claim 60 fps from the Engine.max_fps cap, do not
start M1, and do not change tuning or gameplay. The camera zoom conflict
(0.75 §2.3 / 0.72 §4.8) still needs my decision before M2.
```

## 4. Human decision still needed

- If the captured screen is dark navy and the remaining evidence is collected, F1 can be closed in R3 and M0 can be approved (subject to the R2 F2–F4 review-pack fixes).
- If it is bright blue, add a fix item for the boot-splash/window color before approving.
- The camera zoom conflict remains a GDD-owner decision; do not let the agent pick a value in M0.
