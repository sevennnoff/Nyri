#!/usr/bin/env bash
# Record a one-minute walk-through of Nyri in the nested test window.
#
#   bin/nyri-nested --own-bus          # first, and make its window fullscreen
#   tools/demo.sh ~/Videos/nyri.mp4
#
# Everything is driven from here: keys through wtype, the rest through the
# shell's demo IPC (a drawn pointer, widget menus, drags) — so nothing touches
# the real session. Pacing is slow on purpose: long enough to see each motion.
set -euo pipefail

OUT="${1:-$HOME/Videos/nyri-demo.mp4}"
HERE="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

# The nested shell: the qs instance with NYRI_NESTED=1.
QP=""
for p in $(pgrep -f "^qs -c nyri"); do
    tr '\0' '\n' < /proc/$p/environ | grep -q '^NYRI_NESTED=1$' && QP=$p
done
[[ -n $QP ]] || { echo "demo.sh: start bin/nyri-nested first" >&2; exit 1; }
while IFS= read -r l; do
    case "$l" in WAYLAND_DISPLAY=*|NIRI_SOCKET=*|DBUS_SESSION_BUS_ADDRESS=*|NYRI_*=*) export "$l" ;; esac
done < <(tr '\0' '\n' < /proc/$QP/environ)

q()     { qs ipc --pid "$QP" call nyri "$@" >/dev/null; }
beat()  { sleep "${1:-1.6}"; }
point() { q demoPointer "$1" "$2"; beat "${3:-0.5}"; }
click() { q demoClick; beat 0.25; }
keys()  { wtype -d 110 "$@"; }
key()   { wtype -k "$@"; }

W=$(niri msg -j outputs | jq '[.[]][0].logical.width')
H=$(niri msg -j outputs | jq '[.[]][0].logical.height')

cleanup() {
    pkill -INT -x wf-recorder 2>/dev/null || true
    # Let it finish writing the file (the index goes at the end).
    for _ in $(seq 50); do pgrep -x wf-recorder >/dev/null || break; sleep 0.1; done
    [[ -n ${PLAYER:-} ]] && kill "$PLAYER" 2>/dev/null || true
    niri msg action close-window 2>/dev/null || true
    q demoHidePointer || true
}
trap cleanup EXIT

# ── Scene (about a minute) ────────────────────────────────────────────
q close
q lock
beat 2
wf-recorder -r 60 -c libx264 -p preset=veryfast -p crf=20 -f "$OUT" -y &>/dev/null &
beat 1.4

# Lock: wake, a wrong password, then in.
key Shift_L; beat 1
keys "letmein"; key Return; beat 2.6
keys "hunter2"; q unlockNested; beat 2

# Widgets: a menu of live previews, a new look, a drag onto the grid.
point 186 254 0.6
click; q demoMenu clock; beat 1.6
point 104 643 0.6; click; q demoLook clock 2; q demoMenuClose; beat 1.2
point 186 520 0.5; click; q demoMenu battery; beat 1.4
point 288 180 0.5; click; q demoLook battery 1; q demoMenuClose; beat 1
point 131 559 0.5
q demoDrag battery 552 960; beat 2.4

# A message, then music.
notify-send -a "AyuGram Desktop" -i com.ayugram.desktop "TikTok You" "rfbrt"; beat 1.8
python3 "$HERE/demo-player.py" "AyuGram Desktop" "азарт" "tewiq" "${NYRI_DEMO_COVER:-}" &
PLAYER=$!
beat 1.8

# The right panel and Wi-Fi; the dashboard.
point $((W - 30)) 32 0.5; click; q toggle control; beat 1.8
q open control wifi; beat 1.6
q close; beat 0.4
point $((W / 2)) 32 0.5; click; q toggle dashboard; beat 2.2
q close; beat 0.4

# Search: a sum right in the search field.
point 30 32 0.5; click; q toggle launcher; beat 0.6
wtype -d 70 "2^10 + 24"; beat 1.4
key Escape; beat 0.4

# The capture menu and the volume OSD.
q toggle snip; beat 0.8
key Right; beat 0.6; key Right; beat 0.6
key Escape; beat 0.4
q osd volume; beat 1.2

# Windows: two terminals, maximize, the overview, close.
q demoHidePointer
a() { niri msg action "$@" >/dev/null; }
a spawn -- kitty sh -c "fastfetch; exec fish"; beat 1.6
a spawn -- kitty; beat 1.5
a maximize-column; beat 1.2
a maximize-column; beat 0.8
q switcher next; beat 1.6
a toggle-overview; beat 1.8
a toggle-overview; beat 0.8
a close-window; beat 0.6
a close-window; beat 1

# Settings: the header folds as the page scrolls.
q settings; beat 1.4
key Next; beat 1.2
key Escape; beat 0.6

# Wallpapers: your own colour, apply — everything recolors.
q toggle wallpaper; beat 1.4
key Right; beat 0.7; key Right; beat 0.7
keys "c"; beat 1.2
key Return; beat 4
key Escape; beat 0.8

# Back to the lock screen.
q lock; beat 2.2
