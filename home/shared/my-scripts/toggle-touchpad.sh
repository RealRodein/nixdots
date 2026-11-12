#!/usr/bin/env bash
set -euo pipefail

CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/niri/config.d/devices.kdl"

if [[ ! -f "$CONFIG" ]]; then
  noctalia msg notification-show "Touchpad" "Config not found" || true
  exit 1
fi

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

# Toggle the `off` line inside the touchpad { ... } block:
#   // off  ->  off     (disable)
#     off  ->  // off   (enable)
awk '
  /^[[:space:]]*touchpad[[:space:]]*\{/ { in_tp = 1 }
  in_tp && !done && /^[[:space:]]*\/\/[[:space:]]*off[[:space:]]*$/ {
    sub(/\/\/[[:space:]]*/, ""); done = 1
  }
  in_tp && !done && /^[[:space:]]*off[[:space:]]*$/ {
    sub(/off/, "// off"); done = 1
  }
  in_tp && /^[[:space:]]*\}/ { in_tp = 0 }
  { print }
' "$CONFIG" > "$tmp"

# Detect the new state from the touchpad block only (not unrelated `off`
# lines such as gestures { hot-corners { off } }).
state="$(
  awk '
    /^[[:space:]]*touchpad[[:space:]]*\{/ { in_tp = 1; next }
    in_tp && /^[[:space:]]*\}/ { exit }
    in_tp && /^[[:space:]]*off[[:space:]]*$/ { print "Disabled"; found = 1; exit }
    END { if (!found) print "Enabled" }
  ' "$tmp"
)"

mv "$tmp" "$CONFIG"
trap - EXIT
niri msg action load-config-file >/dev/null 2>&1 || true
noctalia msg notification-show "Touchpad" "$state" || true
