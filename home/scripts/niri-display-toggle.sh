# Usage: niri-display-toggle [1|2] — 1/2 extend with the external display left/right, no argument toggles mirroring.
external="HDMI-A-1"
internal="eDP-1"
external_mode="2560x1440@59.951"
internal_logical_width=1670

output() { niri msg output "$@" 2>/dev/null; }
notify() { notify-send "Display" "$1" 2>/dev/null || true; }
stop_mirror() { pkill -x wl-mirror 2>/dev/null || true; }

prepare_external() {
  output "$external" mode "$external_mode" || output "$external" mode "${external_mode%@*}" || true
  output "$external" scale 1.0 || true
}

extend_left() {
  stop_mirror
  prepare_external
  output "$external" position set 0 0 || true
  output "$internal" position set "${external_mode%%x*}" 0 || true
  notify "Extend — HDMI left, eDP right (1)"
}

extend_right() {
  stop_mirror
  output "$internal" position set 0 0 || true
  prepare_external
  output "$external" position set "$internal_logical_width" 0 || output "$external" position auto || true
  notify "Extend — eDP left, HDMI right (2)"
}

case "${1:-}" in
  1)
    extend_left
    exit 0
    ;;
  2)
    extend_right
    exit 0
    ;;
esac

if pgrep -x wl-mirror >/dev/null; then
  stop_mirror
  choice=$(printf '2 Right (eDP left)\n1 Left (HDMI left)' | fuzzel --dmenu --prompt "Extend side: " 2>/dev/null || echo 2)
  if [[ "$choice" == 1* ]]; then extend_left; else extend_right; fi
  exit 0
fi

if ! niri msg -j outputs 2>/dev/null | jq -e --arg o "$external" '.[$o]' >/dev/null; then
  notify "$external not connected"
  exit 0
fi

prepare_external
output "$external" position set "$internal_logical_width" 0 || output "$external" position auto || true
nohup wl-mirror --fullscreen-output "$external" --scaling fit "$internal" >/dev/null 2>&1 &
sleep 0.4
if pgrep -x wl-mirror >/dev/null; then
  notify "Mirror — HDMI shows eDP (wl-mirror, Mod+M to unmirror)"
else
  notify "Mirror failed to start"
fi
