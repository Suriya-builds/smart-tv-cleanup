#!/usr/bin/env bash
# Put this TV back the way it was before the cleanup: re-enable every package disabled in the batches,
# give Home back to the Zeasn launcher, and undo the Private DNS change.
# Run from the repo root:  TV_HOST=192.168.1.8 bash work/restore-all.sh
# (needs network ADB on, i.e. USB debugging switched on again in the TV's Developer options)
set -uo pipefail
cd "$(dirname "$0")/.."
: "${TV_HOST:?set TV_HOST to the TV IP, e.g. TV_HOST=192.168.1.8}"
export TV_HOST
PY=tools/venv/bin/python; [ -x "$PY" ] || PY=tools/venv/Scripts/python.exe
STOCK=cn.zeasn.launcher.vstoresubclient.videoscape368

# 1. Stock launcher first, so the TV always has a Home.
"$PY" -I tools/tv.py "pm enable --user 0 $STOCK"
"$PY" -I tools/tv.py "cmd package set-home-activity --user 0 $STOCK/com.zeasn.smart.tv.ui.MainActivity"

# 2. The disable batches, newest first. tools/restore.sh uses the state recorded before each batch.
for list in work/batch4-launcher.txt work/batch2.txt work/batch1.txt; do
  [ -f "$list" ] && bash tools/restore.sh "$list"
done

# 3. Belt and braces: every package from every list, one pm call each.
for p in $(cat work/batch*.txt 2>/dev/null | sed -E 's/#.*//' | awk 'NF{print $1}'); do
  "$PY" -I tools/tv.py "pm enable --user 0 $p"
done

# 4. Private DNS back to Android's default (it was unset before).
"$PY" -I tools/tv.py "settings put global private_dns_mode opportunistic"
"$PY" -I tools/tv.py "settings delete global private_dns_specifier"

# 5. Optional: remove the new launcher too.  Uncomment to do it.
# "$PY" -I tools/tv.py "pm uninstall com.gathin.tvhome"

"$PY" -I tools/tv.py "pm list packages -d"
echo "Done. Press Home on the remote; the Zeasn home should come up."
