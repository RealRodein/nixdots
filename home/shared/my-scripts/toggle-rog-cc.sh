#!/usr/bin/env bash
set -euo pipefail

# Toggle ROG Control Center.
#
# rog-control-center is a single-instance app that also lives in the tray. A
# second launch does not raise the existing window, so we:
#   1. focus the existing window if it has one,
#   2. otherwise restart it so it presents a window,
#   3. otherwise start it.

window_id() {
  command -v niri >/dev/null 2>&1 || return 1
  command -v jq   >/dev/null 2>&1 || return 1
  niri msg --json windows 2>/dev/null \
    | jq -r '.[] | select(.app_id == "rog-control-center") | .id' 2>/dev/null \
    | head -n1
}

if pgrep -f '[r]og-control-center' >/dev/null 2>&1; then
  id="$(window_id || true)"
  if [ -n "${id:-}" ] && [ "$id" != "null" ]; then
    niri msg action focus-window --id "$id" >/dev/null 2>&1 && exit 0
  fi
  # Running only as a tray app: restart it so a window is shown.
  pkill -f '[r]og-control-center' 2>/dev/null || true
  sleep 0.4
fi

setsid rog-control-center >/tmp/rog-control-center.log 2>&1 </dev/null &
