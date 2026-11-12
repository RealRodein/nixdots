#!/usr/bin/env bash
set -euo pipefail

CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/niri/config.d/devices.kdl"

if [[ ! -f "$CONFIG" ]]; then
  noctalia msg notification-show "Touchpad" "Config not found" || true
  exit 1
fi

tmp="$(mktemp)"
# Toggle `off` inside the touchpad { ... } block.
# If touchpad is off (uncommented `off`), comment it out to enable.
# If touchpad is enabled (`// off`), uncomment to disable.
awk '
  BEGIN { in_touchpad=0; depth=0; toggled=0 }
  /^[[:space:]]*touchpad[[:space:]]*\{/ { in_touchpad=1; depth=1; print; next }
  in_touchpad {
    # track braces to know when touchpad block ends
    line=$0
    opens=gsub(/\{/, "{", line)
    closes=gsub(/\}/, "}", line)
    # adjust depth using original counts
    # re-count on a copy
  }
  {
    if (in_touchpad && !toggled) {
      if ($0 ~ /^[[:space:]]*\/\/[[:space:]]*off[[:space:]]*$/) {
        sub(/\/\/[[:space:]]*/, "")
        toggled=1
        state="disabled"
        print
        next
      } else if ($0 ~ /^[[:space:]]*off[[:space:]]*$/) {
        sub(/off/, "// off")
        toggled=1
        state="enabled"
        print
        next
      }
    }
    print
    if (in_touchpad) {
      # update brace depth
      t=$0
      o=gsub(/\{/, "&", t)
      t=$0
      c=gsub(/\}/, "&", t)
      depth += o - c
      if (depth <= 0) in_touchpad=0
    }
  }
  END {
    if (toggled) {
      print state > "/dev/stderr"
    } else {
      print "unchanged" > "/dev/stderr"
    }
  }
' "$CONFIG" > "$tmp" 2> >(cat >&2) || { rm -f "$tmp"; exit 1; }

# Capture state from stderr of awk is messy; re-detect from result.
if grep -qE '^[[:space:]]*off[[:space:]]*$' "$tmp"; then
  state_msg="Disabled"
else
  state_msg="Enabled"
fi

mv "$tmp" "$CONFIG"
niri msg action load-config-file >/dev/null 2>&1 || true
noctalia msg notification-show "Touchpad" "$state_msg" || true
