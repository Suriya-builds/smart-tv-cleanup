# This TV: clone "Sony" (ShenZhen VideoScape TVOS, Zeasn launcher)

MediaTek mt5862 board (model `mt9255l`), Android 9 (SDK 28), 1 GB RAM, userdebug firmware
`TVOS-04.16.031.01.12`. Cleaned with the cleanyourtv repo: packages were **disabled for user 0, never
uninstalled**, so everything below can be switched back on.

All commands run from the repo root (`cleanyourtv/`) and need network ADB, which was switched off at the
end. To use them again: on the TV, Settings > Developer options > USB debugging **on**, then:

```bash
export TV_HOST=192.168.1.8          # the TV's IP
tools/venv/Scripts/python.exe -I tools/tv.py --probe
```

(On this PC `tools/venv` is a link to a venv in Claude's scratchpad. If it is gone, recreate it:
`py -3.12 -m venv tools/venv && tools/venv/Scripts/python -m pip install -r tools/requirements.txt`.
Windows' 260-character path limit bites in a deep folder: keep the repo in a short path, or
`subst T: <repo folder>` and work from `T:\`.)

## What was changed

| Batch | Package | Why |
|---|---|---|
| 1 | `com.android.media.module.services` | Not Android: an app in `/data/app` disguised with a system-like name, holding ad and proxy SDK services (Pangolin, PproxySDK, IopSdk, WoranSdk...). Installed silently by `com.zeasn.services.general` |
| 1 | `com.zeasn.services.general` | Zeasn ad / weather / search service, starts at boot |
| 1 | `com.zeasn.tv.assistant` | Zeasn "TV Master": watches app installs and network changes |
| 2 | `com.zeasn.deviceportal.asdprovider.videoscape` | Zeasn device portal: boot-time ad/portal service. Also its firmware-update check, so **no update notices** while it is off |
| 2 | `cn.zeasn.tv.vstoresubclient.mtk368.videoscape` | Zeasn TV Store (could install apps silently). Use Aptoide TV instead |
| 2 | `us.zoom.videomeetings` | Zoom, unused |
| 4 | `cn.zeasn.launcher.vstoresubclient.videoscape368` | Stock Zeasn launcher, replaced by the new Home (only after it was confirmed as Home) |

Also: **Private DNS** set to `dns.adguard-dns.com` (blocks most app/tracker ads, not YouTube's).
New Home: `com.gathin.tvhome`, the cleanyourtv reference launcher, with three changes for this TV
(`launcher/`):

- **Netflix**: this TV's Netflix (4.16) has no Android TV entry, so it is listed in `library_apps` and gets a
  bundled tile, `res/drawable/banner_netflix.xml` (`app_banners`).
- **Live TV** in the Inputs menu: the MediaTek Live TV app has no launcher entry, so the launcher now opens it
  with the standard "view channels" intent (`MainActivity.liveTvIntent()`). It resumes the last source.
- **Activity Launcher** (a sideloaded tool) is in `hidden_apps`, so it does not show on Home.

Look: the **supercars** theme (`work/supercars/`): six night photos of supercars from Wikimedia Commons, a new
one every 30 minutes with its name and photographer under the buttons, a frosted-glass dock. Credits and
licences (CC BY / CC BY-SA) are in `work/supercars/CREDITS.md`.

Left alone on purpose: every `com.vstv.*` package (input menu, hotkeys, settings, fallback Home, screen
mirroring, USB media player, factory menu - never opened), every MediaTek TV package, Android's core,
Aptoide TV and the streaming apps.

## Undo everything

```bash
TV_HOST=192.168.1.8 bash work/restore-all.sh
```

It gives Home back to Zeasn first, re-enables every package in `work/batch*.txt`, and resets Private DNS.
The original package lists, `getprop` and all settings are in `backup/`.

## Re-enable one app

```bash
tools/venv/Scripts/python.exe -I tools/tv.py 'pm enable --user 0 <package>'
```

e.g. firmware update notices back: `pm enable --user 0 com.zeasn.deviceportal.asdprovider.videoscape`.
Old Home back: `pm enable --user 0 cn.zeasn.launcher.vstoresubclient.videoscape368`, then
`cmd package set-home-activity --user 0 cn.zeasn.launcher.vstoresubclient.videoscape368/com.zeasn.smart.tv.ui.MainActivity`.

## Undo the ad-blocking DNS only

```bash
tools/venv/Scripts/python.exe -I tools/tv.py 'settings put global private_dns_mode opportunistic'
```

## Change the dock (order, number of slots) or the wallpaper

Edit `launcher/app/src/main/res/values/config.xml`:

- `dock_apps`: the dock apps, left to right (package names; `tools/tv.py 'pm list packages'` lists them).
  Now: `com.netflix.mediaclient`, `com.google.android.youtube.tv`, `com.amazon.amazonvideo.livingroom`,
  `in.startv.hotstar.dplus.tv`.
- `columns`: dock slots and grid columns (4 now; 5, 6 or 7 also work).
- `hidden_apps`: tiles never shown.

Then build and install:

```bash
bash work/build-and-install-this-tv.sh
```

To change the wallpapers: put your own 1920x1080 JPEGs (dark, under ~300 KB each) in
`work/supercars/wallpapers/` as `001.jpg`, `002.jpg`, ..., edit `captions.txt` to match (or set
`"wallpaper_captions": false` in `work/supercars/config.json`), then push:

```bash
TV_HOST=192.168.1.8 bash tools/theme.sh work/supercars
```

Speed of rotation: `wallpaper_rotation_minutes` in the same `config.json`. Back to the plain look:
`TV_HOST=192.168.1.8 bash tools/theme.sh --reset`.

Small changes need no rebuild: hold OK on a tile for its menu (move, hide). For a different look or a
wallpaper, use a theme instead of a rebuild: `tools/theme.sh themes/<name>` pushes a theme's `config.json`
and wallpaper to the TV (see `themes/README.md`; `tools/theme.sh --reset` goes back).

## Apps changed on 10 Nov 2026

| App | Before | Now |
|---|---|---|
| Netflix (`com.netflix.mediaclient`) | 4.16 (2016, "Can't Connect") | 7.120.6, phone build signed by Netflix, Inc. Old one removed first for space |
| YouTube for Android TV | 2.10.17 | 3.01.006 (newest 32-bit build on Aptoide; 5.x is 64-bit only) |
| Disney+ Hotstar TV (`in.startv.hotstar.dplus.tv`) | 5.1.0 | 5.3.0, which still asks for an update (see below) |
| Aptoide TV | 5.1.1 | 5.1.3 |
| Zoom, old Hotstar (`in.startv.hotstartvonly`) | installed | **uninstalled** (your choice; reinstall from Aptoide if wanted) |

Why Aptoide's "Update all" failed: app storage was full (81 MB free of 1.2 GB; Android keeps ~122 MB in
reserve). App caches were cleared with `pm trim-caches`.

Netflix is the phone version, so its first welcome screen cannot be reached with the remote: if it shows
"GET STARTED / SIGN IN" again, the **SIGN IN** link is at the top right. The sign-in form itself works with the
remote. Disney+ Hotstar 5.3 is the newest TV build Aptoide has; the app still asks for an update, and the
current JioHotstar TV build has to come from APKMirror (it blocks automated downloads).

## Idle clock screen

The TV's screensaver is now the launcher's clock (`settings put secure screensaver_components
com.gathin.tvhome/.ClockDream`; it was `com.google.android.deskclock/com.android.deskclock.Screensaver`).
It shows its own pictures: files named `clock-*.jpg` in `work/supercars/wallpapers/` (three PS5-style light-wave
pictures drawn in code, plus gaming photos from Wikimedia Commons, credited in `CREDITS.md`). Home never shows
`clock-*` pictures. Add or remove `clock-*.jpg` files and push with `tools/theme.sh work/supercars`.

## Checked on 9 Nov 2026

- After a reboot: the same 7 packages disabled, the new Home came up by itself (no Live TV takeover at power-on),
  no display size/density overrides, AdGuard DNS still set.
- Inputs menu: HDMI 1, HDMI 2, AV, AV and Live TV all present; Live TV opens the TV app on its last source.

## After you finish

Network/USB debugging was switched off (`adb_enabled 0`) and `tools/adb-closed.py 192.168.1.8` said
**closed** (twice, a minute apart). "Revoke USB debugging authorisations" is not offered on this firmware,
because it never checks keys (`ro.adb.secure` unset), so there was nothing to revoke. That also means
that while debugging is **on**, any device on your Wi-Fi can get a shell on the TV without a prompt: switch it
off again when you are done.
